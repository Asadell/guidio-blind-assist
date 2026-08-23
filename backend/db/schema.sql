-- Skema Vinara/Guidio - PostgreSQL.
-- Tanpa auth: semua identifikasi pakai device_id anonim yang di-generate app.
-- Dijalankan otomatis (idempoten) saat startup oleh db/database.py.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Risk zone - dulu in-memory di risk_zone_service.py, sekarang persisten.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS risk_zones (
    id           BIGSERIAL PRIMARY KEY,
    grid_key     TEXT UNIQUE NOT NULL,          -- lat/lng dibulatkan 4 desimal (~11 m)
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    report_count INTEGER NOT NULL DEFAULT 0,
    labels       JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_seen    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_risk_zones_latlng ON risk_zones (lat, lng);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Kamus label objek - GET /api/labels?lang=id
--    Dipakai DO-19 (kelas tak dikenal) & DO-08 (nama meluap). Nama kelas
--    mentah model tidak layak dibacakan TTS, jadi pemetaannya harus bisa
--    diperbaiki dari server tanpa rilis ulang aplikasi.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS object_labels (
    id             BIGSERIAL PRIMARY KEY,
    label_en       TEXT NOT NULL,
    lang           TEXT NOT NULL DEFAULT 'id',
    label_local    TEXT NOT NULL,                -- "orang"
    spoken_form    TEXT,                         -- frasa TTS bila beda dari label_local
    real_height_cm INTEGER,                      -- untuk estimasi jarak similar-triangle
    danger_class   TEXT NOT NULL DEFAULT 'info', -- high | medium | info
    searchable     BOOLEAN NOT NULL DEFAULT TRUE,-- boleh jadi target Cari Objek
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (label_en, lang)
);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Perintah suara - POST /api/intent
--    20 intent baku bagian 14. CommandParser lokal tetap jalan lebih dulu;
--    server hanya dipanggil saat lokal tidak match (AS-18 / AS-19).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voice_intents (
    id              BIGSERIAL PRIMARY KEY,
    intent_key      TEXT UNIQUE NOT NULL,        -- mode.money, action.capture, ...
    category        TEXT NOT NULL,               -- mode | action | play | help
    spoken_label    TEXT NOT NULL,               -- "kenali uang" (untuk ditawarkan balik)
    requires_server BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS intent_phrases (
    id        BIGSERIAL PRIMARY KEY,
    intent_id BIGINT NOT NULL REFERENCES voice_intents (id) ON DELETE CASCADE,
    phrase    TEXT NOT NULL,
    UNIQUE (intent_id, phrase)
);
CREATE INDEX IF NOT EXISTS idx_intent_phrases_phrase ON intent_phrases (phrase);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Manifest model on-device - GET /api/models/manifest
--    UG-18: emisi uang baru = update model, bukan update aplikasi.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS model_manifest (
    id              BIGSERIAL PRIMARY KEY,
    model_key       TEXT UNIQUE NOT NULL,        -- detection | money | segmentation
    version         TEXT NOT NULL,
    filename        TEXT NOT NULL,
    format          TEXT NOT NULL DEFAULT 'tflite',
    sha256          TEXT,
    size_bytes      BIGINT,
    url_path        TEXT,                        -- relatif: /api/models/download/<key>
    min_app_version TEXT,
    mandatory       BOOLEAN NOT NULL DEFAULT FALSE,
    notes           TEXT,
    available       BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Telemetri alur - POST /api/events
--    Bukan analitik pemasaran. Yang diukur target desain: jumlah gestur per
--    alur, waktu buka sampai deteksi aktif, perintah suara tak dikenali.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS telemetry_events (
    id          BIGSERIAL PRIMARY KEY,
    device_id   TEXT NOT NULL,
    event_name  TEXT NOT NULL,                   -- flow.pay, mode.enter, voice.unrecognized
    mode        TEXT,
    gesture_count INTEGER,
    duration_ms INTEGER,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_telemetry_name_time ON telemetry_events (event_name, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_telemetry_device ON telemetry_events (device_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 6. Laporan crash - POST /api/crash-report (ER-06 "Kirim laporan")
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crash_reports (
    id           BIGSERIAL PRIMARY KEY,
    device_id    TEXT NOT NULL,
    app_version  TEXT,
    platform     TEXT,
    os_version   TEXT,
    mode         TEXT,                            -- mode terakhir saat crash (dipulihkan ER-06)
    error_type   TEXT,
    message      TEXT,
    stack_trace  TEXT,
    occurred_at  TIMESTAMPTZ,
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crash_time ON crash_reports (received_at DESC);

-- ─────────────────────────────────────────────────────────────────────────
-- 7. Antrean unggah offline - POST /api/queue/flush (BT-13)
--    idempotency_key mencegah dobel saat aplikasi mengirim ulang.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS upload_queue (
    id              BIGSERIAL PRIMARY KEY,
    idempotency_key TEXT UNIQUE NOT NULL,
    device_id       TEXT NOT NULL,
    kind            TEXT NOT NULL,                -- ocr | detect
    status          TEXT NOT NULL DEFAULT 'pending', -- pending | done | failed
    result          JSONB,
    error           TEXT,
    queued_at       TIMESTAMPTZ,
    processed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_queue_device_status ON upload_queue (device_id, status);

-- ─────────────────────────────────────────────────────────────────────────
-- 8. Sesi Asisten Suara - AS-12 (giliran terbaru), AS-13 (riwayat diringkas),
--    AS-23 (riwayat kedaluwarsa 15 menit).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assistant_sessions (
    id            BIGSERIAL PRIMARY KEY,
    session_id    TEXT UNIQUE NOT NULL,
    device_id     TEXT NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_activity TIMESTAMPTZ NOT NULL DEFAULT now(),
    expired       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS assistant_turns (
    id         BIGSERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES assistant_sessions (session_id) ON DELETE CASCADE,
    role       TEXT NOT NULL,                     -- user | vinara
    text       TEXT NOT NULL,
    intent_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_turns_session ON assistant_turns (session_id, created_at);

-- ─────────────────────────────────────────────────────────────────────────
-- 9. Denominasi rupiah - data rujukan untuk Mode Kenali Uang.
--    Klasifikasi nominalnya sendiri ON-DEVICE (TFLite), tabel ini dipakai
--    untuk: manifest model, terbilang kata, dan validasi emisi yang didukung
--    (UG-18 "uang asing / rusak" perlu tahu mana yang memang didukung).
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS money_denominations (
    id         BIGSERIAL PRIMARY KEY,
    value_idr  INTEGER UNIQUE NOT NULL,
    words      TEXT NOT NULL,                     -- "lima puluh ribu rupiah"
    emissions  TEXT NOT NULL DEFAULT '2016,2022',
    color_name TEXT,
    class_index INTEGER,                          -- urutan kelas di model TFLite
    active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- ─────────────────────────────────────────────────────────────────────────
-- 10. Status kemampuan server - GET /api/capabilities
--     Aplikasi perlu tahu mode mana yang server-nya hidup SEBELUM pengguna
--     menekan tombol (menentukan item limited/disabled di ModePickerSheet).
--     Baris ini bisa di-override manual untuk demo/maintenance.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS capability_overrides (
    id          BIGSERIAL PRIMARY KEY,
    capability  TEXT UNIQUE NOT NULL,             -- ocr | assistant | find_object | navigation
    forced_state TEXT,                            -- up | down | limited | NULL (ikut deteksi otomatis)
    reason      TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
