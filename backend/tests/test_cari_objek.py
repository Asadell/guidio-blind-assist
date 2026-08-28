"""
test_cari_objek.py - Tes endpoint POST /api/cari-objek.

Mensimulasikan Flutter mengirim frame kamera saat user berkata "cari dompet".
Semua gambar diambil dari guidio_app/test/fixtures/object_find/ -
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
    """Validasi struktur respons - tidak bergantung apakah objek ditemukan."""

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
        assert body.get("reason") == "gambar_rusak"

    def test_empty_bytes(self, client):
        """Gambar kosong harus balas found=False."""
        r = _post_cari(client, b"", "tas")
        assert r.status_code == 200
        body = r.json()
        assert body["found"] is False
        assert body.get("reason") == "gambar_kosong"

    def test_gagal_gambar_menyarankan_ulang(self, client):
        """Kegagalan kualitas gambar harus BEDA dari 'tidak ada di frame'.

        Pembedaan ini yang membuat aplikasi tahu kapan menyuruh pengguna
        memutar badan (CO-10) dan kapan menyuruh memperbaiki kondisi foto.
        Tanpa itu keduanya terdengar sama dan tindakan penggunanya salah.
        """
        body = _post_cari(client, b"bukan_gambar_valid", "tas").json()
        assert body.get("retry_suggested") is True
        assert body.get("message"), "Pesan untuk TTS tidak boleh kosong"

    def test_target_not_in_frame(self, client, obj_image_botol):
        """Target yang tidak ada di gambar harus balas found=False, bukan error."""
        body = _post_cari(client, obj_image_botol, "pesawat").json()
        assert body["found"] is False
        assert body.get("reason") in (
            "not_in_frame", "no_match", "agak_buram", "sangat_buram", None
        )

    def test_no_crash_on_random_target(self, client, obj_image_botol):
        """Target acak tidak boleh sebabkan crash (500)."""
        r = _post_cari(client, obj_image_botol, "xyzabc123")
        assert r.status_code == 200


class TestCariObjekDeteksi:
    """
    Uji deteksi aktual dengan fixture gambar yang sudah diketahui isinya.
    Lulus jika found=True ATAU reason in (not_in_frame, no_match) -
    objek mungkin tidak terdeteksi oleh YOLOE untuk sudut/pencahayaan tertentu.
    """

    @pytest.mark.parametrize("target,fixture_attr", [
        ("botol",      "obj_image_botol"),
        ("tas",        "obj_image_tas"),
    ])
    def test_deteksi_atau_not_in_frame(self, client, target, fixture_attr, request):
        img = request.getfixturevalue(fixture_attr)
        body = _post_cari(client, img, target).json()
        valid = body["found"] or body.get("reason") in (
            "not_in_frame", "no_match", "agak_buram", "sangat_buram",
        )
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


# ═══════════════════════════════════════════════════════════════════════════════
#  Prompt Inggris dari aplikasi (ML Kit on-device)
# ═══════════════════════════════════════════════════════════════════════════════

class TestPromptEnPembersih:
    """`_clean_prompt_en` adalah gerbang terakhir sebelum `set_classes()`.

    Nilainya datang dari klien, jadi server tidak boleh bergantung pada versi
    aplikasi tertentu untuk kebersihannya sendiri.
    """

    def test_frasa_benda_diteruskan(self):
        from routers.cari_objek import _clean_prompt_en
        assert _clean_prompt_en("red bag") == "red bag"

    def test_kata_perintah_dibuang_bukan_seluruh_prompt_ditolak(self):
        # Aplikasi versi lama bisa mengirim kalimat utuh. Membuang kata
        # perintahnya menyelamatkan promptnya; menolak seluruhnya membuang
        # terjemahan yang sebenarnya masih berguna.
        from routers.cari_objek import _clean_prompt_en
        assert _clean_prompt_en("please find my red bag") == "red bag"

    def test_prompt_tanpa_benda_jadi_none(self):
        from routers.cari_objek import _clean_prompt_en
        assert _clean_prompt_en("find the thing") is None
        assert _clean_prompt_en("   ") is None
        assert _clean_prompt_en(None) is None

    def test_panjang_dibatasi(self):
        from routers.cari_objek import _clean_prompt_en, _MAX_PROMPT_WORDS
        out = _clean_prompt_en("small blue plastic drinking water bottle")
        assert len(out.split(" ")) <= _MAX_PROMPT_WORDS


class TestResolvePromptDenganMlKit:
    """Urutan lapisannya yang diuji, bukan kualitas terjemahannya."""

    def _svc(self):
        from services.find_object_service import FindObjectService
        return FindObjectService()

    def test_kamus_kurasi_menang_atas_ml_kit(self):
        # "hape" ada di kamus dan dipetakan ke nama kelas yang dikenal encoder
        # teks YOLOE. Terjemahan umum "cellphone" tidak salah secara bahasa,
        # tapi lebih jauh dari kosakata modelnya.
        svc = self._svc()
        assert svc.resolve_prompt(
            "hape", {}, client_prompt_en="cellphone"
        ) == "cell phone"

    def test_ml_kit_menutup_kata_di_luar_kamus(self):
        # Tanpa ML Kit, "irus" dikirim apa adanya ke encoder teks berbahasa
        # Inggris - pencarian yang tidak pernah punya peluang.
        svc = self._svc()
        assert svc.resolve_prompt("irus", {}) == "irus"
        assert svc.resolve_prompt(
            "irus", {}, client_prompt_en="ladle"
        ) == "ladle"

    def test_warna_tidak_digandakan(self):
        # Aplikasi menerjemahkan frasa UTUH, jadi warnanya sudah ikut. Kalau
        # server menyambungkan warnanya lagi, hasilnya "red red bag".
        svc = self._svc()
        out = svc.resolve_prompt("irus merah", {}, client_prompt_en="red ladle")
        assert out == "red ladle"

    def test_tanpa_ml_kit_perilaku_lama_tidak_berubah(self):
        svc = self._svc()
        assert svc.resolve_prompt("dompet", {}, client_prompt_en=None) == "wallet"
        assert svc.resolve_prompt("tas merah", {}) == "red bag"


class TestPromptEnEndpoint:
    def test_endpoint_menerima_prompt_en(self, client, obj_image_tas):
        r = client.post(
            "/api/cari-objek",
            files={"file": ("frame.png", obj_image_tas, "image/png")},
            data={"target": "tas merah", "prompt_en": "red bag"},
        )
        assert r.status_code == 200
        assert r.json()["ok"] is True

    def test_prompt_en_opsional(self, client, obj_image_tas):
        # Aplikasi versi lama tidak mengirimnya sama sekali.
        r = client.post(
            "/api/cari-objek",
            files={"file": ("frame.png", obj_image_tas, "image/png")},
            data={"target": "tas merah"},
        )
        assert r.status_code == 200
        assert r.json()["ok"] is True

    def test_target_tetap_bahasa_indonesia_di_balasan(self, client, obj_image_tas):
        # `target` yang dibacakan TTS harus tetap Bahasa Indonesia walau
        # promptnya Inggris - kalau tertukar, aplikasi bicara dua bahasa
        # dalam satu kalimat.
        r = client.post(
            "/api/cari-objek",
            files={"file": ("frame.png", obj_image_tas, "image/png")},
            data={"target": "tas merah", "prompt_en": "red bag"},
        )
        assert r.json()["target"] == "tas merah"
