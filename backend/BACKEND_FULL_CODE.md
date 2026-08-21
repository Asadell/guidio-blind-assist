# Code Document: backend
> Base Path: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend`
> Total Files: 37

## Table of Contents

- [README.md](#file-readmemd)
- [_archive/routers/asisten.py](#file-archiveroutersasistenpy)
- [_archive/routers/detect.py](#file-archiveroutersdetectpy)
- [_archive/routers/navigasi.py](#file-archiveroutersnavigasipy)
- [_archive/routers/ocr.py](#file-archiveroutersocrpy)
- [_archive/routers/risk_zone.py](#file-archiveroutersriskzonepy)
- [_archive/routers/support_full.py](#file-archiverouterssupportfullpy)
- [_archive/routers/uang.py](#file-archiveroutersuangpy)
- [_archive/routers/voice_router.py](#file-archiveroutersvoicerouterpy)
- [_archive/routers/websocket.py](#file-archiverouterswebsocketpy)
- [_archive/services/camera_health.py](#file-archiveservicescamerahealthpy)
- [_archive/services/intent_service.py](#file-archiveservicesintentservicepy)
- [_archive/services/ocr_service.py](#file-archiveservicesocrservicepy)
- [_archive/services/risk_zone_service.py](#file-archiveservicesriskzoneservicepy)
- [_archive/services/segmentation_service.py](#file-archiveservicessegmentationservicepy)
- [_archive/services/uang_service.py](#file-archiveservicesuangservicepy)
- [_archive/services/yolo_service.py](#file-archiveservicesyoloservicepy)
- [compass_artifact_wf-6faa4e5a-1dfa-5f2a-b75b-7ac36d56a1d7_text_markdown.md](#file-compassartifactwf-6faa4e5a-1dfa-5f2a-b75b-7ac36d56a1d7textmarkdownmd)
- [db/database.py](#file-dbdatabasepy)
- [db/schema.sql](#file-dbschemasql)
- [db/seed.py](#file-dbseedpy)
- [export_tflite.py](#file-exporttflitepy)
- [main.py](#file-mainpy)
- [requirements.txt](#file-requirementstxt)
- [routers/cari_objek.py](#file-routerscariobjekpy)
- [routers/describe.py](#file-routersdescribepy)
- [routers/support.py](#file-routerssupportpy)
- [services/find_object_constants.py](#file-servicesfindobjectconstantspy)
- [services/find_object_service.py](#file-servicesfindobjectservicepy)
- [services/moondream_service.py](#file-servicesmoondreamservicepy)
- [services/repository.py](#file-servicesrepositorypy)
- [tests/__init__.py](#file-testsinitpy)
- [tests/conftest.py](#file-testsconftestpy)
- [tests/test_cari_objek.py](#file-teststestcariobjekpy)
- [tests/test_describe.py](#file-teststestdescribepy)
- [tests/test_health.py](#file-teststesthealthpy)
- [utils/image_utils.py](#file-utilsimageutilspy)

---

## File: `README.md`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/README.md`

```markdown
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
9. [Testing Backend (pytest)](#9-testing-backend-pytest)
10. [Koneksi HP ke Backend Laptop](#10-koneksi-hp-ke-backend-laptop)
11. [Ukuran Model dan Kebutuhan Storage](#11-ukuran-model-dan-kebutuhan-storage)

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

## 9. Testing Backend (pytest)

Suite pengujian otomatis untuk semua endpoint backend menggunakan `pytest` +
`httpx` (via `TestClient` FastAPI — tidak perlu server menyala).

### Instalasi

```bash
cd backend
source venv/bin/activate
pip install pytest pytest-asyncio httpx
```

### Menjalankan

```bash
# Semua test sekaligus
python -m pytest tests/ -v

# Per file
python -m pytest tests/test_health.py -v
python -m pytest tests/test_cari_objek.py -v
python -m pytest tests/test_describe.py -v

# Satu test spesifik
python -m pytest tests/test_cari_objek.py::TestCariObjekInvalidInput -v
```

### Struktur test

```
backend/tests/
├── conftest.py              Shared fixtures (TestClient, gambar navigasi, gambar objek)
├── fixtures/
│   ├── navigation/          5 gambar hazard (got, lubang, tiang, motor+orang, tangga)
│   └── object_find/         5 gambar benda (tas, kunci, botol, headphone, payung)
├── test_health.py           GET /health + GET /api/capabilities  (12 test)
├── test_cari_objek.py       POST /api/cari-objek + GET /targets  (14 test)
└── test_describe.py         POST /api/describe (Moondream2 VLM)  (10 test)
```

### Ringkasan cakupan

| File | Skenario yang diuji |
|---|---|
| `test_health.py` | Status `ok`, semua field ada, uptime > 0, latensi < 500 ms, 6 mode capabilities, mode on-device selalu `up` |
| `test_cari_objek.py` | Struktur respons, bytes kosong/rusak tidak crash, target tidak ada di frame, `/targets` endpoint |
| `test_describe.py` | `description_en` ada, bukan Bahasa Indonesia, invalid image tidak 500, validasi caption motor+orang dan got terbuka |

### Catatan: simulasi kamera HP

Semua gambar fixture dikirim ke backend sebagai `multipart/form-data` dengan
`Content-Type: image/png` — **byte-for-byte identik** dengan yang dikirim
Flutter saat user mengarahkan kamera. Backend tidak membedakan sumber gambar.

```
Flutter (kamera) ──┐
                   ├──▶ POST /api/cari-objek  (multipart/form-data)
tests/fixtures  ───┘         ↑ identik
```

### Catatan: test Moondream otomatis skip

Test di `TestDescribeKonten` (validasi isi caption) otomatis di-skip jika
Moondream belum warm. Jalankan backend dulu lalu tunggu request pertama selesai
sebelum menjalankan test tersebut, atau jalankan dengan backend menyala:

```bash
# Terminal 1
uvicorn main:app --host 0.0.0.0 --port 8000

# Terminal 2 — setelah backend siap
python -m pytest tests/test_describe.py -v
```

### Hasil terakhir (2026-08-20)

```
32 passed, 4 skipped — 44.80s
```

4 test di-skip adalah validasi isi caption Moondream (membutuhkan model warm).

---

## 10. Koneksi HP ke Backend Laptop

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

## 11. Ukuran Model dan Kebutuhan Storage

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
```

---

## File: `_archive/routers/asisten.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/asisten.py`

```python
"""Mode Asisten Suara — resolusi perintah + riwayat percakapan.

  POST /api/intent            resolusi perintah suara (AS-17/18/19)
  GET  /api/intent/catalog    20 intent baku + varian ucapannya
  POST /api/asisten/turn      simpan giliran percakapan
  GET  /api/asisten/history   ambil riwayat (AS-12/13)
  POST /api/asisten/expire    bersihkan sesi kedaluwarsa (AS-23)

CommandParser lokal di Flutter tetap jalan lebih dulu dan tidak butuh
internet. Endpoint /api/intent hanya dipanggil saat lokal tidak match.
"""

from fastapi import APIRouter, Request
from pydantic import BaseModel

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["asisten"])


class IntentRequest(BaseModel):
    text: str
    device_id: str | None = None


@router.get("/intent/catalog")
async def intent_catalog():
    """20 intent baku beserta varian ucapan — aplikasi bisa menyinkronkan
    CommandParser lokalnya tanpa rilis ulang."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "intents": []}
    intents = repo.get_all_intents()
    return {"total": len(intents), "intents": intents}


@router.post("/intent")
async def resolve_intent(request: Request, body: IntentRequest):
    """Petakan ucapan ke satu intent.

    Urutan usaha: frasa persis → skor kemiripan → LLM. Kalau tidak ada yang
    yakin, balasannya TETAP menawarkan dua tebakan terdekat, bukan
    "perintah gagal" — prinsip tidak ada jalan buntu.
    """
    svc = request.app.state.intent_service
    text = body.text.strip()
    if not text:
        return {
            "resolved": False,
            "reason": "empty",
            "message": "Belum terdengar apa pun.",
            "suggestions": [],
        }

    if not svc.available:
        return {
            "resolved": False,
            "reason": "catalog_unavailable",
            "message": "Daftar perintah belum termuat di server.",
            "suggestions": [],
        }

    # Lapis 1 — frasa persis.
    exact = svc.match_exact(text)
    if exact:
        return _intent_payload(svc, exact, text, resolved=True)

    # Lapis 2 — kumpulkan kandidat: kemiripan frasa + nama barang yang bisa
    # dicari. Ucapan seperti "kenal kunci" menghasilkan DUA kandidat
    # ("cari kunci" dan "kenali uang"), dan itu memang harus ditanyakan
    # balik, bukan ditebak.
    candidates = svc.rank_candidates(text, limit=2)
    find_cand = svc.find_object_candidate(text)
    if find_cand and not any(c["intent_key"] == "mode.findObject" for c in candidates):
        candidates = ([find_cand] + candidates)[:2]

    strong = [c for c in candidates if c["confidence"] >= 0.8]
    if len(strong) == 1 and len(candidates) == 1:
        return _intent_payload(svc, {**strong[0], "source": "similarity"}, text, resolved=True)

    # AS-19 — dua kandidat yang sama-sama masuk akal: tanya balik.
    # Menebak salah lebih mahal daripada satu pertanyaan.
    if len(candidates) >= 2:
        return {
            "resolved": False,
            "reason": "ambiguous",
            "heard": text,
            "message": svc.compose_suggestion(text, candidates),
            "suggestions": candidates,
        }

    # AS-18 — tidak dikenali: sebut yang didengar, tawarkan tebakan terdekat.
    # (Lapis 3 LLM dihapus — tidak ada LLM di backend)
    return {
        "resolved": False,
        "reason": "unrecognized",
        "heard": text,
        "message": svc.compose_suggestion(text, candidates),
        "suggestions": candidates,
    }


def _intent_payload(svc, intent: dict, text: str, resolved: bool) -> dict:
    payload = {
        "resolved": resolved,
        "intent_key": intent["intent_key"],
        "category": intent["category"],
        "spoken_label": intent["spoken_label"],
        "confidence": intent.get("confidence", 1.0),
        "source": intent.get("source", "phrase"),
        "heard": text,
    }
    # "cari dompet" → target dinamis untuk Mode Cari Objek.
    if intent["intent_key"] == "mode.findObject":
        target = svc.extract_find_target(text)
        if target:
            payload["argument"] = target
    return payload


# ── Riwayat percakapan ───────────────────────────────────────────────────


class TurnIn(BaseModel):
    session_id: str
    device_id: str
    role: str  # user | vinara
    text: str
    intent_key: str | None = None


@router.post("/asisten/turn")
async def add_turn(body: TurnIn):
    if not is_available():
        return {"ok": False, "reason": "database_unavailable"}
    repo.touch_session(body.session_id, body.device_id)
    repo.add_turn(body.session_id, body.role, body.text, body.intent_key)
    return {"ok": True}


@router.get("/asisten/history")
async def history(session_id: str, limit: int = 20):
    """AS-12 / AS-13 — riwayat percakapan. Aplikasi yang memutuskan hanya
    giliran terbaru yang dibacakan; yang lama cukup tampil."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "turns": []}
    if repo.session_expired(session_id):
        return {
            "ok": True,
            "expired": True,
            "turns": [],
            "message": "Percakapan tadi sudah saya hapus.",
        }
    return {"ok": True, "expired": False, "turns": repo.get_turns(session_id, limit)}


@router.post("/asisten/expire")
async def expire_sessions():
    """AS-23 — sesi menganggur lebih dari 15 menit dibersihkan."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable"}
    return {"ok": True, "expired_sessions": repo.expire_stale_sessions()}
```

---

## File: `_archive/routers/detect.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/detect.py`

```python
import cv2
import numpy as np
from fastapi import APIRouter, Request
from loguru import logger

router = APIRouter(prefix="/api", tags=["detect"])


@router.post("/detect")
async def detect_once(request: Request):
    """
    Single-shot inference untuk Voice Assistant — 'Ada apa di sekitar saya?'
    Flutter kirim raw JPEG bytes di body.
    Return: raw detections saja (narasi ada di /api/narasi).
    """
    body  = await request.body()
    arr   = np.frombuffer(body, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)

    if frame is None:
        return {"detections": [], "total": 0, "error": "Frame tidak valid"}

    svc        = request.app.state.yolo_service
    detections = svc.infer(frame)

    logger.info(f"detect_once: {len(detections)} deteksi")
    return {"detections": detections, "total": len(detections)}
```

---

## File: `_archive/routers/navigasi.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/navigasi.py`

```python
"""Mode Navigasi — POST /api/navigasi (segmentasi jalur 3 zona + rintangan).

Sejak deteksi rintangan dipindah dari perangkat ke server, endpoint ini
mengembalikan **keduanya dari satu frame**: status tiga zona jalur DAN daftar
rintangan di depan. Menggabungkannya di sini disengaja — aplikasi kalau tidak
harus mengunggah frame yang sama dua kali ke dua endpoint, dan itu menggandakan
pemakaian kuota serta latensi pada mode yang dipakai sambil berjalan.

Konsekuensi yang harus disadari: kalau endpoint ini tidak terjangkau, Mode
Navigasi tidak punya cadangan apa pun. Aplikasi menyuruh pengguna berhenti
berjalan, bukan melanjutkan dengan "mode terbatas".
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["navigasi"])

GRID_PRECISION = 4  # ~11 meter per sel
RISK_RADIUS_M = 30.0
RISK_MIN_COUNT = 3


@router.post("/navigasi")
async def navigasi(
    request: Request,
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    lat: float = Form(0.0),
    lng: float = Form(0.0),
):
    """Bagi frame jadi tiga zona jalur dan sebut mana yang layak dilewati.

    Kalau `lat`/`lng` diisi, sekalian cek zona rawan dari laporan pengguna
    lain (Risk Zone) — itu informasi yang tidak terlihat kamera.
    """
    raw = await file.read()
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "ok": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca.",
            "zones": None,
            "recommended": None,
        }

    svc = request.app.state.segmentation_service
    result = svc.zones(frame)

    # Rintangan dari frame yang SAMA. Prioritas suara di aplikasi menaruh
    # rintangan di atas zona — jaraknya lebih dekat dan lebih mendesak — jadi
    # keduanya harus datang bersamaan, bukan dari dua permintaan yang bisa
    # tiba dengan selisih waktu.
    yolo = getattr(request.app.state, "yolo_service", None)
    if yolo is not None and yolo.loaded:
        try:
            # Pakai model navigasi custom (6 kelas) jika sudah dilatih.
            # Fallback otomatis ke COCO jika model custom belum tersedia.
            result["obstacles"] = yolo.infer(frame, mode="navigasi")
        except Exception as e:
            logger.warning(f"Deteksi rintangan gagal: {e}")
            result["obstacles"] = []
    else:
        result["obstacles"] = []

    # Risk Zone dari laporan komunitas (opsional, butuh koordinat).
    if lat != 0.0 and lng != 0.0 and is_available():
        try:
            zone = repo.risk_zone_nearby(lat, lng, RISK_RADIUS_M, RISK_MIN_COUNT)
            if zone and zone["distance_m"] <= RISK_RADIUS_M:
                labels = zone["labels"] or {}
                common = max(labels, key=labels.get) if labels else None
                result["risk_zone"] = {
                    "distance_meter": round(float(zone["distance_m"]), 1),
                    "count": zone["report_count"],
                    "common_label": common,
                    "warning": "Area ini sering ada hambatan, hati-hati",
                }
        except Exception as e:
            logger.warning(f"Cek risk zone gagal: {e}")

    return result


@router.get("/navigasi/status")
async def navigasi_status(request: Request):
    """Apakah segmentasi jalur memakai model sungguhan atau fallback.

    Aplikasi memakai ini untuk memutuskan NV-11 (mode terbatas) dan untuk
    menyebut dengan jujur fitur mana yang sedang hilang.
    """
    svc = request.app.state.segmentation_service
    return {
        "loaded": svc.loaded,
        "source": svc.source,
        "model_path": svc.model_path,
        "input_size": svc.input_size,
        "note": (
            "Model PIDNet-S aktif."
            if svc.loaded
            else "Model belum ada — memakai fallback heuristik OpenCV. "
                 "Arahan jalur tetap keluar, tapi akurasinya di bawah model terlatih."
        ),
    }
```

---

## File: `_archive/routers/ocr.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/ocr.py`

```python
from fastapi import APIRouter, Request
from loguru import logger

router = APIRouter(prefix="/api", tags=["ocr"])


@router.post("/ocr")
async def read_text(request: Request):
    """
    Mode Baca Teks.
    Flutter kirim raw JPEG bytes di body → server balik teks hasil OCR.
    Return: {"text": str, "lines": list[str], "confidence": float}
    """
    body   = await request.body()
    svc    = request.app.state.ocr_service
    result = svc.read_text(body)

    logger.info(
        f"OCR: {len(result.get('lines', []))} lines, "
        f"conf={result.get('confidence', 0):.2f}"
    )
    return result
```

---

## File: `_archive/routers/risk_zone.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/risk_zone.py`

```python
from fastapi import APIRouter, Query, Request

router = APIRouter(prefix="/api", tags=["risk_zone"])


@router.get("/risk-zone")
async def check_risk_zone(
    request: Request,
    lat: float = Query(..., description="Latitude pengguna"),
    lng: float = Query(..., description="Longitude pengguna"),
):
    """
    Cek apakah ada zona bahaya di dekat koordinat.
    Dipanggil Flutter saat Mode Navigasi aktif atau secara periodik.
    """
    svc     = request.app.state.risk_zone_service
    warning = svc.check_nearby(lat, lng)
    return {"risk_zone": warning}


@router.post("/risk-zone/report")
async def report_risk_zone(
    request: Request,
    lat:   float = Query(...),
    lng:   float = Query(...),
    label: str   = Query(..., description="Label objek yang terdeteksi"),
):
    """Manual report dari Flutter jika ada deteksi bahaya."""
    svc = request.app.state.risk_zone_service
    svc.report(lat, lng, label)
    return {"status": "reported"}
```

---

## File: `_archive/routers/support_full.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/support_full.py`

```python
"""Endpoint penunjang di luar enam fitur utama.

Semua endpoint di sini lahir dari state yang sudah dirancang di
IMPLEMENTASI.md, bukan dari kebiasaan umum bikin API:

  GET  /api/capabilities        mode mana yang server-nya hidup (DO-11c, BT-01/02)
  GET  /api/labels              kamus label objek Bahasa Indonesia (DO-08, DO-19)
  GET  /api/models/manifest     sinkronisasi model on-device (UG-18)
  POST /api/models/rescan       pindai ulang folder models/
  POST /api/events              telemetri alur (membuktikan target desain)
  GET  /api/events/summary      ringkasan telemetri
  POST /api/crash-report        laporan crash (ER-06)
  GET  /api/crash-report/last-mode  mode terakhir untuk dipulihkan (ER-06)
  POST /api/queue/flush         antrean unggah offline (BT-13)
  GET  /api/queue/pending       sisa antrean per perangkat
"""

import hashlib
import os
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, File, Form, Request, Response, UploadFile
from pydantic import BaseModel, Field

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["penunjang"])

MODELS_DIR = Path(__file__).parent.parent / "models"


def _db_guard() -> dict | None:
    """Pesan seragam saat DB mati: sebut yang masih hidup, baru yang mati."""
    if is_available():
        return None
    return {
        "ok": False,
        "reason": "database_unavailable",
        "message": (
            "Deteksi objek dan kenali uang tetap jalan karena keduanya "
            "on-device. Penyimpanan di server sedang tidak bisa dipakai."
        ),
    }


# ── Capability discovery ─────────────────────────────────────────────────


@router.get("/capabilities")
async def capabilities(request: Request):
    """Kemampuan server SEBELUM pengguna menekan tombol.

    Menentukan item mana yang `limited` / `disabled` di ModePickerSheet dan
    apakah FullScreenButton Mode Baca Teks aktif (BT-01) atau nonaktif
    dengan alasan (BT-02). Tanpa ini status hanya ketahuan setelah gagal.
    """
    state = request.app.state
    yolo_ok = getattr(state, "yolo_service", None) is not None and state.yolo_service.loaded
    ocr_ok = getattr(state, "ocr_service", None) is not None
    seg = getattr(state, "segmentation_service", None)
    finder = getattr(state, "find_object_service", None)
    qwen_svc = getattr(state, "qwen_service", None)
    llm_ok = qwen_svc is not None and qwen_svc.available

    caps = {
        # Dua mode ini sepenuhnya on-device: server mati pun tetap jalan.
        "detection": {"state": "up", "on_device": True,
                      "note": "Berjalan on-device, tidak butuh server."},
        "money": {"state": "up", "on_device": True,
                  "note": "Klasifikasi nominal on-device (TFLite), tidak pernah memanggil server."},

        # Baca Teks pindah ke ML Kit on-device — server tidak dipanggil lagi,
        # jadi ia tidak pernah 'down' dan tetap jalan penuh tanpa internet.
        "read_text": {
            "state": "up",
            "on_device": True,
            "note": "Pengenalan teks on-device (ML Kit), tidak butuh server.",
        },
        "navigation": {
            # Sejak rintangan DAN jalur sama-sama dibaca di sini, tidak ada
            # lagi cadangan on-device: kalau segmentasi mati, mode ini benar-
            # benar tidak melihat apa pun. Menandainya 'limited' akan
            # menjanjikan keselamatan yang tidak ada.
            "state": "up" if (seg and seg.loaded and yolo_ok) else "down",
            "on_device": False,
            "note": "Jalur dan rintangan terbaca." if (seg and seg.loaded and yolo_ok)
                    else "Navigasi sedang mati. Jangan berjalan mengandalkan aplikasi.",
        },
        "assistant": {
            "state": "up" if llm_ok else "limited",
            "on_device": False,
            "note": "Asisten penuh." if llm_ok
                    else "Tanpa kunci LLM: hanya perintah dasar yang dikenali.",
        },
        "find_object": {
            "state": "up" if finder is not None else "down",
            "on_device": False,
            "note": "Pencarian objek siap." if finder is not None
                    else "Cari Objek butuh internet.",
        },
    }

    # Override manual untuk demo / maintenance.
    if is_available():
        try:
            for name, ov in repo.get_capability_overrides().items():
                if name in caps and ov.get("forced_state"):
                    caps[name]["state"] = ov["forced_state"]
                    caps[name]["note"] = ov.get("reason") or caps[name]["note"]
                    caps[name]["forced"] = True
        except Exception:
            pass

    return {
        "server_time": datetime.now(timezone.utc).isoformat(),
        "database": is_available(),
        "yolo_loaded": yolo_ok,
        "capabilities": caps,
    }


# ── Kamus label ──────────────────────────────────────────────────────────


@router.get("/labels")
async def labels(lang: str = "id"):
    """Pemetaan label model → frasa Bahasa Indonesia yang layak dibacakan.

    Nama kelas mentah tidak pantas masuk TTS. Karena kamus ini di server,
    perbaikan nama tidak perlu rilis ulang aplikasi.
    """
    guard = _db_guard()
    if guard:
        return guard
    rows = repo.get_labels(lang)
    return {
        "lang": lang,
        "total": len(rows),
        "updated_at": repo.labels_updated_at(lang),
        "labels": rows,
    }


# ── Manifest model on-device ─────────────────────────────────────────────


@router.get("/models/manifest")
async def models_manifest():
    """Versi model on-device. UG-18: emisi uang baru = update model, bukan
    update aplikasi."""
    guard = _db_guard()
    if guard:
        return guard
    return {"models": repo.get_manifest()}


@router.post("/models/rescan")
async def models_rescan():
    """Pindai folder `models/`, hitung sha256, tandai mana yang tersedia."""
    guard = _db_guard()
    if guard:
        return guard

    MODELS_DIR.mkdir(exist_ok=True)
    updated = []
    for entry in repo.get_manifest():
        path = MODELS_DIR / entry["filename"]
        if not path.exists():
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        repo.update_manifest_file(
            entry["model_key"], entry["version"], entry["filename"],
            digest, path.stat().st_size, True,
        )
        updated.append(entry["model_key"])
    return {"ok": True, "updated": updated, "scanned_dir": str(MODELS_DIR)}


@router.get("/models/download/{model_key}")
async def models_download(model_key: str):
    guard = _db_guard()
    if guard:
        return guard
    entry = repo.get_manifest_entry(model_key)
    if not entry:
        return {"ok": False, "reason": "unknown_model"}
    path = MODELS_DIR / entry["filename"]
    if not path.exists():
        return {
            "ok": False,
            "reason": "file_missing",
            "message": f"File {entry['filename']} belum ada di server.",
        }
    return Response(
        content=path.read_bytes(),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{entry["filename"]}"'},
    )


# ── Telemetri alur ───────────────────────────────────────────────────────


class EventIn(BaseModel):
    event_name: str
    mode: str | None = None
    gesture_count: int | None = None
    duration_ms: int | None = None
    payload: dict = Field(default_factory=dict)
    occurred_at: datetime | None = None


class EventBatch(BaseModel):
    device_id: str
    events: list[EventIn]


@router.post("/events")
async def post_events(batch: EventBatch):
    """Telemetri alur — mengukur target desain, bukan analitik pemasaran.

    Yang dilacak: jumlah gestur per alur (target bayar < 4), waktu buka
    sampai deteksi aktif, berapa kali perintah suara tidak dikenali.
    """
    guard = _db_guard()
    if guard:
        return guard
    now = datetime.now(timezone.utc)
    for ev in batch.events:
        repo.insert_event(
            batch.device_id, ev.event_name, ev.mode, ev.gesture_count,
            ev.duration_ms, ev.payload, ev.occurred_at or now,
        )
    return {"ok": True, "accepted": len(batch.events)}


@router.get("/events/summary")
async def events_summary(hours: int = 24):
    guard = _db_guard()
    if guard:
        return guard
    return {"window_hours": hours, "summary": repo.event_summary(hours)}


# ── Crash report ─────────────────────────────────────────────────────────


class CrashIn(BaseModel):
    device_id: str
    app_version: str | None = None
    platform: str | None = None
    os_version: str | None = None
    mode: str | None = None
    error_type: str | None = None
    message: str | None = None
    stack_trace: str | None = None
    occurred_at: datetime | None = None


@router.post("/crash-report")
async def post_crash(body: CrashIn):
    """ER-06 — tombol "Kirim laporan" setelah aplikasi dibuka pasca-crash."""
    guard = _db_guard()
    if guard:
        return guard
    crash_id = repo.insert_crash(
        body.device_id, body.app_version, body.platform, body.os_version,
        body.mode, body.error_type, body.message, body.stack_trace,
        body.occurred_at,
    )
    return {"ok": True, "id": crash_id,
            "message": "Laporan terkirim. Terima kasih."}


@router.get("/crash-report/last-mode")
async def last_mode(device_id: str):
    """ER-06 — mode terakhir sebelum crash, untuk dipulihkan otomatis."""
    guard = _db_guard()
    if guard:
        return guard
    return {"device_id": device_id, "mode": repo.last_mode_for_device(device_id)}


# ── Antrean unggah offline ───────────────────────────────────────────────


@router.post("/queue/flush")
async def queue_flush(
    request: Request,
    device_id: str = Form(...),
    idempotency_key: str = Form(...),
    kind: str = Form("ocr"),
    queued_at: datetime | None = Form(None),
    file: UploadFile = File(...),
):
    """BT-13 — gambar yang gagal terkirim saat offline, dikirim ulang saat
    internet kembali.

    `idempotency_key` mencegah pemrosesan dobel: pengiriman ulang dengan
    kunci yang sama mengembalikan hasil yang sudah tersimpan, tidak
    memproses gambar dua kali.
    """
    guard = _db_guard()
    if guard:
        return guard

    existing = repo.queue_item_exists(idempotency_key)
    if existing and existing["status"] == "done":
        return {"ok": True, "duplicate": True, "result": existing["result"]}

    repo.queue_insert(idempotency_key, device_id, kind, queued_at)
    raw = await file.read()

    try:
        if kind == "ocr":
            result = request.app.state.ocr_service.read_text(raw)
        elif kind == "detect":
            import cv2
            import numpy as np

            frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                raise ValueError("Frame tidak valid")
            dets = request.app.state.yolo_service.infer(frame)
            result = {"detections": dets, "total": len(dets)}
        else:
            raise ValueError(f"kind '{kind}' tidak dikenal")

        repo.queue_mark_done(idempotency_key, result)
        return {"ok": True, "duplicate": False, "result": result}

    except Exception as e:
        repo.queue_mark_failed(idempotency_key, str(e))
        return {"ok": False, "reason": "processing_failed", "error": str(e)}


@router.get("/queue/pending")
async def queue_pending(device_id: str):
    guard = _db_guard()
    if guard:
        return guard
    return {"device_id": device_id, "pending": repo.queue_pending(device_id)}
```

---

## File: `_archive/routers/uang.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/uang.py`

```python
"""Mode Kenali Uang — endpoint server OPSIONAL.

Jalur utama fitur ini ada di perangkat (.tflite MobileNetV2, 6 kelas emisi
2016) dan TIDAK pernah memanggil endpoint ini. Yang di sini hanya cadangan
untuk pembanding akurasi dan pengujian dari alat lain (curl/Postman).

Kalau model server belum ada, balasannya jujur `model_unavailable` — tidak
pernah menebak nominal.
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["uang"])


@router.get("/uang/denominations")
async def denominations():
    """Denominasi yang didukung + kata terbilangnya.

    `class_index` adalah urutan kelas pada model on-device. Nilai dengan
    `active=false` (mis. Rp1.000) tidak dikenali model dan aplikasi harus
    menyebut keterbatasan itu, bukan menebak.
    """
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "denominations": []}
    rows = repo.get_denominations()
    return {
        "total": len(rows),
        "note": "Klasifikasi berjalan on-device. Daftar ini hanya rujukan kata dan urutan kelas.",
        "denominations": rows,
    }


@router.post("/uang")
async def kenali_uang(request: Request, file: UploadFile = File(...)):
    raw = await file.read()
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "detected": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca. Coba ambil ulang.",
        }

    words_map: dict[int, str] = {}
    if is_available():
        try:
            words_map = {r["value_idr"]: r["words"] for r in repo.get_denominations()}
        except Exception as e:
            logger.warning(f"Kata terbilang tidak terbaca: {e}")

    result = request.app.state.uang_service.predict(frame, words_map)
    logger.info(f"uang: detected={result.get('detected')} reason={result.get('reason', '-')}")
    return result
```

---

## File: `_archive/routers/voice_router.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/voice_router.py`

```python
"""
Router: POST /api/route-intent
Intent routing untuk Voice Assistant — ARSITEKTUR LAMA.

Catatan: Endpoint ini merupakan sisa arsitektur lama sebelum CommandParser
Flutter dibangun. Flutter sekarang melakukan intent parsing secara lokal
(0ms, offline) dengan 70+ keyword dan fuzzy matching.

Endpoint ini TIDAK lagi dipanggil oleh Flutter. Dipertahankan agar tidak
break backward compatibility jika ada client lain yang masih menggunakannya.

Claude Haiku yang sebelumnya di sini sudah DIHAPUS. Sekarang menggunakan
keyword-based classifier sederhana yang tidak membutuhkan API key maupun
model LLM — sesuai dengan sifat tugas yang hanya 4 kategori.
"""

import logging

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

VALID_INTENTS = {"describe_scene", "ocr", "navigation", "chitchat"}
DEFAULT_INTENT = "describe_scene"  # fallback paling aman untuk tunanetra

# Keyword sederhana per intent — cukup untuk 4 kategori ini tanpa LLM
_KEYWORDS: dict[str, list[str]] = {
    "describe_scene": [
        "deskripsikan", "jelaskan", "ceritakan", "gambarkan", "lihatkan",
        "sekitarku", "depanku", "suasana", "kondisi", "pemandangan",
    ],
    "ocr": [
        "baca", "bacakan", "teks", "tulisan", "kata", "huruf",
        "bacain", "tolong baca",
    ],
    "navigation": [
        "navigasi", "pergi", "jalan", "ke mana", "arahkan", "tuntun",
        "panduan", "lewat", "belok",
    ],
    "chitchat": [
        "halo", "hai", "apa kabar", "siapa kamu", "terima kasih",
        "makasih", "selamat", "help", "tolong",
    ],
}


def _classify_keyword(text: str) -> str:
    """Klasifikasi berdasarkan keyword match — O(n) sederhana, tanpa model."""
    low = text.strip().lower()
    scores: dict[str, int] = {intent: 0 for intent in VALID_INTENTS}
    for intent, keywords in _KEYWORDS.items():
        for kw in keywords:
            if kw in low:
                scores[intent] += 1
    best = max(scores, key=lambda k: scores[k])
    return best if scores[best] > 0 else DEFAULT_INTENT


class RouteRequest(BaseModel):
    text: str


class RouteResponse(BaseModel):
    intent: str
    fallback_used: bool


@router.post("/api/route-intent", response_model=RouteResponse)
async def route_intent(req: RouteRequest):
    """
    Intent routing berbasis keyword (tanpa LLM, tanpa API key).

    Endpoint ini adalah sisa arsitektur lama — Flutter tidak lagi
    memanggilnya karena CommandParser lokal sudah lebih lengkap.
    Dipertahankan untuk backward compatibility.
    """
    try:
        intent = _classify_keyword(req.text)
        fallback = intent == DEFAULT_INTENT
        return RouteResponse(intent=intent, fallback_used=fallback)
    except Exception as e:
        logging.error(f"route_intent gagal: {e}")
        return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)
```

---

## File: `_archive/routers/websocket.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/routers/websocket.py`

```python
import cv2
import numpy as np
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from loguru import logger

from services.camera_health import check_camera_health

router = APIRouter()


@router.websocket("/ws/detect")
async def ws_detect(ws: WebSocket):
    """
    Mode Tuntun + Mode Navigasi (obstacle detection).
    Flutter kirim JPEG binary → server balas raw JSON detections.
    Filter pipeline ada di Flutter, BUKAN di sini.

    Query params:
      lat, lng — koordinat GPS user (opsional, untuk Risk Zone)
    """
    await ws.accept()

    svc      = ws.app.state.yolo_service
    rz_svc   = ws.app.state.risk_zone_service

    # Koordinat dari query param (0,0 = tidak aktif / tidak diberi)
    lat = float(ws.query_params.get("lat", 0))
    lng = float(ws.query_params.get("lng", 0))

    frame_count = 0
    logger.info(f"WebSocket connected. lat={lat}, lng={lng}")

    try:
        while True:
            data        = await ws.receive_bytes()
            frame_count += 1

            arr   = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)

            if frame is None:
                await ws.send_json({"type": "error", "msg": "Frame tidak valid"})
                continue

            # Camera health check di server-side
            health = check_camera_health(frame)
            if not health["ok"]:
                await ws.send_json({
                    "type": "camera_error",
                    "msg":  health["message"],
                })
                continue

            # Server-side sample rate: YOLO tiap 3 frame
            if frame_count % 3 != 0:
                continue

            detections = svc.infer(frame)

            # Auto-report ke risk zone jika ada koordinat valid + deteksi bahaya
            risk_warning = None
            if lat != 0 and lng != 0:
                for det in detections:
                    if det["danger_level"] in ("critical", "warning"):
                        rz_svc.report(lat, lng, det["label_en"])
                risk_warning = rz_svc.check_nearby(lat, lng)

            await ws.send_json({
                "type":       "detections",
                "frame_id":   frame_count,
                "detections": detections,   # raw, tanpa filter — filter di Flutter
                "risk_zone":  risk_warning, # None atau dict warning
            })

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await ws.close()
        except Exception:
            pass
```

---

## File: `_archive/services/camera_health.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/camera_health.py`

```python
import cv2
import numpy as np


def check_camera_health(frame: np.ndarray) -> dict:
    """
    Validasi frame sebelum dikirim ke YOLO.
    4 pengecekan: tertutup, gelap, buram, menghadap bawah.
    Return: {"ok": bool, "message": str}
    """
    h, w = frame.shape[:2]
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # 1. Lensa tertutup: > 90% piksel sangat hitam
    black_ratio = (gray < 10).sum() / gray.size
    if black_ratio > 0.90:
        return {"ok": False, "message": "Lensa kamera tertutup"}

    # 2. Terlalu gelap: rata-rata brightness sangat rendah
    if gray.mean() < 30:
        return {"ok": False, "message": "Kamera terlalu gelap"}

    # 3. Buram: Laplacian variance rendah
    lap_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if lap_var < 50:
        return {"ok": False, "message": "Gambar terlalu buram, pegang kamera lebih stabil"}

    # 4. Kamera menghadap ke bawah (heuristik: bawah frame lebih terang dari atas)
    top_mean    = gray[: h // 3, :].mean()
    bottom_mean = gray[2 * h // 3 :, :].mean()
    if bottom_mean > top_mean * 1.8:
        return {"ok": False, "message": "Arahkan kamera ke depan, bukan ke bawah"}

    return {"ok": True, "message": "OK"}
```

---

## File: `_archive/services/intent_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/intent_service.py`

```python
"""Resolusi perintah suara sisi server — POST /api/intent.

CommandParser lokal di Flutter menangani 20 intent baku tanpa internet
(0 ms, tetap jalan offline). Server hanya dipanggil saat lokal TIDAK match,
untuk dua kasus yang memang butuh pemahaman bahasa:
  - AS-18 "tidak dikenali" → tawarkan dua tebakan terdekat
  - AS-19 "ambigu"         → pertanyaan pilihan dua

Urutan usaha: cocokkan frasa persis → skor kemiripan kata.
LLM (Qwen Lapis 3) DIHAPUS — tidak ada LLM di backend.
"""

import re

from loguru import logger

VALID_CATEGORIES = {"mode", "action", "play", "help"}


class IntentService:
    """Pencocokan intent berbasis data dari tabel voice_intents."""

    def __init__(self):
        self._intents: list[dict] = []
        self._searchable: list[str] = []

    def refresh(self, intents: list[dict], searchable: list[str] | None = None) -> None:
        """Muat ulang daftar intent dari DB (dipanggil saat startup).

        `searchable` = nama barang yang bisa jadi target Mode Cari Objek.
        Dipakai supaya ucapan seperti "kenal kunci" bisa dikenali sebagai
        ambigu antara "cari kunci" dan "kenali uang", bukan langsung
        ditebak salah satunya.
        """
        self._intents = intents
        if searchable is not None:
            self._searchable = [s.lower() for s in searchable]

    def find_object_candidate(self, text: str) -> dict | None:
        """Kalau ucapan menyebut barang yang bisa dicari, tawarkan Cari Objek."""
        low = self._normalize(text)
        words = low.split()
        for item in self._searchable:
            if item in low or any(w == item for w in words):
                return {
                    "intent_key": "mode.findObject",
                    "category": "mode",
                    "spoken_label": f"cari {item}",
                    "argument": item,
                    "confidence": 0.5,
                }
        return None

    @property
    def available(self) -> bool:
        return bool(self._intents)

    # ── Lapis 1: cocokkan frasa ──────────────────────────────────────────

    def match_exact(self, text: str) -> dict | None:
        low = self._normalize(text)
        for intent in self._intents:
            for phrase in intent["phrases"]:
                if phrase in low:
                    return {
                        "intent_key": intent["intent_key"],
                        "category": intent["category"],
                        "spoken_label": intent["spoken_label"],
                        "confidence": 1.0,
                        "matched_phrase": phrase,
                        "source": "phrase",
                    }
        return None

    # ── Lapis 2: skor kemiripan kata ─────────────────────────────────────

    def rank_candidates(self, text: str, limit: int = 2) -> list[dict]:
        """Tebakan terdekat berbasis irisan kata + kemiripan awalan.

        Dipakai untuk menyusun naskah AS-18: "Saya dengar kenal kunci.
        Maksudmu cari kunci, atau kenali uang?"
        """
        low = self._normalize(text)
        words = set(low.split())
        if not words:
            return []

        scored: list[tuple[float, dict]] = []
        for intent in self._intents:
            best = 0.0
            for phrase in intent["phrases"]:
                pwords = set(phrase.split())
                if not pwords:
                    continue
                overlap = len(words & pwords)
                partial = sum(
                    1
                    for w in words
                    for p in pwords
                    if w != p and (w.startswith(p[:4]) or p.startswith(w[:4]))
                )
                score = (overlap + 0.5 * partial) / len(pwords)
                best = max(best, score)
            if best > 0:
                scored.append((best, intent))

        scored.sort(key=lambda t: t[0], reverse=True)
        return [
            {
                "intent_key": intent["intent_key"],
                "category": intent["category"],
                "spoken_label": intent["spoken_label"],
                "confidence": round(min(score, 0.99), 3),
            }
            for score, intent in scored[:limit]
        ]

    # ── Ekstraksi target Cari Objek ──────────────────────────────────────

    TARGET_PATTERN = re.compile(r"^cari(?:kan)?\s+(?!objek$|barang$)(.+)$")

    def extract_find_target(self, text: str) -> str | None:
        """"cari dompet" → "dompet". Dipakai intent mode.findObject."""
        m = self.TARGET_PATTERN.match(self._normalize(text))
        return m.group(1).strip() if m else None

    # ── Naskah tawaran tebakan ───────────────────────────────────────────

    @staticmethod
    def compose_suggestion(heard: str, candidates: list[dict]) -> str:
        """AS-18 / AS-19 — sebut yang didengar, lalu tawarkan dua pilihan."""
        if len(candidates) >= 2:
            return (
                f"Saya dengar {heard}. "
                f"Maksudmu {candidates[0]['spoken_label']}, "
                f"atau {candidates[1]['spoken_label']}?"
            )
        if len(candidates) == 1:
            return f"Saya dengar {heard}. Maksudmu {candidates[0]['spoken_label']}?"
        return (
            f"Saya dengar {heard}, tapi belum paham. "
            "Coba sebut: kenali uang, baca teks, atau cari barang."
        )

    @staticmethod
    def _normalize(text: str) -> str:
        return re.sub(r"\s+", " ", text.strip().lower())
```

---

## File: `_archive/services/ocr_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/ocr_service.py`

```python
import io
import numpy as np
import cv2
from loguru import logger

try:
    from PIL import Image
    import pytesseract
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    logger.warning("pytesseract / Pillow tidak tersedia — OCR tidak aktif")


class OCRService:
    def __init__(self):
        logger.info(f"OCR Service init. Tesseract: {TESSERACT_AVAILABLE}")

    def read_text(self, image_bytes: bytes) -> dict:
        """
        Baca teks dari gambar JPEG.
        Return: {"text": str, "lines": list[str], "confidence": float}
        """
        try:
            arr   = np.frombuffer(image_bytes, np.uint8)
            frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
            if frame is None:
                return self._empty("Gambar tidak valid")

            processed = self._preprocess(frame)

            if TESSERACT_AVAILABLE:
                pil_img = Image.fromarray(processed)
                # PSM 6 = assume uniform block of text
                # lang: ind+eng untuk Indonesia + Inggris
                config = "--psm 6 -l ind+eng"
                data   = pytesseract.image_to_data(
                    pil_img, config=config,
                    output_type=pytesseract.Output.DICT,
                )
                text, lines, confidence = self._parse_tesseract(data)
                return {
                    "text": text,
                    "lines": lines,
                    "confidence": round(confidence, 2),
                    **self._reading_estimate(text, lines),
                }
            return self._empty(
                "OCR engine tidak tersedia. Pasang paket sistem tesseract-ocr "
                "beserta bahasa Indonesia (tesseract-langpack-ind)."
            )

        except Exception as e:
            logger.error(f"OCR error: {e}")
            return self._empty(str(e))

    def _empty(self, error: str) -> dict:
        """Balasan kosong dengan bentuk yang SAMA seperti balasan berhasil,
        supaya sisi aplikasi tidak perlu menebak field mana yang ada."""
        return {
            "text": "",
            "lines": [],
            "confidence": 0.0,
            "error": error,
            **self._reading_estimate("", []),
        }

    # Kecepatan TTS Bahasa Indonesia pada setelan bawaan aplikasi.
    # Dipakai BT-08: perkiraan durasi HARUS disebut sebelum pembacaan
    # dimulai, supaya pengguna bisa memilih ringkasan atau bagian tertentu.
    WORDS_PER_MINUTE = 130
    LONG_READ_SECONDS = 90

    def _reading_estimate(self, text: str, lines: list[str]) -> dict:
        words = len(text.split())
        seconds = round(words / self.WORDS_PER_MINUTE * 60, 1) if words else 0.0
        return {
            "word_count": words,
            "line_count": len(lines),
            "estimated_seconds": seconds,
            "estimated_spoken": self._duration_words(seconds),
            # BT-07 vs BT-06: hasil lebih dari 2 baris memakai panel panjang.
            "is_long": len(lines) > 2,
            # BT-08: di atas 90 detik, tawarkan ringkasan / penuh / pilih bagian.
            "is_very_long": seconds > self.LONG_READ_SECONDS,
        }

    @staticmethod
    def _duration_words(seconds: float) -> str:
        """Durasi dalam kata, bukan angka desimal — aturan penulisan copy."""
        if seconds <= 0:
            return "kurang dari satu detik"
        if seconds < 60:
            return f"sekitar {int(round(seconds))} detik"
        minutes = int(seconds // 60)
        rest = int(round(seconds % 60))
        if rest == 0:
            return f"sekitar {minutes} menit"
        return f"sekitar {minutes} menit {rest} detik"

    def _preprocess(self, frame: np.ndarray) -> np.ndarray:
        """Pre-processing untuk meningkatkan akurasi OCR."""
        gray     = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        denoised = cv2.fastNlMeansDenoising(gray, h=10)
        thresh   = cv2.adaptiveThreshold(
            denoised, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, 11, 2,
        )
        return thresh

    def _parse_tesseract(self, data: dict) -> tuple[str, list[str], float]:
        """Parse output tesseract ke teks bersih + confidence."""
        lines: dict[int, list[str]] = {}
        confidences: list[float]    = []

        for i, word in enumerate(data["text"]):
            word = word.strip()
            if not word:
                continue
            conf = int(data["conf"][i])
            if conf < 30:  # buang kata dengan confidence rendah
                continue
            line_num = data["line_num"][i]
            lines.setdefault(line_num, []).append(word)
            confidences.append(conf)

        line_texts = [" ".join(words) for words in lines.values()]
        full_text  = "\n".join(line_texts)
        avg_conf   = (sum(confidences) / len(confidences) / 100) if confidences else 0.0

        return full_text, line_texts, avg_conf
```

---

## File: `_archive/services/risk_zone_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/risk_zone_service.py`

```python
"""Risk Zone: lokasi yang sering dilaporkan ada hambatan.

Dikumpulkan anonim dari semua pengguna (tanpa auth, cukup koordinat).
Sejak versi ini datanya PERSISTEN di PostgreSQL — sebelumnya dict in-memory
yang hilang tiap server restart, jadi zona bahaya tidak pernah benar-benar
terbentuk.

Kalau database mati, service diam-diam menonaktifkan diri: fitur ini
pelengkap, dan matinya tidak boleh menjatuhkan Mode Navigasi yang deteksi
rintangannya on-device.
"""

from loguru import logger

from db.database import is_available
from services import repository as repo


class RiskZoneService:
    RADIUS_METER = 30.0  # radius cek zona bahaya
    MIN_COUNT = 3        # minimum laporan sebelum dianggap zona bahaya
    GRID_PRECISION = 4   # 4 desimal ≈ 11 meter per sel

    def __init__(self):
        logger.info(
            "RiskZoneService init (PostgreSQL)"
            if is_available()
            else "RiskZoneService init — DB mati, fitur zona rawan nonaktif"
        )

    def report(self, lat: float, lng: float, label: str) -> None:
        """Laporkan rintangan di koordinat ini. Dipanggil tiap deteksi
        'critical' atau 'warning' saat koordinat tersedia."""
        if not is_available():
            return
        try:
            repo.risk_zone_report(self._grid_key(lat, lng), lat, lng, label)
        except Exception as e:
            logger.warning(f"Gagal menyimpan laporan zona: {e}")

    def check_nearby(self, lat: float, lng: float) -> dict | None:
        """Zona bahaya di sekitar koordinat ini, atau None."""
        if not is_available():
            return None
        try:
            zone = repo.risk_zone_nearby(lat, lng, self.RADIUS_METER, self.MIN_COUNT)
            if not zone or zone["distance_m"] > self.RADIUS_METER:
                return None
            labels = zone["labels"] or {}
            common = max(labels, key=labels.get) if labels else ""
            return {
                "distance_meter": round(float(zone["distance_m"]), 1),
                "count": zone["report_count"],
                "common_label": common,
                "warning": "Area ini sering ada hambatan, hati-hati",
            }
        except Exception as e:
            logger.warning(f"Gagal cek zona rawan: {e}")
            return None

    def _grid_key(self, lat: float, lng: float) -> str:
        p = self.GRID_PRECISION
        return f"{round(lat, p)}_{round(lng, p)}"
```

---

## File: `_archive/services/segmentation_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/segmentation_service.py`

```python
"""Mode Navigasi — segmentasi jalur jadi 3 zona (kiri / tengah / kanan).

Model utama: PIDNet-S ONNX (three-branch, ada cabang khusus boundary, jadi
tepi trotoar presisi — penting karena overlay zona dipakai terus-menerus).
Kalau file model belum ada, service memakai fallback heuristik OpenCV yang
tetap menghasilkan tiga zona berbeda dari isi gambar sungguhan, sehingga
seluruh state NV-03..NV-09 di aplikasi bisa diuji tanpa menunggu model.

Kontrak balasan sama persis untuk kedua jalur, jadi menukar heuristik ke
PIDNet nanti tidak mengubah satu baris pun di sisi Flutter.
"""

import os
import time

import cv2
import numpy as np
from loguru import logger

# Status zona — cocok dengan enum ZoneStatus di Flutter.
SAFE = "safe"
CAUTION = "caution"
DANGER = "danger"
UNKNOWN = "unknown"

# Ambang rasio jalur layak-injak per zona.
SAFE_RATIO = 0.55
CAUTION_RATIO = 0.25


class SegmentationService:
    def __init__(self, model_path: str | None = None, input_size: int | None = None):
        self.model_path = model_path or os.getenv(
            "SEGMENTATION_MODEL", "models/pidnet_s_3zona.onnx"
        )
        self.input_size = int(os.getenv("SEGMENTATION_INPUT", input_size or 512))
        self.session = None
        self.input_name: str | None = None
        self.loaded = False
        self.source = "heuristic"

    def load(self) -> bool:
        """Muat PIDNet ONNX bila ada. Tidak adanya model BUKAN kegagalan —
        fallback heuristik tetap melayani, dan itu dilaporkan apa adanya
        lewat field `source` supaya tidak ada klaim palsu ke pengguna."""
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model segmentasi '{self.model_path}' belum ada — "
                "Mode Navigasi pakai fallback heuristik OpenCV."
            )
            self.source = "heuristic"
            return False
        try:
            import onnxruntime as ort

            opts = ort.SessionOptions()
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            self.session = ort.InferenceSession(
                self.model_path, opts, providers=["CPUExecutionProvider"]
            )
            self.input_name = self.session.get_inputs()[0].name
            self.loaded = True
            self.source = "pidnet"
            logger.success(f"Model segmentasi dimuat: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"Segmentasi gagal dimuat: {e} — pakai fallback heuristik")
            self.source = "heuristic"
            return False

    # ── API utama ────────────────────────────────────────────────────────

    def zones(self, frame: np.ndarray) -> dict:
        t0 = time.time()
        try:
            if self.loaded:
                ratios = self._ratios_from_model(frame)
            else:
                ratios = self._ratios_from_heuristic(frame)
        except Exception as e:
            logger.error(f"Segmentasi error: {e}")
            return {
                "ok": False,
                "source": self.source,
                "zones": {
                    "kiri": self._zone_payload(0.0),
                    "tengah": self._zone_payload(0.0),
                    "kanan": self._zone_payload(0.0),
                },
                "recommended": None,
                "message": "Jalur tidak terbaca. Rintangan tetap diperingatkan.",
                "inference_ms": round((time.time() - t0) * 1000, 1),
            }

        zones = {
            "kiri": self._zone_payload(ratios[0]),
            "tengah": self._zone_payload(ratios[1]),
            "kanan": self._zone_payload(ratios[2]),
        }
        recommended = self._recommend(zones)

        return {
            "ok": True,
            "source": self.source,
            "zones": zones,
            "recommended": recommended,
            "message": self._compose_message(zones, recommended),
            "inference_ms": round((time.time() - t0) * 1000, 1),
        }

    # ── Jalur model ──────────────────────────────────────────────────────

    def _ratios_from_model(self, frame: np.ndarray) -> tuple[float, float, float]:
        """PIDNet 3 kelas: 0 = bukan jalur, 1 = zona aman, 2 = zona waspada."""
        size = self.input_size
        img = cv2.resize(frame, (size, size))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        img = (img - mean) / std
        tensor = np.ascontiguousarray(np.transpose(img, (2, 0, 1))[None])

        logits = self.session.run(None, {self.input_name: tensor})[0]
        mask = logits[0].argmax(0)  # [h, w] indeks kelas per piksel

        h, w = mask.shape
        # Hanya separuh bawah yang relevan: itu bidang tanah di depan kaki.
        ground = mask[h // 2:, :]
        gw = ground.shape[1]
        thirds = [
            ground[:, : gw // 3],
            ground[:, gw // 3: 2 * gw // 3],
            ground[:, 2 * gw // 3:],
        ]
        # Kelas 1 (aman) dihitung penuh, kelas 2 (waspada) setengah bobot.
        return tuple(
            float((z == 1).mean() + 0.5 * (z == 2).mean()) for z in thirds
        )  # type: ignore[return-value]

    # ── Jalur heuristik (tanpa model) ────────────────────────────────────

    def _ratios_from_heuristic(self, frame: np.ndarray) -> tuple[float, float, float]:
        """Perkiraan jalur layak-injak dari keseragaman permukaan.

        Dasarnya: permukaan yang bisa dijalani (trotoar, aspal, lantai)
        cenderung RATA — sedikit tepi, warna konsisten. Rintangan, rumput,
        tangga, dan jalur kendaraan memecah keseragaman itu.

        Bukan pengganti segmentasi sungguhan, tapi memberi keluaran yang
        benar-benar mengikuti isi gambar, bukan angka karangan.
        """
        h, w = frame.shape[:2]
        ground = frame[h // 2:, :]  # separuh bawah = bidang tanah
        gh, gw = ground.shape[:2]

        gray = cv2.cvtColor(ground, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)

        hsv = cv2.cvtColor(ground, cv2.COLOR_BGR2HSV)
        # Petak acuan: tepat di depan kaki pengguna (tengah-bawah).
        ref = hsv[int(gh * 0.75):, int(gw * 0.4): int(gw * 0.6)]
        ref_hue = float(np.median(ref[:, :, 0])) if ref.size else 0.0
        ref_val = float(np.median(ref[:, :, 2])) if ref.size else 0.0

        ratios = []
        for i in range(3):
            x0, x1 = i * gw // 3, (i + 1) * gw // 3
            zone_edges = edges[:, x0:x1]
            zone_hsv = hsv[:, x0:x1]

            # 1. Kerapatan tepi: makin sedikit tepi, makin rata permukaannya.
            edge_density = float(zone_edges.mean()) / 255.0
            smoothness = max(0.0, 1.0 - edge_density * 8.0)

            # 2. Kemiripan warna dengan petak acuan di depan kaki.
            hue_diff = np.abs(zone_hsv[:, :, 0].astype(np.float32) - ref_hue)
            hue_diff = np.minimum(hue_diff, 180.0 - hue_diff)  # hue melingkar
            val_diff = np.abs(zone_hsv[:, :, 2].astype(np.float32) - ref_val)
            similar = float(((hue_diff < 18) & (val_diff < 60)).mean())

            ratios.append(max(0.0, min(1.0, 0.45 * smoothness + 0.55 * similar)))

        return tuple(ratios)  # type: ignore[return-value]

    # ── Pemetaan rasio → status ──────────────────────────────────────────

    def _zone_payload(self, ratio: float) -> dict:
        if ratio >= SAFE_RATIO:
            status = SAFE
        elif ratio >= CAUTION_RATIO:
            status = CAUTION
        else:
            status = DANGER
        return {"status": status, "walkable_ratio": round(ratio, 3)}

    def _recommend(self, zones: dict) -> str | None:
        """Zona tengah menang bila sama-sama aman: berjalan lurus paling murah
        secara kognitif, jangan suruh pengguna geser tanpa alasan."""
        order = ["tengah", "kiri", "kanan"]
        for status in (SAFE, CAUTION):
            best, best_ratio = None, -1.0
            for name in order:
                z = zones[name]
                if z["status"] == status and z["walkable_ratio"] > best_ratio:
                    best, best_ratio = name, z["walkable_ratio"]
            if best:
                return best
        return None

    def _compose_message(self, zones: dict, recommended: str | None) -> str:
        """Naskah NV-03..NV-07. Darurat maksimal 2,5 detik: kata pembeda di depan."""
        statuses = {k: v["status"] for k, v in zones.items()}

        if all(s == DANGER for s in statuses.values()):
            return "Berhenti dulu. Tidak ada jalur aman di sekitar sini."
        if statuses["tengah"] == DANGER:
            sisi = recommended or "kiri atau kanan"
            return f"Jalur kendaraan di tengah. Geser ke {sisi}."
        if all(s == SAFE for s in statuses.values()):
            return "Jalur aman, jalan lurus."
        if recommended:
            return f"Tetap di {recommended}."
        return "Pelan-pelan, jalur kurang jelas."
```

---

## File: `_archive/services/uang_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/uang_service.py`

```python
"""Mode Kenali Uang — endpoint server OPSIONAL.

Jalur utama fitur ini ON-DEVICE (.tflite MobileNetV3, klasifikasi 7
denominasi), karena tiga alasan yang tidak bisa ditawar:
  1. Aksesibilitas: transaksi tunai sering terjadi di tempat tanpa sinyal
     (pasar, warung). Fitur yang mati saat offline = fitur yang gagal.
  2. Privasi: foto uang tidak perlu meninggalkan perangkat.
  3. Latensi: pengguna butuh umpan balik seketika saat mengarahkan kamera.

Endpoint server ini hanya cadangan untuk pembanding akurasi dan pengujian.

ATURAN KERAS: nominal TIDAK PERNAH ditebak. Kalau model belum ada atau
keyakinan di bawah ambang, balasannya adalah instruksi perbaikan, bukan
angka. Salah menyebut nominal ke pengguna tunanetra = kerugian uang nyata,
jadi false positive di sini jauh lebih berbahaya daripada false negative.
"""

import os
import time

import cv2
import numpy as np
from loguru import logger

# Urutan kelas WAJIB sama dengan model saat training (lihat kolom
# class_index di tabel money_denominations).
CLASS_VALUES = [1000, 2000, 5000, 10000, 20000, 50000, 100000]


class UangService:
    def __init__(self, model_path: str | None = None, threshold: float | None = None):
        self.model_path = model_path or os.getenv(
            "MONEY_MODEL", "models/uang_mobilenetv3.onnx"
        )
        self.threshold = float(os.getenv("MONEY_CONF_THRESHOLD", threshold or 0.85))
        self.input_size = 224
        self.session = None
        self.input_name: str | None = None
        self.loaded = False

    def load(self) -> bool:
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model uang '{self.model_path}' belum ada. "
                "Endpoint /api/uang akan balas 'model_unavailable' — TIDAK menebak. "
                "Jalur utama fitur ini tetap on-device (.tflite)."
            )
            return False
        try:
            import onnxruntime as ort

            opts = ort.SessionOptions()
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            self.session = ort.InferenceSession(
                self.model_path, opts, providers=["CPUExecutionProvider"]
            )
            self.input_name = self.session.get_inputs()[0].name
            self.loaded = True
            logger.success(f"Model uang dimuat: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"Model uang gagal dimuat: {e}")
            return False

    def predict(self, frame: np.ndarray, words_map: dict[int, str]) -> dict:
        """Klasifikasi nominal. Selalu balas dict, tidak pernah menebak.

        Bentuk balasan mengikuti state UG-05 / UG-06:
        - detected=True  → UG-05, nominal boleh ditampilkan (angka + kata)
        - detected=False → UG-06, HANYA instruksi perbaikan yang ditampilkan
        """
        if not self.loaded:
            return {
                "detected": False,
                "reason": "model_unavailable",
                "message": (
                    "Pengenalan uang di server belum aktif. "
                    "Mode Kenali Uang berjalan di perangkat tanpa internet."
                ),
            }

        try:
            t0 = time.time()
            img = cv2.resize(frame, (self.input_size, self.input_size))
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
            tensor = np.ascontiguousarray(np.transpose(img, (2, 0, 1))[None])

            logits = self.session.run(None, {self.input_name: tensor})[0][0]
            exp = np.exp(logits - logits.max())
            probs = exp / exp.sum()
            idx = int(probs.argmax())
            confidence = float(probs[idx])
            inference_ms = (time.time() - t0) * 1000

            if confidence < self.threshold:
                # UG-06 — ragu. Nominal TIDAK ditampilkan.
                return {
                    "detected": False,
                    "reason": "low_confidence",
                    "confidence": round(confidence, 3),
                    "threshold": self.threshold,
                    "message": "Belum yakin. Dekatkan sedikit dan tahan diam.",
                    "inference_ms": round(inference_ms, 1),
                }

            value = CLASS_VALUES[idx] if idx < len(CLASS_VALUES) else None
            if value is None:
                return {
                    "detected": False,
                    "reason": "unknown_class",
                    "message": "Belum yakin. Coba ulangi.",
                }

            return {
                "detected": True,
                "value_idr": value,
                "words": words_map.get(value, ""),
                "formatted": self._format_rupiah(value),
                "confidence": round(confidence, 3),
                "inference_ms": round(inference_ms, 1),
            }

        except Exception as e:
            logger.error(f"Prediksi uang gagal: {e}")
            return {
                "detected": False,
                "reason": "server_error",
                "message": "Gagal mengenali. Coba lagi.",
                "error": str(e),
            }

    @staticmethod
    def _format_rupiah(value: int) -> str:
        return "Rp" + f"{value:,}".replace(",", ".")
```

---

## File: `_archive/services/yolo_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/_archive/services/yolo_service.py`

```python
import os
import time
import numpy as np
from ultralytics import YOLO
from loguru import logger

# ─── Model COCO (pretrained, 80 kelas) ───────────────────────────────────────
# Mapping label COCO (English) → Bahasa Indonesia
LABEL_ID: dict[str, str] = {
    "person":        "orang",
    "bicycle":       "sepeda",
    "car":           "mobil",
    "motorcycle":    "motor",
    "bus":           "bus",
    "truck":         "truk",
    "dog":           "anjing",
    "cat":           "kucing",
    "chair":         "kursi",
    "bench":         "bangku",
    "dining table":  "meja",
    "stairs":        "tangga",
    "door":          "pintu",
    "umbrella":      "payung",
    "backpack":      "tas",
    "traffic light": "lampu merah",
    "stop sign":     "rambu berhenti",
    "potted plant":  "tanaman",
    "suitcase":      "koper",
}

# Tinggi nyata objek dalam cm — model COCO
REAL_HEIGHTS_CM: dict[str, int] = {
    "person":     170,
    "motorcycle": 120,
    "car":        150,
    "bicycle":    100,
    "bus":        300,
    "truck":      280,
    "dog":         60,
    "cat":         25,
    "chair":       90,
    "bench":       85,
    "default":    100,
}

# ─── Model Navigasi Custom (6 kelas GUIDIO) ───────────────────────────────────
# Kelas sudah dalam Bahasa Indonesia → tidak perlu mapping tambahan
NAVIGASI_CLASSES = {"lubang", "got_terbuka", "tangga", "orang", "motor", "tiang"}

# Tinggi nyata untuk kelas navigasi custom (cm)
REAL_HEIGHTS_NAVIGASI: dict[str, int] = {
    "orang":      170,
    "motor":      120,
    "tiang":      200,
    "tangga":      80,
    "lubang":      10,   # objek di tanah → pakai ground-contact method lebih akurat
    "got_terbuka": 10,  # idem
    "default":    100,
}

# Klasifikasi bahaya model navigasi custom
DANGER_HIGH_NAV   = {"lubang", "got_terbuka", "orang", "motor"}
DANGER_MEDIUM_NAV = {"tangga", "tiang"}

# Focal length piksel (kalibrasi default, bisa di-override via .env)
FOCAL_LENGTH_PX = 615

# Klasifikasi bahaya model COCO
DANGER_HIGH   = {"person", "motorcycle", "car", "bus", "truck", "dog"}
DANGER_MEDIUM = {"bicycle", "chair", "bench", "dining table", "stairs"}


class YOLOService:
    def __init__(self, model_path: str = "yolov8m.pt", device: str = "auto",
                 navigasi_model_path: str | None = None):
        """Service YOLO dual-model: COCO untuk mode deteksi umum,
        model navigasi custom (6 kelas) untuk mode navigasi tunanetra.

        Args:
            model_path           : Model COCO pretrained (default yolov8m.pt / yolo11n.pt)
            device               : 'auto', 'cuda', 'cpu'
            navigasi_model_path  : Path ke yolo_navigasi.pt hasil training.
                                   Jika None, navigasi fallback ke model COCO.
        """
        self.model_path          = model_path
        self.navigasi_model_path = navigasi_model_path or os.getenv("YOLO_NAVIGASI_MODEL")
        self.device              = self._resolve_device(device)
        self.model               = None
        self.navigasi_model      = None   # model custom navigasi (opsional)
        self.loaded              = False

    def _resolve_device(self, device: str) -> str:
        if device != "auto":
            return device
        try:
            import torch
            return "cuda" if torch.cuda.is_available() else "cpu"
        except ImportError:
            return "cpu"

    def load(self) -> bool:
        try:
            logger.info(f"Loading YOLO '{self.model_path}' pada device '{self.device}'...")
            t0         = time.time()
            self.model = YOLO(self.model_path)
            dummy      = np.zeros((640, 640, 3), dtype=np.uint8)
            self.model.predict(dummy, verbose=False)
            logger.success(f"YOLO (COCO) loaded dalam {time.time() - t0:.1f}s")
            self.loaded = True

            # Load model navigasi custom jika tersedia
            if self.navigasi_model_path:
                try:
                    nav_path = self.navigasi_model_path
                    logger.info(f"Loading YOLO navigasi custom '{nav_path}'...")
                    self.navigasi_model = YOLO(nav_path)
                    self.navigasi_model.predict(dummy, verbose=False)
                    logger.success(f"YOLO navigasi custom loaded. "
                                   f"Classes: {list(self.navigasi_model.names.values())}")
                except Exception as e:
                    logger.warning(f"Model navigasi custom gagal load: {e} — fallback ke COCO.")
                    self.navigasi_model = None

            return True
        except Exception as e:
            logger.error(f"Gagal load YOLO: {e}")
            return False

    def infer(self, frame: np.ndarray, confidence: float = 0.5,
              mode: str = "coco") -> list[dict]:
        """
        Jalankan inference YOLO.

        Args:
            frame      : Frame BGR dari OpenCV
            confidence : Threshold confidence (default 0.5)
            mode       : 'coco'     → model COCO pretrained (mode deteksi umum)
                         'navigasi' → model custom 6 kelas (mode navigasi)
        """
        # Pilih model yang tepat
        if mode == "navigasi" and self.navigasi_model is not None:
            active_model   = self.navigasi_model
            use_nav_schema = True
        else:
            active_model   = self.model
            use_nav_schema = False
        if not self.loaded:
            raise RuntimeError("Model belum di-load. Panggil load() terlebih dahulu.")

        h, w = frame.shape[:2]
        t0   = time.time()

        results = active_model.predict(
            frame, conf=confidence, iou=0.45,
            imgsz=640, verbose=False, device=self.device,
        )
        inference_ms = (time.time() - t0) * 1000

        detections: list[dict] = []
        result = results[0]
        if result.boxes is None:
            return []

        for box in result.boxes:
            x1, y1, x2, y2 = [int(v) for v in box.xyxy[0].tolist()]
            raw_label = result.names[int(box.cls[0])]
            box_h     = y2 - y1

            if use_nav_schema:
                # Model navigasi: kelas sudah dalam BI, estimasi jarak pakai skema nav
                label_en  = raw_label
                label_id  = raw_label
                dist      = self._estimate_distance_nav(raw_label, box_h)
                danger    = self._get_danger_nav(raw_label, dist)
            else:
                # Model COCO: terjemahkan label ke BI
                label_en  = raw_label
                label_id  = LABEL_ID.get(raw_label, raw_label)
                dist      = self._estimate_distance(raw_label, box_h)
                danger    = self._get_danger(raw_label, dist)

            direction = self._get_direction((x1 + x2) / 2, w)

            detections.append({
                "label_en":       label_en,
                "label_id":       label_id,
                "confidence":     round(float(box.conf[0]), 3),
                "distance_meter": round(dist, 2),
                "direction":      direction,
                "danger_level":   danger,
                "bbox":           {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                "inference_ms":   round(inference_ms, 1),
            })

        return detections

    def _estimate_distance(self, label: str, box_h: int) -> float:
        """Estimasi jarak model COCO via Similar Triangle formula."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_CM.get(label, REAL_HEIGHTS_CM["default"])
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

    def _estimate_distance_nav(self, label: str, box_h: int) -> float:
        """Estimasi jarak model navigasi custom — pakai real heights skema nav."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_NAVIGASI.get(label, REAL_HEIGHTS_NAVIGASI["default"])
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

    def _get_direction(self, cx: float, w: int) -> str:
        """Tentukan arah berdasarkan posisi horizontal center bounding box."""
        t = w / 3
        if cx < t:
            return "kiri"
        if cx < t * 2:
            return "depan"
        return "kanan"

    def _get_danger(self, label: str, dist: float) -> str:
        """Tentukan level bahaya dari kombinasi class COCO + jarak."""
        if label in DANGER_HIGH:
            if dist < 1.5:
                return "critical"
            if dist < 3.0:
                return "warning"
        elif label in DANGER_MEDIUM:
            if dist < 2.0:
                return "critical"
            if dist < 4.0:
                return "warning"
        return "info"

    def _get_danger_nav(self, label: str, dist: float) -> str:
        """Tentukan level bahaya dari kombinasi class navigasi custom + jarak.

        Lubang & got_terbuka lebih kritis dari orang/motor pada jarak dekat
        karena pengguna bisa langsung jatuh — tidak ada waktu menghindar.
        """
        if label in ("lubang", "got_terbuka"):
            if dist < 1.0:
                return "critical"
            if dist < 2.5:
                return "warning"
        elif label in ("orang", "motor"):
            if dist < 1.5:
                return "critical"
            if dist < 3.0:
                return "warning"
        elif label in ("tangga", "tiang"):
            if dist < 2.0:
                return "critical"
            if dist < 4.0:
                return "warning"
        return "info"
```

---

## File: `compass_artifact_wf-6faa4e5a-1dfa-5f2a-b75b-7ac36d56a1d7_text_markdown.md`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/compass_artifact_wf-6faa4e5a-1dfa-5f2a-b75b-7ac36d56a1d7_text_markdown.md`

```markdown
# Riset Teknis Mendalam — Pengembangan Aplikasi Vinara (eks Guidio)

**TL;DR**
- Untuk Scene Description & Live Assistant, arsitektur terbaik untuk Vinara adalah **hybrid grounding**: pertahankan pola "Grounded Text-to-Language" tapi kirim GAMBAR + konteks deteksi on-device ke satu VLM murah (Gemini 2.5 Flash-Lite $0.10/$0.40 per 1M token, atau Claude Haiku 4.5 $1/$5). Biaya per query 640×480 ≈ Rp2–35, sangat terjangkau; jangan self-host VLM di tahap awal.
- Untuk Light Detection & sonifikasi Cari Objek, semua bisa 100% on-device tanpa model ML baru: baca plane Y (luma) langsung dari `CameraImage` YUV420 yang SUDAH ada (nol konversi RGB), dan pakai `flutter_soloud` untuk beep dinamis PCM real-time. Menurut studi Delaunay & Ambard ("How well do you see what you hear?", 28 partisipan) dan Bazilinskyy et al. (2016, N=29), **beep repetition rate** (tempo) memberi estimasi jarak/kedalaman terbaik — jadikan tempo mapping utama.
- Mode Tuntun dan Navigasi Jalur SEBAIKNYA TIDAK dilebur total; jadikan Mode Tuntun sebagai mode "obstacle level mata/kepala" (memakai pitch HP dari `sensors_plus`) dan Navigasi Jalur sebagai mode trotoar. Satu `CameraController` tidak bisa dipakai dua konsumen ML berat sekaligus — auto-switch kontekstual lebih baik daripada dua mode paralel.

---

## Catatan Sumber & Verifikasi
Semua harga API dan benchmark di bawah punya sumber. Beberapa angka (harga image-input OpenAI Realtime, ketersediaan region Gemini Live untuk Indonesia, benchmark segmentasi di chip mobile spesifik) belum bisa diverifikasi dari sumber primer dan DITANDAI eksplisit dengan ⚠️. Jangan anggap angka bertanda ⚠️ sebagai final tanpa cek ulang di dashboard resmi.

---

# FITUR 1: Scene Description AI (deskripsi naratif + Q&A) — ekstensi Asisten Suara

## Requirement & UX Goal
Upgrade Asisten Suara Claude Haiku existing menjadi multimodal: user memotret/pakai kamera, bertanya natural ("ini apa di depan?", "deskripsikan ruangan"), asisten memberi deskripsi naratif, lalu multi-turn Q&A dengan konteks gambar yang sama. Prinsip pembeda Vinara: transparansi ketidakpastian, karena riset Gonzalez, Collins, Bennett & Azenkot (CHI 2024, arXiv:2403.15604) menemukan aplikasi scene description AI diberi skor kepercayaan hanya **2,43/4 (SD=1,16)** dan kepuasan **2,76/5 (SD=1,49)** oleh 16 partisipan BLV — halusinasi dengan nada meyakinkan adalah masalah utama. MacLeod et al. berargumen untuk "designing for mistrust" dengan menampilkan confidence rating.

## Opsi 1: Satu VLM multimodal (Claude Haiku 4.5 vision)
- **Cara kerja teknis**: kirim JPEG 640×480 + prompt teks langsung ke Claude Haiku 4.5 (`claude-haiku-4-5`, model yang SUDAH dipakai untuk narasi). Model ini mendukung vision, tool calling, prompt caching, structured output.
- **Backend (FastAPI)**: endpoint `/api/narasi` diperluas untuk menerima `image` (base64) selain `detections`. Anthropic SDK `anthropic>=0.25.0` sudah ada di requirements. Format pesan: `{"type":"image","source":{"type":"base64",...}}` + `{"type":"text",...}`.
- **Frontend (Flutter)**: `captureJpeg()` sudah ada. Kirim via `http ^1.2.1`.
- **Biaya**: Claude Haiku 4.5 = **$1/M input, $5/M output** (terkonfirmasi resmi anthropic.com/claude/haiku). Formula token gambar Anthropic = `(width × height) / 750`. Untuk 640×480 = 307.200/750 ≈ **410 token** (≈$0.00041). Untuk 1024×768 = 786.432/750 ≈ 1.048 token. Dengan output ~150 token ($0.00075) + prompt teks ~300 token, total ≈ **$0.0015 per query** (~Rp24). 1.000 query ≈ $1,5 (~Rp24.000). 100 user aktif × 10 query/hari × 30 hari = 30.000 query/bulan ≈ **$45/bulan (~Rp720rb)**; 1.000 user = **$450/bulan**.
- **Kelebihan**: satu model untuk teks+vision, konsisten dengan stack existing; kualitas reasoning tinggi; prompt caching untuk multi-turn.
- **Kekurangan**: lebih mahal dari Gemini; Anthropic tidak punya region data di Indonesia (latensi lintas benua).

## Opsi 2: Gemini 2.5 Flash / Flash-Lite (vision)
- **Cara kerja**: sama, panggil Gemini API dari FastAPI (`httpx` sudah ada).
- **Biaya**: Gemini 2.5 Flash-Lite = **$0.10/M input, $0.40/M output** (terkonfirmasi ai.google.dev/gemini-api/docs/pricing; batch mode turun ke $0.05/$0.20; catatan: model 2.5 dijadwalkan retirement 16 Okt 2026 → migrasi ke Gemini 3.1 Flash-Lite $0.25/$1.50). Gemini 2.5 Flash = $0.30/$2.50. Tokenisasi gambar Gemini: ≤384px = 258 token flat; >384px di-tile 768×768 @ 258 token/tile. Gambar 640×480 = beberapa tile ≈ 516–1.032 token. Biaya per query Flash-Lite ≈ **$0.0003–0.0005** (~Rp5–8), ~3–5× lebih murah dari Haiku.
- **Kelebihan**: termurah; context window 1M; kualitas vision baik.
- **Kekurangan**: kualitas hedging/kejujuran ketidakpastian perlu diuji; model 2.5 akan pensiun.

## Opsi 3: Pipeline 2 model (VLM caption → Claude Haiku teks) — TIDAK disarankan
- **Cara kerja**: VLM kecil deskripsikan gambar → teks → diteruskan ke Claude Haiku untuk dinaturalkan.
- **Kekurangan**: menambah latency (2 hop), menambah biaya, dan justru menambah risiko halusinasi karena Claude tidak bisa memverifikasi teks perantara. Kalah dibanding satu VLM yang lihat gambar langsung + grounding deteksi.

## Pendekatan Hybrid Grounding (INTI rekomendasi)
Gabungkan deteksi terstruktur on-device (SSD MobileNet: label + jarak + arah + danger) SEBAGAI grounding context ke prompt VLM. Contoh prompt:
> "Detektor on-device melaporkan: orang 1.2m depan, kursi 2m kanan (confidence 0.7). Konfirmasi atau koreksi berdasarkan gambar. Jika ragu tentang detail, katakan 'sepertinya' atau 'saya tidak yakin'. Jangan sebut objek yang tidak terlihat jelas. Jawab 1–2 kalimat, Bahasa Indonesia."

Ini bentuk **detection-augmented VLM prompting** / visual grounding. Teknik pendukung dari literatur: chain-of-verification, uncertainty-aware captioning. Karena Vinara sudah punya deteksi terstruktur, ini pembeda kuat — VLM tidak start dari nol dan halusinasi bisa "dijangkarkan" ke fakta detektor. Gunakan structured output dengan field `confidence` dan instruksi eksplisit "jawab tidak tahu kalau ragu". Riset Alharbi et al. (ASSETS 2024, "Misfitting With AI: How Blind People Verify and Contest AI Errors") menegaskan error VLM sering tak terdeteksi oleh pengguna tunanetra → menampilkan ketidakpastian adalah safety feature, bukan sekadar UX.

## Multi-turn Q&A dengan gambar sama: gunakan prompt caching
- **Anthropic prompt caching**: cache read = **10% harga input** (90% diskon, ≈$0.10/M untuk Haiku); cache write 5-menit = 1.25× input, 1-jam = 2× (platform.claude.com/docs/en/build-with-claude/prompt-caching). Minimum 1.024 token untuk cacheable — gambar 640×480 (410 token) sendirian TIDAK cukup, tapi gambar 1024×768 (1.048 token) atau gambar+system prompt gabungan bisa. Untuk multi-turn 3–5 giliran soal gambar sama, caching memotong biaya input drastis.
- **Integrasi dengan PostgreSQL existing**: tabel sesi asisten (`/api/asisten/turn`, expired 15 menit) sudah ada. Simpan `image_ref` per sesi; kirim ulang gambar dengan `cache_control` di turn pertama, lalu cache-read di turn berikutnya. Cache TTL 5 menit cocok dengan window percakapan pendek. Alternatif: cache gambar di server (path lokal) dan re-attach; hindari re-upload dari HP tiap turn (hemat kuota user).

## Rekomendasi Fitur 1
**Gunakan Gemini 2.5 Flash-Lite (atau penerusnya 3.1 Flash-Lite) sebagai default untuk deskripsi naratif, dengan hybrid grounding dari deteksi on-device, dan Claude Haiku 4.5 sebagai fallback/premium.** Alasan: biaya Flash-Lite ~5× lebih murah cocok untuk pasar Indonesia yang sensitif harga; hybrid grounding memanfaatkan aset deteksi yang SUDAH ada dan langsung menyerang problem trust 2,43/4. Pertahankan prinsip "jawab tidak tahu kalau ragu" via prompt + structured confidence. Multi-turn pakai prompt caching + tabel sesi PostgreSQL yang ada.

## Ditemukan tapi tidak disarankan
- **Pipeline 2 model terpisah** — menambah latency & biaya tanpa mengurangi halusinasi.
- **GPT-4o-mini vision** — layak secara harga tapi menambah vendor ketiga tanpa keunggulan jelas vs Gemini/Claude yang sudah/mudah diintegrasi.

## Pertanyaan buat user
1. Budget API vision per bulan (menentukan Gemini vs Claude)?
2. Boleh kirim gambar mentah ke server cloud (privasi)? Atau harus on-device?
3. Prioritas: kualitas deskripsi (Haiku/Sonnet) vs biaya minimum (Flash-Lite)?

---

# FITUR 2: Light Detection

## Requirement & UX Goal
Deteksi lampu menyala/mati & terang/gelap. Harus murah baterai, jalan di device kelas bawah, dan membedakan "gelap beneran" vs "kamera tertutup tangan/kantong" (false positive kritis untuk tunanetra). Jadi shared service reusable (`tooDark` CO-19 Cari Objek + Navigasi butuh).

## Opsi 1: Baca plane Y (luma) dari CameraImage YUV420 — DIREKOMENDASIKAN
- **Cara kerja teknis**: `CameraProvider` sudah pakai `ImageFormatGroup.yuv420`. Plane Y (`CameraImage.planes[0]`) ADALAH luminance mentah (0–255) tanpa perlu konversi RGB sama sekali. Hitung rata-rata luma dengan **sampling** (mis. tiap 16 piksel, atau grid 32×32 sampel) — bukan seluruh 640×480 piksel — supaya <1ms CPU.
- **Membedakan lampu mati vs kamera tertutup**: gunakan **variance/histogram spread**, bukan hanya mean. Kamera tertutup tangan/kantong = mean sangat rendah DAN variance sangat rendah (nyaris seragam gelap). Ruangan gelap dengan sedikit cahaya = mean rendah tapi variance lebih tinggi (ada tepi/titik cahaya). Ambang contoh (perlu kalibrasi per-device): mean <30 & variance <50 → "kamera mungkin tertutup"; mean <50 → "gelap"; 50–120 → "redup"; >120 → "terang".
- **Backend**: tidak perlu — 100% on-device.
- **Frontend**: buat `LightService` yang meng-consume frame Y-plane. Ekspos `LightLevel {dark, dim, bright, blocked}` + `luma`, `variance`.
- **Kelebihan**: nol biaya, nol model ML, hampir nol baterai, jalan offline, jalan di semua device.
- **Kekurangan**: perlu kalibrasi ambang per-device (auto-exposure kamera memengaruhi absolut luma).

## Opsi 2: Ambient Light Sensor HP (package `light` / `ambient_light`)
- **Cara kerja**: baca sensor cahaya lingkungan (lux) hardware.
- **Kekurangan**: sensor ALS sering TIDAK ada di device Android kelas bawah, atau posisinya di depan (bukan mengukur arah kamera belakang). Tidak bisa membedakan "kamera tertutup". Kurang reusable dengan pipeline kamera.

## Opsi 3: Metadata exposure/ISO kamera
- **Cara kerja**: baca nilai exposure/ISO dari frame metadata.
- **Kekurangan**: package `camera ^0.11.0` tidak mengekspos ISO/exposure mentah secara konsisten lintas device; auto-exposure justru mengompensasi kegelapan sehingga menyesatkan. Kalah dari analisis luma langsung.

## Rekomendasi Fitur 2
**Opsi 1 (luma Y-plane + variance).** Tidak perlu model ML — image processing sederhana cukup. Desain `LightService` sebagai shared service: satu konsumen frame Y-plane yang dipanggil Cari Objek (isi `tooDark`/CO-19 secara lokal, mengurangi ketergantungan server `invalid_frame`), Navigasi, dan Live Assistant (trigger flashlight). Kalibrasi ambang lewat telemetri (`/api/events` sudah ada). Variance/histogram spread WAJIB dipakai untuk membedakan kamera tertutup — ini masalah false-positive nyata untuk tunanetra.

## Ditemukan tapi tidak disarankan
- **Model ML klasifikasi cahaya** — overkill; luma statistik sudah cukup akurat dan jauh lebih murah.

## Pertanyaan buat user
1. Perlu output lux absolut, atau kategori (gelap/redup/terang) cukup?
2. Light Detection sebagai fitur voice command mandiri ("apakah lampu menyala?") atau hanya shared service internal?

---

# FITUR 3: Live Visual Assistant ala Project Astra — PALING KOMPLEKS

## Requirement & UX Goal
Asisten yang "melihat" real-time via kamera sambil user gerakkan HP, ngobrol natural (voice in/out) tanpa foto manual: live scene description, text recognition, object localization ("di kanan atas"), kontrol flashlight otomatis, voice interface tanpa menu. Harus realistis dengan Flutter+FastAPI TANPA infrastruktur seberat Google, dan layak di device RAM 4–6GB + kuota data Indonesia.

## Opsi Arsitektur A: Streaming video kontinu ke server (WebRTC/WebSocket)
- **Cara kerja**: stream frame kontinu ke FastAPI, server jalankan vision.
- **Bandwidth**: streaming video 1 FPS 640×480 JPEG (~40KB/frame) = ~2.4MB/menit; 5 FPS = ~12MB/menit. Untuk kuota Indonesia (~Rp1.000–3.000/GB), 1 jam pemakaian 1 FPS ≈ 144MB ≈ Rp150–450. Layak untuk sesi pendek, boros untuk terus-menerus.
- **Kekurangan**: device low-end berat untuk encode+stream kontinu; Vinara tidak punya `webrtc` di pubspec (harus tambah dependency besar).

## Opsi Arsitektur B: Gemini Live API (streaming multimodal native)
- **Cara kerja**: WebSocket stateful, stream audio+video, terima suara balik. Ini yang paling mendekati Astra.
- **Batasan konkret (Google official)**: sesi audio+video **maks 2 menit** tanpa context compression (audio-only 15 menit); video diproses **1 FPS @ 768×768**, **258 token/detik** untuk video, **25 token/detik** audio; context window 128K. Dengan sliding-window compression, durasi bisa diperpanjang (ai.google.dev/gemini-api/docs/live-api/best-practices).
- **Biaya**: model native-audio 2.5 Flash = $0.50/M teks input, **$3.00/M audio-video input**, $12/M audio output. Per-menit ekuivalen Gemini 3.1 Flash Live preview ≈ **$0.005/menit audio in, $0.018/menit audio out** (rywalker.com/research/gemini-live-api). Video menambah 258 token/detik = 15.480 token/menit × $3/M ≈ **$0.046/menit video**. Jadi percakapan aktif audio+video ≈ **$0.05–0.07/menit** (~Rp800–1.100/menit). 10 menit/hari × 30 hari × 100 user ≈ $1.500–2.100/bulan — MAHAL untuk skala.
- **Region Indonesia**: ⚠️ ketersediaan region Live API untuk asia-southeast2 (Jakarta) BELUM terverifikasi dari dokumen resmi; perlu cek cloud.google.com/vertex-ai/generative-ai/docs/learn/locations.
- **Kelebihan**: pengalaman paling mulus, natural barge-in built-in.
- **Kekurangan**: biaya tinggi, sesi video pendek, ketergantungan penuh online, region belum pasti. Live API server-to-server only → FastAPI harus jadi perantara.

## Opsi Arsitektur C: Hybrid pintar — on-device gate + capture frame periodik (DIREKOMENDASIKAN)
- **Cara kerja**: SSD MobileNet on-device (SUDAH ADA) jadi *trigger/gate* yang menentukan KAPAN kirim frame ke vision API. Kirim frame hanya saat: (a) user bertanya, (b) scene berubah signifikan (frame differencing / semantic change: himpunan label deteksi berubah), (c) deteksi danger baru. Antara trigger, jawab dari konteks terakhir + deteksi lokal.
- **Biaya**: alih-alih streaming kontinu, mungkin hanya 3–10 frame vision API per percakapan. Dengan Gemini Flash-Lite ~$0.0004/frame → **<$0.005 per percakapan** (~Rp8). Ini 10× lebih murah dari Gemini Live.
- **Teknik**: keyframe selection, scene change detection via perbandingan histogram luma (pakai `LightService`!) atau perubahan set label deteksi. FramePacer existing (buang frame saat in-flight) sudah pola yang tepat.
- **Kelebihan**: murah, hemat kuota, memanfaatkan aset on-device, offline-tolerant (deteksi lokal tetap jalan).
- **Kekurangan**: tidak se-"live" Astra (ada jeda trigger), STT masih push-to-talk kecuali ditambah wake word/VAD.

## Opsi Arsitektur D: On-device VLM (Gemini Nano via ML Kit GenAI / SmolVLM / Moondream)
- **ML Kit GenAI Image Description** (developers.google.com/ml-kit/genai/image-description): pakai Gemini Nano via AICore. TAPI hanya jalan di device flagship (Pixel 8+, Galaxy S24+, chip MediaTek Dimensity/Snapdragon/Tensor tertentu) — **TIDAK jalan di device kelas bawah Indonesia (RAM 4–6GB, Snapdragon 6xx/Helio G)**. Prompt API masih Alpha, terbaik di Pixel 10 (nano-v3).
- **SmolVLM (2.2B)**: encode 384×384 patch = 81 token, hemat memori; SmolVLM-256M <1GB GPU. Moondream 0.5B/2B ada int4/int8 QAT untuk mobile. MobileVLM-3B: 21.5 token/detik di Snapdragon 888 CPU.
- **Kekurangan**: di device 4–6GB, VLM 2B+ berebut RAM dengan kamera+TFLite existing → risiko OOM & thermal throttling; token/detik rendah (~20 t/s) bikin deskripsi terasa lambat. Realistis hanya di flagship.
- **Rekomendasi**: JANGAN andalkan on-device VLM untuk device target sekarang; simpan sebagai opsi masa depan / khusus flagship.

## OpenAI Realtime API (untuk kelengkapan)
- **Vision**: mendukung **input gambar (still), BUKAN video streaming** — sistem "treats it more like adding a picture into the conversation" (openai.com/index/introducing-gpt-realtime/). Jadi bukan live video seperti Gemini Live.
- **Biaya**: gpt-realtime audio input $32/M, output $64/M (resmi OpenAI). ⚠️ Harga image input flagship (~$5/M) berasal dari tracker pihak ketiga, belum diverifikasi di platform.openai.com/docs/pricing.
- **Kesimpulan**: kalah dari Gemini Live untuk kasus "live vision" karena tidak streaming video; tidak direkomendasikan untuk Vinara.

## Self-host VLM di cloud GPU (jika volume besar & privasi)
- **Harga GPU** (RunPod Secure Cloud, verifikasi 2026-07-30): NVIDIA **L4 24GB $0.39/jam**, **RTX A5000 24GB $0.27/jam**, **A100 PCIe 80GB $1.39/jam**, A100 SXM 80GB $1.49/jam.
- **Throughput Qwen2.5-VL-7B**: di A100 40GB (vLLM benchmark, GitHub vllm #24728) = **20,89 request gambar/detik** vs hanya **7,35 request video/detik** @ concurrency 50. Ini mengukur overhead video vs gambar. ⚠️ Tidak ada angka throughput publik untuk L4/A10/T4.
- **Kesimpulan**: self-host baru masuk akal di skala ribuan user aktif dengan volume tinggi; di bawah itu, API pay-per-use (Gemini/Claude) lebih murah + tanpa ops overhead. Untuk MVP, JANGAN self-host.

## Desain UX voice hands-free
- **Wake word**: Picovoice Porcupine mendukung English, Mandarin, Prancis, Jerman, Italia, Jepang, Korea, Portugis, Spanyol — **Bahasa Indonesia TIDAK didukung** built-in ("Support for additional languages is available for commercial customers on a case-by-case basis", github.com/Picovoice/porcupine). Lisensi enterprise mahal (dilaporkan Foundation Plan ~$6.000). openWakeWord/Vosk open-source bisa dilatih ID tapi butuh effort. → **Wake word bahasa Indonesia native BELUM realistis** dari vendor jadi.
- **Rekomendasi**: pertahankan **push-to-talk (SUDAH ADA)** sebagai default + tambah **VAD (Voice Activity Detection)** sebagai jalan tengah untuk hands-free dalam mode Live (Picovoice Cobra VAD, atau `speech_to_text` `listenFor` diperpanjang). Continuous listening boros baterai & privasi.
- **Barge-in & echo (masalah nyata)**: `flutter_tts` + `speech_to_text` berebut audio session Android — ada bug terdokumentasi (github dlutton/flutter_tts #308: memulai STT saat TTS jalan bisa "mem-block" TTS). Solusi: gunakan `audio_session` package untuk konfigurasi kategori & focus; terapkan **half-duplex gating** (matikan STT saat TTS bicara untuk frasa kritis, aktifkan setelahnya) untuk hindari mic menangkap suara TTS sendiri. AEC penuh sulit di Flutter murni. `TtsQueue` + `interruptByUser()` existing sudah fondasi bagus untuk barge-in terkontrol.

## Object localization dengan arah relatif
Manfaatkan stack ada: bbox on-device + `_getDirection` (3-zona) + field `vertical` server (atas/tengah/bawah — SUDAH dihitung tapi belum dipakai!). Petakan bbox → frasa: gabungkan horizontal (kiri/depan/kanan) + vertical (atas/tengah/bawah) = "kanan atas", "kiri bawah". Clock-face ("jam 2") berguna untuk presisi tapi riset O&M menyarankan kiri/kanan egocentric untuk mayoritas kasus; pakai clock-face hanya saat user minta presisi. AKTIFKAN field `vertical` yang sudah ada.

## Kontrol flashlight di Flutter
- Package `torch_light` (pub.dev/packages/torch_light) atau `camera` `setFlashMode(FlashMode.torch)`. Konflik: saat kamera dipakai stream, `torch_light` bisa lempar `EnableTorchExistentUserException` ("camera in use"). Karena Vinara pakai `camera` untuk stream, gunakan `CameraController.setFlashMode(FlashMode.torch)` (satu controller, hindari konflik) BUKAN torch_light terpisah.
- **UX suara**: `LightService` deteksi gelap → asisten tawarkan via suara "Sekitar gelap, nyalakan senter?" → konfirmasi voice → nyalakan. `permission_handler ^11.3.1` sudah ada.

## Anti-tumpang-tindih: satu MODE terpadu, bukan fitur redundant
Jangan bikin Live Assistant sebagai fitur terpisah dari Scene Description + Cari Objek. Usulkan **`LiveAssistantProvider` dengan tool-calling/function-calling**: LLM (Claude/Gemini mendukung tool use) memanggil "cari objek", "baca teks", "deskripsikan scene", "nyalakan senter" sebagai tools, dipetakan ke 20 intent lokal `CommandParser` + provider existing (`FindObjectProvider`, `OcrService`, dll). Ini menyatukan Asisten Suara + Object Finding + Scene Description dalam satu interaksi voice-first. Layer 1 (keyword lokal 0ms) tetap jadi fast-path; Layer 2 LLM tool-calling untuk yang kompleks.

## Rekomendasi Fitur 3
**Opsi C (hybrid gate + frame periodik) sebagai fondasi, dengan `LiveAssistantProvider` + tool-calling.** Alasan: 10× lebih murah dari Gemini Live, hemat kuota Indonesia, memanfaatkan SSD MobileNet + LightService + deteksi terstruktur yang SUDAH ada, dan offline-tolerant. Pertahankan push-to-talk + tambah VAD untuk hands-free. Gemini Live API disimpan sebagai mode "premium/flagship" opsional bila budget & region memungkinkan. On-device VLM TIDAK untuk device target sekarang.

## Ditemukan tapi tidak disarankan
- **Gemini Live API sebagai default** — biaya ~Rp800–1.100/menit terlalu mahal untuk pasar Indonesia di skala; sesi video 2 menit; region belum pasti.
- **OpenAI Realtime API untuk live vision** — hanya input gambar still, bukan video streaming.
- **Wake word Picovoice Porcupine bahasa Indonesia** — tidak didukung + lisensi mahal.
- **On-device VLM (Gemini Nano/SmolVLM)** — tidak jalan di RAM 4–6GB / chip entry; hanya flagship.
- **WebRTC streaming kontinu** — dependency berat, boros device low-end.

## Pertanyaan buat user
1. Budget API bulanan untuk fitur live (menentukan hybrid vs Gemini Live)?
2. Target device minimum (menentukan kelayakan on-device VLM)?
3. Hands-free wajib, atau push-to-talk + VAD cukup untuk v1?
4. Boleh stream gambar ke cloud (privasi)?

---

# FITUR 4: Perbaikan Cari Objek / Object Finding

## Requirement & UX Goal
Berdasarkan ReCog (CHI 2020) & VizWiz::LocateIt: granularitas jarak kategori kasar; sonifikasi (beep tempo/pitch/volume + kiri/kanan/atas/bawah); disambiguasi objek serupa; scanning/sweep guidance; camera framing feedback kontinu.

## Audit implementasi sekarang vs 5 poin target
1. **Granularitas jarak kasar**: SEBAGIAN. Ada threshold-crossing `[0.6, 1.0, 2.0, 3.0]` tapi diumumkan sebagai angka presisi, bukan kategori "dekat/sedang/jauh". PERLU REVISI: umumkan kategori, angka presisi hanya saat sangat dekat (<0.6m).
2. **Sonifikasi**: TIDAK ADA sama sekali (hanya TTS + vibration per arah). PERLU DIBANGUN.
3. **Disambiguasi objek serupa**: TIDAK ADA (hanya count + nearest). `vertical` dihitung server tapi tidak dipakai. PERLU: umumkan tiap instans saat kamera menyapu dengan clock-position + jarak.
4. **Scanning/sweep guidance**: SEBAGIAN — ada "putar badan pelan-pelan" tiap 6 tick, tapi tidak ada feedback eksplisit saat objek masuk/keluar frame. `lostFromView` ada di enum tapi TIDAK PERNAH di-set. PERLU DIPERBAIKI.
5. **Camera framing feedback kontinu**: TIDAK ADA. PERLU sonifikasi kontinu.

## Opsi sonifikasi real-time di Flutter
- **Opsi 1 — `flutter_soloud` (DIREKOMENDASIKAN)**: engine C++ SoLoud low-latency, bisa **generate waveform real-time (sine/square/saw/triangle)**, buffer stream PCM, efek pitch shift, 3D positional/panning (pub.dev/packages/flutter_soloud). Cocok untuk beep dinamis: ubah frekuensi/tempo/volume/pan real-time berdasarkan jarak & arah tanpa file statis.
- **Opsi 2 — `flutter_pcm_sound`**: kirim PCM 16-bit real-time via callback, nol dependency selain platform. Bagus untuk sintesis tone kustom penuh; lebih low-level.
- **Opsi 3 — `just_audio` + tone bank pre-generated / `soundpool`**: play file tone dengan playbackRate. Kurang fleksibel untuk pitch/tempo kontinu; latency lebih tinggi.
- **Audio focus conflict**: sonifikasi + `flutter_tts` + `speech_to_text` berebut audio session Android. Gunakan `audio_session` untuk kategori "playback + mixWithOthers/duck"; beep di-duck saat TTS critical bicara. flutter_soloud dan flutter_tts bisa koeksis bila kategori diset benar.

## Mapping parameter sonifikasi (berbasis literatur, bukan asumsi)
Studi **Bazilinskyy et al. (2016, IFAC-PapersOnLine 49(19):531–536, DOI 10.1016/j.ifacol.2016.10.614, N=29)** membandingkan 3 metode: **Beep Repetition Rate (BRR)** — tempo beep fungsi jarak; **Sound Intensity (SI)** — volume fungsi jarak; **Sound Fundamental Frequency (SFF)** — pitch fungsi jarak; azimuth/arah dipetakan lewat **beda volume kiri-kanan (stereo panning)**. Studi **Delaunay & Ambard ("How well do you see what you hear?", 28 partisipan)** menemukan: "The best depth estimates... were obtained with the sound frequency and the repetition rate of beeps... the beep repetition rate yielded the best depth estimation." Rekomendasi mapping Vinara:
- **Jarak → tempo (BRR)**: makin dekat, makin cepat (mis. 2 Hz @ 3m → 8 Hz @ 0.6m). Utama.
- **Jarak → pitch (opsional redundan)**: The Sonification Handbook memperingatkan mapping redundan pitch+tempo TIDAK selalu memperbaiki performa — jangan berlebihan. Cukup tempo + panning.
- **Arah horizontal → stereo panning** (pakai headphone/speaker stereo).
- **Vertical (atas/bawah) → pitch dasar** (atas=pitch tinggi, bawah=rendah) — memanfaatkan `vertical` server yang ada.
- **Objek dalam frame → earcon "found"** yang beda dari sweep tone.
CATATAN spatial audio: teknik panning stereo di sini adalah reuse ringan dari konsep spatial audio (yang dicoret sebagai fitur mandiri) — hanya panning L/R, bukan 3D beacon.

## Estimasi jarak: bbox similar-triangle vs depth estimation
- **Sekarang**: similar-triangle `FOCAL_LENGTH_PX=615`. Kelemahan: butuh kalibrasi per-device (fokus px beda tiap kamera), objek tidak tegak/terpotong bikin error besar, tinggi asli bervariasi (`DEFAULT_HEIGHT_CM=20` kasar). Untuk kategori kasar (dekat/sedang/jauh) ini CUKUP.
- **Depth estimation on-device**: MiDaS v2 TFLite = 66.3MB; di NPU flagship (Galaxy S23) ~1–3ms, tapi rentang 2.1–84.5ms tergantung device — di Snapdragon 6xx/Helio G CPU jauh lebih lambat (huggingface.co/qualcomm/Midas-V2). Depth Anything V2 Small (25M param) bagus tapi berat untuk entry Android. Jalan BERSAMAAN dengan SSD MobileNet = beban ganda, risiko thermal.
- **Rekomendasi**: PERTAHANKAN similar-triangle untuk kategori jarak kasar (murah, cukup). Depth estimation TIDAK sepadan untuk device target sekarang.

## Pipeline & jalur on-device untuk Cari Objek
- **Usulan penting**: kalau target Cari Objek termasuk 80 kelas COCO yang SUDAH bisa dideteksi SSD MobileNet on-device → jalankan LOKAL (lebih responsif, offline, tanpa server round-trip). Hanya kalau target DI LUAR COCO → baru pakai YOLOE server. Ini memberi jalur offline yang sekarang tidak ada (Cari Objek 100% server).
- **Alternatif open-vocab lebih ringan dari YOLOE untuk server**: YOLO-World (Tencent, prompt-then-detect, ~74 FPS di V100, mAP LVIS ~35.4) lebih cepat dari Grounding DINO (mAP lebih tinggi ~52.5 tapi lambat, API-based). OWLv2 (mAP ~47) punya implementasi HuggingFace. Untuk real-time server, YOLO-World unggul throughput; YOLOE (existing) sudah masuk akal karena open-vocab + seg. Grounding DINO hanya bila akurasi zero-shot kritis.

## Rekomendasi Fitur 4
1. **Bangun sonifikasi dengan `flutter_soloud`**: jarak→tempo (BRR), arah→panning stereo, vertical→pitch. Ini prioritas tertinggi karena benar-benar hilang.
2. **Ubah granularitas jarak jadi kategori** (dekat/sedang/jauh), angka presisi hanya <0.6m.
3. **Aktifkan `vertical`** untuk clock-position/atas-bawah dalam disambiguasi & sonifikasi.
4. **Perbaiki state `lostFromView`** (set saat objek keluar frame) + earcon masuk/keluar frame.
5. **Tambah jalur on-device** untuk target COCO (offline + responsif); YOLOE server hanya untuk non-COCO.
Pertahankan similar-triangle (jangan tambah depth model). Semua ini menghormati loop 350ms + FramePacer 600ms existing.

## Ditemukan tapi tidak disarankan
- **Monocular depth (MiDaS/Depth Anything) on-device** — terlalu berat jalan bareng SSD MobileNet di device entry; overkill untuk kategori jarak kasar.
- **Grounding DINO server** — akurasi tinggi tapi latency/VRAM besar, tidak real-time untuk sweep.
- **Mapping pitch+tempo redundan penuh** — literatur (Sonification Handbook) menunjukkan tidak menambah performa.

## Pertanyaan buat user
1. User biasanya pakai headphone (panning stereo efektif) atau speaker HP (panning lemah)?
2. Berapa banyak target Cari Objek di luar 80 kelas COCO (menentukan seberapa penting jalur server)?
3. Sonifikasi sebagai default ON atau opsi (beberapa user lebih suka speech saja)?

---

# FITUR 5: Upgrade Navigasi Trotoar — deteksi bahaya & panduan hindari halangan

## Requirement & UX Goal
(a) Deteksi bahaya jalur (lubang, tangga turun, halangan mendadak) dengan peringatan prioritas tinggi; (b) arahan hindari ("ada orang di depan, geser kanan sedikit"). BUKAN face recognition — murni deteksi keberadaan sebagai halangan. Prinsip: egocentric framing, prioritas bahaya > info, framing "jalur aman", hindari overload multimodal.

## Arsitektur pipeline: segmentasi + object detection
- **Kombinasi**: PIDNet-S/SegFormer-B0 (jalur walkable) + SSD MobileNet (halangan) dengan **masking bbox terhadap mask jalur**: hitung IoU/overlap footprint bbox (bagian bawah bbox = titik kontak tanah) dengan region walkable. Kalau footprint objek jatuh DI DALAM jalur aman → itu halangan yang relevan; kalau di luar → abaikan. Ini lebih murah dari occupancy grid penuh.
- **Model multi-task satu forward pass**: YOLOP, HybridNets, YOLOPv2 (deteksi + drivable area + lane dalam satu jaringan). Menarik secara efisiensi tapi dilatih untuk jalan raya mobil, bukan trotoar pejalan → perlu retraining dengan data trotoar. Belum realistis tanpa dataset.

## Deteksi drop-off/tangga turun/lubang
- **Dataset**: **SideGuide** (IROS 2020, Park et al., DOI 10.1109/IROS45743.2020.9340734) — 350K bbox, 100K polygon mask, 180K stereo pair, objek trotoar dari wawancara penyandang disabilitas (curb, stairs, dll). SENSATION-DS (2.752 image chest-view, 9 kelas navigasi). Cityscapes/Mapillary (jalan raya, kurang cocok trotoar). Dataset trotoar Indonesia spesifik: tidak ditemukan — ini gap nyata.
- **Realistis dengan kamera monokuler**: deteksi lubang/curb sebagai OBJEK (bbox/segmentasi) bisa dilatih dari SideGuide. TAPI drop-off/tangga TURUN sangat sulit dari monokuler tanpa depth — depth discontinuity/ground-plane fitting/vanishing point membantu tapi rawan false negative. **Ini fitur safety-critical: risiko false negative tinggi** — jangan janjikan deteksi tangga turun yang andal dari kamera HP saja. Sampaikan keterbatasan ini ke user secara jujur (konsisten dengan prinsip Vinara).

## Menentukan "arah geser" (algoritma konkret)
Backend `segmentation_service.py` sudah bagi frame bawah jadi 3 kolom (kiri/tengah/kanan) dengan `walkable_ratio`. Perluas:
- **Gap analysis per kolom**: cari kolom walkable terlebar / `walkable_ratio` tertinggi = arah geser. Atau hitung **centroid free-space** di separuh bawah frame.
- **Hysteresis** untuk stabilitas: jangan ganti instruksi "geser kanan/kiri" kecuali selisih walkable antar sisi melewati ambang (mis. >15%) DAN bertahan ≥2 frame. Mencegah bolak-balik tiap frame. Ini analog `streak 2 frame` di DetectionFilter existing.
- Output egocentric: "geser kanan sedikit" (relatif badan, bukan kompas).

## Prioritization system
Vinara SUDAH punya `SpeechTier` (info/warning/critical) + DetectionFilter cooldown per tier. Perluas:
- **Time-to-collision (TTC)** dari `isApproaching` ObjectTracker: objek mendekat cepat → naikkan urgency → critical + interrupt. Cooldown sudah dipotong 50% saat isApproaching.
- **Threshold jarak dinamis** mengikuti kecepatan jalan (dari `sensors_plus` accelerometer): jalan cepat → warning lebih dini.
- **Urgency score** = f(jarak, TTC, danger level, di dalam jalur). allDanger → "Berhenti dulu" (critical, sudah ada). Center danger → takeover (sudah ada).
Literatur alert prioritization/interruption management mendukung: bahaya mendadak interupsi, info non-kritis antre (sudah tercermin di TtsQueue: Info dibuang kalau menunggu >2s).

## Performa real-time on-device (benchmark)
- **PIDNet-S**: 78.6% mIoU @ 93.2 FPS di Cityscapes test (RTX GPU — bukan mobile). Di mobile CPU/NNAPI jauh lebih lambat.
- **SegFormer-B0**: ~82.98% mIoU tapi hybrid transformer, lebih berat di CPU.
- **Fast-SCNN / BiSeNetV2 / DDRNet-23-slim**: dirancang real-time, lebih ringan. Fast-SCNN "learning to downsample" sangat ringan.
- **Angka mobile spesifik (Snapdragon 680/695, Helio G85/G99, Exynos 1330)**: ⚠️ benchmark publik langsung TIDAK ditemukan — data tidak tersedia. Yang pasti: transformer (SegFormer) lebih berat dari CNN ringan (Fast-SCNN/PIDNet-S) di mobile CPU.
- **Strategi optimasi**: input resolution lebih kecil (512→384/256), **INT8 quantization**, **NNAPI/GPU delegate** di `tflite_flutter ^0.12.1`, **frame skipping / temporal alternation** (segmentasi tiap N frame, deteksi tiap frame), **IsolateInterpreter terpisah** (sudah dipakai). 
- **Server vs on-device**: sekarang Navigasi 100% server (offline = berhenti total). Memindah segmentasi on-device memberi offline-capability tapi berat di device entry. **Rekomendasi**: tetap server-primary untuk segmentasi (PIDNet ONNX saat model tersedia), tapi tambah **fallback on-device ringan** (mis. heuristik OpenCV yang sudah ada dijalankan lokal, atau Fast-SCNN INT8) agar offline tidak "berhenti total". CATATAN: model PIDNet (`pidnet_s_3zona.onnx`) BELUM ADA — sekarang jalan heuristik OpenCV; field `source` jujur melaporkan ini.

## TTS responsif & bisa diinterupsi untuk urgent alert
- `flutter_tts` `stop()` + `speak()` di Android: ada latency kecil; `awaitSpeakCompletion(true)` bisa menghambat interupsi cepat. Untuk alert kritis ("Berhenti!"), latency TTS berbahaya.
- **Rekomendasi**: gunakan **pre-rendered audio clip / earcon** untuk frasa kritis ("Berhenti!") via `flutter_soloud` (latency ~0), BUKAN TTS sintesis on-the-fly. Riset auditory display: earcon non-speech lebih cepat dipahami daripada speech untuk alert mendesak. TtsQueue Critical (clear+interrupt) sudah ada; tambahkan jalur earcon paralel untuk kritis. Native `TextToSpeech` QUEUE_FLUSH via platform channel bila perlu kontrol lebih.

## Rekomendasi Fitur 5
1. **Segmentasi (server-primary, PIDNet-S ONNX saat model jadi) + SSD MobileNet halangan, digabung via footprint-in-walkable masking.**
2. **Arah geser via gap analysis per kolom + hysteresis** (hormati pola streak existing).
3. **Prioritization**: perluas SpeechTier dengan TTC + urgency score + threshold dinamis dari accelerometer.
4. **Earcon pre-rendered untuk "Berhenti!"** (latency ~0) via flutter_soloud, jangan TTS.
5. **Fallback on-device ringan** (Fast-SCNN INT8 atau heuristik lokal) agar offline tidak berhenti total.
6. **Jujur soal keterbatasan** deteksi tangga turun/drop-off monokuler (risiko false negative) — jangan over-promise.

## Ditemukan tapi tidak disarankan
- **YOLOP/HybridNets/YOLOPv2 multi-task** — dilatih untuk jalan raya mobil, butuh retraining data trotoar yang belum ada.
- **Deteksi tangga turun andal dari monokuler** — risiko false negative terlalu tinggi untuk safety-critical tanpa depth sensor.
- **SegFormer-B0 on-device di device entry** — transformer terlalu berat; pilih CNN ringan bila on-device.
- **Multimodal overload** (haptik+audio+speech bersamaan) — riset EEG menunjukkan menambah beban kognitif.

## Pertanyaan buat user
1. Prioritas: offline-capability (perlu segmentasi on-device) vs akurasi (server)?
2. Ada akses ke dataset trotoar Indonesia, atau perlu andalkan SideGuide + fine-tune?
3. Target device minimum untuk fitur navigasi (menentukan model segmentasi)?
4. Terima keterbatasan jujur "tidak bisa jamin deteksi tangga turun"?

---

# BAGIAN C: Tumpang Tindih Mode Tuntun vs Navigasi Jalur

**Rekomendasi tegas: JANGAN lebur total; jadikan dua mode dengan pembagian use-case JELAS + auto-switch kontekstual, dan bedakan Mode Tuntun menjadi fokus rintangan level mata/kepala.**

## Alasan teknis
1. **Satu `CameraController` tidak bisa dilayani dua konsumen ML berat sekaligus** di Android. Menjalankan Mode Tuntun (SSD MobileNet) DAN Navigasi (segmentasi) paralel dari satu stream = rebutan frame + CPU/RAM ganda + thermal throttling di device entry. Jadi 2 mode PARALEL boros/redundant — harus satu mode aktif pada satu waktu.
2. **Melebur total juga tidak optimal**: segmentasi trotoar (mask jalur) dan deteksi objek umum (indoor/jalan bebas) punya tujuan berbeda. Trotoar butuh walkable-region; indoor butuh deteksi objek murni.

## Usulan pembedaan (menjawab opsi 2 & 3)
- **Navigasi Jalur** = khusus trotoar outdoor: segmentasi jalur + halangan di jalur + hazard.
- **Mode Tuntun diubah** = fokus **rintangan level mata/dada/kepala** (dahan pohon, kanopi rendah, palang, papan reklame rendah) + rintangan indoor/jalan bebas. Ini menutup **kelemahan klasik tongkat putih yang terdokumentasi di literatur O&M**: tongkat hanya menyapu bawah, tidak mendeteksi rintangan level kepala. Riset head-level obstacle: "User Evaluation of Head-Level Obstacle Detector for Visually Impaired" (Technologies 2025, doi:10.3390/technologies13090407) menegaskan tongkat putih hanya deteksi rintangan bawah & posisi/mounting detektor krusial; banyak sistem pakai ultrasonic/LiDAR di kepala. Vinara bisa mendekati ini via **sudut kamera/pitch HP**: baca accelerometer `sensors_plus` (SUDAH dipakai untuk camera health) untuk tahu apakah HP diarahkan ke depan/atas (deteksi level kepala) vs ke bawah/trotoar (Navigasi). Ini pembeda produk yang kuat dan jarang ada di produk lain (kebanyakan butuh hardware tambahan).

## UX mode-switching (menjawab opsi 4)
Riset UX assistive navigation menekankan **mode-switching burden** memberatkan pengguna tunanetra. Solusi:
- **Auto-switch berbasis konteks**: gunakan pitch HP (accelerometer) + LightService + hasil segmentasi untuk menebak konteks. HP diarahkan ke depan/atas & ada langit/kanopi → Mode Tuntun (level kepala); HP menunduk ke trotoar & terdeteksi jalur → Navigasi Jalur. 
- **Tetap sediakan override manual** via voice ("mode tuntun", "mode navigasi") lewat CommandParser (20 intent).
- **Satu tombol "mulai jalan"** yang otomatis memilih mode berdasarkan konteks, dengan pengumuman mode aktif ("Mode trotoar aktif") supaya user tidak bingung.

## Pertimbangan resource
Karena satu kamera = satu konsumen aktif, auto-switch memastikan hanya SATU model ML berat jalan pada satu waktu → hemat CPU/RAM/thermal/baterai. Ini alasan teknis kuat untuk auto-switch dibanding dua mode paralel.

---

# PENUTUP

## Dependency & Urutan Pengerjaan
1. **Fitur 2 (Light Detection) DULU** — paling murah, jadi fondasi shared service (`LightService`) yang dipakai Fitur 3 (trigger flashlight & scene-change gate), Fitur 4 (deteksi tooDark), Fitur 5.
2. **Fitur 4 (Perbaikan Cari Objek)** — bangun infrastruktur **sonifikasi `flutter_soloud`** yang akan dipakai ulang untuk earcon Fitur 5. Aktifkan `vertical`, jalur on-device COCO.
3. **Fitur 5 (Navigasi upgrade)** — pakai sonifikasi/earcon dari Fitur 4, prioritization SpeechTier, footprint masking. Juga menyiapkan pola deteksi-di-jalur untuk Mode Tuntun.
4. **Fitur 1 (Scene Description hybrid grounding)** — perluas `/api/narasi` dengan gambar + grounding; fondasi VLM untuk Fitur 3.
5. **Fitur 3 (Live Assistant) TERAKHIR** — butuh Fitur 1 (VLM), Fitur 2 (gate/flashlight), Fitur 4 (object localization), dan deteksi Fitur 5 sudah jalan; menyatukan semua via `LiveAssistantProvider` + tool-calling.

## Potensi Konflik Teknis (antisipasi sejak awal)
- **Rebutan kamera**: satu `CameraController`, banyak konsumen. WAJIB arsitektur satu-konsumen-aktif + frame fan-out terkontrol. FramePacer existing sudah pola tepat. Jangan dua mode ML paralel.
- **Rebutan audio session Android**: `flutter_tts` + `speech_to_text` + sonifikasi `flutter_soloud` berebut audio focus → echo (mic tangkap TTS), bug blocking (dlutton/flutter_tts #308). Solusi: `audio_session` untuk kategori/ducking; half-duplex gating STT saat TTS critical; earcon di-duck.
- **CPU/RAM budget**: beberapa TFLite (SSD MobileNet + segmentasi + depth) bersamaan = OOM/thermal di device 4–6GB. Solusi: satu model berat aktif, IsolateInterpreter, INT8, frame skipping.
- **Thermal throttling**: inferensi kontinu + kamera + flashlight memanaskan device entry → turunkan clock → latency naik. Solusi: adaptive frame rate, matikan flashlight bila tak perlu.
- **Konsumsi kuota data**: fitur server (Navigasi, Cari Objek, Live, Narasi) makan kuota. Solusi: hybrid gate (kirim frame hanya saat perlu), JPEG quality adaptif, jalur on-device untuk yang bisa lokal, idempotency + offline queue (sudah ada).

## Tabel Ringkasan Opsi

| Fitur | Opsi | Offline | Latency estimasi | Biaya | Effort | Rekomendasi |
|---|---|---|---|---|---|---|
| 1 Scene Desc | Gemini Flash-Lite + grounding | Tidak | ~1–2s + jaringan | ~Rp5–8/query | Sedang | ✅ Ya |
| 1 Scene Desc | Claude Haiku 4.5 vision | Tidak | ~1–2s + jaringan | ~Rp24/query | Sedang | ✅ Fallback |
| 1 Scene Desc | Pipeline 2 model | Tidak | ~3–4s | Lebih mahal | Tinggi | ❌ Tidak |
| 2 Light | Luma Y-plane + variance | Ya | <1ms | Rp0 | Rendah | ✅ Ya |
| 2 Light | Ambient light sensor | Ya | ~instant | Rp0 | Rendah | ❌ Tidak (sensor sering absen) |
| 3 Live | Hybrid gate + frame periodik | Sebagian | ~1–2s/trigger | ~Rp8/percakapan | Tinggi | ✅ Ya |
| 3 Live | Gemini Live API | Tidak | Real-time | ~Rp800–1.100/mnt | Sedang | ⚠️ Premium opsional |
| 3 Live | OpenAI Realtime (vision) | Tidak | Real-time | audio $32/$64 per 1M | Sedang | ❌ Tidak (still image only) |
| 3 Live | On-device VLM (Nano/SmolVLM) | Ya | Lambat (~20t/s) | Rp0 | Tinggi | ❌ Hanya flagship |
| 4 Cari Objek | Sonifikasi flutter_soloud | Ya | <50ms | Rp0 | Sedang | ✅ Ya |
| 4 Cari Objek | Jalur on-device COCO | Ya | ~real-time | Rp0 | Sedang | ✅ Ya |
| 4 Cari Objek | Depth (MiDaS/DepthAnything) | Ya | Berat di entry | Rp0 | Tinggi | ❌ Tidak |
| 4 Cari Objek | YOLO-World server (non-COCO) | Tidak | ~server | GPU | Sedang | ✅ Untuk non-COCO |
| 5 Navigasi | Segmentasi server + SSD + masking | Tidak | ~server | GPU | Tinggi | ✅ Ya |
| 5 Navigasi | Fallback on-device Fast-SCNN INT8 | Ya | Sedang | Rp0 | Tinggi | ✅ Ya |
| 5 Navigasi | SegFormer-B0 on-device entry | Ya | Berat | Rp0 | Tinggi | ❌ Tidak |
| 5 Navigasi | Earcon pre-rendered "Berhenti!" | Ya | ~0ms | Rp0 | Rendah | ✅ Ya |

## Fitur yang tidak dibahas (sesuai batasan)
Color detection, barcode/product recognition, face/person recognition & identifikasi, remote sighted assistance, GPS turn-by-turn + POI, spatial/3D audio beacon, handwriting recognition — TIDAK direkomendasikan sesuai instruksi. Teknik panning stereo dari spatial audio hanya dipakai ringan sebagai catatan untuk sonifikasi Cari Objek, bukan fitur beacon mandiri.

---

## Referensi Kunci (untuk verifikasi klaim)
- Claude Haiku 4.5 pricing — anthropic.com/claude/haiku ($1/M input, $5/M output; cache read $0.10/M, write $1.25/M).
- Gemini pricing — ai.google.dev/gemini-api/docs/pricing (2.5 Flash-Lite $0.10/$0.40; batch $0.05/$0.20; 3.1 Flash-Lite $0.25/$1.50).
- Anthropic image tokens — `(w×h)/750`; prompt caching — platform.claude.com/docs/en/build-with-claude/prompt-caching.
- Gemini Live API limits — ai.google.dev/gemini-api/docs/live-api/best-practices (audio+video 2 min, video 258 TPS @ 1 FPS).
- OpenAI Realtime — openai.com/index/introducing-gpt-realtime/ (image still only; audio $32/$64 per 1M).
- CHI 2024 scene description trust — arXiv:2403.15604 (trust 2,43/4; satisfaction 2,76/5); ASSETS 2024 "Misfitting With AI" dl.acm.org/doi/10.1145/3663548.3675659.
- Sonifikasi — Bazilinskyy et al. 2016 (DOI 10.1016/j.ifacol.2016.10.614, N=29, BRR/SI/SFF + panning); Delaunay & Ambard (repetition rate best depth); The Sonification Handbook (redundant mapping caveat).
- Picovoice Porcupine languages — github.com/Picovoice/porcupine (ID tidak didukung built-in).
- MiDaS-V2 TFLite — huggingface.co/qualcomm/Midas-V2 (66.3MB, 2.1–84.5ms).
- PIDNet-S — 78.6% mIoU @ 93.2 FPS Cityscapes (arXiv:2206.02066); SideGuide — DOI 10.1109/IROS45743.2020.9340734.
- Head-level obstacle — doi:10.3390/technologies13090407.
- Flutter: flutter_soloud (pub.dev/packages/flutter_soloud), torch_light (pub.dev/packages/torch_light), flutter_tts↔speech_to_text konflik (github dlutton/flutter_tts #308).
- ML Kit GenAI / Gemini Nano — developers.google.com/ml-kit/genai/image-description (flagship only).
- RunPod GPU — L4 24GB $0.39/jam, A5000 24GB $0.27/jam, A100 80GB $1.39/jam; Qwen2.5-VL-7B A100 40GB 20,89 img req/s vs 7,35 video req/s (github vllm #24728).
```

---

## File: `db/database.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/database.py`

```python
"""Koneksi PostgreSQL + bootstrap skema.

Sengaja pakai SQLAlchemy Core (bukan ORM) supaya query tetap SQL biasa yang
gampang dibaca, tanpa lapisan model tambahan. Tanpa auth: identifikasi cukup
device_id anonim yang di-generate aplikasi.
"""

import os
from pathlib import Path

from loguru import logger
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

_engine: Engine | None = None
_available = False

SCHEMA_PATH = Path(__file__).parent / "schema.sql"


def _build_url() -> str:
    """URL koneksi dari .env. DATABASE_URL menang bila diisi."""
    explicit = os.getenv("DATABASE_URL", "").strip()
    if explicit:
        return explicit
    host = os.getenv("PGHOST", "localhost")
    port = os.getenv("PGPORT", "5432")
    user = os.getenv("PGUSER", "postgres")
    pwd = os.getenv("PGPASSWORD", "")
    name = os.getenv("PGDATABASE", "vinara_dev")
    return f"postgresql+psycopg://{user}:{pwd}@{host}:{port}/{name}"


def init_db() -> bool:
    """Buat engine, jalankan skema (idempoten), seed data rujukan.

    Mengembalikan False kalau database tidak terjangkau — server TETAP jalan,
    hanya endpoint yang butuh DB yang menyerah dengan pesan jelas. Prinsip
    "tidak ada jalan buntu" berlaku juga untuk backend.
    """
    global _engine, _available
    try:
        _engine = create_engine(
            _build_url(),
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=5,
            future=True,
        )
        with _engine.begin() as conn:
            conn.execute(text(SCHEMA_PATH.read_text(encoding="utf-8")))
        _available = True
        logger.success("PostgreSQL terhubung, skema siap")

        from db.seed import seed_all

        seed_all()
        return True
    except Exception as e:
        _available = False
        logger.error(f"PostgreSQL tidak terhubung: {e}")
        logger.warning("Server tetap jalan. Endpoint yang butuh DB akan balas 503.")
        return False


def is_available() -> bool:
    return _available


def get_engine() -> Engine:
    if _engine is None:
        raise RuntimeError("Database belum di-init. Panggil init_db() dulu.")
    return _engine


def fetch_all(sql: str, params: dict | None = None) -> list[dict]:
    with get_engine().connect() as conn:
        rows = conn.execute(text(sql), params or {}).mappings().all()
        return [dict(r) for r in rows]


def fetch_one(sql: str, params: dict | None = None) -> dict | None:
    with get_engine().connect() as conn:
        row = conn.execute(text(sql), params or {}).mappings().first()
        return dict(row) if row else None


def execute(sql: str, params: dict | None = None) -> None:
    with get_engine().begin() as conn:
        conn.execute(text(sql), params or {})


def execute_returning(sql: str, params: dict | None = None) -> dict | None:
    with get_engine().begin() as conn:
        row = conn.execute(text(sql), params or {}).mappings().first()
        return dict(row) if row else None
```

---

## File: `db/schema.sql`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/schema.sql`

```sql
-- Skema Vinara/Guidio — PostgreSQL.
-- Tanpa auth: semua identifikasi pakai device_id anonim yang di-generate app.
-- Dijalankan otomatis (idempoten) saat startup oleh db/database.py.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Risk zone — dulu in-memory di risk_zone_service.py, sekarang persisten.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS risk_zones (
    id           BIGSERIAL PRIMARY KEY,
    grid_key     TEXT UNIQUE NOT NULL,          -- lat/lng dibulatkan 4 desimal (~11 m)
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    report_count INTEGER NOT NULL DEFAULT 0,
    labels       JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_seen    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_risk_zones_latlng ON risk_zones (lat, lng);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Kamus label objek — GET /api/labels?lang=id
--    Dipakai DO-19 (kelas tak dikenal) & DO-08 (nama meluap). Nama kelas
--    mentah model tidak layak dibacakan TTS, jadi pemetaannya harus bisa
--    diperbaiki dari server tanpa rilis ulang aplikasi.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS object_labels (
    id             BIGSERIAL PRIMARY KEY,
    label_en       TEXT NOT NULL,
    lang           TEXT NOT NULL DEFAULT 'id',
    label_local    TEXT NOT NULL,                -- "orang"
    spoken_form    TEXT,                         -- frasa TTS bila beda dari label_local
    real_height_cm INTEGER,                      -- untuk estimasi jarak similar-triangle
    danger_class   TEXT NOT NULL DEFAULT 'info', -- high | medium | info
    searchable     BOOLEAN NOT NULL DEFAULT TRUE,-- boleh jadi target Cari Objek
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (label_en, lang)
);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Perintah suara — POST /api/intent
--    20 intent baku bagian 14. CommandParser lokal tetap jalan lebih dulu;
--    server hanya dipanggil saat lokal tidak match (AS-18 / AS-19).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voice_intents (
    id              BIGSERIAL PRIMARY KEY,
    intent_key      TEXT UNIQUE NOT NULL,        -- mode.money, action.capture, ...
    category        TEXT NOT NULL,               -- mode | action | play | help
    spoken_label    TEXT NOT NULL,               -- "kenali uang" (untuk ditawarkan balik)
    requires_server BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS intent_phrases (
    id        BIGSERIAL PRIMARY KEY,
    intent_id BIGINT NOT NULL REFERENCES voice_intents (id) ON DELETE CASCADE,
    phrase    TEXT NOT NULL,
    UNIQUE (intent_id, phrase)
);
CREATE INDEX IF NOT EXISTS idx_intent_phrases_phrase ON intent_phrases (phrase);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Manifest model on-device — GET /api/models/manifest
--    UG-18: emisi uang baru = update model, bukan update aplikasi.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS model_manifest (
    id              BIGSERIAL PRIMARY KEY,
    model_key       TEXT UNIQUE NOT NULL,        -- detection | money | segmentation
    version         TEXT NOT NULL,
    filename        TEXT NOT NULL,
    format          TEXT NOT NULL DEFAULT 'tflite',
    sha256          TEXT,
    size_bytes      BIGINT,
    url_path        TEXT,                        -- relatif: /api/models/download/<key>
    min_app_version TEXT,
    mandatory       BOOLEAN NOT NULL DEFAULT FALSE,
    notes           TEXT,
    available       BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Telemetri alur — POST /api/events
--    Bukan analitik pemasaran. Yang diukur target desain: jumlah gestur per
--    alur, waktu buka sampai deteksi aktif, perintah suara tak dikenali.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS telemetry_events (
    id          BIGSERIAL PRIMARY KEY,
    device_id   TEXT NOT NULL,
    event_name  TEXT NOT NULL,                   -- flow.pay, mode.enter, voice.unrecognized
    mode        TEXT,
    gesture_count INTEGER,
    duration_ms INTEGER,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_telemetry_name_time ON telemetry_events (event_name, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_telemetry_device ON telemetry_events (device_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 6. Laporan crash — POST /api/crash-report (ER-06 "Kirim laporan")
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crash_reports (
    id           BIGSERIAL PRIMARY KEY,
    device_id    TEXT NOT NULL,
    app_version  TEXT,
    platform     TEXT,
    os_version   TEXT,
    mode         TEXT,                            -- mode terakhir saat crash (dipulihkan ER-06)
    error_type   TEXT,
    message      TEXT,
    stack_trace  TEXT,
    occurred_at  TIMESTAMPTZ,
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crash_time ON crash_reports (received_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 7. Antrean unggah offline — POST /api/queue/flush (BT-13)
--    idempotency_key mencegah dobel saat aplikasi mengirim ulang.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS upload_queue (
    id              BIGSERIAL PRIMARY KEY,
    idempotency_key TEXT UNIQUE NOT NULL,
    device_id       TEXT NOT NULL,
    kind            TEXT NOT NULL,                -- ocr | detect
    status          TEXT NOT NULL DEFAULT 'pending', -- pending | done | failed
    result          JSONB,
    error           TEXT,
    queued_at       TIMESTAMPTZ,
    processed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_queue_device_status ON upload_queue (device_id, status);

-- ─────────────────────────────────────────────────────────────────────────
-- 8. Sesi Asisten Suara — AS-12 (giliran terbaru), AS-13 (riwayat diringkas),
--    AS-23 (riwayat kedaluwarsa 15 menit).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assistant_sessions (
    id            BIGSERIAL PRIMARY KEY,
    session_id    TEXT UNIQUE NOT NULL,
    device_id     TEXT NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_activity TIMESTAMPTZ NOT NULL DEFAULT now(),
    expired       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS assistant_turns (
    id         BIGSERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES assistant_sessions (session_id) ON DELETE CASCADE,
    role       TEXT NOT NULL,                     -- user | vinara
    text       TEXT NOT NULL,
    intent_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_turns_session ON assistant_turns (session_id, created_at);

-- ─────────────────────────────────────────────────────────────────────────
-- 9. Denominasi rupiah — data rujukan untuk Mode Kenali Uang.
--    Klasifikasi nominalnya sendiri ON-DEVICE (TFLite), tabel ini dipakai
--    untuk: manifest model, terbilang kata, dan validasi emisi yang didukung
--    (UG-18 "uang asing / rusak" perlu tahu mana yang memang didukung).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS money_denominations (
    id         BIGSERIAL PRIMARY KEY,
    value_idr  INTEGER UNIQUE NOT NULL,
    words      TEXT NOT NULL,                     -- "lima puluh ribu rupiah"
    emissions  TEXT NOT NULL DEFAULT '2016,2022',
    color_name TEXT,
    class_index INTEGER,                          -- urutan kelas di model TFLite
    active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- ─────────────────────────────────────────────────────────────────────────
-- 10. Status kemampuan server — GET /api/capabilities
--     Aplikasi perlu tahu mode mana yang server-nya hidup SEBELUM pengguna
--     menekan tombol (menentukan item limited/disabled di ModePickerSheet).
--     Baris ini bisa di-override manual untuk demo/maintenance.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS capability_overrides (
    id          BIGSERIAL PRIMARY KEY,
    capability  TEXT UNIQUE NOT NULL,             -- ocr | assistant | find_object | navigation
    forced_state TEXT,                            -- up | down | limited | NULL (ikut deteksi otomatis)
    reason      TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## File: `db/seed.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/seed.py`

```python
"""Seed data rujukan: kamus label, 20 intent suara, denominasi rupiah, manifest.

Semua idempoten (ON CONFLICT DO NOTHING / DO UPDATE), aman dijalankan tiap
startup.
"""

from loguru import logger

from db.database import execute, fetch_one

# ── Kamus label objek (COCO → Bahasa Indonesia) ──────────────────────────
# real_height_cm dipakai estimasi jarak similar-triangle di yolo_service.
# danger_class: high = orang/kendaraan, medium = perabot, info = sisanya.
# searchable: boleh jadi target Mode Cari Objek.
LABELS: list[tuple[str, str, int | None, str, bool]] = [
    ("person", "orang", 170, "high", False),
    ("bicycle", "sepeda", 100, "medium", True),
    ("car", "mobil", 150, "high", False),
    ("motorcycle", "motor", 120, "high", False),
    ("bus", "bus", 300, "high", False),
    ("truck", "truk", 280, "high", False),
    ("traffic light", "lampu merah", 300, "info", False),
    ("stop sign", "rambu berhenti", 200, "info", False),
    ("bench", "bangku", 85, "medium", True),
    ("dog", "anjing", 60, "high", False),
    ("cat", "kucing", 25, "info", False),
    ("backpack", "tas ransel", 45, "info", True),
    ("umbrella", "payung", 90, "info", True),
    ("handbag", "tas tangan", 30, "info", True),
    ("tie", "dasi", 40, "info", True),
    ("suitcase", "koper", 60, "info", True),
    ("bottle", "botol", 25, "info", True),
    ("wine glass", "gelas anggur", 18, "info", True),
    ("cup", "gelas", 12, "info", True),
    ("fork", "garpu", 18, "info", True),
    ("knife", "pisau", 22, "info", True),
    ("spoon", "sendok", 18, "info", True),
    ("bowl", "mangkuk", 12, "info", True),
    ("banana", "pisang", 18, "info", True),
    ("apple", "apel", 8, "info", True),
    ("sandwich", "roti lapis", 8, "info", True),
    ("orange", "jeruk", 8, "info", True),
    ("chair", "kursi", 90, "medium", True),
    ("couch", "sofa", 80, "medium", True),
    ("potted plant", "tanaman pot", 60, "medium", True),
    ("bed", "tempat tidur", 60, "medium", True),
    ("dining table", "meja makan", 75, "medium", True),
    ("toilet", "toilet", 70, "medium", True),
    ("tv", "televisi", 60, "info", True),
    ("laptop", "laptop", 25, "info", True),
    ("mouse", "tetikus", 4, "info", True),
    ("remote", "remote", 18, "info", True),
    ("keyboard", "papan ketik", 3, "info", True),
    ("cell phone", "ponsel", 15, "info", True),
    ("microwave", "microwave", 30, "info", True),
    ("oven", "oven", 60, "medium", True),
    ("sink", "wastafel", 85, "medium", True),
    ("refrigerator", "kulkas", 170, "medium", True),
    ("book", "buku", 24, "info", True),
    ("clock", "jam", 25, "info", True),
    ("vase", "vas", 30, "info", True),
    ("scissors", "gunting", 18, "info", True),
    ("teddy bear", "boneka beruang", 30, "info", True),
    ("hair drier", "pengering rambut", 20, "info", True),
    ("toothbrush", "sikat gigi", 18, "info", True),
    ("door", "pintu", 200, "medium", True),
    ("stairs", "tangga", 100, "medium", False),
]

# ── 20 intent perintah suara (bagian 14 IMPLEMENTASI.md) ─────────────────
INTENTS: list[tuple[str, str, str, bool, list[str]]] = [
    ("mode.money", "mode", "kenali uang", False,
     ["buka mode uang", "kenali uang", "ini uang berapa", "mode uang", "cek uang", "berapa ini"]),
    ("mode.readText", "mode", "baca teks", True,
     ["baca teks", "bacakan", "buka mode baca", "baca tulisan ini", "apa tulisannya"]),
    ("mode.detection", "mode", "deteksi objek", False,
     ["deteksi objek", "mode deteksi", "ada apa di depan"]),
    ("mode.navigation", "mode", "navigasi", True,
     ["mode navigasi", "mau jalan", "bantu jalan", "navigasi"]),
    ("mode.assistant", "mode", "asisten suara", True,
     ["asisten", "tanya", "mode suara"]),
    ("mode.findObject", "mode", "cari objek", True,
     ["cari objek", "cari barang", "carikan"]),
    ("mode.settings", "mode", "pengaturan", False,
     ["pengaturan", "setelan", "buka pengaturan"]),
    ("action.capture", "action", "ambil gambar", False,
     ["ambil gambar", "jepret", "foto"]),
    ("action.replay", "action", "putar ulang", False,
     ["putar ulang", "ulangi", "baca lagi"]),
    ("action.summary", "action", "ringkas", True,
     ["ringkas", "singkat saja", "baca ringkasannya"]),
    ("action.stopWalking", "action", "selesai jalan", False,
     ["selesai jalan", "sudah sampai", "berhenti navigasi"]),
    ("action.showAll", "action", "lihat semua", False, ["lihat semua"]),
    ("action.torch", "action", "nyalakan lampu", False,
     ["nyalakan lampu", "nyalakan senter", "lampu kamera"]),
    ("play.pause", "play", "jeda", False, ["jeda", "berhenti dulu", "stop"]),
    ("play.resume", "play", "lanjut", False, ["lanjut", "terusin", "lanjutkan"]),
    ("play.faster", "play", "lebih cepat", False, ["lebih cepat", "percepat"]),
    ("play.slower", "play", "lebih pelan", False, ["lebih pelan", "pelan-pelan"]),
    ("play.repeatSection", "play", "ulangi bagian", False,
     ["ulangi bagian", "ulang yang tadi"]),
    ("help.what", "help", "bantuan", False,
     ["bisa apa", "apa saja", "bantuan", "tolong"]),
    ("help.whereAmI", "help", "saya di mana", False,
     ["ini mode apa", "saya di mana"]),
]

# ── Denominasi rupiah ────────────────────────────────────────────────────
# class_index HARUS sama dengan class_indices model TFLite on-device:
#   {'100rb': 0, '10rb': 1, '20rb': 2, '2rb': 3, '50rb': 4, '5rb': 5}
# Rp1.000 TIDAK ada di model (6 kelas, emisi 2016) → active=False, supaya
# aplikasi bisa menyebut keterbatasannya dengan jujur (UG-18) alih-alih
# menebak. Salah nominal = kerugian uang nyata.
# (value_idr, words, emissions, color_name, class_index, active)
DENOMINATIONS: list[tuple[int, str, str, str, int | None, bool]] = [
    (100000, "seratus ribu rupiah", "2016", "merah", 0, True),
    (10000, "sepuluh ribu rupiah", "2016", "ungu", 1, True),
    (20000, "dua puluh ribu rupiah", "2016", "hijau", 2, True),
    (2000, "dua ribu rupiah", "2016", "abu-abu", 3, True),
    (50000, "lima puluh ribu rupiah", "2016", "biru", 4, True),
    (5000, "lima ribu rupiah", "2016", "coklat", 5, True),
    (1000, "seribu rupiah", "-", "hijau kebiruan", None, False),
]

# ── Manifest model on-device ─────────────────────────────────────────────
# `available=False` untuk money: model .tflite belum ada, akan diisi user.
MANIFEST: list[tuple[str, str, str, str, str, bool, str]] = [
    ("detection", "1.0.0", "ssd_mobilenet.tflite", "tflite", "1.0.0", False,
     "Deteksi rintangan on-device. Sudah dibundel di assets aplikasi."),
    ("money", "1.0.0", "uang_rupiah.tflite", "tflite", "1.0.0", False,
     "Klasifikasi 6 denominasi rupiah emisi 2016 (MobileNetV2 transfer "
     "learning, input 224x224 float32, rescale 1/255). Sudah dibundel di "
     "assets aplikasi dan berjalan sepenuhnya on-device. Rp1.000 TIDAK "
     "didukung model ini."),
    ("segmentation", "0.0.0", "pidnet_s_3zona.onnx", "onnx", "1.0.0", False,
     "Segmentasi jalur 3 zona (PIDNet-S). Opsional: server pakai fallback "
     "heuristik bila model belum ada."),
]


def seed_all() -> None:
    try:
        _seed_labels()
        _seed_intents()
        _seed_denominations()
        _seed_manifest()
        logger.success("Seed data rujukan siap")
    except Exception as e:
        logger.error(f"Seed gagal: {e}")


def _seed_labels() -> None:
    for label_en, label_id, height, danger, searchable in LABELS:
        execute(
            """
            INSERT INTO object_labels
                (label_en, lang, label_local, real_height_cm, danger_class, searchable)
            VALUES (:en, 'id', :local, :h, :danger, :searchable)
            ON CONFLICT (label_en, lang) DO UPDATE
                SET label_local    = EXCLUDED.label_local,
                    real_height_cm = EXCLUDED.real_height_cm,
                    danger_class   = EXCLUDED.danger_class,
                    searchable     = EXCLUDED.searchable,
                    updated_at     = now()
            """,
            {"en": label_en, "local": label_id, "h": height,
             "danger": danger, "searchable": searchable},
        )


def _seed_intents() -> None:
    for key, category, spoken, needs_server, phrases in INTENTS:
        execute(
            """
            INSERT INTO voice_intents (intent_key, category, spoken_label, requires_server)
            VALUES (:key, :cat, :spoken, :srv)
            ON CONFLICT (intent_key) DO UPDATE
                SET category        = EXCLUDED.category,
                    spoken_label    = EXCLUDED.spoken_label,
                    requires_server = EXCLUDED.requires_server
            """,
            {"key": key, "cat": category, "spoken": spoken, "srv": needs_server},
        )
        row = fetch_one(
            "SELECT id FROM voice_intents WHERE intent_key = :key", {"key": key}
        )
        if not row:
            continue
        for phrase in phrases:
            execute(
                """
                INSERT INTO intent_phrases (intent_id, phrase)
                VALUES (:iid, :phrase)
                ON CONFLICT (intent_id, phrase) DO NOTHING
                """,
                {"iid": row["id"], "phrase": phrase},
            )


def _seed_denominations() -> None:
    for value, words, emissions, color, idx, active in DENOMINATIONS:
        execute(
            """
            INSERT INTO money_denominations
                (value_idr, words, emissions, color_name, class_index, active)
            VALUES (:v, :w, :e, :c, :i, :a)
            ON CONFLICT (value_idr) DO UPDATE
                SET words       = EXCLUDED.words,
                    emissions   = EXCLUDED.emissions,
                    color_name  = EXCLUDED.color_name,
                    class_index = EXCLUDED.class_index,
                    active      = EXCLUDED.active
            """,
            {"v": value, "w": words, "e": emissions, "c": color, "i": idx, "a": active},
        )


def _seed_manifest() -> None:
    for key, version, filename, fmt, min_app, mandatory, notes in MANIFEST:
        execute(
            """
            INSERT INTO model_manifest
                (model_key, version, filename, format, min_app_version, mandatory, notes,
                 url_path, available)
            VALUES (:k, :v, :f, :fmt, :min, :mand, :notes, :url, FALSE)
            ON CONFLICT (model_key) DO UPDATE
                SET notes = EXCLUDED.notes
            """,
            {"k": key, "v": version, "f": filename, "fmt": fmt, "min": min_app,
             "mand": mandatory, "notes": notes,
             "url": f"/api/models/download/{key}"},
        )
```

---

## File: `export_tflite.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/export_tflite.py`

```python
"""
Script export YOLO11 Nano ke format TFLite untuk Guidio.
Jalankan di dalam venv backend yang sudah punya ultralytics.

Usage:
    cd /path/to/project/backend
    python export_tflite.py

Output:
    yolo11n_float32.tflite  (atau yolo11n.tflite tergantung versi ultralytics)
    → copy ke: ../guidio_app/assets/models/yolo11n.tflite
"""

from pathlib import Path
from ultralytics import YOLO


def export():
    print("=== Export YOLO11n → TFLite ===")

    # Download + load YOLO11n (akan auto-download dari ultralytics hub)
    model = YOLO("yolo11n.pt")

    # Export ke TFLite
    # imgsz=320 agar sesuai dengan _inputSize di tflite_service.dart
    # half=False karena Android CPU tidak support float16 natively
    export_path = model.export(
        format="tflite",
        imgsz=320,
        half=False,   # float32 untuk Android CPU
        int8=False,
    )

    print(f"\nExport selesai: {export_path}")

    # Rename dan pindah ke assets
    src = Path(export_path)
    dst = Path("../guidio_app/assets/models/yolo11n.tflite")
    dst.parent.mkdir(parents=True, exist_ok=True)

    import shutil
    shutil.copy(src, dst)
    print(f"Disalin ke: {dst.resolve()}")
    print("\n✅ Selesai! File siap dipakai di Flutter.")


if __name__ == "__main__":
    export()
```

---

## File: `main.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/main.py`

```python
import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from db.database import init_db, is_available
from routers import (
    cari_objek,   # /api/cari-objek — YOLOE open-vocabulary
    describe,     # /api/describe   — Moondream2
    support,      # /api/capabilities
)
from services.find_object_service import FindObjectService
from services.moondream_service import MoonDreamService

load_dotenv()

STARTED_AT = time.time()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Muat semua service saat startup, bersihkan saat shutdown.

    Tidak ada satu pun kegagalan di sini yang boleh menjatuhkan server:
    tiap bagian yang mati dilaporkan apa adanya lewat /api/capabilities,
    supaya aplikasi bisa menyebut fitur mana yang hilang alih-alih gagal
    diam-diam.
    """
    logger.info("=== Menyalakan Vinara/Guidio Backend ===")

    # PostgreSQL — risk zone + capability overrides. Tabel telemetri, crash,
    # antrean, label, dan manifest tidak lagi punya endpoint aktif; lihat
    # `_archive/routers/support_full.py`.
    init_db()

    # Cari Objek — YOLOE open-vocabulary, trigger-based (bukan real-time).
    # Satu dari dua fitur yang benar-benar butuh server: modelnya tidak ada
    # di ponsel.
    app.state.find_object_service = FindObjectService()
    logger.info("[FindObject] Service terdaftar (lazy-load model YOLOE).")

    # Scene Description — Moondream2 dimuat malas saat request pertama.
    # Model ~2GB, tidak pantas menahan startup. RTX 3050 4GB VRAM cukup
    # untuk FP16 (~1.2GB efektif setelah kuantisasi runtime).
    app.state.moondream_service = MoonDreamService(
        device=os.getenv("MOONDREAM_DEVICE", "auto")
    )
    logger.info("[Moondream2] Service terdaftar (lazy-load, belum dimuat).")

    logger.success("=== Vinara Backend siap ===")
    yield
    logger.info("Shutdown.")


app = FastAPI(
    title="Vinara / Guidio Vision API",
    version="2.0.0",
    description=(
        "Backend untuk Vinara — asisten visual suara untuk pengguna tunanetra. "
        "Empat dari enam mode (Deteksi Objek, Kenali Uang, Baca Teks, "
        "Navigasi) berjalan sepenuhnya on-device dan tidak memanggil API ini "
        "sama sekali. Yang tersisa di sini hanya yang modelnya tidak muat di "
        "ponsel: YOLOE untuk Cari Objek dan Moondream2 untuk Deskripsi Suasana."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Permukaan API: 3 router, 3 endpoint + /health ────────────────────────
#
# Router yang diarsipkan ke `_archive/routers/` beserta alasannya:
#   websocket, detect  → deteksi rintangan sudah on-device (SSD MobileNet)
#   ocr                → sudah on-device (ML Kit)
#   uang               → sudah on-device (MobileNetV2 TFLite)
#   navigasi           → sudah on-device (PIDNet-S + YOLO11n TFLite)
#   asisten, voice_router → intent parsing lokal (CommandParser), tanpa LLM
#   risk_zone          → klien tidak pernah memanggilnya
#
# Prinsipnya satu: kalau fiturnya sudah ada di ponsel, backend tidak perlu
# menyediakannya lagi. Jalur ganda hanya menambah kode yang harus dijaga
# konsisten, dan menciptakan ketergantungan diam-diam pada laptop yang
# menyala di mode yang justru menyangkut keselamatan.
app.include_router(cari_objek.router)     # /api/cari-objek   YOLOE open-vocab
app.include_router(describe.router)       # /api/describe     Moondream2 (output EN)
app.include_router(support.router)        # /api/capabilities


@app.get("/health")
async def health():
    """Health check. PG-08c menyebut waktu tempuh, jadi latensi harus ikut
    dikembalikan supaya aplikasi bisa membacakannya."""
    t0 = time.perf_counter()
    finder = getattr(app.state, "find_object_service", None)
    moondream = getattr(app.state, "moondream_service", None)
    payload = {
        "status": "ok",
        "service": "Vinara Vision API",
        "version": "3.0.0",
        "uptime_seconds": round(time.time() - STARTED_AT, 1),
        "database": is_available(),
        # Hanya dua fitur yang benar-benar dilayani server ini.
        "find_object": finder is not None,
        "describe": bool(moondream and getattr(moondream, "available", False)),
    }
    payload["server_time_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return payload
```

---

## File: `requirements.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/requirements.txt`

```text
fastapi==0.115.5
uvicorn[standard]==0.32.1
python-multipart==0.0.12
websockets==13.1
ultralytics>=8.3.0
opencv-python>=4.10.0
numpy>=1.26.0
python-dotenv==1.0.1
loguru>=0.7.2
torch>=2.1.0
torchvision>=0.16.0
onnxruntime>=1.19.0
pytesseract>=0.3.10
Pillow>=10.0.0
httpx>=0.27.0

# Local LLM — menggantikan Claude Haiku (anthropic) untuk narasi, terjemahan, intent.
# Qwen2.5-1.5B-Instruct GGUF via llama-cpp-python dengan akselerasi CUDA.
# Install dengan CUDA: CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python
llama-cpp-python>=0.3.0

# Vision Language Model — scene description (bukan LLM teks biasa)
transformers>=4.40.0

# PostgreSQL (telemetri, crash report, antrean offline, kamus label,
# manifest model, sesi asisten, risk zone)
sqlalchemy>=2.0
psycopg[binary]>=3.2
```

---

## File: `routers/cari_objek.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/cari_objek.py`

```python
"""Mode Cari Objek — POST /api/cari-objek

Trigger-based: dipanggil sekali per perintah suara, bukan stream. Aplikasi
memanggil ulang tiap kali pengguna memutar badan (CO-05 / CO-10), jadi
endpoint ini harus cepat dan tidak menyimpan state di server.
"""

import cv2
import numpy as np
from fastapi import APIRouter, File, Form, Request, UploadFile
from loguru import logger

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["cari-objek"])


@router.get("/cari-objek/targets")
async def searchable_targets():
    """Daftar barang yang dikenali sistem — CO-12 (objek tak dikenali)
    memakai ini untuk menawarkan barang lain yang memang bisa dicari."""
    from services.find_object_service import EXTRA_ID_TO_EN

    db_labels = repo.get_searchable_labels() if is_available() else []
    targets = sorted(
        {row["label_local"] for row in db_labels} | set(EXTRA_ID_TO_EN.keys())
    )
    return {"total": len(targets), "targets": targets}


@router.post("/cari-objek")
async def cari_objek(
    request: Request,
    target: str = Form(..., description="Nama barang Bahasa Indonesia, mis. 'dompet'"),
    file: UploadFile = File(..., description="Frame kamera JPEG"),
    conf: float | None = Form(None),
):
    """Cari satu jenis barang di satu frame.

    Balasan `found=False` dengan reason `not_in_frame` BUKAN error — itu
    kondisi normal CO-10 yang membuat aplikasi menyuruh pengguna memutar
    badan lalu memanggil endpoint ini lagi.
    """
    raw = await file.read()
    if not raw:
        return {
            "found": False,
            "reason": "invalid_frame",
            "message": "Gambar kosong. Coba ambil ulang.",
            "matches": [],
            "total_match": 0,
        }
    frame = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "found": False,
            "reason": "invalid_frame",
            "message": "Gambar tidak terbaca. Coba ambil ulang.",
            "matches": [],
            "total_match": 0,
        }

    svc = request.app.state.find_object_service

    # Terjemahkan target Bahasa Indonesia → prompt Inggris untuk YOLOE.
    label_map: dict[str, str] = {}
    if is_available():
        try:
            label_map = {
                row["label_local"]: row["label_en"]
                for row in repo.get_searchable_labels()
            }
        except Exception as e:
            logger.warning(f"Kamus label tidak terbaca: {e}")

    prompt_en = svc.resolve_prompt(target, label_map)
    result = svc.find(frame, prompt_en, target.strip().lower(), conf=conf)

    logger.info(
        f"cari-objek target='{target}' prompt='{prompt_en}' "
        f"found={result['found']} n={result['total_match']}"
    )
    return result
```

---

## File: `routers/describe.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/describe.py`

```python
"""
Router: POST /api/describe
Menerima gambar JPEG dari Flutter, mengembalikan deskripsi suasana
dalam Bahasa Inggris via Moondream2.

Pipeline (TANPA LLM):
  Foto JPEG → Moondream2 (VLM, caption EN) → dikembalikan langsung ke mobile

Keputusan desain:
- Terjemahan ke Bahasa Indonesia via Qwen DIHAPUS — tidak ada LLM di backend.
- Output tetap Bahasa Inggris; mobile membacanya via TTS dengan locale 'en-US'.
- Key response: 'description_en' (bukan 'deskripsi').
"""

from fastapi import APIRouter, File, Request, UploadFile
from loguru import logger

router = APIRouter(prefix="/api", tags=["describe"])


@router.post("/describe")
async def describe_scene(
    request: Request,
    image: UploadFile = File(..., description="Gambar JPEG/PNG dari kamera"),
):
    """
    POST /api/describe

    Menerima gambar kamera, mengembalikan deskripsi suasana Bahasa Inggris
    dari Moondream2 yang siap dibacakan via TTS (locale en-US) kepada
    pengguna tunanetra.

    Pipeline:
    1. Gambar JPEG → Moondream2 → caption Bahasa Inggris (length='short')
    2. Caption dikembalikan langsung — tanpa terjemahan.

    Fallback:
    - Jika Moondream gagal/belum dimuat: pesan error informatif.
    """
    moondream = getattr(request.app.state, "moondream_service", None)
    if moondream is None:
        return {
            "description_en": "Scene description unavailable. Moondream service not loaded.",
            "error": "moondream_service_unavailable",
        }

    image_bytes = await image.read()
    if len(image_bytes) == 0:
        return {"description_en": "Image is empty or invalid.", "error": "empty_image"}

    # Inferensi Moondream2 — length='short' → ringkas dan cepat (~300ms di GPU)
    logger.info(f"[describe] Menerima gambar {len(image_bytes) // 1024} KB")
    caption_en = await moondream.describe(image_bytes, length="short")

    if not caption_en:
        return {
            "description_en": "Sorry, I could not describe the scene right now.",
            "error": "moondream_inference_failed",
        }

    logger.info(f"[describe] Moondream caption: {caption_en}")

    return {"description_en": caption_en}
```

---

## File: `routers/support.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/support.py`

```python
"""Endpoint penunjang — tinggal satu: `/api/capabilities`.

Sebelas endpoint lain (`/api/labels`, `/api/models/*`, `/api/events`,
`/api/crash-report*`, `/api/queue/*`) dipindah ke
`_archive/routers/support_full.py`: tidak satu pun pernah dipanggil aplikasi.
Method kliennya ada di `ServerService`, lengkap dengan penanganan error, tapi
tidak ada satu pun pemanggil — jadi tabel `telemetry_events`, `crash_reports`,
`upload_queue`, `object_labels`, dan `model_manifest` tidak pernah menerima
satu baris pun dari aplikasi.

Menyisakannya berarti memelihara permukaan API yang harus dijelaskan tapi
tidak pernah dipakai. Berkasnya tetap ada di arsip kalau suatu saat
telemetri benar-benar dipasang.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Request

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["support"])


@router.get("/capabilities")
async def capabilities(request: Request):
    """Kemampuan server SEBELUM pengguna menekan tombol.

    Menentukan item mana yang `limited` / `disabled` di ModePickerSheet.
    Tanpa ini, satu-satunya cara mengetahui sebuah mode sedang mati adalah
    masuk ke sana lalu gagal — dan untuk pengguna yang tidak melihat layar,
    "masuk lalu gagal" berarti beberapa detik kebingungan di tempat yang salah.

    **Empat dari enam mode sekarang on-device penuh.** Deteksi Objek, Kenali
    Uang, Baca Teks, dan Navigasi berjalan sepenuhnya di ponsel, jadi
    statusnya tidak lagi bergantung pada server ini sama sekali — dan
    melaporkannya `down` saat server bermasalah akan mengunci pengguna dari
    mode yang sebenarnya sehat.
    """
    state = request.app.state
    finder = getattr(state, "find_object_service", None)
    moondream = getattr(state, "moondream_service", None)

    find_ok = finder is not None
    describe_ok = moondream is not None and getattr(moondream, "available", False)

    caps = {
        "detection": {
            "state": "up",
            "on_device": True,
            "note": "Berjalan on-device (SSD MobileNet), tidak butuh server.",
        },
        "money": {
            "state": "up",
            "on_device": True,
            "note": "Klasifikasi nominal on-device (TFLite), tidak pernah memanggil server.",
        },
        "read_text": {
            "state": "up",
            "on_device": True,
            "note": "Pengenalan teks on-device (ML Kit), tidak butuh server.",
        },
        "navigation": {
            "state": "up",
            "on_device": True,
            "note": "Jalur dan rintangan dibaca on-device (PIDNet + YOLO11n).",
        },
        # Dua ini yang benar-benar butuh server: modelnya tidak ada di ponsel.
        "assistant": {
            "state": "up" if describe_ok else "limited",
            "on_device": False,
            "note": "Asisten penuh, deskripsi suasana siap."
            if describe_ok
            else "Perintah dan ganti mode tetap jalan; deskripsi suasana butuh server.",
        },
        "find_object": {
            "state": "up" if find_ok else "down",
            "on_device": False,
            "note": "Pencarian objek siap."
            if find_ok
            else "Cari Objek butuh server; modelnya tidak ada di ponsel.",
        },
    }

    # Override manual untuk demo / maintenance.
    if is_available():
        try:
            for name, ov in repo.get_capability_overrides().items():
                if name in caps and ov.get("forced_state"):
                    caps[name]["state"] = ov["forced_state"]
                    caps[name]["note"] = ov.get("reason") or caps[name]["note"]
                    caps[name]["forced"] = True
        except Exception:
            pass

    return {
        "server_time": datetime.now(timezone.utc).isoformat(),
        "database": is_available(),
        "capabilities": caps,
    }
```

---

## File: `services/find_object_constants.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/find_object_constants.py`

```python
"""
GUIDIO - Dictionary untuk fitur Open-Vocabulary Object Detection (YOLOE)
=========================================================================
Berisi tiga dictionary utama:
1. COLOR_MAP           -> pemetaan warna/nuansa/pola ID -> EN
2. EXTRA_ID_TO_EN       -> pemetaan nama objek ID -> prompt class EN
3. EXTRA_HEIGHTS_CM     -> estimasi tinggi fisik objek (cm) untuk
                           similar-triangle distance estimation
"""

# =========================================================================
# 0. SEARCH_PREFIXES & FILLER_WORDS (Pembersih Perintah Suara)
# =========================================================================
SEARCH_PREFIXES: set[str] = {
    "cari", "carikan", "carilah", "tolong cari", "tolong carikan", "mohon cari",
    "mohon carikan", "bantu cari", "bantu carikan", "coba cari", "coba carikan",
    "silakan cari", "silakan carikan", "temukan", "temuin", "tunjukin", "tunjukkan",
    "deteksi", "scan", "pindai", "cariin", "cariin dong", "cariin deh", "cariin dong ya",
    "cariin napa", "cariin woy", "cariin bentar", "cariin sini", "cariin cepetan",
    "tolong cariin", "tolong cariin dong", "tolong cariin ya", "bantu cariin",
    "bantu cariin dong", "bantuin cari", "bantuin cariin", "bantuin dong cariin",
    "bantuin nyari", "bantu nemuin", "tolong temuin", "gan cariin", "bro cariin",
    "woy cariin", "eh cariin", "nyari", "nyariin", "nyari-nyari", "lagi nyari",
    "lagi nyariin", "lagi cariin", "kehilangan", "saya kehilangan", "aku kehilangan",
    "hilang", "ilang", "kemana", "ke mana", "dimana", "di mana", "dimanakah",
    "di manakah", "mana", "ada dimana", "gue kehilangan", "gua kehilangan",
    "ane kehilangan", "gw kehilangan", "ilangan", "ngilang", "kemana ya", "kemana sih",
    "mana ya", "mana sih", "mana nih", "kaga ketemu", "kagak ketemu", "gak ketemu",
    "ga ketemu", "nggak ketemu", "tidak ketemu", "belum ketemu", "susah nemu",
    "ga nemu", "gak nemu", "gak nemu-nemu", "gak bisa nemu", "kok gak ada ya",
    "kok hilang ya", "tadi taruh dimana ya", "ilang kemana ini",
    # Bahasa Daerah
    "ilang kemane", "digoleki", "goleki", "ora ono", "ilang neng ndi", "diteangan",
    "milarian", "leungit dimana", "ilang kama", "ilang dima", "dima yo", "ilang huta dison",
    "alai pileh", "kija alangan", "kemma battu", "keng gun edimma",
    # Lupa naruh / simpan
    "lupa naro", "lupa naruh", "lupa nataro", "lupa taro", "lupa taruh", "lupa ditaruh",
    "lupa meletakkan", "lupa nyimpen", "lupa nyimpan", "lupa menyimpan",
    "lupa simpen dimana", "lupa taro dimana", "lupa naro dimana", "lupa naruh dimana",
    # Konfirmasi / kelihatan
    "ada yang liat", "ada yang lihat", "ada yg liat", "ada yg lihat", "ada yang nemu",
    "nemu", "nampak", "kelihatan", "keliatan", "kliatan", "keliatan gak", "keliatan ga",
}

FILLER_WORDS: set[str] = {
    "saya punya", "aku punya", "punya saya", "punya aku", "punya gue", "punya gua",
    "punya ane", "punyanya", "punyaku", "saya", "aku", "gue", "gua", "gw", "ane",
    "kamu", "kau", "anda", "ku", "mu", "nya", "bentar ya", "sebentar", "bentar",
    "tolong", "yaudah", "please", "dong", "deh", "nih", "tuh", "sih", "ya", "kah",
    "tah", "kek", "lah", "pun", "dulu", "woy", "woi", "eh", "nah", "kok", "toh",
    "kan", "loh", "lho", "lo", "gitu", "gini", "aja", "saja", "juga", "napa",
    "plis", "yuk", "udah", "gan", "bro", "sis", "cuy", "kayaknya", "yah", "banget",
    "coba", "anu", "mmm", "eee", "e", "je", "rek", "atuh", "euy", "teh", "mah",
    "dah", "noh", "yee", "bang", "pole",
}

# =========================================================================
# 1. COLOR_MAP
# =========================================================================
COLOR_MAP: dict[str, str] = {
    # --- Warna dasar ---
    "merah": "red",
    "biru": "blue",
    "hijau": "green",
    "kuning": "yellow",
    "hitam": "black",
    "putih": "white",
    "cokelat": "brown",
    "coklat": "brown",
    "abu-abu": "gray",
    "abu abu": "gray",
    "abuabu": "gray",
    "pink": "pink",
    "merah muda": "pink",
    "ungu": "purple",
    "violet": "violet",
    "oranye": "orange",
    "jingga": "orange",
    "emas": "gold",
    "keemasan": "gold",
    "perak": "silver",
    "keperakan": "silver",
    "krem": "cream",
    "biru dongker": "navy blue",
    "biru donker": "navy blue",
    "navy": "navy blue",
    "maroon": "maroon",
    "marun": "maroon",
    "turquoise": "turquoise",
    "tosca": "turquoise",
    "toska": "turquoise",
    "magenta": "magenta",
    "beige": "beige",
    "khaki": "khaki",
    "lavender": "lavender",
    "lavendel": "lavender",
    "peach": "peach",
    "salem": "salmon",
    "salmon": "salmon",
    "indigo": "indigo",

    # --- Variasi / nuansa merah ---
    "merah tua": "dark red",
    "merah cerah": "bright red",
    "merah menyala": "bright red",
    "merah marun": "maroon",
    "merah bata": "brick red",
    "merah delima": "ruby red",
    "merah anggur": "wine red",
    "merah muda pucat": "pale pink",

    # --- Variasi / nuansa biru ---
    "biru muda": "light blue",
    "biru tua": "dark blue",
    "biru langit": "sky blue",
    "biru laut": "sea blue",
    "biru navy": "navy blue",
    "biru dongker tua": "dark navy blue",
    "biru toska": "turquoise blue",
    "biru elektrik": "electric blue",
    "biru pastel": "pastel blue",

    # --- Variasi / nuansa hijau ---
    "hijau daun": "leaf green",
    "hijau tua": "dark green",
    "hijau muda": "light green",
    "hijau lumut": "moss green",
    "hijau army": "army green",
    "hijau tentara": "army green",
    "hijau toska": "turquoise green",
    "hijau botol": "bottle green",
    "hijau mint": "mint green",
    "hijau pastel": "pastel green",
    "hijau zaitun": "olive green",

    # --- Variasi / nuansa kuning ---
    "kuning kunyit": "turmeric yellow",
    "kuning cerah": "bright yellow",
    "kuning pucat": "pale yellow",
    "kuning emas": "golden yellow",
    "kuning mustard": "mustard yellow",
    "kuning pastel": "pastel yellow",
    "kuning gading": "ivory yellow",

    # --- Variasi / nuansa hitam ---
    "hitam pekat": "jet black",
    "hitam legam": "jet black",
    "hitam doff": "matte black",
    "hitam mengkilap": "glossy black",
    "hitam kelam": "deep black",

    # --- Variasi / nuansa putih ---
    "putih tulang": "bone white",
    "putih gading": "ivory white",
    "putih susu": "milk white",
    "putih bersih": "clean white",
    "putih mutiara": "pearl white",
    "putih salju": "snow white",

    # --- Variasi / nuansa abu-abu ---
    "abu-abu muda": "light gray",
    "abu-abu tua": "dark gray",
    "abu-abu gelap": "dark gray",
    "abu-abu terang": "light gray",
    "abu-abu tikus": "mouse gray",
    "abu-abu metalik": "metallic gray",

    # --- Variasi / nuansa cokelat ---
    "cokelat tua": "dark brown",
    "cokelat muda": "light brown",
    "cokelat kayu": "wood brown",
    "cokelat susu": "milk chocolate brown",
    "cokelat karamel": "caramel brown",
    "cokelat tanah": "earth brown",

    # --- Variasi / nuansa ungu ---
    "ungu tua": "dark purple",
    "ungu muda": "light purple",
    "ungu pastel": "pastel purple",
    "ungu terong": "eggplant purple",

    # --- Variasi / nuansa pink ---
    "pink tua": "dark pink",
    "pink muda": "light pink",
    "pink pastel": "pastel pink",
    "pink fanta": "hot pink",
    "pink cerah": "hot pink",

    # --- Variasi / nuansa oranye ---
    "oranye tua": "dark orange",
    "oranye muda": "light orange",
    "oranye pastel": "pastel orange",

    # --- Pola / deskriptor umum ---
    "garis-garis": "striped",
    "garis garis": "striped",
    "bergaris": "striped",
    "kotak-kotak": "checkered",
    "kotak kotak": "checkered",
    "berkotak": "checkered",
    "polkadot": "polka dot",
    "polka dot": "polka dot",
    "totol-totol": "polka dot",
    "bintik-bintik": "spotted",
    "polos": "plain",
    "bermotif": "patterned",
    "motif bunga": "floral pattern",
    "bermotif bunga": "floral pattern",
    "motif batik": "batik pattern",
    "transparan": "transparent",
    "bening": "clear",
    "gelap": "dark",
    "terang": "light",
    "cerah": "bright",
    "mengkilap": "glossy",
    "berkilau": "shiny",
    "doff": "matte",
    "kusam": "dull",
    "metalik": "metallic",
    "pelangi": "rainbow",
    "warna-warni": "colorful",
    "warni warni": "colorful",
    "multiwarna": "multicolor",
    "pastel": "pastel",
    "kamuflase": "camouflage",
    "loreng": "camouflage",
    "gradasi": "gradient",
    "bermotif kotak": "checkered pattern",
    "bermotif garis": "striped pattern",
    "berbintik": "spotted",
    "bercorak": "patterned",
    "polos tanpa motif": "plain solid",
    "muda": "light",
    "tua": "dark",
    "pudar": "faded",
    "kalem": "muted",
    "soft": "soft",
    "nude": "nude",
    "denim": "denim blue",
    "abu-abu semen": "cement gray",
    "biru pudar": "faded blue",
    "terang benderang": "very bright",
    "silver": "silver",
    "gold": "gold",
    "cream": "cream",
    "off white": "off white",
    "putih gading tua": "dark ivory white",
    "hitam kusam": "dull black",
    "cerah menyala": "vivid bright",
    "corak macan": "tiger print",
    "corak zebra": "zebra print",
    "corak ular": "snake print",
    "motif kotak-kotak besar": "large checkered pattern",
}


# =========================================================================
# 2. EXTRA_ID_TO_EN
# =========================================================================
EXTRA_ID_TO_EN: dict[str, str] = {
    # --- Barang pribadi ---
    "dompet": "wallet",
    "hp": "cell phone",
    "handphone": "cell phone",
    "hape": "cell phone",
    "telepon genggam": "cell phone",
    "telepon seluler": "cell phone",
    "ponsel": "cell phone",
    "smartphone": "cell phone",
    "gawai": "cell phone",
    "kunci": "key",
    "anak kunci": "key",
    "kunci motor": "key",
    "kunci mobil": "key",
    "gembok": "padlock",
    "kacamata": "glasses",
    "kacamata baca": "reading glasses",
    "kacamata hitam": "sunglasses",
    "kartu": "card",
    "kartu identitas": "id card",
    "ktp": "id card",
    "kartu nama": "business card",
    "kartu kredit": "credit card",
    "kartu debit": "debit card",
    "kartu atm": "atm card",
    "jam": "clock",
    "jam tangan": "watch",
    "cincin": "ring",
    "gelang": "bracelet",
    "kalung": "necklace",
    "anting": "earring",
    "anting-anting": "earring",
    "dasi": "necktie",
    "ikat pinggang": "belt",
    "sabuk": "belt",
    "dompet koin": "coin purse",
    "buku tabungan": "bank passbook",

    # --- Barang rumah tangga ---
    "botol": "bottle",
    "botol minum": "water bottle",
    "botol air": "water bottle",
    "gelas": "glass",
    "cangkir": "cup",
    "mug": "mug",
    "piring": "plate",
    "mangkuk": "bowl",
    "sendok": "spoon",
    "garpu": "fork",
    "pisau": "knife",
    "pisau dapur": "kitchen knife",
    "remote": "remote control",
    "remot": "remote control",
    "remote tv": "tv remote control",
    "remot tv": "tv remote control",
    "remote ac": "ac remote control",
    "charger": "charger",
    "cas": "charger",
    "pengisi daya": "charger",
    "kabel": "cable",
    "kabel data": "data cable",
    "gunting": "scissors",
    "sisir": "comb",
    "sikat gigi": "toothbrush",
    "pasta gigi": "toothpaste",
    "handuk": "towel",
    "sabun": "soap",
    "sabun batang": "bar soap",
    "tisu": "tissue",
    "tisu basah": "wet wipes",
    "korek api": "lighter",
    "lilin": "candle",
    "senter": "flashlight",
    "baterai": "battery",
    "termos": "thermos",
    "panci": "pot",
    "wajan": "frying pan",
    "ember": "bucket",
    "sapu": "broom",
    "kemoceng": "feather duster",
    "vas bunga": "flower vase",
    "bantal": "pillow",
    "guling": "bolster",
    "selimut": "blanket",
    "kasur": "mattress",
    "keset": "doormat",
    "gantungan baju": "clothes hanger",
    "jepitan baju": "clothespin",

    # --- Pakaian / aksesoris ---
    "tas": "bag",
    "tas ransel": "backpack",
    "ransel": "backpack",
    "tas selempang": "sling bag",
    "tas tangan": "handbag",
    "koper": "suitcase",
    "sepatu": "shoes",
    "sepatu boot": "boots",
    "sandal": "sandals",
    "sandal jepit": "flip flops",
    "topi": "hat",
    "topi baseball": "baseball cap",
    "jaket": "jacket",
    "mantel": "coat",
    "payung": "umbrella",
    "kaos": "t-shirt",
    "kaus": "t-shirt",
    "kemeja": "shirt",
    "celana": "pants",
    "celana panjang": "pants",
    "celana pendek": "shorts",
    "rok": "skirt",
    "sarung tangan": "gloves",
    "masker": "mask",
    "syal": "scarf",
    "kaos kaki": "socks",
    "kaus kaki": "socks",

    # --- Furnitur / elektronik ---
    "kursi": "chair",
    "meja": "table",
    "lemari": "cabinet",
    "lemari baju": "wardrobe",
    "rak buku": "bookshelf",
    "saklar": "light switch",
    "saklar lampu": "light switch",
    "stop kontak": "power outlet",
    "colokan": "power outlet",
    "colokan listrik": "power outlet",
    "pintu": "door",
    "jendela": "window",
    "tv": "television",
    "televisi": "television",
    "laptop": "laptop",
    "komputer": "computer",
    "keyboard": "keyboard",
    "mouse": "mouse",
    "printer": "printer",
    "kipas angin": "electric fan",
    "ac": "air conditioner",
    "pendingin ruangan": "air conditioner",
    "lampu": "lamp",
    "lampu meja": "table lamp",
    "speaker": "speaker",
    "pengeras suara": "speaker",
    "radio": "radio",
    "kompor": "stove",
    "kulkas": "refrigerator",
    "lemari es": "refrigerator",
    "microwave": "microwave",
    "rice cooker": "rice cooker",
    "penanak nasi": "rice cooker",
    "setrika": "iron",

    # --- Benda umum sehari-hari lainnya ---
    "buku": "book",
    "pena": "pen",
    "bolpoin": "pen",
    "pensil": "pencil",
    "penghapus": "eraser",
    "penggaris": "ruler",
    "kertas": "paper",
    "amplop": "envelope",
    "stapler": "stapler",
    "hekter": "stapler",
    "lem": "glue",
    "selotip": "tape",
    "kalkulator": "calculator",
    "bola": "ball",
    "cermin": "mirror",
    "jam dinding": "wall clock",
    "tanaman": "plant",
    "pot bunga": "flower pot",
    "tongkat": "cane",
    "tongkat tunanetra": "white cane",

    # --- Makanan & minuman ---
    "nasi kotak": "lunch box",
    "kotak makan": "lunch box",
    "botol kecap": "sauce bottle",
    "kaleng": "can",
    "kaleng soda": "soda can",
    "kaleng minuman": "soda can",
    "sachet kopi": "coffee sachet",
    "roti": "bread",
    "roti tawar": "sliced bread",
    "apel": "apple",
    "pisang": "banana",
    "jeruk": "orange fruit",
    "semangka": "watermelon",
    "mangga": "mango",
    "anggur": "grapes",
    "nanas": "pineapple",
    "pepaya": "papaya",
    "alpukat": "avocado",
    "wortel": "carrot",
    "tomat": "tomato",
    "kentang": "potato",
    "bawang": "onion",
    "bawang merah": "shallot",
    "bawang putih": "garlic",
    "cabai": "chili pepper",
    "cabe": "chili pepper",
    "telur": "egg",
    "susu kotak": "milk carton",
    "susu kaleng": "canned milk",
    "air mineral gelas": "cup water",
    "air mineral botol": "mineral water bottle",
    "gelas plastik": "plastic cup",
    "mie instan": "instant noodles",
    "permen": "candy",
    "snack": "snack pack",
    "biskuit": "biscuit pack",
    "teko": "kettle",
    "dispenser galon": "water dispenser",
    "galon air": "water gallon",
    "nampan": "tray",
    "sedotan": "straw",
    "tisu makan": "napkin",
    "tempat tisu": "tissue box",
    "sendok plastik": "plastic spoon",
    "garpu plastik": "plastic fork",
    "cangkir kopi": "coffee cup",

    # --- Alat tulis & kantor tambahan ---
    "folder": "folder",
    "buku catatan": "notebook",
    "spidol": "marker",
    "tipe-x": "correction fluid",
    "tipe x": "correction fluid",
    "paper clip": "paper clip",
    "klip kertas": "paper clip",
    "binder clip": "binder clip",
    "post-it": "sticky notes",
    "papan tulis": "whiteboard",
    "whiteboard": "whiteboard",

    # --- Elektronik tambahan ---
    "earphone": "earphones",
    "headphone": "headphones",
    "headset": "headset",
    "powerbank": "power bank",
    "flashdisk": "usb flash drive",
    "hardisk": "hard drive",
    "harddisk": "hard drive",
    "kamera": "camera",
    "tripod": "tripod",
    "drone": "drone",
    "proyektor": "projector",
    "router wifi": "wifi router",
    "modem": "modem",
    "mesin fax": "fax machine",
    "mesin fotocopy": "photocopier",
    "walkie talkie": "walkie talkie",
    "jam alarm": "alarm clock",
    "timbangan badan": "bathroom scale",
    "timbangan dapur": "kitchen scale",

    # --- Kendaraan & terkait ---
    "motor": "motorcycle",
    "sepeda motor": "motorcycle",
    "mobil": "car",
    "sepeda": "bicycle",
    "helm": "helmet",
    "spion": "side mirror",
    "plat nomor": "license plate",
    "ban": "tire",
    "knalpot": "exhaust pipe",
    "jerigen": "jerrycan",

    # --- Alat kebersihan tambahan ---
    "pel": "mop",
    "vacuum cleaner": "vacuum cleaner",
    "tempat sampah": "trash can",
    "kantong plastik": "plastic bag",
    "spons cuci piring": "dish sponge",
    "sabun cuci piring": "dish soap",
    "deterjen": "detergent",
    "pengharum ruangan": "air freshener",

    # --- Alat masak tambahan ---
    "talenan": "cutting board",
    "parutan": "grater",
    "saringan": "strainer",
    "spatula": "spatula",
    "sutil": "spatula",
    "teflon": "non-stick pan",
    "blender": "blender",
    "toaster": "toaster",
    "oven": "oven",

    # --- Kamar mandi ---
    "shampoo": "shampoo bottle",
    "sabun cair": "liquid soap",
    "sikat wc": "toilet brush",
    "gayung": "dipper",
    "ember mandi": "bathroom bucket",
    "tempat sabun": "soap dish",
    "hair dryer": "hair dryer",

    # --- Perlengkapan bayi & hewan peliharaan ---
    "botol susu bayi": "baby bottle",
    "dot": "pacifier",
    "popok": "diaper",
    "stroller": "stroller",
    "kereta bayi": "stroller",
    "mainan anak": "toy",
    "mangkuk makanan hewan": "pet bowl",
    "kandang hewan": "pet cage",
    "tali anjing": "dog leash",
    "kalung hewan": "pet collar",

    # --- Olahraga ---
    "raket": "racket",
    "bola basket": "basketball",
    "bola sepak": "soccer ball",
    "matras yoga": "yoga mat",
    "dumbbell": "dumbbell",
    "skateboard": "skateboard",

    # --- Perkakas / pertukangan ---
    "obeng": "screwdriver",
    "palu": "hammer",
    "tang": "pliers",
    "bor": "drill",
    "meteran": "tape measure",
    "paku": "nail",
    "baut": "bolt",

    # --- Uang & pembayaran ---
    "uang kertas": "banknote",
    "uang koin": "coin",

    # --- Alat musik ---
    "gitar": "guitar",
    "piano": "piano",
    "drum": "drum",
    "biola": "violin",
    "mikrofon": "microphone",

    # --- Perlengkapan medis ---
    "termometer": "thermometer",
    "tensimeter": "blood pressure monitor",
    "obat": "medicine bottle",
    "plester": "adhesive bandage",
    "kotak p3k": "first aid kit",
}


# =========================================================================
# 3. EXTRA_HEIGHTS_CM
# =========================================================================
EXTRA_HEIGHTS_CM: dict[str, int] = {
    # --- Barang pribadi ---
    "wallet": 10,
    "cell phone": 15,
    "key": 6,
    "padlock": 5,
    "glasses": 14,
    "reading glasses": 14,
    "sunglasses": 14,
    "card": 6,
    "id card": 9,
    "business card": 5,
    "credit card": 6,
    "debit card": 6,
    "atm card": 6,
    "clock": 25,
    "watch": 4,
    "ring": 2,
    "bracelet": 7,
    "necklace": 35,
    "earring": 2,
    "necktie": 130,
    "belt": 100,
    "coin purse": 10,
    "bank passbook": 15,

    # --- Barang rumah tangga ---
    "bottle": 25,
    "water bottle": 22,
    "glass": 12,
    "cup": 9,
    "mug": 10,
    "plate": 25,
    "bowl": 10,
    "spoon": 15,
    "fork": 18,
    "knife": 20,
    "kitchen knife": 25,
    "remote control": 18,
    "tv remote control": 20,
    "ac remote control": 18,
    "charger": 6,
    "data cable": 100,
    "cable": 100,
    "scissors": 18,
    "comb": 17,
    "toothbrush": 18,
    "toothpaste": 16,
    "towel": 70,
    "soap": 7,
    "bar soap": 7,
    "tissue": 12,
    "wet wipes": 10,
    "lighter": 8,
    "candle": 15,
    "flashlight": 15,
    "battery": 5,
    "thermos": 25,
    "pot": 20,
    "frying pan": 5,
    "bucket": 30,
    "broom": 130,
    "feather duster": 40,
    "flower vase": 25,
    "pillow": 45,
    "bolster": 100,
    "blanket": 150,
    "mattress": 20,
    "doormat": 2,
    "clothes hanger": 20,
    "clothespin": 7,

    # --- Pakaian / aksesoris ---
    "bag": 35,
    "backpack": 45,
    "sling bag": 25,
    "handbag": 25,
    "suitcase": 60,
    "shoes": 12,
    "boots": 30,
    "sandals": 5,
    "flip flops": 3,
    "hat": 15,
    "baseball cap": 15,
    "jacket": 65,
    "coat": 100,
    "umbrella": 90,
    "t-shirt": 70,
    "shirt": 75,
    "pants": 105,
    "shorts": 45,
    "skirt": 55,
    "gloves": 25,
    "mask": 15,
    "scarf": 150,
    "socks": 25,

    # --- Furnitur / elektronik ---
    "chair": 90,
    "table": 75,
    "cabinet": 150,
    "wardrobe": 180,
    "bookshelf": 180,
    "light switch": 8,
    "power outlet": 8,
    "door": 200,
    "window": 120,
    "television": 60,
    "laptop": 25,
    "computer": 45,
    "keyboard": 4,
    "mouse": 4,
    "printer": 25,
    "electric fan": 100,
    "air conditioner": 35,
    "lamp": 40,
    "table lamp": 40,
    "speaker": 30,
    "radio": 20,
    "stove": 15,
    "refrigerator": 170,
    "microwave": 30,
    "rice cooker": 25,
    "iron": 15,

    # --- Benda umum sehari-hari lainnya ---
    "book": 25,
    "pen": 15,
    "pencil": 18,
    "eraser": 3,
    "ruler": 3,
    "paper": 30,
    "envelope": 12,
    "stapler": 5,
    "glue": 12,
    "tape": 5,
    "calculator": 15,
    "ball": 22,
    "mirror": 60,
    "wall clock": 25,
    "plant": 40,
    "flower pot": 20,
    "cane": 90,
    "white cane": 130,

    # --- Makanan & minuman ---
    "lunch box": 8,
    "sauce bottle": 20,
    "can": 12,
    "soda can": 12,
    "coffee sachet": 12,
    "bread": 12,
    "sliced bread": 12,
    "apple": 8,
    "banana": 18,
    "orange fruit": 7,
    "watermelon": 25,
    "mango": 10,
    "grapes": 15,
    "pineapple": 25,
    "papaya": 20,
    "avocado": 10,
    "carrot": 18,
    "tomato": 6,
    "potato": 7,
    "onion": 6,
    "shallot": 4,
    "garlic": 4,
    "chili pepper": 8,
    "egg": 6,
    "milk carton": 20,
    "canned milk": 10,
    "cup water": 7,
    "mineral water bottle": 25,
    "plastic cup": 10,
    "instant noodles": 10,
    "candy": 3,
    "snack pack": 20,
    "biscuit pack": 15,
    "kettle": 22,
    "water dispenser": 100,
    "water gallon": 45,
    "tray": 3,
    "straw": 20,
    "napkin": 15,
    "tissue box": 12,
    "plastic spoon": 15,
    "plastic fork": 18,
    "coffee cup": 9,

    # --- Alat tulis & kantor tambahan ---
    "folder": 30,
    "notebook": 21,
    "marker": 14,
    "correction fluid": 8,
    "paper clip": 3,
    "binder clip": 3,
    "sticky notes": 8,
    "whiteboard": 60,

    # --- Elektronik tambahan ---
    "earphones": 4,
    "headphones": 18,
    "headset": 18,
    "power bank": 10,
    "usb flash drive": 5,
    "hard drive": 12,
    "camera": 10,
    "tripod": 100,
    "drone": 15,
    "projector": 15,
    "wifi router": 5,
    "modem": 5,
    "fax machine": 25,
    "photocopier": 100,
    "walkie talkie": 20,
    "alarm clock": 12,
    "bathroom scale": 3,
    "kitchen scale": 5,

    # --- Kendaraan & terkait ---
    "motorcycle": 110,
    "car": 150,
    "bicycle": 100,
    "helmet": 28,
    "side mirror": 15,
    "license plate": 15,
    "tire": 60,
    "exhaust pipe": 10,
    "jerrycan": 35,

    # --- Alat kebersihan tambahan ---
    "mop": 130,
    "vacuum cleaner": 110,
    "trash can": 50,
    "plastic bag": 30,
    "dish sponge": 4,
    "dish soap": 20,
    "detergent": 25,
    "air freshener": 20,

    # --- Alat masak tambahan ---
    "cutting board": 30,
    "grater": 20,
    "strainer": 15,
    "spatula": 30,
    "non-stick pan": 5,
    "blender": 35,
    "toaster": 20,
    "oven": 35,

    # --- Kamar mandi ---
    "shampoo bottle": 20,
    "liquid soap": 18,
    "toilet brush": 40,
    "dipper": 15,
    "bathroom bucket": 25,
    "soap dish": 3,
    "hair dryer": 22,

    # --- Perlengkapan bayi & hewan peliharaan ---
    "baby bottle": 18,
    "pacifier": 6,
    "diaper": 25,
    "stroller": 100,
    "toy": 15,
    "pet bowl": 6,
    "pet cage": 40,
    "dog leash": 100,
    "pet collar": 3,

    # --- Olahraga ---
    "racket": 68,
    "basketball": 24,
    "soccer ball": 22,
    "yoga mat": 3,
    "dumbbell": 20,
    "skateboard": 12,

    # --- Perkakas / pertukangan ---
    "obeng": 20,
    "hammer": 30,
    "pliers": 20,
    "drill": 25,
    "tape measure": 6,
    "nail": 5,
    "bolt": 3,

    # --- Uang & pembayaran ---
    "banknote": 7,
    "coin": 2,

    # --- Alat musik ---
    "guitar": 100,
    "piano": 100,
    "drum": 40,
    "violin": 60,
    "microphone": 20,

    # --- Perlengkapan medis ---
    "thermometer": 15,
    "blood pressure monitor": 10,
    "medicine bottle": 8,
    "adhesive bandage": 5,
    "first aid kit": 15,
}
```

---

## File: `services/find_object_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/find_object_service.py`

```python
"""Mode Cari Objek — YOLOE open-vocabulary (prompt teks).

Kenapa YOLOE dan bukan YOLO closed-set biasa: target pencarian datang dari
ucapan pengguna ("cari dompet", "cari tas merah"), jadi kelasnya tidak bisa
ditentukan saat training. YOLOE menerima prompt teks bebas dan modul
open-vocabulary-nya di-reparameterisasi ke arsitektur YOLO standar saat
inference, jadi kecepatannya setara YOLO closed-set.

Sifatnya trigger-based (sekali per perintah suara), bukan stream kontinu,
jadi beban server dan baterai jauh lebih ringan daripada Mode Navigasi.
"""

import os
import time

import numpy as np
from loguru import logger

from services.find_object_constants import (
    COLOR_MAP,
    EXTRA_HEIGHTS_CM,
    EXTRA_ID_TO_EN,
    FILLER_WORDS,
    SEARCH_PREFIXES,
)

FOCAL_LENGTH_PX = 615
DEFAULT_HEIGHT_CM = 20


class FindObjectService:
    """Pencarian objek berdasarkan prompt teks bebas.

    Model dimuat malas (lazy) saat permintaan pertama: bobot YOLOE + encoder
    teks MobileCLIP berukuran ratusan MB, tidak pantas menahan startup server
    padahal mode ini jarang dipakai dibanding Deteksi Objek.
    """

    def __init__(self, model_path: str | None = None, conf: float = 0.25):
        self.model_path = model_path or os.getenv("YOLOE_MODEL", "yoloe-11s-seg.pt")
        self.conf = float(os.getenv("YOLOE_CONF", conf))
        self.model = None
        self.loaded = False
        self.load_error: str | None = None
        self._active_prompts: list[str] = []

    # ── Pemuatan model ───────────────────────────────────────────────────

    def ensure_loaded(self) -> bool:
        if self.loaded:
            return True
        if self.load_error:
            return False
        try:
            from ultralytics import YOLOE

            t0 = time.time()
            logger.info(f"Memuat YOLOE '{self.model_path}' (sekali saja, agak lama)...")
            self.model = YOLOE(self.model_path)
            self.loaded = True
            logger.success(f"YOLOE siap dalam {time.time() - t0:.1f}s")
            return True
        except Exception as e:
            self.load_error = str(e)
            logger.error(f"YOLOE gagal dimuat: {e}")
            return False

    # ── Terjemahan target ────────────────────────────────────────────────

    def resolve_prompt(self, target_id: str, label_map: dict[str, str]) -> str:
        """Ubah nama barang Bahasa Indonesia (beserta warna/kata sifat) jadi prompt Inggris untuk YOLOE.

        `label_map` = {label_local: label_en} dari tabel object_labels.
        """
        raw_key = target_id.strip().lower()

        # Clean search prefixes & filler words if passed directly to backend
        key = raw_key
        sorted_prefixes = sorted(SEARCH_PREFIXES, key=len, reverse=True)
        for pref in sorted_prefixes:
            if key.startswith(pref + " ") or key == pref:
                key = key[len(pref):].strip()
                break
            elif " " + pref + " " in key:
                key = key.replace(" " + pref + " ", " ").strip()

        sorted_fillers = sorted(FILLER_WORDS, key=len, reverse=True)
        for filler in sorted_fillers:
            if key.startswith(filler + " "):
                key = key[len(filler):].strip()
            if key.endswith(" " + filler):
                key = key[:-len(filler)].strip()
            key = key.replace(f" {filler} ", " ").strip()

        if not key:
            key = raw_key

        # Direct match in EXTRA_ID_TO_EN or DB label_map
        if key in EXTRA_ID_TO_EN:
            return EXTRA_ID_TO_EN[key]
        if key in label_map:
            return label_map[key]

        # Clean filler words like "warna"
        cleaned_key = key.replace(" warna ", " ").replace(" warna", "").strip()

        # Check for color/modifier in COLOR_MAP
        found_color_en = None
        obj_phrase = cleaned_key

        sorted_colors = sorted(COLOR_MAP.keys(), key=len, reverse=True)
        for col_id in sorted_colors:
            if col_id in cleaned_key:
                found_color_en = COLOR_MAP[col_id]
                obj_phrase = cleaned_key.replace(col_id, "").strip()
                break

        # Resolve the object part
        obj_en = None
        if obj_phrase in EXTRA_ID_TO_EN:
            obj_en = EXTRA_ID_TO_EN[obj_phrase]
        elif obj_phrase in label_map:
            obj_en = label_map[obj_phrase]
        else:
            sorted_extra = sorted(EXTRA_ID_TO_EN.keys(), key=len, reverse=True)
            for id_word in sorted_extra:
                if id_word in obj_phrase:
                    obj_en = EXTRA_ID_TO_EN[id_word]
                    break
            if not obj_en:
                sorted_labels = sorted(label_map.keys(), key=len, reverse=True)
                for local in sorted_labels:
                    if local in obj_phrase:
                        obj_en = label_map[local]
                        break

        if not obj_en:
            obj_en = obj_phrase if obj_phrase else key

        if found_color_en:
            return f"{found_color_en} {obj_en}".strip()
        return obj_en

    # ── Inferensi ────────────────────────────────────────────────────────

    def find(
        self,
        frame: np.ndarray,
        prompt_en: str,
        target_id: str,
        conf: float | None = None,
    ) -> dict:
        """Cari satu jenis objek di frame. Selalu balas dict, tidak pernah lempar.

        Bentuk balasan sengaja mengikuti state CO-06 / CO-07 / CO-10:
        - found=False        → CO-10 (tidak ketemu di frame), app menyuruh putar badan
        - found=True, n=1    → CO-06 (arah + jarak)
        - found=True, n>1    → CO-07 (yang terdekat disebut, sisanya dihitung)
        """
        if not self.ensure_loaded():
            return {
                "found": False,
                "reason": "model_unavailable",
                "message": "Pencarian objek sedang tidak bisa dipakai. Bukan karena kameramu.",
                "matches": [],
                "total_match": 0,
            }

        try:
            t0 = time.time()
            if self._active_prompts != [prompt_en]:
                self.model.set_classes([prompt_en], self.model.get_text_pe([prompt_en]))
                self._active_prompts = [prompt_en]

            results = self.model.predict(
                frame, conf=conf or self.conf, verbose=False
            )
            inference_ms = (time.time() - t0) * 1000

            h, w = frame.shape[:2]
            boxes = results[0].boxes
            if boxes is None or len(boxes) == 0:
                return {
                    "found": False,
                    "reason": "not_in_frame",
                    "message": f"{target_id} belum terlihat. Coba putar badan pelan-pelan.",
                    "matches": [],
                    "total_match": 0,
                    "prompt_en": prompt_en,
                    "inference_ms": round(inference_ms, 1),
                }

            matches = []
            for box in boxes:
                x1, y1, x2, y2 = (int(v) for v in box.xyxy[0].tolist())
                box_h = max(y2 - y1, 1)
                dist = self._estimate_distance(prompt_en, box_h)
                matches.append({
                    "confidence": round(float(box.conf[0]), 3),
                    "distance_meter": round(dist, 2),
                    "direction": self._direction((x1 + x2) / 2, w),
                    "vertical": self._vertical((y1 + y2) / 2, h),
                    "bbox": {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                })

            matches.sort(key=lambda m: m["distance_meter"])
            nearest = matches[0]

            return {
                "found": True,
                "reason": "ok",
                "message": self._compose_message(target_id, nearest, len(matches)),
                "matches": matches,
                "total_match": len(matches),
                "nearest": nearest,
                "prompt_en": prompt_en,
                "inference_ms": round(inference_ms, 1),
            }

        except Exception as e:
            logger.error(f"Cari objek gagal: {e}")
            return {
                "found": False,
                "reason": "server_error",
                "message": "Bukan karena kameramu, pencarian sedang bermasalah. Coba lagi.",
                "matches": [],
                "total_match": 0,
                "error": str(e),
            }

    # ── Penyusun naskah suara ────────────────────────────────────────────

    def _compose_message(self, target_id: str, nearest: dict, total: int) -> str:
        """Naskah CO-06 / CO-07 / CO-08 — instruksi fisik dan konkret."""
        dist = nearest["distance_meter"]
        arah = nearest["direction"]

        if dist < 0.6:
            jarak_kata = "setengah meter, ulurkan tangan"
        elif dist < 1.2:
            jarak_kata = "sekitar satu meter"
        elif dist < 2.5:
            jarak_kata = "sekitar dua meter"
        else:
            jarak_kata = f"sekitar {dist:.0f} meter"

        if total > 1:
            return (
                f"Ada {total} {target_id}. Yang terdekat di {arah}, {jarak_kata}."
            )
        return f"{target_id} di {arah}, {jarak_kata}."

    # ── Geometri ─────────────────────────────────────────────────────────

    def _estimate_distance(self, prompt_en: str, box_h: int) -> float:
        real_h = EXTRA_HEIGHTS_CM.get(prompt_en, DEFAULT_HEIGHT_CM)
        for key, val in EXTRA_HEIGHTS_CM.items():
            if key in prompt_en:
                real_h = val
                break
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

    def _direction(self, cx: float, w: int) -> str:
        third = w / 3
        if cx < third:
            return "kiri"
        if cx < third * 2:
            return "depan"
        return "kanan"

    def _vertical(self, cy: float, h: int) -> str:
        third = h / 3
        if cy < third:
            return "atas"
        if cy < third * 2:
            return "tengah"
        return "bawah"
```

---

## File: `services/moondream_service.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/moondream_service.py`

```python
"""
Moondream2 Scene Description Service
=====================================
Menjalankan Moondream2 (~2B) secara lazy-load di GPU lokal (RTX 3050 4GB VRAM).
- Length='short' → caption singkat, padat, alt-text style
- Single image processing (Moondream tidak support batching)
- FP16 untuk efisiensi VRAM 4GB
- Thread-safe via asyncio.Lock
"""

import asyncio
import io
from typing import Optional

from loguru import logger
from PIL import Image


class MoonDreamService:
    """Lazy-loaded Moondream2 service.
    
    Dibuat singleton lewat app.state.moondream_service di lifespan.
    Model TIDAK dimuat saat startup (bobotnya ~2GB) — dimuat saat
    permintaan pertama datang (warm-up ~5-10 detik, sekali saja).

    Menggunakan official `moondream` pip package (bukan transformers
    AutoModelForCausalLM) agar kompatibel dengan transformers >= 5.x.
    """

    def __init__(self, model_id: str = "vikhyatk/moondream2", device: str = "auto"):
        self.model_id = model_id
        self._device = device
        self._model = None
        self._tokenizer = None
        self._loaded = False
        self._lock = asyncio.Lock()

    @property
    def loaded(self) -> bool:
        return self._loaded

    def _resolve_device(self) -> str:
        """Pilih device: 'cuda' jika tersedia, fallback ke 'cpu'."""
        if self._device == "auto":
            try:
                import torch
                return "cuda" if torch.cuda.is_available() else "cpu"
            except ImportError:
                return "cpu"
        return self._device

    def _load_sync(self) -> bool:
        """Muat model secara sinkron — dipanggil di thread pool dari _ensure_loaded.

        Membutuhkan transformers>=4.40,<5.0 — moondream2 (vikhyatk/moondream2)
        belum kompatibel dengan transformers 5.x (all_tied_weights_keys API change).
        """
        try:
            import torch
            from transformers import AutoModelForCausalLM, AutoTokenizer

            device = self._resolve_device()
            dtype = torch.float16 if device == "cuda" else torch.float32

            logger.info(f"[Moondream2] Memuat model {self.model_id} ke {device} ({dtype})...")

            self._tokenizer = AutoTokenizer.from_pretrained(
                self.model_id, trust_remote_code=True
            )
            self._model = AutoModelForCausalLM.from_pretrained(
                self.model_id, trust_remote_code=True, torch_dtype=dtype,
            ).to(device)
            self._model.eval()
            self._loaded = True
            logger.success(f"[Moondream2] Model siap di {device}.")
            return True
        except Exception as e:
            logger.error(f"[Moondream2] Gagal memuat model: {e}")
            return False

    async def _ensure_loaded(self) -> bool:
        """Thread-safe lazy loader. Hanya muat sekali."""
        if self._loaded:
            return True
        async with self._lock:
            if self._loaded:
                return True  # Double-check setelah dapat lock
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(None, self._load_sync)

    async def describe(
        self,
        image_bytes: bytes,
        length: str = "short",
    ) -> Optional[str]:
        """
        Deskripsikan gambar menggunakan Moondream2.
        
        Args:
            image_bytes: JPEG/PNG bytes dari kamera
            length: 'short' (1 kalimat, alt-text style) atau 'normal'
        
        Returns:
            Teks deskripsi Bahasa Inggris, atau None jika gagal.
        """
        if not await self._ensure_loaded():
            return None

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, self._describe_sync, image_bytes, length
            )
            return result
        except Exception as e:
            logger.error(f"[Moondream2] describe() error: {e}")
            return None

    def _describe_sync(self, image_bytes: bytes, length: str) -> Optional[str]:
        """Inferensi sinkron — dijalankan di thread pool."""
        try:
            pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

            # moondream VL API: encode → caption
            enc = self._model.encode_image(pil_image)
            result = self._model.caption(enc, length=length)

            # result bisa dict {"caption": "..."} atau string tergantung versi
            if isinstance(result, dict):
                caption = result.get("caption", "")
            else:
                caption = str(result)

            return caption.strip() if caption else None
        except Exception as e:
            logger.error(f"[Moondream2] _describe_sync error: {e}")
            return None
```

---

## File: `services/repository.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/repository.py`

```python
"""Akses data ke PostgreSQL untuk seluruh endpoint penunjang.

Semua fungsi di sini aman dipanggil walau DB mati: pemanggil cukup mengecek
`db.database.is_available()` lebih dulu, atau menangkap exception dan balas
503 dengan pesan yang menyebut apa yang masih hidup.
"""

import json
from datetime import datetime, timedelta, timezone

from db.database import execute, execute_returning, fetch_all, fetch_one

# ── Kamus label ──────────────────────────────────────────────────────────


def get_labels(lang: str = "id") -> list[dict]:
    return fetch_all(
        """
        SELECT label_en, label_local, spoken_form, real_height_cm,
               danger_class, searchable
        FROM object_labels
        WHERE lang = :lang
        ORDER BY label_en
        """,
        {"lang": lang},
    )


def get_searchable_labels(lang: str = "id") -> list[dict]:
    return fetch_all(
        """
        SELECT label_en, label_local
        FROM object_labels
        WHERE lang = :lang AND searchable = TRUE
        ORDER BY label_local
        """,
        {"lang": lang},
    )


def labels_updated_at(lang: str = "id") -> str | None:
    row = fetch_one(
        "SELECT max(updated_at) AS ts FROM object_labels WHERE lang = :lang",
        {"lang": lang},
    )
    return row["ts"].isoformat() if row and row["ts"] else None


# ── Intent suara ─────────────────────────────────────────────────────────


def get_all_intents() -> list[dict]:
    rows = fetch_all(
        """
        SELECT vi.intent_key, vi.category, vi.spoken_label, vi.requires_server,
               coalesce(array_agg(ip.phrase) FILTER (WHERE ip.phrase IS NOT NULL), '{}') AS phrases
        FROM voice_intents vi
        LEFT JOIN intent_phrases ip ON ip.intent_id = vi.id
        GROUP BY vi.id, vi.intent_key, vi.category, vi.spoken_label, vi.requires_server
        ORDER BY vi.category, vi.intent_key
        """
    )
    for r in rows:
        r["phrases"] = list(r["phrases"]) if r["phrases"] else []
    return rows


# ── Denominasi uang ──────────────────────────────────────────────────────


def get_denominations() -> list[dict]:
    return fetch_all(
        """
        SELECT value_idr, words, emissions, color_name, class_index, active
        FROM money_denominations
        WHERE active = TRUE
        ORDER BY class_index
        """
    )


def get_denomination(value_idr: int) -> dict | None:
    return fetch_one(
        "SELECT * FROM money_denominations WHERE value_idr = :v AND active = TRUE",
        {"v": value_idr},
    )


# ── Manifest model ───────────────────────────────────────────────────────


def get_manifest() -> list[dict]:
    return fetch_all(
        """
        SELECT model_key, version, filename, format, sha256, size_bytes,
               url_path, min_app_version, mandatory, notes, available, updated_at
        FROM model_manifest
        ORDER BY model_key
        """
    )


def get_manifest_entry(model_key: str) -> dict | None:
    return fetch_one(
        "SELECT * FROM model_manifest WHERE model_key = :k", {"k": model_key}
    )


def update_manifest_file(
    model_key: str, version: str, filename: str, sha256: str,
    size_bytes: int, available: bool,
) -> None:
    execute(
        """
        UPDATE model_manifest
           SET version    = :v,
               filename   = :f,
               sha256     = :sha,
               size_bytes = :size,
               available  = :avail,
               updated_at = now()
         WHERE model_key = :k
        """,
        {"k": model_key, "v": version, "f": filename, "sha": sha256,
         "size": size_bytes, "avail": available},
    )


# ── Telemetri ────────────────────────────────────────────────────────────


def insert_event(
    device_id: str, event_name: str, mode: str | None,
    gesture_count: int | None, duration_ms: int | None,
    payload: dict, occurred_at: datetime,
) -> None:
    execute(
        """
        INSERT INTO telemetry_events
            (device_id, event_name, mode, gesture_count, duration_ms, payload, occurred_at)
        VALUES (:dev, :name, :mode, :gc, :dur, CAST(:payload AS jsonb), :at)
        """,
        {"dev": device_id, "name": event_name, "mode": mode, "gc": gesture_count,
         "dur": duration_ms, "payload": json.dumps(payload), "at": occurred_at},
    )


def event_summary(hours: int = 24) -> list[dict]:
    """Ringkasan untuk membuktikan target desain (jumlah gestur, waktu buka)."""
    return fetch_all(
        """
        SELECT event_name,
               count(*)                        AS total,
               round(avg(gesture_count)::numeric, 2) AS avg_gestures,
               round(avg(duration_ms)::numeric, 0)   AS avg_duration_ms,
               max(occurred_at)                AS last_seen
        FROM telemetry_events
        WHERE occurred_at > now() - make_interval(hours => :h)
        GROUP BY event_name
        ORDER BY total DESC
        """,
        {"h": hours},
    )


# ── Crash report ─────────────────────────────────────────────────────────


def insert_crash(
    device_id: str, app_version: str | None, platform: str | None,
    os_version: str | None, mode: str | None, error_type: str | None,
    message: str | None, stack_trace: str | None, occurred_at: datetime | None,
) -> int:
    row = execute_returning(
        """
        INSERT INTO crash_reports
            (device_id, app_version, platform, os_version, mode,
             error_type, message, stack_trace, occurred_at)
        VALUES (:dev, :app, :plat, :os, :mode, :etype, :msg, :stack, :at)
        RETURNING id
        """,
        {"dev": device_id, "app": app_version, "plat": platform, "os": os_version,
         "mode": mode, "etype": error_type, "msg": message, "stack": stack_trace,
         "at": occurred_at},
    )
    return row["id"] if row else 0


def last_mode_for_device(device_id: str) -> str | None:
    """ER-06: mode terakhir sebelum crash, untuk dipulihkan saat app dibuka."""
    row = fetch_one(
        """
        SELECT mode FROM crash_reports
        WHERE device_id = :dev AND mode IS NOT NULL
        ORDER BY received_at DESC LIMIT 1
        """,
        {"dev": device_id},
    )
    return row["mode"] if row else None


# ── Antrean unggah offline ───────────────────────────────────────────────


def queue_item_exists(idempotency_key: str) -> dict | None:
    return fetch_one(
        "SELECT idempotency_key, status, result FROM upload_queue WHERE idempotency_key = :k",
        {"k": idempotency_key},
    )


def queue_insert(idempotency_key: str, device_id: str, kind: str,
                 queued_at: datetime | None) -> None:
    execute(
        """
        INSERT INTO upload_queue (idempotency_key, device_id, kind, queued_at)
        VALUES (:k, :dev, :kind, :at)
        ON CONFLICT (idempotency_key) DO NOTHING
        """,
        {"k": idempotency_key, "dev": device_id, "kind": kind, "at": queued_at},
    )


def queue_mark_done(idempotency_key: str, result: dict) -> None:
    execute(
        """
        UPDATE upload_queue
           SET status = 'done', result = CAST(:res AS jsonb), processed_at = now()
         WHERE idempotency_key = :k
        """,
        {"k": idempotency_key, "res": json.dumps(result)},
    )


def queue_mark_failed(idempotency_key: str, error: str) -> None:
    execute(
        """
        UPDATE upload_queue
           SET status = 'failed', error = :err, processed_at = now()
         WHERE idempotency_key = :k
        """,
        {"k": idempotency_key, "err": error},
    )


def queue_pending(device_id: str) -> list[dict]:
    return fetch_all(
        """
        SELECT idempotency_key, kind, status, queued_at
        FROM upload_queue
        WHERE device_id = :dev AND status = 'pending'
        ORDER BY queued_at NULLS LAST
        """,
        {"dev": device_id},
    )


# ── Sesi Asisten Suara ───────────────────────────────────────────────────

HISTORY_TTL_MINUTES = 15


def touch_session(session_id: str, device_id: str) -> None:
    execute(
        """
        INSERT INTO assistant_sessions (session_id, device_id)
        VALUES (:sid, :dev)
        ON CONFLICT (session_id) DO UPDATE
            SET last_activity = now(), expired = FALSE
        """,
        {"sid": session_id, "dev": device_id},
    )


def add_turn(session_id: str, role: str, text_value: str,
             intent_key: str | None = None) -> None:
    execute(
        """
        INSERT INTO assistant_turns (session_id, role, text, intent_key)
        VALUES (:sid, :role, :text, :intent)
        """,
        {"sid": session_id, "role": role, "text": text_value, "intent": intent_key},
    )


def get_turns(session_id: str, limit: int = 20) -> list[dict]:
    rows = fetch_all(
        """
        SELECT role, text, intent_key, created_at
        FROM assistant_turns
        WHERE session_id = :sid
        ORDER BY created_at DESC
        LIMIT :lim
        """,
        {"sid": session_id, "lim": limit},
    )
    return list(reversed(rows))


def expire_stale_sessions() -> int:
    """AS-23 — riwayat lebih dari 15 menit dihapus, dan itu diumumkan app."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=HISTORY_TTL_MINUTES)
    row = execute_returning(
        """
        WITH stale AS (
            UPDATE assistant_sessions
               SET expired = TRUE
             WHERE expired = FALSE AND last_activity < :cutoff
            RETURNING session_id
        )
        SELECT count(*) AS n FROM stale
        """,
        {"cutoff": cutoff},
    )
    n = row["n"] if row else 0
    if n:
        execute(
            """
            DELETE FROM assistant_turns
             WHERE session_id IN (SELECT session_id FROM assistant_sessions WHERE expired = TRUE)
            """
        )
    return n


def session_expired(session_id: str) -> bool:
    row = fetch_one(
        "SELECT expired FROM assistant_sessions WHERE session_id = :sid",
        {"sid": session_id},
    )
    return bool(row and row["expired"])


# ── Risk zone (pindah dari in-memory) ────────────────────────────────────


def risk_zone_report(grid_key: str, lat: float, lng: float, label: str) -> None:
    execute(
        """
        INSERT INTO risk_zones (grid_key, lat, lng, report_count, labels, last_seen)
        VALUES (:k, :lat, :lng, 1, jsonb_build_object(:label, 1), now())
        ON CONFLICT (grid_key) DO UPDATE
            SET report_count = risk_zones.report_count + 1,
                labels       = jsonb_set(
                                   risk_zones.labels,
                                   ARRAY[:label],
                                   to_jsonb(coalesce((risk_zones.labels ->> :label)::int, 0) + 1)
                               ),
                last_seen    = now()
        """,
        {"k": grid_key, "lat": lat, "lng": lng, "label": label},
    )


def risk_zone_nearby(lat: float, lng: float, radius_m: float, min_count: int) -> dict | None:
    """Cari zona bahaya terdekat memakai jarak haversine langsung di SQL."""
    return fetch_one(
        """
        SELECT grid_key, lat, lng, report_count, labels,
               6371000 * 2 * asin(sqrt(
                   power(sin(radians(lat - :lat) / 2), 2) +
                   cos(radians(:lat)) * cos(radians(lat)) *
                   power(sin(radians(lng - :lng) / 2), 2)
               )) AS distance_m
        FROM risk_zones
        WHERE report_count >= :minc
        ORDER BY distance_m ASC
        LIMIT 1
        """,
        {"lat": lat, "lng": lng, "minc": min_count},
    )


# ── Capability override ──────────────────────────────────────────────────


def get_capability_overrides() -> dict[str, dict]:
    rows = fetch_all(
        "SELECT capability, forced_state, reason FROM capability_overrides"
    )
    return {r["capability"]: r for r in rows}
```

---

## File: `tests/__init__.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/tests/__init__.py`

```python

```

---

## File: `tests/conftest.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/tests/conftest.py`

```python
"""
conftest.py — Shared fixtures untuk semua test backend Guidio.

Menyediakan:
  - `client`   : TestClient FastAPI (tanpa server nyata)
  - `nav_image`: bytes gambar navigasi dari fixtures
  - `obj_image`: bytes gambar cari-objek dari fixtures
"""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Tambah backend root ke sys.path agar `from main import app` bisa jalan
BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

# Fixtures lokal (sudah dicopy dari guidio_app/test/fixtures/)
# Fallback ke guidio_app jika belum dicopy (untuk kompatibilitas)
_LOCAL_FIXTURES = Path(__file__).parent / "fixtures"
_APP_FIXTURES   = BACKEND_DIR.parent.parent / "guidio_app" / "test" / "fixtures"
FIXTURES_DIR    = _LOCAL_FIXTURES if _LOCAL_FIXTURES.exists() else _APP_FIXTURES



@pytest.fixture(scope="session")
def client():
    """TestClient FastAPI — tanpa server nyata, langsung hit ASGI app."""
    from main import app

    with TestClient(app, raise_server_exceptions=True) as c:
        yield c


@pytest.fixture
def nav_image() -> bytes:
    """Gambar navigasi: motor + orang di trotoar (simulasi frame kamera)."""
    path = FIXTURES_DIR / "navigation" / "04_motor_dan_orang.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def got_image() -> bytes:
    """Gambar got terbuka (hazard class 1)."""
    path = FIXTURES_DIR / "navigation" / "01_got_terbuka.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def obj_image_tas() -> bytes:
    """Gambar tas merah di kelas (cari objek fixture 01)."""
    path = FIXTURES_DIR / "object_find" / "test_01_tas_merah_kelas.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def obj_image_botol() -> bytes:
    """Gambar botol minum di dapur (cari objek fixture 03 — model biasanya detect ini)."""
    path = FIXTURES_DIR / "object_find" / "test_03_botol_minum_dapur.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()
```

---

## File: `tests/test_cari_objek.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/tests/test_cari_objek.py`

```python
"""
test_cari_objek.py — Tes endpoint POST /api/cari-objek.

Mensimulasikan Flutter mengirim frame kamera saat user berkata "cari dompet".
Semua gambar diambil dari guidio_app/test/fixtures/object_find/ —
byte-for-byte identik dengan yang dikirim kamera HP via multipart/form-data.
"""

import pytest


def _post_cari(client, image_bytes: bytes, target: str, filename: str = "frame.png"):
    """Helper: POST /api/cari-objek dengan format persis yang dikirim Flutter."""
    return client.post(
        "/api/cari-objek",
        data={"target": target},
        files={"file": (filename, image_bytes, "image/png")},
    )


class TestCariObjekStruktur:
    """Validasi struktur respons — tidak bergantung apakah objek ditemukan."""

    def test_response_200(self, client, obj_image_botol):
        r = _post_cari(client, obj_image_botol, "botol")
        assert r.status_code == 200

    def test_has_found_field(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "found" in body, "Field 'found' tidak ada di response"

    def test_has_total_match(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "total_match" in body

    def test_has_matches_list(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        assert "matches" in body
        assert isinstance(body["matches"], list)

    def test_found_true_means_match_nonempty(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        if body["found"]:
            assert body["total_match"] > 0
            assert len(body["matches"]) > 0

    def test_match_has_required_fields(self, client, obj_image_botol):
        body = _post_cari(client, obj_image_botol, "botol").json()
        for match in body.get("matches", []):
            assert "label" in match or "confidence" in match, \
                "Match item harus punya 'label' atau 'confidence'"


class TestCariObjekInvalidInput:
    def test_invalid_image_bytes(self, client):
        """Gambar rusak harus balas found=False, bukan crash."""
        r = _post_cari(client, b"bukan_gambar_valid", "tas")
        assert r.status_code == 200
        body = r.json()
        assert body["found"] is False
        assert body.get("reason") == "invalid_frame"

    def test_empty_bytes(self, client):
        """Gambar kosong harus balas found=False."""
        r = _post_cari(client, b"", "tas")
        assert r.status_code == 200
        assert r.json()["found"] is False

    def test_target_not_in_frame(self, client, obj_image_botol):
        """Target yang tidak ada di gambar harus balas found=False, bukan error."""
        body = _post_cari(client, obj_image_botol, "pesawat").json()
        assert body["found"] is False
        assert body.get("reason") in ("not_in_frame", "no_match", None)

    def test_no_crash_on_random_target(self, client, obj_image_botol):
        """Target acak tidak boleh sebabkan crash (500)."""
        r = _post_cari(client, obj_image_botol, "xyzabc123")
        assert r.status_code == 200


class TestCariObjekDeteksi:
    """
    Uji deteksi aktual dengan fixture gambar yang sudah diketahui isinya.
    Lulus jika found=True ATAU reason in (not_in_frame, no_match) —
    objek mungkin tidak terdeteksi oleh YOLOE untuk sudut/pencahayaan tertentu.
    """

    @pytest.mark.parametrize("target,fixture_attr", [
        ("botol",      "obj_image_botol"),
        ("tas",        "obj_image_tas"),
    ])
    def test_deteksi_atau_not_in_frame(self, client, target, fixture_attr, request):
        img = request.getfixturevalue(fixture_attr)
        body = _post_cari(client, img, target).json()
        valid = body["found"] or body.get("reason") in ("not_in_frame", "no_match")
        assert valid, f"Respons tidak valid untuk target '{target}': {body}"


class TestCariObjekTargets:
    def test_targets_endpoint_200(self, client):
        r = client.get("/api/cari-objek/targets")
        assert r.status_code == 200

    def test_targets_has_list(self, client):
        body = client.get("/api/cari-objek/targets").json()
        assert "targets" in body
        assert isinstance(body["targets"], list)

    def test_targets_has_total(self, client):
        body = client.get("/api/cari-objek/targets").json()
        assert "total" in body
        assert body["total"] == len(body["targets"])
```

---

## File: `tests/test_describe.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/tests/test_describe.py`

```python
"""
test_describe.py — Tes endpoint POST /api/describe (Moondream2 VLM).

Mensimulasikan Flutter mengirim frame kamera saat user berkata "deskripsikan".
Gambar diambil dari guidio_app/test/fixtures/navigation/ —
byte-for-byte identik dengan yang dikirim kamera HP.

Catatan: Moondream2 lazy-load (~5-10 detik pertama kali).
         Test ini akan lambat di run pertama, cepat di run berikutnya.
"""

import pytest


def _post_describe(client, image_bytes: bytes, filename: str = "frame.png"):
    """Helper: POST /api/describe dengan format persis yang dikirim Flutter."""
    return client.post(
        "/api/describe",
        files={"image": (filename, image_bytes, "image/png")},
        timeout=120,  # Moondream warm-up bisa lambat
    )


class TestDescribeStruktur:
    """Validasi struktur respons — tidak bergantung isi caption."""

    def test_response_200(self, client, nav_image):
        r = _post_describe(client, nav_image)
        assert r.status_code == 200

    def test_has_description_en(self, client, nav_image):
        """Response harus punya key 'description_en' (bukan 'deskripsi')."""
        body = _post_describe(client, nav_image).json()
        assert "description_en" in body, \
            "Key 'description_en' tidak ada — pastikan bukan versi lama yang pakai 'deskripsi'"

    def test_no_deskripsi_key(self, client, nav_image):
        """Key lama 'deskripsi' (Bahasa Indonesia) sudah dihapus."""
        body = _post_describe(client, nav_image).json()
        assert "deskripsi" not in body

    def test_description_is_english(self, client, nav_image):
        """Caption harus dalam Bahasa Inggris (cek beberapa kata umum EN)."""
        body = _post_describe(client, nav_image).json()
        desc = body.get("description_en", "")
        if not desc or body.get("error"):
            pytest.skip("Moondream belum dimuat atau gagal — skip language check")
        # Caption EN tidak mengandung kata-kata khas BI di awal
        bi_starters = ("sebuah", "ini adalah", "gambar menunjukkan", "terdapat")
        assert not any(desc.lower().startswith(s) for s in bi_starters), \
            f"Caption tampaknya Bahasa Indonesia: '{desc[:80]}'"

    def test_description_nonempty_on_success(self, client, nav_image):
        """Jika tidak ada error, description_en tidak boleh kosong."""
        body = _post_describe(client, nav_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream error (mungkin belum dimuat): {body['error']}")
        assert body["description_en"].strip(), "description_en kosong padahal tidak ada error"


class TestDescribeInvalidInput:
    def test_invalid_image_returns_200(self, client):
        """Gambar rusak harus balas 200 dengan error field, bukan crash 500."""
        r = _post_describe(client, b"bukan_gambar")
        assert r.status_code == 200

    def test_invalid_image_has_error_or_fallback(self, client):
        """Gambar rusak harus ada 'error' atau description fallback."""
        body = _post_describe(client, b"bukan_gambar").json()
        has_error = bool(body.get("error"))
        has_desc  = bool(body.get("description_en"))
        assert has_error or has_desc, \
            "Respons tidak punya 'error' maupun 'description_en'"

    def test_empty_image_returns_200(self, client):
        """Gambar kosong (0 byte) harus 200, bukan 500."""
        r = _post_describe(client, b"")
        assert r.status_code == 200


class TestDescribeKonten:
    """
    Validasi isi caption untuk gambar yang sudah diketahui objeknya.
    04_motor_dan_orang.png berisi scooter + orang di trotoar.
    Skip otomatis jika Moondream belum dimuat.
    """

    def test_motor_orang_caption_reasonable(self, client, nav_image):
        body = _post_describe(client, nav_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream tidak tersedia: {body['error']}")
        desc = body["description_en"].lower()
        # Setidaknya salah satu dari: person/people/man/woman, scooter/motorcycle/bike
        has_person = any(w in desc for w in ("person", "people", "man", "woman", "pedestrian"))
        has_vehicle = any(w in desc for w in ("scooter", "motorcycle", "bike", "moped", "vehicle"))
        assert has_person or has_vehicle, \
            f"Caption tidak menyebut orang/motor: '{desc[:120]}'"

    def test_got_terbuka_caption_reasonable(self, client, got_image):
        body = _post_describe(client, got_image).json()
        if body.get("error"):
            pytest.skip(f"Moondream tidak tersedia: {body['error']}")
        desc = body["description_en"].lower()
        # Gambar got terbuka: biasanya ada sidewalk/road/street/drain/gutter
        hazard_words = ("sidewalk", "road", "street", "drain", "gutter",
                        "pavement", "concrete", "ground", "path", "hole")
        assert any(w in desc for w in hazard_words), \
            f"Caption tidak mendeskripsikan permukaan jalan: '{desc[:120]}'"
```

---

## File: `tests/test_health.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/tests/test_health.py`

```python
"""
test_health.py — Tes endpoint /health dan /api/capabilities.

Grup A dari VERIFIKASI_FITUR.md, versi pytest otomatis.
Tidak membutuhkan database atau model hidup — semua dicek strukturnya saja.
"""


class TestHealth:
    def test_status_ok(self, client):
        """GET /health harus balas status='ok'."""
        r = client.get("/health")
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "ok"

    def test_fields_present(self, client):
        """Health response harus punya semua field yang dipakai Flutter."""
        r = client.get("/health")
        body = r.json()
        for field in ("status", "service", "version", "uptime_seconds",
                      "database", "find_object", "describe", "server_time_ms"):
            assert field in body, f"Field '{field}' tidak ada di /health"

    def test_uptime_positive(self, client):
        """Uptime harus bilangan positif."""
        r = client.get("/health")
        assert r.json()["uptime_seconds"] >= 0

    def test_server_time_ms_fast(self, client):
        """Health check harus selesai < 500 ms (server_time_ms)."""
        r = client.get("/health")
        assert r.json()["server_time_ms"] < 500

    def test_no_qwen_reference(self, client):
        """Respons tidak boleh menyebut Qwen (sudah dihapus dari stack)."""
        r = client.get("/health")
        assert "qwen" not in r.text.lower()


class TestCapabilities:
    def test_status_200(self, client):
        """GET /api/capabilities harus balas 200."""
        r = client.get("/api/capabilities")
        assert r.status_code == 200

    def test_has_capabilities_key(self, client):
        """Response harus punya key 'capabilities'."""
        body = client.get("/api/capabilities").json()
        assert "capabilities" in body

    def test_six_modes_present(self, client):
        """Semua 6 mode harus ada di capabilities."""
        caps = client.get("/api/capabilities").json()["capabilities"]
        for mode in ("detection", "money", "read_text", "navigation",
                     "assistant", "find_object"):
            assert mode in caps, f"Mode '{mode}' tidak ada di capabilities"

    def test_on_device_modes_always_up(self, client):
        """4 mode on-device harus selalu 'up' — tidak bergantung server."""
        caps = client.get("/api/capabilities").json()["capabilities"]
        for mode in ("detection", "money", "read_text", "navigation"):
            assert caps[mode]["state"] == "up", \
                f"Mode on-device '{mode}' seharusnya 'up', dapat '{caps[mode]['state']}'"
            assert caps[mode]["on_device"] is True

    def test_no_ws_detect_reference(self, client):
        """Tidak boleh ada referensi /ws/detect (endpoint sudah dihapus)."""
        r = client.get("/api/capabilities")
        assert "/ws/detect" not in r.text

    def test_has_server_time(self, client):
        """Response harus punya server_time (ISO 8601)."""
        body = client.get("/api/capabilities").json()
        assert "server_time" in body
        # Cek format ISO 8601 kasar
        assert "T" in body["server_time"]
```

---

## File: `utils/image_utils.py`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/utils/image_utils.py`

```python
import cv2
import numpy as np


def bytes_to_numpy(image_bytes: bytes) -> np.ndarray:
    """Convert raw bytes (JPEG) to numpy BGR array."""
    arr = np.frombuffer(image_bytes, np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)


def encode_image_base64(frame: np.ndarray, quality: int = 85) -> str:
    """Encode numpy frame to base64 JPEG string (untuk debugging)."""
    import base64
    _, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
    return base64.b64encode(buf.tobytes()).decode()


def draw_detections(frame: np.ndarray, detections: list[dict]) -> np.ndarray:
    """Gambar bounding box di frame untuk debugging/visualisasi."""
    result = frame.copy()
    color_map = {
        "critical": (0, 0, 255),    # merah
        "warning":  (0, 165, 255),  # orange
        "info":     (0, 255, 0),    # hijau
    }
    for det in detections:
        b     = det.get("bbox", {})
        if not b:
            continue
        color = color_map.get(det.get("danger_level", "info"), (255, 255, 255))
        cv2.rectangle(result, (b["x1"], b["y1"]), (b["x2"], b["y2"]), color, 2)
        label = f"{det.get('label_id', '')} {det.get('distance_meter', 0):.1f}m"
        cv2.putText(
            result, label, (b["x1"], max(b["y1"] - 8, 12)),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
        )
    return result
```

---

