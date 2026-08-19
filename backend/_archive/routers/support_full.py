"""Endpoint penunjang di luar enam fitur utama.

Semua endpoint di sini lahir dari state yang sudah dirancang di
IMPLEMENTASI.md, bukan dari kebiasaan umum bikin API:

  GET  /api/capabilities        mode mana yang server-nya hidup (DO-11c, BT-01/02)
  GET  /api/labels              kamus label objek Bahasa Indonesia (DO-08, DO-19)
  GET  /api/models/manifest     sinkronisasi model on-device (UG-18)
  POST /api/models/rescan       pindai ulang folder models/
  POST /api/events              telemetri alur (membuktikan target desain)
  GET  /api/events/summary      ringkasan telemetri
  POST /api/crash-report        laporan crash (ER-06)
  GET  /api/crash-report/last-mode  mode terakhir untuk dipulihkan (ER-06)
  POST /api/queue/flush         antrean unggah offline (BT-13)
  GET  /api/queue/pending       sisa antrean per perangkat
"""

import hashlib
import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, File, Form, Request, Response, UploadFile
from pydantic import BaseModel, Field

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["penunjang"])

MODELS_DIR = Path(__file__).parent.parent / "models"


def _db_guard() -> dict | None:
    """Pesan seragam saat DB mati: sebut yang masih hidup, baru yang mati."""
    if is_available():
        return None
    return {
        "ok": False,
        "reason": "database_unavailable",
        "message": (
            "Deteksi objek dan kenali uang tetap jalan karena keduanya "
            "on-device. Penyimpanan di server sedang tidak bisa dipakai."
        ),
    }


# ── Capability discovery ─────────────────────────────────────────────────


@router.get("/capabilities")
async def capabilities(request: Request):
    """Kemampuan server SEBELUM pengguna menekan tombol.

    Menentukan item mana yang `limited` / `disabled` di ModePickerSheet dan
    apakah FullScreenButton Mode Baca Teks aktif (BT-01) atau nonaktif
    dengan alasan (BT-02). Tanpa ini status hanya ketahuan setelah gagal.
    """
    state = request.app.state
    yolo_ok = getattr(state, "yolo_service", None) is not None and state.yolo_service.loaded
    ocr_ok = getattr(state, "ocr_service", None) is not None
    seg = getattr(state, "segmentation_service", None)
    finder = getattr(state, "find_object_service", None)
    qwen_svc = getattr(state, "qwen_service", None)
    llm_ok = qwen_svc is not None and qwen_svc.available

    caps = {
        # Dua mode ini sepenuhnya on-device: server mati pun tetap jalan.
        "detection": {"state": "up", "on_device": True,
                      "note": "Berjalan on-device, tidak butuh server."},
        "money": {"state": "up", "on_device": True,
                  "note": "Klasifikasi nominal on-device (TFLite), tidak pernah memanggil server."},

        # Baca Teks pindah ke ML Kit on-device — server tidak dipanggil lagi,
        # jadi ia tidak pernah 'down' dan tetap jalan penuh tanpa internet.
        "read_text": {
            "state": "up",
            "on_device": True,
            "note": "Pengenalan teks on-device (ML Kit), tidak butuh server.",
        },
        "navigation": {
            # Sejak rintangan DAN jalur sama-sama dibaca di sini, tidak ada
            # lagi cadangan on-device: kalau segmentasi mati, mode ini benar-
            # benar tidak melihat apa pun. Menandainya 'limited' akan
            # menjanjikan keselamatan yang tidak ada.
            "state": "up" if (seg and seg.loaded and yolo_ok) else "down",
            "on_device": False,
            "note": "Jalur dan rintangan terbaca." if (seg and seg.loaded and yolo_ok)
                    else "Navigasi sedang mati. Jangan berjalan mengandalkan aplikasi.",
        },
        "assistant": {
            "state": "up" if llm_ok else "limited",
            "on_device": False,
            "note": "Asisten penuh." if llm_ok
                    else "Tanpa kunci LLM: hanya perintah dasar yang dikenali.",
        },
        "find_object": {
            "state": "up" if finder is not None else "down",
            "on_device": False,
            "note": "Pencarian objek siap." if finder is not None
                    else "Cari Objek butuh internet.",
        },
    }

    # Override manual untuk demo / maintenance.
    if is_available():
        try:
            for name, ov in repo.get_capability_overrides().items():
                if name in caps and ov.get("forced_state"):
                    caps[name]["state"] = ov["forced_state"]
                    caps[name]["note"] = ov.get("reason") or caps[name]["note"]
                    caps[name]["forced"] = True
        except Exception:
            pass

    return {
        "server_time": datetime.now(timezone.utc).isoformat(),
        "database": is_available(),
        "yolo_loaded": yolo_ok,
        "capabilities": caps,
    }


# ── Kamus label ──────────────────────────────────────────────────────────


@router.get("/labels")
async def labels(lang: str = "id"):
    """Pemetaan label model → frasa Bahasa Indonesia yang layak dibacakan.

    Nama kelas mentah tidak pantas masuk TTS. Karena kamus ini di server,
    perbaikan nama tidak perlu rilis ulang aplikasi.
    """
    guard = _db_guard()
    if guard:
        return guard
    rows = repo.get_labels(lang)
    return {
        "lang": lang,
        "total": len(rows),
        "updated_at": repo.labels_updated_at(lang),
        "labels": rows,
    }


# ── Manifest model on-device ─────────────────────────────────────────────


@router.get("/models/manifest")
async def models_manifest():
    """Versi model on-device. UG-18: emisi uang baru = update model, bukan
    update aplikasi."""
    guard = _db_guard()
    if guard:
        return guard
    return {"models": repo.get_manifest()}


@router.post("/models/rescan")
async def models_rescan():
    """Pindai folder `models/`, hitung sha256, tandai mana yang tersedia."""
    guard = _db_guard()
    if guard:
        return guard

    MODELS_DIR.mkdir(exist_ok=True)
    updated = []
    for entry in repo.get_manifest():
        path = MODELS_DIR / entry["filename"]
        if not path.exists():
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        repo.update_manifest_file(
            entry["model_key"], entry["version"], entry["filename"],
            digest, path.stat().st_size, True,
        )
        updated.append(entry["model_key"])
    return {"ok": True, "updated": updated, "scanned_dir": str(MODELS_DIR)}


@router.get("/models/download/{model_key}")
async def models_download(model_key: str):
    guard = _db_guard()
    if guard:
        return guard
    entry = repo.get_manifest_entry(model_key)
    if not entry:
        return {"ok": False, "reason": "unknown_model"}
    path = MODELS_DIR / entry["filename"]
    if not path.exists():
        return {
            "ok": False,
            "reason": "file_missing",
            "message": f"File {entry['filename']} belum ada di server.",
        }
    return Response(
        content=path.read_bytes(),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{entry["filename"]}"'},
    )


# ── Telemetri alur ───────────────────────────────────────────────────────


class EventIn(BaseModel):
    event_name: str
    mode: str | None = None
    gesture_count: int | None = None
    duration_ms: int | None = None
    payload: dict = Field(default_factory=dict)
    occurred_at: datetime | None = None


class EventBatch(BaseModel):
    device_id: str
    events: list[EventIn]


@router.post("/events")
async def post_events(batch: EventBatch):
    """Telemetri alur — mengukur target desain, bukan analitik pemasaran.

    Yang dilacak: jumlah gestur per alur (target bayar < 4), waktu buka
    sampai deteksi aktif, berapa kali perintah suara tidak dikenali.
    """
    guard = _db_guard()
    if guard:
        return guard
    now = datetime.now(timezone.utc)
    for ev in batch.events:
        repo.insert_event(
            batch.device_id, ev.event_name, ev.mode, ev.gesture_count,
            ev.duration_ms, ev.payload, ev.occurred_at or now,
        )
    return {"ok": True, "accepted": len(batch.events)}


@router.get("/events/summary")
async def events_summary(hours: int = 24):
    guard = _db_guard()
    if guard:
        return guard
    return {"window_hours": hours, "summary": repo.event_summary(hours)}


# ── Crash report ─────────────────────────────────────────────────────────


class CrashIn(BaseModel):
    device_id: str
    app_version: str | None = None
    platform: str | None = None
    os_version: str | None = None
    mode: str | None = None
    error_type: str | None = None
    message: str | None = None
    stack_trace: str | None = None
    occurred_at: datetime | None = None


@router.post("/crash-report")
async def post_crash(body: CrashIn):
    """ER-06 — tombol "Kirim laporan" setelah aplikasi dibuka pasca-crash."""
    guard = _db_guard()
    if guard:
        return guard
    crash_id = repo.insert_crash(
        body.device_id, body.app_version, body.platform, body.os_version,
        body.mode, body.error_type, body.message, body.stack_trace,
        body.occurred_at,
    )
    return {"ok": True, "id": crash_id,
            "message": "Laporan terkirim. Terima kasih."}


@router.get("/crash-report/last-mode")
async def last_mode(device_id: str):
    """ER-06 — mode terakhir sebelum crash, untuk dipulihkan otomatis."""
    guard = _db_guard()
    if guard:
        return guard
    return {"device_id": device_id, "mode": repo.last_mode_for_device(device_id)}


# ── Antrean unggah offline ───────────────────────────────────────────────


@router.post("/queue/flush")
async def queue_flush(
    request: Request,
    device_id: str = Form(...),
    idempotency_key: str = Form(...),
    kind: str = Form("ocr"),
    queued_at: datetime | None = Form(None),
    file: UploadFile = File(...),
):
    """BT-13 — gambar yang gagal terkirim saat offline, dikirim ulang saat
    internet kembali.

    `idempotency_key` mencegah pemrosesan dobel: pengiriman ulang dengan
    kunci yang sama mengembalikan hasil yang sudah tersimpan, tidak
    memproses gambar dua kali.
    """
    guard = _db_guard()
    if guard:
        return guard

    existing = repo.queue_item_exists(idempotency_key)
    if existing and existing["status"] == "done":
        return {"ok": True, "duplicate": True, "result": existing["result"]}

    repo.queue_insert(idempotency_key, device_id, kind, queued_at)
    raw = await file.read()

    try:
        if kind == "ocr":
            result = request.app.state.ocr_service.read_text(raw)
        elif kind == "detect":
            import cv2
            import numpy as np

            frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                raise ValueError("Frame tidak valid")
            dets = request.app.state.yolo_service.infer(frame)
            result = {"detections": dets, "total": len(dets)}
        else:
            raise ValueError(f"kind '{kind}' tidak dikenal")

        repo.queue_mark_done(idempotency_key, result)
        return {"ok": True, "duplicate": False, "result": result}

    except Exception as e:
        repo.queue_mark_failed(idempotency_key, str(e))
        return {"ok": False, "reason": "processing_failed", "error": str(e)}


@router.get("/queue/pending")
async def queue_pending(device_id: str):
    guard = _db_guard()
    if guard:
        return guard
    return {"device_id": device_id, "pending": repo.queue_pending(device_id)}
