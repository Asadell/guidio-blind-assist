# Guidio App — Flutter Mobile

Aplikasi mobile Guidio adalah komponen utama sistem Guidio: "mata" dan "telinga" pengguna tunanetra. Seluruh deteksi rintangan real-time berjalan **langsung di perangkat** tanpa internet, menggunakan YOLO11n via TFLite.

---

## Daftar Isi

1. [Gambaran Arsitektur Mobile](#1-gambaran-arsitektur-mobile)
2. [TFLite On-Device — Kemampuan & Batasan](#2-tflite-on-device--kemampuan--batasan)
3. [Skenario Output ke Pengguna](#3-skenario-output-ke-pengguna)
4. [State Management: Provider Pattern](#4-state-management-provider-pattern)
5. [Kapan TFLite, Kapan Server](#5-kapan-tflite-kapan-server)
6. [Struktur Folder](#6-struktur-folder)
7. [Persyaratan Model TFLite](#7-persyaratan-model-tflite)
8. [Cara Menjalankan](#8-cara-menjalankan)
9. [Dependencies](#9-dependencies)

---

## 1. Gambaran Arsitektur Mobile

App ini **tidak menggunakan LLM di mobile**. LLM (Claude Haiku) hanya dipanggil dari server saat pengguna secara aktif meminta deskripsi (Mode Voice Assistant). Untuk peringatan real-time, semua berjalan lokal.

```
┌──────────────────────────────────────────────────────────────────┐
│ MOBILE — Flutter (Provider Pattern)                              │
│                                                                  │
│  ┌────────────┐   ┌───────────────────────────────────────────┐  │
│  │  Camera    │   │         InferenceProvider (Router)        │  │
│  │  Provider  │──▶│  Mode Tuntun/Navigasi → TFLite (utama)   │  │
│  │  (stream)  │   │  TFLite gagal/offline  → Server (fallback)│  │
│  └────────────┘   │  Voice Assistant       → Server (REST)    │  │
│        │          └──────────────┬────────────────────────────┘  │
│        │                         │ raw List<Detection>           │
│        │          ┌──────────────▼────────────────────────────┐  │
│        │          │           DetectionFilter                 │  │
│        │          │  1. distance > 4m → buang                 │  │
│        │          │  2. confidence < 0.5 → buang              │  │
│        │          │  3. streak < 3 frame → skip               │  │
│        │          │  4. cooldown per tier → skip              │  │
│        │          │  5. sort critical→warning→info            │  │
│        │          │  6. maks 2 pesan per cycle                │  │
│        │          └──────────────┬────────────────────────────┘  │
│        │                         │ filtered List<Detection>      │
│        │          ┌──────────────▼────────────────────────────┐  │
│        │          │           TtsProvider                     │  │
│        │          │  Critical → interrupt + speak segera      │  │
│        │          │  Warning/Info → antrian maks 2            │  │
│        │          │  flutter_tts, bahasa id-ID                │  │
│        │          └───────────────────────────────────────────┘  │
│        │                                                         │
│   captureJpeg ──────────────────────────────────── /api/ocr      │
│                                                                  │
│   Voice: STT → intent → YOLO snapshot → teks → /api/narasi → TTS │
└──────────────────────────────────────────────────────────────────┘
```

**Prinsip utama:**
- Filter pipeline **hanya di Flutter** — server hanya kirim raw detections
- TFLite **di Isolate** — tidak pernah di main thread (UI tidak freeze)
- Tidak ada LLM di mobile — semua peringatan pakai template kalimat lokal

---

## 2. TFLite On-Device — Kemampuan & Batasan

### Model yang Digunakan

| Parameter | Nilai |
|---|---|
| Model | YOLO11n (Nano) |
| Format | TFLite float32 |
| Input size | 320×320 px |
| Ukuran file | ~6.2 MB |
| Input tensor | `[1, 320, 320, 3]` — nested List, bukan flat array |
| Output tensor | `[1, 84, 2100]` — 84=(4 bbox + 80 class), 2100=anchor boxes |
| Target latensi | 55–110 ms di smartphone Android kelas menengah |
| Dijalankan di | Dart Isolate (background thread) via `IsolateInterpreter` |

### Objek yang Bisa Dideteksi (Subset COCO)

TFLite hanya melaporkan kelas yang **relevan untuk navigasi tunanetra**:

| Kelas (EN) | Label (ID) | Tier |
|---|---|---|
| person | orang | Critical |
| motorcycle | motor | Critical |
| car | mobil | Critical |
| bus | bus | Critical |
| truck | truk | Critical |
| dog | anjing | Critical |
| bicycle | sepeda | Warning |
| chair | kursi | Warning |
| dining table | meja | Warning |
| cat | kucing | Info |

Kelas COCO lain (e.g., *kite*, *tennis racket*, *toothbrush*) **diabaikan** — tidak relevan untuk konteks navigasi.

### Preprocessing: YUV420 → Input Tensor

Kamera Android menghasilkan frame format YUV420. Pipeline konversi:

```
CameraImage (YUV420)
        │
        ▼ [di Isolate — tidak block UI]
Konversi YUV → RGB menggunakan rumus:
  R = Y + 1.402 × (V - 128)
  G = Y − 0.344 × (U - 128) − 0.714 × (V - 128)
  B = Y + 1.772 × (U - 128)
        │
        ▼
Resize ke 320×320 (interpolasi linear)
        │
        ▼
Normalisasi: nilai piksel [0, 255] → [0.0, 1.0]
        │
        ▼
Struktur: nested List [1][320][320][3]
(TFLite Flutter WAJIB nested list, bukan flat Float32List)
        │
        ▼
IsolateInterpreter.run(input, output)
```

> ⚠️ **Catatan penting:** `tflite_flutter` membutuhkan input sebagai **nested list**, bukan `Float32List` flat. Jika dikirim flat, PAD kernel akan crash dengan error `dims 4 != 1`.

### Post-processing Output Tensor

```
Output tensor [1][84][2100]
        │
Loop 2100 anchor boxes:
  ├─ Ambil 4 bbox coords (cx, cy, w, h) — normalized
  ├─ Ambil 80 class scores
  ├─ Ambil class dengan score tertinggi
  └─ Filter: skip jika score < 0.5
        │
        ▼
Konversi bbox: normalized (cx,cy,w,h) → pixel (x1,y1,x2,y2)
        │
        ▼
Non-Maximum Suppression (NMS, IoU threshold 0.45)
        │
        ▼
Estimasi jarak (Similar Triangle):
  jarak = (tinggi_nyata_cm × focal_length_px) / (tinggi_bbox_pixel × 100)
  focal_length_px = 615 (kalibrasi default)
        │
        ▼
List<Detection>
```

---

## 3. Skenario Output ke Pengguna

Berikut kemungkinan output yang diterima pengguna berdasarkan kondisi nyata:

### A. Deteksi Normal (Mode Tuntun aktif)

| Kondisi | Output TTS |
|---|---|
| Orang 0.8m di depan | *"Bahaya! Ada orang kurang dari 1 meter di depan"* |
| Motor 2m di kanan | *"Hati-hati, ada motor di kanan"* |
| Kursi 1.5m di kiri | *"Hati-hati, ada kursi di kiri"* |
| Anjing 1m di depan | *"Bahaya! Ada anjing 1 meter di depan"* |
| Objek >4m | *(tidak dilaporkan)* |

### B. Camera Health Check — Kondisi Kamera Bermasalah

Sebelum inference dijalankan, sistem memeriksa kondisi kamera. Jika ada masalah, frame dibuang dan pengguna diberi tahu:

| Kondisi Terdeteksi | Cara Deteksi | Output TTS |
|---|---|---|
| **Kamera terlalu gelap** | avg brightness plane-Y < 30/255 (sampling 100 piksel) | *"Kamera terlalu gelap"* |
| **Lensa tertutup** | >90% piksel bernilai sangat gelap | *"Lensa kamera tertutup"* |
| **Gambar buram** | Laplacian variance < threshold | *"Gambar buram, bersihkan lensa"* |
| **Kamera menghadap bawah** | Accelerometer: kemiringan > 70° dari horizontal | *"Arahkan kamera ke depan"* |

> 💡 Pengecekan brightness dilakukan **setiap frame** menggunakan plane-Y dari YUV420 (sangat ringan: O(100) operasi). Pengecekan accelerometer dilakukan terpisah via `camera_health_service.dart`.

### C. Deteksi Difilter / Tidak Dilaporkan

Filter pipeline membuang deteksi dalam kondisi berikut:

| Alasan Dibuang | Kondisi |
|---|---|
| Terlalu jauh | `distance > 4.0 meter` |
| Confidence rendah | `confidence < 0.5` |
| Belum stabil | Terdeteksi < 3 frame berturut-turut (streak) |
| Cooldown aktif | Objek sama sudah dilaporkan dalam 2–5 detik terakhir |
| Antrian penuh | Sudah ada 2 pesan di antrian TTS |

### D. Status Sistem & Koneksi

| Kondisi | Output ke Pengguna |
|---|---|
| Backend tidak terhubung | SnackBar: *"Backend tidak terhubung. Berjalan di Mode Lokal (TFLite). Fitur Voice & OCR mungkin tidak tersedia."* |
| Izin kamera ditolak | SnackBar: *"Izin kamera ditolak..."* + tombol "Pengaturan" |
| TFLite belum load | Inference dilewati, tidak ada output (silent fallback) |

### E. Voice Assistant (membutuhkan backend)

| Pertanyaan Pengguna | Alur | Output |
|---|---|---|
| *"Ada apa di sekitar saya?"* | YOLO snapshot → teks → `/api/narasi` → Claude Haiku | Kalimat deskriptif natural dalam BI |
| *"Bacakan teks ini"* | captureJpeg → `/api/ocr` → flutter_tts | Teks terbacakan |
| *"Pergi ke halte"* | Intent routing → NavigationProvider | Instruksi navigasi |

---

## 4. State Management: Provider Pattern

```
main.dart
├── AppModeProvider         — mode aktif (tuntun/ocr/navigasi/voice)
├── CameraProvider          — controller kamera, stream, captureJpeg, brightness check
├── InferenceProvider       — routing TFLite vs server, manage koneksi WebSocket
├── DetectionProvider       — hasil deteksi + memanggil DetectionFilter + trigger TTS
├── TtsProvider             — antrian TTS maks 2, priority interrupt
├── VoiceProvider           — STT → intent detection → API call → TTS
└── NavigationProvider      — step navigasi, GPS, favorit tempat
```

**Alur data:**
```
CameraProvider.stream
        │
InferenceProvider (routing)
        │
        ├── TFLiteService.runInference() → di Isolate
        └── ServerService.detectionsStream → WebSocket
        │
DetectionProvider.onDetections()
        │
DetectionFilter.process() [filter, sort, deduplicate]
        │
TtsProvider.enqueue() → flutter_tts speak
```

---

## 5. Kapan TFLite, Kapan Server

| Mode | Engine | Alasan |
|---|---|---|
| Mode Tuntun (default) | **TFLite** | Real-time, offline, < 100ms |
| Mode Tuntun (TFLite gagal) | Server WebSocket | Fallback otomatis |
| Mode Navigasi (obstacle warning) | **TFLite** | Real-time wajib, tidak boleh lag |
| Voice Assistant ("ada apa?") | Server REST `/api/narasi` | 1 shot, butuh kalimat natural LLM |
| OCR (baca teks) | Server REST `/api/ocr` | TFLite tidak bisa OCR |
| Offline penuh | TFLite only | Voice & OCR tidak tersedia, peringatan tetap jalan |

---

## 6. Struktur Folder

```
lib/
├── main.dart
├── models/
│   └── detection.dart              # data class Detection (labelEn, labelId, distance, direction, danger)
├── services/
│   ├── tflite_service.dart         # load model, YUV→tensor, inference di Isolate, postprocess
│   ├── server_service.dart         # WebSocket stream + REST call ke backend
│   ├── detection_filter.dart       # filter pipeline (dipanggil untuk TFLite & server)
│   ├── tts_service.dart            # flutter_tts wrapper + speakAndWait (Completer)
│   └── camera_health_service.dart  # validasi posisi kamera via accelerometer
├── providers/
│   ├── app_mode_provider.dart      # mode aktif
│   ├── inference_provider.dart     # routing TFLite vs server
│   ├── detection_provider.dart     # orkestrasi deteksi + filter + TTS trigger
│   ├── tts_provider.dart           # antrian TTS maks 2, priority system
│   ├── camera_provider.dart        # kamera + brightness check + captureJpeg
│   ├── voice_provider.dart         # STT → intent → API → TTS
│   └── navigation_provider.dart    # step navigasi GPS
├── screens/
│   ├── main_screen.dart            # boot screen + routing mode
│   ├── tuntun_screen.dart          # Mode Tuntun (kamera fullscreen + detection overlay)
│   ├── ocr_screen.dart             # Mode OCR (scan overlay + hasil baca)
│   ├── navigasi_screen.dart        # Mode Navigasi (map + obstacle warning)
│   └── voice_screen.dart           # Mode Voice Assistant (card STT/response)
└── widgets/
    ├── bottom_bar.dart             # 3 tombol: kamera, mic (besar), mode
    ├── detection_card.dart         # card overlay deteksi
    ├── camera_health_banner.dart   # banner peringatan kondisi kamera
    └── mode_sheet.dart             # bottom sheet pilih mode

assets/
└── models/
    └── yolo11n.tflite              # ← TIDAK DI-COMMIT, lihat bagian 7
```

---

## 7. Persyaratan Model TFLite

Model YOLO11n TFLite **tidak disertakan di repositori** (ukuran ~6.2 MB, tidak efisien untuk Git). Export sendiri via Google Colab:

```python
# Jalankan di Google Colab (gratis, tanpa membebani storage lokal)
!pip install ultralytics
from ultralytics import YOLO

# Export ke TFLite float32 — imgsz=320 menghasilkan 2100 anchor boxes
YOLO("yolo11n.pt").export(format="tflite", imgsz=320, half=False, int8=False)

# File output: yolo11n_float32.tflite
# Download dari sidebar Colab, rename menjadi yolo11n.tflite
```

> ⚠️ **Penting:** Export TFLite membutuhkan **Python ≤ 3.12**. TensorFlow tidak mendukung Python 3.13+. Jika dilakukan lokal, butuh ~5 GB disk (CUDA dependencies). **Sangat disarankan pakai Google Colab.**

**Letakkan file di:**
```
guidio_app/assets/models/yolo11n.tflite
```

**Spec model yang sudah diverifikasi bekerja:**
- `imgsz=320` → input tensor `[1, 320, 320, 3]`, output `[1, 84, 2100]`
- `half=False`, `int8=False` → float32 (lebih stabil, akurasi lebih baik)
- File size: ~6.2 MB di perangkat

---

## 8. Cara Menjalankan

### Prasyarat
- Flutter SDK ≥ 3.x (`flutter --version`)
- Android device nyata (bukan emulator) — TFLite inference jauh lebih cepat di real hardware
- Backend sudah menyala (opsional — app tetap jalan di Mode Lokal tanpa backend)

### Langkah-langkah

```bash
# 1. Masuk ke direktori
cd guidio_app

# 2. Install dependencies
flutter pub get

# 3. Pastikan model sudah ada
ls assets/models/yolo11n.tflite

# 4. Jalankan (pastikan device tersambung)
flutter run

# 5. Untuk debug lebih lanjut
flutter run --verbose
```

### Tips Development

```bash
# Hot reload (perubahan UI kecil)
# Tekan 'r' di terminal saat flutter run aktif

# Hot restart (perubahan state/logic)
# Tekan 'R' di terminal

# Lihat log lebih detail
flutter logs

# Build APK untuk testing
flutter build apk --debug
```

---

## 9. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Kamera & AI
  camera: ^0.11.0              # CameraController + ImageStream (YUV420)
  tflite_flutter: ^0.10.4      # IsolateInterpreter untuk inference non-blocking
  image: ^4.1.7                # YUV420 → RGB conversion, resize

  # Komunikasi Backend
  web_socket_channel: ^2.4.0   # WebSocket stream ke /ws/detect
  http: ^1.2.0                 # REST call ke /api/narasi, /api/ocr

  # State Management
  provider: ^6.1.2             # ChangeNotifier + ProxyProvider

  # Audio
  flutter_tts: ^4.0.2          # Text-to-Speech (id-ID)
  speech_to_text: ^6.6.0       # Speech-to-Text Google STT
  vibration: ^2.1.0            # Haptic feedback saat mic aktif

  # Sensor & Lokasi
  sensors_plus: ^4.0.2         # Accelerometer untuk camera health check
  geolocator: ^12.0.0          # GPS untuk Risk Zone & navigasi
  permission_handler: ^11.4.0  # Request runtime permission (kamera, lokasi)
```
