# Guidio - Response to Juri Challenge: Cross-Device Accuracy Consistency

> Dokumen ini dibuat dari pembacaan langsung atas tiga repo:
> `project/backend` (FastAPI), `project/guidio_app` (Flutter), serta dua repo training
> `new_training/rupiah_vision_revised` dan `new_training/guido_cv_training_revised`.
> Semua nomor baris dan nama file di bawah merujuk ke kode yang benar-benar ada,
> bukan rancangan.

---

## 1. Ringkasan Challenge

Juri mempertanyakan validitas klaim value proposition **"tetap berfungsi menyelamatkan tunanetra di area tanpa sinyal internet"** lewat empat poin:

| # | Poin juri | Inti keberatan |
|---|---|---|
| C1 | Ketergantungan penuh ke device saat offline | Semua inferensi jatuh ke CPU/GPU HP pengguna. Spek yang beda jauh berpotensi menghasilkan **akurasi tidak konsisten** |
| C2 | Belum ada strategi mitigasi spek device | Tidak ada spek minimum yang didefinisikan, tidak ada mekanisme memberi tahu user bahwa HP-nya tidak memenuhi syarat |
| C3 | Belum jelas perlu training/kalibrasi ulang per device | Perlukah beta testing di banyak HP untuk mengumpulkan data penyesuaian model terhadap variasi hardware? |
| C4 | Ini aplikasi safety-critical | Inkonsistensi antar device = risiko serius, bukan minor bug. Selisihnya antara "user terselamatkan" vs "user tersesat" |

**Posisi jawaban dokumen ini,** diringkas di depan supaya tidak tenggelam:

> Keberatan juri **benar sebagai risiko**, tetapi **salah sasaran sebagai mekanisme**.
> Yang bervariasi antar device di arsitektur Guidio saat ini **bukan akurasi model, melainkan latensi**.
> Akurasi model hari ini justru sudah deterministik lintas device, dan itu bisa dibuktikan dengan angka.
> Yang belum ada adalah **bukti terukurnya**, **batas bawah yang didefinisikan**, dan **cara memberi tahu pengguna saat batas itu terlampaui**.
> Tiga hal terakhir itulah yang harus dikerjakan, dan Bagian 4 menjelaskan caranya.

Pembedaan ini bukan pembelaan retoris. Konsekuensi teknisnya berbeda total: kalau masalahnya akurasi, obatnya training ulang per device (mahal, tidak dapat dipelihara, dan di aplikasi keselamatan justru merusak ketertelusuran model). Kalau masalahnya latensi, obatnya profiling + tiering + pengakuan jujur ke pengguna, yang jauh lebih murah dan justru **sudah setengah jalan ada di kode**.

---

## 2. Analisis Arsitektur Saat Ini

### 2.1 Peta besar: 4 dari 6 mode sudah 100% on-device

`lib/providers/app_mode_provider.dart:8` mendefinisikan enam mode:

```dart
enum AppMode { tuntun, money, ocr, navigasi, voice, findObject }
```

Pembagian server vs on-device dinyatakan eksplisit di `backend/main.py` (blok komentar sebelum `include_router`):

| Mode | Label UI | Tempat inferensi | Model |
|---|---|---|---|
| `tuntun` | Deteksi Objek | **On-device** | SSD MobileNet TFLite |
| `money` | Kenali Uang | **On-device** | MobileNetV2 TFLite (INT8) |
| `ocr` | Baca Teks | **On-device** | Google ML Kit Text Recognition |
| `navigasi` | Navigasi | **On-device** | PIDNet-S + YOLO11n FP16 + YOLO11n INT8 + SSD MobileNet |
| `voice` | Deskripsi Sekitar | Server | Moondream2 (VLM ~2 GB) |
| `findObject` | Cari Objek | Server | YOLOE open-vocabulary |

Router yang dulu ada di backend (`websocket`, `detect`, `ocr`, `uang`, `navigasi`) **sudah dihapus, bukan dinonaktifkan**. Komentar di `backend/main.py` menyebut alasannya dengan tepat:

> "Kalau fiturnya sudah ada di ponsel, backend tidak perlu menyediakannya lagi. Jalur ganda hanya menambah kode yang harus dijaga konsisten, dan menciptakan ketergantungan diam-diam pada laptop yang menyala di mode yang justru menyangkut keselamatan."

**Implikasi untuk juri:** klaim "tetap berfungsi tanpa internet" bukan klaim marketing yang ditempel belakangan. Itu keputusan arsitektur yang sudah dibayar dengan menghapus jalur server. Empat mode yang menyangkut keselamatan dan kemandirian harian (rintangan, uang, teks, jalur) tidak punya jalur server sama sekali untuk dijatuhi.

Yang hilang saat offline hanya dua: Deskripsi Suasana dan Cari Objek. Keduanya adalah fitur *kenyamanan*, bukan *keselamatan*, dan `CapabilitiesProvider` (`lib/providers/capabilities_provider.dart`) sudah mengumumkan ketidaktersediaannya **sebelum** pengguna menekan apa pun.

### 2.2 Model yang benar-benar dibundel

`guidio_app/assets/models/`:

| File | Ukuran | Dipakai di | Konfigurasi |
|---|---|---|---|
| `ssd_mobilenet.tflite` | 4,0 MB | Deteksi Objek + lapis 3 Navigasi | input `[1,300,300,3]` uint8, `threads = 4` |
| `yolo11n_navigasi.tflite` | 10,1 MB | Navigasi lapis 2 | FP16, NHWC `[1,640,640,3]`, 6 kelas, `threads = 4` |
| `yolo11n.tflite` | 2,9 MB | Navigasi lapis 4 | INT8, model navigasi 6 kelas, `threads = 4` |
| `pidnet_s_3zona_fp16.tflite` | 1,3 MB | Navigasi lapis 1 (kandidat 1) | `threads = 2`, coba GPU delegate |
| `pidnet_s_3zona.tflite` | 2,5 MB | Navigasi lapis 1 (kandidat 2) | idem |
| `rupiah_classifier_int8.tflite` | 2,8 MB | Kenali Uang | MobileNetV2, `[1,224,224,3]` float I/O, `threads = 2` |
| `rupiah_classifier_fp16.tflite` | 4,6 MB | **tidak dipakai** | tersedia tapi tidak pernah dimuat |
| `yoloe_find.onnx` | 11,0 MB | **tidak dipakai di app** | milik backend |

Total ~28 MB bobot model dalam APK, plus model ML Kit yang diunduh terpisah.

### 2.3 Alur data satu siklus Navigasi (mode terberat)

Ini mode yang paling relevan untuk challenge, karena real-time dan safety-critical.

```
CameraController (ResolutionPreset.medium)          camera_provider.dart:933
        │  CameraImage YUV420
        ▼
FramePacer.run(minInterval: 700 ms)                 navigation_provider.dart:221
        │  (Timer.periodic 500 ms → dipagari 700 ms)  navigation_provider.dart:486
        ▼
NavFrameConverter.prepare()  [compute / isolate]    nav_frame_converter.dart:169
        │  satu lintasan YUV → 2 tensor sekaligus:
        │    PIDNet  [1,3,384,640] normalisasi ImageNet
        │    YOLO    [1,640,640,3] rentang 0..1
        ▼
Future.wait 4 lapis PARALEL                         navigation_provider.dart:558 (_tickOnDevice)
   ├─ PidnetService      IsolateInterpreter, threads=2, GPU→CPU fallback
   ├─ YoloNavigasiService IsolateInterpreter, threads=4
   ├─ TFLiteService (COCO) IsolateInterpreter, threads=4
   └─ YoloNavInt8Service   IsolateInterpreter, threads=4
        ▼
NavObstacleMerger + ObjectTracker (SORT)            nav_obstacle_merger.dart, object_tracker.dart
        ▼
DetectionFilter.process()                           detection_filter.dart
        │  jarak → confidence → streak ≥2 → cooldown per tier → sort → take(1..2)
        ▼
DevicePaceWatch.record(ms)                          device_pace_watch.dart
        │  EMA durasi siklus → drop COCO / warn user
        ▼
TtsQueue (SpeechTier info/warning/critical)         core/speech/tts_queue.dart
```

Yang penting dicatat dari diagram ini, dan yang menjadi tulang punggung jawaban ke juri:

**Seluruh preprocessing adalah aritmetika Dart murni.** `nav_frame_converter.dart` menulis piksel langsung ke `Float32List` dalam satu lintasan, tanpa library gambar, tanpa API grafis vendor. Hasilnya **bit-identik** di HP mana pun. Begitu juga `_prepareInput` di `money_tflite_service.dart` yang melakukan letterbox dan normalisasi `x/127.5 - 1.0` sendiri.

### 2.4 Konfigurasi build

`guidio_app/android/app/build.gradle.kts`:

```kotlin
minSdk = 26          // Android 8.0
targetSdk = 36
ndkVersion = "28.2.13676358"
// tidak ada abiFilters
// tidak ada <uses-feature> terkait RAM / GPU
```

`pubspec.yaml` sama sekali **tidak memuat** `device_info_plus` maupun dependensi apa pun yang bisa membaca SoC, jumlah core, RAM, atau performance class. Yang ada hanya `battery_plus` dan `connectivity_plus`, dipakai `GlobalConditionsProvider` (`lib/core/state/global_conditions.dart`) untuk banner offline dan baterai kritis.

### 2.5 Yang SUDAH ada terkait kesadaran-perangkat

Ini bagian yang perlu ditonjolkan ke juri, karena bantahan "belum ada apa-apa" tidak sepenuhnya benar.

**(a) `DevicePaceWatch`** (`lib/services/device_pace_watch.dart`, 108 baris, plus `test/device_pace_watch_test.dart`)

Kelas murni tanpa Timer, TTS, maupun provider, sehingga logikanya bisa diuji tanpa perangkat. Ia menghitung EMA durasi siklus dan mengambil tindakan berjenjang:

```dart
DevicePaceWatch({
  this.dropCocoAboveMs = 1200,   // matikan lapis COCO diam-diam
  this.warnUserAboveMs = 2500,   // beri tahu pengguna, sekali per sesi
  this.smoothing = 0.3,
});
```

Alasan angka 1200 ms didokumentasikan, bukan ditebak: "di angka itu jeda antar arahan sudah melewati satu langkah kaki penuh, sekitar 0,7 detik pada kecepatan jalan normal."

Dan `warnUser` menghasilkan kalimat yang jujur, di `navigation_provider.dart:332`:

> "Ponsel ini memproses jalur lebih lambat dari biasanya. Jalan lebih pelan, arahan bisa datang terlambat."

Ini **sudah** jawaban parsial untuk C2 dan C4: aplikasi sudah mendeteksi device yang tidak mengejar, sudah menurunkan beban sendiri, dan sudah mengaku ke pengguna. Yang belum: ambangnya statis, cakupannya hanya Navigasi, dan tidak ada apa pun sebelum pengguna terlanjur berjalan.

**(b) Fallback berjenjang di `PidnetService`** (`lib/services/pidnet_service.dart:520-640`)

Empat percobaan berurutan: `fp16 + GPU` → `fp16 + CPU` → `fp32 + GPU` → `fp32 + CPU`, masing-masing divalidasi dengan **inferensi percobaan sungguhan**, bukan sekadar "file terbaca":

```dart
final probeIn = Float32List(_pidnetH * _pidnetW * 3);
final probeOut = Float32List(3 * _pidnetH * _pidnetW);
interpreter.runForMultipleInputs(...);   // ini yang membedakan
                                          // "berkasnya terbaca" dari
                                          // "modelnya bisa dipakai"
```

Ini pola *runtime capability probing* yang benar dan sudah ada. Tinggal digeneralisasi.

**(c) Penjaga lapis mati** (`_lapisMati`, `navigation_provider.dart:498+`)

Dokumentasi di kode menyebut bug nyata di `tflite_flutter 0.12.1`: `IsolateInterpreter` menjalankan inferensi tanpa `try/catch`, sehingga satu `TfLiteInterpreterInvoke` yang gagal membunuh isolate, `idle` tidak pernah dikirim, dan `_wait()` menggantung selamanya. Log perangkat aslinya tercatat di komentar. Penjaganya memastikan satu lapis mati tidak menjatuhkan tiga lapis sehat.

**(d) Penolakan jujur saat model gagal** (`navigation_provider.dart:440-465`)

Kalau salah satu dari empat lapis gagal dimuat, mode tidak berjalan setengah-setengah:

```dart
_speak(
  'Panduan jalur tidak bisa dijalankan di perangkat ini. '
  'Mode Deteksi Objek tetap bisa memperingatkan rintangan.',
  tier: SpeechTier.critical,
);
```

Perhatikan bentuk kalimatnya: **menyebut apa yang masih bisa dipakai**, bukan berhenti di "tidak kompatibel". Itu pola UX yang benar untuk pengguna tunanetra dan sudah jadi preseden internal yang bisa dipakai ulang.

**(e) `CapabilitiesProvider`** (`lib/providers/capabilities_provider.dart`)

Menanyakan `GET /api/capabilities` **sebelum** pengguna menekan apa pun, karena, mengutip komentarnya: "untuk pengguna yang tidak melihat layar, 'masuk lalu gagal' berarti beberapa detik kebingungan di tempat yang salah." Ini persis pola yang dibutuhkan untuk kapabilitas *device*, dan sudah terbukti jalan untuk kapabilitas *server*.

**(f) Benchmark regresi** (`test/nav_pipeline_bench_test.dart`)

Sudah ada tes yang mengukur biaya pipeline frame dan menjaga agar pola lama yang mahal tidak kembali.

### 2.6 Repo training: apa yang sudah dihasilkan

**`rupiah_vision_revised`** (MobileNetV2 → TFLite, 7 kelas)

- 16 dataset Roboflow, 30.937 foto sumber → 18.796 grup unik → **22.147 crop** setelah dedup pHash 64-bit dan pembuangan blur/koin. Imbalance ratio 1,34x.
- Split **group-aware**: satu foto sumber = satu grup, tidak boleh pecah antar split. README-nya membuka dengan pengakuan penting: split per-crop yang lama menghasilkan akurasi 99,52% yang **palsu**, karena frame video berurutan bocor antara train dan test. Angka jujurnya turun ke 92-96%.
- `scripts/00b_preflight_check.py --deep` memverifikasi kebocoran grup, kebocoran perseptual, statistik blur, statistik brightness, dan rasio aspek terhadap ukuran fisik resmi BI. Wajib exit 0.
- `scripts/02_export_tflite.py` sudah mengekspor **empat varian**: `fp32`, `fp16`, `int8_floatio`, `int8_full`, lalu **mengevaluasi keempatnya di test set** dan melaporkan penurunan akurasi per kelas (baris 391-413).
- `scripts/03_calibrate_threshold.py` menghasilkan `calibration.json` (temperature scaling + ambang tolak) dengan target presisi.

**`guido_cv_training_revised`** (YOLO11n 6 kelas + PIDNet-S 3 zona)

- 20+ dataset, normalisasi label otomatis ke 6 kelas: `lubang`, `got_terbuka`, `tangga`, `orang`, `motor`, `tiang`.
- `scripts/yolo_aug.py` (17,5 KB) melakukan augmentasi kondisi sulit: bayangan tajam dan belang daun, malam (gamma + lampu jalan + noise + warm shift), hujan, kabut, silau, permukaan basah, motion blur berarah, defocus, downscale.
- `scripts/09_distill_yolo.py`: distilasi YOLO11l/x → YOLO11n. Kutipan langsung dari docstring-nya, dan ini relevan sekali untuk challenge:
  > "Untuk kasus GUIDIO ini menarik karena kamu terkunci di YOLO11n oleh target 2 FPS di HP mid-low. Distillation adalah salah satu dari sedikit cara menaikkan akurasi tanpa melanggar batasan itu."
- `scripts/10_tune_thresholds.py`: mencari confidence threshold **optimal per kelas**, dengan argumen biaya kesalahan asimetris (kelas bahaya threshold rendah untuk recall tinggi; kelas informasional threshold tinggi supaya TTS tidak banjir).
- `scripts/07_export_tflite.py`: ekspor FP16 dan INT8 via onnx2tf, dengan `validate_tflite()` yang menangani dtype int8/uint8.
- `scripts/06_train_pidnet.py --base-ch` memberi keluarga model dengan tabel latensi terukur:

  | base_ch | Parameter | 384px | 512px |
  |---|---|---|---|
  | 16 | 1,18 M | 45 ms | 67 ms |
  | 24 | 2,65 M | 75 ms | 128 ms |
  | 32 | 4,71 M | 108 ms | 193 ms |

  Dan catatan yang sangat tepat, yang akan saya pakai sebagai landasan Bagian 4:
  > "HP Android mid-low umumnya 3-6x lebih lambat dari CPU server. Untuk target 2 FPS (500 ms), `--base-ch 16 --img-size 384` adalah titik awal paling aman. **Angka pastinya harus kamu ukur di HP target, bukan diekstrapolasi dari tabel ini.**"

**Kesimpulan sub-bagian ini:** bahan mentah untuk model tiering, kalibrasi ambang, dan bukti akurasi per varian **sudah diproduksi oleh pipeline training**. Yang belum ada adalah jembatan dari artefak-artefak itu ke aplikasi.

---

## 3. Gap Analysis

### 3.0 Gap nol: pembedaan yang belum pernah dinyatakan

Sebelum daftar gap teknis, satu gap konseptual yang justru paling merugikan saat presentasi: **tim belum pernah memisahkan tiga sumber variasi lintas device secara eksplisit.** Akibatnya, saat juri bilang "akurasi tidak konsisten", tidak ada kerangka untuk menjawab bagian mana yang benar dan bagian mana yang tidak.

| Sumber variasi | Mengubah **akurasi**? | Mengubah **latensi**? | Status di Guidio hari ini |
|---|---|---|---|
| **A. Kernel aritmetika CPU (XNNPACK)** | Tidak. Deterministik, IEEE-754, hasil bit-identik | Ya, sebanding kecepatan core | Ini yang dipakai semua model saat ini |
| **B. Delegate GPU / NPU vendor** | **Ya.** FP16 accumulate, kuantisasi per-tensor vs per-layer, approksimasi vendor | Ya, 2-9x lebih cepat | Hanya PIDNet yang mencoba GPU, dan jalurnya **gagal** (lihat 3.2). Efektif: tidak dipakai |
| **C. Kamera: sensor, ISP, resolusi, auto-exposure, white balance** | **Ya.** Ini pergeseran distribusi input, dan model memang jadi kurang akurat | Sedikit | **Tidak terkendali sama sekali.** `ResolutionPreset.medium` menyerahkan resolusi ke plugin per device |

Literatur mendukung baris B: delegate melakukan komputasi pada presisi berbeda dari CPU, dan pada beberapa NPU inferensi via NNAPI menghasilkan aktivasi yang berbeda, dalam kasus langka sepenuhnya salah, karena akumulasi approksimasi internal ([LiteRT Delegates](https://ai.google.dev/edge/litert/performance/delegates), [tensorflow#56301](https://github.com/tensorflow/tensorflow/issues/56301)). NNAPI sendiri sudah **dideprekasi di Android 15** justru karena "vendor mengimplementasikannya secara tidak merata, dan itu memecah ceritanya" ([NNAPI Migration Guide](https://developer.android.com/ndk/guides/neuralnetworks/migration-guide)).

Jadi: kekhawatiran juri tentang akurasi lintas device adalah kekhawatiran yang **benar untuk baris B dan C**, dan Guidio hari ini kebetulan aman di B tapi **telanjang di C**. Aman-yang-kebetulan bukan jaminan rekayasa, dan itulah yang harus diubah jadi keputusan sadar yang terukur.

### 3.1 [C2] Tidak ada satu baris pun kode yang membaca kapabilitas perangkat

Diverifikasi dengan pencarian di seluruh `lib/`:

```
grep -rn "device_info|Platform.version|androidInfo|supportedAbis" lib/ pubspec.yaml
→ (kosong)
```

Konsekuensinya berlapis:

- Tidak ada gerbang sebelum instalasi. `build.gradle.kts` tidak punya `abiFilters`, tidak punya `<uses-feature>`, tidak punya aturan pengecualian device di Play Console. Redmi 9A dengan Helio G25 dan RAM 2 GB bisa memasang APK yang sama dengan Galaxy S24.
- Tidak ada gerbang saat startup. `main.dart` langsung `runApp` setelah init TTS.
- Tidak ada gerbang sebelum masuk mode. Satu-satunya gerbang adalah `_loadOnDeviceModels()` yang baru berjalan **setelah** `NavigasiScreen` terpasang dan pengguna sudah berdiri di jalan sambil memegang HP.

Untuk pengguna awas, "coba dulu, gagal, keluar" adalah gangguan lima detik. Untuk pengguna tunanetra yang sudah keluar rumah karena mengira punya panduan jalur, itu adalah kepercayaan yang salah tempat pada momen paling buruk. `CapabilitiesProvider` sudah menyadari masalah ini untuk fitur server, tapi tidak ada padanannya untuk perangkat.

### 3.2 [C1] Jalur GPU praktis mati, dan itu belum pernah dinyatakan sebagai keputusan

`PidnetService._coba()` (`pidnet_service.dart:584`) adalah satu-satunya tempat `GpuDelegateV2()` dipakai di seluruh aplikasi. Dan dokumentasi di atasnya mencatat bahwa jalur itu gagal di perangkat nyata:

```
W/tflite: Attempting to use a delegate that only supports static-sized
          tensors with a graph that has dynamic-sized tensors
          (tensor#9 is a dynamic-sized tensor).
```

Sebabnya di sisi ekspor: `scripts/07_export_onnx.py` selalu menandai `{"input": {0: "batch"}}`, sehingga 73 dari 218 tensor bersumbu batch dinamis. Runtime CPU menerimanya, GPU delegate menolak grafnya.

Tiga model lain (`tflite_service`, `yolo_navigasi_service`, `yolo_nav_int8_service`, `money_tflite_service`) **tidak pernah mencoba delegate sama sekali**. Semuanya `InterpreterOptions()..threads = N` polos, artinya XNNPACK CPU.

Ini punya dua sisi yang harus dikatakan bersamaan ke juri:

- **Sisi baik:** karena semua inferensi berjalan di kernel CPU yang sama, **keluaran model bit-identik lintas device**. Sumber inkonsistensi akurasi nomor satu yang dikhawatirkan juri, secara kebetulan, tidak berlaku.
- **Sisi buruk:** Guidio membuang percepatan 2-9x yang bisa didapat dari GPU delegate, dan konsistensi yang dimilikinya adalah konsistensi yang **tidak sengaja dan tidak pernah diukur**. Kalau besok seseorang memperbaiki ekspor ONNX dan menyalakan GPU untuk semua model, inkonsistensi yang dikhawatirkan juri akan **benar-benar muncul**, tanpa ada satu tes pun yang menangkapnya.

### 3.3 [C1] Anggaran thread melebihi jumlah core, dan tidak pernah disesuaikan

Dari pembacaan langsung:

| Service | File:baris | `threads` |
|---|---|---|
| `TFLiteService` (SSD COCO) | `tflite_service.dart:238` | 4 |
| `YoloNavigasiService` (FP16) | `yolo_navigasi_service.dart:69` | 4 |
| `YoloNavInt8Service` | `yolo_nav_int8_service.dart:71` | 4 |
| `PidnetService` | `pidnet_service.dart:590` | 2 |
| `MoneyTFLiteService` | `money_tflite_service.dart:207` | 2 |

Mode Navigasi menjalankan empat yang pertama **serentak** lewat `Future.wait` di `_tickOnDevice`. Total permintaan thread inferensi: **14**, di luar isolate `NavFrameConverter.prepare`, thread UI, thread kamera, dan thread TTS.

Redmi 9A punya 8 core Cortex-A53 yang seluruhnya kecil. Snapdragon 680 punya 4 besar + 4 kecil. Di keduanya, 14 thread inferensi berebut kurang dari 8 core fisik. Yang terjadi bukan crash, melainkan **context switching** dan latensi yang naik super-linear justru pada device yang paling tidak sanggup menanggungnya.

Angka-angka ini konstan lintas semua device. Tidak ada `Platform.numberOfProcessors` di mana pun. Saya sebut ini sebagai **hipotesis kuat yang wajib diukur**, bukan bug yang sudah terbukti: efeknya harus dikonfirmasi dengan benchmark on-device (Bagian 4.6) sebelum diklaim.

### 3.4 [C1/C3] Resolusi kamera diserahkan ke plugin, dan itu variasi input yang nyata

`camera_provider.dart:933`:

```dart
realtime(ResolutionPreset.medium),
capture(ResolutionPreset.high);
```

`ResolutionPreset.medium` bukan angka. Ia adalah permintaan "sekitar 480p" yang **dipetakan berbeda oleh setiap device** ke resolusi yang tersedia di HAL kamera masing-masing. Dua HP bisa memberi 640x480 dan 720x480 untuk preset yang sama, dengan rasio aspek berbeda.

Karena `NavFrameConverter.prepare()` melakukan resize dari `srcW × srcH` ke `640×384` dan `640×640`, perbedaan resolusi sumber berarti **perbedaan faktor penskalaan, perbedaan artefak resampling, dan perbedaan bidang pandang efektif**. Itu masuk ke model sebagai distribusi input yang berbeda, dan **itu benar-benar mengubah akurasi**.

Ditambah lagi: sensor, ISP, kurva auto-exposure, dan white balance berbeda per vendor. Uang kertas yang sama di bawah lampu yang sama akan menghasilkan piksel berbeda di Redmi dan di Samsung.

**Ini gap C3 yang sesungguhnya.** Bukan "CPU-nya beda", melainkan "kameranya beda". Dan kabar baiknya, ini justru yang sudah diserang paling keras oleh pipeline training: augmentasi malam, bayangan, silau, permukaan basah, downscale, motion blur di `yolo_aug.py`, plus preflight check statistik brightness di `00b_preflight_check.py`.

### 3.5 [C3] Ambang keputusan uang bertentangan di tiga tempat, dan kalibrasi tidak pernah dimuat

Ini gap paling konkret dan paling mudah diperbaiki di seluruh dokumen.

| Sumber | Nilai | Status |
|---|---|---|
| `money_tflite_service.dart:83` `confidenceThreshold` | **0,75** | inilah yang benar-benar dieksekusi |
| Docstring di file yang sama, baris 39 | "membandingkan keluaran dengan **0,85**" | dokumentasi basi |
| `assets/models/rupiah_class_info.json` → `mobile_thresholds.confidence_gate` | **0,85** | tidak pernah dibaca kode |
| `assets/models/rupiah_calibration.json` → `confidence_threshold` | **0,9873** (dengan `temperature = 0,5206`) | **file tidak pernah dibaca sama sekali** |

Diverifikasi: `grep -rn "rupiah_calibration" lib/` mengembalikan nol hasil. File hasil `03_calibrate_threshold.py` ikut dibundel ke APK, menambah ukuran, dan tidak pernah dipakai.

Padahal isinya adalah hasil kerja yang serius:

```json
"measured": {
  "coverage": 0.398,
  "selective_accuracy": 1.0,
  "accuracy_all": 0.956,
  "ece_before": 0.0761,
  "ece_after": 0.0168
}
```

ECE turun dari 7,6% ke 1,7% setelah temperature scaling, dan pada cakupan 39,8% akurasi selektifnya **100%**. Untuk mode uang, di mana kesalahan nominal tidak bisa diverifikasi sendiri oleh pengguna, itu angka yang tepat untuk dipakai.

Kaitannya dengan challenge: **kalibrasi adalah cara yang benar untuk menangani ketidakpastian, dan Guidio sudah punya kalibrasinya tapi tidak memakainya.** Sulit mempertahankan "kami serius soal konsistensi" sambil membundel file kalibrasi yang tidak pernah dibuka.

Catatan jujur tambahan yang harus disampaikan apa adanya: komentar panjang di `money_tflite_service.dart:95-110` mendokumentasikan batas yang belum terpecahkan, bahwa `non_rupiah/copy3` (bukan uang) disebut "Rp5.000" dengan keyakinan 89,1% dan margin 84,8, di atas lima jawaban yang benar. Kode itu sendiri menyimpulkan bahwa tidak ada ambang apa pun yang memisahkannya tanpa ikut membuang jawaban benar, dan perbaikannya harus di training dengan menambahkan kelas OOD. Itu bukan masalah lintas device, tapi itu masalah yang harus ada di roadmap yang sama.

### 3.6 [C2/C4] `DevicePaceWatch` benar, tapi cakupannya sempit dan reaktif

| Batasan | Detail | Risiko |
|---|---|---|
| Hanya Navigasi | `grep` menunjukkan ia hanya dipakai `navigation_provider.dart:317`. Deteksi Objek, Kenali Uang, Baca Teks tidak punya pengawas kecepatan | Deteksi Objek juga real-time dan juga safety-critical. Peringatan rintangan yang basi sama berbahayanya |
| Reset tiap sesi | `_startLoop()` memanggil `_pace.reset()` | Benar untuk menghindari menghukum device selamanya, tetapi berarti aplikasi **tidak pernah belajar** bahwa HP ini memang selalu lambat. Pengguna kena keterlambatan ulang setiap sesi sebelum diperingatkan |
| Ambang statis | 1200 / 2500 ms konstan | Tidak dikaitkan dengan tier device, tidak dikaitkan dengan kecepatan jalan pengguna |
| Peringatan sekali per sesi | `_warned` bool | Benar untuk tidak membanjiri, tetapi perjalanan 30 menit dengan thermal throttling di menit ke-10 hanya diperingatkan sekali |
| Murni reaktif | Bertindak setelah lambat terjadi | Tidak ada apa pun yang memberi tahu sebelum pengguna keluar rumah |

### 3.7 [C2/C4] Ketersediaan mode Navigasi bersifat biner

`navigation_provider.dart:440`:

```dart
_modelsReady = results[0] && results[1] && results[2] && results[3];
```

Komentar di atasnya menjelaskan alasan yang **benar secara etis**: dulu lapis 3 dan 4 opsional, sehingga satu nama mode dipakai untuk dua tingkat perlindungan yang berbeda jauh tanpa pengguna tahu yang mana yang aktif. Lapis 4 khusus mengurus rintangan vertikal tipis (tiang), golongan paling berbahaya karena tongkat melewatinya tanpa menyentuh, lalu kepala yang menemukannya.

Tapi konsekuensinya: **tidak ada jalan tengah.** HP yang hanya sanggup tiga lapis mendapat "tidak bisa dijalankan", padahal tiga lapis (PIDNet + YOLO INT8 + COCO) masih jauh lebih baik daripada tidak ada panduan. Yang hilang bukan kemampuan menurunkan tingkat, melainkan **kosakata untuk menamai tingkat yang lebih rendah secara jujur**. Solusi 4.2 mengusulkan kosakata itu.

### 3.8 [C4] Tidak ada satu pun angka lintas device yang tercatat

- `tickMsEma` (`navigation_provider.dart:322`) hanya dibaca panel debug. Tidak ditulis ke mana pun.
- `FramePacer.takeDroppedCount()` ada, tetapi hasilnya tidak dipersistensi.
- Tidak ada `integration_test/` di `guidio_app` (hanya `test/` unit).
- `test/nav_pipeline_bench_test.dart` berjalan di **mesin CI, bukan HP target**, dan docstring-nya mengakuinya: "Angka absolutnya tidak berarti banyak. Yang dijaga adalah PERBANDINGANNYA."

**Ini gap yang paling menentukan untuk menghadapi juri berikutnya.** Semua argumen di Bagian 4 bisa benar secara teknis dan tetap kalah di ruang presentasi kalau tidak ada satu tabel angka pun dari HP sungguhan.

### 3.9 Ringkasan gap terhadap poin juri

| Poin juri | Sudah ada | Yang hilang | Prioritas |
|---|---|---|---|
| C1 akurasi tidak konsisten | Semua inferensi CPU/XNNPACK deterministik; preprocessing Dart murni bit-identik | **Bukti terukurnya**; kendali resolusi kamera; anggaran thread sadar-core | P0 (bukti), P1 (thread), P1 (kamera) |
| C2 spek minimum + notifikasi | `DevicePaceWatch`, fallback PIDNet, penolakan jujur, `CapabilitiesProvider` sebagai preseden | Pembacaan kapabilitas device; profiling awal; definisi tier; pengumuman pra-mode | P0 |
| C3 kalibrasi per device | Artefak `calibration.json` + `10_tune_thresholds.py` + augmentasi berat sudah ada | Kalibrasi tidak dimuat; ambang bertentangan 3 tempat; belum ada eval per varian model | P0 (muat kalibrasi), P1 (eval per varian) |
| C4 safety-critical | Tier TTS, cooldown per tier, streak, penolakan jujur, penjaga lapis mati | Telemetri lokal; uji lintas device; laporan benchmark; kebijakan dukungan device tertulis | P0 |

---

## 4. Proposed Solutions

Enam solusi. Semuanya **aditif** terhadap sistem yang sudah jalan; tidak ada yang menuntut rombak arsitektur.

---

### 4.1 [S1] Device Profiling: ukur, jangan tebak dari nama SoC

**Jawaban langsung untuk pertanyaan "bagaimana mendefinisikan dan mengecek spek minimum CPU/GPU/RAM".**

**Pendekatan.** Jangan pakai daftar SoC atau ambang RAM sebagai kriteria utama. Nama SoC bukan prediktor latensi TFLite yang baik: dua HP dengan Snapdragon 680 bisa berbeda 2x karena versi Android, tekanan memori, dan kebijakan thermal OEM. Repo training sendiri sudah menyimpulkan hal yang sama di README `guido_cv_training_revised`: *"Angka pastinya harus kamu ukur di HP target, bukan diekstrapolasi dari tabel ini."*

Jadi kriterianya adalah **latensi terukur pada model yang benar-benar dipakai**.

Tiga lapis pengukuran:

**Lapis 1, gerbang keras sebelum instalasi** (murah, kasar, hanya untuk menyaring yang mustahil):

```kotlin
// android/app/build.gradle.kts
defaultConfig {
    minSdk = 26
    ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }
}
```

```xml
<!-- AndroidManifest.xml -->
<uses-feature android:name="android.hardware.camera.any" android:required="true"/>
<supports-gl-texture android:name="GL_OES_compressed_ETC1_RGB8_texture"/>
```

Plus aturan pengecualian device di Play Console untuk RAM < 2 GB. Ini bukan kriteria utama, hanya lantai.

**Lapis 2, pembacaan statis saat startup pertama** (`device_info_plus` + Jetpack Core Performance):

Jetpack [`androidx.core:core-performance`](https://developer.android.com/topic/performance/performance-class) melaporkan **Media Performance Class** perangkat, standar resmi Android yang mendefinisikan tingkat kapabilitas di atas baseline. Ini dipakai sebagai *prior*, bukan keputusan.

```dart
// BARU: lib/models/device_profile.dart
class DeviceProfile {
  final String model;          // "Redmi 9A"
  final String soc;            // "mt6762g"
  final int    cores;          // Platform.numberOfProcessors
  final int    ramMb;
  final int    sdkInt;
  final String abi;            // arm64-v8a / armeabi-v7a
  final int    performanceClass; // 0 = tidak dideklarasikan

  // hasil benchmark nyata
  final double pidnetP50Ms, pidnetP90Ms;
  final double yoloP50Ms,   yoloP90Ms;
  final double cocoP50Ms,   cocoP90Ms;
  final double moneyP50Ms;
  final double prepareP50Ms;

  final DeviceTier tier;
  final String modelSetVersion;  // kunci invalidasi
  final String appVersion;
}
```

**Lapis 3, micro-benchmark nyata** (ini yang menentukan tier):

```dart
// BARU: lib/services/device_profiler.dart
class DeviceProfiler {
  /// Jalankan sekali saat onboarding, atau saat modelSetVersion berubah.
  ///
  /// Memakai frame sintetis deterministik yang sama di semua device
  /// (pola yang sama dengan test/nav_pipeline_bench_test.dart), sehingga
  /// yang diukur murni kecepatan perangkat, bukan isi pemandangan.
  Future<DeviceProfile> profile({int warmup = 5, int iterations = 20});
}
```

Prosedurnya meniru praktik standar benchmark inferensi mobile: 5 iterasi pemanasan lalu 20 iterasi terukur, laporkan **p50 dan p90**, bukan rata-rata. p90 yang dipakai untuk penentuan tier, karena yang membahayakan pengguna adalah siklus terburuk, bukan siklus rata-rata.

Disimpan di `shared_preferences` (sudah ada di `pubspec.yaml`) dengan kunci `deviceProfile.v1.<modelSetVersion>.<appVersion>`, sehingga profil otomatis kedaluwarsa saat model atau aplikasi di-update.

**Effort.** 3-4 hari. Termasuk `device_info_plus` (~1 jam), platform channel tipis ke `core-performance` (~4 jam), harness benchmark (~1,5 hari), persistensi + invalidasi (~0,5 hari), tes (~1 hari).

**Trade-off dan risiko.**

| Risiko | Mitigasi |
|---|---|
| Benchmark saat onboarding berjalan pada HP **dingin**. Saat dipakai berjalan 20 menit, thermal throttling bisa membuatnya 40% lebih lambat. Tier bisa terlalu optimistis | `DevicePaceWatch` tetap dipertahankan sebagai penjaga runtime (justru inilah pembenaran keberadaannya). Tambahkan re-profiling ringan di latar setiap N sesi, dan turunkan tier permanen kalau EMA runtime konsisten melampaui ambang tier |
| Menambah 15-25 detik ke onboarding | Jalankan setelah izin kamera diberikan, sambil TTS membacakan langkah onboarding berikutnya. Pengguna tidak menunggu dalam diam. Kalau ditunda, jalankan sebelum masuk mode Navigasi pertama kali |
| Ukuran APK bertambah karena `device_info_plus` | Diabaikan, kurang dari 100 KB |

**Kode yang disentuh.**

| File | Aksi |
|---|---|
| `lib/models/device_profile.dart` | BARU |
| `lib/services/device_profiler.dart` | BARU |
| `lib/providers/device_capability_provider.dart` | BARU (cermin `CapabilitiesProvider`) |
| `lib/main.dart` | daftarkan provider baru |
| `lib/screens/onboarding_screen.dart` | sisipkan langkah profiling |
| `pubspec.yaml` | `device_info_plus: ^11.x` |
| `android/app/build.gradle.kts` | `abiFilters`, dependensi `core-performance` |

---

### 4.2 [S2] Tiga tier device, dengan latensi sebagai kriteria

**Pendekatan.** Definisikan tier dari p90 satu siklus penuh Navigasi, karena mode itulah yang paling menuntut. Anggaran total dipatok dari `FramePacer(minInterval: 700 ms)` yang sudah ada.

| Tier | Kriteria (p90 siklus) | Konfigurasi Navigasi | Mode lain |
|---|---|---|---|
| **A** | < 700 ms | 4 lapis penuh, PIDNet `base_ch 32 @512`, YOLO FP16 640 | Semua penuh |
| **B** | 700 - 1500 ms | 3 lapis (COCO dimatikan), PIDNet `base_ch 16 @384`, YOLO INT8 640 | Semua penuh, laju kamera diturunkan |
| **C** | 1500 - 2500 ms | 2 lapis (PIDNet + YOLO INT8), interval 1000 ms, diumumkan sebagai "panduan jalur terbatas" | Deteksi Objek, Kenali Uang, Baca Teks penuh |
| **D** | > 2500 ms, atau salah satu model gagal probe | **Navigasi dinonaktifkan** | Deteksi Objek, Kenali Uang, Baca Teks tetap jalan |

Poin kunci yang menjawab gap 3.7: tier C bukan "Navigasi yang diam-diam lebih buruk". Ia mode dengan **nama yang berbeda** saat diumumkan ("panduan jalur terbatas"), dan pengumumannya menyebut apa yang tidak dicakup. Prinsip yang sudah dipegang kode saat ini, bahwa satu nama tidak boleh dipakai untuk dua tingkat perlindungan, tetap dijaga; yang ditambahkan adalah nama kedua.

Tier D menonaktifkan Navigasi tetapi **tidak** menonaktifkan aplikasi. Ini penting untuk dinyatakan ke juri: "device tidak memenuhi spek" tidak pernah berarti aplikasi tidak berguna. Kenali Uang (MobileNetV2, 224x224, satu tembakan, bukan real-time) berjalan nyaman bahkan di HP paling lemah, dan itu fitur kemandirian harian yang paling sering dipakai.

Implementasi:

```dart
// BARU: lib/models/device_tier.dart
enum DeviceTier { a, b, c, d }

class TierConfig {
  final int  navLayers;          // 4, 3, 2, 0
  final int  navIntervalMs;      // 700, 900, 1000, -
  final String pidnetAsset;
  final String yoloNavAsset;
  final int  pidnetThreads, yoloThreads, cocoThreads;
  final bool cocoEnabled;
  final String thresholdsAsset;  // per varian model, lihat 4.5
}
```

Sekaligus perbaiki gap 3.3, anggaran thread sadar-core:

```dart
// device_profiler.dart
int budget(int share) {
  final n = Platform.numberOfProcessors;
  // total permintaan thread di mode Navigasi tidak boleh melampaui
  // jumlah core. Angka 4/4/4/2 yang konstan hari ini meminta 14.
  return math.max(1, (n * share / 100).floor());
}
```

**Effort.** 4-5 hari, mengandaikan aset model tier sudah ada (4.3).

**Trade-off dan risiko.**

| Risiko | Mitigasi |
|---|---|
| Empat konfigurasi = empat jalur yang harus diuji. Kombinatorika tes naik | Definisikan tier sebagai **data** (`TierConfig`), bukan cabang `if`. Satu jalur kode, empat set parameter. Tes parametrik atas keempatnya |
| Pengguna tier C mendapat perlindungan lebih rendah dan mungkin tidak sepenuhnya paham | Ini trade-off etis yang harus diputuskan sadar dan didokumentasikan. Alternatifnya, menolak melayani tier C sama sekali, berarti pengguna tunanetra dengan HP 1,5 juta tidak dapat panduan apa pun. Menurut saya panduan terbatas yang jujur lebih baik daripada tidak ada, **asalkan** jujurnya benar-benar disampaikan (4.4) |
| Batas tier bisa salah pada awalnya | Simpan batas di satu konstanta, kalibrasi ulang setelah data beta (4.6) masuk |

**Kode yang disentuh.** `lib/models/device_tier.dart` (BARU), `lib/providers/navigation_provider.dart` (`_loadOnDeviceModels`, `_startLoop`, `_tickOnDevice` membaca `TierConfig`), keempat service inferensi (terima `threads` dan path aset sebagai parameter, bukan konstanta), `lib/providers/app_mode_provider.dart` (ketersediaan mode per tier).

---

### 4.3 [S3] Model tiering: ya, dan artefaknya sebagian besar sudah ada

**Jawaban langsung untuk "apakah perlu model tiering dan bagaimana strategi switching-nya".**

**Ya, perlu.** Dan yang membuat ini realistis untuk Guidio, bukan usulan generik, adalah bahwa **kedua pipeline training sudah memproduksi varian yang dibutuhkan**:

| Model | Script | Varian yang sudah dihasilkan |
|---|---|---|
| Rupiah MobileNetV2 | `rupiah_vision_revised/scripts/02_export_tflite.py` | `fp32`, `fp16`, `int8_floatio`, `int8_full` + evaluasi test set keempatnya + laporan penurunan recall per kelas |
| YOLO11n navigasi | `guido_cv_training_revised/scripts/07_export_tflite.py` | FP16 dan INT8 via onnx2tf, dengan `validate_tflite()` |
| PIDNet-S | `guido_cv_training_revised/scripts/06_train_pidnet.py --base-ch` | keluarga 16 / 24 / 32 dengan tabel latensi terukur |

Bahkan `rupiah_classifier_fp16.tflite` (4,6 MB) **sudah ada di `assets/models/` dan tidak pernah dipakai**.

Peta tier ke aset:

| Tier | PIDNet | YOLO navigasi | COCO | Rupiah |
|---|---|---|---|---|
| A | `pidnet_s_c32_512_fp16.tflite` | `yolo11n_navigasi.tflite` (FP16 10,1 MB) | aktif | `rupiah_classifier_fp16.tflite` |
| B | `pidnet_s_c16_384_fp16.tflite` (~0,5 MB) | `yolo11n.tflite` (INT8 2,9 MB) | mati | `rupiah_classifier_int8.tflite` |
| C | `pidnet_s_c16_384_int8.tflite` | `yolo11n.tflite` (INT8) | mati | `rupiah_classifier_int8.tflite` |
| D | - | - | - | `rupiah_classifier_int8.tflite` |

**Strategi switching: statis saat profiling, bukan dinamis di tengah jalan.**

Ini keputusan yang harus dipertahankan dengan tegas di depan juri, karena intuisi awam mengatakan sebaliknya:

1. Memuat interpreter TFLite memakan waktu, dan `_loadOnDeviceModels()` sudah memuat empat model paralel. Menukar model di tengah perjalanan berarti jeda beberapa detik **tanpa panduan sama sekali**, tepat saat pengguna sedang berjalan.
2. Perilaku yang berubah di tengah satu perjalanan lebih buruk daripada perilaku yang konsisten lebih rendah. Pengguna tunanetra membangun model mental tentang seberapa cepat aplikasinya bereaksi. Mengubah model berarti mengubah kontrak itu tanpa pemberitahuan.
3. `DevicePaceWatch` sudah menangani degradasi runtime dengan cara yang benar, yaitu **mematikan lapis**, bukan menukar bobot. Komentarnya menjelaskan urutan pengorbanan yang tepat: COCO dulu, karena PIDNet memberi arahan jalur dan YOLO memberi peringatan lubang dan tangga, dan keduanya tidak punya pengganti.

Jadi: tier ditetapkan saat profiling, model dipilih saat `_loadOnDeviceModels()`, dan satu-satunya adaptasi runtime adalah menjatuhkan lapis lewat `DevicePaceWatch` yang sudah ada.

**Masalah ukuran APK, dan jawabannya.** Menambah varian menaikkan bobot model dari ~28 MB. Solusinya **Play Feature Delivery / Asset Delivery** dengan asset pack `install-time` yang dikondisikan pada ABI, atau `fast-follow` pack yang diunduh setelah profiling. Ini menambah kompleksitas rilis, dan wajar kalau tidak dikerjakan sebelum beta.

**Effort.** Sisi training 1-2 hari GPU (retrain PIDNet `base_ch 16`, ekspor, evaluasi) plus 1 hari analisis. Sisi aplikasi 2-3 hari (registry aset, parameterisasi service). Play Asset Delivery 3-4 hari terpisah.

**Trade-off dan risiko.** Ini bagian yang paling penting untuk dinyatakan jujur:

> **Model tiering adalah satu-satunya solusi di dokumen ini yang benar-benar memperkenalkan perbedaan akurasi antar device.** Hari ini semua device menjalankan bobot yang sama dan mendapat jawaban yang sama. Setelah tiering, tidak lagi.

Karena itu tiering **tidak boleh diterapkan tanpa** tiga syarat:

1. Setiap varian dievaluasi di test set yang sama, dengan **recall per kelas**, bukan hanya akurasi agregat. `02_export_tflite.py` sudah melakukan persis ini (baris 391-413) dan memperingatkan saat penurunan tidak merata antar kelas.
2. Ambang keputusan **di-tuning ulang per varian**, tidak diwariskan. `10_tune_thresholds.py` untuk YOLO, `03_calibrate_threshold.py` untuk rupiah.
3. Untuk kelas bahaya (`lubang`, `got_terbuka`, `tangga`, `tiang`), tetapkan **lantai recall yang tidak boleh dilanggar varian apa pun**. Kalau varian INT8 menjatuhkan recall `tiang` di bawah lantai, varian itu **tidak dikirim**, dan tier yang bersangkutan turun ke D. Lebih baik mengakui tidak bisa daripada mengirim model yang melewatkan tiang setinggi kepala.

Poin 3 adalah jawaban terkuat untuk C4. Ia mengubah "kami harap konsisten" menjadi "kami punya batas yang dinyatakan angka, dan model yang melanggarnya kami tolak kirim".

**Kode yang disentuh.** `lib/services/model_registry.dart` (BARU), keempat service inferensi (path aset jadi parameter konstruktor), `guido_cv_training_revised/scripts/06_train_pidnet.py` (jalankan `--base-ch 16`), `scripts/07_export_tflite.py` dan `02_export_tflite.py` (sudah siap, tinggal dijalankan), `assets/models/` (+3 file).

---

### 4.4 [S4] Notifikasi ke pengguna tunanetra: empat momen, satu aturan

**Jawaban langsung untuk "bagaimana memberi notifikasi kalau device tidak memenuhi spek, dan UX-nya".**

Notifikasi visual seperti dialog "Perangkat Anda tidak kompatibel" adalah jawaban yang salah, dan bukan hanya karena tidak terlihat. Ia salah karena tiga alasan yang lebih dalam:

1. **Buntu.** Tidak menyebut apa yang masih bisa dipakai.
2. **Bertumpuk dengan TalkBack.** `lib/core/a11y/screen_reader.dart` mendokumentasikan masalah ini: saat TalkBack menyala, ada dua mesin suara ke telinga yang sama, dan yang kalah biasanya justru kalimat yang paling dibutuhkan.
3. **Datang di waktu yang salah.** Dialog muncul saat pengguna sudah masuk mode, artinya sudah keluar rumah.

Aturan tunggal yang berlaku untuk semua momen, dan yang **sudah jadi preseden di kode**:

> Setiap pengumuman keterbatasan **wajib** menyebut apa yang masih berfungsi, dalam kalimat yang sama.

Preseden itu ada di `navigation_provider.dart:315`: *"Panduan jalur tidak bisa dijalankan di perangkat ini. **Mode Deteksi Objek tetap bisa memperingatkan rintangan.**"*

Empat momen:

**Momen 1, akhir onboarding, sekali seumur instalasi.** Setelah profiling selesai:

- Tier A: tidak ada pengumuman khusus. Tidak perlu memuji perangkat.
- Tier B/C: *"Ponsel ini sanggup menjalankan semua fitur. Untuk panduan jalur, ponselmu memproses sedikit lebih lambat, jadi berjalanlah dengan tempo santai saat memakainya."*
- Tier D: *"Ponsel ini bisa menjalankan Deteksi Objek, Kenali Uang, dan Baca Teks sepenuhnya tanpa internet. Panduan Jalur butuh ponsel yang lebih cepat, jadi mode itu tidak akan muncul di daftar."*

Disampaikan lewat `TTSService.instance.speak(..., interrupt: true)`, pola yang sudah dipakai `onboarding_screen.dart:90`.

**Momen 2, di lembar pemilihan mode, setiap kali.** Ini yang paling penting, dan **polanya sudah ada**. `CapabilitiesProvider` sudah membuat item mode nonaktif menyebut alasannya **sebelum ditekan**. Cukup tambahkan `DeviceCapabilityProvider` sebagai sumber kedua di logika yang sama.

TalkBack membacakan: *"Panduan Jalur, tidak tersedia, ponsel ini memproses jalur lebih lambat dari yang dibutuhkan mode ini."* Pengguna tahu sebelum menekan, bukan setelah.

**Momen 3, saat masuk mode, penyetelan ekspektasi.** Tier C, sebelum panduan dimulai: *"Panduan jalur terbatas. Saya akan memperingatkan lubang, tangga, dan tiang, tapi tidak menyebut orang atau kendaraan. Jalan pelan."*

Kalimat ini menyebut **secara spesifik apa yang tidak dicakup**. Itu yang membedakannya dari peringatan basa-basi.

**Momen 4, runtime, saat ternyata lebih lambat dari perkiraan.** `DevicePaceWatch.warnUser` **sudah ada dan sudah benar**. Dua penyempurnaan:

(a) Tambahkan **haptik**, bukan hanya suara. `lib/services/haptic_service.dart` sudah ada. Saat panduan tertinggal, kanal audio justru sedang paling sibuk; getaran adalah kanal terpisah yang tidak berebut. Pola berbeda dari getaran "mic aktif" yang sudah ada.

(b) Izinkan peringatan **berulang** dengan jeda panjang (misal maksimum sekali per 5 menit) alih-alih sekali per sesi, karena thermal throttling di menit ke-10 perjalanan 30 menit hari ini tidak terlaporkan sama sekali.

```dart
// device_pace_watch.dart
DateTime? _lastWarnAt;
static const _warnRepeatGap = Duration(minutes: 5);
```

**Yang secara eksplisit TIDAK dilakukan:** dialog modal, toast, badge, ikon peringatan tanpa padanan lisan, dan kalimat apa pun yang berakhir tanpa menyebut jalan keluar.

**Effort.** 2-3 hari. Sebagian besar adalah penulisan dan pengujian kalimat, bukan kode. Alokasikan waktu untuk **membacakannya ke pengguna tunanetra sungguhan** dan merevisi; kalimat yang enak dibaca sering tidak enak didengar.

**Trade-off dan risiko.**

| Risiko | Mitigasi |
|---|---|
| Menambah panjang onboarding yang sudah panjang | Momen 1 hanya satu kalimat, dan hanya untuk tier B/C/D |
| Terlalu sering diperingatkan = diabaikan (alarm fatigue) | Jeda 5 menit, dan momen 2 tidak berbunyi kecuali pengguna memang menyorot item itu |
| Kalimat terasa merendahkan perangkat pengguna | Rumuskan sebagai sifat mode, bukan kekurangan pengguna: "mode ini butuh ponsel lebih cepat", bukan "ponselmu lemah" |

**Kode yang disentuh.** `lib/providers/device_capability_provider.dart` (BARU), `lib/screens/onboarding_screen.dart`, `lib/screens/main_screen.dart` (lembar mode), `lib/providers/navigation_provider.dart`, `lib/services/device_pace_watch.dart`, `lib/services/haptic_service.dart`, `test/device_pace_watch_test.dart`, `test/onboarding_flow_speech_test.dart`.

---

### 4.5 [S5] Kalibrasi: tidak per device, tapi per varian model. Dan yang sudah ada harus dipakai dulu

**Jawaban langsung untuk "apakah perlu kalibrasi/adaptasi model per device, atau cukup device profiling".**

**Tidak perlu kalibrasi per device. Cukup device profiling.** Alasannya tiga, dan semuanya berdasar pada kode ini:

1. **Aritmetikanya sudah deterministik.** Semua inferensi CPU/XNNPACK, semua preprocessing Dart murni (`nav_frame_converter.dart`, `_prepareInput`). Tidak ada yang perlu dikalibrasi karena tidak ada yang berbeda.
2. **Kalibrasi per device tidak dapat dipelihara dan tidak dapat divalidasi.** Ada ribuan model HP Android di Indonesia. Mengumpulkan data berlabel per device mustahil, dan tanpa data berlabel, "kalibrasi" hanyalah tebakan yang diberi nama ilmiah. Untuk aplikasi keselamatan, itu lebih buruk daripada tidak mengkalibrasi, karena menghilangkan ketertelusuran: tidak ada lagi satu model yang bisa diaudit.
3. **Variasi input yang nyata (kamera) sudah diserang dari sisi training,** yang merupakan tempat yang benar. `yolo_aug.py` sudah mensimulasikan malam, bayangan belang daun, hujan, kabut, silau, permukaan basah, motion blur, defocus, dan downscale. Downscale khususnya adalah simulasi langsung untuk kamera murah.

Yang **memang** perlu dikalibrasi ada tiga, dan tidak satu pun berdimensi device:

**(a) Ambang keputusan per varian model.** Model INT8 punya distribusi softmax yang berbeda dari FP16. Komentar di `money_tflite_service.dart:88-100` sudah mendokumentasikan ini dengan data: model Stage 2 INT8 punya probabilitas rendah di semua kelas sekaligus, sehingga yang bisa dipercaya adalah **margin**, bukan confidence. Setiap varian butuh `03_calibrate_threshold.py` dan `10_tune_thresholds.py` sendiri.

**(b) [P0, quick win] Muat kalibrasi yang sudah ada, dan hentikan kontradiksi tiga arah.**

Ini perbaikan dengan rasio nilai terhadap effort tertinggi di seluruh dokumen. Hari ini `rupiah_calibration.json` dibundel ke APK dan tidak pernah dibaca, sementara tiga angka ambang berbeda hidup berdampingan (0,75 di kode, 0,85 di dua tempat lain, 0,9873 di kalibrasi).

```dart
// BARU: lib/models/calibration.dart
class Calibration {
  final double temperature;          // 0.5206
  final double confidenceThreshold;  // 0.9873
  final double entropyThreshold;     // 0.00515
  final String rejectMessage;
  static Future<Calibration> load(String asset);
}
```

Dan `money_tflite_service.dart` menghapus `static const double confidenceThreshold = 0.75` sebagai sumber kebenaran, menggantinya dengan nilai dari kalibrasi.

Satu peringatan teknis yang harus dibaca sebelum mengerjakannya, karena mudah salah: `rupiah_classifier_int8.tflite` **sudah mengandung softmax** (ditambahkan saat konversi TFLite, dijelaskan di docstring baris 36-42). Temperature scaling harus diterapkan ke **logit**, bukan ke probabilitas. `usage_note` di `rupiah_calibration.json` sendiri menyebut jalan keluarnya: ambil `log(probs)`, bagi dengan temperature, softmax ulang; atau ekspor varian logits. Rekomendasi saya yang kedua, karena `01_train.py` sudah menghasilkan `rupiah_final.keras` yang mengeluarkan logit.

Konsekuensi yang harus diterima: pada `confidence_threshold = 0,9873`, **coverage-nya 39,8%**. Enam dari sepuluh foto akan mendapat jawaban berpagar, bukan jawaban lugas. Tapi pada 39,8% itu, akurasi selektifnya **100%**. Untuk mode uang, di mana pengguna tidak bisa memverifikasi nominal sendiri, trade-off itu benar. Dan `MoneyResult.certain` yang sudah ada memang dirancang persis untuk itu: nominal tetap disebut, hanya nadanya berpagar ("Sepertinya lima puluh ribu rupiah").

**(c) Normalisasi kondisi kamera per device.** Bukan mengkalibrasi model, melainkan menormalkan inputnya. Tiga service yang relevan **sudah ada**: `luma_contrast.dart` (91 baris), `auto_torch_controller.dart` (346 baris, dengan tes), `camera_intrinsics.dart` (96 baris). Tambahan yang diusulkan: catat luma rata-rata per device saat profiling sebagai baseline, dan tetapkan resolusi kamera **secara eksplisit** alih-alih menyerahkannya ke `ResolutionPreset.medium` (gap 3.4):

```dart
// camera_provider.dart, ganti ResolutionPreset.medium
final target = const Size(640, 480);
final chosen = controller.value.previewSize;   // catat yang benar-benar didapat
// masuk ke DeviceProfile, sehingga variasi resolusi terdokumentasi,
// bukan tak terlihat
```

**Effort.** (b) 1 hari, dan ini yang harus dikerjakan minggu ini. (a) mengikuti 4.3. (c) 2 hari.

**Trade-off dan risiko.**

| Risiko | Mitigasi |
|---|---|
| Coverage turun ke ~40% akan terasa seperti kemunduran bagi pengguna | Ini bukan penolakan menjawab. Nominal tetap disebut dengan nada berpagar plus ajakan mengecek ulang, sesuai desain `MoneyResult.certain` yang sudah ada. Ukur ulang coverage setelah dataset 22.147 crop yang baru dipakai; angka 39,8% berasal dari model Stage 2 yang lama |
| Menerapkan temperature ke probabilitas yang sudah di-softmax menghasilkan angka yang salah tanpa error apa pun | Ekspor varian logits dari `rupiah_final.keras`. Tambahkan tes di `test/money_pipeline_test.dart` yang menguji kalibrasi terhadap vektor logit yang diketahui |
| Memaku resolusi kamera bisa gagal di device yang tidak mendukungnya | `camera` plugin mengembalikan resolusi terdekat yang tersedia. Catat yang didapat, jangan asumsikan yang diminta |

**Kode yang disentuh.** `lib/models/calibration.dart` (BARU), `lib/services/money_tflite_service.dart`, `lib/providers/money_provider.dart`, `lib/providers/camera_provider.dart`, `assets/models/rupiah_calibration.json` (regenerasi dari varian logit), `test/money_pipeline_test.dart`, `test/rupiah_kamera_e2e_test.dart`.

---

### 4.6 [S6] Testing lintas device: empat lapis, dari yang paling murah

**Jawaban langsung untuk "bagaimana strategi testing/validasi akurasi lintas device, termasuk beta testing".**

**Lapis 1: golden vector test, membuktikan akurasi TIDAK bergantung device.**

Ini tes terpenting di seluruh rencana, karena ia menyerang keberatan juri secara langsung.

```dart
// BARU: integration_test/golden_inference_test.dart
//
// Input tensor tetap (dihasilkan dari benih deterministik, sama persis
// di semua device) → keluaran model dibandingkan dengan vektor referensi
// yang di-commit ke repo.
//
// Lolos di HP mana pun = akurasi model tidak bergantung perangkat, dan
// itu bukan klaim melainkan hasil ukur.
testWidgets('PIDNet menghasilkan keluaran identik dengan referensi', (t) async {
  final out = await PidnetService.instance.runRaw(deterministicInput());
  expect(maxAbsDiff(out, referenceVector), lessThan(1e-5));
});
```

Ambang `1e-5` untuk jalur CPU. Kalau nanti GPU delegate dinyalakan, ambangnya harus dilonggarkan dan **selisihnya dilaporkan**, bukan disembunyikan, karena itulah momen di mana kekhawatiran juri menjadi nyata.

Cakupan: keempat model navigasi + rupiah. Effort 2 hari. Repo sudah punya fondasinya di `test/model_inference_test.dart` dan `test/fixtures/`.

**Lapis 2: harness benchmark on-device yang bisa dijalankan siapa saja.**

```dart
// BARU: integration_test/device_bench_test.dart
// Keluaran JSON: device, SoC, cores, RAM, ABI, performanceClass,
//   per model: p50, p90, p99 dari 20 iterasi setelah 5 pemanasan
//   siklus navigasi penuh: p50, p90
//   tier yang diberikan
```

Dijalankan lewat `flutter test integration_test/ -d <device>` di HP fisik, atau di Firebase Test Lab untuk cakupan lebih luas. Hasilnya diakumulasi ke `docs/benchmarks/` sebagai artefak yang di-commit.

**Lapis 3: telemetri lokal, offline-first.**

Prinsip aplikasi ini adalah tidak bergantung server, jadi telemetri **tidak boleh** dikirim ke server sebagai syarat.

```dart
// BARU: lib/services/session_metrics.dart
// Ring buffer di penyimpanan lokal. Per sesi:
//   tier, durasi, p50/p90 siklus, jumlah frame dibuang,
//   lapis mana yang gagal muat, berapa kali COCO dijatuhkan,
//   berapa kali warnUser dipicu, kedalaman antrean TTS
// TIDAK PERNAH: gambar, lokasi, isi ucapan.
// Diekspor sebagai file HANYA saat pengguna menekan
// "Bagikan laporan teknis" di Pengaturan.
```

Ini yang mengubah beta testing dari "tanya kesan pengguna" menjadi "baca angka dari perjalanan sungguhan". Effort 2-3 hari.

**Lapis 4: beta testing terarah, 8-12 perangkat.**

Ya, beta testing diperlukan. Tapi tujuannya harus tepat, dan di sinilah pembedaan Bagian 3.0 membayar dirinya:

> Beta testing **bukan** untuk mengumpulkan data penyesuaian model terhadap hardware.
> Beta testing adalah untuk **memvalidasi batas tier** dan **menemukan mode kegagalan yang tidak muncul di lab**.

Matriks perangkat yang mencerminkan pasar Indonesia, bukan pasar global:

| Tier target | Contoh perangkat | Karakteristik |
|---|---|---|
| D (uji batas bawah) | Redmi 9A / 10A | Helio G25/G35, RAM 2-3 GB, 8x Cortex-A53 |
| C | Samsung A05, Infinix Hot 30 | Helio G85, RAM 4 GB |
| B | Redmi Note 12, Samsung A15 | Snapdragon 685 / Helio G99, RAM 6 GB |
| A | Poco X6, Samsung A55 | Snapdragon 7s Gen 2 / Exynos 1480 |
| A (referensi) | Pixel 8a atau Galaxy S23 | Performance class terdeklarasi |

Minimal dua unit per tier untuk memisahkan variasi antar-unit dari variasi antar-model.

Yang diukur, di luar telemetri lapis 3:

1. **Waktu ke peringatan pertama** dari saat rintangan masuk bidang pandang. Ini metrik keselamatan yang sesungguhnya, dan satu-satunya yang benar-benar menjawab "user terselamatkan vs tersesat".
2. **Perilaku thermal**: p90 siklus di menit ke-1, ke-5, ke-15, ke-30 dalam satu perjalanan.
3. **Ketepatan tier**: berapa persen sesi yang p90 runtime-nya melampaui batas tier yang diberikan saat profiling.
4. **Sesi mana yang memicu `warnUser`,** dan apakah pengguna memahaminya (ini wawancara, bukan angka).

Rekrutmen lewat SLB dan cabang Pertuni. Sesi berpasangan: satu peserta tunanetra, satu pendamping awas yang mencatat kejadian dunia nyata yang tidak masuk telemetri.

**Effort.** Lapis 1-3: 5-7 hari rekayasa. Lapis 4: 3-4 minggu kalender, tergantung ketersediaan perangkat dan peserta.

**Trade-off dan risiko.**

| Risiko | Mitigasi |
|---|---|
| Tidak punya 10 HP untuk diuji | Firebase Test Lab menyewakan device fisik per menit untuk lapis 1-2. Lapis 4 bisa dimulai dengan 4 perangkat yang mewakili tier B dan D, yaitu dua batas yang paling menentukan |
| Beta dengan pengguna tunanetra di jalan sungguhan punya risiko keselamatan nyata | Wajib pendamping awas. Mulai di lingkungan terkendali (koridor kampus, trotoar yang sudah disurvei) sebelum jalan umum. Ini bukan formalitas etik, ini syarat |
| Telemetri lokal bisa dianggap pelanggaran privasi | Tidak ada gambar, tidak ada lokasi, tidak ada isi ucapan. Opt-in eksplisit, diekspor hanya atas tindakan pengguna. Nyatakan ini di dokumen dan di UI |

---

## 5. Implementation Roadmap

Urutannya dipilih dengan satu kriteria: **apa yang paling cepat mengubah klaim menjadi angka.**

### Fase 0 - Quick wins (minggu ini, ~5 hari kerja)

Semuanya kecil, semuanya menutup gap nyata, dan hasilnya sudah bisa ditunjukkan ke juri.

| # | Pekerjaan | File | Hari | Menjawab |
|---|---|---|---|---|
| 0.1 | **Muat `rupiah_calibration.json`.** Hentikan kontradiksi ambang tiga arah (0,75 / 0,85 / 0,9873). Terapkan temperature scaling ke logit, bukan ke probabilitas | `money_tflite_service.dart`, `lib/models/calibration.dart` BARU | 1,0 | C3 |
| 0.2 | **Anggaran thread sadar-core.** Ganti konstanta 4/4/4/2 dengan fungsi `Platform.numberOfProcessors`. Ukur sebelum dan sesudah | 4 service inferensi | 0,5 | C1 |
| 0.3 | **Golden vector test** untuk kelima model | `integration_test/golden_inference_test.dart` BARU | 2,0 | **C1, C4** |
| 0.4 | **`DevicePaceWatch` ke Deteksi Objek** | `detection_provider.dart` | 0,5 | C2, C4 |
| 0.5 | **Peringatan pace berulang + haptik** | `device_pace_watch.dart`, `haptic_service.dart` | 0,5 | C2, C4 |
| 0.6 | **Catat resolusi kamera yang benar-benar didapat**, jangan asumsikan preset | `camera_provider.dart` | 0,5 | C1, C3 |

**0.3 adalah yang paling penting.** Setelah ia hijau di dua HP yang berbeda jauh, klaim "akurasi model kami tidak bergantung perangkat" berhenti menjadi argumen dan menjadi hasil ukur.

### Fase 1 - Device profiling & tiering (2-3 minggu)

| # | Pekerjaan | Hari | Menjawab |
|---|---|---|---|
| 1.1 | `DeviceProfile` + `DeviceProfiler` + persistensi berversi | 3,5 | C1, C2 |
| 1.2 | `device_info_plus` + Jetpack `core-performance` + `abiFilters` | 1,0 | C2 |
| 1.3 | `DeviceTier` + `TierConfig` sebagai data, parameterisasi 4 service | 4,0 | C1, C2 |
| 1.4 | `DeviceCapabilityProvider` + integrasi ke lembar mode | 2,0 | C2 |
| 1.5 | Pengumuman aksesibel, 4 momen, diuji dengan pengguna tunanetra | 2,5 | **C2, C4** |
| 1.6 | Harness benchmark on-device + laporan JSON | 2,0 | C4 |
| 1.7 | `SessionMetrics` telemetri lokal | 2,5 | C4 |

Akhir fase ini: aplikasi tahu HP apa yang dijalankannya, memutuskan apa yang boleh dinyalakan, dan mengatakannya dengan jujur sebelum pengguna keluar rumah.

### Fase 2 - Model tiering (3-4 minggu, sebagian paralel)

| # | Pekerjaan | Hari | Menjawab |
|---|---|---|---|
| 2.1 | Retrain PIDNet `--base-ch 16 --img-size 384`, ekspor FP16 + INT8 | 2,0 (GPU) | C1 |
| 2.2 | Evaluasi semua varian di test set yang sama, **recall per kelas** | 1,5 | **C1, C4** |
| 2.3 | Tetapkan **lantai recall kelas bahaya**; varian yang melanggar tidak dikirim | 0,5 | **C4** |
| 2.4 | `10_tune_thresholds.py` + `03_calibrate_threshold.py` per varian | 2,0 | C3 |
| 2.5 | `ModelRegistry` di app, aset per tier | 2,5 | C1, C2 |
| 2.6 | Play Asset Delivery (opsional, kalau APK terlalu besar) | 3,5 | - |

### Fase 3 - Validasi lapangan (4-6 minggu kalender)

| # | Pekerjaan | Menjawab |
|---|---|---|
| 3.1 | Pengadaan/penyewaan perangkat, minimal 4 unit mewakili tier B dan D | C4 |
| 3.2 | Firebase Test Lab untuk lapis 1-2 di ~15 model HP | C1, C4 |
| 3.3 | Beta terpandu dengan pengguna tunanetra + pendamping awas | **C3, C4** |
| 3.4 | Kalibrasi ulang batas tier dari data lapangan | C2 |
| 3.5 | Susun **Cross-Device Consistency Report** (Bagian 6) | **semua** |

### Yang sengaja TIDAK dikerjakan, dan alasannya

Bagian ini penting untuk dibawa ke presentasi, karena menunjukkan bahwa yang tidak dikerjakan pun sudah dipikirkan.

| Tidak dikerjakan | Alasan |
|---|---|
| Kalibrasi/training ulang model **per device** | Tidak dapat dipelihara, tidak dapat divalidasi, dan menghilangkan ketertelusuran model di aplikasi keselamatan. Variasi input yang nyata ditangani augmentasi di training, yang sudah dilakukan berat di `yolo_aug.py` |
| Menyalakan GPU/NNAPI delegate untuk semua model sekarang | Justru inilah yang **memperkenalkan** inkonsistensi lintas device yang dikhawatirkan juri. NNAPI sendiri sudah dideprekasi di Android 15. Boleh dipertimbangkan setelah golden vector test dan pelaporan selisih ada, tidak sebelumnya |
| Mengembalikan jalur server sebagai fallback untuk mode on-device | Melanggar value proposition intinya. Backend sudah menghapus router-router itu dengan alasan yang tertulis, dan alasannya masih berlaku |
| Model switching dinamis di tengah sesi | Jeda muat beberapa detik tanpa panduan, tepat saat pengguna berjalan. Degradasi runtime sudah ditangani `DevicePaceWatch` dengan cara yang lebih aman |

---

## 6. Bukti Teknis untuk Juri

Bagian ini menjawab: **apa yang harus ada di tangan saat juri bertanya lagi.**

### 6.1 Cross-Device Consistency Report

Satu dokumen, empat tabel. Tabel 1 adalah pembalik argumen.

**Tabel 1 - Identitas numerik lintas device** *(inilah yang menjawab C1 secara langsung)*

| Model | Redmi 9A | Samsung A15 | Poco X6 | Pixel 8a | Max abs diff |
|---|---|---|---|---|---|
| PIDNet-S 3 zona | ✓ | ✓ | ✓ | ✓ | < 1e-6 |
| YOLO11n nav FP16 | ✓ | ✓ | ✓ | ✓ | < 1e-6 |
| YOLO11n nav INT8 | ✓ | ✓ | ✓ | ✓ | 0 (bit-identik) |
| SSD MobileNet COCO | ✓ | ✓ | ✓ | ✓ | 0 (bit-identik) |
| Rupiah MobileNetV2 | ✓ | ✓ | ✓ | ✓ | < 1e-6 |

Kalimat yang menyertainya, dan yang harus diucapkan persis:

> "Untuk input yang sama, kelima model menghasilkan keluaran yang identik di keempat perangkat, dari Redmi 9A sampai Pixel 8a. Akurasi model kami tidak bergantung pada spesifikasi perangkat, dan ini bukan klaim desain melainkan hasil pengukuran yang bisa Bapak/Ibu jalankan ulang dengan satu perintah. Yang bervariasi antar perangkat adalah **kecepatan**, dan itu kami tangani dengan cara yang berbeda, di tabel berikutnya."

**Tabel 2 - Latensi p50/p90 per perangkat**

| Perangkat | SoC | RAM | Prepare | PIDNet | YOLO FP16 | COCO | Siklus p90 | Tier |
|---|---|---|---|---|---|---|---|---|
| Redmi 9A | Helio G25 | 2 GB | | | | | | D |
| Samsung A05 | Helio G85 | 4 GB | | | | | | C |
| Redmi Note 12 | SD 685 | 6 GB | | | | | | B |
| Poco X6 | SD 7s Gen 2 | 8 GB | | | | | | A |

**Tabel 3 - Matriks ketersediaan mode per tier**

| Mode | A | B | C | D |
|---|---|---|---|---|
| Deteksi Objek | ✓ | ✓ | ✓ | ✓ |
| Kenali Uang | ✓ | ✓ | ✓ | ✓ |
| Baca Teks | ✓ | ✓ | ✓ | ✓ |
| Navigasi | 4 lapis | 3 lapis | 2 lapis, "terbatas" | dinonaktifkan, diumumkan |
| Deskripsi Sekitar | butuh internet | butuh internet | butuh internet | butuh internet |
| Cari Objek | butuh internet | butuh internet | butuh internet | butuh internet |

Tabel ini sekaligus menjawab pertanyaan yang belum ditanyakan tapi pasti datang: "kalau HP-nya terlalu lemah, aplikasinya jadi tidak berguna dong?" Jawabannya terbaca langsung dari kolom D.

**Tabel 4 - Biaya akurasi dari tiering** *(kejujuran yang justru menguatkan)*

| Varian | Ukuran | Latensi @SD685 | mAP50 | Recall `lubang` | Recall `tangga` | Recall `tiang` |
|---|---|---|---|---|---|---|
| YOLO11n FP16 640 | 10,1 MB | | | | | |
| YOLO11n INT8 640 | 2,9 MB | | | | | |
| **Lantai yang tidak boleh dilanggar** | - | - | - | **≥ 0,85** | **≥ 0,85** | **≥ 0,80** |

Kalimat penyertanya:

> "Model yang lebih ringan memang sedikit kurang akurat, dan angkanya ada di tabel ini. Yang kami tetapkan adalah lantai recall untuk kelas bahaya. Varian yang tidak melewatinya tidak kami kirim ke perangkat mana pun, dan tier yang bersangkutan kami turunkan jadi 'Navigasi dinonaktifkan'. Kami memilih mengakui tidak bisa daripada mengirim model yang melewatkan tiang setinggi kepala."

### 6.2 Device Support Policy (satu halaman)

Dokumen pendek berisi: definisi keempat tier, kriteria latensi masing-masing, matriks mode, apa yang diumumkan ke pengguna di tiap tier, dan cara menjalankan ulang benchmark. Ini artefak yang menunjukkan bahwa "spek minimum" bukan angan-angan tapi kebijakan tertulis.

### 6.3 Demo langsung, tiga menit

Urutan yang paling meyakinkan, dan semuanya bisa dilakukan dengan kode yang ada plus Fase 0-1:

1. **Mode pesawat menyala.** Deteksi Objek, Kenali Uang, Baca Teks berjalan penuh. Ini membuktikan value proposition-nya, bukan menceritakannya.
2. **HP low-end masuk mode Navigasi.** Tunjukkan `DevicePaceWatch` menjatuhkan lapis COCO, lalu mengumumkan *"Ponsel ini memproses jalur lebih lambat dari biasanya."* Ini fitur yang **sudah ada hari ini**, dan menunjukkan bahwa masalah yang juri angkat sudah diantisipasi sebelum ditanyakan.
3. **HP tier D membuka lembar mode.** TalkBack membacakan item Navigasi sebagai tidak tersedia beserta alasannya, **sebelum** ditekan.
4. **Jalankan `integration_test/golden_inference_test.dart` di dua HP berbeda** di depan juri. Keduanya hijau. Ini bukti langsung untuk C1.

### 6.4 Kerangka jawaban lisan per poin

| Poin juri | Kalimat pembuka |
|---|---|
| C1 akurasi tidak konsisten | *"Kami memisahkan dua hal yang sering tercampur: akurasi dan kecepatan. Semua inferensi kami berjalan di kernel CPU yang sama dengan preprocessing yang kami tulis sendiri, sehingga keluarannya identik lintas perangkat. Kami membuktikannya dengan golden vector test yang bisa dijalankan ulang di sini. Yang memang bervariasi adalah kecepatan, dan itu kami tangani dengan tiering."* |
| C2 spek minimum + notifikasi | *"Spek minimum kami definisikan bukan dari nama chipset, tapi dari latensi terukur pada model yang benar-benar kami pakai, karena nama chipset bukan prediktor yang baik. Aplikasi mengukur sendiri di perangkat pengguna saat onboarding, lalu memberi tahu lewat suara, sebelum pengguna keluar rumah, apa yang bisa dan tidak bisa. Dan kami tidak pernah berhenti di 'tidak kompatibel'; kalimatnya selalu menyebut apa yang masih berfungsi."* |
| C3 kalibrasi per device | *"Kalibrasi per device tidak kami lakukan, dan alasannya bukan karena mahal. Di aplikasi keselamatan, model yang berbeda-beda per perangkat berarti tidak ada lagi satu model yang bisa diaudit. Variasi yang nyata datang dari kamera, bukan dari CPU, dan itu kami tangani di training: pipeline kami sudah mensimulasikan malam, bayangan, hujan, silau, dan kamera resolusi rendah. Yang kami kalibrasi adalah ambang keputusan per varian model, dan kami punya file kalibrasinya."* |
| C4 safety-critical | *"Kami setuju sepenuhnya, dan itu sebabnya kami memilih menonaktifkan mode daripada menjalankannya setengah-setengah. Kode kami sudah menolak menyalakan Navigasi kalau salah satu dari empat lapisnya gagal, karena satu nama mode tidak boleh dipakai untuk dua tingkat perlindungan yang berbeda. Yang kami tambahkan adalah lantai recall untuk kelas bahaya, dan varian model yang tidak melewatinya tidak kami kirim."* |

### 6.5 Yang harus diakui apa adanya kalau ditanya

Menyembunyikan ini akan lebih merugikan daripada menyebutnya lebih dulu:

1. **Jalur GPU delegate PIDNet gagal di perangkat nyata** karena sumbu batch dinamis dari `07_export_onnx.py`. Konsekuensinya semua inferensi CPU. Ini menurunkan kecepatan, tapi menaikkan konsistensi, dan sudah terdokumentasi di kode sebagai keputusan sadar untuk jatuh ke CPU daripada mode navigasi yang tidak pernah menyala.
2. **Belum ada satu angka pun dari HP sungguhan** yang tercatat. Fase 0.3 dan 1.6 memperbaikinya, dan sampai itu selesai, semua klaim konsistensi adalah argumen arsitektur, bukan bukti empiris.
3. **False positive non-rupiah belum terpecahkan.** `money_tflite_service.dart:95-110` mendokumentasikan bahwa gambar bukan-uang bisa disebut "Rp5.000" dengan keyakinan 89,1%, dan menyimpulkan sendiri bahwa tidak ada ambang yang memisahkannya tanpa ikut membuang jawaban benar. Perbaikannya di training, dengan menambah kelas OOD. Ini bukan masalah lintas device, tapi ia masalah keselamatan yang nyata dan ada di roadmap yang sama.
4. **Akurasi rupiah yang jujur adalah 92-96%, bukan 99,52%.** README `rupiah_vision_revised` membuka dengan pengakuan bahwa angka lama palsu karena kebocoran split per-crop. Menyebut angka yang lebih rendah tapi jujur, sambil menjelaskan mengapa, jauh lebih kuat daripada mempertahankan angka yang tidak bisa dipertanggungjawabkan.

---

## Lampiran A - Indeks file yang dirujuk

| File | Peran dalam analisis ini |
|---|---|
| `backend/main.py` | Pembagian server vs on-device; router yang dihapus dan alasannya |
| `backend/routers/support.py` | `/api/capabilities` |
| `guidio_app/lib/services/device_pace_watch.dart` | Pengawas kecepatan yang sudah ada; fondasi S4 |
| `guidio_app/lib/services/pidnet_service.dart:520-640` | Fallback GPU→CPU; probing kapabilitas runtime |
| `guidio_app/lib/services/tflite_service.dart:238` | `threads = 4` konstan |
| `guidio_app/lib/services/yolo_navigasi_service.dart:69` | `threads = 4` konstan |
| `guidio_app/lib/services/yolo_nav_int8_service.dart:71` | `threads = 4` konstan |
| `guidio_app/lib/services/money_tflite_service.dart` | Ambang bertentangan; kontrak preprocessing; batas OOD |
| `guidio_app/lib/services/nav_frame_converter.dart` | Preprocessing Dart murni, sumber determinisme |
| `guidio_app/lib/services/detection_filter.dart` | Filter bersama TFLite dan server |
| `guidio_app/lib/providers/navigation_provider.dart` | Loop 4 lapis; gerbang biner; integrasi pace watch |
| `guidio_app/lib/providers/capabilities_provider.dart` | Preseden pengumuman pra-mode |
| `guidio_app/lib/providers/camera_provider.dart:933` | `ResolutionPreset.medium` |
| `guidio_app/lib/core/a11y/screen_reader.dart` | Koeksistensi dengan TalkBack |
| `guidio_app/lib/core/speech/tts_queue.dart` | Tier suara info/warning/critical |
| `guidio_app/assets/models/rupiah_calibration.json` | Kalibrasi yang tidak pernah dimuat |
| `guidio_app/android/app/build.gradle.kts` | `minSdk 26`, tanpa `abiFilters` |
| `guidio_app/test/nav_pipeline_bench_test.dart` | Benchmark regresi (CI, bukan HP target) |
| `rupiah_vision_revised/scripts/02_export_tflite.py` | 4 varian + evaluasi per kelas |
| `rupiah_vision_revised/scripts/03_calibrate_threshold.py` | Temperature scaling + ambang tolak |
| `rupiah_vision_revised/scripts/00b_preflight_check.py` | Verifikasi kebocoran dan statistik cahaya |
| `guido_cv_training_revised/scripts/06_train_pidnet.py` | Keluarga `--base-ch` + tabel latensi |
| `guido_cv_training_revised/scripts/07_export_tflite.py` | Ekspor FP16/INT8 |
| `guido_cv_training_revised/scripts/09_distill_yolo.py` | Distilasi, akurasi naik tanpa ukuran naik |
| `guido_cv_training_revised/scripts/10_tune_thresholds.py` | Ambang per kelas, biaya kesalahan asimetris |
| `guido_cv_training_revised/scripts/yolo_aug.py` | Augmentasi kondisi sulit |

## Lampiran B - Referensi eksternal

- [LiteRT Delegates, Google AI Edge](https://ai.google.dev/edge/litert/performance/delegates) - delegate berkomputasi pada presisi berbeda dari CPU; GPU memakai float untuk model terkuantisasi
- [tensorflow/tensorflow#56301](https://github.com/tensorflow/tensorflow/issues/56301) - model TFLite berperilaku berbeda di delegate NNAPI-GPU
- [NNAPI Migration Guide, Android Developers](https://developer.android.com/ndk/guides/neuralnetworks/migration-guide) - NNAPI dideprekasi di Android 15; vendor mengimplementasikannya tidak merata
- [GPU acceleration delegate, Google AI Edge](https://ai.google.dev/edge/litert/android/gpu) - percepatan GPU vs CPU
- [Performance class, Android Developers](https://developer.android.com/topic/performance/performance-class) - Media Performance Class dan Jetpack Core Performance
- [Device Tiering on Android, Paras Sehgal](https://medium.com/@parassehgal10/device-tiering-on-android-a-practical-guide-to-improving-app-performance-across-diverse-devices-7666df91b2b0) - praktik tiering perangkat
- [MLPerf Mobile Inference Benchmark, MLSys 2022](https://proceedings.mlsys.org/paper_files/paper/2022/file/a2b2702ea7e682c5ea2c20e8f71efb0c-Paper.pdf) - metodologi benchmark inferensi mobile
- [A Benchmark for ML Inference Latency on Mobile Devices, EdgeSys 2024](https://qed.usc.edu/paolieri/papers/2024_edgesys_mobile_inference_benchmark.pdf) - variasi latensi lintas tier perangkat
- [AI Benchmark: Running DNNs on Android Smartphones, ECCVW 2018](https://openaccess.thecvf.com/content_ECCVW_2018/papers/11133/Ignatov_AI_Benchmark_Running_Deep_Neural_Networks_on_Android_Smartphones_ECCVW_2018_paper.pdf) - suite benchmark inferensi Android
