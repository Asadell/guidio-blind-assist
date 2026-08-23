import cv2
import numpy as np
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from loguru import logger

from services.camera_health import check_camera_health

router = APIRouter()


@router.websocket("/ws/detect")
async def ws_detect(ws: WebSocket):
    """
    Mode Tuntun + Mode Navigasi (obstacle detection).
    Flutter kirim JPEG binary → server balas raw JSON detections.
    Filter pipeline ada di Flutter, BUKAN di sini.

    Query params:
      lat, lng - koordinat GPS user (opsional, untuk Risk Zone)
    """
    await ws.accept()

    svc      = ws.app.state.yolo_service
    rz_svc   = ws.app.state.risk_zone_service

    # Koordinat dari query param (0,0 = tidak aktif / tidak diberi)
    lat = float(ws.query_params.get("lat", 0))
    lng = float(ws.query_params.get("lng", 0))

    frame_count = 0
    logger.info(f"WebSocket connected. lat={lat}, lng={lng}")

    try:
        while True:
            data        = await ws.receive_bytes()
            frame_count += 1

            arr   = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)

            if frame is None:
                await ws.send_json({"type": "error", "msg": "Frame tidak valid"})
                continue

            # Camera health check di server-side
            health = check_camera_health(frame)
            if not health["ok"]:
                await ws.send_json({
                    "type": "camera_error",
                    "msg":  health["message"],
                })
                continue

            # Server-side sample rate: YOLO tiap 3 frame
            if frame_count % 3 != 0:
                continue

            detections = svc.infer(frame)

            # Auto-report ke risk zone jika ada koordinat valid + deteksi bahaya
            risk_warning = None
            if lat != 0 and lng != 0:
                for det in detections:
                    if det["danger_level"] in ("critical", "warning"):
                        rz_svc.report(lat, lng, det["label_en"])
                risk_warning = rz_svc.check_nearby(lat, lng)

            await ws.send_json({
                "type":       "detections",
                "frame_id":   frame_count,
                "detections": detections,   # raw, tanpa filter - filter di Flutter
                "risk_zone":  risk_warning, # None atau dict warning
            })

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await ws.close()
        except Exception:
            pass
