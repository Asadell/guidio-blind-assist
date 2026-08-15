"""
Moondream2 Scene Description Service
=====================================
Menjalankan Moondream2 (~2B) secara lazy-load di GPU lokal (RTX 3050 4GB VRAM).
- Length='short' → caption singkat, padat, alt-text style
- Single image processing (Moondream tidak support batching)
- FP16 untuk efisiensi VRAM 4GB
- Thread-safe via asyncio.Lock
"""

import asyncio
import io
from typing import Optional

from loguru import logger
from PIL import Image


class MoonDreamService:
    """Lazy-loaded Moondream2 service.
    
    Dibuat singleton lewat app.state.moondream_service di lifespan.
    Model TIDAK dimuat saat startup (bobotnya ~2GB) — dimuat saat
    permintaan pertama datang (warm-up ~5-10 detik, sekali saja).
    """

    def __init__(self, model_id: str = "vikhyatk/moondream2", device: str = "auto"):
        self.model_id = model_id
        self._device = device
        self._model = None
        self._tokenizer = None
        self._loaded = False
        self._lock = asyncio.Lock()

    @property
    def loaded(self) -> bool:
        return self._loaded

    def _resolve_device(self) -> str:
        """Pilih device: 'cuda' jika tersedia, fallback ke 'cpu'."""
        if self._device == "auto":
            try:
                import torch
                return "cuda" if torch.cuda.is_available() else "cpu"
            except ImportError:
                return "cpu"
        return self._device

    def _load_sync(self) -> bool:
        """Muat model secara sinkron — dipanggil di thread pool dari _ensure_loaded."""
        try:
            import torch
            from transformers import AutoModelForCausalLM, AutoTokenizer

            device = self._resolve_device()
            dtype = torch.float16 if device == "cuda" else torch.float32

            logger.info(f"[Moondream2] Memuat model {self.model_id} ke {device} ({dtype})...")

            self._tokenizer = AutoTokenizer.from_pretrained(
                self.model_id,
                trust_remote_code=True,
            )
            self._model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                trust_remote_code=True,
                torch_dtype=dtype,
            ).to(device)
            self._model.eval()
            self._loaded = True
            logger.success(f"[Moondream2] Model siap di {device}.")
            return True
        except Exception as e:
            logger.error(f"[Moondream2] Gagal memuat model: {e}")
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

    async def describe(
        self,
        image_bytes: bytes,
        length: str = "short",
    ) -> Optional[str]:
        """
        Deskripsikan gambar menggunakan Moondream2.
        
        Args:
            image_bytes: JPEG/PNG bytes dari kamera
            length: 'short' (1 kalimat, alt-text style) atau 'normal'
        
        Returns:
            Teks deskripsi Bahasa Inggris, atau None jika gagal.
        """
        if not await self._ensure_loaded():
            return None

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, self._describe_sync, image_bytes, length
            )
            return result
        except Exception as e:
            logger.error(f"[Moondream2] describe() error: {e}")
            return None

    def _describe_sync(self, image_bytes: bytes, length: str) -> Optional[str]:
        """Inferensi sinkron — dijalankan di thread pool."""
        try:
            import torch

            pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

            with torch.no_grad():
                # encode_image: mengonversi PIL → tensor internal Moondream
                enc = self._model.encode_image(pil_image)
                caption = self._model.caption(enc, length=length)["caption"]

            return caption.strip() if caption else None
        except Exception as e:
            logger.error(f"[Moondream2] _describe_sync error: {e}")
            return None
