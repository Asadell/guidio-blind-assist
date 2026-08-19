import 'dart:math';
import '../models/detection.dart';
import 'camera_health_service.dart';

/// TrackedObject — state satu objek yang sedang di-track.
///
/// ## Kompensasi ayunan tangan
///
/// Pengguna memegang ponsel sambil berjalan, jadi ponselnya ikut mengayun.
/// Ayunan itu membuat kotak deteksi membesar-mengecil sendiri, sehingga objek
/// yang sebenarnya diam terbaca "maju-mundur". Dua akibatnya nyata:
///
/// 1. Jarak yang diucapkan melompat-lompat ("dua meter… satu meter… dua
///    meter") padahal tidak ada yang bergerak.
/// 2. Aturan lama — `area > lastArea * 1.20` dari **satu** frame ke frame
///    berikutnya — menyalakan `isApproaching` pada ayunan biasa, dan itu
///    memotong cooldown jadi separuh. Peringatan jadi lebih sering justru
///    karena tangan bergoyang, bukan karena ada bahaya mendekat.
///
/// Perbaikannya tidak butuh matematika gyroscope: dua EMA jarak dengan
/// kecepatan berbeda, plus syarat tren yang harus bertahan beberapa frame.
/// Saat [CameraHealthService.motionLevel] tinggi, penghalusan diperlambat dan
/// ambangnya dinaikkan — sinyal yang berisik diperlakukan sebagai sinyal yang
/// berisik, bukan sebagai kebenaran.
class TrackedObject {
  final int    id;
  final String label;      // labelEn dari Detection
  double cx, cy, w, h;
  int    missedFrames = 0;

  /// EMA cepat & lambat dari jarak. Perpotongan keduanya = arah tren.
  double? _fastDist;
  double? _slowDist;

  /// Berapa frame berturut-turut tren menunjukkan mendekat.
  int _approachStreak = 0;

  /// Jarak yang sudah dihaluskan — inilah yang layak diucapkan ke pengguna.
  /// Null sebelum ada satu pun pembaruan jarak.
  double? get smoothedDistance => _slowDist;

  /// Butuh tren mendekat yang bertahan, bukan satu frame yang kebetulan besar.
  bool get isApproaching => _approachStreak >= _approachStreakRequired;

  static const int _approachStreakRequired = 3;

  TrackedObject({
    required this.id,
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  });

  void update(
    double newCx,
    double newCy,
    double newW,
    double newH, {
    double? distanceMeter,
    double motionLevel = 0.0,
  }) {
    cx = newCx; cy = newCy;
    w  = newW;  h  = newH;
    missedFrames = 0;

    if (distanceMeter == null || distanceMeter <= 0 || distanceMeter > 500) return;

    // Makin goyang, makin lambat percaya pada nilai baru.
    final shake = motionLevel.clamp(0.0, 1.0);
    final alphaFast = 0.50 - 0.20 * shake; // 0.50 tenang → 0.30 goyang
    final alphaSlow = 0.18 - 0.08 * shake; // 0.18 tenang → 0.10 goyang

    _fastDist = _fastDist == null
        ? distanceMeter
        : _fastDist! + alphaFast * (distanceMeter - _fastDist!);
    _slowDist = _slowDist == null
        ? distanceMeter
        : _slowDist! + alphaSlow * (distanceMeter - _slowDist!);

    // Mendekat = EMA cepat turun cukup jauh di bawah EMA lambat. Marginnya
    // melebar saat goyang supaya derau ayunan tidak lolos sebagai tren.
    final margin = 0.06 + 0.08 * shake; // 6% tenang → 14% goyang
    final approachingNow = _fastDist! < _slowDist! * (1 - margin);

    _approachStreak = approachingNow ? _approachStreak + 1 : 0;
  }
}

/// ObjectTracker — SORT (Simple Online Realtime Tracking) pure Dart.
///
/// Tidak ada library eksternal. Cocok untuk 5–15 objek per frame.
/// Manfaat utama untuk Guidio:
/// 1. Streak counter tidak ter-reset akibat flickering (satu objek = satu ID)
/// 2. Deteksi objek mendekat (isApproaching) → cooldown diperpendek 50%
class ObjectTracker {
  final Map<int, TrackedObject> _tracks = {};
  int _nextId = 0;

  /// Minimal IoU untuk menganggap dua bbox sebagai objek yang sama.
  static const double _iouThreshold   = 0.3;

  /// Hapus track setelah N frame tidak terdeteksi.
  static const int    _maxMissedFrames = 5;

  /// Track yang dipasangkan ke tiap deteksi pada pemanggilan [update]
  /// terakhir, sejajar indeks dengan daftar deteksi yang dikirim.
  ///
  /// Ini yang membuat cooldown bisa dikunci per objek, bukan per kelas.
  /// Tanpa pemetaan ini, pemanggil hanya bisa mencocokkan track lewat label —
  /// dan dengan dua objek sekelas di frame, yang ketemu selalu track pertama,
  /// sehingga status "mendekat" milik objek jauh bisa menempel ke objek dekat.
  List<TrackedObject?> _lastAssignment = const [];
  List<TrackedObject?> get lastAssignment => List.unmodifiable(_lastAssignment);

  /// Update tracker dengan list deteksi frame terbaru.
  /// Return: semua TrackedObject yang masih aktif.
  List<TrackedObject> update(List<Detection> detections) {
    final assignment = List<TrackedObject?>.filled(detections.length, null);

    if (detections.isEmpty) {
      for (final t in _tracks.values) {
        t.missedFrames++;
      }
      _prune();
      _lastAssignment = assignment;
      return _tracks.values.toList();
    }

    // Dibaca sekali per frame: seberapa kuat ponsel sedang mengayun.
    final motion = CameraHealthService.instance.motionLevel;

    final matched   = <int>{};    // index detection yang sudah di-assign
    final trackList = _tracks.values.toList();

    for (final track in trackList) {
      double bestIou = _iouThreshold;
      int    bestIdx = -1;

      for (int i = 0; i < detections.length; i++) {
        if (matched.contains(i)) continue;
        // Hanya match dengan label yang sama — tidak cross-class matching
        if (detections[i].labelEn != track.label) continue;

        final iou = _iou(
          track.cx, track.cy, track.w, track.h,
          detections[i].bboxCx, detections[i].bboxCy,
          detections[i].bboxW,  detections[i].bboxH,
        );

        if (iou > bestIou) {
          bestIou = iou;
          bestIdx = i;
        }
      }

      if (bestIdx >= 0) {
        final d = detections[bestIdx];
        track.update(
          d.bboxCx, d.bboxCy, d.bboxW, d.bboxH,
          distanceMeter: d.distanceMeter,
          motionLevel: motion,
        );
        matched.add(bestIdx);
        assignment[bestIdx] = track;
      } else {
        track.missedFrames++;
      }
    }

    // Detection yang tidak di-assign → buat track baru
    for (int i = 0; i < detections.length; i++) {
      if (matched.contains(i)) continue;
      final d = detections[i];
      final t = TrackedObject(
        id:    _nextId++,
        label: d.labelEn,
        cx:    d.bboxCx, cy: d.bboxCy,
        w:     d.bboxW,  h:  d.bboxH,
      )..update(
          d.bboxCx, d.bboxCy, d.bboxW, d.bboxH,
          distanceMeter: d.distanceMeter,
          motionLevel: motion,
        );
      _tracks[t.id] = t;
      assignment[i] = t;
    }

    _prune();
    _lastAssignment = assignment;
    return _tracks.values.toList();
  }

  void _prune() =>
      _tracks.removeWhere((_, t) => t.missedFrames > _maxMissedFrames);

  /// Intersection over Union dalam pixel coords.
  /// Formula identik dengan normalized coords — unit tidak mempengaruhi rasio.
  double _iou(
    double ax, double ay, double aw, double ah,
    double bx, double by, double bw, double bh,
  ) {
    final aL = ax - aw / 2; final aR = ax + aw / 2;
    final aT = ay - ah / 2; final aB = ay + ah / 2;
    final bL = bx - bw / 2; final bR = bx + bw / 2;
    final bT = by - bh / 2; final bB = by + bh / 2;

    final iL = max(aL, bL); final iR = min(aR, bR);
    final iT = max(aT, bT); final iB = min(aB, bB);

    if (iR <= iL || iB <= iT) return 0.0;

    final inter = (iR - iL) * (iB - iT);
    return inter / (aw * ah + bw * bh - inter);
  }

  /// Reset semua track — dipanggil saat mode berganti (stopRealtime).
  void reset() {
    _tracks.clear();
    _lastAssignment = const [];
    _nextId = 0;
  }
}
