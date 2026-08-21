# Vinara (Guidio)

Asisten visual berbasis suara untuk pengguna tunanetra dan low vision.
Kamera membaca dunia, aplikasi menjelaskannya lewat suara Bahasa Indonesia
dan getar.

> *"Asisten navigasi yang bicara kepada penggunanya, bukan sebaliknya."*

Nama produk di desain adalah **Vinara**; nama paket teknis masih `guidio_app`.
Keduanya merujuk sistem yang sama.

---

## Penjelasan singkat untuk pembaca umum

Bayangkan seseorang yang tidak bisa melihat sedang berjalan di trotoar.
Aplikasi ini dipasang di ponselnya. Ponsel dipegang menghadap ke depan,
layarnya tidak perlu dilihat sama sekali.

Yang terjadi kemudian:

- Kamera menangkap gambar sekitar, beberapa kali setiap detik.
- Program di dalam ponsel mengenali benda pada gambar itu: orang, motor,
  kursi, tiang, dan sebagainya.
- Program memperkirakan jarak dan arah benda tersebut.
- Ponsel berbicara: *"Orang! Di depan, kurang dari satu meter"*, sambil
  bergetar dengan pola tertentu.

Selain memperingatkan rintangan, aplikasi bisa membacakan tulisan (menu
warung, label obat), menyebutkan nominal uang kertas, menuntun arah jalur
trotoar, menjawab pertanyaan tentang sekitar, dan mencarikan barang yang
disebut lewat suara.

Bagian terpenting: **peringatan rintangan dan pengenalan uang bekerja tanpa
internet sama sekali.** Keduanya diproses langsung di dalam ponsel, karena
kedua hal itu menyangkut keselamatan dan uang, dan tidak boleh mati hanya
gara-gara sinyal hilang.

### Istilah yang sering muncul di dokumen ini

| Istilah | Artinya |
|---|---|
| **On-device** | Diproses langsung di dalam ponsel, tanpa mengirim apa pun ke internet |
| **Server** / **backend** | Komputer terpisah yang menangani tugas berat, dihubungi lewat jaringan |
| **Model AI** | Berkas hasil pelatihan komputer yang bisa mengenali sesuatu |
| **TFLite** | Format model AI berukuran kecil yang dirancang agar bisa jalan di ponsel |
| **OCR** | Teknologi membaca tulisan dari foto |
| **VLM** | AI bahasa + visi, bisa memahami gambar (Moondream2 di GUIDIO) |
| **TTS** | Text to Speech, mesin yang mengubah tulisan menjadi suara |
| **STT** | Speech to Text, mesin yang mengubah suara menjadi tulisan |
| **Endpoint** | Alamat di server yang dipanggil aplikasi untuk meminta sesuatu |

---

## Daftar isi

1. [Asumsi yang membentuk seluruh desain](#1-asumsi-yang-membentuk-seluruh-desain)
2. [Enam mode](#2-enam-mode)
3. [Apa yang jalan di perangkat, apa yang butuh server](#3-apa-yang-jalan-di-perangkat-apa-yang-butuh-server)
4. [Arsitektur sistem](#4-arsitektur-sistem)
5. [Teknik: dari kotak deteksi menjadi kalimat](#5-teknik-dari-kotak-deteksi-menjadi-kalimat)
6. [Stack teknologi](#6-stack-teknologi)
7. [Struktur repositori](#7-struktur-repositori)
8. [Menjalankan](#8-menjalankan)
9. [Koneksi HP fisik ke backend laptop](#9-koneksi-hp-fisik-ke-backend-laptop)
10. [Ukuran Model dan Kebutuhan Storage](#10-ukuran-model-dan-kebutuhan-storage)
11. [Status pengerjaan yang jujur](#11-status-pengerjaan-yang-jujur)
12. [Landasan akademis](#12-landasan-akademis)

---

## 1. Asumsi yang membentuk seluruh desain

Semua keputusan antarmuka berangkat dari empat kondisi fisik pengguna:

- Satu tangan memegang tongkat, jadi operasi harus muat satu ibu jari.
- Pengguna sering berjalan saat memakai aplikasi.
- Layar sering tidak dilihat sama sekali.
- Jari tidak menyapu layar saat berjalan.

Konsekuensinya mengikat, dan tidak boleh dilanggar:

| Aturan | Alasannya |
|---|---|
| Tidak ada layar beranda | Aplikasi buka langsung ke Mode Deteksi Objek yang sudah aktif |
| Enam mode sejajar, maksimal dua langkah antar mode | Menelusuri hirarki mahal secara kognitif |
| Tiga tombol bawah tidak pernah pindah posisi, jumlah, atau urutan | Kekekalan posisi adalah satu-satunya peta yang dimiliki pengguna |
| Suara jalur utama, menu cadangan | Perintah suara melompat langsung ke tujuan |
| Tidak ada jalan buntu | Tiap error menawarkan satu tindakan berikutnya |
| Warna tidak pernah satu-satunya pembawa makna | Selalu warna, ditambah bentuk ikon, ditambah teks |

Gestur yang dilarang total: geser untuk menghapus, geser untuk aksi
tersembunyi, seret dan lepas, tekan lama sebagai satu-satunya jalan, serta
gestur dua atau tiga jari.

---

## 2. Enam mode

| Mode | Fungsi | Butuh server? |
|---|---|---|
| **Deteksi Objek** (bawaan) | Peringatan rintangan otomatis, terus menerus | Tidak, sepenuhnya on-device |
| **Kenali Uang** | Sebut nominal uang kertas rupiah | Tidak, sepenuhnya on-device |
| **Baca Teks** | OCR menu, rambu, label obat | Ya, untuk teks panjang |
| **Navigasi** | Arahan jalur trotoar 3 zona | Sebagian, rintangan tetap on-device |
| **Asisten Suara** | Tanya bebas tentang sekitar | Ya, ada cadangan lokal |
| **Cari Objek** | Temukan barang yang disebut lewat suara | Ya |

Aplikasi membuka langsung ke Mode Deteksi Objek dalam keadaan sudah aktif.
Tidak ada layar beranda karena setiap layar perantara berarti satu langkah
tambahan sebelum pengguna mendapat informasi keselamatan.

---

## 3. Apa yang jalan di perangkat, apa yang butuh server

Ini pembagian yang paling penting dipahami sebelum membaca kode mana pun.

**Berjalan sepenuhnya di perangkat, tidak pernah memanggil server:**

- **Deteksi rintangan.** Peringatan keselamatan tidak boleh bergantung pada
  sinyal. Model SSD MobileNet (4 MB, TFLite) berjalan lokal.
- **Pengenalan uang.** Transaksi tunai justru sering terjadi di tempat
  bersinyal buruk seperti pasar dan warung.
- **Perintah suara (intent parsing).** `CommandParser` di Flutter mencocokkan
  20 intent baku dari ratusan variasi ucapan secara offline (0 ms).
- **Narasi deteksi.** `generateNaturalNarration()` menyusun kalimat dari hasil
  deteksi YOLO secara lokal - tanpa LLM, tanpa jaringan.

**Butuh server:**

- OCR teks panjang, pencarian objek dengan prompt teks bebas, deskripsi
  suasana via kamera (Moondream2 VLM), dan segmentasi jalur.

Ketika server mati, aplikasi tidak berhenti: ia menyebut fitur mana yang
hilang dan meneruskan yang masih hidup.

---

## 4. Arsitektur sistem

```
┌──────────────────────────────────────────────────────────────────────┐
│  PERANGKAT (Flutter + Provider)                                      │
│                                                                      │
│  Kamera ──▶ SSD MobileNet TFLite ──▶ DetectionFilter ──▶ TTS+Getar  │
│             (300x300, ~4 MB, ~30ms)   (stabilitas, cooldown, tier)   │
│                                                                      │
│  Kamera ──▶ MobileNetV2 TFLite ────▶ NominalCard ──▶ TTS            │
│             (224x224, uang rupiah)    (ambang keyakinan 0.85)        │
│                                                                      │
│  Suara ──▶ CommandParser (offline) ──▶ 20 intent baku                │
│            (fuzzy multi-lapis, ~0ms)   generateNaturalNarration()    │
│                                                                      │
│  TtsQueue bertingkat: Critical memotong semua, Warning memotong      │
│  Info, Info dibuang bila menunggu lebih dari 2 detik                 │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │ WiFi / USB (ADB reverse)
┌────────────────────────────────▼─────────────────────────────────────┐
│  SERVER (FastAPI - berjalan di laptop)                               │
│                                                                      │
│  /ws/detect       ──▶ YOLO           ──▶ deteksi mentah              │
│  /api/ocr         ──▶ Tesseract      ──▶ teks + estimasi durasi baca │
│  /api/navigasi    ──▶ PIDNet / CV    ──▶ 3 zona jalur                │
│  /api/cari-objek  ──▶ YOLOE          ──▶ objek dari prompt teks      │
│  /api/describe    ──▶ Moondream2     ──▶ caption Bahasa Inggris      │
│  /api/intent      ──▶ katalog frasa  ──▶ resolusi perintah ambigu    │
│                                                                      │
│  TIDAK ADA LLM di backend - semua narasi & intent diselesaikan lokal │
│                                                                      │
│  PostgreSQL: telemetri, crash report, antrean offline, kamus label,  │
│              manifest model, sesi percakapan, zona rawan             │
└──────────────────────────────────────────────────────────────────────┘
```

### Keputusan arsitektur kunci

**1. Filter deteksi hanya ada di Flutter.**
Satu `DetectionFilter` melayani kedua sumber (TFLite dan server). Kalau
filter dipasang di server, hasil TFLite tidak akan tersaring.

**2. Narasi tanpa LLM.**
Hasil deteksi YOLO diolah oleh `generateNaturalNarration()` di Flutter -
fungsi lokal berbasis template + kamus 80 objek COCO. Kalimat yang dihasilkan
terasa natural tanpa bergantung pada model bahasa mana pun.

**3. VLM (Moondream2) untuk deskripsi suasana.**
Saat pengguna bertanya "apa yang ada di depanku", Moondream2 menganalisis
gambar kamera dan menghasilkan caption Bahasa Inggris. Flutter membacakannya
langsung dengan `speakEnglish()` - tidak ada terjemahan tambahan.

**4. Intent parsing berlapis tiga di Flutter.**
CommandParser mencoba: (0) prefiks transisi mode natural → (1) exact phrase
dictionary → (1b) kombinasi keyword → (2) dynamic find-object prefix.
Tidak ada panggilan ke server untuk intent yang sudah dikenali.

**5. Antrean suara bertingkat.**
Critical memotong apa pun dan tidak bisa dipotong pengguna. Warning memotong
Info. Info mengantre dan dibuang kalau sudah menunggu lebih dari 2 detik.

**6. Nominal uang tidak pernah ditebak.**
Di bawah ambang keyakinan, yang muncul hanya instruksi perbaikan, bukan
angka.

---

## 5. Teknik: dari kotak deteksi menjadi kalimat

Model deteksi hanya menghasilkan angka: koordinat kotak dan skor kelas.
Perubahan menjadi kalimat seperti *"Di sekitarmu, ada dua orang di sebelah
kirimu sejauh satu setengah meter, serta sebuah mobil di sebelah kananmu"*
dikerjakan sepenuhnya di Flutter:

```dart
// lib/core/voice/narration_engine.dart
generateNaturalNarration([
  NarrationDetection(objectClass: 'person', dist: 1.5, dir: 'kiri', count: 2),
  NarrationDetection(objectClass: 'car',    dist: 3.0, dir: 'kanan'),
]);
```

**Kamus `cocoObjectDictionary`** memetakan 80 kelas COCO ke nama Indonesia
dan kata kerja konteks ("berjalan", "terparkir", "diletakkan", dst).

**`mapDistancePhrase`** mengubah jarak numerik ke frasa natural ("sangat
dekat di depanmu", "sekitar satu setengah meter", "agak jauh sekitar tiga
meter").

Hasilnya divariasikan lewat pool konektor acak agar tidak monoton setiap
didengar ulang.

### Naskah darurat

Peringatan Critical menaruh **kata pembeda di depan**: *"Orang! Di depan,
kurang dari satu meter"*, bukan *"Awas! Ada orang di depan"*. Dua peringatan
Critical tidak boleh hanya berbeda satu kata di tengah kalimat, karena
pengguna mengenali bahaya dari kata pertama yang terdengar.

---

## 6. Stack teknologi

| Lapisan | Teknologi |
|---|---|
| Aplikasi mobile | Flutter (Dart), Provider, Android |
| Deteksi on-device | SSD MobileNet, TFLite, 300x300, sekitar 30 ms |
| Pengenalan uang on-device | MobileNetV2 transfer learning, TFLite, 224x224, 6 kelas |
| Pelacakan objek | SORT, ditulis murni dengan Dart |
| Intent parsing | CommandParser lokal, fuzzy multi-lapis, 0 ms offline |
| Narasi deteksi | `narration_engine.dart` lokal, kamus 80 objek COCO |
| Deteksi server | YOLO11 via Ultralytics |
| Pencarian objek | YOLOE open-vocabulary (prompt teks) |
| Segmentasi jalur | PIDNet-S ONNX, dengan cadangan heuristik OpenCV |
| OCR | Tesseract, bahasa `ind` dan `eng` |
| Deskripsi suasana | Moondream2 (~2B, VLM, GPU lokal, output English) |
| Ucapan | `speech_to_text` dan `flutter_tts`, default `id-ID`, deskripsi `en-US` |
| Getar | paket `vibration`, pola berbeda per tier |
| Backend | FastAPI, Python |
| Basis data | PostgreSQL, tanpa autentikasi |

> **Tidak ada LLM** di stack ini. Qwen dan semua endpoint narasi/intent LLM
> telah dihapus dari backend.

---

## 7. Struktur repositori

```
project/
├── README.md                      (berkas ini)
├── guidio_app/                    Aplikasi Flutter
│   ├── README.md                  Panduan mobile, token desain, komponen
│   ├── FEATURE_VERIFICATION.md    Daftar uji manual per mode
│   ├── lib/
│   │   ├── core/
│   │   │   ├── voice/             CommandParser, narration_engine, intents
│   │   │   ├── speech/            Antrean suara bertingkat
│   │   │   ├── layout/            Token zona layar
│   │   │   └── state/             Penggabungan kondisi global
│   │   ├── theme/                 Warna, tipografi, spasi, tema
│   │   ├── widgets/               16 komponen sistem desain
│   │   ├── providers/             State per mode dan kondisi global
│   │   ├── services/              TFLite deteksi, TFLite uang, server, TTS
│   │   ├── screens/               6 mode, splash, panduan, izin, pengaturan
│   │   └── mock/                  Data tiruan untuk menguji state tanpa model
│   ├── test/                      Uji Flutter, lihat guidio_app/README.md bagian 14
│   ├── tool/                      setup_tflite_linux.sh (runtime TFLite untuk host)
│   ├── blobs/                     Pustaka native TFLite, tidak ikut ke APK
│   └── assets/models/             ssd_mobilenet.tflite, rupiah_classifier_fp16.tflite
└── backend/                       Server FastAPI
    ├── README.md                  Panduan backend dan rujukan endpoint
    ├── db/                        Skema PostgreSQL dan data rujukan
    ├── routers/                   Endpoint per fitur
    └── services/                  YOLO, YOLOE, Moondream2, OCR, intent
```

---

## 8. Menjalankan

### Prasyarat

- Flutter SDK 3.x, Dart 3.x
- Python 3.10 atau lebih baru
- PostgreSQL yang sedang berjalan
- Perangkat Android sungguhan, bukan emulator, agar TFLite optimal
- Tesseract untuk OCR:

```bash
sudo dnf install -y tesseract tesseract-langpack-ind tesseract-langpack-eng
```

### Backend

```bash
cd backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt

createdb -h localhost -U postgres vinara_dev

cp .env.example .env      # isi kredensial PostgreSQL
venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Skema basis data dibuat otomatis saat startup. Dokumentasi endpoint
interaktif tersedia di `http://localhost:8000/docs`.

### Aplikasi mobile

```bash
cd guidio_app
flutter pub get
flutter run
```

Aplikasi tetap berjalan tanpa backend. Deteksi rintangan, pengenalan uang,
intent parsing, dan narasi deteksi berfungsi penuh karena semuanya on-device;
mode lain menyebut keterbatasannya sendiri.

---

## 9. Koneksi HP fisik ke backend laptop

### Cara 1 - WiFi (paling mudah)

```
Laptop (backend)  ←──WiFi──→  HP (APK Guidio)
```

**Di laptop:**

```bash
cd backend && source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000

ip addr show   # cari bagian wlan0, contoh: 192.168.1.5
```

**Di HP:**

1. Buka Guidio, ucapkan **"pengaturan"**
2. Di kolom **Alamat Server**, isi: `192.168.1.5:8000`
3. Tekan **Uji Sambungan** - waktu tempuh akan muncul kalau berhasil
4. Tekan **Simpan**

### Cara 2 - USB tanpa WiFi (ADB reverse)

```bash
adb reverse tcp:8000 tcp:8000
```

Isi alamat server di Guidio: `localhost:8000`

### Build APK

```bash
flutter build apk --release
flutter install
```

### Troubleshooting koneksi

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| "Tidak bisa menjangkau server" | IP salah atau backend belum `--host 0.0.0.0` | Cek `ip addr show`, restart backend |
| Koneksi timeout | Firewall laptop memblokir port 8000 | `sudo firewall-cmd --add-port=8000/tcp --permanent` |
| HP dan laptop beda subnet | Isolasi client di jaringan kampus | Pakai metode USB (ADB reverse) |
| IP laptop berubah tiap kali | DHCP memberi IP baru | Set IP statis di laptop, atau pakai ADB reverse |

---

## 10. Ukuran Model dan Kebutuhan Storage

| Kategori | Komponen / Model | Ukuran | Eksekusi | Keterangan |
|---|---|---|---|---|
| **Mobile** | `ssd_mobilenet.tflite` | ~4.18 MB | On-Device CPU | Deteksi rintangan real-time |
| **Mobile** | `rupiah_classifier_fp16.tflite` | ~4.6 MB | On-Device CPU | Klasifikasi uang 7 pecahan |
| **Backend VLM** | `vikhyatk/moondream2` | ~1.85 GB | Laptop GPU | Deskripsi suasana kamera (FP16) |
| **Backend Deteksi** | `yolo11n.pt` | ~5.5 MB | Laptop GPU | Deteksi server / fallback |
| **Backend Cari Objek** | `yoloe-11s-seg.pt` | ~30 MB | Laptop GPU | Open-vocabulary text prompt |
| **Dependensi Python** | PyTorch + CUDA | ~1.8 GB | Disk | Runtime CUDA |
| **Dependensi Python** | Transformers, OpenCV, FastAPI | ~300 MB | Disk | Framework |

### Ringkasan

- **Model di HP (Flutter Asset):** `~8.8 MB` (turun dari ~29 MB sejak
  `uang_rupiah.tflite` 24,92 MB diganti `rupiah_classifier_fp16.tflite` 4,6 MB)
- **Download Model Backend:** `~1.9 GB` *(Moondream ~1.85 GB + YOLO ~50 MB)*
- **Storage Virtualenv Python:** `~2.1 GB`
- **Total yang perlu disiapkan:** `~4.0 GB`

### Alokasi Hardware (RTX 3050 4 GB VRAM)

```
Moondream2 FP16  ~1.2 GB
YOLO/YOLOE       ~0.5 GB
─────────────────────────
Total            ~1.7 GB  (dari 4 GB - aman, sisa ~2.3 GB)
```

Tidak ada LLM yang perlu dimuat di GPU atau CPU. Seluruh narasi dan intent
dikerjakan di Flutter.

---

## 11. Status pengerjaan yang jujur

**Sudah berfungsi penuh:**

- Enam mode dengan seluruh state antarmuka.
- Deteksi rintangan on-device beserta pelacak SORT, penyaring kestabilan,
  getar tiga tingkat, dan antrean suara bertingkat.
- Pengenalan uang on-device, 7 pecahan emisi 2016 dan 2022, dengan pengaman
  yang terbukti bekerja: di bawah keyakinan 0,85 aplikasi tidak menyebutkan
  nominal sama sekali.
- OCR beserta estimasi durasi baca.
- Pencarian objek dengan prompt teks bebas.
- Deskripsi suasana via kamera (Moondream2, output English dibacakan TTS).
- Intent parsing lokal: 20 intent, ratusan variasi ucapan multi-bahasa/dialek.
- Narasi deteksi lokal: kamus 80 objek COCO, jarak natural, arah kontekstual.

**Masih tiruan atau terbatas:**

- **Segmentasi jalur** memakai heuristik OpenCV karena model PIDNet-S belum
  ada.
- **Mode Kenali Uang sering tidak memberi jawaban.** Model mengenali 7 pecahan
  dan skor lab-nya 97,98%, tapi angka itu diukur pada crop rapat hasil bounding
  box, bukan pada frame kamera. Diukur lewat jalur aplikasi yang sebenarnya
  (`flutter test test/money_pipeline_test.dart`), dari 5 gambar uji hanya 1
  yang tembus ambang 0,85. Pada empat sisanya aplikasi bilang "belum yakin".
  Yang salah adalah cara model dilatih, bukan bobotnya: dataset training tidak
  pernah memuat uang yang kecil di dalam bidang. Perbaikan sedang berjalan di
  `new_training/rupiah_vision_revised`. Rinciannya di `guidio_app/README.md`
  bagian 3.
- **Navigasi belum memakai GPS.**
- **Empat dari lima uji deteksi bahaya navigasi gagal.** Model YOLO tidak
  mendeteksi satu pun label yang diharapkan pada fixture `got_terbuka`,
  `tiang_listrik`, `motor_dan_orang`, dan `tangga_turun`. Kegagalan ini baru
  terlihat setelah runtime TFLite dipasang di host; sebelumnya uji-uji itu
  selalu di-skip dan suite tampak hijau.
- **Tema gelap dan kontras tinggi** sudah aktif di tingkat aplikasi, tetapi
  belum dirancang ulang per komponen.

---

## 12. Landasan akademis

| Sumber | Kontribusi |
|---|---|
| Wang dkk., *YOLO-OD*, Sensors 2024 | Dataset rintangan navigasi, deteksi objek kecil |
| Lu dkk., *Neural Baby Talk*, CVPR 2018 | Fondasi mengubah keluaran detektor menjadi kalimat tanpa mengirim gambar |
| Hingnekar dkk., *Netra AI*, TechRxiv 2025 | Arsitektur on-device, sistem audio tiga tingkat |
| Alsulaimawi, *Feedback-Enhanced VLM*, arXiv 2025 | Validasi urutan deteksi dulu, VLM kemudian |

---

*Tim Guidio, PENS 2026*
