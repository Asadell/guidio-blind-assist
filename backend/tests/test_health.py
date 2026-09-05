"""
test_health.py - Tes endpoint /health dan /api/capabilities.

Grup A dari VERIFIKASI_FITUR.md, versi pytest otomatis.
Tidak membutuhkan model hidup - semua dicek strukturnya saja.
"""


class TestHealth:
    def test_status_ok(self, client):
        """GET /health harus balas status='ok'."""
        r = client.get("/health")
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "ok"

    def test_fields_present(self, client):
        """Health response harus punya semua field yang dipakai Flutter."""
        r = client.get("/health")
        body = r.json()
        for field in ("status", "service", "version", "uptime_seconds",
                      "find_object", "describe", "server_time_ms"):
            assert field in body, f"Field '{field}' tidak ada di /health"

    def test_no_database_field(self, client):
        """Backend sudah stateless - `/health` tidak boleh melaporkan DB lagi.

        Field `database` dulu selalu ada di sini. Membiarkannya (walau isinya
        `false`) membuat klien menyimpulkan ada database yang sedang mati,
        padahal tidak ada database yang perlu hidup sama sekali.
        """
        body = client.get("/health").json()
        assert "database" not in body

    def test_uptime_positive(self, client):
        """Uptime harus bilangan positif."""
        r = client.get("/health")
        assert r.json()["uptime_seconds"] >= 0

    def test_server_time_ms_fast(self, client):
        """Health check harus selesai < 500 ms (server_time_ms)."""
        r = client.get("/health")
        assert r.json()["server_time_ms"] < 500

    def test_no_qwen_reference(self, client):
        """Respons tidak boleh menyebut Qwen (sudah dihapus dari stack)."""
        r = client.get("/health")
        assert "qwen" not in r.text.lower()


class TestCapabilities:
    def test_status_200(self, client):
        """GET /api/capabilities harus balas 200."""
        r = client.get("/api/capabilities")
        assert r.status_code == 200

    def test_has_capabilities_key(self, client):
        """Response harus punya key 'capabilities'."""
        body = client.get("/api/capabilities").json()
        assert "capabilities" in body

    def test_six_modes_present(self, client):
        """Semua 6 mode harus ada di capabilities."""
        caps = client.get("/api/capabilities").json()["capabilities"]
        for mode in ("detection", "money", "read_text", "navigation",
                     "assistant", "find_object"):
            assert mode in caps, f"Mode '{mode}' tidak ada di capabilities"

    def test_on_device_modes_always_up(self, client):
        """4 mode on-device harus selalu 'up' - tidak bergantung server."""
        caps = client.get("/api/capabilities").json()["capabilities"]
        for mode in ("detection", "money", "read_text", "navigation"):
            assert caps[mode]["state"] == "up", \
                f"Mode on-device '{mode}' seharusnya 'up', dapat '{caps[mode]['state']}'"
            assert caps[mode]["on_device"] is True

    def test_no_ws_detect_reference(self, client):
        """Tidak boleh ada referensi /ws/detect (endpoint sudah dihapus)."""
        r = client.get("/api/capabilities")
        assert "/ws/detect" not in r.text

    def test_has_server_time(self, client):
        """Response harus punya server_time (ISO 8601)."""
        body = client.get("/api/capabilities").json()
        assert "server_time" in body
        # Cek format ISO 8601 kasar
        assert "T" in body["server_time"]


# ═══════════════════════════════════════════════════════════════════════════
#  Regresi: /api/capabilities pernah selalu melaporkan Deskripsi Suasana
#  setengah mati
#
#  `routers/support.py` dan `/health` membaca kesiapan Moondream lewat
#  `getattr(moondream, "available", False)`, padahal `MoonDreamService` tidak
#  pernah punya properti `available`. `getattr` menelan itu tanpa suara dan
#  menghasilkan False selamanya, jadi mode Deskripsi Suasana selalu tampil
#  `limited` dengan catatan "deskripsi suasana butuh server" - di server yang
#  justru sedang terhubung dan sanggup melayaninya.
#
#  Tes ini mengunci dua hal sekaligus: propertinya ada, dan artinya benar.
# ═══════════════════════════════════════════════════════════════════════════

def test_moondream_punya_properti_available():
    """`available` WAJIB ada. Tanpa ini `getattr` diam-diam jatuh ke False."""
    from services.moondream_service import MoonDreamService

    assert hasattr(MoonDreamService, "available"), (
        "MoonDreamService.available hilang - /api/capabilities akan kembali "
        "melaporkan Deskripsi Suasana limited selamanya."
    )


def test_moondream_available_sebelum_dimuat():
    """Lazy-load bukan alasan melaporkan diri setengah mati.

    Bobotnya ~2 GB dan sengaja baru dimuat saat permintaan pertama. Server
    yang belum pernah dipakai tetap sanggup melayani, jadi jawabannya True.
    """
    from services.moondream_service import MoonDreamService

    m = MoonDreamService()
    assert m.loaded is False
    assert m.available is True


def test_moondream_available_false_setelah_gagal_muat():
    """Yang membuatnya False cuma percobaan muat yang sudah pernah gagal."""
    from services.moondream_service import MoonDreamService

    m = MoonDreamService()
    m._load_failed = True
    assert m.available is False
