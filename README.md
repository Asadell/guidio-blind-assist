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

Bagian terpenting: **empat dari enam mode bekerja tanpa internet sama
sekali.** Deteksi rintangan, pengenalan uang, baca teks, dan navigasi jalur
semuanya diproses di dalam ponsel, karena hal-hal itu menyangkut keselamatan
dan uang, dan tidak boleh mati hanya gara-gara sinyal hilang.

### Istilah yang sering muncul di dokumen ini

| Istilah | Artinya |
|---|---|
| **On-device** | Diproses langsung di dalam ponsel, tanpa mengirim apa pun ke internet |
| **Server** / **backend** | Komputer terpisah yang menangani tugas berat, dihubungi lewat jaringan |
| **Model AI** | Berkas hasil pelatihan komputer yang bisa mengenali sesuatu |
| **TFLite** | Format model AI berukuran kecil yang dirancang agar bisa jalan di ponsel |
| **OCR** | Teknologi membaca tulisan dari foto |
| **VLM** | AI bahasa dan visi, bisa memahami gambar (Moondream2 di Vinara) |
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
10. [Ukuran model dan kebutuhan storage](#10-ukuran-model-dan-kebutuhan-storage)
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
| Tidak ada layar beranda | Aplikasi buka langsung ke Mode Deteksi Objek |
| Enam mode sejajar, maksimal dua langkah antar mode | Menelusuri hirarki mahal secara kognitif |
| Tiga tombol bawah tidak pernah pindah posisi, jumlah, atau urutan | Kekekalan posisi adalah satu-satunya peta yang dimiliki pengguna |
| Suara jalur utama, menu cadangan | Perintah suara melompat langsung ke tujuan |
| Tidak ada jalan buntu | Tiap error menawarkan satu tindakan berikutnya |
| Tidak ada tombol yang diam saat ditekan | Tombol nonaktif tetap menyebutkan alasannya |
| Warna tidak pernah satu-satunya pembawa makna | Selalu warna, ditambah bentuk ikon, ditambah teks |
| Tidak pernah mengonfirmasi sesuatu yang tidak terjadi | Suara menyusul perubahan state, tidak mendahuluinya |

Gestur yang dilarang total: geser untuk menghapus, geser untuk aksi
tersembunyi, seret dan lepas, tekan lama sebagai satu-satunya jalan, serta
gestur dua atau tiga jari.

### Satu aturan yang sering disalahpahami: deteksi mulai dalam keadaan MATI

Aplikasi terbuka ke Mode Deteksi Objek, tetapi **pengawasan rintangannya
belum menyala.** Pengguna harus menekan tombol kiri bawah lebih dulu.

Ini disengaja. Saat aplikasi baru dibuka, ponsel biasanya masih di tangan yang
turun, di dalam saku, atau menghadap tanah. Peringatan pertama dari posisi itu
hampir selalu keliru, dan peringatan keliru dari alat bantu jalan lebih merusak
daripada diam: begitu pengguna belajar bahwa aplikasinya sering salah,
peringatan yang benar ikut diabaikan.

Konsekuensinya ditangani, bukan diabaikan. Keadaan mati **diucapkan** saat
masuk mode ("Deteksi rintangan belum menyala. Tekan tombol kiri bawah untuk
mulai mengawasi.") dan diingatkan ulang setiap 30 detik disertai getar. Tidak
boleh ada orang yang berjalan menyangka dirinya sedang dijaga.

---

## 2. Enam mode

| Mode | Fungsi | Butuh server? |
|---|---|---|
| **Deteksi Objek** (bawaan) | Peringatan rintangan, dinyalakan lewat tombol kiri | Tidak, sepenuhnya on-device |
| **Kenali Uang** | Sebut nominal uang kertas rupiah | Tidak, sepenuhnya on-device |
| **Baca Teks** | OCR menu, rambu, label obat | Tidak, ML Kit on-device |
| **Navigasi** | Arahan jalur trotoar 3 zona | Tidak, tiga model on-device |
| **Asisten Suara** | Perintah suara dan tanya sekitar | Sebagian, hanya deskripsi suasana |
| **Cari Objek** | Temukan barang yang disebut lewat suara | Ya, satu-satunya mode yang mati offline |

Berpindah mode ada dua jalan: mengucapkan namanya lewat tombol Bicara (satu
langkah), atau lewat tombol Pilih Mode di kanan bawah (dua langkah).

---

## 3. Apa yang jalan di perangkat, apa yang butuh server

Ini pembagian yang paling penting dipahami sebelum membaca kode mana pun.

**Berjalan sepenuhnya di perangkat, tidak pernah memanggil server:**

- **Deteksi rintangan.** Peringatan keselamatan tidak boleh bergantung pada
  sinyal. Model SSD MobileNet (4 MB, TFLite) berjalan lokal.
- **Pengenalan uang.** Transaksi tunai justru sering terjadi di tempat
  bersinyal buruk seperti pasar dan warung.
- **Baca teks.** Google ML Kit Text Recognition berjalan di ponsel. Label obat
  dan struk belanja tidak boleh menunggu sinyal.
- **Navigasi jalur.** Tiga model TFLite berjalan paralel dari satu frame yang
  sama: PIDNet-S (segmentasi 3 zona), YOLO11n custom (enam kelas bahaya
  jalanan), dan SSD MobileNet COCO yang disaring ke 15 kelas yang bisa
  menghalangi langkah. Lihat bagian 5 soal kenapa tiga, bukan dua.
- **Perintah suara (intent parsing).** `CommandParser` di Flutter mencocokkan
  20 intent baku dari ratusan variasi ucapan secara offline, 0 ms.
- **Narasi deteksi.** `NarrationScheduler` menyusun kalimat dari hasil deteksi
  secara lokal, tanpa LLM dan tanpa jaringan.

**Butuh server, hanya dua:**

- **Cari Objek** (YOLOE open-vocabulary). Modelnya tidak muat di ponsel.
- **Deskripsi suasana** (Moondream2 VLM), dipanggil dari Mode Asisten Suara.

Prinsipnya satu: kalau fiturnya sudah ada di ponsel, backend tidak menyediakannya
lagi. Jalur ganda hanya menambah kode yang harus dijaga konsisten, dan
menciptakan ketergantungan diam-diam pada laptop yang menyala di mode yang
justru menyangkut keselamatan.

Ketika server mati, aplikasi tidak berhenti: ia menyebut fitur mana yang
hilang dan meneruskan yang masih hidup.

---

## 4. Arsitektur sistem

```
┌──────────────────────────────────────────────────────────────────────┐
│  PERANGKAT (Flutter + Provider)                                      │
│                                                                      │
│  Kamera ──▶ SSD MobileNet TFLite ──▶ ObjectTracker (SORT)            │
│             (300x300, ~4 MB)         DetectionFilter                 │
│                                      NarrationScheduler ──▶ TTS+Getar│
│                                                                      │
│  Kamera ──▶ MobileNetV2 TFLite ────▶ NominalCard ──▶ TTS             │
│             (224x224, uang rupiah)   (ambang keyakinan 0,85)         │
│                                                                      │
│  Kamera ──▶ PIDNet-S ──────────────▶ ZoneIndicator ──▶ TTS+Getar     │
│         ├─▶ YOLO11n custom (6 kelas) ┐                               │
│         └─▶ SSD MobileNet COCO       ├▶ mergeNavObstacles            │
│             (disaring ke 15 kelas)   ┘  (anti sebutan ganda)         │
│                                                                      │
│  Kamera ──▶ ML Kit Text Recognition ──▶ blok teks ──▶ TTS            │
│                                                                      │
│  Suara ──▶ CommandParser (offline) ──▶ 20 intent baku, ~0 ms         │
│                                                                      │
│  TtsQueue bertingkat: Critical memotong semua, Warning memotong      │
│  Info, Info dibuang bila menunggu lebih dari 2 detik                 │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │ WiFi / USB (ADB reverse)
                                 │ hanya untuk DUA fitur di bawah
┌────────────────────────────────▼─────────────────────────────────────┐
│  SERVER (FastAPI, berjalan di laptop)                                │
│                                                                      │
│  GET  /health                ──▶ cek hidup + waktu tempuh            │
│  GET  /api/capabilities      ──▶ fitur mana yang siap                │
│  POST /api/cari-objek        ──▶ YOLOE, objek dari prompt teks       │
│  GET  /api/cari-objek/targets──▶ daftar barang yang dikenali         │
│  POST /api/describe          ──▶ Moondream2, caption Bahasa Inggris  │
│                                                                      │
│  Lima endpoint. Itu saja. Tidak ada LLM, tidak ada WebSocket,        │
│  tidak ada OCR, tidak ada deteksi, tidak ada segmentasi jalur.       │
│                                                                      │
│  PostgreSQL: zona rawan + override kemampuan (demo/perawatan).       │
│  Server tetap hidup kalau PostgreSQL mati.                           │
└──────────────────────────────────────────────────────────────────────┘
```

### Keputusan arsitektur kunci

**1. Filter deteksi hanya ada di Flutter.**
`DetectionFilter` menyaring berdasarkan jarak, keyakinan, kestabilan antar
frame, dan cooldown per objek. Kuncinya adalah identitas objek dari SORT
tracker, bukan nama kelasnya. Bedanya nyata: dengan kunci kelas, dua orang di
frame yang sama dianggap satu, sehingga orang yang jauh diumumkan lebih dulu
lalu orang yang dekat ikut kena cooldown dan tidak diumumkan sama sekali.

**2. Narasi tanpa LLM.**
`NarrationScheduler` memutuskan kapan bicara dan berapa banyak yang muat dalam
satu ucapan. Ia punya anggaran kata yang menjaga satu ucapan tetap sekitar
empat detik, karena narasi realtime datang tanpa diminta dan telinga butuh
waktu memisahkan satu kalimat dari kalimat berikutnya.

**3. VLM (Moondream2) untuk deskripsi suasana.**
Saat pengguna bertanya "apa yang ada di depanku", Moondream2 menghasilkan
caption Bahasa Inggris. Flutter menerjemahkannya **secara lokal** lewat
`scene_translator.dart`: kamus ditambah aturan urutan kata, 0 ms, offline,
tanpa LLM. Kalau cakupan kamusnya terlalu rendah, penerjemah menyerah dan
kalimat Inggrisnya dibacakan, didahului penanda singkat "Dalam bahasa Inggris."
supaya pengguna tahu bahasanya berganti dan tidak menyangka aplikasinya rusak.

**4. Intent parsing berlapis di Flutter.**
`CommandParser` mencoba berurutan: prefiks transisi mode natural, frasa
multi-kata terpanjang lebih dulu, pola cari-objek dinamis, kata tunggal, lalu
kombinasi keyword longgar. Urutannya menentukan: "stop navigasi" harus
menghentikan panduan, bukan keluar dari mode hanya karena mengandung kata
"stop".

**5. Antrean suara bertingkat.**
Critical memotong Info dan tidak bisa dipotong pengguna, tapi **tidak memotong
Critical lain yang belum selesai**. Peringatan yang diulang dari awal
terus-menerus tidak pernah selesai diucapkan sekali pun, dan peringatan yang
tidak pernah utuh bukan peringatan.

**6. Nominal uang tidak pernah ditebak.**
Di bawah ambang keyakinan 0,85, yang muncul hanya instruksi perbaikan, bukan
angka.

**7. Sistem tidak pernah mengaku melihat saat sedang tidak melihat.**
Di Mode Navigasi, klaim positif "jalur aman, jalan lurus" ditahan kalau frame
tidak layak jadi dasar arahan. PIDNet tidak pernah berkata "saya tidak bisa
melihat"; ia memberi label ke setiap piksel apa pun yang masuk, dan sebagian
besar permukaan polos jatuh ke kelas walkable. Tanpa penjaga ini, kamera yang
menghadap langit-langit kamar tetap menghasilkan "jalur aman".

---

## 5. Teknik: dari kotak deteksi menjadi kalimat

Model deteksi hanya menghasilkan angka: koordinat kotak dan skor kelas.
Perubahannya menjadi kalimat dikerjakan sepenuhnya di Flutter, dalam tiga
lapis yang tugasnya sengaja dipisah:

| Lapis | Berkas | Memutuskan |
|---|---|---|
| `ObjectTracker` | `services/object_tracker.dart` | Objek mana ini, dan apakah ia mendekat |
| `DetectionFilter` | `services/detection_filter.dart` | **Apa** yang layak diucapkan |
| `NarrationScheduler` | `core/voice/narration_scheduler.dart` | **Kapan** dan **dalam bentuk apa** |

Pemisahan itu bukan kerapian belaka. Filter bekerja baik di kondisi mapan,
tapi tidak menangani momen mode baru menyala: saat itu setiap objek adalah
objek baru, tidak satu pun punya catatan cooldown, jadi semuanya lolos
sekaligus. Enam objek berarti enam narasi dalam waktu kurang dari satu detik,
dan narasi yang kalah rebutan hilang tanpa jejak tanpa pengguna pernah tahu.

### Jarak yang diucapkan adalah jarak yang dihaluskan

Ponsel yang mengayun saat berjalan membuat kotak deteksi membesar dan mengecil
sendiri, sehingga objek yang diam terbaca "maju mundur". Tanpa penghalusan,
objek diam terucap "dua meter, satu meter, dua meter" dan pengguna tidak punya
cara tahu mana yang benar.

`TrackedObject` memelihara dua EMA jarak dengan kecepatan berbeda. Perpotongan
keduanya menentukan arah tren, dan status "mendekat" baru menyala setelah tren
bertahan tiga frame. Saat ponsel terdeteksi banyak bergoyang, penghalusan
diperlambat dan ambangnya dinaikkan: sinyal yang berisik diperlakukan sebagai
sinyal yang berisik.

### Kenapa Mode Navigasi memakai tiga model, bukan dua

`YoloNavigasiService` dilatih khusus untuk enam kelas bahaya jalanan Indonesia.
Itu satu-satunya sumber untuk `lubang`, `got_terbuka`, dan `tangga`: tidak ada
padanannya di COCO, dan justru ketiganya yang paling berbahaya karena tidak
terasa tongkat sampai sudah dekat.

Tapi model itu lemah persis pada kelas yang berlimpah di dataset umum. Diuji
lewat `test/run_corridor_test.py` pada fixture `04_motor_dan_orang.png`, dua
motor terparkir dan satu orang berjalan, semuanya jelas terlihat mata: model
custom melaporkan nol motor dan nol orang.

SSD MobileNet COCO tidak akan pernah tahu apa itu got terbuka, tapi `person`
dan `motorcycle` adalah dua kelas dengan contoh terbanyak di seluruh COCO.
Masing-masing menutup lubang yang tidak bisa ditutup yang lain.

Hanya 15 dari 80 kelas COCO yang lolos saringan, dan hanya benda yang bisa
menghalangi atau membahayakan langkah. Menyebut "botol" atau "ponsel" saat
pengguna menyeberang bukan cuma tidak berguna: ia menunda kalimat yang
menyangkut keselamatan. Penggabungannya di `nav_obstacle_merger.dart`, lengkap
dengan aturan anti sebutan ganda.

### Kamera ponsel yang sudah berumur

Kamera lama kehilangan kontras karena veiling glare: cahaya menyebar di dalam
lensa yang tergores dan berdebu, lalu mengangkat titik hitam. Diukur pada foto
Samsung A30s berusia lima tahun di repo ini:

| | titik hitam (p2) | rentang dinamis |
|---|---|---|
| Kamera sehat | 9 | 220 |
| A30s | 50 | 145-171 |

Tidak ada piksel yang benar-benar hitam. Seluruh histogram terdorong ke tengah,
dan tepi objek yang dipakai detektor jadi tipis.

`luma_contrast.dart` mengembalikan titik hitam ke nol, tapi **hanya pada frame
yang terukur berkabut**. Gerbangnya bukan kerapian: enhancement yang dipasang
tanpa syarat justru menurunkan akurasi pada citra yang sudah jernih, karena
model menerima distorsi alih-alih perbaikan. Diverifikasi di repo ini juga:
pada lima foto kamera sehat, gerbang melewatkan kelimanya dan skor deteksi
tidak berubah sama sekali.

Peregangan linier dipilih ketimbang CLAHE karena CLAHE butuh histogram per ubin
dan buffer tambahan tiap frame, dan biaya itu mendarat persis di ponsel lama
yang jadi sasarannya.

### Ponsel lama yang tidak mengejar

Tiga model per frame di ponsel lima tahun bisa berkali lipat lebih lambat. Yang
berbahaya bukan lambatnya, melainkan diamnya: arahan tetap diucapkan dengan
nada yakin dari pemandangan beberapa detik lalu, sementara pengguna sudah
melangkah melewatinya.

`device_pace_watch.dart` mengukur durasi siklus, lalu bertindak berurutan dari
yang paling tidak mengganggu:

1. **Ukur.** Rata-rata bergerak, bukan nilai terakhir. Satu frame yang kebetulan
   lambat bukan alasan menurunkan kualitas panduan.
2. **Kurangi beban sendiri.** Di atas 1200 ms, lapis COCO dimatikan diam-diam.
   Yang dikorbankan COCO, bukan PIDNet atau YOLO: hanya COCO yang menambah
   cakupan tanpa menopang mode ini.
3. **Katakan apa adanya.** Di atas 2500 ms meski sudah dikurangi, pengguna
   diberi tahu bahwa arahan bisa datang terlambat. Sekali saja per sesi.

Efek sampingnya menutup kebutuhan sensor termal: saat ponsel panas dan
prosesornya diturunkan, durasi siklus naik dan mekanisme yang sama bekerja.

### Naskah darurat

Peringatan Critical menaruh **kata pembeda di depan**: *"Orang! Di depan,
kurang dari satu meter"*, bukan *"Awas! Ada orang di depan"*. Dua peringatan
Critical tidak boleh hanya berbeda satu kata di tengah kalimat, karena
pengguna mengenali bahaya dari kata pertama yang terdengar.

### Catatan: `narration_engine.dart` ada, tapi tidak dipanggil

Berkas itu masih di repo dan gaya naratifnya enak didengar ("Di sekitarmu, ada
dua orang di sebelah kirimu sejauh sekitar tiga meter, serta ..."). Ia tidak
dipakai jalur deteksi realtime karena satu klausanya saja sudah menghabiskan
hampir seluruh anggaran kata `NarrationScheduler`. Gaya itu cocok untuk narasi
**yang diminta** pengguna, saat ia sudah siap mendengarkan; bukan untuk aliran
deteksi yang datang tanpa diminta delapan kali per detik.

---

## 6. Stack teknologi

| Lapisan | Teknologi |
|---|---|
| Aplikasi mobile | Flutter (Dart), Provider, Android |
| Deteksi on-device | SSD MobileNet, TFLite, 300x300 |
| Pengenalan uang on-device | MobileNetV2 transfer learning, TFLite, 224x224, 7 kelas |
| Segmentasi jalur on-device | PIDNet-S, TFLite, 3 zona |
| Rintangan navigasi on-device | YOLO11n custom, TFLite, 6 kelas |
| Lapis ketiga navigasi | SSD MobileNet COCO, disaring ke 15 kelas |
| Perbaikan kontras kamera lama | Peregangan titik hitam, selektif per frame |
| Baca teks on-device | Google ML Kit Text Recognition |
| Pelacakan objek | SORT, ditulis murni dengan Dart |
| Intent parsing | `CommandParser` lokal, berlapis, 0 ms offline |
| Penjadwalan narasi | `NarrationScheduler` lokal, beranggaran kata |
| Terjemahan caption | `scene_translator.dart` lokal, kamus + aturan urutan kata |
| Pencarian objek (server) | YOLOE open-vocabulary, prompt teks |
| Deskripsi suasana (server) | Moondream2 (~2B, VLM, GPU lokal, output English) |
| Ucapan | `speech_to_text` dan `flutter_tts`, default `id-ID` |
| Getar | paket `vibration`, pola berbeda per tier |
| Backend | FastAPI, Python |
| Basis data | PostgreSQL, tanpa autentikasi, opsional |

> **Tidak ada LLM** di stack ini. Qwen, `llama-cpp-python`, dan semua endpoint
> narasi maupun intent berbasis LLM telah dihapus.

---

## 7. Struktur repositori

```
project/
├── README.md                      (berkas ini)
├── VERIFIKASI_FITUR.md            Panduan uji manual per mode, langkah demi langkah
├── guidio_app/                    Aplikasi Flutter
│   ├── README.md                  Panduan mobile, model, sistem desain, testing
│   ├── lib/
│   │   ├── core/
│   │   │   ├── voice/             CommandParser, NarrationScheduler, scene_translator
│   │   │   ├── speech/            TtsQueue bertingkat
│   │   │   ├── layout/            Token zona layar
│   │   │   ├── net/               ApiClient, FramePacer
│   │   │   └── state/             Penggabungan kondisi global
│   │   ├── theme/                 Warna, tipografi, spasi, tema
│   │   ├── widgets/               Komponen sistem desain
│   │   ├── providers/             State per mode dan kondisi global
│   │   ├── services/              TFLite deteksi/uang/PIDNet/YOLO, ML Kit, TTS
│   │   ├── screens/               6 mode, splash, panduan, izin, pengaturan
│   │   └── mock/                  Data tiruan untuk menguji state tanpa model
│   ├── test/                      Uji Flutter, lihat guidio_app/README.md bagian 14
│   ├── tool/                      setup_tflite_linux.sh (runtime TFLite untuk host)
│   ├── blobs/                     Pustaka native TFLite, tidak ikut ke APK
│   └── assets/models/             4 model yang benar-benar dibundel, lihat bagian 10
└── backend/                       Server FastAPI
    ├── README.md                  Panduan backend dan rujukan endpoint
    ├── db/                        Skema PostgreSQL dan data rujukan
    ├── routers/                   3 router aktif
    ├── services/                  YOLOE, Moondream2, gerbang kualitas gambar
    ├── tests/                     pytest
    └── _archive/                  Router lama yang fiturnya sudah pindah on-device
```

---

## 8. Menjalankan

### Prasyarat

- Flutter SDK 3.x, Dart 3.x
- Python 3.10 atau lebih baru
- Perangkat Android sungguhan, bukan emulator, agar TFLite optimal
- PostgreSQL (opsional, backend tetap jalan tanpanya)

> Tesseract **tidak lagi dibutuhkan**. Baca Teks memakai ML Kit di ponsel.

### Aplikasi mobile

```bash
cd guidio_app
flutter pub get
flutter run
```

Empat dari enam mode berfungsi penuh tanpa backend sama sekali. Uji dengan WiFi
dan data seluler dimatikan total untuk membuktikannya.

### Backend (hanya untuk Cari Objek dan Deskripsi Suasana)

```bash
cd backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt

cp .env.example .env      # isi kredensial PostgreSQL bila dipakai
venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Dokumentasi endpoint interaktif tersedia di `http://localhost:8000/docs`.

### Menguji fiturnya

Panduan uji manual langkah demi langkah, lengkap dengan apa yang harus
diucapkan dan apa yang seharusnya terdengar, ada di
[`VERIFIKASI_FITUR.md`](VERIFIKASI_FITUR.md).

---

## 9. Koneksi HP fisik ke backend laptop

### Cara 1: WiFi (paling mudah)

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

1. Buka Guidio, tekan tombol Pilih Mode (kanan bawah), pilih **Pengaturan**
2. Di kolom **Alamat Server**, isi: `192.168.1.5:8000`
3. Tekan **Uji Sambungan**, waktu tempuh akan muncul kalau berhasil
4. Tekan **Simpan**

> Bisa juga lewat suara: dari Mode Asisten Suara atau dari tombol Mic mana pun,
> ucapkan **"pengaturan"**.

### Cara 2: USB tanpa WiFi (ADB reverse)

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

## 10. Ukuran model dan kebutuhan storage

### Model yang benar-benar dibundel ke APK

Daftar aset di `pubspec.yaml` menyebut model **satu per satu**, bukan seluruh
direktori. Ini disengaja: `- assets/models/` akan ikut membundel semua yang
kebetulan ada di folder itu, termasuk berkas percobaan yang tidak pernah dimuat
kode. Untuk pengguna dengan kuota terbatas, itu ratusan megabyte yang dibayar
tanpa satu pun manfaat.

| Berkas | Ukuran | Dipakai oleh |
|---|---|---|
| `ssd_mobilenet.tflite` | ~4,0 MB | Deteksi rintangan |
| `labelmap.txt` | ~1 KB | Label COCO |
| `rupiah_classifier_fp16.tflite` | ~4,6 MB | Kenali Uang, 7 pecahan |
| `pidnet_s_3zona.tflite` | ~2,5 MB | Segmentasi jalur 3 zona |
| `yolo11n_navigasi.tflite` | ~10,1 MB | Rintangan navigasi, 6 kelas |
| **Total di APK** | **~21,2 MB** | |

Berkas lain di `assets/models/` (`uang_rupiah.tflite`,
`rupiah_classifier_int8.tflite`, `yolo11n.tflite`, `pidnet_s_3zona_fp16.tflite`,
`yoloe_find.onnx`, dan berkas `.onnx` lainnya) **tidak dibundel**. Semuanya
arsip atau percobaan. Menambah berkas ke folder itu tidak otomatis
membundelnya; tambahkan barisnya di `pubspec.yaml` hanya kalau kode benar-benar
memuatnya.

### Kebutuhan di sisi laptop

| Komponen | Ukuran | Keterangan |
|---|---|---|
| `vikhyatk/moondream2` | ~1,85 GB | Deskripsi suasana, diunduh saat panggilan pertama |
| `yoloe-11s-seg.pt` | ~30 MB | Cari Objek, open-vocabulary |
| PyTorch + CUDA | ~1,8 GB | Runtime |
| Ultralytics, Transformers, OpenCV, FastAPI | ~300 MB | Framework |
| **Total yang perlu disiapkan** | **~4,0 GB** | |

### Alokasi VRAM (RTX 3050 4 GB)

```
Moondream2 FP16  ~1,2 GB
YOLOE            ~0,5 GB
─────────────────────────
Total            ~1,7 GB  (dari 4 GB, sisa ~2,3 GB)
```

Tidak ada LLM yang perlu dimuat di GPU atau CPU.

---

## 11. Status pengerjaan yang jujur

### Sudah berfungsi penuh

- Enam mode dengan seluruh state antarmuka.
- Deteksi rintangan on-device beserta pelacak SORT, penyaring kestabilan,
  getar tiga tingkat, dan antrean suara bertingkat.
- Baca teks on-device (ML Kit), berjalan penuh tanpa internet.
- Navigasi jalur on-device (PIDNet-S 3 zona), termasuk penolakan jujur saat
  frame tidak layak jadi dasar arahan.
- Pencarian objek dengan prompt teks bebas.
- Deskripsi suasana via kamera, diterjemahkan lokal ke Bahasa Indonesia.
- Intent parsing lokal: 20 intent, ratusan variasi ucapan multi-bahasa dan
  dialek, berjalan offline.
- Pengaman uang yang terbukti bekerja: di bawah keyakinan 0,85 aplikasi tidak
  menyebutkan nominal sama sekali.

### Masih terbatas, dan ini yang paling penting diketahui

**Model uang sering tidak memberi jawaban.** Skor lab-nya 97,98%, tapi angka
itu diukur pada crop rapat hasil bounding box, bukan pada frame kamera. Diukur
lewat jalur aplikasi yang sebenarnya (`flutter test test/money_pipeline_test.dart`),
dari 5 gambar uji hanya **1 yang tembus ambang 0,85**, dan tebakan teratasnya
benar hanya 3 dari 5. Pada sisanya aplikasi bilang "belum yakin". Yang salah
adalah cara model dilatih, bukan bobotnya: dataset training tidak pernah memuat
uang yang kecil di dalam bidang. Rinciannya di `guidio_app/README.md` bagian 3.

**Empat dari enam kelas YOLO navigasi tidak pernah menyala.** Ini temuan
terpenting yang masih terbuka, dan ia bukan soal data maupun kamera.

Diukur langsung pada keluaran mentah model di 11 gambar, `yolo11n_navigasi.tflite`
mengembalikan skor puncak seperti ini:

```
lubang 0,528   got_terbuka 0,0001   tangga 0,816
orang  0,0001  motor       0,0001   tiang  0,0001
```

Model yang lemah tetap mengeluarkan probabilitas kecil yang bervariasi. Angka
0,0001 yang identik di setiap anchor, setiap gambar, berarti kanalnya memang
tidak pernah menyala.

Datasetnya justru berlimpah untuk kelas-kelas itu: `tiang` punya **4205 contoh
latih**, terbanyak dari semua kelas, dan model tidak pernah bisa memunculkannya.
Jadi ini cacat training atau ekspor, bukan kekurangan data.

Model lama `yolo11n.tflite` justru sehat, keenam kelasnya hidup, dan ia benar
mendeteksi `tiang` pada fixture yang gagal total di model baru. Ia NCHW
sehingga ditolak `YoloNavigasiService` yang menyusun NHWC. **Periksa ulang
proses ekspor sebelum melakukan retrain apa pun.**

Konsekuensi yang perlu diketahui: sampai ini beres, lapis SSD COCO adalah
satu-satunya sumber deteksi orang dan motor di Mode Navigasi, dan PIDNet-S
adalah lapis pengaman yang sesungguhnya, bukan YOLO. Perbaikan kontras kamera
lama juga belum bisa dinilai adil, karena model yang rusak memberi respons
erratic. Ukur ulang dengan `test/run_corridor_test.py --enhance off` setelah
ekspornya diperbaiki.

**Navigasi belum memakai GPS.** Kolom tujuan menyimpan apa yang diketik, tapi
tidak ada penuntun rute. Kalimat pembuka mode sengaja tidak menjanjikannya.

**Tema gelap dan kontras tinggi** aktif di tingkat aplikasi, tetapi belum
dirancang ulang per komponen.

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
