# Guidio — AI Navigation Assistant untuk Tunanetra

> *"Asisten navigasi berbasis AI yang bicara kepada penggunanya, bukan sebaliknya."*

Guidio adalah aplikasi Android yang menjadi **mata digital** bagi penyandang tunanetra dan low vision. Cukup pegang ponsel menghadap ke depan — Guidio akan memberi tahu apa yang ada di sekitar melalui suara secara otomatis, dalam Bahasa Indonesia, tanpa perlu koneksi internet untuk fitur keselamatan utamanya.

---

## Daftar Isi

1. [Mengapa Guidio?](#1-mengapa-guidio)
2. [Fitur Utama](#2-fitur-utama)
3. [Arsitektur Sistem](#3-arsitektur-sistem)
4. [Teknik: Mengapa YOLO Bisa Bicara Bahasa Manusia](#4-teknik-mengapa-yolo-bisa-bicara-bahasa-manusia)
5. [Stack Teknologi](#5-stack-teknologi)
6. [Landasan Akademis](#6-landasan-akademis)
7. [Struktur Repositori](#7-struktur-repositori)
8. [Quick Start](#8-quick-start)
9. [Catatan Pengembangan](#9-catatan-pengembangan)

---

## 1. Mengapa Guidio?

Aplikasi yang sudah ada memiliki celah besar untuk pengguna tunanetra di Indonesia:

| Aplikasi | Masalah |
|---|---|
| Google Maps | Tidak tahu ada rintangan fisik di depan |
| TalkBack | Hanya baca elemen layar, tidak "melihat" dunia nyata |
| Seeing AI | Tidak proaktif (harus tap dulu), tidak tersedia di Indonesia |
| Be My Eyes | Butuh orang lain yang online, tidak real-time |

Guidio mengisi celah ini: **satu-satunya** yang menggabungkan peringatan rintangan otomatis + OCR + navigasi dalam **Bahasa Indonesia**, tanpa butuh orang lain.

---

## 2. Fitur Utama

### 🛡️ Mode Tuntun — Deteksi Rintangan Real-time
Kamera aktif terus-menerus. YOLO11n berjalan di perangkat (TFLite), mendeteksi objek berbahaya dan memberi peringatan suara **secara otomatis** tanpa pengguna perlu melakukan apa-apa.

**Contoh output suara:**
- *"Bahaya! Ada orang kurang dari 1 meter di depan"*
- *"Hati-hati, ada motor di kanan"*
- *"Jalur kiri aman"*

**Filter cerdas mencegah spam suara:**
- Hanya objek dalam radius **≤ 4 meter** yang dilaporkan
- Objek yang sama tidak diulang lebih cepat dari cooldown per tier (2s / 3s / 5s)
- Maksimal **2 pesan** dalam antrian TTS sekaligus (dari riset Netra AI: meningkatkan pemahaman dari 52% → 78%)

### 📖 Mode OCR — Membaca Teks
Arahkan kamera ke teks (menu, rambu, label obat), tekan tombol kamera — Guidio membaca tulisan tersebut dengan suara.

### 🗺️ Mode Navigasi — Panduan Langkah demi Langkah
Peringatan rintangan dari Mode Tuntun tetap aktif, ditambah instruksi navigasi turn-by-turn. Jika ada bahaya, instruksi navigasi **selalu diinterupsi** oleh peringatan rintangan.

### 🎙️ Mode Voice Assistant — Tanya Bebas
Tekan mikrofon, tanya: *"Ada apa di sekitar saya?"* — Guidio menjalankan YOLO, lalu mengirim **teks** hasil deteksi (bukan gambar) ke Claude Haiku dan membalas dengan kalimat natural:

> *"Di depan kamu ada seseorang yang cukup dekat, sekitar satu meter. Ada motor di sebelah kananmu. Jalur kiri tampak lebih aman."*

---

## 3. Arsitektur Sistem

### Prinsip Utama: Hybrid On-Device + Cloud

```
┌─────────────────────────────────────────────────────────────────┐
│                     MOBILE (Flutter + Provider)                  │
│                                                                  │
│   Kamera ──▶ YOLO11n TFLite ──▶ DetectionFilter ──▶ TTS        │
│              (imgsz=320, 6.2MB)   (stability, dedup, priority)  │
│              < 100ms latency       cooldown per tier             │
│                   │                                              │
│                   │ (jika server terhubung, paralel)             │
│                   ▼                                              │
│   Mode Tuntun:  TFLite (utama) + Server WebSocket (fallback)    │
│   Voice Assist: TFLite snapshot ──▶ teks ──▶ /api/narasi        │
│   OCR:          captureJpeg ──────────────▶ /api/ocr             │
└──────────────────────────────┬───────────────────────────────────┘
                               │ (network, opsional)
┌──────────────────────────────▼───────────────────────────────────┐
│                      SERVER (FastAPI)                            │
│                                                                  │
│   /ws/detect    ──▶ YOLOv8m ONNX ──▶ raw detections             │
│   /api/narasi   ──▶ Claude Haiku  ──▶ kalimat natural            │
│   /api/ocr      ──▶ Tesseract     ──▶ teks hasil baca            │
│   /api/risk-zone──▶ PostgreSQL+PostGIS ──▶ zona bahaya           │
└──────────────────────────────────────────────────────────────────┘
```

### Keputusan Arsitektur Kunci

**1. Mengapa TFLite di mobile, bukan hanya server?**

Peringatan keselamatan **tidak boleh bergantung pada internet**. Sinyal di jalan bisa tidak stabil. TFLite (YOLO11n, 6.2 MB) berjalan lokal dengan latensi 55–110ms — sudah divalidasi oleh paper Netra AI (TechRxiv 2025) pada smartphone Android kelas menengah.

**2. Mengapa server tidak memfilter deteksi?**

Satu `DetectionFilter` di Flutter dipanggil untuk **kedua** sumber (TFLite dan server). Jika filter ada di server, hasil TFLite tidak akan terfilter. Jika ada di keduanya, akan terjadi *double-filter* yang membuang deteksi valid.

**3. Mengapa Claude Haiku menerima teks, bukan gambar?**

Terinspirasi dari paper *Feedback-Enhanced YOLO + VLM* (arXiv 2025) dan *Neural Baby Talk* (CVPR 2018): YOLO deteksi dulu, hasilnya dikirim sebagai teks terstruktur ke LLM. Ini:
- Mencegah hallucination visual
- Jauh lebih murah (input ~100 token vs kirim gambar)
- Lebih cepat (tidak perlu encode/decode base64)

**4. Sistem Audio 3-Tier (dari Netra AI)**

| Tier | Objek | Cooldown | Behavior |
|---|---|---|---|
| Critical | orang, motor, mobil, bus, truk, anjing | 2 detik | Interupsi TTS yang sedang jalan |
| Warning | sepeda, kursi, meja, anak tangga | 3 detik | Masuk antrian normal |
| Info | tas, payung, tanaman | 5 detik | Hanya jika antrian kosong |

### Alur Lengkap: Frame Kamera → Suara ke Pengguna

```
CameraImage (YUV420)
        │
        ▼ [TFLiteService — di Isolate, non-blocking]
YUV420 → RGB → resize 320×320 → normalize [0,1]
        │
        ▼ nested List [1][320][320][3]
YOLO11n inference
        │
        ▼ output tensor [1][84][2100]
        │  84 = 4 bbox (cx,cy,w,h) + 80 class scores
        │  2100 = anchor boxes untuk imgsz=320
        │
post-process: NMS + confidence threshold > 0.5
        │
        ▼ List<Detection>
[DetectionFilter]
  ├─ distance > 4m → buang
  ├─ confidence < 0.5 → buang
  ├─ streak < 3 frame → skip (belum stabil)
  ├─ masih dalam cooldown tier → skip
  └─ lolos → sort by priority, maks 2
        │
        ▼
[TtsProvider] → flutter_tts → Suara ke pengguna
```

### Camera Health Check (On-Device, Sebelum Inference)

Sebelum setiap frame diproses YOLO, ada 4 pengecekan otomatis di Flutter:

| Kondisi | Cara Deteksi | Output Suara |
|---|---|---|
| Kamera terlalu gelap | avg brightness plane-Y < 30/255 | *"Kamera terlalu gelap"* |
| Arahkan kamera ke depan | Accelerometer (kemiringan > 70°) | *"Arahkan kamera ke depan"* |
| Gambar terlalu buram | Laplacian variance < threshold | *"Gambar buram, bersihkan lensa"* |
| Lensa tertutup | >90% piksel hitam | *"Lensa kamera tertutup"* |

Jika kondisi tidak oke → frame dibuang, inference tidak dijalankan, pengguna diberi tahu.

---

## 4. Teknik: Mengapa YOLO Bisa Bicara Bahasa Manusia

Ini adalah salah satu inovasi inti Guidio — dan mungkin bagian yang paling menarik secara teknis. YOLO sendiri hanya menghasilkan angka: koordinat bounding box dan class scores. Lalu bagaimana output itu bisa berubah menjadi kalimat seperti *"Di depan kamu ada seseorang yang cukup dekat. Jalur kiri tampak lebih aman."*?

Jawabannya adalah teknik yang kami sebut **Grounded Text-to-Language (GTL)** — pipeline dua tahap yang menggabungkan hasil object detector dengan Large Language Model, **tanpa pernah mengirim gambar ke LLM**.

### Masalah dengan Pendekatan Naif

Pendekatan paling sederhana untuk membuat YOLO "bicara" adalah:
1. Kirim frame kamera ke Vision Language Model (VLM) seperti GPT-4V
2. Minta VLM mendeskripsikan apa yang ada di gambar

Ini tidak dipakai Guidio, karena:
- **Mahal:** satu request VLM dengan gambar bisa 10-50× lebih mahal dari teks saja
- **Lambat:** encode base64 + kirim gambar besar butuh bandwidth & latensi tinggi
- **Halusinasi:** VLM bisa "melihat" objek yang tidak ada, atau melewatkan objek nyata
- **Tidak bisa offline:** seluruh pipeline bergantung pada API cloud setiap frame

### Teknik yang Digunakan: YOLO First, LLM Second

Guidio membalik urutan ini:

```
[Langkah 1 — di Mobile, lokal, < 100ms]
Kamera → YOLO11n TFLite → Deteksi terverifikasi:
  {
    "orang": jarak 1.2m, posisi depan, danger: critical
    "motor": jarak 2.8m, posisi kanan, danger: warning
  }

[Langkah 2 — hanya saat user minta, ke server]
Teks terstruktur → Claude Haiku →
  "Di depan kamu ada seseorang yang cukup dekat,
   sekitar satu meter. Ada motor di sebelah kananmu.
   Jalur kiri tampak lebih aman."
```

**Kuncinya:** Claude Haiku **tidak pernah melihat gambar**. Ia hanya menerima fakta yang sudah diverifikasi YOLO dalam bentuk teks, lalu merangkainya menjadi kalimat natural. LLM di sini bukan untuk "melihat" — tapi untuk **merangkai bahasa**.



### Perbandingan: Template vs LLM

Guidio menggunakan **keduanya** untuk tujuan yang berbeda:

| Situasi | Metode | Contoh Output |
|---|---|---|
| Mode Tuntun (real-time, tiap frame) | Template lokal | *"Bahaya! Ada orang 1 meter di depan"* |
| Voice Assistant (on-demand) | Claude Haiku via server | *"Di depanmu ada seseorang yang sangat dekat. Jalur kiri tampak lebih aman untuk dilalui."* |

**Mengapa template untuk real-time?**
Template tidak butuh internet, tidak ada latensi API, dan untuk peringatan keselamatan kecepatan adalah segalanya. Netra AI sudah membuktikan template cukup untuk meningkatkan comprehension secara dramatis.

**Mengapa LLM untuk on-demand?**
Saat pengguna bertanya *"Ada apa di sekitar saya?"*, mereka butuh deskripsi yang **relasional** dan **kontekstual** — bukan daftar objek kaku. Hanya LLM yang bisa menghasilkan:

> *"Ada motor di kananmu yang tampak bergerak mendekat, dan seseorang tepat di depan. Sebaiknya berhenti sejenak dan geser ke kiri."*

Template tidak bisa menghasilkan *"sebaiknya berhenti sejenak"* — itu membutuhkan pemahaman konteks yang hanya dimiliki LLM.

### Mengapa Claude Haiku, Bukan GPT-4o Mini?

| Aspek | Claude Haiku | GPT-4o Mini |
|---|---|---|
| Bahasa Indonesia | ✅ Sangat baik | ✅ Baik |
| Harga per 1M token | Lebih murah | Sebanding |
| `max_tokens=150` biaya | Sangat rendah | Sebanding |
| Kecepatan response | Sangat cepat | Cepat |
| Kalimat singkat & natural | ✅ Optimal | ✅ Baik |

Claude Haiku dipilih karena biayanya sangat rendah untuk output singkat (1-2 kalimat), dan sudah terbukti menghasilkan Bahasa Indonesia natural tanpa perlu prompt engineering yang rumit.

### Ringkasan Teknis Pipeline

```
[On-Device — tidak butuh internet]
1. YUV420 frame → YOLO11n TFLite → bounding boxes
2. NMS + confidence filter (> 0.5)
3. Estimasi jarak via Similar Triangle
4. DetectionFilter: stability + dedup + priority

   Untuk Mode Tuntun:
5a. Template kalimat lokal → TTS → selesai

   Untuk Voice Assistant (saat user tanya):
5b. Format deteksi ke teks:
    "- orang, 1.2m, depan, critical
     - motor, 2.8m, kanan, warning"
6. POST /api/narasi → Claude Haiku
   (INPUT: teks, bukan gambar)
7. Response: kalimat natural BI
8. TTS → selesai
```

**Total latensi Voice Assistant:** ~800ms–1.5s (YOLO 100ms + network + Claude ~500ms + TTS)  
**Total latensi Mode Tuntun:** ~100ms (hanya YOLO + template, tidak ada API call)

---

## 5. Stack Teknologi

| Layer | Teknologi |
|---|---|
| Mobile App | Flutter (Dart), Provider pattern |
| On-Device AI | YOLO11n via TFLite Flutter (imgsz=320, float32) |
| Server AI | YOLOv8m via ONNX |
| LLM Narasi | Claude Haiku (`claude-haiku-4-5`) — input teks, bukan gambar |
| OCR | Tesseract via server |
| Speech-to-Text | Google STT (`speech_to_text` package) |
| Text-to-Speech | flutter_tts (`id-ID`) |
| Backend Framework | FastAPI (Python) |
| Real-time | WebSocket (`/ws/detect`) |
| Database | PostgreSQL + PostGIS (Risk Zone) |
| Komunikasi | REST + WebSocket |

---

## 6. Landasan Akademis

Guidio dibangun di atas 4 paper peer-reviewed/preprint:

| Paper | Kontribusi untuk Guidio |
|---|---|
| Wang et al., *YOLO-OD* — Sensors 2024 | Dataset obstacle navigasi, insight deteksi objek kecil (FWB block) |
| Lu et al., *Neural Baby Talk* — CVPR 2018 | Fondasi: output detector → kalimat natural tanpa kirim gambar ke LLM |
| Hingnekar et al., *Netra AI* — TechRxiv 2025 | Arsitektur on-device, sistem audio 3-tier, validasi latensi 55–110ms |
| Alsulaimawi, *Feedback-Enhanced VLM* — arXiv 2025 | Validasi "YOLO dulu → LLM dari teks" mengurangi hallucination 37% |

---

## 7. Struktur Repositori

```
project/
├── README.md                    ← (ini)
├── guidio_app/                  ← Flutter mobile app
│   ├── README.md                ← Panduan mobile + TFLite detail
│   ├── lib/
│   │   ├── models/              ← Detection data class
│   │   ├── services/            ← TFLite, Server, TTS, Filter, Camera Health
│   │   ├── providers/           ← State management (Camera, Inference, TTS, Voice, Navigation)
│   │   ├── screens/             ← Tuntun, OCR, Navigasi, Voice, Main
│   │   └── widgets/             ← BottomBar, DetectionCard, CameraHealthBanner
│   └── assets/models/           ← yolo11n.tflite (tidak di-commit, lihat README mobile)
├── backend/                     ← FastAPI server
│   ├── README.md                ← Panduan backend + API reference
│   ├── main.py                  ← Entry point FastAPI
│   ├── routers/                 ← detect, websocket, narasi, ocr, risk_zone
│   ├── services/                ← YOLOService, camera_health
│   └── utils/                   ← image_utils
```

---

## 8. Quick Start

### Prasyarat
- Flutter SDK ≥ 3.x, Dart ≥ 3.x
- Python 3.10–3.12 (untuk backend)
- Android device nyata (bukan emulator) untuk TFLite optimal
- `ANTHROPIC_API_KEY` untuk fitur Voice Assistant

### Langkah 1 — Siapkan Model TFLite

Model tidak di-commit ke repo karena ukurannya. Export via Google Colab:

```python
# Di Google Colab (gratis, tidak membebani storage lokal)
!pip install ultralytics
from ultralytics import YOLO
YOLO("yolo11n.pt").export(format="tflite", imgsz=320, half=False, int8=False)
# Download: yolo11n_float32.tflite → rename → yolo11n.tflite
```

Letakkan di: `guidio_app/assets/models/yolo11n.tflite`

> ⚠️ **Penting:** Export TFLite **wajib Python ≤ 3.12** (TensorFlow tidak support 3.13+). Gunakan Google Colab agar tidak memenuhi disk lokal (~5 GB dependency CUDA).

### Langkah 2 — Jalankan Backend

```bash
cd backend

# Buat virtual environment
python3 -m venv venv
source venv/bin/activate       # Windows: venv\Scripts\activate

# Install dependency (ringan, ~150 MB)
pip install -r requirements.txt

# Konfigurasi API Key
echo "ANTHROPIC_API_KEY=sk-ant-..." > .env

# Jalankan server (port 8000)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Langkah 3 — Jalankan Mobile App

Buka terminal baru (biarkan backend tetap menyala):

```bash
cd guidio_app
flutter pub get
flutter run
```

> 💡 App akan berjalan di **Mode Lokal (TFLite only)** jika backend tidak terhubung. Fitur Peringatan Rintangan tetap berfungsi, hanya Voice Assistant dan OCR yang membutuhkan backend.

---

## 9. Catatan Pengembangan

- **Filter pipeline HANYA di Flutter** — jangan tambahkan filter di server
- **Claude Haiku menerima TEKS, bukan gambar** — jangan kirim base64 image
- **TFLite inference HARUS di Isolate** — jangan jalankan di main thread (UI freeze)
- **Critical obstacle SELALU interrupt TTS lain** — tidak pernah antri
- **Semua TTS dalam Bahasa Indonesia** — flutter_tts set ke `id-ID`
- **Server tidak boleh crash jika Claude API gagal** — ada fallback ke template sederhana

---

*Dibuat oleh Tim Guidio — PENS 2026*
