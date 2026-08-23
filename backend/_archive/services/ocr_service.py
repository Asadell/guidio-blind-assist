import io
import numpy as np
import cv2
from loguru import logger

try:
    from PIL import Image
    import pytesseract
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    logger.warning("pytesseract / Pillow tidak tersedia - OCR tidak aktif")


class OCRService:
    def __init__(self):
        logger.info(f"OCR Service init. Tesseract: {TESSERACT_AVAILABLE}")

    def read_text(self, image_bytes: bytes) -> dict:
        """
        Baca teks dari gambar JPEG.
        Return: {"text": str, "lines": list[str], "confidence": float}
        """
        try:
            arr   = np.frombuffer(image_bytes, np.uint8)
            frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
            if frame is None:
                return self._empty("Gambar tidak valid")

            processed = self._preprocess(frame)

            if TESSERACT_AVAILABLE:
                pil_img = Image.fromarray(processed)
                # PSM 6 = assume uniform block of text
                # lang: ind+eng untuk Indonesia + Inggris
                config = "--psm 6 -l ind+eng"
                data   = pytesseract.image_to_data(
                    pil_img, config=config,
                    output_type=pytesseract.Output.DICT,
                )
                text, lines, confidence = self._parse_tesseract(data)
                return {
                    "text": text,
                    "lines": lines,
                    "confidence": round(confidence, 2),
                    **self._reading_estimate(text, lines),
                }
            return self._empty(
                "OCR engine tidak tersedia. Pasang paket sistem tesseract-ocr "
                "beserta bahasa Indonesia (tesseract-langpack-ind)."
            )

        except Exception as e:
            logger.error(f"OCR error: {e}")
            return self._empty(str(e))

    def _empty(self, error: str) -> dict:
        """Balasan kosong dengan bentuk yang SAMA seperti balasan berhasil,
        supaya sisi aplikasi tidak perlu menebak field mana yang ada."""
        return {
            "text": "",
            "lines": [],
            "confidence": 0.0,
            "error": error,
            **self._reading_estimate("", []),
        }

    # Kecepatan TTS Bahasa Indonesia pada setelan bawaan aplikasi.
    # Dipakai BT-08: perkiraan durasi HARUS disebut sebelum pembacaan
    # dimulai, supaya pengguna bisa memilih ringkasan atau bagian tertentu.
    WORDS_PER_MINUTE = 130
    LONG_READ_SECONDS = 90

    def _reading_estimate(self, text: str, lines: list[str]) -> dict:
        words = len(text.split())
        seconds = round(words / self.WORDS_PER_MINUTE * 60, 1) if words else 0.0
        return {
            "word_count": words,
            "line_count": len(lines),
            "estimated_seconds": seconds,
            "estimated_spoken": self._duration_words(seconds),
            # BT-07 vs BT-06: hasil lebih dari 2 baris memakai panel panjang.
            "is_long": len(lines) > 2,
            # BT-08: di atas 90 detik, tawarkan ringkasan / penuh / pilih bagian.
            "is_very_long": seconds > self.LONG_READ_SECONDS,
        }

    @staticmethod
    def _duration_words(seconds: float) -> str:
        """Durasi dalam kata, bukan angka desimal - aturan penulisan copy."""
        if seconds <= 0:
            return "kurang dari satu detik"
        if seconds < 60:
            return f"sekitar {int(round(seconds))} detik"
        minutes = int(seconds // 60)
        rest = int(round(seconds % 60))
        if rest == 0:
            return f"sekitar {minutes} menit"
        return f"sekitar {minutes} menit {rest} detik"

    def _preprocess(self, frame: np.ndarray) -> np.ndarray:
        """Pre-processing untuk meningkatkan akurasi OCR."""
        gray     = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        denoised = cv2.fastNlMeansDenoising(gray, h=10)
        thresh   = cv2.adaptiveThreshold(
            denoised, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, 11, 2,
        )
        return thresh

    def _parse_tesseract(self, data: dict) -> tuple[str, list[str], float]:
        """Parse output tesseract ke teks bersih + confidence."""
        lines: dict[int, list[str]] = {}
        confidences: list[float]    = []

        for i, word in enumerate(data["text"]):
            word = word.strip()
            if not word:
                continue
            conf = int(data["conf"][i])
            if conf < 30:  # buang kata dengan confidence rendah
                continue
            line_num = data["line_num"][i]
            lines.setdefault(line_num, []).append(word)
            confidences.append(conf)

        line_texts = [" ".join(words) for words in lines.values()]
        full_text  = "\n".join(line_texts)
        avg_conf   = (sum(confidences) / len(confidences) / 100) if confidences else 0.0

        return full_text, line_texts, avg_conf
