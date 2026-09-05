"""Mode Cari Objek - YOLOE open-vocabulary (prompt teks).

Kenapa YOLOE dan bukan YOLO closed-set biasa: target pencarian datang dari
ucapan pengguna ("cari dompet", "cari tas merah"), jadi kelasnya tidak bisa
ditentukan saat training. YOLOE menerima prompt teks bebas dan modul
open-vocabulary-nya di-reparameterisasi ke arsitektur YOLO standar saat
inference, jadi kecepatannya setara YOLO closed-set.

Sifatnya trigger-based (sekali per perintah suara), bukan stream kontinu,
jadi beban server dan baterai jauh lebih ringan daripada Mode Navigasi.
"""

import os
import time

import numpy as np
from loguru import logger

from services.find_object_constants import (
    COLOR_MAP,
    EXTRA_HEIGHTS_CM,
    EXTRA_ID_TO_EN,
    FILLER_WORDS,
    SEARCH_PREFIXES,
)

# Panjang fokus dalam pixel, BERLAKU PADA LEBAR FRAME REFERENSI di bawahnya.
# Nilai ini bukan konstanta bebas resolusi: 615 px pada frame 640 px lebar
# setara FOV horizontal sekitar 55 derajat. Kalau frame yang masuk lebih lebar
# atau lebih sempit, panjang fokus efektifnya ikut berskala.
FOCAL_LENGTH_PX = 615
REFERENCE_WIDTH_PX = 640
DEFAULT_HEIGHT_CM = 20

# Resolusi inferensi YOLOE.
#
# Ultralytics memakai 640 kalau `imgsz` tidak disebut - dan itu yang terjadi
# selama ini, sementara routernya sudah menyiapkan frame 1280 px lewat
# `enhance_for_vision(max_side=1280)`. Separuh pixel yang diunggah pengguna
# dibuang tepat sebelum inferensi.
#
# Angka 960 dipilih dari pengukuran, TAPI selisihnya kecil dan tidak
# konsisten. Rata-rata skor tertinggi pada lima fixture:
#
#     imgsz=640 -> 0.171    imgsz=1280 -> 0.181
#     imgsz=960 -> 0.206    imgsz=1600 -> 0.185
#
# Per objek arahnya bahkan berlawanan: botol naik terus sampai 1600,
# headphone justru anjlok dari 0.384 di 960 jadi 0.058 di 1280. Lima sampel
# terlalu sedikit untuk menyebut ini penyetelan. Yang bisa dikatakan jujur:
# 640 bukan pilihan yang disengaja, ia cuma nilai bawaan yang tidak pernah
# ditulis - dan menuliskannya membuat perubahan berikutnya bisa diukur.
INFERENCE_IMGSZ = 960

# Kelipatan stride YOLO. `imgsz` yang bukan kelipatan 32 dibulatkan diam-diam
# oleh ultralytics; membulatkannya sendiri membuat ukuran yang dipakai sama
# dengan yang dicatat di log.
_STRIDE = 32

# ── Penyatuan deteksi ──────────────────────────────────────────────────────
#
# MASALAHNYA. Dengan `conf=0.001`, satu benda menghasilkan BANYAK kotak, bukan
# satu. Diukur pada fixture di `test/object_find/`, yang tiap fotonya cuma
# berisi SATU benda sasaran:
#
#     tas merah      -> 16 kotak      headphone      -> 19 kotak
#     kunci motor    ->  6 kotak      payung kuning  ->  7 kotak
#     botol minum    -> 63 kotak
#
# Kotak-kotak itu bukan benda lain. Mereka menempel pada bagian-bagian benda
# yang sama - tali tas, kantung depan, gagang, zipper - dan NMS bawaan tidak
# membuangnya karena IoU-nya rendah: kotak kecil di dalam kotak besar hanya
# menutupi sedikit bagian dari yang besar.
#
# KENAPA INI BUKAN SEKADAR ANGKA JELEK. Jumlah itu DIBACAKAN ke pengguna:
# "Ada 16 tas merah". Untuk orang yang tidak bisa memeriksa dengan mata,
# kalimat itu bukan pembulatan yang meleset, melainkan keterangan palsu tentang
# ruangan di depannya - dan satu-satunya sumber informasinya adalah kalimat
# tersebut. Menyebut satu tas sebagai enam belas tas lebih buruk daripada tidak
# menyebut jumlah sama sekali.
#
# CARA MENGUKUR TUMPANG TINDIH. Bukan IoU, melainkan irisan dibagi luas kotak
# yang LEBIH KECIL. Kotak "gagang tas" yang sepenuhnya berada di dalam kotak
# "tas" punya IoU kecil (karena penyebutnya luas gabungan), tapi nilai ini
# mendekati 1. Itulah bentuk tumpang tindih yang sebenarnya terjadi di sini.
CONTAINMENT_RATIO = 0.55

# Kotak digabung, BUKAN dibuang, dan gabungannya memakai kotak terluas.
#
# Kalau yang dipertahankan adalah kotak dengan keyakinan tertinggi, jaraknya
# jadi salah: pada `test_01`, kotak berkeyakinan tertinggi (0.047) hanya
# membungkus bagian tengah tas, sedangkan kotak yang membungkus tas utuh
# keyakinannya 0.014. Jarak dihitung dari TINGGI kotak, jadi memilih yang
# tengah membuat tas terdengar lebih jauh daripada yang sebenarnya - dan
# instruksi "ulurkan tangan" ikut salah.
#
# Keyakinan yang dilaporkan tetap yang TERTINGGI di dalam kelompok: itu ukuran
# seberapa yakin model bahwa bendanya ada, dan itu tidak berkurang hanya karena
# kotaknya diperlebar.

# Ambang keyakinan RELATIF terhadap deteksi terbaik di frame yang sama.
#
# Ambang mutlak tidak bisa dipakai di sini, dan itu bukan pilihan gaya:
# keyakinan YOLOE zero-shot berbeda dua kali lipat ORDE antar benda pada frame
# yang sama-sama bagus - botol 0.591, kunci 0.019. Ambang mutlak yang cukup
# tinggi untuk membersihkan botol akan menghapus kunci sepenuhnya, dan itu
# persis kesalahan `YOLOE_CONF=0.25` yang dulu sudah diperbaiki.
#
# Ambang relatif menghindari jebakan itu. Ia bertanya "seberapa lemah deteksi
# ini DIBANDINGKAN yang terbaik di foto yang sama", pertanyaan yang jawabannya
# tidak bergantung pada jenis bendanya.
RELATIVE_CONF_FLOOR = 0.25

# Ambang MUTLAK untuk berani bilang "ketemu".
#
# Berbeda peran dari `YOLOE_CONF`. `YOLOE_CONF=0.001` mengatur kotak mana yang
# BOLEH dihitung; angka di sini mengatur apakah hasilnya layak DILAPORKAN
# sebagai temuan. Keduanya sengaja dipisah: menaikkan `YOLOE_CONF` membuang
# kotak lemah milik benda yang benar-benar ada, sedangkan pemisahan ini
# membiarkan kotak itu tetap terbentuk lalu menilai kekuatannya di akhir.
#
# Kenapa perlu. Kata Bahasa Indonesia yang lolos ke encoder teks berbahasa
# Inggris menghasilkan embedding tanpa makna, dan embedding tanpa makna tetap
# mencocoki SESUATU. Diukur pada foto dapur yang sama:
#
#     prompt "pesawat"  -> 4 kotak, conf 0.001-0.002, found=True   (salah)
#     prompt "airplane" -> 0 kotak,                   found=False  (benar)
#
# Jadi laporan "ketemu" yang palsu itu bukan kesalahan model. Modelnya benar;
# yang dikirim ke sana yang bukan Bahasa Inggris.
#
# Kenapa 0.01. Jaraknya lebar di kedua sisi, diukur pada lima fixture:
#
#     deteksi BENAR terendah  : 0.019  (kunci motor)
#     deteksi PALSU tertinggi : 0.002  (prompt "pesawat")
#
# Nilai ini duduk di tengah, kira-kira 2x di atas yang palsu dan 2x di bawah
# yang benar. Lima fixture jelas bukan dasar yang kuat untuk menyetel angka,
# jadi ia bisa diubah lewat `YOLOE_MIN_REPORT_CONF` tanpa menyentuh kode -
# dan angka di sini adalah titik awal yang bisa diukur, bukan hasil akhir.
MIN_REPORT_CONF = float(os.getenv("YOLOE_MIN_REPORT_CONF", "0.01"))


class FindObjectService:
    """Pencarian objek berdasarkan prompt teks bebas.

    Model dimuat malas (lazy) saat permintaan pertama: bobot YOLOE + encoder
    teks MobileCLIP berukuran ratusan MB, tidak pantas menahan startup server
    padahal mode ini jarang dipakai dibanding Deteksi Objek.
    """

    # Ambang keyakinan bawaan.
    #
    # !! PERHATIAN: nilai ini akan di-OVERRIDE oleh env var YOLOE_CONF di .env !!
    # Jika ingin mengubah threshold, ubah YOLOE_CONF di file .env, BUKAN di sini.
    # Mengubah angka di sini tidak ada efeknya selama YOLOE_CONF ada di .env.
    #
    # Kenapa nilainya sangat kecil (0.001)?
    # YOLOE zero-shot (MobileCLIP) menghasilkan skor jauh lebih kecil dari YOLO
    # closed-set. Diukur pada foto kamera HP nyata (imgsz 960):
    #
    #   kunci motor (keychain)  0.026   <- benda kecil di atas meja
    #   kunci (key)             0.007
    #   kacamata (glasses)      0.003   <- lensa bening/transparan
    #   botol (bottle)          0.920   <- besar & berkontras tinggi
    #
    # Dengan threshold 0.25 (nilai .env lama), kunci dan kacamata tidak pernah
    # ditemukan meskipun jelas ada di depan kamera. 0.001 membiarkan semua
    # deteksi valid lolos tanpa terlalu banyak false positive.
    DEFAULT_CONF = 0.001

    def __init__(self, model_path: str | None = None,
                 conf: float = DEFAULT_CONF):
        self.model_path = model_path or os.getenv("YOLOE_MODEL", "yoloe-11s-seg.pt")
        self.conf = float(os.getenv("YOLOE_CONF", conf))
        self.model = None
        self.loaded = False
        self.load_error: str | None = None
        self._active_prompts: list[str] = []

    # ── Pemuatan model ───────────────────────────────────────────────────

    def ensure_loaded(self) -> bool:
        if self.loaded:
            return True
        if self.load_error:
            return False
        try:
            from ultralytics import YOLOE

            t0 = time.time()
            logger.info(f"Memuat YOLOE '{self.model_path}' (sekali saja, agak lama)...")
            self.model = YOLOE(self.model_path)
            self.loaded = True
            logger.success(f"YOLOE siap dalam {time.time() - t0:.1f}s")
            return True
        except Exception as e:
            self.load_error = str(e)
            logger.error(f"YOLOE gagal dimuat: {e}")
            return False

    # ── Terjemahan target ────────────────────────────────────────────────

    def resolve_prompt(
        self,
        target_id: str,
        label_map: dict[str, str] | None = None,
        client_prompt_en: str | None = None,
    ) -> str:
        """Ubah nama barang Bahasa Indonesia (beserta warna/kata sifat) jadi prompt Inggris untuk YOLOE.

        `label_map` = {nama_id: nama_en} tambahan dari pemanggil. Dulu diisi
        dari tabel `object_labels` di PostgreSQL; database itu sudah dihapus
        dan tidak ada pemanggil yang mengisinya lagi, jadi nilainya opsional.
        Parameternya dipertahankan sebagai titik sisip kalau suatu saat ada
        kamus tambahan dari luar - bukan sebagai jalur yang masih hidup.

        `client_prompt_en` adalah terjemahan ML Kit on-device dari aplikasi
        ("tas merah" -> "red bag"). Nilainya dipakai sebagai LAPIS TENGAH,
        bukan pengganti kamus:

          1. Kamus kurasi (EXTRA_ID_TO_EN / label_map) - menang duluan.
             Isinya dipilih supaya cocok dengan nama kelas yang dikenal
             encoder teks YOLOE. "hape" -> "cell phone", bukan "cellphone";
             "gawai" -> "cell phone", bukan "gadget". Penerjemah umum tidak
             tahu batasan itu dan tidak seharusnya menebaknya.

          2. Terjemahan ML Kit - untuk yang TIDAK ada di kamus. Di sinilah
             janji open-vocabulary YOLOE baru benar-benar ditepati: "termos",
             "spatula", "cobek" tidak akan pernah muat di kamus buatan tangan,
             tapi ketiganya punya terjemahan Inggris yang wajar.

          3. Tebakan substring, lalu frasa Indonesianya apa adanya.

        Urutan 1-2 itu yang penting. Sebelum ada lapis 2, kata di luar kamus
        jatuh ke lapis 3 dan berakhir sebagai prompt Bahasa INDONESIA yang
        dikirim ke encoder teks berbahasa Inggris. Itu bukan pencarian yang
        kurang akurat, melainkan pencarian yang tidak pernah punya peluang -
        dan pengguna cuma mendengar "tidak ketemu", tanpa satu pun petunjuk
        bahwa yang salah adalah promptnya, bukan barangnya.
        """
        label_map = label_map or {}
        raw_key = target_id.strip().lower()

        # Clean search prefixes & filler words if passed directly to backend
        key = raw_key
        sorted_prefixes = sorted(SEARCH_PREFIXES, key=len, reverse=True)
        for pref in sorted_prefixes:
            if key.startswith(pref + " ") or key == pref:
                key = key[len(pref):].strip()
                break
            elif " " + pref + " " in key:
                key = key.replace(" " + pref + " ", " ").strip()

        sorted_fillers = sorted(FILLER_WORDS, key=len, reverse=True)
        for filler in sorted_fillers:
            if key.startswith(filler + " "):
                key = key[len(filler):].strip()
            if key.endswith(" " + filler):
                key = key[:-len(filler)].strip()
            key = key.replace(f" {filler} ", " ").strip()

        if not key:
            key = raw_key

        # Direct match in EXTRA_ID_TO_EN atau label_map dari pemanggil
        if key in EXTRA_ID_TO_EN:
            return EXTRA_ID_TO_EN[key]
        if key in label_map:
            return label_map[key]

        # Clean filler words like "warna"
        cleaned_key = key.replace(" warna ", " ").replace(" warna", "").strip()

        # Check for color/modifier in COLOR_MAP
        found_color_en = None
        obj_phrase = cleaned_key

        sorted_colors = sorted(COLOR_MAP.keys(), key=len, reverse=True)
        for col_id in sorted_colors:
            if col_id in cleaned_key:
                found_color_en = COLOR_MAP[col_id]
                obj_phrase = cleaned_key.replace(col_id, "").strip()
                break

        # Resolve the object part
        obj_en = None
        if obj_phrase in EXTRA_ID_TO_EN:
            obj_en = EXTRA_ID_TO_EN[obj_phrase]
        elif obj_phrase in label_map:
            obj_en = label_map[obj_phrase]
        else:
            # Kamus tidak kenal bendanya. Terjemahan ML Kit dipakai UTUH di
            # sini, bukan disambung dengan `found_color_en` di bawah: yang
            # diterjemahkan aplikasi adalah frasa lengkapnya ("tas merah" ->
            # "red bag"), jadi warnanya sudah ada di dalamnya. Menyambungnya
            # lagi menghasilkan "red red bag".
            if client_prompt_en:
                return client_prompt_en

            sorted_extra = sorted(EXTRA_ID_TO_EN.keys(), key=len, reverse=True)
            for id_word in sorted_extra:
                if id_word in obj_phrase:
                    obj_en = EXTRA_ID_TO_EN[id_word]
                    break
            if not obj_en:
                sorted_labels = sorted(label_map.keys(), key=len, reverse=True)
                for local in sorted_labels:
                    if local in obj_phrase:
                        obj_en = label_map[local]
                        break

        if not obj_en:
            # Lapis terakhir. `obj_phrase` di sini masih Bahasa Indonesia dan
            # praktis tidak akan cocok dengan apa pun - dipertahankan hanya
            # supaya fungsi ini selalu mengembalikan sesuatu.
            obj_en = client_prompt_en or (obj_phrase if obj_phrase else key)

        if found_color_en:
            return f"{found_color_en} {obj_en}".strip()
        return obj_en

    # ── Varian prompt ────────────────────────────────────────────────────

    @staticmethod
    def prompt_variants(prompt_en: str) -> list[str]:
        """Frasa lengkap PLUS kata bendanya saja.

        Encoder teks YOLOE (MobileCLIP) jauh lebih kuat pada nama kelas
        pendek daripada frasa deskriptif, dan selisihnya besar. Diukur pada
        fixture yang sama, imgsz 1280:

            "bottle"          -> 0.504
            "drinking bottle" -> 0.328
            "bottle of water" -> 0.206
            "plastic bottle"  -> 0.167
            "water bottle"    -> 0.084

        Enam kali lipat antara ujung terbaik dan terburuk, untuk botol yang
        sama di foto yang sama. Dan "water bottle" - yang terburuk - persis
        yang dihasilkan kamus kurasi untuk "botol minum".

        Jadi kata bendanya dikirim SEBAGAI KELAS TAMBAHAN, bukan sebagai
        pengganti. Kepala YOLOE bersifat kontrastif: menambah kelas tidak
        menurunkan skor kelas lain, ia cuma menambah kemungkinan salah satu
        mengenali. Diverifikasi - `["water bottle", "bottle"]` mengembalikan
        0.504 yang sama dengan `["bottle"]` sendirian.

        Sifat warna sengaja TIDAK dibuang di sini. "red bag" yang gagal lalu
        ditolong "bag" tetap menemukan tasnya; membuang warnanya sejak awal
        berarti melaporkan tas siapa pun sebagai tas merah yang dicari.
        """
        phrase = " ".join(prompt_en.lower().split())
        if not phrase:
            return []

        variants = [phrase]
        head = phrase.rsplit(" ", 1)[-1]
        if head and head != phrase:
            variants.append(head)
        return variants

    # ── Penyatuan deteksi ────────────────────────────────────────────────

    @staticmethod
    def _containment(a: dict, b: dict) -> float:
        """Luas irisan dibagi luas kotak yang lebih kecil.

        Lihat catatan di [CONTAINMENT_RATIO] soal kenapa bukan IoU.
        """
        ix1 = max(a["x1"], b["x1"])
        iy1 = max(a["y1"], b["y1"])
        ix2 = min(a["x2"], b["x2"])
        iy2 = min(a["y2"], b["y2"])
        iw = ix2 - ix1
        ih = iy2 - iy1
        if iw <= 0 or ih <= 0:
            return 0.0

        area_a = max(1, (a["x2"] - a["x1"]) * (a["y2"] - a["y1"]))
        area_b = max(1, (b["x2"] - b["x1"]) * (b["y2"] - b["y1"]))
        return (iw * ih) / min(area_a, area_b)

    @classmethod
    def merge_detections(cls, raw: list[dict]) -> list[dict]:
        """Satukan kotak yang menempel pada benda yang sama.

        Dua langkah, dan urutannya penting:

        1. Buang deteksi yang terlalu lemah DIBANDINGKAN yang terbaik di frame
           ini (lihat [RELATIVE_CONF_FLOOR]). Dilakukan lebih dulu supaya
           kotak sampah tidak ikut memperlebar kotak gabungan di langkah dua.

        2. Kelompokkan sisanya berdasarkan tumpang tindih, lalu wakili tiap
           kelompok dengan kotak GABUNGAN dan keyakinan TERTINGGI di dalamnya.

        Kotaknya diurutkan dari yang terluas supaya kotak induk yang membentuk
        kelompok, bukan potongan kecil yang kebetulan lebih yakin. Penyerapan
        bersifat transitif dalam satu lintasan: begitu sebuah kotak masuk
        kelompok, kotak gabungannya melebar, dan potongan berikutnya diukur
        terhadap gabungan yang sudah melebar itu.
        """
        if not raw:
            return []

        top = max(d["confidence"] for d in raw)
        floor = top * RELATIVE_CONF_FLOOR
        kept = [d for d in raw if d["confidence"] >= floor]
        if not kept:
            kept = [max(raw, key=lambda d: d["confidence"])]

        def area(d: dict) -> int:
            b = d["bbox"]
            return max(1, (b["x2"] - b["x1"]) * (b["y2"] - b["y1"]))

        kept.sort(key=area, reverse=True)

        groups: list[dict] = []
        for det in kept:
            for g in groups:
                if cls._containment(g["bbox"], det["bbox"]) >= CONTAINMENT_RATIO:
                    gb, db = g["bbox"], det["bbox"]
                    gb["x1"] = min(gb["x1"], db["x1"])
                    gb["y1"] = min(gb["y1"], db["y1"])
                    gb["x2"] = max(gb["x2"], db["x2"])
                    gb["y2"] = max(gb["y2"], db["y2"])
                    g["confidence"] = max(g["confidence"], det["confidence"])
                    g["merged_from"] += 1
                    break
            else:
                det["merged_from"] = 1
                groups.append(det)

        return groups

    # ── Inferensi ────────────────────────────────────────────────────────

    def find(
        self,
        frame: np.ndarray,
        prompt_en: str,
        target_id: str,
        conf: float | None = None,
    ) -> dict:
        """Cari satu jenis objek di frame. Selalu balas dict, tidak pernah lempar.

        Bentuk balasan sengaja mengikuti state CO-06 / CO-07 / CO-10:
        - found=False        → CO-10 (tidak ketemu di frame), app menyuruh putar badan
        - found=True, n=1    → CO-06 (arah + jarak)
        - found=True, n>1    → CO-07 (yang terdekat disebut, sisanya dihitung)
        """
        if not self.ensure_loaded():
            return {
                "found": False,
                "reason": "model_unavailable",
                "message": "Pencarian objek sedang tidak bisa dipakai. Bukan karena kameramu.",
                "matches": [],
                "total_match": 0,
            }

        try:
            t0 = time.time()
            prompts = self.prompt_variants(prompt_en)
            if self._active_prompts != prompts:
                self.model.set_classes(prompts, self.model.get_text_pe(prompts))
                self._active_prompts = prompts

            # `imgsz` disebut EKSPLISIT. Tanpa ini ultralytics memakai 640 dan
            # mengecilkan lagi frame 1280 px yang baru saja disiapkan router -
            # lihat catatan di [INFERENCE_IMGSZ].
            # TIDAK dibatasi ukuran frame aslinya, dan itu disengaja.
            # `imgsz` adalah ukuran letterbox yang dilihat model, bukan
            # sekadar batas atas: frame kecil yang diperbesar ke 1280 justru
            # yang paling terbantu, karena barang kecil butuh lebih banyak
            # pixel di jaring inferensi. Diukur pada frame 270x480 yang sama:
            # imgsz=480 -> 0.234, imgsz=1280 -> 0.504.
            imgsz = int(round(INFERENCE_IMGSZ / _STRIDE)) * _STRIDE

            # `agnostic_nms=True` menyatukan kotak LINTAS kelas.
            #
            # Prompt dikirim sebagai beberapa kelas sekaligus - `["red bag",
            # "bag"]` - dan NMS bawaan bekerja per kelas. Tas yang sama
            # dikenali oleh kedua kelas itu lolos sebagai DUA kotak, lalu
            # dihitung sebagai dua tas. Yang dicari pengguna cuma satu benda,
            # jadi kelasnya tidak boleh memisahkan hitungannya.
            results = self.model.predict(
                frame,
                conf=conf or self.conf,
                imgsz=imgsz,
                agnostic_nms=True,
                verbose=False,
            )
            inference_ms = (time.time() - t0) * 1000

            h, w = frame.shape[:2]
            boxes = results[0].boxes
            if boxes is None or len(boxes) == 0:
                return {
                    "found": False,
                    "reason": "not_in_frame",
                    "message": f"{target_id} belum terlihat. Coba putar badan pelan-pelan.",
                    "matches": [],
                    "total_match": 0,
                    "prompt_en": prompt_en,
                    "prompt_variants": prompts,
                    "imgsz": imgsz,
                    "inference_ms": round(inference_ms, 1),
                }

            raw = []
            for box in boxes:
                x1, y1, x2, y2 = (int(v) for v in box.xyxy[0].tolist())
                raw.append({
                    "confidence": round(float(box.conf[0]), 3),
                    "bbox": {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                })

            # Kotak disatukan SEBELUM jarak dihitung, bukan sesudah. Jarak
            # diturunkan dari tinggi kotak, dan tinggi kotak baru benar
            # setelah potongan-potongan benda yang sama digabung jadi satu.
            merged = self.merge_detections(raw)

            matches = []
            for det in merged:
                b = det["bbox"]
                box_h = max(b["y2"] - b["y1"], 1)
                dist = self._estimate_distance(prompt_en, box_h, w)
                matches.append({
                    "confidence": det["confidence"],
                    "distance_meter": round(dist, 2),
                    "direction": self._direction((b["x1"] + b["x2"]) / 2, w),
                    "vertical": self._vertical((b["y1"] + b["y2"]) / 2, h),
                    "bbox": b,
                    "merged_from": det.get("merged_from", 1),
                })

            # Semua kotak terlalu lemah untuk dipercaya. Jawabannya SAMA
            # dengan tidak ada kotak sama sekali - "belum terlihat, coba putar
            # badan" - karena bagi pengguna kedua keadaan itu memang sama:
            # bendanya tidak ada di depannya. Melaporkan tebakan 0.002 sebagai
            # temuan justru menyuruh dia mengulurkan tangan ke tempat kosong.
            best = max(m["confidence"] for m in matches)
            if best < MIN_REPORT_CONF:
                return {
                    "found": False,
                    "reason": "not_in_frame",
                    "message": f"{target_id} belum terlihat. Coba putar badan pelan-pelan.",
                    "matches": [],
                    "total_match": 0,
                    "prompt_en": prompt_en,
                    "prompt_variants": prompts,
                    "imgsz": imgsz,
                    "best_conf": best,
                    "inference_ms": round(inference_ms, 1),
                }

            matches.sort(key=lambda m: m["distance_meter"])
            nearest = matches[0]

            return {
                "found": True,
                "reason": "ok",
                "message": self._compose_message(target_id, nearest, len(matches)),
                "matches": matches,
                "total_match": len(matches),
                "nearest": nearest,
                "prompt_en": prompt_en,
                "prompt_variants": prompts,
                "imgsz": imgsz,
                "inference_ms": round(inference_ms, 1),
            }

        except Exception as e:
            logger.error(f"Cari objek gagal: {e}")
            return {
                "found": False,
                "reason": "server_error",
                "message": "Bukan karena kameramu, pencarian sedang bermasalah. Coba lagi.",
                "matches": [],
                "total_match": 0,
                "error": str(e),
            }

    # ── Penyusun naskah suara ────────────────────────────────────────────

    def _compose_message(self, target_id: str, nearest: dict, total: int) -> str:
        """Naskah CO-06 / CO-07 / CO-08 - instruksi fisik dan konkret."""
        dist = nearest["distance_meter"]
        arah = nearest["direction"]

        if dist < 0.6:
            jarak_kata = "setengah meter, ulurkan tangan"
        elif dist < 1.2:
            jarak_kata = "sekitar satu meter"
        elif dist < 2.5:
            jarak_kata = "sekitar dua meter"
        else:
            jarak_kata = f"sekitar {dist:.0f} meter"

        if total > 1:
            return (
                f"Ada {total} {target_id}. Yang terdekat di {arah}, {jarak_kata}."
            )
        return f"{target_id} di {arah}, {jarak_kata}."

    # ── Geometri ─────────────────────────────────────────────────────────

    def _estimate_distance(self, prompt_en: str, box_h: int,
                           frame_w: int = REFERENCE_WIDTH_PX) -> float:
        """Perkirakan jarak dari tinggi kotak deteksi, dinormalisasi resolusi.

        Tinggi kotak dalam pixel berskala dengan resolusi frame, sedangkan
        `FOCAL_LENGTH_PX` cuma berlaku pada lebar frame referensi. Tanpa
        penskalaan, foto yang sama pada resolusi berbeda menghasilkan jarak
        yang berbeda: frame yang dikecilkan setengah membuat semua benda
        terdengar dua kali lebih jauh.

        Ini penting sejak router mengecilkan frame lewat `enhance_for_vision`,
        tapi sebenarnya sudah salah sejak dulu - HP dengan resolusi kamera
        berbeda mengirim frame dengan lebar berbeda ke endpoint yang sama.
        """
        real_h = EXTRA_HEIGHTS_CM.get(prompt_en, DEFAULT_HEIGHT_CM)
        for key, val in EXTRA_HEIGHTS_CM.items():
            if key in prompt_en:
                real_h = val
                break
        focal = FOCAL_LENGTH_PX * (max(1, frame_w) / REFERENCE_WIDTH_PX)
        return (real_h * focal) / (max(1, box_h) * 100)

    def _direction(self, cx: float, w: int) -> str:
        third = w / 3
        if cx < third:
            return "kiri"
        if cx < third * 2:
            return "depan"
        return "kanan"

    def _vertical(self, cy: float, h: int) -> str:
        third = h / 3
        if cy < third:
            return "atas"
        if cy < third * 2:
            return "tengah"
        return "bawah"
