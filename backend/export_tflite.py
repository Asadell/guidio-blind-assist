"""
Script export YOLO11 Nano ke format TFLite untuk Guidio.
Jalankan di dalam venv backend yang sudah punya ultralytics.

Usage:
    cd /path/to/project/backend
    python export_tflite.py

Output:
    yolo11n_float32.tflite  (atau yolo11n.tflite tergantung versi ultralytics)
    → copy ke: ../guidio_app/assets/models/yolo11n.tflite
"""

from pathlib import Path
from ultralytics import YOLO


def export():
    print("=== Export YOLO11n → TFLite ===")

    # Download + load YOLO11n (akan auto-download dari ultralytics hub)
    model = YOLO("yolo11n.pt")

    # Export ke TFLite
    # imgsz=320 agar sesuai dengan _inputSize di tflite_service.dart
    # half=False karena Android CPU tidak support float16 natively
    export_path = model.export(
        format="tflite",
        imgsz=320,
        half=False,   # float32 untuk Android CPU
        int8=False,
    )

    print(f"\nExport selesai: {export_path}")

    # Rename dan pindah ke assets
    src = Path(export_path)
    dst = Path("../guidio_app/assets/models/yolo11n.tflite")
    dst.parent.mkdir(parents=True, exist_ok=True)

    import shutil
    shutil.copy(src, dst)
    print(f"Disalin ke: {dst.resolve()}")
    print("\n✅ Selesai! File siap dipakai di Flutter.")


if __name__ == "__main__":
    export()
