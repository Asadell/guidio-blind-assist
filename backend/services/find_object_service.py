"""Mode Cari Objek — YOLOE open-vocabulary (prompt teks).

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

# Terjemahan target Bahasa Indonesia → prompt Inggris untuk YOLOE.
# COCO sudah tercakup lewat tabel object_labels; peta di sini melengkapi
# barang rumah tangga umum yang TIDAK ada di COCO tapi sering dicari.
EXTRA_ID_TO_EN: dict[str, str] = {
    "dompet": "wallet",
    "kunci": "keys",
    "kunci motor": "motorcycle keys",
    "kunci rumah": "house keys",
    "hp": "cell phone",
    "handphone": "cell phone",
    "kacamata": "eyeglasses",
    "botol minum": "water bottle",
    "botol air": "water bottle",
    "tas": "bag",
    "tas ransel": "backpack",
    "remote tv": "tv remote control",
    "sepatu": "shoes",
    "sandal": "sandals",
    "charger": "phone charger",
    "kabel charger": "charging cable",
    "headset": "headphones",
    "earphone": "earphones",
    "jaket": "jacket",
    "topi": "hat",
    "obat": "medicine box",
    "masker": "face mask",
    "jam tangan": "wristwatch",
    "power bank": "power bank",
    "korek": "lighter",
    "sisir": "comb",
    "handuk": "towel",
    "bantal": "pillow",
    "selimut": "blanket",
    "piring": "plate",
    "panci": "cooking pot",
    "wajan": "frying pan",
    "payung lipat": "folding umbrella",
    "tongkat": "walking cane",
    "uang": "banknote",
    "kartu": "plastic card",
    "kotak": "box",
    "tempat sampah": "trash bin",
    "saklar": "light switch",
    "stop kontak": "power outlet",
    "pintu": "door",
    "gagang pintu": "door handle",
    "meja": "table",
    "kursi": "chair",
}

# Tinggi nyata (cm) untuk estimasi jarak similar-triangle pada objek non-COCO.
EXTRA_HEIGHTS_CM: dict[str, int] = {
    "wallet": 10, "keys": 7, "eyeglasses": 4, "water bottle": 25,
    "bag": 35, "backpack": 45, "tv remote control": 18, "shoes": 12,
    "sandals": 5, "phone charger": 8, "charging cable": 10,
    "headphones": 18, "earphones": 5, "jacket": 60, "hat": 12,
    "medicine box": 10, "face mask": 10, "wristwatch": 4,
    "power bank": 10, "lighter": 8, "comb": 18, "towel": 40,
    "pillow": 35, "blanket": 40, "plate": 3, "cooking pot": 20,
    "frying pan": 8, "folding umbrella": 30, "walking cane": 95,
    "banknote": 7, "plastic card": 5, "box": 25, "trash bin": 60,
    "light switch": 8, "power outlet": 8, "door": 200,
    "door handle": 12, "table": 75, "motorcycle keys": 7, "house keys": 7,
}

FOCAL_LENGTH_PX = 615
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

    def resolve_prompt(self, target_id: str, label_map: dict[str, str]) -> str:
        """Ubah nama barang Bahasa Indonesia jadi prompt Inggris untuk YOLOE.

        `label_map` = {label_local: label_en} dari tabel object_labels.
        Kalau tidak ketemu di mana pun, teks aslinya dipakai apa adanya —
        YOLOE open-vocabulary, jadi tetap ada peluang ketemu.
        """
        key = target_id.strip().lower()
        if key in EXTRA_ID_TO_EN:
            return EXTRA_ID_TO_EN[key]
        if key in label_map:
            return label_map[key]
        # Coba pencocokan sebagian: "tas merah" → "tas"
        for id_word, en_word in EXTRA_ID_TO_EN.items():
            if key.startswith(id_word + " ") or key.endswith(" " + id_word):
                sisa = key.replace(id_word, "").strip()
                return f"{sisa} {en_word}".strip()
        for local, en in label_map.items():
            if key.startswith(local + " ") or key.endswith(" " + local):
                sisa = key.replace(local, "").strip()
                return f"{sisa} {en}".strip()
        return key

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
                dist = self._estimate_distance(prompt_en, box_h)
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
        """Naskah CO-06 / CO-07 / CO-08 — instruksi fisik dan konkret."""
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

    def _estimate_distance(self, prompt_en: str, box_h: int) -> float:
        real_h = EXTRA_HEIGHTS_CM.get(prompt_en, DEFAULT_HEIGHT_CM)
        for key, val in EXTRA_HEIGHTS_CM.items():
            if key in prompt_en:
                real_h = val
                break
        return (real_h * FOCAL_LENGTH_PX) / (box_h * 100)

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
