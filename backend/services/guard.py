"""Pembatas antrean GPU.

Satu pintu masuk untuk semua pekerjaan GPU, supaya jumlah inferensi yang
berjalan bersamaan tidak pernah melebihi kapasitas kartu.

KENAPA `asyncio.wait_for` SAJA TIDAK CUKUP
------------------------------------------
`routers/describe.py` sudah membungkus inferensi dengan `asyncio.wait_for(...,
timeout=25)`. Itu terlihat seperti perlindungan, padahal bukan.

Inferensi berjalan lewat `loop.run_in_executor(None, ...)`, yaitu thread biasa,
dan thread Python TIDAK BISA dibatalkan dari luar. Ketika batas waktu tercapai,
`wait_for` hanya berhenti MENUNGGU; pekerjaan GPU-nya tetap jalan sampai
selesai. Akibatnya, saat permintaan datang bertubi-tubi:

    50 permintaan masuk bersamaan
    -> 50 thread menumpuk di GPU
    -> semua klien menerima "timeout" dalam 25 detik lalu mencoba lagi
    -> GPU masih mengerjakan 50 yang pertama, ditambah 50 yang baru

Klien merasa server cepat menolak, padahal antrean GPU tumbuh terus sampai
VRAM habis. Batas waktu tanpa kendali penerimaan bukan rem, melainkan pengeras
suara.

Satu-satunya obatnya adalah menolak SEBELUM pekerjaan dimulai. Itulah tugas
berkas ini.

Nilainya diatur lewat .env: `GPU_CONCURRENCY` dan `GPU_MAX_QUEUE`.
"""

from __future__ import annotations

import asyncio
import os
import time
from contextlib import asynccontextmanager

from loguru import logger


def _env_int(name: str, default: int) -> int:
    try:
        return max(0, int(os.getenv(name, str(default))))
    except (TypeError, ValueError):
        return default


class GpuBusy(Exception):
    """GPU penuh dan antreannya sudah panjang. Ditolak cepat, bukan diantre."""

    def __init__(self, waiting: int, limit: int):
        self.waiting = waiting
        self.limit = limit
        super().__init__(f"GPU sibuk: {waiting} menunggu, batas {limit}")


class GpuAdmission:
    """Dua batas, dan keduanya perlu.

    `concurrency`  Berapa inferensi boleh jalan BERSAMAAN. Bawaannya 1.
                   Moondream2 (FP16, ~1,2 GB) dan YOLOE berbagi kartu yang
                   sama. Menjalankan dua inferensi sekaligus tidak membuat
                   keduanya lebih cepat - GPU-nya toh satu - tapi menggandakan
                   VRAM puncak, dan kehabisan VRAM MEMATIKAN proses, bukan
                   sekadar memperlambatnya. Di kartu yang dipakai bersama,
                   serialisasi justru menaikkan jumlah permintaan yang
                   benar-benar selesai.

    `max_queue`    Berapa yang boleh MENUNGGU giliran. Tanpa ini, membatasi
                   concurrency cuma memindahkan tumpukan dari GPU ke memori
                   proses: permintaan ke-200 tetap diterima, tetap memegang
                   gambarnya di RAM, dan tetap dikerjakan beberapa menit
                   kemudian, saat penggunanya sudah lama pergi.

    Menolak cepat lebih baik daripada mengantre diam-diam. Pengguna tunanetra
    yang mendengar "server sedang sibuk, coba lagi" tahu harus apa. Yang
    menunggu 90 detik tanpa suara tidak tahu apakah aplikasinya rusak,
    ponselnya mati, atau dirinya salah menekan tombol.
    """

    def __init__(self, concurrency: int | None = None,
                 max_queue: int | None = None):
        self.concurrency = concurrency if concurrency is not None else \
            _env_int("GPU_CONCURRENCY", 1)
        self.max_queue = max_queue if max_queue is not None else \
            _env_int("GPU_MAX_QUEUE", 4)

        self._sem = asyncio.Semaphore(self.concurrency)
        self._waiting = 0
        self._active = 0

        # Statistik untuk /health. Murni pengamatan.
        self.total_admitted = 0
        self.total_rejected = 0

    @asynccontextmanager
    async def slot(self, tag: str = "gpu"):
        """Pegang satu slot GPU, atau lempar `GpuBusy` seketika.

        Pemeriksaan antrean terjadi SEBELUM `await`, jadi permintaan yang
        ditolak tidak pernah menyentuh GPU.
        """
        if self._waiting >= self.max_queue:
            self.total_rejected += 1
            logger.warning(
                f"[guard] {tag} ditolak: {self._waiting} menunggu "
                f"(batas {self.max_queue}), {self._active} berjalan"
            )
            raise GpuBusy(self._waiting, self.max_queue)

        self._waiting += 1
        t0 = time.perf_counter()
        try:
            await self._sem.acquire()
        finally:
            self._waiting -= 1

        wait_ms = (time.perf_counter() - t0) * 1000
        self._active += 1
        self.total_admitted += 1
        if wait_ms > 50:
            logger.info(f"[guard] {tag} menunggu {wait_ms:.0f} ms di antrean GPU")
        try:
            yield
        finally:
            self._active -= 1
            self._sem.release()

    def stats(self) -> dict:
        return {
            "concurrency": self.concurrency,
            "max_queue": self.max_queue,
            "active": self._active,
            "waiting": self._waiting,
            "admitted": self.total_admitted,
            "rejected": self.total_rejected,
        }
