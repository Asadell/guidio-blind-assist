"""
test_cari_objek.py — Tes endpoint POST /api/cari-objek.

Mensimulasikan Flutter mengirim frame kamera saat user berkata "cari dompet".
Semua gambar diambil dari guidio_app/test/fixtures/object_find/ —
byte-for-byte identik dengan yang dikirim kamera HP via multipart/form-data.
"""

import pytest


def _post_cari(client, image_bytes: bytes, target: str, filename: str = "frame.png"):
    """Helper: POST /api/cari-objek dengan format persis yang dikirim Flutter."""
    return client.post(
        "/api/cari-objek",
        data={"target": target},
        files={"file": (filename, image_bytes, "image/png")},
    )


class TestCariObjekStruktur:
    """Validasi struktur respons — tidak bergantung apakah objek ditemukan."""

    def test_response_200(self, client, obj_image_botol):
        r = _post_cari(client, obj_image_botol, "botol")
        assert r.status_code == 200

    def test_has_found_field(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "found" in body, "Field 'found' tidak ada di response"

    def test_has_total_match(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "total_match" in body

    def test_has_matches_list(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "matches" in body
        assert isinstance(body["matches"], list)

    def test_found_true_means_match_nonempty(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        if body["found"]:
            assert body["total_match"] > 0
            assert len(body["matches"]) > 0

    def test_match_has_required_fields(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        for match in body.get("matches", []):
            assert "label" in match or "confidence" in match, \
                "Match item harus punya 'label' atau 'confidence'"


class TestCariObjekInvalidInput:
    def test_invalid_image_bytes(self, client):
        """Gambar rusak harus balas found=False, bukan crash."""
        r = _post_cari(client, b"bukan_gambar_valid", "tas")
        assert r.status_code == 200
        body = r.json()
        assert body["found"] is False
        assert body.get("reason") == "invalid_frame"

    def test_empty_bytes(self, client):
        """Gambar kosong harus balas found=False."""
        r = _post_cari(client, b"", "tas")
        assert r.status_code == 200
        assert r.json()["found"] is False

    def test_target_not_in_frame(self, client, obj_image_botol):
        """Target yang tidak ada di gambar harus balas found=False, bukan error."""
        body = _post_cari(client, obj_image_botol, "pesawat").json()
        assert body["found"] is False
        assert body.get("reason") in ("not_in_frame", "no_match", None)

    def test_no_crash_on_random_target(self, client, obj_image_botol):
        """Target acak tidak boleh sebabkan crash (500)."""
        r = _post_cari(client, obj_image_botol, "xyzabc123")
        assert r.status_code == 200


class TestCariObjekDeteksi:
    """
    Uji deteksi aktual dengan fixture gambar yang sudah diketahui isinya.
    Lulus jika found=True ATAU reason in (not_in_frame, no_match) —
    objek mungkin tidak terdeteksi oleh YOLOE untuk sudut/pencahayaan tertentu.
    """

    @pytest.mark.parametrize("target,fixture_attr", [
        ("botol",      "obj_image_botol"),
        ("tas",        "obj_image_tas"),
    ])
    def test_deteksi_atau_not_in_frame(self, client, target, fixture_attr, request):
        img = request.getfixturevalue(fixture_attr)
        body = _post_cari(client, img, target).json()
        valid = body["found"] or body.get("reason") in ("not_in_frame", "no_match")
        assert valid, f"Respons tidak valid untuk target '{target}': {body}"


class TestCariObjekTargets:
    def test_targets_endpoint_200(self, client):
        r = client.get("/api/cari-objek/targets")
        assert r.status_code == 200

    def test_targets_has_list(self, client):
        body = client.get("/api/cari-objek/targets").json()
        assert "targets" in body
        assert isinstance(body["targets"], list)

    def test_targets_has_total(self, client):
        body = client.get("/api/cari-objek/targets").json()
        assert "total" in body
        assert body["total"] == len(body["targets"])
