"""
Router: POST /api/route-intent
Intent routing untuk Voice Assistant — ARSITEKTUR LAMA.

Catatan: Endpoint ini merupakan sisa arsitektur lama sebelum CommandParser
Flutter dibangun. Flutter sekarang melakukan intent parsing secara lokal
(0ms, offline) dengan 70+ keyword dan fuzzy matching.

Endpoint ini TIDAK lagi dipanggil oleh Flutter. Dipertahankan agar tidak
break backward compatibility jika ada client lain yang masih menggunakannya.

Claude Haiku yang sebelumnya di sini sudah DIHAPUS. Sekarang menggunakan
keyword-based classifier sederhana yang tidak membutuhkan API key maupun
model LLM — sesuai dengan sifat tugas yang hanya 4 kategori.
"""

import logging

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

VALID_INTENTS = {"describe_scene", "ocr", "navigation", "chitchat"}
DEFAULT_INTENT = "describe_scene"  # fallback paling aman untuk tunanetra

# Keyword sederhana per intent — cukup untuk 4 kategori ini tanpa LLM
_KEYWORDS: dict[str, list[str]] = {
    "describe_scene": [
        "deskripsikan", "jelaskan", "ceritakan", "gambarkan", "lihatkan",
        "sekitarku", "depanku", "suasana", "kondisi", "pemandangan",
    ],
    "ocr": [
        "baca", "bacakan", "teks", "tulisan", "kata", "huruf",
        "bacain", "tolong baca",
    ],
    "navigation": [
        "navigasi", "pergi", "jalan", "ke mana", "arahkan", "tuntun",
        "panduan", "lewat", "belok",
    ],
    "chitchat": [
        "halo", "hai", "apa kabar", "siapa kamu", "terima kasih",
        "makasih", "selamat", "help", "tolong",
    ],
}


def _classify_keyword(text: str) -> str:
    """Klasifikasi berdasarkan keyword match — O(n) sederhana, tanpa model."""
    low = text.strip().lower()
    scores: dict[str, int] = {intent: 0 for intent in VALID_INTENTS}
    for intent, keywords in _KEYWORDS.items():
        for kw in keywords:
            if kw in low:
                scores[intent] += 1
    best = max(scores, key=lambda k: scores[k])
    return best if scores[best] > 0 else DEFAULT_INTENT


class RouteRequest(BaseModel):
    text: str


class RouteResponse(BaseModel):
    intent: str
    fallback_used: bool


@router.post("/api/route-intent", response_model=RouteResponse)
async def route_intent(req: RouteRequest):
    """
    Intent routing berbasis keyword (tanpa LLM, tanpa API key).

    Endpoint ini adalah sisa arsitektur lama — Flutter tidak lagi
    memanggilnya karena CommandParser lokal sudah lebih lengkap.
    Dipertahankan untuk backward compatibility.
    """
    try:
        intent = _classify_keyword(req.text)
        fallback = intent == DEFAULT_INTENT
        return RouteResponse(intent=intent, fallback_used=fallback)
    except Exception as e:
        logging.error(f"route_intent gagal: {e}")
        return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)
