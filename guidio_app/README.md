# Vinara Mobile (guidio_app)

Aplikasi Flutter untuk Android. Inilah bagian yang dipegang pengguna, dan
bagian yang paling menentukan apakah sistem ini benar benar bisa dipakai
orang yang tidak melihat layar.

Dua fitur berjalan penuh di dalam ponsel tanpa internet: peringatan
rintangan dan pengenalan uang.

---

## Daftar isi

1. [Cara kerja singkat](#1-cara-kerja-singkat)
2. [Enam mode dan layarnya](#2-enam-mode-dan-layarnya)
3. [Dua model AI di dalam ponsel](#3-dua-model-ai-di-dalam-ponsel)
4. [Sistem desain: token dan komponen](#4-sistem-desain-token-dan-komponen)
5. [Aturan tata letak yang mengikat](#5-aturan-tata-letak-yang-mengikat)
6. [Antrean suara bertingkat](#6-antrean-suara-bertingkat)
7. [Panel debug untuk menguji semua state](#7-panel-debug-untuk-menguji-semua-state)
8. [Aksesibilitas](#8-aksesibilitas)
9. [Struktur folder](#9-struktur-folder)
10. [Menjalankan](#10-menjalankan)
11. [Koneksi ke Backend Laptop (HP Fisik)](#11-koneksi-ke-backend-laptop-hp-fisik)

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
Suara + getar ke pengguna
```

Penyaring itu penting. Tanpa penyaring, ponsel akan bicara tanpa henti
setiap kali kamera bergeser sedikit, dan pengguna justru berhenti
mendengarkan.

### Aturan penyaring

- Benda lebih jauh dari 10 meter diabaikan.
- Benda yang cuma muncul di satu frame diabaikan (harus terlihat minimal
  dua kali berturut turut).
- Benda yang sama tidak diumumkan ulang sebelum jeda tertentu: 2 detik untuk
  bahaya, 3 detik untuk hati hati, 5 detik untuk informasi biasa.
- Kalau benda terdeteksi **mendekat**, jeda dipotong setengah supaya
  peringatan datang lebih cepat.
- Maksimal 2 pesan sekaligus. Lebih dari itu, manusia tidak sanggup
  memprosesnya sambil berjalan.

---

## 2. Enam mode dan layarnya

Aplikasi terbuka langsung ke Mode Deteksi Objek yang sudah aktif. Tidak ada
layar beranda, karena setiap layar perantara berarti penundaan sebelum
pengguna mendapat informasi keselamatan.

| Mode | Berkas layar | Butuh internet? |
|---|---|---|
| Deteksi Objek | `screens/tuntun_screen.dart` | Tidak |
| Kenali Uang | `screens/money_screen.dart` | Tidak |
| Baca Teks | `screens/ocr_screen.dart` | Ya |
| Navigasi | `screens/navigasi_screen.dart` | Sebagian |
| Asisten Suara | `screens/voice_screen.dart` | Ya |
| Cari Objek | `screens/find_object_screen.dart` | Ya |

Layar penunjang: splash, panduan awal 3 langkah, permintaan izin, dan
pengaturan berisi 8 opsi yang tersimpan permanen.

Berpindah mode ada dua jalan: mengucapkan namanya (satu langkah), atau lewat
tombol Pilih Mode di kanan bawah (dua langkah). Menu adalah cadangan untuk
situasi pengguna tidak bisa bicara, misalnya di tempat yang sangat bising.

### Satu satunya konfirmasi di seluruh aplikasi

Keluar dari Mode Navigasi saat pengguna terdeteksi masih berjalan akan
memunculkan dialog konfirmasi. Selain itu, semua perpindahan mode langsung
jalan tanpa bertanya. Konfirmasi yang terlalu sering membuat pengguna
menekan "ya" secara refleks, dan itu justru berbahaya.

---

## 3. Dua model AI di dalam ponsel

### Model deteksi rintangan

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/ssd_mobilenet.tflite` |
| Ukuran | sekitar 4 MB |
| Ukuran masukan | 300 x 300 piksel |
| Nilai piksel | 0 sampai 255, tidak dinormalkan |
| Kecepatan | sekitar 30 milidetik per gambar |
| Dijalankan di | thread terpisah, supaya layar tidak macet |

Catatan penting: di folder `assets/models/` ada juga `yolo11l_float32.tflite`
dan `yolo11n.tflite`. **Keduanya tidak dipakai** oleh kode saat ini dan hanya
sisa percobaan. Yang benar benar dimuat adalah `ssd_mobilenet.tflite`.

### Model pengenalan uang

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/uang_rupiah.tflite` |
| Arsitektur | MobileNetV2, dilatih ulang untuk uang rupiah |
| Ukuran masukan | 224 x 224 piksel |
| Nilai piksel | dibagi 255, sesuai cara model dilatih |
| Jumlah kelas | 6 pecahan, emisi 2016 |

Urutan kelas **wajib** persis seperti saat model dilatih:

```
100.000 = 0    10.000 = 1    20.000 = 2
  2.000 = 3    50.000 = 4     5.000 = 5
```

Urutan itu ada di `MoneyTFLiteService.classValues`. Kalau model diganti,
urutan ini dan kolom `class_index` di basis data server harus diubah
bersamaan, kalau tidak nominal akan tertukar.

**Keterbatasan yang harus disebut jujur:** model ini tidak mengenali pecahan
Rp1.000, dan belum mengenali emisi 2022.

**Aturan yang tidak bisa ditawar:** kalau keyakinan model di bawah 0,85,
aplikasi **tidak menampilkan angka sama sekali**, hanya instruksi perbaikan
seperti *"Belum yakin, dekatkan sedikit dan tahan diam"*. Menyebut nominal
yang salah kepada orang yang tidak bisa memeriksa sendiri berarti kerugian
uang nyata. Lebih baik mengaku ragu daripada menebak.

Nominal selalu ditampilkan dan dibacakan dalam **dua bentuk**: angka
(Rp50.000) dan kata (lima puluh ribu rupiah).

---

## 4. Sistem desain: token dan komponen

Semua warna, ukuran huruf, dan jarak diambil dari satu sumber di
`lib/theme/`. Tidak ada layar yang menulis nilai warna atau ukuran secara
langsung. Tujuannya supaya perubahan satu token langsung berlaku menyeluruh.

### Aturan warna yang penting

Warna terang seperti hijau dan kuning **tidak boleh** menjadi latar teks
putih, karena kontrasnya gagal untuk pengguna low vision. Karena itu setiap
tingkat bahaya punya dua warna: satu untuk ikon dan bidang besar, satu lagi
yang lebih pekat khusus untuk teks.

Warna juga tidak pernah menjadi satu satunya penanda. Setiap tingkat bahaya
punya **bentuk ikon berbeda**:

| Tingkat | Bentuk ikon | Kata di kartu |
|---|---|---|
| Bahaya | segi delapan | "Bahaya" |
| Hati hati | segitiga | "Hati-hati" |
| Informasi | persegi membulat | "Info" |
| Aman | lingkaran | "Aman" |

Jadi pengguna buta warna tetap bisa membedakannya, dan pembaca layar tetap
mendapat kata yang jelas.

### 16 komponen

Berada di `lib/widgets/`, semuanya memakai token di atas.

`ModeBadge`, `AlertCard`, `BottomActionBar`, `FullScreenButton`,
`ModePickerSheet`, `VoiceOrb`, `StatusBanner`, `ZoneIndicator`,
`ResultPanel`, `CameraHealthToast`, `GuideFrame`, `ChatBubble`,
`NominalCard`, `TargetChip`, `SpeakingIndicator`, `PermissionCard`.

---

## 5. Aturan tata letak yang mengikat

Layar dibagi menjadi zona dari atas ke bawah. **Tidak ada elemen yang boleh
menimpa elemen lain.** Kalau dua elemen meminta ruang yang sama, yang
prioritasnya lebih rendah digeser atau diperingkas, bukan ditumpuk.

| Zona | Tinggi | Aturan |
|---|---|---|
| Area aman atas | 32 dp | Tidak pernah diisi |
| Banner status | 0, 56, atau 64 dp | **Maksimum satu di layar** |
| Badge mode | 40 dp | Turun otomatis saat banner muncul |
| Konten dan kamera | fleksibel | Menyusut, tidak pernah mendorong zona lain |
| Tumpukan kartu | maksimal 2 kartu | Kartu ketiga menjadi baris "dan 2 objek lain" |
| Bar tombol bawah | 112 dp | **Tetap**, tidak boleh tertutup apa pun |

Kalau dua masalah global terjadi bersamaan (misalnya offline dan baterai
kritis), keduanya digabung menjadi **satu** banner dengan tingkat tertinggi,
bukan dua banner bertumpuk.

Tiga tombol bawah tidak pernah berubah posisi, jumlah, maupun urutannya:
Ambil gambar di kiri, Bicara di tengah, Pilih mode di kanan. Bagi pengguna
yang tidak melihat layar, posisi tetap itu satu satunya peta yang mereka
punya.

---

## 6. Antrean suara bertingkat

Ada di `lib/core/speech/tts_queue.dart`.

| Tingkat | Perilaku |
|---|---|
| Critical | Memotong semua suara, dan tidak bisa dipotong pengguna |
| Warning | Memotong Info, boleh dipotong pengguna |
| Info | Mengantre, dibuang kalau sudah menunggu lebih dari 2 detik |

Info sengaja dibuang saat basi. Informasi tentang benda yang sudah terlewat
tiga detik lalu bukan cuma tidak berguna, tapi juga menghalangi peringatan
yang lebih baru.

Getar selalu mendampingi suara, bukan menggantikannya. Di lingkungan bising
seperti pasar atau jalan raya, getar sering menjadi sinyal utama yang
benar benar sampai.

---

## 7. Panel debug untuk menguji semua state

Ketuk **5 kali** pada badge mode di kiri atas untuk membuka daftar state.
Memilih satu state memaksa layar ke kondisi itu.

Gunanya: seluruh kondisi tampilan bisa diperiksa tanpa perlu benar benar
menghadirkan situasinya. Misalnya kondisi "baterai 9 persen", "empat objek
sekaligus", atau "server mati" bisa dilihat langsung tanpa harus menunggu
baterai habis atau mematikan server.

Data tiruan untuk keperluan ini ada di `lib/mock/`.

---

## 8. Aksesibilitas

Aplikasi ini harus bisa dipakai dengan layar mati total. Beberapa aturan yang
diterapkan di kode:

- **Urutan fokus** mengikuti zona dari atas ke bawah. Elemen yang sedang
  tidak ada dilewati tanpa mengubah urutan sisanya.
- **Live region** dipakai untuk teks yang berubah sendiri, supaya pembaca
  layar mengumumkannya tanpa pengguna perlu mencari.
- Hanya empat hal yang boleh memotong pembacaan: peringatan bahaya, zona
  jalur berbahaya, nominal uang, dan kegagalan izin. Sisanya sopan menunggu.
- **Label menyebut aksi, bukan alat**: "Ambil gambar", bukan "Kamera".
- **Label tidak pernah menyebut lokasi layar**. Tidak ada "tombol di kanan
  bawah", karena pengguna tidak melihat tata letaknya.
- Tombol yang sedang nonaktif **menyebutkan alasannya**: "Baca teks, tidak
  tersedia, butuh internet".
- Elemen dekoratif seperti bingkai panduan dan kotak deteksi disembunyikan
  dari pembaca layar, karena maknanya sudah dibawa teks lain.

### Ukuran huruf 200 persen

Pengaturan ukuran teks sampai 200 persen berlaku ke seluruh aplikasi. Saat
teks membesar, tata letak berubah dari mendatar menjadi menurun, dan target
sentuh membesar dari 48 menjadi 56 dp. Angka nominal uang tidak dibesarkan
lagi karena sudah 56 sp.

---

## 9. Struktur folder

```
lib/
├── main.dart                 Titik masuk, mendaftarkan seluruh provider
├── core/
│   ├── layout/               Ukuran zona dan aturan pergeseran
│   ├── speech/               Antrean suara bertingkat
│   ├── state/                Penggabungan kondisi global jadi satu banner
│   └── voice/                20 intent perintah suara dan pemarsingnya
├── theme/                    Warna, tipografi, jarak, tema
├── widgets/                  16 komponen sistem desain
├── providers/                State per mode, pengaturan, kondisi global
├── services/
│   ├── tflite_service.dart       Deteksi rintangan on-device
│   ├── money_tflite_service.dart Pengenalan uang on-device
│   ├── server_service.dart       Semua panggilan ke backend
│   ├── tts_service.dart          Mesin suara
│   ├── detection_filter.dart     Penyaring anti banjir suara
│   ├── object_tracker.dart       Pelacak SORT
│   └── haptic_service.dart       Pola getar
├── screens/                  6 mode + splash, panduan, izin, pengaturan
└── mock/                     Data tiruan untuk panel debug
```

---

## 10. Menjalankan

```bash
flutter pub get
flutter run
```

Aplikasi tetap jalan tanpa backend. Deteksi rintangan dan pengenalan uang
berfungsi penuh; mode lain akan menyebut sendiri keterbatasannya.

Alamat server bawaan adalah `10.0.2.2:8000`, yaitu alamat khusus emulator Android
yang menunjuk ke `localhost` laptop. **Untuk HP fisik**, alamat ini tidak berlaku.
Ubah lewat layar Pengaturan di dalam aplikasi (ucapkan "pengaturan" atau ketuk
Pilih Mode → Pengaturan), lalu isi IP laptop Anda di jaringan WiFi yang sama.

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
- Model TFLite **wajib** dijalankan di thread terpisah, jangan di thread
  utama, karena layar akan macet.
- Peringatan bahaya **selalu** memotong suara lain, tidak pernah mengantre.
- Pelacak SORT harus direset saat berganti mode.
- Semua suara memakai Bahasa Indonesia (`id-ID`).
- Aplikasi ini menargetkan Android; iOS belum diuji.

---

## 11. Koneksi ke Backend Laptop (HP Fisik)

Setelah APK diinstall di HP fisik, aplikasi perlu diarahkan ke alamat
backend yang berjalan di laptop.

### Cara cepat: WiFi satu jaringan

1. Jalankan backend di laptop dengan perintah:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

2. Cari IP laptop:
   ```bash
   ip addr show  # Linux — cari bagian wlan0, contoh hasilnya: 192.168.1.5
   ```

3. Di HP, buka Guidio → ucapkan **"pengaturan"** atau tekan
   **Pilih Mode → Pengaturan**

4. Di kolom **Alamat Server**, isi `192.168.1.5:8000`
   (gunakan IP laptop Anda)

5. Tekan **Uji Sambungan** — jika berhasil, waktu tempuh akan muncul

6. Tekan **Simpan**

### Cara alternatif: USB tanpa WiFi (ADB Reverse)

Jika WiFi kampus memblokir koneksi antar-device:

```bash
# Sambungkan HP ke laptop via USB, aktifkan USB Debugging di HP
adb reverse tcp:8000 tcp:8000
```

Setelah perintah itu, isi alamat server di Guidio: `localhost:8000`

### Build APK

```bash
# Build APK release
flutter build apk --release

# Install ke HP via USB
flutter install
# atau:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Penjelasan nilai bawaan alamat server

| Situasi | Alamat yang diisi |
|---|---|
| Emulator Android di laptop | `10.0.2.2:8000` (bawaan, tidak perlu diubah) |
| HP fisik, WiFi sama dengan laptop | IP laptop, contoh: `192.168.1.5:8000` |
| HP fisik, sambung USB + ADB reverse | `localhost:8000` |
