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
    cari_objek,   # Cari Objek — trigger-based via backend YOLOE open-vocabulary
    describe,
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
from services.moondream_service import MoonDreamService
from services.ocr_service import OCRService
from services.qwen_service import QwenService
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
    # YOLO_NAVIGASI_MODEL → model custom 6 kelas (lubang, got_terbuka, tangga,
    # orang, motor, tiang) hasil fine-tuning balanced dataset.
    yolo = YOLOService(
        model_path=os.getenv("YOLO_MODEL", "yolo11n.pt"),
        device=os.getenv("DEVICE", "auto"),
        navigasi_model_path=os.getenv(
            "YOLO_NAVIGASI_MODEL", "models/yolo_navigasi.pt"
        ),
    )
    if not yolo.load():
        logger.error("YOLO gagal dimuat — deteksi via server tidak aktif.")
    app.state.yolo_service = yolo

    app.state.ocr_service = OCRService()
    app.state.risk_zone_service = RiskZoneService()

    # ── ON-DEVICE MOBILE NAVIGATION UPDATE ────────────────────────────────────
    # Mode Navigasi (PIDNet-S + YOLO11n) saat ini sudah berjalan 100% On-Device
    # di aplikasi Flutter Mobile (via `PidnetService` & `YoloNavigasiService` TFLite).
    # Oleh karena itu, SegmentationService ONNX di backend dinonaktifkan sementara
    # untuk menghemat CPU/VRAM server laptop.
    # ──────────────────────────────────────────────────────────────────────────
    # seg = SegmentationService(
    #     model_path=os.getenv(
    #         "SEGMENTATION_MODEL", "models/pidnet_s_3zona.onnx"
    #     ),
    #     input_size=384,   # PIDNet-S dilatih dengan H=384, W=640
    # )
    # seg.load()
    # app.state.segmentation_service = seg
    app.state.segmentation_service = None

    # Cari Objek — backend YOLOE open-vocabulary, trigger-based (bukan real-time).
    # Dipindah dari on-device ONNX 80 kelas → backend 300+ barang via text prompt.
    fo_svc = FindObjectService()
    app.state.find_object_service = fo_svc
    logger.info("[FindObject] Service terdaftar (lazy-load model YOLOE).")

    # Scene Description — Moondream2 dimuat malas saat request pertama.
    # Model ~2GB, tidak pantas menahan startup. RTX 3050 4GB VRAM cukup
    # untuk FP16 (~1.2GB efektif setelah kuantisasi runtime).
    moon_device = os.getenv("MOONDREAM_DEVICE", "auto")
    app.state.moondream_service = MoonDreamService(device=moon_device)
    logger.info("[Moondream2] Service terdaftar (lazy-load, belum dimuat).")

    # Narasi & Terjemahan — Qwen2.5-1.5B-Instruct lokal menggantikan Claude Haiku.
    # Model ~1GB GGUF Q4_K_M. Dimuat malas saat request pertama.
    # Jika file model belum ada, service tetap terdaftar tapi available=False
    # (semua caller jatuh ke template fallback — tidak crash).
    qwen_model = os.getenv(
        "QWEN_MODEL_PATH",
        "models/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    )
    qwen_gpu_layers = int(os.getenv("QWEN_GPU_LAYERS", "-1"))
    qwen_svc = QwenService(model_path=qwen_model, n_gpu_layers=qwen_gpu_layers)
    app.state.qwen_service = qwen_svc
    if qwen_svc.available:
        logger.info(f"[Qwen] Service terdaftar (lazy-load): {qwen_model}")
    else:
        logger.warning(
            f"[Qwen] File model tidak ditemukan: {qwen_model}\n"
            "       Narasi dan terjemahan akan pakai template fallback.\n"
            "       Download: huggingface-cli download Qwen/Qwen2.5-1.5B-Instruct-GGUF "
            "qwen2.5-1.5b-instruct-q4_k_m.gguf --local-dir models/"
        )

    # Kenali Uang di server: OPSIONAL. Jalur utama fitur ini on-device.
    uang_svc = UangService()
    uang_svc.load()
    app.state.uang_service = uang_svc

    # Katalog 20 intent perintah suara dari database.
    intent_svc = IntentService()
    if is_available():
        try:
            from services import repository as repo
            # EXTRA_ID_TO_EN dipindah ke Flutter — tidak diimpor lagi dari sini.
            # from services.find_object_service import EXTRA_ID_TO_EN

            intents = repo.get_all_intents()
            searchable = sorted(
                {r["label_local"] for r in repo.get_searchable_labels()}
                # | set(EXTRA_ID_TO_EN.keys())  # nonaktif bersama find_object_service
            )
            intent_svc.refresh(intents, searchable)
            # Inject QwenService ke IntentService sebagai Lapis 3 LLM.
            intent_svc.set_llm(qwen_svc)
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
app.include_router(describe.router)       # /api/describe     scene description Moondream2
app.include_router(voice_router.router)   # /api/route-intent Asisten Suara (lama)
app.include_router(asisten.router)        # /api/intent, /api/asisten/*
app.include_router(cari_objek.router)      # /api/cari-objek  — trigger-based backend YOLOE
# app.include_router(navigasi.router)     # /api/navigasi — Dinonaktifkan: Navigasi sudah 100% On-Device di HP
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
