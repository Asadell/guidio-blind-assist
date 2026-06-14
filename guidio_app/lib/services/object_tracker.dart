import 'dart:math';
import '../models/detection.dart';

/// TrackedObject — state satu objek yang sedang di-track.
class TrackedObject {
  final int    id;
  final String label;      // labelEn dari Detection
  double cx, cy, w, h;
  int    missedFrames = 0;
  double lastArea;
  bool   isApproaching = false; // true jika bbox area tumbuh > 20%

  TrackedObject({
    required this.id,
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  }) : lastArea = w * h;

  void update(double newCx, double newCy, double newW, double newH) {
    final newArea = newW * newH;
    // Objek dianggap mendekat jika area bbox tumbuh > 20% dari frame sebelumnya
    isApproaching = newArea > lastArea * 1.20;
    lastArea      = newArea;
    cx = newCx; cy = newCy;
    w  = newW;  h  = newH;
    missedFrames  = 0;
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

  /// Update tracker dengan list deteksi frame terbaru.
  /// Return: semua TrackedObject yang masih aktif.
  List<TrackedObject> update(List<Detection> detections) {
    if (detections.isEmpty) {
      for (final t in _tracks.values) {
        t.missedFrames++;
      }
      _prune();
      return _tracks.values.toList();
    }

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
        track.update(d.bboxCx, d.bboxCy, d.bboxW, d.bboxH);
        matched.add(bestIdx);
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
      );
      _tracks[t.id] = t;
    }

    _prune();
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
    _nextId = 0;
  }
}
