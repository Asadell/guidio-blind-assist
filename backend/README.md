# Guidio Backend — FastAPI Server

Backend Guidio menangani pemrosesan yang membutuhkan akurasi tinggi atau compute besar yang tidak efisien dijalankan di perangkat mobile: OCR, narasi AI via LLM, dan deteksi server-side sebagai fallback.

> **Prinsip utama:** Backend hanya mengirim **raw detections** — tidak ada filter di sini. Semua pipeline filter ada di Flutter (mobile).

---

## Daftar Isi

1. [Gambaran Arsitektur Backend](#1-gambaran-arsitektur-backend)
2. [Endpoint API Reference](#2-endpoint-api-reference)
3. [Penggunaan LLM: Claude Haiku](#3-penggunaan-llm-claude-haiku)
4. [YOLO Server-Side vs TFLite Mobile](#4-yolo-server-side-vs-tflite-mobile)
5. [Struktur Folder](#5-struktur-folder)
6. [Instalasi & Menjalankan Server](#6-instalasi--menjalankan-server)
7. [Konfigurasi Environment](#7-konfigurasi-environment)
8. [Export Model TFLite (Opsional)](#8-export-model-tflite-opsional)

---

## 1. Gambaran Arsitektur Backend

```
Flutter App
    │
    ├── WebSocket /ws/detect ──▶ YOLOv8m ONNX ──▶ raw detections (stream)
    │
    ├── POST /api/detect     ──▶ YOLOv8m ONNX ──▶ raw detections (1 shot)
    │
    ├── POST /api/narasi     ──▶ Claude Haiku  ──▶ kalimat natural (1-2 kalimat BI)
    │
    ├── POST /api/route-intent ─▶ Claude Haiku  ──▶ intent string (max_tokens=10)
    │
    ├── POST /api/ocr        ──▶ Tesseract     ──▶ teks hasil baca
    │
    └── GET  /api/risk-zone  ──▶ In-memory store ──▶ zona bahaya terdekat
```

**Yang TIDAK dilakukan backend:**
- ❌ Tidak memfilter deteksi berdasarkan jarak atau confidence
- ❌ Tidak menyimpan queue TTS
- ❌ Tidak menentukan apakah objek perlu diumumkan atau tidak
- ❌ Tidak menerima gambar untuk Claude (input LLM selalu teks terstruktur)
- ❌ Tidak menjalankan SORT tracker (ada di Flutter)

---

## 2. Endpoint API Reference

### `GET /health`
Health check — cek apakah server dan YOLO sudah siap.

**Response:**
```json
{
  "status": "ok",
  "service": "Guidio Vision API",
  "yolo_loaded": true
}
```

---

### `WebSocket /ws/detect`
Stream deteksi real-time. Flutter mengirim frame JPEG secara terus-menerus, server membalas dengan raw detections.

**Flutter kirim:** binary JPEG bytes  
**Server balas (JSON):**

```json
{
  "type": "detections",
  "frame_id": 42,
  "detections": [
    {
      "label_en": "person",
      "label_id": "orang",
      "confidence": 0.87,
      "distance_meter": 1.2,
      "direction": "depan",
      "danger_level": "critical",
      "bbox": {"x1": 120, "y1": 80, "x2": 300, "y2": 420},
      "inference_ms": 45.3
    }
  ]
}
```

**Jika kamera bermasalah (camera health check):**
```json
{
  "type": "camera_error",
  "msg": "Kamera terlalu gelap"
}
```

**Catatan:** Server hanya memproses setiap **3 frame** (sample rate) untuk efisiensi.

---

### `POST /api/detect`
Single-shot inference untuk Voice Assistant (1 request = 1 response, bukan stream).

**Request:** `Content-Type: application/octet-stream` (raw JPEG bytes)  
**Response:**
```json
{
  "detections": [...],
  "total": 3
}
```

---

### `POST /api/narasi`
Generate kalimat natural dari hasil deteksi YOLO menggunakan Claude Haiku.

**Request:**
```json
{
  "detections": [
    {
      "label_id": "orang",
      "distance_meter": 1.2,
      "direction": "depan",
      "danger_level": "critical"
    },
    {
      "label_id": "motor",
      "distance_meter": 2.8,
      "direction": "kanan",
      "danger_level": "warning"
    }
  ],
  "context": "voice"
}
```

**Response:**
```json
{
  "narasi": "Di depan kamu ada seseorang yang cukup dekat, sekitar satu meter. Ada motor di sebelah kananmu. Jalur kiri tampak lebih aman."
}
```

**Fallback jika Claude API gagal** (tidak crash):
```json
{
  "narasi": "Ada orang di depan, sangat dekat, dan motor di kanan, sekitar 3 meter."
}
```

**Konteks yang didukung:**
- `"voice"` — pengguna tanya *"ada apa di sekitar?"*
- `"tuntun"` — deskripsi otomatis Mode Tuntun
- `"navigasi"` — deskripsi scene saat navigasi

---

### `POST /api/ocr`
Membaca teks dari gambar menggunakan Tesseract.

**Request:** `Content-Type: application/octet-stream` (JPEG bytes)  
**Response:**
```json
{
  "text": "Selamat Datang di Rumah Sakit XYZ",
  "lines": [
    "Selamat Datang",
    "di Rumah Sakit XYZ"
  ]
}
```

---

### `GET /api/risk-zone?lat={lat}&lng={lng}`
Cek zona bahaya di sekitar koordinat GPS pengguna.

**Response (jika ada zona bahaya):**
```json
{
  "risk_zone": {
    "id": "rz_001",
    "warning": "Area ini sering ada hambatan di trotoar, hati-hati",
    "distance_meter": 45.2
  }
}
```

**Response (aman):**
```json
{
  "risk_zone": null
}
```

---

### `POST /api/route-intent`
Intent routing untuk Voice Assistant menggunakan Claude Haiku. Dipanggil oleh `voice_provider.dart` Layer 2 (setelah keyword lokal tidak match).

**Request:**
```json
{ "text": "Apa yang ada di depan saya?" }
```

**Response:**
```json
{ "intent": "describe_scene", "fallback_used": false }
```

**Intent yang valid:** `describe_scene` | `ocr` | `navigation` | `chitchat`  
**Fallback:** jika Claude error/timeout → `{"intent": "describe_scene", "fallback_used": true}`  
**Latensi:** < 300ms (max_tokens=10, temperature=0.0)

---

## 3. Penggunaan LLM: Claude Haiku

### Kapan Claude Dipanggil?

| Situasi | Claude dipanggil? |
|---|---|
| Mode Tuntun real-time (tiap frame) | ❌ Tidak — pakai template sederhana |
| Voice Assistant ("ada apa?") | ✅ Ya — via `/api/narasi` |
| Voice Assistant intent routing | ✅ Ya — via `/api/route-intent` (max_tokens=10) |
| OCR (baca teks) | ❌ Tidak — Tesseract langsung |
| Navigasi obstacle warning | ❌ Tidak — pakai template |

Claude **hanya dipanggil saat pengguna secara aktif meminta deskripsi**. Tidak pernah per-frame.

### Input ke Claude: Teks, Bukan Gambar

Ini keputusan kritis. Claude **tidak pernah menerima gambar/base64**. Input selalu berupa teks terstruktur dari hasil YOLO:

```
System:
Kamu adalah asisten navigasi bernama Guidio untuk penyandang tunanetra.
Tugasmu: ubah data deteksi objek menjadi 1-2 kalimat Bahasa Indonesia yang natural...

User:
Objek terdeteksi kamera saat ini:
- orang, jarak 1.2 meter, posisi depan, bahaya: critical
- motor, jarak 2.8 meter, posisi kanan, bahaya: warning

Konteks: mode voice. Deskripsikan situasi ini untuk pengguna tunanetra.
```

**Kenapa teks, bukan gambar?**
Terinspirasi dari paper *Feedback-Enhanced YOLO + VLM* (arXiv 2025) dan *Neural Baby Talk* (CVPR 2018):
- Mencegah hallucination visual (Claude tidak bisa "salah lihat" objek yang tidak ada)
- Jauh lebih murah: ~100 token input vs kirim base64 gambar
- Lebih cepat: tidak perlu encode/decode
- Lebih akurat: LLM hanya merangkai kalimat dari fakta yang sudah diverifikasi YOLO

### Estimasi Biaya

Dengan `max_tokens=150` dan ~100 token input per request:

| Skenario | Frekuensi | Perkiraan biaya |
|---|---|---|
| Voice Assistant | ~20x per hari per user | Sangat murah |
| Deskripsi navigasi | ~10x per hari per user | Sangat murah |

Claude Haiku adalah model paling hemat Anthropic — cocok untuk output singkat 1-2 kalimat.

### Fallback jika Claude Gagal

Jika `ANTHROPIC_API_KEY` tidak diset atau Claude API timeout/error, endpoint `/api/narasi` **tidak crash** — ia mengembalikan template sederhana:

```python
def _template_fallback(detections):
    # Contoh output: "Ada orang di depan, sangat dekat, dan motor di kanan, sekitar 3 meter."
    ...
```

---

## 4. YOLO Server-Side vs TFLite Mobile

| Aspek | TFLite (Mobile) | YOLOv8m ONNX (Server) |
|---|---|---|
| Model | YOLO11n Nano | YOLOv8m Medium |
| Ukuran | ~6.2 MB | ~50 MB |
| Input size | 320×320 | 640×640 |
| Latensi | 55–110 ms | 200–500 ms |
| Butuh internet | ❌ Tidak | ✅ Ya |
| Dipakai untuk | Real-time warning (Mode Tuntun) | Fallback + Voice Assistant |
| Akurasi | Cukup untuk obstacle | Lebih detail & presisi |

**Prinsip penggunaan:**
- Mode Tuntun (real-time): **TFLite di mobile** (utama)
- Server WebSocket: **fallback** jika TFLite gagal
- Voice Assistant (1 shot): **server** untuk akurasi lebih tinggi
- OCR: **selalu server** (TFLite tidak bisa OCR)

### Camera Health Check di Server

Server juga melakukan pengecekan kondisi kamera sebelum menjalankan inference (via WebSocket):

| Kondisi | Cara Deteksi | Respons ke Flutter |
|---|---|---|
| Frame invalid/null | `cv2.imdecode` return `None` | `{"type": "error", "msg": "Frame invalid"}` |
| Lensa tertutup | >90% piksel < 10 brightness | `"Lensa kamera tertutup"` |
| Terlalu gelap | `gray.mean() < 30` | `"Kamera terlalu gelap"` |
| Gambar buram | Laplacian variance < 50 | `"Gambar terlalu buram"` |
| Kamera menghadap bawah | bottom_mean > top_mean × 1.8 | `"Arahkan kamera ke depan"` |

---

## 5. Struktur Folder

```
backend/
├── main.py                     # Entry point FastAPI, register routers, lifespan
├── requirements.txt            # Dependencies Python
├── .env                        # API Keys (TIDAK di-commit)
├── .env.example                # Template .env
├── export_tflite.py            # Script export YOLO ke TFLite (opsional)
│
├── routers/
│   ├── websocket.py            # /ws/detect — real-time stream YUV→YOLO
│   ├── detect.py               # /api/detect — single shot inference
│   ├── narasi.py               # /api/narasi — Claude Haiku narasi
│   ├── ocr.py                  # /api/ocr — Tesseract
│   ├── risk_zone.py            # /api/risk-zone — zona bahaya GPS
│   └── voice_router.py         # [NEW] /api/route-intent — LLM intent classifier
│
├── services/
│   ├── yolo_service.py         # YOLOService: load model, infer, estimate distance
│   ├── ocr_service.py          # OCRService: Tesseract wrapper
│   ├── risk_zone_service.py    # RiskZoneService: in-memory store (v1)
│   └── camera_health.py        # check_camera_health(): 4 kondisi kamera
│
└── utils/
    └── image_utils.py          # bytes_to_numpy(): JPEG bytes → OpenCV frame
```

---

## 6. Instalasi & Menjalankan Server

### Prasyarat
- Python 3.10–3.12 (3.13+ tidak direkomendasikan karena TensorFlow)
- `ANTHROPIC_API_KEY` dari [console.anthropic.com](https://console.anthropic.com)
- Model YOLO: `yolo11n.onnx` atau `yolov8m.pt` (sudah tersedia di repo)

### Langkah-langkah

```bash
# 1. Masuk ke direktori backend
cd backend

# 2. Buat virtual environment
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# 3. Install dependencies (ringan, ~150-200 MB)
pip install -r requirements.txt

# 4. Konfigurasi environment
cp .env.example .env
# Edit .env dan isi ANTHROPIC_API_KEY

# 5. Jalankan server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Server berjalan di `http://0.0.0.0:8000`. Flutter terhubung via IP lokal perangkat (pastikan HP dan laptop dalam jaringan WiFi yang sama).

### Akses API Docs

FastAPI auto-generate dokumentasi interaktif:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Troubleshooting

**Server gagal load YOLO:**
```
YOLO gagal di-load! Server tetap jalan tapi deteksi tidak aktif.
```
Server tetap berjalan. OCR dan narasi tetap berfungsi. Pastikan file model ada di direktori `backend/`.

**Claude API tidak tersedia:**
Endpoint `/api/narasi` otomatis fallback ke template sederhana tanpa crash.

**Flutter tidak bisa konek ke server:**
- Pastikan laptop dan HP dalam jaringan WiFi yang sama
- Cek IP lokal laptop: `ip addr show` (Linux) atau `ipconfig` (Windows)
- Update IP di `lib/services/server_service.dart`

---

## 7. Konfigurasi Environment

Buat file `.env` di folder `backend/`:

```env
# WAJIB — untuk endpoint /api/narasi
ANTHROPIC_API_KEY=sk-ant-api03-...

# Opsional — default ke yolov8m.pt
YOLO_MODEL=yolov8m.pt

# Opsional — auto = deteksi GPU/CPU otomatis
DEVICE=auto

# Opsional
PORT=8000
```

**Mendapatkan API Key:**
1. Daftar di [console.anthropic.com](https://console.anthropic.com)
2. Buat API Key baru
3. Tempel di `.env` sebagai `ANTHROPIC_API_KEY`

Jika API Key tidak diset, endpoint `/api/narasi` tetap berfungsi dengan output template (bukan kalimat natural dari Claude).

---

## 8. Export Model TFLite (Opsional)

Script `export_tflite.py` tersedia untuk mengkonversi model YOLO ke format TFLite yang dibutuhkan aplikasi mobile.

> ⚠️ **Peringatan storage:** Proses export men-download TensorFlow + PyTorch + CUDA (~5 GB). **Sangat disarankan menggunakan Google Colab** daripada laptop lokal.

```bash
# Jika ingin export di lokal (pastikan ada 5 GB disk kosong)
python3 export_tflite.py
```

**Atau via Google Colab (direkomendasikan):**
```python
!pip install ultralytics
from ultralytics import YOLO
# imgsz=320 → output tensor [1, 84, 2100] — sesuai yang dibutuhkan app Flutter
YOLO("yolo11n.pt").export(format="tflite", imgsz=320, half=False, int8=False)
```

**Persyaratan Python:**
- Export TFLite: **Python ≤ 3.12** (TensorFlow tidak support 3.13+)
- Menjalankan server FastAPI: Python 3.10–3.14 (semua versi aman)
