# 📁 KUMPULAN KODE LENGKAP GUIDIO MOBILE APP (FLUTTER)

> Total Berkas: 82

---

## 📑 Daftar Berkas

1. `FEATURE_VERIFICATION.md`
2. `README.md`
3. `analysis_options.yaml`
4. `assets/models/labelmap.txt`
5. `lib/core/layout/zone_contract.dart`
6. `lib/core/net/api_client.dart`
7. `lib/core/net/frame_codec.dart`
8. `lib/core/speech/tts_queue.dart`
9. `lib/core/state/global_conditions.dart`
10. `lib/core/voice/command_parser.dart`
11. `lib/core/voice/intents.dart`
12. `lib/main.dart`
13. `lib/mock/mock_find_object.dart`
14. `lib/mock/ocr_mock_data.dart`
15. `lib/models/detection.dart`
16. `lib/models/index.dart`
17. `lib/models/risk_zone.dart`
18. `lib/providers/app_mode_provider.dart`
19. `lib/providers/camera_provider.dart`
20. `lib/providers/capabilities_provider.dart`
21. `lib/providers/detection_provider.dart`
22. `lib/providers/find_object_provider.dart`
23. `lib/providers/index.dart`
24. `lib/providers/inference_provider.dart`
25. `lib/providers/money_provider.dart`
26. `lib/providers/navigation_provider.dart`
27. `lib/providers/settings_provider.dart`
28. `lib/providers/tts_provider.dart`
29. `lib/providers/voice_provider.dart`
30. `lib/screens/find_object_screen.dart`
31. `lib/screens/index.dart`
32. `lib/screens/main_screen.dart`
33. `lib/screens/money_screen.dart`
34. `lib/screens/navigasi_screen.dart`
35. `lib/screens/ocr_screen.dart`
36. `lib/screens/onboarding_screen.dart`
37. `lib/screens/permissions_screen.dart`
38. `lib/screens/server_address_screen.dart`
39. `lib/screens/settings_screen.dart`
40. `lib/screens/splash_screen.dart`
41. `lib/screens/tuntun_screen.dart`
42. `lib/screens/voice_screen.dart`
43. `lib/services/camera_health_service.dart`
44. `lib/services/detection_filter.dart`
45. `lib/services/haptic_service.dart`
46. `lib/services/index.dart`
47. `lib/services/money_tflite_service.dart`
48. `lib/services/object_tracker.dart`
49. `lib/services/ocr_service.dart`
50. `lib/services/risk_zone_service.dart`
51. `lib/services/server_service.dart`
52. `lib/services/tflite_service.dart`
53. `lib/services/tts_service.dart`
54. `lib/theme/app_colors.dart`
55. `lib/theme/app_spacing.dart`
56. `lib/theme/app_theme.dart`
57. `lib/theme/app_typography.dart`
58. `lib/theme/index.dart`
59. `lib/widgets/alert_card.dart`
60. `lib/widgets/bottom_action_bar.dart`
61. `lib/widgets/camera_health_toast.dart`
62. `lib/widgets/chat_bubble.dart`
63. `lib/widgets/detection_card.dart`
64. `lib/widgets/distance_pill.dart`
65. `lib/widgets/full_screen_button.dart`
66. `lib/widgets/guide_frame.dart`
67. `lib/widgets/index.dart`
68. `lib/widgets/mode_badge.dart`
69. `lib/widgets/mode_picker_sheet.dart`
70. `lib/widgets/nominal_card.dart`
71. `lib/widgets/ocr_debug_sheet.dart`
72. `lib/widgets/ocr_long_result_panel.dart`
73. `lib/widgets/page_action_zone.dart`
74. `lib/widgets/permission_card.dart`
75. `lib/widgets/result_panel.dart`
76. `lib/widgets/speaking_indicator.dart`
77. `lib/widgets/status_banner.dart`
78. `lib/widgets/target_chip.dart`
79. `lib/widgets/tier_icon.dart`
80. `lib/widgets/voice_orb.dart`
81. `lib/widgets/zone_indicator.dart`
82. `pubspec.yaml`

---

## Berkas: `FEATURE_VERIFICATION.md`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/FEATURE_VERIFICATION.md`

```markdown
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
```

---

## Berkas: `README.md`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/README.md`

```markdown
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

Alamat server bawaan `10.0.2.2:8000` (untuk emulator Android). Untuk
perangkat fisik, ubah lewat layar Pengaturan di dalam aplikasi, atau lewat
`lib/services/server_service.dart`.

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
```

---

## Berkas: `analysis_options.yaml`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml
```

---

## Berkas: `assets/models/labelmap.txt`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/assets/models/labelmap.txt`

```text
person
bicycle
car
motorcycle
airplane
bus
train
truck
boat
traffic light
fire hydrant
???
stop sign
parking meter
bench
bird
cat
dog
horse
sheep
cow
elephant
bear
zebra
giraffe
???
backpack
umbrella
???
???
handbag
tie
suitcase
frisbee
skis
snowboard
sports ball
kite
baseball bat
baseball glove
skateboard
surfboard
tennis racket
bottle
???
wine glass
cup
fork
knife
spoon
bowl
banana
apple
sandwich
orange
broccoli
carrot
hot dog
pizza
donut
cake
chair
couch
potted plant
bed
???
dining table
???
???
toilet
???
tv
laptop
mouse
remote
keyboard
cell phone
microwave
oven
toaster
sink
refrigerator
???
book
clock
vase
scissors
teddy bear
hair drier
toothbrush
```

---

## Berkas: `lib/core/layout/zone_contract.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/layout/zone_contract.dart`

```dart
import '../../theme/app_spacing.dart';

/// Kontrak layout dan zona — bagian 4 IMPLEMENTASI.md.
/// Tidak ada elemen yang boleh menimpa elemen lain. Kalau dua elemen minta
/// ruang sama, yang prioritasnya lebih rendah digeser atau diperingkas.
abstract final class ZoneHeights {
  static const safeTop = 32.0;
  static const statusBannerOneLine = 56.0;
  static const statusBannerTwoLine = 64.0;
  static const modeBadge = 40.0;
  static const modeBadgeFontScale200 = 48.0;
  static const bottomActionBar = 112.0;
  static const safeBottom = 24.0;
  static const alertCardMax = 2;

  /// `zone/page-action` — 96 dp tombol + 24 dp safe area. Zona untuk aksi
  /// utama layar penunjang (Onboarding, Izin, Pengaturan) yang tidak punya
  /// BottomActionBar. **Tidak pernah hadir bersamaan dengan
  /// [bottomActionBar]** — sebuah layar punya salah satu, tidak pernah
  /// keduanya. Itu yang menjaga aturan "geser, bukan tumpuk".
  static const pageAction = 120.0;
  static const pageActionPrimary = 96.0;
  static const pageActionSecondary = 56.0;

  /// Jarak baku antara tombol sekunder dan tombol utama di `zone/page-action`.
  static const pageActionGap = 8.0;
}

/// Posisi baku (bagian 4, "Posisi baku") — offset relatif terhadap top-left
/// frame, sebelum ditambah safe-area inset perangkat nyata.
abstract final class ZonePositions {
  static const modeBadgeY = 40.0;
  static const modeBadgeYWithBanner = 96.0;
  static const secondaryChipY = 96.0;
  static const secondaryChipYWithBanner = 152.0;
  static const bottomCardSlotBottom = 120.0;
  static const fullScreenButtonBottom = 132.0;
}

/// Turunkan top-offset ModeBadge / chip sekunder saat StatusBanner hadir —
/// aturan tabrakan "Chip target + ModeBadge" & posisi baku di atas.
double modeBadgeTopOffset({required bool hasBanner}) =>
    hasBanner ? ZonePositions.modeBadgeYWithBanner : ZonePositions.modeBadgeY;

double secondaryChipTopOffset({required bool hasBanner}) =>
    hasBanner ? ZonePositions.secondaryChipYWithBanner : ZonePositions.secondaryChipY;

/// Slot kartu bawah (bottom = 120 dp dari tepi layar) untuk layar mode, yang
/// sudah memakai BottomActionBar dan karena itu **tidak boleh** memakai
/// `zone/page-action`. Semua aksi utama di layar mode mendarat di sini: kartu
/// hasil, NominalCard, ResultPanel, dan tombol izin.
double bottomCardSlotOffset(double bottomInset) =>
    bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6;
```

---

## Berkas: `lib/core/net/api_client.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/net/api_client.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Kelas timeout per jenis operasi. Satu angka timeout untuk semua endpoint
/// selalu salah di salah satu sisi: terlalu pendek untuk OCR, terlalu panjang
/// untuk health check yang seharusnya gagal cepat.
enum ApiOp {
  /// Health, capabilities, intent — pengguna menunggu jawabannya sekarang.
  interactive(Duration(seconds: 4)),

  /// Satu frame ke server dan kembali — segmentasi jalur, cari objek.
  frame(Duration(seconds: 8)),

  /// OCR, unggah antrean — berat, pengguna sudah diberi tahu akan lama.
  heavy(Duration(seconds: 20)),

  /// Telemetri — tidak ada yang menunggu.
  background(Duration(seconds: 5));

  final Duration timeout;
  const ApiOp(this.timeout);
}

/// Dilempar saat server menjawab dengan status non-200. Dipisah dari kegagalan
/// jaringan supaya pemanggil bisa membedakan "server hidup tapi menolak" dari
/// "server tidak terjangkau" — dua kondisi itu punya naskah suara berbeda
/// (BT-14 "bukan karena gambarmu" vs ER-03 "server tidak bisa dihubungi").
class ApiStatusException implements Exception {
  final int statusCode;
  final String path;
  final String? body;
  const ApiStatusException(this.statusCode, this.path, [this.body]);

  @override
  String toString() => 'ApiStatusException($statusCode, $path)';
}

/// Dilempar saat jaringan tidak terjangkau atau melewati timeout.
class ApiUnreachableException implements Exception {
  final String path;
  final Object? cause;
  const ApiUnreachableException(this.path, [this.cause]);

  @override
  String toString() => 'ApiUnreachableException($path, $cause)';
}

/// Klien HTTP bersama untuk seluruh aplikasi.
///
/// **Kenapa satu klien, bukan `http.post()` lepasan.** Fungsi tingkat atas
/// `http.post()` membuat `Client` baru tiap panggilan lalu menutupnya. Artinya
/// tiap permintaan membayar handshake TCP baru — di jaringan seluler itu
/// ratusan milidetik yang terbuang, tiap frame, tiap kali. Satu `Client` yang
/// hidup selama aplikasi berjalan memakai ulang koneksi (keep-alive), dan itu
/// penghematan latensi terbesar yang bisa didapat tanpa mengubah apa pun di
/// server.
///
/// Selain itu klien ini memusatkan empat hal yang kalau ditulis ulang per
/// endpoint pasti tidak konsisten: timeout per jenis operasi, percobaan ulang
/// dengan backoff **hanya untuk operasi idempoten**, kunci idempotensi untuk
/// yang tidak, dan pembedaan error jaringan vs error server.
class ApiClient {
  ApiClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final _rand = Random();

  /// Dipanggil sebelum tiap permintaan untuk mendapat host aktif. Dibuat
  /// sebagai callback, bukan field, supaya perubahan alamat server (PG-08)
  /// langsung berlaku pada permintaan berikutnya tanpa membangun ulang klien.
  late String Function() hostProvider;

  String get _base => 'http://${hostProvider()}';

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  // ── GET / POST JSON ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    ApiOp op = ApiOp.interactive,
    int retries = 2,
  }) async {
    final res = await _send(
      () => _inner.get(_uri(path, query)),
      path: path,
      op: op,
      // GET selalu idempoten — aman diulang.
      retries: retries,
    );
    return _decode(res, path);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    ApiOp op = ApiOp.interactive,
    int retries = 0,
  }) async {
    final res = await _send(
      () => _inner.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      path: path,
      op: op,
      retries: retries,
    );
    return _decode(res, path);
  }

  // ── Unggah gambar ───────────────────────────────────────────────────────

  /// Unggah JPEG mentah sebagai `application/octet-stream`.
  ///
  /// Dipakai untuk endpoint yang hanya butuh gambar tanpa metadata. Lebih
  /// murah daripada multipart: tanpa boundary, tanpa header per bagian.
  ///
  /// **Gambarnya harus sudah diperkecil sebelum sampai di sini.** Lihat
  /// `FrameCodec.encodeForUpload` — memperkecil di sisi klien adalah satu
  /// keputusan yang paling menentukan waktu unggah, jauh di atas pilihan
  /// protokol apa pun.
  Future<Map<String, dynamic>> postBytes(
    String path,
    Uint8List bytes, {
    ApiOp op = ApiOp.frame,
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
  }) async {
    final res = await _send(
      () => _inner.post(
        _uri(path),
        headers: {'Content-Type': contentType, ...?headers},
        body: bytes,
      ),
      path: path,
      op: op,
      // Unggah gambar tidak idempoten kecuali diberi kunci — jangan diulang
      // diam-diam. Pengulangan yang benar lewat antrean (BT-13).
      retries: 0,
    );
    return _decode(res, path);
  }

  /// Unggah multipart — gambar + field. Dipakai saat server butuh metadata
  /// menyertai gambar (target pencarian, koordinat, kunci idempotensi).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List bytes,
    String fileField = 'file',
    String filename = 'frame.jpg',
    Map<String, String> fields = const {},
    ApiOp op = ApiOp.frame,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));

    try {
      final streamed = await _inner.send(req).timeout(op.timeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw ApiStatusException(streamed.statusCode, path, body);
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } on ApiStatusException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiUnreachableException(path, e);
    } catch (e) {
      throw ApiUnreachableException(path, e);
    }
  }

  // ── Inti pengiriman ─────────────────────────────────────────────────────

  /// Backoff eksponensial **dengan jitter**. Jitter penting: tanpa itu, semua
  /// klien yang gagal pada detik yang sama akan mencoba lagi pada detik yang
  /// sama juga, dan server yang baru pulih langsung dijatuhkan lagi.
  Duration _backoff(int attempt) {
    final base = 200 * (1 << attempt); // 200, 400, 800 ms
    final jitter = _rand.nextInt(120);
    return Duration(milliseconds: base + jitter);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() run, {
    required String path,
    required ApiOp op,
    required int retries,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) await Future.delayed(_backoff(attempt - 1));
      try {
        final res = await run().timeout(op.timeout);

        // 5xx layak diulang (server sedang pulih); 4xx tidak — permintaannya
        // sendiri yang salah, mengulang hanya membuang waktu pengguna.
        if (res.statusCode >= 500 && attempt < retries) {
          lastError = ApiStatusException(res.statusCode, path);
          continue;
        }
        if (res.statusCode != 200) {
          throw ApiStatusException(res.statusCode, path, res.body);
        }
        return res;
      } on ApiStatusException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt >= retries) break;
      }
    }
    throw ApiUnreachableException(path, lastError);
  }

  Map<String, dynamic> _decode(http.Response res, String path) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiStatusException(res.statusCode, path, res.body);
    }
  }

  void close() => _inner.close();
}

/// Pengatur laju frame untuk mode yang mengalirkan gambar terus-menerus
/// (Navigasi, Cari Objek).
///
/// **Aturan: frame terbaru menang, frame lama dibuang.** Kalau server lambat,
/// mengantrekan frame justru berbahaya — pengguna akan mendengar arahan untuk
/// pemandangan yang sudah lewat beberapa detik lalu, sementara ia sudah
/// berjalan maju. Untuk aplikasi yang menuntun orang berjalan, arahan basi
/// lebih buruk daripada tidak ada arahan.
///
/// Karena itu kelas ini menjaga **paling banyak satu permintaan in-flight**.
/// Frame yang datang saat masih ada yang berjalan langsung dibuang, bukan
/// diantre. Ditambah [minInterval] sebagai batas bawah supaya kamera 30 fps
/// tidak membanjiri server yang sanggup melayani 3 fps.
class FramePacer {
  FramePacer({this.minInterval = const Duration(milliseconds: 350)});

  final Duration minInterval;
  bool _inFlight = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  int _dropped = 0;

  /// Berapa frame dibuang sejak terakhir dibaca — berguna untuk menurunkan
  /// laju kamera saat server konsisten tidak mengejar (NV-13, NV-24).
  int takeDroppedCount() {
    final n = _dropped;
    _dropped = 0;
    return n;
  }

  bool get isBusy => _inFlight;

  /// Menjalankan [task] kalau slot kosong dan jeda minimum sudah lewat.
  /// Mengembalikan null kalau frame dibuang.
  Future<T?> run<T>(Future<T> Function() task) async {
    final now = DateTime.now();
    if (_inFlight || now.difference(_lastSent) < minInterval) {
      _dropped++;
      return null;
    }
    _inFlight = true;
    _lastSent = now;
    try {
      return await task();
    } finally {
      _inFlight = false;
    }
  }

  void reset() {
    _inFlight = false;
    _dropped = 0;
    _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Kunci idempotensi untuk operasi yang **tidak** aman diulang begitu saja
/// (unggah antrean BT-13). Server memakai kunci ini untuk mengenali kiriman
/// ulang dan tidak memproses dua kali.
String newIdempotencyKey() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final salt = Random().nextInt(1 << 32);
  return '$now-${salt.toRadixString(16)}';
}

@visibleForTesting
ApiClient debugApiClient(http.Client inner) => ApiClient(inner: inner);
```

---

## Berkas: `lib/core/net/frame_codec.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/net/frame_codec.dart`

```dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Payload YUV420 yang **bisa dikirim antar isolate**.
///
/// `CameraImage` adalah objek platform dan tidak bisa menyeberang batas
/// isolate, jadi byte-nya disalin ke bentuk polos dulu. Penyalinan ini murah
/// dibanding konversi warnanya sendiri.
@immutable
class YuvFrame {
  final int width;
  final int height;
  final Uint8List y;
  final Uint8List u;
  final Uint8List v;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  const YuvFrame({
    required this.width,
    required this.height,
    required this.y,
    required this.u,
    required this.v,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  factory YuvFrame.fromCameraImage(CameraImage image) => YuvFrame(
        width: image.width,
        height: image.height,
        y: image.planes[0].bytes,
        u: image.planes[1].bytes,
        v: image.planes[2].bytes,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
      );
}

/// Parameter encode. Dibungkus jadi satu objek karena `compute` hanya
/// menerima satu argumen.
@immutable
class _EncodeRequest {
  final YuvFrame frame;
  final int maxEdge;
  final int quality;
  const _EncodeRequest(this.frame, this.maxEdge, this.quality);
}

/// Preset ukuran unggah per jenis pemakaian.
///
/// **Memperkecil gambar sebelum dikirim adalah keputusan yang paling
/// menentukan waktu unggah** — jauh lebih berpengaruh daripada pilihan
/// protokol, keep-alive, atau kompresi tambahan. Frame 640×480 pada kualitas
/// 70 sekitar 40–60 KB; frame 1920×1080 kualitas 90 bisa 400 KB. Di jaringan
/// seluler menengah itu selisih beberapa detik, tiap frame.
///
/// Angka di bawah dipilih dari apa yang model di server benar-benar pakai:
/// mengirim piksel lebih banyak daripada yang dikonsumsi model adalah biaya
/// murni tanpa perbaikan akurasi.
abstract final class UploadPreset {
  /// Segmentasi jalur & deteksi objek — model server memakai 640 px.
  static const navigation = (maxEdge: 640, quality: 70);

  /// Cari objek — butuh sedikit lebih tajam untuk barang kecil.
  static const findObject = (maxEdge: 800, quality: 75);

  /// OCR — teks butuh resolusi jauh lebih tinggi. Huruf kecil hancur di 640 px.
  static const ocr = (maxEdge: 1600, quality: 85);
}

/// Konversi dan kompresi frame kamera untuk dikirim ke server.
abstract final class FrameCodec {
  /// YUV420 → JPEG **di isolate terpisah**.
  ///
  /// Versi lama mengerjakan ini di UI thread: 640×480 berarti 307.200 iterasi
  /// Dart per frame. Pada laju streaming apa pun itu membuat antarmuka
  /// tersendat — dan di aplikasi yang dipakai sambil berjalan, tersendat
  /// berarti peringatan terlambat. `compute` memindahkannya ke isolate lain
  /// sehingga UI thread bebas menggambar dan TTS tetap lancar.
  static Future<Uint8List> encodeForUpload(
    CameraImage image, {
    int maxEdge = 640,
    int quality = 70,
  }) {
    final frame = YuvFrame.fromCameraImage(image);
    return compute(_encodeIsolate, _EncodeRequest(frame, maxEdge, quality));
  }

  /// Versi untuk JPEG yang sudah jadi (hasil `takePicture`) — hanya
  /// memperkecil dan mengompres ulang. Dipakai sebelum mengunggah foto OCR:
  /// kamera sering menghasilkan 4000 px yang tidak menambah akurasi apa pun.
  static Future<Uint8List> recompressJpeg(
    Uint8List jpeg, {
    int maxEdge = 1600,
    int quality = 85,
  }) =>
      compute(_recompressIsolate, (jpeg, maxEdge, quality));
}

Uint8List _encodeIsolate(_EncodeRequest req) {
  final f = req.frame;
  final rgb = img.Image(width: f.width, height: f.height);

  for (var y = 0; y < f.height; y++) {
    final yRow = y * f.yRowStride;
    final uvRow = (y >> 1) * f.uvRowStride;
    for (var x = 0; x < f.width; x++) {
      final uvIdx = uvRow + (x >> 1) * f.uvPixelStride;

      final yVal = f.y[yRow + x] & 0xFF;
      final uVal = (uvIdx < f.u.length ? f.u[uvIdx] : 128) & 0xFF;
      final vVal = (uvIdx < f.v.length ? f.v[uvIdx] : 128) & 0xFF;

      final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
      final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

      rgb.setPixelRgb(x, y, r, g, b);
    }
  }

  return _downscaleAndEncode(rgb, req.maxEdge, req.quality);
}

Uint8List _recompressIsolate((Uint8List, int, int) args) {
  final (bytes, maxEdge, quality) = args;
  final decoded = img.decodeJpg(bytes);
  if (decoded == null) return bytes; // biarkan apa adanya daripada gagal total
  return _downscaleAndEncode(decoded, maxEdge, quality);
}

Uint8List _downscaleAndEncode(img.Image src, int maxEdge, int quality) {
  final longEdge = src.width > src.height ? src.width : src.height;
  final out = longEdge <= maxEdge
      ? src
      : img.copyResize(
          src,
          width: src.width >= src.height ? maxEdge : null,
          height: src.height > src.width ? maxEdge : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}
```

---

## Berkas: `lib/core/speech/tts_queue.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/speech/tts_queue.dart`

```dart
import 'dart:async';

import '../../services/tts_service.dart';

/// Prioritas tier suara — bagian 15 "Model interupsi dan antrean audio".
///
/// ```
/// Critical  → memotong semua, tidak bisa dipotong pengguna
/// Warning   → memotong Info, bisa dipotong pengguna
/// Info      → mengantre; dibuang kalau sudah lewat 2 detik
/// ```
enum SpeechTier { info, warning, critical }

class _QueuedSpeech {
  final String message;
  final SpeechTier tier;
  final DateTime queuedAt;
  _QueuedSpeech(this.message, this.tier) : queuedAt = DateTime.now();
}

/// TtsQueue — mesin antrean bertingkat yang dipakai [TtsProvider].
/// Aturan:
/// - Critical: kosongkan antrean, interrupt TTS berjalan, bicara langsung.
/// - Warning: interrupt Info yang sedang bicara; boleh disela pengguna lewat
///   [interruptByUser].
/// - Info: masuk antrean; dibuang jika sudah menunggu > 2 detik saat giliran
///   tiba (anti-banjir, bagian 15).
class TtsQueue {
  final _pending = <_QueuedSpeech>[];
  SpeechTier? _speakingTier;
  bool _draining = false;

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null;

  Future<void> speak(String message, {SpeechTier tier = SpeechTier.info}) async {
    if (tier == SpeechTier.critical) {
      _pending.clear();
      _speakingTier = SpeechTier.critical;
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = null;
      unawaited(_drain());
      return;
    }

    if (tier == SpeechTier.warning && _speakingTier == SpeechTier.info) {
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = SpeechTier.warning;
      _speakingTier = null;
      unawaited(_drain());
      return;
    }

    _pending.add(_QueuedSpeech(message, tier));
    unawaited(_drain());
  }

  /// Pengguna menimpa TTS yang sedang jalan (mis. menekan tombol) — tidak
  /// berlaku untuk peringatan Critical, yang "tidak bisa dipotong pengguna".
  Future<void> interruptByUser() async {
    if (_speakingTier == SpeechTier.critical) return;
    await TTSService.instance.stop();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        _pending.sort((a, b) => b.tier.index.compareTo(a.tier.index));
        final next = _pending.removeAt(0);

        // Info dibuang kalau sudah lewat 2 detik menunggu.
        if (next.tier == SpeechTier.info &&
            DateTime.now().difference(next.queuedAt) > const Duration(seconds: 2)) {
          continue;
        }

        _speakingTier = next.tier;
        await TTSService.instance.speak(next.message);
        _speakingTier = null;
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> stop() async {
    _pending.clear();
    await TTSService.instance.stop();
    _speakingTier = null;
  }
}
```

---

## Berkas: `lib/core/state/global_conditions.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/state/global_conditions.dart`

```dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../widgets/tier_icon.dart' show AlertTier;

/// Satu kondisi global aktif (offline, baterai kritis, penyimpanan penuh,
/// ponsel panas). Storage dan thermal tidak punya sensor resmi yang murah di
/// Flutter — keduanya dipicu manual lewat [setStorageLow] / [setDeviceHot]
/// (mis. dari panel debug atau pengukuran kasar), sesuai bagian 2 dokumen:
/// "boleh dipalsukan" untuk hal yang bukan inti keselamatan.
class _Condition {
  final String id;
  final AlertTier tier;
  final String label;
  const _Condition(this.id, this.tier, this.label);
}

/// Hasil StatusBanner setelah kondisi digabung — bagian 5.7 & 13.
class MergedBanner {
  final AlertTier tier;
  final String message;
  final String? sub;
  final String? actionLabel;
  const MergedBanner({required this.tier, required this.message, this.sub, this.actionLabel});
}

/// GlobalConditions — penggabungan StatusBanner sesuai bagian 4 & 13.
/// Maksimum SATU banner di layar. 1 kondisi → pesan+sub. 2 kondisi →
/// digabung satu kalimat. 3+ kondisi → dua disebut, sisanya "dan N masalah
/// lain" + aksi "Lihat semua".
class GlobalConditionsProvider extends ChangeNotifier {
  bool _offline = false;
  int? _batteryPercent;
  bool _storageLow = false;
  bool _deviceHot = false;

  StreamSubscription? _connSub;
  Timer? _batteryTimer;

  bool get isOffline => _offline;
  int? get batteryPercent => _batteryPercent;
  bool get isBatteryCritical => (_batteryPercent ?? 100) < 15;
  bool get isStorageLow => _storageLow;
  bool get isDeviceHot => _deviceHot;

  Future<void> init() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      _offline = initial.contains(ConnectivityResult.none);
    } catch (_) {
      _offline = false;
    }
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nowOffline = results.contains(ConnectivityResult.none);
      if (nowOffline != _offline) {
        _offline = nowOffline;
        notifyListeners();
      }
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _pollBattery());
    await _pollBattery();
  }

  Future<void> _pollBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (level != _batteryPercent) {
        _batteryPercent = level;
        notifyListeners();
      }
    } catch (_) {
      // Platform tanpa dukungan battery_plus (mis. desktop web debug) — abaikan.
    }
  }

  void setStorageLow(bool value) {
    if (_storageLow == value) return;
    _storageLow = value;
    notifyListeners();
  }

  void setDeviceHot(bool value) {
    if (_deviceHot == value) return;
    _deviceHot = value;
    notifyListeners();
  }

  List<_Condition> get _active => [
        if (_offline) const _Condition('offline', AlertTier.warning, 'Tanpa internet'),
        if (isBatteryCritical)
          _Condition('battery', AlertTier.critical, 'Baterai ${_batteryPercent ?? 0} persen'),
        if (_storageLow) const _Condition('storage', AlertTier.warning, 'Penyimpanan hampir penuh'),
        if (_deviceHot) const _Condition('thermal', AlertTier.warning, 'Ponsel panas'),
      ];

  /// null = tidak ada banner. Urutan penyebutan: baterai/critical dulu, baru
  /// yang lain — "sebut yang masih hidup dulu, baru yang mati" (bagian 17)
  /// diterjemahkan di layar mode masing-masing; di sini tier tertinggi yang
  /// menentukan urutan tampil.
  MergedBanner? get merged {
    final active = [..._active]..sort((a, b) => b.tier.index.compareTo(a.tier.index));
    if (active.isEmpty) return null;

    final topTier = active.first.tier;
    const subDetection = 'Deteksi rintangan tetap jalan';

    if (active.length == 1) {
      final c = active.first;
      return MergedBanner(
        tier: c.tier,
        message: c.label,
        sub: c.id == 'offline' ? subDetection : null,
      );
    }

    if (active.length == 2) {
      final msg = active.map((c) => c.label).join(', ');
      return MergedBanner(tier: topTier, message: msg, sub: subDetection);
    }

    final first2 = active.take(2).map((c) => c.label).join(', ');
    final rest = active.length - 2;
    return MergedBanner(
      tier: topTier,
      message: first2,
      sub: 'dan $rest masalah lain',
      actionLabel: 'Lihat semua',
    );
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }
}
```

---

## Berkas: `lib/core/voice/command_parser.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/command_parser.dart`

```dart
import 'intents.dart';

/// CommandParser — varian ucapan → intent, sesuai tabel bagian 14.
/// Sengaja berbasis keyword lokal (0ms, aman offline) mengikuti pola
/// [VoiceProvider] yang sudah ada. Panggil [parse] dengan teks hasil STT.
class CommandParser {
  static const Map<VoiceIntent, List<String>> _phrases = {
    VoiceIntent.modeMoney: [
      'buka mode uang', 'kenali uang', 'ini uang berapa', 'mode uang', 'cek uang', 'berapa ini',
    ],
    VoiceIntent.modeReadText: [
      'baca teks', 'bacakan', 'buka mode baca', 'baca tulisan ini', 'apa tulisannya',
    ],
    VoiceIntent.modeDetection: [
      'deteksi objek', 'mode deteksi', 'ada apa di depan',
    ],
    VoiceIntent.modeNavigation: [
      'mode navigasi', 'mau jalan', 'bantu jalan', 'navigasi',
    ],
    VoiceIntent.modeAssistant: [
      'asisten', 'tanya', 'mode suara',
    ],
    VoiceIntent.modeFindObject: [
      'cari objek', 'cari barang', 'carikan',
    ],
    VoiceIntent.modeSettings: [
      'pengaturan', 'setelan', 'buka pengaturan',
    ],
    VoiceIntent.actionCapture: [
      'ambil gambar', 'jepret', 'foto',
    ],
    VoiceIntent.actionReplay: [
      'putar ulang', 'ulangi', 'baca lagi',
    ],
    VoiceIntent.actionSummary: [
      'ringkas', 'singkat saja', 'baca ringkasannya',
    ],
    VoiceIntent.actionStopWalking: [
      'selesai jalan', 'sudah sampai', 'berhenti navigasi',
    ],
    VoiceIntent.actionShowAll: [
      'lihat semua',
    ],
    VoiceIntent.actionTorch: [
      'nyalakan lampu', 'nyalakan senter', 'lampu kamera',
    ],
    VoiceIntent.playPause: [
      'jeda', 'berhenti dulu', 'stop',
    ],
    VoiceIntent.playResume: [
      'lanjut', 'terusin', 'lanjutkan',
    ],
    VoiceIntent.playFaster: [
      'lebih cepat', 'percepat',
    ],
    VoiceIntent.playSlower: [
      'lebih pelan', 'pelan-pelan',
    ],
    VoiceIntent.playRepeatSection: [
      'ulangi bagian', 'ulang yang tadi',
    ],
    VoiceIntent.helpWhat: [
      'bisa apa', 'apa saja', 'bantuan', 'tolong',
    ],
    VoiceIntent.helpWhereAmI: [
      'ini mode apa', 'saya di mana',
    ],
  };

  /// "cari [nama barang]" — pola khusus Cari Objek dengan argumen dinamis.
  static final RegExp _findObjectWithArg = RegExp(r'^cari (?!objek$|barang$)(.+)$');

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand(rawText: rawText);

    final argMatch = _findObjectWithArg.firstMatch(text);
    if (argMatch != null) {
      return VoiceCommand(
        rawText: rawText,
        intent: VoiceIntent.findObjectTarget,
        argument: argMatch.group(1)?.trim(),
      );
    }

    for (final entry in _phrases.entries) {
      for (final phrase in entry.value) {
        if (text.contains(phrase)) {
          return VoiceCommand(rawText: rawText, intent: entry.key);
        }
      }
    }

    return VoiceCommand(
      rawText: rawText,
      suggestions: _nearestGuesses(text),
    );
  }

  /// Dua tebakan terdekat berbasis jumlah kata yang beririsan — dipakai untuk
  /// naskah "Saya dengar X. Maksudmu Y, atau Z?" (bagian 14, "Tidak dikenali").
  static List<VoiceIntent> _nearestGuesses(String text) {
    final words = text.split(RegExp(r'\s+')).toSet();
    final scored = <MapEntry<VoiceIntent, int>>[];

    for (final entry in _phrases.entries) {
      var best = 0;
      for (final phrase in entry.value) {
        final phraseWords = phrase.split(RegExp(r'\s+')).toSet();
        final overlap = words.intersection(phraseWords).length;
        if (overlap > best) best = overlap;
      }
      if (best > 0) scored.add(MapEntry(entry.key, best));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(2).map((e) => e.key).toList();
  }
}

/// Label ucapan untuk ditawarkan balik ke pengguna, mis. "Maksudmu kenali
/// uang, atau cari uang yang jatuh?" — bagian 14.
extension VoiceIntentSpokenLabel on VoiceIntent {
  String get spokenLabel => switch (this) {
        VoiceIntent.modeMoney => 'kenali uang',
        VoiceIntent.modeReadText => 'baca teks',
        VoiceIntent.modeDetection => 'deteksi objek',
        VoiceIntent.modeNavigation => 'navigasi',
        VoiceIntent.modeAssistant => 'asisten suara',
        VoiceIntent.modeFindObject => 'cari objek',
        VoiceIntent.modeSettings => 'pengaturan',
        VoiceIntent.actionCapture => 'ambil gambar',
        VoiceIntent.actionReplay => 'putar ulang',
        VoiceIntent.actionSummary => 'ringkas',
        VoiceIntent.actionStopWalking => 'selesai jalan',
        VoiceIntent.actionShowAll => 'lihat semua',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.playPause => 'jeda',
        VoiceIntent.playResume => 'lanjut',
        VoiceIntent.playFaster => 'lebih cepat',
        VoiceIntent.playSlower => 'lebih pelan',
        VoiceIntent.playRepeatSection => 'ulangi bagian',
        VoiceIntent.helpWhat => 'bantuan',
        VoiceIntent.helpWhereAmI => 'saya di mana',
        VoiceIntent.findObjectTarget => 'cari barang',
      };
}
```

---

## Berkas: `lib/core/voice/intents.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/intents.dart`

```dart
/// Intent perintah suara — bagian 14 IMPLEMENTASI.md. 20 intent baku.
enum VoiceIntent {
  // Ganti mode
  modeMoney,
  modeReadText,
  modeDetection,
  modeNavigation,
  modeAssistant,
  modeFindObject,
  modeSettings,
  // Tindakan dalam mode
  actionCapture,
  actionReplay,
  actionSummary,
  actionStopWalking,
  actionShowAll,
  actionTorch,
  // Kontrol pemutaran
  playPause,
  playResume,
  playFaster,
  playSlower,
  playRepeatSection,
  // Bantuan
  helpWhat,
  helpWhereAmI,
  // Cari Objek — target dinamis, tangkap terpisah dari intent
  findObjectTarget,
}

extension VoiceIntentX on VoiceIntent {
  bool get isModeChange => switch (this) {
        VoiceIntent.modeMoney ||
        VoiceIntent.modeReadText ||
        VoiceIntent.modeDetection ||
        VoiceIntent.modeNavigation ||
        VoiceIntent.modeAssistant ||
        VoiceIntent.modeFindObject ||
        VoiceIntent.modeSettings =>
          true,
        _ => false,
      };
}

/// Hasil parsing satu ucapan.
class VoiceCommand {
  final VoiceIntent? intent;
  final String rawText;
  /// Untuk `findObjectTarget` / `mode.findObject "cari [nama barang]"` —
  /// nama barang yang diekstrak dari ucapan.
  final String? argument;
  /// Dua tebakan terdekat saat tidak dikenali — bagian 14 "Tidak dikenali".
  final List<VoiceIntent> suggestions;

  const VoiceCommand({
    required this.rawText,
    this.intent,
    this.argument,
    this.suggestions = const [],
  });

  bool get recognized => intent != null;
}
```

---

## Berkas: `lib/main.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/index.dart';
import 'screens/index.dart';
import 'services/tts_service.dart';
import 'theme/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only — sesuai PRD
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Init TTS di awal
  await TTSService.instance.init();

  runApp(const GuidioApp());
}

class GuidioApp extends StatelessWidget {
  const GuidioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // SettingsProvider didaftarkan paling awal: ia sumber kebenaran untuk
        // alamat server, kecerewetan, dan ambang jarak — dan provider lain
        // membacanya lewat proxy di bawah.
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),

        // Providers tanpa dependency
        ChangeNotifierProvider(create: (_) => InferenceProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MoneyProvider()),
        ChangeNotifierProvider(create: (_) => FindObjectProvider()),
        ChangeNotifierProvider(create: (_) => GlobalConditionsProvider()..init()),
        ChangeNotifierProvider(create: (_) => CapabilitiesProvider()),

        // AppModeProvider ikut PG-05: kecerewetan mengubah panjang pengumuman
        // saat masuk mode.
        ChangeNotifierProxyProvider<SettingsProvider, AppModeProvider>(
          create: (_) => AppModeProvider(),
          update: (_, settings, prev) =>
              (prev ?? AppModeProvider())..applyVerbosity(settings.verbosity),
        ),

        // DetectionProvider — butuh InferenceProvider + CameraProvider, dan
        // ikut mendengarkan SettingsProvider supaya PG-05 (kecerewetan) dan
        // PG-06 (ambang jarak) benar-benar mengubah perilaku deteksi. Tanpa
        // sambungan ini keduanya hanya tersimpan ke disk.
        ChangeNotifierProxyProvider3<InferenceProvider, CameraProvider, SettingsProvider, DetectionProvider>(
          create: (ctx) => DetectionProvider(
            ctx.read<InferenceProvider>(),
            ctx.read<CameraProvider>(),
          ),
          update: (ctx, inf, cam, settings, prev) {
            final provider = prev ?? DetectionProvider(inf, cam);
            provider.applySettings(
              maxDistanceM: settings.distanceThresholdM,
              verbosity: settings.verbosity,
            );
            return provider;
          },
        ),

        // VoiceProvider — butuh CameraProvider + DetectionProvider +
        // AppModeProvider. AppModeProvider ikut disuntik supaya perintah suara
        // "buka mode X" memindah state SENDIRI, tanpa bergantung layar yang
        // sedang aktif memasang callback (bagian 4.1: konfirmasi TTS tidak
        // boleh mendahului perubahan state).
        ChangeNotifierProxyProvider3<CameraProvider, DetectionProvider, AppModeProvider, VoiceProvider>(
          create: (ctx) => VoiceProvider(
            ctx.read<CameraProvider>(),
            ctx.read<DetectionProvider>(),
            ctx.read<AppModeProvider>(),
          ),
          update: (ctx, cam, det, appMode, prev) =>
              prev ?? VoiceProvider(cam, det, appMode),
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          return MaterialApp(
            title: 'Guidio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: switch (settings.themeMode) {
              AppThemeMode.dark => AppTheme.dark,
              AppThemeMode.highContrast => AppTheme.highContrast,
              AppThemeMode.light => AppTheme.light,
            },
            themeMode: settings.themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
            builder: (context, child) {
              final scaler = TextScaler.linear(settings.fontScale);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaler),
                child: child!,
              );
            },
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
```

---

## Berkas: `lib/mock/mock_find_object.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/mock/mock_find_object.dart`

```dart
import 'dart:math';

/// Kosakata mock untuk Mode Cari Objek (bagian 12 IMPLEMENTASI.md).
///
/// Server pencarian objek sungguhan belum ada — seluruh "pengenalan barang"
/// di mode ini adalah tiruan lokal. [knownCatalog] berperan sebagai daftar
/// barang yang "dikenali" server tiruan (dipakai untuk memutuskan CO-12,
/// "objek tak dikenali"); [scanMessages]/[notFoundMessages] adalah kalimat
/// instruksi fisik yang berganti tiap ~2 detik selama pemindaian (CO-05/CO-10).
abstract final class FindObjectMockData {
  static const knownCatalog = <String>[
    'dompet', 'kunci', 'kunci motor', 'kunci rumah', 'ponsel', 'hp', 'handphone',
    'kacamata', 'botol minum', 'botol air', 'tas', 'tas ransel', 'remote',
    'remote tv', 'payung', 'sepatu', 'sandal', 'charger', 'kabel charger',
    'headset', 'earphone', 'buku', 'jaket', 'topi', 'gelas', 'obat', 'masker',
    'jam tangan', 'dompet uang', 'laptop', 'power bank',
  ];

  /// CO-05 — kalimat pemindaian awal, berganti tiap ~2 detik.
  static const scanMessages = <String>[
    'Memindai ruangan…',
    'Coba putar badan pelan ke kiri.',
    'Coba putar badan pelan ke kanan.',
    'Periksa area meja atau rak di dekatmu.',
  ];

  /// CO-10 — arahan lanjutan setelah beberapa putaran belum ketemu.
  static const notFoundMessages = <String>[
    'Belum terlihat, coba putar badan ke arah lain.',
    'Masih belum ketemu, coba melangkah beberapa langkah.',
    'Belum terlihat dari sini, coba tengok ke belakangmu.',
  ];

  /// CO-12 — barang tak dikenali menyebut barang yang dikenal sebagai ganti.
  static bool isKnown(String target) {
    final t = target.toLowerCase().trim();
    if (t.isEmpty) return false;
    return knownCatalog.any((k) => t.contains(k));
  }

  static String randomFallback(Random rng) => knownCatalog[rng.nextInt(knownCatalog.length)];
}
```

---

## Berkas: `lib/mock/ocr_mock_data.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/mock/ocr_mock_data.dart`

```dart
/// Data & katalog mock khusus Mode Baca Teks (OCR) — dipakai HANYA oleh
/// `ocr_screen.dart` dan `ocr_debug_sheet.dart` untuk mendemonstrasikan
/// 22 state BT-01..BT-22 (bagian 8 dokumen spesifikasi).
///
/// ServerService.readText saat ini hanya mengembalikan `{'text': ...}` —
/// tidak ada info bahasa, blok, atau status per-bagian. State yang butuh
/// info itu (dua bahasa, sebagian gagal, sangat panjang) TIDAK BISA dipicu
/// dari server sungguhan, jadi datanya dipalsukan di sini secara eksplisit.
library;

/// Satu blok hasil baca. Hasil server nyata selalu 1 blok tanpa [language]
/// dan `ok: true`. Blok dengan `ok: false` dipakai untuk mensimulasikan
/// BT-10 (sebagian gagal terbaca).
class OcrBlock {
  final String heading;
  final String text;
  final String? language;
  final bool ok;

  const OcrBlock({
    required this.heading,
    required this.text,
    this.language,
    this.ok = true,
  });
}

/// Satu entri katalog debug — dipakai OcrDebugSheet untuk daftar 22 state.
class OcrDebugEntry {
  final String id;
  final String title;
  final String hint;
  const OcrDebugEntry(this.id, this.title, this.hint);
}

/// Katalog lengkap 22 state, urut sesuai bagian 8 dokumen.
const List<OcrDebugEntry> ocrDebugCatalog = [
  OcrDebugEntry('BT-01', 'Idle', 'Tombol utama aktif, busur panduan'),
  OcrDebugEntry('BT-02', 'Idle offline', 'Tombol utama nonaktif + Baca judul saja'),
  OcrDebugEntry('BT-03', 'Menjepret', 'Kilat + getar + pill "Gambar diambil"'),
  OcrDebugEntry('BT-04', 'Memproses', 'Panel loading, tinggi dipesan penuh'),
  OcrDebugEntry('BT-05', 'Mendekati timeout', 'Banner + hitungan mono + Batalkan'),
  OcrDebugEntry('BT-06', 'Hasil pendek', 'Panel singkat tanpa progress'),
  OcrDebugEntry('BT-07', 'Hasil panjang', 'Blok berheading, gulung 280dp, progress'),
  OcrDebugEntry('BT-08', 'Hasil sangat panjang', 'Peringatan durasi, pilihan ringkasan/penuh'),
  OcrDebugEntry('BT-09', 'Dua bahasa', 'Pill bahasa per blok'),
  OcrDebugEntry('BT-10', 'Terbaca sebagian', 'Banner warning + jumlah blok gagal'),
  OcrDebugEntry('BT-11', 'Nol teks', 'Panel gagal + instruksi jarak'),
  OcrDebugEntry('BT-12a', 'Dijeda', 'Kalimat aktif ditandai, tombol jadi Lanjut'),
  OcrDebugEntry('BT-12b', 'Selesai dibacakan', 'Eyebrow Aman, disimpan 15 menit'),
  OcrDebugEntry('BT-13', 'Gagal offline', 'Panel warning, gambar masuk antrean'),
  OcrDebugEntry('BT-14', 'Gagal server', 'Banner critical, bukan karena gambarmu'),
  OcrDebugEntry('BT-15', 'Gagal timeout', 'Panel gagal, foto tetap tersimpan'),
  OcrDebugEntry('BT-16', 'Lanjut ke Asisten', 'Pindah mode dengan pill konteks'),
  OcrDebugEntry('BT-17', 'Izin kamera belum ada', 'PermissionCard'),
  OcrDebugEntry('BT-18', 'Font scale 200%', 'Panel vertikal, kontrol 56dp'),
  OcrDebugEntry('BT-19', 'Senyap / TTS mati', 'Teks penuh 18sp, kontrol jadi gulung'),
  OcrDebugEntry('BT-20', 'Hasil kedaluwarsa', 'Panel kosong + alasan + retry'),
  OcrDebugEntry('BT-21', 'Penyimpanan penuh', 'Banner warning, antrean offline mati'),
  OcrDebugEntry('BT-22', 'Camera health buram', 'Toast, tombol utama tetap aktif'),
];

String mockShortText() => 'Buka Senin–Sabtu, 08.00–17.00.';

List<OcrBlock> mockLongBlocks() => const [
      OcrBlock(
        heading: 'Bagian 1 — Judul menu',
        text: 'Daftar Menu Warung Bu Sari. Semua harga sudah termasuk nasi putih '
            'dan segelas air teh tawar.',
      ),
      OcrBlock(
        heading: 'Bagian 2 — Menu utama',
        text: 'Ayam goreng lima belas ribu rupiah. Ikan bakar dua puluh ribu rupiah. '
            'Tahu tempe penyet delapan ribu rupiah. Sayur asem lima ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 3 — Minuman',
        text: 'Es teh manis lima ribu rupiah. Es jeruk tujuh ribu rupiah. '
            'Kopi hitam enam ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 4 — Catatan',
        text: 'Buka Senin sampai Sabtu, jam delapan pagi sampai lima sore. '
            'Tutup setiap hari Minggu dan hari besar.',
      ),
    ];

List<OcrBlock> mockVeryLongBlocks() => [
      for (var i = 1; i <= 10; i++)
        OcrBlock(
          heading: 'Bagian $i',
          text: 'Ini adalah contoh paragraf panjang ke-$i yang dipakai untuk '
              'mensimulasikan dokumen dengan perkiraan waktu baca lebih dari '
              'sembilan puluh detik, misalnya brosur, surat resmi, atau '
              'lembar informasi obat dengan banyak baris teks berurutan.',
        ),
    ];

List<OcrBlock> mockBilingualBlocks() => const [
      OcrBlock(
        heading: 'Sambutan',
        language: 'Bahasa Indonesia',
        text: 'Selamat datang di Bandara Internasional. Silakan siapkan dokumen '
            'perjalanan Anda.',
      ),
      OcrBlock(
        heading: 'Greeting',
        language: 'English',
        text: 'Welcome to the International Airport. Please prepare your travel '
            'documents.',
      ),
    ];

List<OcrBlock> mockPartialBlocks() => const [
      OcrBlock(heading: 'Bagian 1', text: 'Jadwal keberangkatan pukul sembilan pagi.'),
      OcrBlock(heading: 'Bagian 2', text: '', ok: false),
      OcrBlock(heading: 'Bagian 3', text: 'Gerbang keberangkatan nomor lima.'),
      OcrBlock(heading: 'Bagian 4', text: '', ok: false),
    ];
```

---

## Berkas: `lib/models/detection.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/models/detection.dart`

```dart
class Detection {
  final String labelEn;
  final String labelId;
  final double confidence;
  final double distanceMeter;
  final String direction;      // "kiri" | "depan" | "kanan"
  final String dangerLevel;    // "critical" | "warning" | "info"
  final Map<String, int> bbox;
  final double inferenceMs;
  final bool isApproaching;    // true jika bbox makin besar (dari SORT tracker)

  const Detection({
    required this.labelEn,
    required this.labelId,
    required this.confidence,
    required this.distanceMeter,
    required this.direction,
    required this.dangerLevel,
    required this.bbox,
    required this.inferenceMs,
    this.isApproaching = false,
  });

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
        labelEn:       json['label_en'] as String? ?? '',
        labelId:       json['label_id'] as String? ?? '',
        confidence:    (json['confidence'] ?? 0).toDouble(),
        distanceMeter: (json['distance_meter'] ?? 999).toDouble(),
        direction:     json['direction'] as String? ?? 'depan',
        dangerLevel:   json['danger_level'] as String? ?? 'info',
        bbox:          Map<String, int>.from(json['bbox'] as Map? ?? {}),
        inferenceMs:   (json['inference_ms'] ?? 0).toDouble(),
        // isApproaching tidak dari JSON — hanya dari tracker lokal
      );

  /// Buat salinan Detection dengan field tertentu diubah.
  /// Digunakan DetectionProvider untuk menambahkan isApproaching dari tracker.
  Detection copyWith({bool? isApproaching}) => Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    confidence,
        distanceMeter: distanceMeter,
        direction:     direction,
        dangerLevel:   dangerLevel,
        bbox:          bbox,
        inferenceMs:   inferenceMs,
        isApproaching: isApproaching ?? this.isApproaching,
      );

  // Computed getters dari bbox pixel (format x1/y1/x2/y2).
  // Dibutuhkan ObjectTracker untuk IoU matching antar frame.
  double get bboxCx   => ((bbox['x1']! + bbox['x2']!) / 2).toDouble();
  double get bboxCy   => ((bbox['y1']! + bbox['y2']!) / 2).toDouble();
  double get bboxW    => (bbox['x2']! - bbox['x1']!).toDouble();
  double get bboxH    => (bbox['y2']! - bbox['y1']!).toDouble();
  double get bboxArea => bboxW * bboxH;

  /// Kalimat TTS singkat sesuai PRD UX
  String get ttsMessage {
    final dist = distanceMeter < 1.0
        ? 'kurang dari 1 meter'
        : '${distanceMeter.toStringAsFixed(0)} meter';
    switch (dangerLevel) {
      case 'critical':
        return 'Bahaya! Ada $labelId $dist di $direction';
      case 'warning':
        return 'Hati-hati, ada $labelId di $direction';
      default:
        return '$labelId di $direction';
    }
  }

  bool get isCritical => dangerLevel == 'critical';
  bool get isWarning  => dangerLevel == 'warning';
}
```

---

## Berkas: `lib/models/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/models/index.dart`

```dart
export 'detection.dart';
export 'risk_zone.dart';
```

---

## Berkas: `lib/models/risk_zone.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/models/risk_zone.dart`

```dart
class RiskZone {
  final double distanceMeter;
  final int count;
  final String commonLabel;
  final String warning;

  const RiskZone({
    required this.distanceMeter,
    required this.count,
    required this.commonLabel,
    required this.warning,
  });

  factory RiskZone.fromJson(Map<String, dynamic> json) => RiskZone(
        distanceMeter: (json['distance_meter'] ?? 0).toDouble(),
        count:         json['count'] as int? ?? 0,
        commonLabel:   json['common_label'] as String? ?? '',
        warning:       json['warning'] as String? ?? 'Area ini sering ada hambatan, hati-hati',
      );
}
```

---

## Berkas: `lib/providers/app_mode_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/app_mode_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/tts_service.dart';

/// Enam mode sejajar, sesuai kontrak navigasi Vinara: tidak ada beranda,
/// mode mana pun bisa dicapai dalam maksimal dua langkah (suara = 1 langkah,
/// ModePickerSheet = 2 langkah).
enum AppMode { tuntun, money, ocr, navigasi, voice, findObject }

extension AppModeLabel on AppMode {
  String get label => switch (this) {
        AppMode.tuntun     => 'Deteksi Objek',
        AppMode.money      => 'Kenali Uang',
        AppMode.ocr        => 'Baca Teks',
        AppMode.navigasi   => 'Navigasi',
        AppMode.voice      => 'Asisten Suara',
        AppMode.findObject => 'Cari Objek',
      };

  /// Satu kalimat "apa yang bisa dilakukan" — diumumkan saat masuk mode.
  String get shortIntro => switch (this) {
        AppMode.tuntun     => 'Arahkan ponsel ke depan, saya akan menyebut rintangan di jalurmu.',
        AppMode.money      => 'Letakkan uang di dalam bingkai, saya akan menyebut nominalnya.',
        AppMode.ocr        => 'Arahkan ponsel ke tulisan, lalu ambil gambar.',
        AppMode.navigasi   => 'Sebutkan atau ketik tujuanmu, saya akan menuntun jalan.',
        AppMode.voice      => 'Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu.',
        AppMode.findObject => 'Sebutkan barang yang kamu cari, saya akan membantu menemukannya.',
      };

  String get icon => switch (this) {
        AppMode.tuntun     => '👁',
        AppMode.money      => '💵',
        AppMode.ocr        => '📄',
        AppMode.navigasi   => '🧭',
        AppMode.voice      => '🎙️',
        AppMode.findObject => '🔍',
      };

  /// Butuh internet untuk berfungsi penuh. Dipakai ModePickerSheet untuk
  /// menandai state `limited` / `disabled` saat offline.
  bool get needsServer => switch (this) {
        AppMode.tuntun     => false, // sepenuhnya on-device
        AppMode.money      => false, // model nominal on-device
        AppMode.ocr        => false, // ML Kit on-device — jalan penuh offline
        AppMode.navigasi   => true,  // segmentasi jalur + rintangan, keduanya di server
        AppMode.voice      => true,  // LLM, ada fallback lokal
        AppMode.findObject => true,  // butuh server sepenuhnya
      };

  /// Mode yang benar-benar mati tanpa internet.
  ///
  /// **Berubah dari desain awal.** Dokumen menetapkan Navigasi tidak pernah
  /// dinonaktifkan offline karena deteksi rintangan on-device tetap hidup
  /// (§2 dan §4.4 ALUR-DAN-TOMBOL.md). Sejak deteksi rintangan dan segmentasi
  /// jalur dipindah sepenuhnya ke server, alasan itu tidak berlaku lagi:
  /// offline berarti Navigasi benar-benar tidak bisa melihat apa pun, dan
  /// membiarkannya "terbatas" akan menjanjikan keselamatan yang tidak ada.
  ///
  /// Kalau deteksi rintangan on-device dikembalikan, kembalikan juga Navigasi
  /// ke state `limited` — itu satu baris di sini.
  bool get disabledWhenOffline =>
      this == AppMode.findObject || this == AppMode.navigasi;
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  /// Verbositas panduan menurun setelah 3 kali pemakaian pertama per mode.
  final Map<AppMode, int> _visitCount = {};
  int visitCountFor(AppMode m) => _visitCount[m] ?? 0;

  /// Kata pembuka yang dititipkan [setMode] untuk diucapkan oleh
  /// [announceEntry] milik layar tujuan — mis. "Baik." dari perintah suara
  /// (AS-17). Dititipkan, bukan diucapkan di sini, supaya konfirmasi tidak
  /// pernah mendahului perpindahan state (bagian 4.1 ALUR-DAN-TOMBOL.md).
  String? _pendingPrefix;

  /// PG-05 — tingkat kecerewetan pengguna. Bekerja **bersama** verbositas
  /// menurun bawaan (tiga pemakaian pertama lebih panjang), bukan
  /// menggantikannya: "ringkas" memotong panduan sejak awal, "detail"
  /// mempertahankannya selamanya.
  Verbosity _verbosity = Verbosity.sedang;
  void applyVerbosity(Verbosity v) => _verbosity = v;

  /// Umumkan masuk mode. Dipanggil dari `initState` layar mode — artinya
  /// pengumuman selalu menyusul mode yang BENAR-BENAR terpasang, tidak pernah
  /// mendahuluinya. Mode default (Deteksi Objek) yang aktif sejak boot tanpa
  /// lewat [setMode] ikut lewat sini juga, supaya DO-29 "verbositas lengkap 3
  /// pemakaian pertama" tetap berlaku untuknya.
  Future<void> announceEntry(AppMode mode) async {
    if (mode != _mode) return; // layar basi (dispose berpapasan) — jangan bicara
    final prefix = _pendingPrefix;
    _pendingPrefix = null;

    final count = (_visitCount[mode] ?? 0) + 1;
    _visitCount[mode] = count;

    // Verbositas menurun bawaan (tiga kali pertama lengkap) digeser oleh
    // pilihan pengguna: "ringkas" tidak pernah membacakan panduan, "detail"
    // selalu membacakannya.
    final withIntro = switch (_verbosity) {
      Verbosity.ringkas => false,
      Verbosity.sedang => count <= 3,
      Verbosity.detail => true,
    };

    final announcement = [
      if (prefix != null) prefix,
      '${mode.label} aktif.',
      if (withIntro) mode.shortIntro,
    ].join(' ');
    await TTSService.instance.speak(announcement);
  }

  /// NV-18 — satu-satunya konfirmasi wajib di seluruh app: keluar dari Mode
  /// Navigasi saat pengguna terdeteksi sedang berjalan. `navigasi_screen.dart`
  /// memasang hook ini selama aktif; kalau terpasang dan mengembalikan
  /// false, perpindahan mode dibatalkan. Ini titik tunggal yang dilewati
  /// SEMUA jalur ganti mode (ModePickerSheet maupun perintah suara).
  Future<bool> Function(AppMode from, AppMode to)? confirmLeave;

  /// Berpindah mode. Mengembalikan **true hanya kalau mode benar-benar
  /// berubah** — pemanggil wajib memeriksa nilai ini sebelum mengucapkan
  /// konfirmasi apa pun. [spokenPrefix] dititipkan ke pengumuman kedatangan
  /// layar tujuan, bukan diucapkan di sini.
  Future<bool> setMode(AppMode mode, {String? spokenPrefix}) async {
    if (_mode == mode) return false;
    if (confirmLeave != null) {
      final ok = await confirmLeave!(_mode, mode);
      if (!ok) return false;
    }
    _pendingPrefix = spokenPrefix;
    _mode = mode;
    notifyListeners();
    // Pengumuman kedatangan diucapkan `announceEntry` dari layar tujuan —
    // sesudah layarnya benar-benar terpasang.
    return true;
  }
}
```

---

## Berkas: `lib/providers/camera_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/camera_provider.dart`

```dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_health_service.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';

/// CameraProvider — kelola kamera, stream, dan capture.
///
/// Fix dari doc 5 masalah 8 + 12:
/// - Mutex _capturing untuk race condition
/// - On-device brightness check (plane Y) setiap frame
/// - YUV420 → JPEG konversi yang benar via package 'image'
class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _initialized = false;
  bool _streaming   = false;
  bool _capturing   = false; // mutex race condition fix
  int  _frameCount  = 0;

  String? _healthMessage; // pesan camera health untuk UI

  CameraController? get controller     => _controller;
  bool              get isInitialized  => _initialized;
  bool              get isStreaming     => _streaming;
  String?           get healthMessage  => _healthMessage;

  // Callback — dipanggil dari CameraProvider ketika frame siap
  // DetectionProvider/InferenceProvider yang subscribe
  Function(CameraImage)? onFrameReady;

  Future<void> initCamera() async {
    // Request camera permission sebelum initialize — mencegah CameraAccessDenied
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('[CameraProvider] Camera permission denied: $status');
      _initialized = false;
      notifyListeners();
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium, // 640x480 cukup untuk YOLO
      enableAudio:    false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    CameraHealthService.instance.startListening();
    _initialized = true;
    notifyListeners();
  }

  void startStream() {
    if (!_initialized || _streaming || _controller == null) return;
    _streaming   = true;
    _frameCount  = 0;

    _controller!.startImageStream((CameraImage image) {
      // Skip frame jika sedang capture (race condition fix)
      if (_capturing) return;

      _frameCount++;

      // [1] On-device brightness check setiap frame — O(100) sangat ringan
      if (_isTooDark(image)) {
        if (_healthMessage != 'Kamera terlalu gelap') {
          _healthMessage = 'Kamera terlalu gelap';
          notifyListeners();
          TTSService.instance.speak('Kamera terlalu gelap');
        }
        return;
      }

      // [2] Cek orientasi dari accelerometer setiap 30 frame
      if (_frameCount % 30 == 0) {
        // Kirim tilt ke TFLiteService untuk koreksi estimasi jarak
        TFLiteService.instance.updateTilt(
          CameraHealthService.instance.lastTiltAngle,
        );
        final health = CameraHealthService.instance.checkOrientation();
        if (!health.ok) {
          if (_healthMessage != health.message) {
            _healthMessage = health.message;
            notifyListeners();
            TTSService.instance.speak(health.message);
          }
          return;
        } else if (_healthMessage != null) {
          _healthMessage = null;
          notifyListeners();
        }
      }

      // [3] Callback ke DetectionProvider jika ada subscriber
      onFrameReady?.call(image);
    });
  }

  void stopStream() {
    if (!_streaming || _controller == null) return;
    _controller!.stopImageStream();
    _streaming = false;
  }

  /// Ambil foto dan kembalikan **path berkas**, bukan byte-nya.
  ///
  /// Dipakai OCR ML Kit, yang membaca langsung dari berkas. Untuk foto 4 MP,
  /// tidak membaca byte ke memori Dart menghemat satu salinan besar yang
  /// tidak pernah dipakai untuk apa pun.
  Future<String> captureFile() async {
    if (_capturing) throw Exception('Sedang capture, coba lagi');
    if (!_initialized || _controller == null) {
      throw Exception('Kamera belum siap');
    }

    _capturing = true;
    try {
      final wasStreaming = _streaming;
      if (wasStreaming) stopStream();

      final xfile = await _controller!.takePicture();

      if (wasStreaming) {
        await Future.delayed(const Duration(milliseconds: 200));
        startStream();
      }
      return xfile.path;
    } finally {
      _capturing = false;
    }
  }

  /// Capture JPEG untuk OCR / Voice Assistant.
  /// Mutex: jika sedang capture, lempar exception (jangan double-capture).
  ///
  /// Fix dari doc 5 masalah 8.
  Future<Uint8List> captureJpeg() async {
    if (_capturing) throw Exception('Sedang capture, coba lagi');
    if (!_initialized || _controller == null) {
      throw Exception('Kamera belum siap');
    }

    _capturing = true;
    try {
      final wasStreaming = _streaming;
      if (wasStreaming) stopStream();

      final xfile = await _controller!.takePicture();
      final bytes = await xfile.readAsBytes();

      if (wasStreaming) {
        // Beri kamera sedikit waktu untuk settle sebelum restart stream
        await Future.delayed(const Duration(milliseconds: 200));
        startStream();
      }

      return bytes;
    } finally {
      _capturing = false;
    }
  }

  /// Konversi CameraImage YUV420 → JPEG untuk dikirim ke server.
  ///
  /// Fix dari doc 5 masalah 1: implementasi penuh, bukan hanya plane Y.
  Future<Uint8List> toJpeg(CameraImage cameraImage) async {
    final int width  = cameraImage.width;
    final int height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBytes      = yPlane.bytes;
    final uBytes      = uPlane.bytes;
    final vBytes      = vPlane.bytes;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStr  = uPlane.bytesPerPixel ?? 1;

    final rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIdx  = y * yPlane.bytesPerRow + x;
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStr;

        final yVal = yBytes[yIdx] & 0xFF;
        final uVal = (uBytes.length > uvIdx ? uBytes[uvIdx] : 128) & 0xFF;
        final vVal = (vBytes.length > uvIdx ? vBytes[uvIdx] : 128) & 0xFF;

        final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        final g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
        final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    // Encode ke JPEG quality 70 — cukup untuk YOLO server, tidak terlalu besar
    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 70));
  }

  /// On-device brightness check — sample 100 piksel dari plane Y (YUV420).
  /// O(100) sangat ringan, aman dipanggil setiap frame.
  ///
  /// Fix dari doc 5 masalah 12.
  bool _isTooDark(CameraImage image) {
    final yPlane = image.planes[0].bytes;
    final step   = yPlane.length ~/ 100;
    if (step <= 0) return false;

    int total = 0;
    for (int i = 0; i < yPlane.length; i += step) {
      total += yPlane[i] & 0xFF;
    }
    final avgBrightness = total / 100;
    return avgBrightness < 30; // < 30/255 = sangat gelap
  }

  @override
  void dispose() {
    CameraHealthService.instance.stopListening();
    _controller?.dispose();
    super.dispose();
  }
}
```

---

## Berkas: `lib/providers/capabilities_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/capabilities_provider.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/server_service.dart';
import 'app_mode_provider.dart';

/// Kemampuan server per mode — `GET /api/capabilities`.
///
/// **Ditanyakan sebelum pengguna menekan apa pun.** Tanpa ini, satu-satunya
/// cara mengetahui sebuah mode sedang mati adalah masuk ke sana lalu gagal —
/// dan untuk pengguna yang tidak melihat layar, "masuk lalu gagal" berarti
/// beberapa detik kebingungan di tempat yang salah. Item sheet karena itu
/// sudah menyebut alasannya sejak sebelum ditekan (bagian 16: "Item nonaktif
/// menyebut alasannya sebagai bagian nilai").
///
/// Offline dan server-mati sengaja dibedakan. Keduanya menghasilkan item yang
/// tidak bisa dipakai, tapi alasannya beda dan tindakan pengguna berikutnya
/// juga beda: menyalakan data seluler, atau menunggu.
enum CapState { up, limited, down }

class ModeCapability {
  final CapState state;
  final String note;
  const ModeCapability(this.state, this.note);
}

class CapabilitiesProvider extends ChangeNotifier {
  /// null = belum pernah berhasil bertanya.
  Map<String, ModeCapability>? _modes;
  DateTime? _fetchedAt;
  bool _fetching = false;

  bool get isKnown => _modes != null;

  /// Hasil cukup lama dianggap basi. Server bisa mati kapan saja, tapi
  /// bertanya tiap kali sheet dibuka akan menambah jeda sebelum sheet tampil.
  static const _staleAfter = Duration(seconds: 45);

  bool get _isStale =>
      _fetchedAt == null || DateTime.now().difference(_fetchedAt!) > _staleAfter;

  ModeCapability? _capOf(AppMode mode) => _modes?[_key(mode)];

  /// State efektif mode ini sekarang, menggabungkan jaringan dan server.
  CapState stateOf(AppMode mode, {required bool offline}) {
    if (!mode.needsServer) return CapState.up;
    if (offline) {
      return mode.disabledWhenOffline ? CapState.down : CapState.limited;
    }
    // Belum tahu — jangan menghalangi. Menebak "mati" akan mengunci pengguna
    // dari mode yang sebenarnya sehat hanya karena satu permintaan lambat.
    return _capOf(mode)?.state ?? CapState.up;
  }

  bool isAvailable(AppMode mode, {required bool offline}) =>
      stateOf(mode, offline: offline) != CapState.down;

  /// Alasan yang dibacakan **sebagai bagian nilai item**, bukan sebagai teks
  /// terpisah yang bisa terlewat saat swipe TalkBack (bagian 16).
  String? unavailableReason(AppMode mode, {required bool offline}) {
    if (!mode.needsServer) return null;

    if (offline) {
      return mode.disabledWhenOffline
          ? 'Tidak tersedia, butuh internet'
          : 'Tanpa internet: sebagian fitur mati';
    }

    final cap = _capOf(mode);
    return switch (cap?.state) {
      CapState.down => 'Tidak tersedia, ${_lowerFirst(cap!.note)}',
      CapState.limited => cap!.note,
      _ => null,
    };
  }

  String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// Menyegarkan kalau sudah basi. Aman dipanggil tiap kali sheet dibuka:
  /// panggilan berturut-turut dalam rentang segar tidak menyentuh jaringan.
  Future<void> refreshIfStale({required bool offline}) async {
    if (offline || _fetching || !_isStale) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final res = await ServerService.instance.capabilities();
      if (res == null) {
        // Server tidak menjawab — seluruh mode yang butuh server dianggap mati.
        _modes = {
          for (final m in AppMode.values)
            if (m.needsServer)
              _key(m): const ModeCapability(CapState.down, 'server tidak menjawab'),
        };
      } else {
        _modes = _parse(res);
      }
      _fetchedAt = DateTime.now();
      notifyListeners();
    } finally {
      _fetching = false;
    }
  }

  Map<String, ModeCapability> _parse(Map<String, dynamic> res) {
    final raw = res['capabilities'];
    final out = <String, ModeCapability>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is! Map) return;
        final state = switch (value['state']) {
          'up' => CapState.up,
          'limited' => CapState.limited,
          'down' => CapState.down,
          _ => CapState.up,
        };
        out['$key'] = ModeCapability(state, value['note'] as String? ?? '');
      });
    }
    return out;
  }

  /// Nama mode versi backend. Dipisah eksplisit supaya penggantian nama di
  /// satu sisi tidak diam-diam membuat semua mode terlihat sehat.
  String _key(AppMode mode) => switch (mode) {
        AppMode.tuntun => 'detection',
        AppMode.money => 'money',
        AppMode.ocr => 'read_text',
        AppMode.navigasi => 'navigation',
        AppMode.voice => 'assistant',
        AppMode.findObject => 'find_object',
      };
}
```

---

## Berkas: `lib/providers/detection_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/detection_provider.dart`

```dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';
import '../providers/inference_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/detection_filter.dart';
import '../services/haptic_service.dart';
import '../services/object_tracker.dart';
import '../services/server_service.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';

class DetectionProvider extends ChangeNotifier {
  final InferenceProvider _inferenceProvider;
  final CameraProvider    _cameraProvider;

  DetectionProvider(this._inferenceProvider, this._cameraProvider);

  final _filter  = DetectionFilter();

  /// PG-05 / PG-06 — diteruskan dari SettingsProvider setiap kali pengaturan
  /// berubah, supaya slider dan segmented benar-benar mengubah perilaku
  /// deteksi alih-alih hanya tersimpan ke disk.
  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _filter.applySettings(maxDistanceM: maxDistanceM, verbosity: verbosity);
  }
  final _tracker = ObjectTracker(); // SORT tracker untuk isApproaching
  StreamSubscription? _serverSub;
  bool _realtimeActive = false;

  List<Detection> _detections = [];
  RiskZone?       _riskZone;

  List<Detection> get detections => _detections;
  RiskZone?       get riskZone   => _riskZone;

  // ── Real-time Mode (Tuntun + Navigasi) ────────────────────────────────────

  void startRealtime() {
    if (_realtimeActive) return;
    _realtimeActive = true;
    _filter.reset();

    if (_inferenceProvider.realtimeEngine == InferenceEngine.tflite) {
      // TFLite path: pasang callback ke CameraProvider
      _cameraProvider.onFrameReady = _processFrameTflite;
    } else {
      // Server path: subscribe ke WebSocket stream
      _serverSub = ServerService.instance.detectionStream.listen(
        _handleServerResult,
      );
      // Pasang callback ke CameraProvider untuk kirim frame ke server
      _cameraProvider.onFrameReady = _processFrameServer;
    }
  }

  void stopRealtime() {
    _realtimeActive = false;
    _cameraProvider.onFrameReady = null;
    _serverSub?.cancel();
    _serverSub = null;
    _tracker.reset(); // bersihkan semua track saat mode berganti
    _detections = [];
    _riskZone   = null;
    notifyListeners();
  }

  /// TFLite path — inference langsung di isolate
  Future<void> _processFrameTflite(CameraImage image) async {
    if (!_realtimeActive) return;
    final raw = await TFLiteService.instance.runInference(image);

    // Jika frame tidak menghasilkan deteksi apapun, skip filter sepenuhnya.
    // PENTING: jangan panggil _filter.process([]) — currentLabels akan kosong
    // dan semua streak akan di-reset, termasuk objek yang masih terdeteksi
    // di frame berikutnya. Ini penyebab streak selalu stuck di 1/2.
    if (raw.isEmpty) return;

    // Debug: log hasil raw inference
    debugPrint(
      '[Detection] raw (${raw.length}): '
      '${raw.map((d) => '${d.labelEn} '
        '${d.distanceMeter.toStringAsFixed(1)}m '
        '(${d.dangerLevel})').join(' | ')}',
    );

    // Update SORT tracker — dapat TrackedObject dengan info isApproaching
    final tracked = _tracker.update(raw);

    // Enrich setiap Detection dengan isApproaching dari tracker-nya
    final enriched = raw.map((det) {
      final t = tracked.firstWhere(
        (t) => t.label == det.labelEn,
        orElse: () => TrackedObject(
          id: -1, label: '', cx: 0, cy: 0, w: 0, h: 0,
        ),
      );
      return det.copyWith(isApproaching: t.isApproaching);
    }).toList();

    final filtered = _filter.process(enriched);

    // Debug: log apa yang akhirnya lolos ke TTS
    if (filtered.isNotEmpty) {
      debugPrint(
        '[Detection] lolos filter (${filtered.length}): '
        '${filtered.map((d) => '${d.labelEn}(${d.dangerLevel})').join(' | ')}',
      );
    }

    _updateAndSpeak(filtered);
  }

  /// Server path — encode JPEG dan kirim ke WebSocket
  Future<void> _processFrameServer(CameraImage image) async {
    if (!_realtimeActive) return;
    try {
      final jpeg = await _cameraProvider.toJpeg(image);
      ServerService.instance.sendFrame(jpeg);
    } catch (_) {}
  }

  void _handleServerResult(ServerDetectionResult result) {
    if (!_realtimeActive) return;
    final filtered = _filter.process(result.detections);
    _riskZone = result.riskZone;
    _updateAndSpeak(filtered);
  }

  void _updateAndSpeak(List<Detection> filtered) {
    _detections = filtered;
    notifyListeners();

    for (final det in filtered) {
      TTSService.instance.speak(
        det.ttsMessage,
        interrupt: det.isCritical, // critical selalu interrupt TTS lain
      );
      // Haptic berdampingan TTS — primary signal di lingkungan bising
      HapticService.instance.fromDangerLevel(det.dangerLevel);
    }
  }

  // ── Single-shot untuk Voice Assistant ─────────────────────────────────────

  /// Detect sekali dari JPEG — tanpa stability filter (langsung hasilkan raw)
  Future<List<Detection>> detectOnce(Uint8List jpegBytes) async {
    return ServerService.instance.detectOnce(jpegBytes);
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}
```

---

## Berkas: `lib/providers/find_object_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/find_object_provider.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/server_service.dart';

/// State machine Mode Cari Objek — bagian 12 IMPLEMENTASI.md (CO-01..CO-13,
/// CO-18, CO-19).
///
/// **Sepenuhnya di server.** Frame dikirim ke `POST /api/cari-objek` yang
/// menjalankan YOLOE dengan prompt terbuka; tidak ada model pencarian di
/// perangkat. Konsekuensinya CO-14 nyata: tanpa internet, mode ini benar-benar
/// tidak bisa apa-apa, dan targetnya disimpan untuk dicoba lagi nanti.
///
/// CO-15 (izin kamera), CO-16 (senyap), CO-17 (font scale 200%) sengaja TIDAK
/// dimodelkan di sini — itu murni keputusan lapisan UI, sama seperti pola
/// MoneyProvider.
enum FindObjectState {
  idle, // CO-01
  listening, // CO-02
  unclear, // CO-03
  targetActive, // CO-04
  scanning, // CO-05
  found, // CO-06 / CO-07 (lihat matchCount)
  lostFromView, // CO-09
  notFoundInFrame, // CO-10
  longNotFound, // CO-11
  unknownObject, // CO-12
  offlineSaved, // CO-14
  serverError, // CO-18
  tooDark, // CO-19
}

class FindObjectProvider extends ChangeNotifier {
  FindObjectState _state = FindObjectState.idle;
  FindObjectState get state => _state;

  String? _target;
  String? get target => _target;

  /// CO-14 — target yang disimpan saat offline, dipakai lagi begitu pulih.
  String? _savedTarget;
  String? get savedTarget => _savedTarget;

  int _matchCount = 1; // CO-07: >1 berarti "lebih dari satu cocok"
  int get matchCount => _matchCount;

  String _direction = 'depan';
  String get direction => _direction;

  double _distanceMeter = 3.0;
  double get distanceMeter => _distanceMeter;

  String? _lastKnownPosition; // CO-09
  String? get lastKnownPosition => _lastKnownPosition;

  /// Pesan terakhir dari server. Server yang menyusun kalimatnya supaya
  /// perbaikan naskah tidak perlu rilis ulang aplikasi.
  String _serverMessage = '';
  String get scanMessage =>
      _serverMessage.isEmpty ? 'Memindai sekitar…' : _serverMessage;
  String get notFoundMessage => scanMessage;

  /// Daftar barang yang dikenali server — CO-12 memakainya untuk menawarkan
  /// barang lain, bukan menebak dari daftar hardcoded di aplikasi.
  List<String> _knownTargets = const [];
  List<String> get knownTargets => _knownTargets;

  /// Callback keluar — screen yang mengubahnya jadi suara/getar sungguhan.
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(String direction)? onDirectionHaptic; // CO-16

  /// Sumber frame. Screen memasang ini supaya provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;

  /// Dibaca sebelum mengirim — CO-14 menuntut mode ini benar-benar berhenti
  /// saat offline, bukan mencoba lalu gagal berkali-kali.
  bool Function()? isOffline;

  /// Satu permintaan in-flight, frame lama dibuang. Untuk pencarian yang
  /// pengguna lakukan sambil memutar badan, jawaban untuk frame tiga detik
  /// lalu menunjuk ke arah yang sudah salah.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 600));

  Timer? _loopTimer;
  Timer? _stepTimer;
  int _consecutiveNotFound = 0;
  int _consecutiveErrors = 0;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) =>
      onSpeak?.call(text, tier);

  void _set(FindObjectState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  /// Ambil kamus target dari server sekali saat masuk mode. Gagal diam-diam:
  /// tanpa kamus, CO-12 hanya kehilangan saran, bukan seluruh fiturnya.
  Future<void> loadKnownTargets() async {
    try {
      _knownTargets = await ServerService.instance.cariObjekTargets();
      notifyListeners();
    } catch (_) {
      // Diabaikan dengan sengaja.
    }
  }

  // -------------------------------------------------------------- CO-02/03

  void startListening() {
    _stopLoop();
    _set(FindObjectState.listening);
  }

  /// Dipanggil screen setelah STT selesai. [heardText] kosong/ambigu → CO-03.
  void submitHeardText(String heardText, {String? parsedTarget}) {
    final t = (parsedTarget ?? heardText).trim();
    if (t.isEmpty) {
      _set(FindObjectState.unclear);
      _speak('Cari apa?', tier: SpeechTier.info);
      _after(2500, () => _set(FindObjectState.idle));
      return;
    }
    setTarget(t);
  }

  // ------------------------------------------------------------------ CO-04

  /// Menetapkan target baru — juga dipakai CO-13 "ganti target" saat target
  /// sudah aktif (tidak perlu kembali ke CO-01 dulu).
  void setTarget(String newTarget) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _matchCount = 1;
    _lastKnownPosition = null;
    _consecutiveNotFound = 0;
    _consecutiveErrors = 0;
    _set(FindObjectState.targetActive);

    // CO-14 — offline: target DISIMPAN, mode berhenti. Perintahnya diterima,
    // yang hilang disebut, dan tidak pernah dikatakan "perintah gagal".
    if (isOffline?.call() ?? false) {
      _savedTarget = newTarget;
      _set(FindObjectState.offlineSaved);
      _speak(
        'Cari objek butuh internet. Target $newTarget saya simpan, '
        'saya coba lagi begitu internet kembali.',
        tier: SpeechTier.warning,
      );
      return;
    }

    _speak(
      isChange ? 'Ganti, sekarang mencari $newTarget.' : 'Mencari $newTarget.',
      tier: SpeechTier.info,
    );
    _after(400, _beginScan);
  }

  /// Dipanggil screen saat koneksi pulih — CO-14 menjanjikan percobaan ulang,
  /// jadi janji itu harus benar-benar ditepati.
  void retrySavedTarget() {
    final saved = _savedTarget;
    if (saved == null) return;
    _savedTarget = null;
    _speak('Internet kembali. Melanjutkan mencari $saved.', tier: SpeechTier.info);
    setTarget(saved);
  }

  // -------------------------------------------------------------- CO-05..11

  void _beginScan() {
    if (_target == null) return;
    _set(FindObjectState.scanning);
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    // Laju pemindaian dipilih dari kecepatan orang memutar badan, bukan dari
    // kemampuan kamera: ~3 frame per detik sudah cukup rapat untuk mengikuti
    // putaran badan, dan tidak membanjiri server.
    _loopTimer = Timer.periodic(const Duration(milliseconds: 350), (_) => _tick());
    _tick();
  }

  void _stopLoop() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _stepTimer?.cancel();
    _pacer.reset();
  }

  Future<void> _tick() async {
    final target = _target;
    final grab = frameSource;
    if (target == null || grab == null) return;

    // Frame yang datang saat masih ada permintaan berjalan dibuang di sini,
    // bukan diantre. Lihat FramePacer.
    await _pacer.run(() async {
      final jpeg = await grab();
      if (jpeg == null || _target != target) return;

      try {
        final res = await ServerService.instance.cariObjek(target, jpeg);
        if (_target != target) return; // target sudah diganti saat menunggu
        _consecutiveErrors = 0;
        _handleResponse(res, target);
      } on ApiStatusException {
        // Server hidup tapi menolak — CO-18, bukan salah kameranya.
        _handleFailure(
          'Bukan karena kameramu. Coba lagi sebentar lagi.',
          FindObjectState.serverError,
        );
      } on ApiUnreachableException {
        _handleFailure(
          'Server tidak bisa dihubungi. Cari objek berhenti sampai sambungan kembali.',
          FindObjectState.serverError,
        );
      }
    });
  }

  void _handleResponse(Map<String, dynamic> res, String target) {
    _serverMessage = res['message'] as String? ?? '';
    final found = res['found'] == true;

    if (!found) {
      final reason = res['reason'] as String? ?? 'not_in_frame';

      if (reason == 'model_unavailable') {
        _handleFailure(_serverMessage, FindObjectState.serverError);
        return;
      }
      if (reason == 'invalid_frame') {
        // CO-19 — frame tidak terbaca; paling sering karena terlalu gelap.
        _set(FindObjectState.tooDark);
        _speak('Terlalu gelap. Nyalakan lampu.', tier: SpeechTier.warning);
        return;
      }

      _consecutiveNotFound++;
      // CO-10 lalu CO-11 — sesudah cukup lama tidak ketemu, berhenti menyuruh
      // memutar badan dan tawarkan jalan keluar. Mengulang instruksi yang sama
      // tanpa batas adalah bentuk jalan buntu.
      if (_consecutiveNotFound >= 18) {
        _stopLoop();
        _set(FindObjectState.longNotFound);
        _speak(
          'Belum ketemu di ruangan ini. Pindah ruangan, atau sebutkan barang lain?',
          tier: SpeechTier.warning,
        );
        return;
      }

      if (_state != FindObjectState.notFoundInFrame) {
        _set(FindObjectState.notFoundInFrame);
      } else {
        notifyListeners(); // pesan berputar dari server
      }
      // Instruksi diucapkan berkala, bukan tiap frame — kalau tidak, TTS
      // akan bicara terus-menerus dan menutupi suara lingkungan.
      if (_consecutiveNotFound % 6 == 1) {
        _speak(scanMessage, tier: SpeechTier.info);
      }
      return;
    }

    // ── Ketemu ───────────────────────────────────────────────────────────
    final nearest = res['nearest'] as Map<String, dynamic>?;
    final total = (res['total_match'] as num?)?.toInt() ?? 1;
    final wasLost = _state == FindObjectState.notFoundInFrame ||
        _state == FindObjectState.lostFromView;

    _consecutiveNotFound = 0;
    _matchCount = total;
    if (nearest != null) {
      _direction = nearest['direction'] as String? ?? _direction;
      _distanceMeter =
          (nearest['distance_meter'] as num?)?.toDouble() ?? _distanceMeter;
    }
    _lastKnownPosition = '$_direction, sekitar ${_distanceMeter.toStringAsFixed(1)} meter';

    final previous = _state;
    _set(FindObjectState.found);

    // CO-06/07/08 — umumkan saat pertama ketemu, saat ketemu lagi setelah
    // hilang, atau saat jaraknya berubah cukup jauh untuk berarti. Tanpa
    // aturan ini, jarak yang berubah tiap frame jadi banjir suara.
    final shouldAnnounce = previous != FindObjectState.found ||
        wasLost ||
        _crossedDistanceStep();
    if (shouldAnnounce) {
      _speak(_serverMessage.isNotEmpty ? _serverMessage : _composeFound(),
          tier: SpeechTier.info);
      onDirectionHaptic?.call(_direction);
    }
    _lastAnnouncedDistance = _distanceMeter;
  }

  double _lastAnnouncedDistance = -1;

  /// CO-08 — panduan bertahap. Diumumkan saat melewati ambang yang berarti
  /// ("dua meter" → "satu meter" → "setengah meter, ulurkan tangan"), bukan
  /// tiap kali angkanya bergeser sedikit.
  bool _crossedDistanceStep() {
    if (_lastAnnouncedDistance < 0) return true;
    const steps = [0.6, 1.0, 2.0, 3.0];
    for (final s in steps) {
      if (_lastAnnouncedDistance > s && _distanceMeter <= s) return true;
    }
    return false;
  }

  String _composeFound() {
    final distText = _distanceMeter < 1
        ? 'kurang dari satu meter'
        : '${_distanceMeter.toStringAsFixed(1)} meter';
    return _matchCount > 1
        ? 'Ada $_matchCount $_target. Yang terdekat di $_direction, sekitar $distText.'
        : '$_target ditemukan di $_direction, sekitar $distText.';
  }

  void _handleFailure(String message, FindObjectState state) {
    _consecutiveErrors++;
    _set(state);
    // Diucapkan sekali per rentetan kegagalan, bukan tiap frame.
    if (_consecutiveErrors == 1) {
      _speak(message, tier: SpeechTier.critical);
    }
    // Sesudah beberapa kegagalan berturut-turut, berhenti membebani server
    // dan baterai. Pengguna diberi tahu, bukan dibiarkan menunggu diam-diam.
    if (_consecutiveErrors >= 5) {
      _stopLoop();
      _speak(
        'Pencarian dihentikan. Ucapkan nama barangnya lagi untuk mencoba ulang.',
        tier: SpeechTier.warning,
      );
      _consecutiveErrors = 0;
    }
  }

  void reset() {
    _stopLoop();
    _target = null;
    _serverMessage = '';
    _consecutiveNotFound = 0;
    _consecutiveErrors = 0;
    _lastAnnouncedDistance = -1;
    _set(FindObjectState.idle);
  }

  @override
  void dispose() {
    _stopLoop();
    super.dispose();
  }
}
```

---

## Berkas: `lib/providers/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/index.dart`

```dart
export 'app_mode_provider.dart';
export 'inference_provider.dart';
export 'camera_provider.dart';
export 'detection_provider.dart';
export 'tts_provider.dart';
export 'navigation_provider.dart';
export 'voice_provider.dart';
export 'settings_provider.dart';
export 'money_provider.dart';
export 'find_object_provider.dart';
export 'capabilities_provider.dart';
export '../core/state/global_conditions.dart';
```

---

## Berkas: `lib/providers/inference_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/inference_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../services/tflite_service.dart';
import '../services/server_service.dart';

enum InferenceEngine { tflite, server }

class InferenceProvider extends ChangeNotifier {
  bool _tfliteReady = false;
  bool _serverReady = false;
  bool _initialized = false;

  bool get tfliteReady => _tfliteReady;
  bool get serverReady => _serverReady;
  bool get isReady     => _tfliteReady || _serverReady;

  /// Engine untuk real-time (Mode Tuntun, Navigasi):
  /// TFLite jika ready, server sebagai fallback.
  InferenceEngine get realtimeEngine =>
      _tfliteReady ? InferenceEngine.tflite : InferenceEngine.server;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load TFLite dan connect server secara parallel
    // GPS/koordinat tidak dipakai (sesuai request user)
    final results = await Future.wait([
      TFLiteService.instance.tryLoad(),
      _tryConnectServer(),
    ]);

    _tfliteReady = results[0];
    _serverReady = results[1];
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _tryConnectServer() async {
    try {
      // Connect tanpa koordinat GPS (risk zone tidak aktif, fitur lain tetap jalan)
      await ServerService.instance.connect();
      return true;
    } catch (_) {
      return false;
    }
  }

  void onServerConnected()    { _serverReady = true;  notifyListeners(); }
  void onServerDisconnected() { _serverReady = false; notifyListeners(); }
}
```

---

## Berkas: `lib/providers/money_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/money_provider.dart`

```dart
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/money_tflite_service.dart';
import '../widgets/nominal_card.dart' show terbilangRupiah;

/// State machine "nol sentuhan" Mode Kenali Uang — bagian 9 IMPLEMENTASI.md
/// (UG-01..UG-12, UG-17, UG-18). Sepenuhnya on-device dan sepenuhnya MOCK:
/// tidak ada model nominal sungguhan, deteksi disimulasikan lewat Timer.
///
/// UG-13 (offline banner), UG-14 (izin kamera), UG-15 (senyap/TTS mati), dan
/// UG-16 (font scale 200%) sengaja TIDAK dimodelkan di sini — itu murni
/// keputusan lapisan UI (screen membaca GlobalConditionsProvider / izin
/// sistem / MediaQuery langsung), sesuai instruksi agar provider ini tetap
/// murni state-machine mock.
enum MoneyState {
  idle,        // UG-01
  noCandidate, // UG-08
  partial,     // UG-02
  folded,      // UG-10
  fit,         // UG-03
  glare,       // UG-12a
  dark,        // UG-12b
  processing,  // UG-04
  detected,    // UG-05 (lembar pertama sesi)
  multiple,    // UG-09a/UG-09b (≥2 lembar, breakdown ditampilkan)
  consecutive, // UG-11 (lembar berturut-turut, total berjalan)
  uncertain,   // UG-06
  notMoney,    // UG-07
  foreign,     // UG-18
  resetAnnounce, // UG-17
}

/// Pola getar bagian 3.6 — `positive` (2×25ms) untuk bingkai pas,
/// `moneyAck` (3×40ms) khusus UG-15 (dipicu dari layar, bukan dari sini).
enum MoneyHaptic { positive }

const _kNoCandidateHints = [
  'Dekatkan sedikit uangnya ke kamera',
  'Cari tempat yang lebih terang',
  'Posisikan uang rata di tengah bingkai',
];

const _kDenoms = [1000, 2000, 5000, 10000, 20000, 50000, 100000];
const _kNotMoneyLabels = ['kartu', 'kwitansi', 'tiket', 'nota belanja'];

class MoneyProvider extends ChangeNotifier {
  final _rand = Random();

  MoneyState _state = MoneyState.idle;
  MoneyState get state => _state;

  /// Rincian lembar dalam sesi berjalan: denominasi → jumlah lembar.
  final Map<int, int> _breakdown = {};
  Map<int, int>? get sessionBreakdown => _breakdown.isEmpty ? null : Map.unmodifiable(_breakdown);
  int get sessionTotal => _breakdown.entries.fold(0, (sum, e) => sum + e.key * e.value);
  int get sheetCount => _breakdown.values.fold(0, (sum, v) => sum + v);

  int _lastAmount = 0;
  int get lastAmount => _lastAmount;

  int _noCandidateHintIndex = 0;
  String get noCandidateHint => _kNoCandidateHints[_noCandidateHintIndex];

  String _notMoneyLabel = _kNotMoneyLabels.first;
  String get notMoneyLabel => _notMoneyLabel;

  int _resetAnnounceTotal = 0;
  int get resetAnnounceTotal => _resetAnnounceTotal;

  bool get busy => _state == MoneyState.processing;

  /// Callback keluar — screen yang mengubahnya jadi suara/getar sungguhan
  /// lewat TtsProvider/Vibration, supaya provider ini tetap tidak bergantung
  /// pada BuildContext (pola sama dengan `CameraProvider.onFrameReady`).
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(MoneyHaptic pattern)? onHaptic;

  Timer? _stepTimer;
  Timer? _hintRotateTimer;
  Timer? _sessionResetTimer;
  bool _running = false;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);
  void _haptic(MoneyHaptic p) => onHaptic?.call(p);

  void _set(MoneyState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  /// Masuk mode (UG-01) — mulai siklus otomatis dari awal.
  void start() {
    if (_running) return;
    _running = true;
    _breakdown.clear();
    _lastAmount = 0;
    _set(MoneyState.idle);
    if (!_useRealModel) _scheduleFromIdle();
  }

  /// Keluar mode — hentikan semua timer, jangan bicara lagi.
  void pause() {
    _running = false;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    _sessionResetTimer?.cancel();
  }

  /// Dipanggil dari tombol kamera BottomActionBar — "paksa deteksi ulang".
  void forceRedetect() {
    if (!_running) return;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    if (_useRealModel) {
      _consecutiveMiss = 0;
      _set(MoneyState.fit);
      return;
    }
    _enterFit();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Jalur inferensi NYATA (on-device TFLite)
  //
  // Saat model tersedia, siklus mock berbasis Timer dimatikan total dan
  // state digerakkan oleh hasil klasifikasi frame sungguhan. Mock tetap
  // dipertahankan sebagai cadangan supaya seluruh 18 state tetap bisa
  // diperiksa walau file model belum ada di perangkat.
  // ─────────────────────────────────────────────────────────────────────

  bool _useRealModel = false;
  bool get useRealModel => _useRealModel;

  bool _inferring = false;
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveMiss = 0;

  /// Jeda antar inferensi. Klasifikasi 224x224 ringan, tapi tidak ada
  /// gunanya berjalan tiap frame: pengguna butuh waktu memposisikan uang.
  static const _inferenceInterval = Duration(milliseconds: 600);

  /// Coba muat model on-device. Mengembalikan false kalau file belum ada —
  /// pemanggil lalu membiarkan siklus mock yang jalan.
  Future<bool> enableRealModel() async {
    final ok = await MoneyTFLiteService.instance.load();
    _useRealModel = ok;
    if (ok) {
      _stepTimer?.cancel();
      _hintRotateTimer?.cancel();
      _set(MoneyState.idle);
    }
    return ok;
  }

  /// Umpan frame kamera. Aman dipanggil tiap frame — di-throttle sendiri.
  Future<void> submitFrame(CameraImage image) async {
    if (!_useRealModel || !_running || _inferring) return;
    if (DateTime.now().difference(_lastInference) < _inferenceInterval) return;

    _inferring = true;
    _lastInference = DateTime.now();
    try {
      final result = await MoneyTFLiteService.instance.classifyCameraImage(image);
      _applyRealResult(result);
    } finally {
      _inferring = false;
    }
  }

  void _applyRealResult(MoneyResult result) {
    if (!_running) return;

    if (result.detected && result.valueIdr != null) {
      _consecutiveMiss = 0;
      // Jangan umumkan lembar yang sama berulang-ulang saat kamera masih
      // menyorot uang yang itu-itu juga.
      if (_state == MoneyState.detected && _lastAmount == result.valueIdr) return;
      if (_state == MoneyState.consecutive && _lastAmount == result.valueIdr) return;
      _enterDetected(result.valueIdr!);
      return;
    }

    switch (result.failure) {
      case MoneyFailure.lowConfidence:
        // UG-06 — ragu. Nominal tidak ditampilkan sama sekali.
        _consecutiveMiss = 0;
        if (_state != MoneyState.uncertain) {
          _set(MoneyState.uncertain);
          _speak('Belum yakin, dekatkan sedikit dan tahan diam.', tier: SpeechTier.warning);
        }
      case MoneyFailure.modelUnavailable:
        _useRealModel = false;
        if (!_running) return;
        _scheduleFromIdle();
      case MoneyFailure.error:
      case null:
        // UG-08 — tidak ada kandidat: pill instruksi berputar tiap 5 detik.
        _consecutiveMiss++;
        if (_consecutiveMiss >= 8 && _state != MoneyState.noCandidate) {
          _set(MoneyState.noCandidate);
          _startHintRotation();
        }
    }
  }

  void _startHintRotation() {
    _hintRotateTimer?.cancel();
    _hintRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _noCandidateHintIndex = (_noCandidateHintIndex + 1) % _kNoCandidateHints.length;
      notifyListeners();
    });
  }

  /// Nominal yang TIDAK didukung model (emisi/pecahan di luar 6 kelas).
  /// Dipakai layar untuk menyusun pesan keterbatasan yang jujur (UG-18).
  List<int> get unsupportedValues => MoneyTFLiteService.unsupportedValues;

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  // ---------------------------------------------------------------- idle

  void _scheduleFromIdle() {
    _set(MoneyState.idle);
    _after(2200 + _rand.nextInt(2000), () {
      if (_rand.nextDouble() < 0.22) {
        _enterNoCandidate();
      } else {
        _enterPartial();
      }
    });
  }

  void _enterNoCandidate() {
    _noCandidateHintIndex = 0;
    _set(MoneyState.noCandidate);
    _hintRotateTimer?.cancel();
    _hintRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _noCandidateHintIndex = (_noCandidateHintIndex + 1) % _kNoCandidateHints.length;
      notifyListeners();
    });
    _after(7000 + _rand.nextInt(4000), () {
      _hintRotateTimer?.cancel();
      _enterPartial();
    });
  }

  // -------------------------------------------------------------- partial

  void _enterPartial() {
    _set(MoneyState.partial);
    _after(1200 + _rand.nextInt(900), () {
      if (_rand.nextDouble() < 0.15) {
        _enterFolded();
      } else {
        _enterFit();
      }
    });
  }

  void _enterFolded() {
    _set(MoneyState.folded);
    _after(1600 + _rand.nextInt(700), _enterFit);
  }

  // ------------------------------------------------------------------ fit

  void _enterFit() {
    _set(MoneyState.fit);
    _haptic(MoneyHaptic.positive);
    _after(550 + _rand.nextInt(400), () {
      final r = _rand.nextDouble();
      if (r < 0.08) {
        _enterGlare();
      } else if (r < 0.16) {
        _enterDark();
      } else {
        _enterProcessing();
      }
    });
  }

  void _enterGlare() {
    _set(MoneyState.glare);
    _after(1400 + _rand.nextInt(500), _enterFit);
  }

  void _enterDark() {
    _set(MoneyState.dark);
    _speak('Terlalu gelap. Coba nyalakan senter kamera.', tier: SpeechTier.warning);
    _after(1700 + _rand.nextInt(600), _enterFit);
  }

  // ------------------------------------------------------------ processing

  void _enterProcessing() {
    _set(MoneyState.processing);
    _after(380 + _rand.nextInt(80), _resolveDetection);
  }

  void _resolveDetection() {
    final r = _rand.nextDouble();
    if (r < 0.70) {
      _enterDetected(_kDenoms[_rand.nextInt(_kDenoms.length)]);
    } else if (r < 0.82) {
      _enterUncertain();
    } else if (r < 0.92) {
      _enterNotMoney();
    } else {
      _enterForeign();
    }
  }

  void _enterUncertain() {
    _set(MoneyState.uncertain);
    _speak('Belum yakin, dekatkan sedikit dan tahan diam.', tier: SpeechTier.warning);
    _after(2200, _enterProcessing);
  }

  void _enterNotMoney() {
    _notMoneyLabel = _kNotMoneyLabels[_rand.nextInt(_kNotMoneyLabels.length)];
    _set(MoneyState.notMoney);
    _speak('Ini sepertinya $_notMoneyLabel, bukan uang.', tier: SpeechTier.info);
    // Aturan #3: total yang sudah ada tidak boleh hilang diam-diam.
    _after(2200, () => _breakdown.isEmpty ? _scheduleFromIdle() : _settleSession());
  }

  void _enterForeign() {
    _set(MoneyState.foreign);
    _speak('Ini sepertinya uang asing atau rusak, saya belum bisa membacanya.', tier: SpeechTier.warning);
    _after(2200, () => _breakdown.isEmpty ? _scheduleFromIdle() : _settleSession());
  }

  // -------------------------------------------------------------- detected

  void _enterDetected(int amount) {
    _lastAmount = amount;
    _breakdown.update(amount, (v) => v + 1, ifAbsent: () => 1);
    _armSessionResetTimer();

    if (sheetCount == 1) {
      _set(MoneyState.detected);
      _speak(terbilangRupiah(amount), tier: SpeechTier.info);
      _scheduleNextSheetOrWait();
    } else {
      _set(MoneyState.multiple);
      _speak('Total ${terbilangRupiah(sessionTotal)}, dari $sheetCount lembar.', tier: SpeechTier.info);
      _after(2600, () {
        _set(MoneyState.consecutive);
        _scheduleNextSheetOrWait();
      });
    }
  }

  /// Lembar berikutnya bisa masuk kapan saja dalam jendela 60 detik — atau
  /// tidak sama sekali, sehingga jatuh ke UG-17.
  void _scheduleNextSheetOrWait() {
    if (_rand.nextDouble() < 0.5) {
      _after(4000 + _rand.nextInt(9000), () {
        if (_state == MoneyState.detected || _state == MoneyState.consecutive) {
          _enterPartial();
        }
      });
    }
    // Kalau tidak dijadwalkan lembar baru, layar tetap diam di
    // detected/consecutive sampai timer 60 detik (UG-17) menyala sendiri.
  }

  void _armSessionResetTimer() {
    _sessionResetTimer?.cancel();
    _sessionResetTimer = Timer(const Duration(seconds: 60), () {
      if (_breakdown.isNotEmpty) _settleSession();
    });
  }

  /// UG-17 — total yang hilang WAJIB diumumkan, tidak pernah hilang diam-diam.
  void _settleSession() {
    _sessionResetTimer?.cancel();
    _resetAnnounceTotal = sessionTotal;
    _set(MoneyState.resetAnnounce);
    _speak('Total ${terbilangRupiah(_resetAnnounceTotal)} direset.', tier: SpeechTier.info);
    _after(2400, () {
      _breakdown.clear();
      _scheduleFromIdle();
    });
  }
}
```

---

## Berkas: `lib/providers/navigation_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/navigation_provider.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier;
import '../models/detection.dart';
import '../services/server_service.dart';
import '../widgets/zone_indicator.dart' show ZoneStatus;

/// NavigationStep — placeholder tanpa GPS/Google Maps (belum diimplementasi,
/// menyusul sprint lain).
class NavigationStep {
  final String instruction;
  final int distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

/// Fase segmentasi jalur — bagian 10 IMPLEMENTASI.md (NV-01..NV-13).
///
/// **Sepenuhnya di server.** Frame dikirim ke `POST /api/navigasi`, yang
/// mengembalikan status tiga zona plus zona rawan dari laporan komunitas.
///
/// > **Perubahan dari desain awal, disengaja.** Dokumen merancang mode ini
/// > dengan dua proses paralel: segmentasi jalur di server DAN deteksi
/// > rintangan on-device yang tetap hidup saat offline (§2, §4.4). Sejak
/// > keduanya dipindah ke server, NV-19 dan NV-20 tidak punya arti lagi —
/// > tidak ada lagi "on-device mati sementara server hidup". Offline sekarang
/// > berarti mode ini benar-benar buta, dan itu dikatakan apa adanya
/// > ketimbang dijanjikan setengah.
enum NavPhase {
  calibrating, // NV-01
  waitingServer, // NV-02
  active, // NV-03..NV-09
  serverDown, // NV-11 — sekarang berarti mode benar-benar berhenti
  serverWeak, // NV-13
  paused, // NV-15
}

class NavigationProvider extends ChangeNotifier {
  bool _navigating = false;
  String? _destination;
  List<NavigationStep> _steps = [];
  int _currentIdx = 0;
  final Map<String, String> _favorites = {};

  bool get isNavigating => _navigating;
  String? get destination => _destination;
  NavigationStep? get currentStep =>
      (_navigating && _steps.isNotEmpty && _currentIdx < _steps.length) ? _steps[_currentIdx] : null;
  Map<String, String> get favorites => Map.unmodifiable(_favorites);

  NavPhase _phase = NavPhase.calibrating;
  NavPhase get phase => _phase;

  ZoneStatus _left = ZoneStatus.unknown;
  ZoneStatus _center = ZoneStatus.unknown;
  ZoneStatus _right = ZoneStatus.unknown;
  ZoneStatus get left => _left;
  ZoneStatus get center => _center;
  ZoneStatus get right => _right;

  bool _pothole = false;
  bool get pothole => _pothole;
  double _potholeSteps = 3;
  double get potholeSteps => _potholeSteps;

  /// Zona rawan dari laporan komunitas — informasi yang tidak terlihat kamera.
  String? _riskZoneWarning;
  String? get riskZoneWarning => _riskZoneWarning;

  /// Rintangan dari server, dari frame yang sama dengan zona. Datang bersama
  /// zona supaya keduanya tidak pernah menggambarkan momen yang berbeda.
  List<Detection> _obstacles = const [];
  List<Detection> get obstacles => _obstacles;

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 — mengambil alih layar

  /// Sumber frame dan koordinat, dipasang screen. Provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;
  ({double lat, double lng})? Function()? locationSource;

  /// Satu permintaan in-flight; frame yang datang saat menunggu dibuang.
  /// Untuk mode yang menuntun orang berjalan, arahan untuk pemandangan tiga
  /// detik lalu lebih berbahaya daripada tidak ada arahan sama sekali.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 500));

  Timer? _loopTimer;
  int _consecutiveFailures = 0;
  String _lastSpokenMessage = '';
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void startCalibration() {
    _phase = NavPhase.calibrating;
    notifyListeners();
  }

  /// NV-01 selesai → NV-02 menunggu server → NV-03 jalur aman.
  ///
  /// NV-02 sekarang benar-benar menunggu jawaban server pertama, bukan timer
  /// tetap: pengguna tidak diberi tahu "siap" sebelum jalurnya sungguh terbaca.
  void finishCalibration() {
    _phase = NavPhase.waitingServer;
    _left = _center = _right = ZoneStatus.unknown;
    notifyListeners();
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    // ~2 frame per detik. Kecepatan jalan kaki sekitar 1,4 m/s, jadi tiap
    // frame mewakili kurang dari satu meter perjalanan — cukup rapat untuk
    // memperingatkan sebelum terlambat, cukup jarang untuk tidak menguras
    // baterai dan kuota di sepanjang perjalanan.
    _loopTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    _tick();
  }

  void _stopLoop() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _pacer.reset();
  }

  Future<void> _tick() async {
    if (_phase == NavPhase.paused) return;
    final grab = frameSource;
    if (grab == null) return;

    await _pacer.run(() async {
      final jpeg = await grab();
      if (jpeg == null) return;
      final loc = locationSource?.call();

      try {
        final res = await ServerService.instance.segmentasiJalur(
          jpeg,
          lat: loc?.lat ?? 0,
          lng: loc?.lng ?? 0,
        );
        _consecutiveFailures = 0;
        _handleZones(res);
      } on ApiStatusException {
        _handleFailure();
      } on ApiUnreachableException {
        _handleFailure();
      }
    });
  }

  void _handleZones(Map<String, dynamic> res) {
    final wasDown = _phase == NavPhase.serverDown || _phase == NavPhase.waitingServer;

    if (res['ok'] != true) {
      // Frame tidak terbaca (lensa tertutup, terlalu gelap) — beda dari
      // server mati, dan naskahnya juga beda.
      _left = _center = _right = ZoneStatus.unknown;
      _phase = NavPhase.serverDown;
      _announce(
        res['message'] as String? ?? 'Jalur tidak terbaca. Berhenti jalan dulu.',
        SpeechTier.critical,
      );
      notifyListeners();
      return;
    }

    final zones = res['zones'] as Map<String, dynamic>?;
    if (zones == null) return;

    _left = _statusFrom(zones['kiri']);
    _center = _statusFrom(zones['tengah']);
    _right = _statusFrom(zones['kanan']);
    _phase = NavPhase.active;

    // Rintangan dari frame yang sama — lihat catatan di routers/navigasi.py.
    final rawObstacles = res['obstacles'];
    _obstacles = rawObstacles is List
        ? rawObstacles
            .map((e) => Detection.fromJson(e as Map<String, dynamic>))
            .toList()
        : const [];

    // NV-09 — lubang dilaporkan server sebagai zona danger yang sempit;
    // sementara backend belum memisahkannya, tandai lewat field opsional.
    _pothole = res['pothole'] == true;
    if (_pothole) {
      _potholeSteps = (res['pothole_steps'] as num?)?.toDouble() ?? 3;
    }

    // Zona rawan komunitas — disebut sekali saat masuk radius, tidak diulang.
    final risk = res['risk_zone'] as Map<String, dynamic>?;
    final riskWarning = risk?['warning'] as String?;
    if (riskWarning != null && riskWarning != _riskZoneWarning) {
      _riskZoneWarning = riskWarning;
      _speak(riskWarning, tier: SpeechTier.warning);
    } else if (risk == null) {
      _riskZoneWarning = null;
    }

    if (wasDown) {
      _speak('Jalur terbaca lagi.', tier: SpeechTier.info);
    }

    final message = res['message'] as String? ?? '';
    final allDanger = _left == ZoneStatus.danger &&
        _center == ZoneStatus.danger &&
        _right == ZoneStatus.danger;

    if (allDanger) {
      // NV-07 — berdiri diam adalah tindakan yang sah.
      _announce('Berhenti dulu. Tidak ada jalur aman di sekitar sini.', SpeechTier.critical);
    } else if (_center == ZoneStatus.danger) {
      // NV-06 — mengambil alih layar dan memotong antrean suara.
      onTakeover?.call();
      _announce(
        message.isNotEmpty ? message : 'Berhenti! Jalur di depan tidak aman.',
        SpeechTier.critical,
      );
    } else if (message.isNotEmpty) {
      _announce(message, SpeechTier.warning);
    }

    notifyListeners();
  }

  /// Anti-banjir suara. Server mengirim pesan tiap frame; mengucapkan semuanya
  /// akan menutupi suara lalu lintas — hal terakhir yang boleh terjadi pada
  /// orang yang sedang menyeberang. Pesan yang sama hanya diulang setelah
  /// jeda, kecuali Critical yang selalu lewat.
  void _announce(String message, SpeechTier tier) {
    final now = DateTime.now();
    final isRepeat = message == _lastSpokenMessage;
    final elapsed = now.difference(_lastSpokenAt);

    if (tier != SpeechTier.critical && isRepeat && elapsed < const Duration(seconds: 6)) {
      return;
    }
    if (tier != SpeechTier.critical && elapsed < const Duration(milliseconds: 1800)) {
      return;
    }
    _lastSpokenMessage = message;
    _lastSpokenAt = now;
    _speak(message, tier: tier);
  }

  ZoneStatus _statusFrom(dynamic zone) {
    final status = (zone is Map<String, dynamic>) ? zone['status'] as String? : null;
    return switch (status) {
      'safe' => ZoneStatus.safe,
      'caution' => ZoneStatus.caution,
      'danger' => ZoneStatus.danger,
      _ => ZoneStatus.unknown,
    };
  }

  void _handleFailure() {
    _consecutiveFailures++;

    // Satu kegagalan bisa jadi hanya satu paket hilang — jangan langsung
    // menakuti pengguna. Tiga berturut-turut berarti sambungannya memang
    // putus, dan itu harus dikatakan segera: mode ini tidak punya cadangan
    // on-device lagi, jadi diam berarti membiarkan orang berjalan buta.
    if (_consecutiveFailures == 2) {
      _phase = NavPhase.serverWeak;
      _speak('Sinyal lemah, arahan jalur mungkin tertinggal.', tier: SpeechTier.warning);
      notifyListeners();
      return;
    }

    if (_consecutiveFailures >= 4 && _phase != NavPhase.serverDown) {
      _phase = NavPhase.serverDown;
      _left = _center = _right = ZoneStatus.unknown;
      _speak(
        'Berhenti jalan dulu. Saya tidak bisa membaca jalur tanpa sambungan ke server.',
        tier: SpeechTier.critical,
      );
      notifyListeners();
    }
  }

  /// NV-14a/b — telepon masuk (disimulasikan manual dari panel debug).
  void simulateIncomingCall() {
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void endSimulatedCall() {
    _phase = NavPhase.active;
    // NV-14b — status jalur SEKARANG, bukan yang tadi. Karena itu loop-nya
    // dijalankan lagi lebih dulu dan ringkasannya menyusul dari frame baru.
    _speak('Navigasi lanjut. ${_summaryPhrase()}', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  String _summaryPhrase() {
    if (_left == ZoneStatus.safe && _center == ZoneStatus.safe && _right == ZoneStatus.safe) return 'Jalur aman.';
    return 'Periksa arahan jalur di layar.';
  }

  /// NV-15 — jeda otomatis (berhenti berjalan / ponsel diturunkan).
  /// Menghentikan loop juga menghentikan unggahan frame: berhenti berjalan
  /// berarti berhenti membakar kuota dan baterai.
  void autoPause() {
    if (_phase != NavPhase.active) return;
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void resumeFromPause() {
    if (_phase != NavPhase.paused) return;
    _phase = NavPhase.active;
    notifyListeners();
    _startLoop();
  }

  Future<void> startNavigation(String dest) async {
    _destination = dest;
    _currentIdx = 0;
    _navigating = true;
    _steps = [
      NavigationStep(instruction: 'Navigasi ke $dest belum tersedia. GPS akan ditambahkan.', distanceM: 0),
    ];
    notifyListeners();
    _speak('Tujuan disimpan: $dest. Fitur navigasi GPS segera hadir, arahan jalur dan rintangan tetap aktif.', tier: SpeechTier.info);
  }

  void stopNavigation() {
    _navigating = false;
    _destination = null;
    _steps = [];
    _currentIdx = 0;
    _riskZoneWarning = null;
    _consecutiveFailures = 0;
    _lastSpokenMessage = '';
    _stopLoop();
    notifyListeners();
  }

  void saveFavorite(String name, String destination) {
    _favorites[name] = destination;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLoop();
    super.dispose();
  }
}
```

---

## Berkas: `lib/providers/settings_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/settings_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/server_service.dart';
import '../services/tts_service.dart';

enum Verbosity { ringkas, sedang, detail }
enum VibrationMode { active, criticalOnly, off }
enum AppThemeMode { light, dark, highContrast }

/// Delapan pengaturan baku (bagian 13, "Delapan pengaturan"), dipersist ke
/// SharedPreferences. Efek nyata: kecepatan TTS, ambang jarak, dan alamat
/// server langsung memengaruhi service terkait. Tema/ukuran teks diterapkan
/// lewat [AppTheme] + `MediaQuery.textScaler` di level MaterialApp.
class SettingsProvider extends ChangeNotifier {
  static const _kSpeechRate = 'speech_rate';
  static const _kVerbosity = 'verbosity';
  static const _kVibration = 'vibration_mode';
  static const _kDistanceThreshold = 'distance_threshold_m';
  static const _kThemeMode = 'theme_mode';
  static const _kFontScale = 'font_scale';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kServerHost = 'server_host';

  double _speechRate = 0.5;
  Verbosity _verbosity = Verbosity.sedang;
  VibrationMode _vibrationMode = VibrationMode.active;
  double _distanceThresholdM = 2.0;
  AppThemeMode _themeMode = AppThemeMode.light;
  double _fontScale = 1.0; // 1.0..2.0 (200%)
  bool _onboardingDone = false;
  String _serverHost = kDefaultServerHost;

  double get speechRate => _speechRate;
  Verbosity get verbosity => _verbosity;
  VibrationMode get vibrationMode => _vibrationMode;
  double get distanceThresholdM => _distanceThresholdM;
  AppThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get onboardingDone => _onboardingDone;
  String get serverHost => _serverHost;
  bool get isFontScale200 => _fontScale >= 1.9;
  bool get isLoaded => _prefs != null;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _speechRate = _prefs!.getDouble(_kSpeechRate) ?? 0.5;
    _verbosity = Verbosity.values[_prefs!.getInt(_kVerbosity) ?? Verbosity.sedang.index];
    _vibrationMode = VibrationMode.values[_prefs!.getInt(_kVibration) ?? VibrationMode.active.index];
    _distanceThresholdM = _prefs!.getDouble(_kDistanceThreshold) ?? 2.0;
    _themeMode = AppThemeMode.values[_prefs!.getInt(_kThemeMode) ?? AppThemeMode.light.index];
    _fontScale = _prefs!.getDouble(_kFontScale) ?? 1.0;
    _onboardingDone = _prefs!.getBool(_kOnboardingDone) ?? false;
    _serverHost = _prefs!.getString(_kServerHost) ?? kDefaultServerHost;
    await TTSService.instance.setRate(_speechRate);
    // Alamat tersimpan diterapkan ke service SEBELUM permintaan pertama —
    // tanpa ini, alamat kustom baru berlaku setelah pengguna membukanya lagi.
    ServerService.instance.setHost(_serverHost);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await TTSService.instance.setRate(rate);
    await _prefs?.setDouble(_kSpeechRate, rate);
    notifyListeners();
  }

  Future<void> setVerbosity(Verbosity v) async {
    _verbosity = v;
    await _prefs?.setInt(_kVerbosity, v.index);
    notifyListeners();
  }

  Future<void> setVibrationMode(VibrationMode m) async {
    _vibrationMode = m;
    await _prefs?.setInt(_kVibration, m.index);
    notifyListeners();
  }

  Future<void> setDistanceThreshold(double meters) async {
    _distanceThresholdM = meters;
    await _prefs?.setDouble(_kDistanceThreshold, meters);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs?.setDouble(_kFontScale, scale);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool done) async {
    _onboardingDone = done;
    await _prefs?.setBool(_kOnboardingDone, done);
    notifyListeners();
  }

  Future<void> setServerHost(String host) async {
    _serverHost = host;
    // Terapkan ke service dulu, baru simpan, baru umumkan. Konfirmasi
    // "tersimpan" yang diucapkan pemanggil karena itu selalu menyusul
    // perubahan yang benar-benar terjadi (bagian 4.1).
    ServerService.instance.setHost(host);
    await _prefs?.setString(_kServerHost, host);
    notifyListeners();
  }
}
```

---

## Berkas: `lib/providers/tts_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/tts_provider.dart`

```dart
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart';

export '../core/speech/tts_queue.dart' show SpeechTier;

/// TtsProvider — pembungkus [TtsQueue] tier-based (bagian 15). Dipakai
/// screen/mode baru lewat `context.read<TtsProvider>().speak(msg, tier: ...)`
/// alih-alih memanggil TTSService langsung, supaya aturan interupsi
/// Critical/Warning/Info dan anti-banjir Info konsisten di seluruh app.
class TtsProvider extends ChangeNotifier {
  final _queue = TtsQueue();

  bool get isActive => _queue.isSpeaking;
  SpeechTier? get speakingTier => _queue.speakingTier;

  Future<void> speak(String message, {SpeechTier tier = SpeechTier.info}) async {
    notifyListeners();
    await _queue.speak(message, tier: tier);
    notifyListeners();
  }

  /// Kompatibel dengan pemanggil lama: `critical: true` ≈ `tier: critical`.
  Future<void> enqueue(String message, {bool critical = false}) =>
      speak(message, tier: critical ? SpeechTier.critical : SpeechTier.info);

  Future<void> interruptByUser() => _queue.interruptByUser();

  Future<void> stop() async {
    await _queue.stop();
    notifyListeners();
  }
}
```

---

## Berkas: `lib/providers/voice_provider.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/voice_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

/// VoiceState — bagian 11 IMPLEMENTASI.md (AS-01..AS-25). Granular dari 4
/// fase asli (idle/listening/processing/responding) supaya tiap sub-state
/// yang dipisah dokumen (mendengarkan vs tanpa suara vs berisik, proses
/// lokal vs LLM, dst.) punya representasi sendiri.
enum VoiceState {
  idle, // AS-01
  listening, // AS-03
  noSpeech, // AS-04
  tooNoisy, // AS-05
  transcribing, // AS-06
  transcribeFailed, // AS-07
  processingLocal, // AS-08
  processingLlm, // AS-09
  responded, // AS-10
  fallbackActive, // AS-14
  allFailed, // AS-15
  unrecognized, // AS-18
  ambiguous, // AS-19
}

class ChatTurn {
  final bool isUser;
  final String text;
  final DateTime at;
  ChatTurn({required this.isUser, required this.text}) : at = DateTime.now();
}

/// VoiceProvider — STT → intent routing → API call → TTS.
///
/// Intent routing 2-lapis dipertahankan dari implementasi awal:
/// - Layer 1: keyword lokal (0ms latency, aman offline) via [CommandParser].
/// - Layer 2: LLM routing via ServerService.routeIntent, hanya dipanggil
///   kalau Layer 1 tidak match.
class VoiceProvider extends ChangeNotifier {
  final CameraProvider _camera;
  final DetectionProvider _detection;
  final AppModeProvider _appMode;

  VoiceProvider(this._camera, this._detection, this._appMode);

  final SpeechToText _stt = SpeechToText();
  VoiceState _state = VoiceState.idle;
  String _lastText = '';
  String _response = '';
  int _consecutiveFailures = 0;

  final List<ChatTurn> _history = [];
  List<ChatTurn> get history => List.unmodifiable(_history);
  DateTime? _lastActivity;

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isProcessing => _state == VoiceState.transcribing || _state == VoiceState.processingLocal || _state == VoiceState.processingLlm;
  String get lastText => _lastText;
  String get response => _response;

  /// AS-18 — dua tebakan terdekat saat perintah tidak dikenali.
  List<VoiceIntent> _suggestions = [];
  List<VoiceIntent> get suggestions => _suggestions;
  String _heardRaw = '';
  String get heardRaw => _heardRaw;

  /// Dipasang layar untuk menyalurkan suara lewat antrean tier — menjaga
  /// provider ini tidak bergantung BuildContext, pola sama dengan mode lain.
  void Function(String text)? onSpeak;
  void Function()? onAllFeaturesFailed;

  /// Pengaturan adalah layar penunjang, bukan mode — pembukaannya butuh
  /// Navigator. Layar yang aktif memasang ini dan mengembalikan **true hanya
  /// kalau halaman benar-benar terbuka**; kalau null atau false, Vinara
  /// mengatakan yang sejujurnya alih-alih mengonfirmasi.
  Future<bool> Function()? onOpenSettings;

  Future<void> init() async {
    await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (_) => _setState(VoiceState.noSpeech),
    );
  }

  /// AS-23 — riwayat kedaluwarsa setelah 15 menit tanpa aktivitas.
  bool checkAndExpireHistory() {
    if (_history.isEmpty || _lastActivity == null) return false;
    if (DateTime.now().difference(_lastActivity!) > const Duration(minutes: 15)) {
      _history.clear();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> startListening() async {
    if (_state != VoiceState.idle &&
        _state != VoiceState.responded &&
        _state != VoiceState.unrecognized &&
        _state != VoiceState.ambiguous &&
        _state != VoiceState.noSpeech &&
        _state != VoiceState.transcribeFailed &&
        _state != VoiceState.allFailed) {
      return;
    }
    _lastText = '';
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _lastText = result.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 5),
      localeId: 'id_ID',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    if (!_stt.isListening) return;
    await _stt.stop();
  }

  void _onSttStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_lastText.trim().isNotEmpty) {
        _processText(_lastText);
      } else {
        _setState(VoiceState.noSpeech);
      }
    }
  }

  Future<void> _processText(String text) async {
    _lastActivity = DateTime.now();
    _heardRaw = text;
    _history.add(ChatTurn(isUser: true, text: text));
    // AS-06 — jeda pendek "mentranskrip", tanpa kata "memproses".
    _setState(VoiceState.transcribing);
    await Future.delayed(const Duration(milliseconds: 250));

    final command = CommandParser.parse(text);

    if (!command.recognized) {
      if (command.suggestions.length >= 2) {
        // AS-19 — ambigu, pertanyaan pilihan dua.
        _suggestions = command.suggestions;
        _setState(VoiceState.ambiguous);
        _respond(
          'Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}, atau ${command.suggestions[1].spokenLabel}?',
          save: false,
        );
        return;
      }
      if (command.suggestions.isNotEmpty) {
        // AS-18 — tidak dikenali, satu tebakan tersedia.
        _suggestions = command.suggestions;
        _setState(VoiceState.unrecognized);
        _respond('Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}?', save: false);
        return;
      }
      await _handleDescribeScene();
      return;
    }

    if (command.intent!.isModeChange) {
      // AS-17 — perintah ganti mode.
      await _applyModeChange(command.intent!);
      return;
    }

    switch (command.intent!) {
      case VoiceIntent.helpWhat:
        await _handleLocal('Aku bisa mendeteksi objek, membaca teks, mengenali uang, menuntun jalan, mencari barang, atau menjawab pertanyaan tentang sekitarmu.');
        break;
      case VoiceIntent.helpWhereAmI:
        await _handleLocal('Kamu di mode Asisten Suara.');
        break;
      default:
        await _handleDescribeScene();
    }
  }

  /// AS-17 — ganti mode lewat suara. **Aturan mutlak bagian 4.1: suara Vinara
  /// tidak boleh pernah mengonfirmasi sesuatu yang tidak terjadi.** State
  /// dipindah dulu lewat [AppModeProvider.setMode]; konfirmasi "Baik."
  /// dititipkan sebagai prefiks pengumuman kedatangan, jadi ia baru terdengar
  /// setelah layar mode tujuan benar-benar terpasang. Kalau perpindahan
  /// dibatalkan (NV-18 saat pengguna masih berjalan), yang diucapkan adalah
  /// keadaan yang sebenarnya — bukan konfirmasi.
  Future<void> _applyModeChange(VoiceIntent intent) async {
    if (intent == VoiceIntent.modeSettings) {
      final opened = await onOpenSettings?.call() ?? false;
      if (opened) {
        _consecutiveFailures = 0;
        // Diucapkan sesudah rutenya benar-benar masuk tumpukan.
        await _respond('Pengaturan terbuka.', save: false);
      } else {
        await _respond(
          'Pengaturan belum bisa dibuka dari sini. Tekan Pilih mode, lalu buka Pengaturan.',
          save: false,
        );
      }
      return;
    }

    final target = switch (intent) {
      VoiceIntent.modeMoney => AppMode.money,
      VoiceIntent.modeReadText => AppMode.ocr,
      VoiceIntent.modeDetection => AppMode.tuntun,
      VoiceIntent.modeNavigation => AppMode.navigasi,
      VoiceIntent.modeAssistant => AppMode.voice,
      VoiceIntent.modeFindObject => AppMode.findObject,
      _ => null,
    };
    if (target == null) {
      await _respond('Saya belum bisa membuka itu. Coba sebutkan nama modenya.', save: false);
      return;
    }

    // Sudah berada di mode yang diminta: katakan apa adanya, jangan berpura-pura
    // berpindah dan jangan mengumumkan ulang panduan mode.
    if (_appMode.mode == target) {
      _consecutiveFailures = 0;
      await _respond('Kamu sudah di mode ${target.label}.', save: false);
      return;
    }

    final changed = await _appMode.setMode(target, spokenPrefix: 'Baik.');
    if (!changed || _appMode.mode != target) {
      // Dibatalkan konfirmasi NV-18 — pengguna tetap di tempatnya.
      await _respond('Tetap di mode ${_appMode.mode.label}.', save: false);
      return;
    }
    _consecutiveFailures = 0;
    // Tidak ada _respond di sini: pengumuman "Baik. <Mode> aktif. <panduan>"
    // diucapkan announceEntry milik layar tujuan, sesudah ia terpasang.
    _setState(VoiceState.responded);
  }

  Future<void> _handleLocal(String answer) async {
    // AS-08 — proses lokal, "Baik." lalu langsung hasilnya.
    _setState(VoiceState.processingLocal);
    await _respond('Baik. $answer');
  }

  /// Implementasi lengkap describe_scene: capture → detect → narasi Claude
  /// → speak. AS-09 mengumumkan jeda 3-5 detik sebelum hasil datang.
  Future<void> _handleDescribeScene() async {
    _setState(VoiceState.processingLlm);
    onSpeak?.call('Saya lihat sekitarmu dulu, sekitar tiga sampai lima detik.');

    if (!_camera.isInitialized) {
      // AS-24 — izin kamera dicabut: tetap bisa menjawab yang tidak butuh penglihatan.
      await _handleChitchat();
      return;
    }

    try {
      final jpeg = await _camera.captureJpeg();
      final dets = await _detection.detectOnce(jpeg);
      final narasi = await ServerService.instance.getNarasi(dets, context: 'voice');
      _consecutiveFailures = 0;
      await _respond(narasi);
    } catch (e) {
      _consecutiveFailures++;
      if (_consecutiveFailures == 1) {
        // AS-14 — fallback lokal sederhana sebelum menyerah total.
        _setState(VoiceState.fallbackActive);
        await _respond('Saya belum bisa melihat detail sekarang. Coba lagi sebentar, atau tanyakan hal lain.');
      } else {
        // AS-15 — semua gagal, tidak buntu.
        _setState(VoiceState.allFailed);
        onAllFeaturesFailed?.call();
        await _respond('Fitur suara sedang bermasalah. Deteksi objek tetap jalan di mode lain.');
        _consecutiveFailures = 0;
      }
    }
  }

  Future<void> _handleChitchat() async {
    await _respond('Saya belum bisa melihat sekarang (izin kamera dicabut), tapi tetap bisa bicara atau ganti mode.');
  }

  Future<void> _respond(String message, {bool save = true}) async {
    _response = message;
    _lastActivity = DateTime.now();
    if (save) _history.add(ChatTurn(isUser: false, text: message));
    _setState(VoiceState.responded);
    if (onSpeak != null) {
      onSpeak!(message);
    } else {
      await TTSService.instance.speak(message);
    }
  }

  /// AS-20 — pengguna menekan tombol Bicara lagi saat Vinara masih bicara:
  /// memotong tanpa nada khusus, langsung mulai dengar lagi.
  Future<void> interruptAndListenAgain() async {
    await TTSService.instance.stop();
    await startListening();
  }

  void _setState(VoiceState state) {
    _state = state;
    notifyListeners();
  }

  void backToIdle() => _setState(VoiceState.idle);

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }
}
```

---

## Berkas: `lib/screens/find_object_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/find_object_screen.dart`

```dart
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../core/net/frame_codec.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Cari Objek — bagian 12 IMPLEMENTASI.md, 19 state (CO-01..CO-19).
/// **Sepenuhnya di server** lewat `POST /api/cari-objek`; layar ini hanya
/// memasok frame dan menggambar hasilnya. Karena itu ia benar-benar
/// dinonaktifkan saat offline (CO-14), dengan targetnya disimpan.
class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

enum _Debug { co03, co07, co09, co11, co12, co14, co15, co16, co17, co18, co19 }

extension on _Debug {
  String get id => switch (this) {
        _Debug.co03 => 'CO-03', _Debug.co07 => 'CO-07', _Debug.co09 => 'CO-09',
        _Debug.co11 => 'CO-11', _Debug.co12 => 'CO-12', _Debug.co14 => 'CO-14',
        _Debug.co15 => 'CO-15', _Debug.co16 => 'CO-16', _Debug.co17 => 'CO-17',
        _Debug.co18 => 'CO-18', _Debug.co19 => 'CO-19',
      };
  String get title => switch (this) {
        _Debug.co03 => 'Nama tidak jelas',
        _Debug.co07 => 'Lebih dari satu cocok',
        _Debug.co09 => 'Hilang dari pandangan',
        _Debug.co11 => 'Lama tidak ketemu',
        _Debug.co12 => 'Objek tak dikenali',
        _Debug.co14 => 'Offline (mode dinonaktifkan)',
        _Debug.co15 => 'Izin kamera belum ada',
        _Debug.co16 => 'Senyap / TTS mati',
        _Debug.co17 => 'Font scale 200%',
        _Debug.co18 => 'Server error',
        _Debug.co19 => 'Terlalu gelap',
      };
}

class _FindObjectScreenState extends State<FindObjectScreen> with WidgetsBindingObserver {
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _hasCameraPermission = true;
  _Debug? _debugOverride;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _stt.initialize().then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" — sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.findObject);
      final provider = context.read<FindObjectProvider>();
      provider.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);
      provider.onDirectionHaptic = _fireDirectionHaptic;
      provider.isOffline = () =>
          context.read<GlobalConditionsProvider>().isOffline;
      provider.frameSource = _grabFrame;
      provider.loadKnownTargets();
      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Status koneksi frame sebelumnya — dipakai mendeteksi transisi
  /// offline→online untuk menepati janji CO-14.
  bool _wasOffline = false;

  /// Frame terakhir dari stream kamera. Disimpan mentah dan baru dikodekan
  /// saat benar-benar akan dikirim — mengodekan tiap frame kamera padahal
  /// hanya sebagian kecil yang terkirim adalah pemborosan CPU dan baterai
  /// yang langsung terasa sebagai panas di tangan pengguna.
  CameraImage? _latestFrame;

  Future<Uint8List?> _grabFrame() async {
    final frame = _latestFrame;
    if (frame == null) return null;
    return FrameCodec.encodeForUpload(
      frame,
      maxEdge: UploadPreset.findObject.maxEdge,
      quality: UploadPreset.findObject.quality,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stt.cancel();
    final provider = context.read<FindObjectProvider>();
    provider.onSpeak = null;
    provider.onDirectionHaptic = null;
    provider.frameSource = null;
    provider.isOffline = null;
    provider.reset();
    final cam = context.read<CameraProvider>();
    cam.onFrameReady = null;
    cam.stopStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        if (!cam.isInitialized) await cam.initCamera();
        cam.startStream();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      cam.startStream();
    }
  }

  Future<void> _fireDirectionHaptic(String direction) async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    if (direction == 'kiri') {
      Vibration.vibrate(duration: 60);
    } else if (direction == 'kanan') {
      Vibration.vibrate(pattern: [0, 60, 60, 60]);
    }
  }

  Future<void> _startListening() async {
    final offline = context.read<GlobalConditionsProvider>().isOffline;
    if (offline) return; // CO-14 — mode benar-benar dinonaktifkan
    if (!_sttReady) return;
    setState(() => _debugOverride = null);
    final provider = context.read<FindObjectProvider>();
    provider.startListening();
    await _stt.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final command = CommandParser.parse(result.recognizedWords);
        final target = command.intent == VoiceIntent.findObjectTarget
            ? command.argument
            : result.recognizedWords;
        provider.submitHeardText(result.recognizedWords, parsedTarget: target);
      },
      listenFor: const Duration(seconds: 5),
      localeId: 'id_ID',
      cancelOnError: true,
    );
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugSheet(
        current: _debugOverride,
        onSelect: (d) {
          Navigator.pop(sheetCtx);
          setState(() => _debugOverride = d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final fo = context.watch<FindObjectProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // CO-14 — janji "saya coba lagi begitu internet kembali" hanya bernilai
    // kalau benar-benar ditepati tanpa pengguna menyebut ulang barangnya.
    if (_wasOffline && !offline && fo.savedTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<FindObjectProvider>().retrySavedTarget();
      });
    }
    _wasOffline = offline;

    final disabledOffline = offline && _debugOverride != _Debug.co14 ? true : _debugOverride == _Debug.co14;
    final banner = disabledOffline
        ? const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet, Cari Objek tidak tersedia')
        : null;
    final hasBanner = banner != null;
    final hasTarget = _debugOverride == null && fo.target != null && fo.state != FindObjectState.idle;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.findObject, onDebugActivate: _openDebugSheet),
          ),

          if (hasTarget || _debugOverride != null)
            Positioned(
              top: topInset + secondaryChipTopOffset(hasBanner: hasBanner),
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              child: TargetChip(itemName: _debugTarget ?? fo.target ?? ''),
            ),

          if (!_hasCameraPermission || _debugOverride == _Debug.co15)
            // CO-15 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mencari dan menunjukkan arah barang yang kamu sebutkan.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (disabledOffline)
            const SizedBox.shrink()
          else
            ..._buildContent(context, fo, bottomInset),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              onMicPressed: _startListening,
              listeningOverride: fo.state == FindObjectState.listening,
            ),
          ),
        ],
      ),
    );
  }

  String? get _debugTarget => switch (_debugOverride) {
        _Debug.co07 => 'kunci motor',
        _Debug.co09 => 'dompet',
        _Debug.co11 => 'ponsel',
        null => null,
        _ => 'barang',
      };

  List<Widget> _buildContent(BuildContext context, FindObjectProvider fo, double bottomInset) {
    if (_debugOverride != null) return _renderDebug(_debugOverride!, bottomInset);

    switch (fo.state) {
      case FindObjectState.idle:
        return [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VoiceOrb(state: VoiceOrbState.idle),
                const SizedBox(height: AppSpacing.s4),
                _pill('Sebutkan barang yang kamu cari'),
              ],
            ),
          ),
        ];
      case FindObjectState.listening:
        return [Center(child: VoiceOrb(state: VoiceOrbState.listening))];
      case FindObjectState.unclear:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s4),
          _pill('Cari apa?'),
        ]))];
      case FindObjectState.targetActive:
      case FindObjectState.scanning:
        return [
          Positioned(
            left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
            bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
            child: AlertCard(
              tier: AlertTier.info,
              title: fo.state == FindObjectState.scanning ? fo.scanMessage : 'Mulai memindai…',
              description: 'Mencari ${fo.target}',
            ),
          ),
        ];
      case FindObjectState.found:
        return [_bottomPanel(bottomInset, _foundCard(fo))];
      case FindObjectState.lostFromView:
        return [_bottomPanel(bottomInset, AlertCard(
          tier: AlertTier.warning,
          title: '${fo.target} sempat hilang dari pandangan',
          description: 'Terakhir terlihat: ${fo.lastKnownPosition}',
        ))];
      case FindObjectState.notFoundInFrame:
        return [_bottomPanel(bottomInset, AlertCard(tier: AlertTier.info, title: fo.notFoundMessage, description: 'Mencari ${fo.target}'))];
      case FindObjectState.longNotFound:
        return [_bottomPanel(bottomInset, AlertCard(
          tier: AlertTier.warning,
          title: 'Belum ketemu di ruangan ini',
          description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.',
        ))];
      case FindObjectState.unknownObject:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Coba sebutkan barang lain.'))];
      case FindObjectState.serverError:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case FindObjectState.tooDark:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
      case FindObjectState.offlineSaved:
        // CO-14 — targetnya disimpan, dan itu dikatakan. Bukan "perintah
        // gagal": perintahnya diterima, hanya pelaksanaannya yang menunggu.
        return [
          _bottomPanel(
            bottomInset,
            AlertCard(
              tier: AlertTier.warning,
              title: 'Cari objek butuh internet',
              description: 'Target ${fo.savedTarget ?? fo.target} disimpan. '
                  'Saya lanjutkan begitu internet kembali.',
            ),
          ),
        ];
    }
  }

  Widget _foundCard(FindObjectProvider fo) {
    final title = fo.matchCount > 1
        ? '${fo.matchCount} ${fo.target} terlihat, yang terdekat di ${fo.direction}'
        : '${fo.target} di ${fo.direction}';
    // CO-08 — panduan bertahap: dekat sekali menyebut "ulurkan tangan".
    final description = fo.distanceMeter < 1 ? 'Sudah sangat dekat, ulurkan tangan' : null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AlertCard(tier: AlertTier.positive, title: title, description: description, distanceMeter: fo.distanceMeter),
        if (fo.matchCount > 1)
          Positioned(
            top: -10, right: 12,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(color: AppColors.actionLabel, borderRadius: AppRadius.pillShape),
                child: Text('+${fo.matchCount - 1} lagi', style: AppTypography.caption(color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(String text) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Text(text, style: AppTypography.body(color: Colors.white)),
      ),
    );
  }

  Widget _bottomPanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }

  List<Widget> _renderDebug(_Debug d, double bottomInset) {
    switch (d) {
      case _Debug.co03:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure), const SizedBox(height: AppSpacing.s4), _pill('Cari apa?'),
        ]))];
      case _Debug.co07:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: '3 kunci motor terlihat, yang terdekat di kiri', distanceMeter: 1.4))];
      case _Debug.co09:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'dompet sempat hilang dari pandangan', description: 'Terakhir terlihat: kanan, sekitar satu meter'))];
      case _Debug.co11:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'Belum ketemu di ruangan ini', description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.'))];
      case _Debug.co12:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Saya bisa mencari dompet, misalnya.'))];
      case _Debug.co14:
        return [];
      case _Debug.co15:
        return [];
      case _Debug.co16:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di kiri', distanceMeter: 1.2, description: 'Senyap aktif — arah lewat getar: 1 ketuk kiri, 2 ketuk kanan'))];
      case _Debug.co17:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di depan', distanceMeter: 1.2))];
      case _Debug.co18:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case _Debug.co19:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
    }
  }
}

class _DebugSheet extends StatelessWidget {
  final _Debug? current;
  final ValueChanged<_Debug?> onSelect;
  const _DebugSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
            Text('Debug — Mode Cari Objek', style: AppTypography.title()),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('Kembali ke mode otomatis'), onTap: () => onSelect(null)),
                  for (final d in _Debug.values)
                    ListTile(
                      leading: SizedBox(width: 56, child: Text(d.id, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                      title: Text(d.title),
                      selected: d == current,
                      onTap: () => onSelect(d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/index.dart`

```dart
export 'main_screen.dart';
export 'tuntun_screen.dart';
export 'money_screen.dart';
export 'ocr_screen.dart';
export 'navigasi_screen.dart';
export 'voice_screen.dart';
export 'find_object_screen.dart';
export 'splash_screen.dart';
export 'onboarding_screen.dart';
export 'permissions_screen.dart';
export 'settings_screen.dart';
```

---

## Berkas: `lib/screens/main_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/main_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/index.dart';
import '../screens/index.dart';
import '../theme/index.dart';

enum _BootStage { splash, onboarding, permissions, initializing, ready }

/// MainScreen — mengelola alur boot (bagian 6 & 13): Splash → Onboarding
/// (hanya pertama kali) → Izin → mode default (Deteksi Objek). Tidak ada
/// layar beranda: setelah boot, aplikasi langsung berada di salah satu dari
/// enam mode sejajar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  _BootStage _stage = _BootStage.splash;

  Future<void> _afterSplash() async {
    // Tunggu SettingsProvider selesai memuat onboarding_done dari disk.
    final settings = context.read<SettingsProvider>();
    while (!settings.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    if (!mounted) return;
    setState(() => _stage = settings.onboardingDone ? _BootStage.permissions : _BootStage.onboarding);
    if (_stage == _BootStage.permissions) await _checkPermissions();
  }

  Future<void> _afterOnboarding() async {
    await context.read<SettingsProvider>().setOnboardingDone(true);
    setState(() => _stage = _BootStage.permissions);
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraGranted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (cameraGranted) {
      setState(() => _stage = _BootStage.initializing);
      await _initServices();
    } else {
      setState(() => _stage = _BootStage.permissions);
    }
  }

  Future<void> _afterPermissions() async {
    setState(() => _stage = _BootStage.initializing);
    await _initServices();
  }

  Future<void> _initServices() async {
    try {
      await Future.wait([
        context.read<CameraProvider>().initCamera(),
        context.read<InferenceProvider>().initialize(),
        context.read<VoiceProvider>().init(),
      ]);
    } catch (e) {
      debugPrint('[MainScreen] Init error: $e');
    }

    if (!mounted) return;
    setState(() => _stage = _BootStage.ready);

    final cam = context.read<CameraProvider>();
    final inf = context.read<InferenceProvider>();

    if (!cam.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin kamera ditolak. Fitur kamera tidak tersedia.'),
          backgroundColor: AppColors.criticalLabel,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Pengaturan',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
    } else if (!inf.serverReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend tidak terhubung. Berjalan di Mode Lokal (TFLite). Fitur Voice & OCR mungkin tidak tersedia.'),
          backgroundColor: AppColors.warningLabel,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _BootStage.splash:
        return SplashScreen(onDone: _afterSplash);
      case _BootStage.onboarding:
        return OnboardingScreen(onDone: _afterOnboarding);
      case _BootStage.permissions:
        return PermissionsScreen(onDone: _afterPermissions);
      case _BootStage.initializing:
        return const _BootScreen();
      case _BootStage.ready:
        final mode = context.watch<AppModeProvider>().mode;
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (mode) {
              AppMode.tuntun     => const TuntunScreen(),
              AppMode.money      => const MoneyScreen(),
              AppMode.ocr        => const OcrScreen(),
              AppMode.navigasi   => const NavigasiScreen(),
              AppMode.voice      => const VoiceScreen(),
              AppMode.findObject => const FindObjectScreen(),
            },
          ),
        );
    }
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink1,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.actionFill,
                strokeWidth: 3,
              ),
              const SizedBox(height: AppSpacing.s6),
              Text('Memulai Vinara…', style: AppTypography.title(color: Colors.white)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Menyiapkan kamera dan AI',
                style: AppTypography.body(color: Colors.white.withValues(alpha: .6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/money_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/money_screen.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import '../widgets/nominal_card.dart';

/// Mode Kenali Uang — bagian 9 IMPLEMENTASI.md, 18 state (UG-01..UG-18).
/// Sepenuhnya on-device, nol sentuhan: [MoneyProvider] menjalankan siklus
/// deteksi mock sendiri lewat Timer, layar ini murni merender.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

/// Satu entri per baris tabel bagian 9 — termasuk pemecahan UG-09a/UG-09b
/// dan UG-12a/UG-12b apa adanya, supaya panel debug bisa menunjukkan kedua
/// varian secara terpisah (mis. UG-09b: campuran Rp20.000×2 + Rp5.000×1).
enum MoneyDebugState {
  ug01, ug02, ug03, ug04, ug05, ug06, ug07, ug08, ug09a, ug09b,
  ug10, ug11, ug12a, ug12b, ug13, ug14, ug15, ug16, ug17, ug18,
}

extension _DebugMeta on MoneyDebugState {
  String get id => switch (this) {
        MoneyDebugState.ug01 => 'UG-01', MoneyDebugState.ug02 => 'UG-02',
        MoneyDebugState.ug03 => 'UG-03', MoneyDebugState.ug04 => 'UG-04',
        MoneyDebugState.ug05 => 'UG-05', MoneyDebugState.ug06 => 'UG-06',
        MoneyDebugState.ug07 => 'UG-07', MoneyDebugState.ug08 => 'UG-08',
        MoneyDebugState.ug09a => 'UG-09a', MoneyDebugState.ug09b => 'UG-09b',
        MoneyDebugState.ug10 => 'UG-10', MoneyDebugState.ug11 => 'UG-11',
        MoneyDebugState.ug12a => 'UG-12a', MoneyDebugState.ug12b => 'UG-12b',
        MoneyDebugState.ug13 => 'UG-13', MoneyDebugState.ug14 => 'UG-14',
        MoneyDebugState.ug15 => 'UG-15', MoneyDebugState.ug16 => 'UG-16',
        MoneyDebugState.ug17 => 'UG-17', MoneyDebugState.ug18 => 'UG-18',
      };

  String get title => switch (this) {
        MoneyDebugState.ug01 => 'Idle',
        MoneyDebugState.ug02 => 'Masuk sebagian',
        MoneyDebugState.ug03 => 'Pas di bingkai',
        MoneyDebugState.ug04 => 'Memproses',
        MoneyDebugState.ug05 => 'Terdeteksi yakin (Rp50.000)',
        MoneyDebugState.ug06 => 'Ragu',
        MoneyDebugState.ug07 => 'Bukan uang',
        MoneyDebugState.ug08 => 'Tidak terdeteksi (5 detik)',
        MoneyDebugState.ug09a => 'Beberapa lembar sama (2×Rp20.000)',
        MoneyDebugState.ug09b => 'Beberapa lembar berbeda (Rp20.000×2 + Rp5.000×1)',
        MoneyDebugState.ug10 => 'Terlipat / terpotong',
        MoneyDebugState.ug11 => 'Lembar berturut-turut (total berjalan)',
        MoneyDebugState.ug12a => 'Silau',
        MoneyDebugState.ug12b => 'Gelap',
        MoneyDebugState.ug13 => 'Offline',
        MoneyDebugState.ug14 => 'Izin kamera belum ada',
        MoneyDebugState.ug15 => 'Senyap / TTS mati',
        MoneyDebugState.ug16 => 'Font scale 200%',
        MoneyDebugState.ug17 => 'Total direset',
        MoneyDebugState.ug18 => 'Uang asing / rusak',
      };
}

enum _CardPlacement { center, bottomSlot }

/// Deskripsi render untuk satu momen layar — dihasilkan baik dari
/// [MoneyProvider] (otomatis) maupun dari [MoneyDebugState] (paksa manual).
class _RenderSpec {
  final FrameFit? frame; // null = bingkai disembunyikan (UG-05/09/11)
  final bool frameDefaultCaption;
  final String? pillOverride;
  final bool badgeBusy;
  final Widget? card;
  final _CardPlacement cardPlacement;
  final String? note;
  final bool healthToastDark;

  const _RenderSpec({
    this.frame,
    this.frameDefaultCaption = false,
    this.pillOverride,
    this.badgeBusy = false,
    this.card,
    this.cardPlacement = _CardPlacement.bottomSlot,
    this.note,
    this.healthToastDark = false,
  });
}

const _moneyAckPattern = [0, 40, 60, 40, 60, 40];
const _positivePattern = [0, 25, 45, 25];

class _MoneyScreenState extends State<MoneyScreen> with WidgetsBindingObserver {
  MoneyDebugState? _debugOverride;
  bool _hasCameraPermission = true;
  bool _offlineBannerShownOnce = false;
  bool _offlineAutoHideScheduled = false;
  Timer? _offlineHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" — sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.money);
      final money = context.read<MoneyProvider>();
      money.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);
      money.onHaptic = (p) {
        switch (p) {
          case MoneyHaptic.positive:
            _fireHaptic(_positivePattern);
        }
      };

      // Klasifikasi nominal berjalan SEPENUHNYA di perangkat. Kalau file
      // model belum ada, provider otomatis jatuh ke siklus mock supaya
      // seluruh 18 state tetap bisa diperiksa.
      final realModel = await money.enableRealModel();
      if (!mounted) return;
      debugPrint('[MoneyScreen] model on-device: ${realModel ? "aktif" : "belum ada, pakai mock"}');

      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        if (realModel) cam.onFrameReady = money.submitFrame;
        cam.startStream();
        money.start();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineHideTimer?.cancel();
    final money = context.read<MoneyProvider>();
    money.onSpeak = null;
    money.onHaptic = null;
    money.pause();
    final cam = context.read<CameraProvider>();
    cam.onFrameReady = null;
    cam.stopStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        if (!cam.isInitialized) await cam.initCamera();
        cam.startStream();
        context.read<MoneyProvider>().start();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      cam.startStream();
      context.read<MoneyProvider>().start();
      await context.read<TtsProvider>().speak('Izin diberikan.', tier: SpeechTier.info);
    } else {
      await context.read<TtsProvider>().speak('Izin kamera belum diberikan.', tier: SpeechTier.warning);
    }
  }

  Future<void> _fireHaptic(List<int> pattern) async {
    if (!mounted) return;
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (has) Vibration.vibrate(pattern: pattern);
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugStateSheet(
        current: _debugOverride,
        onSelect: (d) {
          Navigator.pop(sheetCtx);
          final money = context.read<MoneyProvider>();
          setState(() => _debugOverride = d);
          if (d == null) {
            money.start();
          } else {
            money.pause();
            if (d == MoneyDebugState.ug15) _fireHaptic(_moneyAckPattern);
          }
        },
      ),
    );
  }

  void _replay(int amount) {
    context.read<TtsProvider>().speak(terbilangRupiah(amount), tier: SpeechTier.info);
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final money = context.watch<MoneyProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    final showPermissionCard =
        _debugOverride == MoneyDebugState.ug14 || (_debugOverride == null && !_hasCameraPermission);

    final showOfflineBanner = _debugOverride == MoneyDebugState.ug13 ||
        (_debugOverride == null && offline && !_offlineBannerShownOnce);

    if (showOfflineBanner && _debugOverride == null && !_offlineAutoHideScheduled) {
      _offlineAutoHideScheduled = true;
      _offlineHideTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() => _offlineBannerShownOnce = true);
      });
    }

    final badgeTop = topInset +
        AppSpacing.s2 +
        (modeBadgeTopOffset(hasBanner: showOfflineBanner) - ZonePositions.modeBadgeY);
    final chipTop = topInset +
        AppSpacing.s2 +
        (secondaryChipTopOffset(hasBanner: showOfflineBanner) - ZonePositions.modeBadgeY);

    final spec = showPermissionCard
        ? null
        : _debugOverride != null
            ? _specForDebug(_debugOverride!)
            : _specForState(money);

    final fontScaleDemo = _debugOverride == MoneyDebugState.ug16;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // z0 — kamera adalah lantai, full bleed.
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (showOfflineBanner)
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: MediaQuery(
                data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
                child: const StatusBanner(
                  tier: AlertTier.info,
                  message: 'Tanpa internet. Deteksi tetap berjalan di perangkat.',
                ),
              ),
            ),

          // z25 — ModeBadge, turun otomatis kalau banner hadir.
          Positioned(
            top: badgeTop,
            left: AppSpacing.screenMargin,
            child: MediaQuery(
              data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
              child: ModeBadge(
                mode: AppMode.money,
                busy: spec?.badgeBusy ?? false,
                onDebugActivate: _openDebugSheet,
              ),
            ),
          ),

          if (spec?.healthToastDark == true)
            Positioned(
              top: chipTop,
              left: AppSpacing.screenMargin,
              child: const CameraHealthToast(issue: CameraHealthIssue.dark),
            ),

          if (showPermissionCard)
            // UG-14 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera diperlukan',
              reason: 'Kenali Uang butuh kamera untuk melihat uang di depanmu. Semua diproses di perangkat.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else ...[
            if (spec!.frame != null)
              Center(
                child: SizedBox(
                  width: 300,
                  height: 172,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GuideFrame(fit: spec.frame!, showCaption: spec.frameDefaultCaption),
                      ),
                      if (spec.pillOverride != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Center(
                            child: MediaQuery(
                              data: media.copyWith(
                                textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.scrimText,
                                  borderRadius: AppRadius.pillShape,
                                ),
                                child: Text(spec.pillOverride!, style: AppTypography.caption(color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (spec.card != null && spec.cardPlacement == _CardPlacement.center)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spec.card!,
                      if (spec.note != null) ...[
                        const SizedBox(height: AppSpacing.s3),
                        MediaQuery(
                          data: media.copyWith(
                            textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler,
                          ),
                          child: Text(
                            spec.note!,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (spec.card != null && spec.cardPlacement == _CardPlacement.bottomSlot)
              Positioned(
                left: AppSpacing.screenMargin,
                right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
                child: MediaQuery(
                  data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
                  child: spec.card!,
                ),
              ),
          ],

          // z60 — BottomActionBar, selalu ada, selalu di tempat yang sama.
          // Mode nol-sentuhan: tombol kamera dipakai untuk "paksa deteksi ulang".
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery(
              data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
              child: BottomActionBar(
                cameraLabel: 'Deteksi ulang',
                cameraEnabled: !showPermissionCard && spec?.badgeBusy != true,
                onCameraPressed: () {
                  if (_debugOverride != null) {
                    setState(() => _debugOverride = null);
                    money.start();
                  }
                  money.forceRedetect();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- auto → spec

  _RenderSpec _specForState(MoneyProvider p) {
    switch (p.state) {
      case MoneyState.idle:
        return const _RenderSpec(
          frame: FrameFit.empty,
          pillOverride: 'Letakkan uang di dalam bingkai',
          cardPlacement: _CardPlacement.bottomSlot,
        );
      case MoneyState.noCandidate:
        return _RenderSpec(frame: FrameFit.empty, pillOverride: p.noCandidateHint);
      case MoneyState.partial:
        return const _RenderSpec(frame: FrameFit.partial, frameDefaultCaption: true);
      case MoneyState.folded:
        return const _RenderSpec(
          frame: FrameFit.tooClose,
          pillOverride: 'Ratakan uang, ada bagian di luar bingkai',
        );
      case MoneyState.fit:
        return const _RenderSpec(frame: FrameFit.fit, frameDefaultCaption: true);
      case MoneyState.glare:
        return const _RenderSpec(frame: FrameFit.fit, pillOverride: 'Miringkan sedikit');
      case MoneyState.dark:
        return _RenderSpec(
          frame: FrameFit.fit,
          healthToastDark: true,
          card: const AlertCard(
            tier: AlertTier.warning,
            title: 'Terlalu gelap',
            description: 'Coba nyalakan senter kamera atau cari cahaya lebih terang.',
          ),
        );
      case MoneyState.processing:
        return const _RenderSpec(frame: FrameFit.fit, badgeBusy: true);
      case MoneyState.detected:
        return _RenderSpec(card: NominalCard(amount: p.lastAmount, onReplay: () => _replay(p.lastAmount)));
      case MoneyState.multiple:
        return _RenderSpec(
          card: NominalCard(
            amount: p.sessionTotal,
            breakdown: p.sessionBreakdown,
            onReplay: () => _replay(p.sessionTotal),
          ),
        );
      case MoneyState.consecutive:
        return _RenderSpec(
          card: NominalCard(
            amount: p.lastAmount,
            runningTotal: p.sessionTotal,
            onReplay: () => _replay(p.lastAmount),
          ),
        );
      case MoneyState.uncertain:
        return const _RenderSpec(
          frame: FrameFit.fit,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Belum yakin',
            description: 'Dekatkan sedikit dan tahan diam sebentar.',
          ),
        );
      case MoneyState.notMoney:
        return _RenderSpec(
          frame: FrameFit.empty,
          card: AlertCard(
            tier: AlertTier.info,
            title: 'Ini sepertinya ${p.notMoneyLabel}',
            description: 'Bukan uang. Coba arahkan ke lembaran uang.',
          ),
        );
      case MoneyState.foreign:
        return const _RenderSpec(
          frame: FrameFit.empty,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Uang asing atau rusak',
            description: 'Belum bisa membaca nilainya. Nilai tukar tidak ditebak.',
          ),
        );
      case MoneyState.resetAnnounce:
        return _RenderSpec(
          card: AlertCard(
            tier: AlertTier.info,
            title: 'Total direset',
            description: 'Total ${formatRupiah(p.resetAnnounceTotal)} sudah selesai dihitung.',
          ),
        );
    }
  }

  // -------------------------------------------------------- debug → spec

  _RenderSpec _specForDebug(MoneyDebugState d) {
    switch (d) {
      case MoneyDebugState.ug01:
        return const _RenderSpec(frame: FrameFit.empty, pillOverride: 'Letakkan uang di dalam bingkai');
      case MoneyDebugState.ug02:
        return const _RenderSpec(frame: FrameFit.partial, frameDefaultCaption: true);
      case MoneyDebugState.ug03:
        return const _RenderSpec(frame: FrameFit.fit, frameDefaultCaption: true);
      case MoneyDebugState.ug04:
        return const _RenderSpec(frame: FrameFit.fit, badgeBusy: true);
      case MoneyDebugState.ug05:
        return _RenderSpec(card: NominalCard(amount: 50000, onReplay: () => _replay(50000)));
      case MoneyDebugState.ug06:
        return const _RenderSpec(
          frame: FrameFit.fit,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Belum yakin',
            description: 'Dekatkan sedikit dan tahan diam sebentar.',
          ),
        );
      case MoneyDebugState.ug07:
        return const _RenderSpec(
          frame: FrameFit.empty,
          card: AlertCard(tier: AlertTier.info, title: 'Ini sepertinya kartu', description: 'Bukan uang.'),
        );
      case MoneyDebugState.ug08:
        return const _RenderSpec(frame: FrameFit.empty, pillOverride: 'Cari tempat yang lebih terang');
      case MoneyDebugState.ug09a:
        return _RenderSpec(
          card: NominalCard(amount: 40000, breakdown: const {20000: 2}, onReplay: () => _replay(40000)),
        );
      case MoneyDebugState.ug09b:
        return _RenderSpec(
          card: NominalCard(
            amount: 45000,
            breakdown: const {20000: 2, 5000: 1},
            onReplay: () => _replay(45000),
          ),
        );
      case MoneyDebugState.ug10:
        return const _RenderSpec(
          frame: FrameFit.tooClose,
          pillOverride: 'Ratakan uang, ada bagian di luar bingkai',
        );
      case MoneyDebugState.ug11:
        return _RenderSpec(
          card: NominalCard(amount: 10000, runningTotal: 60000, onReplay: () => _replay(10000)),
        );
      case MoneyDebugState.ug12a:
        return const _RenderSpec(frame: FrameFit.fit, pillOverride: 'Miringkan sedikit');
      case MoneyDebugState.ug12b:
        return const _RenderSpec(
          frame: FrameFit.fit,
          healthToastDark: true,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Terlalu gelap',
            description: 'Coba nyalakan senter kamera atau cari cahaya lebih terang.',
          ),
        );
      case MoneyDebugState.ug13:
        // Banner-nya sendiri dirender terpisah (showOfflineBanner) — konten
        // di baliknya tetap jalan normal (deteksi on-device tak terpengaruh).
        return _RenderSpec(card: NominalCard(amount: 20000, onReplay: () => _replay(20000)));
      case MoneyDebugState.ug14:
        return const _RenderSpec(); // ditangani lewat showPermissionCard
      case MoneyDebugState.ug15:
        return _RenderSpec(
          card: NominalCard(amount: 25000, onReplay: () => _replay(25000)),
          note: 'TTS senyap: kartu bertahan sampai lembar berikutnya, getar 3× pendek menandai deteksi.',
        );
      case MoneyDebugState.ug16:
        return _RenderSpec(card: NominalCard(amount: 75000, onReplay: () => _replay(75000)));
      case MoneyDebugState.ug17:
        return const _RenderSpec(
          card: AlertCard(
            tier: AlertTier.info,
            title: 'Total direset',
            description: 'Total Rp95.000 sudah selesai dihitung.',
          ),
        );
      case MoneyDebugState.ug18:
        return const _RenderSpec(
          frame: FrameFit.empty,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Uang asing atau rusak',
            description: 'Belum bisa membaca nilainya. Nilai tukar tidak ditebak.',
          ),
        );
    }
  }
}

class _DebugStateSheet extends StatelessWidget {
  final MoneyDebugState? current;
  final ValueChanged<MoneyDebugState?> onSelect;

  const _DebugStateSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Panel debug — Kenali Uang', style: AppTypography.title()),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
              children: [
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded, color: AppColors.actionLabel),
                  title: const Text('Kembali ke mode otomatis'),
                  selected: current == null,
                  onTap: () => onSelect(null),
                ),
                const Divider(height: 1),
                for (final d in MoneyDebugState.values)
                  ListTile(
                    dense: true,
                    selected: current == d,
                    selectedTileColor: AppColors.actionTint,
                    title: Text('${d.id} — ${d.title}', style: AppTypography.body()),
                    onTap: () => onSelect(d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/navigasi_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/navigasi_screen.dart`

```dart
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../core/net/frame_codec.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Navigasi — bagian 10 IMPLEMENTASI.md, 25 state (NV-01..NV-25).
///
/// **Sepenuhnya di server** lewat `POST /api/navigasi`: segmentasi jalur dan
/// rintangan sama-sama dibaca di sana. Layar ini memasok frame dan menggambar
/// hasilnya; tidak ada inferensi on-device di mode ini.
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

/// NV-19 dan NV-20 dihapus dari katalog: keduanya memodelkan kombinasi
/// "on-device mati, server hidup" yang tidak mungkin lagi terjadi sejak
/// rintangan dan jalur sama-sama dibaca server. Kegagalan server sekarang
/// selalu berarti NV-11.
const List<(String, String)> _nvDebugCatalog = [
  ('NV-14a', 'Telepon masuk'),
  ('NV-16', 'Kamera tertutup'),
  ('NV-21', 'Izin kamera dicabut'),
  ('NV-22', 'Senyap / TTS mati (arah lewat getar)'),
  ('NV-25', 'Sudut kamera bergeser'),
];

class _NavigasiScreenState extends State<NavigasiScreen> with WidgetsBindingObserver {
  final TextEditingController _destCtrl = TextEditingController();
  bool _hasCameraPermission = true;
  String? _debugOverride;
  bool _silentMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.navigasi);

      final nav = context.read<NavigationProvider>();
      nav.onSpeak = (text, tier) {
        // NV-22 — senyap/TTS mati: arah lewat getar, 1 ketuk kiri, 2 ketuk kanan.
        if (_silentMode) {
          final rec = _recommendedZone(nav);
          if (rec == 0) _fireDirectionHaptic(true);
          if (rec == 2) _fireDirectionHaptic(false);
          return;
        }
        context.read<TtsProvider>().speak(text, tier: tier);
      };
      nav.onTakeover = () => context.read<TtsProvider>().interruptByUser();
      nav.frameSource = _grabFrame;
      nav.startCalibration();

      // NV-18 — satu-satunya konfirmasi wajib di seluruh app.
      context.read<AppModeProvider>().confirmLeave = _confirmLeaveNavigasi;

      if (_hasCameraPermission) {
        // Deteksi rintangan on-device sengaja TIDAK dijalankan di sini lagi:
        // rintangan dan jalur sama-sama dibaca server sekarang. Kamera hanya
        // memasok frame.
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Frame terakhir dari stream, dikodekan hanya saat benar-benar dikirim.
  CameraImage? _latestFrame;

  Future<Uint8List?> _grabFrame() async {
    final frame = _latestFrame;
    if (frame == null) return null;
    return FrameCodec.encodeForUpload(
      frame,
      maxEdge: UploadPreset.navigation.maxEdge,
      quality: UploadPreset.navigation.quality,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final appMode = context.read<AppModeProvider>();
    if (identical(appMode.confirmLeave, _confirmLeaveNavigasi)) {
      appMode.confirmLeave = null;
    }
    final nav = context.read<NavigationProvider>();
    nav.onSpeak = null;
    nav.onTakeover = null;
    nav.frameSource = null;
    nav.stopNavigation();
    final cam = context.read<CameraProvider>();
    cam.onFrameReady = null;
    cam.stopStream();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        if (!cam.isInitialized) await cam.initCamera();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      cam.onFrameReady = (image) => _latestFrame = image;
      cam.startStream();
    }
  }

  /// NV-18 — satu-satunya konfirmasi wajib di seluruh app.
  ///
  /// **Lembar bawah, bukan dialog tengah layar.** Pengguna sedang berjalan;
  /// menjangkau tombol di tengah layar berarti berhenti dan menyesuaikan
  /// pegangan — dengan satu tangan yang lain memegang tongkat. Tombolnya
  /// karena itu menempel di dasar, mengikuti `zone/page-action`.
  ///
  /// Fokus terkunci di dalam lembar (bawaan `showModalBottomSheet`); setelah
  /// ditutup, fokus kembali ke tombol pemanggilnya, bukan ke atas layar.
  Future<bool> _confirmLeaveNavigasi(AppMode from, AppMode to) async {
    final stillWalking = context.read<NavigationProvider>().phase != NavPhase.paused;
    if (!stillWalking) return true;

    await context.read<TtsProvider>().speak(
          'Kamu masih terdeteksi berjalan. Berhenti dulu sebelum keluar dari Navigasi.',
          tier: SpeechTier.critical,
        );
    if (!mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.bgPage,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin, AppSpacing.s6, AppSpacing.screenMargin, AppSpacing.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Keluar dari Navigasi?', style: AppTypography.title()),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'Kamu masih terdeteksi berjalan. Berhenti dulu dan pastikan aman sebelum ganti mode.',
                    style: AppTypography.body(color: AppColors.ink2),
                  ),
                ],
              ),
            ),
            // Pilihan aman ("Tetap di Navigasi") jadi tombol utama di dasar:
            // ia yang paling mudah dijangkau, dan ia yang paling sering benar.
            PageActionZone(
              primaryLabel: 'Tetap di Navigasi',
              onPrimary: () => Navigator.pop(ctx, false),
              secondaryLabel: 'Ya, keluar dari Navigasi',
              onSecondary: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _startNav() async {
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) return;
    await context.read<NavigationProvider>().startNavigation(dest);
  }

  Future<void> _fireDirectionHaptic(bool left) async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    Vibration.vibrate(pattern: left ? [0, 200] : [0, 80, 60, 80]);
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                  decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
              Text('Debug — Mode Navigasi', style: AppTypography.title()),
              const SizedBox(height: 4),
              Text('NV-01..13,15,17,22..24 tercapai lewat kalibrasi/simulasi/kondisi nyata',
                  textAlign: TextAlign.center, style: AppTypography.caption()),
              const SizedBox(height: AppSpacing.s3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(title: const Text('Kembali (bersihkan override)'), onTap: () {
                      Navigator.pop(sheetCtx);
                      setState(() { _debugOverride = null; _silentMode = false; });
                    }),
                    for (final entry in _nvDebugCatalog)
                      ListTile(
                        leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                        title: Text(entry.$2),
                        selected: entry.$1 == _debugOverride,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _applyDebug(entry.$1);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyDebug(String id) {
    setState(() => _debugOverride = id);
    final nav = context.read<NavigationProvider>();
    switch (id) {
      case 'NV-14a':
        nav.simulateIncomingCall();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) nav.endSimulatedCall();
        });
        break;
      case 'NV-22':
        setState(() => _silentMode = !_silentMode);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final cam = context.watch<CameraProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    final banner = _resolveBanner(context, nav, global, cam);
    final hasBanner = banner != null;
    // Rintangan datang dari server bersama zona, dari frame yang sama.
    final obstacles = nav.obstacles;
    final hasCriticalObstacle = obstacles.any((d) => d.isCritical);

    if (_debugOverride == 'NV-21') {
      // NV-21 — layar mengambil alih penuh, tidak ada BottomActionBar, jadi
      // aksinya memakai `zone/page-action`. Ini layar yang paling mungkin
      // muncul saat pengguna sedang memegang tongkat: tombol wajib di dasar.
      return const PageActionScaffold(
        primaryLabel: 'Buka pengaturan izin',
        onPrimary: openAppSettings,
        body: Center(
          child: PermissionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Izin kamera dicabut',
            reason: 'Berhenti jalan dulu. Navigasi butuh kamera untuk membaca rintangan dan jalur.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (nav.phase == NavPhase.active || nav.phase == NavPhase.serverWeak)
            Positioned.fill(child: ExcludeSemantics(child: _ZoneOverlay(left: nav.left, center: nav.center, right: nav.right))),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.navigasi, onDebugActivate: _openDebugSheet),
          ),

          if (!_hasCameraPermission)
            // Kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk membaca rintangan dan jalur di depanmu.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (nav.phase == NavPhase.calibrating)
            _calibrationCard(nav)
          else if (nav.phase == NavPhase.waitingServer)
            Positioned(
              top: topInset + AppSizes.modeBadgeHeight + AppSpacing.s4,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: const ZoneIndicator(left: ZoneStatus.unknown, center: ZoneStatus.unknown, right: ZoneStatus.unknown),
            )
          else ...[
            Positioned(
              top: topInset + modeBadgeTopOffset(hasBanner: hasBanner) + AppSizes.modeBadgeHeight + AppSpacing.s3,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: SizedBox(
                height: hasCriticalObstacle ? 40 : 52,
                child: ZoneIndicator(
                  left: nav.left, center: nav.center, right: nav.right,
                  recommended: _recommendedZone(nav),
                ),
              ),
            ),
            Positioned(
              top: topInset + modeBadgeTopOffset(hasBanner: hasBanner) + AppSizes.modeBadgeHeight + AppSpacing.s3 + (hasCriticalObstacle ? 40 : 52) + AppSpacing.s3,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: nav.isNavigating && nav.currentStep != null
                  ? _NavCard(step: nav.currentStep!, onStop: () => context.read<NavigationProvider>().stopNavigation())
                  : _DestInput(ctrl: _destCtrl, onStart: _startNav, favorites: nav.favorites),
            ),
            if (nav.pothole)
              Positioned(
                left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 100,
                child: AlertCard(tier: AlertTier.warning, title: 'Permukaan tidak rata', description: 'Sekitar ${nav.potholeSteps.toStringAsFixed(0)} langkah di depan'),
              ),
            if (obstacles.isNotEmpty)
              Positioned(
                left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
                child: AlertCardStack(cards: obstacles.map((d) => DetectionCard(detection: d)).toList()),
              ),
          ],

          const Positioned(left: 0, right: 0, bottom: 0, child: BottomActionBar()),
        ],
      ),
    );
  }

  int _recommendedZone(NavigationProvider nav) {
    if (nav.center == ZoneStatus.safe) return 1;
    if (nav.left == ZoneStatus.safe) return 0;
    if (nav.right == ZoneStatus.safe) return 2;
    return -1;
  }

  Widget _calibrationCard(NavigationProvider nav) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android_rounded, color: Colors.white, size: 40),
            const SizedBox(height: AppSpacing.s4),
            Text('Pegang ponsel tegak setinggi dada, kamera menghadap depan',
                textAlign: TextAlign.center, style: AppTypography.body(color: Colors.white)),
            const SizedBox(height: AppSpacing.s6),
            FullScreenButton(label: 'Siap, mulai', onTap: nav.finishCalibration),
          ],
        ),
      ),
    );
  }

  Widget? _resolveBanner(BuildContext context, NavigationProvider nav, GlobalConditionsProvider global, CameraProvider cam) {
    if (_debugOverride == 'NV-16' || (cam.healthMessage?.contains('menutupi') ?? false)) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Berhenti, saya tidak bisa melihat');
    }
    if (_debugOverride == 'NV-25' || (cam.healthMessage?.contains('tegak') ?? false)) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Angkat ponsel sedikit');
    }
    if (nav.phase == NavPhase.paused && _debugOverride == 'NV-14a') {
      return const StatusBanner(tier: AlertTier.info, message: 'Panggilan masuk, peringatan pindah ke getar');
    }
    // NV-11 — sejak segmentasi jalur DAN deteksi rintangan sama-sama di
    // server, "mode terbatas" tidak ada lagi: kalau server tidak terjangkau,
    // mode ini benar-benar tidak melihat apa pun. Bannernya Critical dan
    // menyuruh berhenti, bukan Warning yang menjanjikan sisa fungsi.
    if (nav.phase == NavPhase.serverDown) {
      return const StatusBanner(
        tier: AlertTier.critical,
        message: 'Berhenti jalan dulu, jalur tidak terbaca',
      );
    }
    if (nav.phase == NavPhase.serverWeak) {
      return const StatusBanner(tier: AlertTier.info, message: 'Sinyal lemah, arahan jalur mungkin tertinggal');
    }
    if (nav.left == ZoneStatus.danger && nav.center == ZoneStatus.danger && nav.right == ZoneStatus.danger) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Tidak ada jalur aman, berhenti dulu');
    }
    if (nav.center == ZoneStatus.danger) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Berhenti! Jalur kendaraan di depan');
    }
    final merged = global.merged;
    if (merged != null) {
      return StatusBanner(tier: merged.tier, message: merged.message, actionLabel: merged.actionLabel);
    }
    return null;
  }
}

class _ZoneOverlay extends StatelessWidget {
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;
  const _ZoneOverlay({required this.left, required this.center, required this.right});

  Color _color(ZoneStatus s) => switch (s) {
        ZoneStatus.safe => AppColors.positiveFill,
        ZoneStatus.caution => AppColors.warningFill,
        ZoneStatus.danger => AppColors.criticalFill,
        ZoneStatus.unknown => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.16,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: _color(left))),
          Expanded(child: ColoredBox(color: _color(center))),
          Expanded(child: ColoredBox(color: _color(right))),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final NavigationStep step;
  final VoidCallback onStop;
  const _NavCard({required this.step, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: step.instruction,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_rounded, color: AppColors.actionLabel, size: 28),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(step.instruction, style: AppTypography.bodyStrong())),
            Semantics(
              button: true,
              label: 'Hentikan navigasi',
              child: IconButton(icon: const Icon(Icons.close, color: AppColors.ink2), onPressed: onStop),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestInput extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onStart;
  final Map<String, String> favorites;
  const _DestInput({required this.ctrl, required this.onStart, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: AppTypography.body(),
                  decoration: InputDecoration(
                    hintText: 'Mau ke mana? (opsional)',
                    hintStyle: AppTypography.body(color: AppColors.ink2),
                    prefixIcon: const Icon(Icons.search, color: AppColors.ink2),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Semantics(
                button: true,
                label: 'Mulai navigasi',
                child: GestureDetector(
                  onTap: onStart,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: const BoxDecoration(color: AppColors.actionLabel, borderRadius: AppRadius.pillShape),
                    child: Center(child: Text('Mulai', style: AppTypography.label(color: Colors.white))),
                  ),
                ),
              ),
            ],
          ),
          if (favorites.isNotEmpty) ...[
            const Divider(height: AppSpacing.s6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('FAVORIT', style: AppTypography.eyebrow()),
            ),
            const SizedBox(height: AppSpacing.s2),
            ...favorites.entries.map(
              (e) => Semantics(
                button: true,
                label: 'Navigasi ke ${e.key}',
                child: InkWell(
                  onTap: () {
                    ctrl.text = e.key;
                    onStart();
                  },
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warningFill, size: 20),
                        const SizedBox(width: AppSpacing.s3),
                        Text(e.key, style: AppTypography.body()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/ocr_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/ocr_screen.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../mock/ocr_mock_data.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import '../widgets/ocr_debug_sheet.dart';
import '../widgets/ocr_long_result_panel.dart';

/// Mode Baca Teks — bagian 8 IMPLEMENTASI.md, 22 state (BT-01..BT-22).
/// Alur nyata (jepret → ServerService.readText → TTS) tetap dipakai untuk
/// state dasar; state yang butuh data server yang belum ada (dua bahasa,
/// sebagian gagal, sangat panjang) dicapai lewat panel debug (lib/mock/
/// ocr_mock_data.dart), sesuai bagian 2 dokumen "boleh dipalsukan".
class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

enum _FailKind { none, zeroText, offline, server, timeout }

class _OcrScreenState extends State<OcrScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = true;
  bool _scanning = false;
  bool _speaking = false;
  bool _paused = false;
  bool _nearTimeout = false;
  int _elapsedSeconds = 0;
  _FailKind _fail = _FailKind.none;
  // BT-10 (terbaca sebagian) tidak bisa dipicu dari server nyata saat ini
  // (ServerService.readText tidak mengembalikan status per-blok) — dicapai
  // lewat panel debug saja (lihat _resolveBanner / _renderDebug 'BT-10').
  static const _partialRead = false;

  List<OcrRenderBlock> _blocks = [];
  int _activeSentenceGlobal = -1;
  DateTime? _completedAt;

  String? _debugOverride; // BT-xx id

  Timer? _elapsedTicker;
  Timer? _hardTimeoutTimer;
  Timer? _sentenceTicker;
  Timer? _expiryTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" — diucapkan di sini, sesudah layarnya
      // benar-benar terpasang, bukan oleh pemanggil setMode.
      context.read<AppModeProvider>().announceEntry(AppMode.ocr);
      if (_hasCameraPermission) context.read<CameraProvider>().startStream();
    });
    // BT-20 — cek kedaluwarsa tiap 30 detik.
    _expiryTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTicker?.cancel();
    _hardTimeoutTimer?.cancel();
    _sentenceTicker?.cancel();
    _expiryTicker?.cancel();
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        if (!cam.isInitialized) await cam.initCamera();
        cam.startStream();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      cam.startStream();
    } else {
      await context.read<TtsProvider>().speak('Izin kamera belum diberikan.', tier: SpeechTier.warning);
    }
  }

  List<String> _splitSentences(String text) =>
      text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();

  Future<void> _scan() async {
    if (_scanning) return;
    if (_debugOverride != null) setState(() => _debugOverride = null);

    // Tidak ada lagi penghalang offline di sini. Pengenalan teks berjalan
    // sepenuhnya di perangkat lewat ML Kit, jadi BT-02 ("butuh internet")
    // tidak berlaku: melarang jepret saat offline berarti mematikan fitur
    // yang sebenarnya masih hidup — kesalahan yang sama seperti mematikan
    // Mode Navigasi offline.

    setState(() {
      _scanning = true;
      _fail = _FailKind.none;
      _blocks = [];
      _nearTimeout = false;
      _elapsedSeconds = 0;
    });

    await Vibration.hasVibrator().then((has) {
      if (has) Vibration.vibrate(duration: 15);
    });

    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= 8) setState(() => _nearTimeout = true);
    });
    _hardTimeoutTimer?.cancel();
    _hardTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_scanning) return;
      _elapsedTicker?.cancel();
      setState(() {
        _scanning = false;
        _nearTimeout = false;
        _fail = _FailKind.timeout;
      });
      context.read<TtsProvider>().speak('Terlalu lama, coba lagi.', tier: SpeechTier.warning);
    });

    try {
      final path = await context.read<CameraProvider>().captureFile();
      final result = await OcrService.instance.recognizeFile(path);

      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      setState(() => _scanning = false);

      if (result.isEmpty) {
        // BT-11 — instruksi jarak konkret, bukan "tidak ada teks".
        setState(() => _fail = _FailKind.zeroText);
        await context.read<TtsProvider>().speak(
              'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal, pastikan tulisan rata di tengah.',
              tier: SpeechTier.warning,
            );
        return;
      }

      setState(() {
        // ML Kit sudah memisahkan teks per blok tata letak, jadi heading
        // ResultPanel/long jadi nyata — bukan satu blok "Hasil baca" untuk
        // seluruh halaman seperti waktu OCR dikerjakan server.
        _blocks = [
          for (final b in result.blocks)
            OcrRenderBlock(heading: b.heading, sentences: b.sentences),
        ];
        _completedAt = null;
      });

      // BT-08 — kalau bacaannya panjang, sebut durasinya SEBELUM mulai,
      // supaya pengguna sempat memilih ringkasan.
      final secs = result.estimatedDuration.inSeconds;
      if (secs > 90) {
        await context.read<TtsProvider>().speak(
              'Teksnya panjang, sekitar ${(secs / 60).round()} menit dibacakan. '
              'Ucapkan "ringkas" kalau mau ringkasannya saja.',
              tier: SpeechTier.info,
            );
      }
      await _speak();
    } catch (e) {
      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      // Tidak ada lagi cabang offline/server: pengenalan on-device hanya gagal
      // karena kamera atau berkasnya, dan itu yang dikatakan.
      setState(() {
        _scanning = false;
        _fail = _FailKind.zeroText;
      });
      await context.read<TtsProvider>().speak(
            'Gagal membaca gambar. Coba ambil ulang.',
            tier: SpeechTier.warning,
          );
    }
  }

  Future<void> _speak() async {
    if (_blocks.isEmpty) return;
    setState(() {
      _speaking = true;
      _paused = false;
    });
    final flat = <String>[];
    for (final b in _blocks) {
      if (b.ok) flat.addAll(b.sentences);
    }
    final fullText = flat.join(' ');
    unawaited(_animateActiveSentence(flat.length));
    await TTSService.instance.speak(fullText);
    _sentenceTicker?.cancel();
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _activeSentenceGlobal = -1;
      _completedAt = DateTime.now();
    });
  }

  Future<void> _animateActiveSentence(int count) async {
    if (count == 0) return;
    _sentenceTicker?.cancel();
    var i = 0;
    setState(() => _activeSentenceGlobal = 0);
    _sentenceTicker = Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted || !_speaking) {
        t.cancel();
        return;
      }
      i++;
      if (i >= count) {
        t.cancel();
        return;
      }
      setState(() => _activeSentenceGlobal = i);
    });
  }

  Future<void> _togglePause() async {
    if (_speaking) {
      await context.read<TtsProvider>().interruptByUser();
      _sentenceTicker?.cancel();
      setState(() {
        _speaking = false;
        _paused = true;
      });
    } else if (_paused) {
      setState(() => _paused = false);
      await _speak();
    }
  }

  Future<void> _replay() async {
    if (_blocks.isEmpty) return;
    await _speak();
  }

  Future<void> _copy() async {
    final flat = _blocks.expand((b) => b.ok ? b.sentences : <String>[]).join(' ');
    if (flat.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: flat));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks disalin ke clipboard')),
      );
    }
  }

  void _goToAssistant() {
    context.read<AppModeProvider>().setMode(AppMode.voice);
  }

  Future<void> _readTitleOnly() async {
    setState(() {
      _blocks = [OcrRenderBlock(heading: 'Judul', sentences: [mockShortText()])];
      _fail = _FailKind.none;
    });
    await _speak();
  }

  void _openDebugSheet() {
    showOcrDebugSheet(
      context,
      activeId: _debugOverride,
      onSelect: (id) => setState(() {
        _debugOverride = id;
        _scanning = false;
        _speaking = false;
        _paused = false;
        _fail = _FailKind.none;
      }),
      onCancel: () => setState(() => _debugOverride = null),
    );
  }

  bool get _isSilent => _debugOverride == 'BT-19';
  bool get _isFontScale200 => _debugOverride == 'BT-18';
  bool get _hasExpired =>
      _completedAt != null && DateTime.now().difference(_completedAt!) > const Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final storageLow = context.watch<GlobalConditionsProvider>().isStorageLow;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    final banner = _resolveBanner(offline, storageLow);
    final hasBanner = banner != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: _cameraWithGuide(cam))
          else
            const ColoredBox(color: Colors.black),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.ocr, onDebugActivate: _openDebugSheet),
          ),

          if (_debugOverride == 'BT-22' || (cam.healthMessage != null && _debugOverride == null && !_scanning))
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 60,
              child: const Center(child: CameraHealthToast(issue: CameraHealthIssue.blurry)),
            ),

          if (!_hasCameraPermission)
            // BT-17 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk memotret tulisan yang ingin dibacakan.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else
            ..._buildContentZone(context, bottomInset, offline),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(onCameraPressed: _scan, cameraLabel: 'Baca teks'),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(bool offline, bool storageLow) {
    if (_debugOverride == 'BT-14') {
      return const StatusBanner(tier: AlertTier.critical, message: 'Server tidak bisa dihubungi. Bukan karena gambarmu.');
    }
    if (_fail == _FailKind.server) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Server tidak bisa dihubungi. Bukan karena gambarmu.');
    }
    if (_debugOverride == 'BT-10' || _partialRead) {
      return const StatusBanner(tier: AlertTier.warning, message: '2 dari 4 bagian terbaca. Bagian lain buram.', actionLabel: 'Foto ulang');
    }
    if (_debugOverride == 'BT-21' || storageLow) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Penyimpanan hampir penuh, pembacaan tetap berjalan');
    }
    if (_debugOverride == 'BT-05' || _nearTimeout) {
      return StatusBanner(tier: AlertTier.warning, message: 'Koneksi lambat, ${_elapsedSeconds}d…', actionLabel: 'Batalkan', onAction: () {
        _hardTimeoutTimer?.cancel();
        _elapsedTicker?.cancel();
        setState(() { _scanning = false; _nearTimeout = false; });
      });
    }
    if (_debugOverride != 'BT-02' && offline) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet, baca judul saja tetap bisa dipakai');
    }
    return null;
  }

  List<Widget> _buildContentZone(BuildContext context, double bottomInset, bool offline) {
    if (_debugOverride != null) return [_renderDebug(context, bottomInset, _debugOverride!)];

    if (_fail == _FailKind.offline) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Gambar tersimpan, akan dikirim ulang saat online.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.timeout) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Terlalu lama merespons. Foto tetap tersimpan.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.server) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Server tidak bisa dihubungi. Coba lagi.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.zeroText) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal.', failed: true, onRetry: _scan))];
    }

    if (_scanning) {
      return [const Center(child: CircularProgressIndicator(color: Colors.white))];
    }

    if (_hasExpired) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Hasil sudah lebih dari 15 menit. Foto ulang untuk membaca lagi.', failed: true, onRetry: _scan))];
    }

    if (_blocks.isEmpty) {
      return [
        Positioned(
          left: AppSpacing.screenMargin,
          right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 96 + AppSpacing.s3,
          child: FullScreenButton(
            label: 'Baca teks',
            icon: Icons.document_scanner_outlined,
            onTap: offline ? null : _scan,
            disabled: offline,
            disabledReason: offline ? 'Butuh internet untuk teks panjang' : null,
          ),
        ),
        if (offline)
          Positioned(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s3,
            child: Center(
              child: TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: Colors.white))),
            ),
          ),
      ];
    }

    final singleShort = _blocks.length == 1 && _blocks.first.ok && _blocks.first.sentences.length <= 2;
    if (singleShort) {
      final text = _blocks.first.sentences.join(' ');
      return [
        _bottomPanel(
          bottomInset,
          ResultPanel(
            text: text,
            speaking: _speaking,
            paused: _paused,
            onReplay: _replay,
            onTogglePlayback: _togglePause,
            secondaryLabel: 'Salin teks',
            onSecondary: _copy,
          ),
        ),
      ];
    }

    return [_bottomPanel(bottomInset, _renderLongPanel())];
  }

  Widget _renderLongPanel() {
    final activeBlocks = <OcrRenderBlock>[];
    var counted = 0;
    for (final b in _blocks) {
      final localActive = b.ok && _activeSentenceGlobal >= counted && _activeSentenceGlobal < counted + b.sentences.length
          ? _activeSentenceGlobal - counted
          : -1;
      activeBlocks.add(OcrRenderBlock(
        heading: b.heading, sentences: b.sentences, language: b.language, ok: b.ok, activeLocalIndex: localActive,
      ));
      if (b.ok) counted += b.sentences.length;
    }
    final totalSentences = _blocks.where((b) => b.ok).fold(0, (s, b) => s + b.sentences.length);
    final progress = totalSentences == 0 ? null : (_activeSentenceGlobal < 0 ? (_speaking || _paused ? 0.0 : null) : (_activeSentenceGlobal + 1) / totalSentences);

    if (_isSilent) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('HASIL BACA', style: AppTypography.eyebrow()),
              const SizedBox(height: AppSpacing.s3),
              for (final b in _blocks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: Text(b.ok ? b.sentences.join(' ') : 'Bagian ini tidak terbaca.',
                      style: AppTypography.body().copyWith(fontSize: 18, height: 26 / 18)),
                ),
            ],
          ),
        ),
      );
    }

    return OcrLongResultPanel(
      blocks: activeBlocks,
      speaking: _speaking,
      paused: _paused,
      progress: progress,
      muted: false,
      vertical: _isFontScale200,
      onTogglePlayback: _togglePause,
      onReplay: _replay,
      tertiaryLabel: (!_speaking && !_paused) ? 'Bicara ke Asisten' : null,
      onTertiary: _goToAssistant,
    );
  }

  Widget _bottomPanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin,
      right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }

  Widget _renderDebug(BuildContext context, double bottomInset, String id) {
    switch (id) {
      case 'BT-01':
        return Positioned(
          left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 96 + AppSpacing.s3,
          child: const FullScreenButton(label: 'Baca teks', icon: Icons.document_scanner_outlined),
        );
      case 'BT-02':
        return Positioned(
          left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s3,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const FullScreenButton(label: 'Baca teks', disabled: true, disabledReason: 'Butuh internet untuk teks panjang'),
            const SizedBox(height: AppSpacing.s3),
            TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: Colors.white))),
          ]),
        );
      case 'BT-03':
        return const Center(
          child: ColoredBox(color: Colors.white, child: SizedBox(width: double.infinity, height: double.infinity)),
        );
      case 'BT-04':
        return _bottomPanel(bottomInset, const ResultPanel(text: '', title: 'Membaca teks…'));
      case 'BT-06':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Salin teks', onSecondary: () {}));
      case 'BT-07':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockLongBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
          progress: 0.4, onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-08':
        return _bottomPanel(bottomInset, Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: AppSpacing.s3),
            decoration: BoxDecoration(color: AlertTier.warning.tintColor, borderRadius: AppRadius.card),
            child: Text('Dokumen ini panjang, perkiraan lebih dari 90 detik. Baca ringkasan, baca penuh, atau pilih bagian?',
                style: AppTypography.body(color: AlertTier.warning.labelColor)),
          ),
          OcrLongResultPanel(
            blocks: mockVeryLongBlocks().take(3).map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
            onTogglePlayback: () {}, onReplay: () {},
          ),
        ]));
      case 'BT-09':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockBilingualBlocks().map((b) => OcrRenderBlock(heading: b.heading, language: b.language, sentences: _splitSentences(b.text))).toList(),
          onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-10':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockPartialBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text), ok: b.ok)).toList(),
          onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-11':
        return _bottomPanel(bottomInset, ResultPanel(text: 'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal.', failed: true, onRetry: () {}));
      case 'BT-12a':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockLongBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
          paused: true, progress: 0.3, onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-12b':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Bicara ke Asisten', onSecondary: _goToAssistant));
      case 'BT-13':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Gambar tersimpan, akan dikirim ulang saat online.', failed: true));
      case 'BT-14':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Server tidak bisa dihubungi. Bukan karena gambarmu.', failed: true));
      case 'BT-15':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Terlalu lama merespons. Foto tetap tersimpan.', failed: true));
      case 'BT-16':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Bicara ke Asisten', onSecondary: _goToAssistant));
      case 'BT-19':
        return _renderLongPanelWithSentences(mockLongBlocks());
      case 'BT-20':
        return _bottomPanel(bottomInset, ResultPanel(text: 'Hasil sudah lebih dari 15 menit. Foto ulang untuk membaca lagi.', failed: true, onRetry: () {}));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _renderLongPanelWithSentences(List<OcrBlock> src) {
    _blocks = src.map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList();
    return _bottomPanel(0, _renderLongPanel());
  }

  Widget _cameraWithGuide(CameraProvider cam) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CameraPreview(cam.controller!)),
        Center(
          child: SizedBox(
            width: 280,
            height: 190,
            child: GuideFrame(fit: _scanning ? FrameFit.fit : FrameFit.empty),
          ),
        ),
      ],
    );
  }
}
```

---

## Berkas: `lib/screens/onboarding_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/onboarding_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

class _Step {
  final IconData icon;
  final String title;
  final String body;
  const _Step({required this.icon, required this.title, required this.body});
}

const _steps = [
  _Step(
    icon: Icons.remove_red_eye_outlined,
    title: 'Vinara melihat untukmu',
    body: 'Kamera membaca dunia di depanmu, Vinara menjelaskannya lewat suara dan getar.',
  ),
  _Step(
    icon: Icons.apps_rounded,
    title: 'Tiga tombol yang tidak pernah pindah',
    body: 'Ambil gambar, Bicara, dan Pilih mode selalu ada di posisi yang sama, di bawah layar.',
  ),
  _Step(
    icon: Icons.mic_none_rounded,
    title: 'Cukup bicara',
    body: 'Ucapkan nama mode atau perintah, Vinara langsung melompat ke sana. Menu hanya cadangan.',
  ),
];

/// OB-01..OB-07 — panduan awal 3 langkah. Bisa dilewati (OB-05, menyebut
/// apa yang dilewatkan) dan diulang dari Pengaturan (OB-06).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  /// True saat dipanggil ulang dari Pengaturan (OB-06) — menampilkan tombol
  /// kembali alih-alih alur pertama-kali.
  final bool fromSettings;

  const OnboardingScreen({super.key, required this.onDone, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _announce();
  }

  void _announce() {
    final step = _steps[_index];
    TTSService.instance.speak('${step.title}. ${step.body}');
  }

  void _next() {
    if (_index < _steps.length - 1) {
      setState(() => _index++);
      // Transisi 240ms, narasi ditunda (OB-04).
      Future.delayed(const Duration(milliseconds: 240), _announce);
    } else {
      _finish();
    }
  }

  void _skip() {
    final skipped = _steps.length - 1 - _index;
    TTSService.instance.speak(
      skipped > 0
          ? 'Panduan dilewati. Bisa diulang kapan saja dari Pengaturan.'
          : 'Panduan selesai.',
    );
    _finish();
  }

  void _finish() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    // OB-01..OB-07 — layar penunjang, memakai `zone/page-action`. "Lewati
    // panduan" (dan "Kembali ke Pengaturan" pada OB-06) adalah tombol sekunder
    // 56 dp tepat di atas primer, **tidak pernah di pojok kanan atas**: pojok
    // atas adalah zona merah thumb zone, butuh ganti pegangan.
    return PageActionScaffold(
      primaryLabel: isLast ? 'Mulai pakai Vinara' : 'Lanjut',
      onPrimary: _next,
      secondaryLabel: widget.fromSettings ? 'Kembali ke Pengaturan' : 'Lewati panduan',
      onSecondary: widget.fromSettings ? () => Navigator.of(context).pop() : _skip,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Column(
            children: [
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Column(
                  key: ValueKey(_index),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                        child: Icon(step.icon, size: 44, color: AppColors.actionLabel),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Semantics(
                      header: true,
                      // Eyebrow langkah dibaca sebagai bagian judul — bagian 10
                      // nomor 5, bukan simpul fokus tersendiri.
                      label: 'Langkah ${_index + 1} dari ${_steps.length}. ${step.title}',
                      child: ExcludeSemantics(
                        child: Text(step.title, textAlign: TextAlign.center, style: AppTypography.headline()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(step.body, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
                  ],
                ),
              ),
              const Spacer(),
              // Titik langkah: ExcludeSemantics wajib (bagian 16) — maknanya
              // sudah dibawa label judul di atas.
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (i) => Container(
                      width: i == _index ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.actionLabel : AppColors.surfaceSunk,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/permissions_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/permissions_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// IZ-01..IZ-07 — dua kartu alasan terpisah (kamera dulu, lalu mikrofon).
/// IZ-04: ditolak permanen dibacakan empat langkah bernomor, bertahap.
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionsScreen({super.key, required this.onDone});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

enum _Step { camera, microphone }

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  _Step _step = _Step.camera;
  bool _permanentlyDenied = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _announceStep();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // IZ-06 — kembali dari Pengaturan sistem, cek ulang status izin.
    if (state == AppLifecycleState.resumed && _permanentlyDenied) {
      _checkAfterSettingsReturn();
    }
  }

  Future<void> _checkAfterSettingsReturn() async {
    final granted = _step == _Step.camera
        ? await Permission.camera.isGranted
        : await Permission.microphone.isGranted;
    if (granted) {
      setState(() => _permanentlyDenied = false);
      await TTSService.instance.speak('Izin diberikan. Melanjutkan.');
      _advance();
    }
  }

  void _announceStep() {
    final label = _step == _Step.camera ? 'kamera' : 'mikrofon';
    TTSService.instance.speak('Vinara butuh izin $label untuk berfungsi.');
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    final permission = _step == _Step.camera ? Permission.camera : Permission.microphone;
    final status = await permission.request();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (status.isGranted) {
      await TTSService.instance.speak('Izin diberikan.');
      _advance();
    } else if (status.isPermanentlyDenied) {
      setState(() => _permanentlyDenied = true);
      // IZ-04 — empat langkah bernomor, dibacakan satu per satu, bertahap.
      await TTSService.instance.speak(
        'Izin ditolak permanen. Empat langkah untuk menyalakannya kembali. '
        'Langkah satu: buka Pengaturan ponsel.',
      );
    } else {
      await TTSService.instance.speak('Izin belum diberikan. Coba lagi kapan saja.');
    }
  }

  void _advance() {
    if (_step == _Step.camera) {
      setState(() {
        _step = _Step.microphone;
        _permanentlyDenied = false;
      });
      _announceStep();
    } else {
      widget.onDone();
    }
  }

  /// IZ-04 — dibacakan bertahap. Membacakan empat langkah sekaligus tidak
  /// mungkin diikuti.
  Future<void> _openSystemSettings(bool isCamera) async {
    await TTSService.instance.speak(
      'Langkah dua: cari menu Izin aplikasi. '
      'Langkah tiga: aktifkan izin ${isCamera ? 'Kamera' : 'Mikrofon'}. '
      'Langkah empat: kembali ke Vinara.',
    );
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isCamera = _step == _Step.camera;

    // IZ-01..IZ-04 — layar penunjang tanpa BottomActionBar, jadi seluruh
    // aksinya memakai `zone/page-action`: primer di dasar layar, sekunder 56 dp
    // tepat di atasnya. Kartu tetap di zona konten; perannya memberi tahu.
    if (_permanentlyDenied) {
      return PageActionScaffold(
        primaryLabel: 'Buka Pengaturan ponsel',
        primaryIcon: Icons.settings_outlined,
        onPrimary: () => _openSystemSettings(isCamera),
        secondaryLabel: 'Ulangi langkah ini',
        onSecondary: () => TTSService.instance.speak('Mengulangi langkah ini.'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
              child: _PermanentlyDeniedCard(label: isCamera ? 'kamera' : 'mikrofon'),
            ),
          ),
        ),
      );
    }

    return PageActionScaffold(
      primaryLabel: _requesting ? 'Meminta izin…' : 'Izinkan ${isCamera ? 'kamera' : 'mikrofon'}',
      primaryDisabled: _requesting,
      primaryDisabledReason: _requesting ? 'Menunggu jawabanmu' : null,
      onPrimary: _request,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
            child: PermissionCard(
              icon: isCamera ? Icons.camera_alt_outlined : Icons.mic_none_rounded,
              title: isCamera ? 'Izin kamera' : 'Izin mikrofon',
              reason: isCamera
                  ? 'Kamera dipakai untuk mendeteksi rintangan, membaca teks, mengenali uang, dan mencari barang.'
                  : 'Mikrofon dipakai untuk perintah suara dan Asisten Suara. Fitur lain tetap berjalan penuh tanpa mikrofon.',
            ),
          ),
        ),
      ),
    );
  }
}

/// IZ-04 — kartu penjelasan saja. Kedua tombolnya ("Buka Pengaturan ponsel",
/// "Ulangi langkah ini") dipasang pemanggil di `zone/page-action`.
class _PermanentlyDeniedCard extends StatelessWidget {
  final String label;

  const _PermanentlyDeniedCard({required this.label});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Buka Pengaturan ponsel',
      'Cari menu Izin aplikasi',
      'Aktifkan izin yang dibutuhkan',
      'Kembali ke Vinara',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, size: 34, color: AppColors.criticalLabel),
          const SizedBox(height: AppSpacing.s4),
          Text('Izin $label ditolak permanen', textAlign: TextAlign.center, style: AppTypography.title()),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Nyalakan lagi lewat Pengaturan ponsel, empat langkah:',
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.ink2),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}', style: AppTypography.caption(color: AppColors.actionLabel)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(child: Text(steps[i], style: AppTypography.body())),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/server_address_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/server_address_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// PG-08a..PG-08e — Alamat server, halaman sendiri (PG-02: "halaman kontrol
/// sendiri, bukan sheet").
///
/// Dulu kontrol ini adalah satu baris di dalam daftar Pengaturan, dengan
/// tombol "Uji" menempel di samping kolom isian — di sepertiga atas layar,
/// zona merah thumb zone. Sekarang aksinya memakai `zone/page-action`.
///
/// **Tombolnya tidak pernah berpindah saat pesan hasil berganti.** Target yang
/// bergeser sesudah aksi adalah pola yang paling membingungkan untuk pengguna
/// yang tidak melihat: mereka menghafal posisi, menekan, lalu menemukan
/// tombolnya sudah pindah. Karena itu tinggi zona tetap di seluruh lima state,
/// dan hanya labelnya yang berubah.
class ServerAddressScreen extends StatefulWidget {
  const ServerAddressScreen({super.key});

  @override
  State<ServerAddressScreen> createState() => _ServerAddressScreenState();
}

/// PG-08a idle · PG-08b sedang diuji · PG-08c valid & terhubung ·
/// PG-08d format tidak valid · PG-08e gagal terhubung.
enum ServerFieldState { idle, testing, valid, invalid, failed }

class _ServerAddressScreenState extends State<ServerAddressScreen> {
  late final TextEditingController _ctrl;
  late final String _savedHost;
  ServerFieldState _state = ServerFieldState.idle;
  int? _latencyMs;

  static final _hostPattern = RegExp(r'^[\w.-]+:\d{2,5}$');

  @override
  void initState() {
    super.initState();
    _savedHost = context.read<SettingsProvider>().serverHost;
    _ctrl = TextEditingController(text: _savedHost);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final host = _ctrl.text.trim();

    // PG-08d — sebutkan apa yang salah, bukan "tidak valid" saja.
    if (!_hostPattern.hasMatch(host)) {
      setState(() {
        _state = ServerFieldState.invalid;
        _latencyMs = null;
      });
      await TTSService.instance.speak(
        'Format alamat salah. Alamat butuh titik dua dan nomor port. Contoh benar: 10.0.2.2 titik dua 8000.',
      );
      return;
    }

    setState(() {
      _state = ServerFieldState.testing;
      _latencyMs = null;
    });

    // GET /health ke alamat KANDIDAT, tanpa mengubah alamat aktif. PG-08e
    // mensyaratkan alamat lama tetap dipakai kalau uji gagal, jadi alamat
    // aktif hanya berpindah lewat "Simpan alamat" sesudah uji berhasil.
    final result = await ServerService.instance.healthAt(host);
    if (!mounted) return;

    if (result != null) {
      final ms = (result['round_trip_ms'] as num?)?.round() ?? 0;
      setState(() {
        _state = ServerFieldState.valid;
        _latencyMs = ms;
      });
      await TTSService.instance.speak(
        'Terhubung. Waktu tempuh $ms milidetik. Tekan Simpan alamat untuk memakainya.',
      );
    } else {
      // PG-08e — kegagalan uji tidak boleh diam-diam mencabut server yang
      // sebenarnya masih bekerja.
      setState(() {
        _state = ServerFieldState.failed;
        _latencyMs = null;
      });
      await TTSService.instance.speak(
        'Gagal terhubung. Alamat lama, $_savedHost, tetap dipakai. Periksa alamatnya lalu uji lagi.',
      );
    }
  }

  Future<void> _save() async {
    final host = _ctrl.text.trim();
    await context.read<SettingsProvider>().setServerHost(host);
    if (!mounted) return;
    // Konfirmasi diucapkan SESUDAH tersimpan — bagian 4.1 berlaku untuk semua
    // konfirmasi, bukan hanya ganti mode.
    await TTSService.instance.speak('Alamat server tersimpan.');
    if (mounted) Navigator.of(context).pop();
  }

  /// Label tombol utama berubah, posisinya tidak. PG-08c satu-satunya state
  /// yang aksinya "Simpan alamat" — alamat baru hanya dipakai sesudah terbukti
  /// bisa dihubungi.
  String get _primaryLabel => switch (_state) {
        ServerFieldState.testing => 'Menguji koneksi…',
        ServerFieldState.valid => 'Simpan alamat',
        ServerFieldState.failed => 'Uji lagi',
        _ => 'Uji koneksi',
      };

  ({String text, Color color, IconData icon})? get _result => switch (_state) {
        ServerFieldState.valid => (
            text: 'Terhubung. Waktu tempuh ${_latencyMs ?? 0} ms.',
            color: AppColors.positiveLabel,
            icon: Icons.check_circle_outline_rounded,
          ),
        ServerFieldState.invalid => (
            text: 'Format salah — alamat butuh titik dua dan nomor port. Contoh benar: 10.0.2.2:8000',
            color: AppColors.criticalLabel,
            icon: Icons.error_outline_rounded,
          ),
        ServerFieldState.failed => (
            text: 'Gagal terhubung. Alamat lama ($_savedHost) tetap dipakai.',
            color: AppColors.criticalLabel,
            icon: Icons.cloud_off_rounded,
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return PageActionScaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Alamat server')),
      primaryLabel: _primaryLabel,
      primaryDisabled: _state == ServerFieldState.testing,
      primaryDisabledReason: _state == ServerFieldState.testing ? 'Menunggu jawaban server' : null,
      onPrimary: _state == ServerFieldState.valid ? _save : _test,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.s4,
          AppSpacing.screenMargin,
          AppSpacing.s4,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.cardInner,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  headingLevel: 2,
                  child: Text('Alamat server', style: AppTypography.bodyStrong()),
                ),
                const SizedBox(height: AppSpacing.s1),
                // PG-08a — penjelasan server bawaan.
                Text(
                  'Vinara memakai server bawaan untuk Baca Teks, Asisten Suara, Cari Objek, dan segmentasi jalur. '
                  'Ganti alamat ini hanya kalau kamu menjalankan server sendiri.',
                  style: AppTypography.body(color: AppColors.ink2),
                ),
                const SizedBox(height: AppSpacing.s4),
                Semantics(
                  sortKey: const OrdinalSortKey(8),
                  textField: true,
                  label: 'Alamat server, isi dengan host dan port',
                  child: TextField(
                    controller: _ctrl,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'host:port, mis. 10.0.2.2:8000',
                      isDense: true,
                    ),
                    style: AppTypography.metricMono(),
                    onChanged: (_) {
                      // Isian berubah → hasil lama tidak berlaku lagi. Tanpa
                      // ini, "Simpan alamat" bisa menyimpan alamat yang belum
                      // pernah diuji.
                      if (_state != ServerFieldState.idle) {
                        setState(() {
                          _state = ServerFieldState.idle;
                          _latencyMs = null;
                        });
                      }
                    },
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Semantics(
                    liveRegion: true,
                    label: result.text,
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(result.icon, size: 18, color: result.color),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: Text(result.text, style: AppTypography.caption(color: result.color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/settings_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import 'onboarding_screen.dart';
import 'server_address_screen.dart';

/// PG-01..PG-11 — delapan pengaturan, urutan baku (bagian 13).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// PG-11 — penyimpanan penuh. Kartu error tetap di atas karena perannya
  /// memberi tahu, tapi aksinya **diulang di dasar layar**: aksi yang hanya
  /// ada di kartu atas memaksa pengguna low vision menjangkau zona merah.
  Future<void> _manageStorage() async {
    await TTSService.instance.speak(
      'Membuka Pengaturan ponsel. Cari menu Penyimpanan, lalu hapus cache Vinara.',
    );
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final storageLow = context.watch<GlobalConditionsProvider>().isStorageLow;

    final list = ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        children: [
          if (storageLow) const _StorageFullCard(),
          _SettingsRow(
            title: 'Kecepatan bicara TTS',
            value: '${(settings.speechRate * 200).round()}%',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.speechRate,
                    min: 0.25,
                    max: 1.0,
                    onChanged: (v) => context.read<SettingsProvider>().setSpeechRate(v),
                  ),
                ),
                TextButton(
                  onPressed: () => TTSService.instance.speak(
                    'Motor di sebelah kanan atas, sekitar dua koma delapan meter.',
                  ),
                  child: const Text('Coba dengar'),
                ),
              ],
            ),
          ),
          _SettingsRow(
            title: 'Tingkat kecerewetan',
            value: _verbosityLabel(settings.verbosity),
            child: SegmentedButton<Verbosity>(
              segments: const [
                ButtonSegment(value: Verbosity.ringkas, label: Text('Ringkas')),
                ButtonSegment(value: Verbosity.sedang, label: Text('Sedang')),
                ButtonSegment(value: Verbosity.detail, label: Text('Detail')),
              ],
              selected: {settings.verbosity},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setVerbosity(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Getar',
            value: _vibrationLabel(settings.vibrationMode),
            child: SegmentedButton<VibrationMode>(
              segments: const [
                ButtonSegment(value: VibrationMode.active, label: Text('Aktif')),
                ButtonSegment(value: VibrationMode.criticalOnly, label: Text('Critical saja')),
                ButtonSegment(value: VibrationMode.off, label: Text('Mati')),
              ],
              selected: {settings.vibrationMode},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setVibrationMode(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Ambang jarak peringatan',
            value: '${settings.distanceThresholdM.toStringAsFixed(1)} m',
            child: Slider(
              value: settings.distanceThresholdM,
              min: 1,
              max: 5,
              divisions: 8,
              label: '${settings.distanceThresholdM.toStringAsFixed(1)} m',
              onChanged: (v) => context.read<SettingsProvider>().setDistanceThreshold(v),
            ),
          ),
          _SettingsRow(
            title: 'Tema',
            value: _themeLabel(settings.themeMode),
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.light, label: Text('Terang')),
                ButtonSegment(value: AppThemeMode.dark, label: Text('Gelap')),
                ButtonSegment(value: AppThemeMode.highContrast, label: Text('Kontras tinggi')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setThemeMode(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Ukuran teks',
            value: '${(settings.fontScale * 100).round()}%',
            child: Slider(
              value: settings.fontScale,
              min: 1.0,
              max: 2.0,
              divisions: 4,
              label: '${(settings.fontScale * 100).round()}%',
              onChanged: (v) => context.read<SettingsProvider>().setFontScale(v),
            ),
          ),
          _SettingsRow(
            title: 'Ulangi panduan awal',
            value: null,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(fromSettings: true, onDone: () {}),
                ),
              ),
              child: const Text('Mulai panduan'),
            ),
          ),
          // PG-08 — halaman kontrol sendiri, bukan kontrol inline. Aksinya
          // ("Uji koneksi" / "Simpan alamat") butuh `zone/page-action`, dan
          // zona itu tidak bisa hadir di tengah daftar.
          _SettingsRow(
            title: 'Alamat server',
            value: settings.serverHost,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerAddressScreen()),
              ),
              child: const Text('Ubah alamat server'),
            ),
          ),
        ],
      );

    // PG-11 — selama penyimpanan penuh, aksinya diulang di `zone/page-action`
    // supaya terjangkau tanpa menggulung dan tanpa menjangkau kartu di atas.
    // Di luar kondisi itu Pengaturan tidak punya aksi halaman, jadi tidak ada
    // zona aksi sama sekali — daftar boleh memenuhi layar.
    if (storageLow) {
      return PageActionScaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(title: const Text('Pengaturan')),
        primaryLabel: 'Kelola penyimpanan',
        primaryIcon: Icons.folder_open_rounded,
        onPrimary: _manageStorage,
        body: list,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: list,
    );
  }

  String _verbosityLabel(Verbosity v) => switch (v) {
        Verbosity.ringkas => 'Ringkas',
        Verbosity.sedang => 'Sedang',
        Verbosity.detail => 'Detail',
      };

  String _vibrationLabel(VibrationMode m) => switch (m) {
        VibrationMode.active => 'Aktif',
        VibrationMode.criticalOnly => 'Hanya Critical',
        VibrationMode.off => 'Mati',
      };

  String _themeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.light => 'Terang',
        AppThemeMode.dark => 'Gelap',
        AppThemeMode.highContrast => 'Kontras tinggi',
      };
}

/// PG-11 — kartu error penyimpanan penuh. Tetap di atas: perannya memberi
/// tahu, dan pemberitahuan harus terbaca lebih dulu. Aksinya diulang di
/// `zone/page-action` oleh [SettingsScreen], bukan hanya ada di sini.
class _StorageFullCard extends StatelessWidget {
  const _StorageFullCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Penyimpanan hampir penuh. Pengaturan baru mungkin gagal disimpan '
          'dan nilai lama akan tetap dipakai. Tombol Kelola penyimpanan ada di dasar layar.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin, AppSpacing.s1, AppSpacing.screenMargin, AppSpacing.s3,
          ),
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: const BoxDecoration(
            color: AppColors.warningTint,
            borderRadius: AppRadius.cardInner,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sd_storage_outlined, size: 22, color: AppColors.warningLabel),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penyimpanan hampir penuh',
                        style: AppTypography.bodyStrong(color: AppColors.warningLabel)),
                    const SizedBox(height: 2),
                    Text(
                      'Pengaturan baru mungkin gagal disimpan, dan nilai lama akan tetap dipakai.',
                      style: AppTypography.caption(color: AppColors.warningLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? value;
  final Widget child;

  const _SettingsRow({required this.title, required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: value == null ? title : '$title, $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.s1),
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.cardInner,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppTypography.bodyStrong())),
                if (value != null) Text(value!, style: AppTypography.label(color: AppColors.ink2)),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            child,
          ],
        ),
      ),
    );
  }
}

```

---

## Berkas: `lib/screens/splash_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/splash_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';

/// SP-01 — Splash. Logo tampil, narasi TTS mulai di milidetik pertama,
/// durasi maksimum 900 ms sebelum lanjut ke langkah berikutnya.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    TTSService.instance.speak('Vinara. Menyiapkan…');
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink1,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.actionFill, shape: BoxShape.circle),
              child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text('Vinara', style: AppTypography.headline(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/tuntun_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/tuntun_screen.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../models/detection.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Deteksi Objek — bagian 7 IMPLEMENTASI.md, 29 state (DO-01..DO-29).
/// Kamera, TFLite/server, filter kestabilan, dan SORT tracker SUDAH nyata
/// lewat [DetectionProvider]. State yang tak bisa dipicu dari kondisi nyata
/// (multi-objek serentak, kelas tak dikenal, dst.) dicapai lewat panel debug
/// (ketuk 5× ModeBadge), sesuai bagian 2 "boleh dipalsukan".
class TuntunScreen extends StatefulWidget {
  const TuntunScreen({super.key});

  @override
  State<TuntunScreen> createState() => _TuntunScreenState();
}

class _GhostDetection {
  final Detection detection;
  _GhostDetection(this.detection);
}

const List<(String, String)> _doDebugCatalog = [
  ('DO-06', 'Deteksi ganda (critical + warning)'),
  ('DO-07', 'Empat objek sekaligus'),
  ('DO-13', 'Model warm-up'),
  ('DO-15', 'Izin kamera dicabut saat jalan'),
  ('DO-19', 'Kelas objek tidak dikenal'),
  ('DO-20', 'Objek critical menghilang (fade)'),
  ('DO-21', 'Jarak tidak bisa diperkirakan'),
  ('DO-22', 'Ponsel panas'),
  ('DO-23', 'Antrean suara menumpuk'),
  ('DO-24', 'Izin mikrofon dicabut'),
  ('DO-25', 'Penyimpanan penuh'),
  ('DO-26', 'Senyap / TTS mati'),
  ('DO-29', 'Verbositas lengkap (3 pemakaian pertama)'),
];

class _TuntunScreenState extends State<TuntunScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = true;
  bool _hasMicPermission = true;
  bool _warmingUp = true;
  bool _speaking = false;
  bool _silentMode = false;
  String? _debugOverride;

  final List<_GhostDetection> _ghosts = [];
  List<Detection> _prevCritical = [];

  Timer? _warmupTimer;
  Timer? _speakingPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.tuntun);
      if (_hasCameraPermission) {
        context.read<DetectionProvider>().startRealtime();
        context.read<CameraProvider>().startStream();
      }
    });

    _warmupTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _warmingUp = false);
    });

    _speakingPoll = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final s = TTSService.instance.isSpeaking;
      if (s != _speaking && mounted) setState(() => _speaking = s);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _warmupTimer?.cancel();
    _speakingPoll?.cancel();
    context.read<DetectionProvider>().stopRealtime();
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // DO-18 — kembali dari latar belakang.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      if (mounted) {
        setState(() => _warmingUp = true);
        context.read<CameraProvider>().startStream();
        _warmupTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _warmingUp = false);
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    final cam = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    if (!mounted) return;
    final camChanged = cam != _hasCameraPermission;
    setState(() {
      _hasCameraPermission = cam;
      _hasMicPermission = mic;
    });
    if (camChanged && cam) {
      final camProvider = context.read<CameraProvider>();
      if (!camProvider.isInitialized) await camProvider.initCamera();
      camProvider.startStream();
      context.read<DetectionProvider>().startRealtime();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      cam.startStream();
      context.read<DetectionProvider>().startRealtime();
    }
  }

  void _updateGhosts(List<Detection> current) {
    final currentCritical = current.where((d) => d.isCritical).toList();
    for (final prev in _prevCritical) {
      final stillThere = currentCritical.any((d) => d.labelEn == prev.labelEn && d.direction == prev.direction);
      final alreadyGhost = _ghosts.any((g) => g.detection.labelEn == prev.labelEn && g.detection.direction == prev.direction);
      if (!stillThere && !alreadyGhost) {
        final ghost = _GhostDetection(prev);
        _ghosts.add(ghost);
        // DO-20 — memudar tanpa suara "objek hilang", dibersihkan setelah animasi.
        Timer(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _ghosts.remove(ghost));
        });
      }
    }
    _prevCritical = currentCritical;
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugSheet(
        current: _debugOverride,
        onSelect: (id) {
          Navigator.pop(sheetCtx);
          setState(() {
            _debugOverride = id;
            _silentMode = id == 'DO-26';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final det = context.watch<DetectionProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    var dets = det.detections;
    if (_debugOverride == 'DO-06') dets = _mockDouble;
    if (_debugOverride == 'DO-07') dets = _mockQuad;
    if (_debugOverride == 'DO-19') dets = _mockUnknownClass;
    if (_debugOverride != 'DO-06' && _debugOverride != 'DO-07' && _debugOverride != 'DO-19') {
      _updateGhosts(dets);
    }

    final rz = det.riskZone;
    final banner = _resolveBanner(global, cam, rz);
    final hasBanner = banner != null;
    final warmingUp = _warmingUp || _debugOverride == 'DO-13';
    final micDisabled = !_hasMicPermission || _debugOverride == 'DO-24';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.tuntun, busy: warmingUp, onDebugActivate: _openDebugSheet),
          ),

          if (_speaking && !warmingUp)
            Positioned(
              top: topInset + 52,
              right: 24,
              child: SpeakingIndicator(silent: _silentMode),
            ),

          if (!_hasCameraPermission)
            // DO-14 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mendeteksi rintangan di depanmu tanpa internet.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestCameraPermission,
            )
          else if (!warmingUp)
            ..._buildDetectionZone(context, bottomInset, dets, cam),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(micEnabled: !micDisabled),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(GlobalConditionsProvider global, CameraProvider cam, dynamic rz) {
    if (_debugOverride == 'DO-15') {
      return const StatusBanner(tier: AlertTier.critical, message: 'Izin kamera dicabut. Deteksi berhenti sampai izin dinyalakan lagi.');
    }
    if (_debugOverride == 'DO-22') {
      return const StatusBanner(tier: AlertTier.warning, message: 'Ponsel panas, laju deteksi diturunkan');
    }
    if (_debugOverride == 'DO-25') {
      return const StatusBanner(tier: AlertTier.warning, message: 'Penyimpanan hampir penuh, deteksi tetap jalan');
    }
    if (_debugOverride == 'DO-23') {
      return const StatusBanner(tier: AlertTier.info, message: 'Antrean suara menumpuk, info dibuang');
    }
    final merged = global.merged;
    if (merged != null) {
      return StatusBanner(tier: merged.tier, message: merged.message, actionLabel: merged.actionLabel);
    }
    return null;
  }

  List<Widget> _buildDetectionZone(BuildContext context, double bottomInset, List<Detection> dets, CameraProvider cam) {
    final widgets = <Widget>[];

    if (_debugOverride == 'DO-21') {
      widgets.add(_bottomSlot(bottomInset, const AlertCard(
        tier: AlertTier.info,
        title: 'Ada objek di depan',
        description: 'Jarak tidak bisa diperkirakan, tetap waspada',
      )));
      return widgets;
    }

    final health = cam.healthMessage;
    if (health != null && dets.isEmpty && _debugOverride == null) {
      widgets.add(Positioned(
        left: 0, right: 0,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 44,
        child: Center(child: CameraHealthToast(issue: _mapHealthIssue(health))),
      ));
    }

    final cards = dets.map((d) => DetectionCard(detection: d)).toList();
    final extra = dets.length - 2;

    if (cards.isNotEmpty || _ghosts.isNotEmpty) {
      widgets.add(Positioned(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in _ghosts) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 900),
                builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
                child: DetectionCard(detection: g.detection),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            if (cards.isNotEmpty) AlertCardStack(cards: cards),
            if (extra > 0) ...[
              const SizedBox(height: AppSpacing.s2),
              Semantics(
                liveRegion: true,
                label: 'dan $extra objek lain',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
                  child: Text('dan $extra objek lain', style: AppTypography.caption(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ));
    }

    return widgets;
  }

  CameraHealthIssue _mapHealthIssue(String message) {
    if (message.contains('gelap')) return CameraHealthIssue.dark;
    if (message.contains('menutupi')) return CameraHealthIssue.covered;
    if (message.contains('tegak') || message.contains('depan')) return CameraHealthIssue.tilted;
    return CameraHealthIssue.blurry;
  }

  Widget _bottomSlot(double bottomInset, Widget child) => Positioned(
        left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
        child: child,
      );

  static final _mockDouble = [
    const Detection(labelEn: 'person', labelId: 'orang', confidence: .9, distanceMeter: .8, direction: 'depan', dangerLevel: 'critical', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'motorcycle', labelId: 'motor', confidence: .8, distanceMeter: 1.6, direction: 'kanan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
  ];

  static final _mockQuad = [
    const Detection(labelEn: 'person', labelId: 'orang', confidence: .9, distanceMeter: .7, direction: 'depan', dangerLevel: 'critical', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'motorcycle', labelId: 'motor', confidence: .8, distanceMeter: 1.4, direction: 'kanan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'chair', labelId: 'kursi', confidence: .7, distanceMeter: 2.3, direction: 'kiri', dangerLevel: 'info', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'bicycle', labelId: 'sepeda', confidence: .6, distanceMeter: 3.1, direction: 'depan', dangerLevel: 'info', bbox: {}, inferenceMs: 12),
  ];

  static final _mockUnknownClass = [
    const Detection(labelEn: 'unknown', labelId: '', confidence: .6, distanceMeter: 1.8, direction: 'depan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
  ];
}

class _DebugSheet extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onSelect;
  const _DebugSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
            Text('Debug — Mode Deteksi Objek', style: AppTypography.title()),
            const SizedBox(height: 4),
            Text('DO-01..05,08..12,14,16..18,27,28 sudah tercapai lewat kamera/izin/koneksi nyata',
                textAlign: TextAlign.center, style: AppTypography.caption()),
            const SizedBox(height: AppSpacing.s3),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('Kembali ke mode nyata'), onTap: () => onSelect(null)),
                  for (final entry in _doDebugCatalog)
                    ListTile(
                      leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                      title: Text(entry.$2),
                      selected: entry.$1 == current,
                      onTap: () => onSelect(entry.$1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/screens/voice_screen.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/voice_screen.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import 'settings_screen.dart';

const List<(String, String)> _asDebugCatalog = [
  ('AS-05', 'Terlalu berisik'),
  ('AS-07', 'Transkrip gagal'),
  ('AS-13', 'Delapan giliran (riwayat diringkas)'),
  ('AS-16', 'Offline'),
  ('AS-21', 'Senyap / TTS mati'),
  ('AS-23', 'Riwayat kedaluwarsa'),
  ('AS-24', 'Izin kamera dicabut'),
  ('AS-25', 'Critical menyela jawaban'),
];

/// Mode Asisten Suara — bagian 11 IMPLEMENTASI.md, 25 state (AS-01..AS-25).
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with WidgetsBindingObserver {
  bool _hasMicPermission = true;
  bool _hasCameraPermission = true;
  String? _debugOverride;
  bool _silentMode = false;
  bool _longAnswerOffer = false;
  Timer? _longAnswerTimer;
  Timer? _expiryCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.voice);
      final voice = context.read<VoiceProvider>();

      if (voice.checkAndExpireHistory()) {
        // AS-23 — riwayat kedaluwarsa, sudah dibersihkan oleh provider.
        context.read<TtsProvider>().speak('Percakapan tadi sudah saya hapus.', tier: SpeechTier.info);
      }

      voice.onSpeak = (text) => context.read<TtsProvider>().speak(text, tier: SpeechTier.info);
      voice.onOpenSettings = _openSettings;
      voice.onAllFeaturesFailed = () {};
    });

    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _longAnswerTimer?.cancel();
    _expiryCheckTimer?.cancel();
    final voice = context.read<VoiceProvider>();
    voice.onSpeak = null;
    voice.onOpenSettings = null;
    voice.onAllFeaturesFailed = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.isGranted;
    final cam = await Permission.camera.isGranted;
    if (!mounted) return;
    setState(() {
      _hasMicPermission = mic;
      _hasCameraPermission = cam;
    });
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (status.isGranted) setState(() => _hasMicPermission = true);
  }

  /// `mode.settings` — Pengaturan layar penunjang, bukan mode. Mengembalikan
  /// true hanya kalau halamannya benar-benar terdorong ke Navigator, supaya
  /// VoiceProvider tidak mengonfirmasi pembukaan yang tidak terjadi.
  Future<bool> _openSettings() async {
    if (!mounted) return false;
    // Rute sudah masuk tumpukan begitu `push` dipanggil; Future-nya baru
    // selesai saat halaman DITUTUP, jadi ia sengaja tidak ditunggu — kalau
    // ditunggu, konfirmasinya baru terdengar setelah pengguna keluar lagi.
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ));
    return true;
  }

  Future<void> _onMicPressed() async {
    final voice = context.read<VoiceProvider>();
    setState(() => _debugOverride = null);
    if (voice.isListening) {
      await voice.stopListening();
    } else if (voice.state == VoiceState.responded) {
      // AS-20 — menekan lagi saat masih bicara: potong tanpa nada khusus.
      await voice.interruptAndListenAgain();
    } else {
      await voice.startListening();
    }
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                  decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
              Text('Debug — Mode Asisten Suara', style: AppTypography.title()),
              const SizedBox(height: 4),
              Text('AS-01..04,06,08..12,14,15,17..20,22 tercapai lewat alur bicara nyata',
                  textAlign: TextAlign.center, style: AppTypography.caption()),
              const SizedBox(height: AppSpacing.s3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(title: const Text('Kembali'), onTap: () {
                      Navigator.pop(sheetCtx);
                      setState(() { _debugOverride = null; _silentMode = false; });
                    }),
                    for (final entry in _asDebugCatalog)
                      ListTile(
                        leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                        title: Text(entry.$2),
                        selected: entry.$1 == _debugOverride,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          setState(() {
                            _debugOverride = entry.$1;
                            _silentMode = entry.$1 == 'AS-21';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final cam = context.watch<CameraProvider>();
    final det = context.watch<DetectionProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // AS-25 — Critical dari mode lain menyela jawaban yang sedang dibacakan.
    if (voice.state == VoiceState.responded && det.detections.any((d) => d.isCritical) && !_hasCameraPermission == false) {
      final critical = det.detections.firstWhere((d) => d.isCritical);
      context.read<TtsProvider>().speak(critical.ttsMessage, tier: SpeechTier.critical);
    }

    if (voice.state == VoiceState.responded && !_longAnswerOffer && voice.response.length > 220) {
      _longAnswerTimer?.cancel();
      _longAnswerTimer = Timer(const Duration(seconds: 20), () {
        if (mounted && voice.state == VoiceState.responded) setState(() => _longAnswerOffer = true);
      });
    }
    if (voice.state != VoiceState.responded && _longAnswerOffer) {
      _longAnswerOffer = false;
    }

    final banner = _resolveBanner(global);
    final hasBanner = banner != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.voice, onDebugActivate: _openDebugSheet),
          ),

          if (voice.state == VoiceState.responded && !_silentMode)
            Positioned(top: topInset + 52, right: 24, child: const SpeakingIndicator()),

          if (!_hasMicPermission && _debugOverride == null)
            // AS-02 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.mic_none_rounded,
              title: 'Izin mikrofon',
              reason: 'Mikrofon dipakai untuk mendengarkan pertanyaanmu. Mode lain tetap berfungsi tanpa izin ini.',
              actionLabel: 'Izinkan mikrofon',
              onAction: _requestMicPermission,
            )
          else
            ..._buildContent(context, voice, bottomInset),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              onMicPressed: _onMicPressed,
              micEnabled: _hasMicPermission,
              listeningOverride: voice.isListening,
              processingOverride: voice.isProcessing,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(GlobalConditionsProvider global) {
    if (_debugOverride == 'AS-16' || global.isOffline) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet');
    }
    return null;
  }

  List<Widget> _buildContent(BuildContext context, VoiceProvider voice, double bottomInset) {
    if (_debugOverride == 'AS-24' || (!_hasCameraPermission && _debugOverride == null)) {
      return [_bubblePanel(bottomInset, const _StaticNotice(text: 'Izin kamera dicabut. Saya masih bisa menjawab pertanyaan yang tidak butuh penglihatan atau ganti mode.'))];
    }
    if (_debugOverride == 'AS-16') {
      return [_bubblePanel(bottomInset, const _StaticNotice(
        text: 'Tanpa internet. Masih bisa: ganti mode, deteksi objek, kenali uang.',
      ))];
    }
    if (_debugOverride == 'AS-05') {
      return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const VoiceOrb(state: VoiceOrbState.failure),
        const SizedBox(height: AppSpacing.s3),
        _pill('Terlalu berisik, dekatkan ponsel ke mulutmu'),
      ]))];
    }
    if (_debugOverride == 'AS-07') {
      return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const VoiceOrb(state: VoiceOrbState.failure),
        const SizedBox(height: AppSpacing.s3),
        _pill('Belum jelas. Coba: "kenali uang" atau "baca teks"'),
      ]))];
    }
    if (_debugOverride == 'AS-13') {
      return [_bubblePanel(bottomInset, _mockHistoryTranscript())];
    }
    if (_debugOverride == 'AS-23') {
      return [_bubblePanel(bottomInset, const _StaticNotice(text: 'Percakapan tadi sudah saya hapus.'))];
    }
    if (_debugOverride == 'AS-25') {
      return [_bubblePanel(bottomInset, const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ChatBubble(speaker: ChatSpeaker.vinara, text: 'Di depanmu ada meja panjang, lalu di sebelah kanan ada...', isLatest: true),
        AlertCard(tier: AlertTier.critical, title: 'Orang! Di depan, kurang dari satu meter', distanceMeter: .8),
      ]))];
    }

    switch (voice.state) {
      case VoiceState.idle:
        return [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const VoiceOrb(state: VoiceOrbState.idle),
              const SizedBox(height: AppSpacing.s4),
              _pill('Ketuk lalu bicara'),
            ]),
          ),
        ];
      case VoiceState.listening:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.listening))];
      case VoiceState.noSpeech:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s3),
          _pill('Belum terdengar apa pun'),
        ]))];
      case VoiceState.tooNoisy:
        return [Center(child: _pill('Terlalu berisik, dekatkan ponsel ke mulutmu'))];
      case VoiceState.transcribing:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.processing))];
      case VoiceState.transcribeFailed:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s3),
          _pill('Belum jelas. Coba: "kenali uang" atau "baca teks"'),
        ]))];
      case VoiceState.processingLocal:
      case VoiceState.processingLlm:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.processing))];
      case VoiceState.fallbackActive:
      case VoiceState.allFailed:
      case VoiceState.responded:
      case VoiceState.unrecognized:
      case VoiceState.ambiguous:
        return [_bubblePanel(bottomInset, _historyTranscript(voice))];
    }
  }

  Widget _historyTranscript(VoiceProvider voice) {
    if (_silentMode) {
      // AS-21 — senyap: seluruh jawaban ditampilkan penuh.
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
        child: Text(voice.response, style: AppTypography.body().copyWith(fontSize: 18, height: 26 / 18)),
      );
    }

    final history = voice.history;
    final recent = history.length > 8 ? history.sublist(history.length - 6) : history;
    final summarizedCount = history.length - recent.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summarizedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Text('$summarizedCount giliran sebelumnya diringkas. Ucapkan "ulangi" untuk dengar lagi.',
                  style: AppTypography.caption()),
            ),
          ChatTranscript(
            turns: [
              for (var i = 0; i < recent.length; i++)
                ChatBubble(
                  speaker: recent[i].isUser ? ChatSpeaker.user : ChatSpeaker.vinara,
                  text: recent[i].text,
                  isLatest: i == recent.length - 1 && !recent[i].isUser,
                ),
            ],
          ),
          if (_longAnswerOffer) ...[
            const SizedBox(height: AppSpacing.s2),
            TextButton(onPressed: () {}, child: const Text('Ringkas saja?')),
          ],
        ],
      ),
    );
  }

  Widget _mockHistoryTranscript() {
    final mock = [
      ChatTurn(isUser: true, text: 'ada apa di depan'),
      ChatTurn(isUser: false, text: 'Ada meja dan dua kursi di depanmu.'),
      ChatTurn(isUser: true, text: 'kenali uang'),
      ChatTurn(isUser: false, text: 'Baik, mode Kenali Uang.'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4 giliran sebelumnya diringkas. Ucapkan "ulangi" untuk dengar lagi.', style: AppTypography.caption()),
          const SizedBox(height: AppSpacing.s3),
          ChatTranscript(turns: [
            for (var i = 0; i < mock.length; i++)
              ChatBubble(speaker: mock[i].isUser ? ChatSpeaker.user : ChatSpeaker.vinara, text: mock[i].text, isLatest: i == mock.length - 1),
          ]),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Text(text, style: AppTypography.body(color: Colors.white)),
      ),
    );
  }

  Widget _bubblePanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }
}

class _StaticNotice extends StatelessWidget {
  final String text;
  const _StaticNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
        child: Text(text, style: AppTypography.body()),
      ),
    );
  }
}
```

---

## Berkas: `lib/services/camera_health_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/camera_health_service.dart`

```dart
import 'dart:async';
import 'dart:math'; // untuk atan2()
import 'package:sensors_plus/sensors_plus.dart';

class CameraHealthResult {
  final bool   ok;
  final String message;
  const CameraHealthResult({required this.ok, required this.message});
}

/// Camera Health Service — cek orientasi kamera via accelerometer.
/// Pengecekan gelap/buram/tertutup dilakukan di server (camera_health.py)
/// dan secara on-device di CameraProvider (brightness dari plane Y).
class CameraHealthService {
  static final CameraHealthService instance = CameraHealthService._();
  CameraHealthService._();

  AccelerometerEvent? _lastAccel;
  StreamSubscription? _accelSub;

  void startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      _lastAccel = event;
    });
  }

  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// Cek orientasi kamera dari data accelerometer.
  /// Flutter cek: posisi/orientasi.
  /// Server cek: gelap, buram, tertutup.
  CameraHealthResult checkOrientation() {
    final accel = _lastAccel;
    if (accel == null) {
      return const CameraHealthResult(ok: true, message: 'OK');
    }

    // Z axis besar + Y kecil = kamera menghadap lantai atau langit-langit
    if (accel.z.abs() > 8 && accel.y.abs() < 4) {
      return const CameraHealthResult(
        ok:      false,
        message: 'Arahkan kamera ke depan',
      );
    }

    // X axis besar = HP terlalu miring ke samping
    if (accel.x.abs() > 8) {
      return const CameraHealthResult(
        ok:      false,
        message: 'Pegang HP tegak',
      );
    }

    return const CameraHealthResult(ok: true, message: 'OK');
  }

  /// Sudut kemiringan kamera ke depan/belakang dalam radian.
  /// Dipakai TFLiteService untuk tilt correction estimasi jarak.
  /// Return 0.0 jika belum ada data accelerometer.
  double get lastTiltAngle {
    if (_lastAccel == null) return 0.0;
    return atan2(_lastAccel!.x, _lastAccel!.z);
  }
}
```

---

## Berkas: `lib/services/detection_filter.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/detection_filter.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../providers/settings_provider.dart' show Verbosity;

/// Filter pipeline — dipanggil oleh BOTH TFLite dan Server result.
/// Satu instance, state persist selama sesi aktif.
///
/// Fix dari doc 5 masalah 5:
/// - Streak hanya di-increment SETELAH lolos distance + confidence filter
/// - Cooldown berbeda per tier (Netra AI: critical=2s, warning=3s, info=5s)
class DetectionFilter {
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<String, int>      _streak        = {};

  // streakRequired=2: SSD MobileNet tidak konsisten antar frame (objek bisa
  // flash 1 frame lalu hilang). Minimal 2 frame berturut-turut memastikan
  // deteksi stabil sebelum popup muncul dan TTS disuarakan.
  static const int    _streakRequired = 2;
  static const double _minConfidence  = 0.5;  // SSD lebih noisy, threshold lebih tinggi dari YOLO

  /// PG-06 "Ambang jarak peringatan" (1–5 m) — objek lebih jauh dari ini tidak
  /// diumumkan. Diisi `SettingsProvider`; dulu nilainya konstanta 10 m dan
  /// slider di Pengaturan tidak berpengaruh sama sekali.
  ///
  /// Slider ini mengubah **frekuensi peringatan**, yang untuk sebagian
  /// pengguna adalah selisih antara berguna dan tidak tertahankan: 5 m di
  /// koridor ramai berarti bicara terus-menerus.
  double _maxDistance = 10.0;

  /// PG-05 "Tingkat kecerewetan" — menentukan berapa banyak yang diumumkan
  /// sekaligus, bukan hanya panjang kalimatnya.
  Verbosity _verbosity = Verbosity.sedang;

  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _maxDistance = maxDistanceM;
    _verbosity = verbosity;
  }

  List<Detection> process(List<Detection> raw) {
    final currentLabels = raw.map((d) => d.labelEn).toSet();

    // Remove streak entry untuk label yang hilang dari frame ini
    for (final label in _streak.keys.toList()) {
      if (!currentLabels.contains(label)) {
        _streak.remove(label);
      }
    }

    final approved = <Detection>[];

    for (final det in raw) {
      // [1] Distance filter
      if (det.distanceMeter > _maxDistance) {
        debugPrint('[Filter] DROP ${det.labelEn}: '
            'jarak ${det.distanceMeter.toStringAsFixed(1)}m > ${_maxDistance}m');
        continue;
      }

      // [2] Confidence filter
      if (det.confidence < _minConfidence) {
        debugPrint('[Filter] DROP ${det.labelEn}: '
            'confidence ${det.confidence.toStringAsFixed(2)} < $_minConfidence');
        continue;
      }

      // [3] Increment streak HANYA untuk yang lolos distance + confidence
      _streak[det.labelEn] = (_streak[det.labelEn] ?? 0) + 1;

      // [4] Stability check
      if ((_streak[det.labelEn] ?? 0) < _streakRequired) {
        debugPrint('[Filter] STREAK ${det.labelEn}: '
            '${_streak[det.labelEn]}/$_streakRequired frame');
        continue;
      }

      // [5] Cooldown per tier
      final cooldown = _cooldownFor(det);
      final last     = _lastAnnounced[det.labelEn];
      final now      = DateTime.now();
      if (last != null && now.difference(last) < cooldown) {
        final sisa = cooldown - now.difference(last);
        debugPrint('[Filter] COOLDOWN ${det.labelEn}: '
            'sisa ${sisa.inMilliseconds}ms');
        continue;
      }

      // [6] Lolos semua
      _lastAnnounced[det.labelEn] = now;
      approved.add(det);
    }

    // [7] Sort: critical → warning → info, lalu jarak terdekat
    approved.sort((a, b) {
      final pa = _prio(a.dangerLevel);
      final pb = _prio(b.dangerLevel);
      if (pa != pb) return pa.compareTo(pb);
      return a.distanceMeter.compareTo(b.distanceMeter);
    });

    // [8] Berapa banyak yang boleh bicara sekaligus — PG-05. Batas atas tetap
    // 2 (Cognitive Load Theory, dan kontrak zona hanya menampung 2 kartu);
    // "ringkas" memangkasnya jadi satu supaya hanya yang paling mendesak
    // terdengar.
    final maxPerCycle = switch (_verbosity) {
      Verbosity.ringkas => 1,
      _ => 2,
    };
    return approved.take(maxPerCycle).toList();
  }

  int _prio(String danger) => switch (danger) {
        'critical' => 0,
        'warning'  => 1,
        _          => 2,
      };

  /// Cooldown berbeda per tier, dipotong 50% jika objek sedang mendekat.
  /// Ref: Netra AI paper — critical=2s, warning=3s, info=5s sebagai base.
  Duration _cooldownFor(Detection det) {
    final base = switch (det.dangerLevel) {
      'critical' => const Duration(seconds: 2),
      'warning'  => const Duration(seconds: 3),
      _          => const Duration(seconds: 5),
    };

    // PG-05 — kecerewetan menggeser jeda antar pengumuman. Critical TIDAK
    // ikut digeser: seberapa pun pengguna ingin sepi, peringatan bahaya
    // tidak boleh ditahan lebih lama.
    final scaled = det.dangerLevel == 'critical'
        ? base
        : switch (_verbosity) {
            Verbosity.ringkas => base * 2.0,
            Verbosity.sedang => base,
            Verbosity.detail => base * 0.6,
          };

    if (det.isApproaching) {
      return Duration(milliseconds: scaled.inMilliseconds ~/ 2);
    }
    return scaled;
  }

  void reset() {
    _lastAnnounced.clear();
    _streak.clear();
  }
}
```

---

## Berkas: `lib/services/haptic_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/haptic_service.dart`

```dart
import 'package:vibration/vibration.dart';

/// HapticService — vibration feedback pendamping TTS.
///
/// Di lingkungan bising (pasar, jalan raya), haptic menjadi primary signal.
/// Tidak perlu init() — vibration package sudah handle internally
/// jika device tidak punya vibrator (fail silent).
///
/// Pola berdasarkan penelitian clock-based directional feedback:
/// - Critical: triple pulse cepat (400ms total)
/// - Warning:  double pulse sedang (500ms)
/// - Info:     single pulse panjang (300ms)
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  // ── Tier peringatan rintangan ─────────────────────────────────────────────

  /// Critical: orang/motor/mobil < 1.5m — triple pulse cepat.
  Future<void> critical() async =>
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);

  /// Warning: objek < 3m — double pulse sedang.
  Future<void> warning() async =>
      Vibration.vibrate(pattern: [0, 200, 100, 200]);

  /// Info: objek jauh/tidak berbahaya — single pulse pelan.
  Future<void> info() async =>
      Vibration.vibrate(pattern: [0, 300]);

  // ── Arah navigasi ─────────────────────────────────────────────────────────

  /// Belok kanan: 2 pulse cepat.
  Future<void> turnRight() async =>
      Vibration.vibrate(pattern: [0, 80, 40, 80]);

  /// Belok kiri: 2 pulse lambat.
  Future<void> turnLeft() async =>
      Vibration.vibrate(pattern: [0, 200, 100, 200]);

  /// Lurus: 1 pulse panjang.
  Future<void> goStraight() async =>
      Vibration.vibrate(duration: 400);

  // ── Utility ───────────────────────────────────────────────────────────────

  Future<void> cancel() async => Vibration.cancel();

  /// Dispatch otomatis berdasarkan danger level string.
  /// Dipanggil dari DetectionProvider berdampingan TTS.
  Future<void> fromDangerLevel(String level) async {
    switch (level) {
      case 'critical':
        await critical();
        break;
      case 'warning':
        await warning();
        break;
      case 'info':
        await info();
        break;
    }
  }
}
```

---

## Berkas: `lib/services/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/index.dart`

```dart
export 'tflite_service.dart';
export 'server_service.dart';
export 'ocr_service.dart';
export 'detection_filter.dart';
export 'tts_service.dart';
export 'camera_health_service.dart';
export 'risk_zone_service.dart';
```

---

## Berkas: `lib/services/money_tflite_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/money_tflite_service.dart`

```dart
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Klasifikasi nominal uang kertas rupiah — SEPENUHNYA ON-DEVICE.
///
/// Tidak pernah memanggil server. Tiga alasan yang tidak bisa ditawar:
/// transaksi tunai sering terjadi tanpa sinyal (pasar, warung), foto uang
/// tidak perlu meninggalkan perangkat, dan pengguna butuh umpan balik
/// seketika saat mengarahkan kamera.
///
/// Model: MobileNetV2 transfer learning, 6 kelas, input 224x224x3 float32
/// dengan normalisasi `rescale = 1/255` (sama seperti saat training).
///
/// ATURAN MUTLAK: nominal TIDAK PERNAH ditebak. Di bawah ambang keyakinan,
/// yang dikembalikan hanya instruksi perbaikan — salah menyebut nominal ke
/// pengguna tunanetra berarti kerugian uang nyata, jadi false positive di
/// sini jauh lebih berbahaya daripada false negative.
class MoneyTFLiteService {
  static final MoneyTFLiteService instance = MoneyTFLiteService._();
  MoneyTFLiteService._();

  static const String _modelAsset = 'assets/models/uang_rupiah.tflite';
  static const int _inputSize = 224;

  /// Ambang keyakinan sengaja tinggi. Precedent Seeing AI menyetel presisi
  /// pada confidence sangat tinggi justru untuk menekan false positive pada
  /// alat bantu uang.
  static const double confidenceThreshold = 0.85;

  /// Urutan kelas WAJIB sama dengan `class_indices` saat training:
  /// {'100rb': 0, '10rb': 1, '20rb': 2, '2rb': 3, '50rb': 4, '5rb': 5}
  static const List<int> classValues = [100000, 10000, 20000, 2000, 50000, 5000];

  /// Model ini dilatih pada emisi 2016 dan TIDAK punya kelas Rp1.000.
  /// Dipakai untuk menyusun pesan keterbatasan yang jujur (UG-18).
  static const List<int> unsupportedValues = [1000];

  Interpreter? _interpreter;
  bool _loading = false;

  bool get isReady => _interpreter != null;

  Future<bool> load() async {
    if (_interpreter != null || _loading) return _interpreter != null;
    _loading = true;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
      debugPrint('[MoneyTFLite] Model siap: $_modelAsset');
      return true;
    } catch (e) {
      debugPrint('[MoneyTFLite] Gagal memuat model: $e');
      _interpreter = null;
      return false;
    } finally {
      _loading = false;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Klasifikasi dari frame kamera YUV420.
  ///
  /// [cropRatio] memanfaatkan bingkai panduan di layar: hanya area tengah
  /// yang dianalisis, jadi bebannya jauh lebih ringan daripada memeriksa
  /// seluruh frame, sekaligus menghilangkan latar yang membingungkan model.
  Future<MoneyResult> classifyCameraImage(
    CameraImage image, {
    double cropRatio = 0.7,
  }) async {
    if (_interpreter == null) {
      return const MoneyResult.unavailable();
    }
    try {
      final input = await compute(
        _prepareInput,
        _PrepareArgs(
          yPlane: image.planes[0].bytes,
          uPlane: image.planes[1].bytes,
          vPlane: image.planes[2].bytes,
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes[1].bytesPerRow,
          uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
          cropRatio: cropRatio,
        ),
      );
      return _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyCameraImage error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  /// Klasifikasi dari JPEG (dipakai tombol "paksa deteksi ulang").
  Future<MoneyResult> classifyJpeg(Uint8List jpegBytes, {double cropRatio = 0.7}) async {
    if (_interpreter == null) return const MoneyResult.unavailable();
    try {
      final input = await compute(
        _prepareJpeg,
        _JpegArgs(bytes: jpegBytes, cropRatio: cropRatio),
      );
      return _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyJpeg error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  MoneyResult _runInference(List<List<List<List<double>>>> input) {
    final output = List.generate(1, (_) => List<double>.filled(classValues.length, 0));
    _interpreter!.run(input, output);
    final probs = output[0];

    var bestIndex = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIndex]) bestIndex = i;
    }
    final confidence = probs[bestIndex];

    // UG-06 — ragu: nominal TIDAK ditampilkan, hanya instruksi perbaikan.
    if (confidence < confidenceThreshold) {
      return MoneyResult.uncertain(confidence);
    }
    return MoneyResult.detected(
      valueIdr: classValues[bestIndex],
      confidence: confidence,
    );
  }
}

/// Hasil klasifikasi. `detected == false` berarti layar HANYA boleh
/// menampilkan instruksi, tidak boleh menampilkan angka apa pun.
class MoneyResult {
  final bool detected;
  final int? valueIdr;
  final double confidence;
  final MoneyFailure? failure;
  final String? message;

  const MoneyResult.detected({required int this.valueIdr, required this.confidence})
      : detected = true,
        failure = null,
        message = null;

  const MoneyResult.uncertain(this.confidence)
      : detected = false,
        valueIdr = null,
        failure = MoneyFailure.lowConfidence,
        message = 'Belum yakin. Dekatkan sedikit dan tahan diam.';

  const MoneyResult.unavailable()
      : detected = false,
        valueIdr = null,
        confidence = 0,
        failure = MoneyFailure.modelUnavailable,
        message = 'Model pengenalan uang belum siap.';

  const MoneyResult.failure(this.message)
      : detected = false,
        valueIdr = null,
        confidence = 0,
        failure = MoneyFailure.error;
}

enum MoneyFailure { lowConfidence, modelUnavailable, error }

// ── Preprocessing di isolate ────────────────────────────────────────────
// Konversi + crop + resize dilakukan lewat `compute()` supaya UI thread
// tidak tersendat: pengguna sering memakai mode ini sambil berdiri di
// kasir, jadi layar harus tetap responsif.

class _PrepareArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int width, height, yRowStride, uvRowStride, uvPixelStride;
  final double cropRatio;

  const _PrepareArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.cropRatio,
  });
}

class _JpegArgs {
  final Uint8List bytes;
  final double cropRatio;
  const _JpegArgs({required this.bytes, required this.cropRatio});
}

const int _size = MoneyTFLiteService._inputSize;

/// Sampling langsung ke grid 224x224 dari area crop — piksel yang diproses
/// turun drastis dibanding mengonversi seluruh frame lalu me-resize.
List<List<List<List<double>>>> _prepareInput(_PrepareArgs a) {
  final cropW = (a.width * a.cropRatio).round();
  final cropH = (a.height * a.cropRatio).round();
  final offsetX = (a.width - cropW) ~/ 2;
  final offsetY = (a.height - cropH) ~/ 2;

  return [
    List.generate(_size, (ty) {
      final sy = offsetY + (ty * cropH ~/ _size);
      return List.generate(_size, (tx) {
        final sx = offsetX + (tx * cropW ~/ _size);
        final yIdx = sy * a.yRowStride + sx;
        final uvIdx = (sy ~/ 2) * a.uvRowStride + (sx ~/ 2) * a.uvPixelStride;

        final yVal = yIdx < a.yPlane.length ? a.yPlane[yIdx] & 0xFF : 0;
        final uVal = uvIdx < a.uPlane.length ? (a.uPlane[uvIdx] & 0xFF) - 128 : 0;
        final vVal = uvIdx < a.vPlane.length ? (a.vPlane[uvIdx] & 0xFF) - 128 : 0;

        final r = (yVal + 1.402 * vVal).clamp(0, 255).toDouble();
        final g = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toDouble();
        final b = (yVal + 1.772 * uVal).clamp(0, 255).toDouble();

        // rescale = 1/255, persis seperti ImageDataGenerator saat training.
        return [r / 255.0, g / 255.0, b / 255.0];
      });
    }),
  ];
}

List<List<List<List<double>>>> _prepareJpeg(_JpegArgs a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) {
    throw StateError('JPEG tidak bisa dibaca');
  }
  final side = (math.min(decoded.width, decoded.height) * a.cropRatio).round();
  final cropped = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = img.copyResize(cropped, width: _size, height: _size);

  return [
    List.generate(_size, (y) {
      return List.generate(_size, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      });
    }),
  ];
}
```

---

## Berkas: `lib/services/object_tracker.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/object_tracker.dart`

```dart
import 'dart:math';
import '../models/detection.dart';

/// TrackedObject — state satu objek yang sedang di-track.
class TrackedObject {
  final int    id;
  final String label;      // labelEn dari Detection
  double cx, cy, w, h;
  int    missedFrames = 0;
  double lastArea;
  bool   isApproaching = false; // true jika bbox area tumbuh > 20%

  TrackedObject({
    required this.id,
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  }) : lastArea = w * h;

  void update(double newCx, double newCy, double newW, double newH) {
    final newArea = newW * newH;
    // Objek dianggap mendekat jika area bbox tumbuh > 20% dari frame sebelumnya
    isApproaching = newArea > lastArea * 1.20;
    lastArea      = newArea;
    cx = newCx; cy = newCy;
    w  = newW;  h  = newH;
    missedFrames  = 0;
  }
}

/// ObjectTracker — SORT (Simple Online Realtime Tracking) pure Dart.
///
/// Tidak ada library eksternal. Cocok untuk 5–15 objek per frame.
/// Manfaat utama untuk Guidio:
/// 1. Streak counter tidak ter-reset akibat flickering (satu objek = satu ID)
/// 2. Deteksi objek mendekat (isApproaching) → cooldown diperpendek 50%
class ObjectTracker {
  final Map<int, TrackedObject> _tracks = {};
  int _nextId = 0;

  /// Minimal IoU untuk menganggap dua bbox sebagai objek yang sama.
  static const double _iouThreshold   = 0.3;

  /// Hapus track setelah N frame tidak terdeteksi.
  static const int    _maxMissedFrames = 5;

  /// Update tracker dengan list deteksi frame terbaru.
  /// Return: semua TrackedObject yang masih aktif.
  List<TrackedObject> update(List<Detection> detections) {
    if (detections.isEmpty) {
      for (final t in _tracks.values) {
        t.missedFrames++;
      }
      _prune();
      return _tracks.values.toList();
    }

    final matched   = <int>{};    // index detection yang sudah di-assign
    final trackList = _tracks.values.toList();

    for (final track in trackList) {
      double bestIou = _iouThreshold;
      int    bestIdx = -1;

      for (int i = 0; i < detections.length; i++) {
        if (matched.contains(i)) continue;
        // Hanya match dengan label yang sama — tidak cross-class matching
        if (detections[i].labelEn != track.label) continue;

        final iou = _iou(
          track.cx, track.cy, track.w, track.h,
          detections[i].bboxCx, detections[i].bboxCy,
          detections[i].bboxW,  detections[i].bboxH,
        );

        if (iou > bestIou) {
          bestIou = iou;
          bestIdx = i;
        }
      }

      if (bestIdx >= 0) {
        final d = detections[bestIdx];
        track.update(d.bboxCx, d.bboxCy, d.bboxW, d.bboxH);
        matched.add(bestIdx);
      } else {
        track.missedFrames++;
      }
    }

    // Detection yang tidak di-assign → buat track baru
    for (int i = 0; i < detections.length; i++) {
      if (matched.contains(i)) continue;
      final d = detections[i];
      final t = TrackedObject(
        id:    _nextId++,
        label: d.labelEn,
        cx:    d.bboxCx, cy: d.bboxCy,
        w:     d.bboxW,  h:  d.bboxH,
      );
      _tracks[t.id] = t;
    }

    _prune();
    return _tracks.values.toList();
  }

  void _prune() =>
      _tracks.removeWhere((_, t) => t.missedFrames > _maxMissedFrames);

  /// Intersection over Union dalam pixel coords.
  /// Formula identik dengan normalized coords — unit tidak mempengaruhi rasio.
  double _iou(
    double ax, double ay, double aw, double ah,
    double bx, double by, double bw, double bh,
  ) {
    final aL = ax - aw / 2; final aR = ax + aw / 2;
    final aT = ay - ah / 2; final aB = ay + ah / 2;
    final bL = bx - bw / 2; final bR = bx + bw / 2;
    final bT = by - bh / 2; final bB = by + bh / 2;

    final iL = max(aL, bL); final iR = min(aR, bR);
    final iT = max(aT, bT); final iB = min(aB, bB);

    if (iR <= iL || iB <= iT) return 0.0;

    final inter = (iR - iL) * (iB - iT);
    return inter / (aw * ah + bw * bh - inter);
  }

  /// Reset semua track — dipanggil saat mode berganti (stopRealtime).
  void reset() {
    _tracks.clear();
    _nextId = 0;
  }
}
```

---

## Berkas: `lib/services/ocr_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/ocr_service.dart`

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Satu blok teks hasil pengenalan, sudah diurutkan sesuai urutan baca.
@immutable
class OcrTextBlock {
  final String heading;
  final List<String> sentences;

  /// Perkiraan jumlah kata — dipakai BT-08 untuk menghitung durasi bacaan
  /// sebelum mulai, supaya tawaran "ringkas / penuh / pilih bagian" muncul
  /// sebelum pengguna terjebak mendengarkan tiga menit teks.
  final int wordCount;

  const OcrTextBlock({
    required this.heading,
    required this.sentences,
    required this.wordCount,
  });
}

@immutable
class OcrResult {
  final List<OcrTextBlock> blocks;
  final String fullText;

  const OcrResult({required this.blocks, required this.fullText});

  bool get isEmpty => fullText.trim().isEmpty;
  int get totalWords => blocks.fold(0, (sum, b) => sum + b.wordCount);

  /// BT-08 — perkiraan durasi baca. ~150 kata per menit adalah laju TTS
  /// Bahasa Indonesia yang wajar pada kecepatan bawaan.
  Duration get estimatedDuration =>
      Duration(seconds: (totalWords / 150 * 60).round());
}

/// Pengenalan teks **sepenuhnya di perangkat** lewat ML Kit.
///
/// Ini menggantikan OCR di server. Tiga akibat langsung, semuanya perbaikan:
///
/// 1. **Baca Teks jalan tanpa internet.** BT-02 ("tombol nonaktif + alasan")
///    tidak berlaku lagi — tidak ada alasan menonaktifkan tombol untuk kerja
///    yang tidak butuh jaringan sama sekali.
/// 2. **Tidak ada gambar yang meninggalkan perangkat.** Foto dokumen, resep,
///    surat — semuanya tetap di ponsel.
/// 3. **Hasil datang dalam ratusan milidetik**, bukan detik. BT-05 (banner
///    lambat 8 detik) dan BT-15 (timeout 15 detik) praktis tidak pernah kena.
///
/// Yang hilang: ML Kit tidak melakukan koreksi berbasis LLM, jadi teks
/// bersudut miring atau tulisan tangan lebih sering meleset daripada OCR
/// server. Untuk menu, label harga, dan papan nama — kasus pemakaian utama
/// mode ini — itu pertukaran yang menguntungkan.
class OcrService {
  static final OcrService instance = OcrService._();
  OcrService._();

  TextRecognizer? _recognizer;

  TextRecognizer get _engine =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Mengenali teks dari berkas gambar hasil `takePicture`.
  ///
  /// ML Kit membaca langsung dari path berkas, jadi byte-nya **tidak perlu**
  /// dibaca ke memori Dart lebih dulu — untuk foto 4 MP itu menghemat satu
  /// salinan besar yang tidak ada gunanya.
  Future<OcrResult> recognizeFile(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _engine.processImage(input);
    return _toResult(recognized);
  }

  /// Varian untuk byte yang sudah ada di memori. Menulis berkas sementara
  /// karena `InputImage.fromBytes` menuntut metadata format yang tidak kita
  /// punya untuk JPEG sembarang.
  Future<OcrResult> recognizeBytes(Uint8List jpeg) async {
    final dir = Directory.systemTemp;
    final file = await File(
      '${dir.path}/vinara_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).writeAsBytes(jpeg, flush: true);
    try {
      return await recognizeFile(file.path);
    } finally {
      // Foto tidak ditinggalkan di penyimpanan — BT-21 mengeluh soal ruang,
      // dan menumpuk berkas sementara akan memperburuknya.
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  OcrResult _toResult(RecognizedText recognized) {
    final blocks = <OcrTextBlock>[];

    for (final block in recognized.blocks) {
      final lines = block.lines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).toList();
      if (lines.isEmpty) continue;

      // ML Kit sudah mengelompokkan teks jadi blok berdasarkan tata letak.
      // Baris pertama tiap blok dipakai sebagai heading — itu yang membuat
      // ResultPanel/long punya heading nyata, bukan satu blok "Hasil baca"
      // untuk seluruh halaman seperti waktu memakai OCR server.
      final heading = _asHeading(lines.first);
      final body = lines.length > 1 ? lines.sublist(1) : lines;
      final sentences = _splitSentences(body.join(' '));

      blocks.add(OcrTextBlock(
        heading: heading,
        sentences: sentences,
        wordCount: sentences.fold(0, (n, s) => n + s.split(RegExp(r'\s+')).length),
      ));
    }

    return OcrResult(blocks: blocks, fullText: recognized.text);
  }

  /// Heading dipotong supaya tetap satu baris saat dibacakan sebagai penanda
  /// bagian; teks utuhnya tetap ada di dalam kalimat blok.
  String _asHeading(String line) {
    final clean = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 42) return clean;
    return '${clean.substring(0, 39)}…';
  }

  List<String> _splitSentences(String text) => text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
```

---

## Berkas: `lib/services/risk_zone_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/risk_zone_service.dart`

```dart
import '../models/risk_zone.dart';
import 'server_service.dart';

/// Wrapper lokal untuk Risk Zone — simpan warning terakhir di memory.
class RiskZoneLocalService {
  static final RiskZoneLocalService instance = RiskZoneLocalService._();
  RiskZoneLocalService._();

  RiskZone? _currentWarning;
  RiskZone? get currentWarning => _currentWarning;

  Future<void> checkAndUpdate(double lat, double lng) async {
    try {
      _currentWarning = await ServerService.instance.checkRiskZone(lat, lng);
    } catch (_) {
      // Gagal check = tidak ada warning, bukan crash
      _currentWarning = null;
    }
  }

  void clearWarning() => _currentWarning = null;
}
```

---

## Berkas: `lib/services/server_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/server_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/net/api_client.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Emulator Android  : 10.0.2.2:8000
// Device fisik      : ganti lewat Pengaturan → Alamat server (PG-08).
const String kDefaultServerHost = '10.0.2.2:8000';
// ──────────────────────────────────────────────────────────────────────────

class ServerDetectionResult {
  final List<Detection> detections;
  final RiskZone? riskZone;
  const ServerDetectionResult({required this.detections, this.riskZone});
}

class ServerService {
  static final ServerService instance = ServerService._();
  ServerService._();

  /// Alamat server aktif (PG-08). Dulu ini konstanta hardcoded, jadi
  /// pengaturan "Alamat server" tersimpan ke disk tapi **tidak berpengaruh
  /// sama sekali** — aplikasi mengatakan "tersimpan" untuk perubahan yang
  /// tidak pernah terjadi. Itu pelanggaran bagian 4.1 yang sama seperti
  /// konfirmasi ganti mode palsu, hanya di tempat berbeda.
  ///
  /// Sekarang [host] adalah sumber kebenaran tunggal untuk seluruh endpoint,
  /// diisi `SettingsProvider` saat boot dan setiap kali pengguna menyimpan
  /// alamat baru.
  String _host = kDefaultServerHost;
  String get host => _host;

  /// Mengganti alamat. WebSocket yang sedang tersambung diputus supaya
  /// sambungan berikutnya memakai alamat baru — kalau tidak, mode Deteksi
  /// Objek akan tetap menempel di server lama sampai aplikasi dimatikan.
  void setHost(String value) {
    final next = value.trim();
    if (next.isEmpty || next == _host) return;
    _host = next;
    if (_connected) disconnect();
  }

  String get _wsBase => 'ws://$_host';

  /// Satu klien HTTP untuk seluruh aplikasi — koneksi dipakai ulang
  /// (keep-alive) alih-alih handshake baru tiap permintaan. Lihat
  /// [ApiClient] untuk alasan lengkapnya.
  late final ApiClient _api = ApiClient()..hostProvider = (() => _host);
  ApiClient get api => _api;

  WebSocketChannel? _channel;
  bool _connected = false;
  bool get isConnected => _connected;

  final _streamController =
      StreamController<ServerDetectionResult>.broadcast();
  Stream<ServerDetectionResult> get detectionStream => _streamController.stream;

  /// Connect WebSocket untuk Mode Tuntun/Navigasi.
  /// [lat], [lng] dikirim sebagai query param untuk Risk Zone (opsional).
  Future<void> connect({double lat = 0, double lng = 0}) async {
    try {
      final uri = Uri.parse('$_wsBase/ws/detect?lat=$lat&lng=$lng');
      _channel  = WebSocketChannel.connect(uri);
      _connected = true;

      _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          if (json['type'] == 'detections') {
            final dets = (json['detections'] as List)
                .map((e) => Detection.fromJson(e as Map<String, dynamic>))
                .toList();

            RiskZone? rz;
            if (json['risk_zone'] != null) {
              rz = RiskZone.fromJson(json['risk_zone'] as Map<String, dynamic>);
            }

            _streamController.add(
              ServerDetectionResult(detections: dets, riskZone: rz),
            );
          }
        },
        onError: (_) => _connected = false,
        onDone:  ()  => _connected = false,
      );
    } catch (_) {
      _connected = false;
      rethrow;
    }
  }

  /// Kirim JPEG frame via WebSocket (Mode Tuntun server path).
  void sendFrame(Uint8List jpegBytes) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jpegBytes);
    }
  }

  /// Single-shot detect untuk Voice Assistant (REST).
  Future<List<Detection>> detectOnce(Uint8List jpegBytes) async {
    final json = await _api.postBytes('/api/detect', jpegBytes);
    return (json['detections'] as List)
        .map((e) => Detection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Minta narasi natural dari Claude Haiku berdasarkan deteksi.
  Future<String> getNarasi(List<Detection> detections, {String context = 'voice'}) async {
    final json = await _api.postJson('/api/narasi', {
      'detections': detections
          .map((d) => {
                'label_id': d.labelId,
                'distance_meter': d.distanceMeter,
                'direction': d.direction,
                'danger_level': d.dangerLevel,
              })
          .toList(),
      'context': context,
    }, op: ApiOp.frame);
    return json['narasi'] as String? ?? 'Area sekitar tampak aman.';
  }

  /// Cek risk zone via REST.
  Future<RiskZone?> checkRiskZone(double lat, double lng) async {
    final json = await _api.getJson('/api/risk-zone', query: {
      'lat': '$lat',
      'lng': '$lng',
    });
    if (json['risk_zone'] == null) return null;
    return RiskZone.fromJson(json['risk_zone'] as Map<String, dynamic>);
  }

  /// LLM intent routing untuk Voice Assistant.
  /// Return: 'describe_scene' | 'ocr' | 'navigation' | 'chitchat'
  /// Fallback ke 'describe_scene' jika server tidak tersedia atau timeout.
  Future<String> routeIntent(String text) async {
    try {
      final json = await _api.postJson('/api/route-intent', {'text': text});
      return json['intent'] as String? ?? 'describe_scene';
    } catch (_) {
      return 'describe_scene'; // offline atau timeout → fallback aman
    }
  }

  // ── Mode Cari Objek ─────────────────────────────────────────────────────

  /// Cari satu barang di satu frame. `found: false` dengan reason
  /// `not_in_frame` adalah kondisi NORMAL (CO-10) — aplikasi menyuruh
  /// pengguna memutar badan lalu memanggil ini lagi.
  Future<Map<String, dynamic>> cariObjek(String target, Uint8List jpegBytes) =>
      _api.postMultipart(
        '/api/cari-objek',
        bytes: jpegBytes,
        fields: {'target': target},
        op: ApiOp.frame,
      );

  /// Daftar barang yang dikenali — dipakai CO-12 untuk menawarkan
  /// barang lain saat target tidak dikenal.
  Future<List<String>> cariObjekTargets() async {
    final json = await _api.getJson('/api/cari-objek/targets');
    return (json['targets'] as List).cast<String>();
  }

  // ── Mode Navigasi (segmentasi jalur 3 zona) ─────────────────────────────

  Future<Map<String, dynamic>> segmentasiJalur(
    Uint8List jpegBytes, {
    double lat = 0,
    double lng = 0,
  }) =>
      _api.postMultipart(
        '/api/navigasi',
        bytes: jpegBytes,
        fields: {'lat': '$lat', 'lng': '$lng'},
        op: ApiOp.frame,
      );

  // ── Kemampuan server ────────────────────────────────────────────────────

  /// Mode mana yang server-nya hidup, DITANYAKAN SEBELUM pengguna menekan
  /// tombol. Menentukan item `limited`/`disabled` di ModePickerSheet dan
  /// aktif-tidaknya tombol utama Mode Baca Teks.
  Future<Map<String, dynamic>?> capabilities() async {
    try {
      return await _api.getJson('/api/capabilities');
    } catch (_) {
      return null; // offline: pemanggil menganggap semua mode server mati
    }
  }

  /// Health check + waktu tempuh — PG-08c membacakan latensinya.
  Future<Map<String, dynamic>?> health({Duration? timeout}) =>
      healthAt(_host, timeout: timeout);

  /// Health check ke alamat tertentu **tanpa mengubah alamat aktif** — dipakai
  /// PG-08b untuk menguji kandidat sebelum disimpan. Memisahkan "menguji" dari
  /// "memakai" itulah yang membuat PG-08e mungkin: uji boleh gagal tanpa
  /// merusak sambungan yang sedang bekerja.
  Future<Map<String, dynamic>?> healthAt(String host, {Duration? timeout}) async {
    // Klien sementara dengan host tetap — tidak menyentuh alamat aktif.
    final probe = ApiClient()..hostProvider = (() => host);
    final sw = Stopwatch()..start();
    try {
      final json = await probe.getJson('/health', retries: 0);
      sw.stop();
      json['round_trip_ms'] = sw.elapsedMilliseconds;
      return json;
    } catch (_) {
      return null;
    } finally {
      probe.close();
    }
  }

  // ── Perintah suara ──────────────────────────────────────────────────────

  /// Resolusi perintah yang TIDAK cocok di CommandParser lokal.
  /// `resolved: false` berarti aplikasi harus menawarkan dua tebakan
  /// (AS-18 / AS-19), bukan bilang "perintah gagal".
  Future<Map<String, dynamic>?> resolveIntent(String text) async {
    try {
      return await _api.postJson('/api/intent', {'text': text});
    } catch (_) {
      return null;
    }
  }

  // ── Telemetri, crash, antrean offline ───────────────────────────────────

  /// Telemetri alur. Sengaja fire-and-forget: kegagalan mengirim statistik
  /// tidak boleh terasa oleh pengguna.
  Future<void> sendEvents(String deviceId, List<Map<String, dynamic>> events) async {
    try {
      await _api.postJson(
        '/api/events',
        {'device_id': deviceId, 'events': events},
        op: ApiOp.background,
      );
    } catch (_) {
      // Diabaikan dengan sengaja.
    }
  }

  Future<bool> sendCrashReport(Map<String, dynamic> report) async {
    try {
      await _api.postJson('/api/crash-report', report, op: ApiOp.background);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ER-06 — mode terakhir sebelum crash, untuk dipulihkan otomatis.
  Future<String?> lastModeBeforeCrash(String deviceId) async {
    try {
      final json = await _api.getJson(
        '/api/crash-report/last-mode',
        query: {'device_id': deviceId},
      );
      return json['mode'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// BT-13 — kirim ulang gambar yang tertahan saat offline.
  /// [idempotencyKey] mencegah pemrosesan dobel di server: unggah ulang tidak
  /// idempoten dengan sendirinya, jadi kuncinya yang membuatnya aman diulang.
  Future<Map<String, dynamic>?> flushQueue({
    required String deviceId,
    required String idempotencyKey,
    required String kind,
    required Uint8List jpegBytes,
  }) async {
    try {
      return await _api.postMultipart(
        '/api/queue/flush',
        bytes: jpegBytes,
        filename: 'queued.jpg',
        fields: {
          'device_id': deviceId,
          'idempotency_key': idempotencyKey,
          'kind': kind,
        },
        op: ApiOp.heavy,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Kamus label & manifest model ────────────────────────────────────────

  /// Pemetaan label model → frasa Indonesia (DO-08, DO-19). Ada di server
  /// supaya perbaikan nama tidak perlu rilis ulang aplikasi.
  Future<List<Map<String, dynamic>>?> labels({String lang = 'id'}) async {
    try {
      final json = await _api.getJson('/api/labels', query: {'lang': lang});
      final list = json['labels'];
      if (list is! List) return null;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// UG-18 — emisi uang baru = update model, bukan update aplikasi.
  Future<List<Map<String, dynamic>>?> modelManifest() async {
    try {
      final json = await _api.getJson('/api/models/manifest');
      final list = json['models'];
      if (list is! List) return null;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
```

---

## Berkas: `lib/services/tflite_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/tflite_service.dart`

```dart

import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

// Label Bahasa Indonesia — kunci adalah label Inggris dari labelmap.txt
const Map<String, String> _labelId = {
  // Orang
  'person':         'orang',

  // Kendaraan
  'bicycle':        'sepeda',
  'car':            'mobil',
  'motorcycle':     'motor',
  'airplane':       'pesawat',
  'bus':            'bus',
  'train':          'kereta',
  'truck':          'truk',
  'boat':           'perahu',

  // Outdoor / Jalanan
  'traffic light':  'lampu lalu lintas',
  'fire hydrant':   'hidran',
  'stop sign':      'rambu berhenti',
  'parking meter':  'meteran parkir',
  'bench':          'bangku',

  // Hewan
  'bird':           'burung',
  'cat':            'kucing',
  'dog':            'anjing',
  'horse':          'kuda',
  'sheep':          'domba',
  'cow':            'sapi',
  'elephant':       'gajah',
  'bear':           'beruang',
  'zebra':          'zebra',
  'giraffe':        'jerapah',

  // Aksesoris
  'backpack':       'tas ransel',
  'umbrella':       'payung',
  'handbag':        'tas tangan',
  'tie':            'dasi',
  'suitcase':       'koper',

  // Olahraga
  'frisbee':        'frisbee',
  'skis':           'ski',
  'snowboard':      'snowboard',
  'sports ball':    'bola olahraga',
  'kite':           'layang-layang',
  'baseball bat':   'pemukul baseball',
  'baseball glove': 'sarung tangan baseball',
  'skateboard':     'skateboard',
  'surfboard':      'papan selancar',
  'tennis racket':  'raket tenis',

  // Dapur / Makanan
  'bottle':         'botol',
  'wine glass':     'gelas anggur',
  'cup':            'cangkir',
  'fork':           'garpu',
  'knife':          'pisau',
  'spoon':          'sendok',
  'bowl':           'mangkuk',
  'banana':         'pisang',
  'apple':          'apel',
  'sandwich':       'sandwich',
  'orange':         'jeruk',
  'broccoli':       'brokoli',
  'carrot':         'wortel',
  'hot dog':        'hot dog',
  'pizza':          'pizza',
  'donut':          'donat',
  'cake':           'kue',

  // Furnitur / Ruangan
  'chair':          'kursi',
  'couch':          'sofa',
  'potted plant':   'tanaman pot',
  'bed':            'tempat tidur',
  'dining table':   'meja makan',
  'toilet':         'toilet',

  // Elektronik
  'tv':             'televisi',
  'laptop':         'laptop',
  'mouse':          'mouse',
  'remote':         'remote kontrol',
  'keyboard':       'papan ketik',
  'cell phone':     'ponsel',

  // Peralatan Rumah
  'microwave':      'microwave',
  'oven':           'oven',
  'toaster':        'pemanggang roti',
  'sink':           'wastafel',
  'refrigerator':   'kulkas',

  // Lain-lain
  'book':           'buku',
  'clock':          'jam',
  'vase':           'vas',
  'scissors':       'gunting',
  'teddy bear':     'boneka beruang',
  'hair drier':     'pengering rambut',
  'toothbrush':     'sikat gigi',
};

const Set<String> _dangerHigh   = {'person', 'motorcycle', 'car', 'bus', 'truck', 'dog'};
const Set<String> _dangerMedium = {'bicycle', 'chair', 'dining table'};

const Map<String, int> _realHeightsCm = {
  'person':           170,
  'bicycle':          100,
  'car':              150,
  'motorcycle':       120,
  'airplane':         400,
  'bus':              300,
  'train':            350,
  'truck':            280,
  'boat':             150,
  'traffic light':    250,
  'fire hydrant':      60,
  'stop sign':        200,
  'parking meter':    130,
  'bench':             90,
  'bird':              20,
  'cat':               25,
  'dog':               60,
  'horse':            160,
  'sheep':             80,
  'cow':              140,
  'elephant':         280,
  'bear':             150,
  'zebra':            150,
  'giraffe':          450,
  'backpack':          50,
  'umbrella':         100,
  'handbag':           30,
  'tie':               15,
  'suitcase':          70,
  'frisbee':            3,
  'skis':             150,
  'snowboard':        150,
  'sports ball':       22,
  'kite':              50,
  'baseball bat':     100,
  'baseball glove':    30,
  'skateboard':        15,
  'surfboard':         60,
  'tennis racket':     70,
  'bottle':            25,
  'wine glass':        20,
  'cup':               10,
  'fork':               2,
  'knife':              3,
  'spoon':              2,
  'bowl':              10,
  'banana':            15,
  'apple':             10,
  'sandwich':          10,
  'orange':            10,
  'broccoli':          20,
  'carrot':            20,
  'hot dog':           10,
  'pizza':              5,
  'donut':              5,
  'cake':              15,
  'chair':             90,
  'couch':             90,
  'potted plant':      50,
  'bed':               60,
  'dining table':      75,
  'toilet':            80,
  'tv':                60,
  'laptop':            30,
  'mouse':              4,
  'remote':            20,
  'keyboard':           4,
  'cell phone':        15,
  'microwave':         35,
  'oven':              60,
  'toaster':           20,
  'sink':              25,
  'refrigerator':     175,
  'book':              25,
  'clock':             30,
  'vase':              30,
  'scissors':          20,
  'teddy bear':        30,
  'hair drier':        25,
  'toothbrush':        20,
};

// Focal length piksel (kalibrasi default)
const int _focalLengthPx = 615;

// SSD MobileNet: input 300×300
const int _inputSize = 300;

class TFLiteService {
  static final TFLiteService instance = TFLiteService._();
  TFLiteService._();

  IsolateInterpreter? _isolateInterpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Labels dimuat dinamis dari labelmap.txt
  List<String> _labels = [];

  // Model bytes disimpan agar bisa dikirim ke isolate
  Uint8List? _modelBytes;

  // Tilt correction — sudut kemiringan kamera dari accelerometer (radian)
  double _lastTiltAngle = 0.0;

  /// Dipanggil CameraProvider setiap 30 frame saat orientasi di-check.
  void updateTilt(double angleRadians) {
    _lastTiltAngle = angleRadians;
  }

  Future<bool> tryLoad() async {
    try {
      // Load model SSD MobileNet
      final byteData    = await rootBundle.load('assets/models/ssd_mobilenet.tflite');
      _modelBytes       = byteData.buffer.asUint8List();

      // Load labelmap dinamis dari file teks
      final labelRaw = await rootBundle.loadString('assets/models/labelmap.txt');
      _labels = labelRaw.trim().split('\n').map((l) => l.trim()).toList();
      debugPrint('[TFLite] Loaded ${_labels.length} labels dari labelmap.txt');

      final options     = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(_modelBytes!, options: options);

      // Debug: verifikasi shape tensor
      // SSD MobileNet: input [1, 300, 300, 3]
      final inputShape  = interpreter.getInputTensor(0).shape;
      debugPrint('[TFLite] input shape: $inputShape');  // [1, 300, 300, 3]

      // Bungkus di IsolateInterpreter agar inference tidak freeze UI
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
      );

      _loaded = true;
      return true;
    } catch (e) {
      debugPrint('[TFLite] load error: $e');
      _loaded = false;
      return false;
    }
  }

  /// Jalankan inference dari CameraImage (YUV420).
  /// Menggunakan IsolateInterpreter — tidak freeze UI.
  Future<List<Detection>> runInference(CameraImage image) async {
    if (!_loaded || _isolateInterpreter == null) return [];

    // Konversi YUV420 → RGB → resize 300×300 → nested List [1][300][300][3]
    final inputTensor = _prepareInput(image);
    if (inputTensor == null) return [];

    // SSD MobileNet output 4 tensor terpisah:
    //   tensor[0]: locations [1][10][4]   — [ymin, xmin, ymax, xmax] normalized
    //   tensor[1]: classes   [1][10]      — class index (float)
    //   tensor[2]: scores    [1][10]      — confidence score
    //   tensor[3]: count     [1]          — jumlah deteksi valid
    final outputLocations = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
    final outputClasses   = List.generate(1, (_) => List.filled(10, 0.0));
    final outputScores    = List.generate(1, (_) => List.filled(10, 0.0));
    final outputCount     = List.filled(1, 0.0);

    final outputs = {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: outputCount,
    };

    await _isolateInterpreter!.runForMultipleInputs([inputTensor], outputs);

    return _postProcess(
      outputLocations[0],
      outputClasses[0],
      outputScores[0],
      image.width,
      image.height,
    );
  }

  /// Konversi YUV420 → RGB → resize 300×300 → nested List[1][H][W][3]
  ///
  /// SSD MobileNet membutuhkan uint8 (integer 0..255), bukan float.
  /// TFLite Flutter memetakan List<num> (integer) → uint8 tensor secara otomatis.
  /// Pastikan TIDAK menggunakan .toDouble() agar tidak menjadi float64.
  List<List<List<List<num>>>>? _prepareInput(CameraImage image) {
    try {
      final int width  = image.width;
      final int height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final yBytes      = yPlane.bytes;
      final uBytes      = uPlane.bytes;
      final vBytes      = vPlane.bytes;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStr  = uPlane.bytesPerPixel ?? 1;

      // Buat img.Image RGB
      final rgbImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex  = y * yPlane.bytesPerRow + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStr;

          final int yVal = yBytes[yIndex] & 0xFF;
          final int uVal = (uBytes.length > uvIndex ? uBytes[uvIndex] : 128) & 0xFF;
          final int vVal = (vBytes.length > uvIndex ? vBytes[uvIndex] : 128) & 0xFF;

          final int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
          final int g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
          final int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      // Resize ke 300×300 (SSD MobileNet input size)
      img.Image resized = img.copyResize(
        rgbImage,
        width:         _inputSize,
        height:        _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Rotasi 90° untuk Android karena kamera CameraX default landscape
      if (Platform.isAndroid) {
        resized = img.copyRotate(resized, angle: 90);
      }

      // Build nested List [1][H][W][3] dengan tipe num (integer)
      // PENTING: gunakan pixel.r/g/b sebagai num, BUKAN .toDouble()
      // TFLite akan mapping num integer → uint8 tensor secara otomatis
      final input = List.generate(1, (_) =>
        List.generate(_inputSize, (y) =>
          List.generate(_inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r, pixel.g, pixel.b]; // num integer, bukan double
          }),
        ),
      );

      return input;
    } catch (_) {
      return null;
    }
  }

  /// Post-process output SSD MobileNet → List<Detection>
  ///
  /// Output tensor SSD:
  ///   locations[i] = [ymin, xmin, ymax, xmax] normalized 0..1
  ///   classes[i]   = class index (float, bukan int)
  ///   scores[i]    = confidence score
  ///
  /// NMS sudah dilakukan di dalam model — tidak perlu NMS manual.
  List<Detection> _postProcess(
    List<List<double>> locations, // [10][4]: ymin, xmin, ymax, xmax
    List<double> classes,
    List<double> scores,
    int origWidth,
    int origHeight,
  ) {
    const double confThreshold = 0.5;
    final List<Detection> results = [];

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] < confThreshold) continue;

      final classIdx = classes[i].toInt();
      if (classIdx < 0 || classIdx >= _labels.length) continue;

      final labelEn = _labels[classIdx];
      // Skip entry '???' di labelmap — bukan kelas valid
      if (labelEn == '???') continue;

      final labelId = _labelId[labelEn] ?? labelEn;

      // SSD output: [ymin, xmin, ymax, xmax] normalized 0..1
      final ymin = locations[i][0];
      final xmin = locations[i][1];
      final ymax = locations[i][2];
      final xmax = locations[i][3];

      // Konversi ke pixel koordinat, clamp ke batas frame
      final x1 = (xmin * origWidth).clamp(0.0, (origWidth - 1).toDouble()).toInt();
      final y1 = (ymin * origHeight).clamp(0.0, (origHeight - 1).toDouble()).toInt();
      final x2 = (xmax * origWidth).clamp(0.0, (origWidth - 1).toDouble()).toInt();
      final y2 = (ymax * origHeight).clamp(0.0, (origHeight - 1).toDouble()).toInt();

      final boxH = y2 - y1;
      final cx   = (x1 + x2) / 2.0;
      final cy   = (y1 + y2) / 2.0;

      final dist   = _estimateDistance(labelEn, boxH);
      final dir    = _getDirection(cx, cy, origWidth, origHeight);
      final danger = _getDanger(labelEn, dist);

      // Debug: log tiap deteksi yang lolos threshold
      debugPrint('[Inference] ${scores[i].toStringAsFixed(2)} → $labelEn | $dir | ${dist.toStringAsFixed(1)}m | $danger');

      results.add(Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    scores[i],
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
        inferenceMs:   0, // tidak diukur di sini
      ));
    }

    return results;
  }

  double _estimateDistance(String label, int boxH) {
    if (boxH <= 0) return 999.0;
    final realH = _realHeightsCm[label] ?? 100;
    double dist = (realH * _focalLengthPx) / (boxH * 100);

    // Tilt correction: jika HP miring > 15° (0.26 rad), koreksi jarak.
    if (_lastTiltAngle.abs() > 0.26) {
      dist = dist * cos(_lastTiltAngle.abs());
    }

    return dist;
  }

  /// Tentukan arah berdasarkan posisi horizontal DAN vertikal bounding box.
  ///
  /// Horizontal: kiri / depan / kanan (trisection horizontal)
  /// Vertikal: atas / tengah / bawah (trisection vertikal)
  ///
  /// Jika vertikal = tengah → kembalikan arah horizontal saja ("depan")
  /// Jika vertikal != tengah → gabungkan: "kiri atas", "depan bawah", dll.
  String _getDirection(double cx, double cy, int width, int height) {
    final hThird = width / 3;
    final vThird = height / 3;

    final horiz = cx < hThird ? 'kiri' : cx < hThird * 2 ? 'depan' : 'kanan';
    final vert  = cy < vThird ? 'atas' : cy < vThird * 2 ? 'tengah' : 'bawah';

    // Jika objek di zona tengah vertikal, cukup sebut arah horizontal
    if (vert == 'tengah') return horiz;
    return '$horiz $vert';
  }

  String _getDanger(String label, double dist) {
    if (_dangerHigh.contains(label)) {
      if (dist < 1.5) return 'critical';
      if (dist < 3.0) return 'warning';
    } else if (_dangerMedium.contains(label)) {
      if (dist < 2.0) return 'critical';
      if (dist < 4.0) return 'warning';
    }
    return 'info';
  }

  void dispose() {
    _isolateInterpreter?.close();
    _loaded = false;
  }
}
```

---

## Berkas: `lib/services/tts_service.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/tts_service.dart`

```dart
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service — Text-to-Speech Bahasa Indonesia.
///
/// Fix dari doc 5 masalah 6:
/// - Gunakan awaitSpeakCompletion(true) dari flutter_tts (Context7 confirmed)
///   agar speak() benar-benar resolve saat TTS selesai bicara.
/// - Critical message menggunakan stop() dulu lalu speak (interrupt).
class TTSService {
  static final TTSService instance = TTSService._();
  TTSService._();

  final FlutterTts _tts     = FlutterTts();
  bool             _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> init() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.5);  // sedikit lambat untuk tunanetra
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // awaitSpeakCompletion(true): speak() akan resolve saat TTS benar-benar selesai
    // Ini dari Context7 flutter_tts docs — lebih simple dari Completer manual
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(()      => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(()    => _speaking = false);
    _tts.setErrorHandler((_)    => _speaking = false);
  }

  /// Speak pesan. Jika [interrupt] = true (untuk critical obstacle):
  /// stop TTS yang sedang jalan lalu langsung speak.
  Future<void> speak(String message, {bool interrupt = false}) async {
    if (interrupt) {
      await _tts.stop();
      _speaking = false;
    }
    if (!_speaking) {
      _speaking = true;
      await _tts.speak(message); // resolve saat selesai karena awaitSpeakCompletion(true)
    }
  }

  /// Kecepatan bicara — pengaturan 1 "Kecepatan bicara TTS" (bagian 13).
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  /// Konfirmasi saat ganti mode — "Mode baca teks aktif".
  Future<void> announceMode(String modeName) async {
    await stop();
    await speak('Mode $modeName aktif');
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }
}
```

---

## Berkas: `lib/theme/app_colors.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Token warna design system Vinara.
/// Aturan baku: `fill` hanya untuk ikon & bidang besar (syarat 3:1),
/// `label` untuk semua teks (syarat 4.5:1). Isian vibrant (action/fill,
/// positive/fill, critical/fill) TIDAK BOLEH memuat teks putih kecil.
abstract final class AppColors {
  // Action (biru)
  static const actionFill    = Color(0xFF3181E7); // 3.87:1 — ikon & bidang besar saja
  static const actionLabel   = Color(0xFF1A56B0); // 7.00:1 — teks & tombol bertulisan
  static const actionPressed = Color(0xFF1D5FC2); // 6.05:1 — state ditekan
  static const actionTint    = Color(0xFFEAF2FE); // isian lembut, item aktif

  // Positive (hijau — arah/aman)
  static const positiveFill  = Color(0xFF51B055); // ikon & bidang besar saja (putih gagal 2.75:1)
  static const positiveLabel = Color(0xFF1C6323); // teks "AMAN", isian chip zona aktif
  static const positiveTint  = Color(0xFFE8F4E9);

  // Critical (merah — bahaya)
  static const criticalFill  = Color(0xFFE5484D); // ikon oktagon, pita prioritas, garis bbox
  static const criticalLabel = Color(0xFFA82727); // teks "Bahaya", isian pill jarak
  static const criticalTint  = Color(0xFFFDECEC);

  // Warning (kuning — hati-hati). Kuning TIDAK PERNAH membawa teks putih.
  static const warningFill   = Color(0xFFF2A93C);
  static const warningLabel  = Color(0xFF7A4A00);
  static const warningTint   = Color(0xFFFFF6E9);

  // Pill / overlay di atas kamera
  static const pillBg = Color(0xFF202432); // ModeBadge, opaque

  // Netral
  static const bgPage      = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const ink1        = Color(0xFF16181F); // teks primer 17.8:1
  static const ink2        = Color(0xFF4A4E5A); // teks sekunder 8.3:1

  static const surfaceMuted = Color(0xFFF6F7F9); // panel abu lembut
  static const surfaceSunk  = Color(0xFFECEEF2); // disabled/bg, progress track
  static const disabledInk  = Color(0xFF6B707C);
  static const hairline     = Color(0xFFECEEF2);

  // Scrim di atas video kamera
  static const scrimText = Color(0xDB0B0D12); // #0B0D12 @ 86%
  static const scrimDim  = Color(0x660B0D12); // #0B0D12 @ 40% — tidak pernah membawa teks

  static Color dangerColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalFill,
        'warning'  => warningFill,
        _          => actionFill,
      };

  static Color dangerLabelColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalLabel,
        'warning'  => warningLabel,
        _          => actionLabel,
      };

  static Color dangerTintColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalTint,
        'warning'  => warningTint,
        _          => actionTint,
      };
}
```

---

## Berkas: `lib/theme/app_spacing.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_spacing.dart`

```dart
import 'package:flutter/material.dart';

/// Skala spacing 4-based. Jarak antar elemen interaktif = space2 (8),
/// antar blok informasi = space4 (16), antar kelompok = space6 (24).
abstract final class AppSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
  static const s8 = 40.0;
  static const s9 = 48.0;

  /// Margin kiri-kanan grid layar (393 dp frame → 20 dp margin, 353 dp konten).
  static const screenMargin = 20.0;
}

/// Skala radius. Kartu melayang r/lg, kartu-di-dalam-kartu r/sm,
/// pill & tombol bulat r/pill, bottom sheet r/sheet (dua sudut atas saja).
abstract final class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const sheet = 28.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const cardInner = BorderRadius.all(Radius.circular(sm));
  static const pillShape = BorderRadius.all(Radius.circular(pill));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Elevasi: elev/1 datar, elev/2 kartu, elev/3 sheet + FAB.
abstract final class AppElevation {
  static const flat = <BoxShadow>[
    BoxShadow(color: Color(0x14161819), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x1A161819), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x29161819), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -8),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x1F161819), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x42161819), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -12),
  ];
}

/// Target sentuh minimum & ukuran komponen tetap dari kontrak layout.
abstract final class AppSizes {
  static const minTouchTarget = 48.0;
  static const micButton = 64.0;
  static const fullScreenButtonHeight = 96.0;
  static const modeBadgeHeight = 40.0;
  static const bottomActionBarHeight = 88.0;
  static const statusBannerHeight = 56.0;
  static const alertCardShortHeight = 88.0;
  static const alertCardLongHeight = 112.0;
  static const iconStroke = 1.6;
}
```

---

## Berkas: `lib/theme/app_theme.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData Vinara — dirakit dari token di app_colors / app_typography /
/// app_spacing. Dipasang sekali di MaterialApp.theme.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.actionLabel,
        primary: AppColors.actionLabel,
        secondary: AppColors.actionFill,
        error: AppColors.criticalLabel,
        surface: AppColors.bgPage,
      ),
      scaffoldBackgroundColor: AppColors.bgPage,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTypography.headline(),
        titleLarge: AppTypography.title(),
        bodyLarge: AppTypography.body(),
        bodyMedium: AppTypography.body(),
        labelLarge: AppTypography.label(),
        bodySmall: AppTypography.caption(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.ink1,
        elevation: 0,
        titleTextStyle: AppTypography.title(),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink1, size: 24),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionLabel,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          textStyle: AppTypography.label(color: Colors.white),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillShape),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.actionLabel,
          side: const BorderSide(color: AppColors.actionLabel),
          minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          textStyle: AppTypography.label(color: AppColors.actionLabel),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionLabel,
          textStyle: AppTypography.label(color: AppColors.actionLabel),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: AppTypography.body(color: AppColors.ink2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.pillBg,
        contentTextStyle: AppTypography.body(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  /// Tema gelap — chrome Material (AppBar, tombol, snackbar, scaffold).
  /// Catatan: komponen desain sistem (AlertCard, ModeBadge, dst.) memakai
  /// token AppColors langsung sehingga tetap tampil dengan palet terang di
  /// atas kamera — itu memang benar untuk pill/kartu yang melayang di atas
  /// video, tapi permukaan non-kamera (Settings, Onboarding) mengikuti tema
  /// gelap lewat ThemeData ini.
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.actionFill,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF15171E),
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF15171E), elevation: 0),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2D38), thickness: 1, space: 1),
    );
  }

  /// Tema kontras tinggi — seluruh bayangan diganti garis 2 dp putih (bagian
  /// 3.4): kedalaman lewat bayangan tidak terbaca oleh sensitivitas kontras
  /// rendah.
  static ThemeData get highContrast {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        primary: Colors.white,
        surface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.black,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
      dividerTheme: const DividerThemeData(color: Colors.white, thickness: 1, space: 1),
    );
  }
}
```

---

## Berkas: `lib/theme/app_typography.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_typography.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Skala tipografi design system Vinara.
/// IBM Plex Sans untuk semua teks, IBM Plex Mono untuk angka teknis
/// (jarak, persentase, waktu) — dipakai bersama `tabularFigures` supaya
/// nominal tidak bergeser saat berubah. Fallback otomatis lewat GoogleFonts
/// (Noto Sans / Roboto), tidak pernah font geometris.
abstract final class AppTypography {
  static TextStyle _sans({
    required double fontSize,
    required double height,
    required FontWeight weight,
    required double letterSpacing,
    Color color = AppColors.ink1,
  }) =>
      GoogleFonts.ibmPlexSans(
        fontSize: fontSize,
        height: height / fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _mono({
    required double fontSize,
    required double height,
    required FontWeight weight,
    Color color = AppColors.ink1,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        height: height / fontSize,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle displayMoney({Color color = AppColors.ink1}) =>
      _sans(fontSize: 56, height: 60, weight: FontWeight.w700, letterSpacing: -1.5, color: color)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle headline({Color color = AppColors.ink1}) =>
      _sans(fontSize: 28, height: 34, weight: FontWeight.w700, letterSpacing: -0.4, color: color);

  static TextStyle title({Color color = AppColors.ink1}) =>
      _sans(fontSize: 22, height: 28, weight: FontWeight.w600, letterSpacing: -0.2, color: color);

  static TextStyle body({Color color = AppColors.ink1}) =>
      _sans(fontSize: 16, height: 24, weight: FontWeight.w400, letterSpacing: 0, color: color);

  static TextStyle bodyStrong({Color color = AppColors.ink1}) =>
      _sans(fontSize: 16, height: 24, weight: FontWeight.w600, letterSpacing: 0, color: color);

  static TextStyle label({Color color = AppColors.ink1}) =>
      _sans(fontSize: 14, height: 20, weight: FontWeight.w600, letterSpacing: 0.1, color: color);

  static TextStyle caption({Color color = AppColors.ink2}) =>
      _sans(fontSize: 12, height: 16, weight: FontWeight.w500, letterSpacing: 0.2, color: color);

  static TextStyle eyebrow({Color color = AppColors.ink2}) => _sans(
        fontSize: 12,
        height: 16,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle metricMono({Color color = AppColors.ink1}) =>
      _mono(fontSize: 14, height: 20, weight: FontWeight.w500, color: color);
}
```

---

## Berkas: `lib/theme/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/index.dart`

```dart
export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';
```

---

## Berkas: `lib/widgets/alert_card.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/alert_card.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'distance_pill.dart';
import 'tier_icon.dart';

/// AlertCard — kartu melayang di sepertiga bawah layar (F2).
/// Kartu putih opaque + Pita Prioritas 3 dp di tepi kiri dalam, warna
/// mengikuti tier. Tier terbaca dari bentuk ikon, bukan cuma warna.
class AlertCard extends StatelessWidget {
  final AlertTier tier;
  final String title;
  final String? description;
  final double? distanceMeter;
  final bool dense;

  const AlertCard({
    super.key,
    required this.tier,
    required this.title,
    this.description,
    this.distanceMeter,
    this.dense = false,
  });

  String get _liveLabel {
    final dist = distanceMeter == null
        ? ''
        : distanceMeter! < 1
            ? ', kurang dari satu meter'
            : ', ${distanceMeter!.toStringAsFixed(1)} meter';
    return '${tier.label}. $title$dist';
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 34.0 : 40.0;
    final pad = dense ? 14.0 : 16.0;

    return Semantics(
      liveRegion: true,
      label: _liveLabel,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: description == null ? 88 : 112),
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad).copyWith(left: 20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: -pad + 8,
              top: 4,
              bottom: 4,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: tier.fillColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment:
                  description == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Center(child: TierIcon(tier: tier, size: iconSize - 6)),
                ),
                const SizedBox(width: AppSpacing.s3 + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tier.label.toUpperCase(),
                          style: AppTypography.eyebrow(color: tier.labelColor)),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppTypography.bodyStrong(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: AppTypography.body(color: AppColors.ink2).copyWith(fontSize: 14, height: 20 / 14),
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
                if (distanceMeter != null) ...[
                  const SizedBox(width: AppSpacing.s3 + 2),
                  DistancePill(distanceMeter: distanceMeter!, tier: tier, compact: dense),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tumpukan AlertCard — maksimum 2, gap 8, tier tertinggi di slot bawah
/// (paling dekat ibu jari / BottomActionBar).
class AlertCardStack extends StatelessWidget {
  final List<Widget> cards;

  const AlertCardStack({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final shown = cards.take(2).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s2),
          shown[i],
        ],
      ],
    );
  }
}
```

---

## Berkas: `lib/widgets/bottom_action_bar.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/bottom_action_bar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../providers/index.dart';
import '../theme/index.dart';
import 'mode_picker_sheet.dart';

/// BottomActionBar (F3) — selalu ada, selalu di tempat yang sama, tidak
/// pernah menggulung. Tiga slot: Ambil Gambar 48, Bicara 64, Pilih Mode 48.
/// Saat mic aktif, dua tombol lain nonaktif — supaya tidak ada aksi
/// tabrakan sambil berjalan.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;
  final bool cameraEnabled;
  final String cameraLabel;
  /// DO-24 — izin mikrofon dicabut: nonaktifkan tombol Bicara sepenuhnya.
  final bool micEnabled;
  /// Saat mode aktif punya STT sendiri (mis. Cari Objek), timpa visual
  /// listening/processing bawaan `VoiceProvider` supaya tombol tetap sesuai
  /// dengan apa yang sesungguhnya sedang berjalan.
  final bool? listeningOverride;
  final bool? processingOverride;

  const BottomActionBar({
    super.key,
    this.onCameraPressed,
    this.onMicPressed,
    this.cameraEnabled = true,
    this.cameraLabel = 'Ambil gambar',
    this.micEnabled = true,
    this.listeningOverride,
    this.processingOverride,
  });

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final listening = listeningOverride ?? voice.isListening;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sideButtonsEnabled = cameraEnabled && !listening;

    return Container(
      height: AppSizes.bottomActionBarHeight + bottomInset,
      padding: EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s3, AppSpacing.s8, bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgPage,
        boxShadow: [
          BoxShadow(color: Color(0x0F161819), blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(color: Color(0x2E161819), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -12),
        ],
      ),
      // Urutan fokus 7-8-9 (bagian 10) dipasang eksplisit: reposisi tombol di
      // layar lain tidak boleh menggeser urutan tiga tombol ini, karena
      // kekekalannya adalah satu-satunya peta yang dimiliki pengguna.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            sortKey: const OrdinalSortKey(7),
            child: _SquareButton(
              icon: Icons.camera_alt_outlined,
              label: cameraLabel,
              enabled: sideButtonsEnabled,
              onTap: onCameraPressed ?? () {},
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(8),
            child: _MicButton(
              onTap: onMicPressed,
              enabled: micEnabled,
              listeningOverride: listeningOverride,
              processingOverride: processingOverride,
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(9),
            child: _SquareButton(
              icon: Icons.apps_rounded,
              label: 'Pilih mode',
              enabled: !listening,
              onTap: () => showModePickerSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;
  final bool? listeningOverride;
  final bool? processingOverride;
  const _MicButton({this.onTap, this.enabled = true, this.listeningOverride, this.processingOverride});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    if (!enabled) {
      return Semantics(
        button: true,
        label: 'Bicara, tidak tersedia, izin mikrofon belum diberikan',
        child: Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceSunk),
          child: const Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: 28),
        ),
      );
    }
    final listening = listeningOverride ?? voice.isListening;
    final processing = processingOverride ?? voice.isProcessing;

    final semanticLabel = processing
        ? 'Bicara, sedang memproses'
        : listening
            ? 'Berhenti bicara'
            : 'Bicara';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: processing
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                final v = context.read<VoiceProvider>();
                final hasVib = await Vibration.hasVibrator();
                if (hasVib) Vibration.vibrate(duration: 100);
                if (onTap != null) {
                  onTap!();
                } else if (v.isListening) {
                  v.stopListening();
                } else {
                  v.startListening();
                }
              },
        child: Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: processing ? AppColors.actionTint : AppColors.actionFill,
            boxShadow: listening
                ? [
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .18), blurRadius: 0, spreadRadius: 8),
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .10), blurRadius: 0, spreadRadius: 16),
                  ]
                : [
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .36), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.actionLabel),
                )
              : Icon(listening ? Icons.mic : Icons.mic_none_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, tidak tersedia',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 26,
              color: enabled ? AppColors.ink1 : AppColors.disabledInk,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/camera_health_toast.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/camera_health_toast.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// CameraHealthToast (5.10) — pill gelap melayang, instruksi fisik dan
/// konkret ("miringkan sedikit"), bukan abstrak. Tidak fokusable; live
/// region polite.
enum CameraHealthIssue { dark, blurry, covered, tilted }

extension CameraHealthIssueX on CameraHealthIssue {
  String get message => switch (this) {
        CameraHealthIssue.dark    => 'Terlalu gelap. Cari cahaya lebih terang.',
        CameraHealthIssue.blurry  => 'Gambar buram, tahan lebih stabil.',
        CameraHealthIssue.covered => 'Ada yang menutupi lensa.',
        CameraHealthIssue.tilted  => 'Angkat ponsel sedikit.',
      };
}

class CameraHealthToast extends StatelessWidget {
  final CameraHealthIssue issue;

  const CameraHealthToast({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: issue.message,
      focusable: false,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Center(
          child: Text(
            issue.message,
            style: AppTypography.body(color: Colors.white).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/chat_bubble.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/chat_bubble.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ChatBubble (5.12) — Mode Asisten Suara. Giliran dipisah garis, bukan
/// gelembung berwarna. Live region polite, MergeSemantics per giliran.
enum ChatSpeaker { user, vinara }

class ChatBubble extends StatelessWidget {
  final ChatSpeaker speaker;
  final String text;
  /// Giliran terbaru mendapat live region — bagian 12 "AS-12: hanya giliran
  /// terbaru dibacakan".
  final bool isLatest;

  const ChatBubble({super.key, required this.speaker, required this.text, this.isLatest = false});

  String get _speakerLabel => speaker == ChatSpeaker.user ? 'Kamu' : 'Vinara';
  Color get _speakerColor => speaker == ChatSpeaker.user ? AppColors.ink2 : AppColors.actionLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isLatest,
      child: MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_speakerLabel,
                  style: AppTypography.label(color: _speakerColor).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(text, style: AppTypography.body()),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.hairline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar giliran percakapan — membungkus scroll + aturan ringkas riwayat
/// (AS-13: 8 giliran diringkas).
class ChatTranscript extends StatelessWidget {
  final List<ChatBubble> turns;
  final double maxHeight;

  const ChatTranscript({super.key, required this.turns, this.maxHeight = 320});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: turns),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/detection_card.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/detection_card.dart`

```dart
import 'package:flutter/material.dart';

import '../models/detection.dart';
import 'alert_card.dart';
import 'tier_icon.dart';

/// Adapter: Detection (domain model) → AlertCard (design system).
class DetectionCard extends StatelessWidget {
  final Detection detection;
  const DetectionCard({super.key, required this.detection});

  String get _title {
    final label = detection.labelId.isEmpty ? 'Objek' : _capitalize(detection.labelId);
    return '$label di ${detection.direction}';
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return AlertCard(
      tier: AlertTierX.fromDangerLevel(detection.dangerLevel),
      title: _title,
      distanceMeter: detection.distanceMeter,
    );
  }
}
```

---

## Berkas: `lib/widgets/distance_pill.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/distance_pill.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// Pill jarak bertulisan mono, dipakai di AlertCard & label bounding box.
/// Warna isian & teks mengikuti aturan kontras per tier:
/// Critical → isian pekat + teks putih, Warning → isian vibrant + teks ink
/// (putih gagal 2:1 di atas kuning), Info → isian tint + teks label.
class DistancePill extends StatelessWidget {
  final double distanceMeter;
  final AlertTier tier;
  final bool compact;

  const DistancePill({
    super.key,
    required this.distanceMeter,
    required this.tier,
    this.compact = false,
  });

  Color get _bg => switch (tier) {
        AlertTier.critical => AppColors.criticalLabel,
        AlertTier.warning  => AppColors.warningFill,
        AlertTier.info     => AppColors.actionTint,
        AlertTier.positive => AppColors.positiveLabel,
      };

  Color get _fg => switch (tier) {
        AlertTier.critical => Colors.white,
        AlertTier.warning  => AppColors.ink1,
        AlertTier.info     => AppColors.actionLabel,
        AlertTier.positive => Colors.white,
      };

  String get _text {
    final value = distanceMeter < 1.0
        ? '${(distanceMeter * 100).round()} cm'
        : '${distanceMeter.toStringAsFixed(1)} m';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 10, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(color: _bg, borderRadius: AppRadius.pillShape),
      child: Text(_text, style: AppTypography.metricMono(color: _fg)),
    );
  }
}
```

---

## Berkas: `lib/widgets/full_screen_button.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/full_screen_button.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// FullScreenButton (5.4) — tombol aksi tunggal yang sangat besar, 96 dp.
/// Dipakai untuk aksi utama satu-jari: jepret di Mode Baca Teks, izin di
/// PermissionCard, dst.
class FullScreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  /// Wajib diisi saat [disabled] — bagian 5.4: tombol disabled selalu
  /// menyebut alasannya sebagai baris di bawah teks.
  final String? disabledReason;
  final IconData? icon;

  const FullScreenButton({
    super.key,
    required this.label,
    this.onTap,
    this.disabled = false,
    this.disabledReason,
    this.icon,
  }) : assert(!disabled || disabledReason != null,
            'disabledReason wajib diisi saat tombol disabled');

  @override
  Widget build(BuildContext context) {
    final semanticLabel = disabled ? '$label, tidak tersedia, $disabledReason' : label;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppRadius.card,
          child: Ink(
            height: AppSizes.fullScreenButtonHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: disabled ? AppColors.surfaceSunk : AppColors.actionLabel,
              borderRadius: AppRadius.card,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.actionLabel.withValues(alpha: .32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: disabled ? AppColors.disabledInk : Colors.white, size: 26),
                        const SizedBox(width: AppSpacing.s3),
                      ],
                      Text(
                        label,
                        style: AppTypography.title(
                          color: disabled ? AppColors.disabledInk : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (disabled && disabledReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      disabledReason!,
                      style: AppTypography.caption(color: AppColors.disabledInk),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/guide_frame.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/guide_frame.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// GuideFrame (F11) — empat busur sudut yang mengencang saat objek makin
/// pas, bukan persegi putus-putus statis (itu pola kamera QR dan tidak
/// mengabarkan apa pun).
enum FrameFit { empty, partial, fit, tooClose }

extension FrameFitX on FrameFit {
  Color get color => switch (this) {
        FrameFit.empty   => Colors.white,
        FrameFit.partial => AppColors.warningFill,
        FrameFit.fit     => AppColors.positiveFill,
        FrameFit.tooClose => AppColors.criticalFill,
      };

  double get armLength => switch (this) {
        FrameFit.empty    => 28,
        FrameFit.partial  => 32,
        FrameFit.fit      => 40,
        FrameFit.tooClose => 40,
      };

  double get inset => switch (this) {
        FrameFit.empty    => 34,
        FrameFit.partial  => 32,
        FrameFit.fit      => 30,
        FrameFit.tooClose => 14,
      };

  String get caption => switch (this) {
        FrameFit.empty    => 'Arahkan ke objek',
        FrameFit.partial  => 'Geser ponsel ke tengah',
        FrameFit.fit      => 'Posisi pas, tahan sebentar',
        FrameFit.tooClose => 'Terlalu dekat, jauhkan sedikit',
      };
}

class GuideFrame extends StatelessWidget {
  final FrameFit fit;
  final bool showCaption;

  const GuideFrame({super.key, required this.fit, this.showCaption = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: fit.caption,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CornerPainter(inset: fit.inset, arm: fit.armLength, color: fit.color)),
          ),
          if (showCaption)
            Positioned(
              left: 0, right: 0, bottom: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
                  child: Text(fit.caption, style: AppTypography.caption(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double inset;
  final double arm;
  final Color color;

  _CornerPainter({required this.inset, required this.arm, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const r = 14.0;

    void corner(Offset origin, {required bool right, required bool bottom}) {
      final dx = right ? -1.0 : 1.0;
      final dy = bottom ? -1.0 : 1.0;
      final path = Path()
        ..moveTo(origin.dx, origin.dy + dy * arm)
        ..lineTo(origin.dx, origin.dy + dy * r)
        ..arcToPoint(
          Offset(origin.dx + dx * r, origin.dy),
          radius: const Radius.circular(r),
          clockwise: right != bottom,
        )
        ..lineTo(origin.dx + dx * arm, origin.dy);
      canvas.drawPath(path, paint);
    }

    corner(Offset(inset, inset), right: false, bottom: false);
    corner(Offset(size.width - inset, inset), right: true, bottom: false);
    corner(Offset(inset, size.height - inset), right: false, bottom: true);
    corner(Offset(size.width - inset, size.height - inset), right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.inset != inset || oldDelegate.arm != arm || oldDelegate.color != color;
}
```

---

## Berkas: `lib/widgets/index.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/index.dart`

```dart
export 'alert_card.dart';
export 'bottom_action_bar.dart';
export 'camera_health_toast.dart';
export 'chat_bubble.dart';
export 'detection_card.dart';
export 'distance_pill.dart';
export 'full_screen_button.dart';
export 'guide_frame.dart';
export 'mode_badge.dart';
export 'mode_picker_sheet.dart';
export 'nominal_card.dart';
export 'page_action_zone.dart';
export 'permission_card.dart';
export 'result_panel.dart';
export 'speaking_indicator.dart';
export 'status_banner.dart';
export 'target_chip.dart';
export 'tier_icon.dart';
export 'voice_orb.dart';
export 'zone_indicator.dart';
```

---

## Berkas: `lib/widgets/mode_badge.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/mode_badge.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../providers/app_mode_provider.dart';
import '../theme/index.dart';

/// Ikon garis per mode — dipakai bersama oleh ModeBadge & ModePickerSheet.
IconData modeIcon(AppMode mode) => switch (mode) {
      AppMode.tuntun     => Icons.remove_red_eye_outlined,
      AppMode.money      => Icons.payments_outlined,
      AppMode.ocr        => Icons.article_outlined,
      AppMode.navigasi   => Icons.explore_outlined,
      AppMode.voice      => Icons.mic_none_rounded,
      AppMode.findObject => Icons.search_rounded,
    };

/// ModeBadge (F1) — pill identitas mode, opaque #202432, di atas kamera.
/// Bukan tombol untuk ganti mode (itu lewat tombol Pilih Mode / suara), tapi
/// ketuk 5× membuka panel debug tersembunyi (state switcher) bila disediakan
/// lewat [onDebugActivate] — mekanisme baku bagian 2 "Cara memalsukan fitur".
class ModeBadge extends StatefulWidget {
  final AppMode mode;
  final bool transitioning;
  final bool busy;
  final VoidCallback? onDebugActivate;

  const ModeBadge({
    super.key,
    required this.mode,
    this.transitioning = false,
    this.busy = false,
    this.onDebugActivate,
  });

  @override
  State<ModeBadge> createState() => _ModeBadgeState();
}

class _ModeBadgeState extends State<ModeBadge> {
  int _tapCount = 0;
  Timer? _tapResetTimer;

  void _onTap() {
    if (widget.onDebugActivate == null) return;
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(milliseconds: 800), () => _tapCount = 0);
    if (_tapCount >= 5) {
      _tapCount = 0;
      widget.onDebugActivate!();
    }
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  IconData get _icon => modeIcon(widget.mode);

  String get _label {
    if (widget.transitioning) return 'Berpindah ke mode ${widget.mode.label}';
    if (widget.busy) return 'Mode aktif: ${widget.mode.label}, sedang mengenali';
    return 'Mode aktif: ${widget.mode.label}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 3 — bagian 10, sesudah StatusBanner dan aksinya.
      sortKey: const OrdinalSortKey(3),
      header: true,
      label: _label,
      liveRegion: widget.transitioning || widget.busy,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: Container(
            key: ValueKey('${widget.mode.name}-${widget.transitioning}-${widget.busy}'),
            height: AppSizes.modeBadgeHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(color: AppColors.pillBg, borderRadius: AppRadius.pillShape),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.transitioning
                  ? [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Beralih ke ${widget.mode.label}…',
                          style: AppTypography.metricMono(color: Colors.white.withValues(alpha: .9))),
                    ]
                  : widget.busy
                      ? [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Mengenali…', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ]
                      : [
                          Icon(_icon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Mode: ${widget.mode.label}', style: AppTypography.label(color: Colors.white)),
                        ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/mode_picker_sheet.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/mode_picker_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../screens/settings_screen.dart';
import '../theme/index.dart';
import 'mode_badge.dart';

/// ModePickerSheet (5.5) — enam mode, cadangan untuk situasi tidak bisa
/// bicara. Fokus terkunci di dalam sheet; setelah ditutup, fokus kembali ke
/// tombol Pilih Mode (ditangani otomatis oleh showModalBottomSheet).
///
/// Keputusan audit: Navigasi TIDAK PERNAH dinonaktifkan offline — deteksi
/// rintangan on-device tetap hidup, jadi statenya `limited` dengan alasan
/// "Tanpa internet: rintangan saja". Cari Objek yang benar-benar disabled.
void showModePickerSheet(BuildContext context) {
  // Ditanyakan saat sheet dibuka, bukan saat item ditekan — status harus
  // sudah terbaca sebelum pengguna memilih. Tidak di-await: sheet tampil
  // segera, dan item memperbarui dirinya begitu jawaban datang.
  context.read<CapabilitiesProvider>().refreshIfStale(
        offline: context.read<GlobalConditionsProvider>().isOffline,
      );

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceMuted,
    barrierColor: AppColors.scrimDim,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    constraints: const BoxConstraints(maxHeight: 620),
    builder: (_) => const _ModePickerSheet(),
  );
}

class _ModePickerSheet extends StatelessWidget {
  const _ModePickerSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppModeProvider>().mode;
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final caps = context.watch<CapabilitiesProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Semantics(
              header: true,
              child: Text('Pilih Mode', style: AppTypography.title()),
            ),
            const SizedBox(height: 4),
            Text('atau ucapkan nama mode', style: AppTypography.caption()),
            const SizedBox(height: AppSpacing.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppMode.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
                itemBuilder: (_, i) {
                  final mode = AppMode.values[i];
                  // Status ditentukan jaringan DAN jawaban server, ditanyakan
                  // sebelum sheet dibuka — bukan ditebak dari koneksi saja.
                  final state = caps.stateOf(mode, offline: offline);
                  final disabled = state == CapState.down;
                  final limited = state == CapState.limited && mode != current;

                  return _ModeTile(
                    mode: mode,
                    isCurrent: mode == current,
                    disabled: disabled,
                    limited: limited,
                    reason: caps.unavailableReason(mode, offline: offline),
                    onTap: disabled
                        ? null
                        : () {
                            context.read<AppModeProvider>().setMode(mode);
                            Navigator.pop(context);
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            // Layar penunjang bukan saudara mode, jadi ia TIDAK muncul sebagai
            // item mode. Tempatnya di paling bawah sheet, dipisah garis —
            // bagian 2 ALUR-DAN-TOMBOL.md. Tanpa ini Pengaturan sama sekali
            // tidak punya pintu masuk di layar: satu-satunya jalan adalah
            // perintah suara, dan itu memutus pengguna yang tidak bisa bicara.
            const Divider(height: AppSpacing.s4, color: AppColors.hairline),
            Semantics(
              button: true,
              label: 'Pengaturan',
              child: Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                          child: const Icon(Icons.tune_rounded, size: 22, color: AppColors.ink1),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text('Pengaturan', style: AppTypography.body())),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup pilihan mode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final AppMode mode;
  final bool isCurrent;
  final bool disabled;
  final bool limited;

  /// Alasan dari server (`/api/capabilities`), supaya perbaikan naskah tidak
  /// perlu rilis ulang aplikasi.
  final String? reason;
  final VoidCallback? onTap;

  const _ModeTile({
    required this.mode,
    required this.isCurrent,
    required this.onTap,
    this.disabled = false,
    this.limited = false,
    this.reason,
  });

  String? get _reason => reason;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isCurrent
        ? '${mode.label}, sedang aktif'
        : _reason != null
            ? '${mode.label}, ${_reason!.toLowerCase()}'
            : mode.label;

    return Semantics(
      button: true,
      enabled: !disabled,
      selected: isCurrent,
      label: semanticLabel,
      child: Opacity(
        opacity: disabled ? .6 : 1,
        child: Material(
          color: isCurrent ? AppColors.actionTint : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: isCurrent ? null : AppElevation.flat,
              ),
              child: Row(
                children: [
                  if (isCurrent)
                    Container(
                      width: 3, height: 40,
                      margin: const EdgeInsets.only(right: 11),
                      decoration: BoxDecoration(
                        color: AppColors.actionFill,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 14),
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                    child: Icon(modeIcon(mode), size: 22, color: AppColors.ink1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mode.label,
                          style: isCurrent ? AppTypography.bodyStrong() : AppTypography.body(),
                        ),
                        if (_reason != null)
                          Text(
                            _reason!,
                            style: AppTypography.caption(
                              color: limited ? AppColors.warningLabel : AppColors.disabledInk,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.actionLabel,
                        borderRadius: AppRadius.pillShape,
                      ),
                      child: Text('AKTIF', style: AppTypography.eyebrow(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/nominal_card.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/nominal_card.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Terbilang rupiah — "angka rupiah selalu dibacakan penuh dalam kata, tidak
/// pernah 'seratus rb'" (bagian 9 & 17). Dipakai NominalCard dan naskah TTS.
String terbilangRupiah(int amount) {
  if (amount == 0) return 'nol rupiah';
  return '${_terbilang(amount)} rupiah';
}

const _satuan = [
  '', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan',
  'sepuluh', 'sebelas',
];

String _terbilang(int n) {
  if (n < 12) return _satuan[n];
  if (n < 20) return '${_terbilang(n - 10)} belas';
  if (n < 100) {
    final sisa = n % 10;
    return '${_terbilang(n ~/ 10)} puluh${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 200) return 'seratus${n == 100 ? '' : ' ${_terbilang(n - 100)}'}';
  if (n < 1000) {
    final sisa = n % 100;
    return '${_terbilang(n ~/ 100)} ratus${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 2000) return 'seribu${n == 1000 ? '' : ' ${_terbilang(n - 1000)}'}';
  if (n < 1000000) {
    final sisa = n % 1000;
    return '${_terbilang(n ~/ 1000)} ribu${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 1000000000) {
    final sisa = n % 1000000;
    return '${_terbilang(n ~/ 1000000)} juta${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  final sisa = n % 1000000000;
  return '${_terbilang(n ~/ 1000000000)} miliar${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
}

String formatRupiah(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

/// NominalCard (5.13) — khusus Mode Kenali Uang. Satu-satunya tempat
/// `display` 56sp dipakai. Nominal WAJIB dua bentuk (angka + kata), dan
/// tidak pernah ditampilkan saat keyakinan rendah — pemanggil bertanggung
/// jawab tidak me-render kartu ini pada kondisi itu.
class NominalCard extends StatelessWidget {
  final int amount;
  /// Rincian per lembar, mis. {20000: 2, 5000: 1} — opsional, untuk
  /// UG-09b "beberapa lembar berbeda".
  final Map<int, int>? breakdown;
  /// Total berjalan (UG-11 "lembar berturut-turut") — opsional.
  final int? runningTotal;
  final VoidCallback? onReplay;

  const NominalCard({
    super.key,
    required this.amount,
    this.breakdown,
    this.runningTotal,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final words = terbilangRupiah(amount);
    final formatted = formatRupiah(amount);

    return Semantics(
      header: true,
      liveRegion: true,
      label: '$formatted, $words',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: AppTypography.displayMoney(),
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                words,
                textAlign: TextAlign.center,
                style: AppTypography.title(color: AppColors.ink2),
              ),
            ),
            if (breakdown != null && breakdown!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.s2,
                runSpacing: 4,
                children: breakdown!.entries
                    .map((e) => Text(
                          '${e.value} × ${formatRupiah(e.key)}',
                          style: AppTypography.metricMono(color: AppColors.ink2),
                        ))
                    .toList(),
              ),
            ],
            if (runningTotal != null) ...[
              const SizedBox(height: AppSpacing.s3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
                decoration: const BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.pillShape),
                child: Text('Total: ${formatRupiah(runningTotal!)}',
                    style: AppTypography.label().copyWith(fontSize: 14)),
              ),
            ],
            if (onReplay != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Semantics(
                button: true,
                label: 'Putar ulang nominal',
                child: InkWell(
                  onTap: onReplay,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                    child: const Icon(Icons.replay_rounded, color: AppColors.actionLabel),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/ocr_debug_sheet.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/ocr_debug_sheet.dart`

```dart
import 'package:flutter/material.dart';

import '../mock/ocr_mock_data.dart';
import '../theme/index.dart';

/// OcrDebugSheet — bottom sheet QA khusus Mode Baca Teks: daftar 22 state
/// BT-01..BT-22 (bagian 8). Memilih satu item memaksa tampilan lokal
/// `ocr_screen.dart` ke kondisi itu (data mock) sampai dibatalkan — dibuka
/// lewat ketuk 5× pada [ModeBadge] (`onDebugActivate`).
Future<void> showOcrDebugSheet(
  BuildContext context, {
  required String? activeId,
  required ValueChanged<String> onSelect,
  required VoidCallback onCancel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OcrDebugSheetContent(
      activeId: activeId,
      onSelect: (id) {
        Navigator.of(ctx).pop();
        onSelect(id);
      },
      onCancel: () {
        Navigator.of(ctx).pop();
        onCancel();
      },
    ),
  );
}

class _OcrDebugSheetContent extends StatelessWidget {
  final String? activeId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCancel;

  const _OcrDebugSheetContent({
    required this.activeId,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(bottom: media.viewInsets.bottom),
        constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.sheetTop,
          boxShadow: AppElevation.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s4, AppSpacing.screenMargin, AppSpacing.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Debug — Mode Baca Teks', style: AppTypography.title()),
                  ),
                  if (activeId != null)
                    GestureDetector(
                      onTap: onCancel,
                      child: Semantics(
                        button: true,
                        label: 'Batalkan mode debug',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.criticalTint, borderRadius: AppRadius.pillShape),
                          child: Text('Batalkan', style: AppTypography.label(color: AppColors.criticalLabel)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (activeId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Aktif: $activeId', style: AppTypography.caption(color: AppColors.actionLabel)),
                ),
              ),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
                itemCount: ocrDebugCatalog.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairline),
                itemBuilder: (context, i) {
                  final entry = ocrDebugCatalog[i];
                  final active = entry.id == activeId;
                  return Semantics(
                    button: true,
                    label: '${entry.id}, ${entry.title}. ${entry.hint}',
                    child: ListTile(
                      onTap: () => onSelect(entry.id),
                      tileColor: active ? AppColors.actionTint : Colors.transparent,
                      leading: SizedBox(
                        width: 52,
                        child: Text(entry.id, style: AppTypography.metricMono(color: AppColors.actionLabel)),
                      ),
                      title: Text(entry.title, style: AppTypography.bodyStrong()),
                      subtitle: Text(entry.hint, style: AppTypography.caption()),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.s3 + media.padding.bottom),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/ocr_long_result_panel.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/ocr_long_result_panel.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// Satu blok siap-render untuk [OcrLongResultPanel] — kalimatnya sudah
/// dipecah oleh pemanggil (ocr_screen.dart) supaya panel ini tidak perlu
/// tahu aturan pemisahan kalimat, cuma menyorot kalimat aktif.
class OcrRenderBlock {
  final String heading;
  final String? language;
  final bool ok;
  final List<String> sentences;

  /// Index kalimat aktif di dalam blok ini, -1 kalau tidak ada yang aktif.
  final int activeLocalIndex;

  const OcrRenderBlock({
    required this.heading,
    required this.sentences,
    this.language,
    this.ok = true,
    this.activeLocalIndex = -1,
  });
}

/// OcrLongResultPanel — varian ResultPanel khusus hasil panjang/dua
/// bahasa/sebagian-gagal/senyap Mode Baca Teks (BT-07/08/09/10/12a/19).
/// ResultPanel (komponen sistem, read-only) sengaja tidak dipakai di sini
/// karena butuh: blok berheading, progress baca, dan kontrol yang berubah
/// bentuk saat senyap — di luar API ResultPanel.
class OcrLongResultPanel extends StatelessWidget {
  final List<OcrRenderBlock> blocks;
  final bool speaking;
  final bool paused;
  final double? progress; // null = sembunyikan progress bar
  final double maxContentHeight;
  final bool muted; // BT-19: kontrol jadi tombol gulung, bukan audio
  final bool vertical; // BT-18: font scale 200% → kontrol 56dp, susun vertikal
  final ScrollController? scrollController;

  final VoidCallback? onTogglePlayback; // jeda / lanjut
  final VoidCallback? onReplay; // ulangi dari awal
  final String? tertiaryLabel; // mis. "Bicara ke Asisten"
  final VoidCallback? onTertiary;

  const OcrLongResultPanel({
    super.key,
    required this.blocks,
    this.speaking = false,
    this.paused = false,
    this.progress,
    this.maxContentHeight = 280,
    this.muted = false,
    this.vertical = false,
    this.scrollController,
    this.onTogglePlayback,
    this.onReplay,
    this.tertiaryLabel,
    this.onTertiary,
  });

  int get _controlSize => vertical ? 56 : 48;

  @override
  Widget build(BuildContext context) {
    final eyebrow = speaking
        ? 'Sedang dibacakan'
        : paused
            ? 'Dijeda'
            : 'HASIL BACA';
    final eyebrowColor = speaking ? AppColors.actionLabel : AppColors.ink2;
    final failedCount = blocks.where((b) => !b.ok).length;

    return Semantics(
      liveRegion: true,
      label: '$eyebrow. ${blocks.where((b) => b.ok).map((b) => b.sentences.join(' ')).join(' ')}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(eyebrow, eyebrowColor),
            if (failedCount > 0) ...[
              const SizedBox(height: AppSpacing.s2),
              _partialBanner(failedCount, blocks.length),
            ],
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _progressBar(),
            ],
            const SizedBox(height: AppSpacing.s3),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxContentHeight),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < blocks.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.s4),
                      _block(blocks[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            muted ? _scrollControls() : _audioControls(),
          ],
        ),
      ),
    );
  }

  Widget _header(String eyebrow, Color eyebrowColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(eyebrow, style: AppTypography.eyebrow(color: eyebrowColor))),
        if (!muted && (speaking || paused)) _playPauseButton(),
      ],
    );
  }

  Widget _partialBanner(int failedCount, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AlertTier.warning.tintColor, borderRadius: AppRadius.cardInner),
      child: Row(
        children: [
          TierIcon(tier: AlertTier.warning, size: 20),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              '${total - failedCount} dari $total bagian terbaca. Bagian lain buram atau tertutup.',
              style: AppTypography.body(color: AlertTier.warning.labelColor).copyWith(fontSize: 14, height: 20 / 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final v = progress!.clamp(0.0, 1.0);
    return Semantics(
      label: 'Progres baca ${(v * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: AppColors.surfaceSunk,
          valueColor: const AlwaysStoppedAnimation(AppColors.actionLabel),
        ),
      ),
    );
  }

  Widget _block(OcrRenderBlock block) {
    final baseColor = block.ok ? AppColors.ink1 : AppColors.disabledInk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(block.heading.toUpperCase(),
                  style: AppTypography.caption(color: AppColors.ink2).copyWith(fontWeight: FontWeight.w700)),
            ),
            if (block.language != null) ...[
              const SizedBox(width: AppSpacing.s2),
              _languagePill(block.language!),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (!block.ok)
          Text('Bagian ini tidak terbaca.', style: AppTypography.body(color: AppColors.disabledInk))
        else
          RichText(
            text: TextSpan(
              style: AppTypography.body(color: baseColor),
              children: [
                for (var i = 0; i < block.sentences.length; i++)
                  TextSpan(
                    text: '${block.sentences[i]} ',
                    style: i == block.activeLocalIndex
                        ? const TextStyle(backgroundColor: AppColors.actionTint, color: AppColors.ink1)
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _languagePill(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.actionTint, borderRadius: AppRadius.pillShape),
      child: Text(language, style: AppTypography.caption(color: AppColors.actionLabel)),
    );
  }

  Widget _playPauseButton() {
    return GestureDetector(
      onTap: onTogglePlayback,
      child: Semantics(
        button: true,
        label: speaking ? 'Jeda pembacaan' : 'Lanjutkan pembacaan',
        child: Container(
          width: _controlSize.toDouble(),
          height: _controlSize.toDouble(),
          decoration: BoxDecoration(
            color: speaking ? AppColors.actionLabel : AppColors.actionTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: speaking ? Colors.white : AppColors.actionLabel,
          ),
        ),
      ),
    );
  }

  Widget _audioControls() {
    final buttons = [
      _pill(
        label: paused ? 'Lanjut' : (speaking ? 'Jeda' : 'Putar'),
        icon: paused || !speaking ? Icons.play_arrow_rounded : Icons.pause_rounded,
        filled: true,
        onTap: onTogglePlayback,
      ),
      _pill(label: 'Ulangi', icon: Icons.replay_rounded, filled: false, onTap: onReplay),
      if (tertiaryLabel != null) _pill(label: tertiaryLabel!, icon: Icons.mic_none_rounded, filled: false, onTap: onTertiary),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s2),
                buttons[i],
              ],
            ],
          )
        : Wrap(spacing: AppSpacing.s2, runSpacing: AppSpacing.s2, children: buttons);
  }

  Widget _scrollControls() {
    final buttons = [
      _pill(
        label: 'Gulir naik',
        icon: Icons.keyboard_arrow_up_rounded,
        filled: false,
        onTap: () => scrollController?.animateTo(
          (scrollController!.offset - 200).clamp(0, scrollController!.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      ),
      _pill(
        label: 'Gulir turun',
        icon: Icons.keyboard_arrow_down_rounded,
        filled: false,
        onTap: () => scrollController?.animateTo(
          (scrollController!.offset + 200).clamp(0, scrollController!.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      ),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(height: AppSpacing.s2), buttons[1]],
          )
        : Row(children: [Expanded(child: buttons[0]), const SizedBox(width: AppSpacing.s2), Expanded(child: buttons[1])]);
  }

  Widget _pill({required String label, required IconData icon, required bool filled, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _controlSize.toDouble(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.actionLabel : AppColors.actionTint,
            borderRadius: AppRadius.pillShape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: filled ? Colors.white : AppColors.actionLabel),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.label(color: filled ? Colors.white : AppColors.actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/page_action_zone.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/page_action_zone.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// `zone/page-action` — bagian 6 ALUR-DAN-TOMBOL.md.
///
/// Kontrak zona di IMPLEMENTASI.md dirancang untuk enam mode, yang semuanya
/// diakhiri `BottomActionBar` 112 dp. Layar penunjang — Pengaturan,
/// Onboarding, Izin — tidak punya bar itu, jadi tidak ada zona yang menampung
/// tombol aksi halaman; itu sebabnya tombol seperti "Uji koneksi" dulu
/// berakhir menempel di kolom isian, di sepertiga atas layar.
///
/// Zona ini menempel di dasar layar: 96 dp tombol + 24 dp safe area = 120 dp.
/// Isinya **satu** tombol aksi utama, opsional satu tombol sekunder 56 dp di
/// atasnya dengan jarak 8 dp.
///
/// **Tidak pernah hadir bersamaan dengan `BottomActionBar`.** Sebuah layar
/// punya salah satu, tidak pernah keduanya. Layar mode memakai
/// [bottomCardSlotOffset] sebagai gantinya.
///
/// Sekunder digambar **di atas** primer, dan karena itu juga dibaca TalkBack
/// lebih dulu — urutan fokus bagian 10 nomor 10 lalu 11. Urutan itu dipasang
/// eksplisit lewat [SemanticsSortKey]; di Flutter urutan fokus tidak otomatis
/// mengikuti posisi visual.
class PageActionZone extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDisabled;

  /// Wajib diisi saat [primaryDisabled] — bagian 5.4: tombol nonaktif selalu
  /// menyebut alasannya, dan alasan itu ikut dibacakan sebagai bagian nilai.
  final String? primaryDisabledReason;
  final IconData? primaryIcon;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Titik awal urutan fokus zona ini. Sekunder = [sortOrder], primer =
  /// [sortOrder] + 1. Baku 100 supaya selalu jatuh sesudah seluruh isi
  /// halaman, berapa pun jumlah kontrol inline di atasnya.
  final double sortOrder;

  const PageActionZone({
    super.key,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryDisabled = false,
    this.primaryDisabledReason,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.sortOrder = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondaryLabel != null) ...[
              Semantics(
                sortKey: OrdinalSortKey(sortOrder),
                child: VinaraSecondaryButton(
                  label: secondaryLabel!,
                  onTap: onSecondary,
                ),
              ),
              const SizedBox(height: ZoneHeights.pageActionGap),
            ],
            Semantics(
              sortKey: OrdinalSortKey(sortOrder + 1),
              child: FullScreenButton(
                label: primaryLabel,
                onTap: onPrimary,
                disabled: primaryDisabled,
                disabledReason: primaryDisabledReason,
                icon: primaryIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol sekunder 56 dp untuk `zone/page-action` — "Lewati panduan",
/// "Ulangi langkah ini", "Keluar dari aplikasi". Lebar penuh supaya target
/// sentuhnya sama besarnya dengan primer; yang membedakan hanya bobot visual,
/// bukan kemudahan dijangkau.
class VinaraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const VinaraSecondaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Ink(
            height: ZoneHeights.pageActionSecondary,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: AppRadius.card,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.label(
                  color: onTap == null ? AppColors.disabledInk : AppColors.ink1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold layar penunjang: isi halaman + [PageActionZone] menempel di dasar.
/// Zona dipasang lewat `bottomNavigationBar` supaya ia sticky saat [body]
/// digulung — aksi utama halaman wajib terjangkau **tanpa** pengguna
/// menggulung (bagian 5 "Aturan penempatan").
class PageActionScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDisabled;
  final String? primaryDisabledReason;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Banner kondisi global (StatusBanner), digambar di atas [body] tanpa
  /// menggeser zona aksi.
  final Widget? statusBanner;

  const PageActionScaffold({
    super.key,
    required this.body,
    required this.primaryLabel,
    this.appBar,
    this.backgroundColor,
    this.onPrimary,
    this.primaryDisabled = false,
    this.primaryDisabledReason,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.statusBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.bgPage,
      appBar: appBar,
      body: statusBanner == null
          ? body
          : Column(children: [statusBanner!, Expanded(child: body)]),
      bottomNavigationBar: PageActionZone(
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        primaryDisabled: primaryDisabled,
        primaryDisabledReason: primaryDisabledReason,
        primaryIcon: primaryIcon,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/permission_card.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/permission_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// PermissionCard (5.16) — kartu izin yang mengambil zona konten. ModeBadge
/// dan BottomActionBar tetap di tempatnya (dipasang oleh screen pemanggil).
/// Alasan ditulis per izin, bukan satu paragraf gabungan — bagian 5.16.
///
/// **Kartu ini tidak lagi memuat tombolnya.** Dulu tombol "Berikan izin" ikut
/// di dalam kartu, dan karena kartunya berada di zona konten, tombol berakhir
/// di tengah layar — zona kuning/merah thumb zone, di luar jangkauan ibu jari
/// satu tangan. Tombolnya sekarang dipasang [PermissionPrompt] di slot kartu
/// bawah. Lihat bagian 5 & 8 ALUR-DAN-TOMBOL.md.
class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: AppColors.actionLabel),
            const SizedBox(height: AppSpacing.s4),
            Semantics(
              header: true,
              headingLevel: 2,
              child: Text(title, textAlign: TextAlign.center, style: AppTypography.title()),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(reason, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Permintaan izin di **layar mode** — DO-14, BT-17, UG-14, AS-02, CO-15,
/// NV-21.
///
/// Layar mode sudah memakai `BottomActionBar`, jadi menurut kontrak zona ia
/// tidak boleh juga memakai `zone/page-action`. Aksinya karena itu mendarat di
/// slot kartu bawah (bottom 120 dp, tepat di atas action bar) — tempat yang
/// sama dengan seluruh kartu hasil mode lain, dan tetap di sepertiga bawah
/// layar tempat ibu jari beristirahat.
///
/// Dipasang sebagai anak `Stack` layar mode; ia mengisi stack dan memposisikan
/// dirinya sendiri, jadi pemanggil tidak perlu mengatur apa pun.
class PermissionPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;
  final String actionLabel;
  final VoidCallback onAction;
  final bool actionDisabled;
  final String? actionDisabledReason;

  const PermissionPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.onAction,
    this.actionDisabled = false,
    this.actionDisabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final actionBottom = bottomCardSlotOffset(bottomInset);

    return Positioned.fill(
      child: Stack(
        children: [
          // Kartu tetap di zona konten — perannya memberi tahu, bukan
          // ditekan. Padding bawah menjaga ia tidak pernah menabrak tombol.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: actionBottom + ZoneHeights.pageActionPrimary,
            child: Center(
              child: SingleChildScrollView(
                child: Semantics(
                  sortKey: const OrdinalSortKey(5),
                  child: PermissionCard(icon: icon, title: title, reason: reason),
                ),
              ),
            ),
          ),

          // Aksi utama: slot kartu bawah, tepat di atas BottomActionBar.
          // Urutan fokus 6 — sesudah isi kartu, sebelum tiga tombol bar.
          Positioned(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            bottom: actionBottom,
            child: Semantics(
              sortKey: const OrdinalSortKey(6),
              child: FullScreenButton(
                label: actionLabel,
                onTap: onAction,
                disabled: actionDisabled,
                disabledReason: actionDisabledReason,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/result_panel.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/result_panel.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ResultPanel (F9) — kontrol audio selalu di baris atas kanan supaya
/// posisinya tidak bergeser saat isi berubah panjang.
class ResultPanel extends StatelessWidget {
  final String title;
  final String text;
  final bool speaking;
  final bool paused;
  final bool failed;
  final VoidCallback? onReplay;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ResultPanel({
    super.key,
    this.title = 'Hasil baca',
    required this.text,
    this.speaking = false,
    this.paused = false,
    this.failed = false,
    this.onReplay,
    this.onTogglePlayback,
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return _panel(
        child: Stack(
          children: [
            Positioned(
              left: -4, top: 0, bottom: 0,
              child: Container(width: 3, decoration: BoxDecoration(color: AppColors.criticalFill, borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('GAGAL MEMUAT', style: AppTypography.eyebrow(color: AppColors.criticalLabel)),
                  const SizedBox(height: 6),
                  Text(text, style: AppTypography.body()),
                  const SizedBox(height: 14),
                  _pillButton('Coba lagi', filled: true, onTap: onRetry),
                ],
              ),
            ),
          ],
        ),
        semanticsLabel: 'Gagal memuat. $text. Coba lagi',
      );
    }

    if (text.isEmpty) {
      return _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(), style: AppTypography.eyebrow()),
            const SizedBox(height: 8),
            Text('Belum ada teks. Arahkan kamera ke tulisan, lalu tekan Baca teks.',
                style: AppTypography.body(color: AppColors.ink2)),
          ],
        ),
        semanticsLabel: title,
      );
    }

    final eyebrow = speaking ? 'Sedang dibacakan' : (paused ? 'Dijeda' : title.toUpperCase());
    final eyebrowColor = speaking ? AppColors.actionLabel : AppColors.ink2;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(eyebrow, style: AppTypography.eyebrow(color: eyebrowColor))),
              _audioControl(),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(text, style: AppTypography.body(color: speaking || paused ? AppColors.ink2 : AppColors.ink1)),
            ),
          ),
          if (!speaking && !paused) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _pillButton('Putar ulang', filled: false, icon: Icons.replay_rounded, onTap: onReplay),
                if (secondaryLabel != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  _pillButton(secondaryLabel!, filled: false, onTap: onSecondary),
                ],
              ],
            ),
          ],
        ],
      ),
      semanticsLabel: '$eyebrow. $text',
    );
  }

  Widget _audioControl() {
    if (!speaking && !paused) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTogglePlayback,
      child: Semantics(
        button: true,
        label: speaking ? 'Jeda pembacaan' : 'Lanjutkan pembacaan',
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: speaking ? AppColors.actionLabel : AppColors.actionTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: speaking ? Colors.white : AppColors.actionLabel,
          ),
        ),
      ),
    );
  }

  Widget _pillButton(String label, {required bool filled, IconData? icon, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? AppColors.actionLabel : AppColors.actionTint,
            borderRadius: AppRadius.pillShape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: filled ? Colors.white : AppColors.actionLabel),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.label(color: filled ? Colors.white : AppColors.actionLabel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel({required Widget child, required String semanticsLabel}) {
    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: child,
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/speaking_indicator.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/speaking_indicator.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// SpeakingIndicator (5.15) — pil kecil kanan atas menandakan TTS berjalan.
/// Varian senyap: ikon speaker dicoret + "Getar saja".
class SpeakingIndicator extends StatefulWidget {
  final bool silent;

  const SpeakingIndicator({super.key, this.silent = false});

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.silent ? 'Getar saja' : 'Vinara bicara';

    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.silent
                ? const Icon(Icons.volume_off_rounded, size: 14, color: Colors.white)
                : _Bars(controller: _controller),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.caption(color: Colors.white).copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Bars extends AnimatedWidget {
  final AnimationController controller;
  const _Bars({required this.controller}) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final phase = (controller.value + i * .22) % 1.0;
          final h = 4 + (10 * (0.5 + 0.5 * (phase < .5 ? phase * 2 : (1 - phase) * 2)));
          return Container(width: 2.4, height: h, color: Colors.white);
        }),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/status_banner.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/status_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// StatusBanner (F7) — lebar penuh, tinggi 56, tanpa radius, menempel tepi
/// atas. Isian tint tier + Pita Prioritas horizontal 3 dp di tepi bawah.
/// Satu banner saja pada satu waktu; tier lebih tinggi menang.
class StatusBanner extends StatelessWidget {
  final AlertTier tier;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatusBanner({
    super.key,
    required this.tier,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 1 — bagian 10. Di Flutter urutan fokus TIDAK otomatis
      // mengikuti posisi visual, jadi tiap simpul zona dipasangi kunci urut
      // eksplisit. Elemen yang tidak hadir dilewati tanpa mengubah nomor
      // sisanya, dan itulah gunanya nomor tetap alih-alih urutan relatif.
      sortKey: const OrdinalSortKey(1),
      liveRegion: true,
      label: actionLabel == null ? message : '$message. $actionLabel',
      child: Container(
        width: double.infinity,
        height: AppSizes.statusBannerHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        decoration: BoxDecoration(
          color: tier.tintColor,
          border: Border(bottom: BorderSide(color: tier.fillColor, width: 3)),
        ),
        child: Row(
          children: [
            TierIcon(tier: tier, size: 22),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyStrong(color: tier.labelColor).copyWith(fontSize: 15, height: 20 / 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s3),
                  child: Text(actionLabel!, style: AppTypography.label(color: AppColors.actionLabel)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/target_chip.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/target_chip.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/index.dart';

/// TargetChip (5.14) — khusus Mode Cari Objek. Baris sendiri di bawah
/// ModeBadge, TIDAK PERNAH berbagi baris dengannya. Elipsis hanya pada nama
/// barang; kata "Mencari:" selalu utuh.
class TargetChip extends StatelessWidget {
  final String itemName;

  const TargetChip({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 4 — bagian 10, baris sendiri di bawah ModeBadge.
      sortKey: const OrdinalSortKey(4),
      liveRegion: true,
      label: 'Mencari: $itemName',
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        decoration: const BoxDecoration(color: AppColors.actionFill, borderRadius: AppRadius.pillShape),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Text('Mencari: ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Expanded(
              child: Text(
                itemName,
                style: AppTypography.label(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Berkas: `lib/widgets/tier_icon.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/tier_icon.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tier alert: Critical / Warning / Info / Positive.
/// Setiap tier punya BENTUK ikon yang berbeda (bukan cuma warna berbeda),
/// supaya tetap terbaca oleh pengguna low vision / buta warna:
/// oktagon = Critical, segitiga = Warning, persegi membulat = Info,
/// centang = Positive.
enum AlertTier { critical, warning, info, positive }

extension AlertTierX on AlertTier {
  Color get fillColor => switch (this) {
        AlertTier.critical  => AppColors.criticalFill,
        AlertTier.warning   => AppColors.warningFill,
        AlertTier.info      => AppColors.actionFill,
        AlertTier.positive  => AppColors.positiveLabel,
      };

  Color get labelColor => switch (this) {
        AlertTier.critical  => AppColors.criticalLabel,
        AlertTier.warning   => AppColors.warningLabel,
        AlertTier.info      => AppColors.actionLabel,
        AlertTier.positive  => AppColors.positiveLabel,
      };

  Color get tintColor => switch (this) {
        AlertTier.critical  => AppColors.criticalTint,
        AlertTier.warning   => AppColors.warningTint,
        AlertTier.info      => AppColors.actionTint,
        AlertTier.positive  => AppColors.positiveTint,
      };

  String get label => switch (this) {
        AlertTier.critical  => 'Bahaya',
        AlertTier.warning   => 'Hati-hati',
        AlertTier.info      => 'Info',
        AlertTier.positive  => 'Aman',
      };

  static AlertTier fromDangerLevel(String dangerLevel) => switch (dangerLevel) {
        'critical' => AlertTier.critical,
        'warning'  => AlertTier.warning,
        _          => AlertTier.info,
      };
}

class TierIcon extends StatelessWidget {
  final AlertTier tier;
  final double size;

  const TierIcon({super.key, required this.tier, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TierIconPainter(tier)),
    );
  }
}

class _TierIconPainter extends CustomPainter {
  final AlertTier tier;
  _TierIconPainter(this.tier);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final fill = Paint()
      ..color = tier == AlertTier.positive ? tier.fillColor : tier.fillColor
      ..style = PaintingStyle.fill;

    switch (tier) {
      case AlertTier.critical:
        canvas.drawPath(_octagon(scale), fill);
        _mark(canvas, scale, Colors.white, dotFirst: false);
        break;
      case AlertTier.warning:
        canvas.drawPath(_triangle(scale), fill);
        _mark(canvas, scale, AppColors.ink1, dotFirst: false);
        break;
      case AlertTier.info:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2.4 * scale, 2.4 * scale, 19.2 * scale, 19.2 * scale),
            Radius.circular(6 * scale),
          ),
          fill,
        );
        _mark(canvas, scale, Colors.white, dotFirst: true);
        break;
      case AlertTier.positive:
        final stroke = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawCircle(Offset(12 * scale, 12 * scale), 12 * scale, fill);
        final path = Path()
          ..moveTo(7.5 * scale, 12.5 * scale)
          ..lineTo(10.7 * scale, 15.7 * scale)
          ..lineTo(16.5 * scale, 8.5 * scale);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  /// Tanda seru (garis + titik) — tier Critical/Warning garis-lalu-titik,
  /// tier Info titik-lalu-garis (menyerupai huruf "i").
  void _mark(Canvas canvas, double scale, Color color, {required bool dotFirst}) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    if (dotFirst) {
      canvas.drawLine(Offset(12 * scale, 7.4 * scale), Offset(12 * scale, 7.5 * scale), stroke);
      canvas.drawLine(Offset(12 * scale, 10.6 * scale), Offset(12 * scale, 16.8 * scale), stroke);
    } else {
      canvas.drawLine(Offset(12 * scale, 7 * scale), Offset(12 * scale, 13 * scale), stroke);
      canvas.drawLine(Offset(12 * scale, 16.2 * scale), Offset(12 * scale, 16.3 * scale), stroke);
    }
  }

  Path _octagon(double s) => Path()
    ..moveTo(8.2 * s, 2 * s)
    ..lineTo(15.8 * s, 2 * s)
    ..lineTo(22 * s, 8.2 * s)
    ..lineTo(22 * s, 15.8 * s)
    ..lineTo(15.8 * s, 22 * s)
    ..lineTo(8.2 * s, 22 * s)
    ..lineTo(2 * s, 15.8 * s)
    ..lineTo(2 * s, 8.2 * s)
    ..close();

  Path _triangle(double s) => Path()
    ..moveTo(12 * s, 2.6 * s)
    ..lineTo(22 * s, 20.4 * s)
    ..lineTo(2 * s, 20.4 * s)
    ..close();

  @override
  bool shouldRepaint(covariant _TierIconPainter oldDelegate) => oldDelegate.tier != tier;
}
```

---

## Berkas: `lib/widgets/voice_orb.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/voice_orb.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// VoiceOrb (F6) — setiap state punya bentuk/isi berbeda, bukan cuma warna.
enum VoiceOrbState { idle, listening, processing, success, failure, disabled }

class VoiceOrb extends StatelessWidget {
  final VoiceOrbState state;
  final double size;

  const VoiceOrb({super.key, required this.state, this.size = 96});

  String get _label => switch (state) {
        VoiceOrbState.idle       => 'Bicara',
        VoiceOrbState.listening  => 'Mendengarkan',
        VoiceOrbState.processing => 'Memproses',
        VoiceOrbState.success    => 'Selesai',
        VoiceOrbState.failure    => 'Belum terdengar, coba lagi',
        VoiceOrbState.disabled   => 'Bicara, tidak tersedia, izin mikrofon belum diberikan',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: state != VoiceOrbState.idle,
      label: _label,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: _content()),
      ),
    );
  }

  Widget _content() {
    switch (state) {
      case VoiceOrbState.idle:
        return _circle(
          diameter: size,
          color: AppColors.actionFill,
          shadow: [BoxShadow(color: AppColors.actionFill.withValues(alpha: .3), blurRadius: 12, offset: const Offset(0, 4))],
          child: Icon(Icons.mic_none_rounded, color: Colors.white, size: size * .44),
        );
      case VoiceOrbState.listening:
        return _circle(
          diameter: size,
          color: AppColors.actionFill,
          shadow: [
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .16), blurRadius: 0, spreadRadius: size * .14),
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .08), blurRadius: 0, spreadRadius: size * .28),
          ],
          child: Icon(Icons.mic_rounded, color: Colors.white, size: size * .44),
        );
      case VoiceOrbState.processing:
        return _circle(
          diameter: size,
          color: AppColors.actionTint,
          child: SizedBox(
            width: size * .46, height: size * .46,
            child: const CircularProgressIndicator(strokeWidth: 4, color: AppColors.actionLabel),
          ),
        );
      case VoiceOrbState.success:
        return _circle(
          diameter: size,
          color: AppColors.positiveLabel,
          child: Icon(Icons.check_rounded, color: Colors.white, size: size * .48),
        );
      case VoiceOrbState.failure:
        return _circle(
          diameter: size,
          color: Colors.white,
          border: Border.all(color: AppColors.warningFill, width: 2),
          child: Icon(Icons.priority_high_rounded, color: AppColors.ink1, size: size * .42),
        );
      case VoiceOrbState.disabled:
        return _circle(
          diameter: size,
          color: AppColors.surfaceSunk,
          child: Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: size * .44),
        );
    }
  }

  Widget _circle({
    required double diameter,
    required Color color,
    Widget? child,
    List<BoxShadow>? shadow,
    BoxBorder? border,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: shadow,
        border: border,
      ),
      child: Center(child: child),
    );
  }
}
```

---

## Berkas: `lib/widgets/zone_indicator.dart`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/zone_indicator.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Status per zona (Kiri / Tengah / Kanan) di ZoneIndicator (F8).
enum ZoneStatus { safe, caution, danger, unknown }

extension ZoneStatusX on ZoneStatus {
  String get label => switch (this) {
        ZoneStatus.safe    => 'AMAN',
        ZoneStatus.caution => 'HATI-HATI',
        ZoneStatus.danger  => 'BAHAYA',
        ZoneStatus.unknown => '',
      };

  Color get tint => switch (this) {
        ZoneStatus.safe    => AppColors.positiveTint,
        ZoneStatus.caution => AppColors.warningTint,
        ZoneStatus.danger  => AppColors.criticalTint,
        ZoneStatus.unknown => AppColors.surfaceSunk,
      };

  Color get ink => switch (this) {
        ZoneStatus.safe    => AppColors.positiveLabel,
        ZoneStatus.caution => AppColors.warningLabel,
        ZoneStatus.danger  => AppColors.criticalLabel,
        ZoneStatus.unknown => AppColors.ink2,
      };
}

/// ZoneIndicator (F8) — tiga chip 111 × 56, gap 8. Chip yang sedang
/// direkomendasikan memakai isian pekat (bukan hijau vibrant) supaya
/// teks putih di atasnya lolos 7.35:1.
class ZoneIndicator extends StatelessWidget {
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;
  final int recommended; // -1 none, 0 left, 1 center, 2 right

  const ZoneIndicator({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.recommended = -1,
  });

  String get _liveLabel {
    if ([left, center, right].every((s) => s == ZoneStatus.unknown)) {
      return 'Kondisi jalur belum diketahui';
    }
    return 'Kondisi jalur: kiri ${left.label.toLowerCase()}, '
        'tengah ${center.label.toLowerCase()}, '
        'kanan ${right.label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _liveLabel,
      child: Row(
        children: [
          Expanded(child: _ZoneChip(label: 'Kiri', status: left, recommended: recommended == 0)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: _ZoneChip(label: 'Tengah', status: center, recommended: recommended == 1)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: _ZoneChip(label: 'Kanan', status: right, recommended: recommended == 2)),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final ZoneStatus status;
  final bool recommended;

  const _ZoneChip({required this.label, required this.status, required this.recommended});

  @override
  Widget build(BuildContext context) {
    final solid = recommended && status != ZoneStatus.unknown;
    final bg = solid ? status.ink : status.tint;
    final fg = solid ? Colors.white : status.ink;

    return Container(
      height: 56,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.caption(color: solid ? Colors.white.withValues(alpha: .85) : AppColors.ink2)),
            const SizedBox(height: 1),
            status == ZoneStatus.unknown
                ? _UnknownDots()
                : Text(
                    status.label,
                    style: AppTypography.bodyStrong(color: fg).copyWith(fontSize: 15, letterSpacing: .4),
                  ),
          ],
        ),
      ),
    );
  }
}

class _UnknownDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 0 ? const Color(0xFF9AA0AD) : const Color(0xFFC4C9D2),
            ),
          ),
        );
      }),
    );
  }
}
```

---

## Berkas: `pubspec.yaml`

**Path Lengkap:** `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/pubspec.yaml`

```yaml
name: guidio_app
description: Guidio - AI Navigation Assistant untuk Tunanetra
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.2

  # Kamera
  camera: ^0.11.0+2

  # TFLite on-device inference
  tflite_flutter: ^0.12.1

  # Text-to-Speech (Bahasa Indonesia)
  flutter_tts: ^4.0.2

  # Speech-to-Text (Voice Assistant)
  speech_to_text: ^7.0.0

  # WebSocket ke server
  web_socket_channel: ^3.0.1

  # HTTP untuk REST (OCR, single-shot detect, narasi)
  http: ^1.2.1

  # Sensor accelerometer (camera health check posisi)
  sensors_plus: ^7.0.0

  # Kondisi global — offline, baterai kritis (StatusBanner gabungan)
  connectivity_plus: ^6.0.5
  battery_plus: ^6.0.2

  # Izin kamera, mikrofon
  permission_handler: ^11.3.1

  # Haptic feedback (getar saat mic aktif)
  vibration: ^2.0.0

  # Local storage untuk lokasi favorit (tanpa login)
  shared_preferences: ^2.3.2

  # Konversi YUV420 → JPEG untuk server stream
  image: ^4.1.7

  # Icon
  cupertino_icons: ^1.0.8

  # Font — IBM Plex Sans / IBM Plex Mono (design system Vinara)
  google_fonts: ^6.2.1
  google_mlkit_text_recognition: ^0.16.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/models/
```

---

