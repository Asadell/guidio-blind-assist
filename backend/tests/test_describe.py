"""
test_describe.py - Tes endpoint POST /api/describe (Moondream2 VLM).

Mensimulasikan Flutter mengirim frame kamera saat user berkata "deskripsikan".
Gambar diambil dari guidio_app/test/fixtures/navigation/ -
byte-for-byte identik dengan yang dikirim kamera HP.

Catatan: Moondream2 lazy-load (~5-10 detik pertama kali).
         Test ini akan lambat di run pertama, cepat di run berikutnya.
"""

import pytest


def _post_describe(client, image_bytes: bytes, filename: str = "frame.png"):
    """Helper: POST /api/describe dengan format persis yang dikirim Flutter."""
    return client.post(
        "/api/describe",
        files={"image": (filename, image_bytes, "image/png")},
        timeout=120,  # Moondream warm-up bisa lambat
    )


class TestDescribeStruktur:
    """Validasi struktur respons - tidak bergantung isi caption."""

    def test_response_200(self, client, nav_image):
        r = _post_describe(client, nav_image)
        assert r.status_code == 200

    def test_has_description_en(self, client, nav_image):
        """Response harus punya key 'description_en' (bukan 'deskripsi')."""
        body = _post_describe(client, nav_image).json()
        assert "description_en" in body, \
            "Key 'description_en' tidak ada - pastikan bukan versi lama yang pakai 'deskripsi'"

    def test_no_deskripsi_key(self, client, nav_image):
        """Key lama 'deskripsi' (Bahasa Indonesia) sudah dihapus."""
        body = _post_describe(client, nav_image).json()
        assert "deskripsi" not in body

    def test_description_is_english(self, client, nav_image):
        """Caption harus dalam Bahasa Inggris (cek beberapa kata umum EN)."""
        body = _post_describe(client, nav_image).json()
        desc = body.get("description_en", "")
        if not desc or body.get("error"):
            pytest.skip("Moondream belum dimuat atau gagal - skip language check")
        # Caption EN tidak mengandung kata-kata khas BI di awal
        bi_starters = ("sebuah", "ini adalah", "gambar menunjukkan", "terdapat")
        assert not any(desc.lower().startswith(s) for s in bi_starters), \
            f"Caption tampaknya Bahasa Indonesia: '{desc[:80]}'"

    def test_description_nonempty_on_success(self, client, nav_image):
        """Jika tidak ada error, description_en tidak boleh kosong."""
        body = _post_describe(client, nav_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream error (mungkin belum dimuat): {body['error']}")
        assert body["description_en"].strip(), "description_en kosong padahal tidak ada error"


class TestDescribeInvalidInput:
    def test_invalid_image_returns_200(self, client):
        """Gambar rusak harus balas 200 dengan error field, bukan crash 500."""
        r = _post_describe(client, b"bukan_gambar")
        assert r.status_code == 200

    def test_invalid_image_has_error_or_fallback(self, client):
        """Gambar rusak harus ada 'error' atau description fallback."""
        body = _post_describe(client, b"bukan_gambar").json()
        has_error = bool(body.get("error"))
        has_desc  = bool(body.get("description_en"))
        assert has_error or has_desc, \
            "Respons tidak punya 'error' maupun 'description_en'"

    def test_empty_image_returns_200(self, client):
        """Gambar kosong (0 byte) harus 200, bukan 500."""
        r = _post_describe(client, b"")
        assert r.status_code == 200

    def test_gambar_rusak_ditolak_sebelum_moondream(self, client):
        """Gerbang kualitas harus menolak SEBELUM VLM dipanggil.

        Ini perbaikan yang paling penting di endpoint ini: Moondream2 tidak
        pernah bilang "saya tidak bisa melihat", dia menghasilkan deskripsi
        yang terdengar meyakinkan dari input apa pun. Untuk pengguna yang
        tidak bisa memverifikasi sendiri, halusinasi lebih berbahaya
        daripada penolakan yang jujur.
        """
        body = _post_describe(client, b"bukan_gambar").json()
        assert body.get("ok") is False
        assert body.get("reason") == "gambar_rusak"
        assert body.get("message"), "Pesan Bahasa Indonesia untuk TTS wajib ada"
        assert not body.get("description_en"), \
            "Tidak boleh ada deskripsi dari gambar yang tidak terbaca"


class TestDescribeKonten:
    """
    Validasi isi caption untuk gambar yang sudah diketahui objeknya.
    04_motor_dan_orang.png berisi scooter + orang di trotoar.
    Skip otomatis jika Moondream belum dimuat.
    """

    def test_motor_orang_caption_reasonable(self, client, nav_image):
        body = _post_describe(client, nav_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream tidak tersedia: {body['error']}")
        desc = body["description_en"].lower()
        # Setidaknya salah satu dari: person/people/man/woman, scooter/motorcycle/bike
        has_person = any(w in desc for w in ("person", "people", "man", "woman", "pedestrian"))
        has_vehicle = any(w in desc for w in ("scooter", "motorcycle", "bike", "moped", "vehicle"))
        assert has_person or has_vehicle, \
            f"Caption tidak menyebut orang/motor: '{desc[:120]}'"

    def test_got_terbuka_caption_reasonable(self, client, got_image):
        body = _post_describe(client, got_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream tidak tersedia: {body['error']}")
        desc = body["description_en"].lower()
        # Gambar got terbuka: biasanya ada sidewalk/road/street/drain/gutter
        hazard_words = ("sidewalk", "road", "street", "drain", "gutter",
                        "pavement", "concrete", "ground", "path", "hole")
        assert any(w in desc for w in hazard_words), \
            f"Caption tidak mendeskripsikan permukaan jalan: '{desc[:120]}'"


# ═══════════════════════════════════════════════════════════════════════════
#  Regresi: foto apa pun yang bisa dibaca HARUS sampai ke Moondream2
#
#  Setiap penolakan berarti pengguna tunanetra sudah mengangkat ponsel,
#  menunggu jepretan, menunggu perjalanan jaringan - lalu disuruh mengulang
#  semuanya, tanpa bisa melihat fotonya untuk tahu apa yang salah. Jawaban
#  "sepertinya ruangan dengan meja" dari foto agak buram memberi jauh lebih
#  banyak daripada gerbang yang menjawab "coba lagi".
# ═══════════════════════════════════════════════════════════════════════════

class TestDescribeTidakMenolakKualitas:
    """Gerbang `describe` hanya menjaga sumber daya, bukan menilai foto."""

    @staticmethod
    def _jpeg(frame):
        import cv2
        ok, buf = cv2.imencode(".jpg", frame)
        assert ok
        return buf.tobytes()

    def test_foto_sangat_buram_tetap_diteruskan(self):
        import cv2
        import numpy as np

        from services.image_gate import gate

        buram = cv2.GaussianBlur(np.full((480, 640, 3), 90, np.uint8), (31, 31), 0)
        g = gate(self._jpeg(buram), profile="describe", endpoint="test")

        assert g.ok is True, "foto buram tidak boleh ditolak di jalur describe"
        assert g.frame is not None

    def test_foto_gelap_gulita_tetap_diteruskan(self):
        import numpy as np

        from services.image_gate import gate

        gelap = np.zeros((480, 640, 3), np.uint8)
        g = gate(self._jpeg(gelap), profile="describe", endpoint="test")

        assert g.ok is True, "foto gelap tidak boleh ditolak di jalur describe"

    def test_find_object_ikut_meneruskan_foto_buram(self):
        """`find_object` menyusul `describe`, dengan alasan yang sama.

        Test ini dulu berbunyi kebalikannya - ia menjaga agar `find_object`
        TETAP menolak, sebagai bukti bahwa kelonggaran `describe` bukan
        pelemahan gerbang secara umum. Yang berubah bukan penilaian itu,
        melainkan cakupannya: kedua endpoint ternyata membayar ongkos yang
        sama. Satu tekan tombol, satu foto, satu jawaban - dan pengguna
        tunanetra tidak bisa melihat fotonya untuk tahu apa yang harus
        diperbaiki pada percobaan berikutnya.
        """
        import cv2
        import numpy as np

        from services.image_gate import gate

        buram = cv2.GaussianBlur(np.full((480, 640, 3), 90, np.uint8), (31, 31), 0)
        raw = self._jpeg(buram)

        g = gate(raw, profile="find_object", endpoint="test")
        assert g.ok is True, "foto buram tidak boleh ditolak di jalur cari-objek"
        # Penilaiannya TIDAK ikut hilang - ia yang jadi `quality_note` di
        # balasan, supaya jawaban dari foto buruk tetap membawa keraguannya.
        assert g.quality is not None

    def test_ocr_tetap_ketat(self):
        """Kelonggaran ini bukan pelemahan gerbang secara umum.

        `ocr` menuntut pixel jauh lebih banyak daripada dua yang lain: huruf
        kecil adalah hal pertama yang hilang saat gambar buram, dan teks yang
        salah dibaca lebih berbahaya daripada teks yang tidak terbaca -
        pengguna tidak punya cara memverifikasinya.
        """
        import cv2
        import numpy as np

        from services.image_gate import gate

        buram = cv2.GaussianBlur(np.full((480, 640, 3), 90, np.uint8), (31, 31), 0)
        raw = self._jpeg(buram)

        assert gate(raw, profile="ocr", endpoint="test").ok is False


class TestMoondreamPemanasan:
    """Permintaan pertama tidak boleh membayar biaya pemuatan model.

    Di log perangkat: permintaan pertama timeout pada 25 detik, model siap 6
    detik kemudian, permintaan kedua selesai dalam 2,4 detik. Fotonya tidak
    salah dan modelnya tidak lambat - yang salah cuma siapa yang menanggung
    pemanasannya.
    """

    def test_service_punya_warm_up_dan_ensure_ready(self):
        from services.moondream_service import MoonDreamService

        assert hasattr(MoonDreamService, "warm_up"), (
            "tanpa warm_up, pemuatan kembali ditanggung permintaan pertama"
        )
        assert hasattr(MoonDreamService, "ensure_ready"), (
            "ensure_ready memisahkan tunggu-pemuatan dari batas waktu inferensi"
        )

    def test_pemanasan_dijalankan_saat_startup(self):
        """Lifespan wajib memanggil warm_up, bukan menunggu request pertama."""
        import inspect

        import main

        sumber = inspect.getsource(main.lifespan)
        assert "warm_up()" in sumber
