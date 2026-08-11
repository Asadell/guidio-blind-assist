# Daftar Uji Manual Vinara Mobile

Panduan memeriksa aplikasi langsung di perangkat. Setiap baris adalah satu
hal yang bisa dicoba beserta hasil yang seharusnya terjadi.

Status: `[ ]` belum diuji, `[x]` sudah, `[-]` tidak berlaku.

**Cara membaca kolom "Butuh internet":** kalau tertulis Tidak, matikan data
dan WiFi lalu uji tetap harus lulus.

---

## Cara menguji kondisi yang sulit dihadirkan

Banyak kondisi sulit dimunculkan sengaja, misalnya baterai 9 persen atau
empat objek berbahaya sekaligus. Untuk itu ada panel tersembunyi:

> **Ketuk 5 kali pada badge mode di kiri atas**, lalu pilih kondisi yang
> ingin dilihat.

Panel ini tersedia di keenam mode. Memilih satu kondisi memaksa layar
menampilkannya sampai dibatalkan lewat menu yang sama.

---

## A. Saat aplikasi dibuka

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| A1 | Buka aplikasi pertama kali | Muncul splash Vinara, suara mulai di detik pertama | `[ ]` |
| A2 | Panduan awal | Tiga langkah perkenalan, tiap langkah dibacakan | `[ ]` |
| A3 | Tekan "Lewati panduan" | Menyebutkan panduan bisa diulang dari Pengaturan | `[ ]` |
| A4 | Permintaan izin | Kamera diminta lebih dulu, baru mikrofon, terpisah | `[ ]` |
| A5 | Tolak izin kamera | Muncul kartu izin beserta alasan, aplikasi tidak berhenti | `[ ]` |
| A6 | Tolak izin permanen | Muncul empat langkah bernomor menuju pengaturan ponsel | `[ ]` |
| A7 | Setelah izin diberikan | Langsung masuk Mode Deteksi Objek yang sudah aktif | `[ ]` |
| A8 | Buka aplikasi kedua kali | Panduan awal tidak muncul lagi | `[ ]` |
| A9 | Putar ponsel ke posisi mendatar | Layar tidak ikut berputar, tetap tegak | `[ ]` |

---

## B. Mode Deteksi Objek

**Butuh internet: Tidak.** Uji dengan data dan WiFi mati.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| B1 | Arahkan ke orang, jarak sekitar 3 meter | Kartu muncul, suara menyebut benda dan arahnya | `[ ]` |
| B2 | Dekati orang sampai kurang dari 1 meter | Suara memotong yang sedang bicara, getar tiga kali cepat | `[ ]` |
| B3 | Arahkan ke benda di sisi kanan | Suara menyebut "kanan" | `[ ]` |
| B4 | Hadapkan ke banyak benda sekaligus | Maksimal 2 kartu, sisanya jadi baris "dan N objek lain" | `[ ]` |
| B5 | Biarkan benda yang sama terus terlihat | Suara **tidak** mengulang tiap detik, ada jeda | `[ ]` |
| B6 | Benda bergerak mendekat | Peringatan datang lebih sering daripada biasa | `[ ]` |
| B7 | Benda keluar dari pandangan | Kartu memudar pelan, **tanpa** suara "objek hilang" | `[ ]` |
| B8 | Tutup kamera dengan tangan | Muncul pil hitam berisi instruksi, bukan banner atas | `[ ]` |
| B9 | Miringkan ponsel menunduk | Muncul instruksi "Angkat ponsel sedikit" | `[ ]` |
| B10 | Matikan WiFi saat mode berjalan | Banner "Tanpa internet", badge mode **turun**, tidak tertimpa | `[ ]` |
| B11 | Saat sedang bicara | Muncul penanda kecil di kanan atas | `[ ]` |
| B12 | Debug: pilih DO-07 | Dua kartu ditambah baris ringkasan objek lain | `[ ]` |
| B13 | Debug: pilih DO-19 | Kartu menyebut bentuk dan jarak, bukan nama benda | `[ ]` |
| B14 | Debug: pilih DO-17 | Banner bahaya berisi persentase baterai | `[ ]` |

---

## C. Mode Kenali Uang

**Butuh internet: Tidak.** Ini yang paling penting diuji tanpa sinyal.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| C1 | Masuk mode | Muncul bingkai panduan dan instruksi meletakkan uang | `[ ]` |
| C2 | Letakkan uang di dalam bingkai | Bingkai mengencang hijau, terasa getar pendek dua kali | `[ ]` |
| C3 | Uang terbaca yakin | Angka besar **dan** kata, contoh "Rp50.000" + "lima puluh ribu rupiah" | `[ ]` |
| C4 | Uang miring atau jauh | **Tidak ada angka sama sekali**, hanya instruksi perbaikan | `[ ]` |
| C5 | Tunjukkan benda bukan uang | Menyebut bendanya, bukan menebak nominal | `[ ]` |
| C6 | Tunjukkan lembar kedua | Nominal baru menggantikan, total berjalan muncul, tanpa disentuh | `[ ]` |
| C7 | Diamkan 60 detik setelah menghitung | Total direset **dan resetnya diumumkan**, tidak hilang diam diam | `[ ]` |
| C8 | Tunjukkan pecahan Rp1.000 | Menyebut keterbatasan, **tidak** menebak pecahan lain | `[ ]` |
| C9 | Matikan semua koneksi | Seluruh mode ini tetap berfungsi penuh | `[ ]` |

> **C4 dan C8 adalah uji terpenting di seluruh dokumen ini.** Menyebut
> nominal yang salah kepada orang yang tidak bisa memeriksa sendiri berarti
> kerugian uang nyata. Aplikasi harus lebih memilih mengaku ragu.

---

## D. Mode Baca Teks

**Butuh internet: Ya**, untuk teks panjang.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| D1 | Masuk mode | Tombol besar "Baca teks" di bawah, busur panduan di kamera | `[ ]` |
| D2 | Tekan tombol besar | Kilat putih sebentar, getar pendek, lalu panel memuat | `[ ]` |
| D3 | Arahkan ke tulisan cetak, ambil gambar | Teks dibacakan, panel menampilkan hasilnya | `[ ]` |
| D4 | Teks panjang | Disebutkan perkiraan durasi sebelum mulai dibacakan | `[ ]` |
| D5 | Tekan jeda saat membaca | Bacaan berhenti, tombol berubah jadi Lanjut | `[ ]` |
| D6 | Matikan internet lalu masuk mode | Tombol utama nonaktif **beserta alasannya**, ada pilihan "Baca judul saja" | `[ ]` |
| D7 | Arahkan ke bidang kosong | Panel gagal berisi instruksi jarak yang konkret | `[ ]` |
| D8 | Tunggu 15 menit setelah hasil keluar | Panel kosong beserta alasan dan satu tombol tindakan | `[ ]` |
| D9 | Kamera buram saat siaga | Muncul instruksi, tetapi tombol utama **tetap aktif** | `[ ]` |
| D10 | Tekan tombol dua kali cepat | Permintaan kedua diabaikan, tidak dobel proses | `[ ]` |

> **D9 disengaja.** Melarang memotret hanya karena sistem menduga gambarnya
> buram akan menjebak pengguna kalau dugaan itu keliru.

---

## E. Mode Navigasi

**Butuh internet: Sebagian.** Peringatan rintangan tetap jalan tanpa internet.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| E1 | Masuk mode | Instruksi kalibrasi cara memegang ponsel, ada tombol "Siap" | `[ ]` |
| E2 | Tekan "Siap" | Tiga chip zona muncul: kiri, tengah, kanan | `[ ]` |
| E3 | Arahkan ke jalur lapang | Ketiga zona hijau, arahan "jalan lurus" | `[ ]` |
| E4 | Arahkan ke jalur terhalang sebagian | Zona terhalang berubah warna, arahan menyebut sisi aman | `[ ]` |
| E5 | Ada rintangan sekaligus masalah jalur | Chip zona **menyusut**, kartu rintangan tetap terbaca penuh | `[ ]` |
| E6 | Perhatikan lapisan warna di kamera | Sangat tipis, wajah orang di depan masih terlihat jelas | `[ ]` |
| E7 | Matikan internet | Mode **tetap hidup**, menyebut hanya rintangan yang tersedia | `[ ]` |
| E8 | Coba pindah mode saat masih berjalan | Muncul dialog konfirmasi, ini satu satunya di aplikasi | `[ ]` |
| E9 | Debug: pilih NV-20 | Pesan "berhenti jalan dulu", jawaban paling jujur saat semua mati | `[ ]` |

> **E6 penting.** Lapisan warna sengaja dibuat sangat tipis. Kalau terlalu
> pekat, video jadi tidak terbaca oleh pendamping yang membantu pengguna.

---

## F. Mode Asisten Suara

**Butuh internet: Ya** untuk jawaban panjang; perintah dasar tetap dikenali
tanpa internet.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| F1 | Tekan tombol tengah, ucapkan "kenali uang" | Pindah ke Mode Kenali Uang | `[ ]` |
| F2 | Ucapkan "baca teks" | Pindah ke Mode Baca Teks | `[ ]` |
| F3 | Tekan tombol lalu diam saja | "Belum terdengar apa pun", tidak menggantung | `[ ]` |
| F4 | Ucapkan sesuatu yang ambigu | Menyebutkan yang didengar, lalu menawarkan dua pilihan | `[ ]` |
| F5 | Tanya "ada apa di depan" | Menyebut perkiraan waktu, lalu menjawab dengan kalimat wajar | `[ ]` |
| F6 | Tekan tombol lagi saat masih bicara | Bacaan berhenti langsung, tanpa nada khusus | `[ ]` |
| F7 | Percakapan sampai banyak giliran | Riwayat lama diringkas, hanya jawaban terbaru yang dibacakan | `[ ]` |
| F8 | Matikan internet | Menyebutkan perintah apa saja yang masih bisa dipakai | `[ ]` |
| F9 | Cabut izin kamera lalu tanya | Tetap bisa menjawab hal yang tidak butuh penglihatan | `[ ]` |
| F10 | Ada bahaya saat sedang menjawab | Peringatan bahaya **memotong** jawaban | `[ ]` |

---

## G. Mode Cari Objek

**Butuh internet: Ya.** Ini satu satunya mode yang benar benar dimatikan
saat offline.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| G1 | Masuk mode | Instruksi menyebutkan barang yang dicari | `[ ]` |
| G2 | Tekan tombol tengah, ucapkan "cari dompet" | Muncul chip target di **baris sendiri**, bukan sebaris badge | `[ ]` |
| G3 | Sedang memindai | Instruksi memutar badan berganti ganti tiap 2 detik | `[ ]` |
| G4 | Barang ditemukan | Menyebut arah dan jarak | `[ ]` |
| G5 | Dekati barangnya | Jarak diperbarui bertahap sampai "ulurkan tangan" | `[ ]` |
| G6 | Sebut barang lain saat pencarian berjalan | Target berganti tanpa perlu keluar mode | `[ ]` |
| G7 | Sebut barang yang panjang namanya | Nama dipotong dengan titik titik, kata "Mencari:" tetap utuh | `[ ]` |
| G8 | Matikan internet | Mode dinonaktifkan beserta alasannya | `[ ]` |

---

## H. Perpindahan mode dan tombol bawah

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| H1 | Tekan tombol kanan bawah | Menu enam mode terbuka | `[ ]` |
| H2 | Perhatikan tiga tombol bawah di semua mode | Posisi, jumlah, dan urutannya **tidak pernah** berubah | `[ ]` |
| H3 | Matikan internet lalu buka menu mode | Cari Objek ditandai tidak tersedia, Navigasi hanya "terbatas" | `[ ]` |
| H4 | Pilih mode yang sedang aktif | Tidak terjadi apa apa | `[ ]` |
| H5 | Masuk mode yang sama tiga kali | Kali keempat penjelasannya lebih ringkas | `[ ]` |
| H6 | Cabut izin mikrofon | Tombol tengah nonaktif, menu mode jadi satu satunya jalan | `[ ]` |

---

## I. Pengaturan

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| I1 | Ubah kecepatan bicara, tekan "Coba dengar" | Contoh kalimat memakai kecepatan baru | `[ ]` |
| I2 | Ubah ukuran teks ke 200 persen | Seluruh aplikasi ikut membesar, tata letak tidak rusak | `[ ]` |
| I3 | Matikan getar, picu peringatan bahaya | Suara tetap ada, getar tidak ada | `[ ]` |
| I4 | Ubah alamat server dengan format salah | Menyebutkan apa yang salah beserta contoh yang benar | `[ ]` |
| I5 | Ubah alamat server ke alamat mati | Alamat lama **tetap dipakai**, kegagalan disebutkan | `[ ]` |
| I6 | Tutup aplikasi, buka lagi | Semua pengaturan masih tersimpan | `[ ]` |
| I7 | Tekan "Ulangi panduan awal" | Panduan tiga langkah muncul lagi | `[ ]` |

---

## J. Uji dengan mata tertutup

Ini uji paling menentukan. Semua mode harus bisa diselesaikan **tanpa
melihat layar sama sekali**.

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| J1 | Nyalakan TalkBack, matikan layar, coba pakai | Seluruh alur bisa diselesaikan | `[ ]` |
| J2 | Dengarkan label tombol | Menyebut aksinya, misalnya "Ambil gambar", bukan "Kamera" | `[ ]` |
| J3 | Dengarkan label tombol nonaktif | Menyebut alasan tidak tersedianya | `[ ]` |
| J4 | Perhatikan penyebutan posisi | **Tidak pernah** ada "tombol di kanan bawah" | `[ ]` |
| J5 | Bayar di warung dengan mata tertutup | Selesai dalam 2 gestur | `[ ]` |
| J6 | Mulai berjalan dengan mata tertutup | Selesai dalam 2 gestur | `[ ]` |

---

## K. Ketahanan

| # | Yang diuji | Yang seharusnya terjadi | Status |
|---|---|---|---|
| K1 | Jalankan Mode Deteksi Objek 5 menit | Tidak berhenti mendadak, gambar tetap lancar | `[ ]` |
| K2 | Pindah mode bolak balik 10 kali | Kamera selalu berhenti dan menyala dengan benar | `[ ]` |
| K3 | Pindah ke aplikasi lain lalu kembali | Kamera tersambung ulang, badge menandakan sedang siap siap | `[ ]` |
| K4 | Terima telepon saat mode berjalan | Suara berhenti, peringatan pindah ke getar | `[ ]` |
| K5 | Matikan backend saat aplikasi berjalan | Mode on-device tidak terpengaruh sama sekali | `[ ]` |

---

## Ringkasan ketergantungan internet

| Mode | Tanpa internet |
|---|---|
| Deteksi Objek | Berfungsi penuh |
| Kenali Uang | Berfungsi penuh |
| Baca Teks | Terbatas, hanya "baca judul saja" |
| Navigasi | Terbatas, rintangan tetap diperingatkan |
| Asisten Suara | Terbatas, hanya perintah dasar |
| Cari Objek | Tidak tersedia |

---

## Hal yang memang belum selesai

1. **Segmentasi jalur memakai cara sederhana**, karena model khususnya belum
   tersedia. Arahan tetap keluar dan mengikuti isi gambar, tetapi
   ketelitiannya di bawah model terlatih.
2. **Pengenalan uang hanya 6 pecahan emisi 2016.** Rp1.000 belum dikenali.
3. **Navigasi belum memakai GPS.** Arahan berasal dari kamera, bukan peta.
4. **Pengenalan suara membutuhkan internet** pada sebagian besar perangkat
   Android, karena memakai mesin bawaan sistem.
5. **Tema gelap dan kontras tinggi** sudah aktif secara menyeluruh, tetapi
   belum dirancang ulang komponen per komponen.
6. **Alamat server bawaan `10.0.2.2:8000`** hanya cocok untuk emulator. Untuk
   perangkat sungguhan, ubah lewat Pengaturan.
