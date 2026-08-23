import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from db.database import init_db, is_available
from routers import (
    cari_objek,   # /api/cari-objek - YOLOE open-vocabulary
    describe,     # /api/describe   - Moondream2
    support,      # /api/capabilities
)
from services.find_object_service import FindObjectService
from services.moondream_service import MoonDreamService

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

    # PostgreSQL - risk zone + capability overrides. Tabel telemetri, crash,
    # antrean, label, dan manifest tidak lagi punya endpoint aktif; lihat
    # `_archive/routers/support_full.py`.
    init_db()

    # Cari Objek - YOLOE open-vocabulary, trigger-based (bukan real-time).
    # Satu dari dua fitur yang benar-benar butuh server: modelnya tidak ada
    # di ponsel.
    app.state.find_object_service = FindObjectService()
    logger.info("[FindObject] Service terdaftar (lazy-load model YOLOE).")

    # Scene Description - Moondream2 dimuat malas saat request pertama.
    # Model ~2GB, tidak pantas menahan startup. RTX 3050 4GB VRAM cukup
    # untuk FP16 (~1.2GB efektif setelah kuantisasi runtime).
    app.state.moondream_service = MoonDreamService(
        device=os.getenv("MOONDREAM_DEVICE", "auto")
    )
    logger.info("[Moondream2] Service terdaftar (lazy-load, belum dimuat).")

    logger.success("=== Vinara Backend siap ===")
    yield
    logger.info("Shutdown.")


app = FastAPI(
    title="Vinara / Guidio Vision API",
    version="2.0.0",
    description=(
        "Backend untuk Vinara - asisten visual suara untuk pengguna tunanetra. "
        "Empat dari enam mode (Deteksi Objek, Kenali Uang, Baca Teks, "
        "Navigasi) berjalan sepenuhnya on-device dan tidak memanggil API ini "
        "sama sekali. Yang tersisa di sini hanya yang modelnya tidak muat di "
        "ponsel: YOLOE untuk Cari Objek dan Moondream2 untuk Deskripsi Suasana."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Permukaan API: 3 router, 3 endpoint + /health ────────────────────────
#
# Router yang diarsipkan ke `_archive/routers/` beserta alasannya:
#   websocket, detect  → deteksi rintangan sudah on-device (SSD MobileNet)
#   ocr                → sudah on-device (ML Kit), dan tetap begitu
#   uang               → sudah on-device (MobileNetV2 TFLite)
#   navigasi           → sudah on-device (PIDNet-S + YOLO11n TFLite)
#   asisten, voice_router → intent parsing lokal (CommandParser), tanpa LLM
#   risk_zone          → klien tidak pernah memanggilnya
#
# Prinsipnya satu: kalau fiturnya sudah ada di ponsel, backend tidak perlu
# menyediakannya lagi. Jalur ganda hanya menambah kode yang harus dijaga
# konsisten, dan menciptakan ketergantungan diam-diam pada laptop yang
# menyala di mode yang justru menyangkut keselamatan.
app.include_router(cari_objek.router)     # /api/cari-objek   YOLOE open-vocab
app.include_router(describe.router)       # /api/describe     Moondream2 (output EN)
app.include_router(support.router)        # /api/capabilities


@app.get("/health")
async def health():
    """Health check. PG-08c menyebut waktu tempuh, jadi latensi harus ikut
    dikembalikan supaya aplikasi bisa membacakannya."""
    t0 = time.perf_counter()
    finder = getattr(app.state, "find_object_service", None)
    moondream = getattr(app.state, "moondream_service", None)
    payload = {
        "status": "ok",
        "service": "Vinara Vision API",
        "version": "3.0.0",
        "uptime_seconds": round(time.time() - STARTED_AT, 1),
        "database": is_available(),
        # Hanya dua fitur yang benar-benar dilayani server ini.
        "find_object": finder is not None,
        "describe": bool(moondream and getattr(moondream, "available", False)),
    }
    payload["server_time_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return payload
