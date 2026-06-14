import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from loguru import logger

from services.yolo_service import YOLOService
from services.ocr_service import OCRService
from services.risk_zone_service import RiskZoneService
from routers import websocket, detect, ocr, risk_zone, narasi, voice_router

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load semua service saat startup, cleanup saat shutdown."""
    logger.info("=== Starting Guidio Backend ===")

    # Load YOLO
    svc = YOLOService(
        model_path=os.getenv("YOLO_MODEL", "yolov8m.pt"),
        device=os.getenv("DEVICE", "auto"),
    )
    if not svc.load():
        logger.error("YOLO gagal di-load! Server tetap jalan tapi deteksi tidak aktif.")
    app.state.yolo_service = svc

    # Init OCR
    app.state.ocr_service = OCRService()

    # Init Risk Zone (in-memory untuk v1)
    app.state.risk_zone_service = RiskZoneService()

    logger.success("=== Guidio Backend siap ===")
    yield
    logger.info("Shutdown.")


app = FastAPI(
    title="Guidio Vision API",
    version="1.0.0",
    description="Backend API untuk Guidio — AI Navigation Assistant untuk Tunanetra",
    lifespan=lifespan,
)

# CORS — izinkan semua origin untuk development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(websocket.router)
app.include_router(detect.router)
app.include_router(ocr.router)
app.include_router(risk_zone.router)
app.include_router(narasi.router)
app.include_router(voice_router.router)


@app.get("/health")
async def health():
    """Health check — cek apakah server dan YOLO sudah siap."""
    yolo_ok = getattr(app.state, "yolo_service", None)
    return {
        "status":    "ok",
        "service":   "Guidio Vision API",
        "yolo_loaded": yolo_ok.loaded if yolo_ok else False,
    }
