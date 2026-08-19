"""Risk Zone: lokasi yang sering dilaporkan ada hambatan.

Dikumpulkan anonim dari semua pengguna (tanpa auth, cukup koordinat).
Sejak versi ini datanya PERSISTEN di PostgreSQL — sebelumnya dict in-memory
yang hilang tiap server restart, jadi zona bahaya tidak pernah benar-benar
terbentuk.

Kalau database mati, service diam-diam menonaktifkan diri: fitur ini
pelengkap, dan matinya tidak boleh menjatuhkan Mode Navigasi yang deteksi
rintangannya on-device.
"""

from loguru import logger

from db.database import is_available
from services import repository as repo


class RiskZoneService:
    RADIUS_METER = 30.0  # radius cek zona bahaya
    MIN_COUNT = 3        # minimum laporan sebelum dianggap zona bahaya
    GRID_PRECISION = 4   # 4 desimal ≈ 11 meter per sel

    def __init__(self):
        logger.info(
            "RiskZoneService init (PostgreSQL)"
            if is_available()
            else "RiskZoneService init — DB mati, fitur zona rawan nonaktif"
        )

    def report(self, lat: float, lng: float, label: str) -> None:
        """Laporkan rintangan di koordinat ini. Dipanggil tiap deteksi
        'critical' atau 'warning' saat koordinat tersedia."""
        if not is_available():
            return
        try:
            repo.risk_zone_report(self._grid_key(lat, lng), lat, lng, label)
        except Exception as e:
            logger.warning(f"Gagal menyimpan laporan zona: {e}")

    def check_nearby(self, lat: float, lng: float) -> dict | None:
        """Zona bahaya di sekitar koordinat ini, atau None."""
        if not is_available():
            return None
        try:
            zone = repo.risk_zone_nearby(lat, lng, self.RADIUS_METER, self.MIN_COUNT)
            if not zone or zone["distance_m"] > self.RADIUS_METER:
                return None
            labels = zone["labels"] or {}
            common = max(labels, key=labels.get) if labels else ""
            return {
                "distance_meter": round(float(zone["distance_m"]), 1),
                "count": zone["report_count"],
                "common_label": common,
                "warning": "Area ini sering ada hambatan, hati-hati",
            }
        except Exception as e:
            logger.warning(f"Gagal cek zona rawan: {e}")
            return None

    def _grid_key(self, lat: float, lng: float) -> str:
        p = self.GRID_PRECISION
        return f"{round(lat, p)}_{round(lng, p)}"
