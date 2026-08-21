# Vinara Mobile (guidio_app)

Aplikasi Flutter untuk Android. Inilah bagian yang dipegang pengguna, dan
bagian yang paling menentukan apakah sistem ini benar-benar bisa dipakai
orang yang tidak melihat layar.

Empat hal ini berjalan penuh di dalam ponsel **tanpa internet sama sekali**:

| Fitur | File |
|---|---|
| Peringatan rintangan | `services/tflite_service.dart` |
| Pengenalan uang | `services/money_tflite_service.dart` |
| Intent parsing (20 mode + aksi) | `core/voice/command_parser.dart` |
| Narasi deteksi (kamus 80 objek COCO) | `core/voice/narration_engine.dart` |

---

## Daftar isi

1. [Cara kerja singkat](#1-cara-kerja-singkat)
2. [Enam mode dan layarnya](#2-enam-mode-dan-layarnya)
3. [Dua model AI di dalam ponsel](#3-dua-model-ai-di-dalam-ponsel)
4. [Intent parsing lokal: CommandParser](#4-intent-parsing-lokal-commandparser)
5. [Narasi lokal: narration_engine](#5-narasi-lokal-narration_engine)
6. [Sistem desain: token dan komponen](#6-sistem-desain-token-dan-komponen)
7. [Aturan tata letak yang mengikat](#7-aturan-tata-letak-yang-mengikat)
8. [Antrean suara bertingkat](#8-antrean-suara-bertingkat)
9. [Panel debug untuk menguji semua state](#9-panel-debug-untuk-menguji-semua-state)
10. [Aksesibilitas](#10-aksesibilitas)
11. [Struktur folder](#11-struktur-folder)
12. [Menjalankan](#12-menjalankan)
13. [Koneksi ke Backend Laptop (HP Fisik)](#13-koneksi-ke-backend-laptop-hp-fisik)
14. [Testing](#14-testing)

---

## 1. Cara kerja singkat

```
Kamera menyala terus
        │
        ▼
Gambar diubah jadi angka yang bisa dibaca model AI
(dikerjakan di thread terpisah agar layar tidak tersendat)
        │
        ▼
Model SSD MobileNet mengenali benda dan posisinya
        │
        ▼
Perkiraan jarak, arah (kiri, depan, kanan), dan tingkat bahaya
        │
        ▼
Penyaring: buang yang terlalu jauh, buang yang cuma muncul sekilas,
jangan ulangi benda yang sama terlalu sering
        │
        ▼
generateNaturalNarration() → kalimat Bahasa Indonesia tanpa LLM
        │
        ▼
Suara + getar ke pengguna
```

### Aturan penyaring

- Benda lebih jauh dari 10 meter diabaikan.
- Benda yang cuma muncul di satu frame diabaikan (harus terlihat minimal
  dua kali berturut-turut).
- Benda yang sama tidak diumumkan ulang sebelum jeda tertentu: 2 detik untuk
  bahaya, 3 detik untuk hati-hati, 5 detik untuk informasi biasa.
- Kalau benda terdeteksi **mendekat**, jeda dipotong setengah supaya
  peringatan datang lebih cepat.
- Maksimal 2 pesan sekaligus.

---

## 2. Enam mode dan layarnya

Aplikasi terbuka langsung ke Mode Deteksi Objek yang sudah aktif. Tidak ada
layar beranda - setiap layar perantara berarti penundaan sebelum pengguna
mendapat informasi keselamatan.

| Mode | Berkas layar | Butuh internet? |
|---|---|---|
| Deteksi Objek | `screens/tuntun_screen.dart` | Tidak |
| Kenali Uang | `screens/money_screen.dart` | Tidak |
| Baca Teks | `screens/ocr_screen.dart` | Ya |
| Navigasi | `screens/navigasi_screen.dart` | Sebagian |
| Asisten Suara | `screens/voice_screen.dart` | Ya |
| Cari Objek | `screens/find_object_screen.dart` | Ya |

Berpindah mode ada dua jalan: mengucapkan namanya (satu langkah), atau lewat
tombol Pilih Mode di kanan bawah (dua langkah).

---

## 3. Dua model AI di dalam ponsel

### Model deteksi rintangan

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/ssd_mobilenet.tflite` |
| Ukuran | sekitar 4 MB |
| Ukuran masukan | 300 x 300 piksel |
| Kecepatan | sekitar 30 milidetik per gambar |
| Dijalankan di | thread terpisah, supaya layar tidak macet |

> `yolo11l_float32.tflite` dan `yolo11n.tflite` di folder yang sama **tidak
> dipakai** - hanya sisa percobaan. Yang dimuat adalah `ssd_mobilenet.tflite`.

### Model pengenalan uang

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/rupiah_classifier_fp16.tflite` |
| Arsitektur | MobileNetV2 transfer learning (repo `rupiah_vision_revised`) |
| Ukuran masukan | 224 x 224 piksel, float32 **rentang -1..1** |
| Resize | **letterbox** (`resize_with_pad`), bukan peregangan |
| Praproses aplikasi | center-crop 0,7 dari frame, lalu letterbox |
| Jumlah kelas | 7 pecahan, emisi 2016 dan 2022 |
| Test accuracy (lab) | 97,98% pada test set internal |

> `rupiah_classifier_int8.tflite` dan `uang_rupiah.tflite` di folder yang sama
> **tidak dibundel** ke APK. Keduanya arsip model lama.

#### Angka lab tidak sama dengan angka lapangan

Test accuracy 97,98% diukur pada test set yang isinya **crop rapat** hasil
bounding box: lembar uang mengisi lebih dari 80 persen bidang, rasionya sekitar
2:1 mendatar. Frame kamera sungguhan tidak pernah seperti itu.

Angka di bawah ini diukur lewat `flutter test test/money_pipeline_test.dart`,
memakai `classifyCameraImage` yang sama persis dengan yang dipakai aplikasi:

| Fixture | Nominal asli | Tebakan teratas | Keyakinan | Selisih ke juara dua |
|---|---|---|---|---|
| `money_new2/5rb.png` | 5.000 | 5.000 | 90,6% | 87,6 |
| `money_new2/10rb.png` | 10.000 | 10.000 | 82,0% | 71,0 |
| `money_new2/20rb.png` | 20.000 | 20.000 | 64,7% | 55,2 |
| `money_new/5000.png` | 5.000 | **20.000** | 42,6% | 23,1 |
| `money_new/10000.png` | 10.000 | **50.000** | 35,6% | 2,2 |

Bacanya: tebakan teratas benar 3 dari 5, tapi hanya 1 dari 5 yang tembus ambang
0,85. Artinya pada empat gambar sisanya aplikasi bilang "belum yakin" dan
**tidak menyebutkan nominal apa pun**. Pengaman bekerja, tapi modenya sering
tidak memberi jawaban.

Dua fixture `money_new/` adalah tangkapan layar ponsel 720x1560: lembar uang
cuma sekitar 13 persen bidang, lebih dari separuh tensor jadi bantalan hitam
karena rasio portretnya, dan gelembung petunjuk di layar menutupi tengah uang.
Pada `10000.png` selisih ke juara dua cuma 2,2 poin, yang berarti model memang
sedang menebak, bukan mengenali.

Penyebabnya pergeseran distribusi skala dan framing, bukan bobot yang rusak.
Perbaikannya ada di `new_training/rupiah_vision_revised` (simulasi framing
kamera lewat `--frame-prob` dan `--bg-dir`), bukan di sisi aplikasi.

Urutan kelas **wajib** persis seperti saat model dilatih (`CLASS_ORDER` di `scripts/02_export_tflite.py`):

```
1.000 = 0   2.000 = 1   5.000 = 2   10.000 = 3
20.000 = 4  50.000 = 5  100.000 = 6
```

> **Perhatian rentang input:** model ini memakai rentang -1..1 (`x/127.5 - 1`),
> **bukan** 0..255. Nilai yang salah tidak memunculkan error apa pun, prediksinya
> hanya diam-diam salah. Periksa ulang jika model diganti.

**Aturan yang tidak bisa ditawar:** kalau keyakinan model di bawah 0,85,
aplikasi **tidak menampilkan angka sama sekali**, hanya instruksi perbaikan.
Menyebut nominal yang salah kepada orang yang tidak bisa memeriksa sendiri
berarti kerugian uang nyata.

---

## 4. Intent parsing lokal: CommandParser

`lib/core/voice/command_parser.dart`

Mencocokkan ucapan pengguna ke 20 intent baku **sepenuhnya offline, 0 ms**.
Menggantikan `POST /api/intent` untuk seluruh kasus yang bisa diselesaikan
secara lokal.

### Empat lapis matching

| Lapis | Mekanisme | Contoh |
|---|---|---|
| 0 | Prefiks transisi mode natural | "Saya pengin pindah ke mode baca teks" |
| 1a | Exact phrase dictionary | "kenali uang", "baca teks" |
| 1b | Kombinasi keyword | "baca" + "mode" → `modeReadText` |
| 2 | Dynamic find-object prefix | "cariin kacamata" → `findObjectTarget("kacamata")` |

### Cakupan bank kata

Setiap intent memiliki varian ucapan yang mencakup:
- Frasa formal dan resmi
- Frasa gaul dan informal  
- Dialek daerah: Jawa, Sunda, Betawi, Minang, Batak, Makassar
- Typo dan variasi STT yang umum

Server (`POST /api/intent`) hanya dipanggil saat parser lokal benar-benar
tidak bisa menentukan - biasanya kasus ambigu yang perlu konfirmasi pengguna.

---

## 5. Narasi lokal: narration_engine

`lib/core/voice/narration_engine.dart`

Mengubah daftar objek hasil deteksi YOLO menjadi kalimat Bahasa Indonesia
yang alami. **100% offline, tanpa LLM, tanpa server.**

Menggantikan `POST /api/narasi` yang sebelumnya bergantung pada Qwen di
backend.

### API

```dart
final narasi = generateNaturalNarration([
  NarrationDetection(objectClass: 'person', dist: 1.5, dir: 'kiri', count: 2),
  NarrationDetection(objectClass: 'car',    dist: 3.0, dir: 'kanan'),
]);
// → "Di sekitarmu, ada dua orang di sebelah kirimu sejauh satu setengah
//    meter, serta sebuah mobil di sebelah kananmu sejauh agak jauh
//    sekitar tiga meter."
```

### Komponen

| Komponen | Fungsi |
|---|---|
| `cocoObjectDictionary` | Kamus 80 kelas COCO → nama Indonesia + kata kerja konteks |
| `mapDistancePhrase()` | Angka meter → frasa natural ("sangat dekat", "satu setengah meter") |
| `mapDirectionPhrase()` | "kiri"/"tengah"/"kanan" → "di sebelah kirimu"/dst |
| `generateNaturalNarration()` | Merangkai semua menjadi 1 kalimat dengan variasi konektor |

Urutan objek: yang paling dekat disebut lebih dulu - objek paling berbahaya
mendapat prioritas.

### Deskripsi suasana (Moondream2)

Untuk `POST /api/describe`, backend mengembalikan `description_en` - caption
Bahasa Inggris dari Moondream2. Flutter membacakannya dengan:

```dart
// services/tts_service.dart
await ttsService.speakEnglish(descriptionEn);
// Otomatis ganti locale ke en-US, lalu kembali ke id-ID
```

---

## 6. Sistem desain: token dan komponen

Semua warna, ukuran huruf, dan jarak diambil dari satu sumber di
`lib/theme/`. Tidak ada layar yang menulis nilai warna atau ukuran secara
langsung.

### Aturan warna

Warna terang seperti hijau dan kuning **tidak boleh** menjadi latar teks
putih - kontrasnya gagal untuk pengguna low vision. Setiap tingkat bahaya
punya dua warna: satu untuk ikon/bidang besar, satu yang lebih pekat untuk
teks.

Warna tidak pernah menjadi satu-satunya penanda. Setiap tingkat bahaya punya
**bentuk ikon berbeda**:

| Tingkat | Bentuk ikon | Kata di kartu |
|---|---|---|
| Bahaya | segi delapan | "Bahaya" |
| Hati-hati | segitiga | "Hati-hati" |
| Informasi | persegi membulat | "Info" |
| Aman | lingkaran | "Aman" |

### 16 komponen

Berada di `lib/widgets/`:

`ModeBadge`, `AlertCard`, `BottomActionBar`, `FullScreenButton`,
`ModePickerSheet`, `VoiceOrb`, `StatusBanner`, `ZoneIndicator`,
`ResultPanel`, `CameraHealthToast`, `GuideFrame`, `ChatBubble`,
`NominalCard`, `TargetChip`, `SpeakingIndicator`, `PermissionCard`.

---

## 7. Aturan tata letak yang mengikat

Layar dibagi menjadi zona dari atas ke bawah. **Tidak ada elemen yang boleh
menimpa elemen lain.**

| Zona | Tinggi | Aturan |
|---|---|---|
| Area aman atas | 32 dp | Tidak pernah diisi |
| Banner status | 0, 56, atau 64 dp | **Maksimum satu di layar** |
| Badge mode | 40 dp | Turun otomatis saat banner muncul |
| Konten dan kamera | fleksibel | Menyusut, tidak pernah mendorong zona lain |
| Tumpukan kartu | maksimal 2 kartu | Kartu ketiga menjadi baris "dan 2 objek lain" |
| Bar tombol bawah | 112 dp | **Tetap**, tidak boleh tertutup apa pun |

Tiga tombol bawah tidak pernah berubah posisi, jumlah, maupun urutannya:
Ambil gambar di kiri, Bicara di tengah, Pilih mode di kanan.

---

## 8. Antrean suara bertingkat

`lib/core/speech/tts_queue.dart`

| Tingkat | Perilaku |
|---|---|
| Critical | Memotong semua suara, tidak bisa dipotong pengguna |
| Warning | Memotong Info, boleh dipotong pengguna |
| Info | Mengantre, dibuang kalau sudah menunggu lebih dari 2 detik |

Info sengaja dibuang saat basi - informasi tentang benda yang sudah terlewat
tiga detik lalu bukan cuma tidak berguna, tapi juga menghalangi peringatan
yang lebih baru.

Getar selalu mendampingi suara. Di lingkungan bising seperti pasar atau jalan
raya, getar sering menjadi sinyal utama yang benar-benar sampai.

---

## 9. Panel debug untuk menguji semua state

Ketuk **5 kali** pada badge mode di kiri atas untuk membuka daftar state.
Memilih satu state memaksa layar ke kondisi itu.

Gunanya: kondisi "baterai 9 persen", "empat objek sekaligus", atau "server
mati" bisa dilihat langsung tanpa harus menghadirkan situasinya.

Data tiruan: `lib/mock/`.

---

## 10. Aksesibilitas

Aplikasi ini harus bisa dipakai dengan layar mati total:

- **Urutan fokus** mengikuti zona dari atas ke bawah.
- **Live region** dipakai untuk teks yang berubah sendiri.
- Hanya empat hal yang boleh memotong pembacaan: peringatan bahaya, zona
  jalur berbahaya, nominal uang, dan kegagalan izin.
- **Label menyebut aksi, bukan alat**: "Ambil gambar", bukan "Kamera".
- **Label tidak menyebut lokasi layar**: tidak ada "tombol di kanan bawah".
- Tombol nonaktif **menyebutkan alasannya**: "Baca teks, tidak tersedia, butuh
  internet".
- Elemen dekoratif disembunyikan dari pembaca layar.

### Ukuran huruf 200 persen

Berlaku ke seluruh aplikasi. Tata letak berubah dari mendatar menjadi
menurun, dan target sentuh membesar dari 48 menjadi 56 dp.

---

## 11. Struktur folder

```
lib/
├── main.dart                 Titik masuk, mendaftarkan seluruh provider
├── core/
│   ├── layout/               Ukuran zona dan aturan pergeseran
│   ├── speech/               Antrean suara bertingkat (TtsQueue)
│   ├── state/                Penggabungan kondisi global jadi satu banner
│   └── voice/
│       ├── intents.dart          Enum VoiceIntent (20 intent baku)
│       ├── command_parser.dart   Fuzzy matching offline, 4 lapis
│       ├── narration_engine.dart Narasi deteksi lokal, kamus 80 objek COCO
│       └── object_label_map.dart Kamus label objek tambahan
├── theme/                    Warna, tipografi, jarak, tema
├── widgets/                  16 komponen sistem desain
├── providers/                State per mode, pengaturan, kondisi global
├── services/
│   ├── tflite_service.dart       Deteksi rintangan on-device
│   ├── money_tflite_service.dart Pengenalan uang on-device
│   ├── server_service.dart       Semua panggilan ke backend
│   ├── tts_service.dart          Mesin suara (speakEnglish untuk deskripsi)
│   ├── detection_filter.dart     Penyaring anti banjir suara
│   ├── object_tracker.dart       Pelacak SORT
│   └── haptic_service.dart       Pola getar
├── screens/                  6 mode + splash, panduan, izin, pengaturan
└── mock/                     Data tiruan untuk panel debug
```

---

## 12. Menjalankan

```bash
flutter pub get
flutter run
```

Aplikasi tetap jalan tanpa backend. Deteksi rintangan, pengenalan uang,
intent parsing, dan narasi deteksi berfungsi penuh; mode lain akan menyebut
sendiri keterbatasannya.

Alamat server bawaan adalah `10.0.2.2:8000` (emulator Android). **Untuk HP
fisik**, ubah lewat layar Pengaturan: ucapkan "pengaturan" atau ketuk Pilih
Mode → Pengaturan.

### Delapan pengaturan yang tersimpan permanen

1. Kecepatan bicara
2. Tingkat kecerewetan (ringkas, sedang, detail)
3. Getar (aktif, hanya bahaya, mati)
4. Ambang jarak peringatan (1 sampai 5 meter)
5. Tema (terang, gelap, kontras tinggi)
6. Ukuran teks (normal sampai 200 persen)
7. Ulangi panduan awal
8. Alamat server

### Catatan pengembangan

- Penyaring deteksi **hanya** boleh ada di Flutter, jangan ditambahkan di
  server, supaya tidak terjadi penyaringan ganda.
- Model TFLite **wajib** dijalankan di thread terpisah.
- Peringatan bahaya **selalu** memotong suara lain.
- Pelacak SORT harus direset saat berganti mode.
- TTS default `id-ID`; deskripsi Moondream dibacakan dengan `speakEnglish()`
  yang sementara ganti locale ke `en-US`.

---

## 13. Koneksi ke Backend Laptop (HP Fisik)

### Cara cepat: WiFi satu jaringan

```bash
# Laptop
uvicorn main:app --host 0.0.0.0 --port 8000
ip addr show  # cari wlan0, contoh: 192.168.1.5
```

Di HP: buka Guidio → ucapkan **"pengaturan"** → isi `192.168.1.5:8000` →
**Uji Sambungan** → **Simpan**.

### Cara alternatif: USB tanpa WiFi (ADB Reverse)

```bash
adb reverse tcp:8000 tcp:8000
```

Isi alamat server di Guidio: `localhost:8000`

### Build APK

```bash
flutter build apk --release
flutter install
```

### Penjelasan nilai bawaan alamat server

| Situasi | Alamat yang diisi |
|---|---|
| Emulator Android di laptop | `10.0.2.2:8000` (bawaan) |
| HP fisik, WiFi sama dengan laptop | IP laptop, contoh: `192.168.1.5:8000` |
| HP fisik, sambung USB + ADB reverse | `localhost:8000` |

---


## 14. Testing

### Prinsip: test yang di-skip bukan test yang lulus

Versi README ini sebelumnya menulis *"Test yang di-skip bukan error, tidak ada
yang merah = aman"*. Kalimat itu keliru, dan kekeliruannya mahal.

Di host Linux dan macOS, `tflite_flutter` memuat pustaka native lewat FFI dari
`${Platform.resolvedExecutable}/../blobs/libtensorflowlite_c-<platform>.so`.
Pustaka itu **tidak ikut** waktu `flutter pub get`. Kalau tidak ada,
`svc.load()` mengembalikan `false`, setiap uji inferensi meloncat ke
`markTestSkipped`, dan terminal menulis "All tests passed!" dengan gembira.
Yang sebenarnya terjadi: nol piksel diuji.

Itu bukan skenario hipotetis. Seluruh uji inferensi uang **dan** navigasi di
repo ini berstatus skip sejak awal. Begitu pustakanya dipasang, empat uji
navigasi langsung merah, padahal sebelumnya tidak pernah ada satu pun tanda
peringatan.

Karena itu `test/money_pipeline_test.dart` punya satu uji prasyarat yang
**gagal**, bukan skip, ketika runtime TFLite tidak ada. Untuk sengaja
melewatinya (misalnya CI yang memang hanya memeriksa lint), pakai
`GUIDIO_ALLOW_SKIP_TFLITE=1`, dengan kesadaran penuh bahwa suite itu tidak
memvalidasi model sama sekali.

### Menyiapkan runtime TFLite (sekali per instalasi Flutter)

```bash
# dari folder guidio_app/
curl -L -o blobs/libtensorflowlite_c-linux.so \
  https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.5.0/libtensorflowlite_c-linux.so
tool/setup_tflite_linux.sh
```

Skrip itu menyalin pustaka ke direktori artifacts engine Flutter. Direktori
tersebut **ikut terhapus setiap `flutter upgrade` atau ganti versi FVM**, jadi
jalankan ulang setelahnya. Salinan di `blobs/` sengaja disimpan supaya tidak
perlu mengunduh lagi.

Verifikasi cepat:

```bash
flutter test test/money_pipeline_test.dart
```

Kalau uji `runtime TFLite tersedia` lulus, sisanya benar-benar menjalankan model.

---

### A. Uji pipeline uang: `test/money_pipeline_test.dart`

Ini satu-satunya tempat pengenalan uang diuji, dan ia memanggil
**`MoneyTFLiteService.classifyCameraImage`**, fungsi yang sama persis dengan
yang berjalan waktu pengguna mengarahkan kamera.

Frame kamera dipalsukan dari fixture PNG: RGB dikonversi balik ke YUV420 dengan
tata letak Android `YUV_420_888` termasuk `pixelStride == 2` pada bidang kroma.
Tata letak itu ditiru persis, bukan disederhanakan jadi planar, supaya bug
indeks kroma yang hanya muncul di perangkat asli tetap tertangkap.

Empat kelompok:

| Kelompok | Yang dijaga | Status sekarang |
|---|---|---|
| **A. KEAMANAN** | Tidak pernah yakin tapi salah. Di bawah ambang, `valueIdr` wajib `null` dan pengguna wajib dapat instruksi | 5/5 hijau |
| **B. KEMAMPUAN** | Tebakan teratas harus benar, dan keyakinan harus tembus 0,85 | **4/10 merah** |
| **C. PARITAS** | Jalur kamera dan jalur JPEG harus sepakat | 5/5 hijau |
| **D. KONTRAK** | Urutan kelas cocok dengan `rupiah_class_info.json`, ground-truth fixture bisa diurai | 2/2 hijau |

Kelompok B adalah **ratchet yang sengaja dibiarkan merah**. Merahnya adalah
informasi: pipeline uang belum layak dipakai pengguna. Jangan dilonggarkan
supaya hijau. Yang dinaikkan adalah modelnya, lihat bagian 3.

Kelompok C bukan formalitas. Kedua jalur masuk punya praproses terpisah dan
pernah memakai aturan crop yang berbeda, sehingga lembar yang sama bisa
menjawab lain tergantung tombol mana yang ditekan. Kegagalan seperti itu
mustahil didiagnosis dari laporan pengguna.

Fixture yang dipakai:

```
test/fixtures/
├── money_new/    2 tangkapan layar ponsel 720x1560 (uang kecil, tertimpa overlay UI)
├── money_new2/   3 foto biasa 900x1600 (uang mengisi hampir selebar frame)
├── money/        14 JPEG lama, kini tidak dipakai suite mana pun
└── navigation/   5 PNG bahaya jalan
```

Ground-truth diambil dari nama berkas lewat regex (`5000.png` dan `5rb.png`
sama-sama berarti Rp5.000). Tidak ada tabel hard-coded: kalau nama berkas
menyimpang, regex gagal dan test langsung merah alih-alih diam-diam menguji
hal yang salah.

### B. Uji lain

```bash
flutter test                                  # semua
flutter test test/command_parser_test.dart    # parsing perintah suara, tanpa model
flutter test test/model_inference_test.dart   # inferensi YOLO navigasi
```

`test/model_inference_test.dart` sekarang **hanya** menguji navigasi. Kelompok
uangnya dihapus karena dua cacat yang membuatnya tidak bisa merah:

1. Ia membangun praprosesnya sendiri dengan
   `img.copyResize(source, width: 224, height: 224)`, yaitu **peregangan** ke
   persegi tanpa center-crop. Model dilatih dengan letterbox dan aplikasi
   memakai center-crop 0,7 lalu letterbox. Jadi suite itu mengukur pipeline
   yang tidak pernah dijalankan siapa pun.
2. Assert-nya dibungkus `if (confidence >= 0.85) { ... } else { print(...) }`.
   Karena model jarang menembus 0,85, cabang assert tidak pernah dieksekusi.

Kelompok uang di `test/command_parser_test.dart` juga dihapus. Ia sudah
memanggil `classifyJpeg`, tapi assert-nya dibungkus `if (result.detected)`
sehingga tidak pernah bisa merah. Tempatnya juga keliru: berkas itu menguji
parsing perintah, dan menumpang inferensi model di sana membuat kegagalan
model menyamar jadi kegagalan parser.

### Hasil terakhir

```
79 passed, 3 skipped, 10 failed
```

Sepuluh yang merah, semuanya nyata dan bukan masalah infrastruktur:

| Jumlah | Berkas | Sebab |
|---|---|---|
| 6 | `money_pipeline_test.dart` kelompok B | Model belum tangguh pada framing kamera, lihat bagian 3 |
| 4 | `model_inference_test.dart` kelompok B | Model navigasi YOLO tidak mendeteksi satu pun label yang diharapkan pada 4 dari 5 fixture. Baru terlihat sekarang karena sebelumnya selalu di-skip |

Empat kegagalan navigasi itu **temuan baru**, bukan regresi yang saya sebabkan.
Ia sudah ada sejak lama dan tersembunyi di balik skip.

---

### C. Python visual test - lihat gambar hasilnya

Menghasilkan gambar ter-anotasi seperti di `test/navigation/results_mobile_tflite/`.
Berguna untuk memeriksa secara visual apakah bounding box dan klasifikasi masuk akal.

#### Setup (sekali saja) - dari root repo (folder `guido/`)

```bash
python3 -m venv test/.venv
test/.venv/bin/pip install -r test/requirements-test.txt
```

Hanya install `ai-edge-litert` + `Pillow` + `numpy` (~50 MB, tidak perlu TensorFlow penuh).

#### Menjalankan - dari root repo (folder `guido/`)

```bash
test/.venv/bin/python test/run_visual_test.py
```

Setiap run membuat **folder baru** dengan nama epoch (unix timestamp):

```
test/results/<epoch>/
├── navigation/
│   ├── nav_01_got_terbuka__none.png
│   ├── nav_02_lubang_trotoar__lubangp50.png
│   ├── nav_04_motor_dan_orang__motorp38_orangp17.png
│   └── ...
├── money/
│   ├── money_uang_1000_a__PASS_99p6.jpg
│   ├── money_uang_20000_b__UNCERTAIN_57p4.jpg
│   └── ...
└── summary.txt
```

#### Cara baca nama file tanpa buka gambarnya

**Navigasi** - bagian setelah `__` adalah label yang terdeteksi + confidence:

```
nav_02_lubang_trotoar__lubangp50.png
                       ^ label=lubang, conf=0.50

nav_04_motor_dan_orang__motorp38_orangp17.png
                        ^ motor (0.38), orang (0.17)

nav_01_got_terbuka__none.png
                    ^ tidak ada deteksi
```

**Uang** - bagian setelah `__` adalah status + confidence:

```
money_uang_100000_a__PASS_99p6.jpg        -> benar, conf 99.6%
money_uang_20000_b__UNCERTAIN_57p4.jpg    -> ragu-ragu, conf 57.4% (di bawah threshold 85%)
money_uang_5000_a__FAIL_pred2000_42p1.jpg -> salah prediksi ke 2000 (harusnya tidak terjadi)
```

#### Format isi gambar

**Navigasi:** gambar asli + bounding box berwarna per kelas + label confidence di atas box
+ watermark jumlah deteksi dan epoch di bagian bawah.

**Uang:** gambar asli + panel di bawah berisi status (hijau = benar, merah = salah,
kuning = uncertain) + bar chart probabilitas semua 7 kelas.

#### Exit code

```
0 -> semua pass atau uncertain (aman)
1 -> ada navigasi fail atau uang salah ketika confident
```
