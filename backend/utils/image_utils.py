"""
utils/image_utils.py
====================
Penilaian kualitas gambar dan enhancement konservatif untuk CNN/VLM.

FILOSOFI YANG PERLU DISEPAKATI DULU
-----------------------------------
Ada dua cara menangani foto buram dari HP mid-low, dan keduanya TIDAK
sama efektifnya:

  A. TOLAK dan minta pengguna foto ulang       <- jauh lebih efektif
  B. Terima lalu perbaiki dengan sharpening    <- efektif terbatas

Alasannya fisik: blur menghilangkan informasi frekuensi tinggi secara
permanen. Unsharp masking tidak mengembalikan detail yang hilang, dia
cuma menaikkan kontras di tepi yang masih tersisa.

Yang lebih penting lagi, dan ini sering terlewat: MEMPERTAJAM GAMBAR
SEBELUM MASUK CNN/VLM BISA MEMPERBURUK HASILNYA. Model seperti YOLOE
dan Moondream2 dilatih pada foto natural. Unsharp masking agresif
menciptakan halo di tepi dan menguatkan noise, menghasilkan distribusi
pixel yang tidak pernah dilihat model saat training. Itu domain shift,
dan domain shift menurunkan akurasi.

Karena itu `enhance_for_vision()` sengaja KONSERVATIF: hanya koreksi
eksposur (CLAHE ringan pada channel L) dan downscale untuk kecepatan.
TIDAK ada unsharp agresif, TIDAK ada binarisasi, TIDAK ada
super-resolution. Untuk CNN, memperbaiki gambar yang terlalu gelap itu
membantu; "mempertajam" gambar yang sudah normal itu merugikan.

Dan di atasnya ada `assess_quality()` yang memutuskan apakah gambarnya
layak diproses sama sekali. Itulah jalur A, dan itulah yang benar-benar
menyelesaikan masalah.

TIDAK ADA JALUR OCR DI SINI
---------------------------
Mode Baca Teks berjalan sepenuhnya on-device lewat ML Kit dan tidak
punya endpoint server sama sekali. Pipeline OCR agresif (deskew,
koreksi perspektif, binarisasi Sauvola) sudah dipindah ke
`_archive/utils/image_ocr_pipeline.py` sebagai rujukan - tetap berguna
kalau nanti input ML Kit perlu diperbaiki di sisi Flutter, tapi yang
berpindah ke sana nanti adalah algoritmanya ke Dart, bukan modul ini.
"""


from __future__ import annotations

import base64
import time
from dataclasses import dataclass, field, asdict
from enum import Enum

import cv2
import numpy as np

# ═══════════════════════════════════════════════════════════════════════════════
#  Ambang kualitas
# ═══════════════════════════════════════════════════════════════════════════════
#
# CATATAN PENTING soal angka-angka ini:
# Variance of Laplacian sangat bergantung pada ISI GAMBAR dan RESOLUSI.
# Foto tembok polos yang tajam bisa punya skor lebih rendah daripada foto
# rerumputan yang blur, karena rerumputan punya tekstur di mana-mana.
#
# Karena itu:
#   1. Skor selalu dihitung pada resolusi yang DINORMALISASI (720p),
#      supaya foto 12MP dan 2MP bisa dibandingkan.
#   2. Angka di bawah adalah TITIK AWAL, bukan konstanta universal.
#      Kalibrasi ulang dengan foto asli dari HP target kamu:
#         python -m utils.image_utils --calibrate /path/folder_foto
#
NORMALIZED_HEIGHT = 720

BLUR_REJECT = 40.0      # di bawah ini: tolak, minta foto ulang
BLUR_WARN = 90.0        # di bawah ini: proses tapi turunkan kepercayaan
BLUR_GOOD = 180.0       # di atas ini: tajam

DARK_REJECT = 35.0      # mean brightness (0-255)
DARK_WARN = 60.0

# CATATAN soal "terlalu terang":
# Mean brightness TIDAK bisa dipakai sendirian untuk mendeteksi overexposure.
# Foto struk atau dokumen di atas kertas putih punya mean brightness sangat
# tinggi (240+) padahal eksposurnya sempurna dan teksnya terbaca jelas.
# Menolaknya sebagai "terlalu silau" akan membuat mode Baca Teks nyaris
# tidak bisa dipakai untuk kasus penggunaannya yang paling umum.
#
# Yang benar-benar menandakan overexposure adalah HIGHLIGHT YANG HANGUS:
# porsi pixel yang mentok di 255 sehingga informasinya hilang permanen.
# Dokumen putih yang baik punya kertas di sekitar 240-250 tapi TIDAK
# banyak yang mentok 255, dan tetap punya tinta gelap sebagai kontras.
BRIGHT_WARN = 215.0          # dipakai hanya bersama clipping tinggi
CLIPPED_REJECT = 0.35        # >35% pixel hangus/mati: informasi hilang
CLIPPED_PIXEL_WARN = 0.18

LOW_CONTRAST_WARN = 28.0    # std brightness

# Sisi terpendek minimum. Ini ambang KELAYAKAN, bukan preferensi: di bawah
# ini tidak ada cukup pixel untuk mengenali apa pun dengan andal.
#
# Angkanya berbeda per jalur karena kebutuhannya memang berbeda. OCR paling
# butuh resolusi (huruf kecil hilang lebih dulu daripada bentuk besar),
# deskripsi suasana paling sedikit (gambaran kasar ruangan masih terbaca dari
# frame kecil). Nilai per profil ada di services/image_gate.py.
MIN_SIDE_PX = 240


class QualityVerdict(str, Enum):
    GOOD = "good"
    ACCEPTABLE = "acceptable"
    POOR = "poor"        # diproses, tapi peringatkan pengguna
    REJECT = "reject"    # jangan diproses, minta foto ulang


@dataclass
class ImageQuality:
    """Hasil penilaian kualitas gambar."""
    verdict: QualityVerdict
    blur_score: float
    brightness: float
    contrast: float
    clipped_ratio: float
    width: int
    height: int
    issues: list[str] = field(default_factory=list)
    # Pesan Bahasa Indonesia siap dibacakan TTS
    message_id: str = ""
    message: str = ""
    elapsed_ms: float = 0.0

    @property
    def should_reject(self) -> bool:
        return self.verdict == QualityVerdict.REJECT

    @property
    def confidence_penalty(self) -> float:
        """
        Faktor pengali kepercayaan berdasarkan kualitas (0.0 - 1.0).

        Dipakai untuk menurunkan confidence deteksi pada gambar buruk,
        supaya sistem tidak yakin-yakin amat pada hasil dari foto jelek.
        """
        return {
            QualityVerdict.GOOD: 1.0,
            QualityVerdict.ACCEPTABLE: 0.92,
            QualityVerdict.POOR: 0.75,
            QualityVerdict.REJECT: 0.0,
        }[self.verdict]

    def to_dict(self) -> dict:
        d = asdict(self)
        d["verdict"] = self.verdict.value
        return d


# ═══════════════════════════════════════════════════════════════════════════════
#  Konversi dasar
# ═══════════════════════════════════════════════════════════════════════════════

def bytes_to_numpy(image_bytes: bytes) -> np.ndarray | None:
    """
    Decode bytes JPEG/PNG ke array BGR.

    Return None kalau gagal. Versi lama mengembalikan hasil cv2.imdecode
    apa adanya, yang juga bisa None, tapi tanpa penjelasan. Sekarang
    pemanggil punya kontrak yang jelas.
    """
    if not image_bytes:
        return None
    try:
        arr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        return img if img is not None and img.size > 0 else None
    except Exception:
        return None


def numpy_to_jpeg_bytes(frame: np.ndarray, quality: int = 90) -> bytes:
    ok, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
    return buf.tobytes() if ok else b""


def encode_image_base64(frame: np.ndarray, quality: int = 85) -> str:
    """Encode frame ke base64 JPEG (untuk debugging)."""
    return base64.b64encode(numpy_to_jpeg_bytes(frame, quality)).decode()


def draw_detections(frame: np.ndarray, detections: list[dict]) -> np.ndarray:
    """Gambar bounding box untuk debugging."""
    result = frame.copy()
    color_map = {
        "critical": (0, 0, 255),
        "warning": (0, 165, 255),
        "info": (0, 255, 0),
    }
    for det in detections:
        b = det.get("bbox", {})
        if not b:
            continue
        color = color_map.get(det.get("danger_level", "info"), (255, 255, 255))
        try:
            x1, y1 = int(b["x1"]), int(b["y1"])
            x2, y2 = int(b["x2"]), int(b["y2"])
        except (KeyError, TypeError, ValueError):
            continue
        cv2.rectangle(result, (x1, y1), (x2, y2), color, 2)
        label = f"{det.get('label_id', '')} {det.get('distance_meter', 0):.1f}m"
        cv2.putText(result, label, (x1, max(y1 - 8, 12)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)
    return result


# ═══════════════════════════════════════════════════════════════════════════════
#  Penilaian kualitas
# ═══════════════════════════════════════════════════════════════════════════════

def _normalize_for_scoring(gray: np.ndarray) -> np.ndarray:
    """
    Samakan resolusi sebelum menghitung skor blur.

    Ini WAJIB. Variance of Laplacian berskala dengan resolusi: foto 12MP
    yang sedikit blur bisa memberi skor lebih tinggi daripada foto 2MP
    yang tajam. Tanpa normalisasi, ambang tunggal tidak akan pernah
    bekerja lintas perangkat, dan itu persis kasus kamu (HP mid-low
    campur HP bagus).
    """
    h, w = gray.shape[:2]
    if h == NORMALIZED_HEIGHT:
        return gray
    scale = NORMALIZED_HEIGHT / max(1, h)
    new_w = max(1, int(round(w * scale)))
    interp = cv2.INTER_AREA if scale < 1.0 else cv2.INTER_LINEAR
    return cv2.resize(gray, (new_w, NORMALIZED_HEIGHT), interpolation=interp)


def variance_of_laplacian(image: np.ndarray, normalize: bool = True) -> float:
    """Variance of Laplacian. Makin kecil makin blur."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if image.ndim == 3 else image
    if normalize:
        gray = _normalize_for_scoring(gray)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


def tenengrad(image: np.ndarray, normalize: bool = True) -> float:
    """
    Skor ketajaman Tenengrad (magnitudo gradien Sobel).

    Dipakai sebagai pendapat kedua. Laplacian sensitif terhadap noise;
    pada foto malam yang ber-noise tinggi, Laplacian bisa memberi skor
    tinggi padahal gambarnya blur. Tenengrad lebih tahan noise.
    Kalau keduanya tidak sepakat, gambar itu kemungkinan noise-heavy.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if image.ndim == 3 else image
    if normalize:
        gray = _normalize_for_scoring(gray)
    gx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    gy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    return float(np.mean(gx ** 2 + gy ** 2))


def assess_quality(image: np.ndarray,
                   blur_reject: float = BLUR_REJECT,
                   blur_warn: float = BLUR_WARN,
                   strict: bool = False,
                   min_side: int = MIN_SIDE_PX,
                   reject_dark: bool = True) -> ImageQuality:
    """
    Nilai kualitas gambar dan hasilkan pesan Bahasa Indonesia yang
    ACTIONABLE untuk dibacakan TTS.

    "Gambar buram" tidak berguna bagi pengguna tunanetra. Yang berguna
    adalah instruksi konkret: "tahan HP lebih diam", "cari tempat lebih
    terang", "jangan terlalu dekat".

    Args:
        strict: kalau True, verdict POOR ikut ditolak. Dipakai untuk OCR
                di mana hasil dari foto buruk lebih menyesatkan daripada
                tidak ada hasil sama sekali.
        min_side: sisi terpendek minimum dalam pixel. Disetel per profil di
                services/image_gate.py, karena OCR butuh resolusi jauh lebih
                tinggi daripada deskripsi suasana.
        reject_dark: kalau False, foto di bawah DARK_REJECT tidak ditolak -
                cuma diturunkan ke POOR dan dicatat di `message`, lalu tetap
                diteruskan ke model. Dipakai endpoint yang penolakannya lebih
                merugikan daripada hasil yang kurang tepat; lihat catatan
                `reject_dark` di services/image_gate.py.
    """
    t0 = time.perf_counter()

    h, w = image.shape[:2]
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray_n = _normalize_for_scoring(gray)

    blur = float(cv2.Laplacian(gray_n, cv2.CV_64F).var())
    brightness = float(gray_n.mean())
    contrast = float(gray_n.std())

    clipped = float(
        ((gray_n <= 2) | (gray_n >= 253)).sum() / max(1, gray_n.size)
    )

    issues: list[str] = []
    verdict = QualityVerdict.GOOD
    message_id = "ok"
    message = ""

    def downgrade(to: QualityVerdict):
        nonlocal verdict
        order = [QualityVerdict.GOOD, QualityVerdict.ACCEPTABLE,
                 QualityVerdict.POOR, QualityVerdict.REJECT]
        if order.index(to) > order.index(verdict):
            verdict = to

    # ── Resolusi ──
    if min(h, w) < min_side:
        issues.append("resolusi_terlalu_kecil")
        downgrade(QualityVerdict.REJECT)
        message_id = "resolusi_kecil"
        message = "Gambar terlalu kecil. Coba ambil foto lagi."

    # ── Eksposur ──
    # Dicek DULUAN sebelum blur, karena foto yang sangat gelap otomatis
    # punya skor blur rendah (tidak ada kontras untuk dideteksi tepinya).
    # Melaporkan "buram" padahal masalahnya gelap akan membuat pengguna
    # melakukan tindakan yang salah.
    if brightness < DARK_REJECT and not reject_dark:
        # Gelap, tapi tetap diteruskan ke model. Catatannya TIDAK dibuang:
        # ia ikut lewat `quality_note()` ke narasi, jadi pengguna tetap tahu
        # jawabannya berasal dari foto yang kurang ideal.
        issues.append("terlalu_gelap")
        downgrade(QualityVerdict.POOR)
        message_id = "kurang_cahaya"
        message = ("Cahaya kurang, hasilnya mungkin kurang tepat. "
                   "Nyalakan senter kalau bisa.")
    elif brightness < DARK_REJECT:
        issues.append("terlalu_gelap")
        downgrade(QualityVerdict.REJECT)
        message_id = "terlalu_gelap"
        message = ("Terlalu gelap. Cari tempat yang lebih terang "
                   "atau nyalakan senter.")
    elif brightness < DARK_WARN:
        issues.append("kurang_cahaya")
        downgrade(QualityVerdict.POOR)
        if not message:
            message_id = "kurang_cahaya"
            message = "Cahaya kurang. Hasilnya mungkin kurang tepat."
    elif clipped > CLIPPED_REJECT:
        # Overexposure sejati: banyak pixel mentok sehingga detail hilang.
        # Dinilai dari clipping, BUKAN dari mean brightness, supaya foto
        # dokumen di kertas putih tidak ikut tertolak.
        issues.append("terlalu_silau")
        downgrade(QualityVerdict.REJECT)
        message_id = "terlalu_silau"
        message = ("Terlalu silau. Coba ubah posisi supaya tidak "
                   "menghadap cahaya langsung.")
    elif brightness > BRIGHT_WARN and clipped > CLIPPED_PIXEL_WARN:
        issues.append("agak_silau")
        downgrade(QualityVerdict.POOR)

    # ── Blur ──
    if brightness >= DARK_REJECT:
        if blur < blur_reject:
            issues.append("sangat_buram")
            downgrade(QualityVerdict.REJECT)
            if message_id in ("ok", "kurang_cahaya"):
                message_id = "sangat_buram"
                message = ("Gambar buram. Tahan ponsel lebih diam "
                           "sebentar, lalu coba lagi.")
        elif blur < blur_warn:
            issues.append("agak_buram")
            downgrade(QualityVerdict.POOR)
            if message_id == "ok":
                message_id = "agak_buram"
                message = "Gambar kurang tajam. Hasilnya mungkin kurang tepat."

    # ── Kontras ──
    # Dokumen teks punya std rendah secara global (mayoritas kertas polos)
    # tapi kontras lokal tinggi di area tulisan. Jadi std rendah saja bukan
    # masalah selama masih ada pixel gelap sebagai tinta.
    has_dark_ink = float((gray_n < 100).sum()) / max(1, gray_n.size) > 0.005
    if contrast < LOW_CONTRAST_WARN and not has_dark_ink:
        issues.append("kontras_rendah")
        downgrade(QualityVerdict.ACCEPTABLE)

    if CLIPPED_PIXEL_WARN < clipped <= CLIPPED_REJECT:
        issues.append("banyak_area_hangus")
        downgrade(QualityVerdict.ACCEPTABLE)

    if strict and verdict == QualityVerdict.POOR:
        verdict = QualityVerdict.REJECT
        if not message:
            message_id = "kualitas_kurang"
            message = "Gambar kurang jelas. Coba ambil ulang."

    if verdict in (QualityVerdict.GOOD, QualityVerdict.ACCEPTABLE) and not message:
        message_id = "ok"
        message = ""

    return ImageQuality(
        verdict=verdict,
        blur_score=round(blur, 2),
        brightness=round(brightness, 2),
        contrast=round(contrast, 2),
        clipped_ratio=round(clipped, 4),
        width=w, height=h,
        issues=issues,
        message_id=message_id,
        message=message,
        elapsed_ms=round((time.perf_counter() - t0) * 1000, 2),
    )


# ═══════════════════════════════════════════════════════════════════════════════
#  Enhancement primitif
# ═══════════════════════════════════════════════════════════════════════════════

def clahe_lab(image: np.ndarray, clip_limit: float = 2.0,
              tile_grid: int = 8) -> np.ndarray:
    """
    CLAHE pada channel L di ruang LAB.

    Kenapa LAB dan bukan langsung ke BGR: CLAHE pada tiap channel RGB
    secara terpisah akan menggeser warna, kadang parah. Di LAB, channel L
    murni luminansi, jadi kontras naik tanpa merusak warna.

    Ini enhancement yang PALING AMAN untuk semua jalur (OCR maupun CNN),
    karena dia memperbaiki masalah nyata (eksposur buruk) tanpa
    menciptakan artefak baru.
    """
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=clip_limit,
                            tileGridSize=(tile_grid, tile_grid))
    l = clahe.apply(l)
    return cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)








# ═══════════════════════════════════════════════════════════════════════════════
#  Deskew & koreksi perspektif
# ═══════════════════════════════════════════════════════════════════════════════













# ═══════════════════════════════════════════════════════════════════════════════
#  Binarisasi
# ═══════════════════════════════════════════════════════════════════════════════





# ═══════════════════════════════════════════════════════════════════════════════
#  Pipeline
# ═══════════════════════════════════════════════════════════════════════════════





def enhance_for_vision(image: np.ndarray,
                       quality: ImageQuality | None = None,
                       max_side: int = 1280) -> tuple[np.ndarray, dict]:
    """
    Pipeline enhancement KONSERVATIF untuk CNN dan VLM (YOLOE, Moondream2).

    KENAPA KONSERVATIF, ini poin yang paling sering salah dipahami:

    YOLOE dan Moondream2 dilatih pada foto natural. Unsharp masking
    agresif menciptakan halo di sekitar tepi dan menguatkan noise,
    menghasilkan statistik pixel yang tidak pernah dilihat model saat
    training. Itu domain shift, dan domain shift MENURUNKAN akurasi.

    Jadi yang dilakukan di sini cuma dua:
      1. CLAHE ringan, HANYA kalau gambarnya memang bermasalah eksposur.
         Memperbaiki foto yang terlalu gelap itu membantu, karena model
         memang jarang melihat foto segelap itu.
      2. Downscale kalau kebesaran, murni untuk kecepatan.

    TIDAK ada binarisasi, TIDAK ada sharpening agresif, TIDAK ada
    super-resolution.

    Kalau gambarnya buram, jawaban yang benar adalah menolak dan meminta
    foto ulang (lewat assess_quality), bukan mencoba menambal.
    """
    t0 = time.perf_counter()
    steps: dict = {}
    out = image

    q = quality or assess_quality(out)

    # Downscale DULUAN, baru enhance.
    #
    # Urutan ini penting untuk kecepatan: CLAHE dan bilateral filter
    # berskala linear terhadap jumlah pixel. Pada foto 12MP, menjalankan
    # CLAHE dulu lalu downscale memakan sekitar 3x lebih lama daripada
    # downscale dulu lalu CLAHE, dengan hasil akhir yang praktis sama
    # karena toh gambarnya akan dikecilkan juga.
    h, w = out.shape[:2]
    if max(h, w) > max_side:
        scale = max_side / max(h, w)
        out = cv2.resize(out, (int(w * scale), int(h * scale)),
                         interpolation=cv2.INTER_AREA)
        steps["resized_to"] = out.shape[:2]

    # CLAHE hanya kalau eksposur memang bermasalah
    needs_exposure_fix = (
        q.brightness < DARK_WARN
        or q.brightness > BRIGHT_WARN
        or q.contrast < LOW_CONTRAST_WARN
    )
    if needs_exposure_fix:
        clip = 1.8 if q.brightness < DARK_WARN else 1.4
        out = clahe_lab(out, clip_limit=clip, tile_grid=8)
        steps["clahe"] = clip
    else:
        steps["clahe"] = False

    # Denoise sangat ringan hanya untuk foto gelap ber-noise
    if q.brightness < DARK_WARN:
        out = cv2.bilateralFilter(out, d=5, sigmaColor=35, sigmaSpace=35)
        steps["denoise"] = True

    steps["elapsed_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return out, steps


# ═══════════════════════════════════════════════════════════════════════════════
#  Kalibrasi ambang
# ═══════════════════════════════════════════════════════════════════════════════

def calibrate_thresholds(folder: str, sample_limit: int = 200) -> dict:
    """
    Hitung distribusi skor blur dari folder foto asli.

    JALANKAN INI dengan foto sungguhan dari HP target sebelum memakai
    ambang default. Ambang blur sangat bergantung pada isi gambar dan
    karakteristik sensor; angka default di modul ini titik awal, bukan
    kebenaran universal.

    Cara pakai:
        python -m utils.image_utils --calibrate /path/ke/folder_foto
    """
    from pathlib import Path

    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    paths = [p for p in Path(folder).rglob("*") if p.suffix.lower() in exts]
    paths = paths[:sample_limit]

    if not paths:
        return {"error": f"Tidak ada gambar di {folder}"}

    blurs, brights, contrasts = [], [], []
    for p in paths:
        img = cv2.imread(str(p))
        if img is None:
            continue
        q = assess_quality(img)
        blurs.append(q.blur_score)
        brights.append(q.brightness)
        contrasts.append(q.contrast)

    if not blurs:
        return {"error": "Tidak ada gambar yang terbaca"}

    b = np.array(blurs)
    result = {
        "n_images": len(blurs),
        "blur": {
            "p05": round(float(np.percentile(b, 5)), 1),
            "p10": round(float(np.percentile(b, 10)), 1),
            "p25": round(float(np.percentile(b, 25)), 1),
            "p50": round(float(np.median(b)), 1),
            "p75": round(float(np.percentile(b, 75)), 1),
            "p90": round(float(np.percentile(b, 90)), 1),
        },
        "brightness_median": round(float(np.median(brights)), 1),
        "contrast_median": round(float(np.median(contrasts)), 1),
        "saran": {
            "BLUR_REJECT": round(float(np.percentile(b, 10)), 1),
            "BLUR_WARN": round(float(np.percentile(b, 30)), 1),
            "BLUR_GOOD": round(float(np.percentile(b, 70)), 1),
        },
        "catatan": (
            "Saran di atas mengasumsikan sekitar 10% foto di folder ini "
            "memang tidak layak pakai. Kalau folder berisi foto pilihan "
            "yang semuanya bagus, ambang ini akan terlalu longgar. "
            "Idealnya kumpulkan foto apa adanya, termasuk yang gagal."
        ),
    }
    return result


if __name__ == "__main__":
    import argparse
    import json

    ap = argparse.ArgumentParser(description="Utilitas gambar Vinara")
    ap.add_argument("--calibrate", help="Folder foto untuk kalibrasi ambang")
    ap.add_argument("--assess", help="Nilai kualitas satu file gambar")
    ap.add_argument("--benchmark", help="Benchmark pipeline pada satu gambar")
    args = ap.parse_args()

    if args.calibrate:
        print(json.dumps(calibrate_thresholds(args.calibrate),
                         indent=2, ensure_ascii=False))
    elif args.assess:
        img = cv2.imread(args.assess)
        if img is None:
            print("Gambar tidak terbaca")
        else:
            print(json.dumps(assess_quality(img).to_dict(),
                             indent=2, ensure_ascii=False))
    elif args.benchmark:
        img = cv2.imread(args.benchmark)
        if img is None:
            print("Gambar tidak terbaca")
        else:
            print(f"Ukuran: {img.shape}")
            for name, fn in [
                ("assess_quality", lambda: assess_quality(img)),
                ("clahe_lab", lambda: clahe_lab(img)),
                ("bilateral", lambda: cv2.bilateralFilter(img, 7, 45, 45)),
                ("enhance_for_vision", lambda: enhance_for_vision(img)),
            ]:
                fn()  # warmup
                t = time.perf_counter()
                for _ in range(5):
                    fn()
                dt = (time.perf_counter() - t) / 5 * 1000
                print(f"  {name:<22} {dt:>8.2f} ms")
    else:
        ap.print_help()
