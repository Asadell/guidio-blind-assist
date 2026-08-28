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


class FindObjectService:
    """Pencarian objek berdasarkan prompt teks bebas.

    Model dimuat malas (lazy) saat permintaan pertama: bobot YOLOE + encoder
    teks MobileCLIP berukuran ratusan MB, tidak pantas menahan startup server
    padahal mode ini jarang dipakai dibanding Deteksi Objek.
    """

    def __init__(self, model_path: str | None = None, conf: float = 0.25):
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
        label_map: dict[str, str],
        client_prompt_en: str | None = None,
    ) -> str:
        """Ubah nama barang Bahasa Indonesia (beserta warna/kata sifat) jadi prompt Inggris untuk YOLOE.

        `label_map` = {label_local: label_en} dari tabel object_labels.

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

        # Direct match in EXTRA_ID_TO_EN or DB label_map
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
            if self._active_prompts != [prompt_en]:
                self.model.set_classes([prompt_en], self.model.get_text_pe([prompt_en]))
                self._active_prompts = [prompt_en]

            results = self.model.predict(
                frame, conf=conf or self.conf, verbose=False
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
                    "inference_ms": round(inference_ms, 1),
                }

            matches = []
            for box in boxes:
                x1, y1, x2, y2 = (int(v) for v in box.xyxy[0].tolist())
                box_h = max(y2 - y1, 1)
                dist = self._estimate_distance(prompt_en, box_h, w)
                matches.append({
                    "confidence": round(float(box.conf[0]), 3),
                    "distance_meter": round(dist, 2),
                    "direction": self._direction((x1 + x2) / 2, w),
                    "vertical": self._vertical((y1 + y2) / 2, h),
                    "bbox": {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                })

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
