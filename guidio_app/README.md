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
layar beranda — setiap layar perantara berarti penundaan sebelum pengguna
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
> dipakai** — hanya sisa percobaan. Yang dimuat adalah `ssd_mobilenet.tflite`.

### Model pengenalan uang

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/rupiah_classifier_int8.tflite` |
| Arsitektur | MobileNetV2 transfer learning (repo `rupiah-vision`) |
| Ukuran masukan | 224 × 224 piksel, float32 **rentang −1..1** |
| Jumlah kelas | 7 pecahan — emisi 2016 & 2022 |
| Test accuracy | 98,36% (varian INT8) |

Urutan kelas **wajib** persis seperti saat model dilatih (`CLASS_ORDER` di `scripts/02_export_tflite.py`):

```
1.000 = 0   2.000 = 1   5.000 = 2   10.000 = 3
20.000 = 4  50.000 = 5  100.000 = 6
```

> **Perhatian rentang input:** model ini memakai rentang −1..1 (`x/127.5 − 1`),
> **bukan** 0..255. Nilai yang salah tidak memunculkan error — prediksi hanya
> diam-diam salah. Periksa ulang jika model diganti.

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
tidak bisa menentukan — biasanya kasus ambigu yang perlu konfirmasi pengguna.

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

Urutan objek: yang paling dekat disebut lebih dulu — objek paling berbahaya
mendapat prioritas.

### Deskripsi suasana (Moondream2)

Untuk `POST /api/describe`, backend mengembalikan `description_en` — caption
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
putih — kontrasnya gagal untuk pengguna low vision. Setiap tingkat bahaya
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

Info sengaja dibuang saat basi — informasi tentang benda yang sudah terlewat
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

Ada dua cara testing yang bisa dijalankan secara independen:

| | Flutter unit test | Python visual test |
|---|---|---|
| Tujuan | Validasi logika & parsing | Lihat hasil gambar anotasi |
| Butuh setup? | Tidak | Sekali saja (venv) |
| Output | Pass/fail di terminal | Folder gambar bertimestamp |
| Butuh model? | Opsional (di-skip jika tidak ada) | Ya |

---

### A. Flutter unit test

**Tidak butuh setup apapun.** Jalankan dari folder `guidio_app/`:

```bash
flutter test
```

Atau per file jika mau lebih fokus:

```bash
# Command parser — cepat, tidak butuh model atau device
flutter test test/command_parser_test.dart

# Inferensi model langsung — butuh TFLite shared library
flutter test test/model_inference_test.dart
```

**Hasil tipikal di laptop Linux** (tanpa perangkat Android):

```
+40 passed, ~17 skipped
```

Test yang di-skip **bukan error** — mereka otomatis lewat sendiri kalau dependensinya tidak ada
(TFLite `.so`, backend server, dll.). Tidak ada yang merah = aman.

#### Apa yang ditest?

**`test/command_parser_test.dart`** — logika parsing perintah suara:

| Kelompok | Yang ditest | Syarat jalan |
|---|---|---|
| Pemetaan 21 intent | Contoh ucapan dari dokumen arsitektur | — |
| Prioritas frasa | Frasa spesifik menang atas kata umum (4 kasus) | — |
| Prefiks natural | "saya mau ke mode..." dan variasi (2 kasus) | — |
| Batas kata | Anti false-positive | — |
| Saran intent | Hanya intent yang ada handler-nya yang keluar | — |
| **Kenali Uang** | Klasifikasi 14 gambar JPEG nyata (2 per pecahan) | TFLite SO |
| **Navigasi** | 5 fixture PNG, cek file valid + ada deteksi | — |
| **Cari Objek** | Parse perintah cari + guard jika backend mati | Backend opsional |

**`test/model_inference_test.dart`** — model TFLite langsung, memuat dari path file:

| Model | Input | Cara validasi |
|---|---|---|
| `rupiah_classifier_int8.tflite` | 14 JPEG, 224x224, rentang -1..1 | Nama file `uang_10000_a.jpg` → expected = 10000 |
| `yolo11n.tflite` | 5 PNG, 640x640 NCHW, rentang 0..1 | Nama file `04_motor_dan_orang.png` → {motor, orang} |

Validasi uang: confidence >= 85% harus benar persis; < 85% (uncertain) tetap pass
(sama dengan perilaku production yang tidak menampilkan nominal saat ragu).

Validasi navigasi: setidaknya **satu** label yang diharapkan harus ada di hasil deteksi.

#### Gambar fixture

```
test/fixtures/
├── money/       <- 14 JPEG, 2 gambar per pecahan (1rb s.d. 100rb)
└── navigation/  <- 5 PNG dari test/navigation/test/
```

---

### B. Python visual test — lihat gambar hasilnya

Menghasilkan gambar ter-anotasi seperti di `test/navigation/results_mobile_tflite/`.
Berguna untuk memeriksa secara visual apakah bounding box dan klasifikasi masuk akal.

#### Setup (sekali saja) — dari root repo (folder `guido/`)

```bash
python3 -m venv test/.venv
test/.venv/bin/pip install -r test/requirements-test.txt
```

Hanya install `ai-edge-litert` + `Pillow` + `numpy` (~50 MB, tidak perlu TensorFlow penuh).

#### Menjalankan — dari root repo (folder `guido/`)

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

**Navigasi** — bagian setelah `__` adalah label yang terdeteksi + confidence:

```
nav_02_lubang_trotoar__lubangp50.png
                       ^ label=lubang, conf=0.50

nav_04_motor_dan_orang__motorp38_orangp17.png
                        ^ motor (0.38), orang (0.17)

nav_01_got_terbuka__none.png
                    ^ tidak ada deteksi
```

**Uang** — bagian setelah `__` adalah status + confidence:

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
