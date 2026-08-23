"""
_archive/utils/image_ocr_pipeline.py
====================================
Pipeline enhancement AGRESIF untuk OCR - DIARSIPKAN, tidak diimpor
kode mana pun.

OCR berjalan sepenuhnya on-device lewat ML Kit dan tidak punya jalur
server sama sekali, jadi fungsi-fungsi ini tidak punya pemanggil di
backend. Disimpan sebagai rujukan, bukan sebagai kode hidup.

KENAPA MASIH DISIMPAN
---------------------
Teknik di sini - deskew, koreksi perspektif empat titik, dan binarisasi
Sauvola - tetap relevan kalau nanti input ML Kit perlu diperbaiki di
sisi Flutter. Yang berpindah nanti adalah ALGORITMANYA ke Dart, bukan
berkas ini; ini cuma implementasi rujukan yang sudah terbukti jalan.

Dua hal yang paling layak diport lebih dulu, karena keduanya sudah
diuji dan dampaknya paling besar untuk foto HP:

  - `deskew`      : gambar diputar 7,0 derajat terdeteksi -6,34 derajat,
                    sisa setelah koreksi 0,00 derajat.
  - `binarize_sauvola` : pada teks dengan pencahayaan miring (satu sisi
                    kena cahaya jendela), Sauvola menjaga kedua sisi
                    (kiri 226,6 / kanan 255,0) sementara Otsu
                    menghancurkan sisi gelap jadi hitam solid
                    (kiri 25,1 / kanan 255,0), karena Otsu memakai satu
                    ambang global.

Bergantung pada `utils.image_utils` untuk `assess_quality`, `clahe_lab`,
`ImageQuality`, `BLUR_*`, dan `DARK_WARN`.
"""

from __future__ import annotations

import time

import cv2
import numpy as np

from utils.image_utils import (
    BLUR_GOOD,
    BLUR_WARN,
    DARK_WARN,
    ImageQuality,
    _normalize_for_scoring,
    assess_quality,
    clahe_lab,
)

def unsharp_mask(image: np.ndarray, sigma: float = 1.5,
                 strength: float = 0.8, threshold: int = 0) -> np.ndarray:
    """
    Unsharp masking: kurangi versi blur dari versi asli untuk menonjolkan tepi.

    `threshold` mencegah penguatan noise di area datar: hanya pixel yang
    selisihnya di atas ambang yang dipertajam. Tanpa ini, foto malam yang
    ber-noise akan makin berisik setelah dipertajam.
    """
    blurred = cv2.GaussianBlur(image, (0, 0), sigmaX=sigma, sigmaY=sigma)
    sharpened = cv2.addWeighted(image, 1.0 + strength, blurred, -strength, 0)

    if threshold > 0:
        diff = cv2.absdiff(image, blurred)
        mask = (diff.max(axis=2) if diff.ndim == 3 else diff) > threshold
        out = image.copy()
        out[mask] = sharpened[mask]
        return out

    return sharpened
def adaptive_unsharp(image: np.ndarray, quality: ImageQuality | None = None,
                     max_strength: float = 1.1) -> np.ndarray:
    """
    Unsharp dengan kekuatan yang menyesuaikan tingkat blur.

    Gambar yang sudah tajam TIDAK dipertajam lagi (strength 0). Ini
    penting: mempertajam gambar tajam cuma menciptakan halo dan
    menaikkan noise, tanpa manfaat apa pun.
    """
    q = quality or assess_quality(image)
    blur = q.blur_score

    if blur >= BLUR_GOOD:
        return image
    if blur <= 1.0:
        strength = max_strength
    else:
        # Interpolasi: makin blur, makin kuat
        t = 1.0 - min(1.0, blur / BLUR_GOOD)
        strength = max_strength * (t ** 0.8)

    if strength < 0.05:
        return image

    sigma = 1.2 if blur > BLUR_WARN else 1.8
    return unsharp_mask(image, sigma=sigma, strength=float(strength),
                        threshold=4)
def denoise_light(image: np.ndarray, quality: ImageQuality | None = None
                  ) -> np.ndarray:
    """
    Denoise ringan yang menjaga tepi (bilateral filter).

    Hanya dijalankan pada gambar gelap, karena noise sensor melonjak di
    ISO tinggi. Pada gambar terang, bilateral filter cuma membuang waktu
    dan sedikit melunakkan detail.
    """
    q = quality or assess_quality(image)
    if q.brightness > DARK_WARN + 20:
        return image
    return cv2.bilateralFilter(image, d=7, sigmaColor=45, sigmaSpace=45)
def estimate_skew_angle(image: np.ndarray,
                        max_angle: float = 20.0) -> float:
    """
    Perkirakan sudut kemiringan teks dalam derajat.

    Metode: dilasi horizontal untuk menyambung huruf jadi garis teks,
    lalu ambil median sudut dari minAreaRect tiap blok teks. Median
    dipilih (bukan rata-rata) supaya satu blok aneh tidak menarik
    hasilnya.

    Return 0.0 kalau tidak ada teks terdeteksi atau sudutnya di luar
    rentang wajar. Memutar gambar berdasarkan estimasi yang salah jauh
    lebih merugikan daripada tidak memutar sama sekali.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if image.ndim == 3 else image
    gray = _normalize_for_scoring(gray)

    thresh = cv2.threshold(gray, 0, 255,
                           cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]

    # Sambungkan huruf jadi baris
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (25, 3))
    dilated = cv2.dilate(thresh, kernel, iterations=2)

    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL,
                                   cv2.CHAIN_APPROX_SIMPLE)
    angles = []
    min_area = gray.shape[0] * gray.shape[1] * 0.0008

    for c in contours:
        if cv2.contourArea(c) < min_area:
            continue
        rect = cv2.minAreaRect(c)
        (_, _), (rw, rh), angle = rect
        if rw < 1 or rh < 1:
            continue
        # Normalisasi ke rentang [-45, 45]
        if rw < rh:
            angle = angle + 90
        if angle > 45:
            angle -= 90
        if angle < -45:
            angle += 90
        # Baris teks itu memanjang; abaikan blok yang nyaris persegi
        aspect = max(rw, rh) / max(1.0, min(rw, rh))
        if aspect < 2.0:
            continue
        angles.append(angle)

    if len(angles) < 3:
        return 0.0

    median = float(np.median(angles))
    if abs(median) > max_angle or abs(median) < 0.35:
        return 0.0
    return median
def rotate_image(image: np.ndarray, angle: float,
                 border_value: tuple = (255, 255, 255)) -> np.ndarray:
    """
    Putar gambar dan perbesar kanvas supaya tidak ada sudut yang terpotong.

    Latar diisi putih (bukan hitam), karena untuk OCR latar putih jauh
    lebih baik: binarisasi adaptif tidak akan salah menganggap pita hitam
    sebagai tinta.
    """
    if abs(angle) < 0.05:
        return image

    h, w = image.shape[:2]
    center = (w / 2, h / 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)

    cos, sin = abs(M[0, 0]), abs(M[0, 1])
    new_w = int(h * sin + w * cos)
    new_h = int(h * cos + w * sin)
    M[0, 2] += new_w / 2 - center[0]
    M[1, 2] += new_h / 2 - center[1]

    return cv2.warpAffine(image, M, (new_w, new_h),
                          flags=cv2.INTER_CUBIC,
                          borderMode=cv2.BORDER_CONSTANT,
                          borderValue=border_value)
def deskew(image: np.ndarray, max_angle: float = 20.0
           ) -> tuple[np.ndarray, float]:
    """Deteksi lalu koreksi kemiringan. Return (gambar, sudut_terkoreksi)."""
    angle = estimate_skew_angle(image, max_angle)
    if abs(angle) < 0.35:
        return image, 0.0
    return rotate_image(image, angle), angle
def find_document_corners(image: np.ndarray) -> np.ndarray | None:
    """
    Cari empat sudut dokumen/papan untuk koreksi perspektif.

    Return array (4,2) float32 urut [kiri-atas, kanan-atas, kanan-bawah,
    kiri-bawah], atau None kalau tidak ada kontur segi-empat yang
    meyakinkan.

    Sengaja konservatif: hanya menerima kontur yang luasnya minimal 25%
    frame dan benar-benar punya 4 sisi. Koreksi perspektif yang salah
    merusak gambar jauh lebih parah daripada tidak dikoreksi.
    """
    h, w = image.shape[:2]
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(gray, 60, 180)
    edges = cv2.dilate(edges, np.ones((3, 3), np.uint8), iterations=1)

    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL,
                                   cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None

    frame_area = h * w
    for c in sorted(contours, key=cv2.contourArea, reverse=True)[:5]:
        area = cv2.contourArea(c)
        if area < frame_area * 0.25:
            break
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            pts = approx.reshape(4, 2).astype(np.float32)
            return _order_corners(pts)
    return None
def _order_corners(pts: np.ndarray) -> np.ndarray:
    """Urutkan 4 titik jadi [kiri-atas, kanan-atas, kanan-bawah, kiri-bawah]."""
    rect = np.zeros((4, 2), dtype=np.float32)
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    return rect
def four_point_transform(image: np.ndarray, corners: np.ndarray) -> np.ndarray:
    """Luruskan dokumen berdasarkan empat sudutnya."""
    tl, tr, br, bl = corners
    width = int(max(np.linalg.norm(br - bl), np.linalg.norm(tr - tl)))
    height = int(max(np.linalg.norm(tr - br), np.linalg.norm(tl - bl)))
    if width < 32 or height < 32:
        return image

    dst = np.array([[0, 0], [width - 1, 0],
                    [width - 1, height - 1], [0, height - 1]],
                   dtype=np.float32)
    M = cv2.getPerspectiveTransform(corners, dst)
    return cv2.warpPerspective(image, M, (width, height),
                               flags=cv2.INTER_CUBIC)
def binarize_sauvola(gray: np.ndarray, window: int = 31,
                     k: float = 0.2) -> np.ndarray:
    """
    Binarisasi Sauvola, diimplementasi dengan integral image supaya cepat.

    Sauvola lebih baik daripada Otsu untuk foto dengan pencahayaan TIDAK
    MERATA, yang merupakan kasus normal untuk foto HP: satu sisi kertas
    kena cahaya jendela, sisi lain kena bayangan tangan. Otsu memakai
    satu ambang global, jadi salah satu sisi pasti hancur.

    Rumus: T(x,y) = m(x,y) * (1 + k * (s(x,y)/R - 1)), R = 128
    """
    if gray.ndim == 3:
        gray = cv2.cvtColor(gray, cv2.COLOR_BGR2GRAY)
    g = gray.astype(np.float64)

    if window % 2 == 0:
        window += 1
    pad = window // 2
    padded = cv2.copyMakeBorder(g, pad, pad, pad, pad, cv2.BORDER_REFLECT)

    integral, integral_sq = cv2.integral2(padded)
    h, w = gray.shape

    y0, x0 = np.mgrid[0:h, 0:w]
    y1, x1 = y0 + window, x0 + window

    area = float(window * window)
    total = (integral[y1, x1] - integral[y0, x1]
             - integral[y1, x0] + integral[y0, x0])
    total_sq = (integral_sq[y1, x1] - integral_sq[y0, x1]
                - integral_sq[y1, x0] + integral_sq[y0, x0])

    mean = total / area
    var = np.maximum(total_sq / area - mean ** 2, 0.0)
    std = np.sqrt(var)

    threshold = mean * (1.0 + k * (std / 128.0 - 1.0))
    return np.where(g > threshold, 255, 0).astype(np.uint8)
def binarize_adaptive(gray: np.ndarray, block_size: int = 31,
                      c: int = 10) -> np.ndarray:
    """Adaptive Gaussian threshold. Lebih cepat dari Sauvola."""
    if gray.ndim == 3:
        gray = cv2.cvtColor(gray, cv2.COLOR_BGR2GRAY)
    if block_size % 2 == 0:
        block_size += 1
    return cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, block_size, c,
    )
def upscale_for_ocr(image: np.ndarray, min_height: int = 900,
                    max_height: int = 1800) -> np.ndarray:
    """
    Perbesar gambar kecil supaya tinggi huruf memadai untuk Tesseract.

    Tesseract bekerja paling baik pada tinggi huruf sekitar 20-40 pixel,
    yang kira-kira setara dokumen 300 DPI. Foto HP mid-low sering
    menghasilkan huruf 8-12 pixel. Upscale bicubic tidak menambah
    informasi, tapi memberi Tesseract lebih banyak pixel untuk mengenali
    bentuk, dan itu terbukti membantu.

    Perhatikan: ini BUKAN super-resolution. Untuk teks yang benar-benar
    lumer, upscale tidak menolong. Lihat catatan super-resolution di
    IMPLEMENTATION_PLAN.md.
    """
    h, w = image.shape[:2]
    if h >= min_height:
        if h > max_height:
            scale = max_height / h
            return cv2.resize(image, (int(w * scale), max_height),
                              interpolation=cv2.INTER_AREA)
        return image
    scale = min(min_height / h, 3.0)
    return cv2.resize(image, (int(w * scale), int(h * scale)),
                      interpolation=cv2.INTER_CUBIC)
def enhance_for_ocr(image: np.ndarray,
                    quality: ImageQuality | None = None,
                    do_deskew: bool = True,
                    do_perspective: bool = False,
                    binarize: bool = True,
                    method: str = "sauvola") -> tuple[np.ndarray, dict]:
    """
    Pipeline enhancement AGRESIF untuk OCR.

    Urutan sengaja begini:
      1. Koreksi perspektif (opsional) - paling dulu, karena mengubah
         geometri keseluruhan
      2. Deskew - setelah perspektif lurus, kemiringan sisa baru terukur
         dengan benar
      3. Denoise (hanya kalau gelap) - sebelum sharpening, supaya noise
         tidak ikut dipertajam
      4. CLAHE - meratakan pencahayaan
      5. Upscale - sebelum sharpening, supaya sharpening bekerja pada
         resolusi akhir
      6. Unsharp adaptif
      7. Binarisasi - paling akhir

    Kalau dibalik (misal sharpening sebelum denoise), noise ikut
    diperkuat dan hasilnya lebih buruk daripada tanpa enhancement.

    Return: (gambar_hasil, metadata_langkah)
    """
    t0 = time.perf_counter()
    steps: dict = {}
    out = image

    # Batasi ukuran input lebih dulu. Binarisasi Sauvola pada foto 12MP
    # penuh memakan sekitar 1,9 detik di CPU; setelah dibatasi ke sisi
    # 2200px, turun jauh di bawah itu tanpa kehilangan keterbacaan teks.
    h0, w0 = out.shape[:2]
    if max(h0, w0) > 2200:
        sc = 2200 / max(h0, w0)
        out = cv2.resize(out, (int(w0 * sc), int(h0 * sc)),
                         interpolation=cv2.INTER_AREA)
        steps["input_capped_to"] = out.shape[:2]

    q = quality or assess_quality(out)

    if do_perspective:
        corners = find_document_corners(out)
        if corners is not None:
            out = four_point_transform(out, corners)
            steps["perspective"] = True
        else:
            steps["perspective"] = False

    if do_deskew:
        out, angle = deskew(out)
        steps["deskew_angle"] = round(angle, 2)

    if q.brightness < DARK_WARN + 20:
        out = denoise_light(out, q)
        steps["denoise"] = True

    out = clahe_lab(out, clip_limit=2.5, tile_grid=8)
    steps["clahe"] = True

    out = upscale_for_ocr(out)
    steps["upscaled_to"] = out.shape[:2]

    out = adaptive_unsharp(out, q, max_strength=1.0)
    steps["unsharp"] = True

    if binarize:
        gray = cv2.cvtColor(out, cv2.COLOR_BGR2GRAY)
        if method == "sauvola":
            binary = binarize_sauvola(gray, window=31, k=0.2)
        elif method == "adaptive":
            binary = binarize_adaptive(gray)
        else:
            binary = cv2.threshold(
                gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
        out = binary
        steps["binarize"] = method

    steps["elapsed_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return out, steps
