import sys
import os
from pathlib import Path
import cv2

PROJECT_ROOT = Path(__file__).resolve().parent
BACKEND_DIR  = PROJECT_ROOT / "project" / "backend"
TEST_DIR     = PROJECT_ROOT / "test" / "object_find"
OUTPUT_DIR   = TEST_DIR / "results2"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(BACKEND_DIR))

# Ensure env vars match backend
os.environ["YOLOE_MODEL"] = str(BACKEND_DIR / "models" / "yoloe-11s-seg.pt")
os.environ["YOLOE_CONF"] = "0.001"

from services.find_object_service import FindObjectService

TEST_CASES = [
    {
        "filename": "test_01_tas_merah_kelas.png",
        "target_id": "tas merah",
    },
    {
        "filename": "test_02_kunci_motor_meja.png",
        "target_id": "kunci motor",
    },
    {
        "filename": "test_03_botol_minum_dapur.png",
        "target_id": "botol minum",
    },
    {
        "filename": "test_04_headphone_meja.png",
        "target_id": "headphone",
    },
    {
        "filename": "test_05_payung_kuning_taman.png",
        "target_id": "payung kuning",
    },
]

def main():
    print("=" * 70)
    print("🔍 GUIDIO — Pengujian Mode Cari Objek (YOLOE) -> results2")
    print("=" * 70)

    model_path = str(BACKEND_DIR / "models" / "yoloe-11s-seg.pt")
    if not os.path.exists(model_path):
        model_path = str(BACKEND_DIR / "yoloe-11s-seg.pt")

    print(f"Menggunakan Model: {model_path}")
    service = FindObjectService(model_path=model_path, conf=0.001)
    if not service.ensure_loaded():
        print("[!] Gagal memuat service YOLOE!")
        return

    label_map_db = {}
    summary = []

    for case in TEST_CASES:
        file_path = TEST_DIR / case["filename"]
        if not file_path.exists():
            print(f"\n[SKIP] File tidak ditemukan: {case['filename']}")
            continue

        frame = cv2.imread(str(file_path))
        if frame is None:
            print(f"\n[SKIP] Gagal membaca frame: {case['filename']}")
            continue
            
        h, w = frame.shape[:2]

        target_id = case["target_id"]
        prompt_en = service.resolve_prompt(target_id, label_map_db)

        print(f"\n📷 File Gambar : {case['filename']}")
        print(f"   🗣️ Target Input : \"{target_id}\"")
        print(f"   🔤 Prompt Resolved : \"{prompt_en}\"")

        res = service.find(frame, prompt_en=prompt_en, target_id=target_id)

        found = res["found"]
        matches = res.get("matches", [])
        total = res.get("total_match", 0)
        time_ms = res.get("inference_ms", 0)

        print(f"   ⏱️ Inferensi    : {time_ms:.1f} ms")
        print(f"   📊 Found        : {found} (Total match: {total})")
        print(f"   💬 Message      : \"{res['message']}\"")

        vis = frame.copy()
        if matches:
            for idx, m in enumerate(matches):
                x1, y1, x2, y2 = m["bbox"]["x1"], m["bbox"]["y1"], m["bbox"]["x2"], m["bbox"]["y2"]
                conf = m["confidence"]
                dist = m["distance_meter"]
                arah = m["direction"]

                color = (0, 255, 0) if idx == 0 else (0, 200, 255)
                cv2.rectangle(vis, (x1, y1), (x2, y2), color, 3)

                lbl = f"YOLOE: {prompt_en} {conf:.3f} ({dist}m {arah})"
                cv2.rectangle(vis, (x1, max(0, y1 - 25)), (x1 + min(len(lbl)*10, w - x1), y1), color, -1)
                cv2.putText(vis, lbl, (x1 + 4, max(18, y1 - 6)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 0, 0), 2)

        out_path = OUTPUT_DIR / f"result_{case['filename']}"
        cv2.imwrite(str(out_path), vis)
        print(f"   💾 Output Saved : {out_path.name}")
        
        summary.append({
            "file": case['filename'],
            "target": target_id,
            "prompt_en": prompt_en,
            "found": found,
            "total": total,
            "top_conf": matches[0]["confidence"] if matches else 0,
            "top_dist": matches[0]["distance_meter"] if matches else 0,
            "top_dir": matches[0]["direction"] if matches else "N/A"
        })

    print("\n" + "=" * 70)
    print("📋 RINGKASAN DETEKSI RESULTS2")
    print("=" * 70)
    for s in summary:
        status = "✅ FOUND" if s["found"] else "❌ NOT FOUND"
        print(f"{s['file']:30s} | Target: {s['target']:15s} | Prompt: {s['prompt_en']:15s} | {status} (conf: {s['top_conf']:.3f}, {s['top_dist']}m {s['top_dir']})")
    print("=" * 70)

if __name__ == "__main__":
    main()
