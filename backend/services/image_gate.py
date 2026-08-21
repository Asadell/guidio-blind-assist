"""
services/image_gate.py  (BARU)
==============================
Gerbang kualitas gambar bersama untuk semua endpoint.

KENAPA DIPISAH JADI MODUL SENDIRI
---------------------------------
Endpoint yang menerima foto dari HP sama-sama perlu memutuskan "layak
diproses atau tidak". Kalau logikanya ditulis ulang di tiap router, tiga
hal terjadi:

  1. Ambangnya pelan-pelan menyimpang satu sama lain
  2. Pesan ke pengguna jadi tidak konsisten ("gambar buram" di satu
     tempat, "foto kurang jelas" di tempat lain untuk kondisi yang sama)
  3. Saat kamu mengkalibrasi ulang ambang, kamu harus ingat mengubah
     tiga tempat

Modul ini memusatkan keputusan itu, tapi tetap membiarkan tiap endpoint
punya tingkat ketegasan berbeda, karena kebutuhannya memang berbeda:

  Cari objek  -> sedang. Kalau gagal, aplikasi memang sudah dirancang
                 menyuruh pengguna memutar badan lalu memanggil ulang,
                 jadi kegagalan sesekali sudah tertangani alurnya.

  Describe    -> paling longgar. Deskripsi suasana yang agak kabur masih
                 memberi nilai ("sepertinya ada meja dan beberapa kursi").
                 Menolak terlalu sering justru bikin fitur ini terasa rewel.

Profil "ocr" DIPERTAHANKAN meski tidak ada endpoint OCR di server. Mode
Baca Teks berjalan on-device lewat ML Kit, tapi profil ini tetap jadi
rujukan angka saat menyetel gerbang ketajaman di sisi Flutter
(`CameraCaptureService`) — supaya kedua sisi mengukur hal yang sama
dengan ambang yang sengaja dijaga sejajar, bukan menyimpang diam-diam.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from loguru import logger

from utils.image_utils import (
    ImageQuality,
    QualityVerdict,
    assess_quality,
    bytes_to_numpy,
)


@dataclass
class GateResult:
    """Hasil gerbang kualitas."""
    ok: bool
    frame: np.ndarray | None
    quality: ImageQuality | None
    reason: str = ""
    message: str = ""

    def to_error_payload(self, extra: dict | None = None) -> dict:
        """
        Bentuk balasan error yang konsisten untuk semua endpoint.

        `message` selalu Bahasa Indonesia dan ACTIONABLE, karena inilah
        yang dibacakan TTS ke pengguna. `reason` adalah kode mesin untuk
        logging dan penanganan di sisi klien.
        """
        payload = {
            "ok": False,
            "reason": self.reason,
            "message": self.message,
            # Semua penolakan gerbang bisa diperbaiki dengan mengambil foto
            # ulang, termasuk gambar rusak dan gambar kosong: keduanya
            # menandakan pengambilan atau pengunggahan yang gagal, bukan
            # dunia yang memang tidak berisi apa-apa. Yang membedakannya
            # dari `not_in_frame` justru inilah — di sana yang perlu berubah
            # adalah arah kamera, di sini kondisi pengambilannya.
            "retry_suggested": self.reason in (
                "sangat_buram", "terlalu_gelap", "terlalu_silau",
                "kualitas_kurang", "resolusi_kecil",
                "gambar_rusak", "gambar_kosong",
            ),
        }
        if self.quality is not None:
            payload["image_quality"] = self.quality.to_dict()
        if extra:
            payload.update(extra)
        return payload


# Profil ketegasan per endpoint.
# Angka blur di sini MASIH perlu dikalibrasi dengan foto asli dari HP
# target. Jalankan:
#     python -m utils.image_utils --calibrate /path/folder_foto_asli
PROFILES = {
    # Tidak dipakai router mana pun. Ada sebagai rujukan untuk menyetel
    # ambang di CameraCaptureService sisi Flutter; lihat catatan di
    # docstring modul.
    "ocr": {
        "strict": True,
        "blur_reject": 55.0,
        "blur_warn": 120.0,
        # Huruf kecil adalah yang pertama hilang saat resolusi turun, jadi
        # jalur ini yang paling butuh pixel.
        "min_side": 320,
    },
    "find_object": {
        "strict": False,
        "blur_reject": 35.0,
        "blur_warn": 85.0,
        "min_side": 240,
    },
    "describe": {
        "strict": False,
        "blur_reject": 22.0,
        "blur_warn": 70.0,
        # Paling longgar, konsisten dengan profil lainnya: gambaran kasar
        # sebuah ruangan masih berguna dari frame kecil, dan menolak terlalu
        # sering membuat fitur ini terasa rewel.
        "min_side": 200,
    },
}


def gate(image_bytes: bytes, profile: str = "find_object",
         endpoint: str = "") -> GateResult:
    """
    Decode gambar lalu nilai kelayakannya.

    Args:
        image_bytes: isi file yang diunggah
        profile: "ocr" | "find_object" | "describe"
        endpoint: nama endpoint untuk logging

    Returns:
        GateResult. Kalau ok=False, pemanggil harus mengembalikan
        `to_error_payload()` dan TIDAK menjalankan model.
    """
    tag = endpoint or profile

    if not image_bytes:
        return GateResult(
            ok=False, frame=None, quality=None,
            reason="gambar_kosong",
            message="Gambar kosong. Coba ambil ulang.",
        )

    frame = bytes_to_numpy(image_bytes)
    if frame is None:
        return GateResult(
            ok=False, frame=None, quality=None,
            reason="gambar_rusak",
            message="Gambar tidak terbaca. Coba ambil ulang.",
        )

    cfg = PROFILES.get(profile, PROFILES["find_object"])
    q = assess_quality(
        frame,
        blur_reject=cfg["blur_reject"],
        blur_warn=cfg["blur_warn"],
        strict=cfg["strict"],
        min_side=cfg.get("min_side", 240),
    )

    logger.debug(
        f"[{tag}] kualitas={q.verdict.value} blur={q.blur_score:.1f} "
        f"terang={q.brightness:.1f} masalah={q.issues} "
        f"({q.elapsed_ms:.1f}ms)"
    )

    if q.should_reject:
        logger.info(f"[{tag}] gambar ditolak: {q.message_id} {q.issues}")
        return GateResult(
            ok=False, frame=frame, quality=q,
            reason=q.message_id,
            message=q.message or "Gambar kurang jelas. Coba ambil ulang.",
        )

    return GateResult(ok=True, frame=frame, quality=q)


def quality_note(q: ImageQuality | None) -> str:
    """
    Catatan singkat untuk ditambahkan ke narasi TTS saat hasilnya lolos
    tapi kualitas gambarnya pas-pasan.

    Ini penting untuk kejujuran sistem: kalau model menjawab berdasarkan
    foto yang kurang bagus, pengguna berhak tahu supaya bisa memutuskan
    sendiri apakah mau memfoto ulang. Return string kosong kalau tidak
    ada yang perlu disampaikan, supaya narasi tidak jadi bertele-tele
    untuk kasus normal.
    """
    if q is None or q.verdict in (QualityVerdict.GOOD,
                                  QualityVerdict.ACCEPTABLE):
        return ""
    if "kurang_cahaya" in q.issues:
        return "Cahaya kurang, jadi hasilnya mungkin tidak tepat."
    if "agak_buram" in q.issues:
        return "Gambar kurang tajam, jadi hasilnya mungkin tidak tepat."
    if "agak_silau" in q.issues:
        return "Agak silau, jadi hasilnya mungkin tidak tepat."
    return "Kualitas gambar kurang bagus, jadi hasilnya mungkin tidak tepat."
