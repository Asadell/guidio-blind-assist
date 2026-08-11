"""Mode Asisten Suara — resolusi perintah + riwayat percakapan.

  POST /api/intent            resolusi perintah suara (AS-17/18/19)
  GET  /api/intent/catalog    20 intent baku + varian ucapannya
  POST /api/asisten/turn      simpan giliran percakapan
  GET  /api/asisten/history   ambil riwayat (AS-12/13)
  POST /api/asisten/expire    bersihkan sesi kedaluwarsa (AS-23)

CommandParser lokal di Flutter tetap jalan lebih dulu dan tidak butuh
internet. Endpoint /api/intent hanya dipanggil saat lokal tidak match.
"""

from fastapi import APIRouter, Request
from pydantic import BaseModel

from db.database import is_available
from services import repository as repo

router = APIRouter(prefix="/api", tags=["asisten"])


class IntentRequest(BaseModel):
    text: str
    device_id: str | None = None


@router.get("/intent/catalog")
async def intent_catalog():
    """20 intent baku beserta varian ucapan — aplikasi bisa menyinkronkan
    CommandParser lokalnya tanpa rilis ulang."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "intents": []}
    intents = repo.get_all_intents()
    return {"total": len(intents), "intents": intents}


@router.post("/intent")
async def resolve_intent(request: Request, body: IntentRequest):
    """Petakan ucapan ke satu intent.

    Urutan usaha: frasa persis → skor kemiripan → LLM. Kalau tidak ada yang
    yakin, balasannya TETAP menawarkan dua tebakan terdekat, bukan
    "perintah gagal" — prinsip tidak ada jalan buntu.
    """
    svc = request.app.state.intent_service
    text = body.text.strip()
    if not text:
        return {
            "resolved": False,
            "reason": "empty",
            "message": "Belum terdengar apa pun.",
            "suggestions": [],
        }

    if not svc.available:
        return {
            "resolved": False,
            "reason": "catalog_unavailable",
            "message": "Daftar perintah belum termuat di server.",
            "suggestions": [],
        }

    # Lapis 1 — frasa persis.
    exact = svc.match_exact(text)
    if exact:
        return _intent_payload(svc, exact, text, resolved=True)

    # Lapis 2 — kumpulkan kandidat: kemiripan frasa + nama barang yang bisa
    # dicari. Ucapan seperti "kenal kunci" menghasilkan DUA kandidat
    # ("cari kunci" dan "kenali uang"), dan itu memang harus ditanyakan
    # balik, bukan ditebak.
    candidates = svc.rank_candidates(text, limit=2)
    find_cand = svc.find_object_candidate(text)
    if find_cand and not any(c["intent_key"] == "mode.findObject" for c in candidates):
        candidates = ([find_cand] + candidates)[:2]

    strong = [c for c in candidates if c["confidence"] >= 0.8]
    if len(strong) == 1 and len(candidates) == 1:
        return _intent_payload(svc, {**strong[0], "source": "similarity"}, text, resolved=True)

    # AS-19 — dua kandidat yang sama-sama masuk akal: tanya balik, jangan
    # panggil LLM. Menebak salah lebih mahal daripada satu pertanyaan.
    if len(candidates) >= 2:
        return {
            "resolved": False,
            "reason": "ambiguous",
            "heard": text,
            "message": svc.compose_suggestion(text, candidates),
            "suggestions": candidates,
        }

    # Lapis 3 — LLM, hanya untuk kasus yang belum punya kandidat jelas.
    llm = await svc.match_llm(text)
    if llm:
        return _intent_payload(svc, llm, text, resolved=True)

    # AS-18 — tidak dikenali: sebut yang didengar, tawarkan tebakan terdekat.
    return {
        "resolved": False,
        "reason": "unrecognized",
        "heard": text,
        "message": svc.compose_suggestion(text, candidates),
        "suggestions": candidates,
    }


def _intent_payload(svc, intent: dict, text: str, resolved: bool) -> dict:
    payload = {
        "resolved": resolved,
        "intent_key": intent["intent_key"],
        "category": intent["category"],
        "spoken_label": intent["spoken_label"],
        "confidence": intent.get("confidence", 1.0),
        "source": intent.get("source", "phrase"),
        "heard": text,
    }
    # "cari dompet" → target dinamis untuk Mode Cari Objek.
    if intent["intent_key"] == "mode.findObject":
        target = svc.extract_find_target(text)
        if target:
            payload["argument"] = target
    return payload


# ── Riwayat percakapan ───────────────────────────────────────────────────


class TurnIn(BaseModel):
    session_id: str
    device_id: str
    role: str  # user | vinara
    text: str
    intent_key: str | None = None


@router.post("/asisten/turn")
async def add_turn(body: TurnIn):
    if not is_available():
        return {"ok": False, "reason": "database_unavailable"}
    repo.touch_session(body.session_id, body.device_id)
    repo.add_turn(body.session_id, body.role, body.text, body.intent_key)
    return {"ok": True}


@router.get("/asisten/history")
async def history(session_id: str, limit: int = 20):
    """AS-12 / AS-13 — riwayat percakapan. Aplikasi yang memutuskan hanya
    giliran terbaru yang dibacakan; yang lama cukup tampil."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable", "turns": []}
    if repo.session_expired(session_id):
        return {
            "ok": True,
            "expired": True,
            "turns": [],
            "message": "Percakapan tadi sudah saya hapus.",
        }
    return {"ok": True, "expired": False, "turns": repo.get_turns(session_id, limit)}


@router.post("/asisten/expire")
async def expire_sessions():
    """AS-23 — sesi menganggur lebih dari 15 menit dibersihkan."""
    if not is_available():
        return {"ok": False, "reason": "database_unavailable"}
    return {"ok": True, "expired_sessions": repo.expire_stale_sessions()}
