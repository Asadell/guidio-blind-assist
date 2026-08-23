"""Mode Navigasi - segmentasi jalur jadi 3 zona (kiri / tengah / kanan).

Model utama: PIDNet-S ONNX (three-branch, ada cabang khusus boundary, jadi
tepi trotoar presisi - penting karena overlay zona dipakai terus-menerus).
Kalau file model belum ada, service memakai fallback heuristik OpenCV yang
tetap menghasilkan tiga zona berbeda dari isi gambar sungguhan, sehingga
seluruh state NV-03..NV-09 di aplikasi bisa diuji tanpa menunggu model.

Kontrak balasan sama persis untuk kedua jalur, jadi menukar heuristik ke
PIDNet nanti tidak mengubah satu baris pun di sisi Flutter.
"""

import os
import time

import cv2
import numpy as np
from loguru import logger

# Status zona: cocok dengan enum ZoneStatus di Flutter.
SAFE = "safe"
CAUTION = "caution"
DANGER = "danger"
UNKNOWN = "unknown"

# Ambang rasio jalur layak-injak per zona.
SAFE_RATIO = 0.55
CAUTION_RATIO = 0.25


class SegmentationService:
    def __init__(self, model_path: str | None = None, input_size: int | None = None):
        self.model_path = model_path or os.getenv(
            "SEGMENTATION_MODEL", "models/pidnet_s_3zona.onnx"
        )
        self.input_size = int(os.getenv("SEGMENTATION_INPUT", input_size or 512))
        self.session = None
        self.input_name: str | None = None
        self.loaded = False
        self.source = "heuristic"

    def load(self) -> bool:
        """Muat PIDNet ONNX bila ada. Tidak adanya model BUKAN kegagalan -
        fallback heuristik tetap melayani, dan itu dilaporkan apa adanya
        lewat field `source` supaya tidak ada klaim palsu ke pengguna."""
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model segmentasi '{self.model_path}' belum ada - "
                "Mode Navigasi pakai fallback heuristik OpenCV."
            )
            self.source = "heuristic"
            return False
        try:
            import onnxruntime as ort

            opts = ort.SessionOptions()
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            self.session = ort.InferenceSession(
                self.model_path, opts, providers=["CPUExecutionProvider"]
            )
            self.input_name = self.session.get_inputs()[0].name
            self.loaded = True
            self.source = "pidnet"
            logger.success(f"Model segmentasi dimuat: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"Segmentasi gagal dimuat: {e} - pakai fallback heuristik")
            self.source = "heuristic"
            return False

    # ── API utama ────────────────────────────────────────────────────────

    def zones(self, frame: np.ndarray) -> dict:
        t0 = time.time()
        try:
            if self.loaded:
                ratios = self._ratios_from_model(frame)
            else:
                ratios = self._ratios_from_heuristic(frame)
        except Exception as e:
            logger.error(f"Segmentasi error: {e}")
            return {
                "ok": False,
                "source": self.source,
                "zones": {
                    "kiri": self._zone_payload(0.0),
                    "tengah": self._zone_payload(0.0),
                    "kanan": self._zone_payload(0.0),
                },
                "recommended": None,
                "message": "Jalur tidak terbaca. Rintangan tetap diperingatkan.",
                "inference_ms": round((time.time() - t0) * 1000, 1),
            }

        zones = {
            "kiri": self._zone_payload(ratios[0]),
            "tengah": self._zone_payload(ratios[1]),
            "kanan": self._zone_payload(ratios[2]),
        }
        recommended = self._recommend(zones)

        return {
            "ok": True,
            "source": self.source,
            "zones": zones,
            "recommended": recommended,
            "message": self._compose_message(zones, recommended),
            "inference_ms": round((time.time() - t0) * 1000, 1),
        }

    # ── Jalur model ──────────────────────────────────────────────────────

    def _ratios_from_model(self, frame: np.ndarray) -> tuple[float, float, float]:
        """PIDNet 3 kelas: 0 = bukan jalur, 1 = zona aman, 2 = zona waspada."""
        size = self.input_size
        img = cv2.resize(frame, (size, size))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        img = (img - mean) / std
        tensor = np.ascontiguousarray(np.transpose(img, (2, 0, 1))[None])

        logits = self.session.run(None, {self.input_name: tensor})[0]
        mask = logits[0].argmax(0)  # [h, w] indeks kelas per piksel

        h, w = mask.shape
        # Hanya separuh bawah yang relevan: itu bidang tanah di depan kaki.
        ground = mask[h // 2:, :]
        gw = ground.shape[1]
        thirds = [
            ground[:, : gw // 3],
            ground[:, gw // 3: 2 * gw // 3],
            ground[:, 2 * gw // 3:],
        ]
        # Kelas 1 (aman) dihitung penuh, kelas 2 (waspada) setengah bobot.
        return tuple(
            float((z == 1).mean() + 0.5 * (z == 2).mean()) for z in thirds
        )  # type: ignore[return-value]

    # ── Jalur heuristik (tanpa model) ────────────────────────────────────

    def _ratios_from_heuristic(self, frame: np.ndarray) -> tuple[float, float, float]:
        """Perkiraan jalur layak-injak dari keseragaman permukaan.

        Dasarnya: permukaan yang bisa dijalani (trotoar, aspal, lantai)
        cenderung RATA - sedikit tepi, warna konsisten. Rintangan, rumput,
        tangga, dan jalur kendaraan memecah keseragaman itu.

        Bukan pengganti segmentasi sungguhan, tapi memberi keluaran yang
        benar-benar mengikuti isi gambar, bukan angka karangan.
        """
        h, w = frame.shape[:2]
        ground = frame[h // 2:, :]  # separuh bawah = bidang tanah
        gh, gw = ground.shape[:2]

        gray = cv2.cvtColor(ground, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)

        hsv = cv2.cvtColor(ground, cv2.COLOR_BGR2HSV)
        # Petak acuan: tepat di depan kaki pengguna (tengah-bawah).
        ref = hsv[int(gh * 0.75):, int(gw * 0.4): int(gw * 0.6)]
        ref_hue = float(np.median(ref[:, :, 0])) if ref.size else 0.0
        ref_val = float(np.median(ref[:, :, 2])) if ref.size else 0.0

        ratios = []
        for i in range(3):
            x0, x1 = i * gw // 3, (i + 1) * gw // 3
            zone_edges = edges[:, x0:x1]
            zone_hsv = hsv[:, x0:x1]

            # 1. Kerapatan tepi: makin sedikit tepi, makin rata permukaannya.
            edge_density = float(zone_edges.mean()) / 255.0
            smoothness = max(0.0, 1.0 - edge_density * 8.0)

            # 2. Kemiripan warna dengan petak acuan di depan kaki.
            hue_diff = np.abs(zone_hsv[:, :, 0].astype(np.float32) - ref_hue)
            hue_diff = np.minimum(hue_diff, 180.0 - hue_diff)  # hue melingkar
            val_diff = np.abs(zone_hsv[:, :, 2].astype(np.float32) - ref_val)
            similar = float(((hue_diff < 18) & (val_diff < 60)).mean())

            ratios.append(max(0.0, min(1.0, 0.45 * smoothness + 0.55 * similar)))

        return tuple(ratios)  # type: ignore[return-value]

    # ── Pemetaan rasio → status ──────────────────────────────────────────

    def _zone_payload(self, ratio: float) -> dict:
        if ratio >= SAFE_RATIO:
            status = SAFE
        elif ratio >= CAUTION_RATIO:
            status = CAUTION
        else:
            status = DANGER
        return {"status": status, "walkable_ratio": round(ratio, 3)}

    def _recommend(self, zones: dict) -> str | None:
        """Zona tengah menang bila sama-sama aman: berjalan lurus paling murah
        secara kognitif, jangan suruh pengguna geser tanpa alasan."""
        order = ["tengah", "kiri", "kanan"]
        for status in (SAFE, CAUTION):
            best, best_ratio = None, -1.0
            for name in order:
                z = zones[name]
                if z["status"] == status and z["walkable_ratio"] > best_ratio:
                    best, best_ratio = name, z["walkable_ratio"]
            if best:
                return best
        return None

    def _compose_message(self, zones: dict, recommended: str | None) -> str:
        """Naskah NV-03..NV-07. Darurat maksimal 2,5 detik: kata pembeda di depan."""
        statuses = {k: v["status"] for k, v in zones.items()}

        if all(s == DANGER for s in statuses.values()):
            return "Berhenti dulu. Tidak ada jalur aman di sekitar sini."
        if statuses["tengah"] == DANGER:
            sisi = recommended or "kiri atau kanan"
            return f"Jalur kendaraan di tengah. Geser ke {sisi}."
        if all(s == SAFE for s in statuses.values()):
            return "Jalur aman, jalan lurus."
        if recommended:
            return f"Tetap di {recommended}."
        return "Pelan-pelan, jalur kurang jelas."
