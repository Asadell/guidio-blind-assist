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

     CATATAN REVISI: gerbang kualitas di sini SUDAH TIDAK MENOLAK APA PUN
     (`reject_quality=False` di services/image_gate.py). Buram, gelap,
     silau, resolusi kecil - semuanya diteruskan ke Moondream2. Yang masih
     menolak cuma unggahan yang bukan gambar dan dua batas sumber daya.

     Bahaya halusinasi yang ditulis di atas TIDAK hilang, jadi yang
     menggantikan penolakan adalah catatannya: foto bermasalah tetap turun
     ke POOR dan balasannya membawa `quality_note` ("Fotonya gelap, jadi
     hasilnya mungkin tidak tepat"). Kalau catatan itu sampai dihapus dari
     narasi, gerbangnya harus dihidupkan lagi.

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

from services.guard import GpuBusy
from services.image_gate import gate, quality_note
from utils.image_utils import enhance_for_vision, numpy_to_jpeg_bytes

router = APIRouter(prefix="/api", tags=["describe"])

DEFAULT_TIMEOUT = 25.0

# Batas ATAS untuk `timeout` yang dikirim klien.
#
# `timeout` adalah field form, jadi nilainya datang dari luar dan tidak boleh
# dipercaya. Tanpa batas ini, satu permintaan berisi `timeout=86400` menahan
# satu slot GPU selama sehari penuh, dan hanya butuh beberapa permintaan
# seperti itu untuk membuat kartu tidak pernah bisa dipakai siapa pun lagi.
# Tidak diperlukan berkas jahat maupun banjir permintaan - cukup satu angka.
MAX_TIMEOUT = 60.0
MIN_TIMEOUT = 1.0

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
    # Bawaan "normal", bukan "short".
    #
    # `short` menghasilkan caption gaya alt-text satu baris, dan pada foto
    # yang ramai ia berhenti di tengah kalimat - dari log:
    #
    #     'A modern office features a blue water bottle, a laptop displaying code'
    #
    # Kalimat itu bukan dipotong aplikasi maupun bank kata; itu memang seluruh
    # keluaran model pada panjang `short`. Untuk pengguna tunanetra, deskripsi
    # yang berhenti di tengah adalah kegagalan yang paling menyesatkan: ia
    # terdengar seperti jawaban lengkap, jadi tidak ada alasan untuk bertanya
    # lagi, padahal separuh isinya tidak pernah disebut.
    #
    # `normal` menambah beberapa ratus milidetik inferensi dan itu murah
    # dibayar sekali per tekanan tombol.
    length: str = Form("normal", description="short|normal"),
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

    # ── 1. Gerbang: batas sumber daya saja, bukan penilaian kualitas ──
    #
    # Profil "describe" dipasang `reject_quality: False`, jadi foto buram,
    # gelap, silau, atau kecil TETAP diteruskan ke Moondream2. Yang tersisa
    # sebagai penolakan cuma dua batas yang menjaga server tetap hidup:
    # unggahan raksasa dan kanvas bom-dekode. Rinciannya di
    # `services/image_gate.py`.
    #
    # `gambar_rusak` dan `gambar_kosong` juga masih menolak, dan itu BUKAN
    # pengecualian dari aturan di atas: byte yang tidak bisa didekode sama
    # sekali bukan foto berkualitas rendah, melainkan unggahan yang gagal.
    # PIL di dalam Moondream2 akan gagal membukanya juga, jadi meneruskannya
    # cuma menukar penolakan yang cepat dan jujur dengan penolakan yang sama
    # beberapa detik kemudian - sesudah membangunkan VLM untuk apa-apa.
    g = gate(raw, profile="describe", endpoint="describe")
    if not g.ok:
        return g.to_error_payload({
            "description_en": "",
            "error": g.reason,
        })

    frame = g.frame
    quality = g.quality

    # ── 2. Enhancement konservatif ──
    #
    # Bukan penyaring, melainkan pemercepat: `enhance_for_vision` mengecilkan
    # sisi terpanjang ke 1024 dan hanya mengoreksi eksposur kalau memang
    # bermasalah. Foto 12 MP yang dikirim mentah justru membuat inferensinya
    # lebih lama, jadi langkah ini dipertahankan.
    steps: dict = {}
    if enhance:
        frame, steps = enhance_for_vision(frame, quality=quality,
                                          max_side=1024)

    # Byte yang diteruskan ke Moondream SELALU hasil encode ulang dari frame
    # yang sudah didekode gerbang, tidak pernah `raw` dari klien - termasuk
    # saat `enhance=False`.
    #
    # Kenapa penting: Moondream membuka gambarnya dengan PIL, sementara
    # gerbang memakai OpenCV. Meneruskan `raw` berarti byte yang sama dibaca
    # DUA parser berbeda, dan dua parser tidak pernah sepakat sepenuhnya.
    # Berkas "polyglot" - PNG sah dengan muatan ditempel di belakangnya -
    # memanfaatkan persis celah itu: OpenCV mengabaikan ekornya dan meluluskan
    # gambarnya, lalu PIL menerima byte penuh berikut ekornya.
    #
    # Encode ulang memutus rantai itu. Yang sampai ke PIL adalah JPEG yang
    # dihasilkan server sendiri dari matriks pixel, jadi metadata, chunk
    # tambahan, dan ekor apa pun dari berkas asli tidak ikut - bukan karena
    # disaring satu per satu, melainkan karena tidak pernah disalin.
    #
    # Biayanya satu encode JPEG (beberapa milidetik) untuk menghapus seluruh
    # kelas serangan beda-parser. `enhance=False` tetap berarti apa yang
    # dijanjikannya: tanpa koreksi eksposur dan tanpa perubahan ukuran.
    image_bytes = numpy_to_jpeg_bytes(frame, quality=92)

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

    # ── 4. Inferensi dengan timeout, di dalam satu slot GPU ──
    #
    # Batas waktunya dikurung dulu. Perhatikan juga bahwa `wait_for` hanya
    # berhenti MENUNGGU: pekerjaan di thread pool tidak ikut berhenti saat
    # waktunya habis. `gpu.slot()` yang memastikan pekerjaan yang tidak
    # terlihat itu tidak pernah lebih dari satu, penjelasannya di
    # `services/guard.py`.
    timeout = min(max(timeout, MIN_TIMEOUT), MAX_TIMEOUT)
    gpu = request.app.state.gpu
    try:
        async with gpu.slot("describe"):
            caption_en = await asyncio.wait_for(
                moondream.describe(image_bytes, length=length),
                timeout=timeout,
            )
    except GpuBusy:
        return {
            "ok": False,
            "reason": "server_sibuk",
            "error": "server_sibuk",
            "description_en": "",
            "message": "Server sedang sibuk. Coba lagi sebentar lagi.",
            "elapsed_ms": round((time.perf_counter() - t0) * 1000, 1),
        }
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
