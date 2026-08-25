# GUIDIO: Panduan Uji Fitur (Satu Per Satu)

> **Update terakhir**: 2026-08-25, menyusul **14 commit** sesudah versi 2026-08-23.
> Tiga perubahan di antaranya mengubah cara aplikasi ini dipakai, jadi panduan lama
> akan menyesatkan kalau dipakai apa adanya:
>
> 1. **Tombol Bicara sekarang TEKAN-TAHAN**, seperti walkie-talkie. Sekali ketuk tidak
>    lagi merekam apa pun, dan **VoiceScreen tidak lagi muncul sebagai overlay**.
>    Lihat [bagian 3](#3-peta-tombol-wajib-paham-dulu).
> 2. **"Asisten Suara" berganti nama jadi "Deskripsi Suasana"**, dan tombol kirinya
>    berubah dari `Ulangi jawaban` jadi `Deskripsikan`. Lihat [bagian 5.5](#55-mode-deskripsi-suasana).
> 3. **Baca Teks tidak lagi dikunci saat offline**, dan **Navigasi tidak lagi ditandai
>    "butuh internet"** di lembar Pilih Mode. Keduanya memang sepenuhnya on-device.
> 4. **Mode yang sedang berjalan DIAM selama tombol Bicara ditahan**, dan **Mode Cari
>    Objek punya tombol kedua** di atas bar. Lihat
>    [bagian 13](#13-perubahan-25-agustus-2026-gerbang-suara--tombol-kedua).
>
> Daftar lengkap 14 commit-nya ada di [bagian 12](#12-perubahan-sejak-23-agustus-2026).
> Perubahan yang lebih lama, dari dokumen versi sebelumnya, tetap di
> [bagian 9](#9-perubahan-dari-dokumen-versi-lama) dan
> [bagian 10](#10-bug-yang-ditemukan--diperbaiki).
>
> **Build ulang APK sebelum menguji.** Keadaan uji otomatis saat dokumen ini ditulis:
> `flutter analyze` **bersih (0 issue)**, `flutter test` **168 lulus, 3 dilewati,
> 8 gagal** - kedelapan kegagalan soal kualitas model, bukan kode. Rinciannya di
> [bagian 11, K-2](#k-2--akurasi-model-belum-memadai-8-tes-gagal).

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
   - [5.5 Deskripsi Suasana](#55-mode-deskripsi-suasana) ← dulu "Asisten Suara"
   - [5.6 Cari Objek](#56-mode-cari-objek)
6. [Uji lintas-mode](#6-uji-lintas-mode-suara-getar-gelap-izin)
7. [Uji backend langsung (tanpa HP)](#7-uji-backend-langsung-tanpa-hp)
8. [Troubleshooting](#8-troubleshooting)
9. [Perubahan dari dokumen versi lama](#9-perubahan-dari-dokumen-versi-lama)
10. [Bug yang ditemukan & diperbaiki](#10-bug-yang-ditemukan--diperbaiki)
11. [Yang TIDAK diperbaiki (keputusanmu)](#11-yang-tidak-diperbaiki-keputusanmu)
12. [Perubahan sejak 23 Agustus 2026](#12-perubahan-sejak-23-agustus-2026)
13. [Gerbang suara & tombol kedua](#13-perubahan-25-agustus-2026-gerbang-suara--tombol-kedua) ← **baru**

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
| Navigasi | ❌ on-device, **4 model**: PIDNet-S + YOLO11n FP16 + **YOLO11n INT8 (baru)** + SSD MobileNet COCO |
| Cari Objek | ✅ **wajib** backend (YOLOE open-vocab) |
| Deskripsi Suasana | ✅ **wajib** backend (Moondream2). Perintah suara & ganti mode tetap jalan offline |

> Artinya: uji mode 1-4 bisa dilakukan dengan **WiFi dan data HP dimatikan total**.

> **Berubah 2026-08-25:** di lembar Pilih Mode, **Navigasi tidak lagi ditandai
> "Tanpa internet: sebagian fitur mati"**. Penandaan itu sisa dari era saat
> segmentasi jalur masih dikerjakan server; jalurnya sudah dihapus dari backend,
> tapi labelnya tertinggal dan mengajari pengguna bahwa mode yang sebenarnya hidup
> itu sedang mati. Kalau kamu masih melihat tanda itu, APK-mu build lama.

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

### Tombol TENGAH (Mic): **TEKAN-TAHAN**, seperti walkie-talkie

> 🔴 **INI YANG PALING BERUBAH.** Sekali ketuk **tidak lagi merekam apa pun**, dan
> **VoiceScreen tidak lagi muncul sebagai overlay**. Kalau kamu menguji dengan
> kebiasaan lama (ketuk lalu bicara), kamu akan menyimpulkan mikrofonnya rusak.

**Tahan = mendengarkan. Lepas = jalankan.** Tidak ada layar yang berganti, tidak ada
overlay, tidak ada popup. Berlaku **sama persis di keenam mode**.

| Kamu lakukan | Ekspektasi | ✓ |
|---|---|---|
| Tahan ≥ 0,5 detik | Getar, cincin tombol **berdenyut**, ikon berubah jadi mic terisi. TTS yang sedang berjalan **langsung dipotong** | [ ] |
| Bicara sambil terus menahan | **Pill teks** muncul tepat di atas tombol, isinya teks yang sedang ditangkap + "…" | [ ] |
| Lepas jari | Getar kedua **tepat saat jari diangkat** (bukan setelah pengenalan selesai), mic mati, perintah dijalankan | [ ] |
| Lepas **< 0,5 detik** (ketuk biasa) | Tidak merekam apa pun, tapi **tidak diam**: getar pendek + TTS **"Tahan tombolnya, lalu bicara."** | [ ] |
| Menahan lewat **10 detik** | Audio **dibuang**, TTS **"Waktu habis, silakan coba lagi."** Perintah separuh tidak pernah dijalankan | [ ] |
| Geser jari keluar area tombol sambil bicara | **Rekaman tetap jalan.** Ini disengaja: pengguna yang tidak melihat layar sering bergeser, dan itu tidak boleh memotong kalimatnya | [ ] |
| Tiga tombol tidak bergeser saat pill muncul | Pill tumbuh **ke atas**; posisi kiri/tengah/kanan **tidak boleh bergerak satu piksel pun** | [ ] |

**Dua getar untuk satu perintah, tidak lebih.** Satu saat mic menyala, satu saat jari
diangkat. Kalau kamu merasakan getar ketiga setelah melepas, itu regresi.

**Artinya sama di keenam mode: perintah suara.** Tidak ada mode yang boleh
membajaknya. Mode Cari Objek dulu memakainya untuk menyebut nama barang, dan itu
sudah pindah ke tombolnya sendiri - lihat [C-2](#c-2-menyebutkan-target--tombol-kedua).

#### Mode yang sedang berjalan ikut DIAM

> 🔴 **Baru 2026-08-25.** Ini yang dulu membuat perintah suara sering gagal di Mode
> Deteksi dan Navigasi: narasinya terus berjalan sementara kamu bicara.

| Kamu lakukan | Ekspektasi | ✓ |
|---|---|---|
| Di Mode Deteksi dengan deteksi **menyala**, tahan Mic | Narasi rintangan **berhenti seketika**, termasuk yang sedang setengah jalan | [ ] |
| Di Mode Navigasi berjalan, tahan Mic | Arahan "kiri aman, tengah hati-hati" **berhenti** | [ ] |
| Ucapkan perintah lalu lepas | Jawaban asisten terdengar **utuh**, tidak dipotong arahan jalur | [ ] |
| Sesudah jawaban selesai | Narasi mode **jalan lagi sendiri**, tanpa perlu apa pun | [ ] |
| Narasi yang tertahan | **Dibuang, bukan diantre.** Tidak boleh ada tumpahan 4-5 kalimat basi setelah gerbang lepas | [ ] |
| **Peringatan bahaya (critical) saat menahan Mic** | **TETAP BERSUARA** | [ ] |

> **Kenapa bahaya tetap menembus.** Ini keputusan sadar, dan harganya diterima:
> suara peringatan itu ikut masuk ke mikrofon dan bisa merusak pengenalan
> perintahmu. Tapi perintah yang salah dikenali masih bisa diulang, sedangkan
> langkah yang terlanjur jatuh ke lubang tidak.

**Uji jaring pengaman - aplikasi tidak boleh bisu selamanya:**

- [ ] Tahan Mic, lalu **tarik jarimu keluar layar** / tekan Home di tengah sesi.
      Kembali ke aplikasi: narasi mode **harus hidup lagi**, paling lambat 30 detik
- [ ] Di Cari Objek, tahan tombol "Sebutkan barang" lalu langsung pindah mode lewat
      lembar Pilih mode: mode tujuan **bersuara normal**, tidak diam

**Pill teks itu murni untuk mata.** Ia sengaja disembunyikan dari TalkBack
(`ExcludeSemantics`): isinya berubah beberapa kali per detik, dan setiap perubahan
akan memotong ucapan TalkBack yang sedang berjalan.

#### Jalur cadangan TalkBack: **ketuk**, bukan tahan

Tekan-tahan satu jari sudah dipakai screen reader, jadi saat **TalkBack aktif** tombol
ini otomatis kembali jadi saklar.

| Kamu lakukan (TalkBack ON) | Ekspektasi | ✓ |
|---|---|---|
| Fokuskan tombol Bicara | Dibacakan **"Bicara, ketuk untuk mulai mendengarkan"** | [ ] |
| Ketuk dua kali | Mic menyala | [ ] |
| Diam 3 detik | Sesi **menutup dirinya sendiri** - tidak wajib mengetuk kedua kali | [ ] |
| Saat sedang mendengarkan | Dibacakan **"Berhenti mendengarkan"** | [ ] |

Dengan TalkBack **mati**, labelnya berbeda dan memang harus berbeda:
**"Bicara, tahan lalu ucapkan perintah"** / **"Sedang mendengarkan, lepaskan untuk mengirim"**.

#### Sisanya tetap seperti dulu

- Saat mic aktif, **tombol kiri dan kanan dinonaktifkan** (biar tidak ada aksi tabrakan).
- Kalau izin mikrofon dicabut, tombol jadi abu-abu dan TalkBack membacanya
  "Bicara, tidak tersedia, izin mikrofon belum diberikan".

### Tombol KANAN (Pilih mode)

Membuka lembar berisi **6 mode** + Pengaturan. Ini jalur cadangan kalau tidak bisa bicara.

**Yang diuji di lembar ini (berubah 2026-08-25):**
- [ ] **Keenam mode ada**, termasuk **Deskripsi Suasana**. Ia sempat dikeluarkan dari
      daftar dengan alasan "tombol Bicara sudah jadi pintu masuknya"; alasan itu gugur
      sejak tombol Bicara dan mode ini dipisah perannya
- [ ] Urutannya: Deteksi Objek → Navigasi → Kenali Uang → Baca Teks → Deskripsi Suasana
      → Cari Objek (urutan pemakaian, bukan urutan enum)
- [ ] Pada ukuran teks **normal**, seluruh daftar **tampil sekaligus tanpa perlu digulir**
- [ ] Pada ukuran teks **200%** (Pengaturan HP → Ukuran font terbesar), lembar boleh
      digulir tapi **tidak boleh meluap** (garis kuning-hitam, tombol terpotong)
- [ ] **Navigasi TIDAK bertanda "butuh internet"**, walau WiFi dan data mati total
- [ ] Cari Objek dan Deskripsi Suasana **tetap** ditandai butuh internet - keduanya memang
      butuh backend

### Tombol KIRI: **beda-beda tiap mode**. Ini yang paling sering bikin bingung:

| Mode | Label tombol kiri | Yang dilakukan |
|---|---|---|
| **Deteksi Objek** | `Hentikan` / `Lanjutkan` | **Nyala/mati deteksi rintangan** |
| **Navigasi** | `Matikan Suara` / `Nyalakan Suara` | **Bisu/nyala SUARA panduan** (bukan mematikan navigasi) |
| **Kenali Uang** | `Kenali Uang` | 1 tekan = 1 analisis nominal |
| **Baca Teks** | `Baca teks` → `Jeda bacaan` → `Lanjutkan bacaan` | Berubah mengikuti alur |
| **Deskripsi Suasana** | `Deskripsikan` (ikon cari-gambar 🔍🖼) | **Kirim foto ke VLM server** ← dulu `Ulangi jawaban` |
| **Cari Objek** | `Kirim - cari [barang]` | Kirim frame ke server |

> **Berubah 2026-08-25:** tombol kiri Deskripsi Suasana dulu `Ulangi jawaban`. Sekarang
> ia mengerjakan hal utama mode ini - memotret lalu mengirim ke Moondream2 - sesuai
> kontrak "tombol kiri melakukan hal utama mode ini". Perintah suara **"ulangi"** tetap
> mengulang jawaban terakhir; arti itu tidak tergantikan tombol mana pun.
>
> Ikonnya sengaja **bukan** ikon kamera. Aksinya memang memotret, tapi hasilnya
> deskripsi lisan, bukan foto yang tersimpan.

**Padanan suara:** ucapan **"jepret"** / **"ambil gambar"** / **"foto"** menjalankan
**persis** apa yang dilakukan tombol kiri di mode itu. Jadi kalau kamu di Navigasi lalu
bilang "jepret", yang terjadi adalah suara panduan dibisukan - bukan memotret.

**Tombol nonaktif tidak pernah diam.** Kalau kamu menekan tombol kiri yang sedang
mati, ia tetap mengucapkan alasannya (mis. "Sebutkan barang dulu. **tahan** tombol
bicara lalu sebutkan barangnya") + getar pendek. Ini sengaja - tombol yang diam tidak
bisa dibedakan dari aplikasi yang hang.

> Perhatikan kata **"tahan"** di kalimat itu. Kalau yang terdengar masih "tekan tombol
> bicara", APK-mu build sebelum 2026-08-25.

---

## 4. Uji perpindahan mode lewat suara

Ini uji paling sering dipakai. **Alurnya:**

1. **Tahan** tombol **Mic** (tengah bawah) → terasa getar, cincin berdenyut, pill
   "Mendengarkan…" muncul di atasnya. **Layar mode tidak berganti** - tidak ada lagi
   overlay VoiceScreen.
2. Ucapkan perintah **sambil terus menahan**. Teks yang tertangkap muncul di pill.
   Batasnya **10 detik**; berhenti sejenak di tengah kalimat **tidak** memutus sesi,
   karena yang menutupnya adalah jarimu, bukan hening.
3. **Lepas jari** → getar kedua, lalu terdengar:
   **"Baik. `<Nama Mode>` aktif. `<satu kalimat panduan>`"**

> **Kalau kamu masih menguji dengan cara lama (ketuk lalu bicara), yang terjadi adalah
> "Tahan tombolnya, lalu bicara." dan tidak ada yang direkam.** Itu perilaku yang benar,
> bukan bug.

> **Jeda 3 detik hanya berlaku di jalur ketuk TalkBack**, bukan di tekan-tahan. Dulu 2
> detik, dinaikkan jadi 3 karena pengguna tunanetra yang berjalan sambil memegang
> tongkat, dan pengguna lanjut usia, hampir selalu butuh jeda sebelum mulai bicara.

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
| "deskripsi suasana" / "deskripsikan suasana" / "asisten" / "bicara" / "nanya" / "halo guidio" | Deskripsi Suasana | "Baik. **Deskripsi Suasana** aktif. Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu." | [ ] |
| "cari objek" / "cari barang" | Cari Objek | "Baik. Cari Objek aktif. Sebutkan barang yang kamu cari…" | [ ] |
| "pengaturan" / "setelan" / "setting" | Layar Pengaturan | "Pengaturan terbuka." | [ ] |

### 4B. Kalimat natural (bukan kata kunci kaku)

Parser punya lapis khusus untuk kalimat percakapan. Coba:

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "saya pengin pindah ke mode baca teks" | pindah ke Baca Teks | [ ] |
| "tolong ganti ke mode uang" | pindah ke Kenali Uang | [ ] |
| "aktifkan mode navigasi" | pindah ke Navigasi | [ ] |
| "buka mode asisten suara" | pindah ke Deskripsi Suasana (frasa lama **tetap dikenali**) | [ ] |
| "buka mode deskripsi suasana" | pindah ke Deskripsi Suasana (frasa baru) | [ ] |

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
| "gue mau nanya" | Deskripsi Suasana | [ ] |
| "scan duit" | Kenali Uang | [ ] |

### 4E. Perintah aksi (tanpa ganti mode)

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "nyalakan lampu" / "nyalain senter" | senter menyala, TTS "Baik, lampu dinyalakan." | [ ] |
| "matikan lampu" | senter mati, TTS "Baik, lampu dimatikan." | [ ] |
| "ini mode apa" / "saya di mana" | "Baik. Kamu di mode `<mode aktif saat ini>`." - **harus mode yang sedang aktif**, bukan selalu "Deskripsi Suasana" | [ ] |
| "bisa apa" / "bantuan" | daftar kemampuan dibacakan | [ ] |
| "kembali" / "batal" / "gak jadi" | kembali ke mode sebelumnya, TTS "Kembali. `<Mode>` aktif." | [ ] |
| "lebih cepat" | TTS "Lebih cepat, `<N>` persen." (hanya dari Mode Deskripsi Suasana) | [ ] |
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

#### N-2. Memuat model on-device (sekarang **4 model**)

**Kamu lakukan:** tekan "Siap, mulai"

**Ekspektasi:**
- [ ] Indikator zona muncul dengan status "belum terbaca"
- [ ] Setelah model siap: TTS **"Panduan jalur aktif."**
- [ ] Di `adb logcat`, baris `[Nav] Model on-device siap.` menyebut
      **`PIDNet + YOLO FP16 + YOLO INT8 + SSD COCO`**

> **Berubah 2026-08-25:** ada **lapis keempat**, `yolo11n.tflite` (INT8, ~3 MB), lihat
> [N-6b](#n-6b-lapis-ketiga--keempat-orang-kendaraan-dan-tiang).
>
> Lapis 3 (SSD COCO) dan lapis 4 (YOLO INT8) **tidak menentukan** apakah mode ini
> hidup. Kalau salah satunya gagal dimuat, panduan jalur dan enam kelas bahaya custom
> tetap berjalan penuh, dan tidak ada satu pun pesan galat yang muncul. Yang wajib
> hanya PIDNet-S + YOLO FP16.
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

> **Berubah 2026-08-25 - "pesan sama" sekarang diukur dari IDENTITAS, bukan kalimat.**
> Identitasnya `label|arah|tingkat-bahaya`, dan **jaraknya sengaja tidak ikut**.
> Alasannya bisa kamu buktikan sendiri: `ttsMessage` menyertakan jarak yang dibulatkan
> ("2 meter"), dan angka itu bergoyang tiap frame karena tinggi kotak berubah sedikit.
> Dengan pembanding kalimat penuh, **satu lubang yang diam di tempat** menghasilkan
> kalimat berbeda tiap frame, dianggap peringatan baru, lalu memotong ucapannya sendiri
> berkali-kali sampai tidak ada satu kalimat pun yang selesai.
>
> **Cara mengujinya:** taruh satu benda bahaya diam di depan kamera, lalu **jangan
> bergerak** selama 15 detik.
> - [ ] Kalimatnya **selesai diucapkan utuh**, lalu diam ~4 detik, lalu diulang utuh lagi
> - [ ] **Tidak** terdengar potongan suku kata yang saling memenggal

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

**Uji N-6a - dua bahaya berbeda yang bergantian (baru 2026-08-25):**

**Kamu lakukan:** taruh **dua** benda bahaya berbeda di depan kamera, mis. sebuah
lubang dan sebuah tiang, dengan posisi yang membuat keduanya bergantian terdeteksi

**Ekspektasi:**
- [ ] **Setiap peringatan selesai diucapkan utuh** sebelum yang berikutnya mulai
- [ ] Jarak antar dua peringatan critical **berbeda** minimal **1,5 detik**
- [ ] Kamu **tidak pernah** mendengar "Bahaya! Ada lu-" lalu dipotong "Bahaya! Ada ti-"

> Dua rem terpisah bekerja di sini, dan keduanya baru: **(a)** peringatan critical
> tidak boleh memotong peringatan critical lain yang belum selesai, dan **(b)** ada
> **jeda lantai 1,5 detik** antar critical yang berlaku **walau pesannya berbeda**.
> 1,5 detik kira-kira sepanjang satu kalimat "Bahaya! Ada lubang kurang dari satu
> meter di depan" pada kecepatan bicara bawaan.
>
> Peringatan yang tidak pernah utuh bukan peringatan. Ini uji keselamatan, bukan uji
> kenyamanan.

> **Catatan threshold** (`yolo_navigasi_service.dart`): kelas `lubang` dan `got_terbuka`
> pakai threshold **5%**; kelas lain (`tangga`, `orang`, `motor`, `tiang`) tetap **30%**.
> Kalau YOLO tidak mendeteksi sama sekali, PIDNet-S tetap jadi lapis pengaman lewat
> penurunan rasio area walkable.

#### N-6b. Lapis ketiga & keempat: orang, kendaraan, dan **tiang**

Mode Navigasi sekarang menjalankan **empat model sekaligus**:

| Lapis | Model | Untuk apa | Wajib? |
|---|---|---|---|
| 1 | PIDNet-S | Segmentasi jalur (3 zona) | ✅ ya |
| 2 | `yolo11n_navigasi.tflite` (FP16, NHWC) | 6 kelas bahaya custom | ✅ ya |
| 3 | `ssd_mobilenet.tflite` (COCO) | Orang & kendaraan | ❌ opsional |
| 4 | **`yolo11n.tflite` (INT8, NCHW)** ← baru | 6 kelas yang sama, lebih kuat untuk **`tiang`** | ❌ opsional |

**Kamu lakukan:** arahkan kamera ke orang yang berjalan, ke motor yang terparkir di
trotoar, lalu ke **tiang listrik**

**Ekspektasi:**
- [ ] Orang terdeteksi dan disebut, meski model bahaya jalanan tidak melihatnya
- [ ] Motor terdeteksi dan disebut
- [ ] **Tiang listrik terdeteksi** ← ini yang dulu tidak pernah terjadi
- [ ] Satu benda **tidak pernah disebut dua kali** walau **tiga** model melihatnya
- [ ] Benda tak relevan (botol, ponsel, kursi kantor) **tidak pernah disebut** di mode ini

> **Kenapa lapis keempat ada.** Pada gambar uji `03_tiang_listrik.png`:
>
> ```
> yolo11n_navigasi.tflite (FP16) : tiang max_conf = 0,0000  ← tidak terdeteksi
> yolo11n.tflite          (INT8) : tiang max_conf = 0,3777  ← terdeteksi
> ```
>
> Model INT8 dilatih pada dataset umum yang contoh tiangnya jauh lebih berlimpah.
> Ambangnya juga sengaja sedikit lebih longgar (**0,25** vs 0,30 di model FP16).
> Duplikat antar keduanya dibuang lewat tindih kotak **IoU ≥ 0,45**, jadi satu tiang
> tetap satu peringatan.
>
> ⚠️ **Lapis 4 belum punya uji otomatis sama sekali** - tidak ada satu pun tes yang
> menyentuh `YoloNavInt8Service`. Angka 0,3777 di atas berasal dari catatan
> pengembangan, bukan dari `flutter test`. Untuk sekarang, **uji lapangan N-6b inilah
> satu-satunya bukti** bahwa lapis ini bekerja. Perlakukan hasilnya serius.

#### N-6d. Kartu rintangan tidak boleh berkedip (baru 2026-08-25)

Ini uji untuk **pendamping awas** yang melihat layar, bukan untuk pengguna tunanetra.

**Kamu lakukan:** arahkan kamera ke satu rintangan di kejauhan, tahan diam, perhatikan
kartu peringatan di atas bar tombol

**Ekspektasi:**
- [ ] Kartu **bertahan 1,5 detik** setelah objeknya berhenti terdeteksi, tidak lenyap
      seketika lalu muncul lagi
- [ ] Ada **garis yang menyusut** di dasar kartu - hitung mundur sebelum ia pergi
- [ ] Kartunya **hilang tepat saat garisnya habis**, bukan setengah detik sesudahnya
- [ ] Maksimal **3 kartu** sekaligus, diurutkan dari yang **paling dekat**
- [ ] Objek yang masih terlihat: **isi kartunya diperbarui** (jarak, arah), tapi
      kartunya **tidak dibongkar lalu dipasang lagi**
- [ ] **Tidak pernah ada dua kartu yang tulisannya identik** huruf demi huruf
- [ ] **Kotak hamparan di atas preview tetap mengikuti frame terbaru** (tidak ikut
      ditahan) - kotak yang menggantung akan menggambar sesuatu di tempat yang sudah
      kosong

> Duplikat kasatmata itu pernah nyata: sejak lapis SSD COCO ditambahkan, satu orang
> yang sama datang dari dua model dengan `labelEn` berbeda (`orang` vs `person`) tapi
> `labelId` sama. Identitas kartu kini diambil dari apa yang **benar-benar dibaca
> pengguna** (`"<labelId> di <arah>"`), dan dijaga tes
> `test/nav_card_identity_test.dart`.

#### N-6c. Ponsel lama yang tidak mengejar

**Kamu lakukan:** jalankan Mode Navigasi lama di HP paling lambat yang kamu
punya, sambil memperhatikan jeda antar arahan

**Ekspektasi:**
- [ ] ~~Aplikasi mengurangi bebannya sendiri dulu dengan mematikan deteksi orang dan
      kendaraan~~ ← 🔴 **TIDAK BERLAKU LAGI**, lihat kotak di bawah
- [ ] Kalau tidak mengejar: TTS **"Ponsel ini memproses jalur lebih
      lambat dari biasanya. Jalan lebih pelan, arahan bisa datang terlambat."**
- [ ] Kalimat itu diucapkan **sekali saja**, tidak diulang tiap frame
- [ ] Keluar lalu masuk lagi ke Mode Navigasi mengembalikan semuanya dari nol

> 🔴 **Temuan saat menyusun update ini - katup pelepas beban tidak lagi tersambung.**
>
> Sampai commit `9e3c0ab`, lapis COCO dilewati saat ponsel tertinggal:
> `if (_cocoReady && !_pace.cocoDropped)`. Syarat `!_pace.cocoDropped` **ikut terhapus**
> saat lapis keempat ditambahkan, jadi sekarang berbunyi `if (_cocoReady)` saja
> (`navigation_provider.dart`, `_runOnDeviceInference`). Getter
> `NavigationProvider.cocoDisabledForSpeed` masih ada tapi **tidak dibaca siapa pun**,
> dan `DevicePaceWatch` masih menghitung `cocoDropped` yang tidak lagi berakibat apa pun.
>
> Akibatnya di ponsel lambat justru terbalik dari niat semula: bebannya **naik** dari
> tiga model jadi **empat**, dan satu-satunya yang tersisa adalah kalimat peringatan.
> Jadi yang benar-benar diuji di N-6c sekarang **hanya kalimat itu**.
>
> Ini di luar cakupan pembaruan dokumen. Dicatat supaya penguji tidak menghabiskan
> waktu mencari perilaku pelepas beban yang memang sudah tidak ada, dan supaya
> keputusan memperbaikinya ada di tanganmu - lihat juga
> [bagian 11, K-3](#k-3--katup-pelepas-beban-navigasi-tidak-tersambung).

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

#### U-4b. Gerbang kedua: **margin** ke juara dua (baru 2026-08-25)

> **Perubahan paling berdampak di mode ini.** Yang lolos naik dari **1 dari 5** lembar
> uji jadi **3 dari 5**, **tanpa satu pun jawaban salah ikut lolos.**

Nominal sekarang diucapkan kalau **salah satu** gerbang terpenuhi:

| Gerbang | Syarat |
|---|---|
| **Keyakinan** (lama) | `confidence ≥ 85%` |
| **Margin** (baru) | `margin ke juara dua ≥ 40 poin` **DAN** `confidence ≥ 55%` |

**Kamu lakukan:** ulangi U-3 pada lembar Rp 10.000 dan Rp 20.000 yang sebelumnya
selalu berhenti di "belum yakin"

**Ekspektasi:**
- [ ] Rp 10.000 dan Rp 20.000 sekarang **benar-benar disebut nominalnya**
- [ ] Kertas biasa / kartu **tetap** ditolak, tidak menebak

> **Kenapa margin, bukan menurunkan ambang keyakinan.** Datanya dari
> `test/money_pipeline_test.dart`:
>
> ```
> fixture   benar?  keyakinan   margin
> 5rb          ya       90,6%     87,6
> 10rb         ya       82,0%     71,0
> 20rb         ya       64,7%     55,2
> 5000       TIDAK      42,6%     23,1
> 10000      TIDAK      35,6%      2,2
> ```
>
> Keyakinan memisahkan dengan buruk: `10rb` yang **benar** dan unggul 71 poin tetap
> ditolak, sementara `5000` yang **salah** cuma 42 poin di bawah gerbang. Margin
> memisahkan bersih di angka 40 - ketiga jawaban benar di atas 55, kedua jawaban salah
> di bawah 24. Sebabnya softmax model ini tidak terkalibrasi: probabilitasnya rendah di
> semua kelas sekaligus, tapi **selisihnya** tetap bisa dipercaya.
>
> Menurunkan `confidenceThreshold` saja akan meloloskan `5000` yang **salah** - dan
> menyebut nominal keliru kepada orang yang tidak bisa memeriksanya sendiri berarti
> kerugian uang nyata.

#### U-4c. Instruksi "belum yakin" sekarang **dibedakan** (baru 2026-08-25)

Dulu semua keraguan dijawab satu kalimat: *"Belum yakin, dekatkan sedikit dan tahan
diam."* Itu keluhan nyata dari uji lapangan - pengguna mengulang gerakan yang sama
berkali-kali karena aplikasi tidak pernah memberi tahu apa yang sebenarnya salah.

| Kamu lakukan | Ekspektasi TTS | ✓ |
|---|---|---|
| Lipat/tekuk uang, atau tutupi dengan bayangan (dua pecahan jadi berdempetan, margin < 15 poin) | **"Masih tertukar antara dua pecahan. Bentangkan uangnya, lalu coba dari sudut yang sedikit berbeda."** | [ ] |
| Arahkan ke kertas polos / kartu (keyakinan < 35%) | **"Yang terlihat sepertinya bukan uang. Pastikan seluruh lembar masuk bingkai."** | [ ] |
| Uang benar tapi sedikit goyang (nyaris lolos) | **"Hampir terbaca. Tahan diam sebentar, pastikan tidak ada bayangan di atas uangnya."** | [ ] |
| Tekan tombol sebelum kamera sempat membaca apa pun | **"Belum ada yang terbaca. Arahkan kamera ke uang, lalu tekan lagi."** | [ ] |
| Model gagal dimuat | **"Pengenalan uang tidak tersedia saat ini."** | [ ] |

> Bedanya bukan kosmetik: "tertukar dua pecahan" menyuruh **ganti sudut**, sedangkan
> "bukan uang" menyuruh **ganti sasaran**. Menyuruh "dekatkan dan tahan diam" untuk
> kedua-duanya membuat pengguna mengulang gerakan yang sama sampai menyerah.

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
- [ ] Tombol itu **aktif**, apa pun keadaan jaringannya

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

#### T-7. Uji offline penuh ← **paling penting di mode ini sekarang**

> 🔴 **Berubah 2026-08-25.** Sampai versi sebelumnya, tombol **`Baca teks` dikunci
> saat offline** dengan alasan "Butuh internet untuk teks panjang", dan yang tersisa
> hanyalah tautan kecil "Baca judul saja". Itu bukan sekadar pesan usang: ia
> **mematikan fitur yang sebenarnya hidup**. Jalur `POST /api/ocr` sudah lama dihapus
> dari backend; yang tertinggal cuma gerbang UI-nya. Orang yang percaya lalu berhenti
> mencoba justru saat label obat di tangannya paling perlu dibaca.

**Kamu lakukan:** matikan WiFi **dan** data seluler, ulangi T-2

- [ ] Tombol **`Baca teks` tetap aktif dan bisa ditekan** ← ini intinya
- [ ] Semua tetap berjalan normal (ML Kit on-device)
- [ ] **Tidak ada** pesan "tidak terhubung ke server"
- [ ] **Tidak ada** banner "Tanpa internet, baca judul saja tetap bisa dipakai"
- [ ] **Tidak ada** tautan "Baca judul saja" - tautan itu sudah dihapus, dan
      keberadaannya berarti APK-mu build lama
- [ ] Banner saat proses lama berbunyi **"Masih memproses, `<N>`d…"**, bukan
      "Koneksi lambat" - tidak ada koneksi apa pun yang terlibat

#### T-8. Kegagalan yang masih mungkin (baru 2026-08-25)

Dua jenis kegagalan **dihapus** karena tidak mungkin lagi terjadi: `offline` dan
`server`. Yang tersisa hanya dua.

| Kondisi | Ekspektasi | ✓ |
|---|---|---|
| Tidak ada teks di foto | "Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal." | [ ] |
| Pemrosesan terlalu lama | **"Pembacaan terlalu lama. Coba foto ulang."** (dulu "Terlalu lama merespons") | [ ] |

- [ ] **Tidak boleh** ada pesan "Server tidak bisa dihubungi. Bukan karena gambarmu."
- [ ] **Tidak boleh** ada pesan "Gambar tersimpan, akan dikirim ulang saat online."
      di alur nyata (ia hanya tersisa sebagai state debug BT-13)

#### T-9. Memori ML Kit dilepas saat keluar mode (baru 2026-08-25)

**Kamu lakukan:** masuk Baca Teks → pindai sekali → keluar ke Mode Navigasi → jalankan
navigasi beberapa menit → kembali lagi ke Baca Teks

**Ekspektasi:**
- [ ] Mode Navigasi (yang menjalankan **4 model** sekaligus) tidak jadi lebih berat
      atau lebih sering tersendat gara-gara Baca Teks pernah dibuka
- [ ] Saat kembali ke Baca Teks, pemindaian **pertama** boleh terasa sedikit lebih
      lambat (inisialisasi ulang), pemindaian berikutnya normal lagi
- [ ] Tidak ada crash saat bolak-balik mode ini 10 kali berturut-turut

> ML Kit memegang sumber daya native yang **tidak** ikut dibersihkan pengumpul sampah
> Dart. Sekarang ditutup saat keluar mode, bukan dibiarkan hidup sepanjang umur
> aplikasi. Biayanya satu kali inisialisasi ulang, bukan per pemindaian - dan di ponsel
> 2 GB, setiap megabyte yang ditahan mode lain terasa di Navigasi.

#### T-10. Panel debug: dua state dihapus

**Kamu lakukan:** ketuk badge mode 5× untuk membuka panel debug

**Ekspektasi:**
- [ ] **BT-02 (Idle offline)** dan **BT-14 (Gagal server)** **tidak ada lagi** di daftar
- [ ] State lainnya (BT-01, BT-03…BT-22) tetap lengkap

> Keduanya memodelkan kondisi yang tidak mungkin lagi terjadi. Tombol debug yang
> memaksa state mustahil hanya membuat penguji melaporkan "bug" yang sebenarnya adalah
> simulasinya sendiri.

---

### 5.5 Mode Deskripsi Suasana

> 🔴 **Dulu bernama "Asisten Suara".** Yang berubah bukan cuma namanya - **tombol
> kirinya berganti fungsi**, dari `Ulangi jawaban` jadi `Deskripsikan`, dan mode ini
> berhenti berperan sebagai pintu masuk mikrofon. Sejak tombol Bicara bekerja
> tekan-tahan langsung dari **semua** mode, dua hal itu dipisah: **mic mengurus
> perintah suara, tombol kiri mengirim foto ke VLM.**

#### A-1. Masuk mode

- [ ] TTS "Baik. **Deskripsi Suasana** aktif. Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu."
- [ ] Tombol kiri berlabel **`Deskripsikan`** dengan **ikon cari-gambar**, dan **sudah
      aktif sejak masuk** (dulu `Ulangi jawaban`, nonaktif dengan alasan "belum ada jawaban")
- [ ] Tombol kiri hanya nonaktif saat **sedang memproses**, dengan alasan "sedang memproses"
- [ ] **Tidak ada** slot "Kembali" di atas bar tombol. Keluar dari mode ini lewat tombol
      **Pilih mode** di kanan, sama seperti mode lain

> ⚠️ **Ketidakcocokan kalimat yang sengaja tidak saya ubah.** Kalimat sambutannya masih
> berbunyi *"Ketuk lalu bicara"*, dan pill di layar juga masih *"Ketuk lalu bicara"*
> (`app_mode_provider.dart` dan `voice_screen.dart`). Padahal mengetuk tombol Bicara
> sekarang justru **tidak merekam apa pun** - yang benar adalah **menahannya**.
> Kalimat itu juga masih menggambarkan mode tanya-jawab, bukan mode deskripsi suasana.
> Ini keputusan kata-kata, bukan bug fungsional; lihat
> [bagian 11, K-4](#k-4--kalimat-sambutan-deskripsi-suasana-masih-menyuruh-mengetuk).

#### A-2. Tanya jawab dasar

| Ucapkan | Ekspektasi | ✓ |
|---|---|---|
| "bisa apa" | daftar kemampuan | [ ] |
| "saya di mana" | "Kamu di mode **Deskripsi Suasana**." | [ ] |
| "ulangi jawaban" | jawaban terakhir dibacakan ulang | [ ] |

> **Perhatikan:** "ulangi jawaban" **tidak lagi** sama dengan menekan tombol kiri.
> Tombol kiri sekarang memotret ulang. Kalau menekan tombol kiri malah membacakan
> jawaban lama, APK-mu build sebelum 2026-08-25.

#### A-3. Deskripsi suasana (butuh backend + Moondream2)

**Kamu lakukan:** **tekan tombol kiri `Deskripsikan`** - atau ucapkan "deskripsikan" /
"apa yang ada di depanku" / "liatin depan dong" / "jepret"

**Ekspektasi:**
- [ ] **Keempat cara memicunya menghasilkan perilaku yang sama persis** (satu jalur,
      empat pintu). Tombol dan ucapan tidak boleh bercabang jadi dua perilaku berbeda
- [ ] TTS langsung: **"Saya foto sekitarmu dulu, tunggu sebentar."**
- [ ] Kamera naik ke resolusi capture, foto diambil, dikirim ke backend
- [ ] TTS mengucapkan penanda **"Dalam bahasa Inggris."** dengan suara Indonesia
- [ ] Lalu deskripsinya dibacakan **dalam Bahasa Inggris**, dengan locale `en-US`
- [ ] Sesudahnya, suara **kembali ke Bahasa Indonesia** untuk catatan kualitas dan
      semua ucapan berikutnya
- [ ] Deskripsi **TIDAK berjalan otomatis** saat masuk mode - hanya saat diminta
- [ ] Kalau foto ditolak gerbang kualitas (gelap/buram): terdengar **instruksi konkret**
      ("Terlalu gelap. Cari tempat yang lebih terang"), **bukan** "maaf tidak bisa"

> 🔴 **Berubah 2026-08-25: deskripsi dibacakan APA ADANYA dalam Bahasa Inggris.**
> Penerjemah kamus lokal (`scene_translator.dart`) **dilepas dari jalur produksi**.
>
> Alasannya bukan kualitas kamusnya, melainkan **konsistensinya**: ia menerjemahkan
> sebagian kalimat lalu menyerah pada sisanya, sehingga satu mode yang sama bisa
> menjawab dalam Bahasa Indonesia, Inggris, atau campuran keduanya **tergantung foto**.
> Untuk pengguna yang mengandalkan telinga, tebakan yang tidak konsisten lebih sulit
> diikuti daripada satu bahasa yang tetap.
>
> Konsekuensinya diterima sadar: **ini satu-satunya mode berbahasa Inggris di seluruh
> aplikasi.** Karena itu penanda "Dalam bahasa Inggris." dipertahankan dan **wajib
> terdengar** - tanpa aba-aba, pengguna tunanetra mendengar suaranya tiba-tiba berganti
> bahasa dan kesimpulan pertama yang wajar adalah aplikasinya rusak.
>
> Berkas `scene_translator.dart` dan tesnya sengaja **dipertahankan**, bukan dihapus.
> Kalau kamusnya nanti diperluas sampai cakupannya konsisten, jalurnya tinggal
> disambung lagi di satu tempat.

**Uji A-3b - hanya giliran terakhir yang tampil (baru 2026-08-25):**

**Kamu lakukan:** ucapkan 4-5 perintah berturut-turut di mode ini, lalu lihat layar

**Ekspektasi:**
- [ ] Yang tergambar hanya **satu ucapanmu terakhir + satu jawaban terakhir**
- [ ] Giliran-giliran sebelumnya **tidak menumpuk** dan tidak mendorong jawaban terbaru
      ke bawah layar
- [ ] **Tidak ada** teks "`<N>` giliran sebelumnya diringkas"
- [ ] Perintah **"ulangi"** tetap bisa membacakan jawaban lama - riwayat di dalam
      provider **tidak** ikut dihapus, yang berubah cuma berapa banyak yang digambar
- [ ] Ucapanmu sendiri **tetap ditampilkan** - itu satu-satunya cara kamu memeriksa
      apakah suaramu tertangkap benar

> Transkrip berjalan adalah pola aplikasi obrolan, dan di sini ia salah tempat.
> Pengguna aplikasi ini tidak sedang membaca percakapan; ia baru mengucapkan satu
> perintah dan ingin tahu dua hal: apa yang ditangkap, dan apa jawabannya. Untuk
> pengguna low vision dengan ukuran teks besar, jawaban yang barusan justru yang
> pertama keluar layar.

> ✅ Fitur ini **sebelumnya selalu gagal** (nama field multipart tidak cocok, backend
> membalas 422 untuk setiap permintaan). Sudah diperbaiki - lihat
> [bagian 10, T-1](#10-bug-yang-ditemukan--diperbaiki). Kalau kamu masih mendengar
> "Maaf, saya tidak bisa mendeskripsikan suasana saat ini", pastikan APK yang
> terpasang adalah build **setelah** perbaikan ini.

#### A-7. Kamera harus tetap hidup setelah deskripsi suasana

Ini uji regresi untuk bug yang baru diperbaiki (T-2). **Wajib diuji.**

**Kamu lakukan:**
1. Masuk **Mode Deteksi Objek**, tekan tombol kiri sampai deteksi **menyala**
2. **Tahan** tombol Mic → ucapkan **"deskripsikan"** → lepas → tunggu hasilnya dibacakan
3. Kamu **tidak pernah meninggalkan** Mode Deteksi - tidak ada overlay yang menutup
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

#### A-6. Mic bekerja di tempat, tanpa overlay

> Uji ini dulu berbunyi "VoiceScreen muncul sebagai overlay". **Overlay itu sudah
> dihapus seluruhnya.** Kalau layar penuh masih muncul saat kamu menahan tombol Mic
> dari mode lain, APK-mu build lama.

**Kamu lakukan:** dari Mode Deteksi, **tahan** tombol Mic

**Ekspektasi:**
- [ ] **Layar tidak berganti sama sekali.** Tidak ada transisi, tidak ada layar penuh,
      tidak ada pengumuman TalkBack tentang layar baru
- [ ] Mic menyala seketika, pill teks muncul di atas tombol
- [ ] Lepas jari → perintah dijalankan, mode berganti kalau memang perintah mode
- [ ] Ucapkan **"jepret"** → yang jalan adalah **aksi mode tempat kamu berdiri**
      (mis. toggle deteksi), bukan aksi Deskripsi Suasana

> Untuk perintah dua kata seperti "kenali uang", pola lama menuntut satu transisi
> layar, satu layar penuh yang menutupi mode yang sedang dipakai, dan satu pengumuman
> TalkBack - semuanya **sebelum** mikrofon menyala.
>
> Yang membuat pola baru bisa dipercaya justru **batasnya**, bukan kecepatannya:
> selama jari menempel, mikrofon menyala; begitu diangkat, mati. Pengguna tidak pernah
> perlu menebak apakah aplikasi masih merekam - jarinya sendiri yang menjawab.

#### A-8. TTS dipotong saat mulai menahan (baru 2026-08-25)

**Kamu lakukan:** saat Vinara **masih bicara panjang** (mis. sedang membacakan hasil
Baca Teks), tahan tombol Mic

**Ekspektasi:**
- [ ] Ucapan Vinara **berhenti seketika**, tidak menunggu kalimatnya selesai
- [ ] Mic langsung menyala, dan seluruh perintahmu tertangkap dari kata pertama
- [ ] Berlaku di **semua mode**, bukan cuma di layar ini

> Pengguna yang menahan tombol sudah memutuskan untuk bicara. Memaksanya menunggu
> Vinara selesai berarti separuh perintahnya jatuh ke mikrofon yang belum menyala.

---

### 5.6 Mode Cari Objek

> **Wajib backend hidup.** Ini satu-satunya mode yang benar-benar mati saat offline.

#### C-1. Masuk mode tanpa target

- [ ] TTS "Cari Objek aktif. Sebutkan barang yang kamu cari…"
- [ ] Tombol kiri berlabel **`Sebutkan barang dulu`**, nonaktif
- [ ] Ditekan → tetap bersuara: "Sebutkan barang dulu. **tahan tombol Sebutkan barang
      di atas**" ← menunjuk tombol yang benar
- [ ] **Tombol lebar `Sebutkan barang`** ada tepat di atas bar, setinggi tombol izin
      kamera di layar pembuka

#### C-2. Menyebutkan target ← **tombol kedua**

> 🔴 **Berubah 2026-08-25 - tombolnya pindah.** Nama barang **tidak lagi** diucapkan
> lewat tombol Mic di tengah. Ia punya tombol sendiri: satu blok selebar layar, tepat
> di atas bar.
>
> ```
>   ┌────────────────────────────────────┐
>   │   [ 🎙 Sebutkan barang ]           │  tahan → nama barang
>   └────────────────────────────────────┘
>   ┌────────────────────────────────────┐
>   │ [Kirim]   (( Bicara ))   [Mode]    │  tahan → perintah aplikasi
>   └────────────────────────────────────┘
> ```
>
> **Kenapa dipisah.** Dulu tombol tengah dibajak untuk nama barang, jadi di mode ini
> satu-satunya cara berpindah mode lewat suara hilang - persis di mode yang paling
> mungkin membuat pengguna ingin menyerah dan pindah, saat barangnya tidak ketemu juga
> sementara tangannya penuh dan matanya tidak bisa mencari tombol Pilih mode.
>
> Mode ini tetap punya mesin pengenal suara **sendiri**, karena yang diucapkan adalah
> **nama barang bebas** ("kunci motor", "dompet cokelat"), bukan frasa di bank kata.
> Yang disamakan adalah **gestur**-nya: keduanya memakai kode yang sama persis, jadi
> tidak mungkin menyimpang.

**Kamu lakukan:** **tahan tombol `Sebutkan barang`** → ucapkan "cari dompet" → **lepas**

**Ekspektasi:**
- [ ] Getar saat mulai menahan, getar lagi saat melepas - **sama persis** dengan tombol Mic
- [ ] Tombol berubah **merah**, labelnya jadi **`Mendengarkan…`**
- [ ] Teks yang tertangkap muncul **di dalam tombol itu**, di bawah labelnya
- [ ] TTS "Baik, mencari dompet."
- [ ] Tombol kiri berubah jadi **`Kirim - cari dompet`** dan menjadi aktif
- [ ] Tombol lebar berganti label jadi **`Ganti barang`**
- [ ] Chip target muncul di layar
- [ ] Kartu hasil / panel di layar **tidak tertutup** tombol lebar ini

**Uji C-2a - tombol tengah tetap perintah suara:**

**Kamu lakukan:** di Mode Cari Objek, **tahan tombol Mic di tengah** → ucapkan
"kenali uang" → lepas

**Ekspektasi:**
- [ ] Pindah ke Mode Kenali Uang ← inilah yang dulu **tidak mungkin** dilakukan
- [ ] Pill teks muncul **di atas bar**, bukan di dalam tombol lebar
- [ ] Mesin pengenal yang dipakai adalah `VoiceProvider`, jadi "cari dompet" lewat
      tombol tengah pun tetap bekerja sebagai perintah ganti target

**Uji C-2b - keduanya tidak saling mengacaukan:**
- [ ] Menahan tombol lebar **tidak** membuat tombol Mic tampak menyala, dan sebaliknya
- [ ] Menahan salah satunya membuat **kedua tombol lain di bar** nonaktif seperti biasa

#### C-2c. Jalan buntu yang hening: dua jaring pengaman

| Kamu lakukan | Ekspektasi | ✓ |
|---|---|---|
| Tahan `Sebutkan barang` lalu **lepas tanpa bicara sepatah kata pun** | Dalam **~1,2 detik**: TTS **"Cari apa?"** lalu kembali ke idle. **Tidak boleh** tersangkut di "mendengarkan" | [ ] |
| Tahan `Sebutkan barang` lewat **10 detik** | Audio dibuang, TTS **"Waktu habis, silakan coba lagi."**, status kembali **idle** | [ ] |
| **Ketuk** `Sebutkan barang` (tidak ditahan) | TTS **"Tahan tombolnya, lalu sebutkan barangnya."** | [ ] |
| Sesudah salah satu di atas | Tombol kembali **biru**, dan menahannya lagi **langsung bekerja** | [ ] |

> Ini jalur kegagalan yang paling mudah luput. `stop()` meminta hasil akhir tapi tidak
> menjaminnya: kalau tidak ada satu kata pun tertangkap, **tidak ada apa pun yang
> datang**, dan tanpa jaring pengaman mode ini tinggal di status "mendengarkan"
> **selamanya** - pill terus menyala, tombol Kirim tetap mati. Untuk pengguna yang
> tidak melihat layar, itu jalan buntu yang hening dan tidak bisa dibedakan dari
> aplikasi yang hang.

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
- [ ] **Baru 2026-08-25:** di lembar Pilih Mode, **Navigasi tidak bertanda apa pun**
      soal internet, dan **tombol `Baca teks` tetap bisa ditekan**

> ⚠️ **Satu hal yang TIDAK jalan offline dan memang tidak bisa:** di sebagian perangkat,
> **pengenalan suara Android sendiri butuh internet**. Kalau itu terjadi, yang terdengar
> adalah kalimat yang jujur: **"Pengenalan suara butuh internet di perangkat ini, dan
> sambungannya sedang tidak ada. Gunakan tombol Pilih mode untuk berpindah."** Itu
> perilaku yang benar - bukan kegagalan aplikasi, dan bukan alasan menandai keempat
> mode itu sebagai "butuh internet".

### L-7. Suara Indonesia tidak dipatok kodenya (baru 2026-08-25)

Android memakai kode lama `in` untuk Bahasa Indonesia, warisan ISO 639 sebelum 1989
yang masih dipakai Java sampai hari ini. Jadi tiap pabrikan bisa menuliskannya berbeda:
`id-ID`, `id_ID`, `in-ID`, `in_ID`, `id`, `in`. **Kode yang dipatok akan gagal diam-diam
di perangkat yang menuliskannya lain.**

**Kamu lakukan:** jalankan `adb logcat | grep -E "\[TTS\]|\[STT\]"` lalu buka aplikasi

**Ekspektasi:**
- [ ] Ada baris `[TTS] bahasa dipakai: <kode>` - berapa pun kodenya, asal **ada**
- [ ] Ada baris `[STT] locale dipakai: <kode>`
- [ ] Seluruh aplikasi terdengar dengan **fonetik Bahasa Indonesia**, bukan Inggris
      yang dipaksa membaca kata Indonesia

**Uji L-7b - perangkat tanpa suara Indonesia:**

**Kamu lakukan:** Pengaturan HP → Text-to-speech → copot/nonaktifkan paket suara
Bahasa Indonesia, lalu buka aplikasi dari awal

**Ekspektasi:**
- [ ] **Di layar splash**, terdengar: **"Suara Bahasa Indonesia belum terpasang di
      ponsel ini, jadi ucapan saya mungkin sulit dipahami. Pasang paket suara Bahasa
      Indonesia lewat Pengaturan ponsel, bagian Text-to-speech."**
- [ ] Aplikasi **tetap jalan**, tidak menolak dibuka
- [ ] Log: `[TTS] Bahasa Indonesia TIDAK tersedia di perangkat ini.`

> Fonetiknya memang akan aneh - peringatan itu diucapkan oleh mesin yang bermasalah
> itu juga. Tapi setidaknya **ada yang terdengar dan bisa ditindaklanjuti** oleh
> pendamping awas di dekatnya. Ini satu-satunya momen yang tepat untuk mengatakannya:
> sesudah splash, seluruh aplikasi adalah suara, dan kalau suaranya sendiri yang
> bermasalah, pengguna tunanetra tidak punya cara lain mengetahuinya.

**Uji L-7c - slider kecepatan bicara:**

**Kamu lakukan:** Pengaturan → geser "Kecepatan bicara" dari ujung ke ujung

- [ ] Suaranya **benar-benar berubah** di kedua ujung, bukan slider yang bergerak
      sementara suaranya tetap sama
- [ ] Log menyebut `[TTS] rentang kecepatan: <min>..<max>`

### L-8. Sesi bicara ditutup oleh hasil, bukan oleh mikrofon (baru 2026-08-25)

> Ini perbaikan untuk keluhan **"sudah ngomong tapi langsung bilang belum terdengar
> apa pun"**, dan untuk **"kadang bisa kadang tidak"**.

**Kamu lakukan:** ulangi 10 kali - tahan Mic, ucapkan "kenali uang", lepas

**Ekspektasi:**
- [ ] **10 dari 10 berhasil.** Tidak ada satu pun yang menjawab "Saya belum menangkap
      suaranya" padahal kamu jelas bicara
- [ ] Jawabannya datang **sesudah** kamu melepas jari, bukan mendahuluinya

> Penyebab lamanya: paket `speech_to_text` memancarkan status `notListening` **begitu
> mikrofon berhenti merekam**, padahal mesin pengenal masih memproses audionya. Status
> `done` sengaja ditahan paketnya sampai hasil akhir siap. Versi lama menerima
> **keduanya**, jadi `notListening` yang datang lebih dulu selalu menang - saat itu
> teksnya masih kosong, dan aplikasi langsung menyimpulkan tidak ada yang bicara.
> Hasil sebenarnya tiba sepersekian detik kemudian, ke state yang sudah terlanjur
> menyerah. Itu juga menjelaskan "kadang bisa kadang tidak": yang menentukan cuma
> perlombaan.

**Uji L-8b - sebab kegagalan dibedakan, tidak diseragamkan:**

| Kondisi | Ekspektasi TTS | ✓ |
|---|---|---|
| Mikrofon sedang dipakai aplikasi lain (buka perekam suara dulu, lalu coba) | **"Mikrofon sedang dipakai aplikasi lain. Tutup aplikasi itu, lalu coba lagi."** | [ ] |
| Izin mikrofon dicabut | **"Izin mikrofon belum diberikan. Buka Pengaturan untuk mengizinkannya."** | [ ] |
| Pengenalan butuh internet, jaringan mati | **"Pengenalan suara butuh internet di perangkat ini, dan sambungannya sedang tidak ada. Gunakan tombol Pilih mode untuk berpindah."** | [ ] |
| Benar-benar tidak ada suara | **"Saya belum menangkap suaranya. Tekan tombol bicara lalu ucapkan lagi, agak dekat ke ponsel."** | [ ] |
| Mesin pengenal tidak ada di perangkat | **"Pengenalan suara tidak tersedia di perangkat ini. Gunakan tombol Pilih mode untuk berpindah."** | [ ] |

> Tindakan penggunanya berbeda-beda: mikrofon yang dipakai aplikasi lain tidak akan
> membaik dengan bicara lebih keras, dan izin yang dicabut tidak akan membaik dengan
> mengulang sama sekali. Menyeragamkan semuanya jadi "belum terdengar apa pun" berarti
> menyuruh pengguna mencoba hal yang tidak mungkin berhasil.

### L-9. Izin Android: yang ditambah dan yang dibuang (baru 2026-08-25)

**Kamu lakukan:**

```bash
adb shell dumpsys package <applicationId> | grep -A40 "requested permissions"
```

**Ekspektasi - yang HARUS ada:**
- [ ] `CAMERA`, `RECORD_AUDIO`, `INTERNET`, `VIBRATE`
- [ ] `ACCESS_NETWORK_STATE` - dipakai membedakan "server mati" dari "tidak ada jaringan"
- [ ] `BLUETOOTH_CONNECT` (dan `BLUETOOTH` sampai API 30) - **headset Bluetooth**

**Ekspektasi - yang HARUS TIDAK ADA:**
- [ ] `READ_PHONE_STATE` ← masuk sendiri dari AAR delegate GPU TFLite yang tidak
      menyatakan `targetSdkVersion`, jadi Android menganggapnya aplikasi jaman API 3
- [ ] `READ_EXTERNAL_STORAGE`
- [ ] `WRITE_EXTERNAL_STORAGE` ← keduanya masuk sendiri dari `camera_android_camerax`

> Ketiganya **tidak pernah diminta aplikasi ini**; semuanya diselundupkan penggabung
> manifest, dan bisa dilacak di
> `build/app/outputs/logs/manifest-merger-debug-report.txt`. Membiarkannya bukan cuma
> tidak rapi: **`READ_PHONE_STATE` termasuk izin sensitif** yang menuntut deklarasi
> terpisah di Play Console, dan meminta izin yang tidak dipakai adalah cara tercepat
> ditolak saat rilis.
>
> **Kenapa Bluetooth ditambahkan:** pengguna tunanetra lazim memakai earphone supaya
> panduan suara terdengar di jalan ramai **tanpa menutup telinga dari lalu lintas**.
> Tanpa izin ini, sebagian perangkat menolak merutekan mikrofon ke headset dan
> pengenalan suara memakai mic ponsel yang justru tertutup tangan.

### L-10. Android 11: aplikasi harus BISA MELIHAT mesin suara (baru 2026-08-25)

> 🔴 **Uji ini wajib di Android 11 (API 30), yang kebetulan adalah perangkat uji utama
> proyek ini.**

**Kamu lakukan:** di HP Android 11, tahan tombol Mic dan ucapkan perintah apa pun

**Ekspektasi:**
- [ ] Mikrofon **benar-benar merekam** dan perintahnya dijalankan
- [ ] Ucapan Bahasa Indonesia terdengar dengan **fonetik Indonesia**

> Sejak Android 11, aturan **package visibility** membuat aplikasi tidak bisa melihat
> layanan di perangkat yang tidak dideklarasikan di blok `<queries>`. Tanpa entri
> `android.speech.RecognitionService`, `SpeechRecognizer.isRecognitionAvailable()`
> mengembalikan `false`, `initialize()` gagal, dan `listen()` berikutnya **diam tanpa
> status, tanpa hasil, tanpa galat**. Gejalanya di tangan pengguna persis seperti
> mikrofon yang rusak, padahal mesinnya ada dan berfungsi.
>
> Pasangannya, `android.intent.action.TTS_SERVICE`, punya akibat yang lebih
> menyesatkan lagi: TTS **tetap bersuara**, hanya saja dengan fonetik bahasa bawaan -
> kalimat Bahasa Indonesia dibacakan seolah kata Inggris. Pengguna tunanetra yang
> mengandalkan suara mendengar bunyi yang tidak bisa dia pahami sama sekali.
>
> Keduanya sekarang ada di `AndroidManifest.xml`. Kalau uji ini gagal di Android 11
> tapi lolos di Android 13, **inilah tersangka pertamanya.**

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
| Uang sering "belum yakin" padahal jelas | Akurasi model - 3/5 fixture lolos sejak gerbang margin ditambahkan (dulu 1/5) | Lihat **K-2** bagian 11. Model perlu retrain; jangan turunkan ambangnya |
| Lubang / tangga / tiang tak pernah terdeteksi | YOLO11n FP16 hazard: 0 deteksi di **5** gambar uji, `lubang` kini ikut gagal | Lihat **K-2**. Andalkan PIDNet-S (uji N-4/N-5). Untuk `tiang`, lapis INT8 yang baru adalah harapannya - uji **N-6b** |
| Navigasi stuck di "memuat model" | PIDNet / YOLO11n gagal dimuat | Cek `.tflite` ada di `assets/models/`, jalankan `flutter pub get`, rebuild |
| TTS terdengar buru-buru / saling menimpa | Anti-banjir dilewati | Cek `_minGap` (1,8 s) dan cek `TtsQueue.isSpeaking` di `_emitGuidance` |
| Peringatan critical tidak pernah selesai diucapkan | Critical memotong critical lain | Cek `_criticalFloorGap` (1,5 s), `_criticalRepeatGap` (4 s), dan penjaga `TtsQueue.instance.speakingTier` di `navigation_provider.dart` |
| Suara "jalur aman" dari kamera menghadap tembok | Cabang `_doubtMessage` tidak jalan | Cek `SceneDoubt` di `pidnet_service.dart` |
| Layar hijau "AMAN" tapi suara bilang belum terbaca | Zona tidak di-set `unknown` saat ragu | Cek `untrusted` di `_applyOnDeviceResult` |
| Uang tidak terdeteksi | Keyakinan di bawah ambang | Dekatkan HP, cahaya merata, jangan ada bayangan/silau |
| Nominal acak muncul di release | Mock debug bocor | Build ulang dengan `flutter build apk --release` |
| Cari Objek mati terus | Backend tidak terjangkau HP | Backend harus `--host 0.0.0.0`, isi IP laptop yang benar (bukan `localhost`) |
| Backend error `psycopg.OperationalError` | PostgreSQL belum jalan | `sudo systemctl start postgresql` (opsional - backend tetap hidup tanpa DB) |
| Moondream loading lama sekali | Download pertama ~1,85 GB | Tunggu; hanya sekali, selanjutnya dari cache |
| Perintah suara tidak dikenali | Frasa belum ada di bank kata | Tambahkan ke `command_parser.dart` pada intent yang sesuai |
| **Menekan tombol Bicara tidak merekam apa pun** | **Normal sejak 2026-08-25** - tombolnya tekan-**tahan** | Tahan tombolnya, bicara, lalu lepas. Lihat bagian 3 |
| Layar penuh VoiceScreen tidak muncul lagi saat menekan Mic | **Normal** - overlay itu dihapus | Mic sekarang bekerja di tempat, tanpa berpindah layar |
| Kalimat panjang terpotong saat bicara | Jari terlanjur diangkat, atau memakai jalur ketuk TalkBack | Di tekan-tahan, tahan terus sampai selesai bicara (batas 10 detik). Di jalur ketuk, rekaman ditutup setelah 3 detik hening |
| "Sudah ngomong tapi bilang belum terdengar" | Sesi ditutup `notListening` sebelum hasil tiba (**sudah diperbaiki**) | Build ulang; uji regresi **L-8** |
| Mikrofon seperti rusak di Android 11 | Blok `<queries>` untuk `RecognitionService` tidak ada (**sudah diperbaiki**) | Build ulang; uji **L-10**. Ini tersangka pertama kalau gagal di Android 11 tapi lolos di Android 13 |
| Ucapan Indonesia terdengar dengan fonetik Inggris | Suara Indonesia tidak terpasang, atau `<queries>` TTS tidak ada | Dengarkan peringatan di splash; pasang paket suara lewat Pengaturan HP → Text-to-speech. Uji **L-7b** |
| Deskripsi suasana berbahasa Inggris | **Normal sejak 2026-08-25** - penerjemah lokal dilepas | Penanda "Dalam bahasa Inggris." wajib terdengar lebih dulu. Lihat **A-3** |
| Tombol `Baca teks` mati saat offline | APK build sebelum 2026-08-25 | Build ulang. ML Kit tidak butuh jaringan sama sekali; uji **T-7** |
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
| Deskripsi suasana | "dibacakan dalam Bahasa Inggris" | ⚠️ **Baris ini berbalik lagi pada 2026-08-25.** Penerjemah lokal dilepas dari produksi; deskripsi kini **selalu** Bahasa Inggris, didahului penanda "Dalam bahasa Inggris." Lihat [bagian 12](#12-perubahan-sejak-23-agustus-2026) |
| Field `POST /api/describe` | `-F "file=@..."` | **`-F "image=@..."`** |
| Laju navigasi | "~2 fps (500 ms)" | Timer 500 ms, tapi `FramePacer` menahan minimal **700 ms** → efektif ~1,4 fps |
| Anti-banjir navigasi | "tidak diulang dalam <6 detik" | Lebih rinci: jeda antar pesan berbeda **1,8 s**, pesan sama **6 s**, critical sama **4 s**, plus histeresis **2 frame** untuk non-critical |
| Model `ssd_mobilenet.tflite` | disebut untuk rintangan | Masih benar untuk Mode Deteksi; Navigasi pakai **PIDNet-S + YOLO11n FP16 + YOLO11n INT8 + SSD COCO** (4 model sejak 2026-08-25) |
| Endpoint backend | 8+ endpoint diuji | **Tinggal 5**: `/health`, `/api/capabilities`, `/api/cari-objek`, `/api/cari-objek/targets`, `/api/describe` |

> Tabel di atas mencatat perubahan **sampai 2026-08-23**. Untuk yang sesudahnya, lihat
> [bagian 12](#12-perubahan-sejak-23-agustus-2026).

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

### K-2. 🔴 Akurasi model belum memadai: 8 tes gagal

**Diperbarui 2026-08-25.** `flutter analyze` **bersih (0 issue)**.
`flutter test` → **168 lulus, 3 dilewati, 8 gagal** (sebelumnya 126 lulus, 10 gagal).
Semua kegagalan ada di dua berkas dan semuanya tentang **kualitas model**, bukan kode.

**Kenali Uang** (`money_pipeline_test.dart`) - **3 gagal**, turun dari 6:

```
fixture                asli            top          conf     margin   status
money_new/10000.png    Rp 10.000    Rp50.000       35,6%      2,2     MENEBAK
money_new/5000.png     Rp  5.000    Rp20.000       42,6%     23,1     ragu
money_new2/10rb.png    Rp 10.000    Rp10.000       82,0%     71,0     yakin  ← lolos lewat margin
money_new2/20rb.png    Rp 20.000    Rp20.000       64,7%     55,2     yakin  ← lolos lewat margin
money_new2/5rb.png     Rp  5.000    Rp 5.000       90,6%     87,6     yakin
──────────────────────────────────────────────────────────────────────────────
argmax benar             : 3/5
benar-benar diucapkan    : 3/5   (dulu 1/5)
di zona MENEBAK          : 1/5   (chance level = 14,3%)
```

**Yang membaik:** gerbang margin menaikkan lembar yang benar-benar terbaca dari
**1 dari 5 jadi 3 dari 5**, dan **tidak satu pun jawaban salah ikut lolos**. Ketiga
sisanya memang argmax-nya keliru - model tetap perlu di-retrain, dan ambangnya tetap
tidak boleh diturunkan.

**Yang juga berubah:** tesnya sendiri diperbaiki. Dulu ia membandingkan `confidence`
mentah dengan `confidenceThreshold`; itu berhenti mengukur produksi begitu gerbang
kedua ditambahkan - `10rb` dan `20rb` diucapkan ke pengguna, tapi tesnya tetap merah.
Tes yang mengukur **ambang**, bukan **hasil**, akan memaksa orang berikutnya memilih
antara melonggarkan gerbang atau mengabaikan tesnya. Sekarang yang diuji `detected`.

**Navigasi / hazard YOLO11n FP16** (`model_inference_test.dart`) - **5 gagal**, naik
dari 4: `got_terbuka`, **`lubang`**, `tiang`, `motor+orang`, `tangga` → **0 deteksi**
pada gambar ujinya.

⚠️ **`lubang` yang dulu lulus sekarang ikut gagal.** Ini kelas paling penting di
seluruh mode - ia dan `got_terbuka` sengaja diberi threshold 5%, jauh di bawah kelas
lain, justru karena keduanya paling berbahaya. Kalau keduanya nol deteksi, uji
**N-4/N-5** (segmentasi PIDNet) bukan cuma "lebih menentukan" daripada N-6, ia praktis
**satu-satunya** pengaman yang tersisa untuk lubang.

**Yang belum diuji sama sekali:** lapis keempat, `YoloNavInt8Service`. Tidak ada satu
pun tes yang menyentuhnya. Angka `tiang = 0,3777` yang jadi alasan menambahkannya
berasal dari catatan pengembangan, bukan dari `flutter test`. **Uji lapangan N-6b
adalah satu-satunya bukti yang kamu punya** bahwa lapis ini bekerja.

> Semuanya di luar cakupan perbaikan kode: yang dibutuhkan adalah data latih dan
> pelatihan ulang. Dicatat di sini supaya tidak salah disangka bug aplikasi saat
> kamu menguji di lapangan.

### K-3. 🟠 Katup pelepas beban Navigasi tidak tersambung

- **Di mana**: `navigation_provider.dart` → `_runOnDeviceInference()`
- **Keadaan**: sampai commit `9e3c0ab`, lapis COCO dilewati saat ponsel tertinggal
  (`if (_cocoReady && !_pace.cocoDropped)`). Syarat `!_pace.cocoDropped` **ikut
  terhapus** saat lapis keempat ditambahkan. Getter `cocoDisabledForSpeed` masih ada
  tapi tidak dibaca siapa pun, dan `DevicePaceWatch` masih menghitung `cocoDropped`
  yang tidak lagi berakibat apa pun.
- **Akibatnya**: di ponsel lambat, bebannya justru **naik** dari 3 model jadi 4, dan
  satu-satunya yang tersisa dari mekanisme ini adalah kalimat peringatannya.
- **Kenapa dibiarkan**: perbaikannya sepele secara kode (`&& !_pace.cocoDropped`), tapi
  keputusan **model mana yang dikorbankan lebih dulu** sekarang punya empat pilihan,
  bukan dua - dan itu keputusan desain keselamatan, bukan keputusan kode. Uji **N-6c**
  di HP paling lambat yang kamu punya dulu, lalu putuskan urutan pengorbanannya.

### K-4. 🟡 Kalimat sambutan Deskripsi Suasana masih menyuruh "mengetuk"

- **Di mana**: `app_mode_provider.dart` (`'Ketuk lalu bicara, tanyakan apa saja
  tentang sekitarmu.'`) dan `voice_screen.dart` (pill `'Ketuk lalu bicara'`)
- **Keadaan**: mengetuk tombol Bicara sekarang justru **tidak merekam apa pun** - yang
  benar adalah menahannya. Kalimatnya juga masih menggambarkan mode tanya-jawab,
  padahal mode ini sudah berganti nama dan berganti tombol kiri jadi **Deskripsikan**.
- **Kenapa dibiarkan**: ini keputusan kata-kata, dan kalimat sambutan adalah hal
  pertama yang didengar pengguna di mode ini - layak ditulis sekali dengan benar,
  bukan ditambal. Usulan: *"Tahan tombol bicara untuk memberi perintah, atau tekan
  tombol kiri untuk saya deskripsikan sekitarmu."*

---

## 12. Perubahan sejak 23 Agustus 2026

**14 commit**, dari `9e3c0ab` sampai `6169032`. Kolom terakhir menunjuk uji yang
membuktikannya.

### 🔴 Mengubah cara aplikasi dipakai

| Commit | Perubahan | Uji |
|---|---|---|
| `6169032` | **Tombol Bicara jadi tekan-tahan.** Sekali ketuk tidak lagi merekam; VoiceScreen tidak lagi muncul sebagai overlay. Pill teks parsial muncul di atas tombol. TalkBack dapat jalur ketuk-saklar sendiri | [Bagian 3](#tombol-tengah-mic-tekan-tahan-seperti-walkie-talkie), [A-6](#a-6-mic-bekerja-di-tempat-tanpa-overlay), [A-8](#a-8-tts-dipotong-saat-mulai-menahan-baru-2026-08-25) |
| `197caac` + `4f86a4a` | **"Asisten Suara" → "Deskripsi Suasana".** Tombol kirinya berganti dari `Ulangi jawaban` jadi `Deskripsikan` (kirim foto ke VLM), dengan ikon cari-gambar. Slot "Kembali" dihapus | [5.5](#55-mode-deskripsi-suasana), [A-1](#a-1-masuk-mode) |
| `097d2c7` | **Baca Teks tidak lagi dikunci saat offline.** Tautan "Baca judul saja", banner "Tanpa internet", dan state debug BT-02/BT-14 dihapus. ML Kit juga di-`dispose` saat keluar mode | [T-7](#t-7-uji-offline-penuh--paling-penting-di-mode-ini-sekarang), [T-8](#t-8-kegagalan-yang-masih-mungkin-baru-2026-08-25), [T-9](#t-9-memori-ml-kit-dilepas-saat-keluar-mode-baru-2026-08-25) |
| `0b70ed9` | **Navigasi berhenti ditandai "butuh internet"** di lembar Pilih Mode. Mode Deskripsi Suasana sempat dikeluarkan dari lembar itu, lalu dikembalikan oleh `4f86a4a` | [Bagian 3, tombol kanan](#tombol-kanan-pilih-mode), [L-6](#l-6-uji-offline-total) |
| `0055732` | **Deskripsi suasana dibacakan apa adanya dalam Bahasa Inggris.** Penerjemah kamus lokal dilepas dari produksi karena hasilnya tidak konsisten dari satu foto ke foto lain | [A-3](#a-3-deskripsi-suasana-butuh-backend--moondream2) |

### 🟠 Memperbaiki hal yang diam-diam tidak bekerja

| Commit | Perubahan | Uji |
|---|---|---|
| `81df3e5` | **Sesi bicara ditutup oleh `done`, bukan `notListening`.** Ini penyebab "sudah ngomong tapi bilang belum terdengar" dan "kadang bisa kadang tidak". Sebab kegagalan juga dibedakan per galat Android | [L-8](#l-8-sesi-bicara-ditutup-oleh-hasil-bukan-oleh-mikrofon-baru-2026-08-25) |
| `079f044` | **`<queries>` untuk RecognitionService & TTS_SERVICE.** Wajib sejak Android 11 - tanpanya mikrofon tampak rusak dan TTS membaca Indonesia dengan fonetik Inggris. Tiga izin selundupan penggabung manifest dibuang; Bluetooth headset ditambahkan | [L-9](#l-9-izin-android-yang-ditambah-dan-yang-dibuang-baru-2026-08-25), [L-10](#l-10-android-11-aplikasi-harus-bisa-melihat-mesin-suara-baru-2026-08-25) |
| `b716de1` + `d917ec3` | **Kode bahasa Indonesia dicari, bukan dipatok** - di sisi TTS maupun STT (`id-ID` / `in-ID` / `in_ID` / …). STT tidak pernah lagi jatuh ke bawaan perangkat. Splash memperingatkan kalau suara Indonesia tidak terpasang. Rentang kecepatan bicara ditanyakan ke mesin | [L-7](#l-7-suara-indonesia-tidak-dipatok-kodenya-baru-2026-08-25) |
| `e2a8cae` | **Peringatan bahaya tidak lagi saling memotong.** Perbandingan pengulangan memakai identitas `label\|arah\|bahaya` (jarak sengaja tidak ikut), plus jeda lantai 1,5 detik antar critical yang berbeda | [N-4](#n-4-deteksi-3-zona), [N-6a](#n-6-rintangan-di-jalur) |
| `591d5d2` | **Gerbang margin untuk Kenali Uang.** Lembar yang benar-benar terbaca naik dari 1/5 jadi 3/5, tanpa satu pun jawaban salah ikut lolos. Instruksi "belum yakin" dibedakan jadi 5 kalimat | [U-4b](#u-4b-gerbang-kedua-margin-ke-juara-dua-baru-2026-08-25), [U-4c](#u-4c-instruksi-belum-yakin-sekarang-dibedakan-baru-2026-08-25) |

### 🟢 Menambah cakupan & merapikan

| Commit | Perubahan | Uji |
|---|---|---|
| `9e3c0ab` | **Lapis keempat Navigasi: YOLO11n INT8** (`yolo11n.tflite`, NCHW), khusus memperkuat deteksi `tiang`. Opsional - gagal muat tidak menjatuhkan mode. ⚠️ Ikut menghapus katup pelepas beban COCO, lihat [K-3](#k-3--katup-pelepas-beban-navigasi-tidak-tersambung) | [N-2](#n-2-memuat-model-on-device-sekarang-4-model), [N-6b](#n-6b-lapis-ketiga--keempat-orang-kendaraan-dan-tiang) |
| `1114f86` | `web_socket_channel` **dihapus** (nol pemakaian, sisa era `WS /ws/detect`). Indikator "sedang bicara" diselaraskan dengan token tema | - |
| `4f86a4a` | **Hanya giliran terakhir yang digambar** di Deskripsi Suasana. Riwayat di provider tidak dihapus, "ulangi" tetap bekerja | [A-3b](#a-3-deskripsi-suasana-butuh-backend--moondream2) |
| `9e3c0ab` | **Kartu rintangan ditahan 1,5 detik** dengan garis hitung mundur, maksimal 3, identitas dari teks yang benar-benar dibaca pengguna | [N-6d](#n-6d-kartu-rintangan-tidak-boleh-berkedip-baru-2026-08-25) |

### Uji otomatis yang ikut bertambah

| Berkas | Yang dijaga |
|---|---|
| `test/stt_locale_test.dart` (**baru**) | Bahasa Indonesia adalah bawaan; varian `id_ID` / `id-ID` / `in_ID` semuanya dikenali; daftar yang gagal dibaca **tidak** membuat pilihan jatuh ke bawaan perangkat |
| `test/nav_card_identity_test.dart` (**baru**) | Dua kartu rintangan tidak pernah terlihat kembar walau datang dari dua model dengan `labelEn` berbeda |
| `test/money_pipeline_test.dart` (**diubah**) | Menguji `detected` - apakah nominalnya benar-benar diucapkan - bukan lagi membandingkan `confidence` mentah dengan ambang |

---

## 13. Perubahan 25 Agustus 2026: gerbang suara & tombol kedua

Tiga keluhan pemakaian, satu akar yang sama: **aplikasi ini tidak pernah berhenti
bicara saat penggunanya mencoba bicara.**

### 13.1 Mode dibungkam selama tombol Bicara ditahan

**Keluhannya:** di Mode Deteksi, mencoba pindah mode lewat suara sering gagal, karena
narasi rintangan terus berjalan sementara pengguna bicara.

**Dua sebab, dan keduanya nyata:**

1. **Suara aplikasi masuk ke mikrofonnya sendiri.** Narasi "ada orang di depan" yang
   terucap saat pengguna berkata "kenali uang" membuat mesin pengenal menerima dua
   suara sekaligus, dan yang keluar tidak cocok dengan satu pun frasa `CommandParser`.
2. **Orang tidak bisa menyusun kalimat sambil mendengarkan kalimat lain.** Pengguna
   yang sedang mengingat nama mode tujuan kehilangan kata-katanya begitu ada suara
   lain masuk.

**Yang dipasang:** gerbang di `TtsQueue` - satu-satunya pintu suara di aplikasi ini,
jadi cukup satu tempat untuk menutup semuanya sekaligus.

| Sumber ucapan | Saat tombol Bicara ditahan |
|---|---|
| Narasi mode (rintangan, arahan jalur, petunjuk bingkai) | **dibuang** |
| Jawaban asisten & pengumuman mode | **selalu lewat** |
| **Peringatan bahaya (critical)** | **selalu lewat** |
| Aksi mode yang diminta lewat suara ("jepret", "ulangi", "stop navigasi") | **lewat** - itu jawabannya, bukan narasi |

**Dibuang, bukan diantre.** Narasi yang menumpuk lalu tumpah setelah gerbang lepas
lebih membingungkan daripada tidak terdengar sama sekali - isinya sudah basi.

**Gerbang bertahan sampai jawaban habis diucapkan**, bukan lepas begitu mikrofon
tertutup. Tanpa itu, arahan jalur bertier Warning memotong konfirmasi bertier Info
tepat saat pengguna paling perlu mendengarnya.

**Ada penjaga waktu 30 detik.** Satu jalur yang lupa menutup sesi akan membuat
aplikasi bisu bagi orang yang seluruh antarmukanya adalah suara - kegagalan yang jauh
lebih buruk daripada narasi yang lolos beberapa detik terlalu cepat.

> Uji: [bagian 3](#mode-yang-sedang-berjalan-ikut-diam).

### 13.2 Mode Cari Objek dapat tombol kedua

**Keluhannya:** di mode ini tombol tengah dipakai menyebut nama barang, jadi tidak ada
lagi cara berpindah mode lewat suara.

**Kenapa itu mahal:** mode inilah yang paling mungkin membuat pengguna ingin menyerah
dan pindah - barangnya tidak ketemu juga, tangannya penuh, matanya tidak bisa mencari
tombol Pilih mode. Dan justru di situ jalan keluarnya ditutup.

**Pembagiannya sekarang:**

| Tombol | Arti | Berlaku di |
|---|---|---|
| Tengah, bulat | Perintah suara | **keenam mode, tanpa kecuali** |
| Lebar, di atas bar | Nama barang | Cari Objek saja |

Gestur keduanya **identik** karena berbagi kode yang sama (`HoldToTalkGesture`), bukan
menyalinnya. Dua tombol yang sama-sama berarti "bicara" tapi berbeda dalam satu detail
saja - ambang tahannya, apa yang terjadi saat jari bergeser keluar - merusak
kepercayaan pada keduanya, bukan cuma salah satunya.

> Uji: [C-2](#c-2-menyebutkan-target--tombol-kedua).

### 13.3 Lampu senter: tombolnya melebar, dan statusnya berhenti berbohong

**Sebelumnya:** tombol lampu hanya ada di **Mode Deteksi Objek**. Di mode lain lampu
cuma bisa diatur lewat suara.

**Sekarang** slot lampu ada di **empat mode** - yang kegagalannya benar-benar
ditentukan cahaya:

| Mode | Kenapa | Slot lampu |
|---|---|---|
| Deteksi Objek | rintangan tidak terlihat | ✅ (sudah ada) |
| **Baca Teks** | label obat, struk, papan nama | ✅ **baru** |
| **Kenali Uang** | nominal tidak terkenali | ✅ **baru** |
| **Cari Objek** | barangnya tidak terlihat | ✅ **baru** |
| Navigasi | dipakai sambil berjalan, slot menggeser kartu bahaya | ❌ suara saja |
| Deskripsi Suasana | sama | ❌ suara saja |

**Aturan munculnya sama di keempatnya:** saat sekitar **gelap**, ATAU saat lampunya
**sedang menyala**. Syarat kedua itu yang membuatnya bisa dipercaya - tanpa itu,
menyalakan lampu membuat sekitar terang, `isDark` jadi false, dan tombol untuk
mematikannya lenyap.

#### 🔴 Bug yang ditemukan: status lampu berbohong setelah kamera dibangun ulang

**Jalurnya bisa kamu tempuh sendiri, dan ini uji regresinya:**

1. Masuk **Mode Deteksi Objek** di ruang gelap, tekan **Nyalakan Lampu**
2. Tahan Mic → ucapkan **"deskripsikan"** → lepas
3. Perhatikan lampu ponselmu

**Sebelum perbaikan:** lampu **padam** (controller kamera dibangun ulang untuk
menaikkan resolusi foto, dan controller baru selalu lahir dengan lampu mati), tapi
aplikasi tetap yakin lampunya menyala - tombolnya masih bertuliskan "Matikan Lampu",
dan menekannya tidak mengubah apa pun.

**Ekspektasi sekarang:**
- [ ] Lampu **tetap menyala** setelah "deskripsikan" selesai
- [ ] Tombolnya tetap **`Matikan Lampu`**, dan menekannya **benar-benar mematikan**
- [ ] Hal yang sama setelah berpindah mode bolak-balik, dan setelah aplikasi masuk
      background lalu dibuka lagi

#### Konfirmasi lampu tidak boleh diucapkan kalau lampunya tidak berubah

Dulu `setTorch` menelan dua jalur gagalnya diam-diam - kamera belum siap, dan
perangkat menolak `FlashMode.torch` - lalu pemanggilnya tetap mengucapkan "Lampu
dinyalakan."

| Kamu lakukan | Ekspektasi | ✓ |
|---|---|---|
| Tekan `Nyalakan Lampu` saat kamera normal | TTS **"Lampu dinyalakan."** dan lampu benar-benar menyala | [ ] |
| Tekan `Matikan Lampu` | TTS **"Lampu dimatikan."** dan lampu benar-benar padam | [ ] |
| Di perangkat tanpa lampu / saat kamera bermasalah | TTS **"Lampu tidak bisa dinyalakan sekarang."** - **bukan** konfirmasi palsu | [ ] |
| Ucapkan **"nyalakan lampu"** / **"matikan lampu"** dari mode mana pun | Sama, termasuk di Navigasi dan Deskripsi Suasana yang tidak punya slot | [ ] |

> Aturannya sama dengan perpindahan mode: **suara Vinara tidak boleh pernah
> mengonfirmasi sesuatu yang tidak terjadi.** Lampu justru kasus terburuknya, karena
> ia satu-satunya hal tentang keadaan sekitar yang tidak bisa diperiksa sendiri oleh
> penggunanya.

#### Tata letak di Cari Objek: dua slot bertumpuk

```
  ┌────────────────────────────────────┐
  │ Sekitar gelap - nyalakan lampu?    │  ← hanya saat gelap
  │ [Nyalakan Lampu]      [Lewati]     │
  └────────────────────────────────────┘
  ┌────────────────────────────────────┐
  │   [ 🎙 Sebutkan barang ]           │  ← selalu ada
  └────────────────────────────────────┘
  ┌────────────────────────────────────┐
  │ [Kirim]   (( Bicara ))   [Mode]    │
  └────────────────────────────────────┘
```

- [ ] Slot lampu di **atas** tombol Sebutkan barang, bukan di bawahnya
- [ ] Saat slot lampu muncul dan hilang, **tombol Sebutkan barang tidak bergeser**
- [ ] Kartu hasil pencarian **tidak tertutup** kedua slot itu

### 13.4 Uji otomatis

`test/voice_gate_test.dart` (**baru**, 12 uji): narasi mode dibuang saat gerbang
tertutup, jawaban asisten dan peringatan bahaya menembus, gerbang bertahan sampai
jawaban habis, kalimat yang dibuang masih bisa terdengar sesudahnya (tidak ikut
tercatat di dedup), dan penjaga waktu benar-benar melepas gerbang.

> Uji ini menemukan satu celah nyata di `TtsQueue._drain`: ucapan yang sudah diambil
> dari antrean belum tercatat sebagai "sedang bicara" sampai sesudah jeda bernapas,
> sehingga ada celah di mana antrean tampak kosong padahal ucapannya sudah dipegang di
> tangan. Gerbang lepas satu langkah terlalu awal tepat di celah itu. Sudah diperbaiki.

**Keadaan suite:** `flutter analyze` bersih (0 issue), `flutter test`
**180 lulus, 3 dilewati, 8 gagal** - kedelapan kegagalan sama persis seperti sebelum
perubahan ini, semuanya soal kualitas model ([K-2](#k-2--akurasi-model-belum-memadai-8-tes-gagal)).

---

## Ringkasan cepat: urutan uji yang disarankan

Kalau waktumu terbatas, uji dengan urutan ini:

0. **Kuasai tombol Bicara yang baru dulu** ([bagian 3](#tombol-tengah-mic-tekan-tahan-seperti-walkie-talkie)).
   Tanpa ini, semua uji suara di bawah akan terasa gagal padahal cuma caranya yang
   berubah: **tahan, bicara, lepas.**
1. **Uji regresi perubahan 25 Agustus** - ini yang paling menentukan sekarang:
   **Bagian 3 "Mode yang sedang berjalan ikut DIAM"** dan **C-2** (tombol kedua Cari
   Objek) lebih dulu, karena keduanya mengubah cara aplikasi dipakai. Lalu:
   **L-10** (Android 11 bisa melihat mesin suara - kalau ini gagal, semua uji suara
   ikut gagal), **L-8** (10 dari 10 perintah tertangkap), **T-7** (`Baca teks` aktif
   saat offline), **A-3** (deskripsi suasana + penanda Bahasa Inggris), **U-4b**
   (Rp 10.000 & Rp 20.000 akhirnya disebut), **N-6a** (peringatan bahaya selesai utuh).
2. **Offline dulu** (WiFi + data mati) - Deteksi, Uang, Baca Teks, Navigasi.
   Kalau keempatnya sehat, 4 dari 6 mode sudah aman.
3. **Perpindahan mode lewat suara** (bagian 4) - ini yang paling sering dipakai pengguna.
4. **Tombol kiri tiap mode** (bagian 3 + uji per mode) - pastikan tiap tekan selalu
   ada umpan balik suara/getar. Perhatikan khusus **Deskripsi Suasana**, tombol kirinya
   berganti fungsi.
5. **Mode Navigasi lengkap** (5.2) - mode paling menyangkut keselamatan, paling banyak
   jalur kegagalan. **N-6b wajib**: lapis INT8 tidak punya uji otomatis sama sekali,
   jadi uji lapanganlah satu-satunya bukti.
6. **Nyalakan backend** → uji Cari Objek dan Deskripsi Suasana.
7. **Uji jalur gagal** (bagian 6: gelap, izin dicabut, background, L-7 sampai L-10) -
   di sinilah aplikasi bantu jalan paling sering mengecewakan penggunanya.

---

## Tiga hal yang perlu keputusanmu

Ditemukan saat menyelaraskan dokumen ini dengan kode; semuanya **tidak** saya ubah.

1. **[K-3](#k-3--katup-pelepas-beban-navigasi-tidak-tersambung)** 🟠 - katup pelepas
   beban Navigasi terputus saat lapis keempat ditambahkan. Di ponsel lambat, bebannya
   naik dari 3 model jadi 4.
2. **[K-2](#k-2--akurasi-model-belum-memadai-8-tes-gagal)** 🔴 - kelas **`lubang`** yang
   dulu lulus sekarang ikut nol deteksi, dan lapis INT8 belum punya uji otomatis apa pun.
3. **[K-4](#k-4--kalimat-sambutan-deskripsi-suasana-masih-menyuruh-mengetuk)** 🟡 -
   kalimat sambutan Deskripsi Suasana masih menyuruh "ketuk lalu bicara", padahal
   mengetuk sekarang tidak merekam apa pun.
