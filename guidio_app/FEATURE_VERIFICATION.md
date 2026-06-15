# 📋 Guidio Mobile — Feature Verification Checklist

> **Tujuan**: Verifikasi semua fitur mobile secara manual, tanpa koneksi backend.
> Centang setiap item saat sudah diuji. Status: `[ ]` belum, `[x]` sudah, `[-]` N/A.

---

## 🚀 A. App Startup

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| A1 | Install & buka app pertama kali | Muncul splash "Memulai Guidio..." + loading spinner warna biru di layar hitam | `[ ]` |
| A2 | App minta izin kamera | Dialog permintaan kamera muncul, **sebelum** izin mikrofon | `[ ]` |
| A3 | **Tolak** izin kamera | Muncul SnackBar merah: _"Izin kamera ditolak. Fitur kamera tidak tersedia."_ + tombol "Pengaturan" | `[ ]` |
| A4 | **Izinkan** kamera, tapi backend mati | Muncul SnackBar oranye: _"Backend tidak terhubung. Berjalan di Mode Lokal (TFLite)..."_ | `[ ]` |
| A5 | App berhasil boot (kamera ok, backend mati) | Layar Mode Tuntun (default) aktif, kamera preview langsung terlihat | `[ ]` |
| A6 | Orientasi portrait dipaksakan | Rotasi HP ke landscape → layar **tidak ikut** berputar | `[ ]` |

---

## 👁️ B. Mode Tuntun — Deteksi Objek (On-Device YOLO)

> **Offline 100% — tidak butuh backend sama sekali.**

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| B1 | Masuk Mode Tuntun (default saat boot) | Badge `Mode: Deteksi Objek` muncul pojok kiri atas, preview kamera fullscreen | `[ ]` |
| B2 | Arahkan ke **orang** dari jarak ±3m | Card deteksi muncul di bawah layar, TTS: _"Hati-hati, ada orang di depan"_ | `[ ]` |
| B3 | Majukan HP **mendekati** orang (< 1.5m) | TTS interrupt: _"Bahaya! Ada orang kurang dari 1 meter di depan"_, getar triple pulse | `[ ]` |
| B4 | Arahkan ke **kursi** dari jarak jauh | Tidak ada deteksi (distance filter: > 4m dibuang) | `[ ]` |
| B5 | Arahkan ke **motor/mobil** di kanan frame | TTS: _"Bahaya!... di kanan"_, arah terdeteksi 'kanan' | `[ ]` |
| B6 | Panggil **banyak objek** sekaligus | Maksimum **2** card muncul (Cognitive Load Theory limit) | `[ ]` |
| B7 | Objek sama muncul terus menerus | TTS **tidak** berbunyi setiap frame — ada cooldown (critical 2s, warning 3s, info 5s) | `[ ]` |
| B8 | Objek keluar dari frame | Card deteksi hilang, TTS berhenti | `[ ]` |
| B9 | Tutup dengan tangan / gelap total | Banner kuning: `"Kamera terlalu gelap"` + TTS: _"Kamera terlalu gelap"_ | `[ ]` |
| B10 | Miringkan HP > 45° | Banner: _"Kamera terlalu miring"_ (dari CameraHealthService) | `[ ]` |
| B11 | Muncul objek yang **sama** di frame berikutnya (flicker) | ID tracking tetap stabil, **tidak** ada TTS ganda (SORT tracker) | `[ ]` |
| B12 | Objek mendekat cepat (approaching) | Cooldown otomatis dipotong 50% → lebih sering bicara | `[ ]` |

### Kelas Objek yang Bisa Dideteksi TFLite (15 kelas COCO)

| Kelas | Bahasa Indonesia | Danger Level Default |
|-------|-----------------|---------------------|
| person | orang | High |
| motorcycle | motor | High |
| car | mobil | High |
| bus | bus | High |
| truck | truk | High |
| dog | anjing | High |
| bicycle | sepeda | Medium |
| chair | kursi | Medium |
| dining table | meja | Medium |
| cat | kucing | Info |
| backpack | tas | Info |
| umbrella | payung | Info |
| couch | sofa | Info |
| bed | kasur | Info |
| tv | TV | Info |

---

## 📳 C. Haptic Feedback (Vibration)

> **Offline 100% — dijalankan berdampingan TTS di setiap deteksi.**

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| C1 | Deteksi level **critical** (orang < 1.5m) | Triple pulse cepat: `[100ms ON] [50ms OFF] [100ms ON] [50ms OFF] [100ms ON]` | `[ ]` |
| C2 | Deteksi level **warning** (objek < 3m) | Double pulse sedang: `[200ms ON] [100ms OFF] [200ms ON]` | `[ ]` |
| C3 | Deteksi level **info** (objek jauh) | Single pulse panjang: `[300ms ON]` | `[ ]` |
| C4 | HP tanpa vibrator | App tidak crash, silent (fail gracefully) | `[ ]` |

---

## 📄 D. Mode OCR — Baca Teks

> ⚠️ **BUTUH BACKEND** — OCR diproses di server (`/api/ocr`). Tanpa backend, scan akan **gagal** dengan pesan TTS.

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| D1 | Pindah ke Mode OCR | Badge `Mode: Baca Teks`, TTS: _"Mode Baca Teks aktif"_, overlay kotak biru muncul di tengah | `[ ]` |
| D2 | Kamera tetap aktif di mode OCR | Preview kamera terlihat sebagai background, stream berjalan | `[ ]` |
| D3 | Tekan tombol kamera (tanpa backend) | Loading spinner muncul sebentar → TTS: _"Gagal membaca teks, coba lagi"_ | `[ ]` |
| D4 | *(Dengan backend)* Arahkan ke teks cetak, tekan kamera | Card "HASIL BACAAN" muncul, TTS membacakan teks | `[ ]` |
| D5 | *(Dengan backend)* Tekan **"Ulangi"** | TTS membacakan ulang teks hasil OCR | `[ ]` |
| D6 | *(Dengan backend)* Tekan **"Salin Teks"** | SnackBar: _"Teks disalin ke clipboard"_, clipboard berisi teks | `[ ]` |
| D7 | Tekan scan 2x berturut-turut cepat | Scan kedua diabaikan (mutex `_scanning = true`) | `[ ]` |

---

## 🧭 E. Mode Navigasi

> ⚠️ **GPS turn-by-turn BELUM diimplementasikan** (placeholder). Deteksi objek (YOLO) **tetap aktif offline**.

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| E1 | Pindah ke Mode Navigasi | Badge `Mode: Navigasi`, TTS: _"Mode Navigasi aktif"_, input tujuan muncul di atas | `[ ]` |
| E2 | Ketik tujuan & tekan "Mulai" | TTS: _"Mode navigasi aktif. Tujuan: [nama]. Fitur navigasi GPS segera hadir."_ — NavCard muncul | `[ ]` |
| E3 | NavCard muncul dengan pesan placeholder | Teks: _"Navigasi ke [tujuan] belum tersedia. GPS akan ditambahkan."_ | `[ ]` |
| E4 | Tekan ❌ di NavCard | Navigasi berhenti, kembali ke form input tujuan | `[ ]` |
| E5 | YOLO tetap mendeteksi obstacle di mode navigasi | Card obstacle tetap muncul di bawah (di atas bottom bar), TTS tetap bunyi | `[ ]` |
| E6 | Input tujuan kosong lalu tekan "Mulai" | Tidak ada aksi (validasi: `dest.isEmpty → return`) | `[ ]` |
| E7 | Daftar Favorit (jika ada) | Muncul di bawah input dengan icon bintang kuning; tap → langsung isi & mulai | `[ ]` |

---

## 🎙️ F. Mode Asisten Suara (Voice Assistant)

> ⚠️ **Intent routing Layer 2 (Claude Haiku) & describe_scene BUTUH BACKEND**.  
> **Layer 1 (keyword lokal) & STT tetap berjalan offline.**

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| F1 | Pindah ke Mode Asisten Suara | Badge `Mode: Asisten Suara`, TTS: _"Mode Asisten Suara aktif"_ | `[ ]` |
| F2 | Tekan tombol mic | State berubah → card _"Mendengarkan..."_ muncul | `[ ]` |
| F3 | Ucapkan kata yang tidak dikenali / diam | STT timeout (5 detik) → kembali idle | `[ ]` |
| F4 | Ucapkan **"baca teks"** | Layer 1 keyword hit → TTS: _"Membuka mode baca teks"_ (tanpa server) | `[ ]` |
| F5 | Ucapkan **"tulisan"** | Layer 1 keyword hit → TTS: _"Membuka mode baca teks"_ | `[ ]` |
| F6 | Ucapkan **"pergi ke stasiun"** | Layer 1 keyword hit → TTS: _"Membuka mode navigasi"_ | `[ ]` |
| F7 | Ucapkan **"navigasi ke kampus"** | Layer 1 keyword hit → TTS: _"Membuka mode navigasi"_ | `[ ]` |
| F8 | Ucapkan **"antar ke rumah sakit"** | Layer 1 keyword hit → TTS: _"Membuka mode navigasi"_ | `[ ]` |
| F9 | Ucapkan perintah ambigu tanpa backend | Layer 2 LLM timeout → fallback `describe_scene` → TTS gagal anggun | `[ ]` |
| F10 | *(Dengan backend)* Ucapkan _"ada apa di depan saya?"_ | Capture → detect → narasi Claude → TTS kalimat natural | `[ ]` |
| F11 | Tekan tombol mic saat **sedang** mendengarkan | STT berhenti (`stopListening()`), kembali idle | `[ ]` |
| F12 | Ucapkan _"halo guidio"_ / chitchat | TTS: _"Maaf, saya hanya bisa membantu navigasi dan mendeskripsikan sekitar."_ | `[ ]` |

---

## 🔀 G. Navigasi Antar Mode (Bottom Bar)

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| G1 | Tap ikon 👁 (Tuntun) | Pindah ke Mode Tuntun, TTS: _"Mode Deteksi Objek aktif"_ | `[ ]` |
| G2 | Tap ikon 📄 (OCR) | Pindah ke Mode Baca Teks, TTS: _"Mode Baca Teks aktif"_ | `[ ]` |
| G3 | Tap ikon 🧭 (Navigasi) | Pindah ke Mode Navigasi, TTS: _"Mode Navigasi aktif"_ | `[ ]` |
| G4 | Tap ikon 🎙️ (Voice) | Pindah ke Mode Asisten Suara, TTS: _"Mode Asisten Suara aktif"_ | `[ ]` |
| G5 | Tap mode yang **sudah aktif** | Tidak ada aksi (guard: `if (_mode == mode) return;`) | `[ ]` |
| G6 | Animasi transisi antar mode | `AnimatedSwitcher` 300ms terlihat smooth | `[ ]` |
| G7 | Stream kamera stop saat keluar Mode Tuntun | Kamera stream berhenti (dispose dipanggil), tidak ada memory leak | `[ ]` |

---

## 🔊 H. TTS — Text-to-Speech

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| H1 | Boot app pertama kali | TTS siap (Bahasa Indonesia, rate 0.5, volume 1.0) | `[ ]` |
| H2 | TTS obstacle **non-critical** saat TTS lain sedang main | Tidak diputar (antrian, tidak interrupt) | `[ ]` |
| H3 | TTS obstacle **critical** saat TTS lain sedang main | **Interrupt** langsung, TTS lain dihentikan | `[ ]` |
| H4 | Ganti mode saat TTS sedang jalan | TTS stop dulu, baru announce mode baru | `[ ]` |

---

## 📷 I. Camera Health Check (Akselerometer)

> **Offline 100% — menggunakan `sensors_plus`.**

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| I1 | HP dipegang tegak (portrait normal) | Tidak ada banner health, deteksi berjalan normal | `[ ]` |
| I2 | HP dimiringkan > 45° ke depan/belakang | Banner health muncul + TTS peringatan orientasi | `[ ]` |
| I3 | HP dikembalikan tegak | Banner health hilang, deteksi lanjut normal | `[ ]` |
| I4 | Tilt correction estimasi jarak | Arahkan ke objek sambil miringkan HP → estimasi jarak lebih akurat (cos tilt) | `[ ]` |

---

## ⚙️ J. Inference Engine — TFLite

> **Offline 100%.**

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| J1 | Load model `yolo11l_float32.tflite` saat boot | TFLite berhasil load, `tfliteReady = true` (tidak ada error log) | `[ ]` |
| J2 | Inference di isolate (tidak freeze UI) | Scroll/swipe UI tetap smooth saat deteksi berjalan | `[ ]` |
| J3 | Confidence threshold 50% | Objek tidak jelas / jauh tidak muncul di card | `[ ]` |
| J4 | NMS (Non-Maximum Suppression) bekerja | Satu objek hanya muncul **1 kali** meski ada banyak bounding box tumpang tindih | `[ ]` |
| J5 | Model gagal load (file tidak ada) | App tidak crash, `tfliteReady = false`, fallback ke server (atau error anggun) | `[ ]` |

---

## 🔋 K. Performa & Resource

| # | Test Case | Ekspektasi | Status |
|---|-----------|-----------|--------|
| K1 | Jalankan Mode Tuntun 5 menit | Tidak ada crash, FPS kamera stabil | `[ ]` |
| K2 | Pindah mode bolak-balik 10x | Tidak ada memory leak, kamera stream selalu stop/start dengan benar | `[ ]` |
| K3 | HP digenggam di kantong (layar mati) | App bisa di-background tanpa crash | `[ ]` |

---

## 📊 Ringkasan Status Fitur per Mode

| Mode | Offline? | Fitur Utama | Catatan |
|------|----------|------------|---------|
| **Tuntun** (Deteksi Objek) | ✅ **100% Offline** | YOLO TFLite, SORT Tracker, Haptic, TTS | Model harus ada di `assets/models/` |
| **OCR** (Baca Teks) | ❌ **Butuh Backend** | Capture JPEG → `/api/ocr` → TTS | Tanpa backend: gagal anggun + pesan TTS |
| **Navigasi** | 🔶 **Sebagian** | YOLO obstacle (offline), GPS turn-by-turn (placeholder) | GPS belum diimplementasikan |
| **Asisten Suara** | 🔶 **Sebagian** | STT + keyword Layer 1 (offline), LLM narasi (butuh backend) | Keyword: baca, tulisan, pergi ke, navigasi ke, antar ke |

---

## 🐞 Known Issues / Hal yang Perlu Diperhatikan

1. **OCR & Voice describe_scene** — full butuh backend. Tanpa backend, keduanya gagal tetapi dengan pesan yang ramah user.
2. **GPS/Navigasi** — `NavigationProvider` adalah placeholder. Instruksi navigasi turn-by-turn belum diimplementasikan.
3. **Model TFLite** — pastikan file `assets/models/yolo11l_float32.tflite` ada sebelum build. Dicek via `pubspec.yaml → flutter.assets`.
4. **Speech Recognition** — butuh koneksi internet untuk STT berbasis cloud (default `speech_to_text` menggunakan engine sistem). Perlu ditest di perangkat dengan Google Speech Engine.
5. **Server host** — default di `server_service.dart` adalah `10.0.2.2:8000` (emulator). Untuk device fisik, ganti ke IP laptop di jaringan yang sama.

---

*Dokumen ini dibuat otomatis dari analisis source code pada: 2026-06-15*
