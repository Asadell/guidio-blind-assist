import cv2
import numpy as np


def check_camera_health(frame: np.ndarray) -> dict:
    """
    Validasi frame sebelum dikirim ke YOLO.
    4 pengecekan: tertutup, gelap, buram, menghadap bawah.
    Return: {"ok": bool, "message": str}
    """
    h, w = frame.shape[:2]
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # 1. Lensa tertutup: > 90% piksel sangat hitam
    black_ratio = (gray < 10).sum() / gray.size
    if black_ratio > 0.90:
        return {"ok": False, "message": "Lensa kamera tertutup"}

    # 2. Terlalu gelap: rata-rata brightness sangat rendah
    if gray.mean() < 30:
        return {"ok": False, "message": "Kamera terlalu gelap"}

    # 3. Buram: Laplacian variance rendah
    lap_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if lap_var < 50:
        return {"ok": False, "message": "Gambar terlalu buram, pegang kamera lebih stabil"}

    # 4. Kamera menghadap ke bawah (heuristik: bawah frame lebih terang dari atas)
    top_mean    = gray[: h // 3, :].mean()
    bottom_mean = gray[2 * h // 3 :, :].mean()
    if bottom_mean > top_mean * 1.8:
        return {"ok": False, "message": "Arahkan kamera ke depan, bukan ke bawah"}

    return {"ok": True, "message": "OK"}
