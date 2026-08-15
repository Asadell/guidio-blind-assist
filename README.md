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
gara gara sinyal hilang.

### Istilah yang sering muncul di dokumen ini

| Istilah | Artinya |
|---|---|
| **On-device** | Diproses langsung di dalam ponsel, tanpa mengirim apa pun ke internet |
| **Server** / **backend** | Komputer terpisah yang menangani tugas berat, dihubungi lewat jaringan |
| **Model AI** | Berkas hasil pelatihan komputer yang bisa mengenali sesuatu |
| **TFLite** | Format model AI berukuran kecil yang dirancang agar bisa jalan di ponsel |
| **OCR** | Teknologi membaca tulisan dari foto |
| **LLM** | AI bahasa yang bertugas menyusun kalimat, berjalan lokal di laptop server |
| **VLM** | AI bahasa + visi, bisa memahami gambar (Moondream2 di GUIDIO) |
| **TTS** | Text to Speech, mesin yang mengubah tulisan menjadi suara |
| **STT** | Speech to Text, mesin yang mengubah suara menjadi tulisan |
| **Endpoint** | Alamat di server yang dipanggil aplikasi untuk meminta sesuatu |
| **GGUF** | Format model LLM yang dioptimalkan untuk inferensi lokal via llama-cpp |

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
10. [Status pengerjaan yang jujur](#10-status-pengerjaan-yang-jujur)
11. [Landasan akademis](#11-landasan-akademis)

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
  bersinyal buruk seperti pasar dan warung. Selain itu foto uang tidak perlu
  meninggalkan perangkat, dan pengguna butuh umpan balik seketika.

**Butuh server:**

- OCR teks panjang, segmentasi jalur, asisten suara berbasis LLM, pencarian
  objek dengan prompt teks bebas, dan deskripsi suasana via kamera.

Ketika server mati, aplikasi tidak berhenti: ia menyebut fitur mana yang
hilang dan meneruskan yang masih hidup. Mode Navigasi khususnya **tidak
pernah dinonaktifkan saat offline**, karena deteksi rintangannya on-device
dan mematikannya akan mencabut fungsi keselamatan yang sebenarnya masih ada.

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
│  TtsQueue bertingkat: Critical memotong semua, Warning memotong      │
│  Info, Info dibuang bila menunggu lebih dari 2 detik                 │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │ WiFi / USB (ADB reverse)
┌────────────────────────────────▼─────────────────────────────────────┐
│  SERVER (FastAPI — berjalan di laptop)                               │
│                                                                      │
│  /ws/detect       ──▶ YOLO           ──▶ deteksi mentah              │
│  /api/ocr         ──▶ Tesseract      ──▶ teks + estimasi durasi baca │
│  /api/navigasi    ──▶ PIDNet / CV    ──▶ 3 zona jalur                │
│  /api/cari-objek  ──▶ YOLOE          ──▶ objek dari prompt teks      │
│  /api/describe    ──▶ Moondream2     ──▶ caption ──▶ Qwen (EN→ID)    │
│  /api/intent      ──▶ katalog + Qwen ──▶ resolusi perintah suara     │
│  /api/narasi      ──▶ Qwen lokal     ──▶ kalimat natural             │
│                                                                      │
│  PostgreSQL: telemetri, crash report, antrean offline, kamus label,  │
│              manifest model, sesi percakapan, zona rawan             │
└──────────────────────────────────────────────────────────────────────┘
```

### Keputusan arsitektur kunci

**1. Filter deteksi hanya ada di Flutter.**
Satu `DetectionFilter` melayani kedua sumber (TFLite dan server). Kalau
filter dipasang di server, hasil TFLite tidak akan tersaring. Kalau dipasang
di keduanya, terjadi penyaringan ganda yang membuang deteksi valid.

**2. LLM menerima teks, bukan gambar.**
Model deteksi bekerja lebih dulu, hasilnya dikirim sebagai teks terstruktur
ke LLM. Ini mencegah halusinasi visual, jauh lebih murah, dan lebih cepat.
LLM yang dipakai adalah **Qwen2.5-1.5B-Instruct** yang berjalan lokal di
GPU laptop, tanpa API eksternal.

**3. VLM (Moondream2) untuk deskripsi suasana.**
Saat pengguna bertanya "apa yang ada di depanku", Moondream2 menganalisis
gambar kamera dan menghasilkan caption Bahasa Inggris. Qwen kemudian
menerjemahkannya ke Bahasa Indonesia yang TTS-friendly.

**4. Antrean suara bertingkat.**
Critical memotong apa pun dan tidak bisa dipotong pengguna. Warning memotong
Info. Info mengantre dan dibuang kalau sudah menunggu lebih dari 2 detik.

**5. Nominal uang tidak pernah ditebak.**
Di bawah ambang keyakinan, yang muncul hanya instruksi perbaikan, bukan
angka. Salah menyebut nominal berarti kerugian uang nyata.

---

## 5. Teknik: dari kotak deteksi menjadi kalimat

Model deteksi hanya menghasilkan angka: koordinat kotak dan skor kelas.
Perubahan menjadi kalimat seperti *"Di depanmu ada seseorang yang cukup
dekat, jalur kiri tampak lebih aman"* memakai dua jalur berbeda.

**Jalur cepat (template lokal), untuk peringatan real-time.**
Tidak butuh internet, tidak ada latensi API. Untuk peringatan keselamatan,
kecepatan adalah segalanya.

**Jalur lambat (LLM lokal), hanya saat pengguna bertanya.**
Deteksi diformat menjadi teks terstruktur, lalu dikirim ke Qwen2.5-1.5B
yang berjalan di GPU laptop:

```
Objek terdeteksi kamera saat ini:
- orang, jarak 1.2 meter, posisi depan, bahaya: critical
- motor, jarak 2.8 meter, posisi kanan, bahaya: warning
```

Qwen tidak pernah melihat gambar. Ia hanya merangkai fakta yang sudah
diverifikasi model deteksi menjadi kalimat. LLM di sini bukan untuk melihat,
melainkan untuk menyusun bahasa. Gambar hanya dilihat oleh Moondream2 saat
fitur deskripsi suasana diaktifkan.

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
| Deteksi server | YOLO11 via Ultralytics |
| Pencarian objek | YOLOE open-vocabulary (prompt teks) |
| Segmentasi jalur | PIDNet-S ONNX, dengan cadangan heuristik OpenCV |
| OCR | Tesseract, bahasa `ind` dan `eng` |
| Deskripsi suasana | Moondream2 (~2B, VLM, GPU lokal) |
| LLM narasi & terjemahan | Qwen2.5-1.5B-Instruct GGUF Q4_K_M (lokal, via llama-cpp-python) |
| Ucapan | `speech_to_text` dan `flutter_tts`, keduanya `id-ID` |
| Getar | paket `vibration`, pola berbeda per tier |
| Backend | FastAPI, Python |
| Basis data | PostgreSQL, tanpa autentikasi |

---

## 7. Struktur repositori

```
project/
├── README.md                      (berkas ini)
├── guidio_app/                    Aplikasi Flutter
│   ├── README.md                  Panduan mobile, token desain, komponen
│   ├── FEATURE_VERIFICATION.md    Daftar uji manual per mode
│   ├── lib/
│   │   ├── core/                  Token layout, antrean suara, parser perintah
│   │   ├── theme/                 Warna, tipografi, spasi, tema
│   │   ├── widgets/               16 komponen sistem desain
│   │   ├── providers/             State per mode dan kondisi global
│   │   ├── services/              TFLite deteksi, TFLite uang, server, TTS
│   │   ├── screens/               6 mode, splash, panduan, izin, pengaturan
│   │   └── mock/                  Data tiruan untuk menguji state tanpa model
│   └── assets/models/             ssd_mobilenet.tflite, uang_rupiah.tflite
└── backend/                       Server FastAPI
    ├── README.md                  Panduan backend dan rujukan endpoint
    ├── models/                    File GGUF Qwen (download manual, tidak di git)
    ├── db/                        Skema PostgreSQL dan data rujukan
    ├── routers/                   Endpoint per fitur
    └── services/                  YOLO, YOLOE, Moondream2, Qwen, OCR, intent
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

Skema basis data dibuat otomatis saat startup, lalu data rujukan diisi:
52 label objek, 20 intent suara, 7 denominasi, dan manifest model.
Dokumentasi endpoint interaktif tersedia di `http://localhost:8000/docs`.

### Aplikasi mobile

```bash
cd guidio_app
flutter pub get
flutter run
```

Aplikasi tetap berjalan tanpa backend. Deteksi rintangan dan pengenalan uang
berfungsi penuh karena keduanya on-device; mode lain menyebut keterbatasannya
sendiri.

---

## 9. Koneksi HP fisik ke backend laptop

Skenario: APK sudah di-build dan diinstall di HP fisik, backend berjalan
di laptop yang tersambung ke HP lewat WiFi atau kabel USB.

### Cara 1 — WiFi (paling mudah)

```
Laptop (backend)  ←──WiFi──→  HP (APK Guidio)
```

**Di laptop:**

```bash
# Pastikan backend dijalankan dengan --host 0.0.0.0 agar bisa diakses HP
cd backend && source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000

# Cari IP laptop di jaringan WiFi yang sama
ip addr show   # cari bagian wlan0, contoh: 192.168.1.5
```

**Di HP:**

1. Buka Guidio, ucapkan **"pengaturan"**
   atau tekan **Pilih Mode → Pengaturan**
2. Di kolom **Alamat Server**, isi: `192.168.1.5:8000`
3. Tekan **Uji Sambungan** — waktu tempuh akan muncul kalau berhasil
4. Tekan **Simpan**

> Nilai bawaan `10.0.2.2:8000` hanya untuk emulator Android di laptop
> dan tidak berlaku untuk HP fisik.

### Cara 2 — USB tanpa WiFi (ADB reverse)

Jika jaringan kampus memblokir koneksi antar-device, atau HP dan laptop
berada di jaringan berbeda:

```bash
# Aktifkan USB Debugging di HP, sambungkan via kabel USB, lalu:
adb reverse tcp:8000 tcp:8000
```

Setelah perintah itu, HP bisa mengakses backend laptop seolah-olah ada di
dalam HP sendiri. Isi alamat server di Guidio: `localhost:8000`

### Build APK

```bash
# Di folder guidio_app:
flutter build apk --release

# File APK ada di:
# build/app/outputs/flutter-apk/app-release.apk

# Install langsung ke HP via USB:
flutter install
# atau manual:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Troubleshooting koneksi

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| "Tidak bisa menjangkau server" | IP salah atau backend belum `--host 0.0.0.0` | Cek `ip addr show`, restart backend |
| Koneksi timeout | Firewall laptop memblokir port 8000 | `sudo firewall-cmd --add-port=8000/tcp --permanent` |
| HP dan laptop beda subnet | Isolasi client di jaringan kampus | Pakai metode USB (ADB reverse) |
| IP laptop berubah tiap kali | DHCP memberi IP baru | Set IP statis di laptop, atau pakai ADB reverse |

---

## 10. Status pengerjaan yang jujur

**Sudah berfungsi penuh:**

- Enam mode dengan seluruh state antarmuka yang dirancang, dapat diperiksa
  satu per satu lewat panel debug (ketuk 5 kali pada badge mode).
- Deteksi rintangan on-device beserta pelacak SORT, penyaring kestabilan,
  getar tiga tingkat, dan antrean suara bertingkat.
- Pengenalan uang on-device, 6 denominasi emisi 2016.
- OCR beserta estimasi durasi baca.
- Pencarian objek dengan prompt teks bebas.
- Deskripsi suasana via kamera (Moondream2 + Qwen terjemahan).
- Seluruh endpoint penunjang: kemampuan server, kamus label, manifest model,
  telemetri, laporan crash, dan antrean unggah offline yang idempoten.

**Masih tiruan atau terbatas:**

- **Segmentasi jalur** memakai heuristik OpenCV karena model PIDNet-S belum
  ada. Heuristik membaca gambar sungguhan dan cukup untuk menguji seluruh
  state, tetapi akurasinya di bawah model terlatih.
- **Model uang hanya mengenali 6 pecahan emisi 2016.** Rp1.000 tidak
  didukung, dan aplikasi menyebut keterbatasan itu alih-alih menebak.
- **Navigasi belum memakai GPS.** Arahan jalur berasal dari kamera.
- **Tema gelap dan kontras tinggi** sudah aktif di tingkat aplikasi, tetapi
  belum dirancang ulang per komponen.
- **Model Qwen perlu didownload manual** (~1 GB). Tanpa model, narasi dan
  terjemahan memakai template fallback.

---

## 11. Landasan akademis

| Sumber | Kontribusi |
|---|---|
| Wang dkk., *YOLO-OD*, Sensors 2024 | Dataset rintangan navigasi, deteksi objek kecil |
| Lu dkk., *Neural Baby Talk*, CVPR 2018 | Fondasi mengubah keluaran detektor menjadi kalimat tanpa mengirim gambar |
| Hingnekar dkk., *Netra AI*, TechRxiv 2025 | Arsitektur on-device, sistem audio tiga tingkat |
| Alsulaimawi, *Feedback-Enhanced VLM*, arXiv 2025 | Validasi urutan deteksi dulu, LLM kemudian |

---

*Tim Guidio, PENS 2026*
