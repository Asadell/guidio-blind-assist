import cv2
import numpy as np
from fastapi import APIRouter, Request
from loguru import logger

router = APIRouter(prefix="/api", tags=["detect"])


@router.post("/detect")
async def detect_once(request: Request):
    """
    Single-shot inference untuk Voice Assistant — 'Ada apa di sekitar saya?'
    Flutter kirim raw JPEG bytes di body.
    Return: raw detections saja (narasi ada di /api/narasi).
    """
    body  = await request.body()
    arr   = np.frombuffer(body, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)

    if frame is None:
        return {"detections": [], "total": 0, "error": "Frame tidak valid"}

    svc        = request.app.state.yolo_service
    detections = svc.infer(frame)

    logger.info(f"detect_once: {len(detections)} deteksi")
    return {"detections": detections, "total": len(detections)}
