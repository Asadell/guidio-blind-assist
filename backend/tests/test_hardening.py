"""
test_hardening.py — Tes untuk masukan yang aneh-aneh.

Semua tes di sini menirukan apa yang dilakukan penguji yang iseng, klien yang
rusak, atau pengguna yang salah pencet. Yang diperiksa bukan "apakah hasilnya
benar" — untuk masukan seperti ini tidak ada hasil yang benar — tapi apakah
server tetap berdiri, tetap menjawab 200, dan tetap memberi pengguna kalimat
yang bisa ditindaklanjuti.

KENAPA SELALU 200, BUKAN 4xx

Klien Flutter membacakan `message` lewat TTS. Balasan 4xx tanpa badan yang
terstruktur berakhir sebagai pengecualian jaringan di sisi aplikasi, dan yang
didengar pengguna cuma "gagal menghubungi server" — padahal yang salah adalah
fotonya, dan itu bisa dia perbaiki sendiri kalau diberi tahu.
"""

import io

import numpy as np
import pytest
from PIL import Image

from services.image_gate import MAX_DECODED_PIXELS, MAX_UPLOAD_BYTES


def _jpeg(w: int = 640, h: int = 480, color: int = 128) -> bytes:
    """JPEG polos berukuran tertentu."""
    buf = io.BytesIO()
    Image.fromarray(
        np.full((h, w, 3), color, np.uint8)
    ).save(buf, format="JPEG", quality=85)
    return buf.getvalue()


def _post_cari(client, image_bytes: bytes, target: str, **fields):
    data = {"target": target}
    data.update({k: str(v) for k, v in fields.items()})
    return client.post(
        "/api/cari-objek",
        data=data,
        files={"file": ("frame.jpg", image_bytes, "image/jpeg")},
    )


class TestUkuranUnggahan:
    """Berkas raksasa tidak boleh menjatuhkan proses."""

    def test_unggahan_di_atas_batas_ditolak_dengan_sopan(self, client):
        oversize = b"\xff\xd8\xff" + b"\x00" * (MAX_UPLOAD_BYTES + 1024)
        r = _post_cari(client, oversize, "dompet")
        assert r.status_code == 200
        body = r.json()
        assert body["found"] is False
        assert body["reason"] == "gambar_terlalu_besar"
        assert body["message"], "pesan untuk TTS wajib ada"

    def test_tepat_di_bawah_batas_masih_diproses(self, client):
        # Membuktikan batasnya tidak kelewat ketat sampai menolak foto wajar.
        r = _post_cari(client, _jpeg(1280, 720), "dompet")
        assert r.status_code == 200
        assert r.json().get("reason") != "gambar_terlalu_besar"


class TestDecodeBomb:
    """Berkas kecil, kanvas raksasa."""

    def test_gambar_dengan_pixel_sangat_banyak_ditolak(self, client):
        # PNG satu warna 8000x6000 = 48 MP: berkasnya cuma puluhan KB, tapi
        # begitu didekode jadi BGR 8-bit dia memakan ratusan MB. Tanpa batas
        # ini, beberapa permintaan serentak sudah cukup menjatuhkan proses.
        side_w, side_h = 8000, 6000
        assert side_w * side_h > MAX_DECODED_PIXELS

        buf = io.BytesIO()
        Image.new("RGB", (side_w, side_h), (10, 20, 30)).save(
            buf, format="PNG", optimize=False
        )
        payload = buf.getvalue()
        if len(payload) > MAX_UPLOAD_BYTES:
            pytest.skip(
                "PNG uji melebihi batas unggahan, jadi tertahan lapis pertama "
                "— jalur itu sudah diuji terpisah"
            )

        r = _post_cari(client, payload, "dompet")
        assert r.status_code == 200
        body = r.json()
        assert body["reason"] == "resolusi_terlalu_besar"
        assert body["retry_suggested"] is True


class TestMasukanBukanGambar:
    """Berkas yang formatnya sama sekali bukan gambar."""

    @pytest.mark.parametrize("payload,nama", [
        (b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n", "pdf"),
        (b"\x00\x00\x00\x18ftypmp42", "video mp4"),
        (b"PK\x03\x04" + b"\x00" * 64, "zip"),
        (b"bukan gambar sama sekali", "teks polos"),
        (b"\xff\xd8\xff\xe0" + b"\x00" * 32, "JPEG terpotong"),
    ])
    def test_dijawab_bukan_dilempar(self, client, payload, nama):
        r = _post_cari(client, payload, "dompet")
        assert r.status_code == 200, f"{nama} menyebabkan {r.status_code}"
        body = r.json()
        assert body["found"] is False
        assert body["reason"] == "gambar_rusak"
        assert body["message"]


class TestTargetAneh:
    """`target` datang dari pengenalan suara dan DIBACAKAN kembali ke pengguna."""

    def test_target_kosong_ditolak_dengan_instruksi(self, client):
        r = _post_cari(client, _jpeg(), "   ")
        assert r.status_code == 200
        body = r.json()
        assert body["reason"] == "target_kosong"
        assert "sebutkan" in body["message"].lower()

    def test_target_sangat_panjang_dipotong(self, client):
        r = _post_cari(client, _jpeg(), "dompet " * 500)
        assert r.status_code == 200
        # Yang dipantulkan balik tidak boleh sepanjang aslinya: nilai ini
        # dibacakan TTS, dan teks ribuan karakter menyumbat antrean suara.
        assert len(r.json().get("target", "")) <= 64

    def test_karakter_kendali_dibuang(self, client):
        r = _post_cari(client, _jpeg(), "dom\x00pet\n\nhalo")
        assert r.status_code == 200
        echoed = r.json().get("target", "")
        assert "\x00" not in echoed
        assert "\n" not in echoed

    @pytest.mark.parametrize("aneh", [
        "'; DROP TABLE labels; --",
        "<script>alert(1)</script>",
        "../../etc/passwd",
        "😀🎉🚀",
        "‮ترتيب",
    ])
    def test_tidak_pernah_jatuh_apa_pun_isinya(self, client, aneh):
        r = _post_cari(client, _jpeg(), aneh)
        assert r.status_code == 200
        assert "found" in r.json()


class TestConfAneh:
    """`conf` dikurung, bukan diteruskan mentah ke model."""

    @pytest.mark.parametrize("nilai", [-5, 0, 1.5, 99, 1e9, -1e9])
    def test_nilai_di_luar_rentang_tidak_menjatuhkan(self, client, nilai):
        r = _post_cari(client, _jpeg(), "dompet", conf=nilai)
        assert r.status_code == 200
        assert "found" in r.json()

    def test_conf_bukan_angka_ditolak_form(self, client):
        # FastAPI sendiri yang menolak di lapisan validasi; yang penting
        # servernya tidak jatuh dan balasannya terstruktur.
        r = _post_cari(client, _jpeg(), "dompet", conf="bukan-angka")
        assert r.status_code in (200, 422)


class TestDescribeMasukanAneh:
    """Endpoint deskripsi memakai gerbang yang sama."""

    def test_unggahan_raksasa_ditolak(self, client):
        oversize = b"\xff\xd8\xff" + b"\x00" * (MAX_UPLOAD_BYTES + 1024)
        r = client.post(
            "/api/describe",
            files={"image": ("scene.jpg", oversize, "image/jpeg")},
        )
        assert r.status_code == 200
        body = r.json()
        assert body["reason"] == "gambar_terlalu_besar"
        assert not body.get("description_en"), \
            "tidak boleh ada deskripsi dari gambar yang tidak pernah dibaca"


class TestFieldHilang:
    """Klien rusak yang tidak mengirim bagian yang diwajibkan."""

    def test_tanpa_berkas(self, client):
        r = client.post("/api/cari-objek", data={"target": "dompet"})
        assert r.status_code == 422

    def test_tanpa_target(self, client):
        r = client.post(
            "/api/cari-objek",
            files={"file": ("frame.jpg", _jpeg(), "image/jpeg")},
        )
        assert r.status_code == 422

    def test_berkas_di_field_yang_salah(self, client):
        r = client.post(
            "/api/cari-objek",
            data={"target": "dompet"},
            files={"gambar": ("frame.jpg", _jpeg(), "image/jpeg")},
        )
        assert r.status_code == 422
