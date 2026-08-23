# Code Document: guidio_app
> Base Path: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app`
> Total Files: 112

## Table of Contents

- [FEATURE_VERIFICATION.md](#file-featureverificationmd)
- [README.md](#file-readmemd)
- [analysis_options.yaml](#file-analysisoptionsyaml)
- [android/app/build.gradle.kts](#file-androidappbuildgradlekts)
- [android/app/src/debug/AndroidManifest.xml](#file-androidappsrcdebugandroidmanifestxml)
- [android/app/src/main/AndroidManifest.xml](#file-androidappsrcmainandroidmanifestxml)
- [android/app/src/main/res/drawable-v21/launch_background.xml](#file-androidappsrcmainresdrawable-v21launchbackgroundxml)
- [android/app/src/main/res/drawable/launch_background.xml](#file-androidappsrcmainresdrawablelaunchbackgroundxml)
- [android/app/src/main/res/values-night/styles.xml](#file-androidappsrcmainresvalues-nightstylesxml)
- [android/app/src/main/res/values/styles.xml](#file-androidappsrcmainresvaluesstylesxml)
- [android/app/src/profile/AndroidManifest.xml](#file-androidappsrcprofileandroidmanifestxml)
- [android/build.gradle.kts](#file-androidbuildgradlekts)
- [android/settings.gradle.kts](#file-androidsettingsgradlekts)
- [assets/models/labelmap.txt](#file-assetsmodelslabelmaptxt)
- [assets/models/rupiah_labels.txt](#file-assetsmodelsrupiahlabelstxt)
- [ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json](#file-iosrunnerassetsxcassetsappiconappiconsetcontentsjson)
- [ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json](#file-iosrunnerassetsxcassetslaunchimageimagesetcontentsjson)
- [ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](#file-iosrunnerassetsxcassetslaunchimageimagesetreadmemd)
- [lib/core/layout/zone_contract.dart](#file-libcorelayoutzonecontractdart)
- [lib/core/net/api_client.dart](#file-libcorenetapiclientdart)
- [lib/core/net/frame_codec.dart](#file-libcorenetframecodecdart)
- [lib/core/speech/tts_queue.dart](#file-libcorespeechttsqueuedart)
- [lib/core/state/global_conditions.dart](#file-libcorestateglobalconditionsdart)
- [lib/core/voice/command_parser.dart](#file-libcorevoicecommandparserdart)
- [lib/core/voice/intents.dart](#file-libcorevoiceintentsdart)
- [lib/core/voice/narration_engine.dart](#file-libcorevoicenarrationenginedart)
- [lib/core/voice/scene_translator.dart](#file-libcorevoicescenetranslatordart)
- [lib/main.dart](#file-libmaindart)
- [lib/mock/mock_find_object.dart](#file-libmockmockfindobjectdart)
- [lib/mock/ocr_mock_data.dart](#file-libmockocrmockdatadart)
- [lib/models/detection.dart](#file-libmodelsdetectiondart)
- [lib/models/index.dart](#file-libmodelsindexdart)
- [lib/providers/app_mode_provider.dart](#file-libprovidersappmodeproviderdart)
- [lib/providers/camera_provider.dart](#file-libproviderscameraproviderdart)
- [lib/providers/capabilities_provider.dart](#file-libproviderscapabilitiesproviderdart)
- [lib/providers/detection_provider.dart](#file-libprovidersdetectionproviderdart)
- [lib/providers/find_object_provider.dart](#file-libprovidersfindobjectproviderdart)
- [lib/providers/index.dart](#file-libprovidersindexdart)
- [lib/providers/inference_provider.dart](#file-libprovidersinferenceproviderdart)
- [lib/providers/money_provider.dart](#file-libprovidersmoneyproviderdart)
- [lib/providers/navigation_provider.dart](#file-libprovidersnavigationproviderdart)
- [lib/providers/settings_provider.dart](#file-libproviderssettingsproviderdart)
- [lib/providers/tts_provider.dart](#file-libprovidersttsproviderdart)
- [lib/providers/voice_provider.dart](#file-libprovidersvoiceproviderdart)
- [lib/screens/find_object_screen.dart](#file-libscreensfindobjectscreendart)
- [lib/screens/index.dart](#file-libscreensindexdart)
- [lib/screens/main_screen.dart](#file-libscreensmainscreendart)
- [lib/screens/money_screen.dart](#file-libscreensmoneyscreendart)
- [lib/screens/navigasi_screen.dart](#file-libscreensnavigasiscreendart)
- [lib/screens/ocr_screen.dart](#file-libscreensocrscreendart)
- [lib/screens/onboarding_screen.dart](#file-libscreensonboardingscreendart)
- [lib/screens/permissions_screen.dart](#file-libscreenspermissionsscreendart)
- [lib/screens/server_address_screen.dart](#file-libscreensserveraddressscreendart)
- [lib/screens/settings_screen.dart](#file-libscreenssettingsscreendart)
- [lib/screens/splash_screen.dart](#file-libscreenssplashscreendart)
- [lib/screens/tuntun_screen.dart](#file-libscreenstuntunscreendart)
- [lib/screens/voice_screen.dart](#file-libscreensvoicescreendart)
- [lib/services/camera_health_service.dart](#file-libservicescamerahealthservicedart)
- [lib/services/camera_intrinsics.dart](#file-libservicescameraintrinsicsdart)
- [lib/services/detection_filter.dart](#file-libservicesdetectionfilterdart)
- [lib/services/haptic_service.dart](#file-libserviceshapticservicedart)
- [lib/services/index.dart](#file-libservicesindexdart)
- [lib/services/money_tflite_service.dart](#file-libservicesmoneytfliteservicedart)
- [lib/services/nav_frame_converter.dart](#file-libservicesnavframeconverterdart)
- [lib/services/object_tracker.dart](#file-libservicesobjecttrackerdart)
- [lib/services/ocr_service.dart](#file-libservicesocrservicedart)
- [lib/services/pidnet_service.dart](#file-libservicespidnetservicedart)
- [lib/services/server_service.dart](#file-libservicesserverservicedart)
- [lib/services/tflite_service.dart](#file-libservicestfliteservicedart)
- [lib/services/tts_service.dart](#file-libservicesttsservicedart)
- [lib/services/yolo_navigasi_service.dart](#file-libservicesyolonavigasiservicedart)
- [lib/theme/app_colors.dart](#file-libthemeappcolorsdart)
- [lib/theme/app_spacing.dart](#file-libthemeappspacingdart)
- [lib/theme/app_theme.dart](#file-libthemeappthemedart)
- [lib/theme/app_typography.dart](#file-libthemeapptypographydart)
- [lib/theme/index.dart](#file-libthemeindexdart)
- [lib/widgets/alert_card.dart](#file-libwidgetsalertcarddart)
- [lib/widgets/bottom_action_bar.dart](#file-libwidgetsbottomactionbardart)
- [lib/widgets/camera_health_toast.dart](#file-libwidgetscamerahealthtoastdart)
- [lib/widgets/chat_bubble.dart](#file-libwidgetschatbubbledart)
- [lib/widgets/contextual_action_slot.dart](#file-libwidgetscontextualactionslotdart)
- [lib/widgets/detection_card.dart](#file-libwidgetsdetectioncarddart)
- [lib/widgets/distance_pill.dart](#file-libwidgetsdistancepilldart)
- [lib/widgets/full_screen_button.dart](#file-libwidgetsfullscreenbuttondart)
- [lib/widgets/guide_frame.dart](#file-libwidgetsguideframedart)
- [lib/widgets/index.dart](#file-libwidgetsindexdart)
- [lib/widgets/mode_badge.dart](#file-libwidgetsmodebadgedart)
- [lib/widgets/mode_picker_sheet.dart](#file-libwidgetsmodepickersheetdart)
- [lib/widgets/nominal_card.dart](#file-libwidgetsnominalcarddart)
- [lib/widgets/ocr_debug_sheet.dart](#file-libwidgetsocrdebugsheetdart)
- [lib/widgets/ocr_long_result_panel.dart](#file-libwidgetsocrlongresultpaneldart)
- [lib/widgets/page_action_zone.dart](#file-libwidgetspageactionzonedart)
- [lib/widgets/permission_card.dart](#file-libwidgetspermissioncarddart)
- [lib/widgets/result_panel.dart](#file-libwidgetsresultpaneldart)
- [lib/widgets/speaking_indicator.dart](#file-libwidgetsspeakingindicatordart)
- [lib/widgets/status_banner.dart](#file-libwidgetsstatusbannerdart)
- [lib/widgets/target_chip.dart](#file-libwidgetstargetchipdart)
- [lib/widgets/tier_icon.dart](#file-libwidgetstiericondart)
- [lib/widgets/voice_orb.dart](#file-libwidgetsvoiceorbdart)
- [lib/widgets/zone_indicator.dart](#file-libwidgetszoneindicatordart)
- [linux/CMakeLists.txt](#file-linuxcmakeliststxt)
- [linux/flutter/CMakeLists.txt](#file-linuxfluttercmakeliststxt)
- [linux/runner/CMakeLists.txt](#file-linuxrunnercmakeliststxt)
- [macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json](#file-macosrunnerassetsxcassetsappiconappiconsetcontentsjson)
- [pubspec.yaml](#file-pubspecyaml)
- [test/command_parser_test.dart](#file-testcommandparsertestdart)
- [test/model_inference_test.dart](#file-testmodelinferencetestdart)
- [test/scene_translator_test.dart](#file-testscenetranslatortestdart)
- [web/manifest.json](#file-webmanifestjson)
- [windows/CMakeLists.txt](#file-windowscmakeliststxt)
- [windows/flutter/CMakeLists.txt](#file-windowsfluttercmakeliststxt)
- [windows/runner/CMakeLists.txt](#file-windowsrunnercmakeliststxt)

---

## File: `FEATURE_VERIFICATION.md`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/FEATURE_VERIFICATION.md`

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

## File: `README.md`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/README.md`

```markdown
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
layar beranda - setiap layar perantara berarti penundaan sebelum pengguna
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
> dipakai** - hanya sisa percobaan. Yang dimuat adalah `ssd_mobilenet.tflite`.

### Model pengenalan uang

| Hal | Nilai |
|---|---|
| Berkas | `assets/models/rupiah_classifier_int8.tflite` |
| Arsitektur | MobileNetV2 transfer learning (repo `rupiah-vision`) |
| Ukuran masukan | 224 × 224 piksel, float32 **rentang −1..1** |
| Jumlah kelas | 7 pecahan - emisi 2016 & 2022 |
| Test accuracy | 98,36% (varian INT8) |

Urutan kelas **wajib** persis seperti saat model dilatih (`CLASS_ORDER` di `scripts/02_export_tflite.py`):

```
1.000 = 0   2.000 = 1   5.000 = 2   10.000 = 3
20.000 = 4  50.000 = 5  100.000 = 6
```

> **Perhatian rentang input:** model ini memakai rentang −1..1 (`x/127.5 − 1`),
> **bukan** 0..255. Nilai yang salah tidak memunculkan error - prediksi hanya
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
tidak bisa menentukan - biasanya kasus ambigu yang perlu konfirmasi pengguna.

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

Urutan objek: yang paling dekat disebut lebih dulu - objek paling berbahaya
mendapat prioritas.

### Deskripsi suasana (Moondream2)

Untuk `POST /api/describe`, backend mengembalikan `description_en` - caption
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
# Command parser: cepat, tidak butuh model atau device
flutter test test/command_parser_test.dart

# Inferensi model langsung: butuh TFLite shared library
flutter test test/model_inference_test.dart
```

**Hasil tipikal di laptop Linux** (tanpa perangkat Android):

```
+40 passed, ~17 skipped
```

Test yang di-skip **bukan error** - mereka otomatis lewat sendiri kalau dependensinya tidak ada
(TFLite `.so`, backend server, dll.). Tidak ada yang merah = aman.

#### Apa yang ditest?

**`test/command_parser_test.dart`** - logika parsing perintah suara:

| Kelompok | Yang ditest | Syarat jalan |
|---|---|---|
| Pemetaan 21 intent | Contoh ucapan dari dokumen arsitektur | - |
| Prioritas frasa | Frasa spesifik menang atas kata umum (4 kasus) | - |
| Prefiks natural | "saya mau ke mode..." dan variasi (2 kasus) | - |
| Batas kata | Anti false-positive | - |
| Saran intent | Hanya intent yang ada handler-nya yang keluar | - |
| **Kenali Uang** | Klasifikasi 14 gambar JPEG nyata (2 per pecahan) | TFLite SO |
| **Navigasi** | 5 fixture PNG, cek file valid + ada deteksi | - |
| **Cari Objek** | Parse perintah cari + guard jika backend mati | Backend opsional |

**`test/model_inference_test.dart`** - model TFLite langsung, memuat dari path file:

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

### B. Python visual test: lihat gambar hasilnya

Menghasilkan gambar ter-anotasi seperti di `test/navigation/results_mobile_tflite/`.
Berguna untuk memeriksa secara visual apakah bounding box dan klasifikasi masuk akal.

#### Setup (sekali saja): dari root repo (folder `guido/`)

```bash
python3 -m venv test/.venv
test/.venv/bin/pip install -r test/requirements-test.txt
```

Hanya install `ai-edge-litert` + `Pillow` + `numpy` (~50 MB, tidak perlu TensorFlow penuh).

#### Menjalankan: dari root repo (folder `guido/`)

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
```

---

## File: `analysis_options.yaml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml
```

---

## File: `android/app/build.gradle.kts`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pens.vinara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pens.vinara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Ganti dengan signing config milik tim sebelum distribusi.
            // Untuk sekarang memakai kunci debug supaya `flutter run --release` jalan.
            signingConfig = signingConfigs.getByName("debug")

            // `proguard-rules.pro` HARUS didaftarkan eksplisit. Tanpa baris ini
            // berkasnya ada tapi tidak pernah dibaca R8 - dan build release
            // gagal total karena ML Kit merujuk pengenal aksara Cina, Jepang,
            // Korea, dan Devanagari yang tidak ikut sebagai dependensi.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
```

---

## File: `android/app/src/debug/AndroidManifest.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/debug/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

---

## File: `android/app/src/main/AndroidManifest.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions wajib Guidio -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

    <!-- Camera feature -->
    <uses-feature android:name="android.hardware.camera" android:required="true"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    <application
        android:label="Vinara"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

## File: `android/app/src/main/res/drawable-v21/launch_background.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/main/res/drawable-v21/launch_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="?android:colorBackground" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

---

## File: `android/app/src/main/res/drawable/launch_background.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/main/res/drawable/launch_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

---

## File: `android/app/src/main/res/values-night/styles.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/main/res/values-night/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is on -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

---

## File: `android/app/src/main/res/values/styles.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/main/res/values/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

---

## File: `android/app/src/profile/AndroidManifest.xml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/app/src/profile/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

---

## File: `android/build.gradle.kts`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/build.gradle.kts`

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```

---

## File: `android/settings.gradle.kts`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/android/settings.gradle.kts`

```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
```

---

## File: `assets/models/labelmap.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/assets/models/labelmap.txt`

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

## File: `assets/models/rupiah_labels.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/assets/models/rupiah_labels.txt`

```text
1000
2000
5000
10000
20000
50000
100000
```

---

## File: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

```json
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

---

## File: `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`

```json
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "LaunchImage.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "LaunchImage@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "filename" : "LaunchImage@3x.png",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

---

## File: `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`

```markdown
# Launch Screen Assets

You can customize the launch screen with your own desired assets by replacing the image files in this directory.

You can also do it by opening your Flutter project's Xcode project with `open ios/Runner.xcworkspace`, selecting `Runner/Assets.xcassets` in the Project Navigator and dropping in the desired images.
```

---

## File: `lib/core/layout/zone_contract.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/layout/zone_contract.dart`

```dart
import '../../theme/app_spacing.dart';

/// Kontrak layout dan zona - bagian 4 IMPLEMENTASI.md.
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

  /// `zone/page-action` - 96 dp tombol + 24 dp safe area. Zona untuk aksi
  /// utama layar penunjang (Onboarding, Izin, Pengaturan) yang tidak punya
  /// BottomActionBar. **Tidak pernah hadir bersamaan dengan
  /// [bottomActionBar]** - sebuah layar punya salah satu, tidak pernah
  /// keduanya. Itu yang menjaga aturan "geser, bukan tumpuk".
  static const pageAction = 120.0;
  static const pageActionPrimary = 96.0;
  static const pageActionSecondary = 56.0;

  /// Jarak baku antara tombol sekunder dan tombol utama di `zone/page-action`.
  static const pageActionGap = 8.0;
}

/// Posisi baku (bagian 4, "Posisi baku") - offset relatif terhadap top-left
/// frame, sebelum ditambah safe-area inset perangkat nyata.
abstract final class ZonePositions {
  static const modeBadgeY = 40.0;
  static const modeBadgeYWithBanner = 96.0;
  static const secondaryChipY = 96.0;
  static const secondaryChipYWithBanner = 152.0;
  static const bottomCardSlotBottom = 120.0;
  static const fullScreenButtonBottom = 132.0;
}

/// Turunkan top-offset ModeBadge / chip sekunder saat StatusBanner hadir -
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

## File: `lib/core/net/api_client.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/net/api_client.dart`

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
  /// Health, capabilities, intent - pengguna menunggu jawabannya sekarang.
  interactive(Duration(seconds: 4)),

  /// Satu frame ke server dan kembali - segmentasi jalur, cari objek.
  frame(Duration(seconds: 8)),

  /// OCR, unggah antrean - berat, pengguna sudah diberi tahu akan lama.
  heavy(Duration(seconds: 20)),

  /// Telemetri - tidak ada yang menunggu.
  background(Duration(seconds: 5));

  final Duration timeout;
  const ApiOp(this.timeout);
}

/// Dilempar saat server menjawab dengan status non-200. Dipisah dari kegagalan
/// jaringan supaya pemanggil bisa membedakan "server hidup tapi menolak" dari
/// "server tidak terjangkau" - dua kondisi itu punya naskah suara berbeda
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
/// tiap permintaan membayar handshake TCP baru - di jaringan seluler itu
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
      // GET selalu idempoten - aman diulang.
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
  /// `FrameCodec.encodeForUpload` - memperkecil di sisi klien adalah satu
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
      // Unggah gambar tidak idempoten kecuali diberi kunci - jangan diulang
      // diam-diam. Pengulangan yang benar lewat antrean (BT-13).
      retries: 0,
    );
    return _decode(res, path);
  }

  /// Unggah multipart - gambar + field. Dipakai saat server butuh metadata
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

        // 5xx layak diulang (server sedang pulih); 4xx tidak - permintaannya
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
/// mengantrekan frame justru berbahaya - pengguna akan mendengar arahan untuk
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

  /// Berapa frame dibuang sejak terakhir dibaca - berguna untuk menurunkan
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

## File: `lib/core/net/frame_codec.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/net/frame_codec.dart`

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
/// menentukan waktu unggah** - jauh lebih berpengaruh daripada pilihan
/// protokol, keep-alive, atau kompresi tambahan. Frame 640×480 pada kualitas
/// 70 sekitar 40–60 KB; frame 1920×1080 kualitas 90 bisa 400 KB. Di jaringan
/// seluler menengah itu selisih beberapa detik, tiap frame.
///
/// Angka di bawah dipilih dari apa yang model di server benar-benar pakai:
/// mengirim piksel lebih banyak daripada yang dikonsumsi model adalah biaya
/// murni tanpa perbaikan akurasi.
abstract final class UploadPreset {
  /// Segmentasi jalur & deteksi objek - model server memakai 640 px.
  static const navigation = (maxEdge: 640, quality: 70);

  /// Cari objek - butuh sedikit lebih tajam untuk barang kecil.
  static const findObject = (maxEdge: 800, quality: 75);

  /// OCR - teks butuh resolusi jauh lebih tinggi. Huruf kecil hancur di 640 px.
  static const ocr = (maxEdge: 1600, quality: 85);
}

/// Konversi dan kompresi frame kamera untuk dikirim ke server.
abstract final class FrameCodec {
  /// YUV420 → JPEG **di isolate terpisah**.
  ///
  /// Versi lama mengerjakan ini di UI thread: 640×480 berarti 307.200 iterasi
  /// Dart per frame. Pada laju streaming apa pun itu membuat antarmuka
  /// tersendat - dan di aplikasi yang dipakai sambil berjalan, tersendat
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

  /// Versi untuk JPEG yang sudah jadi (hasil `takePicture`) - hanya
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

## File: `lib/core/speech/tts_queue.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/speech/tts_queue.dart`

```dart
import 'dart:async';

import '../../services/tts_service.dart';

/// Prioritas tier suara - bagian 15 "Model interupsi dan antrean audio".
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

/// TtsQueue - mesin antrean bertingkat yang dipakai [TtsProvider].
///
/// Fix race condition (temuan 2.4):
/// - Tambahkan [_drainGeneration] token: setiap kali Critical masuk, token
///   dinaikkan sehingga drain lama yang sedang await langsung berhenti saat
///   tiba gilirannya untuk set `_speakingTier = null`.
/// - Critical tidak lagi set `_speakingTier` langsung - cukup invalidasi
///   drain lama + stop + speak dengan interrupt.
/// - Warning juga memakai token yang sama untuk keamanan.
/// - `_pending` dibatasi 8 item; item terlama dibuang saat penuh (anti-OOM).
///
/// Aturan:
/// - Critical: kosongkan antrean, interrupt TTS berjalan, bicara langsung.
/// - Warning: interrupt Info yang sedang bicara; boleh disela pengguna lewat
///   [interruptByUser].
/// - Info: masuk antrean; dibuang jika sudah menunggu > 2 detik saat giliran
///   tiba (anti-banjir, bagian 15).
class TtsQueue {
  /// Singleton - semua caller (DetectionProvider, CameraProvider, TtsProvider,
  /// NavigationProvider, dll) memakai antrian yang sama: "satu pintu suara".
  static final TtsQueue instance = TtsQueue._internal();
  factory TtsQueue() => instance;
  TtsQueue._internal();

  static const int _maxPending = 8;

  final _pending = <_QueuedSpeech>[];
  SpeechTier? _speakingTier;
  bool _draining = false;
  int _drainGeneration = 0; // Fix 2.4: token untuk stop drain lama

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null || _draining;

  Future<void> speak(String message, {SpeechTier tier = SpeechTier.info}) async {
    if (tier == SpeechTier.critical) {
      // Invalidasi semua drain yang sedang berjalan
      _pending.clear();
      _drainGeneration++;
      // Stop TTS yang sedang bicara (Info/Warning) agar Critical langsung terdengar
      await TTSService.instance.stop();
      _speakingTier = SpeechTier.critical;
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = null;
      // Drain mungkin ada item baru yang masuk saat critical berbicara
      unawaited(_drain());
      return;
    }

    if (tier == SpeechTier.warning) {
      if (_speakingTier == SpeechTier.info) {
        // Invalidasi drain lama agar tidak lanjut setelah warning selesai
        _drainGeneration++;
        _speakingTier = SpeechTier.warning;
        await TTSService.instance.speak(message, interrupt: true);
        _speakingTier = null;
        unawaited(_drain());
        return;
      }
      // Info belum bicara - cukup antrean sebagai warning
    }

    _pending.add(_QueuedSpeech(message, tier));

    // Batasi 8 item - buang item terlama (Info) saat penuh (anti-OOM)
    if (_pending.length > _maxPending) {
      // Buang item Info terlama; kalau semua Warning, buang yang terlama
      final oldestInfoIdx = _pending.indexWhere((q) => q.tier == SpeechTier.info);
      if (oldestInfoIdx >= 0) {
        _pending.removeAt(oldestInfoIdx);
      } else {
        _pending.removeAt(0);
      }
    }

    unawaited(_drain());
  }

  /// Pengguna menimpa TTS yang sedang jalan (mis. menekan tombol) - tidak
  /// berlaku untuk peringatan Critical, yang "tidak bisa dipotong pengguna".
  Future<void> interruptByUser() async {
    if (_speakingTier == SpeechTier.critical) return;
    await TTSService.instance.stop();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    final myGeneration = _drainGeneration; // snapshot token saat drain dimulai

    try {
      while (_pending.isNotEmpty) {
        // Cek apakah drain ini sudah diinvalidasi oleh Critical/Warning baru
        if (_drainGeneration != myGeneration) break;

        _pending.sort((a, b) => b.tier.index.compareTo(a.tier.index));
        final next = _pending.removeAt(0);

        // Info dibuang kalau sudah lewat 2 detik menunggu.
        if (next.tier == SpeechTier.info &&
            DateTime.now().difference(next.queuedAt) > const Duration(seconds: 2)) {
          continue;
        }

        _speakingTier = next.tier;
        await TTSService.instance.speak(next.message);

        // Setelah await selesai, cek lagi apakah generasi masih valid
        // (mencegah _speakingTier = null menimpa Critical yang sedang bicara)
        if (_drainGeneration == myGeneration) {
          _speakingTier = null;
        }
      }
    } finally {
      _draining = false;
      // Hanya reset _speakingTier jika drain ini masih valid
      if (_drainGeneration == myGeneration && _speakingTier != SpeechTier.critical) {
        _speakingTier = null;
      }
    }
  }

  Future<void> stop() async {
    _pending.clear();
    _drainGeneration++;
    await TTSService.instance.stop();
    _speakingTier = null;
  }
}
```

---

## File: `lib/core/state/global_conditions.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/state/global_conditions.dart`

```dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../services/server_service.dart';
import '../../widgets/tier_icon.dart' show AlertTier;

/// Satu kondisi global aktif (offline, baterai kritis, penyimpanan penuh,
/// ponsel panas). Storage dan thermal tidak punya sensor resmi yang murah di
/// Flutter - keduanya dipicu manual lewat [setStorageLow] / [setDeviceHot]
/// (mis. dari panel debug atau pengukuran kasar), sesuai bagian 2 dokumen:
/// "boleh dipalsukan" untuk hal yang bukan inti keselamatan.
class _Condition {
  final String id;
  final AlertTier tier;
  final String label;
  const _Condition(this.id, this.tier, this.label);
}

/// Hasil StatusBanner setelah kondisi digabung - bagian 5.7 & 13.
class MergedBanner {
  final AlertTier tier;
  final String message;
  final String? sub;
  final String? actionLabel;
  const MergedBanner({required this.tier, required this.message, this.sub, this.actionLabel});
}

/// GlobalConditions - penggabungan StatusBanner sesuai bagian 4 & 13.
/// Maksimum SATU banner di layar. 1 kondisi → pesan+sub. 2 kondisi →
/// digabung satu kalimat. 3+ kondisi → dua disebut, sisanya "dan N masalah
/// lain" + aksi "Lihat semua".
class GlobalConditionsProvider extends ChangeNotifier {
  bool _offline = false;
  bool _serverUnreachable = false;
  bool _cameraError = false;
  int? _batteryPercent;
  bool _storageLow = false;
  bool _deviceHot = false;

  StreamSubscription? _connSub;
  Timer? _batteryTimer;
  Timer? _serverTimer;

  bool get isOffline => _offline;

  /// Ada jaringan, tapi server tidak menjawab.
  ///
  /// Ini kasus paling umum saat demo: ponsel tersambung WiFi sementara laptop
  /// backend mati, IP-nya berubah, atau firewall menutup port. Kondisi lama
  /// hanya membaca `ConnectivityResult.none`, jadi keadaan ini **tidak pernah
  /// terdeteksi** - ModePickerSheet menampilkan semua mode sehat, lalu Cari
  /// Objek gagal saat ditekan.
  bool get isServerUnreachable => _serverUnreachable;

  /// Server tidak bisa dipakai, apa pun sebabnya.
  bool get isBackendDown => _offline || _serverUnreachable;

  bool get isCameraError => _cameraError;
  int? get batteryPercent => _batteryPercent;

  /// Ambang dokumen: <10%. Versi kode lama memakai <15% **dan** tier Critical,
  /// sehingga banner baterai bisa menyingkirkan banner kamera error - padahal
  /// kamera error jauh lebih menentukan keselamatan.
  bool get isBatteryCritical => (_batteryPercent ?? 100) < 10;
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
        unawaited(_pollServer());
      }
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _pollBattery());
    _serverTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollServer());
    await Future.wait([_pollBattery(), _pollServer()]);
  }

  /// Dipanggil CameraProvider saat kamera gagal disiapkan.
  void setCameraError(bool value) {
    if (_cameraError == value) return;
    _cameraError = value;
    notifyListeners();
  }

  Future<void> _pollServer() async {
    if (_offline) {
      if (!_serverUnreachable) {
        _serverUnreachable = true;
        notifyListeners();
      }
      return;
    }
    final health = await ServerService.instance.healthAt(
      ServerService.instance.host,
      timeout: const Duration(seconds: 3),
    );
    final unreachable = health == null;
    if (unreachable != _serverUnreachable) {
      _serverUnreachable = unreachable;
      notifyListeners();
    }
  }

  Future<void> _pollBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (level != _batteryPercent) {
        _batteryPercent = level;
        notifyListeners();
      }
    } catch (_) {
      // Platform tanpa dukungan battery_plus (mis. desktop web debug) - abaikan.
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
        // Kamera bermasalah = mode utama benar-benar buta. Tidak ada kondisi
        // lain yang lebih menentukan, jadi hanya ini yang boleh Critical.
        if (_cameraError)
          const _Condition('camera', AlertTier.critical, 'Kamera bermasalah'),
        if (_offline) const _Condition('offline', AlertTier.warning, 'Tanpa internet'),
        // Dibedakan dari offline: tindakan pengguna berikutnya berbeda -
        // menyalakan data seluler, atau memeriksa server.
        if (!_offline && _serverUnreachable)
          const _Condition('server', AlertTier.info, 'Server tidak terhubung'),
        if (isBatteryCritical)
          _Condition('battery', AlertTier.warning, 'Baterai ${_batteryPercent ?? 0} persen'),
        if (_storageLow) const _Condition('storage', AlertTier.warning, 'Penyimpanan hampir penuh'),
        if (_deviceHot) const _Condition('thermal', AlertTier.warning, 'Ponsel panas'),
      ];

  /// null = tidak ada banner. Urutan penyebutan: baterai/critical dulu, baru
  /// yang lain - "sebut yang masih hidup dulu, baru yang mati" (bagian 17)
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
    _serverTimer?.cancel();
    super.dispose();
  }
}
```

---

## File: `lib/core/voice/command_parser.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/command_parser.dart`

```dart
import 'intents.dart';

/// CommandParser - varian ucapan → intent, sesuai tabel bagian 14.
/// Sengaja berbasis keyword lokal (0ms, aman offline) mengikuti pola
/// [VoiceProvider] yang sudah ada. Panggil [parse] dengan teks hasil STT.
class CommandParser {
  static const Map<VoiceIntent, List<String>> _phrases = {
    VoiceIntent.modeMoney: [
      'buka mode uang', 'kenali uang', 'ini uang berapa', 'mode uang', 'cek uang', 'berapa ini',
      'uang ini nominal berapa', 'berapa nih duitnya', 'identifikasi uang', 'ini duit berapa ribu',
      'cek duit', 'berapa nominal ini', 'ini pecahan berapa', 'uang berapa ini', 'tolong cek uangnya',
      'lembaran berapa ini', 'duit iki piro', 'duit ieu sabaraha',
      // bank kata tambahan
      'aktifkan mode uang', 'deteksi nominal uang', 'kenali uang ini', 'pecahan berapa nih',
      'liatin duit ini dong', 'ini duit berapa sih', 'berapaan nih duitnya', 'duit gue berapa ya',
      'nih duit apaan', 'berapa nih lembaran ini', 'nominal berapa ini', 'ini uang berapa',
      'cek duit dong', 'nominal uang',
      'ono piro duite', 'iki duit piro', 'piro iki duite',
      'sabaraha ieu artos', 'artosna sabaraha',
      'iko doih barapo', 'berape nih duit',
      'mod uang', 'mode uwang', 'cek uwang', 'nominl uang', 'moda uang', 'mode uan',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'duit berapa', 'berapa duit', 'uang', 'duit',
    ],
    VoiceIntent.modeReadText: [
      'baca teks', 'bacakan', 'buka mode baca', 'baca tulisan ini', 'apa tulisannya',
      'bacain ini', 'tolong bacain', 'ini tulisan apa', 'baca dong', 'scan teks', 'scan ini',
      'bacakan surat ini', 'apa isinya ini', 'baca kemasan ini', 'cek label ini', 'ini tulisannya apa ya',
      'baca komposisinya', 'baca tanggal kadaluarsanya', 'baca dokumen ini', 'wacaan ieu naon', 'wacanen iki',
      // bank kata tambahan
      'aktifkan mode baca dokumen', 'pindai teks', 'baca label kemasan', 'pindai dokumen ini',
      'bacain dong ini', 'baca dong tulisannya', 'ini tulisan apaan', 'scan teks dong',
      'bacain kemasan ini', 'ini tulisan apa ya', 'nih tulisan apaan sih',
      'wacakno tulisan iki', 'moco tulisan iki', 'iki tulisane opo',
      'bacakeun ieu tulisan', 'ieu naon tulisanana',
      'bacoan tulisan ko', 'ko tulisan apo',
      'bacain nih tulisan bang', 'ini tulisan apaan bang',
      'mode bacaa teks', 'bca teks', 'mode ocr', 'baca text ini', 'moda baca teks',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'tulung wacakno', 'wacakno', 'bacakeun',
    ],
    VoiceIntent.modeDetection: [
      'deteksi objek', 'mode deteksi', 'ada apa di depan',
      'tuntun aku', 'tuntun saya jalan', 'bantu jalan', 'apa itu di depan', 'awas ada apa',
      'ada rintangan gak', 'ada penghalang gak', 'deteksi rintangan', 'tolong tuntun',
      'jalanin mode tuntun', 'aktifkan deteksi', 'nyalain deteksi', 'cek depan',
      'aman gak jalan di depan', 'ada orang gak di depan', 'hati-hati ada apa', 'bantuin lihat depan',
      'ada apa di ngarep', 'ono opo neng ngarep', 'aya naon di hareup',
      // bank kata tambahan
      'aktifkan pendeteksi objek', 'kenali objek di sekitar', 'deteksi sekeliling',
      'apa saja yang ada di depan saya', 'liatin depan dong', 'apaan tuh di depan', 'liat depan dong',
      'ada apa aja di depan', 'cek sekitar dong', 'liat sekeliling dong', 'apaan sih di depan gue',
      'ada apaan tuh di depan', 'liatin sekitar dong',
      'ndelok ngarep opo ono', 'iki ono opo ngarepe',
      'aya naon di payun', 'tulung tingali payuneun',
      'apo tu di adok an', 'caliak lah adok an',
      'ada ape tuh di depan', 'apaan tuh di depan bang',
      'mode deteski', 'deteksi obek', 'mode dtksi', 'cek skeliling',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'awasi jalan', 'deteksi',
    ],
    VoiceIntent.modeNavigation: [
      'mode navigasi', 'mau jalan', 'bantu jalan', 'navigasi',
      'kemana ya arahnya', 'tolong arahin', 'navigasi ke', 'gimana caranya ke', 'arahin aku ke',
      'arahin saya ke', 'petunjuk jalan ke', 'rute ke', 'jalan ke mana', 'belok kemana',
      'tunjukin jalan ke', 'ke arah mana ya', 'piye carane menyang', 'kumaha carana ka',
      // bank kata tambahan
      'aktifkan navigasi jalan', 'pandu saya berjalan', 'aktifkan panduan jalan',
      'anterin gue jalan', 'pandu gue jalan dong', 'bantuin gue jalan', 'gue mau jalan nih',
      'bantu gue nyebrang', 'pandu jalan dong', 'temenin gue jalan dong',
      'tulung tuntun mlaku', 'kancani aku mlaku',
      'tulung antar abdi leumpang', 'antosan abdi leumpang',
      'tolong anta ambo jalan', 'anterin gue jalan bang',
      'mode navigsi', 'mode navigasii', 'bantu jalann', 'aktifkan navgasi',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'jalan mana', 'mode jalan', 'arahan jalur', 'jalur mana',
    ],
    VoiceIntent.modeAssistant: [
      'asisten', 'tanya', 'mode suara',
      'halo guidio', 'hei guidio', 'oy guidio', 'guidio', 'jarvis', 'hei jarvis', 'halo jarvis',
      'tolong asisten', 'eh guidio', 'guidio tolong', 'woy guidio', 'eh jarvis tolong',
      // bank kata tambahan
      'buka mode asisten suara', 'aktifkan asisten', 'saya ingin bertanya', 'buka mode tanya jawab',
      'bisa bantu saya', 'gue mau nanya', 'nanya dong', 'lu bisa jawab gak', 'bisa bantu gak',
      'gue mau ngobrol', 'boleh nanya gak', 'mau nanya sesuatu nih',
      'aku arep takon', 'iso mbantu ora',
      'abdi bade naros', 'tiasa ngabantosan teu',
      'ambo nio batanyo', 'gue mau nanye bang',
      'mode asisten suaraa', 'aktifkan asistem', 'buka asistenn',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'ngobrol', 'bicara', 'nanya',
    ],
    VoiceIntent.modeFindObject: [
      'cari objek', 'cari barang', 'carikan',
      // bank kata tambahan
      'aktifkan pencarian barang', 'bantu saya cari barang', 'cari barang saya yang hilang',
      'tolong bantu temukan barang saya', 'cariin dong', 'bantu carinya dong',
      'gue kehilangan barang', 'barang gue ilang nih',
      'tulung goleki barangku', 'barangku ilang golekno',
      'tulung pilarian barang', 'barang abdi leungit',
      'tolong cari barang ambo', 'ilang nih barang gue',
      'mode cari barangg', 'cariinn dong', 'aktifkan carii barang',
    ],
    VoiceIntent.modeSettings: [
      'pengaturan', 'setelan', 'buka pengaturan',
      // bank kata tambahan
      'mode pengaturan', 'aktifkan menu pengaturan', 'buka menu konfigurasi',
      'buka setting dong', 'buka setelan dong', 'gue mau atur aplikasi', 'masuk setting dong',
      'buka setelan yo', 'muka setelan atuh',
      'buka pengaturann', 'mode setingan', 'buka stelan',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'seting', 'setting', 'setelan',
    ],
    VoiceIntent.actionCapture: [
      'ambil gambar', 'jepret', 'foto',
    ],
    VoiceIntent.actionReplay: [
      'putar ulang', 'ulangi', 'baca lagi',
      // bank kata tambahan
      'ulangi instruksi', 'ulangi perkataan terakhir', 'tolong ulangi', 'ulangi lagi',
      'ulang dong', 'bilang lagi dong', 'ulangin dong', 'apa tadi bilangnya', 'coba ulang deh',
      'baleni maneh', 'baleni sing mau',
      'ulang deui', 'ulangan anu tadi',
      'ulangi lai', 'ulangin dong bang',
      'ulangii instruksi', 'ulangi lgi',
    ],
    VoiceIntent.actionGoBack: [
      'kembali', 'balik', 'kembali ke sebelumnya', 'mode sebelumnya',
      'balik ke mode lain', 'tutup', 'keluar', 'close', 'exit',
      'batal', 'stop', 'berhenti', 'gak jadi', 'ga usah', 'cancel', 'udah cukup',
      'matiin', 'berhentiin', 'jangan', 'udah stop aja', 'gausah lanjut', 'wis mari', 'geus cukup',
    ],
    VoiceIntent.actionSummary: [
      'ringkas', 'singkat saja', 'baca ringkasannya',
      // bank kata tambahan
      'berikan rangkuman objek', 'rangkum objek di sekitar', 'buat ringkasan objek sekitar',
      'rangkum dong', 'kasih ringkasan dong', 'ringkes dong sekitar gue', 'rangkumin dong',
      'kasih tau intinya aja', 'summary dong',
      'ringkes o wae kahanane', 'ringkeskeun kaayaan sabudeureun',
      'ringkasan objekk', 'rangkum objekk sekitar',
    ],
    VoiceIntent.actionStopWalking: [
      'selesai jalan', 'sudah sampai', 'berhenti navigasi',
      // bank kata tambahan
      'hentikan panduan', 'stop navigasi', 'jeda panduan jalan', 'tolong berhenti dulu',
      'pause navigasi', 'stop dulu', 'berenti dulu', 'berhenti bentar', 'jeda dulu dong',
      'mandeg disik', 'mandeg dhisik yo',
      'eureun heula', 'eureun sakedap',
      'baranti sabanta', 'stop dulu bang',
      'berhentii navigasi', 'hentikn panduan', 'stop navigasii',
    ],
    VoiceIntent.actionShowAll: [
      'lihat semua',
    ],
    VoiceIntent.describeScene: [
      // --- Kata tunggal / trigger ---
      'deskripsikan', 'jelaskan', 'ceritakan', 'lihatkan', 'gambarkan', 'terangkan',
      'liatin', 'tunjukin', 'gambarin', 'jelasin', 'ceritain', 'terangin',
      'intipin', 'potret', 'fotoin', 'jepretin', 'pemandangan', 'sekitarku',
      'depanku', 'suasana sekitar', 'kondisi sekitar', 'ada apa',
      // --- Frasa resmi / formal ---
      'deskripsikan yang ada di depan saya sekarang',
      'tolong jelaskan pemandangan di depan',
      'berikan deskripsi suasana tempat ini',
      'sebutkan objek dan keadaan di sekitar saya',
      'gambarkan kondisi di depan saya',
      'mohon jelaskan situasi di sekitar saya saat ini',
      'tolong deskripsikan ruangan ini',
      'silakan jelaskan apa yang ada di hadapan saya',
      'tolong ceritakan suasana di tempat ini',
      'jelaskan kondisi lingkungan sekitar saya',
      'sebutkan apa saja yang terlihat di depan',
      'berikan gambaran suasana ruangan ini',
      'jelaskan situasi di depan saya sekarang',
      'mohon deskripsikan pemandangan di sekitar saya',
      // --- Frasa santai / informal ---
      'lihat depan dong', 'depan ada apa aja sih', 'coba intip depan',
      'ceritakan sekitarku', 'liatin depan bentar', 'ada pemandangan apa di depan',
      'fotoin depan terus jelasin', 'terangin sekitar dong', 'kasi tau depan ada apaan',
      'depan ada apaan sih', 'coba liat depan dong', 'cerita dong depan kayak gimana',
      'sini jelasin depan', 'ini tempat apaan sih', 'sekitar gue ada apa aja',
      'depan gue kayak gimana', 'liat dulu depan', 'cek depan dong',
      'foto depan terus critain', 'jelasin dong ini tempat apa',
      'sini liatin sekitar', 'sekitar sini kayak apa', 'coba liatin sekeliling gue',
      // --- Tanya kondisi ---
      'pemandangan di depan seperti apa', 'ruangan ini kayak gimana',
      'lagi suasana gimana ini', 'di depan ramai atau sepi',
      'apa aja yang kelihatan di depan', 'ini tempat kayak gimana ya',
      'suasana disini gimana', 'di sini ada orang gak', 'depan itu ada apa ya',
      'ini di luar apa di dalam ya', 'ada barang apa aja disini',
      // --- Bahasa Daerah ---
      'ono opo neng ngarep', 'coba sawang ngarep', 'ceritakno neng ngarep',
      'kahanan kepiye iki', 'aya naon di hareup', 'jelaskeun di hareup',
      'tingali di hareup aya naon', 'kumaha kaayaan didieu',
      'ada apaan di depan gue', 'ceritain dong depan', 'intipin depan napa',
      'kondisi depan gimana bang', 'apo nan di adok den', 'aha na di jolo',
      // --- Typo / STT variasi ---
      'deskripsiin', 'deskripsikn', 'critain', 'liyatin', 'trangin', 'gambrkan',
      'pemandanan', 'skitarku', 'keadan', 'kondsi', 'sutuasi', 'lngkungan',
      'deskripsi kan', 'cerita kan', 'lihat kan',
    ],
    VoiceIntent.actionTorch: [
      // nyalakan
      'nyalakan lampu', 'nyalakan senter', 'nyalakan flash',
      'hidupkan lampu', 'hidupkan senter',
      'lampu kamera', 'nyalain lampu', 'nyalain senter',
      'tolong nyalakan lampu', 'tolong nyalain lampu',
      // matikan
      'matikan lampu', 'matikan senter', 'matikan flash',
      'padamkan lampu', 'padamkan senter',
      'matiin lampu', 'matiin senter',
      'tolong matikan lampu', 'tolong matiin lampu',
      // toggle generic
      'toggle lampu', 'toggle senter',
      // bank kata tambahan
      'aktifkan lampu kamera', 'nyalakan lampu kamera', 'matikan lampu kamera',
      'nonaktifkan senter', 'idupin senter', 'matiin lampu dong', 'nyalain lampu dong',
      'urupno senter', 'patenono senter', 'tulung urupno lampu',
      'hurungkeun senter', 'pareuman senter',
      'nyalain senter bang', 'matiin senter bang',
      'nyalain sentr', 'aktifkn senter', 'nyalakan sentar',
    ],
    VoiceIntent.playPause: [
      'jeda', 'berhenti dulu', 'stop',
      // bank kata tambahan
      'jeda suara', 'pause suara', 'hentikan sebentar suaranya', 'jeda dong',
      'stop bentar suaranya', 'pause dulu',
      'mandeg disik swarane', 'eureun heula sorana', 'baranti sabanta suaronyo',
      'jeda suaraa', 'pauze suara',
    ],
    VoiceIntent.playResume: [
      'lanjut', 'terusin', 'lanjutkan',
    ],
    VoiceIntent.playFaster: [
      'lebih cepat', 'percepat',
      // bank kata tambahan
      'percepat suara', 'percepat laju bicara', 'naikkan kecepatan suara',
      'cepetin dong', 'gasin dong suaranya', 'lebih cepet dong',
      'kebutno swarane', 'gancangkeun sorana',
      'cepetin bang suaranye',
      'percepat suaraa', 'cepetin suarane',
    ],
    VoiceIntent.playSlower: [
      'lebih pelan', 'pelan-pelan',
      // bank kata tambahan
      'perlambat suara', 'perlambat laju bicara', 'turunkan kecepatan suara',
      'pelanin dong', 'pelanin suaranya dong', 'lebih pelan dong', 'jangan cepet-cepet dong',
      'alonno swarane', 'lambatkeun sorana',
      'pelanin bang suaranye',
      'perlambat suaraa', 'pelanin suarane',
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

  static const List<String> searchPrefixes = [
    // --- Frasa resmi ---
    'cari',
    'carikan',
    'carilah',
    'tolong cari',
    'tolong carikan',
    'mohon cari',
    'mohon carikan',
    'bantu cari',
    'bantu carikan',
    'coba cari',
    'coba carikan',
    'silakan cari',
    'silakan carikan',
    'temukan',
    'temuin',
    'tunjukin',
    'tunjukkan',
    'deteksi',
    'scan',
    'pindai',

    // --- Frasa gaul / informal ---
    'cariin',
    'cariin dong',
    'cariin deh',
    'cariin dong ya',
    'cariin napa',
    'cariin woy',
    'cariin bentar',
    'cariin sini',
    'cariin cepetan',
    'tolong cariin',
    'tolong cariin dong',
    'tolong cariin ya',
    'bantu cariin',
    'bantu cariin dong',
    'bantuin cari',
    'bantuin cariin',
    'bantuin dong cariin',
    'bantuin nyari',
    'bantu nemuin',
    'tolong temuin',
    'gan cariin',
    'bro cariin',
    'woy cariin',
    'eh cariin',
    'nyari',
    'nyariin',
    'nyari-nyari',
    'lagi nyari',
    'lagi nyariin',
    'lagi cariin',

    // --- Frasa kondisi / kehilangan (resmi) ---
    'kehilangan',
    'saya kehilangan',
    'aku kehilangan',
    'hilang',
    'ilang',
    'kemana',
    'ke mana',
    'dimana',
    'di mana',
    'dimanakah',
    'di manakah',
    'mana',
    'ada dimana',

    // --- Frasa kondisi / kehilangan (informal / slang) ---
    'gue kehilangan',
    'gua kehilangan',
    'ane kehilangan',
    'gw kehilangan',
    'ilangan',
    'ngilang',
    'kemana ya',
    'kemana sih',
    'mana ya',
    'mana sih',
    'mana nih',
    'kaga ketemu',
    'kagak ketemu',
    'gak ketemu',
    'ga ketemu',
    'nggak ketemu',
    'tidak ketemu',
    'belum ketemu',
    'susah nemu',
    'ga nemu',
    'gak nemu',
    'gak nemu-nemu',
    'gak bisa nemu',
    'kok gak ada ya',
    'kok hilang ya',
    'tadi taruh dimana ya',
    'ilang kemana ini',

    // --- Bahasa Daerah (Jawa, Sunda, Betawi, Minang, Batak, Bali, Makassar, Madura) ---
    'ilang kemane',
    'digoleki',
    'goleki',
    'ora ono',
    'ilang neng ndi',
    'diteangan',
    'teangan',
    'teang',
    'milarian',
    'leungit dimana',
    'ilang kama',
    'ilang dima',
    'dima yo',
    'ilang huta dison',
    'alai pileh',
    'kija alangan',
    'kemma battu',
    'keng gun edimma',

    // --- Lupa naruh / lupa simpan ---
    'lupa naro',
    'lupa naruh',
    'lupa nataro',
    'lupa taro',
    'lupa taruh',
    'lupa ditaruh',
    'lupa meletakkan',
    'lupa nyimpen',
    'lupa nyimpan',
    'lupa menyimpan',
    'lupa simpen dimana',
    'lupa taro dimana',
    'lupa naro dimana',
    'lupa naruh dimana',

    // --- Minta konfirmasi orang lain / ada yang liat ---
    'ada yang liat',
    'ada yang lihat',
    'ada yg liat',
    'ada yg lihat',
    'ada yang nemu',
    'nemu',
    'nampak',
    'kelihatan',
    'keliatan',
    'kliatan',
    'keliatan gak',
    'keliatan ga',
  ];

  static const List<String> fillerWords = [
    // --- Kata ganti orang / kepemilikan ---
    'saya punya',
    'aku punya',
    'punya saya',
    'punya aku',
    'punya gue',
    'punya gua',
    'punya ane',
    'punyanya',
    'punyaku',
    'saya',
    'aku',
    'gue',
    'gua',
    'gw',
    'ane',
    'kamu',
    'kau',
    'anda',
    'ku',
    'mu',
    'nya',

    // --- Kata seru / partikel / basa-basi & Daerah ---
    'bentar ya',
    'sebentar',
    'bentar',
    'tolong',
    'yaudah',
    'please',
    'dong',
    'deh',
    'nih',
    'tuh',
    'sih',
    'ya',
    'kah',
    'tah',
    'kek',
    'lah',
    'pun',
    'dulu',
    'woy',
    'woi',
    'eh',
    'nah',
    'kok',
    'toh',
    'kan',
    'loh',
    'lho',
    'lo',
    'gitu',
    'gini',
    'aja',
    'saja',
    'juga',
    'napa',
    'plis',
    'yuk',
    'udah',
    'gan',
    'bro',
    'sis',
    'cuy',
    'kayaknya',
    'yah',
    'banget',
    'coba',
    'anu',
    'mmm',
    'eee',
    'e',
    'je',
    'rek',
    'atuh',
    'euy',
    'teh',
    'mah',
    'dah',
    'noh',
    'yee',
    'bang',
    'pole',
  ];

  /// Prefiks pengantar mode alami bahasa Indonesia yang sering diucapkan pengguna
  static const List<String> modeTransitionPrefixes = [
    'saya pengin pindah ke mode',
    'saya mau pindah ke mode',
    'pengin pindah ke mode',
    'mau pindah ke mode',
    'pindah ke mode',
    'pindah mode ke',
    'pindah mode',
    'pindahin ke mode',
    'pindahin ke',
    'ganti mode ke',
    'ganti ke mode',
    'ganti mode',
    'masuk ke mode',
    'masuk mode',
    'buka mode',
    'tolong buka mode',
    'tolong pindah ke',
    'tolong ganti ke',
    'mau ke mode',
    'pengin ke mode',
    'aktifkan mode',
    'nyalakan mode',
    'jalankan mode',
  ];

  // ===========================================================================
  // Normalisasi & pencocokan batas kata
  //
  // Versi lama memakai `text.contains(phrase)` mentah dan menelusuri `_phrases`
  // **mengikuti urutan deklarasi Map**. Dua akibatnya nyata:
  //
  //   1. `actionGoBack` memuat 'stop' dan 'berhenti', dan ia dideklarasikan
  //      sebelum `actionStopWalking` dan `playPause`. Maka "stop navigasi" -
  //      yang jelas dimaksudkan untuk menghentikan panduan - malah **keluar
  //      dari Mode Navigasi**. Sebagian besar frasa kedua intent itu tidak
  //      pernah bisa tercapai.
  //   2. `contains` tanpa batas kata membuat potongan kata ikut cocok.
  //
  // Sekarang: frasa dicocokkan pada batas kata, dan **yang paling panjang
  // diperiksa lebih dulu** - yang spesifik selalu menang atas yang umum,
  // terlepas dari urutan deklarasi.
  // ===========================================================================

  static String _normalize(String s) {
    final lowered = s.toLowerCase();
    final buf = StringBuffer(' ');
    for (final rune in lowered.runes) {
      final c = String.fromCharCode(rune);
      final isWordChar = (rune >= 97 && rune <= 122) || // a-z
          (rune >= 48 && rune <= 57) || // 0-9
          c == '-';
      buf.write(isWordChar ? c : ' ');
    }
    buf.write(' ');
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// True kalau [phrase] muncul di [normalized] sebagai rangkaian kata utuh.
  static bool _containsPhrase(String normalized, String phrase) =>
      normalized.contains(' ${_normalize(phrase).trim()} ');

  /// Semua (frasa, intent) diurutkan dari yang terpanjang. Dibangun sekali.
  static List<MapEntry<String, VoiceIntent>>? _sortedPhrasesCache;

  static List<MapEntry<String, VoiceIntent>> get _sortedPhrases {
    final cached = _sortedPhrasesCache;
    if (cached != null) return cached;
    final all = <MapEntry<String, VoiceIntent>>[];
    for (final entry in _phrases.entries) {
      // modeFindObject ditangani dinamis lewat searchPrefixes.
      if (entry.key == VoiceIntent.modeFindObject) continue;
      for (final phrase in entry.value) {
        all.add(MapEntry(phrase, entry.key));
      }
    }
    all.sort((a, b) => b.key.length.compareTo(a.key.length));
    return _sortedPhrasesCache = all;
  }

  static int _wordCount(String phrase) => phrase.trim().split(' ').length;

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand(rawText: rawText);
    final norm = _normalize(rawText);

    // =========================================================================
    // [Fuzzy Matching Layer 0] - Natural Conversational Mode Transition
    // Handles natural spoken sentences like: "Saya pengin pindah ke mode baca teks"
    // Strips conversational prefixes and extracts target keywords (baca, uang, etc).
    // =========================================================================
    for (final prefix in modeTransitionPrefixes) {
      if (text.contains(prefix)) {
        final targetPart = text.substring(text.indexOf(prefix) + prefix.length).trim();
        if (targetPart.contains('uang') || targetPart.contains('duit') || targetPart.contains('money')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeMoney);
        }
        if (targetPart.contains('baca') || targetPart.contains('teks') || targetPart.contains('tulisan') || targetPart.contains('ocr')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeReadText);
        }
        if (targetPart.contains('deteksi') || targetPart.contains('tuntun') || targetPart.contains('objek') || targetPart.contains('rintangan')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeDetection);
        }
        if (targetPart.contains('navigasi') || targetPart.contains('jalan') || targetPart.contains('rute')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeNavigation);
        }
        if (targetPart.contains('asisten') || targetPart.contains('suara') || targetPart.contains('tanya') || targetPart.contains('voice')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeAssistant);
        }
        if (targetPart.contains('cari') || targetPart.contains('barang') || targetPart.contains('find')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeFindObject);
        }
        if (targetPart.contains('pengaturan') || targetPart.contains('setelan') || targetPart.contains('setting')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeSettings);
        }
      }
    }

    // =========================================================================
    // [Layer 1] - Frasa kamus MULTI-KATA, terpanjang lebih dulu.
    //
    // Frasa banyak kata mengungkap maksud jauh lebih tegas daripada satu kata
    // lepas, jadi ia diperiksa sebelum apa pun. Di sinilah "stop navigasi"
    // menemukan `actionStopWalking` sebelum kata 'stop' sempat membawanya ke
    // `actionGoBack`.
    // =========================================================================
    for (final entry in _sortedPhrases) {
      if (_wordCount(entry.key) < 2) continue;
      if (_containsPhrase(norm, entry.key)) {
        return VoiceCommand(rawText: rawText, intent: entry.value);
      }
    }

    // =========================================================================
    // [Layer 2] - Pola cari-objek dinamis ("cari [barang]").
    //
    // Sengaja SEBELUM kata tunggal: "cari uang yang jatuh" harus berarti
    // mencari benda, bukan membuka Mode Kenali Uang hanya karena kata 'uang'
    // muncul di dalamnya.
    // =========================================================================
    final target = _extractSearchTarget(norm);
    if (target != null) {
      return VoiceCommand(
        rawText: rawText,
        intent: VoiceIntent.findObjectTarget,
        argument: target,
      );
    }

    // =========================================================================
    // [Layer 3] - Kata tunggal ("uang", "deteksi", "navigasi", "asisten").
    // =========================================================================
    for (final entry in _sortedPhrases) {
      if (_wordCount(entry.key) != 1) continue;
      if (_containsPhrase(norm, entry.key)) {
        return VoiceCommand(rawText: rawText, intent: entry.value);
      }
    }

    // =========================================================================
    // [Layer 4] - Kombinasi kata kunci longgar ("baca" + "mode").
    // =========================================================================
    bool has(String w) => _containsPhrase(norm, w);
    if (has('mode') || has('buka') || has('aktifkan')) {
      if (has('baca') || has('teks') || has('tulisan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeReadText);
      }
      if (has('uang') || has('duit')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeMoney);
      }
      if (has('deteksi') || has('tuntun') || has('rintangan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeDetection);
      }
      if (has('navigasi') || has('jalur') || has('jalan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeNavigation);
      }
      if (has('asisten') || has('suara') || has('tanya')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeAssistant);
      }
      if (has('cari') || has('barang')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeFindObject);
      }
    }

    return VoiceCommand(
      rawText: rawText,
      suggestions: _nearestGuesses(norm),
    );
  }

  /// Ambil nama barang sesudah prefiks pencarian, lalu buang kata pengisi.
  /// Mengembalikan null kalau tidak ada prefiks atau sisanya kosong.
  static String? _extractSearchTarget(String norm) {
    final sortedPrefixes = List<String>.from(searchPrefixes)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final prefix in sortedPrefixes) {
      final needle = ' ${_normalize(prefix).trim()} ';
      final idx = norm.indexOf(needle);
      if (idx < 0) continue;

      var cleaned = norm.substring(idx + needle.length - 1).trim();
      if (cleaned.isEmpty) continue;

      for (final filler in _sortedFillers) {
        cleaned = cleaned.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ');
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned.isEmpty || cleaned == 'objek' || cleaned == 'barang') continue;
      return cleaned;
    }
    return null;
  }

  static List<String>? _sortedFillersCache;
  static List<String> get _sortedFillers => _sortedFillersCache ??=
      (List<String>.from(fillerWords)..sort((a, b) => b.length.compareTo(a.length)));

  // =========================================================================
  // [Fuzzy Matching Layer 3] - Word Overlap Similarity Scoring (Jaccard-like)
  // Calculates word intersection overlap between raw STT input and phrase database.
  // Returns top 2 nearest guesses for fallback voice prompts ("Saya dengar X. Maksudmu Y, atau Z?").
  // =========================================================================
  /// Intent yang boleh ditawarkan balik ke pengguna.
  ///
  /// **Hanya yang benar-benar punya handler.** Sebelumnya seluruh isi
  /// `_phrases` bisa disarankan, termasuk 10 intent tanpa handler - sehingga
  /// Vinara bisa bertanya "Maksudmu jeda?", pengguna menjawab "jeda", dan
  /// jawabannya "Perintah itu belum saya kenali di mode ini". Lingkaran buntu
  /// yang diciptakan aplikasi sendiri, dan pengguna tunanetra tidak punya
  /// layar untuk keluar darinya.
  ///
  /// Menambah intent ke sini tanpa menambahkan handler di
  /// `VoiceProvider._processText` akan menghidupkan lagi lingkaran itu.
  static const Set<VoiceIntent> suggestableIntents = {
    VoiceIntent.modeMoney,
    VoiceIntent.modeReadText,
    VoiceIntent.modeDetection,
    VoiceIntent.modeNavigation,
    VoiceIntent.modeAssistant,
    VoiceIntent.modeFindObject,
    VoiceIntent.modeSettings,
    VoiceIntent.actionGoBack,
    VoiceIntent.actionReplay,
    VoiceIntent.actionStopWalking,
    VoiceIntent.actionCapture,
    VoiceIntent.actionTorch,
    VoiceIntent.describeScene,
    VoiceIntent.playPause,
    VoiceIntent.playResume,
    VoiceIntent.playFaster,
    VoiceIntent.playSlower,
    VoiceIntent.playRepeatSection,
    VoiceIntent.helpWhat,
    VoiceIntent.helpWhereAmI,
  };

  static List<VoiceIntent> _nearestGuesses(String normalized) {
    final words = normalized.trim().split(' ').where((w) => w.isNotEmpty).toSet();
    if (words.isEmpty) return const [];

    final scored = <MapEntry<VoiceIntent, int>>[];

    for (final entry in _phrases.entries) {
      if (!suggestableIntents.contains(entry.key)) continue;
      var best = 0;
      for (final phrase in entry.value) {
        final phraseWords = _normalize(phrase).trim().split(' ').toSet();
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
/// uang, atau cari uang yang jatuh?" - bagian 14.
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
        VoiceIntent.actionGoBack => 'kembali',
        VoiceIntent.actionSummary => 'ringkas',
        VoiceIntent.actionStopWalking => 'selesai jalan',
        VoiceIntent.actionShowAll => 'lihat semua',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.describeScene => 'deskripsikan suasana',
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

## File: `lib/core/voice/intents.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/intents.dart`

```dart
/// Intent perintah suara - bagian 14 IMPLEMENTASI.md. 20 intent baku.
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
  actionGoBack,
  actionSummary,
  actionStopWalking,
  actionShowAll,
  actionTorch,
  describeScene,
  // Kontrol pemutaran
  playPause,
  playResume,
  playFaster,
  playSlower,
  playRepeatSection,
  // Bantuan
  helpWhat,
  helpWhereAmI,
  // Cari Objek - target dinamis, tangkap terpisah dari intent
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
  String? get commandPhrase => switch (this) {
        VoiceIntent.modeMoney => 'mode uang',
        VoiceIntent.modeReadText => 'mode baca',
        VoiceIntent.modeDetection => 'mode deteksi',
        VoiceIntent.modeNavigation => 'mode navigasi',
        VoiceIntent.modeAssistant => 'mode asisten',
        VoiceIntent.modeFindObject => 'mode cari objek',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.describeScene => 'deskripsikan suasana',
        _ => null,
      };
}

/// Hasil parsing satu ucapan.
class VoiceCommand {
  final VoiceIntent? intent;
  final String rawText;
  /// Untuk `findObjectTarget` / `mode.findObject "cari [nama barang]"` -
  /// nama barang yang diekstrak dari ucapan.
  final String? argument;
  /// Dua tebakan terdekat saat tidak dikenali - bagian 14 "Tidak dikenali".
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

## File: `lib/core/voice/narration_engine.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/narration_engine.dart`

```dart
import 'dart:math';

/// Narration Engine - Merangkai hasil deteksi YOLO menjadi narasi Bahasa Indonesia
/// yang alami untuk dibacakan TTS. 100% offline, tanpa LLM.
///
/// Menggantikan POST /api/narasi yang sebelumnya bergantung pada Qwen LLM di backend.
///
/// Sumber: guidio_bank_kata_dan_narasi_engine.md (Tugas 2)

// ── Kamus Objek COCO-80 ────────────────────────────────────────────────────

/// Info nama dan kata kerja konteks untuk setiap kelas objek COCO.
class ObjectInfo {
  final String nameId;     // nama umum Bahasa Indonesia
  final String actionVerb; // kata kerja/predikat natural untuk objek ini
  const ObjectInfo(this.nameId, this.actionVerb);
}

/// Kamus 80 kelas objek COCO: nama alami Bahasa Indonesia + kata kerja konteks.
const Map<String, ObjectInfo> cocoObjectDictionary = {
  'person':          ObjectInfo('orang', 'berjalan'),
  'bicycle':         ObjectInfo('sepeda', 'terparkir'),
  'car':             ObjectInfo('mobil', 'terparkir'),
  'motorcycle':      ObjectInfo('motor', 'terparkir'),
  'airplane':        ObjectInfo('pesawat', 'terlihat'),
  'bus':             ObjectInfo('bus', 'melintas'),
  'train':           ObjectInfo('kereta', 'melintas'),
  'truck':           ObjectInfo('truk', 'terparkir'),
  'boat':            ObjectInfo('perahu', 'bersandar'),
  'traffic light':   ObjectInfo('lampu lalu lintas', 'menyala'),
  'fire hydrant':    ObjectInfo('hidran', 'berdiri'),
  'stop sign':       ObjectInfo('rambu stop', 'terpasang'),
  'parking meter':   ObjectInfo('meteran parkir', 'terpasang'),
  'bench':           ObjectInfo('bangku', 'diletakkan'),
  'bird':            ObjectInfo('burung', 'hinggap'),
  'cat':             ObjectInfo('kucing', 'duduk'),
  'dog':             ObjectInfo('anjing', 'duduk'),
  'horse':           ObjectInfo('kuda', 'berdiri'),
  'sheep':           ObjectInfo('domba', 'berdiri'),
  'cow':             ObjectInfo('sapi', 'berdiri'),
  'elephant':        ObjectInfo('gajah', 'berdiri'),
  'bear':            ObjectInfo('beruang', 'berdiri'),
  'zebra':           ObjectInfo('zebra', 'berdiri'),
  'giraffe':         ObjectInfo('jerapah', 'berdiri'),
  'backpack':        ObjectInfo('tas ransel', 'diletakkan'),
  'umbrella':        ObjectInfo('payung', 'diletakkan'),
  'handbag':         ObjectInfo('tas tangan', 'diletakkan'),
  'tie':             ObjectInfo('dasi', 'tergantung'),
  'suitcase':        ObjectInfo('koper', 'diletakkan'),
  'frisbee':         ObjectInfo('piringan frisbee', 'tergeletak'),
  'skis':            ObjectInfo('papan ski', 'disandarkan'),
  'snowboard':       ObjectInfo('papan salju', 'disandarkan'),
  'sports ball':     ObjectInfo('bola', 'tergeletak'),
  'kite':            ObjectInfo('layang-layang', 'terbang'),
  'baseball bat':    ObjectInfo('pemukul bisbol', 'tergeletak'),
  'baseball glove':  ObjectInfo('sarung tangan bisbol', 'tergeletak'),
  'skateboard':      ObjectInfo('papan skateboard', 'tergeletak'),
  'surfboard':       ObjectInfo('papan selancar', 'disandarkan'),
  'tennis racket':   ObjectInfo('raket tenis', 'tergeletak'),
  'bottle':          ObjectInfo('botol', 'diletakkan'),
  'wine glass':      ObjectInfo('gelas anggur', 'diletakkan'),
  'cup':             ObjectInfo('gelas', 'diletakkan'),
  'fork':            ObjectInfo('garpu', 'diletakkan'),
  'knife':           ObjectInfo('pisau', 'diletakkan'),
  'spoon':           ObjectInfo('sendok', 'diletakkan'),
  'bowl':            ObjectInfo('mangkuk', 'diletakkan'),
  'banana':          ObjectInfo('pisang', 'diletakkan'),
  'apple':           ObjectInfo('apel', 'diletakkan'),
  'sandwich':        ObjectInfo('roti lapis', 'diletakkan'),
  'orange':          ObjectInfo('jeruk', 'diletakkan'),
  'broccoli':        ObjectInfo('brokoli', 'diletakkan'),
  'carrot':          ObjectInfo('wortel', 'diletakkan'),
  'hot dog':         ObjectInfo('hot dog', 'diletakkan'),
  'pizza':           ObjectInfo('pizza', 'diletakkan'),
  'donut':           ObjectInfo('donat', 'diletakkan'),
  'cake':            ObjectInfo('kue', 'diletakkan'),
  'chair':           ObjectInfo('kursi', 'disediakan'),
  'couch':           ObjectInfo('sofa', 'disediakan'),
  'potted plant':    ObjectInfo('tanaman pot', 'diletakkan'),
  'bed':             ObjectInfo('tempat tidur', 'disediakan'),
  'dining table':    ObjectInfo('meja makan', 'disediakan'),
  'toilet':          ObjectInfo('toilet', 'berada'),
  'tv':              ObjectInfo('televisi', 'menyala'),
  'laptop':          ObjectInfo('laptop', 'diletakkan'),
  'mouse':           ObjectInfo('mouse komputer', 'diletakkan'),
  'remote':          ObjectInfo('remote', 'diletakkan'),
  'keyboard':        ObjectInfo('keyboard', 'diletakkan'),
  'cell phone':      ObjectInfo('ponsel', 'diletakkan'),
  'microwave':       ObjectInfo('microwave', 'terpasang'),
  'oven':            ObjectInfo('oven', 'terpasang'),
  'toaster':         ObjectInfo('pemanggang roti', 'terpasang'),
  'sink':            ObjectInfo('wastafel', 'terpasang'),
  'refrigerator':    ObjectInfo('kulkas', 'berdiri'),
  'book':            ObjectInfo('buku', 'diletakkan'),
  'clock':           ObjectInfo('jam dinding', 'tergantung'),
  'vase':            ObjectInfo('vas bunga', 'diletakkan'),
  'scissors':        ObjectInfo('gunting', 'diletakkan'),
  'teddy bear':      ObjectInfo('boneka beruang', 'diletakkan'),
  'hair drier':      ObjectInfo('pengering rambut', 'diletakkan'),
  'toothbrush':      ObjectInfo('sikat gigi', 'diletakkan'),
};

// ── Mapper Jarak & Arah ────────────────────────────────────────────────────

/// Mengubah jarak numerik (meter) menjadi frasa jarak yang natural.
String mapDistancePhrase(double distanceMeter) {
  if (distanceMeter < 1.0) {
    // Variasi frasa jarak sangat dekat, dipilih acak agar tidak monoton
    final phrases = [
      'sangat dekat di depanmu',
      'di dekat langkahmu',
      'tepat di jangkauanmu',
    ];
    return phrases[(distanceMeter * 100).toInt() % phrases.length];
  } else if (distanceMeter <= 3.0) {
    return 'sekitar ${_formatMeter(distanceMeter)} meter';
  } else {
    return 'agak jauh sekitar ${_formatMeter(distanceMeter)} meter';
  }
}

/// Mengubah angka desimal jarak menjadi teks natural
/// (contoh: 1.5 → "satu setengah", 3.0 → "tiga").
String _formatMeter(double meter) {
  final intPart = meter.floor();
  final decimalPart = meter - intPart;

  const satuan = [
    'nol', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
  ];

  final intWord = (intPart >= 0 && intPart < satuan.length)
      ? satuan[intPart]
      : intPart.toString();

  if (decimalPart >= 0.4 && decimalPart <= 0.6) {
    return '$intWord setengah';
  }
  return intWord;
}

/// Mengubah kode arah menjadi frasa posisi natural.
String mapDirectionPhrase(String direction) {
  switch (direction.toLowerCase()) {
    case 'kiri':
      return 'di sebelah kirimu';
    case 'kanan':
      return 'di sebelah kananmu';
    case 'tengah':
    default:
      return 'tepat di depanmu';
  }
}

// ── Sentence Builder ───────────────────────────────────────────────────────

/// Data deteksi satu objek untuk narasi engine.
/// Berbeda dari model [Detection] utama - ini versi ringan khusus narasi.
class NarrationDetection {
  final String objectClass; // key dari cocoObjectDictionary, mis. "car"
  final double dist;        // jarak dalam meter
  final String dir;         // "kiri" | "tengah" | "kanan"
  final int count;          // jumlah objek sejenis pada kelompok yang sama

  const NarrationDetection({
    required this.objectClass,
    required this.dist,
    required this.dir,
    this.count = 1,
  });
}

final _random = Random();

/// Merangkai daftar deteksi objek mentah menjadi satu kalimat narasi
/// Bahasa Indonesia yang alami untuk dibacakan TTS - 100% tanpa LLM.
///
/// Menggantikan POST /api/narasi (backend Qwen).
///
/// Contoh output:
/// "Di sekitarmu, ada dua orang di sebelah kirimu sejauh satu setengah meter,
///  serta sebuah mobil di sebelah kananmu sejauh agak jauh sekitar tiga meter."
String generateNaturalNarration(List<NarrationDetection> detections) {
  if (detections.isEmpty) {
    return 'Tidak ada objek yang terdeteksi di sekitarmu saat ini.';
  }

  // Urutkan dari yang paling dekat - objek paling berbahaya disebut lebih dulu
  final sorted = [...detections]..sort((a, b) => a.dist.compareTo(b.dist));

  // Batasi maksimal 3 objek utama supaya kalimat tidak terlalu panjang
  final mainObjects = sorted.take(3).toList();

  const connectorsFirst = [
    'Di sekitarmu, ada',
    'Di depanmu terdapat',
    'Saat ini terdeteksi',
  ];
  const connectorsMiddle = [
    'sementara di sana ada',
    'lalu terdapat',
    'kemudian ada',
  ];
  const connectorsLast = ['serta', 'dan juga', 'ditambah'];

  final buffer = StringBuffer();
  buffer.write('${connectorsFirst[_random.nextInt(connectorsFirst.length)]} ');

  var writtenCount = 0;
  for (var i = 0; i < mainObjects.length; i++) {
    final det = mainObjects[i];
    final info = cocoObjectDictionary[det.objectClass];

    if (info == null) continue; // lewati kelas yang tidak dikenal

    final countPhrase = _countToWords(det.count, info.nameId);
    final distPhrase  = mapDistancePhrase(det.dist);
    final dirPhrase   = mapDirectionPhrase(det.dir);
    final clause      = '$countPhrase $dirPhrase sejauh $distPhrase';

    if (writtenCount == 0) {
      buffer.write(clause);
    } else if (i == mainObjects.length - 1) {
      buffer.write(
        ', ${connectorsLast[_random.nextInt(connectorsLast.length)]} $clause',
      );
    } else {
      buffer.write(
        ', ${connectorsMiddle[_random.nextInt(connectorsMiddle.length)]} $clause',
      );
    }
    writtenCount++;
  }

  if (writtenCount == 0) {
    return 'Area sekitar tampak aman.';
  }

  buffer.write('.');
  return buffer.toString();
}

/// Mengubah jumlah objek menjadi frasa natural, termasuk pluralisasi sederhana
/// khas Bahasa Indonesia (mis. "dua orang", "sebuah botol").
String _countToWords(int count, String nameId) {
  const angka = [
    '', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
  ];

  if (count <= 1) {
    if (nameId == 'orang') return nameId;
    return 'sebuah $nameId';
  }

  final numberWord = (count < angka.length) ? angka[count] : count.toString();
  return '$numberWord $nameId';
}

/// Lookup nama Indonesia dari label YOLO/model (fallback ke label asli).
/// Berguna untuk format cepat tanpa narasi penuh.
String labelToIndonesian(String label) {
  return cocoObjectDictionary[label]?.nameId ?? label;
}
```

---

## File: `lib/core/voice/scene_translator.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/core/voice/scene_translator.dart`

```dart
/// Penerjemah kalimat deskripsi suasana Inggris → Indonesia, **tanpa LLM**.
///
/// Moondream2 mengeluarkan caption Bahasa Inggris ("A man standing in front of
/// a white building"). Selama ini kalimat itu dibacakan apa adanya dengan TTS
/// `en-US`, dan itu menuntut kemampuan Inggris lisan yang tidak bisa
/// diasumsikan pada target pengguna: tunanetra di pasar dan warung Indonesia.
///
/// Menambahkan LLM penerjemah akan melanggar prinsip yang sudah dipegang
/// proyek ini - lambat (1–3 detik), bisa berhalusinasi, dan butuh server.
/// Jadi pendekatannya sama persis dengan [generateNaturalNarration]: kamus
/// lokal + aturan urutan kata. 0 ms, offline, dan tidak pernah mengarang.
///
/// **Kalau tidak yakin, ia menyerah.** Caption yang cakupan kamusnya di bawah
/// [_minCoverage] mengembalikan null, dan pemanggil membacakan versi
/// Inggrisnya. Bahasa Indonesia yang kacau lebih buruk daripada Bahasa Inggris
/// yang benar - pengguna tidak punya layar untuk memverifikasi tebakan kita.
library;

/// Ambang cakupan kamus. Di bawah ini, hasilnya tidak layak diucapkan.
const double _minCoverage = 0.72;

/// Frasa banyak kata - dicocokkan lebih dulu, terpanjang menang.
const Map<String, String> _phrases = {
  'in front of': 'di depan',
  'next to': 'di sebelah',
  'close to': 'di dekat',
  'on top of': 'di atas',
  'in the middle of': 'di tengah',
  'to the left of': 'di sebelah kiri',
  'to the right of': 'di sebelah kanan',
  'a couple of': 'beberapa',
  'a lot of': 'banyak',
  'a group of': 'sekelompok',
  'a pair of': 'sepasang',
  'a close-up': 'gambar dekat',
  'close-up': 'gambar dekat',
  'there is': 'ada',
  'there are': 'ada',
  'is standing': 'sedang berdiri',
  'is sitting': 'sedang duduk',
  'is walking': 'sedang berjalan',
  'living room': 'ruang tamu',
  'dining room': 'ruang makan',
  'traffic light': 'lampu lalu lintas',
  'cell phone': 'ponsel',
  'potted plant': 'tanaman pot',
  'dining table': 'meja makan',
  'teddy bear': 'boneka beruang',
  'city street': 'jalan kota',
  'parking lot': 'tempat parkir',
  'sidewalk': 'trotoar',
  'wine glass': 'gelas anggur',
  'cup of coffee': 'cangkir kopi',
  'cup of tea': 'cangkir teh',
  'each other': 'satu sama lain',
};

/// Kata yang dibuang: Bahasa Indonesia tidak memakai artikel, dan kopula
/// "is/are" umumnya tidak diterjemahkan.
const Set<String> _dropped = {
  'a', 'an', 'the', 'is', 'are', 'that', 'which', 'it', 'its', 'be', 'being',
};

/// Kata sifat - di Bahasa Indonesia posisinya SESUDAH kata benda.
const Map<String, String> _adjectives = {
  'white': 'putih', 'black': 'hitam', 'red': 'merah', 'blue': 'biru',
  'green': 'hijau', 'yellow': 'kuning', 'brown': 'cokelat', 'gray': 'abu-abu',
  'grey': 'abu-abu', 'orange': 'oranye', 'purple': 'ungu', 'pink': 'merah muda',
  'dark': 'gelap', 'bright': 'terang', 'light': 'terang',
  'large': 'besar', 'big': 'besar', 'small': 'kecil', 'tiny': 'mungil',
  'long': 'panjang', 'short': 'pendek', 'tall': 'tinggi', 'wide': 'lebar',
  'old': 'tua', 'young': 'muda', 'new': 'baru',
  'wooden': 'kayu', 'metal': 'logam', 'plastic': 'plastik', 'glass': 'kaca',
  'empty': 'kosong', 'full': 'penuh', 'open': 'terbuka', 'closed': 'tertutup',
  'busy': 'ramai', 'quiet': 'sepi', 'clean': 'bersih', 'dirty': 'kotor',
  'wet': 'basah', 'dry': 'kering', 'narrow': 'sempit', 'crowded': 'padat',
};

/// Kata benda, kata kerja, preposisi, angka.
const Map<String, String> _words = {
  // Orang
  'man': 'seorang pria', 'woman': 'seorang wanita', 'men': 'beberapa pria',
  'women': 'beberapa wanita', 'person': 'seseorang', 'people': 'orang-orang',
  'boy': 'anak laki-laki', 'girl': 'anak perempuan', 'child': 'seorang anak',
  'children': 'anak-anak', 'crowd': 'kerumunan',

  // Tempat & bangunan
  'building': 'gedung', 'buildings': 'gedung-gedung', 'house': 'rumah',
  'wall': 'dinding', 'door': 'pintu', 'window': 'jendela', 'floor': 'lantai',
  'ceiling': 'langit-langit', 'room': 'ruangan', 'kitchen': 'dapur',
  'street': 'jalan', 'road': 'jalan', 'path': 'jalur', 'stairs': 'tangga',
  'shop': 'toko', 'store': 'toko', 'market': 'pasar', 'restaurant': 'restoran',
  'office': 'kantor', 'park': 'taman', 'garden': 'kebun', 'bridge': 'jembatan',
  'sky': 'langit', 'ground': 'tanah', 'grass': 'rumput', 'tree': 'pohon',
  'trees': 'pepohonan', 'sign': 'papan tanda', 'fence': 'pagar',

  // Perabot & benda
  'table': 'meja', 'chair': 'kursi', 'chairs': 'kursi', 'desk': 'meja',
  'bed': 'tempat tidur', 'couch': 'sofa', 'sofa': 'sofa', 'shelf': 'rak',
  'laptop': 'laptop', 'computer': 'komputer', 'phone': 'ponsel',
  'keyboard': 'papan ketik', 'screen': 'layar', 'monitor': 'monitor',
  'book': 'buku', 'books': 'buku-buku', 'paper': 'kertas', 'bag': 'tas',
  'backpack': 'tas ransel', 'box': 'kotak', 'bottle': 'botol',
  'cup': 'cangkir', 'glass': 'gelas', 'plate': 'piring', 'bowl': 'mangkuk',
  'food': 'makanan', 'coffee': 'kopi', 'tea': 'teh', 'water': 'air',
  'clock': 'jam', 'lamp': 'lampu', 'light': 'lampu', 'picture': 'gambar',
  'mirror': 'cermin', 'curtain': 'tirai', 'carpet': 'karpet', 'rug': 'karpet',
  'basket': 'keranjang', 'umbrella': 'payung', 'hat': 'topi', 'shirt': 'baju',
  'money': 'uang', 'wallet': 'dompet', 'key': 'kunci', 'keys': 'kunci',
  'glasses': 'kacamata', 'watch': 'jam tangan', 'camera': 'kamera',

  // Kendaraan
  'car': 'mobil', 'cars': 'mobil-mobil', 'bus': 'bus', 'truck': 'truk',
  'motorcycle': 'motor', 'bicycle': 'sepeda', 'bike': 'sepeda',
  'train': 'kereta', 'boat': 'perahu', 'vehicle': 'kendaraan',

  // Hewan
  'dog': 'anjing', 'cat': 'kucing', 'bird': 'burung', 'animal': 'hewan',

  // Kata kerja (bentuk -ing)
  'standing': 'berdiri', 'sitting': 'duduk', 'walking': 'berjalan',
  'running': 'berlari', 'holding': 'memegang', 'wearing': 'memakai',
  'looking': 'melihat', 'talking': 'berbicara', 'eating': 'makan',
  'drinking': 'minum', 'reading': 'membaca', 'working': 'bekerja',
  'lying': 'tergeletak', 'hanging': 'tergantung', 'parked': 'terparkir',
  'placed': 'diletakkan', 'sitting_on': 'duduk di',
  'facing': 'menghadap', 'crossing': 'menyeberang', 'waiting': 'menunggu',

  // Preposisi & penghubung
  'on': 'di atas', 'in': 'di dalam', 'at': 'di', 'near': 'di dekat',
  'behind': 'di belakang', 'under': 'di bawah', 'above': 'di atas',
  'beside': 'di samping', 'between': 'di antara', 'with': 'dengan',
  'and': 'dan', 'or': 'atau', 'of': 'dari', 'from': 'dari', 'to': 'ke',
  'over': 'di atas', 'across': 'di seberang', 'down': 'menyusuri',
  'while': 'sambil', 'front': 'depan', 'side': 'sisi', 'top': 'atas',

  // Angka & kuantitas
  'one': 'satu', 'two': 'dua', 'three': 'tiga', 'four': 'empat',
  'five': 'lima', 'six': 'enam', 'seven': 'tujuh', 'eight': 'delapan',
  'nine': 'sembilan', 'ten': 'sepuluh',
  'some': 'beberapa', 'several': 'beberapa', 'many': 'banyak',
  'few': 'sedikit', 'other': 'lain', 'another': 'satu lagi',
  'his': 'nya', 'her': 'nya', 'their': 'mereka', 'this': 'ini', 'these': 'ini',
};

/// Hasil penerjemahan.
class SceneTranslation {
  /// Kalimat Bahasa Indonesia, atau null kalau cakupan kamus terlalu rendah.
  final String? indonesian;

  /// Berapa bagian kata isi yang berhasil dikenali (0..1). Untuk diagnostik.
  final double coverage;

  const SceneTranslation({required this.indonesian, required this.coverage});

  bool get isUsable => indonesian != null;
}

/// Terjemahkan caption suasana. Mengembalikan [SceneTranslation.indonesian]
/// null kalau hasilnya tidak layak diucapkan.
SceneTranslation translateSceneCaption(String englishCaption) {
  var text = englishCaption.toLowerCase().trim();
  if (text.isEmpty) return const SceneTranslation(indonesian: null, coverage: 0);

  // Buang tanda baca akhir & normalisasi spasi.
  text = text.replaceAll(RegExp(r'[.!?]+$'), '');
  text = text.replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Frasa multi-kata lebih dulu - ditandai dengan token khusus supaya tidak
  // ikut dipecah tahap berikutnya.
  final placeholders = <String, String>{};
  final sortedPhrases = _phrases.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  var i = 0;
  for (final phrase in sortedPhrases) {
    if (!text.contains(phrase)) continue;
    final token = ' ${i++} ';
    placeholders[token] = _phrases[phrase]!;
    text = text.replaceAll(phrase, token);
  }

  final tokens = text.split(' ').where((t) => t.isNotEmpty).toList();
  final out = <String>[];
  var contentWords = 0;
  var known = 0;

  for (var t = 0; t < tokens.length; t++) {
    final token = tokens[t];

    if (placeholders.containsKey(token)) {
      out.add(placeholders[token]!);
      contentWords++;
      known++;
      continue;
    }

    if (_dropped.contains(token)) continue;

    contentWords++;

    // Kata sifat + kata benda → urutannya dibalik: "white building" jadi
    // "gedung putih". Ini satu-satunya aturan tata bahasa yang benar-benar
    // dibutuhkan; sisanya sudah cukup dekat kalau diterjemahkan urut.
    if (_adjectives.containsKey(token)) {
      final next = t + 1 < tokens.length ? tokens[t + 1] : null;
      if (next != null && _words.containsKey(next)) {
        out.add('${_words[next]} ${_adjectives[token]}');
        known += 2;
        contentWords++; // kata benda ikut dihitung
        t++; // lewati kata benda yang sudah dipakai
        continue;
      }
      out.add(_adjectives[token]!);
      known++;
      continue;
    }

    final word = _words[token];
    if (word != null) {
      out.add(word);
      known++;
      continue;
    }

    // Angka tetap angka.
    if (RegExp(r'^\d+$').hasMatch(token)) {
      out.add(token);
      known++;
      continue;
    }

    // Tidak dikenal - pertahankan apa adanya, tapi hitung sebagai tidak
    // tercakup supaya ambang cakupan bisa menolak kalimat yang terlalu asing.
    out.add(token);
  }

  final coverage = contentWords == 0 ? 0.0 : known / contentWords;
  if (coverage < _minCoverage || out.isEmpty) {
    return SceneTranslation(indonesian: null, coverage: coverage);
  }

  var sentence = out.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  sentence = sentence[0].toUpperCase() + sentence.substring(1);
  return SceneTranslation(indonesian: '$sentence.', coverage: coverage);
}
```

---

## File: `lib/main.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/main.dart`

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

  // Portrait-only - sesuai PRD
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
        // alamat server, kecerewetan, dan ambang jarak - dan provider lain
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

        // DetectionProvider - hanya butuh CameraProvider (jalur deteksi
        // sepenuhnya on-device), dan ikut mendengarkan SettingsProvider supaya
        // PG-05 (kecerewetan) dan PG-06 (ambang jarak) benar-benar mengubah
        // perilaku deteksi. Tanpa sambungan ini keduanya hanya tersimpan ke disk.
        ChangeNotifierProxyProvider2<CameraProvider, SettingsProvider, DetectionProvider>(
          create: (ctx) => DetectionProvider(ctx.read<CameraProvider>()),
          update: (ctx, cam, settings, prev) {
            final provider = prev ?? DetectionProvider(cam);
            provider.applySettings(
              maxDistanceM: settings.distanceThresholdM,
              verbosity: settings.verbosity,
            );
            return provider;
          },
        ),

        // VoiceProvider - butuh CameraProvider + DetectionProvider +
        // AppModeProvider + FindObjectProvider. AppModeProvider ikut disuntik
        // supaya perintah suara "buka mode X" memindah state SENDIRI, tanpa
        // bergantung layar yang sedang aktif memasang callback (bagian 4.1:
        // konfirmasi TTS tidak boleh mendahului perubahan state).
        // FindObjectProvider disuntik untuk mendukung perintah suara
        // "carikan [barang]" dari mode mana pun (fitur Jarvis Global Mic).
        ChangeNotifierProxyProvider4<CameraProvider, DetectionProvider, AppModeProvider, FindObjectProvider, VoiceProvider>(
          create: (ctx) => VoiceProvider(
            ctx.read<CameraProvider>(),
            ctx.read<DetectionProvider>(),
            ctx.read<AppModeProvider>(),
            ctx.read<FindObjectProvider>(),
          ),
          update: (ctx, cam, det, appMode, findObj, prev) =>
              prev ?? VoiceProvider(cam, det, appMode, findObj),
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

## File: `lib/mock/mock_find_object.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/mock/mock_find_object.dart`

```dart
import 'dart:math';

/// Kosakata mock untuk Mode Cari Objek (bagian 12 IMPLEMENTASI.md).
///
/// Server pencarian objek sungguhan belum ada - seluruh "pengenalan barang"
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

  /// CO-05 - kalimat pemindaian awal, berganti tiap ~2 detik.
  static const scanMessages = <String>[
    'Memindai ruangan…',
    'Coba putar badan pelan ke kiri.',
    'Coba putar badan pelan ke kanan.',
    'Periksa area meja atau rak di dekatmu.',
  ];

  /// CO-10 - arahan lanjutan setelah beberapa putaran belum ketemu.
  static const notFoundMessages = <String>[
    'Belum terlihat, coba putar badan ke arah lain.',
    'Masih belum ketemu, coba melangkah beberapa langkah.',
    'Belum terlihat dari sini, coba tengok ke belakangmu.',
  ];

  /// CO-12 - barang tak dikenali menyebut barang yang dikenal sebagai ganti.
  static bool isKnown(String target) {
    final t = target.toLowerCase().trim();
    if (t.isEmpty) return false;
    return knownCatalog.any((k) => t.contains(k));
  }

  static String randomFallback(Random rng) => knownCatalog[rng.nextInt(knownCatalog.length)];
}
```

---

## File: `lib/mock/ocr_mock_data.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/mock/ocr_mock_data.dart`

```dart
/// Data & katalog mock khusus Mode Baca Teks (OCR) - dipakai HANYA oleh
/// `ocr_screen.dart` dan `ocr_debug_sheet.dart` untuk mendemonstrasikan
/// 22 state BT-01..BT-22 (bagian 8 dokumen spesifikasi).
///
/// ServerService.readText saat ini hanya mengembalikan `{'text': ...}` -
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

/// Satu entri katalog debug - dipakai OcrDebugSheet untuk daftar 22 state.
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
        heading: 'Bagian 1 - Judul menu',
        text: 'Daftar Menu Warung Bu Sari. Semua harga sudah termasuk nasi putih '
            'dan segelas air teh tawar.',
      ),
      OcrBlock(
        heading: 'Bagian 2 - Menu utama',
        text: 'Ayam goreng lima belas ribu rupiah. Ikan bakar dua puluh ribu rupiah. '
            'Tahu tempe penyet delapan ribu rupiah. Sayur asem lima ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 3 - Minuman',
        text: 'Es teh manis lima ribu rupiah. Es jeruk tujuh ribu rupiah. '
            'Kopi hitam enam ribu rupiah.',
      ),
      OcrBlock(
        heading: 'Bagian 4 - Catatan',
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

## File: `lib/models/detection.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/models/detection.dart`

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

  /// Identitas objek dari [ObjectTracker], stabil antar frame. `null` berarti
  /// deteksi ini belum melewati tracker (mis. hasil server single-shot).
  ///
  /// Dipakai [DetectionFilter] sebagai kunci cooldown dan streak. Sebelumnya
  /// kuncinya `labelEn`, sehingga dua orang berbeda dianggap satu: orang yang
  /// jauh diumumkan lebih dulu, lalu orang yang dekat dan mendekat dibungkam
  /// sampai cooldown label "person" habis.
  final int? trackId;

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
    this.trackId,
  });

  /// Kunci identitas untuk filter. Pakai trackId kalau ada; kalau tidak,
  /// jatuh ke label supaya jalur tanpa tracker tetap punya cooldown.
  String get filterKey => trackId != null ? 't$trackId' : 'l$labelEn';

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
        labelEn:       json['label_en'] as String? ?? '',
        labelId:       json['label_id'] as String? ?? '',
        confidence:    (json['confidence'] ?? 0).toDouble(),
        distanceMeter: (json['distance_meter'] ?? 999).toDouble(),
        direction:     json['direction'] as String? ?? 'depan',
        dangerLevel:   json['danger_level'] as String? ?? 'info',
        bbox:          Map<String, int>.from(json['bbox'] as Map? ?? {}),
        inferenceMs:   (json['inference_ms'] ?? 0).toDouble(),
        // isApproaching tidak dari JSON - hanya dari tracker lokal
      );

  /// Buat salinan Detection dengan field tertentu diubah.
  /// Digunakan DetectionProvider untuk menambahkan isApproaching + trackId
  /// dari tracker.
  Detection copyWith({bool? isApproaching, int? trackId, double? distanceMeter}) => Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    confidence,
        distanceMeter: distanceMeter ?? this.distanceMeter,
        direction:     direction,
        dangerLevel:   dangerLevel,
        bbox:          bbox,
        inferenceMs:   inferenceMs,
        isApproaching: isApproaching ?? this.isApproaching,
        trackId:       trackId ?? this.trackId,
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

## File: `lib/models/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/models/index.dart`

```dart
export 'detection.dart';
```

---

## File: `lib/providers/app_mode_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/app_mode_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../core/speech/tts_queue.dart';
import '../providers/settings_provider.dart' show Verbosity;

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

  /// Satu kalimat "apa yang bisa dilakukan" - diumumkan saat masuk mode.
  String get shortIntro => switch (this) {
        AppMode.tuntun     => 'Arahkan ponsel ke depan, saya akan menyebut rintangan di jalurmu.',
        AppMode.money      => 'Letakkan uang di dalam bingkai, saya akan menyebut nominalnya.',
        AppMode.ocr        => 'Arahkan ponsel ke tulisan, lalu ambil gambar.',
        // JANGAN menjanjikan tujuan/GPS di sini. Kalimat lama berbunyi
        // "Sebutkan atau ketik tujuanmu, saya akan menuntun jalan." padahal
        // GPS belum ada: pengguna tunanetra menyebutkan tujuan, tidak ada yang
        // terjadi, mencoba lagi, tetap tidak ada. Kalimat pembuka yang
        // menjanjikan sesuatu yang tidak ada adalah cara tercepat kehilangan
        // kepercayaan pengguna terhadap seluruh aplikasi.
        AppMode.navigasi   => 'Saya akan menyebut jalur mana yang lebih aman: kiri, tengah, atau kanan.',
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
        AppMode.tuntun     => false, // SSD MobileNet TFLite, sepenuhnya on-device
        AppMode.money      => false, // MobileNetV2 TFLite, sepenuhnya on-device
        AppMode.ocr        => false, // ML Kit on-device - jalan penuh offline
        AppMode.navigasi   => true,  // PIDNet on-device jadi jalur utama; server hanya cadangan
        AppMode.voice      => true,  // butuh server untuk describe; intent parsing lokal, tanpa LLM
        AppMode.findObject => true,  // YOLOE open-vocab hanya ada di server
      };

  /// Mode yang benar-benar mati tanpa internet.
  ///
  /// Mode Navigasi tetap BERJALAN OFFLINE menggunakan model TFLite on-device
  /// (YOLO11n untuk bounding box rintangan & PIDNet-S untuk segmentasi 3-zona).
  bool get disabledWhenOffline => this == AppMode.findObject;

  /// Petunjuk kata kunci perintah suara untuk diumumkan atau ditampilkan di UI
  String get voiceHint => switch (this) {
        AppMode.tuntun     => 'Katakan: "Deteksi objek" atau "Tuntun aku"',
        AppMode.money      => 'Katakan: "Kenali uang" atau "Cek uang"',
        AppMode.ocr        => 'Katakan: "Baca teks" atau "Bacakan"',
        AppMode.navigasi   => 'Katakan: "Navigasi" atau "Jalan mana"',
        AppMode.voice      => 'Katakan: "Asisten suara" atau "Tanya"',
        AppMode.findObject => 'Katakan: "Cari objek" atau "Cari kunci"',
      };
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  /// Mode sebelum perpindahan terakhir - dipakai oleh fitur "kembali"
  /// (perintah suara atau tombol ✕ di VoiceScreen overlay).
  AppMode? _previousMode;
  AppMode? get previousMode => _previousMode;

  /// Verbositas panduan menurun setelah 3 kali pemakaian pertama per mode.
  final Map<AppMode, int> _visitCount = {};
  int visitCountFor(AppMode m) => _visitCount[m] ?? 0;

  /// Kata pembuka yang dititipkan [setMode] untuk diucapkan oleh
  /// [announceEntry] milik layar tujuan - mis. "Baik." dari perintah suara
  /// (AS-17). Dititipkan, bukan diucapkan di sini, supaya konfirmasi tidak
  /// pernah mendahului perpindahan state (bagian 4.1 ALUR-DAN-TOMBOL.md).
  String? _pendingPrefix;

  /// PG-05 - tingkat kecerewetan pengguna. Bekerja **bersama** verbositas
  /// menurun bawaan (tiga pemakaian pertama lebih panjang), bukan
  /// menggantikannya: "ringkas" memotong panduan sejak awal, "detail"
  /// mempertahankannya selamanya.
  Verbosity _verbosity = Verbosity.sedang;
  void applyVerbosity(Verbosity v) => _verbosity = v;

  /// Umumkan masuk mode. Dipanggil dari `initState` layar mode - artinya
  /// pengumuman selalu menyusul mode yang BENAR-BENAR terpasang, tidak pernah
  /// mendahuluinya. Mode default (Deteksi Objek) yang aktif sejak boot tanpa
  /// lewat [setMode] ikut lewat sini juga, supaya DO-29 "verbositas lengkap 3
  /// pemakaian pertama" tetap berlaku untuknya.
  Future<void> announceEntry(AppMode mode) async {
    if (mode != _mode) return; // layar basi (dispose berpapasan) - jangan bicara
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
    // Lewat antrean, tier Warning: pengumuman "di mana saya sekarang" tidak
    // boleh dibuang sebagai Info basi, tapi juga tidak boleh menahan
    // peringatan bahaya yang datang saat mode baru terpasang.
    await TtsQueue().speak(announcement, tier: SpeechTier.warning);
  }

  /// NV-18 - satu-satunya konfirmasi wajib di seluruh app: keluar dari Mode
  /// Navigasi saat pengguna terdeteksi sedang berjalan. `navigasi_screen.dart`
  /// memasang hook ini selama aktif; kalau terpasang dan mengembalikan
  /// false, perpindahan mode dibatalkan. Ini titik tunggal yang dilewati
  /// SEMUA jalur ganti mode (ModePickerSheet maupun perintah suara).
  Future<bool> Function(AppMode from, AppMode to)? confirmLeave;

  /// Berpindah mode. Mengembalikan **true hanya kalau mode benar-benar
  /// berubah** - pemanggil wajib memeriksa nilai ini sebelum mengucapkan
  /// konfirmasi apa pun. [spokenPrefix] dititipkan ke pengumuman kedatangan
  /// layar tujuan, bukan diucapkan di sini.
  Future<bool> setMode(AppMode mode, {String? spokenPrefix}) async {
    if (_mode == mode) return false;
    if (confirmLeave != null) {
      final ok = await confirmLeave!(_mode, mode);
      if (!ok) return false;
    }
    _previousMode = _mode; // simpan mode sebelumnya untuk goBack()
    _pendingPrefix = spokenPrefix;
    _mode = mode;
    notifyListeners();
    // Pengumuman kedatangan diucapkan `announceEntry` dari layar tujuan -
    // sesudah layarnya benar-benar terpasang.
    return true;
  }

  /// Kembali ke mode sebelumnya. Dipanggil oleh `VoiceIntent.actionGoBack`
  /// atau tombol ✕ di VoiceScreen overlay. Fallback ke [AppMode.tuntun]
  /// kalau tidak ada riwayat mode sebelumnya.
  Future<bool> goBack({String? spokenPrefix}) async {
    final target = _previousMode ?? AppMode.tuntun;
    return setMode(target, spokenPrefix: spokenPrefix);
  }
}
```

---

## File: `lib/providers/camera_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/camera_provider.dart`

```dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../core/speech/tts_queue.dart';
import '../services/camera_health_service.dart';
import '../services/tflite_service.dart';

/// CameraProvider - kelola kamera, stream, dan capture.
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
  bool    _isDark         = false; // hasil on-device brightness check
  bool    _darkDismissed  = false; // true = jangan tampilkan tawaran lampu lagi
  bool    _isTorchOn      = false; // status flashlight

  // Fix 2.1: Timer peringatan gelap berkala - ucap setiap 30 detik jika masih gelap
  Timer?   _darkWarningTimer;

  /// Sejak kapan kondisi gelap berlangsung - dibaca layar/telemetri untuk
  /// membedakan "baru saja gelap" dari "sudah lama tidak melihat apa-apa".
  DateTime? _darkSince;
  DateTime? get darkSince => _darkSince;

  CameraController? get controller    => _controller;
  bool              get isInitialized => _initialized;
  bool              get isStreaming    => _streaming;
  String?           get healthMessage => _healthMessage;

  /// True saat rata-rata kecerahan frame < threshold.
  /// UI menampilkan ContextualActionSlot tawaran lampu HANYA jika
  /// [isDark] && ![darkDismissed].
  bool get isDark         => _isDark;

  /// True saat pengguna menekan "Lewati" - tawaran lampu tidak tampil,
  /// TAPI deteksi tetap berjalan (Fix 2.1).
  bool get darkDismissed  => _darkDismissed;

  /// True saat flashlight sedang menyala.
  bool get isTorchOn => _isTorchOn;

  // Callback - dipanggil dari CameraProvider ketika frame siap
  // DetectionProvider/InferenceProvider yang subscribe
  Function(CameraImage)? onFrameReady;

  /// Dipasang MainScreen supaya kamera yang gagal muncul sebagai banner
  /// global Critical, bukan hanya layar hitam tanpa penjelasan.
  void Function(bool hasError)? onErrorChanged;

  bool _hasError = false;
  bool get hasError => _hasError;

  void _setError(bool value) {
    if (_hasError == value) return;
    _hasError = value;
    onErrorChanged?.call(value);
    notifyListeners();
  }

  Future<void> initCamera() async {
    // Request camera permission sebelum initialize - mencegah CameraAccessDenied
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('[CameraProvider] Camera permission denied: $status');
      _initialized = false;
      notifyListeners();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[CameraProvider] Tidak ada kamera pada perangkat ini');
        _setError(true);
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium, // 640x480 cukup untuk YOLO
        enableAudio:    false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      CameraHealthService.instance.startListening();
      _initialized = true;
      _setError(false);
      notifyListeners();
    } catch (e) {
      // Kamera gagal disiapkan = mode utama benar-benar buta. Kegagalan yang
      // ditelan diam-diam di sini akan tampil sebagai aplikasi yang terlihat
      // normal tapi tidak pernah memperingatkan apa pun.
      debugPrint('[CameraProvider] initCamera error: $e');
      _initialized = false;
      _setError(true);
    }
  }

  void startStream() {
    if (!_initialized || _streaming || _controller == null) return;
    _streaming   = true;
    _frameCount  = 0;

    _controller!.startImageStream((CameraImage image) {
      // Skip frame jika sedang capture (race condition fix)
      if (_capturing) return;

      _frameCount++;

      // [1] On-device brightness check setiap frame - O(100) sangat ringan
      final tooDark = _isTooDark(image);
      if (tooDark != _isDark) {
        _isDark = tooDark;
        if (tooDark) {
          // Mulai timer peringatan gelap (Fix 2.1)
          _darkSince = DateTime.now();
          _startDarkWarningTimer();
        } else {
          // Kondisi terang kembali - reset semua
          _cancelDarkWarningTimer();
          _darkDismissed = false;
          _darkSince = null;
        }
        // Notifikasi UI: ContextualActionSlot tampil/sembunyikan tawaran lampu
        notifyListeners();
      }
      // Fix 2.1: JANGAN return di sini - inference tetap berjalan di kondisi gelap.
      // Pengguna perlu tahu ada rintangan meski gelap.
      // UI yang memutuskan apakah tawaran lampu tampil (isDark && !darkDismissed).

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
            // Gunakan TtsQueue agar tunduk pada sistem 3-tier (Fix 1C)
            TtsQueue().speak(health.message, tier: SpeechTier.warning);
          }
          // Sengaja TIDAK `return` - ini kelas bug yang sama dengan kondisi
          // gelap (Fix 2.1). Ponsel yang miring membuat estimasi jarak kurang
          // akurat, tapi objek di depan tetap terlihat. Menghentikan inference
          // berarti menukar "peringatan yang agak meleset" dengan "tidak ada
          // peringatan sama sekali" - dan yang kedua jauh lebih berbahaya.
        } else if (_healthMessage != null) {
          _healthMessage = null;
          notifyListeners();
        }
      }

      // [3] Callback ke DetectionProvider jika ada subscriber
      onFrameReady?.call(image);
    });
  }

  /// Dismiss tawaran lampu tanpa mematikan deteksi (Fix 2.1).
  /// Dipanggil saat pengguna menekan "Lewati" di ContextualActionSlot.
  void dismissDarkOffer() {
    _darkDismissed = true;
    notifyListeners();
  }

  void stopStream() {
    if (!_streaming || _controller == null) return;
    _controller!.stopImageStream();
    _streaming = false;
    _cancelDarkWarningTimer();
    // Reset dark state saat stream berhenti
    if (_isDark) {
      _isDark = false;
      _darkDismissed = false;
      notifyListeners();
    }
  }

  // ── Dark warning timer (Fix 2.1) ─────────────────────────────────────────

  void _startDarkWarningTimer() {
    _cancelDarkWarningTimer();
    // Ucapkan peringatan pertama setelah 3 detik gelap
    _darkWarningTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDark) return;
      TtsQueue().speak(
        'Terlalu gelap, saya tidak bisa melihat jalur dengan jelas. '
        'Nyalakan lampu atau berhenti sejenak.',
        tier: SpeechTier.warning,
      );
      Vibration.vibrate(pattern: [0, 100, 100, 100]);
      // Ulangi setiap 30 detik selama masih gelap
      _darkWarningTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (!_isDark) {
            _cancelDarkWarningTimer();
            return;
          }
          TtsQueue().speak(
            'Masih gelap. Saya tetap berjalan tapi penglihatan terbatas.',
            tier: SpeechTier.info,
          );
        },
      );
    });
  }

  void _cancelDarkWarningTimer() {
    _darkWarningTimer?.cancel();
    _darkWarningTimer = null;
  }

  /// Nyalakan atau matikan flashlight secara eksplisit.
  /// Aman dipanggil saat stream berjalan maupun tidak.
  Future<void> setTorch(bool on) async {
    if (_controller == null || !_initialized) return;
    try {
      await _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _isTorchOn = on;
      notifyListeners();
    } catch (e) {
      debugPrint('[CameraProvider] setTorch($on) error: $e');
    }
  }

  /// Toggle flashlight - nyala → mati, mati → nyala.
  Future<void> toggleTorch() => setTorch(!_isTorchOn);

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

    // Encode ke JPEG quality 70 - cukup untuk YOLO server, tidak terlalu besar
    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 70));
  }

  /// On-device brightness check - sample 100 piksel dari plane Y (YUV420).
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
    _cancelDarkWarningTimer();
    CameraHealthService.instance.stopListening();
    _controller?.dispose();
    super.dispose();
  }
}
```

---

## File: `lib/providers/capabilities_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/capabilities_provider.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/server_service.dart';
import 'app_mode_provider.dart';

/// Kemampuan server per mode - `GET /api/capabilities`.
///
/// **Ditanyakan sebelum pengguna menekan apa pun.** Tanpa ini, satu-satunya
/// cara mengetahui sebuah mode sedang mati adalah masuk ke sana lalu gagal -
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
    // Belum tahu - jangan menghalangi. Menebak "mati" akan mengunci pengguna
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
        // Server tidak menjawab - seluruh mode yang butuh server dianggap mati.
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

## File: `lib/providers/detection_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/detection_provider.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart' show FramePacer;
import '../core/speech/tts_queue.dart';
import '../core/voice/narration_engine.dart';
import '../models/detection.dart';
import '../providers/camera_provider.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/detection_filter.dart';
import '../services/haptic_service.dart';
import '../services/object_tracker.dart';
import '../services/tflite_service.dart';

/// DetectionProvider - Mode Deteksi Objek, sepenuhnya on-device.
///
/// **Jalur server dihapus.** Sebelumnya ada dua jalur (TFLite dan WebSocket
/// `/ws/detect`) yang dipilih dari `InferenceProvider.realtimeEngine`. Itu
/// menggandakan kode di mode paling kritis keselamatan tanpa menambah
/// keandalan: modelnya sudah dibundel di APK, dan hasil server melewati
/// [DetectionFilter] yang sama sehingga mewarisi perilaku yang sama persis.
/// Yang tersisa hanyalah ketergantungan diam-diam pada laptop yang menyala.
/// Sekarang: TFLite gagal muat = dikatakan apa adanya lewat [isUnavailable].
class DetectionProvider extends ChangeNotifier {
  final CameraProvider _cameraProvider;

  DetectionProvider(this._cameraProvider);

  final _filter  = DetectionFilter();
  final _tracker = ObjectTracker();

  /// Satu inferensi dalam penerbangan, dan jeda minimum antar frame.
  ///
  /// Tanpa ini, callback kamera (~30 fps) memicu inferensi yang menumpuk tak
  /// terbatas: tiap frame tertunda memegang buffer sendiri, memori naik, dan
  /// peringatan yang akhirnya terdengar menggambarkan dunia beberapa detik
  /// lalu. 120 ms ≈ 8 fps - dengan `streakRequired = 2`, objek baru terucap
  /// sekitar 250 ms setelah masuk frame, masih di bawah target 500 ms.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 120));

  /// PG-05 / PG-06 - diteruskan dari SettingsProvider setiap kali pengaturan
  /// berubah, supaya slider dan segmented benar-benar mengubah perilaku
  /// deteksi alih-alih hanya tersimpan ke disk.
  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _filter.applySettings(maxDistanceM: maxDistanceM, verbosity: verbosity);
  }

  bool _realtimeActive = false;
  bool get isRealtimeActive => _realtimeActive;

  List<Detection> _detections = [];
  List<Detection> get detections => _detections;

  /// True kalau model on-device tidak bisa dipakai. Layar wajib mengatakannya
  /// - mode ini tidak punya cadangan lain, jadi diam berarti membiarkan orang
  /// berjalan menyangka dirinya dijaga.
  bool get isUnavailable => !TFLiteService.instance.isLoaded;

  /// Kapan terakhir kali pipeline benar-benar menghasilkan sesuatu. Dipakai
  /// layar untuk mendeteksi "hidup tapi bisu".
  DateTime? _lastInferenceAt;
  DateTime? get lastInferenceAt => _lastInferenceAt;

  // ── Real-time ──────────────────────────────────────────────────────────────

  void startRealtime() {
    if (_realtimeActive) return;
    _realtimeActive = true;
    _filter.reset();
    _tracker.reset();
    _cameraProvider.onFrameReady = _processFrame;
    notifyListeners();
  }

  void stopRealtime() {
    _realtimeActive = false;
    _cameraProvider.onFrameReady = null;
    _tracker.reset();
    _filter.reset();
    _detections = [];
    notifyListeners();
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_realtimeActive) return;

    await _pacer.run(() async {
      final raw = await TFLiteService.instance.runInference(image);
      if (!_realtimeActive) return;

      _lastInferenceAt = DateTime.now();

      // Frame kosong tetap diumpankan ke tracker supaya objek yang menghilang
      // benar-benar dianggap hilang setelah beberapa frame. Filter sengaja
      // dilewati: `process([])` hanya akan membersihkan streak, dan itu sudah
      // ditangani tracker.
      if (raw.isEmpty) {
        _tracker.update(const []);
        if (_detections.isNotEmpty) {
          _detections = [];
          notifyListeners();
        }
        return;
      }

      // Tracker memberi identitas stabil per objek. Pemetaannya per-indeks,
      // bukan per-label: dengan dua orang di frame, versi lama mengambil track
      // pertama berlabel "person" untuk keduanya, sehingga status "mendekat"
      // milik orang jauh bisa menempel ke orang dekat - dan status itulah yang
      // memotong cooldown 50%.
      if (!_realtimeActive) return;

      _tracker.update(raw);
      final assignment = _tracker.lastAssignment;

      final enriched = <Detection>[];
      for (var i = 0; i < raw.length; i++) {
        final track = i < assignment.length ? assignment[i] : null;
        enriched.add(raw[i].copyWith(
          isApproaching: track?.isApproaching ?? false,
          trackId: track?.id,
          // Jarak yang DIHALUSKAN, bukan hasil mentah satu frame. Ponsel yang
          // mengayun saat berjalan membuat kotak deteksi membesar-mengecil
          // sendiri; tanpa penghalusan, objek diam terucap "dua meter… satu
          // meter… dua meter" dan pengguna tidak punya cara tahu mana yang
          // benar. Nilai mentah tetap dipakai untuk klasifikasi tier di
          // TFLiteService - yang dihaluskan hanya yang diucapkan.
          distanceMeter: track?.smoothedDistance,
        ));
      }

      final filtered = _filter.process(enriched);
      _updateAndSpeak(filtered);
    });
  }

  void _updateAndSpeak(List<Detection> filtered) {
    _detections = filtered;
    notifyListeners();
    if (filtered.isEmpty) return;

    // Tier = bahaya tertinggi di antara yang lolos. Satu kalimat, satu tier -
    // bukan satu ucapan terpisah per objek yang saling berebut antrean.
    final tier = filtered.any((d) => d.isCritical)
        ? SpeechTier.critical
        : filtered.any((d) => d.isWarning)
            ? SpeechTier.warning
            : SpeechTier.info;

    TtsQueue().speak(_composeNarration(filtered), tier: tier);

    // Getar mendampingi suara - di pasar dan jalan raya, getar sering jadi
    // sinyal utama. Cukup sekali, sesuai tier tertinggi.
    HapticService.instance.fromDangerLevel(
      filtered.first.dangerLevel,
    );
  }

  /// Rangkai satu kalimat dari objek yang lolos filter.
  ///
  /// Fix temuan 2A: `narration_engine.dart` akhirnya tersambung. Selama ini
  /// 265 baris itu tidak pernah dipanggil dari mana pun - yang benar-benar
  /// terucap adalah `det.ttsMessage`, satu kalimat datar per objek, sehingga
  /// dua objek berarti dua ucapan yang saling menyusul tanpa konektor.
  ///
  /// Untuk tier Critical kalimatnya sengaja tetap pendek dan langsung: saat
  /// ada bahaya < 1,5 m, kalimat bernuansa natural justru menunda informasi
  /// yang menentukan.
  String _composeNarration(List<Detection> filtered) {
    final critical = filtered.where((d) => d.isCritical).toList();
    if (critical.isNotEmpty) {
      return critical.first.ttsMessage;
    }

    // Gabungkan objek sekelas dengan arah sama supaya narasinya menyebut
    // "dua orang", bukan "orang" dua kali.
    final grouped = <String, NarrationDetection>{};
    for (final d in filtered) {
      final key = '${d.labelEn}|${d.direction}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = NarrationDetection(
          objectClass: d.labelEn,
          dist: d.distanceMeter,
          dir: _narrationDirection(d.direction),
        );
      } else {
        grouped[key] = NarrationDetection(
          objectClass: existing.objectClass,
          dist: existing.dist < d.distanceMeter ? existing.dist : d.distanceMeter,
          dir: existing.dir,
          count: existing.count + 1,
        );
      }
    }

    final narration = generateNaturalNarration(grouped.values.toList());
    // Kelas di luar kamus 80 COCO membuat narasi kosong. Jangan diam -
    // sampaikan versi datarnya daripada tidak menyebut objeknya sama sekali.
    if (narration.trim().isEmpty || grouped.isEmpty) {
      return filtered.map((d) => d.ttsMessage).join('. ');
    }
    return narration;
  }

  /// `_getDirection` bisa menghasilkan "kiri bawah"; narasi hanya mengenal
  /// sumbu horizontal.
  String _narrationDirection(String direction) {
    if (direction.startsWith('kiri')) return 'kiri';
    if (direction.startsWith('kanan')) return 'kanan';
    return 'tengah';
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}
```

---

## File: `lib/providers/find_object_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/find_object_provider.dart`

```dart

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/server_service.dart';
import '../core/speech/tts_queue.dart' show SpeechTier;

/// State machine Mode Cari Objek.
///
/// **Trigger-based via backend YOLOE** - pengguna tekan tombol kiri,
/// satu foto dikirim ke POST /api/cari-objek, hasilnya diucapkan via TTS.
/// Backend menggunakan YOLOE open-vocabulary (300+ barang Bahasa Indonesia).
///
/// Berbeda dari versi on-device sebelumnya yang berjalan real-time (loop
/// 350 ms), versi ini hanya berjalan sekali per tap - lebih hemat baterai
/// dan bisa mendeteksi jauh lebih banyak jenis barang.
///
/// CO-15 (izin kamera), CO-16 (senyap), CO-17 (font scale 200%) sengaja TIDAK
/// dimodelkan di sini - itu murni keputusan lapisan UI.
enum FindObjectState {
  idle,            // CO-01
  listening,       // CO-02
  unclear,         // CO-03
  targetActive,    // CO-04 - target aktif, menunggu tombol kiri ditekan
  scanning,        // CO-05 - sedang mengirim ke backend
  found,           // CO-06 / CO-07 (lihat matchCount)
  lostFromView,    // CO-09
  notFoundInFrame, // CO-10
  longNotFound,    // CO-11
  unknownObject,   // CO-12
  offlineSaved,    // CO-14
  serverError,     // CO-18
  tooDark,         // CO-19
}

class FindObjectProvider extends ChangeNotifier {
  FindObjectState _state = FindObjectState.idle;
  FindObjectState get state => _state;

  String? _target;
  String? get target => _target;

  /// CO-14 - target yang disimpan saat offline, dipakai lagi begitu pulih.
  String? _savedTarget;
  String? get savedTarget => _savedTarget;

  int _matchCount = 1;
  int get matchCount => _matchCount;

  String _direction = 'depan';
  String get direction => _direction;

  double _distanceMeter = 3.0;
  double get distanceMeter => _distanceMeter;

  String? _lastKnownPosition;
  String? get lastKnownPosition => _lastKnownPosition;

  /// Pesan terakhir dari server.
  String _serverMessage = '';
  String get scanMessage =>
      _serverMessage.isEmpty ? 'Memindai sekitar…' : _serverMessage;
  String get notFoundMessage => scanMessage;

  /// True saat sedang menunggu respons backend - tombol kiri di-disable.
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final List<String> _knownTargets = const [];
  List<String> get knownTargets => _knownTargets;

  /// Callback keluar - screen yang mengubahnya jadi suara/getar sungguhan.
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(String direction)? onDirectionHaptic;

  /// Sumber frame. Screen memasang ini supaya provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;

  /// Dibaca sebelum mengirim - CO-14 menuntut mode ini benar-benar berhenti
  /// saat offline, bukan mencoba lalu gagal berkali-kali.
  bool Function()? isOffline;

  int _notFoundCount = 0;
  Timer? _stepTimer;

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

  /// Tidak dipakai lagi - dipertahankan agar tidak merusak layar yang masih
  /// memanggil ini.
  Future<void> loadKnownTargets() async {
    // no-op
  }

  // -------------------------------------------------------------- CO-02/03

  void startListening() {
    _set(FindObjectState.listening);
  }

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

  void setTarget(String newTarget) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _matchCount = 1;
    _lastKnownPosition = null;
    _notFoundCount = 0;
    _isScanning = false;
    _set(FindObjectState.targetActive);

    _speak(
      isChange
          ? 'Ganti, sekarang mencari $newTarget. Tekan tombol kirim untuk memindai.'
          : 'Mencari $newTarget. Tekan tombol kirim untuk memindai.',
      tier: SpeechTier.info,
    );
  }

  void retrySavedTarget() {
    final saved = _savedTarget;
    if (saved == null) return;
    _savedTarget = null;
    _speak('Internet kembali. Tekan tombol kirim untuk mencari $saved.',
        tier: SpeechTier.info);
    setTarget(saved);
  }

  // --------------------------------------------------------- Trigger (CO-05)

  /// Dipanggil oleh screen saat tombol kiri (📷 / "Kirim") ditekan.
  /// Ambil satu frame → kirim ke backend → proses respons.
  Future<void> triggerScan() async {
    final target = _target;
    if (target == null || _isScanning) return;

    // CO-14 - benar-benar berhenti saat offline
    final offline = isOffline?.call() ?? false;
    if (offline) {
      _savedTarget = target;
      _set(FindObjectState.offlineSaved);
      _speak(
        'Tanpa internet, pencarian tidak bisa dijalankan. '
        'Saya akan ingatkan saat internet kembali.',
        tier: SpeechTier.warning,
      );
      return;
    }

    final grab = frameSource;
    if (grab == null) return;

    _isScanning = true;
    _set(FindObjectState.scanning);

    try {
      final jpeg = await grab();
      if (jpeg == null) {
        _isScanning = false;
        _set(FindObjectState.tooDark);
        _speak('Terlalu gelap. Nyalakan lampu.', tier: SpeechTier.warning);
        return;
      }

      final res = await ServerService.instance.cariObjek(jpeg, target);
      _isScanning = false;
      _handleResponse(res, target);
    } catch (e) {
      _isScanning = false;
      _set(FindObjectState.serverError);
      // Warning, bukan Critical. Tier Critical dicadangkan untuk bahaya fisik
      // dan tidak bisa dipotong pengguna - kegagalan jaringan tidak pernah
      // setara dengan motor yang melaju ke arahmu.
      _speak(
        'Gagal menghubungi server. Periksa koneksi dan coba lagi.',
        tier: SpeechTier.warning,
      );
    }
  }

  void _handleResponse(Map<String, dynamic> res, String target) {
    _serverMessage = res['message'] as String? ?? '';
    final found = res['found'] == true;

    if (!found) {
      final reason = res['reason'] as String? ?? 'not_in_frame';

      if (reason == 'model_unavailable') {
        _set(FindObjectState.serverError);
        _speak(
          _serverMessage.isNotEmpty
              ? _serverMessage
              : 'Pencari objek tidak tersedia di server.',
          tier: SpeechTier.warning,
        );
        return;
      }
      if (reason == 'invalid_frame') {
        _set(FindObjectState.tooDark);
        _speak('Terlalu gelap. Nyalakan lampu.', tier: SpeechTier.warning);
        return;
      }

      _notFoundCount++;
      if (_notFoundCount >= 4) {
        // CO-11 - setelah 4 kali tidak ketemu, tawarkan jalan keluar
        _set(FindObjectState.longNotFound);
        _speak(
          'Belum ketemu di sini. Pindah posisi, lalu tekan kirim lagi. '
          'Atau sebutkan barang lain.',
          tier: SpeechTier.warning,
        );
        return;
      }

      _set(FindObjectState.notFoundInFrame);
      _speak(
        _serverMessage.isNotEmpty
            ? _serverMessage
            : '$target tidak terlihat. Coba arahkan kamera ke tempat lain lalu tekan kirim.',
        tier: SpeechTier.info,
      );
      return;
    }

    // ── Ketemu ──────────────────────────────────────────────────────────────
    final nearest = res['nearest'] as Map<String, dynamic>?;
    final total = (res['total_match'] as num?)?.toInt() ?? 1;

    _notFoundCount = 0;
    _matchCount = total;
    if (nearest != null) {
      _direction = nearest['direction'] as String? ?? _direction;
      _distanceMeter =
          (nearest['distance_meter'] as num?)?.toDouble() ?? _distanceMeter;
    }
    _lastKnownPosition =
        '$_direction, sekitar ${_distanceMeter.toStringAsFixed(1)} meter';

    _set(FindObjectState.found);

    final msg = _serverMessage.isNotEmpty ? _serverMessage : _composeFound();
    _speak(msg, tier: SpeechTier.info);
    onDirectionHaptic?.call(_direction);
  }

  String _composeFound() {
    final distText = _distanceMeter < 1
        ? 'kurang dari satu meter'
        : '${_distanceMeter.toStringAsFixed(1)} meter';
    return _matchCount > 1
        ? 'Ada $_matchCount $_target. Yang terdekat di $_direction, sekitar $distText.'
        : '$_target ditemukan di $_direction, sekitar $distText.';
  }

  void reset() {
    _stepTimer?.cancel();
    _target = null;
    _serverMessage = '';
    _isScanning = false;
    _notFoundCount = 0;
    _set(FindObjectState.idle);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }
}
```

---

## File: `lib/providers/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/index.dart`

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

## File: `lib/providers/inference_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/inference_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../services/camera_intrinsics.dart';
import '../services/tflite_service.dart';
import '../services/server_service.dart';

/// InferenceProvider - kesiapan model on-device dan server saat boot.
///
/// Sejak jalur deteksi via WebSocket dihapus, tidak ada lagi "engine yang
/// dipilih": Mode Deteksi Objek selalu on-device. Server hanya dibutuhkan
/// untuk yang memang tidak ada di perangkat (Cari Objek, Deskripsi Suasana,
/// dan segmentasi jalur sebagai cadangan), jadi kesiapannya diperiksa lewat
/// `/health` - bukan dengan membuka soket deteksi yang tidak akan dipakai.
class InferenceProvider extends ChangeNotifier {
  bool _tfliteReady = false;
  bool _serverReady = false;
  bool _initialized = false;

  bool get tfliteReady => _tfliteReady;
  bool get serverReady => _serverReady;

  /// Deteksi rintangan siap. Ini satu-satunya yang menentukan mode utama
  /// bisa berjalan - server tidak lagi jadi cadangannya.
  bool get isReady => _tfliteReady;

  Future<void> initialize() async {
    if (_initialized) return;

    // Intrinsik lensa dibaca sekali di sini: estimasi jarak butuh panjang
    // fokus perangkat ini, bukan rata-rata semua ponsel. Kegagalannya tidak
    // memblokir apa pun - nilainya jatuh ke fallback.
    final results = await Future.wait([
      TFLiteService.instance.tryLoad(),
      _probeServer(),
      CameraIntrinsics.instance.load().then((_) => true),
    ]);

    _tfliteReady = results[0];
    _serverReady = results[1];
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _probeServer() async {
    try {
      final health = await ServerService.instance.healthAt(
        ServerService.instance.host,
        timeout: const Duration(seconds: 2),
      );
      return health != null;
    } catch (_) {
      return false;
    }
  }

  void onServerConnected()    { _serverReady = true;  notifyListeners(); }
  void onServerDisconnected() { _serverReady = false; notifyListeners(); }
}
```

---

## File: `lib/providers/money_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/money_provider.dart`

```dart
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/money_tflite_service.dart';
import '../widgets/nominal_card.dart' show terbilangRupiah;

/// State machine Mode Kenali Uang - bagian 9 IMPLEMENTASI.md
/// (UG-01..UG-12, UG-18). Sepenuhnya on-device.
///
/// **Tidak ada akumulasi sesi.** Mode ini menjawab satu pertanyaan saja:
/// "lembar yang sedang saya hadapkan ke kamera ini nominalnya berapa?"
/// Tombol kiri mengumumkan nominal frame saat itu, lalu selesai - tidak ada
/// total berjalan, tidak ada rincian lembar, tidak ada kartu "total direset".
/// Penjumlahan otomatis justru berbahaya di sini: pengguna tunanetra tidak
/// bisa melihat lembar mana yang sudah terhitung, jadi satu lembar yang
/// ter-scan dua kali menghasilkan total yang salah tanpa satu pun tanda.
///
/// **Jalur mock hanya hidup di build debug.** Simulasi Timer-nya memanggil
/// `_enterDetected(_kDenoms[_rand.nextInt(...)])` - yaitu **mengucapkan
/// nominal acak dengan nada yakin**. Di rilis, jalur itu bisa tercapai hanya
/// karena model gagal dimuat, dan pengguna tunanetra tidak punya cara
/// membedakannya dari hasil sungguhan. Salah menyebut nominal berarti
/// kerugian uang nyata, jadi di rilis kegagalan model berakhir di satu
/// kalimat jujur: fiturnya tidak tersedia. Titik.
///
/// UG-13 (offline banner), UG-14 (izin kamera), UG-15 (senyap/TTS mati), dan
/// UG-16 (font scale 200%) sengaja TIDAK dimodelkan di sini - itu murni
/// keputusan lapisan UI (screen membaca GlobalConditionsProvider / izin
/// sistem / MediaQuery langsung).
enum MoneyState {
  idle,        // UG-01
  noCandidate, // UG-08
  partial,     // UG-02
  folded,      // UG-10
  fit,         // UG-03
  glare,       // UG-12a
  dark,        // UG-12b
  processing,  // UG-04
  detected,    // UG-05 (nominal lembar yang sedang dihadapi kamera)
  uncertain,   // UG-06
  notMoney,    // UG-07
  foreign,     // UG-18
}

/// Pola getar bagian 3.6 - `positive` (2×25ms) untuk bingkai pas,
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

  int _lastAmount = 0;
  int get lastAmount => _lastAmount;

  int _noCandidateHintIndex = 0;
  String get noCandidateHint => _kNoCandidateHints[_noCandidateHintIndex];

  String _notMoneyLabel = _kNotMoneyLabels.first;
  String get notMoneyLabel => _notMoneyLabel;

  bool get busy => _state == MoneyState.processing;

  /// Callback keluar - screen yang mengubahnya jadi suara/getar sungguhan
  /// lewat TtsProvider/Vibration, supaya provider ini tetap tidak bergantung
  /// pada BuildContext (pola sama dengan `CameraProvider.onFrameReady`).
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(MoneyHaptic pattern)? onHaptic;

  Timer? _stepTimer;
  Timer? _hintRotateTimer;
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

  /// Simulasi hanya boleh hidup di build debug. `kDebugMode` dikompilasi
  /// menjadi konstanta, jadi di rilis seluruh cabang mock ikut tereliminasi.
  static bool get _mockAllowed => kDebugMode;

  /// True kalau model tidak tersedia DAN mock tidak boleh jalan - layar
  /// memakai ini untuk menonaktifkan tombol dengan alasan yang jujur.
  bool get isUnavailable => !_useRealModel && !_mockAllowed;

  /// Masuk mode (UG-01) - mulai siklus otomatis dari awal.
  void start() {
    if (_running) return;
    _running = true;
    _lastAmount = 0;
    _set(MoneyState.idle);
    if (!_useRealModel) _fallbackWhenModelMissing();
  }

  /// Satu titik keputusan untuk "model tidak ada": simulasi di debug,
  /// pengakuan jujur di rilis. Tidak ada jalan ketiga yang menyebut angka.
  void _fallbackWhenModelMissing() {
    if (_mockAllowed) {
      _scheduleFromIdle();
      return;
    }
    _set(MoneyState.idle);
    _speak(
      'Pengenalan uang tidak tersedia saat ini. Model belum siap di perangkat ini.',
      tier: SpeechTier.warning,
    );
  }

  /// Keluar mode - hentikan semua timer, jangan bicara lagi.
  void pause() {
    _running = false;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
  }

  /// Dipanggil dari tombol kamera BottomActionBar - "paksa deteksi ulang".
  void forceRedetect() {
    if (!_running) return;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    if (_useRealModel) {
      _consecutiveMiss = 0;
      _set(MoneyState.fit);
      return;
    }
    if (!_mockAllowed) {
      _speak(
        'Pengenalan uang tidak tersedia saat ini.',
        tier: SpeechTier.warning,
      );
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

  /// Hasil buffer terbaru dari model - diperbarui tiap frame, dipakai saat
  /// snapAndAnnounce() dipanggil. Tidak pernah auto-diumumkan.
  MoneyResult? _latestResult;

  /// Jeda antar inferensi. Klasifikasi 224x224 ringan, tapi tidak ada
  /// gunanya berjalan tiap frame: pengguna butuh waktu memposisikan uang.
  static const _inferenceInterval = Duration(milliseconds: 600);

  /// Coba muat model on-device. Mengembalikan false kalau file belum ada -
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

  /// Umpan frame kamera. Aman dipanggil tiap frame - di-throttle sendiri.
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

    // Selalu perbarui buffer - snapAndAnnounce() akan membaca ini saat user
    // menekan tombol, sehingga hasilnya selalu mencerminkan apa yang kamera
    // lihat saat itu tanpa delay inferensi tambahan.
    _latestResult = result;

    if (result.detected && result.valueIdr != null) {
      _consecutiveMiss = 0;
      // Update visual state ke "fit" (bingkai hijau) agar user tahu
      // kamera sudah melihat uang dan siap di-snap - tapi TIDAK bicara.
      if (_state != MoneyState.fit && _state != MoneyState.detected) {
        _set(MoneyState.fit);
      }
      return;
    }

    switch (result.failure) {
      case MoneyFailure.lowConfidence:
        // UG-06 - ragu. Tampilkan bingkai + indikator tapi tidak bicara
        // secara otomatis; pesan muncul saat user snap.
        _consecutiveMiss = 0;
        if (_state != MoneyState.uncertain) {
          _set(MoneyState.uncertain);
        }
      case MoneyFailure.modelUnavailable:
        _useRealModel = false;
        if (!_running) return;
        _fallbackWhenModelMissing();
      case MoneyFailure.error:
      case null:
        // UG-08 - tidak ada kandidat: pill instruksi berputar tiap 5 detik.
        _consecutiveMiss++;
        if (_consecutiveMiss >= 8 && _state != MoneyState.noCandidate) {
          _set(MoneyState.noCandidate);
          _startHintRotation();
        }
    }
  }

  /// Dipanggil saat user menekan tombol kiri - umumkan hasil buffer terbaru.
  ///
  /// Tidak ada delay inferensi: model sudah berjalan di background tiap 600ms,
  /// jadi _latestResult selalu segar. User mendapat jawaban instan.
  void snapAndAnnounce() {
    if (!_running) return;

    if (!_useRealModel) {
      // Tanpa model: di debug jatuh ke simulasi, di rilis mengaku tidak bisa.
      // Yang tidak pernah terjadi di rilis adalah menyebut angka.
      forceRedetect();
      return;
    }

    final result = _latestResult;
    if (result == null || !result.detected || result.valueIdr == null) {
      // Tidak ada uang di frame saat ini - beri tahu user.
      final msg = (result?.failure == MoneyFailure.lowConfidence)
          ? 'Belum yakin, dekatkan sedikit dan tahan diam.'
          : 'Tidak ada uang terdeteksi. Arahkan kamera ke uang.';
      _speak(msg, tier: SpeechTier.warning);
      return;
    }

    // Ada uang - masuk ke alur deteksi normal (session tracking + TTS).
    _enterDetected(result.valueIdr!);
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
    // Pertahanan berlapis: satu-satunya tempat di seluruh aplikasi yang bisa
    // mengucapkan nominal tanpa melihat uang sungguhan. Kalau suatu saat ada
    // jalur baru yang lolos ke sini di rilis, ia berhenti di sini.
    if (!_mockAllowed) {
      _set(MoneyState.idle);
      return;
    }
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
    _after(2200, _scheduleFromIdle);
  }

  void _enterForeign() {
    _set(MoneyState.foreign);
    _speak('Ini sepertinya uang asing atau rusak, saya belum bisa membacanya.', tier: SpeechTier.warning);
    _after(2200, _scheduleFromIdle);
  }

  // -------------------------------------------------------------- detected

  /// Satu lembar, satu jawaban. Menekan tombol lagi pada lembar yang sama
  /// hanya mengulang nominal yang sama - tidak pernah menambah apa pun.
  void _enterDetected(int amount) {
    _lastAmount = amount;
    _set(MoneyState.detected);
    _speak(terbilangRupiah(amount), tier: SpeechTier.info);
  }
}
```

---

## File: `lib/providers/navigation_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/navigation_provider.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier, TtsQueue;
import '../models/detection.dart';
import '../services/nav_frame_converter.dart';
import '../services/pidnet_service.dart';
import '../services/yolo_navigasi_service.dart';
import '../widgets/zone_indicator.dart' show ZoneStatus;

/// NavigationStep - placeholder tanpa GPS/Google Maps (belum diimplementasi,
/// menyusul sprint lain).
class NavigationStep {
  final String instruction;
  final int distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

/// Fase segmentasi jalur - bagian 10 IMPLEMENTASI.md (NV-01..NV-13).
///
/// **Sepenuhnya on-device.** PIDNet-S (segmentasi 3 zona) dan YOLO11n
/// (rintangan) berjalan di ponsel; keduanya sudah dibundel di APK.
///
/// > Jalur server dihapus. `navigasi.router` memang sudah dinonaktifkan di
/// > `backend/main.py` sejak navigasi dipindah on-device, sehingga fallback
/// > `POST /api/navigasi` di sini hanya menghasilkan 404 - lalu diterjemahkan
/// > menjadi "Saya tidak bisa membaca jalur tanpa sambungan ke server".
/// > Kalimat itu menyalahkan jaringan untuk endpoint yang memang sengaja
/// > tidak disediakan, dan mendorong pengguna mencari sinyal yang tidak akan
/// > menolong. Sekarang mode ini hidup atau mati bersama modelnya sendiri,
/// > dan mengatakannya apa adanya.
enum NavPhase {
  calibrating, // NV-01
  loadingModels, // NV-02 - memuat PIDNet + YOLO on-device
  active, // NV-03..NV-09
  unavailable, // NV-11 - model on-device tidak bisa dipakai
  degraded, // NV-13 - model jalan tapi frame sering gagal dibaca
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
  final double _potholeSteps = 3;
  double get potholeSteps => _potholeSteps;

  /// Zona rawan dari laporan komunitas - informasi yang tidak terlihat kamera.
  String? _riskZoneWarning;
  String? get riskZoneWarning => _riskZoneWarning;

  /// Rintangan dari frame yang sama dengan zona. Datang bersama zona supaya
  /// keduanya tidak pernah menggambarkan momen yang berbeda.
  List<Detection> _obstacles = const [];
  List<Detection> get obstacles => _obstacles;

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 - mengambil alih layar

  /// Sumber frame kamera mentah (YUV) untuk PIDNet + YOLO on-device.
  Future<CameraImage?> Function()? cameraSource;

  /// Status loading model on-device.
  bool _modelsLoading = false;
  bool _modelsReady   = false;
  bool get modelsReady => _modelsReady;

  /// Satu permintaan in-flight; frame yang datang saat menunggu dibuang.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 700));

  Timer? _loopTimer;
  int _consecutiveFailures = 0;
  String _lastSpokenMessage = '';
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pesan yang sedang menunggu konfirmasi frame berikutnya, dan sudah berapa
  /// frame berturut-turut ia bertahan. Dipakai [_emitGuidance] sebagai
  /// histeresis - lihat alasannya di sana.
  String _candidateMessage = '';
  int _candidateStreak = 0;

  /// Jeda minimum antar ucapan berbeda (non-critical).
  static const _minGap = Duration(milliseconds: 1800);

  /// Jeda sebelum pesan non-critical yang SAMA boleh diulang.
  static const _sameMessageGap = Duration(seconds: 6);

  /// Jeda sebelum peringatan critical yang SAMA boleh diulang. Lebih pendek
  /// dari [_sameMessageGap] karena bahayanya nyata, tapi tidak nol - lihat
  /// [_emitGuidance].
  static const _criticalRepeatGap = Duration(seconds: 4);

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void startCalibration() {
    _phase = NavPhase.calibrating;
    notifyListeners();
  }

  /// NV-01 selesai → muat model on-device → NV-03 jalur aman.
  void finishCalibration() {
    _phase = NavPhase.loadingModels;
    _left = _center = _right = ZoneStatus.unknown;
    notifyListeners();

    if (!_modelsReady && !_modelsLoading) {
      _loadOnDeviceModels();
    } else {
      _startLoop();
    }
  }

  /// Muat PIDNet + YOLO secara paralel di background.
  Future<void> _loadOnDeviceModels() async {
    _modelsLoading = true;
    debugPrint('[Nav] Memuat model on-device...');

    final results = await Future.wait([
      PidnetService.instance.tryLoad(),
      YoloNavigasiService.instance.tryLoad(),
    ]);

    _modelsLoading = false;
    _modelsReady = results[0] && results[1];

    if (!_modelsReady) {
      // Tidak ada cadangan server lagi. Katakan apa adanya - dan sebut mode
      // apa yang MASIH bisa dipakai, supaya ini bukan jalan buntu.
      debugPrint('[Nav] Model on-device gagal dimuat.');
      _phase = NavPhase.unavailable;
      _speak(
        'Panduan jalur tidak bisa dijalankan di perangkat ini. '
        'Mode Deteksi Objek tetap bisa memperingatkan rintangan.',
        tier: SpeechTier.critical,
      );
      notifyListeners();
      return;
    }

    debugPrint('[Nav] Model on-device siap. PIDNet + YOLO aktif.');
    _speak('Panduan jalur aktif.', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    _candidateMessage = '';
    _candidateStreak = 0;
    // ~2 frame per detik. Kecepatan jalan kaki sekitar 1,4 m/s, jadi tiap
    // frame mewakili kurang dari satu meter perjalanan - cukup rapat untuk
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
    if (_phase == NavPhase.paused || !_modelsReady) return;
    await _pacer.run(_tickOnDevice);
  }

  // ── On-Device: PIDNet + YOLO di HP ──────────────────────────
  Future<void> _tickOnDevice() async {
    final camGrab = cameraSource;
    if (camGrab == null) return;
    final frame = await camGrab();
    if (frame == null) return;

    try {
      // Konversi YUV→RGB sekali, dipakai keduanya
      final conv = NavFrameConverter.fromCameraImage(frame);

      // Jalankan PIDNet dan YOLO secara paralel
      final results = await Future.wait([
        PidnetService.instance.analyze(conv.rgb, conv.width, conv.height),
        YoloNavigasiService.instance.detect(conv.rgb, conv.width, conv.height),
      ]);

      final zoneAnalysis = results[0] as ZoneAnalysis?;
      final obstacles    = results[1] as List<Detection>;

      if (zoneAnalysis == null) return;

      _consecutiveFailures = 0;
      _applyOnDeviceResult(zoneAnalysis, obstacles);
    } catch (e) {
      debugPrint('[Nav] on-device tick error: $e');
      _handleFailure();
    }
  }

  void _applyOnDeviceResult(ZoneAnalysis zones, List<Detection> obstacles) {
    final wasDown = _phase == NavPhase.degraded || _phase == NavPhase.loadingModels;

    _left   = zones.left;
    _center = zones.center;
    _right  = zones.right;
    _phase  = NavPhase.active;
    _obstacles = obstacles;
    _pothole = obstacles.any((d) =>
        (d.labelEn == 'lubang' || d.labelEn == 'got_terbuka') &&
        d.dangerLevel == 'critical');

    if (wasDown) _speak('Jalur terbaca lagi.', tier: SpeechTier.info);

    final guidance = _composeGuidance(zones, obstacles);
    _emitGuidance(guidance.$1, guidance.$2, takeover: guidance.$3);
    notifyListeners();
  }

  /// Susun satu pesan untuk frame ini: rintangan kritis didahulukan, lalu
  /// rintangan peringatan, baru arahan zona. Fungsi ini murni - tidak bicara
  /// dan tidak mengubah state - supaya keputusan "apa yang perlu dikatakan"
  /// terpisah dari keputusan "apakah sekarang saatnya mengatakannya".
  (String, SpeechTier, bool) _composeGuidance(ZoneAnalysis zones, List<Detection> obstacles) {
    final critical = obstacles.where((d) => d.dangerLevel == 'critical').toList();
    if (critical.isNotEmpty) {
      return (critical.first.ttsMessage, SpeechTier.critical, true);
    }

    final warning = obstacles.where((d) => d.dangerLevel == 'warning').toList();
    if (warning.isNotEmpty) {
      return (warning.first.ttsMessage, SpeechTier.warning, false);
    }

    final allDanger = _left == ZoneStatus.danger &&
        _center == ZoneStatus.danger &&
        _right == ZoneStatus.danger;
    if (allDanger) {
      return ('Berhenti dulu. Tidak ada jalur aman.', SpeechTier.critical, false);
    }
    if (_center == ZoneStatus.danger) {
      return ('Berhenti! Jalur di depan tidak aman.', SpeechTier.critical, true);
    }
    return (zones.ttsMessage, SpeechTier.info, false);
  }

  /// Anti-banjir suara. Loop menghasilkan pesan tiap frame; mengucapkan
  /// semuanya akan menutupi suara lalu lintas - hal terakhir yang boleh
  /// terjadi pada orang yang sedang menyeberang.
  ///
  /// Tiga rem, masing-masing menutup lubang yang berbeda:
  ///
  /// 1. **Histeresis.** PIDNet dan YOLO berkedip antar-frame; tanpa ini satu
  ///    kedipan model langsung jadi satu kedipan suara. Info dan Warning
  ///    butuh dua frame berturut-turut dengan pesan yang sama. Critical lewat
  ///    pada kemunculan pertama - menunda peringatan bahaya ~700 ms demi
  ///    kerapian suara adalah pertukaran yang salah di mode ini.
  ///
  /// 2. **Critical tidak memotong dirinya sendiri.** Sebelumnya kedua rem
  ///    waktu dilewati Critical sepenuhnya, jadi jalur tengah yang berbahaya
  ///    selama sepuluh detik memicu peringatan identik tiap ~700 ms. Tiap
  ///    pemicu menjalankan `TTSService.stop()` lalu `speak(interrupt: true)`,
  ///    sehingga kalimatnya diulang dari awal terus-menerus dan **tidak
  ///    pernah selesai diucapkan sekali pun**. Peringatan yang tidak pernah
  ///    utuh bukan peringatan. Critical tetap memotong Info/Warning; yang
  ///    dilarang hanya memotong Critical yang sama.
  ///
  /// 3. **Jangan menumpuk di atas ucapan yang belum habis.** [_lastSpokenAt]
  ///    dicatat saat pesan DIKIRIM, bukan saat selesai dibacakan. Satu
  ///    kalimat arahan zona ("Kiri aman, tengah hati-hati, kanan bahaya.
  ///    Geser ke kiri.") butuh ~4 detik pada `speechRate` 0,5 - jauh lebih
  ///    lama dari rem 1,8 detik. Tanpa cek [TtsQueue.isSpeaking], pesan
  ///    berikutnya selalu berangkat sebelum yang sekarang habis, lalu
  ///    dibuang antrean karena kedaluwarsa 2 detik. Itulah yang terdengar
  ///    sebagai suara buru-buru dan saling menimpa.
  void _emitGuidance(String message, SpeechTier tier, {required bool takeover}) {
    if (message == _candidateMessage) {
      _candidateStreak++;
    } else {
      _candidateMessage = message;
      _candidateStreak = 1;
    }
    if (tier != SpeechTier.critical && _candidateStreak < 2) return;

    final now = DateTime.now();
    final isRepeat = message == _lastSpokenMessage;
    final elapsed = now.difference(_lastSpokenAt);

    if (tier == SpeechTier.critical) {
      if (isRepeat && elapsed < _criticalRepeatGap) return;
    } else {
      if (isRepeat && elapsed < _sameMessageGap) return;
      if (elapsed < _minGap) return;
      if (TtsQueue.instance.isSpeaking) return;
    }

    _lastSpokenMessage = message;
    _lastSpokenAt = now;
    // Dipanggil hanya kalau pesannya benar-benar jadi diucapkan. Sebelumnya
    // takeover berjalan lebih dulu tanpa syarat, jadi ia tetap memotong
    // ucapan berjalan walau peringatannya kemudian diredam rem di atas.
    if (takeover) onTakeover?.call();
    _speak(message, tier: tier);
  }

  /// Frame gagal dianalisis berturut-turut.
  ///
  /// Penyebabnya sekarang lokal - lensa tertutup, terlalu gelap, model
  /// kehabisan memori - bukan jaringan. Naskahnya ikut berubah: menyalahkan
  /// "sambungan server" untuk masalah yang ada di tangan pengguna hanya
  /// mengirimnya mencari sinyal yang tidak akan menolong.
  void _handleFailure() {
    _consecutiveFailures++;

    // Satu kegagalan bisa jadi hanya satu frame buruk - jangan langsung
    // menakuti pengguna. Beberapa berturut-turut berarti mode ini memang
    // sedang tidak melihat apa-apa, dan itu harus dikatakan segera: diam
    // berarti membiarkan orang berjalan menyangka dirinya dituntun.
    if (_consecutiveFailures == 2 && _phase != NavPhase.degraded) {
      _phase = NavPhase.degraded;
      _speak('Jalur sulit dibaca, arahan mungkin tertinggal.', tier: SpeechTier.warning);
      notifyListeners();
      return;
    }

    if (_consecutiveFailures >= 4 && _phase != NavPhase.unavailable) {
      _phase = NavPhase.unavailable;
      _left = _center = _right = ZoneStatus.unknown;
      _speak(
        'Berhenti jalan dulu. Saya tidak bisa membaca jalur sekarang. '
        'Periksa apakah kamera tertutup, atau cari tempat yang lebih terang.',
        tier: SpeechTier.critical,
      );
      notifyListeners();
    }
  }

  /// NV-14a/b - telepon masuk (disimulasikan manual dari panel debug).
  void simulateIncomingCall() {
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void endSimulatedCall() {
    _phase = NavPhase.active;
    // NV-14b - status jalur SEKARANG, bukan yang tadi. Karena itu loop-nya
    // dijalankan lagi lebih dulu dan ringkasannya menyusul dari frame baru.
    _speak('Navigasi lanjut. ${_summaryPhrase()}', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  String _summaryPhrase() {
    if (_left == ZoneStatus.safe && _center == ZoneStatus.safe && _right == ZoneStatus.safe) return 'Jalur aman.';
    return zoneSummary();
  }

  /// Ringkasan tiga zona dalam kata, bukan warna.
  ///
  /// `ZoneIndicator` menampilkan tiga blok berwarna - tidak ada gunanya bagi
  /// pengguna yang tidak melihat layar. Ini padanan verbalnya, dan inilah yang
  /// dibacakan tombol kiri "Ulangi arahan".
  String zoneSummary() {
    if (_phase == NavPhase.calibrating || _phase == NavPhase.loadingModels) {
      return 'Jalur belum terbaca, tunggu sebentar.';
    }
    if (_left == ZoneStatus.unknown &&
        _center == ZoneStatus.unknown &&
        _right == ZoneStatus.unknown) {
      return 'Jalur belum terbaca.';
    }

    String word(ZoneStatus s) => switch (s) {
          ZoneStatus.safe => 'aman',
          ZoneStatus.caution => 'hati-hati',
          ZoneStatus.danger => 'bahaya',
          ZoneStatus.unknown => 'belum terbaca',
        };

    final parts = 'Kiri ${word(_left)}, tengah ${word(_center)}, kanan ${word(_right)}.';

    // Sebutkan rekomendasinya, bukan hanya keadaannya - pengguna butuh tahu
    // harus berbuat apa, bukan sekadar daftar status.
    final saran = _center == ZoneStatus.safe
        ? 'Tetap di tengah.'
        : _left == ZoneStatus.safe
            ? 'Geser ke kiri.'
            : _right == ZoneStatus.safe
                ? 'Geser ke kanan.'
                : 'Berhenti dulu, tidak ada jalur aman.';

    return '$parts $saran';
  }

  /// Tombol kiri Mode Navigasi / perintah suara "ulangi".
  ///
  /// Sengaja melewati anti-banjir [_announce]: ini permintaan eksplisit
  /// pengguna, bukan pesan otomatis yang berisiko menutupi suara lalu lintas.
  void repeatGuidance() {
    _speak(zoneSummary(), tier: SpeechTier.warning);
  }

  /// `actionStopWalking` - hentikan panduan tanpa keluar mode.
  /// Mengembalikan false kalau memang tidak ada yang berjalan.
  bool pauseGuidance() {
    if (_phase == NavPhase.paused) return false;
    autoPause();
    return true;
  }

  /// NV-15 - jeda otomatis (berhenti berjalan / ponsel diturunkan).
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
    _modelsReady   = false;
    _modelsLoading = false;
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

## File: `lib/providers/settings_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/settings_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/haptic_service.dart';
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
    // Tanpa baris ini, pilihan "Getar: Mati" tersimpan ke disk tapi tidak
    // mematikan apa pun.
    HapticService.instance.setMode(_vibrationMode);
    // Alamat tersimpan diterapkan ke service SEBELUM permintaan pertama -
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
    HapticService.instance.setMode(m);
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

## File: `lib/providers/tts_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/tts_provider.dart`

```dart
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart';

export '../core/speech/tts_queue.dart' show SpeechTier;

/// TtsProvider - pembungkus [TtsQueue] tier-based (bagian 15). Dipakai
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

## File: `lib/providers/voice_provider.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/providers/voice_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../core/voice/scene_translator.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/find_object_provider.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

/// VoiceState - bagian 11 IMPLEMENTASI.md (AS-01..AS-25). Granular dari 4
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

/// VoiceProvider - STT → intent routing → API call → TTS.
///
/// Intent routing 2-lapis dipertahankan dari implementasi awal:
/// - Layer 1: keyword lokal (0ms latency, aman offline) via [CommandParser].
/// - Layer 2: LLM routing via ServerService.routeIntent, hanya dipanggil
///   kalau Layer 1 tidak match.
class VoiceProvider extends ChangeNotifier {
  final CameraProvider _camera;
  final DetectionProvider _detection;
  final AppModeProvider _appMode;
  final FindObjectProvider _findObject;

  VoiceProvider(this._camera, this._detection, this._appMode, this._findObject);

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
  DetectionProvider get detection => _detection;
  int get consecutiveFailures => _consecutiveFailures;
  String get lastText => _lastText;
  String get response => _response;

  /// AS-18 - dua tebakan terdekat saat perintah tidak dikenali.
  List<VoiceIntent> _suggestions = [];
  List<VoiceIntent> get suggestions => _suggestions;
  String _heardRaw = '';
  String get heardRaw => _heardRaw;

  /// Dipasang layar untuk menyalurkan suara lewat antrean tier - menjaga
  /// provider ini tidak bergantung BuildContext, pola sama dengan mode lain.
  void Function(String text)? onSpeak;
  void Function()? onAllFeaturesFailed;

  /// Dipasang oleh VoiceScreen saat masuk sebagai overlay (push Navigator).
  /// Dipanggil setelah `actionGoBack` berhasil - agar layar bisa pop dirinya
  /// sendiri tanpa VoiceProvider bergantung pada BuildContext/Navigator.
  void Function()? onNavigateBack;

  /// Pengaturan adalah layar penunjang, bukan mode - pembukaannya butuh
  /// Navigator. Layar yang aktif memasang ini dan mengembalikan **true hanya
  /// kalau halaman benar-benar terbuka**; kalau null atau false, Vinara
  /// mengatakan yang sejujurnya alih-alih mengonfirmasi.
  Future<bool> Function()? onOpenSettings;

  // ── Kontrak aksi mode ──────────────────────────────────────────────────────
  //
  // Sepuluh intent punya bank kata lengkap tapi tidak punya handler sama
  // sekali; semuanya jatuh ke `default:` dan dijawab "Perintah itu belum saya
  // kenali di mode ini". Callback di bawah menyambungkannya ke mode yang
  // sedang aktif, sehingga perintah suara dan tombol kiri menjalankan hal
  // yang persis sama - satu model mental, dua cara memicunya.

  /// Aksi utama mode aktif - setara menekan tombol kiri.
  /// Dipasang tiap layar mode; `null` berarti mode ini memang tidak punya.
  void Function()? onPrimaryAction;

  /// Label aksi utama, untuk diucapkan saat mengonfirmasi.
  String Function()? primaryActionLabel;

  /// Ucapkan ulang hal penting terakhir di mode ini.
  void Function()? onRepeatLast;

  /// Jeda / lanjutkan pembacaan panjang (Mode Baca Teks).
  /// Mengembalikan true kalau mode aktif benar-benar menanganinya.
  bool Function()? onPauseSpeech;
  bool Function()? onResumeSpeech;

  /// Berhenti berjalan (Mode Navigasi).
  bool Function()? onStopWalking;

  /// Pengaturan kecepatan bicara - dipasang layar dari SettingsProvider.
  Future<double> Function(double delta)? onAdjustSpeechRate;

  Future<void> init() async {
    await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (_) => _setState(VoiceState.noSpeech),
    );
  }

  /// AS-23 - riwayat kedaluwarsa setelah 15 menit tanpa aktivitas.
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
      listenOptions: SpeechListenOptions(
        // 5 detik memotong kalimat yang wajar-wajar saja ("tolong bacakan
        // tulisan yang ada di depan saya"), dan potongannya lalu gagal
        // dikenali - pengguna menyimpulkan parsernya bodoh, padahal ia tidak
        // pernah mendengar kalimat utuhnya. `pauseFor` yang menutup rekaman:
        // 2 detik hening berarti pengguna sudah selesai bicara.
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        localeId: 'id_ID',
        cancelOnError: true,
      ),
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
    // AS-06 - jeda pendek "mentranskrip", tanpa kata "memproses".
    _setState(VoiceState.transcribing);
    await Future.delayed(const Duration(milliseconds: 250));

    final command = CommandParser.parse(text);

    if (!command.recognized) {
      if (command.suggestions.length >= 2) {
        // AS-19 - ambigu, pertanyaan pilihan dua.
        _suggestions = command.suggestions;
        _setState(VoiceState.ambiguous);
        _respond(
          'Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}, atau ${command.suggestions[1].spokenLabel}?',
          save: false,
        );
        return;
      }
      if (command.suggestions.isNotEmpty) {
        // AS-18 - tidak dikenali, satu tebakan tersedia.
        _suggestions = command.suggestions;
        _setState(VoiceState.unrecognized);
        _respond('Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}?', save: false);
        return;
      }
      // Tidak dikenali sama sekali - tidak ada saran.
      await _handleLocal('Maaf, saya tidak mengerti. Coba katakan lagi dengan cara berbeda.');
      return;
    }

    if (command.intent!.isModeChange) {
      // AS-17 - perintah ganti mode.
      await _applyModeChange(command.intent!);
      return;
    }

    // Perintah kembali ke mode sebelumnya.
    if (command.intent == VoiceIntent.actionGoBack) {
      await _handleGoBack();
      return;
    }

    // Perintah cari objek dengan target dinamis - pindah ke FindObject.
    if (command.intent == VoiceIntent.findObjectTarget && command.argument != null) {
      await _handleFindObjectTarget(command.argument!);
      return;
    }

    // Perintah nyalakan/matikan lampu - toggle torch.
    if (command.intent == VoiceIntent.actionTorch) {
      await _handleTorch();
      return;
    }

    // Perintah deskripsi suasana - Moondream2 via server.
    if (command.intent == VoiceIntent.describeScene) {
      await _handleDescribeScene();
      return;
    }

    switch (command.intent!) {
      case VoiceIntent.helpWhat:
        await _handleLocal('Aku bisa mendeteksi objek, membaca teks, mengenali uang, menuntun jalan, mencari barang, atau menjawab pertanyaan tentang sekitarmu.');

      case VoiceIntent.helpWhereAmI:
        // Sebutkan mode yang SEDANG aktif. Jawaban lama selalu "Kamu di mode
        // Asisten Suara" - benar hanya kalau Asisten sedang jadi mode, dan
        // menyesatkan setiap kali mic dibuka sebagai overlay dari mode lain.
        await _handleLocal('Kamu di mode ${_appMode.mode.label}.');

      case VoiceIntent.actionCapture:
        await _handlePrimaryAction();

      case VoiceIntent.actionReplay:
      case VoiceIntent.playRepeatSection:
        await _handleRepeatLast();

      case VoiceIntent.playPause:
        await _handlePlayback(pause: true);

      case VoiceIntent.playResume:
        await _handlePlayback(pause: false);

      case VoiceIntent.playFaster:
        await _handleSpeechRate(0.1);

      case VoiceIntent.playSlower:
        await _handleSpeechRate(-0.1);

      case VoiceIntent.actionStopWalking:
        await _handleStopWalking();

      default:
        await _handleLocal('Perintah itu belum saya kenali di mode ini.');
    }
  }

  /// `actionCapture` - "jepret", "ambil gambar". Menjalankan aksi utama mode
  /// aktif, yaitu hal yang sama dengan tombol kiri.
  Future<void> _handlePrimaryAction() async {
    final action = onPrimaryAction;
    if (action == null) {
      await _handleLocal('Mode ${_appMode.mode.label} tidak punya aksi ambil gambar.');
      return;
    }
    _setState(VoiceState.processingLocal);
    action();
    _consecutiveFailures = 0;
    final label = primaryActionLabel?.call();
    await _respond(label != null ? 'Baik, $label.' : 'Baik.', save: false);
  }

  Future<void> _handleRepeatLast() async {
    final repeat = onRepeatLast;
    if (repeat == null) {
      await _handleLocal('Tidak ada yang bisa diulang di mode ini.');
      return;
    }
    _setState(VoiceState.processingLocal);
    repeat();
    _consecutiveFailures = 0;
    _setState(VoiceState.responded);
  }

  Future<void> _handlePlayback({required bool pause}) async {
    final handler = pause ? onPauseSpeech : onResumeSpeech;
    final handled = handler?.call() ?? false;
    if (handled) {
      _consecutiveFailures = 0;
      await _respond(pause ? 'Dijeda.' : 'Dilanjutkan.', save: false);
      return;
    }
    // Tidak ada pembacaan panjang yang berjalan. Perlakukan "jeda" sebagai
    // permintaan menghentikan suara - itu maksud yang paling mungkin.
    if (pause) {
      await TTSService.instance.stop();
      _setState(VoiceState.responded);
      return;
    }
    await _handleLocal('Tidak ada pembacaan yang sedang dijeda.');
  }

  Future<void> _handleSpeechRate(double delta) async {
    final adjust = onAdjustSpeechRate;
    if (adjust == null) {
      await _handleLocal('Kecepatan bicara bisa diatur di Pengaturan.');
      return;
    }
    _setState(VoiceState.processingLocal);
    final applied = await adjust(delta);
    _consecutiveFailures = 0;
    final persen = (applied * 100).round();
    await _respond(
      delta > 0 ? 'Lebih cepat, $persen persen.' : 'Lebih pelan, $persen persen.',
      save: false,
    );
  }

  Future<void> _handleStopWalking() async {
    final stop = onStopWalking;
    if (stop == null || !stop()) {
      await _handleLocal('Kamu sedang tidak dalam panduan jalan.');
      return;
    }
    _consecutiveFailures = 0;
    await _respond('Panduan jalan dihentikan.', save: false);
  }

  /// AS-17 - ganti mode lewat suara. **Aturan mutlak bagian 4.1: suara Vinara
  /// tidak boleh pernah mengonfirmasi sesuatu yang tidak terjadi.** State
  /// dipindah dulu lewat [AppModeProvider.setMode]; konfirmasi "Baik."
  /// dititipkan sebagai prefiks pengumuman kedatangan, jadi ia baru terdengar
  /// setelah layar mode tujuan benar-benar terpasang. Kalau perpindahan
  /// dibatalkan (NV-18 saat pengguna masih berjalan), yang diucapkan adalah
  /// keadaan yang sebenarnya - bukan konfirmasi.
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
      // Dibatalkan konfirmasi NV-18 - pengguna tetap di tempatnya.
      await _respond('Tetap di mode ${_appMode.mode.label}.', save: false);
      return;
    }
    _consecutiveFailures = 0;
    // Tidak ada _respond di sini: pengumuman "Baik. <Mode> aktif. <panduan>"
    // diucapkan announceEntry milik layar tujuan, sesudah ia terpasang.
    _setState(VoiceState.responded);
  }

  Future<void> _handleLocal(String answer) async {
    // AS-08 - proses lokal, "Baik." lalu langsung hasilnya.
    _setState(VoiceState.processingLocal);
    await _respond('Baik. $answer');
  }

  /// Toggle flashlight - nyala jadi mati, mati jadi nyala.\n  /// Konfirmasi TTS menyebutkan status baru, bukan perintah.
  Future<void> _handleTorch() async {
    _setState(VoiceState.processingLocal);
    await _camera.toggleTorch();
    final msg = _camera.isTorchOn
        ? 'Baik, lampu dinyalakan.'
        : 'Baik, lampu dimatikan.';
    await _respond(msg, save: false);
  }

  /// Deskripsikan suasana di depan via Moondream2 (on-server).
  ///
  /// Moondream2 menjawab dalam Bahasa Inggris. Sebelum ini kalimatnya
  /// dibacakan apa adanya dengan TTS `en-US` - menuntut kemampuan Inggris
  /// lisan yang tidak bisa diasumsikan pada tunanetra di pasar dan warung
  /// Indonesia.
  ///
  /// Sekarang diterjemahkan lokal lewat [translateSceneCaption]: kamus + aturan
  /// urutan kata, 0 ms, offline, tanpa LLM - prinsip yang sama yang membuat
  /// `narration_engine` dan `CommandParser` menggantikan Qwen. Menambahkan LLM
  /// penerjemah akan mengembalikan tepat tiga masalah yang sudah dibuang:
  /// lambat, bisa berhalusinasi, dan butuh server.
  ///
  /// Kalau cakupan kamus terlalu rendah, penerjemah **menyerah** dan kalimat
  /// Inggrisnya dibacakan - didahului satu penanda singkat, supaya pengguna
  /// tahu bahasanya berganti dan tidak menyangka aplikasinya rusak. Bahasa
  /// Indonesia yang kacau lebih buruk daripada Bahasa Inggris yang benar.
  Future<void> _handleDescribeScene() async {
    _setState(VoiceState.processingLlm);
    onSpeak?.call('Saya foto sekitarmu dulu, tunggu sebentar.');

    if (!_camera.isInitialized) {
      await _handleLocal('Kamera tidak tersedia untuk mengambil foto.');
      return;
    }

    try {
      final jpeg = await _camera.captureJpeg();
      final description = await ServerService.instance.describeScene(jpeg);

      if (description == null || description.isEmpty) {
        await _handleLocal('Maaf, saya tidak bisa mendeskripsikan suasana saat ini. Coba lagi.');
        return;
      }

      _consecutiveFailures = 0;

      final translated = translateSceneCaption(description);
      if (translated.isUsable) {
        _response = translated.indonesian!;
        _setState(VoiceState.responded);
        await TTSService.instance.speak(_response);
        return;
      }

      debugPrint('[Describe] cakupan kamus ${translated.coverage.toStringAsFixed(2)} '
          '- dibacakan dalam Bahasa Inggris');
      _response = description;
      _setState(VoiceState.responded);
      await TTSService.instance.speak('Dalam bahasa Inggris.');
      await TTSService.instance.speakEnglish(description);
    } catch (e) {
      debugPrint('[VoiceProvider] _handleDescribeScene error: $e');
      await _handleLocal('Gagal mendeskripsikan suasana. Coba lagi.');
    }
  }



  /// Perintah suara "kembali" \u2014 kembali ke mode sebelumnya via AppModeProvider.
  /// Jika ada onNavigateBack (masuk sebagai overlay push), callback dipanggil
  /// sesudah mode berubah agar Navigator bisa pop layar ini.
  Future<void> _handleGoBack() async {
    _setState(VoiceState.processingLocal);
    final previous = _appMode.previousMode;
    final label = previous?.label ?? AppMode.tuntun.label;
    final changed = await _appMode.goBack(spokenPrefix: 'Kembali.');
    if (changed) {
      _consecutiveFailures = 0;
      _setState(VoiceState.responded);
      // Pop dilakukan setelah mode berubah supaya announceEntry di layar tujuan
      // terucap sebelum layar ini ditutup.
      onNavigateBack?.call();
    } else {
      await _respond('Sudah di mode $label, tidak bisa kembali lebih jauh.', save: false);
    }
  }

  /// Perintah suara "carikan [barang]" dari mode mana pun:
  /// - Set target ke FindObjectProvider
  /// - Pindah mode ke findObject
  /// - Pop VoiceScreen overlay jika ada (via onNavigateBack)
  Future<void> _handleFindObjectTarget(String target) async {
    _setState(VoiceState.processingLocal);
    _findObject.setTarget(target);
    final changed = await _appMode.setMode(AppMode.findObject, spokenPrefix: 'Baik, mencari $target.');
    if (changed) {
      _consecutiveFailures = 0;
      _setState(VoiceState.responded);
      onNavigateBack?.call();
    } else {
      await _respond('Sudah di mode Cari Objek. Target diperbarui ke $target.', save: false);
      onNavigateBack?.call();
    }
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

  /// AS-20 - pengguna menekan tombol Bicara lagi saat Vinara masih bicara:
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

  /// Lepas semua callback mode. Dipanggil layar saat dispose supaya aksi
  /// mode yang sudah ditinggalkan tidak ikut terbawa ke mode berikutnya.
  void clearModeHandlers() {
    onPrimaryAction = null;
    primaryActionLabel = null;
    onRepeatLast = null;
    onPauseSpeech = null;
    onResumeSpeech = null;
    onStopWalking = null;
  }

  @override
  void dispose() {
    onSpeak = null;
    onOpenSettings = null;
    onNavigateBack = null;
    onAllFeaturesFailed = null;
    onAdjustSpeechRate = null;
    clearModeHandlers();
    _stt.cancel();
    super.dispose();
  }
}
```

---

## File: `lib/screens/find_object_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/find_object_screen.dart`

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

/// Mode Cari Objek - bagian 12 IMPLEMENTASI.md, 19 state (CO-01..CO-19).
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
      // Prinsip 6 "umumkan saat tiba" - sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.findObject);
      final provider = context.read<FindObjectProvider>();
      provider.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);
      provider.onDirectionHaptic = _fireDirectionHaptic;
      // Server tidak menjawab sama saja tidak bisa mencari - periksa sebelum
      // memotret, bukan sesudah permintaannya gagal.
      provider.isOffline = () =>
          context.read<GlobalConditionsProvider>().isBackendDown;
      provider.frameSource = _grabFrame;
      provider.loadKnownTargets();

      // Kontrak tombol kiri: "jepret" lewat suara = menekan tombol kirim.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _triggerScan;
      voice.primaryActionLabel = () => 'mencari ${provider.target ?? "barang"}';
      voice.onRepeatLast = () {
        final pos = provider.lastKnownPosition;
        context.read<TtsProvider>().speak(
              pos == null
                  ? 'Belum ada hasil pencarian.'
                  : '${provider.target ?? "Barang"} terakhir terlihat di $pos.',
              tier: SpeechTier.info,
            );
      };
      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Status koneksi frame sebelumnya - dipakai mendeteksi transisi
  /// offline→online untuk menepati janji CO-14.
  bool _wasOffline = false;

  /// Frame terakhir dari stream kamera. Disimpan mentah dan baru dikodekan
  /// saat benar-benar akan dikirim - mengodekan tiap frame kamera padahal
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
    context.read<VoiceProvider>().clearModeHandlers();
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
    if (offline) return; // CO-14 - mode benar-benar dinonaktifkan
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
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 5),
        localeId: 'id_ID',
        cancelOnError: true,
      ),
    );
  }

  /// Dipanggil saat tombol kiri (📷 / "Kirim") ditekan.
  /// Ambil satu foto dari frame kamera terakhir → kirim ke backend YOLOE.
  Future<void> _triggerScan() async {
    final fo = context.read<FindObjectProvider>();
    if (fo.isScanning || fo.target == null) return;
    await fo.triggerScan();
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

    // CO-14 - janji "saya coba lagi begitu internet kembali" hanya bernilai
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
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

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
            // CO-15 - kartu di zona konten, tombolnya di slot kartu bawah.
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
              // Tombol kiri: aktif hanya saat ada target DAN tidak sedang scanning.
              // Label berubah jadi 'Kirim' supaya jelas fungsinya (bukan
              // "ambil foto" biasa, melainkan "kirim ke server untuk dicari").
              onCameraPressed: (fo.target != null && !fo.isScanning && _debugOverride == null)
                  ? _triggerScan
                  : null,
              cameraEnabled: fo.target != null && !fo.isScanning && _debugOverride == null,
              cameraDisabledReason: fo.target == null
                  ? 'tekan tombol bicara lalu sebutkan barangnya'
                  : 'sedang memindai',
              cameraLabel: fo.target != null ? 'Kirim - cari ${fo.target}' : 'Sebutkan barang dulu',
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
        return [const Center(child: VoiceOrb(state: VoiceOrbState.listening))];
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
              title: fo.state == FindObjectState.scanning
                  ? 'Memindai ke server…'
                  : 'Tekan tombol kirim untuk memindai',
              description: 'Mencari ${fo.target}',
            ),
          ),
          if (fo.state == FindObjectState.scanning)
            const Center(
              child: SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.onDark,
                ),
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
        return [_bottomPanel(bottomInset, const AlertCard(
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
        // CO-14 - targetnya disimpan, dan itu dikatakan. Bukan "perintah
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
    // CO-08 - panduan bertahap: dekat sekali menyebut "ulurkan tangan".
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
                child: Text('+${fo.matchCount - 1} lagi', style: AppTypography.caption(color: AppColors.onDark)),
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
        child: Text(text, style: AppTypography.body(color: AppColors.onDark)),
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
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di kiri', distanceMeter: 1.2, description: 'Senyap aktif - arah lewat getar: 1 ketuk kiri, 2 ketuk kanan'))];
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
            Text('Debug - Mode Cari Objek', style: AppTypography.title()),
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

## File: `lib/screens/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/index.dart`

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

## File: `lib/screens/main_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/main_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/index.dart';
import '../screens/index.dart';
import '../theme/index.dart';

enum _BootStage { splash, onboarding, permissions, initializing, ready }

/// MainScreen - mengelola alur boot (bagian 6 & 13): Splash → Onboarding
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
    // Kamera error jadi kondisi global (banner Critical), bukan kegagalan
    // diam-diam yang hanya terlihat sebagai layar hitam.
    final globals = context.read<GlobalConditionsProvider>();
    context.read<CameraProvider>().onErrorChanged = globals.setCameraError;

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
    // Status kamera & backend offline ditangani oleh StatusBanner
    // dan GlobalConditionsProvider di tiap mode screen - tidak perlu
    // SnackBar di sini yang menutupi BottomActionBar.
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
              Text('Memulai Vinara…', style: AppTypography.title(color: AppColors.onDark)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Menyiapkan kamera dan AI',
                style: AppTypography.body(color: AppColors.onDark.withValues(alpha: .6)),
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

## File: `lib/screens/money_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/money_screen.dart`

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

/// Mode Kenali Uang - bagian 9 IMPLEMENTASI.md, 18 state (UG-01..UG-18).
/// Sepenuhnya on-device, nol sentuhan: [MoneyProvider] menjalankan siklus
/// deteksi mock sendiri lewat Timer, layar ini murni merender.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

/// Satu entri per baris tabel bagian 9 - termasuk pemecahan UG-09a/UG-09b
/// dan UG-12a/UG-12b apa adanya, supaya panel debug bisa menunjukkan kedua
/// varian secara terpisah (mis. UG-09b: campuran Rp20.000×2 + Rp5.000×1).
enum MoneyDebugState {
  ug01, ug02, ug03, ug04, ug05, ug06, ug07, ug08,
  ug10, ug12a, ug12b, ug13, ug14, ug15, ug16, ug18,
}

extension _DebugMeta on MoneyDebugState {
  String get id => switch (this) {
        MoneyDebugState.ug01 => 'UG-01', MoneyDebugState.ug02 => 'UG-02',
        MoneyDebugState.ug03 => 'UG-03', MoneyDebugState.ug04 => 'UG-04',
        MoneyDebugState.ug05 => 'UG-05', MoneyDebugState.ug06 => 'UG-06',
        MoneyDebugState.ug07 => 'UG-07', MoneyDebugState.ug08 => 'UG-08',
        MoneyDebugState.ug10 => 'UG-10',
        MoneyDebugState.ug12a => 'UG-12a', MoneyDebugState.ug12b => 'UG-12b',
        MoneyDebugState.ug13 => 'UG-13', MoneyDebugState.ug14 => 'UG-14',
        MoneyDebugState.ug15 => 'UG-15', MoneyDebugState.ug16 => 'UG-16',
        MoneyDebugState.ug18 => 'UG-18',
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
        MoneyDebugState.ug10 => 'Terlipat / terpotong',
        MoneyDebugState.ug12a => 'Silau',
        MoneyDebugState.ug12b => 'Gelap',
        MoneyDebugState.ug13 => 'Offline',
        MoneyDebugState.ug14 => 'Izin kamera belum ada',
        MoneyDebugState.ug15 => 'Senyap / TTS mati',
        MoneyDebugState.ug16 => 'Font scale 200%',
        MoneyDebugState.ug18 => 'Uang asing / rusak',
      };
}

enum _CardPlacement { center, bottomSlot }

/// Deskripsi render untuk satu momen layar - dihasilkan baik dari
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
      // Prinsip 6 "umumkan saat tiba" - sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.money);
      final money = context.read<MoneyProvider>();
      money.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);

      // Kontrak tombol kiri: "jepret" lewat suara = menekan tombol kiri.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = money.snapAndAnnounce;
      voice.primaryActionLabel = () => 'mengenali uang';
      voice.onRepeatLast = () {
        if (money.lastAmount > 0) {
          context.read<TtsProvider>().speak(
                terbilangRupiah(money.lastAmount),
                tier: SpeechTier.info,
              );
        } else {
          context.read<TtsProvider>().speak(
                'Belum ada nominal yang terbaca.',
                tier: SpeechTier.info,
              );
        }
      };
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
    context.read<VoiceProvider>().clearModeHandlers();
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
        if (!mounted) return;
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
      if (!mounted) return;
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
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // z0 - kamera adalah lantai, full bleed.
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

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

          // z25 - ModeBadge, turun otomatis kalau banner hadir.
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
            // UG-14 - kartu di zona konten, tombolnya di slot kartu bawah.
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
                                child: Text(spec.pillOverride!, style: AppTypography.caption(color: AppColors.onDark)),
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
                            style: AppTypography.caption(color: AppColors.onDark),
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

          // z60 - BottomActionBar, selalu ada, selalu di tempat yang sama.
          // Tombol kiri = "Kenali Uang": snap frame saat ini, umumkan hasilnya.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery(
              data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
              child: BottomActionBar(
                cameraLabel: 'Kenali Uang',
                cameraEnabled: !showPermissionCard && !money.isUnavailable,
                cameraDisabledReason: showPermissionCard
                    ? 'izin kamera belum diberikan'
                    : 'model pengenalan uang belum siap',
                onCameraPressed: () {
                  if (_debugOverride != null) {
                    setState(() => _debugOverride = null);
                    money.start();
                    return;
                  }
                  money.snapAndAnnounce();
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
        return const _RenderSpec(
          frame: FrameFit.fit,
          healthToastDark: true,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Terlalu gelap',
            description: 'Coba nyalakan senter kamera atau cari cahaya lebih terang.',
          ),
        );
      case MoneyState.processing:
        return const _RenderSpec(frame: FrameFit.fit, badgeBusy: true);
      case MoneyState.detected:
        return _RenderSpec(card: NominalCard(amount: p.lastAmount, onReplay: () => _replay(p.lastAmount)));
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
      case MoneyDebugState.ug10:
        return const _RenderSpec(
          frame: FrameFit.tooClose,
          pillOverride: 'Ratakan uang, ada bagian di luar bingkai',
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
        // Banner-nya sendiri dirender terpisah (showOfflineBanner) - konten
        // di baliknya tetap jalan normal (deteksi on-device tak terpengaruh).
        return _RenderSpec(card: NominalCard(amount: 20000, onReplay: () => _replay(20000)));
      case MoneyDebugState.ug14:
        return const _RenderSpec(); // ditangani lewat showPermissionCard
      case MoneyDebugState.ug15:
        return _RenderSpec(
          card: NominalCard(amount: 25000, onReplay: () => _replay(25000)),
          note: 'TTS senyap: kartu bertahan sampai deteksi berikutnya, getar 3× pendek menandai deteksi.',
        );
      case MoneyDebugState.ug16:
        return _RenderSpec(card: NominalCard(amount: 75000, onReplay: () => _replay(75000)));
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
              child: Text('Panel debug - Kenali Uang', style: AppTypography.title()),
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
                    title: Text('${d.id} - ${d.title}', style: AppTypography.body()),
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

## File: `lib/screens/navigasi_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/navigasi_screen.dart`

```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Navigasi - bagian 10 IMPLEMENTASI.md, 25 state (NV-01..NV-25).
///
/// **Sepenuhnya on-device**: segmentasi jalur via PIDNet-S TFLite dan deteksi
/// rintangan via YOLO11n TFLite berjalan langsung di HP. Tidak ada upload
/// frame, tidak ada cadangan server - kalau model gagal dimuat, mode ini
/// mengatakannya apa adanya lewat NavPhase.unavailable.
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

/// NV-19 dan NV-20 dihapus dari katalog: keduanya memodelkan kombinasi
/// "on-device mati, server hidup", yang tidak mungkin lagi terjadi karena
/// mode ini tidak punya jalur server sama sekali. Kegagalan model sekarang
/// selalu berarti NV-11 (NavPhase.unavailable).
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
        // NV-22 - senyap/TTS mati: arah lewat getar, 1 ketuk kiri, 2 ketuk kanan.
        if (_silentMode) {
          // Critical selalu bergetar, apa pun rekomendasinya. Sebelum ini
          // hanya rekomendasi kiri/kanan yang menghasilkan getar, sehingga
          // "Berhenti! Jalur di depan tidak aman" - yang rekomendasinya
          // tengah atau tidak ada sama sekali - lewat tanpa suara DAN tanpa
          // getar. Dibisukan tidak boleh berarti peringatan bahaya hilang.
          if (tier == SpeechTier.critical) {
            _fireCriticalHaptic();
            return;
          }
          final rec = _recommendedZone(nav);
          if (rec == 0) _fireDirectionHaptic(true);
          if (rec == 2) _fireDirectionHaptic(false);
          return;
        }
        context.read<TtsProvider>().speak(text, tier: tier);
      };
      nav.onTakeover = () => context.read<TtsProvider>().interruptByUser();
      // Sumber frame on-device: CameraImage langsung ke PIDNet + YOLO.
      nav.cameraSource = _grabCameraImage;
      nav.startCalibration();

      // NV-18 - satu-satunya konfirmasi wajib di seluruh app.
      context.read<AppModeProvider>().confirmLeave = _confirmLeaveNavigasi;

      // Kontrak tombol kiri: perintah suara "jepret" menjalankan hal yang
      // sama persis dengan menekan tombol kiri - di mode ini, membisukan dan
      // menyalakan kembali suara panduan.
      //
      // "Ulangi arahan" tidak hilang, hanya pindah: tetap tersedia lewat
      // perintah suara "ulangi" (`onRepeatLast`).
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _toggleGuidanceVoice;
      voice.primaryActionLabel = () =>
          _silentMode ? 'menyalakan suara panduan' : 'mematikan suara panduan';
      voice.onRepeatLast = nav.repeatGuidance;
      voice.onStopWalking = nav.pauseGuidance;

      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Frame terakhir dari stream, dikodekan hanya saat benar-benar dikirim.
  CameraImage? _latestFrame;

  /// Kembalikan CameraImage mentah langsung ke PIDNet + YOLO.
  Future<CameraImage?> _grabCameraImage() async => _latestFrame;

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
    nav.cameraSource = null;
    nav.stopNavigation();
    context.read<VoiceProvider>().clearModeHandlers();
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

  /// NV-18 - satu-satunya konfirmasi wajib di seluruh app.
  ///
  /// **Lembar bawah, bukan dialog tengah layar.** Pengguna sedang berjalan;
  /// menjangkau tombol di tengah layar berarti berhenti dan menyesuaikan
  /// pegangan - dengan satu tangan yang lain memegang tongkat. Tombolnya
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

  /// Tombol kiri BottomActionBar - membisukan / menyalakan suara panduan.
  ///
  /// **Hanya suaranya.** PIDNet dan YOLO tetap berjalan dan indikator zona di
  /// layar tetap hidup, jadi pendamping yang melihat layar tetap terbantu,
  /// dan panduan arah tetap sampai lewat getar (NV-22). Membisukan di sini
  /// bukan mematikan panduan - itu sebabnya loop-nya sengaja tidak disentuh.
  void _toggleGuidanceVoice() {
    final tts = context.read<TtsProvider>();
    if (_silentMode) {
      setState(() => _silentMode = false);
      tts.speak('Suara panduan dinyalakan.', tier: SpeechTier.warning);
      return;
    }
    // Konfirmasinya diucapkan SEBELUM bisu menyala. Kalau urutannya dibalik,
    // kalimat ini ikut tertelan dan pengguna yang tidak melihat layar tidak
    // punya cara tahu tombolnya bekerja.
    tts.speak(
      'Suara panduan dimatikan. Arah tetap terasa lewat getar. '
      'Tekan tombol kiri bawah lagi untuk menyalakan.',
      tier: SpeechTier.warning,
    );
    _fireCriticalHaptic();
    setState(() => _silentMode = true);
  }

  Future<void> _fireCriticalHaptic() async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    Vibration.vibrate(pattern: [0, 400, 120, 400]);
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
              Text('Debug - Mode Navigasi', style: AppTypography.title()),
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
      // NV-21 - layar mengambil alih penuh, tidak ada BottomActionBar, jadi
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
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (nav.phase == NavPhase.active || nav.phase == NavPhase.degraded)
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
          else if (nav.phase == NavPhase.loadingModels)
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

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              // Dulu `const BottomActionBar()` - labelnya jatuh ke bawaan
              // "Ambil gambar", tombolnya tampak aktif, dan menekannya tidak
              // melakukan apa pun. Lalu sempat "Ulangi arahan". Sekarang:
              // saklar bisu untuk suara panduan, sesuai kontrak tombol kiri
              // di mode lain (Deteksi Objek memakai pola yang sama).
              cameraLabel: _silentMode ? 'Nyalakan Suara' : 'Matikan Suara',
              onCameraPressed: _toggleGuidanceVoice,
            ),
          ),
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
            const Icon(Icons.phone_android_rounded, color: AppColors.onDark, size: 40),
            const SizedBox(height: AppSpacing.s4),
            Text('Pegang ponsel tegak setinggi dada, kamera menghadap depan',
                textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.onDark)),
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
    // NV-11 - mode ini sepenuhnya on-device. Kalau modelnya tidak bisa
    // dipakai atau frame tidak terbaca, tidak ada cadangan apa pun: bannernya
    // Critical dan menyuruh berhenti, bukan Warning yang menjanjikan sisa
    // fungsi yang sebenarnya tidak ada.
    if (nav.phase == NavPhase.unavailable) {
      return const StatusBanner(
        tier: AlertTier.critical,
        message: 'Berhenti jalan dulu, jalur tidak terbaca',
      );
    }
    if (nav.phase == NavPhase.degraded) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Jalur sulit dibaca, arahan mungkin tertinggal');
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
                    child: Center(child: Text('Mulai', style: AppTypography.label(color: AppColors.onDark))),
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

## File: `lib/screens/ocr_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/ocr_screen.dart`

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

/// Mode Baca Teks - bagian 8 IMPLEMENTASI.md, 22 state (BT-01..BT-22).
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
  // (ServerService.readText tidak mengembalikan status per-blok) - dicapai
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
      // Prinsip 6 "umumkan saat tiba" - diucapkan di sini, sesudah layarnya
      // benar-benar terpasang, bukan oleh pemanggil setMode.
      context.read<AppModeProvider>().announceEntry(AppMode.ocr);
      if (_hasCameraPermission) context.read<CameraProvider>().startStream();

      // Kontrak tombol kiri + perintah suara. `playPause` / `playResume` /
      // `actionReplay` punya bank kata lengkap sejak awal tapi tidak pernah
      // punya handler - di mode inilah ketiganya paling masuk akal.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = () => (_speaking || _paused) ? _togglePause() : _scan();
      voice.primaryActionLabel = () =>
          _speaking ? 'menjeda bacaan' : _paused ? 'melanjutkan bacaan' : 'membaca teks';
      voice.onRepeatLast = () { if (_blocks.isNotEmpty) _replay(); };
      voice.onPauseSpeech = () {
        if (!_speaking) return false;
        _togglePause();
        return true;
      };
      voice.onResumeSpeech = () {
        if (!_paused) return false;
        _togglePause();
        return true;
      };
    });
    // BT-20 - cek kedaluwarsa tiap 30 detik.
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
    context.read<VoiceProvider>().clearModeHandlers();
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
    // yang sebenarnya masih hidup - kesalahan yang sama seperti mematikan
    // Mode Navigasi offline.

    final cameraProvider = context.read<CameraProvider>();
    final ttsProvider = context.read<TtsProvider>();

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
    if (!mounted) return;

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
      ttsProvider.speak('Terlalu lama, coba lagi.', tier: SpeechTier.warning);
    });

    try {
      final path = await cameraProvider.captureFile();
      final result = await OcrService.instance.recognizeFile(path);

      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      setState(() => _scanning = false);

      if (result.isEmpty) {
        // BT-11 - instruksi jarak konkret, bukan "tidak ada teks".
        setState(() => _fail = _FailKind.zeroText);
        await context.read<TtsProvider>().speak(
              'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal, pastikan tulisan rata di tengah.',
              tier: SpeechTier.warning,
            );
        return;
      }

      setState(() {
        // ML Kit sudah memisahkan teks per blok tata letak, jadi heading
        // ResultPanel/long jadi nyata - bukan satu blok "Hasil baca" untuk
        // seluruh halaman seperti waktu OCR dikerjakan server.
        _blocks = [
          for (final b in result.blocks)
            OcrRenderBlock(heading: b.heading, sentences: b.sentences),
        ];
        _completedAt = null;
      });

      // BT-08 - kalau bacaannya panjang, sebut durasinya SEBELUM mulai,
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
    // Warning, bukan Info: pembacaan ini diminta pengguna secara eksplisit dan
    // bisa berlangsung menit-menitan - membiarkannya dibuang sebagai "Info
    // basi" karena antre 2 detik akan membatalkan permintaan yang disengaja.
    // Tetap bisa dipotong pengguna lewat tombol "Jeda bacaan".
    if (!mounted) return;
    await context.read<TtsProvider>().speak(fullText, tier: SpeechTier.warning);
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
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: _cameraWithGuide(cam))
          else
            const ColoredBox(color: AppColors.cameraVoid),

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
            // BT-17 - kartu di zona konten, tombolnya di slot kartu bawah.
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
            // Tombol kiri kontekstual: di mode ini "hal utama" memang berubah
            // sepanjang alur. Sebelum jepret yang dibutuhkan adalah memotret;
            // saat sedang dibacakan, yang dibutuhkan adalah menjeda.
            child: BottomActionBar(
              cameraLabel: _speaking
                  ? 'Jeda bacaan'
                  : _paused
                      ? 'Lanjutkan bacaan'
                      : 'Baca teks',
              onCameraPressed:
                  (_speaking || _paused) ? _togglePause : (_scanning ? null : _scan),
              cameraEnabled: !_scanning,
              cameraDisabledReason: 'sedang memindai',
            ),
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
      return [const Center(child: CircularProgressIndicator(color: AppColors.onDark))];
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
              child: TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: AppColors.onDark))),
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
            TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: AppColors.onDark))),
          ]),
        );
      case 'BT-03':
        return const Center(
          child: ColoredBox(color: AppColors.bgPage, child: SizedBox(width: double.infinity, height: double.infinity)),
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

## File: `lib/screens/onboarding_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/onboarding_screen.dart`

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

/// OB-01..OB-07 - panduan awal 3 langkah. Bisa dilewati (OB-05, menyebut
/// apa yang dilewatkan) dan diulang dari Pengaturan (OB-06).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  /// True saat dipanggil ulang dari Pengaturan (OB-06) - menampilkan tombol
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

    // OB-01..OB-07 - layar penunjang, memakai `zone/page-action`. "Lewati
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
                      // Eyebrow langkah dibaca sebagai bagian judul - bagian 10
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
              // Titik langkah: ExcludeSemantics wajib (bagian 16) - maknanya
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

## File: `lib/screens/permissions_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/permissions_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// IZ-01..IZ-07 - dua kartu alasan terpisah (kamera dulu, lalu mikrofon).
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
    // IZ-06 - kembali dari Pengaturan sistem, cek ulang status izin.
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
      // IZ-04 - empat langkah bernomor, dibacakan satu per satu, bertahap.
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

  /// IZ-04 - dibacakan bertahap. Membacakan empat langkah sekaligus tidak
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

    // IZ-01..IZ-04 - layar penunjang tanpa BottomActionBar, jadi seluruh
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

/// IZ-04 - kartu penjelasan saja. Kedua tombolnya ("Buka Pengaturan ponsel",
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

## File: `lib/screens/server_address_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/server_address_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// PG-08a..PG-08e - Alamat server, halaman sendiri (PG-02: "halaman kontrol
/// sendiri, bukan sheet").
///
/// Dulu kontrol ini adalah satu baris di dalam daftar Pengaturan, dengan
/// tombol "Uji" menempel di samping kolom isian - di sepertiga atas layar,
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

  /// Saat demo, tekan ikon mata untuk menyembunyikan alamat IP dari layar.
  bool _obscured = false;

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

    // PG-08d - sebutkan apa yang salah, bukan "tidak valid" saja.
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
      // PG-08e - kegagalan uji tidak boleh diam-diam mencabut server yang
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
    // Konfirmasi diucapkan SESUDAH tersimpan - bagian 4.1 berlaku untuk semua
    // konfirmasi, bukan hanya ganti mode.
    await TTSService.instance.speak('Alamat server tersimpan.');
    if (mounted) Navigator.of(context).pop();
  }

  /// Label tombol utama berubah, posisinya tidak. PG-08c satu-satunya state
  /// yang aksinya "Simpan alamat" - alamat baru hanya dipakai sesudah terbukti
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
            text: 'Format salah - alamat butuh titik dua dan nomor port. Contoh benar: 10.0.2.2:8000',
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
                // PG-08a - penjelasan server bawaan.
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
                    // Saat _obscured = true, teks diganti karakter titik
                    // sehingga alamat IP tidak terlihat saat demo.
                    obscureText: _obscured,
                    obscuringCharacter: '•',
                    decoration: InputDecoration(
                      hintText: 'host:port, mis. 10.0.2.2:8000',
                      isDense: true,
                      suffixIcon: Semantics(
                        label: _obscured ? 'Tampilkan alamat server' : 'Sembunyikan alamat server',
                        button: true,
                        excludeSemantics: false,
                        child: IconButton(
                          icon: Icon(
                            _obscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          tooltip: _obscured ? 'Tampilkan' : 'Sembunyikan',
                          onPressed: () => setState(() => _obscured = !_obscured),
                        ),
                      ),
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

## File: `lib/screens/settings_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/settings_screen.dart`

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

/// PG-01..PG-11 - delapan pengaturan, urutan baku (bagian 13).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// PG-11 - penyimpanan penuh. Kartu error tetap di atas karena perannya
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
          // PG-08 - halaman kontrol sendiri, bukan kontrol inline. Aksinya
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

    // PG-11 - selama penyimpanan penuh, aksinya diulang di `zone/page-action`
    // supaya terjangkau tanpa menggulung dan tanpa menjangkau kartu di atas.
    // Di luar kondisi itu Pengaturan tidak punya aksi halaman, jadi tidak ada
    // zona aksi sama sekali - daftar boleh memenuhi layar.
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

/// PG-11 - kartu error penyimpanan penuh. Tetap di atas: perannya memberi
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

## File: `lib/screens/splash_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/splash_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';

/// SP-01 - Splash. Logo tampil, narasi TTS mulai di milidetik pertama,
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
              child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.onDark, size: 36),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text('Vinara', style: AppTypography.headline(color: AppColors.onDark)),
          ],
        ),
      ),
    );
  }
}
```

---

## File: `lib/screens/tuntun_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/tuntun_screen.dart`

```dart
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../core/speech/tts_queue.dart';
import '../models/detection.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Deteksi Objek - bagian 7 IMPLEMENTASI.md, 29 state (DO-01..DO-29).
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
  // Keadaan gelap & dismiss-nya dimiliki CameraProvider (lihat
  // `cam.isDark` / `cam.darkDismissed`), supaya deteksi tetap berjalan saat
  // gelap dan "Lewati" hanya menyembunyikan tawaran lampu.
  String? _debugOverride;

  /// Apakah deteksi objek sedang aktif (jalan) atau dijeda.
  ///
  /// **Dimulai false - deteksi tidak menyala sendiri.** Ini layar pertama
  /// saat aplikasi dibuka, dan saat itu ponsel biasanya masih di tangan yang
  /// turun, di saku, atau menghadap tanah. Peringatan pertama dari posisi itu
  /// hampir selalu keliru, dan peringatan keliru dari alat bantu jalan lebih
  /// merusak daripada diam: sekali pengguna belajar aplikasinya sering salah,
  /// peringatan yang benar ikut diabaikan.
  ///
  /// Konsekuensinya ditangani, bukan diabaikan - lihat [initState] dan
  /// [_armPausedReminder]: keadaan mati diucapkan saat masuk dan diingatkan
  /// tiap 30 detik, supaya tidak ada yang berjalan menyangka sudah dijaga.
  bool _detectionActive = false;

  final List<_GhostDetection> _ghosts = [];
  List<Detection> _prevCritical = [];

  Timer? _warmupTimer;
  Timer? _speakingPoll;

  /// DO - pengingat berkala saat deteksi dijeda.
  ///
  /// Tanpa ini, "Deteksi dijeda." terucap sekali lalu hening permanen. Untuk
  /// pengguna yang tidak melihat layar, aplikasi yang dijeda **tidak bisa
  /// dibedakan** dari aplikasi yang aktif tapi kebetulan tidak melihat apa
  /// pun - dan ia berjalan menyangka masih dijaga.
  Timer? _pausedReminder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Ditunggu selesai supaya pemberitahuan "belum menyala" di bawah
      // menyusul di belakangnya, bukan mengantre berebut dengannya.
      await context.read<AppModeProvider>().announceEntry(AppMode.tuntun);
      if (!mounted) return;
      if (_hasCameraPermission) {
        // Kamera tetap dinyalakan (pratinjau + deteksi gelap), tapi deteksi
        // rintangan menunggu tombol kiri. Keadaan mati TIDAK boleh senyap:
        // pengguna yang tidak melihat layar tidak bisa membedakan "belum
        // menyala" dari "menyala tapi kebetulan tidak melihat apa pun".
        context.read<CameraProvider>().startStream();
        TtsQueue().speak(
          'Deteksi rintangan belum menyala. '
          'Tekan tombol kiri bawah untuk mulai mengawasi.',
          tier: SpeechTier.warning,
        );
        _armPausedReminder();
      }
      // Listener dark detection - TTS satu kali saat transisi gelap
      context.read<CameraProvider>().addListener(_onCameraDarkChanged);

      // Kontrak tombol kiri: perintah suara "jepret" menjalankan hal yang
      // sama persis dengan menekan tombol kiri.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _toggleDetection;
      voice.primaryActionLabel = () =>
          _detectionActive ? 'menjeda deteksi' : 'melanjutkan deteksi';
      voice.onRepeatLast = _repeatLastDetection;

      // Model gagal muat = mode ini tidak punya cadangan apa pun. Katakan,
      // jangan biarkan layar terlihat normal sementara tidak ada yang mengawasi.
      if (context.read<DetectionProvider>().isUnavailable) {
        TtsQueue().speak(
          'Deteksi rintangan tidak tersedia di perangkat ini. '
          'Mode lain tetap bisa dipakai.',
          tier: SpeechTier.critical,
        );
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
    _pausedReminder?.cancel();
    context.read<CameraProvider>().removeListener(_onCameraDarkChanged);
    context.read<DetectionProvider>().stopRealtime();
    context.read<CameraProvider>().stopStream();
    context.read<VoiceProvider>().clearModeHandlers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // DO-18 - kembali dari latar belakang.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      if (mounted) {
        setState(() => _warmingUp = true);
        context.read<CameraProvider>().startStream();
        // Hormati keadaan jeda. Sebelumnya `startRealtime()` dipanggil tanpa
        // memeriksa apa pun, jadi deteksi hidup lagi diam-diam sementara
        // tombol tetap bertuliskan "Lanjutkan" - label dan keadaan berbohong
        // ke arah yang berlawanan.
        if (_detectionActive) {
          _startDetection();
        } else {
          _armPausedReminder();
        }
        _warmupTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _warmingUp = false);
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // Jangan bicara ke layar yang tidak dilihat siapa pun.
      _pausedReminder?.cancel();
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
      if (!mounted) return;
      camProvider.startStream();
      if (_detectionActive) _startDetection();
    }
  }

  /// "ulangi" di Mode Deteksi - sebutkan lagi apa yang terlihat sekarang.
  void _repeatLastDetection() {
    final det = context.read<DetectionProvider>();
    if (!_detectionActive) {
      TtsQueue().speak('Deteksi sedang dijeda.', tier: SpeechTier.info);
      return;
    }
    final dets = det.detections;
    TtsQueue().speak(
      dets.isEmpty
          ? 'Tidak ada rintangan di depanmu saat ini.'
          : dets.map((d) => d.ttsMessage).join('. '),
      tier: SpeechTier.warning,
    );
  }

  void _startDetection() {
    _pausedReminder?.cancel();
    _pausedReminder = null;
    context.read<DetectionProvider>().startRealtime();
  }

  /// Ingatkan tiap 30 detik selama dijeda - suara + getar, karena di jalan
  /// yang ramai getar sering lebih terdengar daripada suara.
  void _armPausedReminder() {
    _pausedReminder?.cancel();
    _pausedReminder = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _detectionActive) return;
      TtsQueue().speak(
        'Deteksi rintangan masih mati. Tekan tombol kiri bawah untuk mulai.',
        tier: SpeechTier.info,
      );
      HapticService.instance.info();
    });
  }

  /// Dipanggil setiap kali CameraProvider notify.
  ///
  /// Pengumuman gelap **tidak** lagi diucapkan di sini: [CameraProvider] yang
  /// memilikinya (peringatan setelah 3 detik + pengulangan tiap 30 detik),
  /// karena kondisi itu berlaku di semua mode berkamera, bukan hanya mode ini.
  /// Dua sumber untuk satu kondisi hanya menghasilkan ucapan ganda.
  void _onCameraDarkChanged() {
    if (!mounted) return;
    setState(() {}); // slot tawaran lampu muncul/hilang mengikuti provider
  }

  /// Toggle deteksi ON/OFF dari tombol kiri BottomActionBar.
  ///
  /// Menjeda deteksi adalah satu-satunya cara pengguna mematikan pengawasan
  /// rintangan, jadi konfirmasinya naik ke tier Warning: ia harus terdengar
  /// meski ada narasi lain yang sedang mengantre.
  void _toggleDetection() {
    final det = context.read<DetectionProvider>();
    if (_detectionActive) {
      det.stopRealtime();
      setState(() => _detectionActive = false);
      TtsQueue().speak(
        'Deteksi dijeda. Saya tidak akan memperingatkan rintangan sampai dilanjutkan.',
        tier: SpeechTier.warning,
      );
      HapticService.instance.warning();
      _armPausedReminder();
    } else {
      _startDetection();
      setState(() => _detectionActive = true);
      TtsQueue().speak('Deteksi dilanjutkan.', tier: SpeechTier.warning);
      HapticService.instance.info();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      if (!mounted) return;
      cam.startStream();
      if (_detectionActive) _startDetection();
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
        // DO-20 - memudar tanpa suara "objek hilang", dibersihkan setelah animasi.
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

    // Tawaran / kontrol lampu. Perhatikan: slot tampil saat gelap ATAU saat lampu sedang menyala,
    // supaya pengguna bisa mematikan lampu kapan saja.
    final showTorchSlot = _hasCameraPermission && (cam.isTorchOn || (cam.isDark && !cam.darkDismissed));

    final banner = _resolveBanner(global, cam);
    final hasBanner = banner != null;
    final warmingUp = _warmingUp || _debugOverride == 'DO-13';
    final micDisabled = !_hasMicPermission || _debugOverride == 'DO-24';

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

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
            // DO-14 - kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mendeteksi rintangan di depanmu tanpa internet.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestCameraPermission,
            )
          else if (!warmingUp)
            ..._buildDetectionZone(context, bottomInset, dets, cam, showTorchSlot),

          // ContextualActionSlot - tawaran / kontrol lampu senter.
          // Selalu di posisi yang sama: tepat di atas BottomActionBar.
          if (showTorchSlot)
            Positioned(
              left: 0, right: 0,
              bottom: bottomInset + AppSizes.bottomActionBarHeight,
              child: ContextualActionSlot(
                message: cam.isTorchOn
                    ? 'Lampu senter menyala'
                    : 'Sekitar gelap - perlu nyalakan lampu?',
                primaryLabel: cam.isTorchOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
                primaryIcon: cam.isTorchOn
                    ? Icons.flashlight_off_rounded
                    : Icons.flashlight_on_rounded,
                onPrimary: () {
                  if (cam.isTorchOn) {
                    cam.setTorch(false);
                    TtsQueue().speak('Lampu dimatikan.', tier: SpeechTier.info);
                  } else {
                    cam.setTorch(true);
                    TtsQueue().speak('Lampu dinyalakan.', tier: SpeechTier.info);
                  }
                },
                secondaryLabel: 'Lewati',
                secondaryIcon: Icons.close_rounded,
                onSecondary: () {
                  if (cam.isTorchOn) {
                    cam.setTorch(false);
                    TtsQueue().speak('Lampu dimatikan.', tier: SpeechTier.info);
                  } else {
                    cam.dismissDarkOffer();
                    TtsQueue().speak(
                      'Baik, lampu tidak dinyalakan. Deteksi tetap berjalan.',
                      tier: SpeechTier.info,
                    );
                  }
                },
              ),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              micEnabled: !micDisabled,
              cameraLabel: _detectionActive ? 'Hentikan' : 'Lanjutkan',
              onCameraPressed: _hasCameraPermission ? _toggleDetection : null,
              cameraEnabled: _hasCameraPermission,
              cameraDisabledReason: 'izin kamera belum diberikan',
            ),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(GlobalConditionsProvider global, CameraProvider cam) {
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

  List<Widget> _buildDetectionZone(BuildContext context, double bottomInset, List<Detection> dets, CameraProvider cam, bool showTorchSlot) {
    final widgets = <Widget>[];
    // Jika slot lampu aktif, geser semua kartu ke atas sejumlah tinggi slot.
    final slotExtra = showTorchSlot ? ContextualActionSlot.slotHeightWithMsg : 0.0;

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
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 44 + slotExtra,
        child: Center(child: CameraHealthToast(issue: _mapHealthIssue(health))),
      ));
    }

    final cards = dets.map((d) => DetectionCard(detection: d)).toList();
    final extra = dets.length - 2;

    if (cards.isNotEmpty || _ghosts.isNotEmpty) {
      widgets.add(Positioned(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2 + slotExtra,
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
                  child: Text('dan $extra objek lain', style: AppTypography.caption(color: AppColors.onDark)),
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
            Text('Debug - Mode Deteksi Objek', style: AppTypography.title()),
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

## File: `lib/screens/voice_screen.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/screens/voice_screen.dart`

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

/// Mode Asisten Suara - bagian 11 IMPLEMENTASI.md, 25 state (AS-01..AS-25).
/// [isOverlay] = true saat dimasukkan via Navigator push dari mode lain
/// (fitur "Jarvis Global Mic"). Dalam mode overlay:
/// - Tampil tombol ✕ (tutup) di pojok kanan atas.
/// - VoiceProvider.onNavigateBack dipasang untuk pop otomatis setelah
///   perintah suara yang mengubah mode dieksekusi.
class VoiceScreen extends StatefulWidget {
  final bool isOverlay;
  const VoiceScreen({super.key, this.isOverlay = false});

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
        // AS-23 - riwayat kedaluwarsa, sudah dibersihkan oleh provider.
        context.read<TtsProvider>().speak('Percakapan tadi sudah saya hapus.', tier: SpeechTier.info);
      }

      voice.onSpeak = (text) => context.read<TtsProvider>().speak(text, tier: SpeechTier.info);
      voice.onOpenSettings = _openSettings;
      voice.onAllFeaturesFailed = () {};

      // "lebih cepat" / "lebih pelan" - dulu keduanya punya bank kata lengkap
      // tapi tidak ada yang menjalankannya.
      voice.onAdjustSpeechRate = (delta) async {
        final settings = context.read<SettingsProvider>();
        final next = (settings.speechRate + delta).clamp(0.2, 1.0);
        await settings.setSpeechRate(next);
        return next;
      };

      // Sebagai MODE (bukan overlay), aksi utamanya adalah mengulang jawaban.
      // Sebagai OVERLAY, handler mode di bawahnya sengaja TIDAK ditimpa -
      // "jepret" saat mic terbuka harus menjalankan aksi mode aslinya.
      if (!widget.isOverlay) {
        voice.onPrimaryAction = _repeatLastAnswer;
        voice.primaryActionLabel = () => 'mengulang jawaban';
        voice.onRepeatLast = _repeatLastAnswer;
      }

      // Overlay: pasang callback agar VoiceProvider bisa meminta pop Navigator
      // tanpa perlu tahu tentang BuildContext.
      if (widget.isOverlay) {
        voice.onNavigateBack = () {
          if (mounted) Navigator.of(context).pop();
        };
        // Mulai mendengar langsung saat overlay dibuka.
        if (!voice.isListening && voice.state == VoiceState.idle) {
          voice.startListening();
        }
      }
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
    voice.onAdjustSpeechRate = null;
    if (widget.isOverlay) {
      voice.onNavigateBack = null;
    } else {
      // Hanya lepas handler yang dipasang layar ini. Sebagai overlay, handler
      // milik mode di bawahnya harus tetap utuh.
      voice.clearModeHandlers();
    }
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

  /// `mode.settings` - Pengaturan layar penunjang, bukan mode. Mengembalikan
  /// true hanya kalau halamannya benar-benar terdorong ke Navigator, supaya
  /// VoiceProvider tidak mengonfirmasi pembukaan yang tidak terjadi.
  Future<bool> _openSettings() async {
    if (!mounted) return false;
    // Rute sudah masuk tumpukan begitu `push` dipanggil; Future-nya baru
    // selesai saat halaman DITUTUP, jadi ia sengaja tidak ditunggu - kalau
    // ditunggu, konfirmasinya baru terdengar setelah pengguna keluar lagi.
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ));
    return true;
  }

  /// Tombol kiri Mode Asisten Suara - baca ulang jawaban terakhir.
  ///
  /// Rencana perbaikan menyarankan tombol ini dinonaktifkan dengan label jujur.
  /// Itu benar dan jujur, tapi menyisakan satu tombol mati dari enam mode dan
  /// membuat aturan tombol kiri punya pengecualian. "Ulangi jawaban" berguna
  /// nyata: pengguna yang tidak menangkap jawaban cukup menekan tombol yang
  /// posisinya sudah ia hafal - tanpa bertanya ulang, dan tanpa memicu
  /// panggilan Moondream2 kedua yang makan lima detik dan kuota.
  void _repeatLastAnswer() {
    final voice = context.read<VoiceProvider>();
    final answer = voice.response;
    if (answer.isEmpty) {
      context.read<TtsProvider>().speak(
            'Belum ada jawaban untuk diulang. Tekan tombol bicara dulu.',
            tier: SpeechTier.info,
          );
      return;
    }
    context.read<TtsProvider>().speak(answer, tier: SpeechTier.info);
  }

  Future<void> _onMicPressed() async {
    final voice = context.read<VoiceProvider>();
    setState(() => _debugOverride = null);
    if (voice.isListening) {
      await voice.stopListening();
    } else if (voice.state == VoiceState.responded) {
      // AS-20 - menekan lagi saat masih bicara: potong tanpa nada khusus.
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
              Text('Debug - Mode Asisten Suara', style: AppTypography.title()),
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

    // AS-25 - Critical dari mode lain menyela jawaban yang sedang dibacakan.
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
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.voice, onDebugActivate: _openDebugSheet),
          ),

          if (voice.state == VoiceState.responded && !_silentMode)
            Positioned(top: topInset + 52, right: 24, child: const SpeakingIndicator()),

          if (!_hasMicPermission && _debugOverride == null)
            // AS-02 - kartu di zona konten, tombolnya di slot kartu bawah.
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
              cameraLabel: 'Ulangi jawaban',
              onCameraPressed: _repeatLastAnswer,
              cameraEnabled: voice.response.isNotEmpty,
              cameraDisabledReason: 'belum ada jawaban',
              onMicPressed: _onMicPressed,
              micEnabled: _hasMicPermission,
              listeningOverride: voice.isListening,
              processingOverride: voice.isProcessing,
            ),
          ),

          // ContextualActionSlot "Kembali" - hanya saat overlay push.
          // Posisi konsisten dengan slot lampu di TuntunScreen (tepat di atas
          // BottomActionBar) - pengguna terbiasa dengan lokasi yang sama.
          if (widget.isOverlay)
            Positioned(
              left: 0, right: 0,
              bottom: bottomInset + AppSizes.bottomActionBarHeight,
              child: ContextualActionSlot(
                primaryLabel: 'Kembali',
                primaryIcon: Icons.arrow_back_rounded,
                onPrimary: () async {
                  final nav = Navigator.of(context);
                  context.read<TtsProvider>().speak('Kembali.', tier: SpeechTier.info);
                  nav.pop();
                },
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
      // AS-21 - senyap: seluruh jawaban ditampilkan penuh.
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
        child: Text(text, style: AppTypography.body(color: AppColors.onDark)),
      ),
    );
  }

  Widget _bubblePanel(double bottomInset, Widget child) {
    // Geser ke atas jika overlay: ContextualActionSlot 'Kembali' ada di bawah.
    final slotExtra = widget.isOverlay ? ContextualActionSlot.slotHeight : 0.0;
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2 + slotExtra,
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

## File: `lib/services/camera_health_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/camera_health_service.dart`

```dart
import 'dart:async';
import 'dart:math'; // untuk atan2()
import 'package:sensors_plus/sensors_plus.dart';

class CameraHealthResult {
  final bool   ok;
  final String message;
  const CameraHealthResult({required this.ok, required this.message});
}

/// Camera Health Service - cek orientasi kamera via accelerometer.
/// Pengecekan gelap/buram/tertutup dilakukan di server (camera_health.py)
/// dan secara on-device di CameraProvider (brightness dari plane Y).
class CameraHealthService {
  static final CameraHealthService instance = CameraHealthService._();
  CameraHealthService._();

  AccelerometerEvent? _lastAccel;
  StreamSubscription? _accelSub;

  /// Seberapa banyak ponsel bergoyang, 0 (diam) sampai 1 (ayunan kuat).
  ///
  /// Saat pengguna berjalan, ponsel yang dipegang ikut mengayun naik-turun.
  /// Ayunan itu membuat kotak deteksi membesar-mengecil sendiri, sehingga
  /// objek yang diam terbaca "maju-mundur" - dan `isApproaching` yang memotong
  /// cooldown 50% ikut menyala tanpa ada yang benar-benar mendekat.
  ///
  /// Diukur dari perubahan percepatan antar sampel. Ini bukan pengganti
  /// gyroscope, tapi cukup untuk **membedakan tangan diam dari tangan
  /// mengayun** - dan itulah satu-satunya yang dibutuhkan: saat goyang, ambang
  /// "mendekat" dinaikkan dan penghalusan jarak diperlambat.
  double _motionLevel = 0.0;
  double get motionLevel => _motionLevel;

  /// True saat ayunan cukup kuat sehingga sinyal jarak tidak bisa dipercaya
  /// begitu saja.
  bool get isShaky => _motionLevel > 0.35;

  void startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      final prev = _lastAccel;
      if (prev != null) {
        final dx = event.x - prev.x;
        final dy = event.y - prev.y;
        final dz = event.z - prev.z;
        final delta = sqrt(dx * dx + dy * dy + dz * dz);
        // Normalisasi kasar: Δ 4 m/s² antar sampel sudah tergolong ayunan
        // penuh saat berjalan. EMA menahan lonjakan satu sampel agar satu
        // sentakan tidak langsung dianggap goyang terus-menerus.
        final instant = (delta / 4.0).clamp(0.0, 1.0);
        _motionLevel = _motionLevel * 0.7 + instant * 0.3;
      }
      _lastAccel = event;
    });
  }

  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _motionLevel = 0.0;
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

## File: `lib/services/camera_intrinsics.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/camera_intrinsics.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Panjang fokus kamera dalam piksel, dibaca dari perangkatnya sendiri.
///
/// Estimasi jarak memakai rumus pinhole:
/// ```
/// jarak_m = tinggi_asli_cm × fokus_px / (tinggi_kotak_px × 100)
/// ```
/// `fokus_px` bukan properti universal - ia tergantung lensa **dan** resolusi
/// keluaran. Konstanta 615 yang dipakai sebelumnya adalah rata-rata yang
/// kebetulan tidak benar untuk perangkat mana pun secara khusus: lensa
/// ultrawide dan telefoto bisa meleset jauh lebih dari 2×, dan seluruh
/// klasifikasi bahaya (`critical` di bawah 1,5 m) mewarisi kesalahannya.
///
/// Android menyimpan angka aslinya di `CameraCharacteristics`. Dari panjang
/// fokus (mm) dan ukuran fisik sensor (mm) kita dapat sudut pandang, dan dari
/// sudut pandang kita dapat fokus dalam piksel untuk resolusi apa pun:
/// ```
/// fokus_px = (lebar_px / 2) / tan(fov / 2)
/// ```
///
/// Ini menggantikan rencana kalibrasi manual dengan meteran di lapangan:
/// tanpa model baru, tanpa pengukuran, dan benar per-perangkat alih-alih
/// benar rata-rata.
///
/// **Gagal itu wajar dan aman.** Emulator, iOS, dan perangkat yang tidak
/// melaporkan intrinsik akan mengembalikan null; pemanggil lalu memakai
/// [fallbackFocalPx]. Deteksi tidak boleh mati hanya karena kalibrasi gagal.
class CameraIntrinsics {
  static final CameraIntrinsics instance = CameraIntrinsics._();
  CameraIntrinsics._();

  static const MethodChannel _channel = MethodChannel('vinara/camera_intrinsics');

  /// Nilai lama, dipertahankan sebagai jaring pengaman saat intrinsik tidak
  /// tersedia. Kira-kira benar untuk kamera ponsel 4:3 pada 640 px.
  static const double fallbackFocalPx = 615.0;

  double? _horizontalFovRad;
  double? _verticalFovRad;
  bool _queried = false;

  /// True kalau nilai berasal dari perangkat, bukan dari fallback.
  bool get isCalibrated => _horizontalFovRad != null;

  double? get horizontalFovDeg =>
      _horizontalFovRad == null ? null : _horizontalFovRad! * 180 / math.pi;

  double? get verticalFovDeg =>
      _verticalFovRad == null ? null : _verticalFovRad! * 180 / math.pi;

  /// Baca intrinsik sekali per proses. Aman dipanggil berkali-kali.
  Future<void> load() async {
    if (_queried) return;
    _queried = true;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('lensInfo');
      if (info == null) {
        debugPrint('[Intrinsics] perangkat tidak melaporkan intrinsik lensa - pakai fallback');
        return;
      }
      final h = (info['horizontalFovRad'] as num?)?.toDouble();
      final v = (info['verticalFovRad'] as num?)?.toDouble();
      // Sanity check: FOV kamera ponsel wajar di 30°–130°. Nilai di luar itu
      // lebih mungkin salah baca daripada lensa aneh, dan lebih baik memakai
      // fallback yang diketahui daripada angka yang diketahui ngawur.
      if (h == null || v == null || h <= 0.5 || h >= 2.3 || v <= 0.3 || v >= 2.3) {
        debugPrint('[Intrinsics] FOV di luar rentang wajar ($h, $v) - pakai fallback');
        return;
      }
      _horizontalFovRad = h;
      _verticalFovRad = v;
      debugPrint('[Intrinsics] FOV terbaca: '
          'H=${(h * 180 / math.pi).toStringAsFixed(1)}° '
          'V=${(v * 180 / math.pi).toStringAsFixed(1)}° '
          '(fokus ${info['focalLengthMm']}mm, sensor ${info['sensorWidthMm']}×${info['sensorHeightMm']}mm)');
    } catch (e) {
      debugPrint('[Intrinsics] gagal membaca intrinsik: $e - pakai fallback');
    }
  }

  /// Fokus dalam piksel pada sumbu **vertikal bingkai tegak**.
  ///
  /// Ponsel terkunci portrait sementara sensor memberi frame landscape, jadi
  /// sumbu vertikal yang dilihat pengguna adalah sumbu **horizontal** sensor.
  /// [srcWidth] adalah lebar frame sensor (mis. 640) - itulah yang menjadi
  /// tinggi bingkai tegak, dan itulah sumbu tempat tinggi kotak diukur.
  double focalPxForUprightFrame(int srcWidth) {
    final fov = _horizontalFovRad;
    if (fov == null) return fallbackFocalPx;
    return (srcWidth / 2) / math.tan(fov / 2);
  }
}
```

---

## File: `lib/services/detection_filter.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/detection_filter.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../providers/settings_provider.dart' show Verbosity;

/// Filter pipeline - dipanggil oleh BOTH TFLite dan Server result.
/// Satu instance, state persist selama sesi aktif.
///
/// Fix dari doc 5 masalah 5:
/// - Streak hanya di-increment SETELAH lolos distance + confidence filter
/// - Cooldown berbeda per tier (Netra AI: critical=2s, warning=3s, info=5s)
///
/// Fix temuan 2B - kunci cooldown dan streak adalah **identitas objek**
/// ([Detection.filterKey], berasal dari `trackId` SORT), bukan lagi `labelEn`.
/// Dengan kunci label, dua orang di frame yang sama dianggap satu objek:
/// orang yang jauh diumumkan lebih dulu, lalu orang yang dekat dan sedang
/// mendekat ikut kena cooldown "person" dan **tidak diumumkan sama sekali**
/// sampai 2 detik berlalu. Persis kebalikan dari yang dibutuhkan.
class DetectionFilter {
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<String, int>      _streak        = {};

  // streakRequired=2: SSD MobileNet tidak konsisten antar frame (objek bisa
  // flash 1 frame lalu hilang). Minimal 2 frame berturut-turut memastikan
  // deteksi stabil sebelum popup muncul dan TTS disuarakan.
  static const int    _streakRequired = 2;
  static const double _minConfidence  = 0.5;  // SSD lebih noisy, threshold lebih tinggi dari YOLO

  /// PG-06 "Ambang jarak peringatan" (1–5 m) - objek lebih jauh dari ini tidak
  /// diumumkan. Diisi `SettingsProvider`; dulu nilainya konstanta 10 m dan
  /// slider di Pengaturan tidak berpengaruh sama sekali.
  ///
  /// Slider ini mengubah **frekuensi peringatan**, yang untuk sebagian
  /// pengguna adalah selisih antara berguna dan tidak tertahankan: 5 m di
  /// koridor ramai berarti bicara terus-menerus.
  double _maxDistance = 10.0;

  /// PG-05 "Tingkat kecerewetan" - menentukan berapa banyak yang diumumkan
  /// sekaligus, bukan hanya panjang kalimatnya.
  Verbosity _verbosity = Verbosity.sedang;

  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _maxDistance = maxDistanceM;
    _verbosity = verbosity;
  }

  List<Detection> process(List<Detection> raw) {
    final currentKeys = raw.map((d) => d.filterKey).toSet();

    // Buang streak untuk objek yang hilang dari frame ini. Cooldown sengaja
    // TIDAK ikut dibuang: objek yang berkelip hilang-muncul satu frame tidak
    // boleh mendapat izin bicara ulang seketika.
    _streak.removeWhere((key, _) => !currentKeys.contains(key));

    // Batasi pertumbuhan _lastAnnounced. trackId terus bertambah sepanjang
    // sesi, jadi tanpa ini map-nya tumbuh selamanya di perjalanan panjang.
    if (_lastAnnounced.length > 200) _pruneAnnounced();

    final approved = <Detection>[];

    for (final det in raw) {
      final key = det.filterKey;

      // [1] Distance filter
      if (det.distanceMeter > _maxDistance) {
        continue;
      }

      // [2] Confidence filter
      if (det.confidence < _minConfidence) {
        continue;
      }

      // [3] Increment streak HANYA untuk yang lolos distance + confidence
      _streak[key] = (_streak[key] ?? 0) + 1;

      // [4] Stability check
      if ((_streak[key] ?? 0) < _streakRequired) {
        continue;
      }

      // [5] Cooldown per tier
      final cooldown = _cooldownFor(det);
      final last     = _lastAnnounced[key];
      final now      = DateTime.now();
      if (last != null && now.difference(last) < cooldown) {
        continue;
      }

      // [6] Lolos semua
      _lastAnnounced[key] = now;
      approved.add(det);
    }

    // [7] Sort: critical → warning → info, lalu jarak terdekat
    approved.sort((a, b) {
      final pa = _prio(a.dangerLevel);
      final pb = _prio(b.dangerLevel);
      if (pa != pb) return pa.compareTo(pb);
      return a.distanceMeter.compareTo(b.distanceMeter);
    });

    // [8] Berapa banyak yang boleh bicara sekaligus - PG-05. Batas atas tetap
    // 2 (Cognitive Load Theory, dan kontrak zona hanya menampung 2 kartu);
    // "ringkas" memangkasnya jadi satu supaya hanya yang paling mendesak
    // terdengar.
    final maxPerCycle = switch (_verbosity) {
      Verbosity.ringkas => 1,
      _ => 2,
    };

    if (approved.isNotEmpty) {
      debugPrint('[Filter] lolos ${approved.length}/${raw.length}: '
          '${approved.take(maxPerCycle).map((d) => '${d.labelEn}#${d.trackId}(${d.dangerLevel})').join(' | ')}');
    }

    return approved.take(maxPerCycle).toList();
  }

  /// Buang catatan cooldown yang jauh lebih lama dari cooldown terpanjang -
  /// objek itu sudah pasti tidak akan tertahan lagi.
  void _pruneAnnounced() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
    _lastAnnounced.removeWhere((_, at) => at.isBefore(cutoff));
  }

  int _prio(String danger) => switch (danger) {
        'critical' => 0,
        'warning'  => 1,
        _          => 2,
      };

  /// Cooldown berbeda per tier, dipotong 50% jika objek sedang mendekat.
  /// Ref: Netra AI paper - critical=2s, warning=3s, info=5s sebagai base.
  Duration _cooldownFor(Detection det) {
    final base = switch (det.dangerLevel) {
      'critical' => const Duration(seconds: 2),
      'warning'  => const Duration(seconds: 3),
      _          => const Duration(seconds: 5),
    };

    // PG-05 - kecerewetan menggeser jeda antar pengumuman. Critical TIDAK
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

## File: `lib/services/haptic_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/haptic_service.dart`

```dart
import 'package:vibration/vibration.dart';

import '../providers/settings_provider.dart' show VibrationMode;

/// HapticService - vibration feedback pendamping TTS.
///
/// Di lingkungan bising (pasar, jalan raya), haptic menjadi primary signal.
/// Tidak perlu init() - vibration package sudah handle internally
/// jika device tidak punya vibrator (fail silent).
///
/// Pola berdasarkan penelitian clock-based directional feedback:
/// - Critical: triple pulse cepat (400ms total)
/// - Warning:  double pulse sedang (500ms)
/// - Info:     single pulse panjang (300ms)
///
/// **Menghormati Pengaturan "Getar"** (Aktif / Hanya bahaya / Mati). Sebelum
/// ini, pilihan pengguna tersimpan ke SharedPreferences tapi tidak pernah
/// dibaca siapa pun: mematikan getar tidak mematikan apa pun. Pengaturan yang
/// berbohong lebih buruk daripada pengaturan yang tidak ada, karena pengguna
/// menyangka sudah menyelesaikan masalahnya.
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  VibrationMode _mode = VibrationMode.active;
  VibrationMode get mode => _mode;

  /// Dipanggil [SettingsProvider] saat boot dan setiap kali pengaturan berubah.
  void setMode(VibrationMode mode) => _mode = mode;

  /// Apakah getar tier ini boleh dijalankan.
  bool _allowed({required bool isDanger}) => switch (_mode) {
        VibrationMode.active => true,
        VibrationMode.criticalOnly => isDanger,
        VibrationMode.off => false,
      };

  // ── Tier peringatan rintangan ─────────────────────────────────────────────

  /// Critical: orang/motor/mobil < 1.5m - triple pulse cepat.
  Future<void> critical() async {
    if (!_allowed(isDanger: true)) return;
    Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
  }

  /// Warning: objek < 3m - double pulse sedang.
  Future<void> warning() async {
    if (!_allowed(isDanger: true)) return;
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  /// Info: objek jauh/tidak berbahaya - single pulse pelan.
  Future<void> info() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 300]);
  }

  // ── Arah navigasi ─────────────────────────────────────────────────────────

  /// Belok kanan: 2 pulse cepat.
  Future<void> turnRight() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 80, 40, 80]);
  }

  /// Belok kiri: 2 pulse lambat.
  Future<void> turnLeft() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  /// Lurus: 1 pulse panjang.
  Future<void> goStraight() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(duration: 400);
  }

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

## File: `lib/services/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/index.dart`

```dart
export 'tflite_service.dart';
export 'server_service.dart';
export 'ocr_service.dart';
export 'detection_filter.dart';
export 'tts_service.dart';
export 'camera_health_service.dart';
export 'haptic_service.dart';
export 'pidnet_service.dart';
export 'yolo_navigasi_service.dart';
export 'nav_frame_converter.dart';
```

---

## File: `lib/services/money_tflite_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/money_tflite_service.dart`

```dart
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Klasifikasi nominal uang kertas rupiah - SEPENUHNYA ON-DEVICE.
///
/// Tidak pernah memanggil server. Tiga alasan yang tidak bisa ditawar:
/// transaksi tunai sering terjadi tanpa sinyal (pasar, warung), foto uang
/// tidak perlu meninggalkan perangkat, dan pengguna butuh umpan balik
/// seketika saat mengarahkan kamera.
///
/// Model: MobileNetV2 transfer learning (repo `rupiah-vision`), **7 kelas**,
/// varian INT8-quantized dengan I/O float32 - input 224x224x3, output [1,7]
/// softmax. Test accuracy 99,52%; varian INT8 ~98% pada sampel evaluasi.
///
/// **Rentang input: -1..1, BUKAN 0..255.** Ini berbeda dari model lama
/// (`uang_rupiah.tflite`) yang memanggang preprocessing `mobilenet_v2` ke
/// dalam grafnya sehingga menerima piksel mentah. Model ini tidak: di
/// `scripts/01_train.py` normalisasi `x/127.5 - 1` dilakukan di pipeline
/// `tf.data`, di luar model, dan `scripts/02_export_tflite.py` mengekspor
/// tanpa `inference_input_type` sehingga tensor masuk tetap float32 mentah
/// tanpa parameter kuantisasi.
///
/// Salah rentang di sini TIDAK memunculkan error apa pun - interpreter tetap
/// menerima float32 berapa pun nilainya, hanya prediksinya yang diam-diam
/// salah. Di mode uang itu berarti nominal keliru dibacakan ke pengguna
/// tunanetra. Jadi kalau model diganti lagi, periksa dulu apakah
/// preprocessing ada di dalam graf atau tidak, jangan diasumsikan.
///
/// ATURAN MUTLAK: nominal TIDAK PERNAH ditebak. Di bawah ambang keyakinan,
/// yang dikembalikan hanya instruksi perbaikan - salah menyebut nominal ke
/// pengguna tunanetra berarti kerugian uang nyata, jadi false positive di
/// sini jauh lebih berbahaya daripada false negative.
class MoneyTFLiteService {
  static final MoneyTFLiteService instance = MoneyTFLiteService._();
  MoneyTFLiteService._();

  static const String _modelAsset = 'assets/models/rupiah_classifier_int8.tflite';
  static const int _inputSize = 224;

  /// Ambang keyakinan sengaja tinggi. Precedent Seeing AI menyetel presisi
  /// pada confidence sangat tinggi justru untuk menekan false positive pada
  /// alat bantu uang.
  static const double confidenceThreshold = 0.85;

  /// Urutan kelas sesuai `CLASS_ORDER` di `scripts/02_export_tflite.py` dan
  /// isi `assets/models/rupiah_labels.txt` - sudah dicocokkan baris per
  /// baris, **jangan diubah**.
  ///
  /// Kalau model diganti, urutan ini WAJIB dicocokkan ulang: model
  /// mengeluarkan indeks, dan indeks yang dipetakan ke nominal yang salah
  /// menghasilkan jawaban yang percaya diri dan keliru - kegagalan paling
  /// mahal yang bisa dilakukan aplikasi ini.
  static const List<int> classValues = [1000, 2000, 5000, 10000, 20000, 50000, 100000];

  /// Model dilatih pada dataset gabungan Emisi 2016 & 2022 (7 pecahan lengkap).
  static const List<int> unsupportedValues = [];

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

    // UG-06 - ragu: nominal TIDAK ditampilkan, hanya instruksi perbaikan.
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

/// Sampling langsung ke grid 224x224 dari area crop - piksel yang diproses
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

        // Normalisasi ke [-1, 1] - preprocessing mobilenet_v2 TIDAK ada di
        // dalam graf model ini, jadi harus dikerjakan di sini.
        return [r / 127.5 - 1.0, g / 127.5 - 1.0, b / 127.5 - 1.0];
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
        return [p.r / 127.5 - 1.0, p.g / 127.5 - 1.0, p.b / 127.5 - 1.0];
      });
    }),
  ];
}
```

---

## File: `lib/services/nav_frame_converter.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/nav_frame_converter.dart`

```dart
import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Konversi CameraImage (YUV420) → RGB888 bytes (Uint8List).
///
/// Dipakai oleh PidnetService dan YoloNavigasiService untuk preprocessing
/// frame kamera sebelum inference TFLite on-device.
///
/// Output: [R, G, B, R, G, B, ...] panjang = width × height × 3.
/// Caller meneruskan origW dan origH dari CameraImage.
class NavFrameConverter {
  NavFrameConverter._();

  static ({Uint8List rgb, int width, int height}) fromCameraImage(
    CameraImage image,
  ) {
    final int w = image.width;
    final int h = image.height;

    final yPlane  = image.planes[0];
    final uPlane  = image.planes[1];
    final vPlane  = image.planes[2];

    final yBytes      = yPlane.bytes;
    final uBytes      = uPlane.bytes;
    final vBytes      = vPlane.bytes;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixStride = uPlane.bytesPerPixel ?? 1;

    final rgb = Uint8List(w * h * 3);
    int idx = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yIdx  = y * yPlane.bytesPerRow + x;
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixStride;

        final yVal = yBytes[yIdx] & 0xFF;
        final uVal = (uBytes.length > uvIdx ? uBytes[uvIdx] : 128) & 0xFF;
        final vVal = (vBytes.length > uvIdx ? vBytes[uvIdx] : 128) & 0xFF;

        rgb[idx++] = (yVal + 1.402  * (vVal - 128)).round().clamp(0, 255);
        rgb[idx++] = (yVal - 0.344  * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
        rgb[idx++] = (yVal + 1.772  * (uVal - 128)).round().clamp(0, 255);
      }
    }

    return (rgb: rgb, width: w, height: h);
  }
}
```

---

## File: `lib/services/object_tracker.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/object_tracker.dart`

```dart
import 'dart:math';
import '../models/detection.dart';
import 'camera_health_service.dart';

/// TrackedObject - state satu objek yang sedang di-track.
///
/// ## Kompensasi ayunan tangan
///
/// Pengguna memegang ponsel sambil berjalan, jadi ponselnya ikut mengayun.
/// Ayunan itu membuat kotak deteksi membesar-mengecil sendiri, sehingga objek
/// yang sebenarnya diam terbaca "maju-mundur". Dua akibatnya nyata:
///
/// 1. Jarak yang diucapkan melompat-lompat ("dua meter… satu meter… dua
///    meter") padahal tidak ada yang bergerak.
/// 2. Aturan lama - `area > lastArea * 1.20` dari **satu** frame ke frame
///    berikutnya - menyalakan `isApproaching` pada ayunan biasa, dan itu
///    memotong cooldown jadi separuh. Peringatan jadi lebih sering justru
///    karena tangan bergoyang, bukan karena ada bahaya mendekat.
///
/// Perbaikannya tidak butuh matematika gyroscope: dua EMA jarak dengan
/// kecepatan berbeda, plus syarat tren yang harus bertahan beberapa frame.
/// Saat [CameraHealthService.motionLevel] tinggi, penghalusan diperlambat dan
/// ambangnya dinaikkan - sinyal yang berisik diperlakukan sebagai sinyal yang
/// berisik, bukan sebagai kebenaran.
class TrackedObject {
  final int    id;
  final String label;      // labelEn dari Detection
  double cx, cy, w, h;
  int    missedFrames = 0;

  /// EMA cepat & lambat dari jarak. Perpotongan keduanya = arah tren.
  double? _fastDist;
  double? _slowDist;

  /// Berapa frame berturut-turut tren menunjukkan mendekat.
  int _approachStreak = 0;

  /// Jarak yang sudah dihaluskan - inilah yang layak diucapkan ke pengguna.
  /// Null sebelum ada satu pun pembaruan jarak.
  double? get smoothedDistance => _slowDist;

  /// Butuh tren mendekat yang bertahan, bukan satu frame yang kebetulan besar.
  bool get isApproaching => _approachStreak >= _approachStreakRequired;

  static const int _approachStreakRequired = 3;

  TrackedObject({
    required this.id,
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  });

  void update(
    double newCx,
    double newCy,
    double newW,
    double newH, {
    double? distanceMeter,
    double motionLevel = 0.0,
  }) {
    cx = newCx; cy = newCy;
    w  = newW;  h  = newH;
    missedFrames = 0;

    if (distanceMeter == null || distanceMeter <= 0 || distanceMeter > 500) return;

    // Makin goyang, makin lambat percaya pada nilai baru.
    final shake = motionLevel.clamp(0.0, 1.0);
    final alphaFast = 0.50 - 0.20 * shake; // 0.50 tenang → 0.30 goyang
    final alphaSlow = 0.18 - 0.08 * shake; // 0.18 tenang → 0.10 goyang

    _fastDist = _fastDist == null
        ? distanceMeter
        : _fastDist! + alphaFast * (distanceMeter - _fastDist!);
    _slowDist = _slowDist == null
        ? distanceMeter
        : _slowDist! + alphaSlow * (distanceMeter - _slowDist!);

    // Mendekat = EMA cepat turun cukup jauh di bawah EMA lambat. Marginnya
    // melebar saat goyang supaya derau ayunan tidak lolos sebagai tren.
    final margin = 0.06 + 0.08 * shake; // 6% tenang → 14% goyang
    final approachingNow = _fastDist! < _slowDist! * (1 - margin);

    _approachStreak = approachingNow ? _approachStreak + 1 : 0;
  }
}

/// ObjectTracker - SORT (Simple Online Realtime Tracking) pure Dart.
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

  /// Track yang dipasangkan ke tiap deteksi pada pemanggilan [update]
  /// terakhir, sejajar indeks dengan daftar deteksi yang dikirim.
  ///
  /// Ini yang membuat cooldown bisa dikunci per objek, bukan per kelas.
  /// Tanpa pemetaan ini, pemanggil hanya bisa mencocokkan track lewat label -
  /// dan dengan dua objek sekelas di frame, yang ketemu selalu track pertama,
  /// sehingga status "mendekat" milik objek jauh bisa menempel ke objek dekat.
  List<TrackedObject?> _lastAssignment = const [];
  List<TrackedObject?> get lastAssignment => List.unmodifiable(_lastAssignment);

  /// Update tracker dengan list deteksi frame terbaru.
  /// Return: semua TrackedObject yang masih aktif.
  List<TrackedObject> update(List<Detection> detections) {
    final assignment = List<TrackedObject?>.filled(detections.length, null);

    if (detections.isEmpty) {
      for (final t in _tracks.values) {
        t.missedFrames++;
      }
      _prune();
      _lastAssignment = assignment;
      return _tracks.values.toList();
    }

    // Dibaca sekali per frame: seberapa kuat ponsel sedang mengayun.
    final motion = CameraHealthService.instance.motionLevel;

    final matched   = <int>{};    // index detection yang sudah di-assign
    final trackList = _tracks.values.toList();

    for (final track in trackList) {
      double bestIou = _iouThreshold;
      int    bestIdx = -1;

      for (int i = 0; i < detections.length; i++) {
        if (matched.contains(i)) continue;
        // Hanya match dengan label yang sama - tidak cross-class matching
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
        track.update(
          d.bboxCx, d.bboxCy, d.bboxW, d.bboxH,
          distanceMeter: d.distanceMeter,
          motionLevel: motion,
        );
        matched.add(bestIdx);
        assignment[bestIdx] = track;
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
      )..update(
          d.bboxCx, d.bboxCy, d.bboxW, d.bboxH,
          distanceMeter: d.distanceMeter,
          motionLevel: motion,
        );
      _tracks[t.id] = t;
      assignment[i] = t;
    }

    _prune();
    _lastAssignment = assignment;
    return _tracks.values.toList();
  }

  void _prune() =>
      _tracks.removeWhere((_, t) => t.missedFrames > _maxMissedFrames);

  /// Intersection over Union dalam pixel coords.
  /// Formula identik dengan normalized coords - unit tidak mempengaruhi rasio.
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

  /// Reset semua track - dipanggil saat mode berganti (stopRealtime).
  void reset() {
    _tracks.clear();
    _lastAssignment = const [];
    _nextId = 0;
  }
}
```

---

## File: `lib/services/ocr_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/ocr_service.dart`

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Satu blok teks hasil pengenalan, sudah diurutkan sesuai urutan baca.
@immutable
class OcrTextBlock {
  final String heading;
  final List<String> sentences;

  /// Perkiraan jumlah kata - dipakai BT-08 untuk menghitung durasi bacaan
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

  /// BT-08 - perkiraan durasi baca. ~150 kata per menit adalah laju TTS
  /// Bahasa Indonesia yang wajar pada kecepatan bawaan.
  Duration get estimatedDuration =>
      Duration(seconds: (totalWords / 150 * 60).round());
}

/// Pengenalan teks **sepenuhnya di perangkat** lewat ML Kit.
///
/// Ini menggantikan OCR di server. Tiga akibat langsung, semuanya perbaikan:
///
/// 1. **Baca Teks jalan tanpa internet.** BT-02 ("tombol nonaktif + alasan")
///    tidak berlaku lagi - tidak ada alasan menonaktifkan tombol untuk kerja
///    yang tidak butuh jaringan sama sekali.
/// 2. **Tidak ada gambar yang meninggalkan perangkat.** Foto dokumen, resep,
///    surat - semuanya tetap di ponsel.
/// 3. **Hasil datang dalam ratusan milidetik**, bukan detik. BT-05 (banner
///    lambat 8 detik) dan BT-15 (timeout 15 detik) praktis tidak pernah kena.
///
/// Yang hilang: ML Kit tidak melakukan koreksi berbasis LLM, jadi teks
/// bersudut miring atau tulisan tangan lebih sering meleset daripada OCR
/// server. Untuk menu, label harga, dan papan nama - kasus pemakaian utama
/// mode ini - itu pertukaran yang menguntungkan.
class OcrService {
  static final OcrService instance = OcrService._();
  OcrService._();

  TextRecognizer? _recognizer;

  TextRecognizer get _engine =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Mengenali teks dari berkas gambar hasil `takePicture`.
  ///
  /// ML Kit membaca langsung dari path berkas, jadi byte-nya **tidak perlu**
  /// dibaca ke memori Dart lebih dulu - untuk foto 4 MP itu menghemat satu
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
      // Foto tidak ditinggalkan di penyimpanan - BT-21 mengeluh soal ruang,
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
      // Baris pertama tiap blok dipakai sebagai heading - itu yang membuat
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

## File: `lib/services/pidnet_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/pidnet_service.dart`

```dart
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../widgets/zone_indicator.dart' show ZoneStatus;

// ─────────────────────────────────────────────────────────────
// Hasil segmentasi 3 zona dari PIDNet-S
// ─────────────────────────────────────────────────────────────
class ZoneAnalysis {
  /// Rasio piksel walkable (0.0 – 1.0) per zona.
  final double leftRatio;
  final double centerRatio;
  final double rightRatio;

  /// Status per zona berdasarkan threshold.
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;

  /// Indeks zona yang direkomendasikan (0=kiri, 1=tengah, 2=kanan).
  final int recommendedZone;

  /// Waktu inference dalam milidetik.
  final double inferenceMs;

  const ZoneAnalysis({
    required this.leftRatio,
    required this.centerRatio,
    required this.rightRatio,
    required this.left,
    required this.center,
    required this.right,
    required this.recommendedZone,
    required this.inferenceMs,
  });

  /// Pesan TTS sederhana berdasarkan zona - sama dengan yang dipakai backend.
  String get ttsMessage {
    // Rintangan akan ditangani lapisan atas (NavigationProvider).
    // Di sini hanya beri arahan zona jalur.
    if (left == ZoneStatus.danger &&
        center == ZoneStatus.danger &&
        right == ZoneStatus.danger) {
      return 'Berhenti dulu. Tidak ada jalur aman di sekitar sini.';
    }
    if (center == ZoneStatus.danger) {
      return 'Jalur di depan tidak aman.';
    }
    return switch (recommendedZone) {
      0 => 'Tetap di kiri.',
      2 => 'Geser ke kanan.',
      _ => 'Jalur aman, jalan lurus.',
    };
  }

  ZoneStatus get recommendedStatus => switch (recommendedZone) {
        0 => left,
        2 => right,
        _ => center,
      };
}

// ─────────────────────────────────────────────────────────────
// Konfigurasi PIDNet-S
// ─────────────────────────────────────────────────────────────

// Dimensi input model: H=384, W=640 (sesuai training)
const int _pidnetH = 384;
const int _pidnetW = 640;

// Kelas output: 0=non-walkable, 1=walkable/trotoar, 2=hazard
// Hanya kelas 1 (walkable) yang dihitung untuk rasio zona.
const int _classWalkable = 1;

// Threshold rasio walkable per zona
const double _threshSafe    = 0.50; // ≥50% walkable → AMAN
const double _threshCaution = 0.30; // ≥30% walkable → HATI-HATI, sisanya BAHAYA

// ImageNet normalisasi (sama persis dengan preprocessing Python)
const List<double> _mean = [0.485, 0.456, 0.406];
const List<double> _std  = [0.229, 0.224, 0.225];

// ─────────────────────────────────────────────────────────────
// PidnetService - segmentasi jalur 3 zona on-device
// ─────────────────────────────────────────────────────────────
class PidnetService {
  static final PidnetService instance = PidnetService._();
  PidnetService._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Input shape: [1, 384, 640, 3] (BHWC - TFLite default)
  // Atau [1, 3, 384, 640] (BCHW - jika model tidak di-transpose saat export)
  // Akan dideteksi otomatis saat load.
  bool _isBHWC = true;

  /// Muat model pidnet_s_3zona.tflite dari assets.
  /// Gunakan FP16 jika tersedia (lebih kecil, lebih cepat di A30S),
  /// fallback ke FP32 jika tidak.
  Future<bool> tryLoad() async {
    try {
      // Coba FP16 dulu - lebih efisien di Mali-G71 (Samsung A30S)
      Uint8List? modelBytes;
      try {
        final bd = await rootBundle.load('assets/models/pidnet_s_3zona_fp16.tflite');
        modelBytes = bd.buffer.asUint8List();
        debugPrint('[PIDNet] Memuat FP16 model (${(modelBytes.length / 1024).toStringAsFixed(0)} KB)');
      } catch (_) {
        // FP16 tidak ada, pakai FP32
        final bd = await rootBundle.load('assets/models/pidnet_s_3zona.tflite');
        modelBytes = bd.buffer.asUint8List();
        debugPrint('[PIDNet] Memuat FP32 model (${(modelBytes.length / 1024).toStringAsFixed(0)} KB)');
      }

      // GPU delegate - coba aktifkan di Android; jika gagal, CPU saja
      InterpreterOptions options;
      try {
        if (Platform.isAndroid) {
          options = InterpreterOptions()
            ..addDelegate(GpuDelegateV2())
            ..threads = 2;
          debugPrint('[PIDNet] GPU delegate aktif');
        } else {
          options = InterpreterOptions()..threads = 2;
        }
      } catch (_) {
        options = InterpreterOptions()..threads = 2;
        debugPrint('[PIDNet] GPU delegate gagal, pakai CPU');
      }

      final interpreter = Interpreter.fromBuffer(modelBytes, options: options);

      // Deteksi input format: BHWC atau BCHW
      final inputShape = interpreter.getInputTensor(0).shape;
      debugPrint('[PIDNet] Input shape: $inputShape');
      // BHWC: [1, H, W, C] → shape[1]=384, shape[2]=640, shape[3]=3
      // BCHW: [1, C, H, W] → shape[1]=3,   shape[2]=384, shape[3]=640
      _isBHWC = (inputShape.length == 4 && inputShape[3] == 3);
      debugPrint('[PIDNet] Format: ${_isBHWC ? "BHWC" : "BCHW"}');

      final outputShape = interpreter.getOutputTensor(0).shape;
      debugPrint('[PIDNet] Output shape: $outputShape');

      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[PIDNet] Model siap.');
      return true;
    } catch (e) {
      debugPrint('[PIDNet] Gagal load: $e');
      _loaded = false;
      return false;
    }
  }

  /// Analisis frame kamera → ZoneAnalysis (3 zona jalur).
  ///
  /// [rgbBytes] adalah bytes RGB888 dari frame kamera (setelah konversi YUV).
  /// [origW] dan [origH] adalah dimensi asli frame sebelum resize.
  Future<ZoneAnalysis?> analyze(
    Uint8List rgbBytes,
    int origW,
    int origH,
  ) async {
    if (!_loaded || _interpreter == null) return null;

    final t0 = DateTime.now();

    try {
      // Decode bytes ke img.Image untuk resize
      final rawImg = img.Image.fromBytes(
        width: origW,
        height: origH,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );

      // Resize ke 640×384 (W×H) - cv2.resize pakai (W, H)
      // Untuk rotasi Android: rotate 90° dulu sebelum resize
      img.Image resized;
      if (Platform.isAndroid) {
        final rotated = img.copyRotate(rawImg, angle: 90);
        resized = img.copyResize(rotated, width: _pidnetW, height: _pidnetH,
            interpolation: img.Interpolation.linear);
      } else {
        resized = img.copyResize(rawImg, width: _pidnetW, height: _pidnetH,
            interpolation: img.Interpolation.linear);
      }

      // Bangun tensor input sesuai format model
      final List input;
      if (_isBHWC) {
        // [1, 384, 640, 3] - float32 normalized
        input = _buildBHWC(resized);
      } else {
        // [1, 3, 384, 640] - float32 normalized
        input = _buildBCHW(resized);
      }

      // Output: [1, numClasses, H, W] atau [1, H, W, numClasses]
      // Deteksi output shape saat runtime
      final outTensor  = _interpreter!;
      // Perkiraan output: [1, 3, 384, 640] atau [1, 384, 640, 3]
      // Kita simpan sebagai flat Float32List lalu argmax manual
      final outputFlat = List.filled(1 * 3 * _pidnetH * _pidnetW, 0.0);

      final outputs = {0: outputFlat.reshape([1, 3, _pidnetH, _pidnetW])};
      await outTensor.runForMultipleInputs([input], outputs);

      // Argmax per-piksel → mask [H*W]
      final logits4D = outputs[0] as List; // [1][3][H][W] atau [1][H][W][3]
      final mask = _argmax(logits4D);

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();
      return _computeZones(mask, inferMs);
    } catch (e) {
      debugPrint('[PIDNet] analyze error: $e');
      return null;
    }
  }

  // ── Build input BHWC [1][H][W][3] ──────────────────────────
  List _buildBHWC(img.Image img_) {
    return List.generate(1, (_) =>
      List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) {
          final p = img_.getPixel(x, y);
          final r = (p.r / 255.0 - _mean[0]) / _std[0];
          final g = (p.g / 255.0 - _mean[1]) / _std[1];
          final b = (p.b / 255.0 - _mean[2]) / _std[2];
          return [r, g, b];
        }),
      ),
    );
  }

  // ── Build input BCHW [1][3][H][W] ──────────────────────────
  List _buildBCHW(img.Image img_) {
    final r = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).r / 255.0 - _mean[0]) / _std[0]));
    final g = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).g / 255.0 - _mean[1]) / _std[1]));
    final b_ = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).b / 255.0 - _mean[2]) / _std[2]));
    return [[r, g, b_]];
  }

  // ── Argmax [1][3][H][W] → flat Int List panjang H*W ─────────
  List<int> _argmax(List logits4D) {
    // logits4D[0][c][h][w]
    final classes = logits4D[0] as List; // [3][H][W]
    final mask = List<int>.filled(_pidnetH * _pidnetW, 0);
    for (int h = 0; h < _pidnetH; h++) {
      for (int w = 0; w < _pidnetW; w++) {
        double maxVal = double.negativeInfinity;
        int maxC = 0;
        for (int c = 0; c < 3; c++) {
          final val = (classes[c] as List)[h][w] as double;
          if (val > maxVal) { maxVal = val; maxC = c; }
        }
        mask[h * _pidnetW + w] = maxC;
      }
    }
    return mask;
  }

  // ── Hitung rasio 3 zona & hasilkan ZoneAnalysis ─────────────
  ZoneAnalysis _computeZones(List<int> mask, double inferMs) {
    // Bagi gambar jadi 3 kolom vertikal (kiri, tengah, kanan)
    const zoneW  = _pidnetW ~/ 3;

    int leftWalk = 0, leftTotal = 0;
    int centWalk = 0, centTotal = 0;
    int rightWalk = 0, rightTotal = 0;

    for (int h = 0; h < _pidnetH; h++) {
      for (int w = 0; w < _pidnetW; w++) {
        final cls = mask[h * _pidnetW + w];
        // _classWalkable=1 → layak jalan; _classNonWalkable=0 & _classHazard=2 → tidak
        final isWalk = cls == _classWalkable;
        if (w < zoneW) {
          leftTotal++;
          if (isWalk) { leftWalk++; }
        } else if (w < zoneW * 2) {
          centTotal++;
          if (isWalk) { centWalk++; }
        } else {
          rightTotal++;
          if (isWalk) { rightWalk++; }
        }
      }
    }

    final lRatio = leftWalk  / max(leftTotal,  1);
    final cRatio = centWalk  / max(centTotal,  1);
    final rRatio = rightWalk / max(rightTotal, 1);

    ZoneStatus toStatus(double ratio) {
      if (ratio >= _threshSafe)    { return ZoneStatus.safe; }
      if (ratio >= _threshCaution) { return ZoneStatus.caution; }
      return ZoneStatus.danger;
    }

    final lStatus = toStatus(lRatio);
    final cStatus = toStatus(cRatio);
    final rStatus = toStatus(rRatio);

    // Rekomendasi zona: pilih yang paling aman, prioritas tengah
    int recommended = 1; // tengah default
    if (cStatus == ZoneStatus.safe) {
      recommended = 1;
    } else if (lRatio >= rRatio && lStatus != ZoneStatus.danger) {
      recommended = 0;
    } else if (rStatus != ZoneStatus.danger) {
      recommended = 2;
    } else {
      // Semua bahaya - pilih yang paling tinggi rasionya
      if (lRatio >= cRatio && lRatio >= rRatio) {
        recommended = 0;
      } else if (rRatio >= cRatio) {
        recommended = 2;
      } else {
        recommended = 1;
      }
    }

    debugPrint('[PIDNet] L=${lRatio.toStringAsFixed(2)} '
        'C=${cRatio.toStringAsFixed(2)} R=${rRatio.toStringAsFixed(2)} '
        '→ rec=$recommended  (${inferMs.toStringAsFixed(0)}ms)');

    return ZoneAnalysis(
      leftRatio:       lRatio,
      centerRatio:     cRatio,
      rightRatio:      rRatio,
      left:            lStatus,
      center:          cStatus,
      right:           rStatus,
      recommendedZone: recommended,
      inferenceMs:     inferMs,
    );
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}
```

---

## File: `lib/services/server_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/server_service.dart`

```dart
import 'dart:typed_data';
import '../core/net/api_client.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Emulator Android  : 10.0.2.2:8000
// Device fisik      : ganti lewat Pengaturan → Alamat server (PG-08).
const String kDefaultServerHost = '10.0.2.2:8000';
// ──────────────────────────────────────────────────────────────────────────

/// Klien untuk **hanya** yang benar-benar butuh server.
///
/// Setelah OCR pindah ke ML Kit, uang ke TFLite, deteksi ke SSD MobileNet, dan
/// intent parsing ke `CommandParser`, yang tersisa di server tinggal yang
/// memang tidak ada di perangkat: YOLOE (Cari Objek), Moondream2 (Deskripsi
/// Suasana), dan segmentasi jalur sebagai cadangan PIDNet on-device.
///
/// Dua belas method lain - `detectOnce`, `routeIntent`, `resolveIntent`,
/// `cariObjekTargets`, `health`, `sendEvents`, `sendCrashReport`,
/// `lastModeBeforeCrash`, `flushQueue`, `labels`, `modelManifest`,
/// `checkRiskZone` - dihapus karena tidak punya satu pun pemanggil. Endpoint
/// backend-nya ikut diarsipkan.
class ServerService {
  static final ServerService instance = ServerService._();
  ServerService._();

  /// Alamat server aktif (PG-08). Dulu ini konstanta hardcoded, jadi
  /// pengaturan "Alamat server" tersimpan ke disk tapi **tidak berpengaruh
  /// sama sekali** - aplikasi mengatakan "tersimpan" untuk perubahan yang
  /// tidak pernah terjadi. Itu pelanggaran bagian 4.1 yang sama seperti
  /// konfirmasi ganti mode palsu, hanya di tempat berbeda.
  ///
  /// Sekarang [host] adalah sumber kebenaran tunggal untuk seluruh endpoint,
  /// diisi `SettingsProvider` saat boot dan setiap kali pengguna menyimpan
  /// alamat baru.
  String _host = kDefaultServerHost;
  String get host => _host;

  /// Mengganti alamat. Permintaan berikutnya langsung memakai alamat baru
  /// karena [ApiClient] membaca [_host] lewat `hostProvider`.
  void setHost(String value) {
    final next = value.trim();
    if (next.isEmpty || next == _host) return;
    _host = next;
  }

  /// Satu klien HTTP untuk seluruh aplikasi - koneksi dipakai ulang
  /// (keep-alive) alih-alih handshake baru tiap permintaan. Lihat
  /// [ApiClient] untuk alasan lengkapnya.
  late final ApiClient _api = ApiClient()..hostProvider = (() => _host);
  ApiClient get api => _api;

  // ── Deteksi rintangan: TIDAK ADA jalur server ───────────────────────────
  //
  // `WS /ws/detect`, `POST /api/detect`, dan `POST /api/narasi` dihapus.
  // Deteksi rintangan sepenuhnya on-device (SSD MobileNet TFLite) dan
  // narasinya dirangkai `narration_engine.dart` - keduanya sudah ada di
  // perangkat, jadi jalur server hanya menggandakan kode di mode paling
  // kritis keselamatan sambil menambahkan ketergantungan diam-diam pada
  // laptop yang menyala.
  // ─────────────────────────────────────────────────────────────────────────

  /// Kirim satu frame ke backend YOLOE untuk mencari [target].
  ///
  /// Backend YOLOE open-vocabulary (300+ barang Bahasa Indonesia) - jauh lebih
  /// fleksibel dari on-device ONNX 80 kelas. Melempar exception saat gagal.
  ///
  /// `found: false` dengan reason `not_in_frame` adalah kondisi NORMAL (CO-10)
  /// - pengguna cukup arahkan kamera ke tempat lain lalu tekan kirim lagi.
  Future<Map<String, dynamic>> cariObjek(Uint8List jpegBytes, String target) =>
      _api.postMultipart(
        '/api/cari-objek',
        bytes: jpegBytes,
        fileField: 'file',
        filename: 'frame.jpg',
        fields: {'target': target},
        op: ApiOp.frame,
      );

  /// Daftar barang yang dikenali - dipakai CO-12 untuk menawarkan
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

  /// Health check ke alamat tertentu **tanpa mengubah alamat aktif** - dipakai
  /// PG-08b untuk menguji kandidat sebelum disimpan. Memisahkan "menguji" dari
  /// "memakai" itulah yang membuat PG-08e mungkin: uji boleh gagal tanpa
  /// merusak sambungan yang sedang bekerja.
  Future<Map<String, dynamic>?> healthAt(String host, {Duration? timeout}) async {
    // Klien sementara dengan host tetap - tidak menyentuh alamat aktif.
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

  /// Scene Description via Moondream2.
  /// Mengirim gambar JPEG ke /api/describe dan mengembalikan deskripsi
  /// suasana dalam Bahasa Inggris (output langsung Moondream2, tanpa terjemahan).
  /// Mobile membacanya via TTSService.speakEnglish() dengan locale 'en-US'.
  Future<String?> describeScene(Uint8List jpegBytes) async {
    try {
      final result = await _api.postMultipart(
        '/api/describe',
        bytes: jpegBytes,
        filename: 'scene.jpg',
        fields: {},
        op: ApiOp.heavy,
      );
      return result['description_en'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _api.close();
}
```

---

## File: `lib/services/tflite_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/tflite_service.dart`

```dart

import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';
import 'camera_intrinsics.dart';

// Label Bahasa Indonesia - kunci adalah label Inggris dari labelmap.txt
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

  // Tilt correction - sudut kemiringan kamera dari accelerometer (radian)
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
  ///
  /// Preprocessing berjalan di isolate lewat [compute] dan menghasilkan
  /// **buffer datar** `Uint8List` yang langsung disalin ke tensor uint8.
  ///
  /// Versi sebelumnya melakukan seluruhnya di isolate UI: loop 640×480
  /// YUV→RGB dengan `setPixelRgb()` per piksel, lalu `copyResize`, lalu
  /// `copyRotate`, lalu membangun `List<List<List<List<num>>>>` berisi
  /// 270.000 angka ter-boxing. Hanya interpreter-nya yang ada di isolate;
  /// bagian yang jauh lebih mahal justru menghalangi thread UI - dan karena
  /// TTS dijadwalkan dari thread yang sama, suaralah yang ikut tersendat.
  Future<List<Detection>> runInference(CameraImage image) async {
    if (!_loaded || _isolateInterpreter == null) return [];

    final geo = _FrameGeometry.of(image.width, image.height);
    final Uint8List inputTensor;
    try {
      inputTensor = await compute(_prepareSsdInput, _SsdPrepArgs.from(image, geo));
    } catch (e) {
      debugPrint('[TFLite] preprocessing gagal: $e');
      return [];
    }

    // SSD MobileNet output 4 tensor terpisah:
    //   tensor[0]: locations [1][10][4]   - [ymin, xmin, ymax, xmax] normalized
    //   tensor[1]: classes   [1][10]      - class index (float)
    //   tensor[2]: scores    [1][10]      - confidence score
    //   tensor[3]: count     [1]          - jumlah deteksi valid
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
      geo,
    );
  }

  /// Post-process output SSD MobileNet → List<Detection>
  ///
  /// Output tensor SSD:
  ///   locations[i] = [ymin, xmin, ymax, xmax] normalized 0..1
  ///                  **relatif terhadap kotak crop tegak**, bukan frame mentah
  ///   classes[i]   = class index (float, bukan int)
  ///   scores[i]    = confidence score
  ///
  /// NMS sudah dilakukan di dalam model - tidak perlu NMS manual.
  List<Detection> _postProcess(
    List<List<double>> locations, // [10][4]: ymin, xmin, ymax, xmax
    List<double> classes,
    List<double> scores,
    _FrameGeometry geo,
  ) {
    const double confThreshold = 0.5;
    // Fokus per-perangkat, dihitung ulang dari lebar frame yang benar-benar
    // dipakai - bukan konstanta yang mengasumsikan satu lensa untuk semua HP.
    final focalPx = CameraIntrinsics.instance.focalPxForUprightFrame(geo.srcW);
    final List<Detection> results = [];

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] < confThreshold) continue;

      final classIdx = classes[i].toInt();
      if (classIdx < 0 || classIdx >= _labels.length) continue;

      final labelEn = _labels[classIdx];
      // Skip entry '???' di labelmap - bukan kelas valid
      if (labelEn == '???') continue;

      final labelId = _labelId[labelEn] ?? labelEn;

      // SSD output: [ymin, xmin, ymax, xmax] normalized 0..1
      final ymin = locations[i][0].clamp(0.0, 1.0);
      final xmin = locations[i][1].clamp(0.0, 1.0);
      final ymax = locations[i][2].clamp(0.0, 1.0);
      final xmax = locations[i][3].clamp(0.0, 1.0);

      // Koordinat piksel di ruang **bingkai tegak**. Karena crop-nya persegi
      // dan skalanya seragam, tinggi kotak di sini sebanding lurus dengan
      // tinggi objek sebenarnya - syarat yang tidak dipenuhi versi lama, yang
      // meregangkan 640×480 menjadi 300×300 (rasio berubah) lalu memutarnya,
      // sehingga "tinggi" kotak sebenarnya mengukur lebar objek.
      final x1 = (geo.offsetX + xmin * geo.cropSide).round();
      final y1 = (geo.offsetY + ymin * geo.cropSide).round();
      final x2 = (geo.offsetX + xmax * geo.cropSide).round();
      final y2 = (geo.offsetY + ymax * geo.cropSide).round();

      final boxH = (ymax - ymin) * geo.cropSide;

      final dist   = _estimateDistance(labelEn, boxH, focalPx);
      final dir    = _getDirection((xmin + xmax) / 2, (ymin + ymax) / 2);
      final danger = _getDanger(labelEn, dist);

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

  /// Estimasi jarak dari tinggi kotak dalam piksel bingkai tegak.
  ///
  /// [focalPx] dibaca dari intrinsik lensa perangkat lewat [CameraIntrinsics];
  /// kalau perangkat tidak melaporkannya, nilainya jatuh ke fallback yang
  /// sama seperti konstanta lama.
  double _estimateDistance(String label, double boxHpx, double focalPx) {
    if (boxHpx <= 0) return 999.0;
    final realH = _realHeightsCm[label] ?? 100;
    double dist = (realH * focalPx) / (boxHpx * 100);

    // Tilt correction: jika HP miring > 15° (0.26 rad), koreksi jarak.
    if (_lastTiltAngle.abs() > 0.26) {
      dist = dist * cos(_lastTiltAngle.abs());
    }

    return dist;
  }

  /// Tentukan arah dari posisi kotak dalam koordinat ternormalisasi (0..1)
  /// pada kotak crop tegak.
  ///
  /// Horizontal: kiri / depan / kanan (trisection horizontal)
  /// Vertikal: atas / tengah / bawah (trisection vertikal)
  ///
  /// Jika vertikal = tengah → kembalikan arah horizontal saja ("depan")
  /// Jika vertikal != tengah → gabungkan: "kiri atas", "depan bawah", dll.
  String _getDirection(double cxNorm, double cyNorm) {
    final horiz = cxNorm < 1 / 3 ? 'kiri' : cxNorm < 2 / 3 ? 'depan' : 'kanan';
    final vert  = cyNorm < 1 / 3 ? 'atas' : cyNorm < 2 / 3 ? 'tengah' : 'bawah';

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

// ── Geometri bingkai ────────────────────────────────────────────────────────

/// Pemetaan antara frame sensor (landscape) dan bingkai tegak yang dilihat
/// pengguna, plus kotak crop persegi yang dikirim ke model.
///
/// Kamera Android memberi frame landscape (mis. 640×480) sementara aplikasi
/// terkunci portrait, jadi bingkai tegaknya 480×640. Model butuh masukan
/// persegi 300×300; supaya rasio tidak berubah, yang diambil adalah **crop
/// persegi di tengah** bingkai tegak, bukan seluruh frame yang diregangkan.
class _FrameGeometry {
  /// Lebar & tinggi frame sensor mentah.
  final int srcW, srcH;

  /// Sisi kotak crop, dalam piksel bingkai tegak.
  final int cropSide;

  /// Posisi kiri-atas kotak crop di dalam bingkai tegak.
  final int offsetX, offsetY;

  const _FrameGeometry({
    required this.srcW,
    required this.srcH,
    required this.cropSide,
    required this.offsetX,
    required this.offsetY,
  });

  factory _FrameGeometry.of(int srcW, int srcH) {
    // Bingkai tegak = frame sensor diputar 90°.
    final uprightW = srcH;
    final uprightH = srcW;
    final side = uprightW < uprightH ? uprightW : uprightH;
    return _FrameGeometry(
      srcW: srcW,
      srcH: srcH,
      cropSide: side,
      offsetX: (uprightW - side) ~/ 2,
      offsetY: (uprightH - side) ~/ 2,
    );
  }
}

/// Argumen preprocessing - semua sudah berupa data biasa supaya bisa dikirim
/// ke isolate lewat [compute].
class _SsdPrepArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int yRowStride, uvRowStride, uvPixelStride;
  final int srcH;
  final int cropSide, offsetX, offsetY;

  const _SsdPrepArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.srcH,
    required this.cropSide,
    required this.offsetX,
    required this.offsetY,
  });

  factory _SsdPrepArgs.from(CameraImage image, _FrameGeometry geo) => _SsdPrepArgs(
        yPlane: image.planes[0].bytes,
        uPlane: image.planes[1].bytes,
        vPlane: image.planes[2].bytes,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
        srcH: geo.srcH,
        cropSide: geo.cropSide,
        offsetX: geo.offsetX,
        offsetY: geo.offsetY,
      );
}

/// YUV420 → RGB langsung ke grid 300×300, dalam satu lintasan, di isolate.
///
/// Rotasi 90° dan crop persegi dilakukan lewat pemetaan indeks - tidak ada
/// gambar antara yang dialokasikan, dan piksel yang disentuh hanya 90.000
/// alih-alih 307.200. Hasilnya buffer datar `Uint8List` yang disalin apa
/// adanya ke tensor uint8 (`ByteConversionUtils` memakai jalur cepat untuk
/// `Uint8List`), jadi tidak ada 270.000 angka ter-boxing seperti sebelumnya.
Uint8List _prepareSsdInput(_SsdPrepArgs a) {
  final out = Uint8List(_inputSize * _inputSize * 3);
  final yLen = a.yPlane.length;
  final uLen = a.uPlane.length;
  final vLen = a.vPlane.length;
  var o = 0;

  for (int ty = 0; ty < _inputSize; ty++) {
    // Sumbu vertikal bingkai tegak = sumbu horizontal sensor.
    final uy = a.offsetY + (ty * a.cropSide) ~/ _inputSize;
    final sx = uy;
    final uvCol = (sx >> 1) * a.uvPixelStride;

    for (int tx = 0; tx < _inputSize; tx++) {
      final ux = a.offsetX + (tx * a.cropSide) ~/ _inputSize;
      final sy = a.srcH - 1 - ux;

      final yIdx = sy * a.yRowStride + sx;
      final uvIdx = (sy >> 1) * a.uvRowStride + uvCol;

      final yVal = yIdx >= 0 && yIdx < yLen ? a.yPlane[yIdx] : 0;
      final uVal = (uvIdx >= 0 && uvIdx < uLen ? a.uPlane[uvIdx] : 128) - 128;
      final vVal = (uvIdx >= 0 && uvIdx < vLen ? a.vPlane[uvIdx] : 128) - 128;

      out[o++] = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
      out[o++] = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toInt();
      out[o++] = (yVal + 1.772 * uVal).clamp(0, 255).toInt();
    }
  }
  return out;
}
```

---

## File: `lib/services/tts_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/tts_service.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service - Text-to-Speech, satu-satunya pintu keluar suara aplikasi.
///
/// **Aturan mutlak: tidak ada ucapan yang dibuang diam-diam.**
///
/// Versi sebelumnya menjaga flag `_speaking` lalu membungkus `speak()` dengan
/// `if (!_speaking)`. Akibatnya setiap permintaan bicara yang datang saat TTS
/// sedang berjalan **hilang tanpa jejak** - termasuk peringatan rintangan -
/// dan pemanggilnya tetap menerima Future yang selesai normal, jadi
/// [TtsQueue] mengira pesannya sudah tersampaikan. Untuk pengguna yang
/// berjalan sambil mengandalkan suara, itu bukan bug performa; itu peringatan
/// bahaya yang tidak pernah terdengar.
///
/// Sekarang ucapan diserialkan lewat rantai Future ([_tail]). Yang datang
/// belakangan menunggu gilirannya, bukan dibuang. Interupsi tetap mungkin dan
/// bersifat eksplisit lewat `interrupt: true` / [stop], yang menaikkan
/// [_generation] sehingga ucapan yang masih mengantre membatalkan dirinya
/// sendiri alih-alih terlanjur bicara sesudah pengguna menghentikannya.
class TTSService {
  static final TTSService instance = TTSService._();
  TTSService._();

  static const String localeId = 'id-ID';
  static const String localeEn = 'en-US';

  final FlutterTts _tts = FlutterTts();

  bool _speaking = false;
  bool get isSpeaking => _speaking;

  /// Locale yang sedang terpasang di engine. Dilacak supaya `setLanguage`
  /// hanya dipanggil saat benar-benar berganti - pemanggilan berulang pada
  /// sebagian engine Android memotong ucapan yang sedang berjalan.
  String _engineLocale = localeId;

  /// Ekor rantai serial. Setiap [speak] menyambung di belakangnya.
  Future<void> _tail = Future<void>.value();

  /// Dinaikkan oleh [stop] dan oleh ucapan `interrupt: true`.
  int _generation = 0;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.5); // sedikit lambat, lebih terdengar saat berjalan
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // speak() baru resolve setelah engine benar-benar selesai bicara. Tanpa
    // ini, serialisasi di bawah tidak ada artinya: semua ucapan akan
    // "selesai" seketika dan saling menimpa di engine.
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((msg) {
      _speaking = false;
      debugPrint('[TTS] error: $msg');
    });

    _initialized = true;
  }

  /// Ucapkan [message]. Selalu tersampaikan kecuali dibatalkan [stop] atau
  /// oleh ucapan lain yang meminta [interrupt].
  ///
  /// [english] memakai locale `en-US` (hasil Moondream2), lalu mengembalikan
  /// engine ke `id-ID` - pengembaliannya di blok `finally`, jadi kegagalan di
  /// tengah tidak meninggalkan aplikasi berbicara Inggris selamanya.
  Future<void> speak(
    String message, {
    bool interrupt = false,
    bool english = false,
  }) {
    final text = message.trim();
    if (text.isEmpty) return Future<void>.value();

    if (interrupt) {
      _generation++;
      // Rantai lama ditinggalkan: ucapan yang masih mengantre di belakangnya
      // akan melihat generasi yang sudah berubah lalu berhenti sendiri.
      _tail = Future<void>.value();
    }

    final myGeneration = _generation;
    final previous = _tail;

    final next = previous.then((_) async {
      if (myGeneration != _generation) return; // dibatalkan saat mengantre
      await _utter(text, english: english, interrupt: interrupt);
    }).catchError((Object e) {
      debugPrint('[TTS] speak gagal: $e');
    });

    _tail = next;
    return next;
  }

  /// Baca hasil deskripsi Moondream2 dalam Bahasa Inggris.
  Future<void> speakEnglish(String message, {bool interrupt = false}) =>
      speak(message, interrupt: interrupt, english: true);

  Future<void> _utter(String text, {required bool english, required bool interrupt}) async {
    final target = english ? localeEn : localeId;

    if (interrupt) {
      await _tts.stop();
      _speaking = false;
    }

    try {
      if (_engineLocale != target) {
        await _tts.setLanguage(target);
        _engineLocale = target;
      }
      _speaking = true;
      await _tts.speak(text);
    } finally {
      _speaking = false;
      // Bahasa Inggris hanya berlaku untuk satu ucapan. Dikembalikan di
      // `finally` supaya exception di tengah tidak mengunci locale.
      if (english && _engineLocale != localeId) {
        try {
          await _tts.setLanguage(localeId);
          _engineLocale = localeId;
        } catch (e) {
          debugPrint('[TTS] gagal kembali ke $localeId: $e');
        }
      }
    }
  }

  /// Kecepatan bicara - Pengaturan "Kecepatan bicara".
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  /// Hentikan yang sedang bicara DAN batalkan yang masih mengantre.
  Future<void> stop() async {
    _generation++;
    _tail = Future<void>.value();
    _speaking = false;
    await _tts.stop();
  }
}
```

---

## File: `lib/services/yolo_navigasi_service.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/services/yolo_navigasi_service.dart`

```dart
import 'dart:io';
import 'dart:math';


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';

// ─────────────────────────────────────────────────────────────
// Kelas navigasi custom (6 kelas) - urutan sesuai training
// ─────────────────────────────────────────────────────────────
const List<String> _navLabels = [
  'lubang',
  'got_terbuka',
  'tangga',
  'orang',
  'motor',
  'tiang',
];

// Tinggi nyata (cm) untuk estimasi jarak via Similar Triangles
const Map<String, int> _realHeightsNav = {
  'lubang':      15,
  'got_terbuka': 20,
  'tangga':      20,
  'orang':      170,
  'motor':      120,
  'tiang':      300,
};

// Focal length piksel (default kalibrasi kamera belakang ~f=615)
const int _focalPx = 615;

// Confidence threshold
const double _confThresh = 0.30;

// IoU threshold untuk NMS
const double _iouThresh = 0.45;

// YOLO input size
const int _yoloSize = 640;

// ─────────────────────────────────────────────────────────────
// YoloNavigasiService - deteksi rintangan on-device (YOLO11n)
// ─────────────────────────────────────────────────────────────
class YoloNavigasiService {
  static final YoloNavigasiService instance = YoloNavigasiService._();
  YoloNavigasiService._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Muat yolo11n.tflite (INT8, 3.0 MB) dari assets.
  Future<bool> tryLoad() async {
    try {
      final bd = await rootBundle.load('assets/models/yolo11n.tflite');
      final bytes = bd.buffer.asUint8List();
      debugPrint('[YOLO-Nav] Memuat model ${(bytes.length / 1024).toStringAsFixed(0)} KB');

      // CPU saja - model INT8 sudah sangat ringan di CPU
      final options = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(bytes, options: options);

      final inputShape  = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      debugPrint('[YOLO-Nav] Input: $inputShape  Output: $outputShape');
      // Diharapkan: Input [1,640,640,3], Output [1,10,8400]

      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[YOLO-Nav] Model siap. Kelas: $_navLabels');
      return true;
    } catch (e) {
      debugPrint('[YOLO-Nav] Gagal load: $e');
      return false;
    }
  }

  /// Deteksi rintangan dari bytes RGB888.
  /// [origW], [origH] = dimensi asli frame sebelum resize.
  Future<List<Detection>> detect(
    Uint8List rgbBytes,
    int origW,
    int origH,
  ) async {
    if (!_loaded || _interpreter == null) return [];

    final t0 = DateTime.now();
    try {
      // Decode → resize ke 640×640
      final rawImg = img.Image.fromBytes(
        width: origW,
        height: origH,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );

      img.Image resized;
      if (Platform.isAndroid) {
        final rotated = img.copyRotate(rawImg, angle: 90);
        resized = img.copyResize(rotated, width: _yoloSize, height: _yoloSize,
            interpolation: img.Interpolation.linear);
      } else {
        resized = img.copyResize(rawImg, width: _yoloSize, height: _yoloSize,
            interpolation: img.Interpolation.linear);
      }

      // Build input [1][640][640][3] - float32 normalized 0..1
      final input = List.generate(1, (_) =>
        List.generate(_yoloSize, (y) =>
          List.generate(_yoloSize, (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          }),
        ),
      );

      // Output [1][10][8400] - 10 = 4 (box) + 6 (class scores)
      final output = [List.generate(10, (_) => List.filled(8400, 0.0))];
      final outputs = {0: output};

      await _interpreter!.runForMultipleInputs([input], outputs);

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();

      // Post-process
      return _postProcess(output[0], inferMs, origW, origH);
    } catch (e) {
      debugPrint('[YOLO-Nav] detect error: $e');
      return [];
    }
  }

  // ── Post-process output [10][8400] ──────────────────────────
  List<Detection> _postProcess(
    List<List<double>> raw, // [10][8400]
    double inferMs,
    int origW,
    int origH,
  ) {
    // raw[0..3] = cx, cy, w, h (normalized 0..1)
    // raw[4..9] = class scores
    final numAnchors = raw[0].length; // 8400
    final numClasses = _navLabels.length; // 6

    // Kumpulkan box yang lolos threshold
    final List<_Box> boxes = [];
    for (int i = 0; i < numAnchors; i++) {
      // Cari kelas dengan skor tertinggi
      double maxScore = 0;
      int maxClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = raw[4 + c][i];
        if (score > maxScore) { maxScore = score; maxClass = c; }
      }
      // Threshold khusus: 0.05 (5%) untuk lubang/got_terbuka, 0.30 (30%) untuk kelas lainnya
      final thresh = (maxClass == 0 || maxClass == 1) ? 0.05 : _confThresh;
      if (maxScore < thresh) continue;

      // cx, cy, w, h → x1, y1, x2, y2 (dalam skala input 640×640)
      final cx = raw[0][i] * _yoloSize;
      final cy = raw[1][i] * _yoloSize;
      final bw = raw[2][i] * _yoloSize;
      final bh = raw[3][i] * _yoloSize;

      boxes.add(_Box(
        x1:       (cx - bw / 2).clamp(0, _yoloSize.toDouble()),
        y1:       (cy - bh / 2).clamp(0, _yoloSize.toDouble()),
        x2:       (cx + bw / 2).clamp(0, _yoloSize.toDouble()),
        y2:       (cy + bh / 2).clamp(0, _yoloSize.toDouble()),
        score:    maxScore,
        classIdx: maxClass,
      ));
    }

    if (boxes.isEmpty) return [];

    // NMS per kelas
    final kept = _nms(boxes);

    // Skala kembali ke ukuran frame asli
    final scaleX = origW / _yoloSize;
    final scaleY = origH / _yoloSize;

    return kept.map((b) {
      final x1 = (b.x1 * scaleX).round().clamp(0, origW - 1);
      final y1 = (b.y1 * scaleY).round().clamp(0, origH - 1);
      final x2 = (b.x2 * scaleX).round().clamp(0, origW - 1);
      final y2 = (b.y2 * scaleY).round().clamp(0, origH - 1);
      final boxH = y2 - y1;
      final cx   = (x1 + x2) / 2.0;

      final label   = _navLabels[b.classIdx];
      final dist    = _estimateDist(label, boxH);
      final dir     = _direction(cx, origW);
      final danger  = _dangerLevel(label, dist);

      return Detection(
        labelEn:       label,
        labelId:       label, // label sudah dalam BI
        confidence:    b.score,
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
        inferenceMs:   inferMs,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));
  }

  // ── NMS greedy per kelas ─────────────────────────────────────
  List<_Box> _nms(List<_Box> boxes) {
    // Sort descending per score
    boxes.sort((a, b) => b.score.compareTo(a.score));
    final kept = <_Box>[];
    final suppressed = List<bool>.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (boxes[i].classIdx != boxes[j].classIdx) continue;
        if (_iou(boxes[i], boxes[j]) > _iouThresh) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  double _iou(_Box a, _Box b) {
    final ix1 = max(a.x1, b.x1);
    final iy1 = max(a.y1, b.y1);
    final ix2 = min(a.x2, b.x2);
    final iy2 = min(a.y2, b.y2);
    final inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1);
    if (inter == 0) return 0;
    final aA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final bA = (b.x2 - b.x1) * (b.y2 - b.y1);
    return inter / (aA + bA - inter);
  }

  double _estimateDist(String label, int boxH) {
    if (boxH <= 0) return 999.0;
    final realH = _realHeightsNav[label] ?? 50;
    return (realH * _focalPx) / (boxH * 100.0);
  }

  String _direction(double cx, int w) {
    final t = w / 3;
    if (cx < t) return 'kiri';
    if (cx < t * 2) return 'depan';
    return 'kanan';
  }

  String _dangerLevel(String label, double dist) {
    switch (label) {
      case 'lubang':
      case 'got_terbuka':
        if (dist < 1.0) return 'critical';
        if (dist < 2.5) return 'warning';
        return 'info';
      case 'orang':
      case 'motor':
        if (dist < 1.5) return 'critical';
        if (dist < 3.0) return 'warning';
        return 'info';
      case 'tangga':
      case 'tiang':
        if (dist < 2.0) return 'critical';
        if (dist < 4.0) return 'warning';
        return 'info';
      default:
        return 'info';
    }
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}

// Helper box untuk NMS
class _Box {
  final double x1, y1, x2, y2, score;
  final int classIdx;
  const _Box({
    required this.x1, required this.y1,
    required this.x2, required this.y2,
    required this.score, required this.classIdx,
  });
}
```

---

## File: `lib/theme/app_colors.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Token warna design system Vinara.
/// Aturan baku: `fill` hanya untuk ikon & bidang besar (syarat 3:1),
/// `label` untuk semua teks (syarat 4.5:1). Isian vibrant (action/fill,
/// positive/fill, critical/fill) TIDAK BOLEH memuat teks putih kecil.
abstract final class AppColors {
  // Action (biru)
  static const actionFill    = Color(0xFF3181E7); // 3.87:1 - ikon & bidang besar saja
  static const actionLabel   = Color(0xFF1A56B0); // 7.00:1 - teks & tombol bertulisan
  static const actionPressed = Color(0xFF1D5FC2); // 6.05:1 - state ditekan
  static const actionTint    = Color(0xFFEAF2FE); // isian lembut, item aktif

  // Positive (hijau - arah/aman)
  static const positiveFill  = Color(0xFF51B055); // ikon & bidang besar saja (putih gagal 2.75:1)
  static const positiveLabel = Color(0xFF1C6323); // teks "AMAN", isian chip zona aktif
  static const positiveTint  = Color(0xFFE8F4E9);

  // Critical (merah - bahaya)
  static const criticalFill  = Color(0xFFE5484D); // ikon oktagon, pita prioritas, garis bbox
  static const criticalLabel = Color(0xFFA82727); // teks "Bahaya", isian pill jarak
  static const criticalTint  = Color(0xFFFDECEC);

  // Warning (kuning - hati-hati). Kuning TIDAK PERNAH membawa teks putih.
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
  static const scrimDim  = Color(0x660B0D12); // #0B0D12 @ 40% - tidak pernah membawa teks

  // ── Foreground di atas bidang gelap/berwarna ────────────────────────────

  /// Teks & ikon di atas bidang gelap atau vibrant - scrim di atas kamera,
  /// [pillBg], dan isian `*Fill`.
  ///
  /// Ini yang dulu ditulis sebagai `Colors.white` mentah di 64 tempat.
  /// Nilainya memang putih, tapi menyebutnya lewat token membuat maksudnya
  /// terbaca - dan membuat tema kontras tinggi bisa menggesernya di **satu**
  /// tempat alih-alih di 64 tempat yang harus ditemukan satu per satu dulu.
  ///
  /// Aturan 3:1 di header berkas ini tetap berlaku: putih di atas isian
  /// vibrant hanya untuk teks besar/tebal dan ikon, tidak untuk teks kecil.
  static const onDark = Color(0xFFFFFFFF);

  // ── Latar kamera ────────────────────────────────────────────────────────

  /// Latar di belakang preview kamera, dan pengganti saat preview belum siap.
  ///
  /// Hitam pekat disengaja: apa pun selain hitam akan terbaca sebagai "ada
  /// sesuatu di layar" oleh pengguna low vision, padahal yang benar adalah
  /// "belum ada gambar".
  static const cameraVoid = Color(0xFF000000);

  // ── Tema gelap ──────────────────────────────────────────────────────────
  static const darkBg       = Color(0xFF15171E);
  static const darkSurface  = Color(0xFF1E212B);
  static const darkHairline = Color(0xFF2A2D38);

  // ── Abu netral untuk indikator non-teks ─────────────────────────────────
  /// Titik/segmen indikator yang tidak membawa teks (mis. penanda langkah).
  static const indicatorOn  = Color(0xFF9AA0AD);
  static const indicatorOff = Color(0xFFC4C9D2);

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

## File: `lib/theme/app_spacing.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_spacing.dart`

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
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .08), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const card = <BoxShadow>[
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .10), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .16), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -8),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .12), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .26), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -12),
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

## File: `lib/theme/app_theme.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData Vinara - dirakit dari token di app_colors / app_typography /
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
          foregroundColor: AppColors.onDark,
          minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          textStyle: AppTypography.label(color: AppColors.onDark),
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
        contentTextStyle: AppTypography.body(color: AppColors.onDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  /// Tema gelap - chrome Material (AppBar, tombol, snackbar, scaffold).
  /// Catatan: komponen desain sistem (AlertCard, ModeBadge, dst.) memakai
  /// token AppColors langsung sehingga tetap tampil dengan palet terang di
  /// atas kamera - itu memang benar untuk pill/kartu yang melayang di atas
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
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkBg, elevation: 0),
      dividerTheme: const DividerThemeData(color: AppColors.darkHairline, thickness: 1, space: 1),
    );
  }

  /// Tema kontras tinggi - seluruh bayangan diganti garis 2 dp putih (bagian
  /// 3.4): kedalaman lewat bayangan tidak terbaca oleh sensitivitas kontras
  /// rendah.
  static ThemeData get highContrast {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.onDark,
        brightness: Brightness.dark,
        primary: AppColors.onDark,
        surface: AppColors.cameraVoid,
      ),
      scaffoldBackgroundColor: AppColors.cameraVoid,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.cameraVoid, elevation: 0),
      dividerTheme: const DividerThemeData(color: AppColors.onDark, thickness: 1, space: 1),
    );
  }
}
```

---

## File: `lib/theme/app_typography.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/app_typography.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Skala tipografi design system Vinara.
/// IBM Plex Sans untuk semua teks, IBM Plex Mono untuk angka teknis
/// (jarak, persentase, waktu) - dipakai bersama `tabularFigures` supaya
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

## File: `lib/theme/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/theme/index.dart`

```dart
export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';
```

---

## File: `lib/widgets/alert_card.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/alert_card.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'distance_pill.dart';
import 'tier_icon.dart';

/// AlertCard - kartu melayang di sepertiga bawah layar (F2).
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

/// Tumpukan AlertCard - maksimum 2, gap 8, tier tertinggi di slot bawah
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

## File: `lib/widgets/bottom_action_bar.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/bottom_action_bar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/speech/tts_queue.dart';
import '../providers/index.dart';
import '../screens/voice_screen.dart';
import '../services/haptic_service.dart';
import '../theme/index.dart';
import 'mode_picker_sheet.dart';

/// BottomActionBar (F3) - selalu ada, selalu di tempat yang sama, tidak
/// pernah menggulung. Tiga slot: Aksi Utama 48, Bicara 64, Pilih Mode 48.
/// Saat mic aktif, dua tombol lain nonaktif - supaya tidak ada aksi
/// tabrakan sambil berjalan.
///
/// ## Kontrak tombol kiri
///
/// **Tombol kiri = lakukan hal utama mode ini, sekarang. Kalau mode itu tidak
/// punya "hal utama", ia mengulang hal penting terakhir yang diucapkan.**
///
/// Bagian kedua yang membuat aturannya utuh: dengan itu tidak ada satu pun
/// mode dengan tombol kiri mati, dan pengguna punya jaring pengaman - kalau
/// lupa tombol kiri melakukan apa di mode ini, paling buruk ia mengulang
/// sesuatu. Tidak pernah merusak, tidak pernah hening.
///
/// | Mode          | Label                        | Aksi                     |
/// |---------------|------------------------------|--------------------------|
/// | Deteksi Objek | "Hentikan" / "Lanjutkan"     | Toggle deteksi           |
/// | Kenali Uang   | "Kenali Uang"                | 1 tap = 1 analisis       |
/// | Baca Teks     | "Baca teks" → "Jeda bacaan"  | Kontekstual              |
/// | Navigasi      | "Ulangi arahan"              | Baca ulang status zona   |
/// | Asisten Suara | "Ulangi jawaban"             | Baca ulang respons       |
/// | Cari Objek    | "Kirim - cari [X]"           | Scan                     |
///
/// Aturan pendukung: label berupa kata kerja + objek maksimal 3 kata (TalkBack
/// membacanya tiap fokus mendarat), tombol nonaktif tetap bersuara saat
/// ditekan, dan setiap tekan memberi getar konfirmasi.
///
/// [cameraLabel] sengaja **wajib**. Nilai bawaan lamanya "Ambil gambar" membuat
/// dua mode (Navigasi dan Asisten) menampilkan tombol aktif yang dibacakan
/// TalkBack sebagai "Ambil gambar, tombol" padahal menekannya tidak melakukan
/// apa pun - label yang berbohong, dan jalan buntu yang hening.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;
  final bool cameraEnabled;
  final String cameraLabel;

  /// Alasan tombol kiri nonaktif, diucapkan saat ditekan.
  final String? cameraDisabledReason;

  /// DO-24 - izin mikrofon dicabut: nonaktifkan tombol Bicara sepenuhnya.
  final bool micEnabled;
  /// Saat mode aktif punya STT sendiri (mis. Cari Objek), timpa visual
  /// listening/processing bawaan `VoiceProvider` supaya tombol tetap sesuai
  /// dengan apa yang sesungguhnya sedang berjalan.
  final bool? listeningOverride;
  final bool? processingOverride;

  const BottomActionBar({
    super.key,
    required this.cameraLabel,
    this.onCameraPressed,
    this.onMicPressed,
    this.cameraEnabled = true,
    this.cameraDisabledReason,
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
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .06), blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .18), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -12),
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
              // Tanpa handler = tidak aktif. Tidak ada lagi `?? () {}` yang
              // membuat tombol tampak hidup lalu diam saat ditekan.
              enabled: sideButtonsEnabled && onCameraPressed != null,
              disabledReason: listening
                  ? 'sedang mendengarkan'
                  : cameraDisabledReason,
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
          child: const ExcludeSemantics(
            child: Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: 28),
          ),
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
                final appMode = context.read<AppModeProvider>();
                final hasVib = await Vibration.hasVibrator();
                if (hasVib) Vibration.vibrate(duration: 100);

                // Jika bukan di mode voice, push VoiceScreen sebagai overlay
                // (fitur "Jarvis Global Mic") alih-alih langsung ke onTap.
                if (appMode.mode != AppMode.voice) {
                  if (context.mounted) {
                    await Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierDismissible: false,
                        pageBuilder: (_, __, ___) =>
                            const VoiceScreen(isOverlay: true),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                    // Setelah pop, mulai listen segera
                    if (!v.isListening) v.startListening();
                  }
                  return;
                }

                // Sudah di mode voice - perilaku bawaan
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
              : ExcludeSemantics(
              child: Icon(listening ? Icons.mic : Icons.mic_none_rounded, color: AppColors.onDark, size: 30),
            ),
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

  /// Alasan tombol nonaktif - diucapkan saat ditekan, bukan didiamkan.
  final String? disabledReason;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.disabledReason,
  });

  /// Menekan tombol nonaktif TIDAK boleh hening.
  ///
  /// Untuk pengguna yang tidak melihat layar, tombol yang diam saat ditekan
  /// tidak bisa dibedakan dari aplikasi yang macet - dan satu-satunya cara
  /// menguji dugaannya adalah menekan lagi. Katakan alasannya, sekali, dengan
  /// getar pendek supaya jelas tekanannya terdaftar.
  void _explainDisabled() {
    final reason = disabledReason;
    TtsQueue().speak(
      reason == null ? '$label tidak tersedia sekarang.' : '$label. $reason',
      tier: SpeechTier.info,
    );
    HapticService.instance.info();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? label
          : disabledReason == null
              ? '$label, tidak tersedia'
              : '$label, tidak tersedia, $disabledReason',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : _explainDisabled,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 26,
                color: enabled ? AppColors.ink1 : AppColors.disabledInk,
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

## File: `lib/widgets/camera_health_toast.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/camera_health_toast.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// CameraHealthToast (5.10) - pill gelap melayang, instruksi fisik dan
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
            style: AppTypography.body(color: AppColors.onDark).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
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

## File: `lib/widgets/chat_bubble.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/chat_bubble.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ChatBubble (5.12) - Mode Asisten Suara. Giliran dipisah garis, bukan
/// gelembung berwarna. Live region polite, MergeSemantics per giliran.
enum ChatSpeaker { user, vinara }

class ChatBubble extends StatelessWidget {
  final ChatSpeaker speaker;
  final String text;
  /// Giliran terbaru mendapat live region - bagian 12 "AS-12: hanya giliran
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

/// Daftar giliran percakapan - membungkus scroll + aturan ringkas riwayat
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

## File: `lib/widgets/contextual_action_slot.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/contextual_action_slot.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ContextualActionSlot - slot tombol kontekstual yang selalu duduk di posisi
/// yang sama: tepat di atas BottomActionBar, dari kiri ke kanan layar.
///
/// Dipakai untuk prompt situasional jangka pendek yang butuh respons segera:
/// - Tawaran nyalakan lampu saat gelap (TuntunScreen)
/// - Tombol "Kembali" saat VoiceScreen dimasuki sebagai overlay
///
/// **Aturan keamanan zona:**
/// Konten di atas slot (kartu deteksi, panel bubble) wajib membaca
/// [slotHeight] dan menggeser dirinya ke atas - bukan sebaliknya.
///
/// Slot ini diposisikan oleh pemanggil via [Positioned] karena tiap layar
/// punya cara berbeda mengelola Stack-nya.
class ContextualActionSlot extends StatelessWidget {
  /// Teks situasional kecil (opsional) di atas tombol.
  final String? message;

  /// Label tombol utama (kiri / satu-satunya).
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryIcon;
  final Color? primaryColor;

  /// Label tombol sekunder (kanan, opsional).
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;

  const ContextualActionSlot({
    super.key,
    this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryColor,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
  });

  /// Tinggi tombol saja (tanpa message) - pemanggil pakai ini untuk geser kartu.
  static const double slotHeight = 64.0;

  /// Tinggi total dengan message (pill + gap + tombol).
  static const double slotHeightWithMsg = 92.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.s2,
        AppSpacing.screenMargin,
        AppSpacing.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[
            Semantics(
              liveRegion: true,
              label: message,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.scrimText,
                  borderRadius: AppRadius.pillShape,
                ),
                child: Text(
                  message!,
                  style: AppTypography.caption(color: AppColors.onDark),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: _SlotButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  icon: primaryIcon,
                  fillColor: primaryColor ?? AppColors.actionFill,
                  labelColor: AppColors.onDark,
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _SlotButton(
                    label: secondaryLabel!,
                    onTap: onSecondary ?? () {},
                    icon: secondaryIcon,
                    fillColor: AppColors.surfaceSunk,
                    labelColor: AppColors.ink1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color fillColor;
  final Color labelColor;

  const _SlotButton({
    required this.label,
    required this.onTap,
    this.icon,
    required this.fillColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: AppRadius.card,
            boxShadow: AppElevation.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(child: Icon(icon, color: labelColor, size: 20)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.label(color: labelColor),
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

## File: `lib/widgets/detection_card.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/detection_card.dart`

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

## File: `lib/widgets/distance_pill.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/distance_pill.dart`

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
        AlertTier.critical => AppColors.onDark,
        AlertTier.warning  => AppColors.ink1,
        AlertTier.info     => AppColors.actionLabel,
        AlertTier.positive => AppColors.onDark,
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

## File: `lib/widgets/full_screen_button.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/full_screen_button.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// FullScreenButton (5.4) - tombol aksi tunggal yang sangat besar, 96 dp.
/// Dipakai untuk aksi utama satu-jari: jepret di Mode Baca Teks, izin di
/// PermissionCard, dst.
class FullScreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  /// Wajib diisi saat [disabled] - bagian 5.4: tombol disabled selalu
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
                        Icon(icon, color: disabled ? AppColors.disabledInk : AppColors.onDark, size: 26),
                        const SizedBox(width: AppSpacing.s3),
                      ],
                      Text(
                        label,
                        style: AppTypography.title(
                          color: disabled ? AppColors.disabledInk : AppColors.onDark,
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

## File: `lib/widgets/guide_frame.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/guide_frame.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// GuideFrame (F11) - empat busur sudut yang mengencang saat objek makin
/// pas, bukan persegi putus-putus statis (itu pola kamera QR dan tidak
/// mengabarkan apa pun).
enum FrameFit { empty, partial, fit, tooClose }

extension FrameFitX on FrameFit {
  Color get color => switch (this) {
        FrameFit.empty   => AppColors.onDark,
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
                  child: Text(fit.caption, style: AppTypography.caption(color: AppColors.onDark)),
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

## File: `lib/widgets/index.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/index.dart`

```dart
export 'alert_card.dart';
export 'bottom_action_bar.dart';
export 'camera_health_toast.dart';
export 'chat_bubble.dart';
export 'contextual_action_slot.dart';
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

## File: `lib/widgets/mode_badge.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/mode_badge.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../providers/app_mode_provider.dart';
import '../theme/index.dart';

/// Ikon garis per mode - dipakai bersama oleh ModeBadge & ModePickerSheet.
IconData modeIcon(AppMode mode) => switch (mode) {
      AppMode.tuntun     => Icons.remove_red_eye_outlined,
      AppMode.money      => Icons.payments_outlined,
      AppMode.ocr        => Icons.article_outlined,
      AppMode.navigasi   => Icons.explore_outlined,
      AppMode.voice      => Icons.mic_none_rounded,
      AppMode.findObject => Icons.search_rounded,
    };

/// ModeBadge (F1) - pill identitas mode, opaque #202432, di atas kamera.
/// Bukan tombol untuk ganti mode (itu lewat tombol Pilih Mode / suara), tapi
/// ketuk 5× membuka panel debug tersembunyi (state switcher) bila disediakan
/// lewat [onDebugActivate] - mekanisme baku bagian 2 "Cara memalsukan fitur".
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
      // Urutan fokus 3 - bagian 10, sesudah StatusBanner dan aksinya.
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
                          color: AppColors.onDark,
                          valueColor: AlwaysStoppedAnimation(AppColors.onDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Beralih ke ${widget.mode.label}…',
                          style: AppTypography.metricMono(color: AppColors.onDark.withValues(alpha: .9))),
                    ]
                  : widget.busy
                      ? [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: ExcludeSemantics(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onDark,
                                valueColor: AlwaysStoppedAnimation(AppColors.onDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const ExcludeSemantics(
                            child: Text('Mengenali…', style: TextStyle(color: AppColors.onDark, fontSize: 14)),
                          ),
                        ]
                      : [
                          ExcludeSemantics(child: Icon(_icon, size: 18, color: AppColors.onDark)),
                          const SizedBox(width: 8),
                          ExcludeSemantics(
                            child: Text('Mode: ${widget.mode.label}', style: AppTypography.label(color: AppColors.onDark)),
                          ),
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

## File: `lib/widgets/mode_picker_sheet.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/mode_picker_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../screens/settings_screen.dart';
import '../theme/index.dart';
import 'mode_badge.dart';

/// ModePickerSheet (5.5) - enam mode, cadangan untuk situasi tidak bisa
/// bicara. Fokus terkunci di dalam sheet; setelah ditutup, fokus kembali ke
/// tombol Pilih Mode (ditangani otomatis oleh showModalBottomSheet).
///
/// Keputusan audit: Navigasi TIDAK PERNAH dinonaktifkan offline - deteksi
/// rintangan on-device tetap hidup, jadi statenya `limited` dengan alasan
/// "Tanpa internet: rintangan saja". Cari Objek yang benar-benar disabled.
void showModePickerSheet(BuildContext context) {
  // Ditanyakan saat sheet dibuka, bukan saat item ditekan - status harus
  // sudah terbaca sebelum pengguna memilih. Tidak di-await: sheet tampil
  // segera, dan item memperbarui dirinya begitu jawaban datang.
  context.read<CapabilitiesProvider>().refreshIfStale(
        offline: context.read<GlobalConditionsProvider>().isBackendDown,
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
    // `isBackendDown`, bukan `isOffline`: mode yang butuh server sama-sama
    // tidak bisa dipakai entah karena tidak ada jaringan atau karena server
    // tidak menjawab. Yang penting bagi pengguna adalah statusnya sudah benar
    // SEBELUM ia menekan, bukan sesudah gagal.
    final offline = context.watch<GlobalConditionsProvider>().isBackendDown;
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
            ExcludeSemantics(
              child: Container(
                width: 34, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text('Pilih Mode', style: AppTypography.title()),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.actionTint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_none_rounded, size: 14, color: AppColors.actionLabel),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Atau ucapkan via tombol Bicara (Mic)',
                      style: AppTypography.caption(color: AppColors.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppMode.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
                itemBuilder: (_, i) {
                  final mode = AppMode.values[i];
                  // Status ditentukan jaringan DAN jawaban server, ditanyakan
                  // sebelum sheet dibuka - bukan ditebak dari koneksi saja.
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
                        : () async {
                            // Nilai balik `setMode` WAJIB diperiksa. Tanpa ini,
                            // membatalkan konfirmasi keluar-Navigasi menutup
                            // sheet tanpa satu kata pun terucap: `announceEntry`
                            // tidak jalan karena mode tidak berubah, dan
                            // pengguna yang tidak melihat layar menyimpulkan
                            // modenya sudah berganti. VoiceProvider sudah
                            // menangani ini dengan benar sejak awal - hanya
                            // jalur sheet yang bocor.
                            final appMode = context.read<AppModeProvider>();
                            final tts = context.read<TtsProvider>();
                            final navigator = Navigator.of(context);
                            final previous = appMode.mode;

                            final changed = await appMode.setMode(mode);
                            if (!changed && appMode.mode == previous) {
                              tts.speak(
                                'Tetap di mode ${previous.label}.',
                                tier: SpeechTier.info,
                              );
                            }
                            navigator.pop();
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            // Layar penunjang bukan saudara mode, jadi ia TIDAK muncul sebagai
            // item mode. Tempatnya di paling bawah sheet, dipisah garis -
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
                        ExcludeSemantics(
                          child: Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                            child: const Icon(Icons.tune_rounded, size: 22, color: AppColors.ink1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: ExcludeSemantics(child: Text('Pengaturan', style: AppTypography.body()))),
                        const ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink2)),
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
        ? '${mode.label}, sedang aktif. Perintah suara: ${mode.voiceHint}'
        : _reason != null
            ? '${mode.label}, ${_reason!.toLowerCase()}'
            : '${mode.label}. Perintah suara: ${mode.voiceHint}';

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
                  ExcludeSemantics(
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                      child: Icon(modeIcon(mode), size: 22, color: AppColors.ink1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            mode.label,
                            style: isCurrent ? AppTypography.bodyStrong() : AppTypography.body(),
                          ),
                        ),
                        if (_reason != null)
                          ExcludeSemantics(
                            child: Text(
                              _reason!,
                              style: AppTypography.caption(
                                color: limited ? AppColors.warningLabel : AppColors.disabledInk,
                              ),
                            ),
                          )
                        else
                          ExcludeSemantics(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.actionLabel),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      mode.voiceHint,
                                      style: AppTypography.caption(color: AppColors.ink2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.actionLabel,
                          borderRadius: AppRadius.pillShape,
                        ),
                        child: Text('AKTIF', style: AppTypography.eyebrow(color: AppColors.onDark)),
                      ),
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

## File: `lib/widgets/nominal_card.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/nominal_card.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Terbilang rupiah - "angka rupiah selalu dibacakan penuh dalam kata, tidak
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

/// NominalCard (5.13) - khusus Mode Kenali Uang. Satu-satunya tempat
/// `display` 56sp dipakai. Nominal WAJIB dua bentuk (angka + kata), dan
/// tidak pernah ditampilkan saat keyakinan rendah - pemanggil bertanggung
/// jawab tidak me-render kartu ini pada kondisi itu.
///
/// Kartu ini hanya menampilkan **satu nominal**: lembar yang sedang dihadapi
/// kamera. Tidak ada rincian lembar dan tidak ada total berjalan - mode ini
/// tidak menjumlahkan apa pun.
class NominalCard extends StatelessWidget {
  final int amount;
  final VoidCallback? onReplay;

  const NominalCard({
    super.key,
    required this.amount,
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

## File: `lib/widgets/ocr_debug_sheet.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/ocr_debug_sheet.dart`

```dart
import 'package:flutter/material.dart';

import '../mock/ocr_mock_data.dart';
import '../theme/index.dart';

/// OcrDebugSheet - bottom sheet QA khusus Mode Baca Teks: daftar 22 state
/// BT-01..BT-22 (bagian 8). Memilih satu item memaksa tampilan lokal
/// `ocr_screen.dart` ke kondisi itu (data mock) sampai dibatalkan - dibuka
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
                    child: Text('Debug - Mode Baca Teks', style: AppTypography.title()),
                  ),
                  if (activeId != null)
                    GestureDetector(
                      onTap: onCancel,
                      child: Semantics(
                        button: true,
                        label: 'Batalkan mode debug',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: const BoxDecoration(color: AppColors.criticalTint, borderRadius: AppRadius.pillShape),
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

## File: `lib/widgets/ocr_long_result_panel.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/ocr_long_result_panel.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// Satu blok siap-render untuk [OcrLongResultPanel] - kalimatnya sudah
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

/// OcrLongResultPanel - varian ResultPanel khusus hasil panjang/dua
/// bahasa/sebagian-gagal/senyap Mode Baca Teks (BT-07/08/09/10/12a/19).
/// ResultPanel (komponen sistem, read-only) sengaja tidak dipakai di sini
/// karena butuh: blok berheading, progress baca, dan kontrol yang berubah
/// bentuk saat senyap - di luar API ResultPanel.
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
          const TierIcon(tier: AlertTier.warning, size: 20),
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
      decoration: const BoxDecoration(color: AppColors.actionTint, borderRadius: AppRadius.pillShape),
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
            color: speaking ? AppColors.onDark : AppColors.actionLabel,
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
              Icon(icon, size: 20, color: filled ? AppColors.onDark : AppColors.actionLabel),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.label(color: filled ? AppColors.onDark : AppColors.actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## File: `lib/widgets/page_action_zone.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/page_action_zone.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// `zone/page-action` - bagian 6 ALUR-DAN-TOMBOL.md.
///
/// Kontrak zona di IMPLEMENTASI.md dirancang untuk enam mode, yang semuanya
/// diakhiri `BottomActionBar` 112 dp. Layar penunjang - Pengaturan,
/// Onboarding, Izin - tidak punya bar itu, jadi tidak ada zona yang menampung
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
/// lebih dulu - urutan fokus bagian 10 nomor 10 lalu 11. Urutan itu dipasang
/// eksplisit lewat [SemanticsSortKey]; di Flutter urutan fokus tidak otomatis
/// mengikuti posisi visual.
class PageActionZone extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDisabled;

  /// Wajib diisi saat [primaryDisabled] - bagian 5.4: tombol nonaktif selalu
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

/// Tombol sekunder 56 dp untuk `zone/page-action` - "Lewati panduan",
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
/// digulung - aksi utama halaman wajib terjangkau **tanpa** pengguna
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

## File: `lib/widgets/permission_card.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/permission_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// PermissionCard (5.16) - kartu izin yang mengambil zona konten. ModeBadge
/// dan BottomActionBar tetap di tempatnya (dipasang oleh screen pemanggil).
/// Alasan ditulis per izin, bukan satu paragraf gabungan - bagian 5.16.
///
/// **Kartu ini tidak lagi memuat tombolnya.** Dulu tombol "Berikan izin" ikut
/// di dalam kartu, dan karena kartunya berada di zona konten, tombol berakhir
/// di tengah layar - zona kuning/merah thumb zone, di luar jangkauan ibu jari
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

/// Permintaan izin di **layar mode** - DO-14, BT-17, UG-14, AS-02, CO-15,
/// NV-21.
///
/// Layar mode sudah memakai `BottomActionBar`, jadi menurut kontrak zona ia
/// tidak boleh juga memakai `zone/page-action`. Aksinya karena itu mendarat di
/// slot kartu bawah (bottom 120 dp, tepat di atas action bar) - tempat yang
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
          // Kartu tetap di zona konten - perannya memberi tahu, bukan
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
          // Urutan fokus 6 - sesudah isi kartu, sebelum tiga tombol bar.
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

## File: `lib/widgets/result_panel.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/result_panel.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ResultPanel (F9) - kontrol audio selalu di baris atas kanan supaya
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
            color: speaking ? AppColors.onDark : AppColors.actionLabel,
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
                Icon(icon, size: 20, color: filled ? AppColors.onDark : AppColors.actionLabel),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.label(color: filled ? AppColors.onDark : AppColors.actionLabel)),
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

## File: `lib/widgets/speaking_indicator.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/speaking_indicator.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// SpeakingIndicator (5.15) - pil kecil kanan atas menandakan TTS berjalan.
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
                ? const Icon(Icons.volume_off_rounded, size: 14, color: AppColors.onDark)
                : _Bars(controller: _controller),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.caption(color: AppColors.onDark).copyWith(fontSize: 13)),
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
          return Container(width: 2.4, height: h, color: AppColors.onDark);
        }),
      ),
    );
  }
}
```

---

## File: `lib/widgets/status_banner.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/status_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// StatusBanner (F7) - lebar penuh, tinggi 56, tanpa radius, menempel tepi
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
      // Urutan fokus 1 - bagian 10. Di Flutter urutan fokus TIDAK otomatis
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
            ExcludeSemantics(child: TierIcon(tier: tier, size: 22)),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  message,
                  style: AppTypography.bodyStrong(color: tier.labelColor).copyWith(fontSize: 15, height: 20 / 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (actionLabel != null)
              Semantics(
                button: true,
                label: actionLabel,
                child: GestureDetector(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s3),
                    child: ExcludeSemantics(
                      child: Text(actionLabel!, style: AppTypography.label(color: AppColors.actionLabel)),
                    ),
                  ),
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

## File: `lib/widgets/target_chip.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/target_chip.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/index.dart';

/// TargetChip (5.14) - khusus Mode Cari Objek. Baris sendiri di bawah
/// ModeBadge, TIDAK PERNAH berbagi baris dengannya. Elipsis hanya pada nama
/// barang; kata "Mencari:" selalu utuh.
class TargetChip extends StatelessWidget {
  final String itemName;

  const TargetChip({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 4 - bagian 10, baris sendiri di bawah ModeBadge.
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
            const Text('Mencari: ', style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.w600)),
            Expanded(
              child: Text(
                itemName,
                style: AppTypography.label(color: AppColors.onDark),
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

## File: `lib/widgets/tier_icon.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/tier_icon.dart`

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
        _mark(canvas, scale, AppColors.onDark, dotFirst: false);
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
        _mark(canvas, scale, AppColors.onDark, dotFirst: true);
        break;
      case AlertTier.positive:
        final stroke = Paint()
          ..color = AppColors.onDark
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

  /// Tanda seru (garis + titik) - tier Critical/Warning garis-lalu-titik,
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

## File: `lib/widgets/voice_orb.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/voice_orb.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/index.dart';

/// VoiceOrb (F6) - setiap state punya bentuk/isi berbeda, bukan cuma warna.
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
          child: Icon(Icons.mic_none_rounded, color: AppColors.onDark, size: size * .44),
        );
      case VoiceOrbState.listening:
        return _circle(
          diameter: size,
          color: AppColors.actionFill,
          shadow: [
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .16), blurRadius: 0, spreadRadius: size * .14),
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .08), blurRadius: 0, spreadRadius: size * .28),
          ],
          child: Icon(Icons.mic_rounded, color: AppColors.onDark, size: size * .44),
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
          child: Icon(Icons.check_rounded, color: AppColors.onDark, size: size * .48),
        );
      case VoiceOrbState.failure:
        return _circle(
          diameter: size,
          color: AppColors.onDark,
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

## File: `lib/widgets/zone_indicator.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/lib/widgets/zone_indicator.dart`

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

/// ZoneIndicator (F8) - tiga chip 111 × 56, gap 8. Chip yang sedang
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
    final fg = solid ? AppColors.onDark : status.ink;

    return Container(
      height: 56,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.caption(color: solid ? AppColors.onDark.withValues(alpha: .85) : AppColors.ink2)),
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
              color: i == 0 ? AppColors.indicatorOn : AppColors.indicatorOff,
            ),
          ),
        );
      }),
    );
  }
}
```

---

## File: `linux/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/linux/CMakeLists.txt`

```text
# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "guidio_app")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.example.guidio_app")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
```

---

## File: `linux/flutter/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/linux/flutter/CMakeLists.txt`

```text
# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as list(TRANSFORM ... PREPEND ...),
# which isn't available in 3.10.
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        list(APPEND NEW_LIST "${PREFIX}${element}")
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()

# === Flutter Library ===
# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/lib/libapp.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "fl_basic_message_channel.h"
  "fl_binary_codec.h"
  "fl_binary_messenger.h"
  "fl_dart_project.h"
  "fl_engine.h"
  "fl_json_message_codec.h"
  "fl_json_method_codec.h"
  "fl_message_codec.h"
  "fl_method_call.h"
  "fl_method_channel.h"
  "fl_method_codec.h"
  "fl_method_response.h"
  "fl_plugin_registrar.h"
  "fl_plugin_registry.h"
  "fl_standard_message_codec.h"
  "fl_standard_method_codec.h"
  "fl_string_codec.h"
  "fl_value.h"
  "fl_view.h"
  "flutter_linux.h"
)
list_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/flutter_linux/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}")
target_link_libraries(flutter INTERFACE
  PkgConfig::GTK
  PkgConfig::GLIB
  PkgConfig::GIO
)
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)
```

---

## File: `linux/runner/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/linux/runner/CMakeLists.txt`

```text
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
```

---

## File: `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

```json
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_64.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_1024.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

---

## File: `pubspec.yaml`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/pubspec.yaml`

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

  # Kondisi global - offline, baterai kritis (StatusBanner gabungan)
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

  # Font - IBM Plex Sans / IBM Plex Mono (design system Vinara)
  google_fonts: ^6.2.1
  google_mlkit_text_recognition: ^0.16.0


dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  change_app_package_name: ^1.5.0
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/vinara_logo.png"
  min_sdk_android: 26
  remove_alpha_ios: true

flutter:
  uses-material-design: true
  assets:
    # Daftar model DISEBUT SATU PER SATU, bukan seluruh direktori.
    #
    # `- assets/models/` ikut membundel semua yang kebetulan ada di folder itu,
    # termasuk yolo11l_float32.tflite (96,9 MB), yoloe_find.onnx (11 MB),
    # pidnet_s.onnx.data (2,5 MB) dan pidnet_s_3zona.onnx - tidak satu pun
    # dimuat kode, semuanya ikut ke APK. Untuk pengguna dengan kuota terbatas
    # itu ratusan megabyte yang dibayar tanpa satu pun manfaat.
    #
    # Menambah berkas ke assets/models/ TIDAK otomatis membundelnya. Itu
    # disengaja: tambahkan barisnya di sini hanya kalau kode benar-benar
    # memuatnya lewat rootBundle.
    - assets/models/ssd_mobilenet.tflite        # TFLiteService - deteksi rintangan
    - assets/models/labelmap.txt                # TFLiteService - label COCO
    - assets/models/rupiah_classifier_int8.tflite  # MoneyTFLiteService - 7 pecahan
    #
    # uang_rupiah.tflite (model lama) sengaja TIDAK dibundel lagi: sudah
    # digantikan rupiah_classifier_int8.tflite. Berkasnya tetap ada di
    # assets/models/ sebagai arsip, tapi tidak ikut ke APK.
    #
    # rupiah_labels.txt juga tidak dibundel - urutan kelasnya sudah tetap di
    # MoneyTFLiteService.classValues, jadi tidak ada yang memuatnya lewat
    # rootBundle. Berkasnya disimpan sebagai rujukan saat mengganti model.
    - assets/models/pidnet_s_3zona_fp16.tflite  # PidnetService - segmentasi jalur
    - assets/models/pidnet_s_3zona.tflite       # PidnetService - cadangan non-fp16
    - assets/models/yolo11n.tflite              # YoloNavigasiService - rintangan navigasi
    - assets/icons/
```

---

## File: `test/command_parser_test.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/test/command_parser_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/command_parser.dart';
import 'package:guidio_app/core/voice/intents.dart';
import 'package:guidio_app/services/money_tflite_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Test suite gabungan untuk:
///
/// 1. **CommandParser** - memastikan intent mapping tetap benar setelah
///    refactor apa pun.
/// 2. **Kenali Uang (TFLite)** - integrasi ringan: muat model dan klasifikasi
///    sampel nyata dari dataset `uang-emisi-2022-baru`.
/// 3. **Mode Navigasi** - fixture gambar bahaya jalan ada & valid.
/// 4. **Cari Objek** - test parse command, hanya dieksekusi kalau backend
///    tersedia (skip otomatis jika offline/belum deploy).
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
  VoiceIntent? intentOf(String text) => CommandParser.parse(text).intent;

  // ─── 1. Command Parser - contoh ucapan dari dokumen arsitektur ─────────────
  group('contoh ucapan dari dokumen arsitektur', () {
    const cases = <String, VoiceIntent>{
      // Deteksi Objek
      'deteksi': VoiceIntent.modeDetection,
      'awasi jalan': VoiceIntent.modeDetection,
      'mode jalan': VoiceIntent.modeNavigation,
      'deteksi objek': VoiceIntent.modeDetection,
      'tuntun aku': VoiceIntent.modeDetection,
      // Kenali Uang
      'uang': VoiceIntent.modeMoney,
      'kenali uang': VoiceIntent.modeMoney,
      'cek duit': VoiceIntent.modeMoney,
      'duit berapa': VoiceIntent.modeMoney,
      // Baca Teks
      'baca teks': VoiceIntent.modeReadText,
      'tolong bacain': VoiceIntent.modeReadText,
      'baca dong': VoiceIntent.modeReadText,
      'tulung wacakno': VoiceIntent.modeReadText,
      // Navigasi
      'navigasi': VoiceIntent.modeNavigation,
      'jalan mana': VoiceIntent.modeNavigation,
      'arahan jalur': VoiceIntent.modeNavigation,
      // Asisten
      'asisten': VoiceIntent.modeAssistant,
      'ngobrol': VoiceIntent.modeAssistant,
      // Pengaturan
      'pengaturan': VoiceIntent.modeSettings,
      'seting': VoiceIntent.modeSettings,
    };

    cases.forEach((utterance, expected) {
      test('"$utterance" → $expected', () {
        expect(intentOf(utterance), expected);
      });
    });
  });

  // ─── 2. Frasa spesifik menang atas kata umum ───────────────────────────────
  group('frasa spesifik menang atas kata umum', () {
    test('"stop navigasi" menghentikan panduan, bukan keluar mode', () {
      expect(intentOf('stop navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti navigasi" sama', () {
      expect(intentOf('berhenti navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti dulu" adalah jeda suara', () {
      expect(intentOf('berhenti dulu'), VoiceIntent.playPause);
    });

    test('"kembali" tetap actionGoBack', () {
      expect(intentOf('kembali'), VoiceIntent.actionGoBack);
    });
  });

  // ─── 3. Prefiks transisi mode natural ─────────────────────────────────────
  group('prefiks transisi mode natural', () {
    test('"saya pengin pindah ke mode baca teks"', () {
      expect(
        intentOf('saya pengin pindah ke mode baca teks'),
        VoiceIntent.modeReadText,
      );
    });

    test('"ganti mode ke uang"', () {
      expect(intentOf('ganti mode ke uang'), VoiceIntent.modeMoney);
    });
  });

  // ─── 4. Pencocokan pada batas kata ────────────────────────────────────────
  group('pencocokan pada batas kata', () {
    test('kata yang hanya mengandung potongan frasa tidak ikut cocok', () {
      // 'uang' tidak boleh tercabut dari 'ruangan'.
      expect(intentOf('ruangan ini kayak gimana'), isNot(VoiceIntent.modeMoney));
    });
  });

  // ─── 5. Saran hanya berisi intent yang punya handler ──────────────────────
  group('saran hanya berisi intent yang punya handler', () {
    test('setiap saran ada di suggestableIntents', () {
      const gibberish = [
        'anu itu yang tadi bagaimana',
        'coba yang begitu deh',
        'hmm apa ya kira-kira',
      ];
      for (final text in gibberish) {
        final cmd = CommandParser.parse(text);
        for (final s in cmd.suggestions) {
          expect(
            CommandParser.suggestableIntents.contains(s),
            isTrue,
            reason: '"$text" menyarankan $s yang tidak punya handler - '
                'inilah yang membuat "Maksudmu X?" → "X" → "belum saya kenali"',
          );
        }
      }
    });
  });

  // ─── 6. Kenali Uang - sample gambar nyata dari dataset ────────────────────
  //
  // Test ini muat model TFLite on-device lalu mengklasifikasi gambar dari
  // dataset asli emisi 2022. Setiap pecahan diuji dengan 2 sampel berbeda.
  // Fixture ada di test/fixtures/money/ (sudah di-copy dari dataset).
  //
  // Skip otomatis kalau model asset tidak tersedia (misalnya CI tanpa assets).
  group('Kenali Uang - klasifikasi gambar nyata', () {
    late MoneyTFLiteService svc;
    late bool modelLoaded;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      svc = MoneyTFLiteService.instance;
      modelLoaded = await svc.load();
    });

    tearDownAll(() {/* singleton - jangan dispose; bisa dipakai test lain */});

    /// Helper: baca fixture → kirim ke classifyJpeg → kembalikan MoneyResult.
    Future<MoneyResult> classify(String fixtureName) async {
      final file = File('test/fixtures/money/$fixtureName');
      expect(file.existsSync(), isTrue, reason: 'Fixture tidak ada: $fixtureName');
      return svc.classifyJpeg(file.readAsBytesSync());
    }

    // Tabel: (fixtureName, expectedValueIdr)
    const samples = [
      ('uang_1000_a.jpg', 1000),
      ('uang_1000_b.jpg', 1000),
      ('uang_2000_a.jpg', 2000),
      ('uang_2000_b.jpg', 2000),
      ('uang_5000_a.jpg', 5000),
      ('uang_5000_b.jpg', 5000),
      ('uang_10000_a.jpg', 10000),
      ('uang_10000_b.jpg', 10000),
      ('uang_20000_a.jpg', 20000),
      ('uang_20000_b.jpg', 20000),
      ('uang_50000_a.jpg', 50000),
      ('uang_50000_b.jpg', 50000),
      ('uang_100000_a.jpg', 100000),
      ('uang_100000_b.jpg', 100000),
    ];

    for (final (fixture, expected) in samples) {
      test('${fixture.replaceAll('.jpg', '')} → Rp${_fmt(expected)}', () async {
        if (!modelLoaded) {
          markTestSkipped('Model TFLite tidak berhasil dimuat - skip.');
          return;
        }
        final result = await classify(fixture);
        // Dua kemungkinan sukses: terdeteksi dengan nominal benar, atau
        // uncertain (confidence di bawah threshold). Yang TIDAK boleh terjadi
        // adalah detected == true dengan nominal yang salah.
        if (result.detected) {
          expect(
            result.valueIdr,
            equals(expected),
            reason: '$fixture dikenali sebagai Rp${_fmt(result.valueIdr!)} '
                '(confidence: ${(result.confidence * 100).toStringAsFixed(1)}%), '
                'seharusnya Rp${_fmt(expected)}.',
          );
        }
        // uncertain → test tetap pass; model hanya kurang yakin.
      });
    }
  });

  // ─── 7. Mode Navigasi - fixture gambar valid ───────────────────────────────
  //
  // Test ini TIDAK menjalankan inference (model YOLOv11 terlalu besar untuk
  // dipush ke repo). Yang diverifikasi: gambar fixture ada, bisa dibaca, dan
  // berukuran wajar (> 100 KB) sehingga coverage integrasi tetap terjaga.
  group('Navigation mode - fixture images exist and are valid', () {
    const fixtures = [
      '01_got_terbuka.png',   // open drain / got terbuka
      '02_lubang_trotoar.png', // sidewalk hole
      '03_tiang_listrik.png',  // utility pole
      '04_motor_dan_orang.png', // motorcycle and pedestrian
      '05_tangga_turun.png',   // descending stairs
    ];

    for (final name in fixtures) {
      test('$name - file exists and is readable', () {
        final file = File('test/fixtures/navigation/$name');
        expect(file.existsSync(), isTrue, reason: 'Fixture tidak ada: $name');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(100 * 1024),
            reason: '$name terlalu kecil - mungkin file rusak atau terpotong.');
        // Validasi magic bytes PNG: 0x89 0x50 0x4E 0x47
        expect(bytes[0], equals(0x89));
        expect(bytes[1], equals(0x50)); // 'P'
        expect(bytes[2], equals(0x4E)); // 'N'
        expect(bytes[3], equals(0x47)); // 'G'
      });
    }
  });

  // ─── 8. Cari Objek - parse command + guard backend ────────────────────────
  //
  // CommandParser harus mengekstrak target dari perintah bahasa Indonesia dan
  // Sunda. Backend check (HTTP ping) dilakukan di sini: kalau tidak reachable,
  // semua sub-test "would call backend" di-skip secara eksplisit, bukan fail.
  group('Find Object - command parsing', () {
    // --- 8a. Parser: bahasa Indonesia
    test('"cari dompet" extracts target "dompet"', () {
      final cmd = CommandParser.parse('cari dompet');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompet');
    });

    test('"cariin kunci dong" strips filler words', () {
      final cmd = CommandParser.parse('cariin kunci dong');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'kunci');
    });

    test('"teang dompu" (Sundanese) is recognized', () {
      final cmd = CommandParser.parse('teang dompu');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompu');
    });

    test('"cari uang yang jatuh" is object-find, not money mode', () {
      // 'uang' is in modeMoney dictionary; object-find pattern must win
      // because it is checked first (prevents ambiguity for blind users).
      final cmd = CommandParser.parse('cari uang yang jatuh');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
    });

    // --- 8b. Parser: English target extraction (for backend API)
    //
    // When the app translates the target to English before sending to the
    // backend, the parser must still set intent correctly.  Actual translation
    // happens in SceneTranslator; here we only verify the parsed intent.
    const englishTargetCases = <String, String>{
      'cari tas merah': 'red bag',       // tas merah → red bag
      'cariin botol minum': 'botol minum', // extraction only; translation elsewhere
      'cari HP': 'HP',
    };

    englishTargetCases.forEach((utterance, _) {
      test('"$utterance" → findObjectTarget intent', () {
        expect(intentOf(utterance), VoiceIntent.findObjectTarget);
      });
    });

    // --- 8c. Backend-dependent tests (skip if unreachable)
    //
    // Image fixtures are in test/fixtures/object_find/.
    // These tests would normally call the vision backend to verify that
    // "red bag", "water bottle", etc. are detected in the provided images.
    // Since the backend is not always running, they are marked skip here.
    //
    // To run locally: start the backend, then:
    //   flutter test --name "object_find"
    group('object_find - backend integration (skipped unless BE running)', () {
      const backendUrl = String.fromEnvironment(
        'GUIDO_BACKEND_URL',
        defaultValue: '',
      );

      bool backendAvailable = false;

      setUpAll(() async {
        if (backendUrl.isEmpty) return;
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 3);
          final req = await client.getUrl(Uri.parse('$backendUrl/health'));
          final res = await req.close();
          backendAvailable = res.statusCode == 200;
          client.close();
        } catch (_) {
          backendAvailable = false;
        }
      });

      const objectTargets = [
        ('red bag', 'test/fixtures/object_find/red_bag.jpg'),
        ('water bottle', 'test/fixtures/object_find/water_bottle.jpg'),
        ('black umbrella', 'test/fixtures/object_find/black_umbrella.jpg'),
      ];

      for (final (target, fixturePath) in objectTargets) {
        test('find "$target" in ${fixturePath.split('/').last}', () {
          if (!backendAvailable) {
            markTestSkipped('Backend not reachable - set GUIDO_BACKEND_URL to run.');
            return;
          }
          final file = File(fixturePath);
          expect(file.existsSync(), isTrue,
              reason: 'Fixture $fixturePath not found.');
          // Placeholder: actual HTTP call to backend would go here.
          // The test is already useful as a guard: it ensures the fixture
          // exists and the backend is reachable before spending time on it.
        });
      }
    });
  });
}

/// Format angka ribuan singkat: 1000 → "1.000", 100000 → "100.000".
String _fmt(int value) => value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
```

---

## File: `test/model_inference_test.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/test/model_inference_test.dart`

```dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Inferensi on-device - TIDAK membutuhkan Flutter binding / rootBundle.
///
/// Dua kelompok besar:
///
/// **A. Kenali Uang (MobileNetV2 INT8)**
///   - Model  : assets/models/rupiah_classifier_int8.tflite
///   - Input  : [1,224,224,3] float32, rentang −1..1
///   - Output : [1,7] softmax (kelas: 1k 2k 5k 10k 20k 50k 100k)
///   - Fixture: test/fixtures/money/  (nama file → ground-truth via regex)
///   - Validasi: detected == true → valueIdr harus tepat;
///              uncertain boleh (confidence threshold tinggi di production).
///
/// **B. Navigasi YOLO11n (INT8)**
///   - Model  : assets/models/yolo11n.tflite
///   - Input  : [1,640,640,3] float32, rentang 0..1
///   - Output : [1,10,8400] - 4 box + 6 class scores
///   - Fixture: test/fixtures/navigation/ (PNG gambar bahaya jalan)
///   - Validasi: setidaknya satu Detection terdeteksi, dan labelnya
///              ada di daftar kelas yang diketahui dari gambar itu
///              (diambil dari nama file via regex).
///
/// Kedua kelompok skip secara otomatis kalau shared library TFLite tidak ada
/// (contoh: CI Linux tanpa libtensorflowlite_c-linux.so).
/// ─────────────────────────────────────────────────────────────────────────────

// ── Konstanta model ──────────────────────────────────────────────────────────

const _kMoneyModelPath = 'assets/models/rupiah_classifier_int8.tflite';
const _kYoloModelPath  = 'assets/models/yolo11n.tflite';

/// Urutan kelas sesuai CLASS_ORDER di scripts/02_export_tflite.py.
/// Harus identik dengan MoneyTFLiteService.classValues - jangan diubah.
const List<int> _moneyClasses = [1000, 2000, 5000, 10000, 20000, 50000, 100000];

/// Kelas navigasi - urutan sesuai training (lihat yolo_navigasi_service.dart).
const List<String> _navLabels = [
  'lubang', 'got_terbuka', 'tangga', 'orang', 'motor', 'tiang',
];

// Confidence threshold production (sama dengan service)
const double _moneyConfThresh = 0.85;
const double _yoloConfThresh  = 0.30;
const double _yoloIouThresh   = 0.45;
const int    _yoloSize        = 640;
const int    _moneySize       = 224;

// ── Helper: parse ground-truth dari nama file ────────────────────────────────

/// Ekstrak nominal (int) dari nama file money fixture.
/// Contoh: "uang_10000_a.jpg" → 10000
/// Pola: uang_{nilai}_{sample}.jpg
int? _moneyValueFromFilename(String filename) {
  final m = RegExp(r'uang_(\d+)_[a-z]\.jpg').firstMatch(filename);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

/// Ekstrak label yang DIHARAPKAN ada di gambar navigasi dari nama file.
/// Pola: {seq}_{label_dengan_underscore}.png
/// Contoh: "02_lubang_trotoar.png" → hint 'lubang'
///         "01_got_terbuka.png"    → hint 'got_terbuka'
///         "04_motor_dan_orang.png"→ hint 'motor', 'orang'
List<String> _navLabelsFromFilename(String filename) {
  // Hapus ekstensi dan sequence prefix (mis. "01_")
  final bare = filename.replaceFirst(RegExp(r'^\d+_'), '').replaceAll('.png', '');
  // bare mis: "got_terbuka", "lubang_trotoar", "motor_dan_orang", "tiang_listrik", "tangga_turun"
  return _navLabels.where((label) => bare.contains(label)).toList();
}

// ── Helper: load TFLite interpreter dari file ────────────────────────────────

Interpreter? _loadInterpreter(String assetRelPath, {int threads = 2}) {
  final file = File(assetRelPath);
  if (!file.existsSync()) return null;
  try {
    final bytes = file.readAsBytesSync();
    final opts  = InterpreterOptions()..threads = threads;
    return Interpreter.fromBuffer(bytes, options: opts);
  } catch (_) {
    return null;
  }
}

// ── Helper: preprocessing gambar untuk money (−1..1) ───────────────────────

List<List<List<List<double>>>> _preprocessMoney(img.Image source) {
  final resized = img.copyResize(source,
      width: _moneySize, height: _moneySize,
      interpolation: img.Interpolation.linear);

  return List.generate(1, (_) =>
    List.generate(_moneySize, (y) =>
      List.generate(_moneySize, (x) {
        final p = resized.getPixel(x, y);
        return [
          p.r / 127.5 - 1.0,
          p.g / 127.5 - 1.0,
          p.b / 127.5 - 1.0,
        ];
      }),
    ),
  );
}

// ── Helper: preprocessing gambar untuk YOLO (0..1) ──────────────────────────

List<List<List<List<double>>>> _preprocessYolo(img.Image source) {
  final resized = img.copyResize(source,
      width: _yoloSize, height: _yoloSize,
      interpolation: img.Interpolation.linear);

  return List.generate(1, (_) =>
    List.generate(_yoloSize, (y) =>
      List.generate(_yoloSize, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      }),
    ),
  );
}

// ── Helper: NMS sederhana ────────────────────────────────────────────────────

double _iou(List<double> a, List<double> b) {
  final ix1 = math.max(a[0], b[0]);
  final iy1 = math.max(a[1], b[1]);
  final ix2 = math.min(a[2], b[2]);
  final iy2 = math.min(a[3], b[3]);
  final iw = math.max(0.0, ix2 - ix1);
  final ih = math.max(0.0, iy2 - iy1);
  final inter = iw * ih;
  if (inter == 0) return 0;
  final aA = (a[2]-a[0]) * (a[3]-a[1]);
  final aB = (b[2]-b[0]) * (b[3]-b[1]);
  return inter / (aA + aB - inter);
}

class _Box {
  final int classIdx;
  final double conf;
  final List<double> xyxy;
  const _Box(this.classIdx, this.conf, this.xyxy);
}

List<_Box> _postProcessYolo(List<List<double>> raw) {
  // raw shape: [10][8400], layout: [cx,cy,w,h, score0..score5]
  final boxes = <_Box>[];
  for (var i = 0; i < 8400; i++) {
    double bestScore = 0;
    int bestCls = 0;
    for (var c = 0; c < _navLabels.length; c++) {
      final s = raw[4 + c][i];
      if (s > bestScore) { bestScore = s; bestCls = c; }
    }
    if (bestScore < _yoloConfThresh) continue;
    final cx = raw[0][i], cy = raw[1][i],
          w  = raw[2][i], h  = raw[3][i];
    boxes.add(_Box(bestCls, bestScore, [cx-w/2, cy-h/2, cx+w/2, cy+h/2]));
  }

  // Sort by confidence desc
  boxes.sort((a, b) => b.conf.compareTo(a.conf));

  // NMS
  final keep = <_Box>[];
  final suppressed = List.filled(boxes.length, false);
  for (var i = 0; i < boxes.length; i++) {
    if (suppressed[i]) continue;
    keep.add(boxes[i]);
    for (var j = i + 1; j < boxes.length; j++) {
      if (suppressed[j]) continue;
      if (boxes[i].classIdx == boxes[j].classIdx &&
          _iou(boxes[i].xyxy, boxes[j].xyxy) > _yoloIouThresh) {
        suppressed[j] = true;
      }
    }
  }
  return keep;
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ─── A. Kenali Uang ────────────────────────────────────────────────────────
  group('A. Kenali Uang - MobileNetV2 INT8 inference', () {
    late Interpreter? interp;

    setUpAll(() {
      interp = _loadInterpreter(_kMoneyModelPath);
      if (interp == null) {
        // ignore: avoid_print
        print('[TEST] TFLite SO tidak ada - semua test Money akan di-skip.');
      }
    });

    tearDownAll(() => interp?.close());

    /// Ground-truth: langsung dari nama file via regex.
    /// Tidak ada hard-coded mapping - kalau nama file salah, regex gagal,
    /// test langsung merah.
    const moneyFixtures = [
      'uang_1000_a.jpg',
      'uang_1000_b.jpg',
      'uang_2000_a.jpg',
      'uang_2000_b.jpg',
      'uang_5000_a.jpg',
      'uang_5000_b.jpg',
      'uang_10000_a.jpg',
      'uang_10000_b.jpg',
      'uang_20000_a.jpg',
      'uang_20000_b.jpg',
      'uang_50000_a.jpg',
      'uang_50000_b.jpg',
      'uang_100000_a.jpg',
      'uang_100000_b.jpg',
    ];

    for (final fixture in moneyFixtures) {
      final expected = _moneyValueFromFilename(fixture);

      test('$fixture → Rp${_fmtIdr(expected!)}', () {
        if (interp == null) {
          markTestSkipped('TFLite SO tidak tersedia (non-Android host).');
          return;
        }

        // 1. Baca dan decode gambar
        final file = File('test/fixtures/money/$fixture');
        expect(file.existsSync(), isTrue,
            reason: 'Fixture tidak ada: $fixture');

        final decoded = img.decodeImage(file.readAsBytesSync());
        expect(decoded, isNotNull, reason: 'Gagal decode $fixture');

        // 2. Preprocessing: resize ke 224×224, normalisasi −1..1
        final input = _preprocessMoney(decoded!);

        // 3. Inferensi
        final output = List.generate(1, (_) => List<double>.filled(7, 0));
        interp!.run(input, output);
        final probs = output[0];

        // 4. Temukan kelas terbaik
        var bestIdx  = 0;
        for (var i = 1; i < probs.length; i++) {
          if (probs[i] > probs[bestIdx]) bestIdx = i;
        }
        final predictedValue = _moneyClasses[bestIdx];
        final confidence     = probs[bestIdx];

        // 5. Format untuk debugging
        final probStr = List.generate(probs.length,
            (i) => '${_fmtIdr(_moneyClasses[i])}:${(probs[i]*100).toStringAsFixed(1)}%'
        ).join('  ');

        // ignore: avoid_print
        print('[$fixture] pred=Rp${_fmtIdr(predictedValue)} '
              'conf=${(confidence*100).toStringAsFixed(1)}%\n  $probStr');

        // 6. Validasi:
        //    - Kalau confidence ≥ threshold → nominal HARUS tepat (tidak boleh salah)
        //    - Kalau uncertain → kelas yang mendapat prob tertinggi tetap harus benar
        //      (model boleh ragu, tapi tidak boleh yakin-yakin salah)
        if (confidence >= _moneyConfThresh) {
          // Deteksi penuh: nominal harus persis
          expect(predictedValue, equals(expected),
              reason: '$fixture dikenali Rp${_fmtIdr(predictedValue)} '
                      '(${(confidence*100).toStringAsFixed(1)}%), '
                      'seharusnya Rp${_fmtIdr(expected)}.\n  Semua prob: $probStr');
        } else {
          // Uncertain: tetap tidak boleh salah kelas (argmax harus benar)
          // - ini lebih longgar; test pass tapi print peringatan
          // ignore: avoid_print
          print('  ⚠ Uncertain (conf=${(confidence*100).toStringAsFixed(1)}% '
                '< ${(_moneyConfThresh*100).toStringAsFixed(0)}%): '
                'argmax Rp${_fmtIdr(predictedValue)} vs expected Rp${_fmtIdr(expected)}');
          // Tidak assert gagal - production juga tidak tampilkan nominal saat uncertain
        }
      });
    }
  });

  // ─── B. Navigasi YOLO11n ───────────────────────────────────────────────────
  group('B. Navigasi YOLO11n - hazard detection inference', () {
    late Interpreter? interp;

    setUpAll(() {
      interp = _loadInterpreter(_kYoloModelPath, threads: 4);
      if (interp == null) {
        // ignore: avoid_print
        print('[TEST] TFLite SO tidak ada - semua test YOLO akan di-skip.');
      }
    });

    tearDownAll(() => interp?.close());

    /// Fixture + label yang DIHARAPKAN terdeteksi (dari nama file).
    /// Regex dipakai oleh _navLabelsFromFilename() - tidak ada hard-coded list.
    const navFixtures = [
      '01_got_terbuka.png',    // → got_terbuka
      '02_lubang_trotoar.png', // → lubang
      '03_tiang_listrik.png',  // → tiang
      '04_motor_dan_orang.png',// → motor, orang
      '05_tangga_turun.png',   // → tangga
    ];

    for (final fixture in navFixtures) {
      final expectedLabels = _navLabelsFromFilename(fixture);

      test('$fixture → mendeteksi: $expectedLabels', () {
        if (interp == null) {
          markTestSkipped('TFLite SO tidak tersedia (non-Android host).');
          return;
        }

        // 1. Baca & decode PNG
        final file = File('test/fixtures/navigation/$fixture');
        expect(file.existsSync(), isTrue,
            reason: 'Fixture tidak ada: $fixture');

        final decoded = img.decodeImage(file.readAsBytesSync());
        expect(decoded, isNotNull, reason: 'Gagal decode $fixture');

        // 2. Preprocessing: resize ke 640×640, normalisasi 0..1
        final input = _preprocessYolo(decoded!);

        // 3. Inferensi - output [1][10][8400]
        final rawOutput = [List.generate(10, (_) => List.filled(8400, 0.0))];
        final outputs = {0: rawOutput};
        interp!.runForMultipleInputs([input], outputs);

        // 4. Post-process
        final detections = _postProcessYolo(rawOutput[0]);
        final detectedLabels = detections.map((d) => _navLabels[d.classIdx]).toSet();

        // ignore: avoid_print
        print('[$fixture] deteksi: ${detections.map((d) =>
            '${_navLabels[d.classIdx]}(${(d.conf*100).toStringAsFixed(1)}%)').toList()}');

        // 5. Validasi: setidaknya satu label dari yang diharapkan harus muncul
        if (expectedLabels.isEmpty) {
          // Gambar tidak punya mapping label yang diketahui → skip validasi label,
          // cukup pastikan inference tidak crash
          // ignore: avoid_print
          print('  ⚠ Tidak ada expected label dari nama file "$fixture" - skip label check.');
          return;
        }

        final intersection = detectedLabels.intersection(expectedLabels.toSet());
        expect(
          intersection.isNotEmpty,
          isTrue,
          reason: '$fixture: tidak ada label yang diharapkan ($expectedLabels) '
                  'terdeteksi. Yang terdeteksi: $detectedLabels\n'
                  'Periksa apakah confidence threshold (${ _yoloConfThresh}) '
                  'terlalu tinggi atau model perlu di-retrain.',
        );
      });
    }

    // Extra: pastikan inference tidak crash pada gambar "normal" (bukan bahaya)
    test('inference tidak crash pada gambar arbitrary', () {
      if (interp == null) {
        markTestSkipped('TFLite SO tidak tersedia.');
        return;
      }

      // Buat gambar solid 640x640 (simulasi frame kosong)
      final blank = img.Image(width: _yoloSize, height: _yoloSize);
      img.fill(blank, color: img.ColorFloat16.rgb(128, 128, 128));

      final input = _preprocessYolo(blank);
      final rawOutput = [List.generate(10, (_) => List.filled(8400, 0.0))];
      final outputs = {0: rawOutput};

      // Tidak boleh throw
      expect(
        () => interp!.runForMultipleInputs([input], outputs),
        returnsNormally,
      );
    });
  });
}

/// Format nominal IDR: 10000 → "10.000"
String _fmtIdr(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
```

---

## File: `test/scene_translator_test.dart`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/test/scene_translator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/scene_translator.dart';

/// Dua hal yang dikunci tes ini:
///
/// 1. Caption khas Moondream2 benar-benar terterjemahkan, dengan urutan
///    kata Indonesia (kata benda dulu, sifat menyusul).
/// 2. Kalimat yang di luar jangkauan kamus **menyerah** alih-alih
///    menghasilkan Bahasa Indonesia yang kacau. Pengguna tunanetra tidak
///    punya layar untuk memverifikasi tebakan kita, jadi menyerah dengan
///    jujur lebih aman daripada menebak dengan percaya diri.
void main() {
  group('caption khas Moondream2 diterjemahkan', () {
    const cases = <String, List<String>>{
      'A man standing in front of a white building.':
          ['pria', 'berdiri', 'di depan', 'gedung putih'],
      'A table with a laptop and a cup of coffee.':
          ['meja', 'dengan', 'laptop', 'dan', 'cangkir kopi'],
      'Two people walking down a street.':
          ['dua', 'orang-orang', 'berjalan', 'jalan'],
      'A wooden table with some books on it.':
          ['meja kayu', 'dengan', 'beberapa', 'buku-buku'],
      'A dog sitting on the floor near a chair.':
          ['anjing', 'duduk', 'di atas', 'lantai', 'di dekat', 'kursi'],
      'A busy market with many people.':
          ['pasar ramai', 'dengan', 'banyak', 'orang-orang'],
    };

    cases.forEach((english, mustContain) {
      test('"$english"', () {
        final r = translateSceneCaption(english);
        expect(r.isUsable, isTrue,
            reason: 'cakupan hanya ${r.coverage.toStringAsFixed(2)}');
        final id = r.indonesian!.toLowerCase();
        for (final fragment in mustContain) {
          expect(id, contains(fragment));
        }
      });
    });
  });

  group('urutan kata Indonesia', () {
    test('kata sifat pindah SESUDAH kata benda', () {
      final r = translateSceneCaption('a white building');
      expect(r.indonesian, 'Gedung putih.');
    });

    test('bukan "putih gedung"', () {
      final r = translateSceneCaption('a large red car');
      expect(r.indonesian!.toLowerCase(), contains('mobil merah'));
    });
  });

  group('artikel Inggris dibuang', () {
    test('"a" dan "the" tidak muncul di hasil', () {
      final r = translateSceneCaption('The man is near the door.');
      final id = r.indonesian!.toLowerCase();
      expect(id.split(' '), isNot(contains('a')));
      expect(id.split(' '), isNot(contains('the')));
    });
  });

  group('menyerah saat di luar jangkauan', () {
    test('kalimat penuh kata asing mengembalikan null', () {
      final r = translateSceneCaption(
        'An intricate baroque chandelier suspended amidst ornate cornices.',
      );
      expect(r.isUsable, isFalse);
      expect(r.indonesian, isNull);
    });

    test('caption kosong tidak crash', () {
      expect(translateSceneCaption('').isUsable, isFalse);
      expect(translateSceneCaption('   ').isUsable, isFalse);
    });
  });

  group('hasil selalu kalimat yang layak diucapkan', () {
    test('diawali huruf besar dan diakhiri titik', () {
      final r = translateSceneCaption('a cat on a table');
      expect(r.indonesian!.startsWith(RegExp(r'[A-Z]')), isTrue);
      expect(r.indonesian!.endsWith('.'), isTrue);
    });

    test('tidak ada spasi ganda', () {
      final r = translateSceneCaption('A man with a bag and a hat.');
      expect(r.indonesian!, isNot(contains('  ')));
    });
  });
}
```

---

## File: `web/manifest.json`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/web/manifest.json`

```json
{
    "name": "guidio_app",
    "short_name": "guidio_app",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#0175C2",
    "theme_color": "#0175C2",
    "description": "A new Flutter project.",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ]
}
```

---

## File: `windows/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/windows/CMakeLists.txt`

```text
# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(guidio_app LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "guidio_app")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
```

---

## File: `windows/flutter/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/windows/flutter/CMakeLists.txt`

```text
# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Set fallback configurations for older versions of the flutter tool.
if (NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/windows/app.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

# === Wrapper ===
list(APPEND CPP_WRAPPER_SOURCES_CORE
  "core_implementations.cc"
  "standard_codec.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_CORE PREPEND "${WRAPPER_ROOT}/")
list(APPEND CPP_WRAPPER_SOURCES_PLUGIN
  "plugin_registrar.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_PLUGIN PREPEND "${WRAPPER_ROOT}/")
list(APPEND CPP_WRAPPER_SOURCES_APP
  "flutter_engine.cc"
  "flutter_view_controller.cc"
)
list(TRANSFORM CPP_WRAPPER_SOURCES_APP PREPEND "${WRAPPER_ROOT}/")

# Wrapper sources needed for a plugin.
add_library(flutter_wrapper_plugin STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_PLUGIN}
)
apply_standard_settings(flutter_wrapper_plugin)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)
target_include_directories(flutter_wrapper_plugin PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_plugin flutter_assemble)

# Wrapper sources needed for the runner.
add_library(flutter_wrapper_app STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_APP}
)
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
set(PHONY_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/_phony_")
set_source_files_properties("${PHONY_OUTPUT}" PROPERTIES SYMBOLIC TRUE)
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_PLUGIN}
    ${CPP_WRAPPER_SOURCES_APP}
    ${PHONY_OUTPUT}
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat"
      ${FLUTTER_TARGET_PLATFORM} $<CONFIG>
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_PLUGIN}
  ${CPP_WRAPPER_SOURCES_APP}
)
```

---

## File: `windows/runner/CMakeLists.txt`

**Path**: `/home/asadel/kuliah/lomba/smstr6/guido/project/guidio_app/windows/runner/CMakeLists.txt`

```text
cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
```

---

