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
| **Navigasi** | Arahan jalur trotoar 3 zona | Tidak, empat model on-device |
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
- **Navigasi jalur.** Empat model TFLite berjalan paralel dari satu frame yang
  sama: PIDNet-S (segmentasi 3 zona), YOLO11n custom FP16 (enam kelas bahaya
  jalanan), YOLO11n INT8 (enam kelas yang sama, tata letak NCHW, menambal
  `tiang` yang tidak pernah menyala di varian FP16), dan SSD MobileNet COCO
  yang disaring ke 15 kelas yang bisa menghalangi langkah. Lihat bagian 5 soal
  kenapa empat, bukan dua.
- **Perintah suara (intent parsing).** `CommandParser` di Flutter mencocokkan
  24 intent baku dari ratusan variasi ucapan secara offline, 0 ms.
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
│  Kamera ──▶ MobileNetV2 INT8 ──────▶ NominalCard ──▶ TTS             │
│             (224x224, uang rupiah)   (nada lugas / berpagar)         │
│                                                                      │
│  Kamera ──▶ PIDNet-S ──────────────▶ ZoneIndicator ──▶ TTS+Getar     │
│         ├─▶ YOLO11n FP16 (6 kelas)  ┐                                │
│         ├─▶ YOLO11n INT8 (6 kelas)  ├▶ mergeNavObstacles             │
│         └─▶ SSD MobileNet COCO      ┘  (anti sebutan ganda)          │
│             (disaring ke 15 kelas)                                   │
│                                                                      │
│  Kamera ──▶ ML Kit Text Recognition ──▶ blok teks ──▶ TTS            │
│                                                                      │
│  Suara ──▶ CommandParser (offline) ──▶ 24 intent baku, ~0 ms         │
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
caption Bahasa Inggris. Flutter menerjemahkannya **di perangkat** lewat
`services/translation_service.dart`, yang memakai Google ML Kit On-Device
Translation: offline saat dipakai, tanpa LLM, dan tidak mengarang isi baru.

**Yang dibacakan ke pengguna selalu Bahasa Indonesia.** Kalau modelnya belum
siap atau terjemahannya tidak layak, `toIndonesian` mengembalikan null (tidak
pernah setengah kalimat) dan yang diucapkan adalah keadaan sebenarnya dalam
Bahasa Indonesia, bukan caption Inggrisnya. Membacakan kalimat Inggris kepada
tunanetra di pasar dan warung Indonesia bukan memberi informasi yang lebih
sedikit, melainkan nol informasi yang terdengar seperti jawaban. Karena itu
kesiapan penerjemah dijaga: kegagalan unduhan tidak permanen dalam satu sesi,
dan `prewarm()` diulang saat masuk Mode Asisten Suara.

Pendahulunya, `core/voice/scene_translator.dart`, adalah kamus kata-per-kata
buatan sendiri dan sudah dihapus. Cakupannya tidak konsisten, dan pengguna yang
mengandalkan telinga tidak punya cara menebak versi mana yang sedang dia dengar.

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

**6. Nominal uang selalu disebut, tapi tidak selalu dengan nada yakin.**
Ini berubah dari versi sebelumnya, yang menolak menjawab di bawah ambang.
Penolakan itu terdengar seperti pengaman, tapi di lapangan justru mematikan
fiturnya: kasus paling biasa, uang di meja difoto sambil berdiri, berakhir
buntu di kartu peringatan tanpa jalan keluar, dan pengguna yang tidak melihat
layar tidak punya cara menebak apa yang kurang.

Sekarang nominalnya selalu keluar, dan `MoneyResult.certain` yang membedakan
nadanya: lolos gerbang dibacakan lugas ("Lima puluh ribu rupiah"), tidak lolos
wajib berpagar ("Sepertinya lima puluh ribu rupiah") plus ajakan mengecek
ulang. Gerbangnya dua jalur: keyakinan >= 0,85, atau margin ke juara dua >= 0,50
dengan keyakinan >= 0,80. Risikonya dipindah, bukan dihapus, dan lapisan atas
tidak boleh mengabaikan `certain`.

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

### Kenapa Mode Navigasi memakai empat model, bukan dua

`YoloNavigasiService` (FP16, `yolo11n_navigasi.tflite`) dilatih khusus untuk
enam kelas bahaya jalanan Indonesia. Itu satu-satunya sumber untuk `lubang`,
`got_terbuka`, dan `tangga`: tidak ada padanannya di COCO, dan justru ketiganya
yang paling berbahaya karena tidak terasa tongkat sampai sudah dekat.

Tapi model itu lemah persis pada kelas yang berlimpah di dataset umum. Diuji
lewat `test/run_corridor_test.py` pada fixture `04_motor_dan_orang.png`, dua
motor terparkir dan satu orang berjalan, semuanya jelas terlihat mata: model
custom melaporkan nol motor dan nol orang.

SSD MobileNet COCO tidak akan pernah tahu apa itu got terbuka, tapi `person`
dan `motorcycle` adalah dua kelas dengan contoh terbanyak di seluruh COCO.
Masing-masing menutup lubang yang tidak bisa ditutup yang lain.

Lapis keempat, `YoloNavInt8Service` (`yolo11n.tflite`, INT8, NCHW
`[1,3,640,640]`), menambal satu kelas yang tidak tertutup keduanya: `tiang`.
Kelas itu tidak ada di COCO sebagai benda tunggal, dan varian FP16 tidak pernah
memunculkannya sama sekali. Pada fixture `03_tiang_listrik.png` selisihnya
telanjang: FP16 memberi skor puncak 0,0000, INT8 memberi 0,3777. Tiang justru
golongan paling berbahaya bagi pengguna tongkat, karena tongkat melewatinya
tanpa menyentuh dan kepala yang menemukannya.

Karena tata letak tensornya berbeda, lapis keempat punya service sendiri: ia
menerima tensor NHWC yang sama lalu mentransposenya ke NCHW, dan menolak memuat
model yang bukan NCHW. Duplikat antara lapis FP16 dan INT8 dibuang berdasarkan
IoU >= 0,45 sebelum digabung dengan COCO.

Keempatnya **wajib termuat** sebelum mode ini menyala. Sebelumnya lapis COCO dan
INT8 opsional, dan akibatnya satu mode memakai nama yang sama untuk dua tingkat
perlindungan yang berbeda jauh tanpa pengguna pernah diberi tahu yang mana yang
sedang aktif.

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

Empat model per frame di ponsel lima tahun bisa berkali lipat lebih lambat.
Yang berbahaya bukan lambatnya, melainkan diamnya: arahan tetap diucapkan dengan
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
| Pengenalan uang on-device | MobileNetV2 transfer learning, TFLite INT8, 224x224, 7 kelas |
| Segmentasi jalur on-device | PIDNet-S, TFLite, 3 zona |
| Rintangan navigasi on-device | YOLO11n custom FP16, TFLite NHWC, 6 kelas |
| Lapis ketiga navigasi | SSD MobileNet COCO, disaring ke 15 kelas |
| Lapis keempat navigasi | YOLO11n INT8, TFLite NCHW, 6 kelas, penambal `tiang` |
| Perbaikan kontras kamera lama | Peregangan titik hitam, selektif per frame |
| Baca teks on-device | Google ML Kit Text Recognition |
| Pelacakan objek | SORT, ditulis murni dengan Dart |
| Intent parsing | `CommandParser` lokal, berlapis, 0 ms offline |
| Penjadwalan narasi | `NarrationScheduler` lokal, beranggaran kata |
| Terjemahan caption | Google ML Kit On-Device Translation (`translation_service.dart`) |
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
│   │   │   ├── voice/             CommandParser, NarrationScheduler, intents, voice_log
│   │   │   ├── speech/            TtsQueue bertingkat
│   │   │   ├── layout/            Token zona layar
│   │   │   ├── net/               ApiClient + FramePacer, frame_codec
│   │   │   └── state/             Penggabungan kondisi global
│   │   ├── models/                Tipe hasil deteksi bersama
│   │   ├── theme/                 Warna, tipografi, spasi, tema
│   │   ├── widgets/               Komponen sistem desain
│   │   ├── providers/             State per mode dan kondisi global
│   │   ├── services/              TFLite deteksi/uang/PIDNet/YOLO x2, ML Kit, TTS, terjemahan
│   │   ├── screens/               6 mode, splash, panduan, izin, pengaturan
│   │   └── mock/                  Data tiruan untuk menguji state tanpa model
│   ├── test/                      Uji Flutter + fixtures bersama, lihat guidio_app/README.md bagian 14
│   ├── tool/                      setup_tflite_linux.sh, eval_rupiah_litert.py
│   ├── blobs/                     Pustaka native TFLite untuk host, tidak ikut ke APK
│   └── assets/models/             5 model yang benar-benar dibundel, lihat bagian 10
└── backend/                       Server FastAPI
    ├── README.md                  Panduan backend dan rujukan endpoint
    ├── db/                        Skema PostgreSQL dan data rujukan
    ├── routers/                   3 router aktif
    ├── services/                  YOLOE, Moondream2, gerbang gambar
    ├── tests/                     pytest, fixtures-nya menumpang guidio_app/test/fixtures
    └── _archive/                  Router, service, dan util lama yang sudah pindah on-device
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
| `ssd_mobilenet.tflite` | ~4,0 MB | Deteksi rintangan, sekaligus lapis COCO navigasi |
| `labelmap.txt` | ~1 KB | Label COCO |
| `rupiah_classifier_int8.tflite` | ~2,8 MB | Kenali Uang, 7 pecahan |
| `pidnet_s_3zona.tflite` | ~2,5 MB | Segmentasi jalur 3 zona |
| `yolo11n_navigasi.tflite` | ~10,1 MB | Rintangan navigasi FP16, 6 kelas |
| `yolo11n.tflite` | ~2,9 MB | Rintangan navigasi INT8 NCHW, lapis keempat |
| **Total di APK** | **~22,3 MB** | |

Berkas lain di `assets/models/` (`rupiah_classifier_fp16.tflite`,
`uang_rupiah.tflite`, `pidnet_s_3zona_fp16.tflite`, `yolo11n_e100_*.tflite`,
`yoloe_find.onnx`, dan berkas `.onnx` lainnya) **tidak dibundel**. Semuanya
arsip, varian yang tidak dimuat kode, atau percobaan.

Menambah berkas ke folder itu tidak otomatis membundelnya, dan **mencabutnya
juga tidak otomatis aman**. `yolo11n.tflite` pernah dicabut dari daftar, dan
pencabutan itu diam-diam melumpuhkan lapis keempat: `rootBundle.load` gagal,
`_int8Ready` tetap false, dan pipeline yang dikira empat lapis cuma tiga tanpa
galat, tanpa log, tanpa perbedaan yang terlihat di layar.

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
- Intent parsing lokal: 24 intent, ratusan variasi ucapan multi-bahasa dan
  dialek, berjalan offline.
- Pengaman uang berupa nada jawaban: nominal yang tidak lolos gerbang keyakinan
  wajib dibacakan berpagar ("Sepertinya ..."), bukan lugas.

### Masih terbatas, dan ini yang paling penting diketahui

**Model uang belum tangguh pada framing kamera, dan angkanya belum bisa diukur
dari host Linux.** Skor lab-nya 97,98%, tapi angka itu diukur pada crop rapat
hasil bounding box, bukan pada frame kamera. Yang salah adalah cara model
dilatih, bukan bobotnya: dataset training tidak pernah memuat uang yang kecil
di dalam bidang.

Sejak model yang dibundel berganti ke varian INT8, `flutter test` di Linux
**tidak lagi bisa mengukurnya sama sekali**. Runtime desktop di `blobs/`
berasal dari `tflite_flutter_plugin` v0.5.0 (2021) dan tidak sanggup
menjalankan model terkuantisasi: ia memuatnya tanpa mengeluh lalu mengembalikan
distribusi rata 1/7 untuk masukan apa pun. Kelima fixture pulang sebagai
Rp1.000 dengan keyakinan 14,5%, yaitu chance level, dan itu bukan pengukuran
model. Android memakai LiteRT 1.4.0 dan menjalankan model yang sama dengan
benar.

Angka yang mewakili ponsel diukur lewat `guidio_app/tool/eval_rupiah_litert.py`
(LiteRT modern di Python) atau langsung di perangkat. Rinciannya di
`guidio_app/README.md` bagian 3.

**Empat dari enam kelas YOLO navigasi FP16 tidak pernah menyala.** Ini temuan
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

Model lama `yolo11n.tflite` justru sehat, dan ia benar mendeteksi `tiang` pada
fixture yang gagal total di model baru (0,3777 lawan 0,0000). Bentuknya NCHW
sehingga dulu ditolak `YoloNavigasiService` yang menyusun NHWC.

**Itu sudah ditambal, tapi tambalannya bukan perbaikan.** Model lama itu
sekarang dimuat `YoloNavInt8Service` sebagai lapis keempat, service terpisah
yang mentranspose tensornya sendiri ke NCHW. Jadi `tiang` hidup lagi di Mode
Navigasi. Yang belum beres tetap belum beres: `got_terbuka`, `orang`, dan
`motor` masih mati di varian FP16, dan **proses ekspornya harus diperiksa ulang
sebelum melakukan retrain apa pun.**

Konsekuensi yang perlu diketahui: sampai ini beres, lapis SSD COCO adalah
satu-satunya sumber deteksi orang dan motor di Mode Navigasi, `got_terbuka`
tidak punya sumber sama sekali, dan PIDNet-S adalah lapis pengaman yang
sesungguhnya. Perbaikan kontras kamera lama juga belum bisa dinilai adil,
karena model yang rusak memberi respons erratic. Ukur ulang dengan
`test/run_corridor_test.py --enhance off` setelah ekspornya diperbaiki.

Uji navigasi di `test/model_inference_test.dart` hanya menguji varian FP16.
Lapis INT8 yang menambalnya belum punya uji sendiri, jadi kalau berkasnya
tercabut lagi dari `pubspec.yaml`, tidak ada satu pun test yang merah.

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
