"""Mode Cari Objek — POST /api/cari-objek

Trigger-based: dipanggil sekali per perintah suara, bukan stream. Aplikasi
memanggil ulang tiap kali pengguna memutar badan (CO-05 / CO-10), jadi
endpoint ini harus cepat dan tidak menyimpan state di server.
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["cari-objek"])


@router.get("/cari-objek/targets")
async def searchable_targets():
    """Daftar barang yang dikenali sistem — CO-12 (objek tak dikenali)
    memakai ini untuk menawarkan barang lain yang memang bisa dicari."""
    from services.find_object_service import EXTRA_ID_TO_EN

    db_labels = repo.get_searchable_labels() if is_available() else []
    targets = sorted(
        {row["label_local"] for row in db_labels} | set(EXTRA_ID_TO_EN.keys())
    )
    return {"total": len(targets), "targets": targets}


@router.post("/cari-objek")
async def cari_objek(
    request: Request,
    target: str = Form(..., description="Nama barang Bahasa Indonesia, mis. 'dompet'"),
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    conf: float | None = Form(None),
):
    """Cari satu jenis barang di satu frame.

    Balasan `found=False` dengan reason `not_in_frame` BUKAN error — itu
    kondisi normal CO-10 yang membuat aplikasi menyuruh pengguna memutar
    badan lalu memanggil endpoint ini lagi.
    """
    raw = await file.read()
    if not raw:
        return {
            "found": False,
            "reason": "invalid_frame",
            "message": "Gambar kosong. Coba ambil ulang.",
            "matches": [],
            "total_match": 0,
        }
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "found": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca. Coba ambil ulang.",
            "matches": [],
            "total_match": 0,
        }

    svc = request.app.state.find_object_service

    # Terjemahkan target Bahasa Indonesia → prompt Inggris untuk YOLOE.
    label_map: dict[str, str] = {}
    if is_available():
        try:
            label_map = {
                row["label_local"]: row["label_en"]
                for row in repo.get_searchable_labels()
            }
        except Exception as e:
            logger.warning(f"Kamus label tidak terbaca: {e}")

    prompt_en = svc.resolve_prompt(target, label_map)
    result = svc.find(frame, prompt_en, target.strip().lower(), conf=conf)

    logger.info(
        f"cari-objek target='{target}' prompt='{prompt_en}' "
        f"found={result['found']} n={result['total_match']}"
    )
    return result
