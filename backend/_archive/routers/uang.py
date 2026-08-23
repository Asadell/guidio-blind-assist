"""Mode Kenali Uang - endpoint server OPSIONAL.

Jalur utama fitur ini ada di perangkat (.tflite MobileNetV2, 6 kelas emisi
2016) dan TIDAK pernah memanggil endpoint ini. Yang di sini hanya cadangan
untuk pembanding akurasi dan pengujian dari alat lain (curl/Postman).

Kalau model server belum ada, balasannya jujur `model_unavailable` - tidak
pernah menebak nominal.
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["uang"])


@router.get("/uang/denominations")
async def denominations():
    """Denominasi yang didukung + kata terbilangnya.

    `class_index` adalah urutan kelas pada model on-device. Nilai dengan
    `active=false` (mis. Rp1.000) tidak dikenali model dan aplikasi harus
    menyebut keterbatasan itu, bukan menebak.
    """
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "denominations": []}
    rows = repo.get_denominations()
    return {
        "total": len(rows),
        "note": "Klasifikasi berjalan on-device. Daftar ini hanya rujukan kata dan urutan kelas.",
        "denominations": rows,
    }


@router.post("/uang")
async def kenali_uang(request: Request, file: UploadFile = File(...)):
    raw = await file.read()
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "detected": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca. Coba ambil ulang.",
        }

    words_map: dict[int, str] = {}
    if is_available():
        try:
            words_map = {r["value_idr"]: r["words"] for r in repo.get_denominations()}
        except Exception as e:
            logger.warning(f"Kata terbilang tidak terbaca: {e}")

    result = request.app.state.uang_service.predict(frame, words_map)
    logger.info(f"uang: detected={result.get('detected')} reason={result.get('reason', '-')}")
    return result
