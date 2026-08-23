# Vinara (Guidio): Alur & Fitur Baru (Di Luar IMPLEMENTASI.md & ALUR-DAN-TOMBOL.md)

Dokumen ini mendokumentasikan seluruh **alur baru, tombol baru, arsitektur baru, dan peningkatan fitur** yang telah diimplementasikan di kode saat ini, namun **belum ada atau telah berkembang melampaui** spesifikasi awal di `IMPLEMENTASI.md` dan `ALUR-DAN-TOMBOL.md`.

---

## Daftar Isi

1. [Ringkasan Perbedaan: Spesifikasi Awal vs Implementasi Terbaru](#1-ringkasan-perbedaan-spesifikasi-awal-vs-implementasi-terbaru)
2. [Alur Baru 1: Deskripsi Suasana Kamera (Moondream2 VLM + Qwen LLM)](#2-alur-baru-1-deskripsi-suasana-kamera-moondream2-vlm--qwen-llm)
3. [Alur Baru 2: Jarvis Global Mic (Voice Overlay Modal dari Semua Mode)](#3-alur-baru-2-jarvis-global-mic-voice-overlay-modal-dari-semua-mode)
4. [Alur Baru 3: Slot Aksi Kontekstual (ContextualActionSlot) & Senter Otomatis](#4-alur-baru-3-slot-aksi-kontekstual-contextualactionslot--senter-otomatis)
5. [Alur Baru 4: Konfigurasi Dinamis Alamat Server & Uji Sambungan](#5-alur-baru-4-konfigurasi-dinamis-alamat-server--uji-sambungan)
6. [Alur Baru 5: Arsitektur Local LLM Penuh (Qwen2.5-1.5B GGUF Offline)](#6-alur-baru-5-arsitektur-local-llm-penuh-qwen25-15b-gguf-offline)
7. [Inventaris Tombol & Widget Baru](#7-inventaris-tombol--widget-baru)
8. [Matriks Perintah Suara Tambahan (70+ Trigger Baru)](#8-matriks-perintah-suara-tambahan-70-trigger-baru)
9. [Dampak Terhadap Kontrak Layout & Aksesibilitas](#9-dampak-terhadap-kontrak-layout--aksesibilitas)

---

## 1. Ringkasan Perbedaan: Spesifikasi Awal vs Implementasi Terbaru

| Komponen / Fitur | Spesifikasi Awal (`IMPLEMENTASI.md` & `ALUR-DAN-TOMBOL.md`) | Implementasi Terbaru Saat Ini | Status Perubahan |
|---|---|---|---|
| **Deskripsi Pemandangan Sekitar** | ❌ *Belum ada* (Hanya ada deteksi kotak YOLO dan OCR) | ✅ **Ada** via endpoint `/api/describe` (Moondream2 VLM + Qwen LLM) | **Fitur Baru Penuh** |
| **Akses Asisten Suara** | ⚠️ Harus ganti mode penuh ke `VoiceScreen` (merusak/menutup mode aktif) | ✅ **Jarvis Global Mic**: Push `VoiceScreen(isOverlay: true)` tanpa menutup mode aktif | **Alur Baru** |
| **Aksi Kontekstual (Senter/Kembali)** | ⚠️ Tersebar di `FullScreenButton` atau `StatusBanner` | ✅ **`ContextualActionSlot`**: Slot dedicated tepat di atas `BottomActionBar` | **Komponen & Zona Baru** |
| **Model LLM Bahasa** | ☁️ Cloud API Claude Haiku (Anthropic) - butuh internet & API Key | 💻 **Qwen2.5-1.5B-Instruct GGUF** lokal di CPU/GPU (0 API Key, 100% offline) | **Arsitektur Baru** |
| **Konfigurasi Server** | ⚠️ Statis / Hardcoded `10.0.2.2:8000` | ✅ Pengaturan Dinamis + **Tombol "Uji Sambungan"** (Ping real-time) | **Fitur Baru** |
| **Kamus Cari Objek** | ⚠️ Tercampur di dalam file service backend | ✅ Modular di `find_object_constants.py` (83+ benda rumah tangga) | **Refactor Arsitektur** |

---

## 2. Alur Baru 1: Deskripsi Suasana Kamera (Moondream2 VLM + Qwen LLM)

Fitur ini menjawab kebutuhan utama tunanetra saat berada di tempat baru: *"Tolong jelaskan apa yang ada di hadapan saya sekarang."*

```
Pengguna ucapkan "Deskripsikan" ──► TTS "Saya foto sekitarmu dulu..."
                                                  │
                                                  ▼
                                      Ambil Foto Kamera (JPEG)
                                                  │
                                                  ▼
                                   Kirim POST ke /api/describe
                                                  │
                       ┌──────────────────────────┴──────────────────────────┐
                       ▼                                                     ▼
         1. Moondream2 (~2B VLM di GPU)                         2. Qwen2.5-1.5B (di CPU)
      Membaca gambar ──► Caption Inggris                 Menerjemahkan ──► Bahasa Indonesia
   "A child playing on a swing near a tree"               "Ada anak sedang bermain ayunan
                                                              di dekat pohon di depanmu."
                                                                             │
                                                                             ▼
                                                                TTS membacakan ke Pengguna
```

### Langkah demi Langkah:
1. **Pemicu:** Pengguna mengucapkan perintah suara (tersedia 70+ variasi kata kunci, frasa santai, formal, hingga bahasa daerah seperti *"ono opo neng ngarep"*, *"aya naon di hareup"*, *"deskripsikan sekitarku"*).
2. **Umpan Balik Instan:** Aplikasi seketika mengubah state ke `VoiceState.processingLlm` dan berbicara via TTS:  
   *`"Saya foto sekitarmu dulu, tunggu sebentar."`* (Mengikuti pola AS-09).
3. **Pengambilan Citra:** `CameraProvider.captureJpeg()` mengambil frame resolusi penuh dari kamera perangkat.
4. **Pemrosesan Server (Hibrida VLM + LLM):**
   - **Langkah A (Moondream2):** Model VLM memproses gambar dengan mode `length='short'` (~300ms) menghasilkan caption ringkas Bahasa Inggris.
   - **Langkah B (Qwen2.5-1.5B):** Caption diterjemahkan ke Bahasa Indonesia natural yang dirancang khusus untuk enak didengar via TTS (maksimal 2 kalimat, tanpa istilah teknis).
5. **Hasil:** TTS membacakan deskripsi suasana dan menyimpannya ke histori percakapan.
6. **Penanganan Kegagalan:**
   - Jika kamera tidak siap: *"Kamera tidak tersedia untuk mengambil foto."*
   - Jika Moondream gagal: *"Maaf, saya tidak bisa mendeskripsikan suasana saat ini. Coba lagi."*
   - Jika Qwen belum didownload: Otomatis menggunakan template fallback *"Di depanmu terlihat [caption EN]."*

---

## 3. Alur Baru 2: Jarvis Global Mic (Voice Overlay Modal dari Semua Mode)

Di spesifikasi lama, pengguna harus berpindah mode penuh ke `VoiceScreen` untuk berbicara dengan asisten. Pada implementasi baru, tombol **Mic** di `BottomActionBar` berfungsi sebagai **Global Voice Overlay**.

```
Mode Deteksi Objek / Uang / OCR
              │
              ▼  (Tekan tombol Mic tengah bawah)
┌─────────────────────────────────────────────────────────────┐
│  VOICE SCREEN OVERLAY (Transparan, Non-Destruktif)          │
│                                                             │
│  - Getar 100 ms                                             │
│  - Langsung mendengarkan (VoiceOrb aktif berdenyut)         │
│  - Background semi-transparan (layar asal tetap terlihat)   │
│  - Ada tombol ContextualActionSlot "Kembali" di bawah       │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
   Perintah Ganti Mode              Perintah Pertanyaan/Deskripsi
   ("Mode Kenali Uang")             ("Deskripsikan suasana")
               │                               │
               ▼                               ▼
   - Tutup overlay otomatis         - Eksekusi di tempat
   - Pindah ke Mode Uang            - TTS membacakan jawaban
   - 0 gestur tambahan              - Overlay tetap aktif
```

### Keunggulan Desain:
* **Non-destruktif:** Mode asal tidak di-*destroy*, state kamera dan rintangan tidak di-reset.
* **Smart Pop-on-Action:** Jika pengguna memerintahkan pindah mode, modal otomatis menutup sendiri (`onNavigateBack()`).
* **Bisa Dibatalkan:** Cukup tekan tombol *"Kembali"* di atas BottomBar atau ucapkan *"kembali"*.

---

## 4. Alur Baru 3: Slot Aksi Kontekstual (ContextualActionSlot) & Senter Otomatis

Untuk mencegah tombol aksi menutupi kartu deteksi atau terselip di menu tersembunyi, dibuat komponen **`ContextualActionSlot`**.

```
┌─────────────────────────────────────────────────────────────┐
│  Area Kamera / Konten Utama                                 │
├─────────────────────────────────────────────────────────────┤
│  AlertCard / DetectionCard (Otomatis naik 80 dp)            │
├─────────────────────────────────────────────────────────────┤
│  [!] Kondisi gelap - Nyalakan Senter                        │
│  [ 💡 Nyalakan Senter ] ◄── ContextualActionSlot (56-80 dp)  │
├─────────────────────────────────────────────────────────────┤
│  BottomActionBar: [ Ambil Foto ]   [ 🎙️ Mic ]   [ Mode ]    │
└─────────────────────────────────────────────────────────────┘
```

### Skenario Penggunaan:
1. **Skenario Gelap (TuntunScreen):**
   - Saat sensor kamera mendeteksi ruangan gelap (`CameraHealth.dark`), slot senter muncul tepat di atas BottomBar.
   - Semua kartu peringatan rintangan otomatis terdorong naik secara mulus (`slotExtra = 80 dp`) tanpa menimpa tombol.
   - Menekan tombol atau mengucapkan *"nyalakan senter"* langsung menyalakan flash LED HP.
2. **Skenario Overlay (VoiceScreen):**
   - Menampilkan tombol *"Kembali"* selebar layar dengan target sentuh 56 dp agar mudah ditekan oleh pengguna tunanetra/low-vision.

---

## 5. Alur Baru 4: Konfigurasi Dinamis Alamat Server & Uji Sambungan

Untuk mendukung skenario demo lomba dan testing real device (HP fisik tersambung ke laptop via WiFi atau kabel USB):

```
Buka Pengaturan ──► Ketik IP Laptop (misal: 192.168.1.5:8000)
                                 │
                                 ▼
                     Tekan "Uji Sambungan"
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
            [ Sukses ]                       [ Gagal ]
     Muncul: "Terhubung (14 ms)"       Muncul: "Gagal terhubung"
                 │                               │
                 ▼                               ▼
            Tekan Simpan               Cek Firewall / WiFi
```

### Opsi Konektivitas:
1. **WiFi LAN Satu Jaringan:** Isi IP laptop `192.168.x.x:8000`.
2. **Kabel USB (ADB Reverse):** Jalankan `adb reverse tcp:8000 tcp:8000` di laptop, lalu isi `localhost:8000` di HP.

---

## 6. Alur Baru 5: Arsitektur Local LLM Penuh (Qwen2.5-1.5B GGUF Offline)

Menggantikan seluruh dependensi cloud API (Claude Haiku / Anthropic) menjadi server offline mandiri:

```
FastAPI Server (Laptop)
├── YOLO11n / YOLOE  ──► GPU RTX 3050 (~0.5 GB VRAM)  ──► Deteksi Objek & Cari Barang
├── Moondream2 FP16  ──► GPU RTX 3050 (~1.2 GB VRAM)  ──► Deskripsi Visual Kamera (VLM)
└── Qwen2.5-1.5B Q4  ──► Laptop CPU   (~1.2 GB RAM)   ──► Narasi YOLO & Terjemahan TTS
```

* **Zero API Cost & Unlimited Requests:** Tidak ada batas kuota token atau biaya per panggilan.
* **Zero Internet Dependency:** Server dan HP bisa berjalan penuh di area tanpa koneksi internet luar.
* **Separasi Hardware:** GPU dialokasikan penuh untuk visi (YOLO + Moondream), sementara CPU menangani teks (Qwen).

---

## 7. Inventaris Tombol & Widget Baru

| Nama Widget | File Lokasi | Fungsi & Karakteristik |
|---|---|---|
| **`ContextualActionSlot`** | `guidio_app/lib/widgets/contextual_action_slot.dart` | Slot dinamis di atas BottomBar untuk aksi kontekstual (senter, tombol kembali). Tinggi 56–80 dp, touch target 56 dp. |
| **`_MicButton` (Global)** | `guidio_app/lib/widgets/bottom_action_bar.dart` | Tombol Mic tengah yang memicu modal overlay transparan saat ditekan dari mode selain Voice. |
| **`VoiceScreen(isOverlay)`**| `guidio_app/lib/screens/voice_screen.dart` | Varian modal overlay dari VoiceScreen dengan tombol kembali dan smart auto-dismiss. |

---

## 8. Matriks Perintah Suara Tambahan (70+ Trigger Baru)

Intent baru: **`VoiceIntent.describeScene`** (Enum key: `describeScene`)

```dart
// Contoh variasi yang dikenali CommandParser lokal (0 ms, offline):
[
  // Kata Kunci Tunggal
  'deskripsikan', 'jelaskan', 'ceritakan', 'lihatkan', 'gambarkan', 'terangkan',
  'pemandangan', 'sekitarku', 'depanku', 'suasana sekitar', 'ada apa',

  // Frasa Santai
  'lihat depan dong', 'depan ada apa aja sih', 'coba intip depan',
  'fotoin depan terus jelasin', 'ini tempat apaan sih', 'sekitar gue ada apa aja',

  // Pertanyaan Kondisi
  'pemandangan di depan seperti apa', 'ruangan ini kayak gimana', 'lagi suasana gimana ini',

  // Bahasa Daerah
  'ono opo neng ngarep' (Jawa), 'aya naon di hareup' (Sunda), 'kahanan kepiye iki',
  'apo nan di adok den' (Minang), 'aha na di jolo' (Batak),
]
```

---

## 9. Dampak Terhadap Kontrak Layout & Aksesibilitas

1. **Perhitungan Inset Dinamis:**  
   Ketika `ContextualActionSlot` aktif, posisi seluruh elemen floating dihitung ulang:
   $$\text{bottomOffset} = \text{bottomInset} + \text{AppSizes.bottomActionBarHeight} + \text{slotExtra}$$
2. **TalkBack Urutan Fokus Baru:**  
   `Area Kamera / StatusBanner` ──► `AlertCard / Deteksi` ──► `ContextualActionSlot (Tombol Senter / Kembali)` ──► `BottomActionBar (Ambil Foto, Mic, Mode)`
3. **Kekekalan Spasial Tetap Terjaga:**  
   Tiga tombol BottomActionBar tetap tidak pernah bergeser, berubah urutan, atau tertutup oleh widget baru apapun.

---

*Dokumen ini melengkapi `IMPLEMENTASI.md` dan `ALUR-DAN-TOMBOL.md` sebagai acuan fungsional codebase terbaru Guidio.*
