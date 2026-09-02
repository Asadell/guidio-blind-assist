"""Seed data rujukan: kamus label, 20 intent suara, denominasi rupiah, manifest.

Semua idempoten (ON CONFLICT DO NOTHING / DO UPDATE), aman dijalankan tiap
startup.
"""

from loguru import logger

from db.database import execute, fetch_one

# ── Kamus label objek (COCO → Bahasa Indonesia) ──────────────────────────
# real_height_cm dipakai estimasi jarak similar-triangle di yolo_service.
# danger_class: high = orang/kendaraan, medium = perabot, info = sisanya.
# searchable: boleh jadi target Mode Cari Objek.
LABELS: list[tuple[str, str, int | None, str, bool]] = [
    ("person", "orang", 170, "high", False),
    ("bicycle", "sepeda", 100, "medium", True),
    ("car", "mobil", 150, "high", False),
    ("motorcycle", "motor", 120, "high", False),
    ("bus", "bus", 300, "high", False),
    ("truck", "truk", 280, "high", False),
    ("traffic light", "lampu merah", 300, "info", False),
    ("stop sign", "rambu berhenti", 200, "info", False),
    ("bench", "bangku", 85, "medium", True),
    ("dog", "anjing", 60, "high", False),
    ("cat", "kucing", 25, "info", False),
    ("backpack", "tas ransel", 45, "info", True),
    ("umbrella", "payung", 90, "info", True),
    ("handbag", "tas tangan", 30, "info", True),
    ("tie", "dasi", 40, "info", True),
    ("suitcase", "koper", 60, "info", True),
    ("bottle", "botol", 25, "info", True),
    ("wine glass", "gelas anggur", 18, "info", False),
    ("cup", "gelas", 12, "info", True),
    ("fork", "garpu", 18, "info", True),
    ("knife", "pisau", 22, "info", True),
    ("spoon", "sendok", 18, "info", True),
    ("bowl", "mangkuk", 12, "info", True),
    ("banana", "pisang", 18, "info", True),
    ("apple", "apel", 8, "info", True),
    ("sandwich", "roti lapis", 8, "info", True),
    ("orange", "jeruk", 8, "info", True),
    ("chair", "kursi", 90, "medium", True),
    ("couch", "sofa", 80, "medium", True),
    ("potted plant", "tanaman pot", 60, "medium", True),
    ("bed", "tempat tidur", 60, "medium", True),
    ("dining table", "meja makan", 75, "medium", True),
    ("toilet", "toilet", 70, "medium", False),
    ("tv", "televisi", 60, "info", True),
    ("laptop", "laptop", 25, "info", True),
    ("mouse", "tetikus", 4, "info", True),
    ("remote", "remote", 18, "info", True),
    ("keyboard", "papan ketik", 3, "info", True),
    ("cell phone", "ponsel", 15, "info", True),
    ("microwave", "microwave", 30, "info", True),
    ("oven", "oven", 60, "medium", True),
    ("sink", "wastafel", 85, "medium", False),
    ("refrigerator", "kulkas", 170, "medium", True),
    ("book", "buku", 24, "info", True),
    ("clock", "jam", 25, "info", True),
    ("vase", "vas", 30, "info", True),
    ("scissors", "gunting", 18, "info", True),
    ("teddy bear", "boneka beruang", 30, "info", False),
    ("hair drier", "pengering rambut", 20, "info", True),
    ("toothbrush", "sikat gigi", 18, "info", True),
    ("door", "pintu", 200, "medium", True),
    ("stairs", "tangga", 100, "medium", False),
]

# ── 20 intent perintah suara (bagian 14 IMPLEMENTASI.md) ─────────────────
INTENTS: list[tuple[str, str, str, bool, list[str]]] = [
    ("mode.money", "mode", "kenali uang", False,
     ["buka mode uang", "kenali uang", "ini uang berapa", "mode uang", "cek uang", "berapa ini"]),
    ("mode.readText", "mode", "baca teks", True,
     ["baca teks", "bacakan", "buka mode baca", "baca tulisan ini", "apa tulisannya"]),
    ("mode.detection", "mode", "deteksi objek", False,
     ["deteksi objek", "mode deteksi", "ada apa di depan"]),
    ("mode.navigation", "mode", "navigasi", True,
     ["mode navigasi", "mau jalan", "bantu jalan", "navigasi"]),
    ("mode.assistant", "mode", "asisten suara", True,
     ["asisten", "tanya", "mode suara"]),
    ("mode.findObject", "mode", "cari objek", True,
     ["cari objek", "cari barang", "carikan"]),
    ("mode.settings", "mode", "pengaturan", False,
     ["pengaturan", "setelan", "buka pengaturan"]),
    ("action.capture", "action", "ambil gambar", False,
     ["ambil gambar", "jepret", "foto"]),
    ("action.replay", "action", "putar ulang", False,
     ["putar ulang", "ulangi", "baca lagi"]),
    ("action.summary", "action", "ringkas", True,
     ["ringkas", "singkat saja", "baca ringkasannya"]),
    ("action.stopWalking", "action", "selesai jalan", False,
     ["selesai jalan", "sudah sampai", "berhenti navigasi"]),
    ("action.showAll", "action", "lihat semua", False, ["lihat semua"]),
    ("action.torch", "action", "nyalakan lampu", False,
     ["nyalakan lampu", "nyalakan senter", "lampu kamera"]),
    ("play.pause", "play", "jeda", False, ["jeda", "berhenti dulu", "stop"]),
    ("play.resume", "play", "lanjut", False, ["lanjut", "terusin", "lanjutkan"]),
    ("play.faster", "play", "lebih cepat", False, ["lebih cepat", "percepat"]),
    ("play.slower", "play", "lebih pelan", False, ["lebih pelan", "pelan-pelan"]),
    ("play.repeatSection", "play", "ulangi bagian", False,
     ["ulangi bagian", "ulang yang tadi"]),
    ("help.what", "help", "bantuan", False,
     ["bisa apa", "apa saja", "bantuan", "tolong"]),
    ("help.whereAmI", "help", "saya di mana", False,
     ["ini mode apa", "saya di mana"]),
]

# ── Denominasi rupiah ────────────────────────────────────────────────────
# class_index HARUS sama dengan class_indices model TFLite on-device:
#   {'100rb': 0, '10rb': 1, '20rb': 2, '2rb': 3, '50rb': 4, '5rb': 5}
# Rp1.000 TIDAK ada di model (6 kelas, emisi 2016) → active=False, supaya
# aplikasi bisa menyebut keterbatasannya dengan jujur (UG-18) alih-alih
# menebak. Salah nominal = kerugian uang nyata.
# (value_idr, words, emissions, color_name, class_index, active)
DENOMINATIONS: list[tuple[int, str, str, str, int | None, bool]] = [
    (100000, "seratus ribu rupiah", "2016", "merah", 0, True),
    (10000, "sepuluh ribu rupiah", "2016", "ungu", 1, True),
    (20000, "dua puluh ribu rupiah", "2016", "hijau", 2, True),
    (2000, "dua ribu rupiah", "2016", "abu-abu", 3, True),
    (50000, "lima puluh ribu rupiah", "2016", "biru", 4, True),
    (5000, "lima ribu rupiah", "2016", "coklat", 5, True),
    (1000, "seribu rupiah", "-", "hijau kebiruan", None, False),
]

# ── Manifest model on-device ─────────────────────────────────────────────
# `available=False` untuk money: model .tflite belum ada, akan diisi user.
MANIFEST: list[tuple[str, str, str, str, str, bool, str]] = [
    ("detection", "1.0.0", "ssd_mobilenet.tflite", "tflite", "1.0.0", False,
     "Deteksi rintangan on-device. Sudah dibundel di assets aplikasi."),
    ("money", "1.0.0", "uang_rupiah.tflite", "tflite", "1.0.0", False,
     "Klasifikasi 6 denominasi rupiah emisi 2016 (MobileNetV2 transfer "
     "learning, input 224x224 float32, rescale 1/255). Sudah dibundel di "
     "assets aplikasi dan berjalan sepenuhnya on-device. Rp1.000 TIDAK "
     "didukung model ini."),
    ("segmentation", "0.0.0", "pidnet_s_3zona.onnx", "onnx", "1.0.0", False,
     "Segmentasi jalur 3 zona (PIDNet-S). Opsional: server pakai fallback "
     "heuristik bila model belum ada."),
]


def seed_all() -> None:
    try:
        _seed_labels()
        _seed_intents()
        _seed_denominations()
        _seed_manifest()
        logger.success("Seed data rujukan siap")
    except Exception as e:
        logger.error(f"Seed gagal: {e}")


def _seed_labels() -> None:
    for label_en, label_id, height, danger, searchable in LABELS:
        execute(
            """
            INSERT INTO object_labels
                (label_en, lang, label_local, real_height_cm, danger_class, searchable)
            VALUES (:en, 'id', :local, :h, :danger, :searchable)
            ON CONFLICT (label_en, lang) DO UPDATE
                SET label_local    = EXCLUDED.label_local,
                    real_height_cm = EXCLUDED.real_height_cm,
                    danger_class   = EXCLUDED.danger_class,
                    searchable     = EXCLUDED.searchable,
                    updated_at     = now()
            """,
            {"en": label_en, "local": label_id, "h": height,
             "danger": danger, "searchable": searchable},
        )


def _seed_intents() -> None:
    for key, category, spoken, needs_server, phrases in INTENTS:
        execute(
            """
            INSERT INTO voice_intents (intent_key, category, spoken_label, requires_server)
            VALUES (:key, :cat, :spoken, :srv)
            ON CONFLICT (intent_key) DO UPDATE
                SET category        = EXCLUDED.category,
                    spoken_label    = EXCLUDED.spoken_label,
                    requires_server = EXCLUDED.requires_server
            """,
            {"key": key, "cat": category, "spoken": spoken, "srv": needs_server},
        )
        row = fetch_one(
            "SELECT id FROM voice_intents WHERE intent_key = :key", {"key": key}
        )
        if not row:
            continue
        for phrase in phrases:
            execute(
                """
                INSERT INTO intent_phrases (intent_id, phrase)
                VALUES (:iid, :phrase)
                ON CONFLICT (intent_id, phrase) DO NOTHING
                """,
                {"iid": row["id"], "phrase": phrase},
            )


def _seed_denominations() -> None:
    for value, words, emissions, color, idx, active in DENOMINATIONS:
        execute(
            """
            INSERT INTO money_denominations
                (value_idr, words, emissions, color_name, class_index, active)
            VALUES (:v, :w, :e, :c, :i, :a)
            ON CONFLICT (value_idr) DO UPDATE
                SET words       = EXCLUDED.words,
                    emissions   = EXCLUDED.emissions,
                    color_name  = EXCLUDED.color_name,
                    class_index = EXCLUDED.class_index,
                    active      = EXCLUDED.active
            """,
            {"v": value, "w": words, "e": emissions, "c": color, "i": idx, "a": active},
        )


def _seed_manifest() -> None:
    for key, version, filename, fmt, min_app, mandatory, notes in MANIFEST:
        execute(
            """
            INSERT INTO model_manifest
                (model_key, version, filename, format, min_app_version, mandatory, notes,
                 url_path, available)
            VALUES (:k, :v, :f, :fmt, :min, :mand, :notes, :url, FALSE)
            ON CONFLICT (model_key) DO UPDATE
                SET notes = EXCLUDED.notes
            """,
            {"k": key, "v": version, "f": filename, "fmt": fmt, "min": min_app,
             "mand": mandatory, "notes": notes,
             "url": f"/api/models/download/{key}"},
        )
