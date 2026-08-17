# GUIDIO — Panduan Verifikasi Fitur

> Jalankan langkah **Persiapan** terlebih dahulu sebelum masuk ke checklist fitur.
> Urutan penting — jangan loncat.

---

## Daftar isi

1. [Status kesiapan saat ini](#1-status-kesiapan-saat-ini)
2. [Persiapan wajib sebelum testing](#2-persiapan-wajib-sebelum-testing)
3. [Menjalankan backend](#3-menjalankan-backend)
4. [Menghubungkan HP ke backend](#4-menghubungkan-hp-ke-backend)
5. [Checklist verifikasi fitur](#5-checklist-verifikasi-fitur)
6. [Troubleshooting cepat](#6-troubleshooting-cepat)

---

## 1. Status kesiapan saat ini

### ✅ Sudah siap (100% lengkap)
| Komponen | Status | Ukuran |
|---|---|---|
| `transformers` Python | ✅ Terinstall | ~50 MB |
| `llama-cpp-python` (CPU) | ✅ Terinstall | ~21 MB |
| **Qwen2.5-1.5B GGUF** | ✅ Terdownload di `models/` | 1.12 GB |
| `ssd_mobilenet.tflite` (rintangan) | ✅ Ada di `assets/models/` | ~4.18 MB |
| `uang_rupiah.tflite` (kenali uang) | ✅ Ada di `assets/models/` | ~24.92 MB |
| FastAPI, Uvicorn, YOLO, Tesseract | ✅ Terinstall | ~300 MB |
| Tesseract bahasa `ind` + `eng` | ✅ Ada di `/usr/share/tesseract/` | - |
| `.env` file backend | ✅ Ada | - |
| Flutter analyze | ✅ Clean (0 error, 0 warning), siap build | - |

### ⏳ Tinggal dijalankan
| Komponen | Yang perlu dilakukan |
|---|---|
| PostgreSQL service | `sudo systemctl start postgresql` |
| **Moondream2** (~1.85 GB) | Auto-download otomatis saat panggil `/api/describe` pertama kali |

---

## 2. Persiapan wajib sebelum testing

### 2A. Install dependensi Python yang kurang

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
source venv/bin/activate

# Moondream2 (VLM — vision language model)
pip install "transformers>=4.40.0"

# Qwen2.5-1.5B lokal (CPU mode)
pip install llama-cpp-python

# Verifikasi
python -c "import transformers, llama_cpp; print('OK')"
```

### 2B. Download model Qwen (~1 GB)

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
mkdir -p models

# Download model Qwen via hf CLI
hf download Qwen/Qwen2.5-1.5B-Instruct-GGUF \
  qwen2.5-1.5b-instruct-q4_k_m.gguf \
  --local-dir models/

# Cek hasilnya
ls -lh models/
```

> Moondream2 tidak perlu download manual — dia akan otomatis download
> dari HuggingFace saat endpoint `/api/describe` pertama kali dipanggil (~1.85 GB).
> Proses ini butuh beberapa menit di koneksi normal (hanya sekali).

### 2C. Jalankan PostgreSQL

```bash
# Cek status
sudo systemctl status postgresql

# Jika belum jalan
sudo systemctl start postgresql

# Buat database jika belum ada (hanya sekali)
sudo -u postgres createdb vinara_dev 2>/dev/null || echo "DB sudah ada"
```

### 2D. Build APK Flutter (untuk HP fisik)

```bash
cd ~/kuliah/lomba/smstr6/guido/project/guidio_app
flutter pub get
flutter build apk --release

# Install ke HP yang tersambung USB
flutter install
```

---

## 3. Menjalankan backend

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
source venv/bin/activate

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Cek apakah startup sukses — harus muncul log seperti ini:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
[YOLO] Service terdaftar (lazy-load, belum dimuat).
[Moondream2] Service terdaftar (lazy-load, belum dimuat).
[Qwen] Service terdaftar (lazy-load): models/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

**Verifikasi cepat backend hidup:**
```bash
curl http://localhost:8000/health
# Harus balas: {"status": "ok", ...}

curl http://localhost:8000/api/capabilities
# Harus balas JSON daftar fitur yang aktif/terbatas
```

---

## 4. Menghubungkan HP ke backend

### Cara WiFi (paling mudah)

```bash
# Cari IP laptop di jaringan WiFi yang sama dengan HP
ip addr show | grep "inet " | grep -v "127.0.0"
# Contoh output: 192.168.1.5
```

Di HP, buka Guidio → ucapkan **"pengaturan"** → isi **Alamat Server**: `192.168.1.5:8000` → **Uji Sambungan** → **Simpan**.

### Cara USB (jika WiFi bermasalah)

```bash
adb reverse tcp:8000 tcp:8000
```

Di HP isi alamat server: `localhost:8000`

---

## 5. Checklist verifikasi fitur

Tandai tiap item setelah berhasil. Urutan dari yang paling sederhana.

---

### 🔵 GRUP A — Backend dasar (bisa ditest tanpa HP)

```bash
B=http://localhost:8000
```

**A-1. Health check**
```bash
curl -s $B/health
```
✅ Balas JSON dengan `status: ok` dan `elapsed_ms`

**A-2. Capabilities (status fitur)**
```bash
curl -s $B/api/capabilities | python3 -m json.tool
```
✅ JSON berisi tiap fitur dengan status `up`, `limited`, atau `down`

**A-3. Kamus label objek**
```bash
curl -s "$B/api/labels?lang=id" | head -20
```
✅ Daftar 52 nama benda Bahasa Indonesia

**A-4. Intent catalog**
```bash
curl -s $B/api/intent/catalog | python3 -m json.tool | head -30
```
✅ 20 perintah suara beserta variannya

---

### 🟢 GRUP B — OCR (Baca Teks)

**B-1. OCR dengan foto nyata**
```bash
# Ambil foto sembarang yang ada teksnya, misalnya foto buku
curl -s -X POST $B/api/ocr \
  --data-binary "@/path/ke/foto_teks.jpg" \
  -H "Content-Type: application/octet-stream"
```
✅ Balas dengan `text`, `confidence`, `estimated_spoken`
✅ `confidence` > 0 (ada teks terbaca)

**B-2. OCR dari HP** → Mode Baca Teks → arahkan ke teks → ambil gambar
✅ Hasil teks terbaca dan dibacakan via TTS

---

### 🟡 GRUP C — Asisten Suara / Intent

**C-1. Intent yang jelas**
```bash
curl -s -X POST $B/api/intent \
  -H "Content-Type: application/json" \
  -d '{"text": "kenali uang"}'
```
✅ `resolved: true`, `intent_key: "mode.money"`

**C-2. Intent ambigu (harus bertanya balik, bukan menebak)**
```bash
curl -s -X POST $B/api/intent \
  -H "Content-Type: application/json" \
  -d '{"text": "kenal kunci"}'
```
✅ `resolved: false`, `reason: "ambiguous"`, ada `message` yang bertanya balik

**C-3. Narasi YOLO**
```bash
curl -s -X POST $B/api/narasi \
  -H "Content-Type: application/json" \
  -d '{
    "detections": [
      {"label_id": "orang", "distance_meter": 0.8, "direction": "depan", "danger_level": "critical"},
      {"label_id": "motor", "distance_meter": 2.5, "direction": "kanan", "danger_level": "warning"}
    ],
    "context": "voice"
  }'
```
✅ Balas kalimat Bahasa Indonesia natural, maks 2 kalimat
✅ Jika Qwen ada: kalimat lebih natural (bukan template `"Ada orang di depan..."`)

---

### 🟠 GRUP D — Cari Objek

**D-1. Cari target yang ada di foto**
```bash
# Siapkan foto yang ada misalnya botol air
curl -s -X POST $B/api/cari-objek \
  -F "target=botol" \
  -F "file=@/path/ke/foto.jpg"
```
✅ `found: true` dengan posisi dan jarak
❎ `found: false, reason: not_in_frame` — normal jika objek memang tak ada

**D-2. Daftar target yang bisa dicari**
```bash
curl -s $B/api/cari-objek/targets
```
✅ Daftar nama benda Bahasa Indonesia

---

### 🔴 GRUP E — Navigasi jalur (3 zona)

**E-1. Segmentasi jalur**
```bash
curl -s -X POST $B/api/navigasi \
  -F "file=@/path/ke/foto_jalan.jpg"
```
✅ Balas `zones` dengan `kiri`, `tengah`, `kanan` masing-masing punya `status` dan `walkable_ratio`
✅ Ada `recommended` dan `message`
> `source: "heuristic"` itu normal — jika model PIDNet belum ada

**E-2. Status navigasi**
```bash
curl -s $B/api/navigasi/status
```
✅ Menjelaskan apakah pakai model atau heuristic

---

### 🟣 GRUP F — Deskripsi Suasana (Moondream2 + Qwen)

> ⚠️ Fitur ini memuat Moondream2 (~1.85 GB) — pemanggilan pertama kali butuh waktu beberapa menit untuk download bobot model.

**F-1. Uji endpoint describe**
```bash
curl -s -X POST $B/api/describe \
  -F "image=@/path/ke/foto.jpg"
```
✅ Balas `deskripsi` dalam Bahasa Indonesia
✅ Ada `caption_en` (hasil Moondream mentah Bahasa Inggris) untuk debugging

**F-2. Uji dari HP** → Mode Asisten Suara → ucapkan "deskripsikan"
✅ App merekam foto kamera, kirim ke backend, baca hasil via TTS

---

### 🏁 GRUP G — Fitur On-Device di HP (Tanpa Backend)

> Test ini bisa dilakukan tanpa backend menyala sama sekali.

**G-1. Deteksi Rintangan**
- Buka Guidio langsung → Mode Deteksi Objek sudah aktif
- Arahkan HP ke orang atau benda dekat (<3m)
✅ Ada suara + getar peringatan
✅ Kartu deteksi muncul di layar
✅ Delay antara deteksi dan suara <500ms

**G-2. Pengenalan Uang**
- Beralih ke Mode Kenali Uang
- Letakkan uang kertas (Rp 2.000 / 5.000 / 10.000 / 20.000 / 50.000 / 100.000) di bawah kamera, cahaya cukup, posisi rata
✅ Nominal disebutkan dalam 2 bentuk: angka + kata (contoh: "Rp 50.000, lima puluh ribu rupiah")
✅ Jika keyakinan rendah: hanya instruksi perbaikan, tidak menyebut nominal

**G-3. Tombol Mic Global (Jarvis Overlay)**
- Di mode Deteksi Objek, tekan tombol Mic (tengah bawah)
✅ VoiceScreen muncul sebagai overlay (bukan ganti layar)
✅ Ada tombol Kembali di atas BottomBar
✅ Ucapkan perintah mode → setelah dieksekusi, overlay hilang dan mode berganti

---

### 🎙️ GRUP H — Perintah Suara dari HP

Ucapkan masing-masing perintah dan cek apakah mode/aksi sesuai:

| Ucapan | Mode yang diharapkan |
|---|---|
| "deteksi" / "deteksi objek" | Mode Deteksi Objek |
| "uang" / "kenali uang" | Mode Kenali Uang |
| "baca" / "baca teks" | Mode Baca Teks |
| "navigasi" / "tuntun" | Mode Navigasi |
| "asisten" / "bicara" | Mode Asisten Suara |
| "cari dompet" | Mode Cari Objek, target dompet |
| "deskripsikan" / "apa yang ada di depanku" | Deskripsi suasana (trigger Moondream) |
| "lampu" / "nyalakan senter" | Senter menyala (ContextualActionSlot) |
| "pengaturan" | Layar Pengaturan |

✅ Tiap perintah dieksekusi dalam <2 detik
✅ TTS mengkonfirmasi mode yang aktif

---

## 6. Troubleshooting cepat

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| Backend startup error `psycopg.OperationalError` | PostgreSQL belum jalan | `sudo systemctl start postgresql` |
| `ModuleNotFoundError: transformers` | Package belum install | `pip install "transformers>=4.40.0"` |
| `ModuleNotFoundError: llama_cpp` | Package belum install | `pip install llama-cpp-python` |
| `[Qwen] File model tidak ditemukan` | GGUF belum didownload | Download dengan `hf download` (lihat bagian 2B) |
| Moondream loading lama | Pertama kali download model (~1.85 GB) | Tunggu sampai selesai (hanya sekali, selanjutnya cache) |
| HP tidak bisa reach backend | IP salah atau backend pakai localhost | Pastikan backend `--host 0.0.0.0`, isi IP laptop yang benar |
| Flutter `null check operator` crash | Provider belum siap | Pastikan `flutter pub get` sudah dijalankan |
| OCR hasil jelek | Foto buram / cahaya kurang | Perbaiki pencahayaan, pegang HP lebih stabil |
| Uang tidak terdeteksi | Keyakinan <0.85 | Dekatkan HP ke uang, cahaya merata, jangan ada bayangan |
