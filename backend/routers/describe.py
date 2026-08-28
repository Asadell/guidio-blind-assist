"""
routers/describe.py  (REVISI)
=============================
POST /api/describe - Deskripsi suasana lewat Moondream2.

PERUBAHAN DARI VERSI LAMA

  1. GERBANG KUALITAS (profil longgar)
     Versi lama hanya mengecek `len(image_bytes) == 0`. File JPEG yang
     valid tapi gelap gulita tetap dikirim ke Moondream2, yang lalu
     menghasilkan halusinasi percaya diri seperti "a dimly lit room with
     furniture" dari foto yang sebenarnya hitam total.

     Ini masalah yang lebih serius daripada kelihatannya. VLM tidak
     mengatakan "saya tidak bisa melihat"; dia menghasilkan deskripsi
     yang terdengar masuk akal apa pun inputnya. Untuk pengguna tunanetra
     yang TIDAK BISA memverifikasi sendiri, deskripsi halusinasi jauh
     lebih berbahaya daripada penolakan yang jujur.

     Profilnya sengaja paling longgar di antara tiga endpoint: deskripsi
     yang agak kabur masih berguna, jadi kita hanya menolak yang
     benar-benar tidak terbaca.

     CATATAN REVISI: gelap TIDAK lagi ditolak di sini (`reject_dark=False`
     di services/image_gate.py) - fotonya diteruskan ke Moondream2. Bahaya
     halusinasi yang ditulis di atas TIDAK hilang, jadi yang menggantikan
     penolakan adalah catatannya: foto gelap turun ke POOR dan balasannya
     selalu membawa `quality_note` "Fotonya gelap, jadi hasilnya mungkin
     tidak tepat". Kalau catatan itu sampai dihapus dari narasi, penolakan
     di sini harus dihidupkan lagi.

  2. ENHANCEMENT KONSERVATIF
     Sama alasannya dengan cari_objek: Moondream2 dilatih pada foto
     natural. Yang dilakukan cuma koreksi eksposur seperlunya.

  3. CATATAN KETIDAKPASTIAN DI NARASI
     Kalau foto lolos gerbang tapi kualitasnya pas-pasan, balasan
     menyertakan catatan supaya pengguna tahu deskripsi ini berasal dari
     foto yang kurang ideal dan bisa memutuskan sendiri untuk memfoto ulang.

  4. TIMEOUT
     Moondream2 di CPU bisa memakan puluhan detik. Tanpa timeout,
     aplikasi menunggu tanpa kejelasan dan pengguna tidak tahu apakah
     sistemnya hang atau memang lambat.

  5. DETEKSI JAWABAN TIDAK BERGUNA
     Caption seperti "a photo" atau "an image" secara teknis berhasil
     tapi tidak memberi informasi apa pun. Lebih baik dikenali dan
     dibalas jujur.

CATATAN: output tetap Bahasa Inggris sesuai keputusan desain yang sudah
ada (tanpa LLM penerjemah di backend). Pesan KESALAHAN dan catatan
kualitas tetap Bahasa Indonesia, karena itu instruksi untuk pengguna,
bukan hasil model.
"""

from __future__ import annotations

import asyncio
import time

from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from services.image_gate import gate, quality_note
from utils.image_utils import enhance_for_vision, numpy_to_jpeg_bytes

router = APIRouter(prefix="/api", tags=["describe"])

DEFAULT_TIMEOUT = 25.0

# Caption yang secara teknis valid tapi tidak memberi informasi apa pun.
# Moondream2 cenderung menghasilkan ini pada input yang tidak jelas.
USELESS_CAPTIONS = {
    "a photo", "an image", "a picture", "a blurry image", "a dark image",
    "a photo of something", "an image of something", "a close up",
    "a blurry photo", "a black image", "a white image",
}


def _is_useless(caption: str) -> bool:
    c = caption.strip().lower().rstrip(".")
    if len(c) < 12:
        return True
    return c in USELESS_CAPTIONS


@router.post("/describe")
async def describe_scene(
    request: Request,
    image: UploadFile = File(..., description="Gambar JPEG/PNG dari kamera"),
    length: str = Form("short", description="short|normal"),
    enhance: bool = Form(True),
    timeout: float = Form(DEFAULT_TIMEOUT),
):
    """
    Deskripsikan suasana dari satu foto.

    Balasan:
        description_en : caption Bahasa Inggris (dibacakan TTS locale en-US)
        message        : pesan Bahasa Indonesia, HANYA saat gagal atau
                         saat ada catatan kualitas
    """
    t0 = time.perf_counter()

    moondream = getattr(request.app.state, "moondream_service", None)
    if moondream is None:
        return {
            "ok": False,
            "reason": "moondream_service_unavailable",
            "error": "moondream_service_unavailable",
            "description_en": "",
            "message": ("Layanan deskripsi suasana belum siap. "
                        "Coba lagi sebentar lagi."),
        }

    raw = await image.read()

    # ── 1. Gerbang kualitas ──
    g = gate(raw, profile="describe", endpoint="describe")
    if not g.ok:
        return g.to_error_payload({
            "description_en": "",
            "error": g.reason,
        })

    frame = g.frame
    quality = g.quality

    # ── 2. Enhancement konservatif ──
    steps: dict = {}
    if enhance:
        frame, steps = enhance_for_vision(frame, quality=quality,
                                          max_side=1024)
        image_bytes = numpy_to_jpeg_bytes(frame, quality=92)
    else:
        image_bytes = raw

    # ── 3. Pastikan model siap SEBELUM jam inferensi mulai ──
    #
    # Pemuatan model ~20 detik dan batas waktu di bawah 25 detik. Kalau
    # keduanya dihitung dalam jam yang sama, permintaan pertama sesudah server
    # menyala menghabiskan hampir seluruh anggarannya untuk menunggu bobot
    # model lalu gagal, persis seperti di log:
    #
    #     20:47:49  [describe] timeout setelah 25.0s
    #     20:47:55  [Moondream2] Model siap di cuda
    #     20:48:06  permintaan kedua berhasil dalam 2401 ms
    #
    # Sejak model dipanaskan saat startup (`main.py`), baris ini hampir selalu
    # pulang seketika. Ia tetap ada sebagai jaring: kalau permintaan datang
    # saat pemanasan belum selesai, ia MENUNGGU pemuatannya alih-alih
    # mengurangi jatah inferensi.
    await moondream.ensure_ready()

    # ── 4. Inferensi dengan timeout ──
    try:
        caption_en = await asyncio.wait_for(
            moondream.describe(image_bytes, length=length),
            timeout=timeout,
        )
    except asyncio.TimeoutError:
        logger.warning(f"[describe] timeout setelah {timeout}s")
        return {
            "ok": False,
            "reason": "timeout",
            "error": "timeout",
            "description_en": "",
            "message": ("Butuh waktu terlalu lama. "
                        "Periksa koneksi lalu coba lagi."),
            "elapsed_ms": round((time.perf_counter() - t0) * 1000, 1),
        }
    except Exception as e:
        logger.error(f"[describe] inferensi gagal: {e}")
        return {
            "ok": False,
            "reason": "moondream_inference_failed",
            "error": "moondream_inference_failed",
            "description_en": "",
            "message": "Gagal mendeskripsikan suasana. Coba lagi.",
            "elapsed_ms": round((time.perf_counter() - t0) * 1000, 1),
        }

    elapsed = (time.perf_counter() - t0) * 1000

    # ── 4. Validasi hasil ──
    if not caption_en or _is_useless(caption_en):
        logger.info(f"[describe] caption tidak berguna: '{caption_en}'")
        note = quality_note(quality)
        msg = "Suasananya tidak bisa dikenali dengan jelas."
        if note:
            msg += " " + note
        else:
            msg += " Coba arahkan kamera ke arah lain."
        return {
            "ok": True,
            "found": False,
            "reason": "deskripsi_tidak_jelas",
            # Alias lama: klien memakai `error` untuk memutuskan apakah ada
            # deskripsi yang layak dibacakan, dan di jalur ini memang tidak ada.
            "error": "deskripsi_tidak_jelas",
            "description_en": caption_en or "",
            "message": msg,
            "image_quality": quality.to_dict() if quality else None,
            "elapsed_ms": round(elapsed, 1),
        }

    note = quality_note(quality)

    logger.info(
        f"[describe] '{caption_en[:70]}' "
        f"kualitas={quality.verdict.value if quality else 'n/a'} "
        f"{elapsed:.0f}ms"
    )

    return {
        "ok": True,
        "found": True,
        "description_en": caption_en,
        # Catatan kualitas dalam Bahasa Indonesia. Aplikasi sebaiknya
        # membacakan caption dengan locale en-US, lalu catatan ini dengan
        # locale id-ID sebagai utterance terpisah.
        "quality_note": note,
        "message": note,
        "image_quality": quality.to_dict() if quality else None,
        "preprocessing": steps,
        "elapsed_ms": round(elapsed, 1),
    }
