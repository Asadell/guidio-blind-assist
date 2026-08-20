"""
conftest.py — Shared fixtures untuk semua test backend Guidio.

Menyediakan:
  - `client`   : TestClient FastAPI (tanpa server nyata)
  - `nav_image`: bytes gambar navigasi dari fixtures
  - `obj_image`: bytes gambar cari-objek dari fixtures
"""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Tambah backend root ke sys.path agar `from main import app` bisa jalan
BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

# Fixtures lokal (sudah dicopy dari guidio_app/test/fixtures/)
# Fallback ke guidio_app jika belum dicopy (untuk kompatibilitas)
_LOCAL_FIXTURES = Path(__file__).parent / "fixtures"
_APP_FIXTURES   = BACKEND_DIR.parent.parent / "guidio_app" / "test" / "fixtures"
FIXTURES_DIR    = _LOCAL_FIXTURES if _LOCAL_FIXTURES.exists() else _APP_FIXTURES



@pytest.fixture(scope="session")
def client():
    """TestClient FastAPI — tanpa server nyata, langsung hit ASGI app."""
    from main import app

    with TestClient(app, raise_server_exceptions=True) as c:
        yield c


@pytest.fixture
def nav_image() -> bytes:
    """Gambar navigasi: motor + orang di trotoar (simulasi frame kamera)."""
    path = FIXTURES_DIR / "navigation" / "04_motor_dan_orang.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def got_image() -> bytes:
    """Gambar got terbuka (hazard class 1)."""
    path = FIXTURES_DIR / "navigation" / "01_got_terbuka.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def obj_image_tas() -> bytes:
    """Gambar tas merah di kelas (cari objek fixture 01)."""
    path = FIXTURES_DIR / "object_find" / "test_01_tas_merah_kelas.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()


@pytest.fixture
def obj_image_botol() -> bytes:
    """Gambar botol minum di dapur (cari objek fixture 03 — model biasanya detect ini)."""
    path = FIXTURES_DIR / "object_find" / "test_03_botol_minum_dapur.png"
    if not path.exists():
        pytest.skip(f"Fixture tidak ada: {path}")
    return path.read_bytes()
