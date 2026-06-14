from fastapi import APIRouter
from pydantic import BaseModel
import anthropic
import logging

router = APIRouter()

# Gunakan AsyncAnthropic agar tidak blocking FastAPI event loop
client = anthropic.AsyncAnthropic()

VALID_INTENTS = {"describe_scene", "ocr", "navigation", "chitchat"}
DEFAULT_INTENT = "describe_scene"  # fallback paling aman untuk tunanetra

ROUTER_SYSTEM = """Kamu adalah intent classifier untuk asisten navigasi tunanetra berbahasa Indonesia.

Klasifikasikan teks input ke SATU intent dari daftar berikut:
- describe_scene : user ingin tahu apa yang ada di sekitar atau di depan mereka
- ocr            : user ingin membaca teks, tulisan, atau kata-kata yang ada di depan
- navigation     : user ingin pergi ke suatu tempat atau meminta panduan navigasi
- chitchat       : pertanyaan umum, sapaan, atau percakapan yang tidak terkait navigasi

Jawab HANYA dengan satu kata intent tersebut. Tidak ada tanda baca, tidak ada kalimat lain."""


class RouteRequest(BaseModel):
    text: str


class RouteResponse(BaseModel):
    intent: str
    fallback_used: bool


@router.post("/api/route-intent", response_model=RouteResponse)
async def route_intent(req: RouteRequest):
    """
    LLM intent routing untuk Voice Assistant.

    max_tokens=10 + temperature=0.0 → latency routing < 300ms.
    Fallback ke 'describe_scene' jika Claude gagal atau return intent tidak valid.
    """
    try:
        response = await client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=10,
            temperature=0.0,
            system=ROUTER_SYSTEM,
            messages=[{"role": "user", "content": req.text}],
        )
        intent = response.content[0].text.strip().lower()

        if intent not in VALID_INTENTS:
            logging.warning(
                f"Intent tidak valid dari LLM: '{intent}', fallback ke {DEFAULT_INTENT}"
            )
            return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)

        return RouteResponse(intent=intent, fallback_used=False)

    except Exception as e:
        logging.error(f"route_intent gagal: {e}")
        return RouteResponse(intent=DEFAULT_INTENT, fallback_used=True)
