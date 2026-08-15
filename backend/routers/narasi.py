"""
Router: POST /api/narasi
Mengubah data deteksi YOLO (terstruktur) menjadi narasi Bahasa Indonesia
yang natural untuk dibacakan kepada pengguna tunanetra via TTS.

LLM yang dipakai: Qwen2.5-1.5B-Instruct lokal (bukan API eksternal).
Input ke Qwen: teks terstruktur — BUKAN gambar/base64.
"""

from fastapi import APIRouter, Request
from pydantic import BaseModel
from loguru import logger

router = APIRouter(prefix="/api", tags=["narasi"])


class NarasiRequest(BaseModel):
    detections: list[dict]
    context: str = "voice"  # "voice" | "tuntun" | "navigasi"


def _template_fallback(detections: list[dict]) -> str:
    """Fallback template jika Qwen service belum tersedia — sederhana tapi tidak crash."""
    nearby = [d for d in detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return "Area sekitar tampak aman."
    parts = []
    for d in nearby[:3]:
        dist = d.get("distance_meter", 0)
        dist_str = "sangat dekat" if dist < 1 else f"sekitar {int(dist)} meter"
        label = d.get("label_id", d.get("label_en", "objek"))
        direction = d.get("direction", "depan")
        danger = d.get("danger_level", "info")
        part = f"{label} di {direction}, {dist_str}"
        if danger in ("warning", "danger"):
            part += " — hati-hati"
        parts.append(part)
    return "Ada " + ", dan ".join(parts) + "."


def _format_detections(nearby: list[dict]) -> str:
    """Format deteksi ke teks terstruktur sebagai input Qwen."""
    lines = []
    for d in nearby[:5]:  # maks 5 objek untuk menjaga output tetap ringkas
        lines.append(
            f"- {d.get('label_id', d.get('label_en', 'objek'))}, "
            f"jarak {d.get('distance_meter', 0):.1f} meter, "
            f"posisi {d.get('direction', 'depan')}, "
            f"bahaya: {d.get('danger_level', 'info')}"
        )
    return "\n".join(lines)


@router.post("/narasi")
async def generate_narasi(body: NarasiRequest, request: Request):
    """
    Generate kalimat natural dari hasil deteksi YOLO.
    Input: detections (teks terstruktur) — BUKAN gambar/base64.
    Model: Qwen2.5-1.5B-Instruct lokal (menggantikan Claude Haiku).
    Fallback ke template jika Qwen belum dimuat atau file model tidak ada.
    """
    if not body.detections:
        return {"narasi": "Area sekitar tampak aman, tidak ada objek yang terdeteksi."}

    nearby = [d for d in body.detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return {"narasi": "Tidak ada rintangan dalam jangkauan 4 meter."}

    # Coba pakai Qwen lokal
    qwen = getattr(request.app.state, "qwen_service", None)
    if qwen is not None and qwen.available:
        det_text = _format_detections(nearby)
        try:
            narasi = await qwen.narrate_detections(det_text, context=body.context)
            if narasi:
                logger.info(f"[narasi] Qwen: {narasi[:60]}...")
                return {"narasi": narasi}
            logger.warning("[narasi] Qwen menghasilkan output kosong — fallback template")
        except Exception as e:
            logger.error(f"[narasi] Qwen gagal: {e} — fallback template")
    else:
        logger.debug("[narasi] Qwen service tidak tersedia — template fallback")

    return {"narasi": _template_fallback(nearby)}
