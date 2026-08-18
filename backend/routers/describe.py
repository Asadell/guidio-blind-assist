"""
Router: POST /api/describe
Menerima gambar JPEG dari Flutter, mengembalikan deskripsi suasana
dalam Bahasa Inggris via Moondream2.

Pipeline (TANPA LLM):
  Foto JPEG → Moondream2 (VLM, caption EN) → dikembalikan langsung ke mobile

Keputusan desain:
- Terjemahan ke Bahasa Indonesia via Qwen DIHAPUS — tidak ada LLM di backend.
- Output tetap Bahasa Inggris; mobile membacanya via TTS dengan locale 'en-US'.
- Key response: 'description_en' (bukan 'deskripsi').
"""

from fastapi import APIRouter, File, Request, UploadFile
from loguru import logger

router = APIRouter(prefix="/api", tags=["describe"])


@router.post("/describe")
async def describe_scene(
    request: Request,
    image: UploadFile = File(..., description="Gambar JPEG/PNG dari kamera"),
):
    """
    POST /api/describe

    Menerima gambar kamera, mengembalikan deskripsi suasana Bahasa Inggris
    dari Moondream2 yang siap dibacakan via TTS (locale en-US) kepada
    pengguna tunanetra.

    Pipeline:
    1. Gambar JPEG → Moondream2 → caption Bahasa Inggris (length='short')
    2. Caption dikembalikan langsung — tanpa terjemahan.

    Fallback:
    - Jika Moondream gagal/belum dimuat: pesan error informatif.
    """
    moondream = getattr(request.app.state, "moondream_service", None)
    if moondream is None:
        return {
            "description_en": "Scene description unavailable. Moondream service not loaded.",
            "error": "moondream_service_unavailable",
        }

    image_bytes = await image.read()
    if len(image_bytes) == 0:
        return {"description_en": "Image is empty or invalid.", "error": "empty_image"}

    # Inferensi Moondream2 — length='short' → ringkas dan cepat (~300ms di GPU)
    logger.info(f"[describe] Menerima gambar {len(image_bytes) // 1024} KB")
    caption_en = await moondream.describe(image_bytes, length="short")

    if not caption_en:
        return {
            "description_en": "Sorry, I could not describe the scene right now.",
            "error": "moondream_inference_failed",
        }

    logger.info(f"[describe] Moondream caption: {caption_en}")

    return {"description_en": caption_en}
