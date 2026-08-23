"""Mode Navigasi - POST /api/navigasi (segmentasi jalur 3 zona + rintangan).

Sejak deteksi rintangan dipindah dari perangkat ke server, endpoint ini
mengembalikan **keduanya dari satu frame**: status tiga zona jalur DAN daftar
rintangan di depan. Menggabungkannya di sini disengaja - aplikasi kalau tidak
harus mengunggah frame yang sama dua kali ke dua endpoint, dan itu menggandakan
pemakaian kuota serta latensi pada mode yang dipakai sambil berjalan.

Konsekuensi yang harus disadari: kalau endpoint ini tidak terjangkau, Mode
Navigasi tidak punya cadangan apa pun. Aplikasi menyuruh pengguna berhenti
berjalan, bukan melanjutkan dengan "mode terbatas".
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["navigasi"])

GRID_PRECISION = 4  # ~11 meter per sel
RISK_RADIUS_M = 30.0
RISK_MIN_COUNT = 3


@router.post("/navigasi")
async def navigasi(
    request: Request,
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    lat: float = Form(0.0),
    lng: float = Form(0.0),
):
    """Bagi frame jadi tiga zona jalur dan sebut mana yang layak dilewati.

    Kalau `lat`/`lng` diisi, sekalian cek zona rawan dari laporan pengguna
    lain (Risk Zone) - itu informasi yang tidak terlihat kamera.
    """
    raw = await file.read()
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "ok": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca.",
            "zones": None,
            "recommended": None,
        }

    svc = request.app.state.segmentation_service
    result = svc.zones(frame)

    # Rintangan dari frame yang SAMA. Prioritas suara di aplikasi menaruh
    # rintangan di atas zona - jaraknya lebih dekat dan lebih mendesak - jadi
    # keduanya harus datang bersamaan, bukan dari dua permintaan yang bisa
    # tiba dengan selisih waktu.
    yolo = getattr(request.app.state, "yolo_service", None)
    if yolo is not None and yolo.loaded:
        try:
            # Pakai model navigasi custom (6 kelas) jika sudah dilatih.
            # Fallback otomatis ke COCO jika model custom belum tersedia.
            result["obstacles"] = yolo.infer(frame, mode="navigasi")
        except Exception as e:
            logger.warning(f"Deteksi rintangan gagal: {e}")
            result["obstacles"] = []
    else:
        result["obstacles"] = []

    # Risk Zone dari laporan komunitas (opsional, butuh koordinat).
    if lat != 0.0 and lng != 0.0 and is_available():
        try:
            zone = repo.risk_zone_nearby(lat, lng, RISK_RADIUS_M, RISK_MIN_COUNT)
            if zone and zone["distance_m"] <= RISK_RADIUS_M:
                labels = zone["labels"] or {}
                common = max(labels, key=labels.get) if labels else None
                result["risk_zone"] = {
                    "distance_meter": round(float(zone["distance_m"]), 1),
                    "count": zone["report_count"],
                    "common_label": common,
                    "warning": "Area ini sering ada hambatan, hati-hati",
                }
        except Exception as e:
            logger.warning(f"Cek risk zone gagal: {e}")

    return result


@router.get("/navigasi/status")
async def navigasi_status(request: Request):
    """Apakah segmentasi jalur memakai model sungguhan atau fallback.

    Aplikasi memakai ini untuk memutuskan NV-11 (mode terbatas) dan untuk
    menyebut dengan jujur fitur mana yang sedang hilang.
    """
    svc = request.app.state.segmentation_service
    return {
        "loaded": svc.loaded,
        "source": svc.source,
        "model_path": svc.model_path,
        "input_size": svc.input_size,
        "note": (
            "Model PIDNet-S aktif."
            if svc.loaded
            else "Model belum ada - memakai fallback heuristik OpenCV. "
                 "Arahan jalur tetap keluar, tapi akurasinya di bawah model terlatih."
        ),
    }
