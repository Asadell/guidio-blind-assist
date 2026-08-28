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
| Navigasi jalur 3 zona (tiga model) | `services/pidnet_service.dart`, `services/yolo_navigasi_service.dart`, `services/tflite_service.dart` |
| Intent parsing (20 mode + aksi) | `core/voice/command_parser.dart` |
| Penjadwalan dan penyusunan narasi | `core/voice/narration_scheduler.dart` |

Hanya dua hal yang butuh server: **Cari Objek** (YOLOE) dan **deskripsi
suasana** (Moondream2). Sisanya tidak pernah memanggil backend sama sekali.

---

## Daftar isi

1. [Cara kerja singkat](#1-cara-kerja-singkat)
2. [Enam mode dan layarnya](#2-enam-mode-dan-layarnya)
3. [Empat model AI di dalam ponsel](#3-empat-model-ai-di-dalam-ponsel)
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
| Navigasi | `screens/navigasi_screen.dart` | Tidak, tiga model on-device |
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

## 3. Empat model AI di dalam ponsel

Daftar aset di `pubspec.yaml` menyebut model **satu per satu**, bukan seluruh
direktori. Ini disengaja: `- assets/models/` akan ikut membundel semua yang
kebetulan ada di folder itu, termasuk berkas percobaan yang tidak pernah dimuat
kode. Untuk pengguna dengan kuota terbatas, itu ratusan megabyte yang dibayar
tanpa satu pun manfaat.

| Berkas | Ukuran | Dipakai oleh |
|---|---|---|
| `ssd_mobilenet.tflite` | ~4,0 MB | Deteksi rintangan |
| `rupiah_classifier_fp16.tflite` | ~4,6 MB | Kenali Uang, 7 pecahan |
| `pidnet_s_3zona.tflite` | ~2,5 MB | Segmentasi jalur 3 zona |
| `yolo11n_navigasi.tflite` | ~10,1 MB | Rintangan navigasi, 6 kelas |
| **Total di APK** | **~21,2 MB** | ditambah `labelmap.txt` |

> Baca Teks tidak punya berkas model di daftar ini: Google ML Kit membawa
> mesinnya sendiri lewat Play Services.

### Berkas yang ADA di folder tapi sengaja tidak dibundel

| Berkas | Kenapa tidak ikut |
|---|---|
| `yolo11n.tflite` | Bentuk inputnya NCHW `[1,3,640,640]`, sementara `YoloNavigasiService` menyusun NHWC `[1,640,640,3]`. Interpreter menolaknya dan deteksi rintangan mengembalikan daftar kosong **pada setiap frame tanpa tanda apa pun** |
| `pidnet_s_3zona_fp16.tflite` | Tensor masukannya FLOAT16 sementara seluruh pipeline menghasilkan FLOAT32, jadi ia tidak akan pernah bisa dipakai. Dulu ia dicoba lebih dulu dan hanya dilewati kalau berkasnya hilang, sehingga segmentasi jalur gagal di setiap frame tanpa satu pun tanda di layar |
| `uang_rupiah.tflite`, `rupiah_classifier_int8.tflite` | Arsip model uang lama |
| `yoloe_find.onnx`, `pidnet_s*.onnx` | Sisa percobaan, tidak dimuat kode mana pun |

Dua baris pertama tabel itu adalah kelas kegagalan yang sama, dan keduanya
pernah terjadi: model salah bentuk **tidak melempar error**, ia cuma
mengembalikan hasil kosong selamanya. `PidnetService.tryLoad` sekarang
membuktikan tiap varian dengan inferensi percobaan sebelum menerimanya.

### Model deteksi rintangan

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/ssd_mobilenet.tflite` |
| Ukuran masukan | 300 x 300 piksel |
| Kecepatan | sekitar 30 milidetik per gambar |
| Laju | `FramePacer` 120 ms, sekitar 8 fps |
| Dijalankan di | `IsolateInterpreter`, supaya layar tidak macet |

### Mode Navigasi memakai TIGA model, bukan dua

| Lapis | Model | Yang hanya bisa dilihat lapis ini |
|---|---|---|
| Jalur | PIDNet-S | Zona kiri, tengah, kanan; permukaan layak jalan |
| Bahaya jalanan | YOLO11n custom | `lubang`, `got_terbuka`, `tangga` |
| Benda umum | SSD MobileNet COCO | `orang`, `motor`, mobil, sepeda, anjing, perabot jalan |

Ketiganya jalan paralel dari **satu frame yang sama**. Frame yang sama itu
syarat, bukan penghematan: kalau salah satunya terlambat satu frame, pengguna
bisa mendengar "jalur tengah aman" bersamaan dengan "ada motor di depan" dari
pemandangan yang sudah lewat.

Lapis COCO **tidak ikut menentukan** `_modelsReady`. Kalau SSD gagal dimuat,
panduan jalur dan enam kelas custom tetap jalan penuh. Menjatuhkan seluruh mode
karena lapisan tambahan gagal berarti menukar fungsi yang masih sehat dengan
layar mati.

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
| Rintangan | YOLO11n, 6 kelas: lubang, got_terbuka, tangga, orang, motor, tiang |
| Laju | Timer 500 ms ditahan `FramePacer` 700 ms, efektif sekitar 1,4 fps |
| Ambang | `lubang` dan `got_terbuka` 5%; kelas lain 30% |

Kalau YOLO tidak mendeteksi apa pun, PIDNet-S tetap jadi lapis pengaman lewat
penurunan rasio area walkable. Lihat bagian 14 soal seberapa sering itu yang
benar-benar terjadi.

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

### Anggaran kinerja dan RAM

Target perangkat: RAM 3 sampai 4 GB. Di kelas itu yang membunuh kelancaran
bukan kecepatan CPU, melainkan **tekanan garbage collector**. Setiap alokasi
besar yang berulang memicu GC pause, dan karena antrean suara dijadwalkan dari
thread UI, GC pause muncul sebagai TTS yang tersendat. Bagi pengguna tunanetra
suara yang patah lebih merusak daripada gambar yang patah.

Empat jalur inferensi kini memakai pola yang sama:

| Service | Buffer masukan | Interpreter |
|---|---|---|
| `tflite_service` (SSD rintangan) | `Uint8List` datar | `IsolateInterpreter` |
| `yolo_navigasi_service` | datar | `IsolateInterpreter` |
| `pidnet_service` | datar | `IsolateInterpreter` |
| `money_tflite_service` | `Float32List` datar | `IsolateInterpreter` |

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
`tflite_service.dart`, supaya ketiga model navigasi melihat frame yang identik.
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
`ResultPanel`, `CameraHealthToast`, `GuideFrame`, `ChatBubble`,
`NominalCard`, `TargetChip`, `SpeakingIndicator`, `PermissionCard`,
`CameraStage`, `DetectionOverlay`, `SegmentationOverlay`, `DetectionCard`,
`DistancePill`, `TierIcon`, `ContextualActionSlot`, `PageActionZone`,
`OcrLongResultPanel`, `OcrDebugSheet`.

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
│   ├── layout/               Ukuran zona dan aturan pergeseran
│   ├── speech/               Antrean suara bertingkat (TtsQueue)
│   ├── state/                Penggabungan kondisi global jadi satu banner
│   ├── net/                  ApiClient, FramePacer
│   └── voice/
│       ├── intents.dart              Enum VoiceIntent (20 intent baku)
│       ├── command_parser.dart       Pencocokan ucapan offline, berlapis
│       ├── narration_scheduler.dart  Kapan bicara + anggaran kata (AKTIF)
│       └── narration_engine.dart     Narasi bergaya panjang (tidak dipanggil)
├── theme/                    Warna, tipografi, jarak, tema
├── widgets/                  Komponen sistem desain
├── providers/                State per mode, pengaturan, kondisi global
├── services/
│   ├── tflite_service.dart       Deteksi rintangan on-device (SSD MobileNet)
│   ├── money_tflite_service.dart Pengenalan uang on-device (MobileNetV2)
│   ├── pidnet_service.dart       Segmentasi jalur 3 zona on-device
│   ├── yolo_navigasi_service.dart Rintangan navigasi on-device (YOLO11n custom)
│   ├── nav_obstacle_merger.dart  Saring COCO + gabung tanpa sebutan ganda
│   ├── device_pace_watch.dart    Turunkan beban saat ponsel tidak mengejar
│   ├── luma_contrast.dart        Perbaikan kontras selektif kamera lama
│   ├── nav_frame_converter.dart  Satu lintasan isolate untuk kedua tensor nav
│   ├── ocr_service.dart          Baca teks on-device (ML Kit)
│   ├── camera_capture_service.dart Kunci fokus, pilih frame tertajam, tolak buram
│   ├── camera_health_service.dart  Orientasi dan guncangan dari accelerometer
│   ├── server_service.dart       Dua panggilan backend yang tersisa
│   ├── tts_service.dart          Mesin suara, ucapan diserialkan
│   ├── translation_service.dart  Terjemah caption Moondream ke Indonesia (ML Kit)
│   ├── detection_filter.dart     Penyaring anti banjir suara
│   ├── object_tracker.dart       Pelacak SORT, penghalus jarak
│   └── haptic_service.dart       Pola getar
├── screens/                  6 mode + splash, panduan, izin, pengaturan
└── mock/                     Data tiruan untuk panel debug
```

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
flutter test test/nav_obstacle_merger_test.dart  # gabung YOLO custom + COCO
flutter test test/device_pace_watch_test.dart    # penurunan beban di ponsel lama
flutter test test/luma_contrast_test.dart        # gerbang perbaikan kontras
```

Tiga berkas terakhir menguji **kelas murni tanpa model**, mengikuti pola
`assessScene`: logika yang menentukan apakah pengguna diberi tahu bahwa
panduannya tertinggal, atau apakah sebuah bahaya disebut dua kali, tidak boleh
cuma dibuktikan lewat uji lapangan.

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
151 passed, 3 skipped, 10 failed
```

Sepuluh yang merah, semuanya nyata dan bukan masalah infrastruktur:

| Jumlah | Berkas | Sebab |
|---|---|---|
| 6 | `money_pipeline_test.dart` kelompok B | Model belum tangguh pada framing kamera, lihat bagian 3 |
| 4 | `model_inference_test.dart` kelompok B | Model navigasi YOLO tidak mendeteksi satu pun label yang diharapkan pada 4 dari 5 fixture. Baru terlihat sekarang karena sebelumnya selalu di-skip |

Empat kegagalan navigasi itu **temuan baru**, bukan regresi yang saya sebabkan.
Ia sudah ada sejak lama dan tersembunyi di balik skip.

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
