"""Mode Kenali Uang — endpoint server OPSIONAL.

Jalur utama fitur ini ON-DEVICE (.tflite MobileNetV3, klasifikasi 7
denominasi), karena tiga alasan yang tidak bisa ditawar:
  1. Aksesibilitas: transaksi tunai sering terjadi di tempat tanpa sinyal
     (pasar, warung). Fitur yang mati saat offline = fitur yang gagal.
  2. Privasi: foto uang tidak perlu meninggalkan perangkat.
  3. Latensi: pengguna butuh umpan balik seketika saat mengarahkan kamera.

Endpoint server ini hanya cadangan untuk pembanding akurasi dan pengujian.

ATURAN KERAS: nominal TIDAK PERNAH ditebak. Kalau model belum ada atau
keyakinan di bawah ambang, balasannya adalah instruksi perbaikan, bukan
angka. Salah menyebut nominal ke pengguna tunanetra = kerugian uang nyata,
jadi false positive di sini jauh lebih berbahaya daripada false negative.
"""

import os
import time

import cv2
import numpy as np
from loguru import logger

# Urutan kelas WAJIB sama dengan model saat training (lihat kolom
# class_index di tabel money_denominations).
CLASS_VALUES = [1000, 2000, 5000, 10000, 20000, 50000, 100000]


class UangService:
    def __init__(self, model_path: str | None = None, threshold: float | None = None):
        self.model_path = model_path or os.getenv(
            "MONEY_MODEL", "models/uang_mobilenetv3.onnx"
        )
        self.threshold = float(os.getenv("MONEY_CONF_THRESHOLD", threshold or 0.85))
        self.input_size = 224
        self.session = None
        self.input_name: str | None = None
        self.loaded = False

    def load(self) -> bool:
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model uang '{self.model_path}' belum ada. "
                "Endpoint /api/uang akan balas 'model_unavailable' — TIDAK menebak. "
                "Jalur utama fitur ini tetap on-device (.tflite)."
            )
            return False
        try:
            import onnxruntime as ort

            opts = ort.SessionOptions()
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            self.session = ort.InferenceSession(
                self.model_path, opts, providers=["CPUExecutionProvider"]
            )
            self.input_name = self.session.get_inputs()[0].name
            self.loaded = True
            logger.success(f"Model uang dimuat: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"Model uang gagal dimuat: {e}")
            return False

    def predict(self, frame: np.ndarray, words_map: dict[int, str]) -> dict:
        """Klasifikasi nominal. Selalu balas dict, tidak pernah menebak.

        Bentuk balasan mengikuti state UG-05 / UG-06:
        - detected=True  → UG-05, nominal boleh ditampilkan (angka + kata)
        - detected=False → UG-06, HANYA instruksi perbaikan yang ditampilkan
        """
        if not self.loaded:
            return {
                "detected": False,
                "reason": "model_unavailable",
                "message": (
                    "Pengenalan uang di server belum aktif. "
                    "Mode Kenali Uang berjalan di perangkat tanpa internet."
                ),
            }

        try:
            t0 = time.time()
            img = cv2.resize(frame, (self.input_size, self.input_size))
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
            tensor = np.ascontiguousarray(np.transpose(img, (2, 0, 1))[None])

            logits = self.session.run(None, {self.input_name: tensor})[0][0]
            exp = np.exp(logits - logits.max())
            probs = exp / exp.sum()
            idx = int(probs.argmax())
            confidence = float(probs[idx])
            inference_ms = (time.time() - t0) * 1000

            if confidence < self.threshold:
                # UG-06 — ragu. Nominal TIDAK ditampilkan.
                return {
                    "detected": False,
                    "reason": "low_confidence",
                    "confidence": round(confidence, 3),
                    "threshold": self.threshold,
                    "message": "Belum yakin. Dekatkan sedikit dan tahan diam.",
                    "inference_ms": round(inference_ms, 1),
                }

            value = CLASS_VALUES[idx] if idx < len(CLASS_VALUES) else None
            if value is None:
                return {
                    "detected": False,
                    "reason": "unknown_class",
                    "message": "Belum yakin. Coba ulangi.",
                }

            return {
                "detected": True,
                "value_idr": value,
                "words": words_map.get(value, ""),
                "formatted": self._format_rupiah(value),
                "confidence": round(confidence, 3),
                "inference_ms": round(inference_ms, 1),
            }

        except Exception as e:
            logger.error(f"Prediksi uang gagal: {e}")
            return {
                "detected": False,
                "reason": "server_error",
                "message": "Gagal mengenali. Coba lagi.",
                "error": str(e),
            }

    @staticmethod
    def _format_rupiah(value: int) -> str:
        return "Rp" + f"{value:,}".replace(",", ".")
