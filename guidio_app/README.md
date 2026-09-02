# Vinara Mobile (guidio_app)

Aplikasi Flutter untuk Android. Inilah bagian yang dipegang pengguna, dan
bagian yang paling menentukan apakah sistem ini benar-benar bisa dipakai
orang yang tidak melihat layar.

Enam hal ini berjalan penuh di dalam ponsel **tanpa internet sama sekali**:

| Fitur | File |
|---|---|
| Peringatan rintangan | `services/tflite_service.dart` |
| Pengenalan uang | `services/money_tflite_service.dart` |
| Baca teks (ML Kit) | `services/ocr_service.dart` |
| Navigasi jalur 3 zona (empat model) | `services/pidnet_service.dart`, `services/yolo_navigasi_service.dart`, `services/yolo_nav_int8_service.dart`, `services/tflite_service.dart` |
| Intent parsing (24 intent baku) | `core/voice/command_parser.dart` |
| Penjadwalan dan penyusunan narasi | `core/voice/narration_scheduler.dart` |

Hanya dua hal yang butuh server: **Cari Objek** (YOLOE) dan **deskripsi
suasana** (Moondream2). Sisanya tidak pernah memanggil backend sama sekali.

---

## Daftar isi

1. [Cara kerja singkat](#1-cara-kerja-singkat)
2. [Enam mode dan layarnya](#2-enam-mode-dan-layarnya)
3. [Lima model AI di dalam ponsel](#3-lima-model-ai-di-dalam-ponsel)
4. [Intent parsing lokal: CommandParser](#4-intent-parsing-lokal-commandparser)
5. [Narasi lokal](#5-narasi-lokal)
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
ObjectTracker (SORT): identitas stabil per objek, jarak dihaluskan
        │
        ▼
DetectionFilter: buang yang terlalu jauh, buang yang cuma muncul sekilas,
jangan ulangi objek yang sama terlalu sering
        │
        ▼
NarrationScheduler: kapan bicara, dan berapa banyak yang muat
dalam satu ucapan (beranggaran kata, tanpa LLM)
        │
        ▼
TtsQueue bertingkat → suara + getar ke pengguna
```

Tiga lapis terakhir tugasnya sengaja dipisah: tracker memutuskan **objek mana
ini**, filter memutuskan **apa** yang layak diucapkan, scheduler memutuskan
**kapan** dan **dalam bentuk apa**.

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

Aplikasi terbuka langsung ke Mode Deteksi Objek. Tidak ada layar beranda,
karena setiap layar perantara berarti penundaan sebelum pengguna mendapat
informasi keselamatan.

| Mode | Berkas layar | Butuh internet? |
|---|---|---|
| Deteksi Objek | `screens/tuntun_screen.dart` | Tidak |
| Kenali Uang | `screens/money_screen.dart` | Tidak |
| Baca Teks | `screens/ocr_screen.dart` | Tidak, ML Kit on-device |
| Navigasi | `screens/navigasi_screen.dart` | Tidak, empat model on-device |
| Asisten Suara | `screens/voice_screen.dart` | Sebagian, hanya deskripsi suasana |
| Cari Objek | `screens/find_object_screen.dart` | Ya, satu-satunya yang mati offline |

Berpindah mode ada dua jalan: mengucapkan namanya (satu langkah), atau lewat
tombol Pilih Mode di kanan bawah (dua langkah).

### Deteksi rintangan mulai dalam keadaan MATI

Mode Deteksi Objek terbuka, tetapi pengawasannya belum menyala. Pengguna harus
menekan tombol kiri bawah lebih dulu.

Saat aplikasi baru dibuka, ponsel biasanya masih di tangan yang turun, di dalam
saku, atau menghadap tanah. Peringatan pertama dari posisi itu hampir selalu
keliru, dan peringatan keliru dari alat bantu jalan lebih merusak daripada
diam: sekali pengguna belajar aplikasinya sering salah, peringatan yang benar
ikut diabaikan.

Konsekuensinya ditangani, bukan diabaikan. Keadaan mati **diucapkan** saat
masuk mode, dan diingatkan ulang tiap 30 detik disertai getar. Aplikasi yang
dijeda tidak bisa dibedakan dari aplikasi yang aktif tapi kebetulan tidak
melihat apa pun, jadi diam bukan pilihan.

### Kontrak tombol kiri, berbeda tiap mode

| Mode | Label tombol kiri | Aksi |
|---|---|---|
| Deteksi Objek | `Hentikan` / `Lanjutkan` | Nyala dan mati deteksi |
| Navigasi | `Matikan Suara` / `Nyalakan Suara` | Bisu dan nyala **suara** panduan, bukan modenya |
| Kenali Uang | `Kenali Uang` | Satu tekan sama dengan satu analisis |
| Baca Teks | `Baca teks` ke `Jeda bacaan` ke `Lanjutkan bacaan` | Kontekstual |
| Asisten Suara | `Ulangi jawaban` | Bacakan ulang jawaban terakhir |
| Cari Objek | `Kirim, cari [barang]` | Kirim frame ke server |

Perintah suara **"jepret"** menjalankan persis apa yang dilakukan tombol kiri
di mode yang sedang aktif. Satu model mental, dua cara memicunya.

Tombol kiri yang nonaktif **tetap bersuara** saat ditekan, menyebutkan
alasannya. Untuk pengguna yang tidak melihat layar, tombol yang diam saat
ditekan tidak bisa dibedakan dari aplikasi yang macet, dan satu-satunya cara
menguji dugaannya adalah menekan lagi.

---

## 3. Lima model AI di dalam ponsel

Daftar aset di `pubspec.yaml` menyebut model **satu per satu**, bukan seluruh
direktori. Ini disengaja: `- assets/models/` akan ikut membundel semua yang
kebetulan ada di folder itu, termasuk berkas percobaan yang tidak pernah dimuat
kode. Untuk pengguna dengan kuota terbatas, itu ratusan megabyte yang dibayar
tanpa satu pun manfaat.

| Berkas | Ukuran | Dipakai oleh |
|---|---|---|
| `ssd_mobilenet.tflite` | ~4,0 MB | Deteksi rintangan, sekaligus lapis COCO Mode Navigasi |
| `rupiah_classifier_int8.tflite` | ~2,8 MB | Kenali Uang, 7 pecahan |
| `pidnet_s_3zona.tflite` | ~2,5 MB | Segmentasi jalur 3 zona |
| `yolo11n_navigasi.tflite` | ~10,1 MB | Rintangan navigasi FP16, 6 kelas |
| `yolo11n.tflite` | ~2,9 MB | Rintangan navigasi INT8 NCHW, lapis keempat |
| **Total di APK** | **~22,3 MB** | ditambah `labelmap.txt` |

> Model uang yang dibundel adalah varian **INT8**, bukan FP16. Itu rekomendasi
> repo pelatihannya sendiri (`scripts/02_export_tflite.py`, kunci
> `recommended_for_flutter`). Bobot dan aktivasinya INT8 tapi I/O-nya tetap
> float32, jadi praproses di Dart tidak berubah sama sekali.

> Baca Teks tidak punya berkas model di daftar ini: Google ML Kit membawa
> mesinnya sendiri lewat Play Services.

### Berkas yang ADA di folder tapi sengaja tidak dibundel

| Berkas | Kenapa tidak ikut |
|---|---|
| `pidnet_s_3zona_fp16.tflite` | Tensor masukannya FLOAT16 sementara seluruh pipeline menghasilkan FLOAT32, jadi ia tidak akan pernah bisa dipakai. Dulu ia dicoba lebih dulu dan hanya dilewati kalau berkasnya hilang, sehingga segmentasi jalur gagal di setiap frame tanpa satu pun tanda di layar |
| `rupiah_classifier_fp16.tflite`, `uang_rupiah.tflite` | Varian dan arsip model uang yang tidak dimuat `MoneyTFLiteService` |
| `rupiah_labels.txt` | Urutan kelas sudah tetap di `MoneyTFLiteService.classValues`, tidak ada yang memuatnya lewat `rootBundle`. Disimpan sebagai rujukan saat mengganti model |
| `yoloe_find.onnx`, `pidnet_s*.onnx`, `yolo11n_e100_*.tflite` | Sisa percobaan, tidak dimuat kode mana pun |

Model salah bentuk **tidak melempar error**, ia cuma mengembalikan hasil
kosong selamanya, dan itu sudah pernah terjadi di sini. `PidnetService.tryLoad`
sekarang membuktikan tiap varian dengan inferensi percobaan sebelum
menerimanya.

> **Catatan sejarah `yolo11n.tflite`.** Berkas ini pernah dicabut dari
> `pubspec.yaml` dengan alasan yang benar pada masanya: bentuknya NCHW
> `[1,3,640,640]` sementara `YoloNavigasiService` menyusun NHWC
> `[1,640,640,3]`, jadi interpreter menolaknya. Sekarang ia dimuat
> `YoloNavInt8Service`, service terpisah yang memang dibangun untuk tata letak
> NCHW dan justru **menolak** model yang bukan NCHW. Selama berkasnya tidak
> terdaftar di `pubspec.yaml`, `rootBundle.load` gagal, `_int8Ready` tetap
> false, dan pipeline yang dikira empat lapis diam-diam cuma tiga.

### Model deteksi rintangan

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/ssd_mobilenet.tflite` |
| Ukuran masukan | 300 x 300 piksel |
| Kecepatan | sekitar 30 milidetik per gambar |
| Laju | `FramePacer` 120 ms, sekitar 8 fps |
| Dijalankan di | `IsolateInterpreter`, supaya layar tidak macet |

### Mode Navigasi memakai EMPAT model, bukan tiga

| Lapis | Model | Yang hanya bisa dilihat lapis ini |
|---|---|---|
| 1. Jalur | PIDNet-S | Zona kiri, tengah, kanan; permukaan layak jalan |
| 2. Bahaya jalanan | YOLO11n custom FP16 (`yolo11n_navigasi.tflite`) | `lubang`, `got_terbuka`, `tangga` |
| 3. Benda umum | SSD MobileNet COCO | `orang`, `motor`, mobil, sepeda, anjing, perabot jalan |
| 4. Bahaya jalanan INT8 | YOLO11n INT8 NCHW (`yolo11n.tflite`) | `tiang`, yang tidak pernah menyala di lapis 2 |

Keempatnya jalan paralel dari **satu frame yang sama**. Frame yang sama itu
syarat, bukan penghematan: kalau salah satunya terlambat satu frame, pengguna
bisa mendengar "jalur tengah aman" bersamaan dengan "ada motor di depan" dari
pemandangan yang sudah lewat.

**Keempat lapis wajib.** `_modelsReady` baru true kalau keempatnya termuat, dan
kalau ada yang gagal `NavigationProvider` menyebutkan lapis mana lewat log.
Sebelumnya lapis 3 dan 4 opsional dan modenya tetap menyala dengan dua lapis.
Niatnya baik, tapi akibatnya satu mode memakai nama yang sama untuk dua tingkat
perlindungan yang berbeda jauh, tanpa pengguna pernah diberi tahu yang mana
yang sedang aktif. Lapis 4 khusus mengurus rintangan vertikal tipis seperti
tiang listrik dan tiang rambu, justru golongan yang paling berbahaya: tongkat
melewatinya tanpa menyentuh, lalu kepala yang menemukannya.

Lapis 3 memakai singleton `TFLiteService` yang sama dengan Mode Deteksi Objek.
Kalau modelnya sudah termuat dari sana, tidak ada interpreter kedua yang
dibangun: di HP 4 GB dua interpreter menganggur sudah terasa.

Duplikat antara lapis 2 dan lapis 4 dibuang berdasarkan IoU >= 0,45, lalu
hasilnya digabung lagi dengan lapis COCO. Dua kali `mergeNavObstacles`, satu
aturan prioritas bahaya.

Hanya 15 dari 80 kelas COCO yang lolos saringan `kCocoNavRelevant`, dan hanya
benda yang bisa menghalangi atau membahayakan langkah. Menyebut "botol" atau
"ponsel" saat pengguna menyeberang bukan cuma tidak berguna: ia menunda kalimat
yang menyangkut keselamatan.

Aturan penggabungan ada di `nav_obstacle_merger.dart` dan diuji di
`test/nav_obstacle_merger_test.dart`: benda yang sama tidak disebut dua kali,
tapi motor yang terparkir di atas got terbuka tetap disebut sebagai dua bahaya
karena kelasnya tidak berpadanan.

### Model navigasi

| Hal | Nilai |
|---|---|
| Segmentasi | PIDNet-S, 3 zona (kiri, tengah, kanan) |
| Rintangan FP16 | YOLO11n NHWC `[1,640,640,3]`, 6 kelas: lubang, got_terbuka, tangga, orang, motor, tiang |
| Rintangan INT8 | YOLO11n NCHW `[1,3,640,640]`, 6 kelas yang sama, keluaran `[1,10,8400]` |
| Laju | Timer 500 ms ditahan `FramePacer` 700 ms, efektif sekitar 1,4 fps |
| Ambang FP16 | `lubang` dan `got_terbuka` 5%; kelas lain 30% |
| Ambang INT8 | 25% untuk semua kelas, NMS IoU 0,45 |

Kalau YOLO tidak mendeteksi apa pun, PIDNet-S tetap jadi lapis pengaman lewat
penurunan rasio area walkable. Lihat bagian 14 soal seberapa sering itu yang
benar-benar terjadi.

### Model pengenalan uang

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/rupiah_classifier_int8.tflite` |
| Arsitektur | MobileNetV2 transfer learning (repo `rupiah_vision_revised`) |
| Kuantisasi | INT8 untuk bobot dan aktivasi, I/O tetap float32 |
| Ukuran masukan | 224 x 224 piksel, float32 **rentang -1..1** |
| Resize | **letterbox** (`resize_with_pad`), bukan peregangan |
| Praproses aplikasi | **frame utuh**, tanpa crop, lalu letterbox |
| Keluaran | softmax, bukan logit |
| Jumlah kelas | 7 pecahan, emisi 2016 dan 2022 |
| Ambang yakin | `confidenceThreshold` 0,85 |
| Jalur margin | `marginThreshold` 0,50 dengan `marginPathMinConfidence` 0,80 |
| Test accuracy (lab) | 97,98% pada test set internal |

> `rupiah_classifier_fp16.tflite` dan `uang_rupiah.tflite` di folder yang sama
> **tidak dibundel** ke APK. `MoneyTFLiteService` hanya memuat varian int8.

#### Frame dikirim utuh, tanpa center-crop

Versi sebelumnya hanya menganalisis 70 persen area tengah, dengan asumsi
pengguna menaruh uang pas di dalam bingkai panduan. Asumsi itu tidak berlaku
untuk pengguna tunanetra: mereka tidak bisa melihat bingkai itu, jadi lembar
yang sedikit bergeser kehilangan tepi, justru tempat angka nominal berada, dan
model menjawab salah atau ragu tanpa satu pun tanda bahwa penyebabnya cuma
framing.

Jalur kamera (`classifyCameraImage`) dan jalur JPEG (`classifyJpeg`) sekarang
sama-sama memakai gambar utuh. Kesepakatan keduanya dijaga kelompok C di
`test/money_pipeline_test.dart`.

#### Angka lab tidak sama dengan angka lapangan

Test accuracy 97,98% diukur pada test set yang isinya **crop rapat** hasil
bounding box: lembar uang mengisi lebih dari 80 persen bidang, rasionya sekitar
2:1 mendatar. Frame kamera sungguhan tidak pernah seperti itu. Pergeseran
distribusi skala dan framing itulah yang menahan mode ini, bukan bobot yang
rusak; perbaikannya ada di `new_training/rupiah_vision_revised` (simulasi
framing kamera lewat `--frame-prob` dan `--bg-dir`), bukan di sisi aplikasi.

**Angka lapangannya tidak bisa diukur dari `flutter test` di Linux.** Runtime
desktop di `blobs/` berasal dari `tflite_flutter_plugin` v0.5.0 (2021) dan
tidak sanggup menjalankan model INT8: ia memuatnya tanpa mengeluh lalu
mengembalikan distribusi **rata 1/7 untuk masukan apa pun**. Gambar hitam polos
dan gambar putih polos menghasilkan tujuh angka 0,1445 yang identik. Android
memakai LiteRT 1.4.0 lewat `tflite_flutter` 0.12.1 dan menjalankan model yang
sama dengan benar.

Karena itu `money_pipeline_test.dart` punya satu uji prasyarat bernama *runtime
bisa menjalankan model terkuantisasi* yang **gagal**, bukan skip, di host
Linux. Merahnya benar: tanpa uji itu seluruh kelompok B akan terbaca sebagai
"model rusak" padahal yang tidak sanggup adalah runtimenya.

Untuk mengukur angka yang benar-benar mewakili ponsel, pakai LiteRT modern:

```bash
python3 -m venv .venv && .venv/bin/pip install ai-edge-litert pillow numpy
.venv/bin/python tool/eval_rupiah_litert.py          # meniru jalur kamera
.venv/bin/python tool/eval_rupiah_litert.py jpeg     # meniru jalur JPEG
```

Praproses dan gerbang di skrip itu **disalin persis** dari
`lib/services/money_tflite_service.dart`. Kalau salah satunya diubah, ubah
keduanya; kalau tidak, skrip itu mengukur pipeline yang tidak pernah dijalankan
siapa pun. Versi Dart-nya ada di `test/rupiah_kamera_e2e_test.dart` dan akan
jalan sendiri begitu runtime desktopnya diperbarui atau saat diuji on-device.

Urutan kelas **wajib** persis seperti saat model dilatih (`CLASS_ORDER` di `scripts/02_export_tflite.py`):

```
1.000 = 0   2.000 = 1   5.000 = 2   10.000 = 3
20.000 = 4  50.000 = 5  100.000 = 6
```

> **Perhatian rentang input:** model ini memakai rentang -1..1 (`x/127.5 - 1`),
> **bukan** 0..255. Nilai yang salah tidak memunculkan error apa pun, prediksinya
> hanya diam-diam salah. Periksa ulang jika model diganti.

#### Aturan jawaban: SELALU menjawab, TIDAK selalu dengan nada yakin

Ini berubah, dan perubahannya penting dimengerti sebelum menyentuh
`MoneyResult`.

Versi sebelumnya **menolak menjawab** di bawah ambang: nominalnya dibuang dan
yang keluar cuma instruksi "Belum yakin, dekatkan sedikit". Di atas kertas itu
terdengar seperti pengaman. Di lapangan justru itu yang mematikan fiturnya:
kasus paling biasa, uang tergeletak di meja lalu difoto sambil berdiri,
berakhir buntu di kartu peringatan tanpa jalan keluar, dan pengguna yang tidak
melihat layar tidak punya cara menebak apa yang kurang.

Sekarang `_runInference` **selalu** mengembalikan nominal, dan
`MoneyResult.certain` yang membedakan dua nada jawaban:

| `certain` | Kapan | Nada yang wajib dipakai |
|---|---|---|
| `true` | keyakinan >= 0,85, **atau** margin ke juara dua >= 0,50 dengan keyakinan >= 0,80 | lugas: "Lima puluh ribu rupiah" |
| `false` | selain itu | berpagar: "Sepertinya lima puluh ribu rupiah", plus ajakan mengecek ulang |

`detected == false` sekarang **hanya** berarti tidak ada hasil sama sekali:
model belum siap, atau frame-nya gagal dibaca. Keraguan model tidak lagi muncul
sebagai `detected == false`.

**Risikonya tidak dihapus, hanya dipindah, dan itu disengaja.** Nominal di
bawah ambang memang masih bisa salah. Yang menahannya sekarang bukan diam,
melainkan kata "sepertinya". Lapisan atas **tidak boleh** mengabaikan
`MoneyResult.certain`: membacakan hasil berpagar dengan nada lugas
mengembalikan persis bahaya yang dulu ditahan oleh penolakan menjawab, yaitu
menyebut nominal keliru kepada orang yang tidak bisa memeriksa sendiri.

---

### Anggaran kinerja dan RAM

Target perangkat: RAM 3 sampai 4 GB. Di kelas itu yang membunuh kelancaran
bukan kecepatan CPU, melainkan **tekanan garbage collector**. Setiap alokasi
besar yang berulang memicu GC pause, dan karena antrean suara dijadwalkan dari
thread UI, GC pause muncul sebagai TTS yang tersendat. Bagi pengguna tunanetra
suara yang patah lebih merusak daripada gambar yang patah.

Kelima jalur inferensi kini memakai pola yang sama:

| Service | Buffer masukan | Interpreter |
|---|---|---|
| `tflite_service` (SSD rintangan) | `Uint8List` datar | `IsolateInterpreter` |
| `yolo_navigasi_service` | datar | `IsolateInterpreter` |
| `yolo_nav_int8_service` | `Float32List` datar, ditranspose NHWC ke NCHW di tempat | `IsolateInterpreter` |
| `pidnet_service` | datar | `IsolateInterpreter` |
| `money_tflite_service` | `Float32List` datar | `IsolateInterpreter` |

`yolo_nav_int8_service` menerima tensor NHWC yang sama dengan lapis FP16 lalu
mentransposenya sendiri ke NCHW, memakai buffer yang dipakai ulang antar frame
alih-alih mengalokasi yang baru. Jadi `NavFrameConverter` tetap satu lintasan
untuk kedua lapis YOLO, bukan dua.

Service uang adalah yang terakhir menyusul. Sebelumnya ia membangun
`List<List<List<List<double>>>>`, yaitu **50.401 objek List dan 150.528 double
ter-boxing** per inferensi, sekitar 3,8 MB sampah heap. Semua itu juga harus
diserialisasi melewati port isolate `compute()`. Sekarang: satu `Float32List`
602.112 byte, sekali alokasi, transfer nyaris gratis. Inferensinya juga pindah
dari thread UI ke `IsolateInterpreter`.

Hasil inferensi diverifikasi tidak berubah sedikit pun oleh
`test/money_pipeline_test.dart`: kelima fixture menghasilkan keyakinan yang
sama persis sebelum dan sesudah perubahan.

#### Jebakan yang ditemukan saat mengerjakannya

`Tensor.getInputShapeIfDifferent` di `tflite_flutter` hanya mengecualikan
`ByteBuffer` dan `Uint8List` dari penyimpulan bentuk. Buffer datar bertipe lain,
termasuk `Float32List`, akan disimpulkan berbentuk `[150528]`, lalu tensor
masukan di-resize dan model gagal dengan
`Node number 108 (CONV_2D) failed to prepare`.

Lewat `IsolateInterpreter`, kegagalan itu **tidak melempar apa pun**. Tensor
keluaran cuma tidak pernah ditulis, jadi hasilnya nol semua dan setiap pecahan
terbaca Rp1.000 dengan keyakinan 0%. Karena itu tensor dikirim sebagai view
`Uint8List` di atas buffer `Float32List` yang sama, tanpa penyalinan.

Jenis kegagalan seperti ini yang membuat suite uji wajib punya assertion keras,
bukan `if (detected) { ... }`.

### Ponsel lama: kamera berkabut dan prosesor yang tidak mengejar

Dua hal ini digarap terpisah karena penyebabnya berbeda.

**Kamera berkabut.** Lensa yang tergores dan berdebu menyebarkan cahaya di
dalamnya lalu mengangkat titik hitam. Terukur pada Samsung A30s lima tahun di
repo ini: p2 naik dari 9 ke 50, rentang dinamis turun dari 220 ke 145-171.
Tidak ada piksel yang benar-benar hitam, dan tepi objek yang dipakai detektor
jadi tipis.

`luma_contrast.dart` mengembalikan titik hitam ke nol, **hanya pada frame yang
terukur berkabut**. Gerbangnya yang jadi fiturnya: enhancement tanpa syarat
justru menurunkan akurasi pada citra yang sudah jernih. Diverifikasi di repo
ini, lima foto kamera sehat semuanya dilewati dan skor deteksi tidak berubah
sama sekali.

Dipakai di dua tempat sekaligus, `nav_frame_converter.dart` dan
`tflite_service.dart`, supaya keempat model navigasi melihat frame yang identik.
Diuji di `test/luma_contrast_test.dart`.

> Peregangan linier, bukan CLAHE. CLAHE butuh histogram per ubin dan buffer
> tambahan tiap frame; konversi di sini sudah berupa pemetaan indeks satu
> lintasan tanpa gambar antara, dan biaya membongkarnya mendarat persis di
> ponsel lama yang jadi sasarannya.

**Prosesor yang tidak mengejar.** Tiga model per frame di ponsel lama bisa
berkali lipat lebih lambat. Yang berbahaya bukan lambatnya, melainkan diamnya:
arahan tetap diucapkan dengan nada yakin dari pemandangan beberapa detik lalu,
sementara pengguna sudah melangkah melewatinya.

`device_pace_watch.dart` bertindak berurutan dari yang paling tidak mengganggu:
ukur rata-rata bergerak, matikan lapis COCO di atas 1200 ms, baru beri tahu
pengguna di atas 2500 ms. Yang dikorbankan COCO, bukan PIDNet atau YOLO, karena
hanya COCO yang menambah cakupan tanpa menopang mode ini.

Ini tidak bertabrakan dengan aturan "keempat lapis wajib" di bagian 3. Yang
wajib adalah **termuat saat mode dinyalakan**; yang dimatikan pengawas ini
adalah **pemanggilan per frame** sesudah mode berjalan dan terbukti tidak
mengejar. Menolak menyalakan mode karena satu lapis tidak ada, dan menurunkan
beban karena ponselnya kewalahan, adalah dua keputusan berbeda.

Efek sampingnya menutup kebutuhan sensor termal: saat ponsel panas dan
prosesornya diturunkan, durasi siklus naik dan mekanisme yang sama bekerja.
Diuji di `test/device_pace_watch_test.dart`.

> **Catatan yang belum digarap:** di Mode Navigasi tiga interpreter jalan
> paralel dengan `threads = 4 + 4 + 2`, sepuluh thread di atas prosesor yang
> mungkin cuma punya dua inti kuat. Pengawas di atas meredam gejalanya, tapi
> penyetelan thread-nya sendiri belum disentuh karena `TFLiteService` dipakai
> bersama Mode Deteksi Objek yang justru butuh empat thread.

### Kesiapan Play Store (.aab)

| Syarat | Status |
|---|---|
| `targetSdk` 35 atau lebih (wajib sejak Agustus 2025) | 36 |
| `minSdk` | 26 |
| Alignment halaman 16 KB untuk pustaka native (wajib untuk target Android 15+) | Semua `.so` arm64 sudah `0x4000` atau `0x10000` |
| NDK | r28 (`28.2.13676358`), 16 KB by default |
| `blobs/libtensorflowlite_c-linux.so` ikut ke bundle? | **Tidak.** Ia pustaka desktop untuk `flutter test`, tidak terdaftar di `pubspec.yaml` bagian assets |
| Model tak terpakai ikut ke APK? | Tidak. Assets disebut satu per satu, bukan `- assets/models/` |

Verifikasi ulang alignment kapan saja:

```bash
for so in $(find build -path "*arm64-v8a*" -name "*.so"); do
  echo "$(basename $so) $(readelf -lW $so | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' ')"
done
```

Nilai apa pun di bawah `0x4000` akan ditolak Play Store untuk target Android 15+.

---

## 4. Intent parsing lokal: CommandParser

`lib/core/voice/command_parser.dart`

Mencocokkan ucapan pengguna ke 24 intent baku (enum `VoiceIntent`)
**sepenuhnya offline, 0 ms**.
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

**Tidak ada jalur server sama sekali.** `POST /api/intent` sudah dihapus dari
backend; kalau parser lokal tidak bisa menentukan, ia menawarkan dua tebakan
terdekat langsung dari perangkat ("Saya dengar ... Maksudmu A, atau B?").

Tebakan itu hanya boleh diambil dari `suggestableIntents`, yaitu intent yang
**benar-benar punya handler**. Sebelumnya seluruh isi kamus bisa disarankan,
termasuk intent tanpa handler, sehingga aplikasi bisa bertanya "Maksudmu
jeda?", pengguna menjawab "jeda", dan jawabannya "Perintah itu belum saya
kenali di mode ini". Lingkaran buntu yang diciptakan aplikasi sendiri, dan
pengguna tunanetra tidak punya layar untuk keluar darinya.

### Urutan lapis menentukan, bukan sekadar rapi

Frasa multi-kata diperiksa **sebelum** kata tunggal, dan yang terpanjang lebih
dulu. Di sinilah "stop navigasi" menemukan `actionStopWalking` sebelum kata
"stop" sempat membawanya ke `actionGoBack`. Versi lama memakai `contains`
mentah dan menelusuri kamus mengikuti urutan deklarasi, sehingga "stop
navigasi" justru **mengeluarkan pengguna dari Mode Navigasi**.

Pola cari-objek dinamis juga sengaja diletakkan sebelum kata tunggal: "cari
uang yang jatuh" harus berarti mencari benda, bukan membuka Mode Kenali Uang
hanya karena kata "uang" muncul di dalamnya.

### Penyaringan frasa benda: `normalizeSearchPhrase()`

Mode Cari Objek memakai YOLOE open-vocabulary, yang menerima **prompt teks
bebas** lewat encoder teks MobileCLIP. Sifat itu yang membuat penyaringan di
sini bukan soal kerapian: encoder mencocokkan **seluruh frasa** dengan isi
gambar, bukan kata kuncinya saja. Prompt `please find my red bag` mencari
sesuatu yang serentak cocok dengan "please", "find", DAN "bag" - dan tas yang
sebenarnya ada tepat di depan pengguna dilaporkan tidak ketemu.

Jadi setiap kata yang lolos **mempersempit** hasil, bukan memperjelasnya.
Lima tahap, berurutan:

| Tahap | Membuang | Contoh |
|---|---|---|
| 1 | Kata pembuka (`searchPrefixes` + `changeTargetPrefixes`) | `tolong carikan tas merah` → `tas merah` |
| 2 | Basa-basi (`fillerWords`) dan derau frasa benda | `botol minum warna biru` → `botol minum biru` |
| 3 | Potong di penanda tempat/waktu dan kata kerja simpan | `kunci yang saya taruh di meja` → `kunci` |
| 4 | Kata yang tidak menunjuk benda apa pun | `barangnya` → *(kosong)* |
| 5 | Batas empat kata | |

Tahap 1 mengambil sisa kalimat **sesudah** kata pembuka, bukan menghapus kata
pembukanya di tempat. Bedanya nyata pada ucapan koreksi: `bukan itu, cariin
keyboard`. Menghapus "cariin" saja menyisakan `bukan itu keyboard`, dan "bukan"
ikut jadi `not` di prompt YOLOE.

String kosong berarti **jangan kirim apa pun** - pengguna belum menyebutkan
barangnya, dan memindai kata "itu" cuma menghasilkan "tidak ketemu" yang
terdengar seperti barangnya tidak ada.

Fungsinya sengaja **mandiri dan idempoten**, tidak mengandalkan pemanggilnya
sudah bersih. `_target` bisa datang dari tiga jalur - perintah suara global,
tombol "Ganti barang" di layar, dan target tersimpan saat offline - dan hanya
dua di antaranya yang sudah lewat pengupas kata pembuka.

### Dari frasa Indonesia ke prompt YOLOE

Hasil penyaringan diterjemahkan ML Kit on-device (`TranslationService.
toEnglish`), lalu dikirim ke backend sebagai field **terpisah** `prompt_en` -
`target` tetap Bahasa Indonesia karena nilainya yang dibacakan kembali ke
pengguna ("Ada 2 tas merah, yang terdekat di kiri").

Di backend, `resolve_prompt()` memakainya sebagai **lapis kedua**, bukan
pengganti kamus:

1. **Kamus kurasi** (`EXTRA_ID_TO_EN`) menang duluan. Isinya dipilih supaya
   cocok dengan kosakata encoder teks YOLOE: `hape` → `cell phone`, bukan
   `cellphone`; `gawai` → `cell phone`, bukan `gadget`.
2. **Terjemahan ML Kit** untuk yang tidak ada di kamus. Di sinilah janji
   open-vocabulary baru ditepati: `irus` → `ladle`, `cobek` → `mortar`.
3. Tebakan substring, lalu frasa Indonesianya apa adanya.

Sebelum lapis 2 ada, kata di luar kamus jatuh ke lapis 3 dan berakhir sebagai
prompt **Bahasa Indonesia** yang dikirim ke encoder berbahasa Inggris - bukan
pencarian yang kurang akurat, melainkan pencarian yang tidak pernah punya
peluang. Pengguna cuma mendengar "tidak ketemu", tanpa satu pun petunjuk bahwa
yang salah adalah promptnya, bukan barangnya.

Terjemahannya dimulai saat target **ditetapkan**, bukan saat tombol kirim
ditekan: di antara keduanya ada konfirmasi suara beberapa detik yang sudah
dibayar. Kalau belum selesai dalam 2 detik saat tombol ditekan, `prompt_en`
tidak dikirim dan backend memakai kamusnya - hasilnya lebih kasar, bukan gagal.

---

## 5. Narasi lokal

**100% offline, tanpa LLM, tanpa server.** Menggantikan `POST /api/narasi` yang
sebelumnya bergantung pada Qwen di backend.

Ada **dua** berkas di sini, dan hanya satu yang benar-benar dipakai jalur
deteksi realtime.

### 5a. `narration_scheduler.dart` (yang aktif)

Inilah yang dipanggil `DetectionProvider`. Ia memutuskan **kapan** bicara dan
**berapa banyak yang muat** dalam satu ucapan.

Keduanya tidak bisa dipisah: scheduler punya **anggaran kata**, dan anggaran
itulah yang menjaga satu ucapan tetap sekitar empat detik. Tanpanya, momen mode
baru menyala jadi masalah: saat itu setiap objek adalah objek baru, tidak satu
pun punya catatan cooldown, jadi semuanya lolos sekaligus. Enam objek berarti
enam narasi dalam waktu kurang dari satu detik, dan narasi yang kalah rebutan
hilang tanpa jejak tanpa pengguna pernah tahu.

### 5b. `narration_engine.dart` (ada, tapi TIDAK dipanggil)

Berkas ini masih di repo dan gaya naratifnya enak didengar. Ia **sengaja tidak
dihapus**, tapi juga tidak dipakai jalur deteksi realtime: satu klausanya saja
sudah menghabiskan hampir seluruh anggaran kata scheduler.

Gaya itu cocok untuk narasi **yang diminta** pengguna, saat ia sudah siap
mendengarkan; bukan untuk aliran deteksi yang datang tanpa diminta delapan kali
per detik. Kalau suatu saat ada tombol "ceritakan sekitarku", di sanalah
tempatnya.

### API `narration_engine`

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

### 5c. Deskripsi suasana: `translation_service.dart`

`POST /api/describe` mengembalikan `description_en`, caption Bahasa Inggris
dari Moondream2 - modelnya memang hanya bisa berbahasa Inggris. **Flutter
menerjemahkannya di perangkat** sebelum dibacakan, lewat Google ML Kit
On-Device Translation (`google_mlkit_translation`).

```dart
final translated = await TranslationService.instance.toIndonesian(captionEn);
final speakInEnglish = translated == null;

if (speakInEnglish) {
  await TtsQueue.instance.speak('Dalam bahasa Inggris.');   // penanda
}
await TtsQueue.instance.speak(
  translated ?? captionEn,
  english: speakInEnglish,   // id-ID kalau berhasil, en-US kalau menyerah
);
```

Prinsipnya sama dengan yang membuat `narration_scheduler` dan `CommandParser`
menggantikan Qwen: penerjemahannya berjalan **penuh di perangkat**, tidak
menyentuh jaringan saat dipakai, dan tidak mengarang isi baru. Menambahkan LLM
penerjemah akan mengembalikan tepat tiga masalah yang sudah dibuang: lambat,
bisa berhalusinasi, dan butuh server.

Model kedua bahasa (~30 MB per bahasa) diunduh **sekali** di latar belakang
saat aplikasi pertama kali dibuka - `main()` memanggil `prewarm()` tanpa
`await`, jadi tidak ada yang menunggu. `isWifiRequired` sengaja `false`,
berlawanan dengan default ML Kit: default itu berarti unduhannya diam-diam
tidak pernah terjadi pada pengguna yang hanya punya data seluler, dan mereka
justru mayoritas target aplikasi ini.

Kalau modelnya belum siap, unduhannya gagal, atau terjemahannya tidak layak,
`toIndonesian` mengembalikan **null** - tidak pernah setengah kalimat - dan
kalimat Inggrisnya dibacakan, didahului satu penanda singkat supaya pengguna
tahu bahasanya berganti dan tidak menyangka aplikasinya rusak. Deskripsi
Inggris yang benar lebih berguna daripada keheningan.

Pendahulunya, `core/voice/scene_translator.dart`, adalah kamus kata-per-kata
buatan sendiri. Berkas itu **sudah dihapus**. Cakupannya tidak konsisten: satu
foto diterjemahkan penuh, foto berikutnya setengah, foto ketiga menyerah - dan
pengguna yang mengandalkan telinga tidak punya cara menebak versi mana yang
sedang dia dengar. ML Kit menyelesaikan justru bagian itu: kalimat utuh atau
tidak sama sekali.

Sebelum keduanya, versi paling awal membacakan hasilnya langsung dalam Bahasa
Inggris tanpa penerjemahan sama sekali, yang menuntut kemampuan Inggris lisan
yang tidak bisa diasumsikan pada pengguna tunanetra di pasar dan warung
Indonesia.

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

### Komponen

Berada di `lib/widgets/`:

`ModeBadge`, `AlertCard`, `BottomActionBar`, `FullScreenButton`,
`ModePickerSheet`, `VoiceOrb`, `StatusBanner`, `ZoneIndicator`,
`ResultPanel`, `CameraHealthToast`, `ChatBubble`, `NominalCard`,
`TargetChip`, `SpeakingIndicator`, `PermissionCard`, `CameraStage`,
`DetectionOverlay`, `SegmentationOverlay`, `DetectionCard`,
`DetectionStatusPill`, `DistancePill`, `TierIcon`, `ContextualActionSlot`,
`PageActionZone`, `OcrLongResultPanel`, `OcrDebugSheet`, `SheetHeader`,
`TorchSlot`, `HoldToTalkGesture`, `HoldToTalkButton`.

`CameraStage` layak disebut khusus: preview kamera dan hamparannya wajib
berbagi persegi yang sama persis. `CameraPreview` menjaga rasio kamera dan
tidak benar-benar mengisi layar, jadi hamparan yang dipasang dengan
`Positioned.fill` akan memetakan koordinatnya ke area yang lebih besar daripada
gambarnya, dan setiap kotak deteksi meleset dari objeknya.

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
**aksi utama mode** di kiri, **Bicara** di tengah, **Pilih mode** di kanan.
Urutan fokus 7-8-9 dipasang eksplisit lewat `OrdinalSortKey`, supaya reposisi
tombol di layar lain tidak pernah menggeser urutan ketiganya. Kekekalan itu
satu-satunya peta yang dimiliki pengguna.

Yang berubah hanyalah **label** tombol kiri, mengikuti mode yang aktif (lihat
tabel kontrak tombol kiri di bagian 2). Labelnya wajib kata kerja ditambah
objek, maksimal tiga kata, karena TalkBack membacanya tiap fokus mendarat.

Saat mic sedang mendengarkan, dua tombol samping dinonaktifkan supaya tidak ada
aksi yang bertabrakan sambil berjalan.

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
- **Label menyebut aksi, bukan alat**: "Kenali Uang", bukan "Kamera".
- **Label tidak menyebut lokasi layar**: tidak ada "tombol di kanan bawah".
- Tombol nonaktif **menyebutkan alasannya**, dan bersuara saat ditekan:
  "Kirim, cari barang, tidak tersedia, tekan tombol bicara lalu sebutkan
  barangnya".
- Elemen dekoratif disembunyikan dari pembaca layar.
- **Tidak pernah mengonfirmasi sesuatu yang tidak terjadi.** Perpindahan mode
  memindahkan state lebih dulu; kata "Baik." dititipkan sebagai prefiks
  pengumuman kedatangan, jadi ia baru terdengar setelah layar tujuan
  benar-benar terpasang. Kalau perpindahannya dibatalkan, yang diucapkan adalah
  keadaan sebenarnya ("Tetap di mode Navigasi"), bukan konfirmasi.

### Ukuran huruf 200 persen

Berlaku ke seluruh aplikasi. Tata letak berubah dari mendatar menjadi
menurun, dan target sentuh membesar dari 48 menjadi 56 dp.

---

## 11. Struktur folder

```
lib/
├── main.dart                 Titik masuk, mendaftarkan seluruh provider
├── core/
│   ├── layout/               zone_contract.dart, ukuran zona dan aturan pergeseran
│   ├── speech/               tts_queue.dart, antrean suara bertingkat
│   ├── state/                global_conditions.dart, kondisi global jadi satu banner
│   ├── net/
│   │   ├── api_client.dart           Klien HTTP + FramePacer
│   │   └── frame_codec.dart          Encoding frame sebelum dikirim
│   └── voice/
│       ├── intents.dart              Enum VoiceIntent (24 intent baku)
│       ├── command_parser.dart       Pencocokan ucapan offline, berlapis
│       ├── narration_scheduler.dart  Kapan bicara + anggaran kata (AKTIF)
│       ├── narration_engine.dart     Narasi bergaya panjang (tidak dipanggil)
│       └── voice_log.dart            Jejak ucapan untuk penyelidikan
├── models/                   detection.dart, tipe hasil deteksi bersama
├── theme/                    Warna, tipografi, jarak, tema
├── widgets/                  Komponen sistem desain
├── providers/                State per mode, pengaturan, kondisi global
├── services/
│   ├── tflite_service.dart       Deteksi rintangan on-device (SSD MobileNet)
│   ├── money_tflite_service.dart Pengenalan uang on-device (MobileNetV2 INT8)
│   ├── pidnet_service.dart       Segmentasi jalur 3 zona on-device
│   ├── yolo_navigasi_service.dart Rintangan navigasi FP16 NHWC (lapis 2)
│   ├── yolo_nav_int8_service.dart Rintangan navigasi INT8 NCHW (lapis 4)
│   ├── nav_obstacle_merger.dart  Saring COCO + gabung tanpa sebutan ganda
│   ├── device_pace_watch.dart    Turunkan beban saat ponsel tidak mengejar
│   ├── luma_contrast.dart        Perbaikan kontras selektif kamera lama
│   ├── nav_frame_converter.dart  Satu lintasan isolate untuk tensor nav
│   ├── ocr_service.dart          Baca teks on-device (ML Kit)
│   ├── camera_capture_service.dart Kunci fokus, pilih frame tertajam, gerbang gelap
│   ├── camera_health_service.dart  Orientasi dan guncangan dari accelerometer
│   ├── camera_intrinsics.dart    Panjang fokus untuk perkiraan jarak
│   ├── server_service.dart       Panggilan backend yang tersisa
│   ├── tts_service.dart          Mesin suara, ucapan diserialkan
│   ├── translation_service.dart  Terjemah dua arah lewat ML Kit on-device
│   ├── detection_filter.dart     Penyaring anti banjir suara
│   ├── object_tracker.dart       Pelacak SORT, penghalus jarak
│   └── haptic_service.dart       Pola getar
├── screens/                  6 mode + splash, panduan, izin, pengaturan, alamat server
└── mock/                     Data tiruan untuk panel debug
```

`TranslationService` dipakai dua arah: `toIndonesian` untuk caption Moondream2,
`toEnglish` untuk menyusun `prompt_en` Mode Cari Objek.

> `object_label_map.dart` sudah **dihapus**. Ia tidak pernah punya satu pun
> import aktif.

---

## 12. Menjalankan

```bash
flutter pub get
flutter run
```

Aplikasi tetap jalan tanpa backend. Empat dari enam mode berfungsi **penuh**
tanpa internet: Deteksi Objek, Kenali Uang, Baca Teks, dan Navigasi. Begitu
juga intent parsing dan narasi deteksi. Uji dengan WiFi dan data seluler
dimatikan total untuk membuktikannya.

Yang benar-benar mati offline hanya **Cari Objek**. Deskripsi suasana di Mode
Asisten Suara juga butuh server, tapi perintah dan perpindahan mode di mode itu
tetap jalan.

Panduan uji manual langkah demi langkah, lengkap dengan apa yang harus
diucapkan dan apa yang seharusnya terdengar, ada di
[`../VERIFIKASI_FITUR.md`](../VERIFIKASI_FITUR.md).

Alamat server bawaan adalah `127.0.0.1:8000` (`kDefaultServerHost` di
`services/server_service.dart`), yaitu server yang berjalan di perangkat yang
sama. **Untuk emulator maupun HP fisik**, ubah lewat layar Pengaturan: ucapkan
"pengaturan" atau ketuk Pilih Mode lalu Pengaturan.

Alamat yang pernah disimpan **selalu menang** atas nilai bawaan, jadi mengubah
konstanta itu hanya berpengaruh pada pemasangan baru.

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
- Model TFLite **wajib** dijalankan lewat `IsolateInterpreter`.
- Peringatan bahaya **selalu** memotong suara lain, **kecuali** peringatan
  bahaya lain yang belum selesai diucapkan.
- Pelacak SORT harus direset saat berganti mode.
- TTS default `id-ID`. `speakEnglish()` mengganti locale sementara lalu
  mengembalikannya di blok `finally`, jadi kegagalan di tengah tidak
  meninggalkan aplikasi berbicara Inggris selamanya.
- **Mengganti preset kamera akan membangun ulang controller.** `initCamera`
  menyalakan kembali aliran frame kalau sebelumnya mengalir. Jangan menghapus
  perilaku itu: tanpanya, apa pun yang mengganti preset di tengah mode aliran
  akan meninggalkan kamera mati tanpa ada yang menyalakannya lagi, dan Mode
  Deteksi berhenti memperingatkan rintangan tanpa sepatah kata.
- **Mode foto wajib meminta presetnya di `initState`**, bukan hanya saat status
  izin berubah. Cabang perubahan izin tidak pernah jalan kalau izinnya sudah
  lama diberikan, dan modenya akan memotret pada 640x480.

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
| Backend di perangkat yang sama | `127.0.0.1:8000` (bawaan) |
| Emulator Android di laptop | `10.0.2.2:8000` |
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

Karena itu `test/money_pipeline_test.dart` punya uji prasyarat yang **gagal**,
bukan skip, ketika runtime TFLite tidak ada. Untuk sengaja melewatinya
(misalnya CI yang memang hanya memeriksa lint), pakai
`GUIDIO_ALLOW_SKIP_TFLITE=1`, dengan kesadaran penuh bahwa suite itu tidak
memvalidasi model sama sekali.

Ada prasyarat kedua yang lebih baru, *runtime bisa menjalankan model
terkuantisasi*, dan di host Linux ia **memang merah**. Runtime desktop di
`blobs/` tidak sanggup menjalankan model INT8 yang sekarang dibundel; lihat
bagian 3. Merahnya itu yang menjaga kelompok B tidak salah dibaca sebagai
"model rusak".

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

| Kelompok | Yang dijaga | Status di host Linux |
|---|---|---|
| **A. KEAMANAN** | Tidak pernah yakin tapi salah. Nominal yang tidak lolos gerbang tidak boleh dibacakan dengan nada lugas | 5/5 hijau |
| **B. KEMAMPUAN** | Tebakan teratas harus benar, dan nominalnya harus lolos gerbang yakin | **10/10 merah** |
| **C. PARITAS** | Jalur kamera dan jalur JPEG harus sepakat | 5/5 hijau |
| **D. KONTRAK** | Urutan kelas cocok dengan `rupiah_class_info.json`, ground-truth fixture bisa diurai | 2/2 hijau |

Kelompok B adalah **ratchet yang sengaja dibiarkan merah**. Jangan dilonggarkan
supaya hijau. Tapi bacalah merahnya dengan benar: di host Linux ia merah karena
**dua** sebab yang bertumpuk, dan cuma satu yang soal model.

1. Runtime desktop tidak bisa menjalankan model INT8, jadi kelima fixture
   pulang sebagai Rp1.000 dengan keyakinan 14,5 persen, yaitu chance level
   untuk 7 kelas. Ini bukan pengukuran model.
2. Modelnya sendiri memang belum tangguh pada framing kamera. Itu diukur di
   Android atau lewat `tool/eval_rupiah_litert.py`, bukan di sini.

Yang dinaikkan adalah modelnya, lihat bagian 3.

Kelompok C bukan formalitas. Kedua jalur masuk punya praproses terpisah dan
pernah memakai aturan crop yang berbeda, sehingga lembar yang sama bisa
menjawab lain tergantung tombol mana yang ditekan. Kegagalan seperti itu
mustahil didiagnosis dari laporan pengguna. Sekarang keduanya memakai frame
utuh, dan kelompok inilah yang menjaganya tetap begitu.

Fixture yang dipakai:

```
test/fixtures/
├── money_new/      2 tangkapan layar ponsel 720x1560 (uang kecil, tertimpa overlay UI)
├── money_new2/     3 foto biasa 900x1600 (uang mengisi hampir selebar frame)
├── money/          14 JPEG lama, kini tidak dipakai suite mana pun
├── rupiah_mobile/  Foto HP untuk tool/eval_rupiah_litert.py
│   ├── foto_rupiah/  8 foto berlabel (5rb sampai 50rb, dua sudut per pecahan)
│   ├── 20_ribuan/    6 foto satu pecahan, variasi jarak dan cahaya
│   └── non_rupiah/   6 foto bukan uang, untuk menguji penolakan
├── navigation/     5 PNG bahaya jalan
└── object_find/    5 PNG benda, dipakai juga oleh pytest backend
```

`backend/tests/` tidak punya folder `fixtures/` sendiri: `conftest.py` mencari
`backend/tests/fixtures/` lebih dulu, dan karena tidak ada, ia jatuh ke
`guidio_app/test/fixtures/`. Jadi kedua sisi menguji gambar yang sama persis.

Ground-truth diambil dari nama berkas lewat regex (`5000.png` dan `5rb.png`
sama-sama berarti Rp5.000). Tidak ada tabel hard-coded: kalau nama berkas
menyimpang, regex gagal dan test langsung merah alih-alih diam-diam menguji
hal yang salah.

### B. Uji lain

```bash
flutter test                                     # semua, 26 berkas
flutter test test/command_parser_test.dart       # parsing perintah suara, tanpa model
flutter test test/model_inference_test.dart      # inferensi YOLO navigasi
flutter test test/nav_pipeline_test.dart         # bentuk dan rentang tensor navigasi
flutter test test/nav_obstacle_merger_test.dart  # gabung YOLO custom + COCO
flutter test test/device_pace_watch_test.dart    # penurunan beban di ponsel lama
flutter test test/luma_contrast_test.dart        # gerbang perbaikan kontras
flutter test test/translation_service_test.dart  # ML Kit menyerah dengan jujur
flutter test test/voice_gate_test.dart           # jawaban asisten tidak dibuang
```

Selebihnya menguji alur dan kelas murni tanpa model: `mode_switch_guard_test`,
`nav_phase_flapping_test`, `nav_card_identity_test`, `nav_guidance_wording_test`,
`find_object_prompt_filter_test`, `find_object_announce_test`,
`scene_plausibility_test`, `stt_locale_test`, `tts_answer_now_test`,
`onboarding_flow_speech_test`, `permissions_flow_test`,
`server_address_ready_test`, `detection_overlay_test`,
`narration_scheduler_test`, `nav_pipeline_bench_test`.

Polanya sama seperti `assessScene`: logika yang menentukan apakah pengguna
diberi tahu bahwa panduannya tertinggal, atau apakah sebuah bahaya disebut dua
kali, tidak boleh cuma dibuktikan lewat uji lapangan.

### C. Pipeline visual: `test/run_corridor_test.py`

Di luar folder ini, di root repo, ada runner Python yang menjalankan **ketiga
model sekaligus** pada gambar diam lalu menghasilkan gambar ter-anotasi:
segmentasi jalur, kotak rintangan bertanda sumber (`[YOLO]` atau `[COCO]`),
status tiga zona, dan kalimat arahan yang benar-benar akan diucapkan.

```bash
test/.venv/bin/python test/run_corridor_test.py                    # koridor indoor
test/.venv/bin/python test/run_corridor_test.py \
    --src project/guidio_app/test/fixtures/navigation \
    --out test/navigation/results_fixtures --summary summary_fixtures.txt
```

Konstantanya sengaja disalin dari sisi Dart, bukan dikira-kira, dan berkasnya
menyebutkan dari mana tiap angka berasal. Kalau salah satu berubah di Dart,
berkas itu ikut berubah; kalau tidak, yang diuji di sana bukan lagi yang
berjalan di ponsel.

Opsi yang berguna untuk menyelidiki:

| Opsi | Gunanya |
|---|---|
| `--enhance off\|auto\|always` | Ukur dampak perbaikan kontras kamera lama |
| `--resize stretch\|letterbox` | Bandingkan cara memasang bingkai ke tensor |
| `--yolo <berkas>` | Bandingkan model YOLO kandidat |

`test/model_inference_test.dart` sekarang **hanya** menguji navigasi. Kelompok
uangnya dihapus karena dua cacat yang membuatnya tidak bisa merah:

1. Ia membangun praprosesnya sendiri dengan
   `img.copyResize(source, width: 224, height: 224)`, yaitu **peregangan** ke
   persegi tanpa letterbox. Model dilatih dengan `resize_with_pad` dan
   aplikasi memakai letterbox atas frame utuh. Jadi suite itu mengukur
   pipeline yang tidak pernah dijalankan siapa pun.
2. Assert-nya dibungkus `if (confidence >= 0.85) { ... } else { print(...) }`.
   Karena model jarang menembus 0,85, cabang assert tidak pernah dieksekusi.

Kelompok uang di `test/command_parser_test.dart` juga dihapus. Ia sudah
memanggil `classifyJpeg`, tapi assert-nya dibungkus `if (result.detected)`
sehingga tidak pernah bisa merah. Tempatnya juga keliru: berkas itu menguji
parsing perintah, dan menumpang inferensi model di sana membuat kegagalan
model menyamar jadi kegagalan parser.

### Hasil terakhir

```
278 passed, 24 skipped, 15 failed
```

Kelima belas yang merah, dan sebabnya masing-masing:

| Jumlah | Berkas | Sebab |
|---|---|---|
| 1 | `money_pipeline_test.dart` prasyarat | Runtime desktop tidak sanggup menjalankan model INT8. **Ini soal runtime, bukan model.** Lihat bagian 3 |
| 10 | `money_pipeline_test.dart` kelompok B | Akibat langsung dari baris di atas: seluruh fixture pulang di chance level. Angka model yang sebenarnya diukur lewat `tool/eval_rupiah_litert.py` atau di Android |
| 4 | `model_inference_test.dart` kelompok B | `yolo11n_navigasi.tflite` tidak mendeteksi satu pun label yang diharapkan pada 4 dari 5 fixture navigasi |

Empat kegagalan navigasi itu **temuan lama yang akhirnya terlihat**, bukan
regresi baru. Ia tersembunyi di balik skip selama runtime TFLite belum
terpasang. Uji itu hanya menguji lapis FP16; lapis INT8 (`yolo11n.tflite`) yang
sekarang menambalnya belum punya uji sendiri.

---

### D. Python visual test lama (per model, bukan pipeline)

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
