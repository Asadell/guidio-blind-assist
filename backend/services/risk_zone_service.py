import math
from datetime import datetime
from loguru import logger

# In-memory store untuk v1.
# Untuk production: ganti dengan PostgreSQL + PostGIS.
_risk_zones: dict[str, dict] = {}


class RiskZoneService:
    """
    Risk Zone: lokasi yang sering dilaporkan ada hambatan.
    Data dikumpulkan dari semua pengguna (anonim, tanpa auth).
    """

    RADIUS_METER = 30   # radius cek zona bahaya
    MIN_COUNT    = 3    # minimum laporan sebelum dianggap zona bahaya

    def __init__(self):
        logger.info("RiskZoneService init (in-memory)")

    def report(self, lat: float, lng: float, label: str) -> None:
        """
        Laporkan deteksi rintangan di koordinat ini.
        Dipanggil tiap kali ada deteksi 'critical' atau 'warning'.
        """
        zone_key = self._to_grid_key(lat, lng)
        if zone_key not in _risk_zones:
            _risk_zones[zone_key] = {
                "lat":       lat,
                "lng":       lng,
                "count":     0,
                "labels":    {},
                "last_seen": None,
            }
        zone = _risk_zones[zone_key]
        zone["count"]  += 1
        zone["labels"][label] = zone["labels"].get(label, 0) + 1
        zone["last_seen"]     = datetime.utcnow().isoformat()

    def check_nearby(self, lat: float, lng: float) -> dict | None:
        """
        Cek apakah ada zona bahaya dekat koordinat ini.
        Return None jika tidak ada, atau dict info zona jika ada.
        """
        for zone_key, zone in _risk_zones.items():
            dist = self._haversine(lat, lng, zone["lat"], zone["lng"])
            if dist <= self.RADIUS_METER and zone["count"] >= self.MIN_COUNT:
                most_common = max(zone["labels"], key=zone["labels"].get)
                return {
                    "distance_meter": round(dist, 1),
                    "count":          zone["count"],
                    "common_label":   most_common,
                    "warning":        "Area ini sering ada hambatan, hati-hati",
                }
        return None

    def _to_grid_key(self, lat: float, lng: float) -> str:
        # Grid ~30 meter per cell (4 desimal ≈ 11 meter)
        return f"{round(lat, 4)}_{round(lng, 4)}"

    def _haversine(self, lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        """Jarak dua koordinat dalam meter (Haversine formula)."""
        R  = 6_371_000
        p1 = math.radians(lat1)
        p2 = math.radians(lat2)
        dp = math.radians(lat2 - lat1)
        dl = math.radians(lng2 - lng1)
        a  = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
