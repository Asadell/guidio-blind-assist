import os
from fastapi import APIRouter, Request
from pydantic import BaseModel
from loguru import logger

router = APIRouter(prefix="/api", tags=["narasi"])

# System prompt khusus untuk Guidio — asisten navigasi tunanetra
SYSTEM_PROMPT = """Kamu adalah asisten navigasi bernama Guidio untuk penyandang tunanetra.

Tugasmu: ubah data deteksi objek menjadi 1-2 kalimat Bahasa Indonesia yang:
- Natural dan mudah dipahami, seperti orang yang berbicara langsung
- Menyebut posisi (kiri/depan/kanan) dan jarak dalam bahasa sehari-hari (contoh: "sekitar satu meter", "cukup dekat")
- Memberi saran keselamatan jika ada bahaya (contoh: "jalur kiri tampak lebih aman")
- Singkat — maksimal 2 kalimat pendek
- JANGAN sebut angka confidence atau istilah teknis (bounding box, sistem mendeteksi, dll)
- JANGAN sebut angka desimal (gunakan "sekitar satu meter", bukan "1.2 meter")

Jika tidak ada objek berbahaya di sekitar: sampaikan bahwa area tampak aman."""


class NarasiRequest(BaseModel):
    detections: list[dict]
    context: str = "voice"  # "voice" | "tuntun" | "navigasi"


def _template_fallback(detections: list[dict]) -> str:
    """Fallback template jika Claude API gagal — sederhana tapi tidak crash."""
    nearby = [d for d in detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return "Area sekitar tampak aman."
    parts = []
    for d in nearby[:3]:
        dist = d.get("distance_meter", 0)
        dist_str = "sangat dekat" if dist < 1 else f"sekitar {int(dist)} meter"
        parts.append(f"{d.get('label_id', d.get('label_en', 'objek'))} di {d.get('direction', 'depan')}, {dist_str}")
    return "Ada " + ", dan ".join(parts) + "."


@router.post("/narasi")
async def generate_narasi(body: NarasiRequest):
    """
    Generate kalimat natural dari hasil deteksi YOLO.
    Input: detections (teks terstruktur) — BUKAN gambar/base64.
    Model: Claude Haiku (murah, cepat, cukup untuk 1-2 kalimat).
    Fallback ke template jika Claude API gagal.
    """
    if not body.detections:
        return {"narasi": "Area sekitar tampak aman, tidak ada objek yang terdeteksi."}

    nearby = [d for d in body.detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return {"narasi": "Tidak ada rintangan dalam jangkauan 4 meter."}

    api_key = os.getenv("ANTHROPIC_API_KEY", "")
    if not api_key or api_key.startswith("sk-ant-xxxx"):
        logger.warning("ANTHROPIC_API_KEY tidak diset — pakai template fallback")
        return {"narasi": _template_fallback(nearby)}

    # Format deteksi ke teks terstruktur (input ke Claude — BUKAN gambar)
    det_lines = []
    for d in nearby[:5]:  # maks 5 objek
        det_lines.append(
            f"- {d.get('label_id', d.get('label_en', 'objek'))}, "
            f"jarak {d.get('distance_meter', 0):.1f} meter, "
            f"posisi {d.get('direction', 'depan')}, "
            f"bahaya: {d.get('danger_level', 'info')}"
        )

    user_message = (
        "Objek terdeteksi kamera saat ini:\n"
        + "\n".join(det_lines)
        + f"\n\nKonteks: mode {body.context}. Deskripsikan situasi ini untuk pengguna tunanetra."
    )

    try:
        import anthropic
        client   = anthropic.Anthropic(api_key=api_key)
        response = client.messages.create(
            model      = "claude-haiku-4-5-20251001",
            max_tokens = 150,
            system     = SYSTEM_PROMPT,
            messages   = [{"role": "user", "content": user_message}],
        )
        narasi = response.content[0].text.strip()
        logger.info(f"Claude narasi: {narasi[:60]}...")
        return {"narasi": narasi}

    except Exception as e:
        logger.error(f"Claude API gagal: {e} — pakai template fallback")
        return {"narasi": _template_fallback(nearby)}
