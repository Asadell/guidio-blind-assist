"""
test_describe.py — Tes endpoint POST /api/describe (Moondream2 VLM).

Mensimulasikan Flutter mengirim frame kamera saat user berkata "deskripsikan".
Gambar diambil dari guidio_app/test/fixtures/navigation/ —
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
    """Validasi struktur respons — tidak bergantung isi caption."""

    def test_response_200(self, client, nav_image):
        r = _post_describe(client, nav_image)
        assert r.status_code == 200

    def test_has_description_en(self, client, nav_image):
        """Response harus punya key 'description_en' (bukan 'deskripsi')."""
        body = _post_describe(client, nav_image).json()
        assert "description_en" in body, \
            "Key 'description_en' tidak ada — pastikan bukan versi lama yang pakai 'deskripsi'"

    def test_no_deskripsi_key(self, client, nav_image):
        """Key lama 'deskripsi' (Bahasa Indonesia) sudah dihapus."""
        body = _post_describe(client, nav_image).json()
        assert "deskripsi" not in body

    def test_description_is_english(self, client, nav_image):
        """Caption harus dalam Bahasa Inggris (cek beberapa kata umum EN)."""
        body = _post_describe(client, nav_image).json()
        desc = body.get("description_en", "")
        if not desc or body.get("error"):
            pytest.skip("Moondream belum dimuat atau gagal — skip language check")
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
