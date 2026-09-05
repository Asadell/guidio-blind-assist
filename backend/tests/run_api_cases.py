import json
import urllib.request
import urllib.error
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
TEST_DIR = PROJECT_ROOT / "test" / "object_find"
BASE_URL = "http://localhost:8000"

TEST_CASES = [
    {
        "filename": "test_01_tas_merah_kelas.png",
        "target": "tas merah",
        "prompt_en": "red bag",
        "label": "Tas Merah"
    },
    {
        "filename": "test_02_kunci_motor_meja.png",
        "target": "kunci motor",
        "prompt_en": "key",
        "label": "Kunci Motor"
    },
    {
        "filename": "test_03_botol_minum_dapur.png",
        "target": "botol minum",
        "prompt_en": "water bottle",
        "label": "Botol Minum"
    },
    {
        "filename": "test_04_headphone_meja.png",
        "target": "headphone",
        "prompt_en": "headphones",
        "label": "Headphone"
    },
    {
        "filename": "test_05_payung_kuning_taman.png",
        "target": "payung kuning",
        "prompt_en": "yellow umbrella",
        "label": "Payung Kuning"
    },
]

def test_single_case(case):
    img_path = TEST_DIR / case["filename"]
    if not img_path.exists():
        return {"error": f"File {case['filename']} tidak ada"}

    boundary = "----WebKitFormBoundaryGuidioTest7MA4YWxkTrZu0gW"
    img_bytes = img_path.read_bytes()
    
    # Build multipart/form-data payload
    body = bytearray()
    
    # target field
    body.extend(f"--{boundary}\r\n".encode('utf-8'))
    body.extend(f'Content-Disposition: form-data; name="target"\r\n\r\n'.encode('utf-8'))
    body.extend(f'{case["target"]}\r\n'.encode('utf-8'))
    
    # prompt_en field
    body.extend(f"--{boundary}\r\n".encode('utf-8'))
    body.extend(f'Content-Disposition: form-data; name="prompt_en"\r\n\r\n'.encode('utf-8'))
    body.extend(f'{case["prompt_en"]}\r\n'.encode('utf-8'))
    
    # conf field (optional override)
    body.extend(f"--{boundary}\r\n".encode('utf-8'))
    body.extend(f'Content-Disposition: form-data; name="conf"\r\n\r\n'.encode('utf-8'))
    body.extend(f'0.001\r\n'.encode('utf-8'))

    # file field
    body.extend(f"--{boundary}\r\n".encode('utf-8'))
    body.extend(f'Content-Disposition: form-data; name="file"; filename="{case["filename"]}"\r\n'.encode('utf-8'))
    body.extend(f"Content-Type: image/png\r\n\r\n".encode('utf-8'))
    body.extend(img_bytes)
    body.extend(f"\r\n--{boundary}--\r\n".encode('utf-8'))
    
    req = urllib.request.Request(
        f"{BASE_URL}/api/cari-objek",
        data=bytes(body),
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            return data
    except Exception as e:
        return {"error": str(e)}

def main():
    results = []
    print("Testing API /api/cari-objek live...")
    for c in TEST_CASES:
        print(f"\n--- Testing {c['label']} ({c['filename']}) ---")
        res = test_single_case(c)
        results.append({
            "case": c,
            "response": res
        })
        print(json.dumps(res, indent=2, ensure_ascii=False))

    with open("api_test_results.json", "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    main()
