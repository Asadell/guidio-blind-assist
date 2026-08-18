# Vinara Backend (FastAPI)

Server untuk Vinara. Menangani pekerjaan yang tidak masuk akal dikerjakan di
ponsel: membaca tulisan, mencari barang dari kalimat bebas, memahami perintah
suara yang ambigu, dan membaca jalur trotoar.

**Hal pertama yang perlu dipahami:** dua dari enam mode **tidak pernah
memanggil server ini sama sekali**, yaitu Deteksi Objek dan Kenali Uang.
Itu keputusan sengaja, bukan kekurangan. Dan sekarang ditambah dua lagi:
**intent parsing** dan **narasi deteksi** juga dikerjakan lokal di Flutter —
tanpa server, tanpa LLM.

> **Tidak ada LLM di backend ini.** `QwenService` dan `narasi.py` telah
> dihapus. Narasi dikerjakan oleh `narration_engine.dart` di Flutter.
> Intent parsing dikerjakan oleh `CommandParser` di Flutter.

---

## Daftar isi

1. [Menjalankan](#1-menjalankan)
2. [Pembagian tugas: on-device vs server](#2-pembagian-tugas-on-device-vs-server)
3. [Rujukan endpoint](#3-rujukan-endpoint)
4. [Basis data](#4-basis-data)
5. [Prinsip yang dipegang server ini](#5-prinsip-yang-dipegang-server-ini)
6. [Struktur folder](#6-struktur-folder)
7. [Keterbatasan yang perlu diketahui](#7-keterbatasan-yang-perlu-diketahui)
8. [Uji cepat](#8-uji-cepat)
9. [Koneksi HP ke Backend Laptop](#9-koneksi-hp-ke-backend-laptop)
10. [Ukuran Model dan Kebutuhan Storage](#10-ukuran-model-dan-kebutuhan-storage)

---

## 1. Menjalankan

### Prasyarat

**Tesseract**, mesin pembaca tulisan. Ini program sistem, bukan paket Python:

```bash
sudo dnf install -y tesseract tesseract-langpack-ind tesseract-langpack-eng
```

Paket `tesseract-langpack-ind` penting — OCR dipanggil dengan bahasa `ind+eng`.

**PostgreSQL** yang sedang berjalan, lalu buat basis datanya sekali saja:

```bash
createdb -h localhost -U postgres vinara_dev
```

### Langkah menjalankan

```bash
cd backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt

cp .env.example .env  # isi kredensial PostgreSQL

venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Tabel basis data dibuat otomatis saat startup (aman diulang berkali-kali),
lalu data rujukan diisi: 52 label objek, 20 intent suara beserta variannya,
7 denominasi uang, dan manifest model.

Dokumentasi endpoint interaktif: `http://localhost:8000/docs`

**Kalau PostgreSQL mati, server tetap jalan.** Endpoint yang membutuhkan
basis data membalas dengan pesan yang menyebutkan apa yang masih berfungsi.

---

## 2. Pembagian tugas: on-device vs server

| Fitur | Diproses di mana | Endpoint |
|---|---|---|
| Deteksi Objek | **Flutter** (TFLite on-device) | `WS /ws/detect`, `POST /api/detect` |
| Kenali Uang | **Flutter** (TFLite on-device) | `POST /api/uang` (opsional) |
| Intent parsing | **Flutter** (`CommandParser`, offline) | `POST /api/intent` (hanya fallback ambigu) |
| Narasi deteksi | **Flutter** (`narration_engine.dart`, offline) | ~~`/api/narasi`~~ (dihapus) |
| Baca Teks | Server | `POST /api/ocr` |
| Deskripsi suasana | Server (Moondream2 VLM) | `POST /api/describe` |
| Cari Objek | Server (YOLOE) | `POST /api/cari-objek` |
| Navigasi jalur | Server, rintangan tetap di Flutter | `POST /api/navigasi` |

### Cari Objek: kenapa memakai YOLOE

Model pengenalan benda biasa hanya bisa mengenali daftar benda yang sudah
ditentukan saat pelatihan. Masalahnya, target pencarian datang dari ucapan
pengguna dan bisa apa saja: "dompet", "kunci motor", "tas merah".

YOLOE menerima **prompt teks bebas**, jadi bisa mencari benda yang tidak
pernah diajarkan secara khusus. Nama barang Bahasa Indonesia diterjemahkan
dulu ke Inggris memakai tabel `object_labels` ditambah kamus bawaan.

Model dimuat **saat permintaan pertama**, bukan saat startup. Panggilan
pertama memakan sekitar 2 detik, sesudahnya cepat.

### Navigasi: tiga zona jalur

Gambar dari kamera dibagi menjadi tiga bagian (kiri, tengah, kanan), lalu
masing-masing dinilai seberapa layak dilewati.

Model utamanya PIDNet-S. Kalau berkas modelnya belum ada, server memakai
**cadangan berbasis pengolahan citra**: permukaan yang bisa dijalani umumnya
rata dan warnanya konsisten.

> Mode Navigasi **tidak pernah dimatikan saat offline.** Deteksi rintangannya
> berjalan di Flutter dan tetap hidup. Status terburuknya adalah `limited`.

### Deskripsi suasana: Moondream2

`POST /api/describe` mengembalikan `description_en` — caption Bahasa Inggris
langsung dari Moondream2. Flutter membacakannya dengan TTS locale `en-US`
tanpa terjemahan tambahan. Tidak ada LLM terjemahan di tengah alur ini.

---

## 3. Rujukan endpoint

### Fitur utama

#### `POST /api/ocr`

Membaca tulisan dari gambar. Kirim JPEG mentah sebagai isi permintaan.

```json
{
  "text": "Menu Warung Bu Sari\nAyam goreng 15000",
  "lines": ["Menu Warung Bu Sari", "Ayam goreng 15000"],
  "confidence": 0.96,
  "word_count": 15,
  "estimated_seconds": 6.9,
  "estimated_spoken": "sekitar 7 detik",
  "is_long": false,
  "is_very_long": false
}
```

#### `POST /api/describe`

Deskripsikan suasana kamera via Moondream2. Kirim `file` (JPEG).

```json
{
  "description_en": "A person walking on a sidewalk near a parked bicycle.",
  "model": "moondream2",
  "length": "short"
}
```

Flutter langsung membacakan `description_en` dengan TTS `en-US`.

#### `POST /api/cari-objek`

Kirim `target` (nama barang Bahasa Indonesia) dan `file` (gambar JPEG).

```json
{
  "found": true,
  "message": "dompet di kiri, sekitar satu meter.",
  "total_match": 1,
  "nearest": {
    "direction": "kiri",
    "distance_meter": 1.1,
    "confidence": 0.72
  },
  "prompt_en": "wallet"
}
```

`GET /api/cari-objek/targets` mengembalikan daftar barang yang dikenali.

#### `POST /api/navigasi`

Kirim `file` (gambar JPEG), opsional `lat` dan `lng`.

```json
{
  "ok": true,
  "source": "heuristic",
  "zones": {
    "kiri":   {"status": "caution", "walkable_ratio": 0.466},
    "tengah": {"status": "safe",    "walkable_ratio": 0.998},
    "kanan":  {"status": "caution", "walkable_ratio": 0.469}
  },
  "recommended": "tengah",
  "message": "Tetap di tengah."
}
```

#### `POST /api/intent`

Memahami perintah suara yang **tidak dikenali** `CommandParser` lokal di
Flutter. Server hanya dipanggil untuk dua kasus:

- **Ambigu** — dua kemungkinan sama-sama masuk akal → server bertanya balik
- **Tidak dikenali** — server menawarkan dua tebakan terdekat

Urutan usahanya: cocokkan frasa persis (Lapis 1) → skor kemiripan kata
(Lapis 2). **Tidak ada LLM** — Lapis 3 telah dihapus.

```json
POST {"text": "kenal kunci"}

{
  "resolved": false,
  "reason": "ambiguous",
  "message": "Saya dengar kenal kunci. Maksudmu cari kunci, atau kenali uang?"
}
```

#### `POST /api/uang` (opsional)

Jalur utama fitur ini ada di Flutter. Endpoint ini hanya untuk pembanding.

```json
{
  "detected": false,
  "reason": "model_unavailable",
  "message": "Pengenalan uang di server belum aktif. Mode Kenali Uang berjalan di perangkat tanpa internet."
}
```

### Endpoint penunjang

| Endpoint | Kegunaan |
|---|---|
| `GET /health` | Cek server hidup, melaporkan waktu tempuh |
| `GET /api/capabilities` | Mode mana yang hidup, ditanyakan sebelum tombol ditekan |
| `GET /api/labels` | Kamus nama benda dalam Bahasa Indonesia |
| `GET /api/models/manifest` | Versi model yang ada di ponsel |
| `POST /api/models/rescan` | Pindai folder `models/`, hitung sidik jari berkas |
| `POST /api/events` | Telemetri alur pemakaian |
| `GET /api/events/summary` | Ringkasan telemetri |
| `POST /api/crash-report` | Laporan aplikasi berhenti mendadak |
| `GET /api/crash-report/last-mode` | Mode terakhir sebelum berhenti |
| `POST /api/queue/flush` | Kirim ulang gambar yang tertahan saat offline |
| `GET /api/intent/catalog` | 20 perintah suara beserta variannya |
| `POST /api/asisten/turn` | Simpan satu giliran percakapan |
| `GET /api/asisten/history` | Ambil riwayat percakapan |

---

## 4. Basis data

Sembilan kelompok tabel di PostgreSQL. **Tanpa autentikasi** — identifikasi
cukup memakai `device_id` anonim yang dibuat aplikasi sendiri.

| Tabel | Isi |
|---|---|
| `risk_zones` | Lokasi yang sering dilaporkan ada hambatan |
| `object_labels` | Nama benda dalam Bahasa Indonesia, tinggi nyata, tingkat bahaya |
| `voice_intents`, `intent_phrases` | 20 perintah suara dan variannya |
| `model_manifest` | Versi model yang dipakai ponsel |
| `telemetry_events` | Telemetri alur |
| `crash_reports` | Laporan aplikasi berhenti mendadak |
| `upload_queue` | Antrean unggah offline (kunci idempotensi wajib) |
| `assistant_sessions`, `assistant_turns` | Riwayat percakapan |
| `money_denominations` | Pecahan uang, kata terbilang, urutan kelas model |
| `capability_overrides` | Paksa status fitur, untuk demo atau perawatan |

---

## 5. Prinsip yang dipegang server ini

**Server tidak menyaring deteksi.** Ia mengirim hasil mentah. Seluruh
penyaringan ada di Flutter supaya hasil TFLite dan YOLO melewati aturan
yang sama persis.

**Tidak ada jalan buntu.** Setiap kegagalan membawa pesan yang menyebutkan
apa yang masih berfungsi, lalu satu tindakan berikutnya.

**Tidak ada kegagalan yang menjatuhkan server.** Model gagal dimuat, basis
data mati: semuanya dilaporkan lewat `/api/capabilities`, dan server tetap
melayani sisanya.

**Jujur soal kemampuan.** Kalau segmentasi jalur sedang memakai cadangan
sederhana, itu disebutkan di kolom `source`.

**Tidak ada LLM.** Semua teks natural — narasi deteksi dan resolusi intent —
dikerjakan di sisi Flutter, offline, tanpa latensi jaringan.

---

## 6. Struktur folder

```
backend/
├── main.py                  Titik masuk, memuat semua service saat startup
├── .env                     Konfigurasi (tidak ikut ke git)
├── .env.example             Contoh konfigurasi
├── db/
│   ├── database.py          Koneksi PostgreSQL
│   ├── schema.sql           Definisi tabel
│   └── seed.py              Data rujukan: label, intent, denominasi
├── routers/
│   ├── websocket.py         Deteksi aliran waktu nyata
│   ├── detect.py            Deteksi sekali jalan
│   ├── ocr.py               Baca teks
│   ├── describe.py          Deskripsi suasana via kamera (Moondream2, output EN)
│   ├── cari_objek.py        Pencarian barang dengan prompt teks
│   ├── navigasi.py          Segmentasi jalur tiga zona
│   ├── uang.py              Pengenalan uang (opsional, jalur utama on-device)
│   ├── asisten.py           Perintah suara ambigu dan riwayat percakapan
│   ├── voice_router.py      /api/route-intent legacy (keyword-only, tanpa LLM)
│   ├── risk_zone.py         Zona rawan
│   └── support.py           Kemampuan, label, manifest, telemetri, antrean
├── services/
│   ├── yolo_service.py         Deteksi rintangan server
│   ├── find_object_service.py  YOLOE prompt teks
│   ├── segmentation_service.py PIDNet dan cadangan heuristik
│   ├── ocr_service.py          Tesseract dan estimasi durasi baca
│   ├── intent_service.py       Pencocokan frasa + similarity (Lapis 1 & 2)
│   ├── uang_service.py         Pengenalan uang di server
│   ├── risk_zone_service.py    Zona rawan
│   ├── camera_health.py        Pemeriksaan kondisi kamera
│   ├── moondream_service.py    Deskripsi scene via kamera (VLM, output EN)
│   └── repository.py           Seluruh akses basis data
└── utils/
    └── image_utils.py       Bantuan konversi gambar
```

> `narasi.py` dan `qwen_service.py` telah **dihapus**. Tidak ada file LLM
> di folder ini.

---

## 7. Keterbatasan yang perlu diketahui

1. **Model PIDNet-S belum ada.** Navigasi memakai cadangan heuristik OpenCV
   yang cukup untuk menguji seluruh tampilan. Letakkan
   `models/pidnet_s_3zona.onnx` untuk mengaktifkan jalur model.

2. **Model uang di server memang tidak ada, dan itu disengaja.** Jalur utama
   fitur ini di Flutter.

3. **Model uang di Flutter hanya mengenali 6 pecahan emisi 2016.** Rp1.000
   belum dikenali.

4. **Berkas model besar tidak ikut ke git** (`yoloe-v8l-seg.pt`,
   `yolo11l_float32.tflite`, dan berkas `.pt`/`.onnx` lainnya). Ultralytics
   mengunduhnya otomatis saat pertama dipakai.

---

## 8. Uji cepat

```bash
B=http://localhost:8000

curl -s $B/health
curl -s $B/api/capabilities
curl -s "$B/api/labels?lang=id"

# Perintah ambigu: seharusnya bertanya balik, bukan menebak
curl -s -X POST $B/api/intent -H 'Content-Type: application/json' \
     -d '{"text":"kenal kunci"}'

# Baca teks
curl -s -X POST $B/api/ocr --data-binary "@foto.jpg" \
     -H "Content-Type: application/octet-stream"

# Deskripsi suasana (output English)
curl -s -X POST $B/api/describe -F "file=@foto.jpg"

# Cari barang (panggilan pertama memuat model, ~2 detik)
curl -s -X POST $B/api/cari-objek -F "target=dompet" -F "file=@foto.jpg"

# Jalur tiga zona
curl -s -X POST $B/api/navigasi -F "file=@foto.jpg" -F "lat=0" -F "lng=0"
```

---

## 9. Koneksi HP ke Backend Laptop

### Cara paling mudah: WiFi satu jaringan

```bash
# Laptop
uvicorn main:app --host 0.0.0.0 --port 8000
ip addr show   # cari wlan0, contoh: 192.168.1.5
```

Di HP: buka Guidio → ucapkan **"pengaturan"** → isi `192.168.1.5:8000` →
**Uji Sambungan** → **Simpan**.

### Cara alternatif: USB (ADB reverse)

```bash
adb reverse tcp:8000 tcp:8000
```

Isi alamat server di Guidio: `localhost:8000`

### Troubleshooting koneksi

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| "Tidak bisa menjangkau server" | Salah IP atau belum `--host 0.0.0.0` | Cek `ip addr show`, restart backend |
| Koneksi timeout | Firewall memblokir port 8000 | `sudo firewall-cmd --add-port=8000/tcp --permanent` |
| HP dan laptop beda WiFi | Isolasi client jaringan kampus | Pakai metode USB |
| IP laptop berubah | DHCP | Set IP statis atau pakai ADB reverse |

---

## 10. Ukuran Model dan Kebutuhan Storage

| Kategori | Komponen | Ukuran | Eksekusi | Keterangan |
|---|---|---|---|---|
| **Mobile** | `ssd_mobilenet.tflite` | ~4.18 MB | On-Device CPU | Deteksi rintangan |
| **Mobile** | `uang_rupiah.tflite` | ~24.92 MB | On-Device CPU | Klasifikasi uang |
| **Backend VLM** | `vikhyatk/moondream2` | ~1.85 GB | Laptop GPU | Deskripsi suasana (FP16) |
| **Backend Deteksi** | `yolo11n.pt` | ~5.5 MB | Laptop GPU | Deteksi server |
| **Backend Cari Objek** | `yoloe-11s-seg.pt` | ~30 MB | Laptop GPU | Open-vocabulary |
| **Dependensi Python** | PyTorch + CUDA | ~1.8 GB | Disk | Runtime CUDA |
| **Dependensi Python** | Transformers, OpenCV, FastAPI | ~300 MB | Disk | Framework |

### Ringkasan

- **Model di HP:** `~29.1 MB`
- **Model Backend (download):** `~1.9 GB` *(Moondream ~1.85 GB + YOLO ~50 MB)*
- **Virtualenv Python:** `~2.1 GB`
- **Total:** `~4.0 GB`

### Alokasi VRAM (RTX 3050 4 GB)

```
Moondream2 FP16  ~1.2 GB
YOLO/YOLOE       ~0.5 GB
─────────────────────────
Total            ~1.7 GB  (dari 4 GB — aman)
```

Tidak ada LLM. Tidak ada `llama-cpp-python`. VRAM yang tersisa (~2.3 GB)
bebas untuk kebutuhan lain.
