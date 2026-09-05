"""Endpoint penunjang - tinggal satu: `/api/capabilities`.

Sebelas endpoint lain (`/api/labels`, `/api/models/*`, `/api/events`,
`/api/crash-report*`, `/api/queue/*`) sudah dihapus: tidak satu pun pernah
dipanggil aplikasi. Method kliennya ada di `ServerService`, lengkap dengan
penanganan error, tapi tidak ada satu pun pemanggil - jadi tabel
`telemetry_events`, `crash_reports`, `upload_queue`, `object_labels`, dan
`model_manifest` tidak pernah menerima satu baris pun dari aplikasi.

Menyisakannya berarti memelihara permukaan API yang harus dijelaskan tapi
tidak pernah dipakai. PostgreSQL ikut hilang bersamanya: backend ini sekarang
stateless dan hanya melayani dua model yang tidak muat di ponsel.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Request

router = APIRouter(prefix="/api", tags=["support"])


@router.get("/capabilities")
async def capabilities(request: Request):
    """Kemampuan server SEBELUM pengguna menekan tombol.

    Menentukan item mana yang `limited` / `disabled` di ModePickerSheet.
    Tanpa ini, satu-satunya cara mengetahui sebuah mode sedang mati adalah
    masuk ke sana lalu gagal - dan untuk pengguna yang tidak melihat layar,
    "masuk lalu gagal" berarti beberapa detik kebingungan di tempat yang salah.

    **Empat dari enam mode sekarang on-device penuh.** Deteksi Objek, Kenali
    Uang, Baca Teks, dan Navigasi berjalan sepenuhnya di ponsel, jadi
    statusnya tidak lagi bergantung pada server ini sama sekali - dan
    melaporkannya `down` saat server bermasalah akan mengunci pengguna dari
    mode yang sebenarnya sehat.
    """
    state = request.app.state
    finder = getattr(state, "find_object_service", None)
    moondream = getattr(state, "moondream_service", None)

    find_ok = finder is not None
    describe_ok = moondream is not None and getattr(moondream, "available", False)

    caps = {
        "detection": {
            "state": "up",
            "on_device": True,
            "note": "Berjalan on-device (SSD MobileNet), tidak butuh server.",
        },
        "money": {
            "state": "up",
            "on_device": True,
            "note": "Klasifikasi nominal on-device (TFLite), tidak pernah memanggil server.",
        },
        "read_text": {
            "state": "up",
            "on_device": True,
            "note": "Pengenalan teks on-device (ML Kit), tidak butuh server.",
        },
        "navigation": {
            "state": "up",
            "on_device": True,
            "note": "Jalur dan rintangan dibaca on-device (PIDNet + YOLO11n).",
        },
        # Dua ini yang benar-benar butuh server: modelnya tidak ada di ponsel.
        "assistant": {
            "state": "up" if describe_ok else "limited",
            "on_device": False,
            "note": "Asisten penuh, deskripsi suasana siap."
            if describe_ok
            else "Perintah dan ganti mode tetap jalan; deskripsi suasana butuh server.",
        },
        "find_object": {
            "state": "up" if find_ok else "down",
            "on_device": False,
            "note": "Pencarian objek siap."
            if find_ok
            else "Cari Objek butuh server; modelnya tidak ada di ponsel.",
        },
    }

    # Tidak ada lagi override manual dari database: status di sini murni
    # dibaca dari service yang benar-benar hidup di proses ini.
    return {
        "server_time": datetime.now(timezone.utc).isoformat(),
        "capabilities": caps,
    }
