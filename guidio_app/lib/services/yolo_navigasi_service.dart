import 'dart:io';
import 'dart:math';


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';

// ─────────────────────────────────────────────────────────────
// Kelas navigasi custom (6 kelas) — urutan sesuai training
// ─────────────────────────────────────────────────────────────
const List<String> _navLabels = [
  'lubang',
  'got_terbuka',
  'tangga',
  'orang',
  'motor',
  'tiang',
];

// Tinggi nyata (cm) untuk estimasi jarak via Similar Triangles
const Map<String, int> _realHeightsNav = {
  'lubang':      15,
  'got_terbuka': 20,
  'tangga':      20,
  'orang':      170,
  'motor':      120,
  'tiang':      300,
};

// Focal length piksel (default kalibrasi kamera belakang ~f=615)
const int _focalPx = 615;

// Confidence threshold
const double _confThresh = 0.30;

// IoU threshold untuk NMS
const double _iouThresh = 0.45;

// YOLO input size
const int _yoloSize = 640;

// ─────────────────────────────────────────────────────────────
// YoloNavigasiService — deteksi rintangan on-device (YOLO11n)
// ─────────────────────────────────────────────────────────────
class YoloNavigasiService {
  static final YoloNavigasiService instance = YoloNavigasiService._();
  YoloNavigasiService._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Faktor pengali koordinat kotak, ditentukan saat model dimuat.
  ///
  /// 1.0 kalau model mengeluarkan PIXEL (0..640), 640.0 kalau TERNORMALISASI
  /// (0..1). Lihat [_probeBoxScale] untuk alasan kenapa ini dideteksi alih-alih
  /// dipatok.
  double _boxScale = 1.0;

  /// Muat model deteksi rintangan navigasi (6 kelas) dari assets.
  Future<bool> tryLoad() async {
    try {
      final bd = await rootBundle.load('assets/models/yolo11n_navigasi.tflite');
      final bytes = bd.buffer.asUint8List();
      debugPrint('[YOLO-Nav] Memuat model ${(bytes.length / 1024).toStringAsFixed(0)} KB');

      final options = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(bytes, options: options);

      final inputShape  = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      debugPrint('[YOLO-Nav] Input: $inputShape  Output: $outputShape');

      // Bentuk input WAJIB dicek, bukan diasumsikan.
      //
      // Model yang dibundel sebelumnya berbentuk NCHW [1,3,640,640] sementara
      // kode ini menyusun input NHWC [1,640,640,3]. Interpreter menolaknya,
      // pengecualiannya tertangkap di bawah, dan `detect()` mengembalikan
      // daftar kosong pada SETIAP frame — mode navigasi berjalan tanpa pernah
      // melaporkan satu pun rintangan, tanpa satu pun tanda di layar bahwa
      // ada yang salah.
      if (inputShape.length != 4 ||
          inputShape[1] != _yoloSize ||
          inputShape[2] != _yoloSize ||
          inputShape[3] != 3) {
        debugPrint('[YOLO-Nav] TOLAK: input $inputShape bukan NHWC '
            '[1,$_yoloSize,$_yoloSize,3]. Model ini tidak cocok dengan '
            'penyusun input di detect().');
        return false;
      }
      final expectedCh = 4 + _navLabels.length;
      if (outputShape.length != 3 || outputShape[1] != expectedCh) {
        debugPrint('[YOLO-Nav] TOLAK: output $outputShape, diharapkan '
            'channel $expectedCh (4 kotak + ${_navLabels.length} kelas).');
        return false;
      }

      _boxScale = _probeBoxScale(interpreter, outputShape[2]);

      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[YOLO-Nav] Model siap. Kelas: $_navLabels  '
          'skalaKotak: $_boxScale');
      return true;
    } catch (e) {
      debugPrint('[YOLO-Nav] Gagal load: $e');
      return false;
    }
  }

  /// Tentukan apakah model mengeluarkan koordinat pixel atau ternormalisasi,
  /// dengan menjalankan satu inferensi percobaan saat muat.
  ///
  /// ## Kenapa dideteksi, bukan dipatok
  ///
  /// Dua jalur ekspor yang sama-sama wajar memberi konvensi yang BERBEDA:
  ///
  ///   - `onnx2tf` (dipakai untuk model ini) meneruskan graf apa adanya, jadi
  ///     koordinatnya PIXEL 0..640, sama seperti ONNX aslinya.
  ///   - `yolo export format=tflite` milik Ultralytics menambahkan pembagian
  ///     dengan imgsz, jadi koordinatnya TERNORMALISASI 0..1.
  ///
  /// Model yang dibundel sebelumnya memakai konvensi kedua, model ini yang
  /// pertama. Memakai pengali yang salah menggeser setiap kotak sejauh 640
  /// kali — semuanya terdorong ke tepi frame lalu ter-clamp, jadi jaraknya
  /// ngawur dan arahnya selalu sama.
  ///
  /// Dan yang membuatnya berbahaya: TIDAK ADA error. Modelnya termuat,
  /// inferensinya jalan, kotaknya keluar. Hanya isinya yang salah, di mode
  /// yang tugasnya memperingatkan lubang di depan kaki pengguna tunanetra.
  ///
  /// Satu inferensi saat muat jauh lebih murah daripada menaruh asumsi ini
  /// di komentar dan berharap orang berikutnya membacanya.
  double _probeBoxScale(Interpreter interpreter, int anchors) {
    try {
      // Abu-abu netral: tidak memicu apa pun, tapi tetap menghasilkan
      // koordinat kotak di seluruh anchor.
      final probe = List.generate(1, (_) =>
        List.generate(_yoloSize, (_) =>
          List.generate(_yoloSize, (_) => [0.5, 0.5, 0.5])));
      final out = [List.generate(4 + _navLabels.length,
          (_) => List.filled(anchors, 0.0))];
      interpreter.run(probe, out);

      var maxCoord = 0.0;
      for (var c = 0; c < 4; c++) {
        for (final v in out[0][c]) {
          if (v > maxCoord) maxCoord = v;
        }
      }
      // Koordinat ternormalisasi tidak pernah jauh melewati 1,0. Ambang 2,0
      // memberi ruang aman tanpa mendekati rentang pixel yang ratusan.
      final pixels = maxCoord > 2.0;
      debugPrint('[YOLO-Nav] koordinat maks percobaan=${maxCoord.toStringAsFixed(3)} '
          '-> ${pixels ? "PIXEL" : "TERNORMALISASI"}');
      return pixels ? 1.0 : _yoloSize.toDouble();
    } catch (e) {
      // Gagal menyelidiki bukan alasan menolak model. Kembali ke konvensi
      // model yang sedang dibundel.
      debugPrint('[YOLO-Nav] percobaan skala kotak gagal ($e), pakai PIXEL');
      return 1.0;
    }
  }

  /// Deteksi rintangan dari bytes RGB888.
  /// [origW], [origH] = dimensi asli frame sebelum resize.
  Future<List<Detection>> detect(
    Uint8List rgbBytes,
    int origW,
    int origH,
  ) async {
    if (!_loaded || _interpreter == null) return [];

    final t0 = DateTime.now();
    try {
      // Decode → resize ke 640×640
      final rawImg = img.Image.fromBytes(
        width: origW,
        height: origH,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );

      img.Image resized;
      if (Platform.isAndroid) {
        final rotated = img.copyRotate(rawImg, angle: 90);
        resized = img.copyResize(rotated, width: _yoloSize, height: _yoloSize,
            interpolation: img.Interpolation.linear);
      } else {
        resized = img.copyResize(rawImg, width: _yoloSize, height: _yoloSize,
            interpolation: img.Interpolation.linear);
      }

      // Build input [1][640][640][3] — float32 normalized 0..1
      final input = List.generate(1, (_) =>
        List.generate(_yoloSize, (y) =>
          List.generate(_yoloSize, (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          }),
        ),
      );

      // Output [1][10][8400] — 10 = 4 (box) + 6 (class scores)
      final output = [List.generate(10, (_) => List.filled(8400, 0.0))];
      final outputs = {0: output};

      await _interpreter!.runForMultipleInputs([input], outputs);

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();

      // Post-process
      return _postProcess(output[0], inferMs, origW, origH);
    } catch (e) {
      debugPrint('[YOLO-Nav] detect error: $e');
      return [];
    }
  }

  // ── Post-process output [10][8400] ──────────────────────────
  List<Detection> _postProcess(
    List<List<double>> raw, // [10][8400]
    double inferMs,
    int origW,
    int origH,
  ) {
    // raw[0..3] = cx, cy, w, h (normalized 0..1)
    // raw[4..9] = class scores
    final numAnchors = raw[0].length; // 8400
    final numClasses = _navLabels.length; // 6

    // Kumpulkan box yang lolos threshold
    final List<_Box> boxes = [];
    for (int i = 0; i < numAnchors; i++) {
      // Cari kelas dengan skor tertinggi
      double maxScore = 0;
      int maxClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = raw[4 + c][i];
        if (score > maxScore) { maxScore = score; maxClass = c; }
      }
      // Threshold khusus: 0.05 (5%) untuk lubang/got_terbuka, 0.30 (30%) untuk kelas lainnya
      final thresh = (maxClass == 0 || maxClass == 1) ? 0.05 : _confThresh;
      if (maxScore < thresh) continue;

      // cx, cy, w, h → x1, y1, x2, y2 (dalam skala input 640×640).
      //
      // `_boxScale` ditentukan saat muat lewat [_probeBoxScale]: 1.0 kalau
      // model sudah mengeluarkan pixel, 640 kalau ternormalisasi.
      final cx = raw[0][i] * _boxScale;
      final cy = raw[1][i] * _boxScale;
      final bw = raw[2][i] * _boxScale;
      final bh = raw[3][i] * _boxScale;

      boxes.add(_Box(
        x1:       (cx - bw / 2).clamp(0, _yoloSize.toDouble()),
        y1:       (cy - bh / 2).clamp(0, _yoloSize.toDouble()),
        x2:       (cx + bw / 2).clamp(0, _yoloSize.toDouble()),
        y2:       (cy + bh / 2).clamp(0, _yoloSize.toDouble()),
        score:    maxScore,
        classIdx: maxClass,
      ));
    }

    if (boxes.isEmpty) return [];

    // NMS per kelas
    final kept = _nms(boxes);

    // Skala kembali ke ukuran frame asli
    final scaleX = origW / _yoloSize;
    final scaleY = origH / _yoloSize;

    return kept.map((b) {
      final x1 = (b.x1 * scaleX).round().clamp(0, origW - 1);
      final y1 = (b.y1 * scaleY).round().clamp(0, origH - 1);
      final x2 = (b.x2 * scaleX).round().clamp(0, origW - 1);
      final y2 = (b.y2 * scaleY).round().clamp(0, origH - 1);
      final boxH = y2 - y1;
      final cx   = (x1 + x2) / 2.0;

      final label   = _navLabels[b.classIdx];
      final dist    = _estimateDist(label, boxH);
      final dir     = _direction(cx, origW);
      final danger  = _dangerLevel(label, dist);

      return Detection(
        labelEn:       label,
        labelId:       label, // label sudah dalam BI
        confidence:    b.score,
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
        inferenceMs:   inferMs,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));
  }

  // ── NMS greedy per kelas ─────────────────────────────────────
  List<_Box> _nms(List<_Box> boxes) {
    // Sort descending per score
    boxes.sort((a, b) => b.score.compareTo(a.score));
    final kept = <_Box>[];
    final suppressed = List<bool>.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (boxes[i].classIdx != boxes[j].classIdx) continue;
        if (_iou(boxes[i], boxes[j]) > _iouThresh) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  double _iou(_Box a, _Box b) {
    final ix1 = max(a.x1, b.x1);
    final iy1 = max(a.y1, b.y1);
    final ix2 = min(a.x2, b.x2);
    final iy2 = min(a.y2, b.y2);
    final inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1);
    if (inter == 0) return 0;
    final aA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final bA = (b.x2 - b.x1) * (b.y2 - b.y1);
    return inter / (aA + bA - inter);
  }

  double _estimateDist(String label, int boxH) {
    if (boxH <= 0) return 999.0;
    final realH = _realHeightsNav[label] ?? 50;
    return (realH * _focalPx) / (boxH * 100.0);
  }

  String _direction(double cx, int w) {
    final t = w / 3;
    if (cx < t) return 'kiri';
    if (cx < t * 2) return 'depan';
    return 'kanan';
  }

  String _dangerLevel(String label, double dist) {
    switch (label) {
      case 'lubang':
      case 'got_terbuka':
        if (dist < 1.0) return 'critical';
        if (dist < 2.5) return 'warning';
        return 'info';
      case 'orang':
      case 'motor':
        if (dist < 1.5) return 'critical';
        if (dist < 3.0) return 'warning';
        return 'info';
      case 'tangga':
      case 'tiang':
        if (dist < 2.0) return 'critical';
        if (dist < 4.0) return 'warning';
        return 'info';
      default:
        return 'info';
    }
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}

// Helper box untuk NMS
class _Box {
  final double x1, y1, x2, y2, score;
  final int classIdx;
  const _Box({
    required this.x1, required this.y1,
    required this.x2, required this.y2,
    required this.score, required this.classIdx,
  });
}
