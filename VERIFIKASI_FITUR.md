# GUIDIO: Panduan Uji Fitur (Satu Per Satu)

> **Update terakhir**: 2026-08-23 - disesuaikan ulang dengan kode yang benar-benar
> berjalan. Beberapa isi dokumen versi sebelumnya sudah **tidak berlaku** (endpoint
> backend yang sudah dihapus, tombol Navigasi yang berubah fungsi, Mode Deteksi yang
> kini mulai dalam keadaan MATI). Lihat [bagian 9](#9-perubahan-dari-dokumen-versi-lama)
> untuk daftar perubahannya.
>
> **8 bug ditemukan dan diperbaiki** saat menyusun panduan ini - tiga di antaranya
> membuat fitur diam-diam berhenti bekerja tanpa memberi tahu pengguna. Rinciannya di
> [bagian 10](#10-bug-yang-ditemukan--diperbaiki). **Build ulang APK sebelum menguji.**

Dokumen ini dipakai untuk **menguji manual satu per satu**: apa yang harus diucapkan,
tombol mana yang ditekan, dan **apa yang seharusnya terdengar/terlihat**. Tiap langkah
punya kolom "Ekspektasi" - kalau yang terjadi beda dari itu, berarti ada masalah.

---

## Daftar isi

1. [Cara membaca panduan ini](#1-cara-membaca-panduan-ini)
2. [Persiapan](#2-persiapan)
3. [Peta tombol - wajib paham dulu](#3-peta-tombol-wajib-paham-dulu)
4. [Uji perpindahan mode lewat suara](#4-uji-perpindahan-mode-lewat-suara)
5. [Uji per mode](#5-uji-per-mode)
   - [5.1 Deteksi Objek](#51-mode-deteksi-objek)
   - [5.2 Navigasi](#52-mode-navigasi) ← termasuk tombol kiri nyala/mati
   - [5.3 Kenali Uang](#53-mode-kenali-uang)
   - [5.4 Baca Teks](#54-mode-baca-teks)
   - [5.5 Asisten Suara](#55-mode-asisten-suara)
   - [5.6 Cari Objek](#56-mode-cari-objek)
6. [Uji lintas-mode](#6-uji-lintas-mode-suara-getar-gelap-izin)
7. [Uji backend langsung (tanpa HP)](#7-uji-backend-langsung-tanpa-hp)
8. [Troubleshooting](#8-troubleshooting)
9. [Perubahan dari dokumen versi lama](#9-perubahan-dari-dokumen-versi-lama)
10. [Bug yang ditemukan & diperbaiki](#10-bug-yang-ditemukan--diperbaiki)
11. [Yang TIDAK diperbaiki (keputusanmu)](#11-yang-tidak-diperbaiki-keputusanmu)

---

## 1. Cara membaca panduan ini

Tiap uji punya format sama:

> **Kamu lakukan** → apa yang kamu tekan / ucapkan
> **Ekspektasi** → apa yang HARUS terjadi (suara, getar, tampilan)
> `[ ]` → centang kalau cocok

**Aturan penting saat menguji:** aplikasi ini dibuat untuk pengguna tunanetra, jadi
**patokan utamanya adalah SUARA, bukan layar**. Kalau kamu menekan sesuatu dan layar
berubah tapi tidak ada suara/getar, itu **dihitung gagal** - meskipun secara teknis
fiturnya jalan.

**Tips uji:** coba sesekali menutup mata dan hanya mengandalkan suara. Kalau kamu
bingung "ini nyala atau mati ya?", berarti umpan baliknya kurang.

### Empat mode jalan tanpa internet

| Mode | Butuh backend? |
|---|---|
| Deteksi Objek | ❌ on-device (SSD MobileNet TFLite) |
| Kenali Uang | ❌ on-device (MobileNetV2 TFLite) |
| Baca Teks | ❌ on-device (**ML Kit**, bukan Tesseract server) |
| Navigasi | ❌ on-device (PIDNet-S + YOLO11n + SSD MobileNet COCO) |
| Cari Objek | ✅ **wajib** backend (YOLOE open-vocab) |
| Asisten Suara | ⚠️ perintah & ganti mode jalan offline; **deskripsi suasana** butuh backend |

> Artinya: uji mode 1–4 bisa dilakukan dengan **WiFi dan data HP dimatikan total**.

---

## 2. Persiapan

### 2A. Build & pasang APK

```bash
cd ~/kuliah/lomba/smstr6/guido/project/guidio_app
flutter pub get
flutter analyze          # harus 0 error
flutter build apk --release
flutter install
```

> Uji **release**, bukan debug. Mode Kenali Uang punya jalur simulasi mock yang hanya
> aktif di `kDebugMode` - di debug kamu bisa melihat nominal acak yang tidak nyata.

### 2B. Backend (hanya untuk Cari Objek & Deskripsi Suasana)

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
source venv/bin/activate

sudo systemctl start postgresql        # opsional; backend tetap jalan tanpa DB
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Log startup yang benar:

```
[FindObject] Service terdaftar (lazy-load model YOLOE).
[Moondream2] Service terdaftar (lazy-load, belum dimuat).
=== Vinara Backend siap ===
```

> Tidak akan ada log `[Qwen]`, `[YOLO]` server, `[OCR]`, atau `[Tesseract]` - semuanya
> sudah dipindah on-device atau dihapus.

### 2C. Sambungkan HP ke backend

```bash
ip addr show | grep "inet " | grep -v 127.0.0    # cari IP laptop, mis. 192.168.1.5
```

Di HP: tekan tombol **Pilih mode** (kanan bawah) → **Pengaturan** → **Alamat Server**
→ isi `192.168.1.5:8000` → **Uji Sambungan** → **Simpan**.

Alternatif lewat USB:

```bash
adb reverse tcp:8000 tcp:8000    # lalu isi alamat: localhost:8000
```

---

## 3. Peta tombol: wajib paham dulu

Di bawah layar selalu ada **tiga tombol yang tidak pernah pindah tempat**:

```
┌──────────────────────────────────────────────┐
│   [ KIRI ]        (( MIC ))       [ KANAN ]   │
│  aksi utama        bicara        pilih mode   │
└──────────────────────────────────────────────┘
```

### Tombol TENGAH (Mic): sama di semua mode

- Dari mode mana pun **selain** Asisten Suara: menekannya **membuka VoiceScreen sebagai
  overlay** (layar mode di belakang tidak hilang) dan **langsung mulai mendengarkan**.
- Ada getar 100 ms sebagai tanda tekanan terdaftar.
- Saat mic aktif, **tombol kiri dan kanan dinonaktifkan** (biar tidak ada aksi tabrakan).
- Kalau izin mikrofon dicabut, tombol jadi abu-abu dan TalkBack membacanya
  "Bicara, tidak tersedia, izin mikrofon belum diberikan".

### Tombol KANAN (Pilih mode)

Membuka lembar berisi 6 mode + Pengaturan. Ini jalur cadangan kalau tidak bisa bicara.

### Tombol KIRI: **beda-beda tiap mode**. Ini yang paling sering bikin bingung:

| Mode | Label tombol kiri | Yang dilakukan |
|---|---|---|
| **Deteksi Objek** | `Hentikan` / `Lanjutkan` | **Nyala/mati deteksi rintangan** |
| **Navigasi** | `Matikan Suara` / `Nyalakan Suara` | **Bisu/nyala SUARA panduan** (bukan mematikan navigasi) |
| **Kenali Uang** | `Kenali Uang` | 1 tekan = 1 analisis nominal |
| **Baca Teks** | `Baca teks` → `Jeda bacaan` → `Lanjutkan bacaan` | Berubah mengikuti alur |
| **Asisten Suara** | `Ulangi jawaban` | Bacakan ulang jawaban terakhir |
| **Cari Objek** | `Kirim - cari [barang]` | Kirim frame ke server |

**Padanan suara:** ucapan **"jepret"** / **"ambil gambar"** / **"foto"** menjalankan
**persis** apa yang dilakukan tombol kiri di mode itu. Jadi kalau kamu di Navigasi lalu
bilang "jepret", yang terjadi adalah suara panduan dibisukan - bukan memotret.

**Tombol nonaktif tidak pernah diam.** Kalau kamu menekan tombol kiri yang sedang
mati, ia tetap mengucapkan alasannya (mis. "Kirim - cari barang. tekan tombol bicara
lalu sebutkan barangnya") + getar pendek. Ini sengaja - tombol yang diam tidak bisa
dibedakan dari aplikasi yang hang.

---

## 4. Uji perpindahan mode lewat suara

Ini uji paling sering dipakai. **Alurnya:**

1. Tekan tombol **Mic** (tengah bawah) → terasa getar, layar overlay muncul, mic
   **langsung mendengarkan** (tidak perlu tekan lagi).
2. Ucapkan perintah. Kamu punya waktu **maksimal 10 detik**, dan rekaman **otomatis
   ditutup setelah 2 detik hening** - jadi berhenti sejenak setelah selesai bicara.
3. Ekspektasi: overlay tertutup sendiri, lalu terdengar:
   **"Baik. `<Nama Mode>` aktif. `<satu kalimat panduan>`"**

> Kalimat panduan hanya dibacakan pada **3 kunjungan pertama** ke mode itu (setelan
> verbositas "sedang"). Jadi wajar kalau kunjungan ke-4 hanya berbunyi "Navigasi aktif."
> Kalau ingin selalu lengkap: Pengaturan → verbositas **Detail**.

### 4A. Perintah dasar per mode

| Ucapkan | Mode tujuan | Ekspektasi TTS | ✓ |
|---|---|---|---|
| "deteksi" / "deteksi objek" / "awasi jalan" | Deteksi Objek | "Baik. Deteksi Objek aktif. Arahkan ponsel ke depan, saya akan menyebut rintangan di jalurmu." | [ ] |
| "navigasi" / "jalan mana" / "arahan jalur" | Navigasi | "Baik. Navigasi aktif. Saya akan menyebut jalur mana yang lebih aman: kiri, tengah, atau kanan." | [ ] |
| "uang" / "kenali uang" / "duit berapa" | Kenali Uang | "Baik. Kenali Uang aktif. Letakkan uang di dalam bingkai, saya akan menyebut nominalnya." | [ ] |
| "baca teks" / "baca dong" / "tolong bacain" | Baca Teks | "Baik. Baca Teks aktif. Arahkan ponsel ke tulisan, lalu ambil gambar." | [ ] |
| "asisten" / "bicara" / "nanya" / "halo guidio" | Asisten Suara | "Baik. Asisten Suara aktif. Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu." | [ ] |
| "cari objek" / "cari barang" | Cari Objek | "Baik. Cari Objek aktif. Sebutkan barang yang kamu cari…" | [ ] |
| "pengaturan" / "setelan" / "setting" | Layar Pengaturan | "Pengaturan terbuka." | [ ] |

### 4B. Kalimat natural (bukan kata kunci kaku)

Parser punya lapis khusus untuk kalimat percakapan. Coba:

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "saya pengin pindah ke mode baca teks" | pindah ke Baca Teks | [ ] |
| "tolong ganti ke mode uang" | pindah ke Kenali Uang | [ ] |
| "aktifkan mode navigasi" | pindah ke Navigasi | [ ] |
| "buka mode asisten suara" | pindah ke Asisten Suara | [ ] |

### 4C. Cari barang dengan target dinamis

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "cari dompet" | pindah Cari Objek, TTS "Baik, mencari dompet." Tombol kiri berubah jadi `Kirim - cari dompet` | [ ] |
| "cariin kunci dong" | target = "kunci" (kata "dong" dibuang otomatis) | [ ] |
| "lupa naruh hp dimana" | target = "hp" | [ ] |
| **"cari uang yang jatuh"** | **Cari Objek** (BUKAN Mode Kenali Uang) - ini jebakan yang sengaja ditangani | [ ] |

### 4D. Dialek & bahasa gaul

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "tulung wacakno" (Jawa) | Baca Teks | [ ] |
| "duit iki piro" (Jawa) | Kenali Uang | [ ] |
| "aya naon di hareup" (Sunda) | Deteksi Objek | [ ] |
| "tulung tuntun mlaku" (Jawa) | Navigasi | [ ] |
| "gue mau nanya" | Asisten Suara | [ ] |
| "scan duit" | Kenali Uang | [ ] |

### 4E. Perintah aksi (tanpa ganti mode)

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "nyalakan lampu" / "nyalain senter" | senter menyala, TTS "Baik, lampu dinyalakan." | [ ] |
| "matikan lampu" | senter mati, TTS "Baik, lampu dimatikan." | [ ] |
| "ini mode apa" / "saya di mana" | "Baik. Kamu di mode `<mode aktif saat ini>`." - **harus mode yang sedang aktif**, bukan selalu "Asisten Suara" | [ ] |
| "bisa apa" / "bantuan" | daftar kemampuan dibacakan | [ ] |
| "kembali" / "batal" / "gak jadi" | kembali ke mode sebelumnya, TTS "Kembali. `<Mode>` aktif." | [ ] |
| "lebih cepat" | TTS "Lebih cepat, `<N>` persen." (hanya dari Mode Asisten Suara / overlay mic) | [ ] |
| "lebih pelan" | TTS "Lebih pelan, `<N>` persen." | [ ] |

### 4F. Perintah tidak dikenali (uji jalur gagal)

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| ucapan ngawur, mis. "kambing terbang biru" | "Saya dengar '…'. Maksudmu `<tebakan A>`, atau `<tebakan B>`?" - dan **kedua tebakan harus mode/aksi yang benar-benar bisa dijalankan** | [ ] |
| diam saja (tidak bicara) | tidak macet; kembali ke idle, tidak ada konfirmasi palsu | [ ] |

> **Aturan mutlak yang diuji di sini:** aplikasi **tidak boleh pernah** mengucapkan
> konfirmasi untuk sesuatu yang tidak terjadi. Kalau perpindahan mode dibatalkan
> (mis. konfirmasi Navigasi), yang terdengar harus "Tetap di mode `<X>`", bukan "Baik".

---

## 5. Uji per mode

### 5.1 Mode Deteksi Objek

> Mode default saat aplikasi dibuka. **Penting: deteksi TIDAK menyala otomatis.**

#### D-1. Masuk mode: keadaan awal MATI

**Kamu lakukan:** buka aplikasi (atau pindah ke mode ini)

**Ekspektasi:**
- [ ] TTS: "Deteksi Objek aktif. Arahkan ponsel ke depan…"
- [ ] Disusul: **"Deteksi rintangan belum menyala. Tekan tombol kiri bawah untuk mulai mengawasi."**
- [ ] Tombol kiri berlabel **`Lanjutkan`**
- [ ] Kamera preview tetap hidup, tapi **tidak ada kotak deteksi** di layar

> Ini disengaja: saat aplikasi baru dibuka, HP biasanya masih di tangan yang turun atau
> di saku - peringatan dari posisi itu hampir selalu keliru.

#### D-2. Pengingat berkala saat mati

**Kamu lakukan:** biarkan saja tanpa menekan apa-apa, tunggu 30 detik

**Ekspektasi:**
- [ ] Tiap **30 detik**: TTS "Deteksi rintangan masih mati. Tekan tombol kiri bawah untuk mulai." + getar
- [ ] Berhenti mengingatkan begitu deteksi dinyalakan

#### D-3. Tombol kiri: nyala

**Kamu lakukan:** tekan tombol kiri (`Lanjutkan`)

**Ekspektasi:**
- [ ] TTS **"Deteksi dilanjutkan"** (langsung, tidak tertelan)
- [ ] Getar konfirmasi
- [ ] Label tombol berubah jadi **`Hentikan`**
- [ ] Kotak deteksi mulai muncul di layar

#### D-4. Tombol kiri: mati

**Kamu lakukan:** tekan tombol kiri (`Hentikan`)

**Ekspektasi:**
- [ ] TTS **"Deteksi dijeda. Saya tidak akan memperingatkan rintangan sampai dilanjutkan."**
- [ ] Getar warning
- [ ] Label kembali jadi `Lanjutkan`
- [ ] **Kotak deteksi hilang dari layar** (tidak menampilkan sisa frame lama)
- [ ] Pengingat 30 detik menyala lagi

#### D-5. Deteksi nyata

**Kamu lakukan:** nyalakan deteksi, arahkan ke orang/benda pada jarak <3 m

**Ekspektasi:**
- [ ] Suara + getar peringatan, jeda deteksi→suara <500 ms
- [ ] Kartu deteksi muncul di layar
- [ ] Narasi terdengar **natural**, bukan template kaku
  ("Di sekitarmu ada dua orang di sebelah kirimu…")
- [ ] Dua objek kelas sama + arah sama **digabung** ("dua orang", bukan diucapkan dua kali)
- [ ] Jarak diucapkan dalam frasa natural ("sangat dekat", "sekitar tiga meter") dan
      **tidak naik-turun tiap frame** (nilai smoothed)
- [ ] Identitas objek stabil - tidak berkedip antara "orang depan" ↔ "orang kiri"

#### D-6. "Ulangi": cek kejujuran sistem

Ini uji penting. Ucapkan **"ulangi"** di beberapa kondisi berbeda:

| Kondisi | Ekspektasi TTS | ✓ |
|---|---|---|
| Deteksi sedang dijeda | "Deteksi sedang dijeda." | [ ] |
| Ada objek terdeteksi | menyebut ulang objek-objeknya | [ ] |
| Tutup lensa dengan tangan | "Terlalu gelap, saya tidak bisa memastikan apa yang ada di depanmu. Nyalakan senter." | [ ] |
| HP dimiringkan ke bawah/atas | "`<pesan perbaikan>`. Sampai itu, saya belum bisa memastikan apa yang ada di depanmu." | [ ] |
| Baru saja nyala (<3 detik) | "Saya belum sempat membaca sekitarmu. Tunggu sebentar, lalu coba lagi." | [ ] |
| Kamera jelas, tidak ada apa-apa | "Tidak ada rintangan di depanmu saat ini." | [ ] |

> **Yang tidak boleh terjadi:** mengucapkan "tidak ada rintangan" saat lensa tertutup
> atau saat sistem belum sempat membaca apa pun. Itu jaminan palsu, dan pengguna
> tunanetra tidak punya cara memverifikasinya.

#### D-7. Panel debug (opsional)

**Kamu lakukan:** ketuk badge mode (kiri atas) **5×**

**Ekspektasi:** lembar debug muncul berisi DO-06, DO-07, DO-13, DO-15, DO-19…DO-29
untuk memicu state yang sulit dibuat nyata.

---

### 5.2 Mode Navigasi

> **Ini bagian yang kamu tanyakan soal tombol kiri.** Baca D-tombol di bawah.

#### N-1. Kalibrasi (layar pertama)

**Kamu lakukan:** masuk mode Navigasi

**Ekspektasi:**
- [ ] TTS: "Navigasi aktif. Saya akan menyebut jalur mana yang lebih aman: kiri, tengah, atau kanan."
- [ ] Layar: "Pegang ponsel tegak setinggi dada, kamera menghadap depan" + tombol **"Siap, mulai"**
- [ ] Navigasi **belum** memberi arahan sebelum tombol ini ditekan

#### N-2. Memuat model on-device

**Kamu lakukan:** tekan "Siap, mulai"

**Ekspektasi:**
- [ ] Indikator zona muncul dengan status "belum terbaca"
- [ ] Setelah model siap: TTS **"Panduan jalur aktif."**
- [ ] Kalau model gagal dimuat: TTS **"Panduan jalur tidak bisa dijalankan di perangkat ini.
      Mode Deteksi Objek tetap bisa memperingatkan rintangan."** + banner merah
      "Berhenti jalan dulu, jalur tidak terbaca"
- [ ] **Tidak boleh** ada pesan "tidak terhubung ke server" - mode ini murni on-device

#### N-3. 🔘 TOMBOL KIRI: nyala/mati suara panduan

**Ini yang kamu tanyakan.** Perlu diluruskan dulu:

> Tombol kiri di Mode Navigasi **BUKAN** untuk mematikan/menyalakan mode navigasi.
> Ia **membisukan dan menyalakan kembali SUARA panduan**. Ketiga model tetap
> berjalan, indikator zona di layar tetap hidup, dan arah tetap sampai lewat **getar**.
>
> Alasan desainnya: mematikan panduan jalur sepenuhnya sambil pengguna sedang berjalan
> adalah aksi berbahaya. Yang benar-benar dibutuhkan pengguna adalah **membisukan
> sementara** (mis. saat menyeberang dan perlu mendengar lalu lintas).
>
> Kalau kamu ingin benar-benar **menghentikan panduan**, itu ada di perintah suara
> **"stop navigasi"** / **"berhenti navigasi"** / **"selesai jalan"**.

**Uji N-3a - membisukan:**

**Kamu lakukan:** dengan navigasi aktif, tekan tombol kiri (`Matikan Suara`)

**Ekspektasi:**
- [ ] TTS **"Suara panduan dimatikan. Arah tetap terasa lewat getar. Tekan tombol
      kiri bawah lagi untuk menyalakan."** ← kalimat ini harus **terdengar utuh**,
      diucapkan SEBELUM bisu menyala
- [ ] **Getar pola panjang** `[400, 120, 400]` menyertainya - inilah "rasa mati"-nya
- [ ] Label tombol berubah jadi **`Nyalakan Suara`**
- [ ] Setelah itu: **tidak ada lagi arahan suara**, tapi indikator zona di layar
      **tetap berubah-ubah** (bukti loop masih jalan)

**Uji N-3b - arah lewat getar saat bisu:**

**Kamu lakukan:** dalam keadaan bisu, arahkan kamera sehingga rekomendasi berganti

**Ekspektasi:**
- [ ] Rekomendasi **kiri** → getar **1 ketukan panjang** (200 ms)
- [ ] Rekomendasi **kanan** → getar **2 ketukan pendek** (80-60-80 ms)
- [ ] Rekomendasi tengah → tidak ada getar arah (memang tidak perlu geser)
- [ ] **Peringatan CRITICAL tetap bergetar pola panjang walau dibisukan** - dibisukan
      tidak boleh berarti peringatan bahaya ikut hilang

**Uji N-3c - menyalakan lagi:**

**Kamu lakukan:** tekan tombol kiri lagi (`Nyalakan Suara`)

**Ekspektasi:**
- [ ] TTS **"Suara panduan dinyalakan."**
- [ ] Label kembali jadi `Matikan Suara`
- [ ] Arahan suara jalan lagi dalam beberapa detik

> ⚠️ **Perhatikan saat menguji:** saat **menyalakan**, kode saat ini **tidak
> mengirim getar** (hanya saat mematikan). Jadi "rasa nyala" hanya lewat suara.
> Kalau menurutmu ini terasa timpang, lihat [bagian 11, K-1](#11-yang-tidak-diperbaiki-keputusanmu).

**Uji N-3d - lewat suara:**

**Kamu lakukan:** ucapkan **"jepret"** (padanan suara tombol kiri)

**Ekspektasi:**
- [ ] TTS "Baik, mematikan suara panduan." (atau "menyalakan…" kalau sedang bisu)
- [ ] Efeknya **sama persis** dengan menekan tombol kiri

#### N-4. Deteksi 3 zona

**Kamu lakukan:** arahkan kamera ke koridor/trotoar, jalan pelan

**Ekspektasi:**
- [ ] Indikator zona kiri/tengah/kanan berubah warna: hijau (aman), kuning (hati-hati), merah (bahaya)
- [ ] Overlay segmentasi jalur tergambar di atas preview + legenda warna muncul
- [ ] TTS memberi arahan: "Kiri aman, tengah hati-hati, kanan aman. Geser ke kiri."
- [ ] Arahan **tidak membanjir** - jeda minimal 1,8 detik antar pesan berbeda
- [ ] Pesan **sama** tidak diulang dalam **6 detik**
- [ ] Peringatan **critical** boleh diulang setelah **4 detik** (lebih cepat, karena bahaya nyata)
- [ ] Arahan tidak menimpa ucapan yang belum selesai

#### N-5. Kejujuran saat jalur tidak terbaca

Ini uji penting - sistem tidak boleh mengarang "jalur aman".

| Kamu lakukan | Ekspektasi TTS | ✓ |
|---|---|---|
| Arahkan kamera ke **langit-langit** / tembok polos | "Jalur belum terbaca. Arahkan kamera ke depan bawah, sekitar dua langkah di depanmu." | [ ] |
| Arahkan kamera terlalu ke **atas** | "Kamera terlalu ke atas. Turunkan sedikit supaya jalur di depan kakimu terlihat." | [ ] |
| Tutup lensa / ruangan gelap | "Terlalu gelap untuk membaca jalur. Nyalakan senter." | [ ] |
| Miringkan HP | "`<pesan perbaikan>`. Jalur belum terbaca." | [ ] |

**Yang tidak boleh terjadi:** terdengar "Jalur aman, jalan lurus" dari kamera yang
menghadap tembok atau bagian dalam saku. Saat ragu, indikator zona juga **harus
menjadi "belum terbaca"** - layar dan suara tidak boleh saling membantah.

#### N-6. Rintangan di jalur

**Kamu lakukan:** arahkan ke objek/lubang di depan

**Ekspektasi:**
- [ ] Rintangan **critical**: TTS langsung memotong ucapan lain, kartu deteksi muncul
- [ ] Rintangan **warning**: diucapkan setelah arahan zona
- [ ] Semua zona bahaya: **"Berhenti dulu. Tidak ada jalur aman."** + banner merah
- [ ] Zona tengah bahaya: **"Berhenti! Jalur di depan tidak aman."**
- [ ] Peringatan critical **tidak mengulang dirinya sendiri terus-menerus** sampai
      kalimatnya tidak pernah selesai (jeda minimum 4 detik)

> **Catatan threshold** (`yolo_navigasi_service.dart`): kelas `lubang` dan `got_terbuka`
> pakai threshold **5%**; kelas lain (`tangga`, `orang`, `motor`, `tiang`) tetap **30%**.
> Kalau YOLO tidak mendeteksi sama sekali, PIDNet-S tetap jadi lapis pengaman lewat
> penurunan rasio area walkable.

#### N-6b. Lapis ketiga: orang dan kendaraan

Ini uji untuk model COCO yang baru ditambahkan ke Mode Navigasi.

**Kamu lakukan:** arahkan kamera ke orang yang berjalan, atau ke motor yang
terparkir di trotoar

**Ekspektasi:**
- [ ] Orang terdeteksi dan disebut, meski model bahaya jalanan tidak melihatnya
- [ ] Motor terdeteksi dan disebut
- [ ] Satu benda **tidak pernah disebut dua kali** walau dua model melihatnya
- [ ] Benda tak relevan (botol, ponsel, kursi kantor) **tidak pernah disebut**
      di mode ini

> Sampai ekspor YOLO custom diperbaiki, lapis inilah **satu-satunya** sumber
> deteksi orang dan motor di Mode Navigasi. Lihat bagian 11, K-2.

#### N-6c. Ponsel lama yang tidak mengejar

**Kamu lakukan:** jalankan Mode Navigasi lama di HP paling lambat yang kamu
punya, sambil memperhatikan jeda antar arahan

**Ekspektasi:**
- [ ] Kalau ponsel tidak mengejar, aplikasi **mengurangi bebannya sendiri
      dulu** tanpa mengumumkan apa pun. Panduan jalur dan peringatan lubang
      tetap jalan; yang berhenti hanya deteksi orang dan kendaraan
- [ ] Kalau masih tidak mengejar juga: TTS **"Ponsel ini memproses jalur lebih
      lambat dari biasanya. Jalan lebih pelan, arahan bisa datang terlambat."**
- [ ] Kalimat itu diucapkan **sekali saja**, tidak diulang tiap frame
- [ ] Keluar lalu masuk lagi ke Mode Navigasi mengembalikan semuanya dari nol

> Ini juga yang menangkap ponsel yang panas. Saat prosesornya diturunkan
> sendiri, durasi siklus naik dan mekanisme yang sama bekerja.

#### N-7. Frame gagal berturut-turut

**Kamu lakukan:** tutup lensa beberapa detik saat navigasi aktif

**Ekspektasi:**
- [ ] Setelah **2 kegagalan**: TTS "Jalur sulit dibaca, arahan mungkin tertinggal." + banner kuning
- [ ] Setelah **4 kegagalan**: TTS "Berhenti jalan dulu. Saya tidak bisa membaca jalur sekarang.
      Periksa apakah kamera tertutup, atau cari tempat yang lebih terang." + banner merah
- [ ] Saat lensa dibuka lagi: TTS **"Jalur terbaca lagi."**

#### N-8. "Ulangi arahan" (lewat suara)

**Kamu lakukan:** ucapkan **"ulangi"** / **"ulang dong"**

**Ekspektasi:**
- [ ] TTS merangkum 3 zona + rekomendasi: "Kiri aman, tengah hati-hati, kanan bahaya. Geser ke kiri."
- [ ] **Melewati anti-banjir** (permintaan eksplisit pengguna, langsung diucapkan)
- [ ] Kalau belum ada data: "Jalur belum terbaca, tunggu sebentar."

#### N-9. Menghentikan panduan (tanpa keluar mode)

**Kamu lakukan:** ucapkan **"stop navigasi"** / **"berhenti navigasi"** / **"selesai jalan"**

**Ekspektasi:**
- [ ] TTS "Panduan jalan dihentikan."
- [ ] Loop berhenti (indikator zona berhenti berubah, baterai/CPU turun)
- [ ] Kalau memang tidak sedang berjalan: "Kamu sedang tidak dalam panduan jalan."

> **Ini uji jebakan yang sengaja dipasang:** kata "stop" sendirian berarti "kembali",
> tapi **"stop navigasi"** harus dikenali sebagai menghentikan panduan - bukan keluar
> dari mode. Kalau ucapan "stop navigasi" malah mengeluarkanmu dari Mode Navigasi,
> itu **gagal**.

#### N-10. Konfirmasi keluar (NV-18): satu-satunya konfirmasi di seluruh app

**Kamu lakukan:** saat navigasi masih aktif (belum di-pause), coba pindah mode
(lewat suara atau tombol Pilih mode)

**Ekspektasi:**
- [ ] TTS **"Kamu masih terdeteksi berjalan. Berhenti dulu sebelum keluar dari Navigasi."**
- [ ] Muncul **lembar bawah** (bukan dialog tengah layar) berjudul "Keluar dari Navigasi?"
- [ ] Tombol utama = **"Tetap di Navigasi"** (pilihan aman, paling mudah dijangkau)
- [ ] Tombol kedua = "Ya, keluar dari Navigasi"
- [ ] Kalau pilih "Tetap": TTS **"Tetap di mode Navigasi."** - bukan "Baik"
- [ ] Kalau pilih "Ya, keluar": pindah normal ke mode tujuan
- [ ] Setelah **"stop navigasi"** (fase paused), pindah mode **tidak lagi minta konfirmasi**

#### N-11. Panel debug Navigasi

Ketuk badge mode 5× → NV-14a (telepon masuk), NV-16 (kamera tertutup),
NV-21 (izin dicabut), NV-22 (senyap), NV-25 (sudut bergeser).

---

### 5.3 Mode Kenali Uang

#### U-1. Masuk mode

- [ ] TTS "Kenali Uang aktif. Letakkan uang di dalam bingkai, saya akan menyebut nominalnya."
- [ ] Tombol kiri berlabel **`Kenali Uang`**

#### U-2. Bingkai panduan

**Kamu lakukan:** letakkan uang kertas perlahan masuk ke bingkai

**Ekspektasi:**
- [ ] Bingkai berubah saat uang masuk sebagian → pas di bingkai (**hijau**)
- [ ] Ada instruksi perbaikan kalau posisi belum pas ("dekatkan", "geser")

#### U-3. Tombol kiri: analisis

**Kamu lakukan:** tekan tombol kiri `Kenali Uang`

**Ekspektasi:**
- [ ] Nominal disebut dalam **2 bentuk**: angka + kata - "Rp 50.000, lima puluh ribu rupiah"
- [ ] Getar pola positif `[25, 45, 25]`
- [ ] Hasil muncul dari buffer terakhir (tidak menunggu inferensi baru)

#### U-4. Keyakinan rendah: tidak boleh menebak

**Kamu lakukan:** miringkan uang, tutup sebagian, atau kurangi cahaya

**Ekspektasi:**
- [ ] Hanya instruksi perbaikan yang diucapkan
- [ ] **TIDAK menyebut nominal apa pun** ← ini kritis: salah sebut nominal = pengguna dirugikan uang

#### U-5. Bukan uang

**Kamu lakukan:** arahkan ke kertas biasa / kartu

**Ekspektasi:**
- [ ] TTS memberi tahu bahwa itu bukan uang / tidak terdeteksi
- [ ] Tidak menebak nominal

#### U-6. TIDAK ada penjumlahan total: ini disengaja

**Kamu lakukan:** kenali beberapa lembar berturut-turut

**Ekspektasi:**
- [ ] Tiap tekan hanya menyebut nominal **lembar yang sedang dihadapi**
- [ ] **Tidak ada** total sesi, tidak ada kartu "total direset", tidak ada rincian lembar
- [ ] Menekan tombol dua kali pada lembar yang sama hanya mengulang nominal yang sama

> Ini keputusan desain, bukan fitur yang hilang. Pengguna tunanetra tidak bisa
> melihat lembar mana yang sudah terhitung, jadi satu lembar yang ter-scan dua kali
> akan menghasilkan total yang salah **tanpa satu pun tanda**.

#### U-7. Ulangi

**Kamu lakukan:** ucapkan "ulangi"

- [ ] Kalau sudah ada hasil: nominal terakhir dibacakan ulang
- [ ] Kalau belum ada: "Belum ada nominal yang terbaca."

#### U-8. Model gagal dimuat

- [ ] Tombol kiri nonaktif dengan alasan "model pengenalan uang belum siap"
- [ ] Menekannya tetap mengucapkan alasan itu (tidak diam)

#### U-9. Panel debug

Ketuk badge 5× → UG-01…UG-18 (idle, ragu, bukan uang, silau, gelap, uang asing, dll.)

---

### 5.4 Mode Baca Teks

> **Sepenuhnya on-device (ML Kit).** Bisa diuji dengan internet mati total.

#### T-1. Masuk mode

- [ ] TTS "Baca Teks aktif. Arahkan ponsel ke tulisan, lalu ambil gambar."
- [ ] Tombol kiri berlabel **`Baca teks`**

#### T-2. Memindai

**Kamu lakukan:** arahkan ke tulisan (kemasan, buku, dokumen), tekan tombol kiri

**Ekspektasi:**
- [ ] Saat memindai, tombol kiri **nonaktif** dengan alasan "sedang memindai"
- [ ] Teks terbaca lalu **dibacakan TTS Bahasa Indonesia**
- [ ] Blok teks tampil di layar mengikuti urutan baca

#### T-3. Tombol kiri berubah jadi kontrol bacaan

**Kamu lakukan:** saat teks sedang dibacakan, perhatikan tombol kiri

**Ekspektasi:**
- [ ] Label berubah jadi **`Jeda bacaan`**
- [ ] Ditekan → bacaan berhenti, label jadi **`Lanjutkan bacaan`**
- [ ] Ditekan lagi → bacaan lanjut dari tempatnya berhenti

#### T-4. Kontrol lewat suara

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "jeda" / "pause dulu" (saat sedang dibacakan) | TTS "Dijeda." | [ ] |
| "lanjut" / "terusin" | TTS "Dilanjutkan." | [ ] |
| "lanjut" (padahal tidak ada yang dijeda) | "Baik. Tidak ada pembacaan yang sedang dijeda." | [ ] |
| "ulangi" / "baca lagi" | teks dibacakan ulang dari awal | [ ] |
| "jepret" | sama dengan tombol kiri (memindai / menjeda, sesuai keadaan) | [ ] |

#### T-5. Teks panjang

**Kamu lakukan:** arahkan ke dokumen panjang (>1 halaman)

**Ekspektasi:**
- [ ] Sebelum mulai membaca, ditawarkan **ringkas / penuh / pilih bagian**
- [ ] Tawaran muncul **sebelum** pengguna terjebak mendengarkan 3 menit teks

#### T-6. Gagal baca

| Kondisi | Ekspektasi | ✓ |
|---|---|---|
| Foto buram / tidak ada teks | pesan jujur + instruksi perbaikan konkret | [ ] |
| Cahaya kurang | disarankan menyalakan lampu, bukan sekadar "gagal" | [ ] |

#### T-7. Uji offline penuh

**Kamu lakukan:** matikan WiFi **dan** data seluler, ulangi T-2

- [ ] Semua tetap berjalan normal (ML Kit on-device)
- [ ] **Tidak ada** pesan "tidak terhubung ke server"

---

### 5.5 Mode Asisten Suara

#### A-1. Masuk mode

- [ ] TTS "Asisten Suara aktif. Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu."
- [ ] Tombol kiri berlabel **`Ulangi jawaban`**, awalnya nonaktif dengan alasan "belum ada jawaban"

#### A-2. Tanya jawab dasar

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "bisa apa" | daftar kemampuan | [ ] |
| "saya di mana" | "Kamu di mode Asisten Suara." | [ ] |
| "ulangi jawaban" / tekan tombol kiri | jawaban terakhir dibacakan ulang | [ ] |

#### A-3. Deskripsi suasana (butuh backend + Moondream2)

**Kamu lakukan:** ucapkan "deskripsikan" / "apa yang ada di depanku" / "liatin depan dong"

**Ekspektasi:**
- [ ] TTS langsung: **"Saya foto sekitarmu dulu, tunggu sebentar."**
- [ ] Kamera naik ke resolusi capture, foto diambil, dikirim ke backend
- [ ] Hasil dibacakan **dalam Bahasa Indonesia** (diterjemahkan lokal oleh `scene_translator`)
- [ ] Kalau kamus terjemahan tidak cukup: TTS mengucapkan **"Dalam bahasa Inggris."**
      lalu membacakan kalimat Inggris dengan locale `en-US`
- [ ] Kalau foto ditolak gerbang kualitas (gelap/buram): terdengar **instruksi konkret**
      ("Terlalu gelap. Cari tempat yang lebih terang"), **bukan** "maaf tidak bisa"

> ✅ Fitur ini **sebelumnya selalu gagal** (nama field multipart tidak cocok, backend
> membalas 422 untuk setiap permintaan). Sudah diperbaiki - lihat
> [bagian 10, T-1](#10-bug-yang-ditemukan--diperbaiki). Kalau kamu masih mendengar
> "Maaf, saya tidak bisa mendeskripsikan suasana saat ini", pastikan APK yang
> terpasang adalah build **setelah** perbaikan ini.

#### A-7. Kamera harus tetap hidup setelah deskripsi suasana

Ini uji regresi untuk bug yang baru diperbaiki (T-2). **Wajib diuji.**

**Kamu lakukan:**
1. Masuk **Mode Deteksi Objek**, tekan tombol kiri sampai deteksi **menyala**
2. Tekan Mic → ucapkan **"deskripsikan"** → tunggu hasilnya dibacakan
3. Overlay tertutup, kamu kembali di Mode Deteksi
4. Arahkan HP ke orang/benda dekat

**Ekspektasi:**
- [ ] Deteksi **masih berjalan** - peringatan tetap terdengar seperti sebelumnya
- [ ] Kotak deteksi masih muncul di layar
- [ ] HP tidak terasa lebih panas / lebih berat dari biasanya

Ulangi hal yang sama dari **Mode Navigasi**:
- [ ] Indikator zona **masih berubah-ubah** setelah kembali dari deskripsi
- [ ] Arahan suara masih mengikuti apa yang benar-benar ada di depan (bukan
      pemandangan beberapa detik lalu yang membeku)

#### A-4. Kecepatan bicara

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "lebih cepat" | "Lebih cepat, `<N>` persen." dan suara benar-benar lebih cepat | [ ] |
| "lebih pelan" | "Lebih pelan, `<N>` persen." | [ ] |

#### A-5. Riwayat kedaluwarsa

**Kamu lakukan:** tinggalkan mode >15 menit lalu kembali

- [ ] TTS "Percakapan tadi sudah saya hapus."

#### A-6. Mic sebagai overlay dari mode lain

**Kamu lakukan:** dari Mode Deteksi, tekan tombol Mic

**Ekspektasi:**
- [ ] VoiceScreen muncul sebagai **overlay** (layar mode di belakang masih ada), bukan ganti layar
- [ ] Mic **langsung mendengarkan** tanpa tekan lagi
- [ ] Ucapkan perintah mode → overlay tertutup sendiri, mode berganti
- [ ] Ucapkan **"jepret"** saat overlay terbuka → yang jalan adalah **aksi mode di
      belakangnya** (mis. toggle deteksi), bukan aksi Asisten Suara

---

### 5.6 Mode Cari Objek

> **Wajib backend hidup.** Ini satu-satunya mode yang benar-benar mati saat offline.

#### C-1. Masuk mode tanpa target

- [ ] TTS "Cari Objek aktif. Sebutkan barang yang kamu cari…"
- [ ] Tombol kiri berlabel **`Sebutkan barang dulu`**, nonaktif
- [ ] Ditekan → tetap bersuara: "Sebutkan barang dulu. tekan tombol bicara lalu sebutkan barangnya"

#### C-2. Menyebutkan target

**Kamu lakukan:** tekan Mic → ucapkan "cari dompet"

**Ekspektasi:**
- [ ] TTS "Baik, mencari dompet."
- [ ] Tombol kiri berubah jadi **`Kirim - cari dompet`** dan menjadi aktif
- [ ] Chip target muncul di layar

#### C-3. Kirim & hasil

**Kamu lakukan:** arahkan kamera, tekan tombol kiri

| Hasil | Ekspektasi | ✓ |
|---|---|---|
| Ketemu | posisi + jarak dibacakan, ada getar arah | [ ] |
| Tidak ada di frame | disuruh memutar badan lalu kirim lagi (bukan dianggap error) | [ ] |
| Foto terlalu gelap/buram | **ditolak sebelum dikirim**, instruksi perbaikan dibacakan (nyalakan lampu), **bukan** "barangnya tidak ada" | [ ] |
| Backend mati | mode dinonaktifkan, target tetap disimpan | [ ] |

> Perbedaan "tidak ada di frame" vs "foto tidak layak" itu penting: tindakan
> penggunanya berbeda total - yang satu memutar badan, yang lain menyalakan lampu.

#### C-4. Ulangi

**Kamu lakukan:** ucapkan "ulangi"

- [ ] "Dompet terakhir terlihat di `<posisi>`." atau "Belum ada hasil pencarian."

#### C-5. Offline

**Kamu lakukan:** matikan backend, masuk mode ini

- [ ] Di lembar Pilih Mode, Cari Objek tampil **disabled** dengan alasan jelas
- [ ] Kalau tetap masuk: dinonaktifkan dengan pesan jujur, bukan gagal diam-diam
- [ ] Saat backend hidup lagi: mode aktif kembali, target sebelumnya masih tersimpan

---

## 6. Uji lintas-mode (suara, getar, gelap, izin)

### L-1. Prioritas suara (TtsQueue)

Sistem suara punya 3 tingkat: **Critical** (memotong semua, tidak bisa dihentikan
pengguna) → **Warning** (memotong Info) → **Info** (mengantre, dibuang kalau basi).

| Kamu lakukan | Ekspektasi | ✓ |
|---|---|---|
| Saat narasi info berjalan, dekatkan objek besar (<1 m) | peringatan critical **langsung memotong** | [ ] |
| Saat info berjalan, miringkan HP | warning memotong info; info dilanjutkan setelahnya | [ ] |
| Tekan Mic saat TTS **info/warning** berbicara | TTS berhenti, mic mulai mendengarkan | [ ] |
| Tekan Mic saat TTS **critical** berbicara | critical **tidak bisa dihentikan** | [ ] |
| Berjalan di area sangat ramai | tidak ada dua suara tumpang tindih; tidak ada crash/OOM | [ ] |
| Perhatikan antar kalimat | ada **jeda bernapas**, tidak langsung nyambung | [ ] |

### L-2. Kondisi gelap

**Kamu lakukan:** tutup lensa dengan tangan atau masuk ruangan gelap

**Ekspektasi:**
- [ ] Setelah **3 detik** gelap: TTS "Terlalu gelap, saya tidak bisa melihat jalur dengan
      jelas. Nyalakan lampu atau berhenti sejenak." + getar `[100, 100, 100]`
- [ ] Slot tawaran lampu muncul tepat **di atas** BottomActionBar, dengan tombol
      **"Nyalakan Lampu"** dan **"Lewati"**
- [ ] Tekan "Nyalakan Lampu" → senter menyala, TTS "Lampu dinyalakan.", tombol berubah
      jadi "Matikan Lampu"
- [ ] Tekan "Lewati" → TTS "Baik, lampu tidak dinyalakan. Deteksi tetap berjalan." dan
      tawaran hilang - **tapi deteksi tetap jalan**
- [ ] Tiap **30 detik** masih gelap: TTS "Masih gelap. Saya tetap berjalan tapi penglihatan terbatas."
- [ ] Saat terang kembali: tawaran hilang otomatis dan status dismiss ter-reset

### L-3. Izin dicabut

**Kamu lakukan:** cabut izin kamera dari Settings Android, kembali ke aplikasi

**Ekspektasi:**
- [ ] Kartu izin muncul dengan alasan **spesifik per mode** (mis. di Navigasi:
      "Berhenti jalan dulu. Navigasi butuh kamera untuk membaca rintangan dan jalur.")
- [ ] Tombol "Izinkan kamera" ada di **dasar layar** (bisa dijangkau satu tangan)
- [ ] Tombol kiri nonaktif dengan alasan "izin kamera belum diberikan", tapi tetap bersuara saat ditekan
- [ ] Setelah izin diberikan lagi: kamera langsung hidup tanpa perlu restart aplikasi

Ulangi untuk izin **mikrofon**:
- [ ] Tombol Mic jadi abu-abu dengan ikon mic dicoret
- [ ] TalkBack: "Bicara, tidak tersedia, izin mikrofon belum diberikan"

### L-4. Aplikasi masuk background

**Kamu lakukan:** tekan Home, tunggu, lalu buka lagi

**Ekspektasi:**
- [ ] Kamera hidup lagi otomatis
- [ ] **Keadaan jeda dihormati** - kalau deteksi tadi dijeda, ia tetap jeda dan label
      tombol tetap `Lanjutkan` (tidak hidup diam-diam)
- [ ] Tidak ada TTS yang berbicara ke layar yang tidak dilihat siapa pun

### L-5. Tekan tombol cepat berkali-kali

**Kamu lakukan:** di Baca Teks / Cari Objek, tekan tombol kiri berkali-kali cepat

- [ ] Tidak ada double-capture
- [ ] Tidak ada error mentah bocor ke pengguna
- [ ] Stream kamera pulih dengan benar setelah capture

### L-6. Uji offline total

**Kamu lakukan:** matikan WiFi + data, lalu uji Deteksi, Uang, Baca Teks, Navigasi

- [ ] Keempatnya berjalan **penuh**
- [ ] Perpindahan mode lewat suara tetap jalan (CommandParser lokal, 0 ms)
- [ ] **Tidak ada** pesan "tidak terhubung ke server" di keempat mode itu
- [ ] Hanya Cari Objek yang dinonaktifkan, dan Deskripsi Suasana yang tidak tersedia

---

## 7. Uji backend langsung (tanpa HP)

> **Permukaan API sekarang tinggal 5 endpoint.** Semua endpoint lain sudah dihapus /
> diarsipkan ke `_archive/routers/` karena fiturnya sudah on-device.

```bash
B=http://localhost:8000
```

### S-1. Health check

```bash
curl -s $B/health | python3 -m json.tool
```

- [ ] `status: "ok"`, ada `uptime_seconds`, `server_time_ms`
- [ ] `find_object: true`
- [ ] `describe`: `true` kalau Moondream2 sudah dimuat, `false` sebelum panggilan pertama

### S-2. Capabilities

```bash
curl -s $B/api/capabilities | python3 -m json.tool
```

- [ ] `detection`, `money`, `read_text`, `navigation` → semuanya `state: "up"` dengan
      `on_device: true`
- [ ] `assistant` → `up` kalau Moondream siap, `limited` kalau belum
- [ ] `find_object` → `up` / `down`
- [ ] **Tidak ada** referensi Qwen / LLM / WebSocket

### S-3. Daftar target Cari Objek

```bash
curl -s $B/api/cari-objek/targets | python3 -m json.tool | head -30
```

- [ ] Balas `{"total": N, "targets": [...]}` berisi nama barang Bahasa Indonesia

### S-4. Cari objek

```bash
curl -s -X POST $B/api/cari-objek \
  -F "target=botol" \
  -F "file=@/path/ke/foto.jpg" | python3 -m json.tool
```

- [ ] Ketemu → `found: true` + posisi & jarak
- [ ] Tidak ada → `found: false, reason: "not_in_frame"` (ini **normal**, bukan error)
- [ ] Foto gelap → `reason` kualitas + `retry_suggested: true` + pesan Bahasa Indonesia
- [ ] Target kosong → `reason: "target_kosong"`

### S-5. Deskripsi suasana

```bash
# PERHATIKAN: nama field-nya "image", BUKAN "file"
curl -s -X POST $B/api/describe \
  -F "image=@/path/ke/foto.jpg" \
  -F "length=short" | python3 -m json.tool
```

- [ ] Balas `description_en` dalam Bahasa Inggris
- [ ] Foto gelap/buram → `ok: false` + `message` Bahasa Indonesia yang **instruktif**
- [ ] Caption tidak berguna ("a photo", "an image") → dikenali dan dibalas jujur
- [ ] Panggilan pertama lama (~beberapa menit) karena download Moondream2 ~1,85 GB

> Coba juga dengan `-F "file=@..."` - **harus balas 422**. Itu membuktikan temuan
> **T-1** di [bagian 10](#10-bug-yang-ditemukan--diperbaiki).

### S-6. Endpoint yang HARUS 404

Ini uji negatif - memastikan tidak ada jalur server ganda yang tertinggal:

```bash
for p in /api/ocr /api/uang /api/navigasi /api/detect /api/narasi \
         /api/intent /api/intent/catalog /api/labels; do
  echo -n "$p → "; curl -s -o /dev/null -w "%{http_code}\n" $B$p
done
```

- [ ] Semuanya **404** (atau 405). Kalau ada yang 200, berarti ada file lama tertinggal.

---

## 8. Troubleshooting

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| Deteksi tidak jalan padahal sudah di Mode Deteksi | **Normal** - deteksi mulai MATI | Tekan tombol kiri (`Lanjutkan`) |
| Tombol kiri Navigasi tidak mematikan navigasi | **Normal** - ia membisukan SUARA | Untuk menghentikan panduan: ucapkan "stop navigasi" |
| "stop navigasi" malah keluar dari mode | Frasa tidak tercocokkan sebagai multi-kata | Cek `command_parser.dart` - frasa multi-kata harus diperiksa sebelum kata tunggal |
| Deskripsi suasana selalu gagal | Nama field `file` vs `image` (**sudah diperbaiki**) | Pastikan APK dibuild ulang setelah perbaikan T-1 |
| Deteksi berhenti diam-diam setelah pakai "deskripsikan" | Aliran kamera tidak dinyalakan lagi (**sudah diperbaiki**) | Build ulang; uji regresi **A-7** |
| Baca Teks hasilnya jelek terus padahal cahaya cukup | Memotret pada 640x480 (**sudah diperbaiki**) | Build ulang; bandingkan pada teks kecil yang sama |
| Uang sering "belum yakin" padahal jelas | Akurasi model - hanya 1/5 fixture tembus ambang 0,85 | Lihat **K-2** bagian 11. Model perlu retrain; jangan turunkan ambangnya |
| Lubang / tangga / tiang tak pernah terdeteksi | YOLO11n hazard: 0 deteksi di semua gambar uji | Lihat **K-2**. Andalkan PIDNet-S (uji N-4/N-5), bukan N-6 |
| Navigasi stuck di "memuat model" | PIDNet / YOLO11n gagal dimuat | Cek `.tflite` ada di `assets/models/`, jalankan `flutter pub get`, rebuild |
| TTS terdengar buru-buru / saling menimpa | Anti-banjir dilewati | Cek `_minGap` (1,8 s) dan cek `TtsQueue.isSpeaking` di `_emitGuidance` |
| Peringatan critical tidak pernah selesai diucapkan | Critical memotong dirinya sendiri | Cek `_criticalRepeatGap` (4 s) di `navigation_provider.dart` |
| Suara "jalur aman" dari kamera menghadap tembok | Cabang `_doubtMessage` tidak jalan | Cek `SceneDoubt` di `pidnet_service.dart` |
| Layar hijau "AMAN" tapi suara bilang belum terbaca | Zona tidak di-set `unknown` saat ragu | Cek `untrusted` di `_applyOnDeviceResult` |
| Uang tidak terdeteksi | Keyakinan di bawah ambang | Dekatkan HP, cahaya merata, jangan ada bayangan/silau |
| Nominal acak muncul di release | Mock debug bocor | Build ulang dengan `flutter build apk --release` |
| Cari Objek mati terus | Backend tidak terjangkau HP | Backend harus `--host 0.0.0.0`, isi IP laptop yang benar (bukan `localhost`) |
| Backend error `psycopg.OperationalError` | PostgreSQL belum jalan | `sudo systemctl start postgresql` (opsional - backend tetap hidup tanpa DB) |
| Moondream loading lama sekali | Download pertama ~1,85 GB | Tunggu; hanya sekali, selanjutnya dari cache |
| Perintah suara tidak dikenali | Frasa belum ada di bank kata | Tambahkan ke `command_parser.dart` pada intent yang sesuai |
| Kalimat panjang terpotong saat bicara | Berhenti terlalu lama di tengah | Rekaman ditutup setelah 2 detik hening - bicara mengalir, jeda setelah selesai |
| Panduan mode tidak dibacakan lagi | **Normal** setelah 3 kunjungan | Pengaturan → verbositas **Detail** |

---

## 9. Perubahan dari dokumen versi lama

Yang **berubah** dan sebelumnya salah di dokumen ini:

| Hal | Dokumen lama (SALAH) | Kondisi sebenarnya |
|---|---|---|
| Tombol kiri Navigasi | "Ulangi arahan" | **`Matikan Suara` / `Nyalakan Suara`** - bisu/nyala suara panduan. "Ulangi arahan" pindah ke perintah suara "ulangi" |
| Mode Deteksi saat dibuka | "sudah aktif" | **Mulai MATI** - harus tekan tombol kiri dulu |
| OCR / Baca Teks | via backend Tesseract `POST /api/ocr` | **On-device ML Kit**, jalan penuh offline. Endpoint backend sudah dihapus |
| Intent parsing | ada fallback `POST /api/intent` ke backend | **Sepenuhnya lokal** - endpoint intent sudah dihapus dari backend |
| `/api/labels`, `/api/intent/catalog` | didokumentasikan sebagai uji | **Sudah dihapus** (diarsipkan ke `_archive/routers/support_full.py`) |
| Deskripsi suasana | "dibacakan dalam Bahasa Inggris" | **Diterjemahkan lokal ke Bahasa Indonesia**; Inggris hanya jadi cadangan, didahului penanda "Dalam bahasa Inggris." |
| Field `POST /api/describe` | `-F "file=@..."` | **`-F "image=@..."`** |
| Laju navigasi | "~2 fps (500 ms)" | Timer 500 ms, tapi `FramePacer` menahan minimal **700 ms** → efektif ~1,4 fps |
| Anti-banjir navigasi | "tidak diulang dalam <6 detik" | Lebih rinci: jeda antar pesan berbeda **1,8 s**, pesan sama **6 s**, critical sama **4 s**, plus histeresis **2 frame** untuk non-critical |
| Model `ssd_mobilenet.tflite` | disebut untuk rintangan | Masih benar untuk Mode Deteksi; Navigasi pakai **YOLO11n + PIDNet-S** |
| Endpoint backend | 8+ endpoint diuji | **Tinggal 5**: `/health`, `/api/capabilities`, `/api/cari-objek`, `/api/cari-objek/targets`, `/api/describe` |

---

## 10. Bug yang ditemukan & diperbaiki

Ditemukan saat menelusuri kode untuk menyusun panduan ini. Semua sudah diperbaiki;
`flutter analyze` bersih (0 error, 0 warning). Bagian ini disimpan sebagai catatan
apa yang berubah dan **uji mana yang membuktikannya**.

### T-1. 🔴 Deskripsi suasana **selalu** gagal: nama field multipart tidak cocok

- **Di mana**: `server_service.dart` → `describeScene()` vs `backend/routers/describe.py`
- **Masalah**: `describeScene()` memanggil `postMultipart` tanpa menyebut `fileField`,
  sehingga memakai nilai bawaan `'file'`. Backend mendeklarasikan parameternya
  `image: UploadFile = File(...)`.
- **Akibat**: FastAPI membalas **422** untuk **setiap** permintaan. `ApiStatusException`
  ditelan `catch (_)` lalu dilaporkan sebagai `reason: 'network_error'` dengan pesan
  kosong, jadi pengguna mendengar "Maaf, saya tidak bisa mendeskripsikan suasana saat
  ini" - aplikasi menyalahkan jaringan yang sebenarnya sehat. Fitur ini **tidak pernah
  berhasil sekali pun**.
- **Perbaikan**: `fileField: 'image'`.
- **Bukti** (diuji langsung ke backend yang berjalan):
  ```
  -F "file=@tiny.jpg"   → HTTP 422              ← perilaku lama
  -F "image=@tiny.jpg"  → HTTP 200 {"message":"Gambar tidak terbaca. Coba ambil ulang."}
  ```
- **Diuji oleh**: A-3, S-5

### T-2. 🔴 Kamera mati diam-diam setelah "deskripsikan": deteksi berhenti tanpa suara

- **Di mana**: `camera_provider.dart` → `initCamera()`, `voice_provider.dart` → `_handleDescribeScene()`
- **Masalah**: `_handleDescribeScene` memanggil `initCamera(preset: capture)` untuk
  menaikkan resolusi foto. `initCamera` menghentikan aliran frame untuk membangun
  ulang controller - **lalu tidak pernah menyalakannya lagi**. Alasan di komentar lama
  ("tiap mode aliran meminta presetnya sendiri saat dimasuki") hanya berlaku kalau
  modenya dimasuki ulang, dan itu justru **tidak terjadi** di jalur yang paling sering
  dipakai: mic dibuka sebagai **overlay** di atas mode yang sedang berjalan lalu
  ditutup - layar di bawahnya tidak pernah `initState` ulang.
- **Akibat**, dan inilah kenapa ini yang paling serius dari semuanya:
  - **Mode Deteksi**: berhenti memperingatkan rintangan **tanpa sepatah kata**.
    Layar terlihat normal, tombol tetap bertuliskan "Hentikan", tapi tidak ada satu
    frame pun yang masuk lagi. Pengguna berjalan menyangka masih dijaga.
  - **Mode Navigasi**: lebih buruk. `_latestFrame` membeku di frame terakhir, dan
    PIDNet + YOLO **terus menganalisisnya berulang-ulang** - panduan arah tetap
    diucapkan dengan yakin, disusun dari pemandangan yang sudah lewat.
  - **Mode Kenali Uang**: `snapAndAnnounce` membacakan hasil buffer yang tidak
    pernah diperbarui lagi.
- **Perbaikan**: `initCamera` mencatat `wasStreaming` dan menyalakan aliran lagi
  setelah controller baru siap; `_handleDescribeScene` mengembalikan preset semula
  di blok `finally` (bukan hanya di jalur sukses - foto yang ditolak gerbang kualitas
  justru hasil yang paling sering terjadi di tempat gelap).
- **Diuji oleh**: **A-7** ← uji regresi, wajib dijalankan

### T-3. 🔴 Baca Teks & Cari Objek memotret pada 640x480, bukan 1280x720

- **Di mana**: `ocr_screen.dart` dan `find_object_screen.dart` → `initState` / `_checkPermission`
- **Masalah**: preset `capture` hanya diminta di dalam `_checkPermission`, dan cabang
  itu hanya jalan saat status izin **berubah**. `_hasCameraPermission` bernilai `true`
  sejak awal, jadi pada kasus paling umum - izin sudah lama diberikan - cabang itu
  **tidak pernah jalan**. Kedua mode foto memakai preset `realtime` 640x480 warisan
  mode sebelumnya.
- **Akibat**: untuk Baca Teks, 640x480 menghapus informasi huruf kecil sebelum ML Kit
  sempat melihatnya - sebagus apa pun fokus dan cahayanya, teksnya memang tidak akan
  terbaca, dan kegagalannya terlihat seperti masalah pencahayaan. Untuk Cari Objek,
  barang kecil di kejauhan hilang di resolusi itu dan yang terdengar pengguna adalah
  "barangnya tidak ada", padahal barangnya ada.
- **Perbaikan**: preset diminta di `initState` kedua layar.
- **Diuji oleh**: T-2 (Baca Teks), C-3 (Cari Objek) - bandingkan hasil sebelum/sesudah
  pada teks kecil yang sama

### T-4. 🟠 Kegagalan server Cari Objek dilaporkan sebagai "barangnya tidak ada"

- **Di mana**: `find_object_provider.dart` → `_handleResponse()`
- **Masalah**: backend mengembalikan `reason: "server_error"` saat inferensinya sendiri
  gagal. Nilai itu tidak ditangani, jadi jatuh ke cabang "tidak ketemu": state menjadi
  `notFoundInFrame` (kartu Info "Mencari …") dan `_notFoundCount` ikut naik.
- **Akibat**: empat kegagalan server berturut-turut memicu tawaran CO-11 **"pindah
  ruangan, atau sebutkan barang lain"**. Pengguna disuruh berjalan ke ruangan lain
  untuk masalah yang sepenuhnya ada di server - dan barang yang dicarinya mungkin ada
  tepat di depannya. (Kalimat yang diucapkan kebetulan sudah benar karena diambil dari
  `message` server; yang salah adalah state, kartu, dan penghitung menyerahnya.)
- **Perbaikan**: `server_error` ditangani bersama `model_unavailable`.
- **Diuji oleh**: C-3 baris "Backend mati"

### T-5. 🟠 Konfirmasi keluar Navigasi menghadang di fase yang salah

- **Di mana**: `navigasi_screen.dart` → `_confirmLeaveNavigasi()`
- **Masalah**: syaratnya `phase != paused`, yang ikut menjaring tiga fase yang sama
  sekali bukan "sedang dituntun berjalan": `calibrating` (kartu "Pegang ponsel tegak"
  masih terbuka, panduan belum pernah mulai), `loadingModels`, dan `unavailable`
  (model gagal dimuat).
- **Akibat**: siapa pun yang masuk Mode Navigasi karena salah dengar lalu mencoba
  keluar akan ditahan lembar konfirmasi yang mengklaim dia "masih terdeteksi berjalan"
  - klaim yang tidak pernah diukur dari apa pun, dan yang tidak bisa dia bantah karena
  tidak melihat layar. Paling menyakitkan di fase `unavailable`: pesan kegagalannya
  sendiri menyarankan pindah ke Mode Deteksi Objek, lalu aplikasinya menghalangi.
- **Perbaikan**: hanya `active` dan `degraded` yang menghadang.
- **Diuji oleh**: N-10

### T-6. 🟡 Frame gelap bisa lolos dari ambang "terlalu gelap"

- **Di mana**: `camera_provider.dart` → `_isTooDark()`
- **Masalah**: jumlah sampel dibagi konstanta `100`, padahal `step = length ~/ 100`
  dibulatkan ke bawah sehingga putarannya hampir selalu **lebih** dari 100.
- **Akibat**: rata-rata kecerahan terhitung lebih terang dari sebenarnya, jadi frame
  yang betul-betul gelap bisa lolos dan peringatan "terlalu gelap" tidak muncul.
- **Perbaikan**: dibagi jumlah sampel yang benar-benar diambil.
- **Diuji oleh**: L-2

### T-7. 🟡 Pemotretan berpacu dengan penghentian aliran kamera

- **Di mana**: `camera_provider.dart` → `stopStream()` / `_capture()`
- **Masalah**: `stopStream()` membuang Future dari `stopImageStream()`, jadi
  `takePicture()` bisa berjalan saat aliran masih hidup - kombinasi yang gagal di
  sebagian perangkat Android. `startImageStream()` juga tidak punya penangkap error,
  sehingga kegagalannya menguap sebagai error asinkron sambil meninggalkan
  `_streaming = true`, dan setiap `startStream()` berikutnya berhenti di penjaga
  di awal fungsi - kamera tidak pernah mengalir lagi selama aplikasi hidup.
- **Perbaikan**: `stopStream()` jadi `Future<void>` dan ditunggu di `_capture()`;
  `startImageStream` diberi `catchError` yang mengembalikan `_streaming` ke false.
- **Diuji oleh**: L-5

### T-8. 🟢 Dokumentasi & kode mati

- Tabel kontrak tombol kiri di `bottom_action_bar.dart` masih menulis Navigasi =
  "Ulangi arahan" - **diperbarui** jadi saklar bisu.
- `segmentasiJalur()` di `server_service.dart` memanggil `POST /api/navigasi` yang
  sudah tidak didaftarkan di backend - **dihapus**. Ia terlihat seperti cadangan
  server padahal ujungnya cuma 404, dan pesan errornya akan menyalahkan jaringan
  untuk endpoint yang memang sengaja tidak disediakan.

---

## 11. Yang TIDAK diperbaiki (keputusanmu)

### K-1. 🟡 Tombol kiri Navigasi: "mati" bergetar, "nyala" tidak

- **Di mana**: `navigasi_screen.dart` → `_toggleGuidanceVoice()`
- **Keadaan**: saat **membisukan** ada TTS + getar panjang `[400, 120, 400]`. Saat
  **menyalakan kembali**, hanya TTS tanpa getar sama sekali.
- **Kenapa dibiarkan**: ini keputusan desain, bukan bug fungsional. Uji **N-3c** di HP
  nyata dulu. Kalau terasa timpang, tambahkan getar pendek berpola berbeda saat
  menyalakan (mis. `[0, 60, 40, 60]`) supaya dua arah punya penanda fisik yang bisa
  dibedakan.

### K-2. 🔴 Akurasi model belum memadai: 10 tes gagal

`flutter test` → **126 lulus, 10 gagal**. Semua kegagalan ada di dua berkas dan
semuanya tentang **kualitas model**, bukan kode:

**Kenali Uang** (`money_pipeline_test.dart`) - 6 gagal:

```
money_new/10000.png   asli=Rp 10.000  top=Rp50.000   conf=35,6%   MENEBAK
money_new/5000.png    asli=Rp  5.000  top=Rp20.000   conf=42,6%   ragu
money_new2/10rb.png   asli=Rp 10.000  top=Rp10.000   conf=82,0%   ragu
money_new2/20rb.png   asli=Rp 20.000  top=Rp20.000   conf=64,7%   ragu
money_new2/5rb.png    asli=Rp  5.000  top=Rp 5.000   conf=90,6%   yakin
──────────────────────────────────────────────────────────────────
argmax benar     : 3/5
tembus ambang 0,85 : 1/5
di zona MENEBAK  : 1/5   (chance level = 14,3%)
```

Artinya: **hanya 1 dari 5 lembar** yang cukup diyakini untuk diucapkan di produksi.
Yang lain berhenti di "Belum yakin, dekatkan sedikit dan tahan diam." Kabar baiknya,
ambang 0,85 **bekerja sebagaimana mestinya** - tidak ada nominal keliru yang
terlanjur diucapkan dengan yakin. Model perlu di-retrain, bukan ambangnya diturunkan.

**Navigasi / hazard YOLO11n** (`model_inference_test.dart`) - 4 gagal:
`got_terbuka`, `tiang`, `motor+orang`, `tangga` → **0 deteksi** pada gambar ujinya.

Ini menjelaskan catatan lama "lubang/tangga tidak terdeteksi". Untuk sekarang,
PIDNet-S adalah lapis pengaman yang sesungguhnya di Mode Navigasi - bukan YOLO.
Uji **N-4** dan **N-5** (segmentasi zona) jauh lebih menentukan daripada **N-6**.

> Dua-duanya di luar cakupan perbaikan kode: yang dibutuhkan adalah data latih dan
> pelatihan ulang. Dicatat di sini supaya tidak salah disangka bug aplikasi saat
> kamu menguji di lapangan.

---

## Ringkasan cepat: urutan uji yang disarankan

Kalau waktumu terbatas, uji dengan urutan ini:

0. **Uji regresi bug yang baru diperbaiki** - ini yang paling penting sekarang:
   **A-7** (kamera hidup setelah "deskripsikan"), **A-3** (deskripsi suasana
   akhirnya berhasil), **T-2** (Baca Teks pada teks kecil), **N-10** (konfirmasi
   keluar Navigasi tidak lagi menghadang saat kalibrasi).
1. **Offline dulu** (WiFi + data mati) - Deteksi, Uang, Baca Teks, Navigasi.
   Kalau keempatnya sehat, 4 dari 6 mode sudah aman.
2. **Perpindahan mode lewat suara** (bagian 4) - ini yang paling sering dipakai pengguna.
3. **Tombol kiri tiap mode** (bagian 3 + uji per mode) - pastikan tiap tekan selalu
   ada umpan balik suara/getar.
4. **Mode Navigasi lengkap** (5.2) - mode paling menyangkut keselamatan, paling banyak
   jalur kegagalan.
5. **Nyalakan backend** → uji Cari Objek dan Deskripsi Suasana.
6. **Uji jalur gagal** (bagian 6: gelap, izin dicabut, background) - di sinilah
   aplikasi bantu jalan paling sering mengecewakan penggunanya.
