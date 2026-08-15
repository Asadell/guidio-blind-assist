"""
Qwen2.5-1.5B-Instruct Local LLM Service
=========================================
Menggantikan Claude Haiku untuk tiga tugas di backend GUIDIO:
  1. Narasi deteksi YOLO → kalimat Bahasa Indonesia natural
  2. Terjemahan caption Moondream2 (EN → ID) untuk TTS
  3. Semantic intent matching (Lapis 3, last resort)

Model: Qwen2.5-1.5B-Instruct (GGUF Q4_K_M, ~1 GB)
Runtime: llama-cpp-python dengan akselerasi CUDA (n_gpu_layers=-1)
VRAM: ~1.0 GB — aman jalan bersamaan dengan YOLO + Moondream di RTX 3050 4GB

Ini BUKAN VLM — tidak memproses gambar sama sekali.
Semua input adalah teks; gambar diproses sepenuhnya oleh Moondream2.
"""

import asyncio
from pathlib import Path
from typing import Optional

from loguru import logger


class QwenService:
    """Singleton lazy-load wrapper untuk Qwen2.5-1.5B-Instruct via llama-cpp-python.

    Dibuat lewat app.state.qwen_service di lifespan main.py.
    Model TIDAK dimuat saat startup — dimuat saat request pertama datang
    (warm-up ~3–5 detik, sekali saja). Startup server tetap cepat.
    """

    def __init__(self, model_path: str, n_gpu_layers: int = -1):
        self.model_path = Path(model_path)
        self._n_gpu_layers = n_gpu_layers
        self._llm = None
        self._loaded = False
        self._lock = asyncio.Lock()

    @property
    def loaded(self) -> bool:
        return self._loaded

    @property
    def available(self) -> bool:
        """True jika model file ada di disk (bisa dimuat)."""
        return self.model_path.exists()

    def _load_sync(self) -> bool:
        """Muat model secara sinkron — dipanggil dari thread pool."""
        if not self.model_path.exists():
            logger.warning(
                f"[Qwen] File model tidak ditemukan: {self.model_path}\n"
                "       Download dari HuggingFace:\n"
                "       huggingface-cli download Qwen/Qwen2.5-1.5B-Instruct-GGUF "
                "qwen2.5-1.5b-instruct-q4_k_m.gguf --local-dir backend/models/"
            )
            return False

        try:
            from llama_cpp import Llama

            logger.info(f"[Qwen] Memuat model dari {self.model_path} ...")
            self._llm = Llama(
                model_path=str(self.model_path),
                n_gpu_layers=self._n_gpu_layers,  # -1 = semua layer ke GPU
                n_ctx=512,          # context window kecil — output maks 150 token
                n_batch=64,
                verbose=False,
                chat_format="chatml",  # Qwen2.5 pakai ChatML format
            )
            self._loaded = True
            logger.success("[Qwen] Model siap.")
            return True
        except ImportError:
            logger.error(
                "[Qwen] llama-cpp-python belum terinstall.\n"
                "       Install: pip install llama-cpp-python"
            )
            return False
        except Exception as e:
            logger.error(f"[Qwen] Gagal memuat model: {e}")
            return False

    async def _ensure_loaded(self) -> bool:
        """Thread-safe lazy loader. Hanya muat sekali."""
        if self._loaded:
            return True
        async with self._lock:
            if self._loaded:
                return True  # Double-check setelah dapat lock
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(None, self._load_sync)

    async def generate(
        self,
        system: str,
        user: str,
        max_tokens: int = 150,
        temperature: float = 0.3,
    ) -> Optional[str]:
        """Generate teks dari system + user prompt.

        Returns:
            Teks hasil generasi, atau None jika service tidak tersedia.
        """
        if not await self._ensure_loaded():
            return None

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._generate_sync,
                system,
                user,
                max_tokens,
                temperature,
            )
            return result
        except Exception as e:
            logger.error(f"[Qwen] generate() error: {e}")
            return None

    def _generate_sync(
        self,
        system: str,
        user: str,
        max_tokens: int,
        temperature: float,
    ) -> Optional[str]:
        """Inferensi sinkron — dijalankan di thread pool."""
        try:
            messages = [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ]
            response = self._llm.create_chat_completion(
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
                stop=["<|im_end|>", "<|endoftext|>"],
            )
            text = response["choices"][0]["message"]["content"]
            return text.strip() if text else None
        except Exception as e:
            logger.error(f"[Qwen] _generate_sync error: {e}")
            return None

    # ── Shortcut khusus per use-case ────────────────────────────────────────

    async def translate_to_id(self, text_en: str) -> Optional[str]:
        """Terjemahkan satu kalimat/frasa Inggris → Bahasa Indonesia TTS-friendly.

        Dipakai di describe.py untuk menghaluskan output Moondream2.
        Output max ~80 token — cukup untuk 1-2 kalimat.
        """
        system = (
            "Kamu adalah penerjemah Inggris–Indonesia untuk aplikasi pemandu tunanetra. "
            "Terjemahkan kalimat berikut ke Bahasa Indonesia yang natural dan enak didengar "
            "via Text-to-Speech. Cukup satu atau dua kalimat. "
            "Jangan tambahkan kata pembuka seperti 'Terjemahan:' atau 'Di depanmu:'. "
            "Keluarkan terjemahan saja."
        )
        return await self.generate(system, text_en, max_tokens=100, temperature=0.2)

    async def narrate_detections(self, det_text: str, context: str = "navigasi") -> Optional[str]:
        """Ubah data deteksi YOLO (teks terstruktur) → narasi Bahasa Indonesia natural.

        Dipakai di narasi.py.
        """
        system = (
            "Kamu adalah asisten navigasi untuk penyandang tunanetra bernama Guidio. "
            "Ubah data deteksi objek berikut menjadi 1–2 kalimat Bahasa Indonesia yang "
            "natural dan mudah dipahami. Sebutkan posisi (kiri/depan/kanan) dan jarak "
            "dalam bahasa sehari-hari (contoh: 'sekitar satu meter', 'cukup dekat'). "
            "Beri saran keselamatan jika ada bahaya. "
            "JANGAN sebut angka desimal, confidence, atau istilah teknis."
        )
        user = f"Objek terdeteksi (mode {context}):\n{det_text}"
        return await self.generate(system, user, max_tokens=120, temperature=0.3)

    async def classify_intent(self, text: str, intent_list: str) -> Optional[str]:
        """Klasifikasikan ucapan ke satu intent_key dari daftar yang diberikan.

        Dipakai di intent_service.py sebagai Lapis 3 (last resort).
        Output hanya 1 kata — max_tokens=20, temperature=0.0 untuk determinisme.
        """
        system = (
            "Kamu pemetaan perintah suara Bahasa Indonesia untuk aplikasi asisten tunanetra Vinara.\n\n"
            f"Daftar intent yang tersedia:\n{intent_list}\n\n"
            "Petakan ucapan pengguna ke SATU intent_key dari daftar di atas. "
            "Jawab HANYA dengan intent_key persis seperti tertulis. "
            "Jawab 'none' jika ucapan ambigu atau tidak cocok dengan intent manapun."
        )
        return await self.generate(system, text, max_tokens=20, temperature=0.0)
