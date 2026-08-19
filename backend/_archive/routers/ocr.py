from fastapi import APIRouter, Request
from loguru import logger

router = APIRouter(prefix="/api", tags=["ocr"])


@router.post("/ocr")
async def read_text(request: Request):
    """
    Mode Baca Teks.
    Flutter kirim raw JPEG bytes di body → server balik teks hasil OCR.
    Return: {"text": str, "lines": list[str], "confidence": float}
    """
    body   = await request.body()
    svc    = request.app.state.ocr_service
    result = svc.read_text(body)

    logger.info(
        f"OCR: {len(result.get('lines', []))} lines, "
        f"conf={result.get('confidence', 0):.2f}"
    )
    return result
