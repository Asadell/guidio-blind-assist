"""Koneksi PostgreSQL + bootstrap skema.

Sengaja pakai SQLAlchemy Core (bukan ORM) supaya query tetap SQL biasa yang
gampang dibaca, tanpa lapisan model tambahan. Tanpa auth: identifikasi cukup
device_id anonim yang di-generate aplikasi.
"""

import os
from pathlib import Path

from loguru import logger
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

_engine: Engine | None = None
_available = False

SCHEMA_PATH = Path(__file__).parent / "schema.sql"


def _build_url() -> str:
    """URL koneksi dari .env. DATABASE_URL menang bila diisi."""
    explicit = os.getenv("DATABASE_URL", "").strip()
    if explicit:
        return explicit
    host = os.getenv("PGHOST", "localhost")
    port = os.getenv("PGPORT", "5432")
    user = os.getenv("PGUSER", "postgres")
    pwd = os.getenv("PGPASSWORD", "")
    name = os.getenv("PGDATABASE", "vinara_dev")
    return f"postgresql+psycopg://{user}:{pwd}@{host}:{port}/{name}"


def init_db() -> bool:
    """Buat engine, jalankan skema (idempoten), seed data rujukan.

    Mengembalikan False kalau database tidak terjangkau - server TETAP jalan,
    hanya endpoint yang butuh DB yang menyerah dengan pesan jelas. Prinsip
    "tidak ada jalan buntu" berlaku juga untuk backend.
    """
    global _engine, _available
    try:
        _engine = create_engine(
            _build_url(),
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=5,
            future=True,
        )
        with _engine.begin() as conn:
            conn.execute(text(SCHEMA_PATH.read_text(encoding="utf-8")))
        _available = True
        logger.success("PostgreSQL terhubung, skema siap")

        from db.seed import seed_all

        seed_all()
        return True
    except Exception as e:
        _available = False
        logger.error(f"PostgreSQL tidak terhubung: {e}")
        logger.warning("Server tetap jalan. Endpoint yang butuh DB akan balas 503.")
        return False


def is_available() -> bool:
    return _available


def get_engine() -> Engine:
    if _engine is None:
        raise RuntimeError("Database belum di-init. Panggil init_db() dulu.")
    return _engine


def fetch_all(sql: str, params: dict | None = None) -> list[dict]:
    with get_engine().connect() as conn:
        rows = conn.execute(text(sql), params or {}).mappings().all()
        return [dict(r) for r in rows]


def fetch_one(sql: str, params: dict | None = None) -> dict | None:
    with get_engine().connect() as conn:
        row = conn.execute(text(sql), params or {}).mappings().first()
        return dict(row) if row else None


def execute(sql: str, params: dict | None = None) -> None:
    with get_engine().begin() as conn:
        conn.execute(text(sql), params or {})


def execute_returning(sql: str, params: dict | None = None) -> dict | None:
    with get_engine().begin() as conn:
        row = conn.execute(text(sql), params or {}).mappings().first()
        return dict(row) if row else None
