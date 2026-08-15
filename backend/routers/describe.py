"""
Router: POST /api/describe
Menerima gambar JPEG dari Flutter, mengembalikan deskripsi suasana
dalam Bahasa Indonesia via Moondream2 → Qwen2.5-1.5B terjemahan.

Pipeline:
  Foto JPEG → Moondream2 (VLM, caption EN) → Qwen (terjemah EN→ID) → TTS Bahasa Indonesia

Qwen di sini BUKAN VLM — tidak melihat gambar sama sekali.
Tugasnya hanya: ubah kalimat Inggris pendek menjadi Bahasa Indonesia yang
enak didengar via speaker HP.
"""

from fastapi import APIRouter, File, Request, UploadFile
from loguru import logger

router = APIRouter(prefix="/api", tags=["describe"])


def _template_translate(caption_en: str) -> str:
    """Fallback sederhana jika Qwen service belum tersedia atau belum dimuat."""
    return f"Di depanmu terlihat {caption_en}."


async def _translate_to_id(request: Request, caption_en: str) -> str:
    """Terjemahkan caption Inggris Moondream ke Bahasa Indonesia via QwenService.

    Fallback ke template sederhana jika:
    - Qwen service tidak terdaftar di app.state
    - File model GGUF belum ada / belum di-download
    - Inferensi gagal karena sebab apapun
    """
    qwen = getattr(request.app.state, "qwen_service", None)
    if qwen is None:
        logger.warning("[describe] qwen_service tidak ada di app.state — template fallback")
        return _template_translate(caption_en)

    result = await qwen.translate_to_id(caption_en)
    if result:
        return result

    logger.warning("[describe] Qwen translate gagal — template fallback")
    return _template_translate(caption_en)


@router.post("/describe")
async def describe_scene(
    request: Request,
    image: UploadFile = File(..., description="Gambar JPEG/PNG dari kamera"),
):
    """
    POST /api/describe

    Menerima gambar kamera, mengembalikan deskripsi suasana Bahasa Indonesia
    yang siap dibacakan via TTS kepada pengguna tunanetra.

    Pipeline:
    1. Gambar JPEG → Moondream2 → caption Bahasa Inggris (length='short')
    2. Caption Inggris → Qwen2.5-1.5B → kalimat Bahasa Indonesia natural

    Fallback bertingkat:
    - Jika Moondream gagal/belum dimuat: pesan error informatif
    - Jika Qwen gagal/belum dimuat: template "Di depanmu terlihat [caption]."
    """
    moondream = getattr(request.app.state, "moondream_service", None)
    if moondream is None:
        return {
            "deskripsi": "Fitur deskripsi tidak tersedia. Moondream service belum dimuat.",
            "error": "moondream_service_unavailable",
        }

    image_bytes = await image.read()
    if len(image_bytes) == 0:
        return {"deskripsi": "Gambar kosong atau tidak valid.", "error": "empty_image"}

    # Inferensi Moondream2 — length='short' → ringkas dan cepat (~300ms di GPU)
    logger.info(f"[describe] Menerima gambar {len(image_bytes) // 1024} KB")
    caption_en = await moondream.describe(image_bytes, length="short")

    if not caption_en:
        return {
            "deskripsi": "Maaf, saya tidak dapat mendeskripsikan suasana saat ini.",
            "error": "moondream_inference_failed",
        }

    logger.info(f"[describe] Moondream caption: {caption_en}")

    # Terjemahkan ke Bahasa Indonesia via Qwen (bukan Claude, bukan API eksternal)
    deskripsi_id = await _translate_to_id(request, caption_en)
    logger.info(f"[describe] Deskripsi ID: {deskripsi_id}")

    return {
        "deskripsi": deskripsi_id,
        "caption_en": caption_en,  # Untuk debugging
    }
