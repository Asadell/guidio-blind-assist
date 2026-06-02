# Guidio AI Navigation Assistant

Guidio adalah asisten navigasi berbasis kecerdasan buatan yang dirancang khusus untuk tunanetra. Sistem ini menggabungkan deteksi objek *real-time* di perangkat (On-Device AI) dengan pemrosesan bahasa alami di server (Cloud AI) untuk memberikan panduan yang aman, cepat, dan natural.

## Arsitektur Hybrid: Kenapa ada Backend & TFLite?
Guidio menggunakan pendekatan arsitektur *Hybrid* untuk menyeimbangkan antara kecepatan (latensi) dan kecerdasan:

1. **On-Device TFLite (Flutter Mobile)**: 
   Deteksi rintangan dan objek berbahaya (lubang, tiang, tangga) **HARUS** diproses secara *real-time* (di bawah 100ms) tanpa bergantung pada koneksi internet yang kadang tidak stabil di jalan. Karena itu, model **YOLO11n** di-convert menjadi format `TFLite` yang super ringan dan dijalankan secara lokal langsung di *hardware* HP pengguna. Ini memastikan pengguna langsung mendapat peringatan bahaya seketika demi keselamatan fisik.
   
2. **Cloud Backend (FastAPI)**: 
   Pemrosesan yang tidak butuh respons milidetik tapi butuh *compute power* besar seperti **OCR** (membaca teks) dan **Pemahaman Konteks** (mendeskripsikan suasana "Ada apa di sekitar saya?") dilempar ke backend. Server menggunakan kekuatan Cloud (LLM Anthropic Claude Haiku) untuk memproses logika kompleks tanpa menguras memori RAM atau baterai HP pengguna secara drastis.

## Bagaimana YOLO Berbicara dengan Bahasa Manusia (Tidak Kaku)?
Salah satu inovasi utama Guidio adalah menghindari *cognitive overload* (pengguna stres karena diserang ribuan suara kaku seperti *"Orang. Orang. Kursi."*). Ini dipecahkan dengan cara:
1. **Ekstraksi Text-Payload (Bukan Gambar)**: Daripada mengirim gambar kamera yang butuh kuota internet dan bandwidth besar, Flutter menjalankan deteksi TFLite lokal lalu "merangkum" hasilnya menjadi JSON yang sangat kecil (contoh: `{"kiri": ["kursi (2m)"], "depan": ["orang (1m)"]}`).
2. **LLM Narration**: Payload teks super ringan tersebut dikirim ke Backend FastAPI. Backend lalu membungkus data itu ke dalam *prompt* sistem khusus dan mengirimkannya ke **Claude Haiku**.
3. **Hasil Natural & Mengalir**: Claude Haiku akan memahami konteks spasial tersebut lalu merespons dengan kalimat deskriptif layaknya manusia, contoh: *"Di depan Anda ada seseorang dalam jarak 1 meter, sementara di sebelah kiri ada kursi."*

## Penjelasan Fitur & Tutorial Penggunaan
Aplikasi Guidio dirancang dengan **antarmuka super simpel (hanya 4 tombol besar di layar bawah)** agar sangat mudah dihafal secara taktil oleh pengguna tunanetra. Berikut adalah cara kerja masing-masing fitur:

### 1. Mode Tuntun (Deteksi Rintangan Real-time)
- **Cara Kerja:** Kamera secara pasif memindai lingkungan sekitar. Mode ini menggunakan **On-Device TFLite (YOLO11n)**.
- **Tutorial:** Cukup buka aplikasi, dan default-nya Anda sudah berada di mode ini. Arahkan HP ke depan saat berjalan.
- **Kelebihan:** Aplikasi akan membunyikan suara seperti *"Awas, tiang di depan"* hanya jika rintangan berada dalam jarak **Critical (1-2 meter)**. Tidak akan melakukan *spam* jika objek masih jauh berkat fitur *Detection Filter Cooldown*.

### 2. Mode Asisten Suara (AI Narration)
- **Cara Kerja:** Menggunakan kombinasi YOLO + Claude Haiku untuk mendeskripsikan suasana sekitar.
- **Tutorial:** Tekan tombol Mic di layar. Anda akan mendengar bunyi *Bip*. Tanyakan: *"Ada apa di sekitar saya?"*
- **Kelebihan:** Aplikasi memotret *"snapshot"* deteksi saat itu, mengirim payload ringkas ke backend, dan membalas dengan kalimat natural (contoh: *"Di sebelah kanan ada kursi kosong, dan di depan ada meja"*).

### 3. Mode OCR (Membaca Teks)
- **Cara Kerja:** Mengambil gambar dan mengirimnya ke backend FastAPI (Tesseract OCR).
- **Tutorial:** Pilih mode OCR (tombol berlogo teks). Arahkan kamera ke kertas, papan nama, atau botol obat, lalu tekan sembarang area di layar.
- **Kelebihan:** Aplikasi akan membacakan teks yang tertangkap dengan jelas menggunakan *Text-to-Speech*.

### 4. Mode Navigasi (Placeholder)
- **Cara Kerja:** Dirancang untuk memberikan rute *turn-by-turn* menggunakan Google Maps API.
- **Tutorial:** Masuk ke mode Navigasi, masukkan tujuan lewat suara.
- **Catatan:** Fitur ini masih tahap *mock/placeholder* dalam versi saat ini.

---

## 🚀 Quick Start (Cara Menjalankan Proyek)

Karena proyek ini memiliki dua bagian (Backend dan Mobile), Anda harus menjalankan keduanya secara bersamaan.

### 1. Jalankan Backend (FastAPI)
Buka terminal baru dan jalankan perintah berikut:
```bash
# Masuk ke folder backend
cd backend

# Buat virtual environment dan aktifkan
python3 -m venv venv
source venv/bin/activate  # Untuk Windows: venv\Scripts\activate

# Install dependensi (ringan, ~100MB)
pip install -r requirements.txt

# Buat file .env dan isi API Key Anthropic Anda
echo "ANTHROPIC_API_KEY=sk-ant-..." > .env

# Jalankan server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
*Server akan berjalan di `http://localhost:8000` atau IP lokal Anda.*

### 2. Siapkan Model TFLite (WAJIB)
Karena alasan ukuran file, model **YOLO11n** tidak disertakan dalam repositori ini. Anda harus meletakkannya secara manual:
1. Jalankan script ini di **Google Colab** (agar tidak membuat disk lokal Anda penuh):
   ```python
   !pip install ultralytics
   from ultralytics import YOLO
   YOLO("yolo11n.pt").export(format="tflite", imgsz=320, half=False, int8=False)
   ```
2. Download file hasil konversinya (`yolo11n_float32.tflite`).
3. Ubah nama file menjadi **`yolo11n.tflite`**.
4. Pindahkan file tersebut ke folder: `guidio_app/assets/models/yolo11n.tflite`

### 3. Jalankan Aplikasi Mobile (Flutter)
Buka terminal baru (biarkan terminal backend tetap menyala):
```bash
# Masuk ke folder aplikasi
cd guidio_app

# Install dependensi flutter
flutter pub get

# Jalankan ke device yang terhubung (disarankan *real device* Android/iOS)
flutter run
```

---

## 📂 Struktur Repositori
- [`/guidio_app`](./guidio_app/): Berisi *source code* aplikasi mobile berbasis Flutter.
- [`/backend`](./backend/): Berisi *source code* server berbasis FastAPI untuk API OCR dan Narasi LLM.

Silakan baca `README.md` di masing-masing direktori untuk instruksi lengkap mengenai prasyarat instalasi, *storage*, dan cara menjalankannya.
