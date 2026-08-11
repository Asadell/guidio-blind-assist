# Vinara / Guidio — Backend

Backend untuk Vinara, asisten visual suara untuk pengguna tunanetra.

**Hal terpenting yang perlu dipahami lebih dulu:** dua dari enam mode
berjalan **sepenuhnya di perangkat** dan tidak pernah memanggil API ini —
Deteksi Objek dan Kenali Uang. Itu keputusan sengaja, bukan kekurangan:
keduanya dipakai di tempat tanpa sinyal (jalan, pasar, warung), jadi fitur
yang mati saat offline berarti fitur yang gagal.

---

## 1. Menjalankan

```bash
cd backend
venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Buka `http://localhost:8000/docs` untuk daftar endpoint interaktif.

### Prasyarat sistem

```bash
# OCR (Mode Baca Teks) — paket OS, bukan paket Python.
sudo dnf install -y tesseract tesseract-langpack-ind tesseract-langpack-eng
```

`pytesseract` di venv hanya pembungkus; tanpa binary `tesseract` di
`/usr/bin`, endpoint `/api/ocr` balas apa adanya bahwa engine tidak ada.

### PostgreSQL

```bash
createdb -h localhost -U postgres vinara_dev   # sekali saja
```

Skema dibuat otomatis saat startup (idempoten, lihat `db/schema.sql`), lalu
data rujukan di-seed (`db/seed.py`): 52 label objek, 20 intent suara, 7
denominasi, dan manifest model.

Kalau database mati, **server tetap jalan**. Endpoint yang butuh DB balas
pesan yang menyebut apa yang masih hidup, bukan sekadar 503 kosong.

### Konfigurasi

Semua lewat `.env` (lihat `.env.example`). Yang wajib diisi hanya kredensial
PostgreSQL dan `ANTHROPIC_API_KEY` bila ingin Asisten Suara penuh.

---

## 2. Enam fitur utama

| Fitur | Di mana jalan | Endpoint |
|---|---|---|
| Deteksi Objek Real-Time | **On-device** (TFLite), server hanya pembanding | `WS /ws/detect`, `POST /api/detect` |
| Kenali Uang Rupiah | **On-device** (TFLite), tidak pernah ke server | `POST /api/uang` (opsional) |
| Baca Teks / OCR | Server (butuh internet untuk teks panjang) | `POST /api/ocr` |
| Asisten Suara AI | Server (ada fallback lokal) | `POST /api/intent`, `/api/narasi`, `/api/asisten/*` |
| Cari Objek via suara | Server (YOLOE open-vocabulary) | `POST /api/cari-objek` |
| Navigasi jalur 3 zona | Server + rintangan on-device | `POST /api/navigasi` |

### Kenali Uang — kenapa on-device

Model: MobileNetV2 transfer learning, **6 kelas emisi 2016**, input
224×224×3 float32 dengan normalisasi `rescale = 1/255`.
Berkas: `guidio_app/assets/models/uang_rupiah.tflite`.

Urutan kelas **wajib** sama dengan saat training:

```
{'100rb': 0, '10rb': 1, '20rb': 2, '2rb': 3, '50rb': 4, '5rb': 5}
```

Urutan itu tersimpan di kolom `class_index` tabel `money_denominations`
dan di konstanta `MoneyTFLiteService.classValues`. **Kalau mengganti model,
dua tempat itu harus diubah bersamaan.**

Keterbatasan yang harus disebut jujur ke pengguna: model ini **tidak punya
kelas Rp1.000**. Di database, Rp1.000 ditandai `active = false`.

Aturan yang tidak bisa ditawar: **nominal tidak pernah ditebak.** Di bawah
ambang keyakinan (0.85), yang keluar hanya instruksi perbaikan. Salah
menyebut nominal ke pengguna tunanetra berarti kerugian uang nyata, jadi
false positive di sini jauh lebih berbahaya daripada false negative.

### Cari Objek — YOLOE

Prompt teks bebas, karena target datang dari ucapan pengguna dan tidak bisa
ditentukan saat training. Nama barang Bahasa Indonesia diterjemahkan ke
prompt Inggris lewat tabel `object_labels` + kamus `EXTRA_ID_TO_EN`
(83 nama barang siap pakai).

Model dimuat **malas** saat permintaan pertama (~2 detik), karena bobot
YOLOE + encoder teks MobileCLIP berukuran ratusan MB dan mode ini jarang
dipakai dibanding Deteksi Objek.

`found: false` dengan `reason: not_in_frame` **bukan error** — itu kondisi
normal CO-10 yang membuat aplikasi menyuruh pengguna memutar badan lalu
memanggil endpoint ini lagi.

### Navigasi — 3 zona

Model utama PIDNet-S ONNX (three-branch, ada cabang boundary, jadi tepi
trotoar presisi). Kalau `models/pidnet_s_3zona.onnx` belum ada, service
memakai **fallback heuristik OpenCV** yang tetap membaca isi gambar
sungguhan: permukaan yang bisa dijalani cenderung rata (sedikit tepi,
warna konsisten dengan area tepat di depan kaki).

Bentuk balasannya identik untuk kedua jalur, dan jalur mana yang dipakai
selalu dilaporkan di field `source` — tidak ada klaim palsu. Menukar
heuristik ke PIDNet nanti tidak mengubah satu baris pun di sisi Flutter.

Cek jalur aktif: `GET /api/navigasi/status`.

> Mode Navigasi **tidak pernah dinonaktifkan saat offline.** Deteksi
> rintangan on-device tetap hidup; mematikannya akan mencabut fungsi
> keselamatan yang sebenarnya masih ada. Paling buruk statusnya `limited`.

---

## 3. Endpoint penunjang

Semuanya lahir dari state yang sudah dirancang, bukan dari kebiasaan umum
bikin API.

| Endpoint | Untuk state | Kegunaan |
|---|---|---|
| `GET /health` | PG-08b/c/e | Health check + waktu tempuh (dibacakan ke pengguna) |
| `GET /api/capabilities` | DO-11c, BT-01/02 | Mode mana yang hidup, **sebelum** tombol ditekan |
| `GET /api/labels` | DO-08, DO-19 | Kamus label → frasa Indonesia yang layak dibacakan |
| `GET /api/models/manifest` | UG-18 | Sinkronisasi model on-device |
| `POST /api/models/rescan` | — | Pindai `models/`, hitung sha256 |
| `POST /api/events` | target desain | Telemetri alur (jumlah gestur, waktu buka) |
| `GET /api/events/summary` | — | Ringkasan untuk membuktikan target |
| `POST /api/crash-report` | ER-06 | Tombol "Kirim laporan" |
| `GET /api/crash-report/last-mode` | ER-06 | Mode terakhir untuk dipulihkan |
| `POST /api/queue/flush` | BT-13 | Antrean unggah offline, idempoten |
| `POST /api/intent` | AS-17/18/19 | Resolusi perintah suara |
| `GET /api/intent/catalog` | — | 20 intent + varian ucapannya |
| `POST /api/asisten/turn` | AS-12/13 | Simpan giliran percakapan |
| `GET /api/asisten/history` | AS-12/13/23 | Riwayat percakapan |

### Kenapa capability discovery penting

Tanpa `/api/capabilities`, status server hanya ketahuan **setelah** gagal.
Untuk pengguna yang tidak melihat layar, itu berarti menekan tombol,
menunggu, lalu mendengar kegagalan. Dengan endpoint ini, ModePickerSheet
sudah bisa menandai item `limited`/`disabled` sejak awal, dan tombol utama
Mode Baca Teks tampil nonaktif **beserta alasannya** (BT-02).

### Idempotency antrean offline

`POST /api/queue/flush` wajib menyertakan `idempotency_key`. Pengiriman
ulang dengan kunci sama mengembalikan hasil tersimpan tanpa memproses
gambar dua kali — penting karena BT-13 mengirim ulang otomatis begitu
internet kembali.

### Resolusi perintah suara

Urutan usaha: **frasa persis → kemiripan kata + nama barang → LLM**.

Kalau ada **dua kandidat yang sama-sama masuk akal**, server sengaja
**tidak** memanggil LLM dan langsung menanyakan balik. Contoh dari
dokumen desain:

```
POST /api/intent  {"text": "kenal kunci"}

{
  "resolved": false,
  "reason": "ambiguous",
  "message": "Saya dengar kenal kunci. Maksudmu cari kunci, atau kenali uang?",
  "suggestions": [...]
}
```

Menebak salah lebih mahal daripada satu pertanyaan, karena penggunanya
tidak bisa melihat layar untuk mengoreksi. Prompt LLM pun diinstruksikan
menjawab `none` saat ragu.

---

## 4. Database

Sembilan tabel, tanpa auth — identifikasi cukup `device_id` anonim yang
di-generate aplikasi. Tidak ada satu pun layar di peta alur yang menuntut
login, jadi menambahkan akun berarti memaksa layar yang tidak dirancang.

| Tabel | Isi |
|---|---|
| `risk_zones` | Lokasi yang sering dilaporkan ada hambatan |
| `object_labels` | Kamus label → Bahasa Indonesia, tinggi nyata, kelas bahaya |
| `voice_intents` + `intent_phrases` | 20 intent + varian ucapan |
| `model_manifest` | Versi model on-device |
| `telemetry_events` | Telemetri alur |
| `crash_reports` | Laporan crash |
| `upload_queue` | Antrean unggah offline (idempoten) |
| `assistant_sessions` + `assistant_turns` | Riwayat percakapan |
| `money_denominations` | Denominasi + kata terbilang + urutan kelas model |
| `capability_overrides` | Paksa status kemampuan untuk demo/maintenance |

`risk_zones` dulu `dict` in-memory yang hilang tiap restart — artinya zona
bahaya tidak pernah benar-benar terbentuk. Sekarang persisten, dan jarak
haversine dihitung langsung di SQL.

---

## 5. Yang belum selesai / catatan jujur

1. **Model PIDNet-S belum ada.** Navigasi memakai fallback heuristik.
   Heuristik membaca gambar sungguhan dan cukup untuk menguji seluruh
   state NV-03..NV-09, tapi akurasinya di bawah model terlatih. Taruh
   `models/pidnet_s_3zona.onnx` untuk mengaktifkan jalur model.

2. **Model uang di server tidak ada, dan itu disengaja.** Jalur utama
   on-device. Endpoint `/api/uang` balas `model_unavailable` — tidak
   menebak.

3. **Model uang on-device hanya 6 kelas emisi 2016.** Rp1.000 tidak
   dikenali. Untuk emisi 2022 dan Rp1.000, model perlu dilatih ulang;
   kontrak API dan tabel denominasi sudah siap menampungnya.

4. **`ANTHROPIC_API_KEY` tersimpan plaintext di `.env`.** Sudah masuk
   `.gitignore`, tapi sebaiknya dirotasi sebelum repo dibagikan.

5. **Bobot model besar tidak di-commit** (`mobileclip_blt.ts`,
   `yoloe-11s-seg.pt`, `*.pt`, `*.onnx`). Ultralytics mengunduhnya otomatis
   saat pertama dipakai.

---

## 6. Uji cepat

```bash
B=http://localhost:8000

curl -s $B/health
curl -s $B/api/capabilities
curl -s "$B/api/labels?lang=id"

# Perintah suara ambigu — harus menanyakan balik, bukan menebak
curl -s -X POST $B/api/intent -H 'Content-Type: application/json' \
     -d '{"text":"kenal kunci"}'

# Cari objek (pemanggilan pertama memuat YOLOE, ~2 detik)
curl -s -X POST $B/api/cari-objek -F "target=dompet" -F "file=@foto.jpg"

# Navigasi 3 zona
curl -s -X POST $B/api/navigasi -F "file=@foto.jpg" -F "lat=0" -F "lng=0"
```
