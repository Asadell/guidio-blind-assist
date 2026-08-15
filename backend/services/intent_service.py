"""Resolusi perintah suara sisi server — POST /api/intent.

CommandParser lokal di Flutter menangani 20 intent baku tanpa internet
(0 ms, tetap jalan offline). Server hanya dipanggil saat lokal TIDAK match,
untuk dua kasus yang memang butuh pemahaman bahasa:
  - AS-18 "tidak dikenali" → tawarkan dua tebakan terdekat
  - AS-19 "ambigu"         → pertanyaan pilihan dua

Urutan usaha: cocokkan frasa persis → skor kemiripan kata → LLM lokal (opsional).
Kalau semuanya gagal, balasannya tetap menawarkan dua tebakan, bukan
"perintah gagal" — prinsip "tidak ada jalan buntu".

LLM Lapis 3: Qwen2.5-1.5B-Instruct via QwenService lokal (bukan API eksternal).
"""

import re

from loguru import logger

VALID_CATEGORIES = {"mode", "action", "play", "help"}


class IntentService:
    """Pencocokan intent berbasis data dari tabel voice_intents."""

    def __init__(self):
        self._intents: list[dict] = []
        self._searchable: list[str] = []
        self._qwen = None  # Di-inject dari main.py setelah QwenService siap

    def refresh(self, intents: list[dict], searchable: list[str] | None = None) -> None:
        """Muat ulang daftar intent dari DB (dipanggil saat startup).

        `searchable` = nama barang yang bisa jadi target Mode Cari Objek.
        Dipakai supaya ucapan seperti "kenal kunci" bisa dikenali sebagai
        ambigu antara "cari kunci" dan "kenali uang", bukan langsung
        ditebak salah satunya.
        """
        self._intents = intents
        if searchable is not None:
            self._searchable = [s.lower() for s in searchable]

    def set_llm(self, qwen_service) -> None:
        """Inject QwenService dari app.state (dipanggil di lifespan main.py)."""
        self._qwen = qwen_service
        logger.info("[IntentService] QwenService terdaftar sebagai Lapis 3 LLM.")

    def find_object_candidate(self, text: str) -> dict | None:
        """Kalau ucapan menyebut barang yang bisa dicari, tawarkan Cari Objek."""
        low = self._normalize(text)
        words = low.split()
        for item in self._searchable:
            if item in low or any(w == item for w in words):
                return {
                    "intent_key": "mode.findObject",
                    "category": "mode",
                    "spoken_label": f"cari {item}",
                    "argument": item,
                    "confidence": 0.5,
                }
        return None

    @property
    def available(self) -> bool:
        return bool(self._intents)

    # ── Lapis 1: cocokkan frasa ──────────────────────────────────────────

    def match_exact(self, text: str) -> dict | None:
        low = self._normalize(text)
        for intent in self._intents:
            for phrase in intent["phrases"]:
                if phrase in low:
                    return {
                        "intent_key": intent["intent_key"],
                        "category": intent["category"],
                        "spoken_label": intent["spoken_label"],
                        "confidence": 1.0,
                        "matched_phrase": phrase,
                        "source": "phrase",
                    }
        return None

    # ── Lapis 2: skor kemiripan kata ─────────────────────────────────────

    def rank_candidates(self, text: str, limit: int = 2) -> list[dict]:
        """Tebakan terdekat berbasis irisan kata + kemiripan awalan.

        Dipakai untuk menyusun naskah AS-18: "Saya dengar kenal kunci.
        Maksudmu cari kunci, atau kenali uang?"
        """
        low = self._normalize(text)
        words = set(low.split())
        if not words:
            return []

        scored: list[tuple[float, dict]] = []
        for intent in self._intents:
            best = 0.0
            for phrase in intent["phrases"]:
                pwords = set(phrase.split())
                if not pwords:
                    continue
                overlap = len(words & pwords)
                partial = sum(
                    1
                    for w in words
                    for p in pwords
                    if w != p and (w.startswith(p[:4]) or p.startswith(w[:4]))
                )
                score = (overlap + 0.5 * partial) / len(pwords)
                best = max(best, score)
            if best > 0:
                scored.append((best, intent))

        scored.sort(key=lambda t: t[0], reverse=True)
        return [
            {
                "intent_key": intent["intent_key"],
                "category": intent["category"],
                "spoken_label": intent["spoken_label"],
                "confidence": round(min(score, 0.99), 3),
            }
            for score, intent in scored[:limit]
        ]

    # ── Lapis 3: LLM lokal (Qwen, opsional) ─────────────────────────────

    async def match_llm(self, text: str) -> dict | None:
        """Semantic matching via Qwen2.5-1.5B lokal — last resort.

        Hanya dipanggil jika Lapis 1 dan 2 gagal menemukan intent yang
        cukup yakin. Output hanya 1 kata (intent_key) jadi bahkan model
        kecil seperti 0.5B sudah cukup untuk tugas ini.
        """
        if self._qwen is None or not self._intents:
            return None

        try:
            intent_list = "\n".join(
                f"- {i['intent_key']}: {i['spoken_label']}" for i in self._intents
            )
            key_raw = await self._qwen.classify_intent(text, intent_list)
            if not key_raw:
                return None

            key = key_raw.strip().lower()
            if key == "none":
                return None

            for intent in self._intents:
                if intent["intent_key"].lower() == key:
                    return {
                        "intent_key": intent["intent_key"],
                        "category": intent["category"],
                        "spoken_label": intent["spoken_label"],
                        "confidence": 0.85,
                        "source": "llm_local",
                    }
            logger.debug(f"[IntentService] Qwen return key tidak dikenal: '{key}'")
            return None
        except Exception as e:
            logger.warning(f"[IntentService] Pencocokan intent via Qwen gagal: {e}")
            return None

    # ── Ekstraksi target Cari Objek ──────────────────────────────────────

    TARGET_PATTERN = re.compile(r"^cari(?:kan)?\s+(?!objek$|barang$)(.+)$")

    def extract_find_target(self, text: str) -> str | None:
        """"cari dompet" → "dompet". Dipakai intent mode.findObject."""
        m = self.TARGET_PATTERN.match(self._normalize(text))
        return m.group(1).strip() if m else None

    # ── Naskah tawaran tebakan ───────────────────────────────────────────

    @staticmethod
    def compose_suggestion(heard: str, candidates: list[dict]) -> str:
        """AS-18 / AS-19 — sebut yang didengar, lalu tawarkan dua pilihan."""
        if len(candidates) >= 2:
            return (
                f"Saya dengar {heard}. "
                f"Maksudmu {candidates[0]['spoken_label']}, "
                f"atau {candidates[1]['spoken_label']}?"
            )
        if len(candidates) == 1:
            return f"Saya dengar {heard}. Maksudmu {candidates[0]['spoken_label']}?"
        return (
            f"Saya dengar {heard}, tapi belum paham. "
            "Coba sebut: kenali uang, baca teks, atau cari barang."
        )

    @staticmethod
    def _normalize(text: str) -> str:
        return re.sub(r"\s+", " ", text.strip().lower())
