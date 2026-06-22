# Guidio App — Flutter Mobile (Android)

Aplikasi mobile Guidio adalah komponen utama sistem Guidio: "mata" dan "telinga" pengguna tunanetra. Seluruh deteksi rintangan real-time berjalan **langsung di perangkat** tanpa internet, menggunakan SSD MobileNet via TFLite. Aplikasi ini dikhususkan untuk **Android**.

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
│        │          │  1. distance > 10m → buang                │  │
│        │          │  2. confidence < 0.5 → buang              │  │
│        │          │  3. streak < 1 frame → skip               │  │
│        │          │  4. cooldown tier (50% jika approaching)  │  │
│        │          │  5. sort critical→warning→info            │  │
│        │          │  6. maks 2 pesan per cycle                │  │
│        │          └──────────────┬────────────────────────────┘  │
│        │                         │ filtered List<Detection>      │
│        │          ┌──────────────▼────────────────────────────┐  │
│        │          │       TTS + HapticService                 │  │
│        │          │  Critical → interrupt + triple pulse      │  │
│        │          │  Warning/Info → antrian + pattern sesuai  │  │
│        │          │  flutter_tts + vibration package          │  │
│        │          └───────────────────────────────────────────┘  │
│        │                                                         │
│   captureJpeg ──────────────────────────────────── /api/ocr      │
│                                                                  │
│   Voice: STT → intent → SSD snapshot → teks → /api/narasi → TTS  │
└──────────────────────────────────────────────────────────────────┘
```

**Prinsip utama:**
- Filter pipeline **hanya di Flutter** — server hanya kirim raw detections
- TFLite **di Isolate** — tidak pernah di main thread (UI tidak freeze)
- SORT tracker **pure Dart** — tidak ada library eksternal, ~0ms overhead
- Haptic **mendampingi** TTS — tidak menggantikan, keduanya aktif bersamaan
- Tidak ada LLM di mobile — semua peringatan pakai template kalimat lokal

---

## 2. TFLite On-Device — Kemampuan & Batasan

### Model yang Digunakan

| Parameter | Nilai |
|---|---|
| Model | SSD MobileNet |
| Format | TFLite float32 |
| Input size | 300×300 px |
| Ukuran file | ~4 MB |
| Input tensor | `[1, 300, 300, 3]` — nested List, pixel range **0..255** (tidak dinormalisasi) |
| Output tensor | 4 tensor: `locations[1][10][4]`, `classes[1][10]`, `scores[1][10]`, `count[1]` |
| Target latensi | ~30 ms di smartphone Android kelas menengah |
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
Resize ke 300×300 (interpolasi linear)
        │
        ▼
Pixel value tetap 0..255 (SSD MobileNet TIDAK dinormalisasi ke 0..1)
        │
        ▼
Struktur: nested List [1][300][300][3]
(TFLite Flutter WAJIB nested list, bukan flat Float32List)
        │
        ▼
IsolateInterpreter.runForMultipleInputs(input, outputs)
```

> ⚠️ **Catatan penting:** `tflite_flutter` membutuhkan input sebagai **nested list**, bukan `Float32List` flat. Jika dikirim flat, PAD kernel akan crash dengan error `dims 4 != 1`.

### Post-processing Output Tensor

```
Output tensor SSD MobileNet
        │
        │  tensor[0]: locations [1][10][4] — [ymin, xmin, ymax, xmax] normalized
        │  tensor[1]: classes   [1][10]    — class index (float)
        │  tensor[2]: scores    [1][10]    — confidence score
        │  tensor[3]: count     [1]        — jumlah deteksi valid
        │
Loop maks 10 kandidat:
  ├─ Skip jika score < 0.5
  ├─ Skip jika label '???'
  └─ Konversi bbox [ymin,xmin,ymax,xmax] normalized → pixel x1,y1,x2,y2
        │
        ▼
(NMS sudah di dalam model — tidak perlu NMS manual)
        │
        ▼
Estimasi jarak (Similar Triangle + Tilt Correction):
  jarak_raw = (tinggi_nyata_cm × focal_length_px) / (tinggi_bbox_pixel × 100)
  jika HP miring > 15° → jarak = jarak_raw × cos(tilt_angle)
  focal_length_px = 615 (kalibrasi default)
        │
        ▼
Arah deteksi (horizontal + vertikal):
  Horizontal: kiri / depan / kanan (trisection lebar frame)
  Vertikal:   atas / tengah / bawah (trisection tinggi frame)
  Jika tengah → sebut horizontal saja
  Jika tidak → gabung: "kiri atas", "depan bawah", dll.
        │
        ▼
[ObjectTracker — SORT pure Dart]
  ├─ Greedy IoU matching label-aware (threshold 0.3)
  ├─ isApproaching = bbox area tumbuh > 20%
  └─ Track hilang > 5 frame → hapus
        │
        ▼
List<Detection> enriched (isApproaching)
```

---

## 3. Skenario Output ke Pengguna

Berikut kemungkinan output yang diterima pengguna berdasarkan kondisi nyata:

### A. Deteksi Normal (Mode Tuntun aktif)

| Kondisi | Output TTS |
|---|---|
| Orang 0.8m di depan | *"Bahaya! Ada orang kurang dari 1 meter di depan"* |
| Motor 2m di kanan atas | *"Hati-hati, ada motor di kanan atas"* |
| Kursi 1.5m di kiri bawah | *"Hati-hati, ada kursi di kiri bawah"* |
| Anjing 1m di depan | *"Bahaya! Ada anjing 1 meter di depan"* |
| Objek > 10m | *(tidak dilaporkan)* |

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
| Terlalu jauh | `distance > 10.0 meter` |
| Confidence rendah | `confidence < 0.5` |
| Belum stabil | Terdeteksi < 3 frame berturut-turut (streak) |
| Cooldown aktif | Objek sama sudah dilaporkan dalam cooldown terakhir (dipotong 50% jika mendekat) |
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
| *"Ada apa di sekitar saya?"* | Keyword miss → LLM routing → YOLO snapshot → teks → `/api/narasi` → Claude Haiku | Kalimat deskriptif natural dalam BI |
| *"Bacakan teks ini"* | Keyword "baca" → Layer 1 langsung → captureJpeg → `/api/ocr` → flutter_tts | Teks terbacakan |
| *"Pergi ke halte"* | Keyword "pergi ke" → Layer 1 langsung → NavigationProvider | Instruksi navigasi |
| Kalimat ambigu | Keyword miss → Layer 2 Claude Haiku (`max_tokens=10`) → intent → dispatch | Sesuai intent | 

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
│   └── detection.dart              # Detection: isApproaching, copyWith(), bboxCx/Cy/W/H/Area
├── services/
│   ├── tflite_service.dart         # load model, YUV→tensor, inference di Isolate, tilt correction
│   ├── server_service.dart         # WebSocket stream + REST + routeIntent()
│   ├── detection_filter.dart       # filter pipeline + approach-aware cooldown
│   ├── tts_service.dart            # flutter_tts wrapper + speakAndWait (Completer)
│   ├── haptic_service.dart         # [NEW] tri-tier vibration pattern (Critical/Warning/Info)
│   ├── object_tracker.dart         # [NEW] SORT tracker pure Dart — isApproaching detection
│   └── camera_health_service.dart  # validasi posisi kamera + lastTiltAngle getter
├── providers/
│   ├── app_mode_provider.dart      # mode aktif
│   ├── inference_provider.dart     # routing TFLite vs server
│   ├── detection_provider.dart     # orkestrasi: tracker → filter → TTS + haptic
│   ├── tts_provider.dart           # antrian TTS maks 2, priority system
│   ├── camera_provider.dart        # kamera + brightness check + tilt update tiap 30 frame
│   ├── voice_provider.dart         # STT → 2-layer routing (keyword + LLM) → TTS
│   └── navigation_provider.dart    # step navigasi GPS
├── screens/
│   ├── main_screen.dart
│   ├── tuntun_screen.dart
│   ├── ocr_screen.dart
│   ├── navigasi_screen.dart
│   └── voice_screen.dart
└── widgets/
    ├── bottom_bar.dart
    ├── detection_card.dart
    ├── camera_health_banner.dart
    └── mode_sheet.dart

assets/
└── models/
    ├── ssd_mobilenet.tflite               # model SSD MobileNet
    └── labelmap.txt                        # 90 label COCO
```

---

## 7. Persyaratan Model TFLite

Model SSD MobileNet (`ssd_mobilenet.tflite`) dan labelmap (`labelmap.txt`) **sudah disertakan di repositori** karena ukurannya kecil (~4 MB).

**Letakkan file di:**
```
guidio_app/assets/models/ssd_mobilenet.tflite
guidio_app/assets/models/labelmap.txt
```

**Spec model yang digunakan:**
- Input: `[1, 300, 300, 3]` float32, pixel range **0..255**
- Output: 4 tensor — locations, classes, scores, count (maks 10 deteksi per frame)
- NMS sudah built-in di model
- Labelmap: 90 baris (termasuk `???` untuk slot kosong COCO)
- File size: ~4 MB

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
ls assets/models/ssd_mobilenet.tflite assets/models/labelmap.txt

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

  # State Management
  provider: ^6.1.2

  # Kamera & AI
  camera: ^0.11.0+2            # CameraController + ImageStream (YUV420)
  tflite_flutter: ^0.12.1      # IsolateInterpreter untuk inference non-blocking
  image: ^4.1.7                # YUV420 → RGB conversion, resize

  # Komunikasi Backend
  web_socket_channel: ^3.0.1   # WebSocket stream ke /ws/detect
  http: ^1.2.1                 # REST call ke /api/narasi, /api/ocr, /api/route-intent

  # Audio & Feedback
  flutter_tts: ^4.0.2          # Text-to-Speech (id-ID)
  speech_to_text: ^7.0.0       # Speech-to-Text Google STT
  vibration: ^2.0.0            # Haptic feedback tri-tier (Critical/Warning/Info)

  # Sensor
  sensors_plus: ^7.0.0         # Accelerometer untuk camera health + tilt correction

  # Izin & Storage
  permission_handler: ^11.3.1  # Request runtime permission (kamera, mikrofon)
  shared_preferences: ^2.3.2   # Local storage lokasi favorit

  # Icon
  cupertino_icons: ^1.0.8
```
