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

     CATATAN REVISI: gerbang ini TIDAK LAGI MENOLAK APA PUN. Bukan cuma
     gelap - buram, silau, dan resolusi kecil ikut diteruskan
     (`reject_quality=False` di services/image_gate.py, profil
     `find_object`). Yang tersisa dari gerbang ini hanya dekode gambar,
     penilaian kualitas untuk catatan narasi, dan dua batas sumber daya.

     Alasannya sama dengan `describe`: satu tekan tombol = satu pencarian.
     Setiap penolakan berarti pengguna tunanetra sudah mengangkat ponsel,
     mengarahkannya, dan menekan tombol - lalu disuruh mengulang semuanya
     tanpa bisa melihat fotonya untuk tahu apa yang salah. Mobile pun sudah
     berhenti menyaring di sisinya (`_grabFrame` di
     find_object_screen.dart), jadi penolakan di sini akan jadi satu-satunya
     yang membatalkan permintaan yang sudah disetujui pengguna.

     Yang menggantikan pembedaannya adalah `quality_note`: foto gelap tetap
     turun ke POOR dan balasannya membawa "Fotonya gelap, jadi hasilnya
     mungkin tidak tepat". Kalau catatan itu dihapus dari narasi, penolakan
     di sini harus dihidupkan lagi.

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

  5. KAMUS LABEL SEPENUHNYA INTERNAL
     Versi lama memanggil `repo.get_searchable_labels()` pada SETIAP
     request. Untuk endpoint yang dipanggil berulang kali saat pengguna
     memutar badan (alur CO-05/CO-10), itu query database berulang untuk
     data yang praktis tidak pernah berubah - dan satu-satunya isi tabelnya
     memang hasil seed dari kamus yang sudah ada di dalam kode.

     Sekarang kamusnya dibaca langsung dari `EXTRA_ID_TO_EN`
     (`services/find_object_constants.py`). Nama di luar kamus tetap
     terlayani lewat `prompt_en` hasil terjemahan ML Kit on-device, jadi
     janji open-vocabulary YOLOE tidak berkurang sedikit pun.
"""

from __future__ import annotations

import asyncio
import re
import time

from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from services.find_object_constants import EXTRA_ID_TO_EN
from services.guard import GpuBusy
from services.image_gate import gate, quality_note
from utils.image_utils import enhance_for_vision

router = APIRouter(prefix="/api", tags=["cari-objek"])


# ═══════════════════════════════════════════════════════════════════════════════
#  Pembersihan input
# ═══════════════════════════════════════════════════════════════════════════════

# Nama barang terpanjang yang masuk akal. "botol minum warna biru" saja sudah
# 24 karakter; 64 memberi ruang lega. Yang di atas itu bukan nama barang, dan
# meneruskannya ke YOLOE cuma membuang waktu sebelum tetap gagal.
_MAX_TARGET_LEN = 64

# Huruf, angka, spasi, dan tanda hubung. Cukup untuk nama barang Bahasa
# Indonesia maupun Inggris, termasuk "HP", "kunci motor", "e-KTP".
_TARGET_ALLOWED = re.compile(r"[^0-9A-Za-zÀ-ÿ \-']")


def _clean_target(raw: str) -> str:
    """
    Rapikan nama barang dari klien.

    KENAPA INI PERLU, bukan sekadar kebersihan

    Nilai ini berakhir di dua tempat yang berbahaya: dikembalikan mentah di
    balasan (`result["target"] = target`), dan dipakai `_compose_message()`
    untuk menyusun kalimat yang DIBACAKAN TTS ke pengguna tunanetra.

    Tanpa pembersihan, klien mana pun bisa membuat aplikasi membacakan teks
    apa saja - dan pengguna tidak punya cara memeriksa bahwa yang didengarnya
    bukan berasal dari sistem. Karakter kendali dan teks sepanjang ribuan
    karakter juga membuat antrean suara tersumbat.

    Yang dibuang bukan cuma karakter aneh, tapi juga baris baru: TTS
    membacakannya sebagai jeda panjang yang terdengar seperti aplikasi
    menggantung.
    """
    if not raw:
        return ""
    # Karakter kendali dan pemisah baris jadi spasi lebih dulu, supaya kata
    # yang terpisah tidak menempel jadi satu.
    cleaned = re.sub(r"[\r\n\t\x00-\x1f\x7f]+", " ", raw)
    cleaned = _TARGET_ALLOWED.sub("", cleaned)
    cleaned = re.sub(r"\s{2,}", " ", cleaned).strip()
    return cleaned[:_MAX_TARGET_LEN].strip()


# Kata Inggris yang bukan nama benda. Kalau ini muncul di `prompt_en`,
# artinya penyaringan di aplikasi bocor - biasanya versi aplikasi lama yang
# menerjemahkan kalimat utuh alih-alih frasa bendanya saja.
#
# YOLOE mencocokkan SELURUH frasa prompt dengan isi gambar, jadi "please find
# my red bag" bukan sekadar prompt yang lebih panjang: ia mencari sesuatu yang
# serentak cocok dengan "please", "find", DAN "bag". Hasilnya bukan tas.
_PROMPT_EN_STOPWORDS = {
    "find", "finds", "finding", "search", "searching", "locate", "look",
    "looking", "seek", "detect", "scan", "show", "please", "help", "where",
    "whereis", "lost", "missing", "i", "me", "my", "mine", "your", "our",
    "can", "you", "want", "need", "get", "give", "tell", "let",
    "the", "a", "an", "is", "are", "was", "were", "of", "for", "to", "that",
    "this", "it", "its", "thing", "things", "item", "items", "object",
    "objects", "something", "anything",
}

# Sama dengan batas di sisi aplikasi (`CommandParser._maxPhraseWords`).
# Disamakan dengan sengaja: keduanya menjaga hal yang sama, dan batas yang
# berbeda membuat perilaku bergantung pada versi aplikasi yang dipakai.
_MAX_PROMPT_WORDS = 4


def _clean_prompt_en(raw: str | None) -> str | None:
    """Rapikan prompt Inggris dari aplikasi (hasil terjemahan ML Kit).

    Mengembalikan None kalau tidak ada yang layak dipakai - dan itu BUKAN
    kegagalan: `resolve_prompt` lalu memakai kamus manualnya, persis seperti
    sebelum ML Kit ada.

    Kenapa dibersihkan lagi padahal aplikasi sudah menyaring: nilai ini
    dikirim klien dan berakhir di `model.set_classes()`. Server tidak boleh
    bergantung pada versi aplikasi tertentu untuk kebersihannya sendiri.
    """
    cleaned = _clean_target(raw or "")
    if not cleaned:
        return None

    words = [w for w in cleaned.lower().split(" ") if w]
    words = [w for w in words if w not in _PROMPT_EN_STOPWORDS]
    if not words:
        return None

    return " ".join(words[:_MAX_PROMPT_WORDS])


def _clean_conf(raw: float | None) -> float | None:
    """
    Kurung ambang keyakinan ke rentang yang berarti.

    `conf` diteruskan ke `model.predict(conf=...)`. Nilai negatif membuat
    YOLOE mengembalikan ribuan kotak sampah - beban yang tidak perlu di
    endpoint yang dipanggil berulang kali. Nilai di atas 1 tidak pernah
    menghasilkan apa pun, jadi pengguna cuma mendengar "tidak ketemu" tanpa
    tahu bahwa yang salah adalah permintaannya.

    Dikurung, BUKAN ditolak: ini parameter opsional untuk penyetelan, dan
    menolak seluruh permintaan karena satu angka meleset akan menghentikan
    pencarian yang sebenarnya masih bisa dilayani.
    """
    if raw is None:
        return None
    try:
        v = float(raw)
    except (TypeError, ValueError):
        return None
    if v != v:                      # NaN tidak sama dengan dirinya sendiri
        return None
    return min(max(v, 0.001), 0.99)


@router.get("/cari-objek/targets")
async def searchable_targets():
    """
    Daftar barang yang dikenali sistem.

    Dipakai alur CO-12 (objek tak dikenali) untuk menawarkan barang lain
    yang memang bisa dicari.

    Daftar ini bukan batas atas kemampuan pencarian: nama di luar kamus tetap
    bisa dicari selama aplikasi mengirim `prompt_en`. Isinya adalah nama-nama
    yang dijamin punya padanan prompt yang cocok dengan encoder teks YOLOE.
    """
    targets = sorted(EXTRA_ID_TO_EN.keys())
    return {"total": len(targets), "targets": targets}


@router.post("/cari-objek")
async def cari_objek(
    request: Request,
    target: str = Form(..., description="Nama barang, mis. 'dompet'"),
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    prompt_en: str | None = Form(
        None,
        description="Terjemahan Inggris dari aplikasi (ML Kit), mis. 'red bag'. "
                    "Opsional - tanpa ini server memakai kamus manual.",
    ),
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

    # ── 0. Bersihkan input teks ──
    #
    # `target` datang dari pengenalan suara, jadi isinya tidak pernah bisa
    # diandalkan bentuknya. Yang lebih menentukan: nilainya DIKEMBALIKAN di
    # balasan dan dipakai `svc.find()` untuk menyusun kalimat yang dibacakan
    # TTS ke pengguna. Teks yang tidak dibersihkan berarti apa pun yang
    # dikirim klien bisa berakhir sebagai suara di telinga pengguna.
    target = _clean_target(target)
    if not target:
        return {
            "ok": False,
            "found": False,
            "reason": "target_kosong",
            "message": "Belum ada barang yang dicari. Sebutkan nama barangnya.",
            "matches": [],
            "total_match": 0,
            "retry_suggested": False,
        }

    conf = _clean_conf(conf)

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
    client_prompt_en = _clean_prompt_en(prompt_en)
    resolved_prompt = svc.resolve_prompt(
        target, client_prompt_en=client_prompt_en
    )
    # `svc.find()` sinkron dan berat: ia menahan GIL selama inferensi. Versi
    # lama memanggilnya langsung di dalam `async def`, jadi seluruh event loop
    # ikut berhenti - termasuk `/health`. Satu permintaan cari-objek membuat
    # server tampak MATI bagi pemantau mana pun selama beberapa detik, padahal
    # ia justru sedang bekerja.
    #
    # `to_thread` memindahkannya keluar dari event loop; `gpu.slot()` yang
    # menjaga agar perpindahan itu tidak berubah menjadi 50 thread berebut
    # satu kartu.
    gpu = request.app.state.gpu
    try:
        async with gpu.slot("cari-objek"):
            result = await asyncio.to_thread(
                svc.find, frame, resolved_prompt, target.strip().lower(), conf
            )
    except GpuBusy:
        return {
            "found": False,
            "reason": "server_sibuk",
            "error": "server_sibuk",
            "matches": [],
            "message": "Server sedang sibuk. Coba lagi sebentar lagi.",
            "elapsed_ms": round((time.perf_counter() - t0) * 1000, 1),
        }

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
        f"[cari-objek] target='{target}' prompt='{resolved_prompt}' "
        f"mlkit={'ya' if client_prompt_en else 'tidak'} "
        f"found={result.get('found')} n={result.get('total_match')} "
        f"kualitas={quality.verdict.value if quality else 'n/a'} "
        f"{result['elapsed_ms']:.0f}ms"
    )
    return result
