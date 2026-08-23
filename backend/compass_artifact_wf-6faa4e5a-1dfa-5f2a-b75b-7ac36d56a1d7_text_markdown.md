# Riset Teknis Mendalam: Pengembangan Aplikasi Vinara (eks Guidio)

**TL;DR**
- Untuk Scene Description & Live Assistant, arsitektur terbaik untuk Vinara adalah **hybrid grounding**: pertahankan pola "Grounded Text-to-Language" tapi kirim GAMBAR + konteks deteksi on-device ke satu VLM murah (Gemini 2.5 Flash-Lite $0.10/$0.40 per 1M token, atau Claude Haiku 4.5 $1/$5). Biaya per query 640×480 ≈ Rp2–35, sangat terjangkau; jangan self-host VLM di tahap awal.
- Untuk Light Detection & sonifikasi Cari Objek, semua bisa 100% on-device tanpa model ML baru: baca plane Y (luma) langsung dari `CameraImage` YUV420 yang SUDAH ada (nol konversi RGB), dan pakai `flutter_soloud` untuk beep dinamis PCM real-time. Menurut studi Delaunay & Ambard ("How well do you see what you hear?", 28 partisipan) dan Bazilinskyy et al. (2016, N=29), **beep repetition rate** (tempo) memberi estimasi jarak/kedalaman terbaik - jadikan tempo mapping utama.
- Mode Tuntun dan Navigasi Jalur SEBAIKNYA TIDAK dilebur total; jadikan Mode Tuntun sebagai mode "obstacle level mata/kepala" (memakai pitch HP dari `sensors_plus`) dan Navigasi Jalur sebagai mode trotoar. Satu `CameraController` tidak bisa dipakai dua konsumen ML berat sekaligus - auto-switch kontekstual lebih baik daripada dua mode paralel.

---

## Catatan Sumber & Verifikasi
Semua harga API dan benchmark di bawah punya sumber. Beberapa angka (harga image-input OpenAI Realtime, ketersediaan region Gemini Live untuk Indonesia, benchmark segmentasi di chip mobile spesifik) belum bisa diverifikasi dari sumber primer dan DITANDAI eksplisit dengan ⚠️. Jangan anggap angka bertanda ⚠️ sebagai final tanpa cek ulang di dashboard resmi.

---

# FITUR 1: Scene Description AI (deskripsi naratif + Q&A): ekstensi Asisten Suara

## Requirement & UX Goal
Upgrade Asisten Suara Claude Haiku existing menjadi multimodal: user memotret/pakai kamera, bertanya natural ("ini apa di depan?", "deskripsikan ruangan"), asisten memberi deskripsi naratif, lalu multi-turn Q&A dengan konteks gambar yang sama. Prinsip pembeda Vinara: transparansi ketidakpastian, karena riset Gonzalez, Collins, Bennett & Azenkot (CHI 2024, arXiv:2403.15604) menemukan aplikasi scene description AI diberi skor kepercayaan hanya **2,43/4 (SD=1,16)** dan kepuasan **2,76/5 (SD=1,49)** oleh 16 partisipan BLV - halusinasi dengan nada meyakinkan adalah masalah utama. MacLeod et al. berargumen untuk "designing for mistrust" dengan menampilkan confidence rating.

## Opsi 1: Satu VLM multimodal (Claude Haiku 4.5 vision)
- **Cara kerja teknis**: kirim JPEG 640×480 + prompt teks langsung ke Claude Haiku 4.5 (`claude-haiku-4-5`, model yang SUDAH dipakai untuk narasi). Model ini mendukung vision, tool calling, prompt caching, structured output.
- **Backend (FastAPI)**: endpoint `/api/narasi` diperluas untuk menerima `image` (base64) selain `detections`. Anthropic SDK `anthropic>=0.25.0` sudah ada di requirements. Format pesan: `{"type":"image","source":{"type":"base64",...}}` + `{"type":"text",...}`.
- **Frontend (Flutter)**: `captureJpeg()` sudah ada. Kirim via `http ^1.2.1`.
- **Biaya**: Claude Haiku 4.5 = **$1/M input, $5/M output** (terkonfirmasi resmi anthropic.com/claude/haiku). Formula token gambar Anthropic = `(width × height) / 750`. Untuk 640×480 = 307.200/750 ≈ **410 token** (≈$0.00041). Untuk 1024×768 = 786.432/750 ≈ 1.048 token. Dengan output ~150 token ($0.00075) + prompt teks ~300 token, total ≈ **$0.0015 per query** (~Rp24). 1.000 query ≈ $1,5 (~Rp24.000). 100 user aktif × 10 query/hari × 30 hari = 30.000 query/bulan ≈ **$45/bulan (~Rp720rb)**; 1.000 user = **$450/bulan**.
- **Kelebihan**: satu model untuk teks+vision, konsisten dengan stack existing; kualitas reasoning tinggi; prompt caching untuk multi-turn.
- **Kekurangan**: lebih mahal dari Gemini; Anthropic tidak punya region data di Indonesia (latensi lintas benua).

## Opsi 2: Gemini 2.5 Flash / Flash-Lite (vision)
- **Cara kerja**: sama, panggil Gemini API dari FastAPI (`httpx` sudah ada).
- **Biaya**: Gemini 2.5 Flash-Lite = **$0.10/M input, $0.40/M output** (terkonfirmasi ai.google.dev/gemini-api/docs/pricing; batch mode turun ke $0.05/$0.20; catatan: model 2.5 dijadwalkan retirement 16 Okt 2026 → migrasi ke Gemini 3.1 Flash-Lite $0.25/$1.50). Gemini 2.5 Flash = $0.30/$2.50. Tokenisasi gambar Gemini: ≤384px = 258 token flat; >384px di-tile 768×768 @ 258 token/tile. Gambar 640×480 = beberapa tile ≈ 516–1.032 token. Biaya per query Flash-Lite ≈ **$0.0003–0.0005** (~Rp5–8), ~3–5× lebih murah dari Haiku.
- **Kelebihan**: termurah; context window 1M; kualitas vision baik.
- **Kekurangan**: kualitas hedging/kejujuran ketidakpastian perlu diuji; model 2.5 akan pensiun.

## Opsi 3: Pipeline 2 model (VLM caption → Claude Haiku teks): TIDAK disarankan
- **Cara kerja**: VLM kecil deskripsikan gambar → teks → diteruskan ke Claude Haiku untuk dinaturalkan.
- **Kekurangan**: menambah latency (2 hop), menambah biaya, dan justru menambah risiko halusinasi karena Claude tidak bisa memverifikasi teks perantara. Kalah dibanding satu VLM yang lihat gambar langsung + grounding deteksi.

## Pendekatan Hybrid Grounding (INTI rekomendasi)
Gabungkan deteksi terstruktur on-device (SSD MobileNet: label + jarak + arah + danger) SEBAGAI grounding context ke prompt VLM. Contoh prompt:
> "Detektor on-device melaporkan: orang 1.2m depan, kursi 2m kanan (confidence 0.7). Konfirmasi atau koreksi berdasarkan gambar. Jika ragu tentang detail, katakan 'sepertinya' atau 'saya tidak yakin'. Jangan sebut objek yang tidak terlihat jelas. Jawab 1–2 kalimat, Bahasa Indonesia."

Ini bentuk **detection-augmented VLM prompting** / visual grounding. Teknik pendukung dari literatur: chain-of-verification, uncertainty-aware captioning. Karena Vinara sudah punya deteksi terstruktur, ini pembeda kuat - VLM tidak start dari nol dan halusinasi bisa "dijangkarkan" ke fakta detektor. Gunakan structured output dengan field `confidence` dan instruksi eksplisit "jawab tidak tahu kalau ragu". Riset Alharbi et al. (ASSETS 2024, "Misfitting With AI: How Blind People Verify and Contest AI Errors") menegaskan error VLM sering tak terdeteksi oleh pengguna tunanetra → menampilkan ketidakpastian adalah safety feature, bukan sekadar UX.

## Multi-turn Q&A dengan gambar sama: gunakan prompt caching
- **Anthropic prompt caching**: cache read = **10% harga input** (90% diskon, ≈$0.10/M untuk Haiku); cache write 5-menit = 1.25× input, 1-jam = 2× (platform.claude.com/docs/en/build-with-claude/prompt-caching). Minimum 1.024 token untuk cacheable - gambar 640×480 (410 token) sendirian TIDAK cukup, tapi gambar 1024×768 (1.048 token) atau gambar+system prompt gabungan bisa. Untuk multi-turn 3–5 giliran soal gambar sama, caching memotong biaya input drastis.
- **Integrasi dengan PostgreSQL existing**: tabel sesi asisten (`/api/asisten/turn`, expired 15 menit) sudah ada. Simpan `image_ref` per sesi; kirim ulang gambar dengan `cache_control` di turn pertama, lalu cache-read di turn berikutnya. Cache TTL 5 menit cocok dengan window percakapan pendek. Alternatif: cache gambar di server (path lokal) dan re-attach; hindari re-upload dari HP tiap turn (hemat kuota user).

## Rekomendasi Fitur 1
**Gunakan Gemini 2.5 Flash-Lite (atau penerusnya 3.1 Flash-Lite) sebagai default untuk deskripsi naratif, dengan hybrid grounding dari deteksi on-device, dan Claude Haiku 4.5 sebagai fallback/premium.** Alasan: biaya Flash-Lite ~5× lebih murah cocok untuk pasar Indonesia yang sensitif harga; hybrid grounding memanfaatkan aset deteksi yang SUDAH ada dan langsung menyerang problem trust 2,43/4. Pertahankan prinsip "jawab tidak tahu kalau ragu" via prompt + structured confidence. Multi-turn pakai prompt caching + tabel sesi PostgreSQL yang ada.

## Ditemukan tapi tidak disarankan
- **Pipeline 2 model terpisah** - menambah latency & biaya tanpa mengurangi halusinasi.
- **GPT-4o-mini vision** - layak secara harga tapi menambah vendor ketiga tanpa keunggulan jelas vs Gemini/Claude yang sudah/mudah diintegrasi.

## Pertanyaan buat user
1. Budget API vision per bulan (menentukan Gemini vs Claude)?
2. Boleh kirim gambar mentah ke server cloud (privasi)? Atau harus on-device?
3. Prioritas: kualitas deskripsi (Haiku/Sonnet) vs biaya minimum (Flash-Lite)?

---

# FITUR 2: Light Detection

## Requirement & UX Goal
Deteksi lampu menyala/mati & terang/gelap. Harus murah baterai, jalan di device kelas bawah, dan membedakan "gelap beneran" vs "kamera tertutup tangan/kantong" (false positive kritis untuk tunanetra). Jadi shared service reusable (`tooDark` CO-19 Cari Objek + Navigasi butuh).

## Opsi 1: Baca plane Y (luma) dari CameraImage YUV420: DIREKOMENDASIKAN
- **Cara kerja teknis**: `CameraProvider` sudah pakai `ImageFormatGroup.yuv420`. Plane Y (`CameraImage.planes[0]`) ADALAH luminance mentah (0–255) tanpa perlu konversi RGB sama sekali. Hitung rata-rata luma dengan **sampling** (mis. tiap 16 piksel, atau grid 32×32 sampel) - bukan seluruh 640×480 piksel - supaya <1ms CPU.
- **Membedakan lampu mati vs kamera tertutup**: gunakan **variance/histogram spread**, bukan hanya mean. Kamera tertutup tangan/kantong = mean sangat rendah DAN variance sangat rendah (nyaris seragam gelap). Ruangan gelap dengan sedikit cahaya = mean rendah tapi variance lebih tinggi (ada tepi/titik cahaya). Ambang contoh (perlu kalibrasi per-device): mean <30 & variance <50 → "kamera mungkin tertutup"; mean <50 → "gelap"; 50–120 → "redup"; >120 → "terang".
- **Backend**: tidak perlu - 100% on-device.
- **Frontend**: buat `LightService` yang meng-consume frame Y-plane. Ekspos `LightLevel {dark, dim, bright, blocked}` + `luma`, `variance`.
- **Kelebihan**: nol biaya, nol model ML, hampir nol baterai, jalan offline, jalan di semua device.
- **Kekurangan**: perlu kalibrasi ambang per-device (auto-exposure kamera memengaruhi absolut luma).

## Opsi 2: Ambient Light Sensor HP (package `light` / `ambient_light`)
- **Cara kerja**: baca sensor cahaya lingkungan (lux) hardware.
- **Kekurangan**: sensor ALS sering TIDAK ada di device Android kelas bawah, atau posisinya di depan (bukan mengukur arah kamera belakang). Tidak bisa membedakan "kamera tertutup". Kurang reusable dengan pipeline kamera.

## Opsi 3: Metadata exposure/ISO kamera
- **Cara kerja**: baca nilai exposure/ISO dari frame metadata.
- **Kekurangan**: package `camera ^0.11.0` tidak mengekspos ISO/exposure mentah secara konsisten lintas device; auto-exposure justru mengompensasi kegelapan sehingga menyesatkan. Kalah dari analisis luma langsung.

## Rekomendasi Fitur 2
**Opsi 1 (luma Y-plane + variance).** Tidak perlu model ML - image processing sederhana cukup. Desain `LightService` sebagai shared service: satu konsumen frame Y-plane yang dipanggil Cari Objek (isi `tooDark`/CO-19 secara lokal, mengurangi ketergantungan server `invalid_frame`), Navigasi, dan Live Assistant (trigger flashlight). Kalibrasi ambang lewat telemetri (`/api/events` sudah ada). Variance/histogram spread WAJIB dipakai untuk membedakan kamera tertutup - ini masalah false-positive nyata untuk tunanetra.

## Ditemukan tapi tidak disarankan
- **Model ML klasifikasi cahaya** - overkill; luma statistik sudah cukup akurat dan jauh lebih murah.

## Pertanyaan buat user
1. Perlu output lux absolut, atau kategori (gelap/redup/terang) cukup?
2. Light Detection sebagai fitur voice command mandiri ("apakah lampu menyala?") atau hanya shared service internal?

---

# FITUR 3: Live Visual Assistant ala Project Astra: PALING KOMPLEKS

## Requirement & UX Goal
Asisten yang "melihat" real-time via kamera sambil user gerakkan HP, ngobrol natural (voice in/out) tanpa foto manual: live scene description, text recognition, object localization ("di kanan atas"), kontrol flashlight otomatis, voice interface tanpa menu. Harus realistis dengan Flutter+FastAPI TANPA infrastruktur seberat Google, dan layak di device RAM 4–6GB + kuota data Indonesia.

## Opsi Arsitektur A: Streaming video kontinu ke server (WebRTC/WebSocket)
- **Cara kerja**: stream frame kontinu ke FastAPI, server jalankan vision.
- **Bandwidth**: streaming video 1 FPS 640×480 JPEG (~40KB/frame) = ~2.4MB/menit; 5 FPS = ~12MB/menit. Untuk kuota Indonesia (~Rp1.000–3.000/GB), 1 jam pemakaian 1 FPS ≈ 144MB ≈ Rp150–450. Layak untuk sesi pendek, boros untuk terus-menerus.
- **Kekurangan**: device low-end berat untuk encode+stream kontinu; Vinara tidak punya `webrtc` di pubspec (harus tambah dependency besar).

## Opsi Arsitektur B: Gemini Live API (streaming multimodal native)
- **Cara kerja**: WebSocket stateful, stream audio+video, terima suara balik. Ini yang paling mendekati Astra.
- **Batasan konkret (Google official)**: sesi audio+video **maks 2 menit** tanpa context compression (audio-only 15 menit); video diproses **1 FPS @ 768×768**, **258 token/detik** untuk video, **25 token/detik** audio; context window 128K. Dengan sliding-window compression, durasi bisa diperpanjang (ai.google.dev/gemini-api/docs/live-api/best-practices).
- **Biaya**: model native-audio 2.5 Flash = $0.50/M teks input, **$3.00/M audio-video input**, $12/M audio output. Per-menit ekuivalen Gemini 3.1 Flash Live preview ≈ **$0.005/menit audio in, $0.018/menit audio out** (rywalker.com/research/gemini-live-api). Video menambah 258 token/detik = 15.480 token/menit × $3/M ≈ **$0.046/menit video**. Jadi percakapan aktif audio+video ≈ **$0.05–0.07/menit** (~Rp800–1.100/menit). 10 menit/hari × 30 hari × 100 user ≈ $1.500–2.100/bulan - MAHAL untuk skala.
- **Region Indonesia**: ⚠️ ketersediaan region Live API untuk asia-southeast2 (Jakarta) BELUM terverifikasi dari dokumen resmi; perlu cek cloud.google.com/vertex-ai/generative-ai/docs/learn/locations.
- **Kelebihan**: pengalaman paling mulus, natural barge-in built-in.
- **Kekurangan**: biaya tinggi, sesi video pendek, ketergantungan penuh online, region belum pasti. Live API server-to-server only → FastAPI harus jadi perantara.

## Opsi Arsitektur C: Hybrid pintar: on-device gate + capture frame periodik (DIREKOMENDASIKAN)
- **Cara kerja**: SSD MobileNet on-device (SUDAH ADA) jadi *trigger/gate* yang menentukan KAPAN kirim frame ke vision API. Kirim frame hanya saat: (a) user bertanya, (b) scene berubah signifikan (frame differencing / semantic change: himpunan label deteksi berubah), (c) deteksi danger baru. Antara trigger, jawab dari konteks terakhir + deteksi lokal.
- **Biaya**: alih-alih streaming kontinu, mungkin hanya 3–10 frame vision API per percakapan. Dengan Gemini Flash-Lite ~$0.0004/frame → **<$0.005 per percakapan** (~Rp8). Ini 10× lebih murah dari Gemini Live.
- **Teknik**: keyframe selection, scene change detection via perbandingan histogram luma (pakai `LightService`!) atau perubahan set label deteksi. FramePacer existing (buang frame saat in-flight) sudah pola yang tepat.
- **Kelebihan**: murah, hemat kuota, memanfaatkan aset on-device, offline-tolerant (deteksi lokal tetap jalan).
- **Kekurangan**: tidak se-"live" Astra (ada jeda trigger), STT masih push-to-talk kecuali ditambah wake word/VAD.

## Opsi Arsitektur D: On-device VLM (Gemini Nano via ML Kit GenAI / SmolVLM / Moondream)
- **ML Kit GenAI Image Description** (developers.google.com/ml-kit/genai/image-description): pakai Gemini Nano via AICore. TAPI hanya jalan di device flagship (Pixel 8+, Galaxy S24+, chip MediaTek Dimensity/Snapdragon/Tensor tertentu) - **TIDAK jalan di device kelas bawah Indonesia (RAM 4–6GB, Snapdragon 6xx/Helio G)**. Prompt API masih Alpha, terbaik di Pixel 10 (nano-v3).
- **SmolVLM (2.2B)**: encode 384×384 patch = 81 token, hemat memori; SmolVLM-256M <1GB GPU. Moondream 0.5B/2B ada int4/int8 QAT untuk mobile. MobileVLM-3B: 21.5 token/detik di Snapdragon 888 CPU.
- **Kekurangan**: di device 4–6GB, VLM 2B+ berebut RAM dengan kamera+TFLite existing → risiko OOM & thermal throttling; token/detik rendah (~20 t/s) bikin deskripsi terasa lambat. Realistis hanya di flagship.
- **Rekomendasi**: JANGAN andalkan on-device VLM untuk device target sekarang; simpan sebagai opsi masa depan / khusus flagship.

## OpenAI Realtime API (untuk kelengkapan)
- **Vision**: mendukung **input gambar (still), BUKAN video streaming** - sistem "treats it more like adding a picture into the conversation" (openai.com/index/introducing-gpt-realtime/). Jadi bukan live video seperti Gemini Live.
- **Biaya**: gpt-realtime audio input $32/M, output $64/M (resmi OpenAI). ⚠️ Harga image input flagship (~$5/M) berasal dari tracker pihak ketiga, belum diverifikasi di platform.openai.com/docs/pricing.
- **Kesimpulan**: kalah dari Gemini Live untuk kasus "live vision" karena tidak streaming video; tidak direkomendasikan untuk Vinara.

## Self-host VLM di cloud GPU (jika volume besar & privasi)
- **Harga GPU** (RunPod Secure Cloud, verifikasi 2026-07-30): NVIDIA **L4 24GB $0.39/jam**, **RTX A5000 24GB $0.27/jam**, **A100 PCIe 80GB $1.39/jam**, A100 SXM 80GB $1.49/jam.
- **Throughput Qwen2.5-VL-7B**: di A100 40GB (vLLM benchmark, GitHub vllm #24728) = **20,89 request gambar/detik** vs hanya **7,35 request video/detik** @ concurrency 50. Ini mengukur overhead video vs gambar. ⚠️ Tidak ada angka throughput publik untuk L4/A10/T4.
- **Kesimpulan**: self-host baru masuk akal di skala ribuan user aktif dengan volume tinggi; di bawah itu, API pay-per-use (Gemini/Claude) lebih murah + tanpa ops overhead. Untuk MVP, JANGAN self-host.

## Desain UX voice hands-free
- **Wake word**: Picovoice Porcupine mendukung English, Mandarin, Prancis, Jerman, Italia, Jepang, Korea, Portugis, Spanyol - **Bahasa Indonesia TIDAK didukung** built-in ("Support for additional languages is available for commercial customers on a case-by-case basis", github.com/Picovoice/porcupine). Lisensi enterprise mahal (dilaporkan Foundation Plan ~$6.000). openWakeWord/Vosk open-source bisa dilatih ID tapi butuh effort. → **Wake word bahasa Indonesia native BELUM realistis** dari vendor jadi.
- **Rekomendasi**: pertahankan **push-to-talk (SUDAH ADA)** sebagai default + tambah **VAD (Voice Activity Detection)** sebagai jalan tengah untuk hands-free dalam mode Live (Picovoice Cobra VAD, atau `speech_to_text` `listenFor` diperpanjang). Continuous listening boros baterai & privasi.
- **Barge-in & echo (masalah nyata)**: `flutter_tts` + `speech_to_text` berebut audio session Android - ada bug terdokumentasi (github dlutton/flutter_tts #308: memulai STT saat TTS jalan bisa "mem-block" TTS). Solusi: gunakan `audio_session` package untuk konfigurasi kategori & focus; terapkan **half-duplex gating** (matikan STT saat TTS bicara untuk frasa kritis, aktifkan setelahnya) untuk hindari mic menangkap suara TTS sendiri. AEC penuh sulit di Flutter murni. `TtsQueue` + `interruptByUser()` existing sudah fondasi bagus untuk barge-in terkontrol.

## Object localization dengan arah relatif
Manfaatkan stack ada: bbox on-device + `_getDirection` (3-zona) + field `vertical` server (atas/tengah/bawah - SUDAH dihitung tapi belum dipakai!). Petakan bbox → frasa: gabungkan horizontal (kiri/depan/kanan) + vertical (atas/tengah/bawah) = "kanan atas", "kiri bawah". Clock-face ("jam 2") berguna untuk presisi tapi riset O&M menyarankan kiri/kanan egocentric untuk mayoritas kasus; pakai clock-face hanya saat user minta presisi. AKTIFKAN field `vertical` yang sudah ada.

## Kontrol flashlight di Flutter
- Package `torch_light` (pub.dev/packages/torch_light) atau `camera` `setFlashMode(FlashMode.torch)`. Konflik: saat kamera dipakai stream, `torch_light` bisa lempar `EnableTorchExistentUserException` ("camera in use"). Karena Vinara pakai `camera` untuk stream, gunakan `CameraController.setFlashMode(FlashMode.torch)` (satu controller, hindari konflik) BUKAN torch_light terpisah.
- **UX suara**: `LightService` deteksi gelap → asisten tawarkan via suara "Sekitar gelap, nyalakan senter?" → konfirmasi voice → nyalakan. `permission_handler ^11.3.1` sudah ada.

## Anti-tumpang-tindih: satu MODE terpadu, bukan fitur redundant
Jangan bikin Live Assistant sebagai fitur terpisah dari Scene Description + Cari Objek. Usulkan **`LiveAssistantProvider` dengan tool-calling/function-calling**: LLM (Claude/Gemini mendukung tool use) memanggil "cari objek", "baca teks", "deskripsikan scene", "nyalakan senter" sebagai tools, dipetakan ke 20 intent lokal `CommandParser` + provider existing (`FindObjectProvider`, `OcrService`, dll). Ini menyatukan Asisten Suara + Object Finding + Scene Description dalam satu interaksi voice-first. Layer 1 (keyword lokal 0ms) tetap jadi fast-path; Layer 2 LLM tool-calling untuk yang kompleks.

## Rekomendasi Fitur 3
**Opsi C (hybrid gate + frame periodik) sebagai fondasi, dengan `LiveAssistantProvider` + tool-calling.** Alasan: 10× lebih murah dari Gemini Live, hemat kuota Indonesia, memanfaatkan SSD MobileNet + LightService + deteksi terstruktur yang SUDAH ada, dan offline-tolerant. Pertahankan push-to-talk + tambah VAD untuk hands-free. Gemini Live API disimpan sebagai mode "premium/flagship" opsional bila budget & region memungkinkan. On-device VLM TIDAK untuk device target sekarang.

## Ditemukan tapi tidak disarankan
- **Gemini Live API sebagai default** - biaya ~Rp800–1.100/menit terlalu mahal untuk pasar Indonesia di skala; sesi video 2 menit; region belum pasti.
- **OpenAI Realtime API untuk live vision** - hanya input gambar still, bukan video streaming.
- **Wake word Picovoice Porcupine bahasa Indonesia** - tidak didukung + lisensi mahal.
- **On-device VLM (Gemini Nano/SmolVLM)** - tidak jalan di RAM 4–6GB / chip entry; hanya flagship.
- **WebRTC streaming kontinu** - dependency berat, boros device low-end.

## Pertanyaan buat user
1. Budget API bulanan untuk fitur live (menentukan hybrid vs Gemini Live)?
2. Target device minimum (menentukan kelayakan on-device VLM)?
3. Hands-free wajib, atau push-to-talk + VAD cukup untuk v1?
4. Boleh stream gambar ke cloud (privasi)?

---

# FITUR 4: Perbaikan Cari Objek / Object Finding

## Requirement & UX Goal
Berdasarkan ReCog (CHI 2020) & VizWiz::LocateIt: granularitas jarak kategori kasar; sonifikasi (beep tempo/pitch/volume + kiri/kanan/atas/bawah); disambiguasi objek serupa; scanning/sweep guidance; camera framing feedback kontinu.

## Audit implementasi sekarang vs 5 poin target
1. **Granularitas jarak kasar**: SEBAGIAN. Ada threshold-crossing `[0.6, 1.0, 2.0, 3.0]` tapi diumumkan sebagai angka presisi, bukan kategori "dekat/sedang/jauh". PERLU REVISI: umumkan kategori, angka presisi hanya saat sangat dekat (<0.6m).
2. **Sonifikasi**: TIDAK ADA sama sekali (hanya TTS + vibration per arah). PERLU DIBANGUN.
3. **Disambiguasi objek serupa**: TIDAK ADA (hanya count + nearest). `vertical` dihitung server tapi tidak dipakai. PERLU: umumkan tiap instans saat kamera menyapu dengan clock-position + jarak.
4. **Scanning/sweep guidance**: SEBAGIAN - ada "putar badan pelan-pelan" tiap 6 tick, tapi tidak ada feedback eksplisit saat objek masuk/keluar frame. `lostFromView` ada di enum tapi TIDAK PERNAH di-set. PERLU DIPERBAIKI.
5. **Camera framing feedback kontinu**: TIDAK ADA. PERLU sonifikasi kontinu.

## Opsi sonifikasi real-time di Flutter
- **Opsi 1 - `flutter_soloud` (DIREKOMENDASIKAN)**: engine C++ SoLoud low-latency, bisa **generate waveform real-time (sine/square/saw/triangle)**, buffer stream PCM, efek pitch shift, 3D positional/panning (pub.dev/packages/flutter_soloud). Cocok untuk beep dinamis: ubah frekuensi/tempo/volume/pan real-time berdasarkan jarak & arah tanpa file statis.
- **Opsi 2 - `flutter_pcm_sound`**: kirim PCM 16-bit real-time via callback, nol dependency selain platform. Bagus untuk sintesis tone kustom penuh; lebih low-level.
- **Opsi 3 - `just_audio` + tone bank pre-generated / `soundpool`**: play file tone dengan playbackRate. Kurang fleksibel untuk pitch/tempo kontinu; latency lebih tinggi.
- **Audio focus conflict**: sonifikasi + `flutter_tts` + `speech_to_text` berebut audio session Android. Gunakan `audio_session` untuk kategori "playback + mixWithOthers/duck"; beep di-duck saat TTS critical bicara. flutter_soloud dan flutter_tts bisa koeksis bila kategori diset benar.

## Mapping parameter sonifikasi (berbasis literatur, bukan asumsi)
Studi **Bazilinskyy et al. (2016, IFAC-PapersOnLine 49(19):531–536, DOI 10.1016/j.ifacol.2016.10.614, N=29)** membandingkan 3 metode: **Beep Repetition Rate (BRR)** - tempo beep fungsi jarak; **Sound Intensity (SI)** - volume fungsi jarak; **Sound Fundamental Frequency (SFF)** - pitch fungsi jarak; azimuth/arah dipetakan lewat **beda volume kiri-kanan (stereo panning)**. Studi **Delaunay & Ambard ("How well do you see what you hear?", 28 partisipan)** menemukan: "The best depth estimates... were obtained with the sound frequency and the repetition rate of beeps... the beep repetition rate yielded the best depth estimation." Rekomendasi mapping Vinara:
- **Jarak → tempo (BRR)**: makin dekat, makin cepat (mis. 2 Hz @ 3m → 8 Hz @ 0.6m). Utama.
- **Jarak → pitch (opsional redundan)**: The Sonification Handbook memperingatkan mapping redundan pitch+tempo TIDAK selalu memperbaiki performa - jangan berlebihan. Cukup tempo + panning.
- **Arah horizontal → stereo panning** (pakai headphone/speaker stereo).
- **Vertical (atas/bawah) → pitch dasar** (atas=pitch tinggi, bawah=rendah) - memanfaatkan `vertical` server yang ada.
- **Objek dalam frame → earcon "found"** yang beda dari sweep tone.
CATATAN spatial audio: teknik panning stereo di sini adalah reuse ringan dari konsep spatial audio (yang dicoret sebagai fitur mandiri) - hanya panning L/R, bukan 3D beacon.

## Estimasi jarak: bbox similar-triangle vs depth estimation
- **Sekarang**: similar-triangle `FOCAL_LENGTH_PX=615`. Kelemahan: butuh kalibrasi per-device (fokus px beda tiap kamera), objek tidak tegak/terpotong bikin error besar, tinggi asli bervariasi (`DEFAULT_HEIGHT_CM=20` kasar). Untuk kategori kasar (dekat/sedang/jauh) ini CUKUP.
- **Depth estimation on-device**: MiDaS v2 TFLite = 66.3MB; di NPU flagship (Galaxy S23) ~1–3ms, tapi rentang 2.1–84.5ms tergantung device - di Snapdragon 6xx/Helio G CPU jauh lebih lambat (huggingface.co/qualcomm/Midas-V2). Depth Anything V2 Small (25M param) bagus tapi berat untuk entry Android. Jalan BERSAMAAN dengan SSD MobileNet = beban ganda, risiko thermal.
- **Rekomendasi**: PERTAHANKAN similar-triangle untuk kategori jarak kasar (murah, cukup). Depth estimation TIDAK sepadan untuk device target sekarang.

## Pipeline & jalur on-device untuk Cari Objek
- **Usulan penting**: kalau target Cari Objek termasuk 80 kelas COCO yang SUDAH bisa dideteksi SSD MobileNet on-device → jalankan LOKAL (lebih responsif, offline, tanpa server round-trip). Hanya kalau target DI LUAR COCO → baru pakai YOLOE server. Ini memberi jalur offline yang sekarang tidak ada (Cari Objek 100% server).
- **Alternatif open-vocab lebih ringan dari YOLOE untuk server**: YOLO-World (Tencent, prompt-then-detect, ~74 FPS di V100, mAP LVIS ~35.4) lebih cepat dari Grounding DINO (mAP lebih tinggi ~52.5 tapi lambat, API-based). OWLv2 (mAP ~47) punya implementasi HuggingFace. Untuk real-time server, YOLO-World unggul throughput; YOLOE (existing) sudah masuk akal karena open-vocab + seg. Grounding DINO hanya bila akurasi zero-shot kritis.

## Rekomendasi Fitur 4
1. **Bangun sonifikasi dengan `flutter_soloud`**: jarak→tempo (BRR), arah→panning stereo, vertical→pitch. Ini prioritas tertinggi karena benar-benar hilang.
2. **Ubah granularitas jarak jadi kategori** (dekat/sedang/jauh), angka presisi hanya <0.6m.
3. **Aktifkan `vertical`** untuk clock-position/atas-bawah dalam disambiguasi & sonifikasi.
4. **Perbaiki state `lostFromView`** (set saat objek keluar frame) + earcon masuk/keluar frame.
5. **Tambah jalur on-device** untuk target COCO (offline + responsif); YOLOE server hanya untuk non-COCO.
Pertahankan similar-triangle (jangan tambah depth model). Semua ini menghormati loop 350ms + FramePacer 600ms existing.

## Ditemukan tapi tidak disarankan
- **Monocular depth (MiDaS/Depth Anything) on-device** - terlalu berat jalan bareng SSD MobileNet di device entry; overkill untuk kategori jarak kasar.
- **Grounding DINO server** - akurasi tinggi tapi latency/VRAM besar, tidak real-time untuk sweep.
- **Mapping pitch+tempo redundan penuh** - literatur (Sonification Handbook) menunjukkan tidak menambah performa.

## Pertanyaan buat user
1. User biasanya pakai headphone (panning stereo efektif) atau speaker HP (panning lemah)?
2. Berapa banyak target Cari Objek di luar 80 kelas COCO (menentukan seberapa penting jalur server)?
3. Sonifikasi sebagai default ON atau opsi (beberapa user lebih suka speech saja)?

---

# FITUR 5: Upgrade Navigasi Trotoar: deteksi bahaya & panduan hindari halangan

## Requirement & UX Goal
(a) Deteksi bahaya jalur (lubang, tangga turun, halangan mendadak) dengan peringatan prioritas tinggi; (b) arahan hindari ("ada orang di depan, geser kanan sedikit"). BUKAN face recognition - murni deteksi keberadaan sebagai halangan. Prinsip: egocentric framing, prioritas bahaya > info, framing "jalur aman", hindari overload multimodal.

## Arsitektur pipeline: segmentasi + object detection
- **Kombinasi**: PIDNet-S/SegFormer-B0 (jalur walkable) + SSD MobileNet (halangan) dengan **masking bbox terhadap mask jalur**: hitung IoU/overlap footprint bbox (bagian bawah bbox = titik kontak tanah) dengan region walkable. Kalau footprint objek jatuh DI DALAM jalur aman → itu halangan yang relevan; kalau di luar → abaikan. Ini lebih murah dari occupancy grid penuh.
- **Model multi-task satu forward pass**: YOLOP, HybridNets, YOLOPv2 (deteksi + drivable area + lane dalam satu jaringan). Menarik secara efisiensi tapi dilatih untuk jalan raya mobil, bukan trotoar pejalan → perlu retraining dengan data trotoar. Belum realistis tanpa dataset.

## Deteksi drop-off/tangga turun/lubang
- **Dataset**: **SideGuide** (IROS 2020, Park et al., DOI 10.1109/IROS45743.2020.9340734) - 350K bbox, 100K polygon mask, 180K stereo pair, objek trotoar dari wawancara penyandang disabilitas (curb, stairs, dll). SENSATION-DS (2.752 image chest-view, 9 kelas navigasi). Cityscapes/Mapillary (jalan raya, kurang cocok trotoar). Dataset trotoar Indonesia spesifik: tidak ditemukan - ini gap nyata.
- **Realistis dengan kamera monokuler**: deteksi lubang/curb sebagai OBJEK (bbox/segmentasi) bisa dilatih dari SideGuide. TAPI drop-off/tangga TURUN sangat sulit dari monokuler tanpa depth - depth discontinuity/ground-plane fitting/vanishing point membantu tapi rawan false negative. **Ini fitur safety-critical: risiko false negative tinggi** - jangan janjikan deteksi tangga turun yang andal dari kamera HP saja. Sampaikan keterbatasan ini ke user secara jujur (konsisten dengan prinsip Vinara).

## Menentukan "arah geser" (algoritma konkret)
Backend `segmentation_service.py` sudah bagi frame bawah jadi 3 kolom (kiri/tengah/kanan) dengan `walkable_ratio`. Perluas:
- **Gap analysis per kolom**: cari kolom walkable terlebar / `walkable_ratio` tertinggi = arah geser. Atau hitung **centroid free-space** di separuh bawah frame.
- **Hysteresis** untuk stabilitas: jangan ganti instruksi "geser kanan/kiri" kecuali selisih walkable antar sisi melewati ambang (mis. >15%) DAN bertahan ≥2 frame. Mencegah bolak-balik tiap frame. Ini analog `streak 2 frame` di DetectionFilter existing.
- Output egocentric: "geser kanan sedikit" (relatif badan, bukan kompas).

## Prioritization system
Vinara SUDAH punya `SpeechTier` (info/warning/critical) + DetectionFilter cooldown per tier. Perluas:
- **Time-to-collision (TTC)** dari `isApproaching` ObjectTracker: objek mendekat cepat → naikkan urgency → critical + interrupt. Cooldown sudah dipotong 50% saat isApproaching.
- **Threshold jarak dinamis** mengikuti kecepatan jalan (dari `sensors_plus` accelerometer): jalan cepat → warning lebih dini.
- **Urgency score** = f(jarak, TTC, danger level, di dalam jalur). allDanger → "Berhenti dulu" (critical, sudah ada). Center danger → takeover (sudah ada).
Literatur alert prioritization/interruption management mendukung: bahaya mendadak interupsi, info non-kritis antre (sudah tercermin di TtsQueue: Info dibuang kalau menunggu >2s).

## Performa real-time on-device (benchmark)
- **PIDNet-S**: 78.6% mIoU @ 93.2 FPS di Cityscapes test (RTX GPU - bukan mobile). Di mobile CPU/NNAPI jauh lebih lambat.
- **SegFormer-B0**: ~82.98% mIoU tapi hybrid transformer, lebih berat di CPU.
- **Fast-SCNN / BiSeNetV2 / DDRNet-23-slim**: dirancang real-time, lebih ringan. Fast-SCNN "learning to downsample" sangat ringan.
- **Angka mobile spesifik (Snapdragon 680/695, Helio G85/G99, Exynos 1330)**: ⚠️ benchmark publik langsung TIDAK ditemukan - data tidak tersedia. Yang pasti: transformer (SegFormer) lebih berat dari CNN ringan (Fast-SCNN/PIDNet-S) di mobile CPU.
- **Strategi optimasi**: input resolution lebih kecil (512→384/256), **INT8 quantization**, **NNAPI/GPU delegate** di `tflite_flutter ^0.12.1`, **frame skipping / temporal alternation** (segmentasi tiap N frame, deteksi tiap frame), **IsolateInterpreter terpisah** (sudah dipakai). 
- **Server vs on-device**: sekarang Navigasi 100% server (offline = berhenti total). Memindah segmentasi on-device memberi offline-capability tapi berat di device entry. **Rekomendasi**: tetap server-primary untuk segmentasi (PIDNet ONNX saat model tersedia), tapi tambah **fallback on-device ringan** (mis. heuristik OpenCV yang sudah ada dijalankan lokal, atau Fast-SCNN INT8) agar offline tidak "berhenti total". CATATAN: model PIDNet (`pidnet_s_3zona.onnx`) BELUM ADA - sekarang jalan heuristik OpenCV; field `source` jujur melaporkan ini.

## TTS responsif & bisa diinterupsi untuk urgent alert
- `flutter_tts` `stop()` + `speak()` di Android: ada latency kecil; `awaitSpeakCompletion(true)` bisa menghambat interupsi cepat. Untuk alert kritis ("Berhenti!"), latency TTS berbahaya.
- **Rekomendasi**: gunakan **pre-rendered audio clip / earcon** untuk frasa kritis ("Berhenti!") via `flutter_soloud` (latency ~0), BUKAN TTS sintesis on-the-fly. Riset auditory display: earcon non-speech lebih cepat dipahami daripada speech untuk alert mendesak. TtsQueue Critical (clear+interrupt) sudah ada; tambahkan jalur earcon paralel untuk kritis. Native `TextToSpeech` QUEUE_FLUSH via platform channel bila perlu kontrol lebih.

## Rekomendasi Fitur 5
1. **Segmentasi (server-primary, PIDNet-S ONNX saat model jadi) + SSD MobileNet halangan, digabung via footprint-in-walkable masking.**
2. **Arah geser via gap analysis per kolom + hysteresis** (hormati pola streak existing).
3. **Prioritization**: perluas SpeechTier dengan TTC + urgency score + threshold dinamis dari accelerometer.
4. **Earcon pre-rendered untuk "Berhenti!"** (latency ~0) via flutter_soloud, jangan TTS.
5. **Fallback on-device ringan** (Fast-SCNN INT8 atau heuristik lokal) agar offline tidak berhenti total.
6. **Jujur soal keterbatasan** deteksi tangga turun/drop-off monokuler (risiko false negative) - jangan over-promise.

## Ditemukan tapi tidak disarankan
- **YOLOP/HybridNets/YOLOPv2 multi-task** - dilatih untuk jalan raya mobil, butuh retraining data trotoar yang belum ada.
- **Deteksi tangga turun andal dari monokuler** - risiko false negative terlalu tinggi untuk safety-critical tanpa depth sensor.
- **SegFormer-B0 on-device di device entry** - transformer terlalu berat; pilih CNN ringan bila on-device.
- **Multimodal overload** (haptik+audio+speech bersamaan) - riset EEG menunjukkan menambah beban kognitif.

## Pertanyaan buat user
1. Prioritas: offline-capability (perlu segmentasi on-device) vs akurasi (server)?
2. Ada akses ke dataset trotoar Indonesia, atau perlu andalkan SideGuide + fine-tune?
3. Target device minimum untuk fitur navigasi (menentukan model segmentasi)?
4. Terima keterbatasan jujur "tidak bisa jamin deteksi tangga turun"?

---

# BAGIAN C: Tumpang Tindih Mode Tuntun vs Navigasi Jalur

**Rekomendasi tegas: JANGAN lebur total; jadikan dua mode dengan pembagian use-case JELAS + auto-switch kontekstual, dan bedakan Mode Tuntun menjadi fokus rintangan level mata/kepala.**

## Alasan teknis
1. **Satu `CameraController` tidak bisa dilayani dua konsumen ML berat sekaligus** di Android. Menjalankan Mode Tuntun (SSD MobileNet) DAN Navigasi (segmentasi) paralel dari satu stream = rebutan frame + CPU/RAM ganda + thermal throttling di device entry. Jadi 2 mode PARALEL boros/redundant - harus satu mode aktif pada satu waktu.
2. **Melebur total juga tidak optimal**: segmentasi trotoar (mask jalur) dan deteksi objek umum (indoor/jalan bebas) punya tujuan berbeda. Trotoar butuh walkable-region; indoor butuh deteksi objek murni.

## Usulan pembedaan (menjawab opsi 2 & 3)
- **Navigasi Jalur** = khusus trotoar outdoor: segmentasi jalur + halangan di jalur + hazard.
- **Mode Tuntun diubah** = fokus **rintangan level mata/dada/kepala** (dahan pohon, kanopi rendah, palang, papan reklame rendah) + rintangan indoor/jalan bebas. Ini menutup **kelemahan klasik tongkat putih yang terdokumentasi di literatur O&M**: tongkat hanya menyapu bawah, tidak mendeteksi rintangan level kepala. Riset head-level obstacle: "User Evaluation of Head-Level Obstacle Detector for Visually Impaired" (Technologies 2025, doi:10.3390/technologies13090407) menegaskan tongkat putih hanya deteksi rintangan bawah & posisi/mounting detektor krusial; banyak sistem pakai ultrasonic/LiDAR di kepala. Vinara bisa mendekati ini via **sudut kamera/pitch HP**: baca accelerometer `sensors_plus` (SUDAH dipakai untuk camera health) untuk tahu apakah HP diarahkan ke depan/atas (deteksi level kepala) vs ke bawah/trotoar (Navigasi). Ini pembeda produk yang kuat dan jarang ada di produk lain (kebanyakan butuh hardware tambahan).

## UX mode-switching (menjawab opsi 4)
Riset UX assistive navigation menekankan **mode-switching burden** memberatkan pengguna tunanetra. Solusi:
- **Auto-switch berbasis konteks**: gunakan pitch HP (accelerometer) + LightService + hasil segmentasi untuk menebak konteks. HP diarahkan ke depan/atas & ada langit/kanopi → Mode Tuntun (level kepala); HP menunduk ke trotoar & terdeteksi jalur → Navigasi Jalur. 
- **Tetap sediakan override manual** via voice ("mode tuntun", "mode navigasi") lewat CommandParser (20 intent).
- **Satu tombol "mulai jalan"** yang otomatis memilih mode berdasarkan konteks, dengan pengumuman mode aktif ("Mode trotoar aktif") supaya user tidak bingung.

## Pertimbangan resource
Karena satu kamera = satu konsumen aktif, auto-switch memastikan hanya SATU model ML berat jalan pada satu waktu → hemat CPU/RAM/thermal/baterai. Ini alasan teknis kuat untuk auto-switch dibanding dua mode paralel.

---

# PENUTUP

## Dependency & Urutan Pengerjaan
1. **Fitur 2 (Light Detection) DULU** - paling murah, jadi fondasi shared service (`LightService`) yang dipakai Fitur 3 (trigger flashlight & scene-change gate), Fitur 4 (deteksi tooDark), Fitur 5.
2. **Fitur 4 (Perbaikan Cari Objek)** - bangun infrastruktur **sonifikasi `flutter_soloud`** yang akan dipakai ulang untuk earcon Fitur 5. Aktifkan `vertical`, jalur on-device COCO.
3. **Fitur 5 (Navigasi upgrade)** - pakai sonifikasi/earcon dari Fitur 4, prioritization SpeechTier, footprint masking. Juga menyiapkan pola deteksi-di-jalur untuk Mode Tuntun.
4. **Fitur 1 (Scene Description hybrid grounding)** - perluas `/api/narasi` dengan gambar + grounding; fondasi VLM untuk Fitur 3.
5. **Fitur 3 (Live Assistant) TERAKHIR** - butuh Fitur 1 (VLM), Fitur 2 (gate/flashlight), Fitur 4 (object localization), dan deteksi Fitur 5 sudah jalan; menyatukan semua via `LiveAssistantProvider` + tool-calling.

## Potensi Konflik Teknis (antisipasi sejak awal)
- **Rebutan kamera**: satu `CameraController`, banyak konsumen. WAJIB arsitektur satu-konsumen-aktif + frame fan-out terkontrol. FramePacer existing sudah pola tepat. Jangan dua mode ML paralel.
- **Rebutan audio session Android**: `flutter_tts` + `speech_to_text` + sonifikasi `flutter_soloud` berebut audio focus → echo (mic tangkap TTS), bug blocking (dlutton/flutter_tts #308). Solusi: `audio_session` untuk kategori/ducking; half-duplex gating STT saat TTS critical; earcon di-duck.
- **CPU/RAM budget**: beberapa TFLite (SSD MobileNet + segmentasi + depth) bersamaan = OOM/thermal di device 4–6GB. Solusi: satu model berat aktif, IsolateInterpreter, INT8, frame skipping.
- **Thermal throttling**: inferensi kontinu + kamera + flashlight memanaskan device entry → turunkan clock → latency naik. Solusi: adaptive frame rate, matikan flashlight bila tak perlu.
- **Konsumsi kuota data**: fitur server (Navigasi, Cari Objek, Live, Narasi) makan kuota. Solusi: hybrid gate (kirim frame hanya saat perlu), JPEG quality adaptif, jalur on-device untuk yang bisa lokal, idempotency + offline queue (sudah ada).

## Tabel Ringkasan Opsi

| Fitur | Opsi | Offline | Latency estimasi | Biaya | Effort | Rekomendasi |
|---|---|---|---|---|---|---|
| 1 Scene Desc | Gemini Flash-Lite + grounding | Tidak | ~1–2s + jaringan | ~Rp5–8/query | Sedang | ✅ Ya |
| 1 Scene Desc | Claude Haiku 4.5 vision | Tidak | ~1–2s + jaringan | ~Rp24/query | Sedang | ✅ Fallback |
| 1 Scene Desc | Pipeline 2 model | Tidak | ~3–4s | Lebih mahal | Tinggi | ❌ Tidak |
| 2 Light | Luma Y-plane + variance | Ya | <1ms | Rp0 | Rendah | ✅ Ya |
| 2 Light | Ambient light sensor | Ya | ~instant | Rp0 | Rendah | ❌ Tidak (sensor sering absen) |
| 3 Live | Hybrid gate + frame periodik | Sebagian | ~1–2s/trigger | ~Rp8/percakapan | Tinggi | ✅ Ya |
| 3 Live | Gemini Live API | Tidak | Real-time | ~Rp800–1.100/mnt | Sedang | ⚠️ Premium opsional |
| 3 Live | OpenAI Realtime (vision) | Tidak | Real-time | audio $32/$64 per 1M | Sedang | ❌ Tidak (still image only) |
| 3 Live | On-device VLM (Nano/SmolVLM) | Ya | Lambat (~20t/s) | Rp0 | Tinggi | ❌ Hanya flagship |
| 4 Cari Objek | Sonifikasi flutter_soloud | Ya | <50ms | Rp0 | Sedang | ✅ Ya |
| 4 Cari Objek | Jalur on-device COCO | Ya | ~real-time | Rp0 | Sedang | ✅ Ya |
| 4 Cari Objek | Depth (MiDaS/DepthAnything) | Ya | Berat di entry | Rp0 | Tinggi | ❌ Tidak |
| 4 Cari Objek | YOLO-World server (non-COCO) | Tidak | ~server | GPU | Sedang | ✅ Untuk non-COCO |
| 5 Navigasi | Segmentasi server + SSD + masking | Tidak | ~server | GPU | Tinggi | ✅ Ya |
| 5 Navigasi | Fallback on-device Fast-SCNN INT8 | Ya | Sedang | Rp0 | Tinggi | ✅ Ya |
| 5 Navigasi | SegFormer-B0 on-device entry | Ya | Berat | Rp0 | Tinggi | ❌ Tidak |
| 5 Navigasi | Earcon pre-rendered "Berhenti!" | Ya | ~0ms | Rp0 | Rendah | ✅ Ya |

## Fitur yang tidak dibahas (sesuai batasan)
Color detection, barcode/product recognition, face/person recognition & identifikasi, remote sighted assistance, GPS turn-by-turn + POI, spatial/3D audio beacon, handwriting recognition - TIDAK direkomendasikan sesuai instruksi. Teknik panning stereo dari spatial audio hanya dipakai ringan sebagai catatan untuk sonifikasi Cari Objek, bukan fitur beacon mandiri.

---

## Referensi Kunci (untuk verifikasi klaim)
- Claude Haiku 4.5 pricing - anthropic.com/claude/haiku ($1/M input, $5/M output; cache read $0.10/M, write $1.25/M).
- Gemini pricing - ai.google.dev/gemini-api/docs/pricing (2.5 Flash-Lite $0.10/$0.40; batch $0.05/$0.20; 3.1 Flash-Lite $0.25/$1.50).
- Anthropic image tokens - `(w×h)/750`; prompt caching - platform.claude.com/docs/en/build-with-claude/prompt-caching.
- Gemini Live API limits - ai.google.dev/gemini-api/docs/live-api/best-practices (audio+video 2 min, video 258 TPS @ 1 FPS).
- OpenAI Realtime - openai.com/index/introducing-gpt-realtime/ (image still only; audio $32/$64 per 1M).
- CHI 2024 scene description trust - arXiv:2403.15604 (trust 2,43/4; satisfaction 2,76/5); ASSETS 2024 "Misfitting With AI" dl.acm.org/doi/10.1145/3663548.3675659.
- Sonifikasi - Bazilinskyy et al. 2016 (DOI 10.1016/j.ifacol.2016.10.614, N=29, BRR/SI/SFF + panning); Delaunay & Ambard (repetition rate best depth); The Sonification Handbook (redundant mapping caveat).
- Picovoice Porcupine languages - github.com/Picovoice/porcupine (ID tidak didukung built-in).
- MiDaS-V2 TFLite - huggingface.co/qualcomm/Midas-V2 (66.3MB, 2.1–84.5ms).
- PIDNet-S - 78.6% mIoU @ 93.2 FPS Cityscapes (arXiv:2206.02066); SideGuide - DOI 10.1109/IROS45743.2020.9340734.
- Head-level obstacle - doi:10.3390/technologies13090407.
- Flutter: flutter_soloud (pub.dev/packages/flutter_soloud), torch_light (pub.dev/packages/torch_light), flutter_tts↔speech_to_text konflik (github dlutton/flutter_tts #308).
- ML Kit GenAI / Gemini Nano - developers.google.com/ml-kit/genai/image-description (flagship only).
- RunPod GPU - L4 24GB $0.39/jam, A5000 24GB $0.27/jam, A100 80GB $1.39/jam; Qwen2.5-VL-7B A100 40GB 20,89 img req/s vs 7,35 video req/s (github vllm #24728).