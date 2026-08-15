# 📁 KUMPULAN KODE LENGKAP VINARA BACKEND (FASTAPI)

> Total Berkas: 28

---

## 📑 Daftar Berkas

1. `README.md`
2. `db/database.py`
3. `db/schema.sql`
4. `db/seed.py`
5. `export_tflite.py`
6. `main.py`
7. `requirements.txt`
8. `routers/asisten.py`
9. `routers/cari_objek.py`
10. `routers/detect.py`
11. `routers/narasi.py`
12. `routers/navigasi.py`
13. `routers/ocr.py`
14. `routers/risk_zone.py`
15. `routers/support.py`
16. `routers/uang.py`
17. `routers/voice_router.py`
18. `routers/websocket.py`
19. `services/camera_health.py`
20. `services/find_object_service.py`
21. `services/intent_service.py`
22. `services/ocr_service.py`
23. `services/repository.py`
24. `services/risk_zone_service.py`
25. `services/segmentation_service.py`
26. `services/uang_service.py`
27. `services/yolo_service.py`
28. `utils/image_utils.py`

---

## Berkas: `README.md`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/README.md`

```markdown
# Vinara Backend (FastAPI)

Server untuk Vinara. Menangani pekerjaan yang tidak masuk akal dikerjakan di
ponsel: membaca tulisan, memahami perintah suara yang rumit, mencari barang
dari kalimat bebas, dan membaca jalur trotoar.

**Hal pertama yang perlu dipahami:** dua dari enam mode **tidak pernah
memanggil server ini sama sekali**, yaitu Deteksi Objek dan Kenali Uang.
Itu keputusan sengaja, bukan kekurangan. Keduanya menyangkut keselamatan dan
uang, dan dipakai di tempat yang sinyalnya sering buruk seperti jalan raya,
pasar, dan warung. Fitur yang mati saat tidak ada internet berarti fitur yang
gagal di saat paling dibutuhkan.

---

## Daftar isi

1. [Menjalankan](#1-menjalankan)
2. [Enam fitur dan pembagian tugasnya](#2-enam-fitur-dan-pembagian-tugasnya)
3. [Rujukan endpoint](#3-rujukan-endpoint)
4. [Basis data](#4-basis-data)
5. [Prinsip yang dipegang server ini](#5-prinsip-yang-dipegang-server-ini)
6. [Struktur folder](#6-struktur-folder)
7. [Keterbatasan yang perlu diketahui](#7-keterbatasan-yang-perlu-diketahui)
8. [Uji cepat](#8-uji-cepat)

---

## 1. Menjalankan

### Prasyarat

**Tesseract**, mesin pembaca tulisan. Ini program sistem, bukan paket Python:

```bash
sudo dnf install -y tesseract tesseract-langpack-ind tesseract-langpack-eng
```

Paket `tesseract-langpack-ind` penting, karena kode memanggil OCR dengan
bahasa `ind+eng`. Tanpa data bahasa Indonesia, hasil bacaannya buruk.

**PostgreSQL** yang sedang berjalan, lalu buat basis datanya sekali saja:

```bash
createdb -h localhost -U postgres vinara_dev
```

### Langkah menjalankan

```bash
cd backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt

cp .env.example .env      # isi kredensial PostgreSQL dan kunci Anthropic

venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Tabel basis data dibuat otomatis saat startup (aman diulang berkali kali),
lalu data rujukan diisi: 52 label objek, 20 intent suara beserta 61 varian
ucapan, 7 denominasi uang, dan manifest model.

Dokumentasi endpoint interaktif: `http://localhost:8000/docs`

**Kalau PostgreSQL mati, server tetap jalan.** Endpoint yang membutuhkan
basis data membalas dengan pesan yang menyebutkan apa yang masih berfungsi,
bukan sekadar kode error kosong.

---

## 2. Enam fitur dan pembagian tugasnya

| Fitur | Diproses di mana | Endpoint |
|---|---|---|
| Deteksi Objek | **Ponsel**, server hanya pembanding | `WS /ws/detect`, `POST /api/detect` |
| Kenali Uang | **Ponsel**, tidak pernah ke server | `POST /api/uang` (opsional) |
| Baca Teks | Server | `POST /api/ocr` |
| Asisten Suara | Server, ada cadangan lokal | `POST /api/intent`, `/api/narasi` |
| Cari Objek | Server | `POST /api/cari-objek` |
| Navigasi jalur | Server, rintangan tetap di ponsel | `POST /api/navigasi` |

### Cari Objek: kenapa memakai YOLOE

Model pengenalan benda biasa hanya bisa mengenali daftar benda yang sudah
ditentukan saat pelatihan. Masalahnya, target pencarian datang dari ucapan
pengguna dan bisa apa saja: "dompet", "kunci motor", "tas merah".

YOLOE menerima **prompt teks bebas**, jadi bisa mencari benda yang tidak
pernah diajarkan secara khusus. Nama barang Bahasa Indonesia diterjemahkan
dulu ke Inggris memakai tabel `object_labels` ditambah kamus bawaan berisi
83 nama barang sehari hari.

Model dimuat **saat permintaan pertama**, bukan saat startup, karena
berkasnya ratusan megabita dan mode ini jarang dipakai dibanding deteksi
rintangan. Panggilan pertama memakan sekitar 2 detik, sesudahnya cepat.

Balasan `found: false` dengan alasan `not_in_frame` **bukan error**. Itu
kondisi normal: barangnya memang belum terlihat, dan aplikasi akan menyuruh
pengguna memutar badan lalu memanggil endpoint ini lagi.

### Navigasi: tiga zona jalur

Gambar dari kamera dibagi menjadi tiga bagian (kiri, tengah, kanan), lalu
masing masing dinilai seberapa layak dilewati.

Model utamanya PIDNet-S. Kalau berkas modelnya belum ada, server memakai
**cadangan berbasis pengolahan citra biasa**: permukaan yang bisa dijalani
umumnya rata, yaitu sedikit garis tepi dan warnanya konsisten dengan area
tepat di depan kaki pengguna.

Bentuk balasannya sama persis untuk kedua jalur, dan jalur mana yang sedang
dipakai selalu disebutkan di kolom `source`. Jadi tidak ada klaim palsu, dan
mengganti cadangan dengan model sungguhan nanti tidak mengubah satu baris pun
di sisi aplikasi.

Cek jalur yang sedang aktif lewat `GET /api/navigasi/status`.

> Mode Navigasi **tidak pernah dimatikan saat offline.** Deteksi rintangannya
> berjalan di ponsel dan tetap hidup. Mematikan seluruh mode hanya karena
> segmentasi jalur tidak tersedia sama saja mencabut fungsi keselamatan yang
> sebenarnya masih bekerja. Status terburuknya adalah `limited`.

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

Estimasi durasi bacaan disertakan karena aplikasi harus menyebutkan perkiraan
waktu **sebelum** mulai membacakan teks panjang, supaya pengguna bisa memilih
mendengar ringkasannya saja.

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

Kalau `lat` dan `lng` diisi, balasan bisa memuat `risk_zone`, yaitu peringatan
dari laporan pengguna lain di lokasi itu. Itu informasi yang tidak terlihat
kamera.

#### `POST /api/intent`

Memahami perintah suara yang tidak dikenali parser lokal di ponsel.

Urutan usahanya: **cocokkan frasa persis, lalu kemiripan kata dan nama
barang, baru LLM.**

Yang menarik: kalau ada **dua kemungkinan yang sama sama masuk akal**, server
sengaja **tidak** memanggil LLM dan langsung bertanya balik.

```json
POST {"text": "kenal kunci"}

{
  "resolved": false,
  "reason": "ambiguous",
  "message": "Saya dengar kenal kunci. Maksudmu cari kunci, atau kenali uang?"
}
```

Alasannya: menebak salah lebih mahal daripada satu pertanyaan, karena
penggunanya tidak bisa melihat layar untuk mengoreksi. Perintah untuk LLM pun
secara eksplisit menyuruhnya menjawab "tidak tahu" saat ragu.

#### `POST /api/narasi`

Mengubah hasil deteksi menjadi kalimat natural memakai Claude Haiku.
Masukannya **teks terstruktur, bukan gambar**:

```
- orang, jarak 1.2 meter, posisi depan, bahaya: critical
- motor, jarak 2.8 meter, posisi kanan, bahaya: warning
```

Ini mencegah AI "salah lihat" benda yang tidak ada, jauh lebih murah, dan
lebih cepat. Kalau Claude gagal atau kuncinya tidak diisi, endpoint ini
otomatis memakai template sederhana dan tidak pernah membuat server berhenti.

#### `POST /api/uang` (opsional)

Jalur utama fitur ini ada di ponsel. Endpoint ini hanya untuk pembanding.
Kalau model server tidak ada, balasannya jujur:

```json
{
  "detected": false,
  "reason": "model_unavailable",
  "message": "Pengenalan uang di server belum aktif. Mode Kenali Uang berjalan di perangkat tanpa internet."
}
```

Endpoint ini **tidak pernah menebak nominal**.

### Endpoint penunjang

Semuanya lahir dari kebutuhan tampilan yang sudah dirancang, bukan dari
kebiasaan umum membuat API.

| Endpoint | Kegunaan |
|---|---|
| `GET /health` | Cek server hidup, sekaligus melaporkan waktu tempuh |
| `GET /api/capabilities` | Mode mana yang hidup, ditanyakan **sebelum** tombol ditekan |
| `GET /api/labels` | Kamus nama benda dalam Bahasa Indonesia |
| `GET /api/models/manifest` | Versi model yang ada di ponsel |
| `POST /api/models/rescan` | Pindai folder `models/`, hitung sidik jari berkas |
| `POST /api/events` | Telemetri alur pemakaian |
| `GET /api/events/summary` | Ringkasan telemetri |
| `POST /api/crash-report` | Laporan aplikasi berhenti mendadak |
| `GET /api/crash-report/last-mode` | Mode terakhir sebelum berhenti, untuk dipulihkan |
| `POST /api/queue/flush` | Kirim ulang gambar yang tertahan saat offline |
| `GET /api/intent/catalog` | 20 perintah suara beserta variannya |
| `POST /api/asisten/turn` | Simpan satu giliran percakapan |
| `GET /api/asisten/history` | Ambil riwayat percakapan |

#### Kenapa `/api/capabilities` penting

Tanpa endpoint ini, pengguna baru tahu server mati **setelah** menekan tombol
dan menunggu. Bagi orang yang tidak melihat layar, itu berarti menunggu dalam
ketidakpastian lalu mendengar kabar gagal.

Dengan endpoint ini, menu mode sudah bisa menandai fitur yang sedang terbatas
sejak awal, dan tombol yang nonaktif bisa langsung menyebutkan alasannya.

#### Kenapa antrean offline butuh kunci idempotensi

`POST /api/queue/flush` mewajibkan `idempotency_key`. Kalau permintaan dengan
kunci yang sama dikirim dua kali, server mengembalikan hasil yang sudah
tersimpan tanpa memproses ulang gambarnya.

Ini penting karena aplikasi mengirim ulang antrean secara otomatis begitu
internet kembali, dan tanpa penjaga ini satu foto bisa terproses berkali kali.

#### Telemetri untuk apa

Bukan untuk pemasaran. Yang diukur adalah target desain yang bisa dibuktikan:
berapa gestur yang dibutuhkan untuk membayar di warung (targetnya di bawah
4), berapa lama dari membuka aplikasi sampai deteksi aktif (targetnya di
bawah 2 detik), dan berapa sering perintah suara tidak dikenali.

---

## 4. Basis data

Sembilan kelompok tabel di PostgreSQL. **Tanpa autentikasi**: identifikasi
cukup memakai `device_id` anonim yang dibuat aplikasi sendiri.

Tidak ada satu pun layar dalam rancangan yang membutuhkan login, jadi
menambahkan sistem akun berarti memaksa hadirnya layar yang tidak pernah
dirancang, dan itu justru menambah langkah bagi pengguna.

| Tabel | Isi |
|---|---|
| `risk_zones` | Lokasi yang sering dilaporkan ada hambatan |
| `object_labels` | Nama benda dalam Bahasa Indonesia, tinggi nyata, tingkat bahaya |
| `voice_intents`, `intent_phrases` | 20 perintah suara dan variannya |
| `model_manifest` | Versi model yang dipakai ponsel |
| `telemetry_events` | Telemetri alur |
| `crash_reports` | Laporan aplikasi berhenti mendadak |
| `upload_queue` | Antrean unggah offline |
| `assistant_sessions`, `assistant_turns` | Riwayat percakapan |
| `money_denominations` | Pecahan uang, kata terbilang, urutan kelas model |
| `capability_overrides` | Paksa status fitur, untuk demo atau perawatan |

Catatan: `risk_zones` dulu hanya disimpan di memori dan hilang setiap server
dinyalakan ulang, artinya zona bahaya tidak pernah benar benar terbentuk.
Sekarang tersimpan permanen, dan perhitungan jaraknya dilakukan langsung di
dalam kueri SQL.

---

## 5. Prinsip yang dipegang server ini

**Server tidak menyaring deteksi.** Ia mengirim hasil mentah. Seluruh
penyaringan ada di aplikasi, supaya hasil dari model di ponsel dan hasil dari
server melewati aturan yang sama persis.

**Tidak ada jalan buntu.** Setiap kegagalan membawa pesan yang menyebutkan
apa yang masih berfungsi, lalu satu tindakan berikutnya. Contohnya, saat
basis data mati: *"Deteksi objek dan kenali uang tetap jalan karena keduanya
on-device. Penyimpanan di server sedang tidak bisa dipakai."*

**Tidak ada kegagalan yang menjatuhkan server.** Model gagal dimuat, basis
data mati, kunci LLM kosong: semuanya dilaporkan lewat `/api/capabilities`,
dan server tetap melayani sisanya.

**Jujur soal kemampuan.** Kalau segmentasi jalur sedang memakai cadangan
sederhana, itu disebutkan di kolom `source`. Tidak ada yang berpura pura
memakai model sungguhan.

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
│   ├── narasi.py            Kalimat natural dari LLM
│   ├── cari_objek.py        Pencarian barang dengan prompt teks
│   ├── navigasi.py          Segmentasi jalur tiga zona
│   ├── uang.py              Pengenalan uang (opsional)
│   ├── asisten.py           Perintah suara dan riwayat percakapan
│   ├── risk_zone.py         Zona rawan
│   └── support.py           Kemampuan, label, manifest, telemetri, antrean
├── services/
│   ├── yolo_service.py         Deteksi rintangan
│   ├── find_object_service.py  YOLOE prompt teks
│   ├── segmentation_service.py PIDNet dan cadangan heuristik
│   ├── ocr_service.py          Tesseract dan estimasi durasi baca
│   ├── intent_service.py       Pencocokan perintah suara
│   ├── uang_service.py         Pengenalan uang di server
│   ├── risk_zone_service.py    Zona rawan
│   ├── camera_health.py        Pemeriksaan kondisi kamera
│   └── repository.py           Seluruh akses basis data
└── utils/
    └── image_utils.py       Bantuan konversi gambar
```

---

## 7. Keterbatasan yang perlu diketahui

1. **Model PIDNet-S belum ada.** Navigasi memakai cadangan heuristik yang
   membaca gambar sungguhan dan cukup untuk menguji seluruh tampilan, tetapi
   ketelitiannya di bawah model terlatih. Letakkan
   `models/pidnet_s_3zona.onnx` untuk mengaktifkan jalur model.

2. **Model uang di server memang tidak ada, dan itu disengaja.** Jalur utama
   fitur ini di ponsel.

3. **Model uang di ponsel hanya mengenali 6 pecahan emisi 2016.** Rp1.000
   belum dikenali. Untuk emisi 2022, model perlu dilatih ulang; struktur API
   dan tabel denominasinya sudah siap menampung.

4. **`ANTHROPIC_API_KEY` tersimpan apa adanya di `.env`.** Berkas itu sudah
   dikecualikan dari git, tetapi sebaiknya kuncinya diganti sebelum
   repositori dibagikan.

5. **Berkas model besar tidak ikut ke git** (`mobileclip_blt.ts`,
   `yoloe-11s-seg.pt`, dan berkas `.pt` serta `.onnx` lainnya). Ultralytics
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

# Cari barang (panggilan pertama memuat model, sekitar 2 detik)
curl -s -X POST $B/api/cari-objek -F "target=dompet" -F "file=@foto.jpg"

# Jalur tiga zona
curl -s -X POST $B/api/navigasi -F "file=@foto.jpg" -F "lat=0" -F "lng=0"
```
```

---

## Berkas: `db/database.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/database.py`

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

## Berkas: `db/schema.sql`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/schema.sql`

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

## Berkas: `db/seed.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/db/seed.py`

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

## Berkas: `export_tflite.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/export_tflite.py`

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

## Berkas: `main.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/main.py`

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
    asisten,
    cari_objek,
    detect,
    narasi,
    navigasi,
    ocr,
    risk_zone,
    support,
    uang,
    voice_router,
    websocket,
)
from services.find_object_service import FindObjectService
from services.intent_service import IntentService
from services.ocr_service import OCRService
from services.risk_zone_service import RiskZoneService
from services.segmentation_service import SegmentationService
from services.uang_service import UangService
from services.yolo_service import YOLOService

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

    # PostgreSQL — telemetri, crash report, antrean offline, kamus label,
    # manifest model, sesi asisten, risk zone.
    init_db()

    # Deteksi rintangan (Mode Deteksi Objek + Navigasi).
    yolo = YOLOService(
        model_path=os.getenv("YOLO_MODEL", "yolo11n.pt"),
        device=os.getenv("DEVICE", "auto"),
    )
    if not yolo.load():
        logger.error("YOLO gagal dimuat — deteksi via server tidak aktif.")
    app.state.yolo_service = yolo

    app.state.ocr_service = OCRService()
    app.state.risk_zone_service = RiskZoneService()

    # Segmentasi jalur 3 zona. Tidak adanya model BUKAN kegagalan: service
    # memakai fallback heuristik dan melaporkannya lewat field `source`.
    seg = SegmentationService()
    seg.load()
    app.state.segmentation_service = seg

    # Cari Objek — YOLOE dimuat malas saat permintaan pertama (bobotnya
    # ratusan MB, tidak pantas menahan startup untuk mode yang jarang dipakai).
    app.state.find_object_service = FindObjectService()

    # Kenali Uang di server: OPSIONAL. Jalur utama fitur ini on-device.
    uang_svc = UangService()
    uang_svc.load()
    app.state.uang_service = uang_svc

    # Katalog 20 intent perintah suara dari database.
    intent_svc = IntentService()
    if is_available():
        try:
            from services import repository as repo
            from services.find_object_service import EXTRA_ID_TO_EN

            intents = repo.get_all_intents()
            searchable = sorted(
                {r["label_local"] for r in repo.get_searchable_labels()}
                | set(EXTRA_ID_TO_EN.keys())
            )
            intent_svc.refresh(intents, searchable)
            logger.info(
                f"Katalog intent dimuat: {len(intents)} intent, "
                f"{len(searchable)} nama barang bisa dicari"
            )
        except Exception as e:
            logger.warning(f"Katalog intent gagal dimuat: {e}")
    app.state.intent_service = intent_svc

    logger.success("=== Vinara Backend siap ===")
    yield
    logger.info("Shutdown.")


app = FastAPI(
    title="Vinara / Guidio Vision API",
    version="2.0.0",
    description=(
        "Backend untuk Vinara — asisten visual suara untuk pengguna tunanetra. "
        "Dua dari enam mode (Deteksi Objek, Kenali Uang) berjalan sepenuhnya "
        "on-device dan tidak memanggil API ini sama sekali."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Fitur utama
app.include_router(websocket.router)      # /ws/detect        Deteksi Objek + Navigasi
app.include_router(detect.router)         # /api/detect       single-shot
app.include_router(ocr.router)            # /api/ocr          Baca Teks
app.include_router(narasi.router)         # /api/narasi       narasi scene
app.include_router(voice_router.router)   # /api/route-intent Asisten Suara (lama)
app.include_router(asisten.router)        # /api/intent, /api/asisten/*
app.include_router(cari_objek.router)     # /api/cari-objek
app.include_router(navigasi.router)       # /api/navigasi
app.include_router(uang.router)           # /api/uang (opsional)
app.include_router(risk_zone.router)      # /api/risk-zone

# Penunjang
app.include_router(support.router)        # capabilities, labels, models, events, crash, queue


@app.get("/health")
async def health():
    """Health check. PG-08c menyebut waktu tempuh, jadi latensi harus ikut
    dikembalikan supaya aplikasi bisa membacakannya."""
    t0 = time.perf_counter()
    yolo = getattr(app.state, "yolo_service", None)
    seg = getattr(app.state, "segmentation_service", None)
    payload = {
        "status": "ok",
        "service": "Vinara Vision API",
        "version": "2.0.0",
        "uptime_seconds": round(time.time() - STARTED_AT, 1),
        "database": is_available(),
        "yolo_loaded": bool(yolo and yolo.loaded),
        "segmentation": (seg.source if seg else "unavailable"),
    }
    payload["server_time_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    return payload
```

---

## Berkas: `requirements.txt`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/requirements.txt`

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
anthropic>=0.25.0
httpx>=0.27.0

# PostgreSQL (telemetri, crash report, antrean offline, kamus label,
# manifest model, sesi asisten, risk zone)
sqlalchemy>=2.0
psycopg[binary]>=3.2
```

---

## Berkas: `routers/asisten.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/asisten.py`

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

    # AS-19 — dua kandidat yang sama-sama masuk akal: tanya balik, jangan
    # panggil LLM. Menebak salah lebih mahal daripada satu pertanyaan.
    if len(candidates) >= 2:
        return {
            "resolved": False,
            "reason": "ambiguous",
            "heard": text,
            "message": svc.compose_suggestion(text, candidates),
            "suggestions": candidates,
        }

    # Lapis 3 — LLM, hanya untuk kasus yang belum punya kandidat jelas.
    llm = await svc.match_llm(text)
    if llm:
        return _intent_payload(svc, llm, text, resolved=True)

    # AS-18 — tidak dikenali: sebut yang didengar, tawarkan tebakan terdekat.
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

## Berkas: `routers/cari_objek.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/cari_objek.py`

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

## Berkas: `routers/detect.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/detect.py`

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

## Berkas: `routers/narasi.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/narasi.py`

```python
import os
from fastapi import APIRouter, Request
from pydantic import BaseModel
from loguru import logger

router = APIRouter(prefix="/api", tags=["narasi"])

# System prompt khusus untuk Guidio — asisten navigasi tunanetra
SYSTEM_PROMPT = """Kamu adalah asisten navigasi bernama Guidio untuk penyandang tunanetra.

Tugasmu: ubah data deteksi objek menjadi 1-2 kalimat Bahasa Indonesia yang:
- Natural dan mudah dipahami, seperti orang yang berbicara langsung
- Menyebut posisi (kiri/depan/kanan) dan jarak dalam bahasa sehari-hari (contoh: "sekitar satu meter", "cukup dekat")
- Memberi saran keselamatan jika ada bahaya (contoh: "jalur kiri tampak lebih aman")
- Singkat — maksimal 2 kalimat pendek
- JANGAN sebut angka confidence atau istilah teknis (bounding box, sistem mendeteksi, dll)
- JANGAN sebut angka desimal (gunakan "sekitar satu meter", bukan "1.2 meter")

Jika tidak ada objek berbahaya di sekitar: sampaikan bahwa area tampak aman."""


class NarasiRequest(BaseModel):
    detections: list[dict]
    context: str = "voice"  # "voice" | "tuntun" | "navigasi"


def _template_fallback(detections: list[dict]) -> str:
    """Fallback template jika Claude API gagal — sederhana tapi tidak crash."""
    nearby = [d for d in detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return "Area sekitar tampak aman."
    parts = []
    for d in nearby[:3]:
        dist = d.get("distance_meter", 0)
        dist_str = "sangat dekat" if dist < 1 else f"sekitar {int(dist)} meter"
        parts.append(f"{d.get('label_id', d.get('label_en', 'objek'))} di {d.get('direction', 'depan')}, {dist_str}")
    return "Ada " + ", dan ".join(parts) + "."


@router.post("/narasi")
async def generate_narasi(body: NarasiRequest):
    """
    Generate kalimat natural dari hasil deteksi YOLO.
    Input: detections (teks terstruktur) — BUKAN gambar/base64.
    Model: Claude Haiku (murah, cepat, cukup untuk 1-2 kalimat).
    Fallback ke template jika Claude API gagal.
    """
    if not body.detections:
        return {"narasi": "Area sekitar tampak aman, tidak ada objek yang terdeteksi."}

    nearby = [d for d in body.detections if d.get("distance_meter", 999) < 4.0]
    if not nearby:
        return {"narasi": "Tidak ada rintangan dalam jangkauan 4 meter."}

    api_key = os.getenv("ANTHROPIC_API_KEY", "")
    if not api_key or api_key.startswith("sk-ant-xxxx"):
        logger.warning("ANTHROPIC_API_KEY tidak diset — pakai template fallback")
        return {"narasi": _template_fallback(nearby)}

    # Format deteksi ke teks terstruktur (input ke Claude — BUKAN gambar)
    det_lines = []
    for d in nearby[:5]:  # maks 5 objek
        det_lines.append(
            f"- {d.get('label_id', d.get('label_en', 'objek'))}, "
            f"jarak {d.get('distance_meter', 0):.1f} meter, "
            f"posisi {d.get('direction', 'depan')}, "
            f"bahaya: {d.get('danger_level', 'info')}"
        )

    user_message = (
        "Objek terdeteksi kamera saat ini:\n"
        + "\n".join(det_lines)
        + f"\n\nKonteks: mode {body.context}. Deskripsikan situasi ini untuk pengguna tunanetra."
    )

    try:
        import anthropic

        # AsyncAnthropic + await: versi sinkron memblokir event loop FastAPI
        # selama panggilan ke Claude, jadi permintaan narasi kedua mengantre
        # di belakang yang pertama.
        client   = anthropic.AsyncAnthropic(api_key=api_key)
        response = await client.messages.create(
            model      = "claude-haiku-4-5-20251001",
            max_tokens = 150,
            system     = SYSTEM_PROMPT,
            messages   = [{"role": "user", "content": user_message}],
        )
        narasi = response.content[0].text.strip()
        logger.info(f"Claude narasi: {narasi[:60]}...")
        return {"narasi": narasi}

    except Exception as e:
        logger.error(f"Claude API gagal: {e} — pakai template fallback")
        return {"narasi": _template_fallback(nearby)}
```

---

## Berkas: `routers/navigasi.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/navigasi.py`

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
            result["obstacles"] = yolo.infer(frame)
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

## Berkas: `routers/ocr.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/ocr.py`

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

## Berkas: `routers/risk_zone.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/risk_zone.py`

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

## Berkas: `routers/support.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/support.py`

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
    llm_ok = bool(os.getenv("ANTHROPIC_API_KEY", "").strip())

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

## Berkas: `routers/uang.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/uang.py`

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

## Berkas: `routers/voice_router.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/voice_router.py`

```python
from fastapi import APIRouter
from pydantic import BaseModel
import anthropic
import logging

router = APIRouter()

# Gunakan AsyncAnthropic agar tidak blocking FastAPI event loop
client = anthropic.AsyncAnthropic()

VALID_INTENTS = {"describe_scene", "ocr", "navigation", "chitchat"}
DEFAULT_INTENT = "describe_scene"  # fallback paling aman untuk tunanetra

ROUTER_SYSTEM = """Kamu adalah intent classifier untuk asisten navigasi tunanetra berbahasa Indonesia.

Klasifikasikan teks input ke SATU intent dari daftar berikut:
- describe_scene : user ingin tahu apa yang ada di sekitar atau di depan mereka
- ocr            : user ingin membaca teks, tulisan, atau kata-kata yang ada di depan
- navigation     : user ingin pergi ke suatu tempat atau meminta panduan navigasi
- chitchat       : pertanyaan umum, sapaan, atau percakapan yang tidak terkait navigasi

Jawab HANYA dengan satu kata intent tersebut. Tidak ada tanda baca, tidak ada kalimat lain."""


class RouteRequest(BaseModel):
    text: str


class RouteResponse(BaseModel):
    intent: str
    fallback_used: bool


@router.post("/api/route-intent", response_model=RouteResponse)
async def route_intent(req: RouteRequest):
    """
    LLM intent routing untuk Voice Assistant.

    max_tokens=10 + temperature=0.0 → latency routing < 300ms.
    Fallback ke 'describe_scene' jika Claude gagal atau return intent tidak valid.
    """
    try:
        response = await client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=10,
            temperature=0.0,
            system=ROUTER_SYSTEM,
            messages=[{"role": "user", "content": req.text}],
        )
        intent = response.content[0].text.strip().lower()

        if intent not in VALID_INTENTS:
            logging.warning(
                f"Intent tidak valid dari LLM: '{intent}', fallback ke {DEFAULT_INTENT}"
            )
            return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)

        return RouteResponse(intent=intent, fallback_used=False)

    except Exception as e:
        logging.error(f"route_intent gagal: {e}")
        return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)
```

---

## Berkas: `routers/websocket.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/routers/websocket.py`

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

## Berkas: `services/camera_health.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/camera_health.py`

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

## Berkas: `services/find_object_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/find_object_service.py`

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

# Terjemahan target Bahasa Indonesia → prompt Inggris untuk YOLOE.
# COCO sudah tercakup lewat tabel object_labels; peta di sini melengkapi
# barang rumah tangga umum yang TIDAK ada di COCO tapi sering dicari.
EXTRA_ID_TO_EN: dict[str, str] = {
    "dompet": "wallet",
    "kunci": "keys",
    "kunci motor": "motorcycle keys",
    "kunci rumah": "house keys",
    "hp": "cell phone",
    "handphone": "cell phone",
    "kacamata": "eyeglasses",
    "botol minum": "water bottle",
    "botol air": "water bottle",
    "tas": "bag",
    "tas ransel": "backpack",
    "remote tv": "tv remote control",
    "sepatu": "shoes",
    "sandal": "sandals",
    "charger": "phone charger",
    "kabel charger": "charging cable",
    "headset": "headphones",
    "earphone": "earphones",
    "jaket": "jacket",
    "topi": "hat",
    "obat": "medicine box",
    "masker": "face mask",
    "jam tangan": "wristwatch",
    "power bank": "power bank",
    "korek": "lighter",
    "sisir": "comb",
    "handuk": "towel",
    "bantal": "pillow",
    "selimut": "blanket",
    "piring": "plate",
    "panci": "cooking pot",
    "wajan": "frying pan",
    "payung lipat": "folding umbrella",
    "tongkat": "walking cane",
    "uang": "banknote",
    "kartu": "plastic card",
    "kotak": "box",
    "tempat sampah": "trash bin",
    "saklar": "light switch",
    "stop kontak": "power outlet",
    "pintu": "door",
    "gagang pintu": "door handle",
    "meja": "table",
    "kursi": "chair",
}

# Tinggi nyata (cm) untuk estimasi jarak similar-triangle pada objek non-COCO.
EXTRA_HEIGHTS_CM: dict[str, int] = {
    "wallet": 10, "keys": 7, "eyeglasses": 4, "water bottle": 25,
    "bag": 35, "backpack": 45, "tv remote control": 18, "shoes": 12,
    "sandals": 5, "phone charger": 8, "charging cable": 10,
    "headphones": 18, "earphones": 5, "jacket": 60, "hat": 12,
    "medicine box": 10, "face mask": 10, "wristwatch": 4,
    "power bank": 10, "lighter": 8, "comb": 18, "towel": 40,
    "pillow": 35, "blanket": 40, "plate": 3, "cooking pot": 20,
    "frying pan": 8, "folding umbrella": 30, "walking cane": 95,
    "banknote": 7, "plastic card": 5, "box": 25, "trash bin": 60,
    "light switch": 8, "power outlet": 8, "door": 200,
    "door handle": 12, "table": 75, "motorcycle keys": 7, "house keys": 7,
}

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
        """Ubah nama barang Bahasa Indonesia jadi prompt Inggris untuk YOLOE.

        `label_map` = {label_local: label_en} dari tabel object_labels.
        Kalau tidak ketemu di mana pun, teks aslinya dipakai apa adanya —
        YOLOE open-vocabulary, jadi tetap ada peluang ketemu.
        """
        key = target_id.strip().lower()
        if key in EXTRA_ID_TO_EN:
            return EXTRA_ID_TO_EN[key]
        if key in label_map:
            return label_map[key]
        # Coba pencocokan sebagian: "tas merah" → "tas"
        for id_word, en_word in EXTRA_ID_TO_EN.items():
            if key.startswith(id_word + " ") or key.endswith(" " + id_word):
                sisa = key.replace(id_word, "").strip()
                return f"{sisa} {en_word}".strip()
        for local, en in label_map.items():
            if key.startswith(local + " ") or key.endswith(" " + local):
                sisa = key.replace(local, "").strip()
                return f"{sisa} {en}".strip()
        return key

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

## Berkas: `services/intent_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/intent_service.py`

```python
"""Resolusi perintah suara sisi server — POST /api/intent.

CommandParser lokal di Flutter menangani 20 intent baku tanpa internet
(0 ms, tetap jalan offline). Server hanya dipanggil saat lokal TIDAK match,
untuk dua kasus yang memang butuh pemahaman bahasa:
  - AS-18 "tidak dikenali" → tawarkan dua tebakan terdekat
  - AS-19 "ambigu"         → pertanyaan pilihan dua

Urutan usaha: cocokkan frasa persis → skor kemiripan kata → LLM (opsional).
Kalau semuanya gagal, balasannya tetap menawarkan dua tebakan, bukan
"perintah gagal" — prinsip "tidak ada jalan buntu".
"""

import os
import re

from loguru import logger

VALID_CATEGORIES = {"mode", "action", "play", "help"}

LLM_SYSTEM = """Kamu pemetaan perintah suara Bahasa Indonesia untuk aplikasi
asisten tunanetra bernama Vinara.

Daftar intent yang tersedia beserta artinya:
{intent_list}

Tugasmu: petakan ucapan pengguna ke SATU intent_key dari daftar di atas.
Jawab HANYA dengan intent_key persis seperti tertulis.

PENTING: jawab `none` kalau ucapan itu MERAGUKAN — yaitu bisa masuk akal
untuk lebih dari satu intent, atau kedengarannya seperti salah dengar.
Menebak salah lebih berbahaya daripada bertanya balik, karena penggunanya
tidak bisa melihat layar untuk mengoreksi. Kalau ragu sedikit saja: none"""


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

    # ── Lapis 3: LLM (opsional) ──────────────────────────────────────────

    async def match_llm(self, text: str) -> dict | None:
        api_key = os.getenv("ANTHROPIC_API_KEY", "")
        if not api_key or api_key.startswith("sk-ant-xxxx") or not self._intents:
            return None
        try:
            import anthropic

            client = anthropic.AsyncAnthropic(api_key=api_key)
            intent_list = "\n".join(
                f"- {i['intent_key']}: {i['spoken_label']}" for i in self._intents
            )
            resp = await client.messages.create(
                model="claude-haiku-4-5-20251001",
                max_tokens=20,
                temperature=0.0,
                system=LLM_SYSTEM.format(intent_list=intent_list),
                messages=[{"role": "user", "content": text}],
            )
            key = resp.content[0].text.strip().lower()
            if key == "none":
                return None
            for intent in self._intents:
                if intent["intent_key"].lower() == key:
                    return {
                        "intent_key": intent["intent_key"],
                        "category": intent["category"],
                        "spoken_label": intent["spoken_label"],
                        "confidence": 0.9,
                        "source": "llm",
                    }
            return None
        except Exception as e:
            logger.warning(f"Pencocokan intent via LLM gagal: {e}")
            return None

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

## Berkas: `services/ocr_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/ocr_service.py`

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

## Berkas: `services/repository.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/repository.py`

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

## Berkas: `services/risk_zone_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/risk_zone_service.py`

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

## Berkas: `services/segmentation_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/segmentation_service.py`

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

## Berkas: `services/uang_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/uang_service.py`

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

## Berkas: `services/yolo_service.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/services/yolo_service.py`

```python
import time
import numpy as np
from ultralytics import YOLO
from loguru import logger

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

# Tinggi nyata objek dalam cm (untuk estimasi jarak)
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

# Focal length piksel (kalibrasi default, bisa di-override via .env)
FOCAL_LENGTH_PX = 615

# Klasifikasi bahaya
DANGER_HIGH   = {"person", "motorcycle", "car", "bus", "truck", "dog"}
DANGER_MEDIUM = {"bicycle", "chair", "bench", "dining table", "stairs"}


class YOLOService:
    def __init__(self, model_path: str = "yolov8m.pt", device: str = "auto"):
        self.model_path = model_path
        self.device     = self._resolve_device(device)
        self.model      = None
        self.loaded     = False

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
            t0          = time.time()
            self.model  = YOLO(self.model_path)
            # Warm-up inference
            dummy = np.zeros((640, 640, 3), dtype=np.uint8)
            self.model.predict(dummy, verbose=False)
            logger.success(f"YOLO loaded dalam {time.time() - t0:.1f}s")
            self.loaded = True
            return True
        except Exception as e:
            logger.error(f"Gagal load YOLO: {e}")
            return False

    def infer(self, frame: np.ndarray, confidence: float = 0.5) -> list[dict]:
        """
        Jalankan inference — kembalikan raw detections TANPA filter.
        Filter ada di Flutter (DetectionFilter).
        """
        if not self.loaded:
            raise RuntimeError("Model belum di-load. Panggil load() terlebih dahulu.")

        h, w = frame.shape[:2]
        t0   = time.time()

        results      = self.model.predict(
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
            label_en  = result.names[int(box.cls[0])]
            label_id  = LABEL_ID.get(label_en, label_en)
            box_h     = y2 - y1
            dist      = self._estimate_distance(label_en, box_h)
            direction = self._get_direction((x1 + x2) / 2, w)
            danger    = self._get_danger(label_en, dist)

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
        """Estimasi jarak via Similar Triangle formula."""
        if box_h <= 0:
            return 999.0
        real_h = REAL_HEIGHTS_CM.get(label, REAL_HEIGHTS_CM["default"])
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
        """Tentukan level bahaya dari kombinasi class + jarak."""
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
```

---

## Berkas: `utils/image_utils.py`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/backend/utils/image_utils.py`

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

