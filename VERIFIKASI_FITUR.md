# GUIDIO — Panduan Verifikasi Fitur

> **Update terakhir**: 2026-08-20 — mencerminkan arsitektur akhir: On-Device First,
> singleton TtsQueue, NavigationProvider PIDNet+YOLO, DetectionProvider FramePacer,
> MoneyProvider on-device classifier, CameraProvider dark-state + mutex.
> Threshold deteksi `lubang`/`got_terbuka` diturunkan ke 5% (dari 30%) — keduanya
> dianggap setara dalam validasi pengujian.
>
> Jalankan langkah **Persiapan** terlebih dahulu sebelum masuk ke checklist fitur.
> Urutan penting — jangan loncat.

---

## Daftar isi

1. [Status kesiapan saat ini](#1-status-kesiapan-saat-ini)
2. [Persiapan wajib sebelum testing](#2-persiapan-wajib-sebelum-testing)
3. [Menjalankan backend](#3-menjalankan-backend)
4. [Menghubungkan HP ke backend](#4-menghubungkan-hp-ke-backend)
5. [Checklist verifikasi fitur](#5-checklist-verifikasi-fitur)
6. [Troubleshooting cepat](#6-troubleshooting-cepat)

---

## 1. Status kesiapan saat ini

### ✅ Sudah siap (lengkap)

| Komponen | Status | Keterangan |
|---|---|---|
| `ssd_mobilenet.tflite` (rintangan) | ✅ | `assets/models/` ~4.18 MB |
| `rupiah_classifier_int8.tflite` (kenali uang) | ✅ | `assets/models/` — MobileNetV2 INT8, 7 kelas pecahan |
| `pidnet_s_3zona_fp16.tflite` (segmentasi jalan) | ✅ | `assets/models/` — cadangan: `pidnet_s_3zona.tflite` (float32) |
| `yolo11n.tflite` (navigasi obstacle) | ✅ | `assets/models/` — bundel di APK |
| `transformers` Python (Moondream2) | ✅ | Terinstall di venv backend |
| FastAPI, Uvicorn, Tesseract | ✅ | Terinstall di venv backend |
| Tesseract bahasa `ind` + `eng` | ✅ | `/usr/share/tesseract/` |
| `.env` file backend | ✅ | Ada di `backend/` |
| Flutter analyze | ✅ | Clean (0 error, 0 warning) |
| `CommandParser` lokal (intent offline) | ✅ | `lib/core/voice/command_parser.dart` |
| `narration_engine.dart` (narasi offline) | ✅ | `lib/core/voice/narration_engine.dart` |
| `TtsQueue` singleton (satu pintu suara) | ✅ | Race condition fix + `_drainGeneration` token |
| `DetectionFilter` keyed by `trackId` | ✅ | Mencegah flicker identifikasi antar objek |
| `FramePacer` detection (120 ms min) | ✅ | Anti-tumpukan frame inference |
| `CameraProvider` dark-state + mutex | ✅ | Timer gelap 3 s + `_darkDismissed` |
| `MoneyProvider` on-device classifier | ✅ | `MoneyTFLiteService` + class mapping eksplisit |
| `NavigationProvider` PIDNet-S + YOLO | ✅ | 3-zona (kiri/tengah/kanan), ~2 fps |
| Qwen LLM | 🗑️ Dihapus | Narasi & intent dikerjakan Flutter |
| YOLO11l (model besar) | 🗑️ Dihapus | Dikecilkan ke YOLO11n, APK lebih ramping |
| `object_label_map.dart` (dead code) | 🗑️ Dikonfirmasi | Tidak ada import aktif — aman dihapus |

### ⏳ Tinggal dijalankan / diverifikasi lapangan

| Komponen | Yang perlu dilakukan |
|---|---|
| PostgreSQL service | `sudo systemctl start postgresql` |
| **Moondream2** (~1.85 GB) | Auto-download saat panggil `/api/describe` pertama kali |
| Kalibrasi `_focalLengthPx` (615 px) | Uji fisik di lapangan dengan berbagai kamera HP |
| Kompensasi postur/guncangan jalan | Riset filter accelerometer/gyroscope lebih lanjut |

> **Tidak ada LLM yang perlu didownload.** Qwen dan `llama-cpp-python` telah
> dihapus dari stack. Narasi dan intent dikerjakan lokal di Flutter.

---

## 2. Persiapan wajib sebelum testing

### 2A. Verifikasi dependensi Python

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
source venv/bin/activate

# Cek semua dependensi kunci tersedia
python -c "import fastapi, transformers, cv2, pytesseract; print('OK — semua modul tersedia')"
```

> `transformers` dibutuhkan untuk Moondream2. Tidak ada `llama_cpp` dan tidak ada
> `ultralytics` — YOLO sekarang dijalankan on-device via TFLite di Flutter.

### 2B. Jalankan PostgreSQL

```bash
# Cek status
sudo systemctl status postgresql

# Jika belum jalan
sudo systemctl start postgresql

# Buat database jika belum ada (hanya sekali)
sudo -u postgres createdb vinara_dev 2>/dev/null || echo "DB sudah ada"
```

### 2C. Build APK Flutter (untuk HP fisik)

```bash
cd ~/kuliah/lomba/smstr6/guido/project/guidio_app
flutter pub get
flutter build apk --release

# Install ke HP yang tersambung USB
flutter install
```

> APK lebih kecil karena YOLO11l telah dihapus dari `pubspec.yaml`. Hanya
> model yang benar-benar dipakai yang dibundel.

---

## 3. Menjalankan backend

```bash
cd ~/kuliah/lomba/smstr6/guido/project/backend
source venv/bin/activate

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Cek startup sukses — harus muncul log seperti ini:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
[Moondream2] Service terdaftar (lazy-load, belum dimuat).
[OCR] Tesseract service siap.
=== Vinara Backend siap ===
```

> Tidak akan ada log `[Qwen]` dan tidak ada log `[YOLO]` server — keduanya
> sudah dipindah ke on-device Flutter.

**Verifikasi cepat backend hidup:**
```bash
curl http://localhost:8000/health
# Harus balas: {"status": "ok", ...}

curl http://localhost:8000/api/capabilities
# Harus balas JSON daftar fitur yang aktif/terbatas
```

---

## 4. Menghubungkan HP ke backend

### Cara WiFi (paling mudah)

```bash
# Cari IP laptop di jaringan WiFi yang sama dengan HP
ip addr show | grep "inet " | grep -v "127.0.0"
# Contoh output: 192.168.1.5
```

Di HP, buka Guidio → ucapkan **"pengaturan"** → isi **Alamat Server**: `192.168.1.5:8000` → **Uji Sambungan** → **Simpan**.

### Cara USB (jika WiFi bermasalah)

```bash
adb reverse tcp:8000 tcp:8000
```

Di HP isi alamat server: `localhost:8000`

---

## 5. Checklist verifikasi fitur

Tandai tiap item setelah berhasil. Urutan dari yang paling sederhana.

---

### 🔵 GRUP A — Backend dasar (bisa ditest tanpa HP)

```bash
B=http://localhost:8000
```

**A-1. Health check**
```bash
curl -s $B/health
```
- [ ] Balas JSON dengan `status: ok` dan `elapsed_ms`

**A-2. Capabilities (status fitur)**
```bash
curl -s $B/api/capabilities | python3 -m json.tool
```
- [ ] JSON berisi tiap fitur dengan status `up`, `limited`, atau `down`
- [ ] **Tidak ada** referensi Qwen / LLM di response
- [ ] **Tidak ada** referensi `/ws/detect` WebSocket — navigasi & deteksi sudah on-device

**A-3. Kamus label objek**
```bash
curl -s "$B/api/labels?lang=id" | head -20
```
- [ ] Daftar nama benda Bahasa Indonesia (COCO 80 kelas)

**A-4. Intent catalog**
```bash
curl -s $B/api/intent/catalog | python3 -m json.tool | head -30
```
- [ ] Berisi perintah suara + variannya
- [ ] Tidak ada perintah yang bergantung endpoint LLM

---

### 🟢 GRUP B — OCR (Baca Teks) via Backend

**B-1. OCR dengan foto nyata**
```bash
curl -s -X POST $B/api/ocr \
  --data-binary "@/path/ke/foto_teks.jpg" \
  -H "Content-Type: application/octet-stream"
```
- [ ] Balas dengan `text`, `confidence`, `estimated_spoken`
- [ ] `confidence` > 0 (ada teks terbaca)

**B-2. OCR dari HP** → Mode Baca Teks → arahkan ke teks → ambil gambar
- [ ] Hasil teks terbaca dan dibacakan via TTS Bahasa Indonesia
- [ ] TTS melalui `TtsQueue` (tier info) — tidak memotong peringatan lain

---

### 🟡 GRUP C — Intent & Narasi (On-Device Flutter)

> Intent dan narasi **sepenuhnya on-device** di Flutter — tidak perlu backend.
> Test C-1 sampai C-3 cukup dari HP langsung (bisa offline).

**C-1. Intent via CommandParser lokal**
- Di HP, buka Mode Deteksi → tekan tombol Mic → ucapkan salah satu:
  - "baca teks" / "baca dong" / "tolong bacain"
  - "kenali uang" / "cek duit" / "duit berapa"
  - "navigasi" / "tuntun" / "jalan mana"

- [ ] Mode berganti sesuai ucapan dalam <1 detik
- [ ] **Tidak ada** request ke backend `/api/intent` untuk perintah yang dikenali
- [ ] Berhasil dieksekusi **tanpa koneksi WiFi** (offline)

**C-2. Intent ambigu (fallback ke backend)**
```bash
# Dari backend langsung — hanya untuk perintah yang benar-benar ambigu
curl -s -X POST $B/api/intent \
  -H "Content-Type: application/json" \
  -d '{"text": "kenal kunci"}'
```
- [ ] `resolved: false`, `reason: "ambiguous"`, ada `message` yang bertanya balik
- [ ] **Tidak ada** `reason: "llm"` di response (Qwen sudah dihapus)

**C-3. Narasi via narration_engine lokal**
- Biarkan Mode Deteksi Objek mendeteksi beberapa benda

- [ ] Kalimat narasi terdengar natural ("Di sekitarmu ada dua orang di sebelah kirimu…")
- [ ] Bukan template kaku ("Ada orang di depan")
- [ ] Jarak disebut dalam frasa natural ("sangat dekat", "satu setengah meter", "sekitar tiga meter")
- [ ] Dua objek kelas sama + arah sama dikelompokkan ("dua orang", bukan "orang" dua kali)
- [ ] Narasi melalui `TtsQueue` singleton — tidak tabrakan antar provider

---

### 🟠 GRUP D — Cari Objek

**D-1. Cari target yang ada di foto**
```bash
curl -s -X POST $B/api/cari-objek \
  -F "target=botol" \
  -F "file=@/path/ke/foto.jpg"
```
- [ ] `found: true` dengan posisi dan jarak
- [ ] `found: false, reason: not_in_frame` — normal jika objek memang tak ada

**D-2. Daftar target yang bisa dicari**
```bash
curl -s $B/api/cari-objek/targets
```
- [ ] Daftar nama benda Bahasa Indonesia

**D-3. Dari HP** → Mode Cari Objek → ucapkan "cari dompet"
- [ ] Kamera aktif, hasil dibacakan

---

### 🔴 GRUP E — Navigasi Jalur (On-Device, 3 Zona)

> Navigasi **sepenuhnya on-device** — PIDNet-S + YOLO11n berjalan di HP.
> Tidak ada panggilan ke `/api/navigasi` (endpoint itu dinonaktifkan di backend).

**E-1. Loading model on-device**
- Masuk Mode Navigasi → amati fase `loadingModels`

- [ ] TTS: "Panduan jalur aktif." setelah model berhasil dimuat
- [ ] Jika model gagal: TTS mengatakan "Panduan jalur tidak bisa dijalankan di perangkat ini. Mode Deteksi Objek tetap bisa memperingatkan rintangan."
- [ ] **Tidak ada** pesan "tidak terhubung ke server" untuk mode ini

**E-2. Deteksi 3 zona aktif**
- Arahkan kamera ke jalan/koridor

- [ ] Zona kiri/tengah/kanan menampilkan status di UI (ZoneIndicator)
- [ ] TTS memberi arahan arah ("Geser ke kiri", "Tetap di tengah", dll.)
- [ ] Arahan tidak diulang dalam <6 detik untuk pesan yang sama (anti-banjir)
- [ ] Critical selalu lolos anti-banjir (berhenti mendadak)

**E-3. Rintangan di jalur navigasi**
- Arahkan ke objek langsung di depan

- [ ] Rintangan critical: TTS langsung interrupt, layar `onTakeover` aktif
- [ ] Rintangan warning: TTS muncul setelah arahan zona
- [ ] Jika semua zona danger: "Berhenti dulu. Tidak ada jalur aman."

> **Catatan threshold deteksi rintangan** (`yolo_navigasi_service.dart`):
> - Kelas `lubang` (class 0) dan `got_terbuka` (class 1): threshold **5%** (diturunkan dari 30%).
>   Keduanya dianggap setara — deteksi salah satu sudah dihitung sebagai bahaya got/lubang.
> - Kelas lain (`tangga`, `orang`, `motor`, `tiang`): threshold tetap **30%**.
> - Jika YOLO tidak mendeteksi (skor 0%), PIDNet-S tetap berfungsi sebagai lapis pengaman
>   melalui penurunan rasio *walkable area* ($<50\%$ → HATI-HATI, $<30\%$ → BAHAYA).

**E-4. Frame pacing navigasi**
- Navigasi berjalan terus tanpa hang

- [ ] Loop berjalan ~2 fps (500 ms interval)
- [ ] Frame yang datang saat inferensi berjalan dibuang (tidak menumpuk)
- [ ] Jika 2 frame gagal: TTS "Jalur sulit dibaca, arahan mungkin tertinggal."
- [ ] Jika 4 frame gagal berturut-turut: TTS "Berhenti jalan dulu. Saya tidak bisa membaca jalur sekarang…"

**E-5. Tombol "Ulangi arahan" (kiri bawah Mode Navigasi)**
```
Tekan tombol kiri saat navigasi aktif
```
- [ ] TTS merangkum 3 zona + rekomendasi ("Kiri aman, tengah hati-hati, kanan aman. Geser ke kiri.")
- [ ] Melewati anti-banjir (permintaan eksplisit pengguna)

---

### 🟣 GRUP F — Deskripsi Suasana (Moondream2, output English)

> ⚠️ Fitur ini memuat Moondream2 (~1.85 GB) — pemanggilan pertama kali butuh
> waktu beberapa menit untuk download bobot model (hanya sekali).

**F-1. Uji endpoint describe**
```bash
curl -s -X POST $B/api/describe \
  -F "file=@/path/ke/foto.jpg"
```
- [ ] Balas `description_en` dalam **Bahasa Inggris** (contoh: `"A person walking on a sidewalk…"`)
- [ ] Ada field `model: "moondream2"` dan `length: "short"`
- [ ] **Tidak ada** field `deskripsi` Bahasa Indonesia — terjemahan sudah dihapus

**F-2. Uji dari HP** → ucapkan "deskripsikan" / "apa yang ada di depanku"
- [ ] App merekam foto kamera, kirim ke backend
- [ ] Hasil dibacakan TTS dalam **Bahasa Inggris** (locale `en-US`)
- [ ] Setelah selesai, TTS kembali ke Bahasa Indonesia

---

### ⚫ GRUP G — TtsQueue Singleton & Prioritas Suara

> Test ini memverifikasi sistem antrean TTS yang telah di-fix race condition-nya.
> Semua provider (Detection, Navigation, Camera, Money) menggunakan `TtsQueue.instance`.

**G-1. Critical menginterrupt Info**
- Dalam Mode Deteksi, dengan banyak objek terdeteksi (TTS info sedang berjalan)
- Dekatkan objek besar ke kamera (<1 m) agar trigger critical

- [ ] TTS critical langsung terdengar, memotong TTS info
- [ ] TTS info yang terputus tidak dilanjutkan
- [ ] Tidak ada TTS ganda yang terdengar bersamaan

**G-2. Warning menginterrupt Info**
- Biarkan TTS info sedang berbicara
- Miringkan HP agar `CameraHealthService` trigger warning

- [ ] TTS warning terdengar, memotong TTS info
- [ ] Info dilanjutkan (dari antrean) setelah warning selesai

**G-3. Antrean anti-OOM (max 8 item)**
- Jalankan Mode Deteksi di area ramai (banyak objek)

- [ ] Tidak ada crash OOM / memory spike
- [ ] Info yang menunggu >2 detik dibuang otomatis (tidak terucap terlambat)

**G-4. Stop TTS via interruptByUser**
- Tekan tombol Mic saat TTS sedang berbicara

- [ ] TTS berhenti (jika tier Info atau Warning)
- [ ] TTS critical tidak bisa dihentikan pengguna

---

### 🏁 GRUP H — Fitur On-Device di HP (Tanpa Backend)

> Test ini bisa dilakukan dengan backend **dimatikan** sama sekali.
> Semua fitur di bawah harus berjalan 100% offline.

**H-1. Deteksi Rintangan (TFLite On-Device)**
- Buka Guidio langsung → Mode Deteksi Objek sudah aktif
- Arahkan HP ke orang atau benda dekat (<3m)

- [ ] Ada suara + getar peringatan
- [ ] Kartu deteksi muncul di layar
- [ ] Delay antara deteksi dan suara <500ms (target 250ms dengan streakRequired=2)
- [ ] Narasi berbunyi natural (bukan template kaku)
- [ ] Jarak yang diucapkan adalah nilai **smoothed** (tidak naik-turun tiap frame)
- [ ] Identitas objek stabil (tidak flicker antara "orang depan" dan "orang kiri")

**H-2. Pengenalan Uang (On-Device TFLite)**
- Beralih ke Mode Kenali Uang
- Letakkan uang kertas (Rp 2.000 / 5.000 / 10.000 / 20.000 / 50.000 / 100.000) di bawah kamera, cahaya cukup, posisi rata

- [ ] Nominal disebutkan dalam 2 bentuk: angka + kata ("Rp 50.000, lima puluh ribu rupiah")
- [ ] Jika keyakinan rendah: hanya instruksi perbaikan, **tidak menyebut nominal**
- [ ] Bingkai UI hijau (`MoneyState.fit`) saat uang terdeteksi, sebelum tombol snap
- [ ] Tombol "Snap" / kiri mengumumkan hasil buffer terbaru tanpa delay inferensi tambahan
- [ ] Model di debug: simulasi mock berjalan; di release: jika model gagal, ucapkan "Pengenalan uang tidak tersedia"
- [ ] Session total terakumulasi untuk beberapa lembar; reset setelah 60 detik idle

**H-3. Intent Parsing Offline**
- Matikan WiFi dan data di HP
- Buka Guidio → tekan Mic → ucapkan perintah mode

- [ ] Mode berganti tanpa internet (CommandParser lokal)
- [ ] Tidak ada error "tidak terhubung server" untuk perpindahan mode

**H-4. Dark State + Timer Peringatan**
- Tutup lensa kamera dengan tangan atau masuk ke ruangan gelap

- [ ] Setelah 3 detik gelap: TTS "Terlalu gelap, saya tidak bisa melihat jalur dengan jelas. Nyalakan lampu atau berhenti sejenak."
- [ ] Getar pola `[0, 100, 100, 100]` menyertai peringatan
- [ ] Setiap 30 detik masih gelap: TTS "Masih gelap. Saya tetap berjalan tapi penglihatan terbatas."
- [ ] Tombol "Lewati" muncul di UI → setelah ditekan, tawaran lampu hilang tapi deteksi tetap berjalan (`_darkDismissed = true`)
- [ ] Saat terang kembali: tawaran lampu hilang otomatis, `_darkDismissed` direset

**H-5. Camera Mutex (Capture Race Condition)**
- Di Mode Baca Teks / Asisten Suara, tekan tombol foto berkali-kali cepat

- [ ] Tidak ada double-capture
- [ ] Tidak ada error "Sedang capture" yang terekspos ke pengguna tanpa recovery
- [ ] Stream kamera restart dengan benar setelah capture

**H-6. Tombol Mic Global (Overlay)**
- Di mode Deteksi Objek, tekan tombol Mic (tengah bawah)

- [ ] VoiceScreen muncul sebagai overlay (bukan ganti layar)
- [ ] Ada tombol Kembali di atas BottomBar
- [ ] Ucapkan perintah mode → setelah dieksekusi, overlay hilang dan mode berganti

---

### 🎙️ GRUP I — Perintah Suara dari HP

Ucapkan masing-masing perintah dan cek apakah mode/aksi sesuai:

| Ucapan | Mode yang diharapkan | Verifikasi |
|---|---|---|
| "deteksi" / "deteksi objek" / "awasi jalan" | Mode Deteksi Objek | [ ] |
| "uang" / "kenali uang" / "cek duit" / "duit berapa" | Mode Kenali Uang | [ ] |
| "baca" / "baca teks" / "tolong bacain" | Mode Baca Teks | [ ] |
| "navigasi" / "tuntun" / "jalan mana" | Mode Navigasi | [ ] |
| "asisten" / "bicara" / "tanya" | Mode Asisten Suara | [ ] |
| "cari dompet" / "cariin kunci" | Mode Cari Objek, target sesuai | [ ] |
| "deskripsikan" / "apa yang ada di depanku" | Deskripsi suasana (trigger Moondream) | [ ] |
| "lampu" / "nyalakan senter" | Senter menyala | [ ] |
| "pengaturan" | Layar Pengaturan | [ ] |
| "ulangi" / "ulang" | Repeat arahan navigasi (saat Mode Navigasi) | [ ] |
| Dialek Jawa: "tulung wacakno" | Mode Baca Teks | [ ] |
| Dialek Sunda: "teang dompu" | Mode Cari Objek, target dompet | [ ] |
| Bahasa gaul: "scan duit" / "scan uang" | Mode Kenali Uang | [ ] |

Kriteria keberhasilan per perintah:
- [ ] Tiap perintah dieksekusi dalam <2 detik
- [ ] TTS mengkonfirmasi mode yang aktif
- [ ] Perintah dialek dan gaul juga berhasil dikenali

---

## 6. Troubleshooting cepat

| Gejala | Kemungkinan penyebab | Solusi |
|---|---|---|
| Backend startup error `psycopg.OperationalError` | PostgreSQL belum jalan | `sudo systemctl start postgresql` |
| `ModuleNotFoundError: transformers` | Package belum install | `pip install "transformers>=4.40.0"` |
| Backend log ada `[Qwen]` atau `[YOLO]` server | File lama tertinggal | Pastikan `main.py` versi terbaru (Qwen & YOLO server sudah dihapus) |
| `/api/navigasi` not found (404) | Endpoint dinonaktifkan intentional | Normal — navigasi dikerjakan on-device PIDNet+YOLO di Flutter |
| `/api/narasi` not found (404) | Endpoint sudah dihapus | Normal — narasi dikerjakan oleh `narration_engine.dart` di Flutter |
| `/api/detect` WebSocket 404 | Endpoint sudah dihapus | Normal — deteksi dikerjakan on-device TFLite di Flutter |
| `/api/describe` balas `deskripsi` bukan `description_en` | File lama / cache | Restart backend |
| Moondream loading lama | Pertama kali download model (~1.85 GB) | Tunggu sampai selesai (hanya sekali, selanjutnya cache) |
| TTS deskripsi berbahasa Indonesia | `speakEnglish()` tidak terpanggil | Cek `server_service.dart` apakah sudah panggil `speakEnglish` |
| HP tidak bisa reach backend | IP salah atau backend pakai localhost | Pastikan backend `--host 0.0.0.0`, isi IP laptop yang benar |
| Intent tidak dikenali dari HP | Frasa tidak ada di `command_parser.dart` | Tambahkan frasa baru ke bank kata sesuai intent yang relevan |
| Flutter `null check operator` crash | Provider belum siap | Pastikan `flutter pub get` sudah dijalankan |
| OCR hasil jelek | Foto buram / cahaya kurang | Perbaiki pencahayaan, pegang HP lebih stabil |
| Uang tidak terdeteksi | Keyakinan <0.85 atau `_consecutiveMiss` terlalu banyak | Dekatkan HP ke uang, cahaya merata, jangan ada bayangan |
| Narasi terdengar kaku/template | Hanya 1 objek terdeteksi atau kelas di luar COCO | Normal jika 1 objek — narasi lebih kaya jika ada 2+ objek |
| TTS tabrakan / dua suara bersamaan | `TtsQueue` tidak singleton | Pastikan semua provider panggil `TtsQueue()` (factory → instance) |
| Narasi jarak naik-turun tiap frame | Menggunakan `distanceMeter` mentah, bukan `smoothedDistance` | Cek `detection_provider.dart` — harus pakai `track?.smoothedDistance` |
| Navigasi stuck di `loadingModels` | PIDNet atau YOLO11n gagal dimuat | Cek file `.tflite` ada di `assets/models/`, jalankan `flutter pub get` |
| `lubang` / `got_terbuka` tidak terdeteksi YOLO | Skor model 0% untuk gambar tertentu (sudut kamera, pencahayaan) | Normal — PIDNet-S tetap mendeteksi area tidak aman via penurunan *walkable ratio*. Keduanya dianggap setara dalam validasi: mendeteksi salah satu sudah cukup |
| Tangga tidak terdeteksi YOLO | Skor model 0% — struktur tangga sulit dideteksi *bounding box* 2D dari sudut *first-person* | Normal — PIDNet-S mendeteksi area tangga sebagai non-walkable (status HATI-HATI/BAHAYA) |
| Mode Uang debug: nominal acak muncul di release | `kDebugMode` check tidak berfungsi | Pastikan build release dengan `flutter build apk --release` |
| `MoneyState.notMoney` tidak pernah muncul | Mock disabled di release | Normal — di release hanya model yang bekerja |
| Dark state tidak reset setelah terang | `_cancelDarkWarningTimer()` tidak terpanggil | Cek `stopStream()` dipanggil dengan benar saat keluar mode |
