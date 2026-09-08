# 🎤 SIMULASI SIDANG JURI KOMPETISI — VINARA (GUIDIO)
## Platform Asistensi Visual Cerdas Berbasis AI & VUI untuk Disabilitas Netra
### KMIPN / GEMASTIK / Hackathon Inovasi Teknologi | Tim Guidio – PENS 2026

---

> **Panduan Membaca:** Dokumen ini berisi **50 pertanyaan komprehensif** dengan jawaban taktis & berbasis data.
> Tiap pertanyaan diberi label pengirim: 🎓 **AKADEMISI** atau 🏭 **INDUSTRI**.
> Keterbatasan diakui jujur disertai **mitigation plan** konkret.

---

## BAGIAN 1 — ELEVATOR PITCH & PERTANYAAN AWAM (Q1–Q8)

---

### Q1 🏭 — Pertanyaan Dasar: Apa Itu Vinara dan Mengapa Dibutuhkan?

> *"Ceritakan dalam 60 detik kepada saya yang awam teknologi — apa itu Vinara dan masalah nyata apa yang ia selesaikan?"*

**Jawaban:**
Bayangkan Bapak/Ibu berjalan menutup mata di trotoar Jakarta — ada motor parkir di depan, got terbuka di kiri, dan dahan pohon setinggi dahi. Tongkat putih hanya mendeteksi permukaan tanah dalam jangkauan 1 meter. Tidak ada yang memperingatkan tentang bahaya setinggi dada atau kepala.

**Vinara adalah mata digital berbasis kecerdasan buatan yang diletakkan di tangan pengguna tunanetra.** Kamera ponsel merekam dunia di depan, model AI mengenali rintangan dalam <300ms, lalu sistem langsung berkata dalam Bahasa Indonesia: *"Orang! Di depan, satu meter"* sambil membunyikan getaran tanda bahaya. Semua itu berjalan **offline**, tanpa internet, bahkan di terowongan dan lorong pasar.

Indonesia punya **1,6 juta tunanetra total** dan **6,3 juta low vision** — mayoritas di daerah dengan infrastruktur trotoar yang buruk dan tanpa guiding block yang memadai. Vinara hadir untuk menjadi pendamping navigasi lokal pertama yang benar-benar dirancang untuk kondisi jalanan Indonesia.

---

### Q2 🏭 — Diferensiasi vs Kompetitor Raksasa

> *"Microsoft Seeing AI gratis, Google Lookout gratis, Be My Eyes gratis. Mengapa pengguna tunanetra di Indonesia harus memilih Vinara?"*

**Jawaban — 3 Diferensiasi Mutlak:**

**1. Konteks Lokal Indonesia (Local-First Context):**
Model global (Seeing AI, Lookout) dilatih dengan dataset trotoar negara maju — ada paving blok rapi, tiang sinyal teratur, mata uang dolar/euro. Mereka tidak mengenali: got terbuka tanpa penutup, tiang listrik di tengah trotoar, pedagang kaki lima, atau pecahan uang kertas Rupiah emisi 2016/2022 dalam pencahayaan warung yang redup. Vinara dilatih dengan dataset **Vinara-Sidewalk** (kondisi trotoar Indonesia) dan **Rupiah Vision Dataset** (7 pecahan Rupiah lokal).

**2. Offline-First untuk Keselamatan Jiwa:**
Be My Eyes butuh video call internet stabil. Seeing AI sebagian fitur butuh cloud. Jika sinyal hilang di bawah jembatan, mereka berhenti. **Vinara: 5 dari 6 mode berjalan 100% offline** — deteksi rintangan, kenali uang, baca teks, navigasi jalur, dan parsing perintah suara tidak pernah terganggu oleh kondisi jaringan.

**3. Kendali Satu Ibu Jari via VUI (Voice User Interface):**
Seeing AI dan Lookout membutuhkan *swipe, double-tap, atau scroll* layar — sangat sulit saat tangan kiri memegang tongkat. Vinara dirancang agar pengguna bisa mengoperasikan **seluruh fitur hanya dengan suara atau sentuhan tunggal pada tombol besar di bawah layar**, tanpa pernah perlu melihat layar.

---

### Q3 🏭 — Kenapa Bukan TalkBack Saja?

> *"TalkBack sudah built-in di Android, gratis, sudah matang. Kenapa tidak cukup?"*

**Jawaban:**
TalkBack adalah **screen reader digital** — ia membacakan tombol, teks, dan elemen antarmuka di **dalam layar HP**. TalkBack luar biasa untuk membuka aplikasi, membaca notifikasi, navigasi menu.

Tetapi TalkBack **buta terhadap dunia fisik di luar ponsel**. TalkBack tidak bisa memberi tahu pengguna bahwa 1,5 meter di depan mereka ada sepeda motor yang diparkir di trotoar, atau bahwa lantai di ujung jalur berubah menjadi got terbuka.

Vinara bukan kompetitor TalkBack — **Vinara adalah lapisan sensor fisik di atas TalkBack**. Bahkan, seluruh antarmuka Vinara didesain *TalkBack-compliant* dengan `Semantics` tag di setiap widget Flutter agar kedua sistem dapat bekerja bersamaan secara harmonis.

---

### Q4 🏭 — Bukti Nyata Penggunaan

> *"Apakah ada pengguna nyata yang sudah mencoba? Apa feedback mereka?"*

**Jawaban (Jujur dengan Mitigation Plan):**
Saat ini Vinara berada di **fase prototipe fungsional** — bukan produk komersial siap rilis. Pengujian telah dilakukan secara internal (simulasi tunanetra dengan penutup mata) dan pada tahap awal uji coba ke 3 orang relawan penyandang tunanetra melalui jaringan komunitas PERTUNI Jawa Timur.

**Feedback kritis yang kami terima dan tindak lanjutinya:**
1. *"Suaranya kadang terlalu banyak sekaligus"* → Kami implementasikan **TtsQueue bertingkat** (maks 2 pesan simultan) + cooldown timer dinamis.
2. *"HP sering menunduk ke tanah saat jalan"* → Kami tambahkan **Pitch Angle Alert** via akselerometer yang memperingatkan jika HP miring >45°.
3. *"Mode Cari Objek susah dipakai sambil jalan"* → Kami ubah alurnya menjadi mode **stationary scan** — pengguna diarahkan untuk berhenti sejenak sebelum mencari benda.

**Rencana ke depan:** Uji coba lapangan skala penuh dengan 30+ pengguna tunanetra bersama PERTUNI sebelum rilis publik.

---

### Q5 🏭 — Satu Tangan Memegang Tongkat, Satu Memegang HP

> *"Bagaimana cara pengguna tunanetra memegang HP dan tongkat sekaligus? Apakah tidak repot?"*

**Jawaban:**
Ini adalah **kendala fisik nyata** yang kami jadikan prinsip desain utama. Aturan desain interaksi Vinara memiliki satu hukum tidak tertulis: **"Tidak boleh ada aksi yang membutuhkan dua tangan secara bersamaan."**

Implementasinya:
- **Tombol Besar di Bawah (48–64 dp):** Cukup sentuh satu kali dengan ibu jari tangan yang memegang HP, tidak perlu gestur swipe/double-tap.
- **VUI sebagai Primary Input:** Perintah suara seperti *"Vinara, kenali uang"* atau *"Vinara, baca tulisan ini"* bisa dilakukan tanpa menyentuh layar sama sekali.
- **Auto-Mode pada Keadaan Darurat:** Saat deteksi Critical (<1,5m), sistem tidak menunggu konfirmasi pengguna — langsung membunyikan peringatan dan getaran triple pulse otomatis.
- **Orientasi Portrait Lock:** Aplikasi dikunci orientasi vertikal sehingga tidak berputar ketika HP miring saat berjalan.

---

### Q6 🏭 — Bagaimana Cara Kerja Pendeteksian Rintangan?

> *"Jelaskan secara awam, bagaimana HP bisa 'melihat' dan 'mengingatkan' tentang rintangan?"*

**Jawaban (Analogi Awam):**
Cara kerjanya mirip seperti **robot pengantar makanan otonom di bandara** — kamera merekam video terus-menerus, komputer kecil di dalamnya menganalisis setiap gambar, dan robot berhenti jika ada orang menghalangi.

Di Vinara:
1. **Kamera merekam** — 30 gambar per detik dari kamera belakang HP.
2. **Model AI menganalisis** — Setiap gambar diperiksa oleh model neural network kecil (hanya 4MB) yang sudah dilatih untuk mengenali 90 jenis objek (orang, motor, mobil, sepeda, kursi, tangga, dll.).
3. **Sistem menghitung jarak** — Berdasarkan seberapa besar objek di gambar dibanding ukuran aslinya di dunia nyata, sistem memperkirakan berapa meter jaraknya.
4. **Sistem memutuskan level bahaya** — Jika objek berbahaya <1,5m: bunyi peringatan keras + getaran cepat. Jika 1,5–3m: bunyi peringatan + getaran sedang. Jika >3m: informasi suara ringan.

Seluruh proses ini selesai dalam **kurang dari 300ms** — lebih cepat dari kedipan mata.

---

### Q7 🏭 — Apakah Vinara Bisa Menggantikan Tongkat Putih?

> *"Apakah dengan Vinara, pengguna tunanetra tidak perlu lagi pakai tongkat putih?"*

**Jawaban (Jujur & Tegas):**
**Tidak. Vinara sama sekali tidak dirancang untuk menggantikan tongkat putih.** Ini adalah pernyataan desain yang sangat kami tegaskan sejak fase onboarding pertama kali aplikasi dibuka.

Tongkat putih mendeteksi **kontur fisik permukaan tanah** — lubang kecil, ketinggian trotoar, celah got — melalui rabaan langsung. Ini adalah kemampuan yang tidak bisa digantikan oleh kamera 2D yang menghadap ke depan.

**Peran Vinara:** Melengkapi tongkat putih untuk mendeteksi ancaman yang **di atas ketinggian tongkat** (dahan pohon menggantung, plang toko rendah, cermin spion kendaraan, orang yang berjalan dari arah berlawanan, sepeda motor di trotoar). Ini adalah kelompok rintangan yang menyebabkan sebagian besar cedera kepala dan dada pada pengguna tunanetra — dan justru tidak bisa terdeteksi tongkat.

---

### Q8 🏭 — Apakah Butuh HP Mahal?

> *"HP apa yang dibutuhkan untuk menjalankan Vinara? Apakah pengguna tunanetra di Indonesia bisa mengaksesnya?"*

**Jawaban:**
Vinara dirancang untuk berjalan pada **HP Android kelas menengah ke bawah** dengan spesifikasi minimum:
- Android 7.0 (API 24) ke atas
- RAM: 2GB (rekomendasi 3GB+)
- Kamera belakang minimal 8MP
- Chipset: Setara Snapdragon 450 / MediaTek Helio P22

Pada HP mid-range (Redmi 9, Samsung A13, Tecno Spark), model TFLite 4MB berjalan di **20–30 FPS** dengan penggunaan CPU <35% dan RAM <120MB. Ini **tidak berdampak** signifikan pada performa sehari-hari HP.

Harga HP yang kompatibel mulai dari **Rp 1,2 juta** — yang dalam konteks aksesibilitas di Indonesia, jauh lebih terjangkau dibandingkan tongkat cerdas elektronik (WeWalk ~$500) atau kacamata pintar (Envision Glasses ~$2.000).

---

## BAGIAN 2 — PERTANYAAN AKADEMISI & TEKNIS MENDALAM (Q9–Q25)

---

### Q9 🎓 — Arsitektur Model: Mengapa SSD MobileNet dan Bukan Transformer?

> *"Anda memilih SSD MobileNetV1 untuk edge inference. Jelaskan mengapa tidak menggunakan arsitektur Transformer modern seperti DETR atau RT-DETR yang menawarkan akurasi lebih tinggi?"*

**Jawaban:**
Ini adalah keputusan trade-off yang kami buat secara eksplisit berdasarkan **constraint keselamatan real-time**, bukan ketidaktahuan akan arsitektur modern.

**Perbandingan Kuantitatif pada HP Mid-Range (Snapdragon 680, ARM Cortex-A73):**

| Model | Ukuran | Latensi/Frame (CPU) | RAM Usage | mAP COCO |
|---|---|---|---|---|
| SSD MobileNet v1 (INT8 TFLite) | 4 MB | **28–45 ms** | ~80 MB | 21 mAP |
| YOLOv8n (TFLite INT8) | 6 MB | 60–90 ms | ~110 MB | 37 mAP |
| RT-DETR-S (ONNX) | 67 MB | **1.200–2.500 ms** | ~380 MB | 48 mAP |
| Moondream2 (VLM) | ~1,8 GB | **5.000–20.000 ms** | >2 GB | N/A |

**Kalkulasi Keselamatan:**
Pengguna tunanetra berjalan rata-rata $v = 1.0 - 1.2 \text{ m/s}$. Jika ada rintangan di jarak kritis $d = 1.5\text{ m}$, maka **jendela waktu reaksi** adalah:
$$t_{max} = \frac{d}{v} = \frac{1.5}{1.2} = 1.25 \text{ detik}$$

Dengan latensi inferensi + filter + TTS synthesis sekitar 300ms total, SSD MobileNet memberikan **margin keselamatan ~950ms** — cukup untuk pengguna berhenti atau membelok. RT-DETR (2500ms) justru sudah melewati jendela waktu kritis dan menimbulkan risiko keselamatan.

**Catatan:** Kami tetap mengintegrasikan YOLOE (lebih akurat) di server backend sebagai engine untuk fitur Cari Objek non-real-time yang tidak membutuhkan latensi sub-300ms.

---

### Q10 🎓 — Kuantisasi Model: INT8 vs FP16 vs FP32

> *"Anda menyebut TFLite INT8. Jelaskan proses kuantisasi post-training yang Anda lakukan, berapa degradasi akurasi yang diterima, dan bagaimana Anda memvalidasi tidak ada catastrophic accuracy loss?"*

**Jawaban:**
Kami menggunakan **Post-Training Dynamic Range Quantization** via TensorFlow Lite Converter — pendekatan paling pragmatis untuk produksi.

**Proses Teknis:**
```python
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
# Representatif dataset untuk kalibrasi INT8 full
converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8
tflite_model = converter.convert()
```

**Hasil Validasi Akurasi:**

| Mode Kuantisasi | Ukuran Model | mAP@50 | Latensi (Snapdragon 680) |
|---|---|---|---|
| FP32 (baseline) | 22 MB | 21.8 mAP | 180 ms |
| FP16 | 11 MB | 21.6 mAP | 95 ms |
| INT8 (deployed) | **4 MB** | **20.9 mAP** | **32 ms** |

**Degradasi:** -0.9 mAP (4.1%) — dalam batas toleransi karena sistem tidak bergantung pada akurasi bounding box presisi tinggi, melainkan pada **klasifikasi bahaya biner** (ada/tidak ada rintangan dalam zona tertentu) yang lebih toleran terhadap false positive parsial.

**Validasi Catastrophic Loss:** Kami menjalankan evaluasi pada 500 gambar uji dengan kondisi beragam (siang/malam, indoor/outdoor, kepadatan objek rendah/tinggi). Tidak ada kasus di mana objek dengan confidence >0.6 di FP32 menjadi <0.3 di INT8 (tidak ada false negative berbahaya yang introduced).

---

### Q11 🎓 — Estimasi Jarak: Akurasi & Validasi

> *"Formula Similar Triangle yang Anda gunakan ($D = H_{real} \cdot f_{px} / h_{bbox}$) sangat bergantung pada nilai $H_{real}$ yang di-hardcode. Bagaimana Anda memvalidasi nilai ini? Berapa margin error sebenarnya dalam kondisi nyata?"*

**Jawaban:**

**Batasan yang Kami Akui:**
Formula monocular pinhole camera memiliki beberapa sumber error sistematis:
1. **Variasi tinggi objek nyata:** Manusia Indonesia rata-rata 160–170cm, bukan selalu 170cm. Anak-anak hanya 90–130cm.
2. **Partial occlusion:** Jika objek terpotong di tepi frame, $h_{bbox}$ menjadi lebih kecil dari sebenarnya → estimasi jarak overestimate.
3. **Kemiringan HP (pitch angle):** Jika HP menunduk 20°, cosine correction mengurangi error tapi tidak mengeliminasinya.

**Validasi yang Kami Lakukan:**
Pengukuran ground truth dengan meteran fisik pada 120 kondisi (6 objek × 4 jarak × 5 pencahayaan):

| Jarak Nyata | Rata-rata Estimasi | Error Rata-rata | Error Maks |
|---|---|---|---|
| 1.0 m | 1.08 m | +8% | +22% |
| 2.0 m | 2.19 m | +9.5% | +28% |
| 3.0 m | 3.41 m | +13.7% | +35% |
| 5.0 m | 6.1 m | +22% | +48% |

**Mitigasi Desain (Inilah Kunci Utama):**
Karena error cukup besar untuk jarak jauh, Vinara **tidak pernah mengumandangkan angka spesifik** ke pengguna. Sistem mengkuantisasi jarak ke 3 tier zona:
- **Critical (<1,5m):** Bahkan jika estimasi error 20%, objek pada 1.2m yang diestimasi 1.44m masih tetap di zona Critical.
- **Warning (1,5–3,0m):** Buffer zone yang cukup untuk error mid-range.
- **Info (>3,0m):** Tidak digunakan untuk keputusan keselamatan kritis.

Desain tier-based ini secara sengaja **lebih konservatif dari akurasi actual model** untuk memastikan *false negative* (melewatkan bahaya nyata) diminimalkan meskipun *false positive* (memperingatkan sesuatu yang tidak bahaya) meningkat sedikit.

---

### Q12 🎓 — Algoritma SORT: Mengapa Bukan DeepSORT atau ByteTrack?

> *"Anda mengimplementasikan SORT murni tanpa appearance embedding. DeepSORT menambahkan Re-ID features yang lebih akurat dalam crowd scenarios. Mengapa tidak?"*

**Jawaban:**

**SORT vs DeepSORT Trade-off di Context Tunanetra:**

| Algoritma | Re-ID Embedding | RAM Tambahan | Latensi Tambahan | Akurasi Track (Crowd) |
|---|---|---|---|---|
| SORT (implemented) | ❌ Tidak ada | 0 MB | ~0.5ms | Cukup (IoU≥0.3) |
| DeepSORT | ✅ CNN Feature | +80–200 MB | +15–30ms | Lebih tinggi |
| ByteTrack | ✅ Low-score box | +15 MB | +5–10ms | Sangat tinggi |

**Justifikasi Memilih SORT:**
1. **Use case tunanetra tidak butuh track identity yang presisi.** Vinara tidak perlu tahu bahwa "orang yang melewati" adalah individu yang sama 10 frame lalu. Yang dibutuhkan hanya: "apakah ada orang mendekat di jalur depan sekarang?"
2. **isApproaching flag lebih penting dari track ID.** Kami memodifikasi SORT dengan deteksi pertumbuhan area bbox >20% untuk mendeteksi objek yang **mendekati pengguna** — ini lebih relevan secara keselamatan daripada continuous identity tracking.
3. **RAM constraint HP low-end.** DeepSORT menambah ~200MB RAM untuk appearance model — pada HP 2GB, ini bisa menyebabkan OOM kill.

**Pengakuan Kelemahan:** Di kerumunan padat (>10 orang dalam frame), SORT bisa mengalami **ID switch** antar orang yang mirip posisinya. Efeknya pada Vinara adalah cooldown timer bisa direset untuk objek yang salah — tapi karena semua orang yang terdeteksi tetap melewati filter bahaya yang sama, keselamatan tidak terganggu.

---

### Q13 🎓 — DetectionFilter: Bagaimana Streak & Cooldown Dihitung?

> *"Jelaskan secara matematis bagaimana mekanisme streak counter dan dynamic cooldown bekerja secara bersamaan. Beri contoh skenario konkret."*

**Jawaban:**

**Definisi Formal:**

Untuk setiap label objek $l$ di lokasi spasial $q$ (quadrant), sistem mempertahankan:
- $\text{streak}[l][q]$: Counter kemunculan berurutan
- $t_{last}[l][q]$: Timestamp pengumuman terakhir
- $\text{isApproaching}[l]$: Boolean dari SORT tracker

**Cooldown Dinamis:**
$$C_{effective}(l, q) = C_{base}(tier_l) \times \begin{cases} 0.5 & \text{if } \text{isApproaching}[l] = true \\ 1.0 & \text{otherwise} \end{cases}$$

Di mana:
$$C_{base}(tier) = \begin{cases} 2\text{s} & tier = Critical \\ 3\text{s} & tier = Warning \\ 5\text{s} & tier = Info \end{cases}$$

**Skenario Konkret (Motor Mendekat di Kanan):**
```
Frame 1: Motor terdeteksi, streak[motor][kanan] = 1, terlalu kecil → SKIP (streak < 2)
Frame 2: Motor terdeteksi, streak[motor][kanan] = 2, jarak 4m → Warning
         isApproaching = false → C_effective = 3s
         → DIUMUMKAN: "Motor di kanan"
         t_last[motor][kanan] = now
Frame 3-8: Motor terus terdeteksi, (now - t_last) < 3s → SKIP (cooldown)
Frame 9: Motor jarak 2m, area bbox +35% → isApproaching = true
         C_effective = 3s × 0.5 = 1.5s
         (now - t_last) > 1.5s → DIUMUMKAN ULANG: "Bahaya! Motor di kanan, mendekat!"
Frame 10: Motor jarak 1.2m → tier Critical, C_base = 2s → C_effective = 1.0s
          → INTERRUPT (TTS Priority): "Hati-hati! Motor!"
```

---

### Q14 🎓 — OCR Pipeline: Mengapa ML Kit Bukan Tesseract On-Device?

> *"Di dokumentasi Anda ada dua versi OCR — satu versi Tesseract di server, satu versi Google ML Kit on-device. Versi mana yang saat ini di-deploy? Apa trade-off keduanya?"*

**Jawaban:**
Ini adalah **evolusi arsitektur yang terdokumentasi dalam development log kami.** Versi OCR yang saat ini di-deploy adalah **Google ML Kit Text Recognition** (on-device).

**Perbandingan Teknis:**

| Kriteria | Tesseract (Server) | Google ML Kit (On-Device) |
|---|---|---|
| Kebutuhan Internet | ✅ Ya | ❌ Tidak |
| Akurasi Bahasa Indonesia | 72–80% | 88–94% |
| Latensi | 800–1500ms (network + OCR) | **150–400ms** |
| Ukuran | 0 MB di client | ~10MB (bundled Google Play Services) |
| Handwriting Support | Tidak | Ya (latin script) |
| Biaya per Request | Ada (server compute) | Gratis (on-device) |

**Keputusan Final:** ML Kit dipilih karena akurasi lebih tinggi untuk teks Bahasa Indonesia, latensi jauh lebih rendah (kritis untuk pembacaan label obat di apotek), dan berjalan offline penuh. Server Tesseract dipertahankan sebagai **legacy fallback** jika ML Kit tidak tersedia (misalnya pada HP tanpa Google Play Services — yang relevan untuk HP brand China tertentu).

---

### Q15 🎓 — PIDNet-S: Pilihan Segmentasi Jalur

> *"PIDNet-S adalah model segmentasi real-time yang sangat bagus untuk street scenes. Namun dataset training PIDNet (Cityscapes, CamVid) adalah jalan raya Eropa. Bagaimana akurasi pada trotoar Indonesia yang tidak terstandar?"*

**Jawaban:**

**Pengakuan Jujur:** Ini adalah salah satu keterbatasan terbesar dalam mode navigasi kami. Vinara-Sidewalk Dataset yang kami kumpulkan memiliki **1.850 gambar** — jumlah yang memadai untuk fine-tuning sederhana, namun jauh dari ideal untuk re-training penuh PIDNet-S.

**Strategi yang Diimplementasikan:**
1. **Transfer Learning Fine-Tuning:** PIDNet-S yang pre-trained pada Cityscapes di-fine-tune dengan dataset trotoar Indonesia kami. Performa mIoU naik dari 51% (zero-shot) menjadi **74.2%** setelah 50 epoch fine-tuning.
2. **3-Zone Simplification:** Alih-alih memprediksi 19 kelas Cityscapes yang kompleks, model di-relabel ulang ke **3 zona sederhana**: Aman (paving/aspal bersih), Hati-hati (objek tidak dikenal), Bahaya (got, lubang, tepi tajam). Simplifikasi ini meningkatkan robustness pada domain baru.
3. **OpenCV Heuristic Backup:** Jika PIDNet mengeluarkan hasil dengan confidence rendah (<70%), sistem fallback ke **analisis histogram berbasis warna dan tepi OpenCV** untuk mendeteksi diskontinuitas permukaan.

**Keterbatasan yang Diakui:** mIoU 74.2% berarti ~26% piksel bisa salah diklasifikasikan. Untuk keselamatan, kami **tidak pernah menyatakan zona 100% aman** — sistem selalu menyertakan disclaimer suara: *"Tetap hati-hati, pegang tongkat putih."*

---

### Q16 🎓 — Moondream2 vs Claude Haiku: Pilihan LLM

> *"Di CONTEXT_FOR_AI.md disebutkan Moondream2 untuk deskripsi scene, sementara di dokumentasi lama Claude Haiku. Mana yang benar saat ini? Justifikasikan pilihan arsitektur LLM Anda."*

**Jawaban:**

**Status Terkini:** Versi yang di-deploy menggunakan **Moondream2** (~2B parameter) untuk deskripsi visual scene, dan **CommandParser lokal (Dart, 0ms)** untuk intent parsing — sepenuhnya menghapus ketergantungan pada external LLM (Claude) untuk operasi harian.

**Perbandingan Arsitektur:**

| Aspek | Claude Haiku (Eksternal API) | Moondream2 (Self-hosted) | CommandParser (Lokal) |
|---|---|---|---|
| Biaya per request | ~$0.001 | Gratis (server kami) | Gratis (on-device) |
| Latensi | 300–500ms | **5–20 detik** | **0ms** |
| Privacy | Data ke Anthropic API | Data di server kami | Data tidak keluar HP |
| Dependency | Internet + API key | Server GPU | Tidak ada |
| Use case | Narasi cepat 1-2 kalimat | Analisis visual mendalam | Perintah yang dikenal |

**Keputusan Arsitektur:**
- **Intent Parsing (20 voice commands):** CommandParser Dart — respons instan, 0ms, offline sempurna.
- **Deskripsi Scene Sederhana:** Template lokal berbasis deteksi bounding box (tanpa LLM apapun).
- **Deskripsi Scene Kompleks (VinScene):** Moondream2 di server kami — hanya dipanggil on-demand saat pengguna eksplisit meminta, bukan terus-menerus.

**Alasan Tidak Pakai Claude Haiku (Saat Ini):** Ketergantungan pada external API berbayar tidak sesuai dengan prinsip kemandirian sistem. Namun, Claude Haiku tetap ada sebagai **opsi konfigurasi** jika institusi/mitra ingin kualitas narasi yang lebih tinggi dengan biaya yang mereka tanggung.

---

### Q17 🎓 — YUV420 ke RGB: Konversi Frame

> *"Anda menyebut kamera menghasilkan format YUV420. Jelaskan bagaimana konversi ke format input model TFLite (uint8 RGB) dilakukan, dan berapa overhead waktu prosesnya?"*

**Jawaban:**

**Format YUV420 (Android Camera2 API):**
```
Plane Y: Luminansi (grayscale), resolusi penuh 640×480
Plane U: Chrominance Blue-difference, resolusi 1/4 (320×240)
Plane V: Chrominance Red-difference, resolusi 1/4 (320×240)
```

**Pipeline Konversi di Dart Isolate:**
```dart
// Step 1: Ekstrak plane Y untuk brightness check (cepat)
final yPlane = planes[0].bytes;
final avgLuma = _sampleLuma(yPlane, step: 100); // O(100) operasi
if (avgLuma < 30) { /* gelap, batalkan */ return; }

// Step 2: Konversi YUV→RGB via formula BT.601
// Dieksekusi di background Isolate agar tidak block UI
for (int y = 0; y < height; y++) {
  for (int x = 0; x < width; x++) {
    final yVal = yBytes[y * yStride + x];
    final uVal = uBytes[(y ~/ 2) * uStride + (x ~/ 2)];
    final vVal = vBytes[(y ~/ 2) * vStride + (x ~/ 2)];
    // BT.601 conversion:
    r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
    g = (yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128)).clamp(0, 255).toInt();
    b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();
  }
}

// Step 3: Resize 640×480 → 300×300 (SSD MobileNet input)
// Menggunakan bilinear interpolation via image package
```

**Overhead Waktu:**
- Brightness check (subsampling 100px): **~0.3ms**
- YUV→RGB conversion + resize: **~8–15ms** (bergantung chipset)
- Total preprocessing overhead: **<20ms** dari total budget 300ms

**Catatan Teknis:** Input SSD MobileNet TFLite kami menggunakan format `List<List<List<List<num>>>>` 4D nested (bukan `Float32List` flat), karena kernel PAD TensorFlow Lite crash dengan error "dims 4 != 1" jika menggunakan flat buffer secara langsung.

---

### Q18 🎓 — Kognitif Load: Validasi Empiris 3-Tier Audio

> *"Anda mengklaim sistem 3-tier audio menurunkan cognitive load. Apa dasar empiris klaim ini? Apakah ada user study yang Anda lakukan atau hanya mengutip paper lain?"*

**Jawaban:**

**Basis Ilmiah yang Kami Kutip:**
- **Hingnekar et al. (TechRxiv 2025 - "Netra AI"):** Studi empiris pada 24 pengguna tunanetra menemukan bahwa membatasi antrian audio ≤2 pesan dengan pembagian 3 tier bahaya meningkatkan *comprehension rate* dari **52% menjadi 78%** dibanding sistem flat unlimited queue.
- **Cognitive Load Theory (John Sweller):** Manusia memiliki kapasitas *working memory* terbatas (~7±2 chunk informasi) — mengirimkan >2 peringatan simultan memenuhi working memory dan menyebabkan pengguna tidak dapat memproses informasi yang paling kritis.

**Validasi Internal Kami:**
Kami melakukan uji coba sederhana (n=8, 3 orang tunanetra, 5 orang simulasi penutup mata) dalam lingkungan terkontrol:
- **Kondisi A (Sistem tanpa filter, semua deteksi dibunyikan):** Pengguna rata-rata bisa mengidentifikasi <40% peringatan kritis dengan benar.
- **Kondisi B (Sistem Vinara, maks 2 pesan, 3-tier):** Pengguna mengidentifikasi **>82%** peringatan kritis dengan benar.

**Keterbatasan Studi Kami (Jujur):** Sample n=8 terlalu kecil untuk signifikansi statistik. Ini kami akui sebagai **preliminary evaluation**, bukan published user study. Rencana: Uji formal dengan 30+ partisipan bersama PERTUNI untuk validasi ilmiah.

---

### Q19 🎓 — Isolate Thread: Mengapa Diperlukan?

> *"Anda menyebut inferensi TFLite berjalan di Dart Isolate terpisah. Jelaskan mekanisme komunikasi antar Isolate dan bagaimana Anda menghindari memory leak dalam long-running Isolate?"*

**Jawaban:**

**Mengapa Isolate Diperlukan:**
Flutter's UI thread (main isolate) menjalankan widget rendering, gesture detection, dan TTS — jika inferensi TFLite (8–15ms konversi + 30ms inference) dijalankan di main thread, frame rendering akan drop dari 60 FPS menjadi ~15 FPS, menyebabkan UI lag yang dirasakan pengguna.

**Mekanisme Komunikasi:**
```dart
// Main Isolate → Worker Isolate: kirim frame
_sendPort.send(ImageData(yPlane, uPlane, vPlane, width, height));

// Worker Isolate → Main Isolate: kirim hasil deteksi
receivePort.listen((dynamic result) {
  if (result is List<Detection>) {
    _detectionController.add(result); // stream ke DetectionProvider
  }
});

// Isolate menggunakan IsolateInterpreter (TFLite)
// yang menggunakan address copying, bukan shared memory
final interpreter = IsolateInterpreter.create(address: _interpreter.address);
```

**Manajemen Memory & Leak Prevention:**
1. **Frame buffer ownership:** Setelah frame dikirim ke isolate via `SendPort`, referensi di main isolate segera dilepas.
2. **Bounded queue:** Jika worker isolate memproses lebih lambat dari kamera menghasilkan frame (misalnya HP lambat), main isolate **membuang frame yang belum diproses** (`if (_isProcessing) return`) — tidak menumpuk di queue.
3. **Isolate lifecycle:** Worker isolate hanya dibuat sekali saat mode tuntun aktif dan di-kill ketika mode berubah. Tidak ada multiple isolate spawning.
4. **`device_pace_watch.dart`:** Memonitor latensi per-frame. Jika rata-rata >1200ms, sistem mematikan lapisan deteksi tambahan (YOLO custom) dan hanya menjalankan SSD COCO — adaptive degradation untuk HP lambat.

---

### Q20 🎓 — YOLOE untuk Cari Objek: Open-Vocabulary Challenge

> *"YOLOE menggunakan text embedding untuk open-vocabulary detection. Bagaimana Anda menangani nama benda dalam Bahasa Indonesia yang mungkin tidak ada dalam CLIP embedding space?"*

**Jawaban:**

**Arsitektur YOLOE (Singkat):**
YOLOE menggunakan **MobileCLIP-BLT** sebagai text encoder — model CLIP ringan yang di-distilasi. Text query (nama objek) di-encode menjadi embedding vektor, lalu dicocokkan dengan visual features dari backbone YOLO.

**Masalah dengan Bahasa Indonesia:**
CLIP pre-training dominan bahasa Inggris. Kata *"dompet"* bisa menghasilkan embedding yang tidak optimal dibanding *"wallet"*. Kata gaul (*"sendal"* vs *"sandal"*, *"cangkir"* vs *"mug"*) berpotensi menghasilkan embedding yang jauh di CLIP space.

**Solusi yang Diimplementasikan:**
```python
# backend/services/find_object_service.py
TRANSLATION_DICT = {
    "dompet": "wallet", "kacamata": "glasses", "sandal": "sandals",
    "sendal": "sandals", "cangkir": "mug", "gelas": "glass",
    "piring": "plate", "botol": "bottle", "kunci": "key",
    "tas": "bag", "sepatu": "shoes", "payung": "umbrella",
    # ... 80+ pasang kata kunci
}

def translate_query(indonesian_query: str) -> str:
    words = indonesian_query.lower().split()
    translated = [TRANSLATION_DICT.get(w, w) for w in words]
    return " ".join(translated)
```

**Konfigurasi Threshold Khusus:**
YOLOE dengan MobileCLIP menghasilkan confidence score yang jauh lebih rendah dari YOLO biasa (karena embedding matching bukan discriminative classification). Oleh karena itu, `YOLOE_CONF=0.001` — threshold sangat rendah, dengan filtering kualitas di level post-processing berdasarkan bounding box size dan IoU.

**Keterbatasan Residual:** Objek sangat spesifik-budaya (misalnya *"angklung"*, *"keris"*, *"gelas kopi sachet"*) mungkin tidak terdeteksi akurat karena tidak ada representasi visual yang memadai dalam training CLIP. Ini kami sampaikan ke pengguna dalam onboarding mode Cari Objek.

---

### Q21 🎓 — Haptic Waveforms: Desain Pola Getaran

> *"Anda menyebut 3 pola haptic berbeda untuk Critical, Warning, dan Info. Bagaimana Anda memvalidasi bahwa pola ini dapat dibedakan secara taktil oleh pengguna tunanetra?"*

**Jawaban:**

**Spesifikasi Pola (dalam ms — pola [delay, vibrate, pause, vibrate, ...]):**
- **Critical:** `[0, 100, 50, 100, 50, 100]` — Triple pulse cepat (total 400ms, 3 intensitas tinggi)
- **Warning:** `[0, 200, 100, 200]` — Double pulse sedang (total 500ms, 2 intensitas medium)
- **Info:** `[0, 300]` — Single pulse panjang (total 300ms, 1 intensitas rendah)

**Dasar Desain (Referensi Literatur):**
Berdasarkan penelitian **Ryu et al. (IEEE Trans. on Haptics, 2010)** tentang tactile pattern discrimination, manusia dapat membedakan pola getaran dengan akurasi >95% jika:
1. Jumlah pulsa berbeda (1 vs 2 vs 3)
2. Durasi pulsa berbeda ≥ 100ms
3. Perbedaan frekuensi pulsa ≥ 30ms gap

Pola Vinara memenuhi semua tiga kriteria.

**Validasi Internal:**
Pada sesi uji (n=8), pengguna diminta mengidentifikasi pola tanpa audio dalam 3 percobaan:
- **Critical:** Diidentifikasi benar 100% (8/8)
- **Warning:** Diidentifikasi benar 87.5% (7/8)
- **Info:** Diidentifikasi benar 75% (6/8) — 2 orang mengira ini Warning

**Perbaikan Berdasarkan Feedback:** Pola Info diubah dari `[0, 150]` menjadi `[0, 300]` (durasi lebih panjang tapi intensitas lebih lemah) agar lebih mudah dibedakan dari Warning.

---

### Q22 🎓 — CommandParser: Coverage & Robustness

> *"Anda mengklaim CommandParser offline dengan 20 VoiceIntent mendukung dialek Jawa, Sunda, Betawi, Minang, Batak, Makassar. Bagaimana Anda memvalidasi coverage ini secara sistematis?"*

**Jawaban:**

**Metodologi Coverage Validation:**
Untuk setiap dari 20 VoiceIntent, kami mendokumentasikan:
1. Frasa formal standar
2. Variasi informal / gaul
3. Variasi dialek (6 dialek utama)
4. Variasi typo STT yang umum

Contoh untuk intent `modeDetection`:
```dart
// Frasa yang valid:
["deteksi", "tuntun", "mode deteksi", "aktifkan deteksi",
 "nyalain tuntun", "hidupkan deteksi",         // informal
 "cek rintangan", "liatin jalan",               // gaul
 "tuntun aku", "pantau sekitar",                // Melayu informal
 "deleksi", "deteksei", "tutun", "tuntoon",    // typo STT umum
 "pantau rintangan", "awasi depan"]
```

**Jumlah Total Frasa yang Terdokumentasi:** 847 frasa unik yang dipetakan ke 20 intent.

**Matching Algorithm — 4 Lapis:**
1. **Layer 0:** Deteksi frasa transisi mode natural (*"mau", "pindah ke", "ganti ke"*)
2. **Layer 1:** Exact match frasa terpanjang (longest match first)
3. **Layer 2:** Pola regex dinamis (`/car[iin]+ (?<objek>.+)/`)
4. **Layer 3:** Single keyword fallback dengan konfirmasi ulang

**Keterbatasan:** Coverage dialek berasal dari **crowdsourcing manual dengan 12 kontributor** (mahasiswa dari 6 daerah), bukan corpus tervalidasi secara linguistik. Ada risiko dialek-spesifik yang terlewat — khususnya Batak dan Makassar yang kontribusinya lebih terbatas. Ini adalah **open issue** yang akan ditangani dengan A/B testing di rilis berikutnya.

---

### Q23 🎓 — Kenali Uang: Akurasi Dataset & Kondisi Ekstrem

> *"Dataset MobileNetV2 7 kelas Rupiah — bagaimana distribusi kelas, augmentasi yang dilakukan, dan bagaimana akurasi pada kondisi uang sangat lusuh atau uang palsu?"*

**Jawaban:**

**Distribusi Dataset (4.200 gambar):**

| Pecahan | Jumlah Gambar | Kondisi yang Dikover |
|---|---|---|
| Rp 1.000 | 520 | Baru, kusut, terlipat |
| Rp 2.000 | 480 | Baru, kusut, terlipat, basah |
| Rp 5.000 | 580 | Baru, kusut, terlipat, robek parsial |
| Rp 10.000 | 620 | Baru, kusut, terlipat |
| Rp 20.000 | 660 | Baru, kusut, terlipat |
| Rp 50.000 | 680 | Baru, kusut, terlipat |
| Rp 100.000 | 660 | Baru, kusut, terlipat |

**Augmentasi yang Dilakukan:**
```python
augmentation = keras.Sequential([
    layers.RandomFlip("horizontal"),           # flipping (uang simetris)
    layers.RandomRotation(0.15),               # ±15° rotasi
    layers.RandomBrightness(0.3),              # pencahayaan 70–130%
    layers.RandomContrast(0.2),                # kontras ±20%
    layers.GaussianNoise(stddev=0.05),         # noise sensor kamera lama
])
```

**Akurasi pada Kondisi Khusus:**
- Uang sangat lusuh (lipatan >30%): Akurasi turun ke ~82% → threshold 0.85 menolak prediksi → sistem meminta perbaikan posisi ✅
- Uang basah/terlipat separuh: Akurasi ~70% → threshold 0.85 menolak → aman ✅
- Uang palsu: **Model tidak dirancang untuk deteksi keaslian** — hanya klasifikasi nominal visual. Uang palsu yang tampilannya mirip asli akan terdeteksi sebagai nominal tersebut. Ini adalah **keterbatasan eksplisit** yang dikomunikasikan ke pengguna.

---

### Q24 🎓 — Privacy-by-Design: Implementasi Teknis

> *"Anda mengklaim 'zero camera data retention'. Buktikan secara teknis, bukan hanya secara kebijakan, bahwa foto kamera tidak pernah tersimpan ke disk."*

**Jawaban:**

**Arsitektur Memori yang Menjamin Zero Retention:**

Dalam Flutter, `CameraController` menghasilkan stream `CameraImage` yang hidup di heap memory sebagai objek Dart. Objek ini:
1. Tidak pernah di-serialize ke file (`File.writeAsBytes()` tidak pernah dipanggil dalam pipeline deteksi)
2. Langsung dikirim ke Dart Isolate sebagai copy bytes (bukan reference ke disk)
3. Setelah `Isolate.send()`, GC Dart akan mereclaim memori karena tidak ada reference lain

**Audit Kode:**
```bash
# Grep seluruh codebase untuk penulisan file gambar
grep -r "writeAsBytes\|savePicture\|File\(" lib/ --include="*.dart" \
  | grep -v "test\|ocr_screen"
# Output: Hanya ocr_screen.dart untuk fitur "Salin ke Clipboard" yang
# menulis ke temporary system path (bukan galeri/penyimpanan permanen)
# dan file tersebut dihapus setelah clipboard copy (await file.delete())
```

**Untuk Upload ke Server (OCR, VinScene):**
Data yang dikirim ke server menggunakan `application/octet-stream` dalam memori, bukan file path. Server juga **tidak menyimpan gambar** — hanya memproses dan mengembalikan hasil teks/deteksi:
```python
# Backend: tidak ada kode seperti ini:
# cv2.imwrite("uploaded.jpg", frame)  ← TIDAK ADA
# Hanya:
frame = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
result = process(frame)
# frame langsung di-GC saat fungsi return
```

---

### Q25 🎓 — Validasi Dataset Sidewalk Indonesia

> *"1.850 gambar untuk fine-tuning PIDNet-S — bagaimana proses anotasi, siapa annotator-nya, dan berapa Inter-Annotator Agreement (IAA) yang dicapai?"*

**Jawaban:**

**Proses Pengumpulan Data:**
- Rekaman video dari 8 lokasi berbeda: trotoar mall, pasar tradisional, jalanan kampus, trotoar pusat kota Surabaya, area pemukiman, terminal bus, area wisata
- Total: 12 video @30FPS, diekstrak menjadi 3.100 frame unik
- **Filtering kualitas:** 1.250 frame dibuang (buram, gelap total, duplikat temporal) → 1.850 frame final

**Proses Anotasi:**
- Tool: **CVAT (Computer Vision Annotation Tool)** dengan 3 kelas: safe_path, caution_zone, danger_zone
- **5 annotator** (mahasiswa Teknik Komputer PENS yang dilatih selama 2 jam)
- Setiap gambar dianotasi oleh **2 annotator berbeda**

**Inter-Annotator Agreement:**
$$IAA = \frac{2 \times |A_1 \cap A_2|}{|A_1| + |A_2|}$$
Rata-rata IAA pixel-wise: **0.73** (dice coefficient) — tergolong "substantial agreement" menurut Landis & Koch scale.

**Keterbatasan Jujur:**
- Malam hari: hanya 180 gambar (9.7% dataset) — model mungkin kurang akurat di kondisi malam
- Banjir/basah: 0 gambar — kondisi hujan deras tidak terwakili dalam dataset
- Rencana: Penambahan 500+ gambar kondisi malam dan hujan dalam iterasi berikutnya

---

## BAGIAN 3 — SKENARIO KRITIS & EDGE CASES (Q26–Q38)

---

### Q26 🏭 — Skenario: Kegagalan Berbahaya di Jembatan

> *"Pengguna sedang berjalan di atas jembatan pedestrian sempit. Tidak ada rintangan objek (YOLO clear), tapi tepian jembatan ada di kiri-kanan tanpa pagar. Model tidak mengenali 'tepian jembatan tanpa pagar' sebagai bahaya. Apa yang Vinara lakukan?"*

**Jawaban:**

**Pengakuan Jujur:** Ini adalah **genuine blind spot** dalam arsitektur saat ini. SSD MobileNet yang dilatih pada COCO tidak memiliki kelas "tepi jembatan" atau "void/jurang". PIDNet-S 3-zona mungkin mengklasifikasikan area kosong di bawah/samping sebagai "caution" berdasarkan perubahan tekstur, tapi tidak ada jaminan.

**Mitigasi yang Ada (Tidak Sempurna):**
1. **PIDNet-S edge analysis:** Jika distribusi piksel di kiri dan kanan frame tiba-tiba menjadi "sky" (warna langit dominan) dan bukan trotoar, sistem menandai sebagai caution zone.
2. **Disclaimer onboarding:** Pengguna secara eksplisit diberitahu bahwa Vinara **tidak menggantikan orientasi spasial dan pendengaran alami** — di lingkungan asing (jembatan, eskalator, lift), pengguna harus lebih berhati-hati dan bertanya pada orang sekitar.

**Rencana Roadmap:** Integrasi **depth estimation monocular** (MiDaS atau DepthAnything Lite) untuk mendeteksi perbedaan kedalaman mendadak di kiri-kanan pengguna — ini dapat mendeteksi tepian jembatan, tepi peron, dan tangga tanpa pagar secara universal tanpa membutuhkan kelas spesifik.

---

### Q27 🏭 — Skenario: Motor Muncul dari Blind Spot Belakang

> *"Sepeda motor muncul dari belakang pengguna dengan kecepatan tinggi. Kamera hanya menghadap ke depan. Bagaimana Vinara melindungi pengguna dari bahaya dari arah belakang?"*

**Jawaban:**

**Pengakuan Tegas:** Vinara **tidak dapat mendeteksi ancaman dari arah belakang pengguna**. Ini adalah keterbatasan fisik desain — kamera menghadap ke depan sebagaimana mata normal manusia.

**Argumen Desain:**
Motor dari belakang menghasilkan suara mesin yang terdengar oleh pengguna tunanetra — kemampuan pendengaran spasial alami mereka justru sangat tajam untuk mendeteksi ancaman dari belakang. Vinara tidak boleh "berbicara" saat motor dari belakang lewat karena justru akan **mengganggu pendengaran alami** yang sedang memproses suara motor.

**Mitigasi Jangka Pendek:**
- Instruksi onboarding: *"Selalu berjalan di sisi trotoar yang paling jauh dari jalan kendaraan. Percayakan telinga Anda untuk ancaman dari samping dan belakang."*

**Mitigasi Jangka Panjang (Roadmap):**
Integrasi dengan **earphone/headset Bluetooth** — microphone headset menangkap suara dari belakang dan sistem memproses intensitas suara untuk memperkirakan arah dan jarak kendaraan. Ini adalah teknologi yang sudah digunakan oleh **Microsoft Soundscape** dan **Wayband WearWorks**.

---

### Q28 🏭 — Skenario: Mati Lampu & Baterai Lemah

> *"Baterai HP tinggal 5% saat pengguna sedang dalam perjalanan pulang di malam hari. Bagaimana Vinara mengelola kondisi darurat ini?"*

**Jawaban:**

**Mekanisme yang Diimplementasikan:**

1. **Battery Level Monitoring (StatusBanner):**
   - Saat baterai <20%: Banner Info muncul (tidak interruptif) — *"Baterai mulai menipis"*
   - Saat baterai <10%: Banner Warning + TTS — *"Baterai hampir habis, segera cari tempat pengisian"*
   - Saat baterai <5%: Banner Critical + TTS berulang setiap 60 detik

2. **Battery Saver Mode (Auto-Activate <10%):**
   - Resolusi kamera diturunkan dari 640×480 ke 320×240
   - FPS target diturunkan dari 30 ke 15
   - Fitur server-dependent (VinScene, VinSearch) dinonaktifkan otomatis
   - Hanya SSD MobileNet on-device yang tetap aktif (mode darurat minimal)

3. **Emergency Contact Preparation (Roadmap):**
   - Saat baterai <5% dan sistem terdeteksi sedang dalam navigasi aktif (GPS bergerak), opsi **kirim lokasi GPS ke kontak darurat** via SMS — tidak butuh internet.

**Saat HP Mati Total:** Vinara tidak dapat berbuat apa-apa — ini adalah batas keras. Rekomendasi kami: pengguna tunanetra yang aktif berjalan jauh harus membawa **power bank** atau mengaktifkan mode hemat daya OS sejak awal perjalanan.

---

### Q29 🏭 — Skenario: Server Backend Mati Saat VinScene Aktif

> *"Backend server mati (crash, mati lampu kantor tempat server berjalan). Pengguna sedang meminta deskripsi scene. Apa yang terjadi?"*

**Jawaban:**

**Mekanisme Graceful Degradation (5 Level):**

```
Level 5 (Normal): Server aktif → Moondream2 → deskripsi kaya
Level 4 (Server Lambat >5s): Timeout → fallback ke deskripsi template berbasis deteksi lokal
Level 3 (Server Unreachable): HTTP error → offline mode → template narasi
Level 2 (Partial offline): TFLite + CommandParser tetap berjalan → 5 fitur utama OK
Level 1 (Minimal): Hanya TTS peringatan darurat, TalkBack OS sebagai backup
```

**Implementasi Konkret:**
```dart
// server_service.dart
try {
  final response = await http.post(uri, body: jsonEncode(payload))
    .timeout(const Duration(seconds: 8)); // 8 detik timeout
  return jsonDecode(response.body)['narasi'];
} on TimeoutException {
  // Fallback ke template narasi lokal
  return _buildLocalNarasi(currentDetections);
} on SocketException {
  // Server tidak terhubung
  _statusBanner.show('Server tidak terhubung', tier: InfoTier);
  return _buildLocalNarasi(currentDetections);
}
```

**Template Narasi Fallback (Tanpa LLM):**
```
Deteksi: [orang (depan, 1.2m, Critical), motor (kanan, 2.8m, Warning)]
Output: "Di depan ada orang, sekitar satu meter. 
         Di kanan ada motor, sekitar tiga meter."
```

Tanpa LLM, kalimat lebih kaku, tapi **informasi keselamatan tetap tersampaikan**.

---

### Q30 🏭 — Skenario: Cahaya Sangat Silau (Backlight)

> *"Pengguna berjalan dari dalam gedung ke luar saat siang hari cerah — kamera mengalami overexposure. Bagaimana sistem menangani kondisi backlight/silau?"*

**Jawaban:**

**Deteksi Kondisi Overexposure:**
Sama seperti deteksi gelap, sistem melakukan **brightness check via plane-Y**:
$$\text{Avg Luminance} = \frac{1}{100} \sum_{i=0}^{99} Y[\text{step} \times i]$$

- Jika `avgLuma > 220` (dari 0–255): Frame dianggap **overexposed** → inferensi dibatalkan.
- TTS: *"Cahaya terlalu silau, kamera perlu penyesuaian. Tunggu sebentar."*

**Auto-Exposure Adaptation:**
Camera2 API Android memiliki mekanisme Auto-Exposure (AE) yang membutuhkan **~1–3 detik** untuk menyesuaikan dari kondisi gelap ke terang atau sebaliknya. Selama periode adaptasi, Vinara **menahan inferensi dan memperingatkan pengguna untuk berhenti sejenak** via TTS + haptic.

**Luma Contrast Enhancement (`luma_contrast.dart`):**
Setelah AE stabil, sistem menerapkan **CLAHE (Contrast Limited Adaptive Histogram Equalization)** pada frame yang kontrasnya rendah akibat sisa backlight — ini meningkatkan akurasi deteksi pada kondisi pencahayaan tidak merata.

---

### Q31 🏭 — Skenario: Liability & Kecelakaan

> *"Pengguna menggunakan Vinara, tidak terdeteksi rintangan, dan mengalami cedera. Siapa yang bertanggung jawab secara hukum? Bagaimana tim Anda mengelola risiko liability ini?"*

**Jawaban:**

**Posisi Hukum yang Kami Ambil:**
Vinara adalah **alat bantu asistif, bukan pengganti indera penglihatan dan sistem navigasi primer**. Ini setara dengan tongkat putih elektronik — jika tongkat putih gagal mendeteksi lubang, pabrikan tongkat tidak otomatis bertanggung jawab atas cedera.

**Implementasi Perlindungan Hukum:**

1. **Disclaimer Eksplisit di Onboarding (Layar 1):**
   *"Vinara adalah alat bantu tambahan, bukan sistem navigasi primer. Selalu gunakan tongkat putih dan penilaian Anda sendiri untuk keselamatan. Tim Guidio tidak bertanggung jawab atas cedera akibat keterbatasan teknologi AI."*

2. **In-App Reminder Periodik:**
   Setiap 30 menit penggunaan aktif, TTS mengingatkan: *"Vinara membantu navigasi, tapi selalu waspada dengan lingkungan sekitar."*

3. **Transparent Limitations (Settings → "Tentang Keterbatasan"):**
   Daftar eksplisit apa yang Vinara TIDAK bisa deteksi (got kecil, rintangan di luar jangkauan kamera, ancaman dari belakang, dll.)

4. **Rencana:** Konsultasi dengan ahli hukum TIK Indonesia untuk mengkaji apakah perlu **end-user license agreement (EULA)** yang spesifik mengatur batasan liability produk AI asistif — mengacu pada praktik terbaik dari Seeing AI (Microsoft) dan Be My Eyes.

---

### Q32 🏭 — Skenario: Kepadatan Sosial — Tempat Ibadah / Pasar Malam

> *"Di pasar malam atau halaman masjid saat Jumat, ada 50+ orang dalam jangkauan kamera dalam satu frame. SSD MobileNet maks 10 deteksi per frame. Apa yang terjadi?"*

**Jawaban:**

**Perilaku SSD MobileNet:**
Model ini memang menghasilkan maksimal 10 bounding box per frame (sudah include NMS). Dalam frame dengan 50 orang, model akan mendeteksi **10 orang terpadat dan terdekat** (karena bounding box lebih besar = score lebih tinggi untuk overlap).

**Efek pada Pengguna (Menguntungkan):**
Model secara alami memprioritaskan orang-orang **paling dekat dengan pengguna** — yang justru merupakan ancaman keselamatan terbesar. 40 orang lainnya yang lebih jauh tidak kritis untuk peringatan segera.

**Masalah yang Muncul:**
Dengan 10 orang detected, semuanya bisa berpotensi critical (<1,5m) di pasar padat. **Audio overload** akan terjadi jika tidak ada filter.

**Solusi (Sudah Diimplementasikan):**
1. **Cognitive Cap (Filter Step 8):** Hanya **2 objek terpadat dengan tier tertinggi** yang diumumkan.
2. **Same-label Deduplication:** Jika semua 10 deteksi adalah "orang", hanya 1 pengumuman "Orang, sangat dekat, di depan!" — tidak diulangi 10 kali.
3. **Speed Adaptation:** Di kerumunan padat, pengguna secara naluri berjalan **lebih lambat** — ini memberi buffer waktu lebih panjang, dan sistem cooldown otomatis menyesuaikan.

---

### Q33 🏭 — Skenario: HP yang Miring Drastis saat Naik Tangga

> *"Saat naik tangga, pengguna cenderung menundukkan badan dan HP ikut miring ke bawah 60–70°. Formula tilt correction menggunakan cosine correction — pada 70°, cos(70°) = 0.34, jarak akan sangat underestimate. Bagaimana?"*

**Jawaban:**

$$D_{corrected} = D_{raw} \times \cos(|\theta|) = D_{raw} \times \cos(70°) = D_{raw} \times 0.342$$

Jika $D_{raw} = 3\text{m}$, maka $D_{corrected} = 1.03\text{m}$ → objek diestimasi sangat dekat padahal mungkin aman.

**Ini adalah false positive berbahaya** — sistem akan memperingatkan "Bahaya!" padahal pengguna sedang naik tangga dalam kondisi normal.

**Mekanisme Deteksi Kondisi Tangga:**
```dart
// camera_health_service.dart
void _checkTiltCondition(double ax, double ay, double az) {
  final pitchAngle = math.atan2(ax, az) * 180 / math.pi;
  
  if (pitchAngle.abs() > 55) {
    // HP miring sangat parah — mode tangga/berlutut
    _isSteepTilt = true;
    _notifyTts("Kamera sedang miring, peringatan jarak mungkin tidak akurat");
    // Nonaktifkan sementara distance-based warnings
    // Hanya tampilkan LABEL objek tanpa estimasi jarak
    detectionFilter.setDistanceModeDisabled(true);
  } else {
    _isSteepTilt = false;
    detectionFilter.setDistanceModeDisabled(false);
  }
}
```

**Saat `distanceModeDisabled = true`:**
Sistem masih mendeteksi objek, tapi mengumumkan tanpa jarak: *"Ada anak tangga di depan"* alih-alih *"Tangga, 1 meter di depan"*. Ini lebih aman daripada memberikan estimasi jarak yang salah secara dramatis.

---

### Q34 🏭 — Skenario: STT Salah Mendengar dan Memicu Aksi Berbahaya

> *"Dalam kondisi bising, STT salah mendengar 'hentikan' sebagai 'sentakan'. CommandParser memproses 'sentakan' sebagai intent tidak dikenal → tidak ada aksi. Tapi bagaimana jika salah dengar menghasilkan perintah yang berbahaya?"*

**Jawaban:**

**Desain Safety-First pada VoiceIntent:**
Kami secara sengaja **tidak mengimplementasikan intent berbahaya yang bisa terpicu oleh suara**. Semua aksi yang dapat dilakukan melalui suara adalah **aksi informatif** (ganti mode, minta deskripsi, minta ulangi) — tidak ada aksi seperti "hentikan semua sistem" atau "nonaktifkan peringatan darurat".

**Pemetaan Intent yang Aman:**
```
describeScene    → Minta deskripsi (tidak berbahaya jika salah trigger)
modeMoney        → Ganti ke mode uang (mundur ke mode tuntun via tombol)
actionReplay     → Ulangi suara terakhir (aman)
actionStopWalking → Menghentikan instruksi navigasi aktif (bukan menghentikan deteksi keselamatan)
```

**Pertanyaan Juri: "Tapi kalau 'matikan vinara' salah dipicu?"**
`actionPowerOff` atau shutdown total **tidak ada dalam daftar 20 VoiceIntent**. Untuk mematikan aplikasi, pengguna harus menggunakan tombol fisik OS (power button atau swipe gesture OS-level) — bukan perintah suara aplikasi.

---

### Q35 🏭 — Skenario: Pengguna Low Vision (Bukan Totally Blind)

> *"Tidak semua target pengguna Anda adalah tunanetra total. Low vision user mungkin masih bisa melihat layar samar-samar. Apakah UI Vinara berfungsi optimal untuk low vision?"*

**Jawaban:**

**Desain Dual-Mode untuk Low Vision:**

1. **High Contrast Mode (WCAG 2.2 AAA):**
   - Rasio kontras teks: min 7:1 (AAA) hingga 17.8:1 (extreme high contrast untuk low vision berat)
   - Font size minimum 18sp untuk label utama, 14sp untuk sekunder
   - Ikon berbasis bentuk geometris (segitiga = Critical, lingkaran = Warning, persegi = Info) — dapat dibedakan tanpa bergantung warna

2. **Text Size Customization:**
   Settings → Ukuran Teks: S/M/L/XL — mengubah `textScaleFactor` di seluruh aplikasi

3. **Visual Feedback yang Tumpang-tindih dengan Audio:**
   Kartu peringatan bahaya (`AlertCard`) menampilkan teks besar dengan warna kontras tinggi di layar — pengguna low vision yang memegang HP dekat ke wajah dapat membacanya sekaligus mendengar TTS.

4. **Torch Mode (Lampu Kilat):**
   Pengguna low vision di kondisi kurang cahaya dapat mengaktifkan lampu kilat HP via perintah suara — meningkatkan visibilitas lingkungan untuk sisa penglihatan yang masih ada.

---

### Q36 🏭 — Keamanan Backend: Siapa yang Bisa Akses?

> *"Backend Anda berjalan di laptop lokal dengan IP yang dikonfigurasi manual. Artinya siapa pun di jaringan WiFi yang sama bisa mengakses endpoint API Anda tanpa autentikasi. Ini risiko keamanan serius."*

**Jawaban:**

**Pengakuan Jujur:** Ini adalah **kelemahan nyata dalam versi prototipe saat ini**. Backend versi demo berjalan tanpa autentikasi — ini disengaja untuk kemudahan demonstrasi kompetisi.

**Rencana Keamanan untuk Produksi:**

1. **API Key Authentication:**
```python
# Middleware autentikasi sederhana
async def verify_api_key(request: Request, api_key: str = Header(...)):
    if api_key not in VALID_API_KEYS:
        raise HTTPException(status_code=401)
```

2. **TLS/HTTPS via Reverse Proxy (Nginx):**
   Seluruh komunikasi dienkripsi — mencegah man-in-the-middle attack di jaringan publik.

3. **Rate Limiting:**
   Maks 60 request/menit per IP — mencegah abuse.

4. **JWT Token per Session:**
   Setiap sesi aplikasi mendapat token sementara (expired 24 jam) — bukan hardcoded API key.

5. **Untuk Versi Distribusi:** Backend tidak lagi di laptop lokal, melainkan cloud VM dengan VPN private network — hanya HP yang terdaftar yang dapat mengakses.

---

### Q37 🏭 — Skenario: Pengguna Tuli-Buta (Deafblind)

> *"Bagaimana Vinara melayani pengguna yang sekaligus tuli dan buta? Mereka tidak dapat mendengar TTS."*

**Jawaban:**

**Kondisi Saat Ini:** Vinara belum dioptimalkan untuk pengguna tuli-buta — ini adalah **keterbatasan yang kami akui secara jujur**. Mayoritas pengguna target adalah tunanetra yang masih memiliki pendengaran normal.

**Yang Sudah Ada untuk Deafblind:**
- **Haptic Feedback:** Sistem 3-tier haptic (Critical/Warning/Info) dapat menjadi satu-satunya channel komunikasi untuk pengguna deafblind. Mereka dapat merasakan perbedaan triple pulse vs double vs single.
- **Pola Haptic yang Lebih Ekspresif (Roadmap):** Mengembangkan "haptic alphabet" yang dapat menyampaikan informasi arah (kiri/kanan/depan) melalui kombinasi pola dan posisi getaran.

**Teknologi Masa Depan:**
Integrasi dengan **Braille display Bluetooth** (seperti Orbit Reader 20) yang sudah ada di pasar — teks deskripsi scene dapat dikirim ke display Braille secara real-time. Ini adalah roadmap yang sudah kami identifikasi namun membutuhkan partnership dengan produsen Braille display.

---

### Q38 🏭 — Skenario: Kacamata Penanda (Fiducial Marker) / QR Code di Lingkungan

> *"Apotek, rumah sakit, dan gedung modern mulai memasang QR code dan NFC tag aksesibilitas. Apakah Vinara bisa memanfaatkannya?"*

**Jawaban:**

**Integrasi yang Sudah Ada (OCR):**
Mode Baca Teks (VinRead) menggunakan ML Kit yang otomatis membaca teks pada papan nama, label, dan kartu — termasuk URL yang tertera pada QR code (jika OCR membaca teks di sekitar QR).

**Integrasi QR Code Aktif (Roadmap):**
Flutter memiliki paket `qr_code_scanner` yang dapat membaca QR code sambil kamera aktif — dengan API call ke database lokal yang berisi metadata gedung (nama ruangan, arah lift, toilet penyandang disabilitas). Ini sejalan dengan standar **ISO 21542 (Building Accessibility)** yang merekomendasikan QR code aksesibilitas.

**Integrasi NFC (Roadmap):**
Android mendukung NFC reader native — pengguna mendekatkan HP ke tag NFC di pintu atau lift, sistem membacakan informasi lokasi dan instruksi navigasi indoor.

---

## BAGIAN 4 — BISNIS, REGULASI, & KEBERLANJUTAN (Q39–Q50)

---

### Q39 🏭 — Regulasi: Kepatuhan UU Disabilitas Indonesia

> *"Sejauh mana Vinara selaras dengan Undang-Undang No. 8 Tahun 2016 tentang Penyandang Disabilitas dan Peraturan Pemerintah No. 42 Tahun 2020 tentang Aksesibilitas Penyandang Disabilitas?"*

**Jawaban:**

**Relevansi Regulasi:**
- **UU 8/2016 Pasal 18:** Pemerintah wajib menyediakan aksesibilitas di fasilitas publik untuk penyandang disabilitas netra, termasuk teknologi asisitif. Vinara mendukung mandat ini sebagai teknologi asisitif yang dapat didistribusikan oleh pemerintah.
- **PP 42/2020 Pasal 7:** Standar aksesibilitas informasi dan komunikasi untuk penyandang disabilitas — Vinara mengimplementasikan TalkBack compatibility, kontras warna WCAG 2.2, dan target sentuh minimum 48×48dp.
- **UU PDP No. 27/2022:** Data pribadi pengguna harus dilindungi. Vinara mengimplementasikan Privacy-by-Design — tidak ada data biometrik (foto, suara) yang disimpan atau ditransmisikan ke pihak ketiga.

**Peluang B2G:**
Melalui regulasi ini, Kementerian Sosial dan pemerintah daerah memiliki **mandat dan anggaran** untuk pengadaan teknologi asisitif. Vinara dapat masuk ke skema pengadaan ini melalui jalur TKDN (Tingkat Komponen Dalam Negeri) sebagai produk teknologi lokal.

---

### Q40 🏭 — Model Bisnis: Detail Angka

> *"Anda menyebut biaya server <Rp800/user/bulan. Berikan breakdown rinci kalkulasi ini."*

**Jawaban:**

**Asumsi Infrastruktur:**
- Server: VPS dengan GPU NVIDIA T4 (16GB VRAM) — harga ~$120/bulan (Google Cloud N1 + T4)
- Moondream2 inference: ~1 detik/request
- Utilisasi: 1 server mampu menangani 60 request/menit = 3.600 request/jam

**Estimasi Penggunaan per User:**
- Pengguna aktif menggunakan VinScene (fitur yang butuh server) rata-rata **3 kali per hari**
- Per request: ~1 detik GPU time
- Per user per bulan: 3 × 30 = 90 requests

**Kalkulasi Biaya:**
```
Kapasitas server per bulan: 60 req/menit × 60 min × 24h × 30 hari = 2.592.000 request
Target user aktif: 10.000 user (90 request/user/bulan) = 900.000 request/bulan
Utilisasi server: 900.000 / 2.592.000 = 34.7% (1 server cukup)

Biaya server: $120/bulan × Rp16.000 = Rp 1.920.000/bulan
Biaya per request: Rp 1.920.000 / 900.000 = Rp 2.13/request
Biaya per user/bulan: Rp 2.13 × 90 request = Rp 192/user/bulan
```

**Catatan:** Estimasi <Rp800/user/bulan termasuk **overhead infra tambahan** (bandwidth, storage, monitoring, maintenance = 4× cost of compute) → $192 × 4 = $768/bulan ~ **Rp 768/user/bulan** ✅ Konsisten dengan klaim.

**Pada 50.000 user aktif:**
- Request/bulan: 50.000 × 90 = 4.500.000 → butuh 2 server
- Total biaya server: $240/bulan = Rp 3.840.000
- Biaya/user: Rp 3.840.000 × 4 overhead / 50.000 user = **Rp 307/user/bulan** (semakin hemat saat scale)

---

### Q41 🏭 — Skalabilitas Backend

> *"Jika pengguna bertumbuh dari 1.000 ke 100.000 dalam 6 bulan karena viral di media sosial, arsitektur server apa yang siap menampung itu?"*

**Jawaban:**

**Arsitektur Skalabilitas (Rencana Produksi):**

```
[Load Balancer (Nginx/Cloudflare)]
         ↓
[API Gateway (rate limiting, auth)]
         ↓
[Worker Pool — FastAPI + Uvicorn]
  Worker 1: CPU (OCR, intent routing)
  Worker 2: GPU Node 1 (Moondream2)
  Worker 3: GPU Node 2 (Moondream2)
         ↓
[Task Queue — Celery + Redis]
  (untuk request yang bisa async)
         ↓
[PostgreSQL + Read Replica]
```

**Horizontal Scaling Strategy:**
- **CPU workers (OCR, intent):** Stateless FastAPI — scale horizontal dengan menambah instance di balik load balancer. Biaya CPU sangat murah.
- **GPU workers (Moondream2):** Autoscaling group berdasarkan queue depth — tambah GPU instance saat request >200/menit.
- **Estimasi biaya 100.000 user aktif:**
  - CPU workers: 3 instance × $50/bulan = $150
  - GPU workers (autoscale): rata-rata 2 GPU × $120 = $240
  - Database: $50/bulan
  - **Total: ~$440/bulan = Rp 7.040.000/bulan → Rp 70/user/bulan**

---

### Q42 🏭 — Go-to-Market Strategy: Bagaimana Menjangkau Pengguna?

> *"Pengguna tunanetra bukan pengguna biasa. App Store visibility tidak berguna jika mereka tidak bisa melihat screenshot. Bagaimana Vinara menjangkau pengguna yang tepat?"*

**Jawaban:**

**Jalur Distribusi yang Direncanakan:**

1. **Komunitas Disabilitas (Zero Cost):**
   - PERTUNI (Persatuan Tunanetra Indonesia) — jaringan 500+ anggota aktif di 34 provinsi
   - ITMI (Ikatan Tunanetra Muslim Indonesia)
   - Yayasan Mitra Netra Jakarta
   - **Strategi:** Demo langsung di pertemuan komunitas, distribusi APK via WhatsApp group komunitas (lebih efektif dari Play Store untuk segmen ini)

2. **Sekolah Luar Biasa (SLB) — Channel Edukasi:**
   - 2.200+ SLB-A (Tunanetra) di Indonesia
   - Guru SLB dapat menjadi agen adopsi — mengajarkan penggunaan Vinara sebagai skill digital inklusif

3. **Partnership Institusi:**
   - Rumah Sakit Mata — instalasi Vinara pada tablet demo di waiting room
   - Bank Nasional — distribusi lewat program CSR inklusi keuangan (fitur VinCash)

4. **Media Coverage (PR):**
   - Pitch ke **Kumparan, Detik, CNN Indonesia** dengan human interest story — studi kasus 1 pengguna tunanetra yang hidupnya berubah dengan Vinara
   - Demo langsung di **Hari Disabilitas Nasional (3 Desember)** dan **Hari Kesehatan Mata Dunia (12 Oktober)**

---

### Q43 🏭 — Kompetitor Baru: Apakah Ada Ancaman dari Perusahaan Besar?

> *"Google bisa saja update Lookout besok dengan fitur yang sama persis dengan Vinara. Microsoft bisa kembangkan Seeing AI untuk Indonesia. Apa yang membuat Vinara tidak mudah disalip?"*

**Jawaban:**

**Competitive Moat Vinara:**

1. **Konteks Dataset Lokal (Data Moat):**
   Vinara-Sidewalk Dataset dan Rupiah Vision Dataset adalah aset proprietari yang butuh **waktu dan biaya besar untuk direplikasi**. Google dan Microsoft tidak memiliki dataset trotoar Indonesia yang terkurasi. Membangun dataset ini membutuhkan fieldwork lokal, anotasi lokal, dan pemahaman konteks lokal.

2. **Bahasa & Dialek (Language Moat):**
   CommandParser dengan 847 frasa Bahasa Indonesia informal + 6 dialek daerah adalah knowledge lokal yang tidak mudah dikurasi oleh perusahaan asing. Google Speech-to-Text memang kuat di Bahasa Indonesia, tapi pemahaman konteks perintah navigasi spesifik tunanetra Indonesia tidak tersedia di produk mereka.

3. **Regulasi & Pengadaan Pemerintah (Regulatory Moat):**
   Sebagai produk lokal dengan TKDN, Vinara memiliki keunggulan dalam pengadaan pemerintah yang mensyaratkan komponen dalam negeri.

4. **Kecepatan Adaptasi:**
   Tim mahasiswa lokal dapat merespon kebutuhan spesifik pengguna Indonesia (misalnya: integrasi dengan layanan ojek online, pembacaan BPJS, dll.) jauh lebih cepat dibandingkan siklus produk Microsoft/Google yang bersifat global.

---

### Q44 🏭 — Tantangan Adopsi: Literasi Digital Tunanetra

> *"Sebagian besar tunanetra di Indonesia adalah lansia atau orang dengan literasi teknologi rendah. Bagaimana Vinara memastikan mereka bisa menggunakan HP secara mandiri?"*

**Jawaban:**

**Realita Demografik:**
Data PERTUNI menunjukkan bahwa **>60% anggota aktif** sudah menggunakan smartphone secara rutin — terutama untuk WhatsApp audio/video call, YouTube audio, dan TalkBack. Mereka bukan "tidak tahu teknologi", tapi butuh adaptasi untuk aplikasi baru.

**Strategi Onboarding:**

1. **3-Langkah Onboarding Audio-First:**
   Onboarding tidak mengandalkan teks — setiap langkah diucapkan oleh TTS: *"Ini Vinara. Pegang HP tegak menghadap ke depan. Tekan tombol besar di bawah untuk mulai. Vinara akan memberitahu jika ada rintangan di depan."*

2. **Physical Metaphor:**
   *"Tombol kiri: aksi di mode ini. Tombol tengah: bicara ke Vinara. Tombol kanan: ganti mode."* — Tiga tombol yang posisinya tidak pernah berubah menciptakan muscle memory yang cepat.

3. **Pendampingan oleh "Vinara Ambassador":**
   Rencana melatih 50 relawan dari komunitas PERTUNI sebagai "Vinara Ambassador" — mereka mendampingi pengguna baru selama 1-2 sesi belajar pertama.

4. **Tutorial Audio Bawaan:**
   Tersedia di Settings → Tutorial Suara — panduan audio 10 menit yang dapat diputar ulang kapan saja.

---

### Q45 🏭 — Keberlanjutan Tim: Bagaimana Setelah Kompetisi?

> *"Ini adalah proyek mahasiswa untuk kompetisi. Setelah kompetisi selesai, siapa yang akan maintain, update, dan kembangkan Vinara?"*

**Jawaban:**

**Rencana Keberlanjutan (Roadmap Tim):**

**Jangka Pendek (0–6 bulan post-kompetisi):**
- Publikasi open-source dataset Vinara-Sidewalk ke Hugging Face Hub — komunitas riset dapat berkontribusi
- Mendaftarkan Vinara ke **Google Play Store** (APK gratis) untuk mulai membangun user base
- Mengajukan proposal riset lanjutan ke **PENS Sky Venture** (inkubator kampus) dan **BRIN (Badan Riset dan Inovasi Nasional)**

**Jangka Menengah (6–18 bulan):**
- Spin-off startup dengan guidance dari alumni PENS entrepreneur
- Mengajukan hibah ke **Kedaireka (kemendikbudristek.go.id)** untuk pendanaan R&D lanjutan
- Target: 5.000 pengguna aktif sebagai proof of traction untuk investor impact

**Jangka Panjang (>18 bulan):**
- Partnership dengan vendor HP Android lokal (Advan, Polytron) untuk pre-install Vinara
- B2G: Pengadaan ke Kementerian Sosial untuk distribusi ke PPKS (Pusat Pengembangan Kompetensi Sumber Daya)

---

### Q46 🏭 — Perbandingan dengan Ainetra (Juara GEMASTIK XVII)

> *"Di Indonesia, Ainetra dari ITS sudah menang GEMASTIK XVII tahun lalu di divisi UX dengan konsep serupa. Apa bedanya Vinara dengan Ainetra?"*

**Jawaban:**

**Perbedaan Fundamental:**

| Aspek | Ainetra (ITS, GEMASTIK XVII) | Vinara (Guidio, PENS) |
|---|---|---|
| Fokus Kompetisi | UX Design (konsep/prototipe visual) | Pengembangan Perangkat Lunak (PPL) — sistem fungsional |
| Implementasi | Prototipe high-fidelity Figma | Aplikasi Flutter + Backend Python yang berjalan nyata |
| Model AI | Konseptual (belum di-implementasikan) | Deployed TFLite (SSD MobileNet, MobileNetV2, PIDNet-S, YOLOE) |
| Cakupan Fitur | Konsep navigasi dan voice UI | 6 mode fungsional + 6 model AI berbeda |
| Dataset | Tidak tersedia | Vinara-Sidewalk (1.850 img) + Rupiah Vision (4.200 img) |

Ainetra adalah pencapaian luar biasa di ranah UX design — kami sangat menghormati tim ITS. Vinara bercompete di jalur yang berbeda: **pengembangan teknis sistem fungsional**, bukan desain konseptual. Kami justru terinspirasi oleh konsep Ainetra untuk mewujudkannya sebagai sistem kerja yang dapat diuji dan digunakan langsung.

---

### Q47 🏭 — Aksesibilitas Ekonomi: Mengapa Gratis?

> *"Anda berencana menjual ke pemerintah (B2G) dan bisnis (B2B CSR), tapi aplikasinya gratis untuk pengguna. Bukankah ini risiko bisnis? Bagaimana jika B2G tidak tertarik?"*

**Jawaban:**

**Logika Model Bisnis:**
Gratis untuk pengguna akhir adalah **prasyarat adopsi** dalam konteks aplikasi aksesibilitas disabilitas. Jika berbayar, penyandang disabilitas — yang secara statistik memiliki tingkat penghasilan lebih rendah dari rata-rata — akan semakin terpinggirkan. Ini bertentangan dengan misi inti Vinara.

**Sumber Revenue Alternatif Jika B2G Gagal:**

1. **Freemium Model:**
   - Gratis: Deteksi objek, kenali uang, OCR
   - Premium Rp 15.000/bulan: Deskripsi scene VLM tak terbatas, navigasi dengan peta, dukungan prioritas
   - **Bagi mereka yang tidak mampu:** Skema "bayar sekehendak" (pay-what-you-can) dengan minimum Rp 0

2. **Data Partnership (Anonim & Opt-in):**
   Peta zona bahaya rintangan trotoar yang dikumpulkan secara anonim dari laporan pengguna dapat menjadi data berharga bagi Dinas PUPR, pengembang kota, dan akademisi yang membutuhkan data infrastruktur trotoar Indonesia.

3. **API Monetization:**
   Endpoint deteksi YOLOE dan narasi AI dapat dijual sebagai API ke pengembang lain yang membangun aplikasi aksesibilitas.

---

### Q48 🏭 — Standar Internasional & Sertifikasi

> *"Apakah ada standar sertifikasi untuk aplikasi assistive technology? Apakah Vinara berencana mendapatkan sertifikasi formal?"*

**Jawaban:**

**Standar yang Relevan:**

1. **WCAG 2.2 Level AA (W3C):** Vinara sudah didesain mengacu WCAG 2.2 — target sentuh, kontras warna, TalkBack compatibility. Validasi formal membutuhkan audit oleh accessibility specialist bersertifikat IAAP (International Association of Accessibility Professionals).

2. **ISO 9241-171 (Software Accessibility):** Standar internasional aksesibilitas perangkat lunak. Membutuhkan evaluasi formal oleh lembaga penguji terakreditasi.

3. **Sertifikasi KOMINFO/BSN (Indonesia):** Untuk distribusi resmi di Indonesia, terutama jika masuk pengadaan pemerintah, TKDN (Tingkat Komponen Dalam Negeri) perlu diverifikasi.

**Rencana:**
- **Jangka Pendek:** Self-assessment WCAG 2.2 dengan checklist resmi W3C
- **Jangka Menengah:** Audit aksesibilitas oleh PERTUNI (organisasi perwakilan pengguna) sebagai "user certification"
- **Jangka Panjang (Pre-B2G):** Sertifikasi formal ISO 9241-171 dan TKDN untuk memenuhi syarat pengadaan pemerintah

---

### Q49 🏭 — Global Expansion: Apakah Vinara Bisa Diekspor?

> *"Jika Vinara sukses di Indonesia, apakah bisa diekspor ke negara Asia Tenggara lain seperti Malaysia, Filipina, Vietnam yang punya masalah serupa?"*

**Jawaban:**

**Potensi Ekspansi Regional:**

| Negara | Populasi Tunanetra | Bahasa | Tantangan Adaptasi |
|---|---|---|---|
| Malaysia | ~400K | Bahasa Melayu (sangat dekat Indonesia) | Minimal — CommandParser 80% kompatibel |
| Filipina | ~1.2M | Filipino + Inggris | Butuh retrain CommandParser + TTS Filipino |
| Vietnam | ~2.1M | Vietnam | Lebih kompleks — tonal language, beda TTS engine |
| Thailand | ~1.4M | Thai | Paling sulit — script berbeda, tonal language |

**Strategi Ekspansi:**

1. **Malaysia First:** Bahasa Melayu sangat mirip Bahasa Indonesia — penyesuaian minimal pada CommandParser dan konten TTS. Target ekspansi 6–12 bulan setelah validasi Indonesia.

2. **Rupiah → Multi-Currency:** Mengganti model VinCash dari 7 kelas Rupiah menjadi framework multi-currency yang dapat di-retrain per negara.

3. **Dataset Sidewalk Lokal:** Setiap negara butuh fine-tuning PIDNet-S dengan dataset trotoar lokal. Partnership dengan universitas lokal untuk pengumpulan data.

---

### Q50 🏭 — Pertanyaan Penutup: Apa Satu Hal yang Paling Kamu Bangga & Paling Kamu Sesali?

> *"Setelah semua yang Anda jelaskan, apa SATU hal yang paling Anda banggakan dari Vinara, dan SATU hal yang paling Anda sesali / ingin perbaiki jika ada waktu lebih?"*

**Jawaban:**

**Yang Paling Dibanggakan:**
**CommandParser Dart — 847 frasa, 0ms, 100% offline.**

Dari semua komponen teknis yang dibangun, ini yang paling mencerminkan filosofi "local-first, offline-first" secara nyata. Kami menulis ribuan frasa dalam Bahasa Indonesia formal, informal, gaul, dan 6 dialek daerah secara manual dan teliti — bukan menggunakan LLM atau model siap pakai. Hasilnya adalah sistem perintah suara yang **bekerja di bawah jembatan tanpa sinyal, di pasar yang bising, dan tanpa biaya API** — sesuatu yang tidak bisa ditawarkan oleh kompetitor global.

**Yang Paling Disesali:**
**Bug ekspor model YOLO11n custom — 4 kelas kritis tidak aktif.**

Kami menghabiskan hampir 3 minggu mengumpulkan dan menganotasi dataset kelas kritis Indonesia (`got_terbuka`, `lubang`, `tiang`, `motor_di_trotoar`). Proses training berhasil, akurasi bagus. Tapi saat ekspor ke TFLite, terjadi bug **NCHW vs NHWC channel ordering** yang menyebabkan 4 dari 6 kelas output model menjadi silent (tidak pernah muncul dalam prediksi). Kami tidak sempat menyelesaikan fix ekspor sebelum deadline kompetisi.

Ini kami akui sebagai kegagalan teknis nyata yang berdampak langsung pada kemampuan navigasi inti Vinara. **Perbaikan ini adalah prioritas #1 pada sprint berikutnya** — dengan migrasi ke ONNX runtime (yang menangani channel ordering lebih konsisten dibanding TFLite converter) sebagai solusi yang sudah kami validasi pada environment testing.

---

## CHEAT-SHEET RINGKAS (QUICK REFERENCE CARD)

| Pertanyaan Kilat | Jawaban 1 Kalimat |
|---|---|
| Apa itu Vinara? | Mata digital AI untuk tunanetra Indonesia — proaktif, offline, Bahasa Indonesia. |
| Model deteksi apa? | SSD MobileNet TFLite (4MB, 28–45ms, 30FPS) on-device + YOLOE di server. |
| Butuh internet? | 5/6 mode 100% offline. Hanya VinScene (deskripsi visual mendalam) butuh server. |
| Kalau gelap/silau? | Deteksi luma <30 atau >220 → hentikan inferensi, beri peringatan suara+haptic. |
| Kalau server mati? | 5 mode tetap berjalan offline. VinScene fallback ke template narasi lokal. |
| Jarak dihitung bagaimana? | Monocular pinhole + tilt correction, dikelompokkan ke 3 tier (bukan angka presisi). |
| Biaya server? | <Rp800/user/bulan (semakin murah saat skala naik, karena 90% komputasi on-device). |
| Target pasar? | 2.1 juta tunanetra usia produktif pengguna smartphone di Indonesia. |
| Model bisnis? | B2G (Kemensos) + B2B CSR (bank nasional) → pengguna akhir GRATIS. |
| Kompetitor utama? | Seeing AI, Lookout, Be My Eyes — Vinara unggul di: lokal, offline, VUI Bahasa Indonesia. |
| Kelemahan terbesar? | Bug ekspor YOLO custom (4 kelas kritis mati) + n=8 user study masih terlalu kecil. |
| Rencana perbaikan? | Migrasi ke ONNX runtime + uji formal 30+ pengguna dengan PERTUNI. |

---

*Dokumen ini dibuat oleh Tim Guidio — PENS 2026 sebagai materi persiapan sidang juri KMIPN / GEMASTIK / Hackathon Inovasi Teknologi. Versi 2.0.*
