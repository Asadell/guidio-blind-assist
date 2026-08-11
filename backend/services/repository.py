"""Akses data ke PostgreSQL untuk seluruh endpoint penunjang.

Semua fungsi di sini aman dipanggil walau DB mati: pemanggil cukup mengecek
`db.database.is_available()` lebih dulu, atau menangkap exception dan balas
503 dengan pesan yang menyebut apa yang masih hidup.
"""

import json
from datetime import datetime, timedelta, timezone

from db.database import execute, execute_returning, fetch_all, fetch_one

# ── Kamus label ──────────────────────────────────────────────────────────


def get_labels(lang: str = "id") -> list[dict]:
    return fetch_all(
        """
        SELECT label_en, label_local, spoken_form, real_height_cm,
               danger_class, searchable
        FROM object_labels
        WHERE lang = :lang
        ORDER BY label_en
        """,
        {"lang": lang},
    )


def get_searchable_labels(lang: str = "id") -> list[dict]:
    return fetch_all(
        """
        SELECT label_en, label_local
        FROM object_labels
        WHERE lang = :lang AND searchable = TRUE
        ORDER BY label_local
        """,
        {"lang": lang},
    )


def labels_updated_at(lang: str = "id") -> str | None:
    row = fetch_one(
        "SELECT max(updated_at) AS ts FROM object_labels WHERE lang = :lang",
        {"lang": lang},
    )
    return row["ts"].isoformat() if row and row["ts"] else None


# ── Intent suara ─────────────────────────────────────────────────────────


def get_all_intents() -> list[dict]:
    rows = fetch_all(
        """
        SELECT vi.intent_key, vi.category, vi.spoken_label, vi.requires_server,
               coalesce(array_agg(ip.phrase) FILTER (WHERE ip.phrase IS NOT NULL), '{}') AS phrases
        FROM voice_intents vi
        LEFT JOIN intent_phrases ip ON ip.intent_id = vi.id
        GROUP BY vi.id, vi.intent_key, vi.category, vi.spoken_label, vi.requires_server
        ORDER BY vi.category, vi.intent_key
        """
    )
    for r in rows:
        r["phrases"] = list(r["phrases"]) if r["phrases"] else []
    return rows


# ── Denominasi uang ──────────────────────────────────────────────────────


def get_denominations() -> list[dict]:
    return fetch_all(
        """
        SELECT value_idr, words, emissions, color_name, class_index, active
        FROM money_denominations
        WHERE active = TRUE
        ORDER BY class_index
        """
    )


def get_denomination(value_idr: int) -> dict | None:
    return fetch_one(
        "SELECT * FROM money_denominations WHERE value_idr = :v AND active = TRUE",
        {"v": value_idr},
    )


# ── Manifest model ───────────────────────────────────────────────────────


def get_manifest() -> list[dict]:
    return fetch_all(
        """
        SELECT model_key, version, filename, format, sha256, size_bytes,
               url_path, min_app_version, mandatory, notes, available, updated_at
        FROM model_manifest
        ORDER BY model_key
        """
    )


def get_manifest_entry(model_key: str) -> dict | None:
    return fetch_one(
        "SELECT * FROM model_manifest WHERE model_key = :k", {"k": model_key}
    )


def update_manifest_file(
    model_key: str, version: str, filename: str, sha256: str,
    size_bytes: int, available: bool,
) -> None:
    execute(
        """
        UPDATE model_manifest
           SET version    = :v,
               filename   = :f,
               sha256     = :sha,
               size_bytes = :size,
               available  = :avail,
               updated_at = now()
         WHERE model_key = :k
        """,
        {"k": model_key, "v": version, "f": filename, "sha": sha256,
         "size": size_bytes, "avail": available},
    )


# ── Telemetri ────────────────────────────────────────────────────────────


def insert_event(
    device_id: str, event_name: str, mode: str | None,
    gesture_count: int | None, duration_ms: int | None,
    payload: dict, occurred_at: datetime,
) -> None:
    execute(
        """
        INSERT INTO telemetry_events
            (device_id, event_name, mode, gesture_count, duration_ms, payload, occurred_at)
        VALUES (:dev, :name, :mode, :gc, :dur, CAST(:payload AS jsonb), :at)
        """,
        {"dev": device_id, "name": event_name, "mode": mode, "gc": gesture_count,
         "dur": duration_ms, "payload": json.dumps(payload), "at": occurred_at},
    )


def event_summary(hours: int = 24) -> list[dict]:
    """Ringkasan untuk membuktikan target desain (jumlah gestur, waktu buka)."""
    return fetch_all(
        """
        SELECT event_name,
               count(*)                        AS total,
               round(avg(gesture_count)::numeric, 2) AS avg_gestures,
               round(avg(duration_ms)::numeric, 0)   AS avg_duration_ms,
               max(occurred_at)                AS last_seen
        FROM telemetry_events
        WHERE occurred_at > now() - make_interval(hours => :h)
        GROUP BY event_name
        ORDER BY total DESC
        """,
        {"h": hours},
    )


# ── Crash report ─────────────────────────────────────────────────────────


def insert_crash(
    device_id: str, app_version: str | None, platform: str | None,
    os_version: str | None, mode: str | None, error_type: str | None,
    message: str | None, stack_trace: str | None, occurred_at: datetime | None,
) -> int:
    row = execute_returning(
        """
        INSERT INTO crash_reports
            (device_id, app_version, platform, os_version, mode,
             error_type, message, stack_trace, occurred_at)
        VALUES (:dev, :app, :plat, :os, :mode, :etype, :msg, :stack, :at)
        RETURNING id
        """,
        {"dev": device_id, "app": app_version, "plat": platform, "os": os_version,
         "mode": mode, "etype": error_type, "msg": message, "stack": stack_trace,
         "at": occurred_at},
    )
    return row["id"] if row else 0


def last_mode_for_device(device_id: str) -> str | None:
    """ER-06: mode terakhir sebelum crash, untuk dipulihkan saat app dibuka."""
    row = fetch_one(
        """
        SELECT mode FROM crash_reports
        WHERE device_id = :dev AND mode IS NOT NULL
        ORDER BY received_at DESC LIMIT 1
        """,
        {"dev": device_id},
    )
    return row["mode"] if row else None


# ── Antrean unggah offline ───────────────────────────────────────────────


def queue_item_exists(idempotency_key: str) -> dict | None:
    return fetch_one(
        "SELECT idempotency_key, status, result FROM upload_queue WHERE idempotency_key = :k",
        {"k": idempotency_key},
    )


def queue_insert(idempotency_key: str, device_id: str, kind: str,
                 queued_at: datetime | None) -> None:
    execute(
        """
        INSERT INTO upload_queue (idempotency_key, device_id, kind, queued_at)
        VALUES (:k, :dev, :kind, :at)
        ON CONFLICT (idempotency_key) DO NOTHING
        """,
        {"k": idempotency_key, "dev": device_id, "kind": kind, "at": queued_at},
    )


def queue_mark_done(idempotency_key: str, result: dict) -> None:
    execute(
        """
        UPDATE upload_queue
           SET status = 'done', result = CAST(:res AS jsonb), processed_at = now()
         WHERE idempotency_key = :k
        """,
        {"k": idempotency_key, "res": json.dumps(result)},
    )


def queue_mark_failed(idempotency_key: str, error: str) -> None:
    execute(
        """
        UPDATE upload_queue
           SET status = 'failed', error = :err, processed_at = now()
         WHERE idempotency_key = :k
        """,
        {"k": idempotency_key, "err": error},
    )


def queue_pending(device_id: str) -> list[dict]:
    return fetch_all(
        """
        SELECT idempotency_key, kind, status, queued_at
        FROM upload_queue
        WHERE device_id = :dev AND status = 'pending'
        ORDER BY queued_at NULLS LAST
        """,
        {"dev": device_id},
    )


# ── Sesi Asisten Suara ───────────────────────────────────────────────────

HISTORY_TTL_MINUTES = 15


def touch_session(session_id: str, device_id: str) -> None:
    execute(
        """
        INSERT INTO assistant_sessions (session_id, device_id)
        VALUES (:sid, :dev)
        ON CONFLICT (session_id) DO UPDATE
            SET last_activity = now(), expired = FALSE
        """,
        {"sid": session_id, "dev": device_id},
    )


def add_turn(session_id: str, role: str, text_value: str,
             intent_key: str | None = None) -> None:
    execute(
        """
        INSERT INTO assistant_turns (session_id, role, text, intent_key)
        VALUES (:sid, :role, :text, :intent)
        """,
        {"sid": session_id, "role": role, "text": text_value, "intent": intent_key},
    )


def get_turns(session_id: str, limit: int = 20) -> list[dict]:
    rows = fetch_all(
        """
        SELECT role, text, intent_key, created_at
        FROM assistant_turns
        WHERE session_id = :sid
        ORDER BY created_at DESC
        LIMIT :lim
        """,
        {"sid": session_id, "lim": limit},
    )
    return list(reversed(rows))


def expire_stale_sessions() -> int:
    """AS-23 — riwayat lebih dari 15 menit dihapus, dan itu diumumkan app."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=HISTORY_TTL_MINUTES)
    row = execute_returning(
        """
        WITH stale AS (
            UPDATE assistant_sessions
               SET expired = TRUE
             WHERE expired = FALSE AND last_activity < :cutoff
            RETURNING session_id
        )
        SELECT count(*) AS n FROM stale
        """,
        {"cutoff": cutoff},
    )
    n = row["n"] if row else 0
    if n:
        execute(
            """
            DELETE FROM assistant_turns
             WHERE session_id IN (SELECT session_id FROM assistant_sessions WHERE expired = TRUE)
            """
        )
    return n


def session_expired(session_id: str) -> bool:
    row = fetch_one(
        "SELECT expired FROM assistant_sessions WHERE session_id = :sid",
        {"sid": session_id},
    )
    return bool(row and row["expired"])


# ── Risk zone (pindah dari in-memory) ────────────────────────────────────


def risk_zone_report(grid_key: str, lat: float, lng: float, label: str) -> None:
    execute(
        """
        INSERT INTO risk_zones (grid_key, lat, lng, report_count, labels, last_seen)
        VALUES (:k, :lat, :lng, 1, jsonb_build_object(:label, 1), now())
        ON CONFLICT (grid_key) DO UPDATE
            SET report_count = risk_zones.report_count + 1,
                labels       = jsonb_set(
                                   risk_zones.labels,
                                   ARRAY[:label],
                                   to_jsonb(coalesce((risk_zones.labels ->> :label)::int, 0) + 1)
                               ),
                last_seen    = now()
        """,
        {"k": grid_key, "lat": lat, "lng": lng, "label": label},
    )


def risk_zone_nearby(lat: float, lng: float, radius_m: float, min_count: int) -> dict | None:
    """Cari zona bahaya terdekat memakai jarak haversine langsung di SQL."""
    return fetch_one(
        """
        SELECT grid_key, lat, lng, report_count, labels,
               6371000 * 2 * asin(sqrt(
                   power(sin(radians(lat - :lat) / 2), 2) +
                   cos(radians(:lat)) * cos(radians(lat)) *
                   power(sin(radians(lng - :lng) / 2), 2)
               )) AS distance_m
        FROM risk_zones
        WHERE report_count >= :minc
        ORDER BY distance_m ASC
        LIMIT 1
        """,
        {"lat": lat, "lng": lng, "minc": min_count},
    )


# ── Capability override ──────────────────────────────────────────────────


def get_capability_overrides() -> dict[str, dict]:
    rows = fetch_all(
        "SELECT capability, forced_state, reason FROM capability_overrides"
    )
    return {r["capability"]: r for r in rows}
