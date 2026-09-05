"""Keamanan unggahan: berkas yang menyamar sebagai gambar.

Pertanyaan yang dijawab berkas ini: kalau seseorang mengirim `.exe` yang
dinamai ulang `foto.png`, apa yang terjadi?

Jawabannya ada tiga lapis, dan ketiganya diuji di sini:

  1. NAMA BERKAS TIDAK PERNAH DIBACA. `file.filename` dan `file.content_type`
     tidak muncul satu kali pun di seluruh backend. Keduanya dikirim klien,
     jadi memeriksanya tidak menambah keamanan apa pun - penyerang yang
     mengarang isi berkas juga bisa mengarang namanya.

  2. ISINYA YANG DIPERIKSA. Delapan byte pertama harus cocok dengan JPEG,
     PNG, atau WebP, lalu isinya harus benar-benar bisa didekode jadi matriks
     pixel. Berkas PE, ELF, skrip, dan SVG gagal di lapis ini.

  3. TIDAK ADA YANG DIJALANKAN ATAU DISIMPAN. Byte yang masuk tidak pernah
     ditulis ke disk, tidak pernah diserahkan ke shell, dan tidak pernah
     dideserialisasi. Ia hanya pernah menjadi array angka. `.exe` yang lolos
     sekalipun tidak punya jalan untuk dieksekusi, karena tidak ada satu pun
     baris kode yang menjalankan apa pun.

Lapis 3 diuji sebagai properti kode (bukan lewat HTTP), karena "tidak pernah
terjadi" tidak bisa dibuktikan dengan satu permintaan.
"""

import re
import struct
import zlib
from pathlib import Path

import pytest

BACKEND_DIR = Path(__file__).resolve().parent.parent


# ── Pembuat berkas ────────────────────────────────────────────────────────

def _png(w: int = 8, h: int = 8) -> bytes:
    """PNG merah polos yang benar-benar sah."""
    def chunk(tag: bytes, data: bytes) -> bytes:
        body = tag + data
        return (struct.pack(">I", len(data)) + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    raw = b"".join(b"\x00" + b"\xff\x00\x00" * w for _ in range(h))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw))
            + chunk(b"IEND", b""))


_PE = (b"MZ" + b"\x90\x00" * 30
       + b"This program cannot be run in DOS mode.\r\n$"
       + b"PE\x00\x00" + b"\x4c\x01" + b"\x00" * 200)

_ELF = (b"\x7fELF\x02\x01\x01\x00" + b"\x00" * 8
        + struct.pack("<HH", 2, 0x3E) + b"\x00" * 200)

# Nama berkasnya sengaja meyakinkan. Kalau ada satu saja lapis yang memeriksa
# ekstensi alih-alih isi, berkas-berkas ini akan lolos.
PENYAMARAN = [
    ("foto_liburan.png", _PE, "PE Windows"),
    ("selfie.jpg", _ELF, "ELF Linux"),
    ("gambar.png", b"<?php system($_GET['cmd']); ?>\n" + b"A" * 100, "webshell PHP"),
    ("kamera.jpeg", b"#!/bin/sh\nrm -rf /\n", "skrip shell"),
    ("logo.png", b'<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>', "SVG berisi script"),
    ("rusak.png", b"\x89PNG\r\n\x1a\n" + b"\x00" * 500, "header PNG palsu"),
    ("arsip.png", b"PK\x03\x04" + b"\x00" * 200, "ZIP"),
    ("dokumen.jpg", b"%PDF-1.7\n" + b"\x00" * 200, "PDF"),
]


# ── Lapis 1 + 2: lewat HTTP ───────────────────────────────────────────────

class TestBerkasMenyamarJadiGambar:
    """Ekstensi `.png` tidak menolong berkas yang isinya bukan gambar."""

    @pytest.mark.parametrize("nama,isi,jenis", PENYAMARAN,
                             ids=[p[2] for p in PENYAMARAN])
    def test_cari_objek_menolak(self, client, nama, isi, jenis):
        r = client.post(
            "/api/cari-objek",
            data={"target": "dompet"},
            files={"file": (nama, isi, "image/png")},
        )
        assert r.status_code == 200, f"{jenis} membuat server melempar galat"
        body = r.json()
        assert body["found"] is False
        assert body.get("reason") in ("format_tidak_didukung", "gambar_rusak"), (
            f"{jenis} bernama {nama} TIDAK ditolak, reason={body.get('reason')}"
        )

    @pytest.mark.parametrize("nama,isi,jenis", PENYAMARAN,
                             ids=[p[2] for p in PENYAMARAN])
    def test_describe_menolak(self, client, nama, isi, jenis):
        r = client.post("/api/describe",
                        files={"image": (nama, isi, "image/jpeg")})
        assert r.status_code == 200
        body = r.json()
        assert body["ok"] is False
        assert body.get("reason") in ("format_tidak_didukung", "gambar_rusak")

    def test_gambar_sah_tetap_lolos(self, client):
        """Kontrol. Tanpa ini, tes di atas bisa hijau hanya karena semuanya ditolak."""
        r = client.post(
            "/api/cari-objek",
            data={"target": "dompet"},
            files={"file": ("apa_saja.bin", _png(), "application/octet-stream")},
        )
        assert r.status_code == 200
        # Nama `.bin` dan content-type `octet-stream` sengaja salah semua.
        # Yang menentukan cuma isinya, jadi ini harus lolos gerbang.
        assert r.json().get("reason") != "format_tidak_didukung"


class TestPolyglot:
    """PNG sah dengan muatan ditempel di belakangnya.

    Berkas ini LOLOS gerbang, dan itu memang benar: ia sungguh gambar yang
    bisa didekode. Yang penting bukan menolaknya, melainkan memastikan ekornya
    tidak pernah ikut ke mana-mana.
    """

    def test_diterima_sebagai_gambar_biasa(self, client):
        r = client.post(
            "/api/cari-objek",
            data={"target": "dompet"},
            files={"file": ("polyglot.png", _png() + _PE, "image/png")},
        )
        assert r.status_code == 200
        assert r.json().get("reason") not in ("format_tidak_didukung", "gambar_rusak")

    def test_muatan_tidak_ikut_ke_moondream(self):
        """Byte yang diteruskan ke VLM adalah hasil encode ulang server.

        `describe` mengambil frame yang sudah didekode lalu meng-encode-nya
        kembali jadi JPEG, jadi apa pun yang menempel di berkas asli tidak
        ikut. Diuji langsung pada fungsinya, karena inilah satu-satunya
        tempat byte klien pernah bisa mencapai parser kedua.
        """
        import sys
        sys.path.insert(0, str(BACKEND_DIR))
        from utils.image_utils import bytes_to_numpy, numpy_to_jpeg_bytes

        polyglot = _png() + _PE
        assert b"This program cannot be run in DOS mode" in polyglot

        frame = bytes_to_numpy(polyglot)
        assert frame is not None, "polyglot seharusnya tetap gambar yang sah"

        keluar = numpy_to_jpeg_bytes(frame, quality=92)
        assert b"This program cannot be run in DOS mode" not in keluar
        assert b"MZ" != keluar[:2]
        assert keluar[:3] == b"\xff\xd8\xff", "hasilnya harus JPEG buatan server"


# ── Lapis 3: properti kode, bukan permintaan HTTP ─────────────────────────

class TestTidakAdaJalanEksekusi:
    """Yang diuji: ketiadaan. Sekali ada yang menambahkannya, tes ini merah."""

    BERKAS = [
        "main.py",
        "routers/cari_objek.py",
        "routers/describe.py",
        "routers/support.py",
        "services/image_gate.py",
        "services/find_object_service.py",
        "services/moondream_service.py",
        "utils/image_utils.py",
    ]

    @pytest.mark.parametrize("relatif", BERKAS)
    def test_tidak_menjalankan_proses_atau_deserialisasi(self, relatif):
        isi = (BACKEND_DIR / relatif).read_text(encoding="utf-8")
        # Baris komentar dibuang: berkas ini banyak menjelaskan ALASAN,
        # dan penjelasannya wajar menyebut nama-nama berbahaya itu.
        kode = "\n".join(b for b in isi.splitlines()
                         if not b.lstrip().startswith("#"))
        for terlarang in ("subprocess", "os.system", "os.popen",
                          "pickle.load", "yaml.load", "marshal."):
            assert terlarang not in kode, (
                f"{relatif} memakai `{terlarang}`. Unggahan pengguna mengalir "
                f"lewat berkas ini; tidak ada satu pun alasan menjalankan "
                f"proses atau mendeserialisasi data di jalur itu."
            )

    @pytest.mark.parametrize("relatif", BERKAS)
    def test_tidak_menulis_unggahan_ke_disk(self, relatif):
        """Yang dicari penulisan ke DISK, bukan pembukaan buffer di memori.

        `Image.open(io.BytesIO(...))` sengaja tidak dihitung: ia mendekode
        byte yang sudah ada di RAM dan tidak pernah menyentuh berkas. Yang
        dilarang adalah `open()` dengan mode tulis dan sepupunya, karena di
        situlah byte unggahan berubah menjadi berkas - dan begitu ia menjadi
        berkas, nama berkasnya berubah menjadi masalah keamanan yang baru.
        """
        isi = (BACKEND_DIR / relatif).read_text(encoding="utf-8")
        kode = "\n".join(b for b in isi.splitlines()
                         if not b.lstrip().startswith("#"))

        for terlarang in ("cv2.imwrite", ".write_bytes(", ".write_text(",
                          "os.rename", "shutil."):
            assert terlarang not in kode, (
                f"{relatif} menulis ke disk lewat `{terlarang}`."
            )

        # `open(..., "w")` / "wb" / "a" / "x" dalam segala variasi kutipnya.
        tulis = re.search(r"""(?<![.\w])open\s*\([^)]*['"][rb+]*[wax]""", kode)
        assert tulis is None, (
            f"{relatif} membuka berkas dengan mode tulis: {tulis.group(0)!r}"
        )

    def test_nama_berkas_klien_tidak_pernah_dibaca(self):
        """`filename` dan `content_type` keduanya dikarang klien.

        Membacanya bukan sekadar sia-sia, tapi menyesatkan: kode yang
        memeriksa ekstensi terlihat seperti sedang mengamankan sesuatu,
        padahal keputusannya diambil dari data penyerang.
        """
        for relatif in self.BERKAS:
            isi = (BACKEND_DIR / relatif).read_text(encoding="utf-8")
            kode = "\n".join(b for b in isi.splitlines()
                             if not b.lstrip().startswith("#"))
            assert ".filename" not in kode, f"{relatif} membaca nama berkas klien"
            assert ".content_type" not in kode, f"{relatif} membaca content-type klien"


class TestBatasSumberDaya:
    """Batas yang menjaga proses tetap hidup, bukan menilai kualitas foto."""

    def test_timeout_dikurung(self):
        """`timeout` datang dari form, jadi ia data penyerang."""
        import sys
        sys.path.insert(0, str(BACKEND_DIR))
        from routers.describe import MAX_TIMEOUT, MIN_TIMEOUT

        assert MAX_TIMEOUT <= 120, (
            "Batas atas terlalu longgar. Satu permintaan dengan timeout besar "
            "menahan slot GPU selama itu juga."
        )
        assert MIN_TIMEOUT > 0

    def test_timeout_raksasa_tidak_menahan_gpu(self, client):
        """Kiriman `timeout=86400` harus dipotong, bukan dituruti."""
        r = client.post(
            "/api/describe",
            data={"timeout": "86400"},
            files={"image": ("x.png", _png(), "image/png")},
        )
        # Yang diuji: server menjawab, tidak menggantung sampai tes gagal
        # karena kehabisan waktu.
        assert r.status_code == 200
