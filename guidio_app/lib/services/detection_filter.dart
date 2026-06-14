import '../models/detection.dart';

/// Filter pipeline — dipanggil oleh BOTH TFLite dan Server result.
/// Satu instance, state persist selama sesi aktif.
///
/// Fix dari doc 5 masalah 5:
/// - Streak hanya di-increment SETELAH lolos distance + confidence filter
/// - Cooldown berbeda per tier (Netra AI: critical=2s, warning=3s, info=5s)
class DetectionFilter {
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<String, int>      _streak        = {};

  static const int    _streakRequired = 3;
  static const double _maxDistance    = 4.0;
  static const double _minConfidence  = 0.5;

  List<Detection> process(List<Detection> raw) {
    final currentLabels = raw.map((d) => d.labelEn).toSet();

    // Reset streak untuk label yang tidak muncul di frame ini
    for (final label in _streak.keys.toList()) {
      if (!currentLabels.contains(label)) _streak[label] = 0;
    }

    final approved = <Detection>[];

    for (final det in raw) {
      // [1] Distance filter — buang dulu, JANGAN increment streak
      if (det.distanceMeter > _maxDistance) continue;

      // [2] Confidence filter — buang dulu, JANGAN increment streak
      if (det.confidence < _minConfidence) continue;

      // [3] Increment streak HANYA untuk yang lolos distance + confidence
      _streak[det.labelEn] = (_streak[det.labelEn] ?? 0) + 1;

      // [4] Stability check — skip tapi streak sudah di-increment (objek sedang "diantre")
      if ((_streak[det.labelEn] ?? 0) < _streakRequired) continue;

      // [5] Cooldown per tier — skip jika masih dalam cooldown.
      //     Jika objek mendekat (isApproaching), cooldown dipotong 50%.
      final cooldown = _cooldownFor(det);
      final last     = _lastAnnounced[det.labelEn];
      final now      = DateTime.now();
      if (last != null && now.difference(last) < cooldown) continue;

      // [6] Lolos semua — set lastAnnounced, tambah ke approved
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

    // [8] Maks 2 pesan per cycle (sesuai PRD Cognitive Load Theory)
    return approved.take(2).toList();
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
    if (det.isApproaching) {
      return Duration(milliseconds: base.inMilliseconds ~/ 2);
    }
    return base;
  }

  void reset() {
    _lastAnnounced.clear();
    _streak.clear();
  }
}
