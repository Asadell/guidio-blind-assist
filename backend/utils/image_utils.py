import cv2
import numpy as np


def bytes_to_numpy(image_bytes: bytes) -> np.ndarray:
    """Convert raw bytes (JPEG) to numpy BGR array."""
    arr = np.frombuffer(image_bytes, np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)


def encode_image_base64(frame: np.ndarray, quality: int = 85) -> str:
    """Encode numpy frame to base64 JPEG string (untuk debugging)."""
    import base64
    _, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
    return base64.b64encode(buf.tobytes()).decode()


def draw_detections(frame: np.ndarray, detections: list[dict]) -> np.ndarray:
    """Gambar bounding box di frame untuk debugging/visualisasi."""
    result = frame.copy()
    color_map = {
        "critical": (0, 0, 255),    # merah
        "warning":  (0, 165, 255),  # orange
        "info":     (0, 255, 0),    # hijau
    }
    for det in detections:
        b     = det.get("bbox", {})
        if not b:
            continue
        color = color_map.get(det.get("danger_level", "info"), (255, 255, 255))
        cv2.rectangle(result, (b["x1"], b["y1"]), (b["x2"], b["y2"]), color, 2)
        label = f"{det.get('label_id', '')} {det.get('distance_meter', 0):.1f}m"
        cv2.putText(
            result, label, (b["x1"], max(b["y1"] - 8, 12)),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
        )
    return result
