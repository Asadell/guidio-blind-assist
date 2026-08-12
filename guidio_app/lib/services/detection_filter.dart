import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../providers/settings_provider.dart' show Verbosity;

/// Filter pipeline — dipanggil oleh BOTH TFLite dan Server result.
/// Satu instance, state persist selama sesi aktif.
///
/// Fix dari doc 5 masalah 5:
/// - Streak hanya di-increment SETELAH lolos distance + confidence filter
/// - Cooldown berbeda per tier (Netra AI: critical=2s, warning=3s, info=5s)
class DetectionFilter {
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<String, int>      _streak        = {};

  // streakRequired=2: SSD MobileNet tidak konsisten antar frame (objek bisa
  // flash 1 frame lalu hilang). Minimal 2 frame berturut-turut memastikan
  // deteksi stabil sebelum popup muncul dan TTS disuarakan.
  static const int    _streakRequired = 2;
  static const double _minConfidence  = 0.5;  // SSD lebih noisy, threshold lebih tinggi dari YOLO

  /// PG-06 "Ambang jarak peringatan" (1–5 m) — objek lebih jauh dari ini tidak
  /// diumumkan. Diisi `SettingsProvider`; dulu nilainya konstanta 10 m dan
  /// slider di Pengaturan tidak berpengaruh sama sekali.
  ///
  /// Slider ini mengubah **frekuensi peringatan**, yang untuk sebagian
  /// pengguna adalah selisih antara berguna dan tidak tertahankan: 5 m di
  /// koridor ramai berarti bicara terus-menerus.
  double _maxDistance = 10.0;

  /// PG-05 "Tingkat kecerewetan" — menentukan berapa banyak yang diumumkan
  /// sekaligus, bukan hanya panjang kalimatnya.
  Verbosity _verbosity = Verbosity.sedang;

  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _maxDistance = maxDistanceM;
    _verbosity = verbosity;
  }

  List<Detection> process(List<Detection> raw) {
    final currentLabels = raw.map((d) => d.labelEn).toSet();

    // Remove streak entry untuk label yang hilang dari frame ini
    for (final label in _streak.keys.toList()) {
      if (!currentLabels.contains(label)) {
        _streak.remove(label);
      }
    }

    final approved = <Detection>[];

    for (final det in raw) {
      // [1] Distance filter
      if (det.distanceMeter > _maxDistance) {
        debugPrint('[Filter] DROP ${det.labelEn}: '
            'jarak ${det.distanceMeter.toStringAsFixed(1)}m > ${_maxDistance}m');
        continue;
      }

      // [2] Confidence filter
      if (det.confidence < _minConfidence) {
        debugPrint('[Filter] DROP ${det.labelEn}: '
            'confidence ${det.confidence.toStringAsFixed(2)} < $_minConfidence');
        continue;
      }

      // [3] Increment streak HANYA untuk yang lolos distance + confidence
      _streak[det.labelEn] = (_streak[det.labelEn] ?? 0) + 1;

      // [4] Stability check
      if ((_streak[det.labelEn] ?? 0) < _streakRequired) {
        debugPrint('[Filter] STREAK ${det.labelEn}: '
            '${_streak[det.labelEn]}/$_streakRequired frame');
        continue;
      }

      // [5] Cooldown per tier
      final cooldown = _cooldownFor(det);
      final last     = _lastAnnounced[det.labelEn];
      final now      = DateTime.now();
      if (last != null && now.difference(last) < cooldown) {
        final sisa = cooldown - now.difference(last);
        debugPrint('[Filter] COOLDOWN ${det.labelEn}: '
            'sisa ${sisa.inMilliseconds}ms');
        continue;
      }

      // [6] Lolos semua
      _lastAnnounced[det.labelEn] = now;
      approved.add(det);
    }

    // [7] Sort: critical → warning → info, lalu jarak terdekat
    approved.sort((a, b) {
      final pa = _prio(a.dangerLevel);
      final pb = _prio(b.dangerLevel);
      if (pa != pb) return pa.compareTo(pb);
      return a.distanceMeter.compareTo(b.distanceMeter);
    });

    // [8] Berapa banyak yang boleh bicara sekaligus — PG-05. Batas atas tetap
    // 2 (Cognitive Load Theory, dan kontrak zona hanya menampung 2 kartu);
    // "ringkas" memangkasnya jadi satu supaya hanya yang paling mendesak
    // terdengar.
    final maxPerCycle = switch (_verbosity) {
      Verbosity.ringkas => 1,
      _ => 2,
    };
    return approved.take(maxPerCycle).toList();
  }

  int _prio(String danger) => switch (danger) {
        'critical' => 0,
        'warning'  => 1,
        _          => 2,
      };

  /// Cooldown berbeda per tier, dipotong 50% jika objek sedang mendekat.
  /// Ref: Netra AI paper — critical=2s, warning=3s, info=5s sebagai base.
  Duration _cooldownFor(Detection det) {
    final base = switch (det.dangerLevel) {
      'critical' => const Duration(seconds: 2),
      'warning'  => const Duration(seconds: 3),
      _          => const Duration(seconds: 5),
    };

    // PG-05 — kecerewetan menggeser jeda antar pengumuman. Critical TIDAK
    // ikut digeser: seberapa pun pengguna ingin sepi, peringatan bahaya
    // tidak boleh ditahan lebih lama.
    final scaled = det.dangerLevel == 'critical'
        ? base
        : switch (_verbosity) {
            Verbosity.ringkas => base * 2.0,
            Verbosity.sedang => base,
            Verbosity.detail => base * 0.6,
          };

    if (det.isApproaching) {
      return Duration(milliseconds: scaled.inMilliseconds ~/ 2);
    }
    return scaled;
  }

  void reset() {
    _lastAnnounced.clear();
    _streak.clear();
  }
}
