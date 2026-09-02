# Vinara Backend (FastAPI)

Server untuk Vinara. Menangani **dua** pekerjaan yang modelnya tidak muat di
ponsel: mencari barang dari kalimat bebas, dan mendeskripsikan suasana dari
satu foto.

**Hal pertama yang perlu dipahami:** empat dari enam mode **tidak pernah
memanggil server ini sama sekali**. Deteksi Objek, Kenali Uang, Baca Teks, dan
Navigasi berjalan penuh di ponsel. Kalau Kenali Uang salah membaca nominal,
backend sama sekali bukan tempat mencarinya; yang relevan adalah
`guidio_app/README.md` bagian 3 dan repo pelatihan
`new_training/rupiah_vision_revised`.

Itu keputusan sengaja, bukan kekurangan. Prinsipnya satu: kalau fiturnya sudah
ada di ponsel, backend tidak menyediakannya lagi. Jalur ganda hanya menambah
kode yang harus dijaga konsisten, dan menciptakan ketergantungan diam-diam pada
laptop yang menyala di mode yang justru menyangkut keselamatan.

> **Tidak ada LLM di backend ini.** `QwenService` dan `narasi.py` telah dihapus,
> begitu juga `llama-cpp-python` dari `requirements.txt`. Narasi dan intent
> parsing dikerjakan di Flutter, offline.

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
9. [Testing backend (pytest)](#9-testing-backend-pytest)
10. [Koneksi HP ke backend laptop](#10-koneksi-hp-ke-backend-laptop)
11. [Ukuran model dan kebutuhan storage](#11-ukuran-model-dan-kebutuhan-storage)

---

## 1. Menjalankan

### Prasyarat

**PostgreSQL** bersifat **opsional**. Ia dipakai untuk zona rawan dan override
kemampuan (demo/perawatan). Kalau tidak ada, server tetap jalan penuh dan kedua
fitur utamanya tidak terpengaruh sama sekali.

```bash
createdb -h localhost -U postgres vinara_dev   # hanya kalau dipakai
```

> **Tesseract tidak lagi dibutuhkan.** Baca Teks sudah pindah ke ML Kit
> on-device di ponsel dan berjalan penuh tanpa server. Kalau dokumen lama
> menyuruh memasang `tesseract-langpack-ind`, abaikan.

### Langkah menjalankan

```bash
cd backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt

cp .env.example .env  # isi kredensial PostgreSQL bila dipakai

venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

> **Sesudah menyalin `.env.example`, ubah `YOLOE_CONF` menjadi `0.001`.**
> Berkas contoh itu masih berisi nilai lama `0.25`, yang membuat Cari Objek
> gagal menemukan benda berskor rendah tanpa satu pun galat. Alasan lengkapnya
> di bagian 2.
>
> Kunci lain di `.env.example` (`YOLO_MODEL`, `SEGMENTATION_MODEL`,
> `MONEY_MODEL`, `ANTHROPIC_API_KEY`) adalah sisa dari fitur yang sudah pindah
> on-device atau dibuang. Tidak ada satu pun yang dibaca kode yang tersisa.
> Yang benar-benar dipakai: `YOLOE_MODEL`, `YOLOE_CONF`, `MOONDREAM_DEVICE`,
> dan kredensial PostgreSQL.

Log startup yang benar:

```
[FindObject] Service terdaftar (lazy-load model YOLOE).
[Moondream2] Service terdaftar, pemanasan berjalan.
=== Vinara Backend siap ===
```

**Moondream2 dipanaskan di latar belakang saat startup**, tidak lagi menunggu
permintaan pertama. Pemuatannya makan sekitar 20 detik, dan selama itu
ditanggung permintaan pertama, permintaan itu hampir pasti gagal: batas waktu
endpoint 25 detik, jadi hampir seluruh anggarannya habis untuk menunggu bobot
model. Persis yang terjadi di log lama, permintaan pertama timeout dan model
baru siap 6 detik sesudahnya.

Pemanasan dijalankan lewat `asyncio.create_task`, jadi startup tetap seketika
dan `/health` melayani seperti biasa selama bobotnya dibaca. Kegagalan
pemanasan bukan alasan menggagalkan startup: `describe` tetap mencoba memuat
sendiri lewat `ensure_ready()`.

Tidak akan ada log `[Qwen]`, `[YOLO]` server, `[OCR]`, atau `[Tesseract]`.
Kalau muncul, berarti ada berkas lama yang tertinggal.

Dokumentasi endpoint interaktif: `http://localhost:8000/docs`

**Kalau PostgreSQL mati, server tetap jalan.** Kedua model utamanya tidak
menyentuh basis data sama sekali.

---

## 2. Pembagian tugas: on-device vs server

| Fitur | Diproses di mana | Endpoint |
|---|---|---|
| Deteksi Objek | **Flutter** (SSD MobileNet TFLite) | tidak ada |
| Kenali Uang | **Flutter** (MobileNetV2 TFLite) | tidak ada |
| Baca Teks | **Flutter** (Google ML Kit) | tidak ada |
| Navigasi jalur | **Flutter** (PIDNet-S + YOLO11n FP16 + YOLO11n INT8 + SSD COCO) | tidak ada |
| Intent parsing | **Flutter** (`CommandParser`, offline) | tidak ada |
| Narasi deteksi | **Flutter** (`NarrationScheduler`, offline) | tidak ada |
| Cari Objek | **Server** (YOLOE) | `POST /api/cari-objek` |
| Deskripsi suasana | **Server** (Moondream2 VLM) | `POST /api/describe` |

Router yang diarsipkan ke `_archive/routers/` beserta alasannya:

| Berkas | Kenapa dibuang |
|---|---|
| `websocket.py`, `detect.py` | Deteksi rintangan sudah on-device (SSD MobileNet) |
| `ocr.py` | Sudah on-device (ML Kit), dan tetap begitu |
| `uang.py` | Sudah on-device (MobileNetV2 TFLite) |
| `navigasi.py` | Sudah on-device (PIDNet-S + YOLO11n TFLite) |
| `asisten.py`, `voice_router.py` | Intent parsing lokal (`CommandParser`), tanpa LLM |
| `risk_zone.py` | Klien tidak pernah memanggilnya |
| `support_full.py` | 11 endpoint penunjang yang tidak satu pun pernah dipanggil |

Kalau kamu memanggil `/api/ocr`, `/api/uang`, `/api/navigasi`, `/api/detect`,
`/api/narasi`, `/api/intent`, atau `/api/labels` dan mendapat **404**, itu
benar. Lihat uji negatif di bagian 8.

### Cari Objek: kenapa memakai YOLOE

Model pengenalan benda biasa hanya bisa mengenali daftar benda yang sudah
ditentukan saat pelatihan. Masalahnya, target pencarian datang dari ucapan
pengguna dan bisa apa saja: "dompet", "kunci motor", "tas merah".

YOLOE menerima **prompt teks bebas**, jadi bisa mencari benda yang tidak pernah
diajarkan secara khusus. Nama barang Bahasa Indonesia diterjemahkan dulu ke
Inggris oleh `resolve_prompt()`, dalam tiga lapis berurutan:

1. **Kamus kurasi** (`EXTRA_ID_TO_EN` di `services/find_object_constants.py`)
   menang duluan. Isinya dipilih supaya cocok dengan kosakata encoder teks
   YOLOE: `hape` menjadi `cell phone`, bukan `cellphone`.
2. **Field `prompt_en` dari aplikasi**, hasil terjemahan ML Kit on-device, untuk
   kata yang tidak ada di kamus. Di sinilah janji open-vocabulary baru ditepati:
   `irus` menjadi `ladle`, `cobek` menjadi `mortar`.
3. Tebakan substring, lalu frasa Indonesianya apa adanya.

Sebelum lapis 2 ada, kata di luar kamus jatuh ke lapis 3 dan berakhir sebagai
prompt **Bahasa Indonesia** yang dikirim ke encoder berbahasa Inggris. Itu bukan
pencarian yang kurang akurat, melainkan pencarian yang tidak pernah punya
peluang, dan pengguna cuma mendengar "tidak ketemu".

`prompt_en` bersifat opsional. Kalau aplikasi tidak mengirimkannya, server jatuh
ke kamusnya sendiri: hasilnya lebih kasar, bukan gagal.

Model dimuat **saat permintaan pertama**, bukan saat startup. Panggilan pertama
memakan sekitar 2 detik, sesudahnya cepat.

#### Mengapa `YOLOE_CONF` di `.env` sangat kecil (0.001)?

> **Satu-satunya tempat yang benar untuk mengubah threshold adalah `YOLOE_CONF`
> di file `.env`. Nilai di `DEFAULT_CONF` dalam kode akan di-override oleh
> `.env` selama server berjalan, sehingga mengedit kode tidak ada efeknya.**
>
> **Perhatian saat memasang dari nol:** `.env.example` masih berisi
> `YOLOE_CONF=0.25`, nilai lama yang justru bermasalah. Sesudah
> `cp .env.example .env`, ubah menjadi `0.001`. Kalau tidak, Cari Objek akan
> gagal menemukan benda berskor rendah persis seperti yang dijelaskan di bawah,
> dan tidak ada satu pun galat yang menandainya.

YOLOE menggunakan **MobileCLIP text encoder** yang bekerja secara kontrastif:
ia tidak mengklasifikasikan ke kelas yang sudah dilatih, melainkan mengukur
kesamaan antara embedding gambar dan embedding teks prompt. Hasilnya, skor
"confidence" yang dihasilkan jauh lebih kecil dari YOLO closed-set biasa.

Pengukuran pada foto kamera HP nyata (`imgsz=960`, gambar standar lab):

| Benda            | Prompt         | Skor tertinggi |
|------------------|----------------|----------------|
| Botol plastik    | `bottle`       | **0.920**      |
| Kunci motor      | `keychain`     | **0.026**      |
| Kunci            | `key`          | **0.007**      |
| Kacamata bening  | `glasses`      | **0.003**      |

Dengan threshold lama `YOLOE_CONF=0.25`, kunci dan kacamata **tidak pernah
ditemukan** meskipun jelas terlihat di foto, karena skor tertinggi mereka di
bawah ambang. Pengguna hanya mendengar *"belum terlihat, coba putar badan"*
untuk benda yang ada tepat di depan kameranya.

Nilai `0.001` membiarkan semua deteksi valid lolos. False positive memang
lebih mungkin, tapi untuk pengguna tunanetra **salah arah lebih bisa
dikoreksi** (coba lagi dari posisi berbeda) daripada tidak pernah mendapat
informasi posisi sama sekali.

### Deskripsi suasana: Moondream2

`POST /api/describe` mengembalikan `description_en`, caption Bahasa Inggris
langsung dari Moondream2. **Flutter menerjemahkannya secara lokal** lewat
`services/translation_service.dart`, yang memakai Google ML Kit On-Device
Translation. Kalau modelnya belum siap atau terjemahannya tidak layak, kalimat
Inggrisnya dibacakan apa adanya dengan penanda singkat lebih dulu. Tidak ada
LLM penerjemah di alur ini, di sisi mana pun.

> Pendahulunya, `core/voice/scene_translator.dart`, adalah kamus kata-per-kata
> buatan sendiri dan **sudah dihapus** dari repo. Kalau dokumen lama menyebut
> berkas itu, yang berlaku sekarang adalah `translation_service.dart`.

### Gerbang kualitas gambar: sekarang mencatat, bukan menolak

Kedua endpoint melewatkan gambar ke `services/image_gate.py` sebelum menyentuh
model. Yang dikerjakan gerbang itu **sudah berubah**, dan perubahannya perlu
dimengerti sebelum menyetel ambang apa pun di sana.

Kedua profil yang masih dipakai router, `find_object` dan `describe`, sekarang
dipasang `reject_dark: False` **dan** `reject_quality: False`. Foto buram,
gelap, silau, atau beresolusi kecil **tetap diteruskan** ke YOLOE dan
Moondream2.

Alasannya soal biaya, bukan soal kualitas foto. Setiap penolakan berarti
pengguna tunanetra sudah mengangkat ponsel, menunggu jepretan, menunggu
perjalanan jaringan, lalu diberi tahu untuk mengulang semuanya, tanpa pernah
tahu apakah percobaan berikutnya akan lebih baik. Dia tidak bisa melihat
fotonya untuk memutuskan. Untuk kasus gelap, mobile juga sudah punya gerbangnya
sendiri (`CameraCaptureService`, dipakai `_grabFrame` di
`find_object_screen.dart`) yang menawarkan senter sebelum satu byte pun
dikirim, jadi penolakan kedua di server cuma menghentikan permintaan yang sudah
disetujui pengguna.

**Yang TIDAK ikut dibuang adalah catatannya.** Foto bermasalah tetap turun ke
POOR dan balasannya membawa `quality_note` ("Fotonya gelap, jadi hasilnya
mungkin tidak tepat"), yang mengalir ke narasi. Ini penting khusus untuk
`describe`: VLM **tidak pernah mengatakan "saya tidak bisa melihat"**. Dari
foto gelap gulita pun Moondream2 menghasilkan deskripsi yang terdengar
meyakinkan, seperti "a dimly lit room with furniture", dan pengguna tunanetra
tidak punya cara memeriksanya. Menghapus penolakan tanpa menyisakan catatan
berarti halusinasi itu sampai tanpa satu pun tanda. **Kalau `quality_note`
sampai dihapus dari narasi, gerbangnya harus dihidupkan lagi.**

Untuk `find_object` ada satu hal yang berubah artinya, dan itu disengaja.
Gerbang ini dulu dipasang justru untuk membedakan dua hal yang terdengar sama
di telinga: "barangnya tidak ada di sini" dan "fotonya tidak terbaca". Sekarang
keduanya sama-sama pulang sebagai `not_in_frame`, dan yang membedakannya adalah
`quality_note` tadi.

Yang masih ditolak tinggal empat, dan tidak satu pun penilaian kualitas:

| `reason` | Kenapa tetap ditolak |
|---|---|
| `gambar_kosong` | Unggahan gagal, bukan foto jelek |
| `gambar_rusak` | Byte yang tidak bisa didekode. PIL di dalam Moondream2 akan gagal juga, jadi meneruskannya cuma menukar penolakan cepat dengan penolakan yang sama beberapa detik kemudian |
| `gambar_terlalu_besar` | Batas 16 MB, menjaga memori saat berkas masuk |
| `resolusi_terlalu_besar` | Batas 40 MP setelah dekode. Menahan "decode bomb": PNG beberapa ratus kilobyte bisa berisi kanvas 30.000 x 30.000 yang menjadi ~2,7 GB di memori dan menjatuhkan seluruh proses |

Profil `ocr` di berkas itu **dipertahankan meski tidak ada endpoint OCR**. Ia
jadi rujukan angka saat menyetel gerbang ketajaman di sisi Flutter, supaya
kedua sisi mengukur hal yang sama dengan ambang yang sengaja dijaga sejajar.

---

## 3. Rujukan endpoint

Lima endpoint. Itu saja.

### `POST /api/describe`

Deskripsikan suasana kamera via Moondream2.

> **Nama field-nya `image`, bukan `file`.** Ini pernah menjadi bug nyata:
> aplikasi mengirim dengan nama `file`, FastAPI membalas 422 untuk setiap
> permintaan, dan kegagalannya ditelan lalu dilaporkan sebagai gangguan
> jaringan. Fitur itu tidak pernah berhasil sekali pun sampai diperbaiki.

```bash
curl -X POST http://localhost:8000/api/describe -F "image=@foto.jpg"
```

Berhasil:

```json
{
  "ok": true,
  "found": true,
  "description_en": "A person walking on a sidewalk near a parked bicycle.",
  "quality_note": "",
  "message": "",
  "image_quality": {"verdict": "good"},
  "preprocessing": {},
  "elapsed_ms": 2401.3
}
```

Caption ada tapi tidak berguna (`"a photo"`, `"an image"`, atau lebih pendek
dari 12 karakter):

```json
{
  "ok": true,
  "found": false,
  "reason": "deskripsi_tidak_jelas",
  "error": "deskripsi_tidak_jelas",
  "description_en": "a photo",
  "message": "Suasananya tidak bisa dikenali dengan jelas. Fotonya gelap, jadi hasilnya mungkin tidak tepat."
}
```

Ditolak gerbang:

```json
{
  "ok": false,
  "reason": "gambar_rusak",
  "message": "Gambar tidak terbaca. Coba ambil ulang.",
  "retry_suggested": true,
  "image_quality": null,
  "description_en": "",
  "error": "gambar_rusak"
}
```

`message` selalu Bahasa Indonesia dan selalu **instruktif**, karena itu
instruksi untuk pengguna, bukan hasil model. `description_en` tetap Bahasa
Inggris sesuai keputusan desain: penerjemahan dikerjakan di sisi Flutter.

Parameter:

| Field | Bawaan | Catatan |
|---|---|---|
| `image` | wajib | **Namanya `image`, bukan `file`** |
| `length` | `normal` | `short` menghasilkan caption gaya alt-text satu baris, dan pada foto yang ramai ia berhenti di tengah kalimat. Deskripsi yang berhenti di tengah adalah kegagalan paling menyesatkan bagi pengguna tunanetra: terdengar seperti jawaban lengkap, jadi tidak ada alasan untuk bertanya lagi |
| `enhance` | `true` | Mengecilkan sisi terpanjang ke 1024 dan mengoreksi eksposur seperlunya. Bukan penyaring, melainkan pemercepat |
| `timeout` | `25.0` | Detik. Pemuatan model **tidak** dihitung di dalamnya: `ensure_ready()` dipanggil sebelum jam inferensi mulai |

Aplikasi tidak mengirim `length` sama sekali, jadi yang berlaku di jalur nyata
adalah `normal`.

### `POST /api/cari-objek`

Kirim `target` (nama barang Bahasa Indonesia) dan `file` (gambar JPEG).

```bash
curl -X POST http://localhost:8000/api/cari-objek \
     -F "target=dompet" -F "file=@foto.jpg"
```

Parameter:

| Field | Bawaan | Catatan |
|---|---|---|
| `target` | wajib | Nama barang Bahasa Indonesia. **Dibersihkan lebih dulu** (`_clean_target`), karena nilainya dikembalikan di balasan dan ikut menyusun kalimat yang dibacakan TTS |
| `file` | wajib | Frame kamera JPEG. **Namanya `file`, bukan `image`**, kebalikan dari `/api/describe` |
| `prompt_en` | opsional | Terjemahan Inggris dari ML Kit di aplikasi, mis. `red bag`. Dipakai sebagai lapis kedua `resolve_prompt()` |
| `conf` | opsional | Menimpa `YOLOE_CONF` untuk satu permintaan |
| `enhance` | `true` | Koreksi eksposur otomatis |

```json
{
  "found": true,
  "reason": "ok",
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

**Semantik `reason` menentukan tindakan pengguna, jadi jangan disamakan:**

| `reason` | Artinya | Yang harus dilakukan aplikasi |
|---|---|---|
| `ok` | Ketemu | Bacakan arah dan jarak |
| `not_in_frame` | Barangnya tidak terlihat di frame ini. **Bukan error** | Suruh pengguna memutar badan lalu kirim lagi |
| `target_kosong` | Nama barang kosong setelah dibersihkan | Minta pengguna menyebutkan barangnya |
| `model_unavailable` | Model YOLOE gagal dimuat | Katakan ini bukan salah kameranya |
| `server_error` | Inferensi gagal di server | Katakan ini bukan salah kameranya |
| apa pun dengan `retry_suggested: true` | Unggahan gagal atau melewati batas sumber daya | Perbaiki kondisi pengambilan, **jangan** suruh memutar badan |

Deteksi dari foto jelek tidak sama andalnya dengan deteksi dari foto bagus,
walau angka mentahnya sama. Karena itu `confidence` tiap match dikalikan
`quality.confidence_penalty`, dan angka aslinya disimpan di `confidence_raw`
supaya penaltinya terlihat, bukan tersembunyi.

`GET /api/cari-objek/targets` mengembalikan daftar barang yang dikenali:

```json
{"total": 312, "targets": ["botol", "buku", "dompet", "..."]}
```

### `GET /health`

```json
{
  "status": "ok",
  "service": "Vinara Vision API",
  "version": "3.0.0",
  "uptime_seconds": 128.4,
  "database": true,
  "find_object": true,
  "describe": false,
  "server_time_ms": 0.21
}
```

`describe: false` **hanya normal di detik-detik awal**, selama pemanasan latar
belakang belum selesai (sekitar 20 detik sesudah startup). Kalau ia masih
`false` beberapa menit setelah server menyala, pemanasannya gagal dan
alasannya ada di log.

Aplikasi memakai `server_time_ms` untuk membacakan waktu tempuh di layar
Pengaturan.

> `/health` mengembalikan `"version": "3.0.0"`, sementara `FastAPI(version=...)`
> di `main.py` masih `"2.0.0"`, jadi `/docs` menampilkan angka yang berbeda.
> Keduanya di kode, bukan di dokumen ini.

### `GET /api/capabilities`

Ditanyakan **sebelum** pengguna menekan tombol, bukan sesudah gagal. Tanpa ini,
satu-satunya cara mengetahui sebuah mode sedang mati adalah masuk ke sana lalu
gagal, dan untuk pengguna yang tidak melihat layar itu berarti beberapa detik
kebingungan di tempat yang salah.

```json
{
  "server_time": "2026-08-23T07:39:41+00:00",
  "database": true,
  "capabilities": {
    "detection":   {"state": "up", "on_device": true,  "note": "..."},
    "money":       {"state": "up", "on_device": true,  "note": "..."},
    "read_text":   {"state": "up", "on_device": true,  "note": "..."},
    "navigation":  {"state": "up", "on_device": true,  "note": "..."},
    "assistant":   {"state": "limited", "on_device": false, "note": "..."},
    "find_object": {"state": "up", "on_device": false, "note": "..."}
  }
}
```

Empat mode on-device **selalu** `up`. Melaporkannya `down` saat server
bermasalah akan mengunci pengguna dari mode yang sebenarnya sehat.

---

## 4. Basis data

PostgreSQL bersifat **opsional** dan hanya dua kelompok tabel yang masih punya
pemakai:

| Tabel | Isi |
|---|---|
| `risk_zones` | Lokasi yang sering dilaporkan ada hambatan |
| `capability_overrides` | Paksa status fitur, untuk demo atau perawatan |

Tabel lain di `db/schema.sql` (`telemetry_events`, `crash_reports`,
`upload_queue`, `object_labels`, `model_manifest`, `assistant_sessions`,
`voice_intents`) **tidak lagi punya endpoint aktif**. Method kliennya sempat
ada di `ServerService`, lengkap dengan penanganan error, tapi tidak satu pun
pernah dipanggil, jadi tabel-tabel itu tidak pernah menerima satu baris pun
dari aplikasi. Skemanya dipertahankan kalau suatu saat telemetri benar-benar
dipasang; endpoint-nya diarsipkan ke `_archive/routers/support_full.py`.

Tanpa autentikasi. Identifikasi cukup memakai `device_id` anonim yang dibuat
aplikasi sendiri.

---

## 5. Prinsip yang dipegang server ini

**Server tidak menyaring deteksi.** Seluruh penyaringan ada di Flutter supaya
tidak ada penyaringan ganda.

**Tidak ada jalan buntu.** Setiap kegagalan membawa pesan Bahasa Indonesia yang
menyebutkan satu tindakan berikutnya, bukan sekadar melaporkan bahwa ia gagal.
"Terlalu gelap, cari tempat yang lebih terang" memberi pengguna sesuatu untuk
dikerjakan; "maaf, tidak bisa mendeskripsikan" hanya memberi tahu bahwa dia
gagal, tanpa jalan keluar.

**Tidak ada kegagalan yang menjatuhkan server.** Model gagal dimuat, basis data
mati: semuanya dilaporkan lewat `/api/capabilities`, dan server tetap melayani
sisanya.

**Menolak lebih baik daripada mengarang.** Lihat catatan gerbang kualitas di
bagian 2.

**Tidak ada LLM.** Semua teks natural, narasi deteksi maupun resolusi intent,
dikerjakan di sisi Flutter, offline, tanpa latensi jaringan.

---

## 6. Struktur folder

```
backend/
├── main.py                  Titik masuk, 3 router + /health
├── requirements.txt         Dependensi (lihat catatan di dalamnya)
├── .env / .env.example      Konfigurasi
├── export_tflite.py         Skrip sekali pakai, bukan bagian server
├── db/
│   ├── database.py          Koneksi PostgreSQL, aman kalau DB mati
│   ├── schema.sql           Definisi tabel
│   └── seed.py              Data rujukan
├── routers/
│   ├── cari_objek.py        POST /api/cari-objek, GET /api/cari-objek/targets
│   ├── describe.py          POST /api/describe (Moondream2, output EN)
│   └── support.py           GET /api/capabilities
├── services/
│   ├── find_object_service.py   YOLOE prompt teks
│   ├── moondream_service.py     Deskripsi suasana (VLM), warm_up + ensure_ready
│   ├── image_gate.py            Gerbang gambar: batas sumber daya, catatan kualitas
│   ├── find_object_constants.py Kamus nama barang ID ke EN
│   └── repository.py            Akses basis data
├── utils/
│   └── image_utils.py       Konversi, penilaian kualitas, koreksi eksposur
├── tests/                   pytest, lihat bagian 9
└── _archive/
    ├── routers/             Router lama, fiturnya sudah pindah on-device
    ├── services/            Service pendampingnya (OCR, uang, YOLO, segmentasi)
    └── utils/               Pipeline OCR lama
```

> Tidak ada berkas LLM di folder ini. `narasi.py` dan `qwen_service.py` telah
> dihapus.

---

## 7. Keterbatasan yang perlu diketahui

1. **Moondream2 diunduh saat startup pertama** (~1,85 GB), lewat pemanasan
   latar belakang. Startup pertama di mesin baru bisa memakan beberapa menit
   sebelum `describe` siap; sesudahnya dari cache dan hanya ~20 detik.
   Server tetap melayani `/health`, `/api/capabilities`, dan `/api/cari-objek`
   selama itu.

2. **Moondream2 menjawab dalam Bahasa Inggris**, dan itu disengaja. Tidak ada
   LLM penerjemah di backend. Penerjemahan dikerjakan lokal di Flutter.

3. **Model uang di server memang tidak ada, dan itu disengaja.** Jalur satu
   satunya ada di Flutter.

4. **Berkas model besar tidak ikut ke git** (`yoloe-11s-seg.pt`, `yolo11n.pt`,
   dan berkas `.pt`/`.onnx` lainnya). Ultralytics mengunduhnya otomatis saat
   pertama dipakai.

5. **Cari Objek adalah satu-satunya mode yang benar-benar mati saat server
   tidak terjangkau.** Aplikasi menandainya `disabled` di lembar Pilih Mode dan
   menyimpan target yang sudah disebutkan, supaya pencariannya bisa dilanjutkan
   begitu koneksi kembali.

---

## 8. Uji cepat

```bash
B=http://localhost:8000

curl -s $B/health | python3 -m json.tool
curl -s $B/api/capabilities | python3 -m json.tool
curl -s $B/api/cari-objek/targets | python3 -m json.tool | head -20

# Cari barang (panggilan pertama memuat model, ~2 detik)
curl -s -X POST $B/api/cari-objek -F "target=dompet" -F "file=@foto.jpg"

# Deskripsi suasana. PERHATIKAN: field-nya "image", bukan "file"
curl -s -X POST $B/api/describe -F "image=@foto.jpg" -F "length=short"
```

### Uji negatif: endpoint yang HARUS 404

Ini memastikan tidak ada jalur server ganda yang tertinggal untuk fitur yang
sudah pindah on-device:

```bash
for p in /api/ocr /api/uang /api/navigasi /api/detect /api/narasi \
         /api/intent /api/intent/catalog /api/labels; do
  echo -n "$p -> "; curl -s -o /dev/null -w "%{http_code}\n" $B$p
done
```

Semuanya harus **404** (atau 405). Kalau ada yang 200, berarti ada berkas lama
yang tertinggal.

---

## 9. Testing backend (pytest)

Memakai `pytest` dan `httpx` lewat `TestClient` FastAPI, jadi server tidak
perlu menyala.

```bash
cd backend
source venv/bin/activate
pip install pytest pytest-asyncio

python -m pytest tests/ -v
```

### Struktur test

```
backend/tests/
├── conftest.py              Fixture bersama (TestClient, gambar navigasi, gambar objek)
├── test_health.py           GET /health + GET /api/capabilities
├── test_cari_objek.py       POST /api/cari-objek + GET /targets
├── test_describe.py         POST /api/describe (Moondream2 VLM)
├── test_hardening.py        Input rusak, ukuran ekstrem, field salah
├── test_api_endpoints.py    Sapuan endpoint lewat HTTP, butuh server menyala
└── run_yoloe_results2.py    Skrip eksplorasi YOLOE, bukan test pytest
```

**Gambar fixture-nya tidak ada di folder ini.** `conftest.py` mencari
`backend/tests/fixtures/` lebih dulu, dan karena folder itu tidak ada ia jatuh
ke `../guidio_app/test/fixtures/`:

```
guidio_app/test/fixtures/
├── navigation/    5 gambar hazard (got, lubang, tiang, motor+orang, tangga)
└── object_find/   5 gambar benda (tas, kunci, botol, headphone, payung)
```

Satu sumber gambar untuk dua sisi, jadi backend dan mobile tidak pernah menguji
dua himpunan yang diam-diam menyimpang. Versi lama `conftest.py` naik dua
tingkat dan menunjuk direktori yang tidak ada, sehingga **seluruh** tes berbasis
gambar tersembunyi di balik skip: hijau, tapi tidak menguji apa pun.

### Catatan: simulasi kamera HP

Semua gambar fixture dikirim sebagai `multipart/form-data`, **byte-for-byte
identik** dengan yang dikirim Flutter saat pengguna mengarahkan kamera. Backend
tidak membedakan sumber gambar.

```
Flutter (kamera) ──┐
                   ├──▶ POST /api/cari-objek  (multipart/form-data)
tests/fixtures  ───┘         ↑ identik
```

### Peringatan: skip bukan lulus

Beberapa test sengaja di-skip, dan itu wajar selama alasannya diketahui. Tapi
jangan pernah membaca "N skipped" sebagai kabar baik secara otomatis.

Pelajaran ini datang dari sisi mobile, bukan dari sini. Di `guidio_app`,
seluruh uji inferensi model uang dan navigasi berstatus skip sejak awal karena
pustaka native TFLite tidak ada di host. Terminal menulis "All tests passed!"
sementara nol piksel diuji, dan sebuah mode yang salah baca nominal lolos ke
tangan pengguna. Begitu pustakanya dipasang, sepuluh test langsung merah.

Aturan yang dipakai sekarang di kedua sisi: **skip harus punya alasan yang
disebutkan dan disengaja.** Kalau sebuah dependensi seharusnya ada di
lingkungan itu, ketiadaannya adalah kegagalan, bukan skip. Lihat
`guidio_app/README.md` bagian 14 untuk penerapannya.

Untuk backend, dependensi yang sah untuk di-skip cuma satu: model Moondream
yang belum selesai dipanaskan. Sejak pemanasan dipindah ke startup, jendela itu
jauh lebih sempit, tapi `TestClient` menyalakan aplikasi sendiri, jadi
`test_describe.py` tetap bisa mulai sebelum bobotnya siap.

```bash
# Cukup satu terminal, TestClient tidak butuh server terpisah
python -m pytest tests/ -v

# Kalau test_describe di-skip karena model belum siap, hangatkan dulu:
uvicorn main:app --host 0.0.0.0 --port 8000   # tunggu log "[Moondream2] Model siap"
python -m pytest tests/test_describe.py -v
```

`tests/test_api_endpoints.py` adalah pengecualian: ia memukul server lewat HTTP
sungguhan, jadi ia butuh `uvicorn` yang sudah menyala di terminal lain.

---

## 10. Koneksi HP ke backend laptop

### Cara paling mudah: WiFi satu jaringan

```bash
# Laptop
uvicorn main:app --host 0.0.0.0 --port 8000
ip addr show   # cari wlan0, contoh: 192.168.1.5
```

Di HP: buka Guidio, tekan **Pilih Mode**, pilih **Pengaturan**, isi
`192.168.1.5:8000`, tekan **Uji Sambungan**, lalu **Simpan**. Bisa juga lewat
suara: ucapkan **"pengaturan"**.

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
| `/api/describe` balas 422 | Field dikirim sebagai `file` | Harus `image`, lihat bagian 3 |

---

## 11. Ukuran model dan kebutuhan storage

Backend hanya memuat dua model. Sisanya ada di ponsel.

| Komponen | Ukuran | Eksekusi | Keterangan |
|---|---|---|---|
| `vikhyatk/moondream2` | ~1,85 GB | Laptop GPU | Deskripsi suasana (FP16), unduh saat panggilan pertama |
| `yoloe-11s-seg.pt` | ~30 MB | Laptop GPU | Cari Objek, open-vocabulary |
| PyTorch + CUDA | ~1,8 GB | Disk | Runtime |
| Ultralytics, Transformers, OpenCV, FastAPI | ~300 MB | Disk | Framework |

### Ringkasan

- **Download model:** `~1,9 GB`
- **Virtualenv Python:** `~2,1 GB`
- **Total:** `~4,0 GB`

> Angka virtualenv ini **turun** setelah `llama-cpp-python` dibuang dari
> `requirements.txt`. Paket itu tidak pernah diimpor satu berkas pun, tapi ia
> dikompilasi dari sumber sehingga memperlambat instalasi berjam-jam dan sering
> menggagalkannya sama sekali di mesin tanpa toolchain CUDA.

### Alokasi VRAM (RTX 3050 4 GB)

```
Moondream2 FP16  ~1,2 GB
YOLOE            ~0,5 GB
─────────────────────────
Total            ~1,7 GB  (dari 4 GB, aman)
```

Tidak ada LLM. Tidak ada `llama-cpp-python`. VRAM yang tersisa (~2,3 GB) bebas
untuk kebutuhan lain.
