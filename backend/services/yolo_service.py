import time
import numpy as np
from ultralytics import YOLO
from loguru import logger

# Mapping label COCO (English) → Bahasa Indonesia
LABEL_ID: dict[str, str] = {
    "person":        "orang",
    "bicycle":       "sepeda",
    "car":           "mobil",
    "motorcycle":    "motor",
    "bus":           "bus",
    "truck":         "truk",
    "dog":           "anjing",
    "cat":           "kucing",
    "chair":         "kursi",
    "bench":         "bangku",
    "dining table":  "meja",
    "stairs":        "tangga",
    "door":          "pintu",
    "umbrella":      "payung",
    "backpack":      "tas",
    "traffic light": "lampu merah",
    "stop sign":     "rambu berhenti",
    "potted plant":  "tanaman",
    "suitcase":      "koper",
}

# Tinggi nyata objek dalam cm (untuk estimasi jarak)
REAL_HEIGHTS_CM: dict[str, int] = {
    "person":     170,
    "motorcycle": 120,
    "car":        150,
    "bicycle":    100,
    "bus":        300,
    "truck":      280,
    "dog":         60,
    "cat":         25,
    "chair":       90,
    "bench":       85,
    "default":    100,
}

# Focal length piksel (kalibrasi default, bisa di-override via .env)
FOCAL_LENGTH_PX = 615

# Klasifikasi bahaya
DANGER_HIGH   = {"person", "motorcycle", "car", "bus", "truck", "dog"}
DANGER_MEDIUM = {"bicycle", "chair", "bench", "dining table", "stairs"}


class YOLOService:
    def __init__(self, model_path: str = "yolov8m.pt", device: str = "auto"):
        self.model_path = model_path
        self.device     = self._resolve_device(device)
        self.model      = None
        self.loaded     = False

    def _resolve_device(self, device: str) -> str:
        if device != "auto":
            return device
        try:
            import torch
            return "cuda" if torch.cuda.is_available() else "cpu"
        except ImportError:
            return "cpu"

    def load(self) -> bool:
        try:
            logger.info(f"Loading YOLO '{self.model_path}' pada device '{self.device}'...")
            t0          = time.time()
            self.model  = YOLO(self.model_path)
            # Warm-up inference
            dummy = np.zeros((640, 640, 3), dtype=np.uint8)
            self.model.predict(dummy, verbose=False)
            logger.success(f"YOLO loaded dalam {time.time() - t0:.1f}s")
            self.loaded = True
            return True
        except Exception as e:
            logger.error(f"Gagal load YOLO: {e}")
            return False

    def infer(self, frame: np.ndarray, confidence: float = 0.5) -> list[dict]:
        """
        Jalankan inference — kembalikan raw detections TANPA filter.
        Filter ada di Flutter (DetectionFilter).
        """
        if not self.loaded:
            raise RuntimeError("Model belum di-load. Panggil load() terlebih dahulu.")

        h, w = frame.shape[:2]
        t0   = time.time()

        results      = self.model.predict(
            frame, conf=confidence, iou=0.45,
            imgsz=640, verbose=False, device=self.device,
        )
        inference_ms = (time.time() - t0) * 1000

        detections: list[dict] = []
        result = results[0]
        if result.boxes is None:
            return []

        for box in result.boxes:
            x1, y1, x2, y2 = [int(v) for v in box.xyxy[0].tolist()]
            label_en  = result.names[int(box.cls[0])]
            label_id  = LABEL_ID.get(label_en, label_en)
            box_h     = y2 - y1
            dist      = self._estimate_distance(label_en, box_h)
            direction = self._get_direction((x1 + x2) / 2, w)
            danger    = self._get_danger(label_en, dist)

            detections.append({
                "label_en":       label_en,
                "label_id":       label_id,
                "confidence":     round(float(box.conf[0]), 3),
                "distance_meter": round(dist, 2),
                "direction":      direction,
                "danger_level":   danger,
                "bbox":           {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                "inference_ms":   round(inference_ms, 1),
            })

        return detections

    def _estimate_distance(self, label: str, box_h: int) -> float:
        """Estimasi jarak via Similar Triangle formula."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_CM.get(label, REAL_HEIGHTS_CM["default"])
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

    def _get_direction(self, cx: float, w: int) -> str:
        """Tentukan arah berdasarkan posisi horizontal center bounding box."""
        t = w / 3
        if cx < t:
            return "kiri"
        if cx < t * 2:
            return "depan"
        return "kanan"

    def _get_danger(self, label: str, dist: float) -> str:
        """Tentukan level bahaya dari kombinasi class + jarak."""
        if label in DANGER_HIGH:
            if dist < 1.5:
                return "critical"
            if dist < 3.0:
                return "warning"
        elif label in DANGER_MEDIUM:
            if dist < 2.0:
                return "critical"
            if dist < 4.0:
                return "warning"
        return "info"
