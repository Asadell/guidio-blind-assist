import asyncio
import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from routers import (
    cari_objek,   # /api/cari-objek - YOLOE open-vocabulary
    describe,     # /api/describe   - Moondream2
    support,      # /api/capabilities
)
from services.find_object_service import FindObjectService
from services.guard import GpuAdmission
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

    # Cari Objek - YOLOE open-vocabulary, trigger-based (bukan real-time).
    # Satu dari dua fitur yang benar-benar butuh server: modelnya tidak ada
    # di ponsel.
    # Satu pintu masuk GPU untuk KEDUA model. Sengaja dibagi, bukan satu
    # semaphore per model: yang terbatas adalah kartunya, bukan modelnya.
    # Dua semaphore terpisah masing-masing berisi 1 tetap membiarkan dua
    # inferensi berjalan bersamaan di VRAM yang sama.
    app.state.gpu = GpuAdmission()
    logger.info(
        f"[guard] antrean GPU: {app.state.gpu.concurrency} berjalan, "
        f"{app.state.gpu.max_queue} menunggu"
    )

    app.state.find_object_service = FindObjectService()
    logger.info("[FindObject] Service terdaftar (lazy-load model YOLOE).")

    # Scene Description - Moondream2. Model ~2GB, RTX 3050 4GB VRAM cukup
    # untuk FP16 (~1.2GB efektif setelah kuantisasi runtime).
    app.state.moondream_service = MoonDreamService(
        device=os.getenv("MOONDREAM_DEVICE", "auto")
    )

    # ── Dipanaskan di latar belakang, tidak lagi menunggu request pertama ──
    #
    # Pemuatannya makan ~20 detik, dan selama itu ditanggung permintaan
    # pertama, permintaan itu hampir pasti gagal: batas waktu endpoint 25
    # detik, jadi hampir seluruh anggarannya habis untuk menunggu bobot model.
    # Persis yang terjadi di log - permintaan pertama timeout, model siap 6
    # detik kemudian, permintaan kedua selesai dalam 2,4 detik.
    #
    # `create_task` menjaga startup tetap seketika: `/health` dan endpoint
    # lain melayani seperti biasa selama bobotnya dibaca. Yang berubah cuma
    # satu - saat foto pertama datang, model sudah menunggu.
    #
    # Kegagalan pemanasan bukan alasan menggagalkan startup: `describe` tetap
    # mencoba memuat sendiri, dan lima mode lain tidak menyentuh model ini
    # sama sekali.
    warmup = asyncio.create_task(app.state.moondream_service.warm_up())
    logger.info("[Moondream2] Service terdaftar, pemanasan berjalan.")

    logger.success("=== Vinara Backend siap ===")
    yield
    logger.info("Shutdown.")
    # Server yang dimatikan saat pemanasan belum selesai tidak boleh
    # meninggalkan task menggantung.
    warmup.cancel()


app = FastAPI(
    title="Vinara / Guidio Vision API",
    version="3.0.0",
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
# Router yang dulu ada di sini sudah dihapus, bukan dipindah, beserta
# alasannya:
#   websocket, detect     → deteksi rintangan sudah on-device (SSD MobileNet)
#   ocr                   → sudah on-device (ML Kit), dan tetap begitu
#   uang                  → sudah on-device (MobileNetV2 TFLite)
#   navigasi              → sudah on-device (PIDNet-S + YOLO11n TFLite)
#   asisten, voice_router → intent parsing lokal (CommandParser), tanpa LLM
#   risk_zone             → klien tidak pernah memanggilnya
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
        # Hanya dua fitur yang benar-benar dilayani server ini.
        "find_object": finder is not None,
        "describe": bool(moondream and getattr(moondream, "available", False)),
    }
    gpu = getattr(app.state, "gpu", None)
    if gpu is not None:
        payload["gpu_queue"] = gpu.stats()
    payload["server_time_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return payload
