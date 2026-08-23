import os
import time
import numpy as np
from ultralytics import YOLO
from loguru import logger

# ─── Model COCO (pretrained, 80 kelas) ───────────────────────────────────────
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

# Tinggi nyata objek dalam cm: model COCO
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

# ─── Model Navigasi Custom (6 kelas GUIDIO) ───────────────────────────────────
# Kelas sudah dalam Bahasa Indonesia → tidak perlu mapping tambahan
NAVIGASI_CLASSES = {"lubang", "got_terbuka", "tangga", "orang", "motor", "tiang"}

# Tinggi nyata untuk kelas navigasi custom (cm)
REAL_HEIGHTS_NAVIGASI: dict[str, int] = {
    "orang":      170,
    "motor":      120,
    "tiang":      200,
    "tangga":      80,
    "lubang":      10,   # objek di tanah → pakai ground-contact method lebih akurat
    "got_terbuka": 10,  # idem
    "default":    100,
}

# Klasifikasi bahaya model navigasi custom
DANGER_HIGH_NAV   = {"lubang", "got_terbuka", "orang", "motor"}
DANGER_MEDIUM_NAV = {"tangga", "tiang"}

# Focal length piksel (kalibrasi default, bisa di-override via .env)
FOCAL_LENGTH_PX = 615

# Klasifikasi bahaya model COCO
DANGER_HIGH   = {"person", "motorcycle", "car", "bus", "truck", "dog"}
DANGER_MEDIUM = {"bicycle", "chair", "bench", "dining table", "stairs"}


class YOLOService:
    def __init__(self, model_path: str = "yolov8m.pt", device: str = "auto",
                 navigasi_model_path: str | None = None):
        """Service YOLO dual-model: COCO untuk mode deteksi umum,
        model navigasi custom (6 kelas) untuk mode navigasi tunanetra.

        Args:
            model_path           : Model COCO pretrained (default yolov8m.pt / yolo11n.pt)
            device               : 'auto', 'cuda', 'cpu'
            navigasi_model_path  : Path ke yolo_navigasi.pt hasil training.
                                   Jika None, navigasi fallback ke model COCO.
        """
        self.model_path          = model_path
        self.navigasi_model_path = navigasi_model_path or os.getenv("YOLO_NAVIGASI_MODEL")
        self.device              = self._resolve_device(device)
        self.model               = None
        self.navigasi_model      = None   # model custom navigasi (opsional)
        self.loaded              = False

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
            t0         = time.time()
            self.model = YOLO(self.model_path)
            dummy      = np.zeros((640, 640, 3), dtype=np.uint8)
            self.model.predict(dummy, verbose=False)
            logger.success(f"YOLO (COCO) loaded dalam {time.time() - t0:.1f}s")
            self.loaded = True

            # Load model navigasi custom jika tersedia
            if self.navigasi_model_path:
                try:
                    nav_path = self.navigasi_model_path
                    logger.info(f"Loading YOLO navigasi custom '{nav_path}'...")
                    self.navigasi_model = YOLO(nav_path)
                    self.navigasi_model.predict(dummy, verbose=False)
                    logger.success(f"YOLO navigasi custom loaded. "
                                   f"Classes: {list(self.navigasi_model.names.values())}")
                except Exception as e:
                    logger.warning(f"Model navigasi custom gagal load: {e} - fallback ke COCO.")
                    self.navigasi_model = None

            return True
        except Exception as e:
            logger.error(f"Gagal load YOLO: {e}")
            return False

    def infer(self, frame: np.ndarray, confidence: float = 0.5,
              mode: str = "coco") -> list[dict]:
        """
        Jalankan inference YOLO.

        Args:
            frame      : Frame BGR dari OpenCV
            confidence : Threshold confidence (default 0.5)
            mode       : 'coco'     → model COCO pretrained (mode deteksi umum)
                         'navigasi' → model custom 6 kelas (mode navigasi)
        """
        # Pilih model yang tepat
        if mode == "navigasi" and self.navigasi_model is not None:
            active_model   = self.navigasi_model
            use_nav_schema = True
        else:
            active_model   = self.model
            use_nav_schema = False
        if not self.loaded:
            raise RuntimeError("Model belum di-load. Panggil load() terlebih dahulu.")

        h, w = frame.shape[:2]
        t0   = time.time()

        results = active_model.predict(
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
            raw_label = result.names[int(box.cls[0])]
            box_h     = y2 - y1

            if use_nav_schema:
                # Model navigasi: kelas sudah dalam BI, estimasi jarak pakai skema nav
                label_en  = raw_label
                label_id  = raw_label
                dist      = self._estimate_distance_nav(raw_label, box_h)
                danger    = self._get_danger_nav(raw_label, dist)
            else:
                # Model COCO: terjemahkan label ke BI
                label_en  = raw_label
                label_id  = LABEL_ID.get(raw_label, raw_label)
                dist      = self._estimate_distance(raw_label, box_h)
                danger    = self._get_danger(raw_label, dist)

            direction = self._get_direction((x1 + x2) / 2, w)

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
        """Estimasi jarak model COCO via Similar Triangle formula."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_CM.get(label, REAL_HEIGHTS_CM["default"])
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

    def _estimate_distance_nav(self, label: str, box_h: int) -> float:
        """Estimasi jarak model navigasi custom - pakai real heights skema nav."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_NAVIGASI.get(label, REAL_HEIGHTS_NAVIGASI["default"])
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
        """Tentukan level bahaya dari kombinasi class COCO + jarak."""
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

    def _get_danger_nav(self, label: str, dist: float) -> str:
        """Tentukan level bahaya dari kombinasi class navigasi custom + jarak.

        Lubang & got_terbuka lebih kritis dari orang/motor pada jarak dekat
        karena pengguna bisa langsung jatuh - tidak ada waktu menghindar.
        """
        if label in ("lubang", "got_terbuka"):
            if dist < 1.0:
                return "critical"
            if dist < 2.5:
                return "warning"
        elif label in ("orang", "motor"):
            if dist < 1.5:
                return "critical"
            if dist < 3.0:
                return "warning"
        elif label in ("tangga", "tiang"):
            if dist < 2.0:
                return "critical"
            if dist < 4.0:
                return "warning"
        return "info"
