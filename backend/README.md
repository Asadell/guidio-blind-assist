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
