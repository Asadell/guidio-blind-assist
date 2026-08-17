# Panduan & Analisis Arsitektur Navigasi Asistif Tunanetra

> Dokumen komprehensif mengenai fundamental sistem navigasi mikro berbasis Computer Vision untuk tunanetra, analisis komparasi teknologi, alasan penolakan metode alternatif, serta prompt template siap pakai.

---

## 📑 Daftar Isi
1. [Konteks & Problem Statement (Mikro-Navigasi)](#1-konteks--problem-statement-mikro-navigasi)
2. [Fundamental & Arsitektur Solusi yang Direkomendasikan](#2-fundamental--arsitektur-solusi-yang-direkomendasikan)
   - [2.1 Segmentasi Jalur Layak Injak & Grid 3-Zona](#21-segmentasi-jalur-layak-injak--grid-3-zona)
   - [2.2 Deteksi Bahaya Khusus: Tangga dan Lubang](#22-deteksi-bahaya-khusus-tangga-dan-lubang)
   - [2.3 Estimasi Jarak Monokuler (Single RGB Camera)](#23-estimasi-jarak-monokuler-single-rgb-camera)
   - [2.4 Sensor Fusion Kamera + IMU (Gyroscope/Accelerometer)](#24-sensor-fusion-kamera--imu-gyroscopeaccelerometer)
   - [2.5 Arsitektur Hybrid: Pembagian Beban On-Device vs Server](#25-arsitektur-hybrid-pembagian-beban-on-device-vs-server)
   - [2.6 Desain Interaksi: Anti-Banjir Suara & Haptik Kritis](#26-desain-interaksi-anti-banjir-suara--haptik-kritis)
3. [Analisis Pendekatan Alternatif & Alasan Tidak Dipakai](#3-analisis-pendekatan-alternatif--alasan-tidak-dipakai)
   - [3.1 Hardware Sensor Tambahan (Tongkat Ultrasonik / LiDAR Add-on)](#31-hardware-sensor-tambahan-tongkat-ultrasonik--lidar-add-on)
   - [3.2 Pure VLM / LLM Video Streaming (Gemini Live / GPT-4o)](#32-pure-vlm--llm-video-streaming-gemini-live--gpt-4o)
   - [3.3 Full On-Device Heavy Semantic Segmentation di HP](#33-full-on-device-heavy-semantic-segmentation-di-hp)
   - [3.4 Standalone GPS Turn-by-Turn (Google Maps / OSM)](#34-standalone-gps-turn-by-turn-google-maps--osm)
   - [3.5 Pure Classical Computer Vision (Edge/Color Detection Saja)](#35-pure-classical-computer-vision-edgecolor-detection-saja)
4. [Matriks Perbandingan & Evaluasi Trade-Off](#4-matriks-perbandingan--evaluasi-trade-off)
5. [Master Prompt Template untuk AI Eksternal](#5-master-prompt-template-untuk-ai-eksternal)

---

## 1. Konteks & Problem Statement (Mikro-Navigasi)

Navigasi bagi tunanetra terbagi menjadi dua level:
1. **Makro-Navigasi (Global):** Menentukan rute dari Titik A ke Titik B (misal: berjalan 200m ke arah utara menuju halte bus). Masalah ini sudah cukup terbantu oleh GPS dan peta digital.
2. **Mikro-Navigasi (Lokal/Spasial Kritis):** Memandu **langkah kaki per detik** agar tidak menabrak rintangan setinggi tubuh (tiang, spion mobil, ranting), tidak terperosok ke dalam **lubang/selokan**, dan tidak tersandung **undakan/tangga**.

Tantangan utama mikro-navigasi smartphone:
- **Latensi Kritis:** Kecepatan berjalan manusia adalah ~1 hingga 1.4 m/s. Peringatan bahaya yang terlambat 1 detik dapat menyebabkan pengguna celaka.
- **Keterbatasan Sensori:** Pengguna mengandalkan telinga untuk mendengar suara lingkungan sekitar (klakson, deru mesin, langkah kaki). Aplikasi tidak boleh membuat pengguna "tuli" terhadap lingkungannya akibat suara notifikasi yang tiada henti.
- **Variabilitas Lingkungan:** Bayangan pohon, genangan air berbayang cermin, aspal belang, dan goyangan tangan saat melangkah.

---

## 2. Fundamental & Arsitektur Solusi yang Direkomendasikan

### 2.1 Segmentasi Jalur Layak Injak & Grid 3-Zona
* **Konsep:** Citra dari kamera depan dibagi secara vertikal menjadi 3 zona geometris di depan langkah kaki: **Kiri**, **Tengah**, dan **Kanan**.
* **Mekanisme AI:** Model segmentasi semantik jalan (misal: *PIDNet* atau *BiSeNet*) mengklasifikasikan tiap piksel bidang tanah menjadi 3 kelas:
  - *Class 0 (Non-Walkable / Danger):* Jalan raya kendaraan, selokan, dinding, rumput liar.
  - *Class 1 (Walkable / Safe):* Trotoar rata, jalur pemandu kuning (guiding blocks), lantai dalam ruangan.
  - *Class 2 (Caution / Warning):* Tepi trotoar, permukaan bergelombang, genangan tipis.
* **Pengambilan Keputusan:** Sistem menghitung rasio permukaan layak-injak (*walkable ratio*) di tiap kolom:
  - Jika **Tengah = Aman**: Instruksi tetap lurus.
  - Jika **Tengah = Bahaya** tapi **Kiri = Aman**: Instruksi *"Geser ke kiri"*.
  - Jika **Semua = Bahaya**: Instruksi darurat *"Berhenti dulu, tidak ada jalur aman"*.

---

### 2.2 Deteksi Bahaya Khusus: Tangga dan Lubang
* **Deteksi Tangga (Stairs):**
  - Menggabungkan model Object Detection (YOLO) berbobot ringan untuk mengenali pola anak tangga (naik/turun).
  - Tepi-tepi undakan tangga memutus kontinuitas bidang datar (*edge discontinuity*), yang secara otomatis memicu penurunan drastis pada *walkable ratio* zona terkait.
* **Deteksi Lubang & Got Terbuka (Potholes / Drop-offs):**
  - Lubang di permukaan jalan memecah keseragaman tekstur dan warna bidang acuan di depan kaki.
  - Begitu anomali kontur terdeteksi di zona tengah, sistem memicu *state* darurat `pothole` yang menginstruksikan pengguna untuk berhenti sebelum langkah berikutnya menapak.

---

### 2.3 Estimasi Jarak Monokuler (Single RGB Camera)
* **Konsep:** Smartphone standar hanya memiliki satu kamera RGB aktif dalam satu waktu (tanpa sensor depth bawaan).
* **Mekanisme:**
  1. **Tinggi Objek Relatif (*Bounding Box Heuristics*):** Mengetahui tinggi rata-rata objek nyata (orang = 170cm, motor = 120cm, tiang = 250cm) lalu menghitung proyeksi piksel terhadap *focal length* kamera:
     $$\text{Jarak} = \frac{\text{Tinggi Nyata} \times \text{Focal Length (px)}}{\text{Tinggi Bounding Box (px)}}$$
  2. **Posisi Garis Tanah (*Ground Contact Point*):** Koordinat piksel terbawah dari suatu rintangan ($y_{\text{max}}$) menunjukkan seberapa dekat dasar objek tersebut dengan kaki pengguna.

---

### 2.4 Sensor Fusion Kamera + IMU (Gyroscope/Accelerometer)
* **Masalah:** Sudut HP yang terlalu mendongak ke langit atau terlalu menunduk ke sepatu akan merusak akurasi segmentasi.
* **Solusi:** Membaca sudut pitch dari sensor kemiringan ponsel (IMU/Gyroscope). Sistem hanya memproses inferensi saat sudut kemiringan berada di rentang optimal (misal $40^\circ - 70^\circ$ ke arah lantai). Jika sudut di luar batas, sistem memberikan nada panduan singkat untuk memposisikan ulang HP.

---

### 2.5 Arsitektur Hybrid: Pembagian Beban On-Device vs Server
* **On-Device (Smartphone):**
  - Manajemen aliran kamera (*Frame Pacing* tiap 400–600ms).
  - Filter sensor gerak & sudut kamera.
  - UI State Machine (status zona, getaran haptik, dan antrean audio prioritas).
  - Deteksi rintangan instan fallback berbasis TFLite (SSD-MobileNet / YOLO-nano).
* **Server-Side (Local/Cloud Backend):**
  - Segmentasi semantik berakurasi tinggi (PIDNet ONNX).
  - Deteksi objek menyeluruh (YOLO11).
  - Integrasi database zona bahaya berbasis GPS (*Risk Zone Database*).

---

### 2.6 Desain Interaksi: Anti-Banjir Suara & Haptik Kritis
* **Prinsip "Audio Minimality":** Jangan pernah berbicara terus-menerus. Informasi yang berulang hanya diumumkan jika ada perubahan status zona atau setelah interval jeda (misal 5–6 detik).
* **Hirarki Prioritas Suara (*Speech Tier Queue*):**
  1. **Tier 1 - Kritis (Emergency / Immediate Takeover):** Rintangan mendadak < 1 meter atau lubang di jalur tengah. Suara langsung memotong ucapan lain + memicu getaran haptik panjang.
  2. **Tier 2 - Peringatan (Warning):** Perintah geser jalur atau mendekati tangga (jeda minimal 1.8 detik).
  3. **Tier 3 - Info Rutin (Info):** Konfirmasi jalur lurus aman (hanya diumumkan berkala).

---

## 3. Analisis Pendekatan Alternatif & Alasan Tidak Dipakai

Di bawah ini adalah analisis mendalam mengapa pendekatan-pendekatan alternatif yang populer justru **tidak dipilih atau dieliminasi** untuk sistem ini:

```
+-------------------------------------------------------------------------+
|                  SPEKTRUM PENDEKATAN NAVIGASI ASISTIF                   |
+-------------------------------------------------------------------------+
| [Hardware Eksternal]   [Heavy On-Device]   [HYBRID GUIDIO]   [Pure VLM] |
| Biaya Tinggi           HP Panas/Throttling  Cepat & Akurat   Latensi &  |
| Tidak Aksesibel        Akurasi Rendah      (Dipilih)        Biaya Mahal |
+-------------------------------------------------------------------------+
```

---

### 3.1 Hardware Sensor Tambahan (Tongkat Ultrasonik / LiDAR Add-on)
* **Apa itu:** Membuat alat fisik baru berupa tongkat cerdas dengan modul Arduino/ESP32, sensor ultrasonik HC-SR04, atau modul LiDAR eksternal.
* **Alasan Ditolak:**
  1. **Hambatan Aksesibilitas & Biaya:** Memaksa tunanetra membeli, membawa, dan mengisi daya perangkat keras tambahan yang mahal dan rentan rusak.
  2. **Resolusi Spasial Sangat Rendah:** Sensor ultrasonik hanya membaca pantulan gelombang berbentuk kerucut 1 dimensi (hanya tahu "ada benda", tapi tidak bisa membedakan antara rumput, genangan air, tangga, atau trotoar).
  3. **Smartphone Ubiquity:** Smartphone modern sudah memiliki kamera beresolusi tinggi, komputasi mumpuni, GPS, TTS, dan koneksi internet dalam satu genggaman.

---

### 3.2 Pure VLM / LLM Video Streaming (Gemini Live / GPT-4o)
* **Apa itu:** Mengalirkan video kamera secara non-stop ke Multimodal Large Language Model (VLM) di cloud dan membiarkan AI berbicara menarasikan jalan secara terus-menerus.
* **Alasan Ditolak:**
  1. **Latensi Tidak Aman (1.5 - 4 Detik):** Model LLM berbasis autoregressive generation membutuhkan waktu untuk merespons token per token. Keterlambatan 2 detik saat berjalan kaki di pinggir jalan raya sangat membahayakan nyawa.
  2. **Biaya Operasional (Token Cost) Ekstrem:** Streaming video 30 FPS ke cloud LLM komersial memakan ribuan token per menit, membuat biaya per pengguna menjadi sangat mahal dan tidak berkelanjutan.
  3. **Ketergantungan Kuota & Sinyal 5G Non-Stop:** Begitu pengguna masuk ke area sinyal lemah (edge/3G), model langsung terputus total (*freezing*).
  4. **Karakter Halusinasi:** LLM generatif memiliki resiko halusinasi (menyatakan jalan aman padahal ada lubang transparan/bayangan).

---

### 3.3 Full On-Device Heavy Semantic Segmentation di HP
* **Apa itu:** Menjalankan model segmentasi semantik berat (seperti SegFormer, DeepLabV3+, atau Mask2Former) sepenuhnya di CPU/NPU ponsel.
* **Alasan Ditolak:**
  1. **Thermal Throttling & Baterai Boros:** Segmentasi piksel beresolusi tinggi membebani GPU/NPU ponsel secara konstan. Dalam 10 menit, HP pengguna akan terasa sangat panas dan frame rate anjlok.
  2. **Kompatibilitas HP Pengguna:** Tidak semua pengguna memiliki HP flagship dengan NPU kuat. Banyak pengguna tunanetra menggunakan ponsel Android mid-to-low end.
  3. **Solusi yang Lebih Baik:** Menggunakan model hybrid berbobot sangat ramping di edge atau mendelegasikan segmentasi matriks berat ke local/cloud server dengan *Frame Pacer*.

---

### 3.4 Standalone GPS Turn-by-Turn (Google Maps / OSM)
* **Apa itu:** Hanya mengandalkan navigasi suara Google Maps/GPS tanpa sensor visual kamera.
* **Alasan Ditolak:**
  1. **Akurasi GPS Ponsel Terlalu Kasar:** Akurasi GPS komersial di smartphone berkisar antara 5 hingga 15 meter (bahkan lebih buruk di antara gedung tinggi).
  2. **Buta Terhadap Hambatan Mikro:** GPS tahu jalan raya, tetapi **tidak tahu** apakah ada got terbuka di depan kaki, ada motor parkir di atas trotoar, atau ada tangga darurat.

---

### 3.5 Pure Classical Computer Vision (Edge/Color Detection Saja)
* **Apa itu:** Menggunakan algoritma OpenCV klasik (Canny Edge Detection, Sobel Filter, Thresholding warna HSV) tanpa Machine Learning.
* **Alasan Ditolak:**
  1. **Sangat Rentan terhadap Bayangan (*Shadow Fragility*):** Bayangan pohon atau tiang di siang hari akan dianggap sebagai rintangan/lubang fisik oleh Canny Edge.
  2. **Tidak Memahami Semantik Objek:** Filter klasik tidak bisa membedakan apakah garis horizontal di depan adalah *undakan tangga*, *zebra cross*, atau sekadar *sambungan semen trotoar*.
  3. **Peran yang Benar:** Teknik heuristik klasik hanya ideal dipakai sebagai *safety fallback* saat koneksi server terputus, bukan sebagai mesin utama.

---

## 4. Matriks Perbandingan & Evaluasi Trade-Off

| Parameter | Solusi Hybrid GUIDIO (Rekomendasi) | Hardware Eksternal (Tongkat Pintar) | Pure VLM / LLM Video Streaming | Full Heavy On-Device Seg | Standalone GPS Maps |
|---|---|---|---|---|---|
| **Latensi Respon** | ⚡ **< 400 ms** *(Sangat Cepat)* | ⚡ **< 100 ms** | 🐢 **1.5 – 4.0 s** *(Berbahaya)* | ⏱️ **400 – 900 ms** | 🐢 **> 2.0 s** |
| **Akurasi Deteksi Lubang & Tangga** | 🎯 **Tinggi** *(Visual + Boundary)* | ⚠️ **Sangat Rendah** *(Hanya 1D)* | 🎯 **Tinggi** *(Tapi lambat)* | 🎯 **Tinggi** | ❌ **Nol (Tidak Terdeteksi)** |
| **Biaya Hardware Pengguna** | 🟢 **Rp 0** *(Pakai HP Sendiri)* | 🔴 **Mahal** *(Beli kit alat)* | 🟢 **Rp 0** | 🟡 **Butuh HP Flagship** | 🟢 **Rp 0** |
| **Biaya Operasional (API/Server)** | 🟢 **Rendah** *(Self-hosted/Light)* | 🟢 **Nol** | 🔴 **Sangat Mahal** *(Token Video)* | 🟢 **Nol** | 🟢 **Rendah/Gratis** |
| **Konsumsi Baterai HP** | 🟢 **Hemat** *(Throttled 2 FPS)* | 🟢 **Hemat** | 🔴 **Tinggi** *(Video Uplink)* | 🔴 **Sangat Boros & Panas** | 🟢 **Sangat Hemat** |
| **Ketahanan terhadap Bayangan** | 🟢 **Tinggi** *(Deep Learning)* | 🟢 **Kebal** | 🟢 **Tinggi** | 🟢 **Tinggi** | ⚪ **N/A** |
| **Kesiapan Digunakan Nyata** | 🏆 **Siap Produksi** | ⚠️ **Perlu Produksi Fisik** | ⚠️ **Eksperimental** | ⚠️ **Sering Crash di HP Low** | ⚠️ **Hanya untuk Makro** |

---

## 5. Master Prompt Template untuk AI Eksternal

Gunakan prompt di bawah ini untuk berdiskusi atau memvalidasi arsitektur ini dengan AI lain:

````markdown
Saya sedang merancang fitur "Navigasi Mikro & Panduan Jalur Berjalan Real-Time untuk Tunanetra" menggunakan kamera smartphone berbasis Computer Vision dan AI.

Tolong berikan analisis teknis mendalam mengenai perancangan arsitektur terbaik, rekomendasi algoritma/model, serta evaluasi trade-off dari pendekatan-pendekatan yang ada.

---

### 1. Kebutuhan & Skenario Fitur:
1. **Segmentasi Jalur Layak Injak (Walkable Path):**
   - Membagi pandangan depan kamera menjadi 3 zona (Kiri, Tengah, Kanan) untuk mengarahkan pengguna (*"Lurus aman"*, *"Ada halangan di tengah, geser ke kiri"*).
   - Membedakan permukaan trotoar/lantai datar dari rumput, selokan, dan jalan raya kendaraan.
2. **Deteksi Bahaya Kritis Permukaan & Hambatan:**
   - Mendeteksi rintangan setinggi tubuh (orang, kendaraan, tiang, bangku).
   - Mendeteksi bahaya permukaan tanah: **undakan tangga (naik/turun), lubang jalan (potholes), dan tepi jurang/drop-offs**.
3. **Konstrain Teknis Nyata:**
   - **Latensi:** Wajib sub-second (<500ms) karena pengguna sedang melangkah aktif.
   - **Kamera:** Single RGB camera smartphone dengan guncangan saat berjalan kaki.
   - **Audio Safety:** Instruksi suara tidak boleh membombardir telinga pengguna (*anti-audio flooding*) agar suara lingkungan sekitar tetap terdengar.
   - **Aksesibilitas:** Berjalan di smartphone standar tanpa mewajibkan perangkat keras eksternal tambahan.

---

### 2. Yang Ingin Saya Analisis:
1. **Rekomendasi Arsitektur Ideal (Edge vs Cloud Hybrid):**
   - Bagaimana rancangan pipeline dari kamera HP hingga menghasilkan suara panduan ke telinga pengguna?
   - Model Computer Vision apa yang paling optimal untuk segmentasi jalur 3-zona dan estimasi jarak rintangan monokuler?
2. **Sensor Fusion:**
   - Bagaimana memanfaatkan sensor IMU/Gyroscope ponsel untuk mengoreksi sudut kemiringan kamera ke arah lantai?
3. **Analisis Mengapa Pendekatan Alternatif Ditolak:**
   - Jelaskan kelemahan kritis dari:
     a. Hardware sensor kit tambahan (Tongkat ultrasonik / LiDAR eksternal).
     b. Pure VLM/LLM real-time video streaming (seperti GPT-4o / Gemini Live).
     c. Full heavy on-device semantic segmentation di prosesor HP.
     d. Navigasi GPS Turn-by-Turn biasa.
     e. Pure Classical Computer Vision (Canny/Color thresholding saja).
4. **Matriks Perbandingan:**
   - Buatkan tabel komparasi parameter Latensi, Akurasi Bahaya, Biaya Operasional, Konsumsi Daya Baterai, dan Aksesibilitas Pengguna.
````
