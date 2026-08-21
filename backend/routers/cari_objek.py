"""
routers/cari_objek.py  (REVISI)
===============================
POST /api/cari-objek - Cari satu jenis barang di satu frame (YOLOE).

PERUBAHAN DARI VERSI LAMA

  1. GERBANG KUALITAS SEBELUM INFERENSI
     Versi lama cuma mengecek `frame is None`. Frame yang berhasil
     di-decode tapi gelap gulita atau buram parah tetap dikirim ke YOLOE,
     yang lalu mengembalikan `found=False`. Dari sisi pengguna, hasilnya
     terdengar sama persis dengan "barangnya memang tidak ada di sini",
     padahal masalahnya beda total dan tindakan yang tepat juga beda:
       - "tidak ada di frame"  -> putar badan, coba lagi
       - "foto terlalu gelap"  -> nyalakan lampu / cari tempat terang
     Sekarang keduanya dibedakan dengan `reason` dan pesan yang berbeda.

  2. ENHANCEMENT KONSERVATIF
     Hanya koreksi eksposur (CLAHE) kalau gambarnya memang bermasalah.
     TIDAK ada sharpening agresif. YOLOE dilatih pada foto natural;
     unsharp masking menciptakan halo dan menguatkan noise, yang
     menggeser distribusi input menjauh dari data training. Itu
     menurunkan akurasi, bukan menaikkan.

  3. PENALTI CONFIDENCE BERBASIS KUALITAS
     Deteksi dari foto berkualitas rendah dikalikan faktor penalti.
     Tujuannya bukan menyembunyikan hasil, tapi supaya ambang keputusan
     di sisi aplikasi tidak memperlakukan tebakan dari foto jelek sama
     yakinnya dengan deteksi dari foto bagus.

  4. PERINGATAN PENCAHAYAAN YANG ACTIONABLE
     Pesan seperti "gambar buram" tidak berguna bagi pengguna tunanetra.
     Yang berguna: "tahan ponsel lebih diam sebentar".

  5. KAMUS LABEL DI-CACHE
     Versi lama memanggil `repo.get_searchable_labels()` pada SETIAP
     request. Untuk endpoint yang dipanggil berulang kali saat pengguna
     memutar badan (alur CO-05/CO-10), itu query database berulang untuk
     data yang praktis tidak pernah berubah.
"""

from __future__ import annotations

import time

from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo
from services.image_gate import gate, quality_note
from utils.image_utils import enhance_for_vision

router = APIRouter(prefix="/api", tags=["cari-objek"])


# ═══════════════════════════════════════════════════════════════════════════════
#  Cache kamus label
# ═══════════════════════════════════════════════════════════════════════════════

_LABEL_CACHE: dict = {"data": None, "ts": 0.0}
_LABEL_TTL = 300.0  # detik


def _get_label_map() -> dict[str, str]:
    """
    Ambil kamus label Indonesia -> Inggris, dengan cache 5 menit.

    Kamus ini praktis statis. Memanggil database tiap request menambah
    latency pada endpoint yang dipanggil berulang kali dalam satu sesi
    pencarian, dan menciptakan kegagalan yang tidak perlu kalau database
    sedang lambat.
    """
    now = time.time()
    if (_LABEL_CACHE["data"] is not None
            and now - _LABEL_CACHE["ts"] < _LABEL_TTL):
        return _LABEL_CACHE["data"]

    label_map: dict[str, str] = {}
    if is_available():
        try:
            label_map = {
                row["label_local"]: row["label_en"]
                for row in repo.get_searchable_labels()
            }
        except Exception as e:
            logger.warning(f"[cari-objek] kamus label tidak terbaca: {e}")
            # Kalau ada cache lama, lebih baik pakai itu daripada kosong
            if _LABEL_CACHE["data"] is not None:
                return _LABEL_CACHE["data"]

    _LABEL_CACHE["data"] = label_map
    _LABEL_CACHE["ts"] = now
    return label_map


def invalidate_label_cache() -> None:
    """Panggil ini kalau kamus label diubah lewat jalur admin."""
    _LABEL_CACHE["data"] = None
    _LABEL_CACHE["ts"] = 0.0


# ═══════════════════════════════════════════════════════════════════════════════
#  Endpoint
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/cari-objek/targets")
async def searchable_targets():
    """
    Daftar barang yang dikenali sistem.

    Dipakai alur CO-12 (objek tak dikenali) untuk menawarkan barang lain
    yang memang bisa dicari.
    """
    from services.find_object_service import EXTRA_ID_TO_EN

    label_map = _get_label_map()
    targets = sorted(set(label_map.keys()) | set(EXTRA_ID_TO_EN.keys()))
    return {"total": len(targets), "targets": targets}


@router.post("/cari-objek")
async def cari_objek(
    request: Request,
    target: str = Form(..., description="Nama barang, mis. 'dompet'"),
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    conf: float | None = Form(None),
    enhance: bool = Form(True, description="Koreksi eksposur otomatis"),
):
    """
    Cari satu jenis barang di satu frame.

    PENTING soal semantik balasan:
    `found=False` dengan `reason='not_in_frame'` BUKAN error. Itu kondisi
    normal CO-10 yang membuat aplikasi menyuruh pengguna memutar badan
    lalu memanggil endpoint ini lagi.

    Yang BERBEDA dan baru dibedakan di versi ini adalah `reason` yang
    menunjukkan masalah kualitas gambar. Aplikasi harus memperlakukan
    keduanya berbeda: kalau `retry_suggested=True`, jangan suruh pengguna
    memutar badan, tapi perbaiki kondisi pengambilan gambar dulu.
    """
    t0 = time.perf_counter()
    raw = await file.read()

    # ── 1. Gerbang kualitas ──
    g = gate(raw, profile="find_object", endpoint="cari-objek")
    if not g.ok:
        return g.to_error_payload({
            "found": False,
            "matches": [],
            "total_match": 0,
            "target": target,
        })

    frame = g.frame
    quality = g.quality

    # ── 2. Enhancement konservatif ──
    steps: dict = {}
    if enhance:
        frame, steps = enhance_for_vision(frame, quality=quality,
                                          max_side=1280)

    # ── 3. Inferensi ──
    svc = request.app.state.find_object_service
    prompt_en = svc.resolve_prompt(target, _get_label_map())
    result = svc.find(frame, prompt_en, target.strip().lower(), conf=conf)

    # ── 4. Penalti confidence berbasis kualitas ──
    #
    # Deteksi dari foto jelek TIDAK sama andalnya dengan deteksi dari foto
    # bagus, walau angka confidence mentahnya sama. Faktor penalti membuat
    # ketidakpastian itu terlihat, bukan tersembunyi.
    penalty = quality.confidence_penalty if quality else 1.0
    if penalty < 1.0 and result.get("matches"):
        for m in result["matches"]:
            if "confidence" in m:
                m["confidence_raw"] = m["confidence"]
                m["confidence"] = round(m["confidence"] * penalty, 4)
        result["confidence_penalty"] = round(penalty, 3)

    # ── 5. Catatan kualitas untuk narasi ──
    note = quality_note(quality)
    if note:
        result["quality_note"] = note
        # Sisipkan ke pesan yang akan dibacakan, supaya pengguna tahu
        # hasilnya berasal dari foto yang kurang ideal.
        if not result.get("found") and result.get("message"):
            result["message"] = f"{result['message']} {note}"

    result["ok"] = True
    result["target"] = target
    result["image_quality"] = quality.to_dict() if quality else None
    result["preprocessing"] = steps
    result["elapsed_ms"] = round((time.perf_counter() - t0) * 1000, 1)

    logger.info(
        f"[cari-objek] target='{target}' prompt='{prompt_en}' "
        f"found={result.get('found')} n={result.get('total_match')} "
        f"kualitas={quality.verdict.value if quality else 'n/a'} "
        f"{result['elapsed_ms']:.0f}ms"
    )
    return result
