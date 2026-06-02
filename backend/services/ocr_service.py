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
    logger.warning("pytesseract / Pillow tidak tersedia — OCR tidak aktif")


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
                return {"text": "", "lines": [], "confidence": 0.0, "error": "Gambar tidak valid"}

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
                return {"text": text, "lines": lines, "confidence": round(confidence, 2)}
            else:
                return {
                    "text": "", "lines": [], "confidence": 0.0,
                    "error": "OCR engine tidak tersedia (install pytesseract + tesseract-ocr)",
                }

        except Exception as e:
            logger.error(f"OCR error: {e}")
            return {"text": "", "lines": [], "confidence": 0.0, "error": str(e)}

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
