import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../providers/settings_provider.dart' show Verbosity;

/// Filter pipeline - dipanggil oleh BOTH TFLite dan Server result.
/// Satu instance, state persist selama sesi aktif.
///
/// Fix dari doc 5 masalah 5:
/// - Streak hanya di-increment SETELAH lolos distance + confidence filter
/// - Cooldown berbeda per tier (Netra AI: critical=2s, warning=3s, info=5s)
///
/// Fix temuan 2B - kunci cooldown dan streak adalah **identitas objek**
/// ([Detection.filterKey], berasal dari `trackId` SORT), bukan lagi `labelEn`.
/// Dengan kunci label, dua orang di frame yang sama dianggap satu objek:
/// orang yang jauh diumumkan lebih dulu, lalu orang yang dekat dan sedang
/// mendekat ikut kena cooldown "person" dan **tidak diumumkan sama sekali**
/// sampai 2 detik berlalu. Persis kebalikan dari yang dibutuhkan.
class DetectionFilter {
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<String, int>      _streak        = {};

  // streakRequired=2: SSD MobileNet tidak konsisten antar frame (objek bisa
  // flash 1 frame lalu hilang). Minimal 2 frame berturut-turut memastikan
  // deteksi stabil sebelum popup muncul dan TTS disuarakan.
  static const int    _streakRequired = 2;
  static const double _minConfidence  = 0.5;  // SSD lebih noisy, threshold lebih tinggi dari YOLO

  /// PG-06 "Ambang jarak peringatan" (1–5 m) - objek lebih jauh dari ini tidak
  /// diumumkan. Diisi `SettingsProvider`; dulu nilainya konstanta 10 m dan
  /// slider di Pengaturan tidak berpengaruh sama sekali.
  ///
  /// Slider ini mengubah **frekuensi peringatan**, yang untuk sebagian
  /// pengguna adalah selisih antara berguna dan tidak tertahankan: 5 m di
  /// koridor ramai berarti bicara terus-menerus.
  double _maxDistance = 10.0;

  /// PG-05 "Tingkat kecerewetan" - menentukan berapa banyak yang diumumkan
  /// sekaligus, bukan hanya panjang kalimatnya.
  Verbosity _verbosity = Verbosity.sedang;

  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _maxDistance = maxDistanceM;
    _verbosity = verbosity;
  }

  List<Detection> process(List<Detection> raw) {
    final currentKeys = raw.map((d) => d.filterKey).toSet();

    // Buang streak untuk objek yang hilang dari frame ini. Cooldown sengaja
    // TIDAK ikut dibuang: objek yang berkelip hilang-muncul satu frame tidak
    // boleh mendapat izin bicara ulang seketika.
    _streak.removeWhere((key, _) => !currentKeys.contains(key));

    // Batasi pertumbuhan _lastAnnounced. trackId terus bertambah sepanjang
    // sesi, jadi tanpa ini map-nya tumbuh selamanya di perjalanan panjang.
    if (_lastAnnounced.length > 200) _pruneAnnounced();

    final approved = <Detection>[];

    for (final det in raw) {
      final key = det.filterKey;

      // [1] Distance filter
      if (det.distanceMeter > _maxDistance) {
        continue;
      }

      // [2] Confidence filter
      if (det.confidence < _minConfidence) {
        continue;
      }

      // [3] Increment streak HANYA untuk yang lolos distance + confidence
      _streak[key] = (_streak[key] ?? 0) + 1;

      // [4] Stability check
      if ((_streak[key] ?? 0) < _streakRequired) {
        continue;
      }

      // [5] Cooldown per tier
      final cooldown = _cooldownFor(det);
      final last     = _lastAnnounced[key];
      final now      = DateTime.now();
      if (last != null && now.difference(last) < cooldown) {
        continue;
      }

      // [6] Lolos semua
      _lastAnnounced[key] = now;
      approved.add(det);
    }

    // [7] Sort: critical → warning → info, lalu jarak terdekat
    approved.sort((a, b) {
      final pa = _prio(a.dangerLevel);
      final pb = _prio(b.dangerLevel);
      if (pa != pb) return pa.compareTo(pb);
      return a.distanceMeter.compareTo(b.distanceMeter);
    });

    // [8] Berapa banyak yang boleh bicara sekaligus - PG-05. Batas atas tetap
    // 2 (Cognitive Load Theory, dan kontrak zona hanya menampung 2 kartu);
    // "ringkas" memangkasnya jadi satu supaya hanya yang paling mendesak
    // terdengar.
    final maxPerCycle = switch (_verbosity) {
      Verbosity.ringkas => 1,
      _ => 2,
    };

    if (approved.isNotEmpty) {
      debugPrint('[Filter] lolos ${approved.length}/${raw.length}: '
          '${approved.take(maxPerCycle).map((d) => '${d.labelEn}#${d.trackId}(${d.dangerLevel})').join(' | ')}');
    }

    return approved.take(maxPerCycle).toList();
  }

  /// Buang catatan cooldown yang jauh lebih lama dari cooldown terpanjang -
  /// objek itu sudah pasti tidak akan tertahan lagi.
  void _pruneAnnounced() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
    _lastAnnounced.removeWhere((_, at) => at.isBefore(cutoff));
  }

  int _prio(String danger) => switch (danger) {
        'critical' => 0,
        'warning'  => 1,
        _          => 2,
      };

  /// Cooldown berbeda per tier, dipotong 50% jika objek sedang mendekat.
  /// Ref: Netra AI paper - critical=2s, warning=3s, info=5s sebagai base.
  Duration _cooldownFor(Detection det) {
    final base = switch (det.dangerLevel) {
      'critical' => const Duration(seconds: 2),
      'warning'  => const Duration(seconds: 3),
      _          => const Duration(seconds: 5),
    };

    // PG-05 - kecerewetan menggeser jeda antar pengumuman. Critical TIDAK
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
