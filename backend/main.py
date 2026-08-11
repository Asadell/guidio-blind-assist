import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from db.database import init_db, is_available
from routers import (
    asisten,
    cari_objek,
    detect,
    narasi,
    navigasi,
    ocr,
    risk_zone,
    support,
    uang,
    voice_router,
    websocket,
)
from services.find_object_service import FindObjectService
from services.intent_service import IntentService
from services.ocr_service import OCRService
from services.risk_zone_service import RiskZoneService
from services.segmentation_service import SegmentationService
from services.uang_service import UangService
from services.yolo_service import YOLOService

load_dotenv()

STARTED_AT = time.time()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Muat semua service saat startup, bersihkan saat shutdown.

    Tidak ada satu pun kegagalan di sini yang boleh menjatuhkan server:
    tiap bagian yang mati dilaporkan apa adanya lewat /api/capabilities,
    supaya aplikasi bisa menyebut fitur mana yang hilang alih-alih gagal
    diam-diam.
    """
    logger.info("=== Menyalakan Vinara/Guidio Backend ===")

    # PostgreSQL — telemetri, crash report, antrean offline, kamus label,
    # manifest model, sesi asisten, risk zone.
    init_db()

    # Deteksi rintangan (Mode Deteksi Objek + Navigasi).
    yolo = YOLOService(
        model_path=os.getenv("YOLO_MODEL", "yolo11n.pt"),
        device=os.getenv("DEVICE", "auto"),
    )
    if not yolo.load():
        logger.error("YOLO gagal dimuat — deteksi via server tidak aktif.")
    app.state.yolo_service = yolo

    app.state.ocr_service = OCRService()
    app.state.risk_zone_service = RiskZoneService()

    # Segmentasi jalur 3 zona. Tidak adanya model BUKAN kegagalan: service
    # memakai fallback heuristik dan melaporkannya lewat field `source`.
    seg = SegmentationService()
    seg.load()
    app.state.segmentation_service = seg

    # Cari Objek — YOLOE dimuat malas saat permintaan pertama (bobotnya
    # ratusan MB, tidak pantas menahan startup untuk mode yang jarang dipakai).
    app.state.find_object_service = FindObjectService()

    # Kenali Uang di server: OPSIONAL. Jalur utama fitur ini on-device.
    uang_svc = UangService()
    uang_svc.load()
    app.state.uang_service = uang_svc

    # Katalog 20 intent perintah suara dari database.
    intent_svc = IntentService()
    if is_available():
        try:
            from services import repository as repo
            from services.find_object_service import EXTRA_ID_TO_EN

            intents = repo.get_all_intents()
            searchable = sorted(
                {r["label_local"] for r in repo.get_searchable_labels()}
                | set(EXTRA_ID_TO_EN.keys())
            )
            intent_svc.refresh(intents, searchable)
            logger.info(
                f"Katalog intent dimuat: {len(intents)} intent, "
                f"{len(searchable)} nama barang bisa dicari"
            )
        except Exception as e:
            logger.warning(f"Katalog intent gagal dimuat: {e}")
    app.state.intent_service = intent_svc

    logger.success("=== Vinara Backend siap ===")
    yield
    logger.info("Shutdown.")


app = FastAPI(
    title="Vinara / Guidio Vision API",
    version="2.0.0",
    description=(
        "Backend untuk Vinara — asisten visual suara untuk pengguna tunanetra. "
        "Dua dari enam mode (Deteksi Objek, Kenali Uang) berjalan sepenuhnya "
        "on-device dan tidak memanggil API ini sama sekali."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Fitur utama
app.include_router(websocket.router)      # /ws/detect        Deteksi Objek + Navigasi
app.include_router(detect.router)         # /api/detect       single-shot
app.include_router(ocr.router)            # /api/ocr          Baca Teks
app.include_router(narasi.router)         # /api/narasi       narasi scene
app.include_router(voice_router.router)   # /api/route-intent Asisten Suara (lama)
app.include_router(asisten.router)        # /api/intent, /api/asisten/*
app.include_router(cari_objek.router)     # /api/cari-objek
app.include_router(navigasi.router)       # /api/navigasi
app.include_router(uang.router)           # /api/uang (opsional)
app.include_router(risk_zone.router)      # /api/risk-zone

# Penunjang
app.include_router(support.router)        # capabilities, labels, models, events, crash, queue


@app.get("/health")
async def health():
    """Health check. PG-08c menyebut waktu tempuh, jadi latensi harus ikut
    dikembalikan supaya aplikasi bisa membacakannya."""
    t0 = time.perf_counter()
    yolo = getattr(app.state, "yolo_service", None)
    seg = getattr(app.state, "segmentation_service", None)
    payload = {
        "status": "ok",
        "service": "Vinara Vision API",
        "version": "2.0.0",
        "uptime_seconds": round(time.time() - STARTED_AT, 1),
        "database": is_available(),
        "yolo_loaded": bool(yolo and yolo.loaded),
        "segmentation": (seg.source if seg else "unavailable"),
    }
    payload["server_time_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return payload
