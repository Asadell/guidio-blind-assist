# Guidio App (Flutter Frontend)

Aplikasi mobile Guidio dibangun menggunakan kerangka kerja Flutter. Aplikasi ini bertugas sebagai "mata" dan "telinga" utama bagi pengguna tunanetra. Tugas utamanya mencakup menangkap frame kamera, menjalankan inferensi AI lokal (TFLite) secara cepat, mengatur antrean notifikasi suara (TTS), dan merouting input suara pengguna ke backend.

## Arsitektur Mobile (Provider-Based)
Aplikasi ini memanfaatkan pola arsitektur **Provider** (ChangeNotifierProxyProvider) dengan injeksi dependensi untuk memastikan aliran data aman dan tidak terjadi *race condition*:
- **TFLiteService**: Menjalankan inferensi model YOLO11n secara offline murni di dalam *Isolate* (background thread terpisah dari UI) untuk mengejar target minimal 30 FPS.
- **DetectionFilter**: Bertugas menyaring noise hasil kamera. Menerapkan algoritma stabilisasi (streak counts) dan jeda waktu (cooldown timers) berdasarkan zona bahaya (Critical, Warning, Info) agar suara peringatan tidak tumpang tindih dan *spamming*.
- **VoiceProvider**: Mengatur *intent* suara pengguna (OCR, navigasi, atau tanya sekitar) lalu berkomunikasi via REST ke FastAPI.
- **CameraProvider & TTSService**: Mengelola hardware kamera dengan fitur konversi buffer YUV420, mengecek kegelapan layar (on-device brightness), dan memastikan antrean suara *Text-to-Speech* dieksekusi secara berurutan.

## Persyaratan TFLite Model
Aplikasi ini secara spesifik membutuhkan model **YOLO11n TFLite**. Karena batasan *storage repository*, model pre-trained ini **TIDAK** di-include.

**Cara Mendapatkan Model:**
1. Gunakan Google Colab untuk meng-export model dari Ultralytics secara gratis tanpa membebani laptop Anda:
   ```python
   !pip install ultralytics
   from ultralytics import YOLO
   YOLO("yolo11n.pt").export(format="tflite", imgsz=320, half=False, int8=False)
   ```
2. Download file hasil bernama `yolo11n_float32.tflite` dari menu sidebar Colab.
3. **Ubah nama file tersebut menjadi:** `yolo11n.tflite`.
4. Masukkan file tersebut secara manual ke direktori Flutter: 
   `guidio_app/assets/models/yolo11n.tflite`

## Cara Menjalankan Aplikasi
1. Pastikan Anda sudah menginstal Flutter SDK dan menyambungkan *real device* Android/iOS (disarankan fisik, bukan emulator, untuk hasil FPS TFLite yang optimal).
2. Masuk ke direktori aplikasi:
   ```bash
   cd guidio_app
   ```
3. Install seluruh dependensi paket:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi (Pastikan backend sudah menyala):
   ```bash
   flutter run
   ```
