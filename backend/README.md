# Guidio Backend (FastAPI)

Backend Guidio bertugas menangani pemrosesan berat yang tidak cocok dijalankan di perangkat mobile. Ini mencakup fungsi-fungsi penting seperti **Optical Character Recognition (OCR)** dan **Pembuatan Narasi AI** menggunakan LLM (Claude Haiku).

## Kebutuhan Sistem & Persiapan Storage (PENTING!)
Terdapat dua mode penggunaan pada backend ini: **Mode Server** (wajib) dan **Mode Export TFLite** (opsional). Anda harus memperhatikan kapasitas *storage* laptop Anda!

### 1. Kebutuhan Storage: Export TFLite (Opsional - Hati-hati!)
Jika Anda memutuskan untuk melakukan konversi model `.pt` ke `.tflite` di laptop ini secara manual (dengan menjalankan `export_tflite.py`), **Anda wajib menyiapkan setidaknya 5 GB ruang kosong di disk Anda.** 

Proses export akan men-download dan meng-install library berukuran raksasa, meliputi:
- **TensorFlow** & Keras (~570 MB)
- **PyTorch** (~532 MB)
- **NVIDIA CUDA Toolkits** (cuDNN, cuBLAS, cusparse, dll - Ber-Gigabyte)

Selain itu, **Export TensorFlow WAJIB menggunakan Python maksimal versi 3.12** (misalnya `python3.12`), karena TensorFlow tidak mendukung Python versi di atasnya (seperti 3.13 atau 3.14). Jika Anda tidak punya *space* disk sebesar ini, instalasi akan *error OSError: [Errno 28] No space left on device*.
*(Rekomendasi Terbaik: Gunakan **Google Colab** untuk melakukan export agar storage laptop Anda aman).*

### 2. Kebutuhan Storage: Menjalankan Server FastAPI (Aman)
Menjalankan server API hanya membutuhkan library yang sangat ringan (FastAPI, Uvicorn, Anthropic, Loguru, Pytesseract). **Proses ini sangat aman dan hanya memakan sekitar 100-200 MB.**

## Cara Instalasi & Menjalankan Server
1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Buat Virtual Environment (Bisa pakai Python versi berapapun yang ada di OS Anda, misal Python 3.14):
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependensi server (ringan & aman):
   ```bash
   pip install -r requirements.txt
   ```
4. Buat file `.env` di dalam folder `backend` ini dan masukkan kredensial API Key Anda:
   ```env
   ANTHROPIC_API_KEY=sk-ant-api03-...
   ```
5. Jalankan server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

Aplikasi Flutter (Guidio App) akan otomatis terhubung ke port `8000` laptop Anda ini.
