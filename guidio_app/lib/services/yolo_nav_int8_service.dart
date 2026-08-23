import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';

// ─────────────────────────────────────────────────────────────
// YoloNavInt8Service - model lama INT8 NCHW [1,3,640,640]
// ─────────────────────────────────────────────────────────────
//
// Model ini (yolo11n.tflite ~3 MB, INT8) terbukti lebih baik mendeteksi
// kelas yang berlimpah contohnya di dataset umum - khususnya `tiang`.
// Pada pengujian 03_tiang_listrik.png:
//   yolo11n_navigasi.tflite : tiang max_conf = 0.0000  ← tidak terdeteksi
//   yolo11n.tflite          : tiang max_conf = 0.3777  ← terdeteksi
//
// Dijalankan paralel di samping YoloNavigasiService; hasilnya digabung
// oleh mergeNavObstacles sehingga aturan prioritas bahaya tetap satu.
// Duplikat antar keduanya dibuang berdasarkan IoU ≥ 0.45.
//
// Format tensor NCHW [1,3,640,640] ≠ NHWC [1,640,640,3] yang dipakai
// yolo11n_navigasi. Tensor YOLO dari NavFrameConverter ditulis sebagai
// NHWC datar; di sini kita transpose in-place ke NCHW sebelum dikirim
// ke interpreter, tanpa membuat buffer baru setiap frame.

// Label sesuai urutan training - harus identik dengan YoloNavigasiService.
const List<String> _navLabelsInt8 = [
  'lubang',
  'got_terbuka',
  'tangga',
  'orang',
  'motor',
  'tiang',
];

const Map<String, int> _realHeightsInt8 = {
  'lubang':      15,
  'got_terbuka': 20,
  'tangga':      20,
  'orang':      170,
  'motor':      120,
  'tiang':      300,
};

const int _focalPxInt8  = 615;
const double _confThreshInt8 = 0.25; // sedikit lebih longgar dari model FP16
const double _iouThreshInt8  = 0.45;
const int _yoloSizeInt8      = 640;

class YoloNavInt8Service {
  static final YoloNavInt8Service instance = YoloNavInt8Service._();
  YoloNavInt8Service._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Muat yolo11n.tflite (INT8, NCHW) dari assets.
  ///
  /// Gagal dimuat → kembalikan false; service tidak dipakai oleh provider.
  /// Mode navigasi tidak bergantung pada model ini untuk bertahan - ia hanya
  /// lapis tambahan, jadi kegagalannya tidak boleh menjatuhkan mode.
  Future<bool> tryLoad() async {
    try {
      final bd = await rootBundle.load('assets/models/yolo11n.tflite');
      final bytes = bd.buffer.asUint8List();
      debugPrint('[YOLO-Int8] Memuat model ${(bytes.length / 1024).toStringAsFixed(0)} KB');

      final options = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(bytes, options: options);

      final inputShape  = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      debugPrint('[YOLO-Int8] Input: $inputShape  Output: $outputShape');

      // Pastikan NCHW [1, 3, 640, 640]
      if (inputShape.length != 4 ||
          inputShape[1] != 3 ||
          inputShape[2] != _yoloSizeInt8 ||
          inputShape[3] != _yoloSizeInt8) {
        debugPrint('[YOLO-Int8] TOLAK: input $inputShape bukan NCHW '
            '[1,3,$_yoloSizeInt8,$_yoloSizeInt8].');
        return false;
      }
      final expectedCh = 4 + _navLabelsInt8.length; // 10
      if (outputShape.length != 3 || outputShape[1] != expectedCh) {
        debugPrint('[YOLO-Int8] TOLAK: output $outputShape, diharapkan '
            'channel $expectedCh.');
        return false;
      }

      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[YOLO-Int8] Model siap. Kelas: $_navLabelsInt8');
      return true;
    } catch (e) {
      debugPrint('[YOLO-Int8] Gagal load: $e');
      return false;
    }
  }

  /// Buffer keluaran yang dipakai ulang — [10 × 8400] float.
  Float32List? _outputBuffer;
  Uint8List?   _outputBytes;

  /// Buffer NCHW yang dipakai ulang — [3 × 640 × 640] float.
  ///
  /// Tensor masuk dari NavFrameConverter dalam format NHWC datar
  /// (R0G0B0 R1G1B1 ...). Di sini kita salin ke tata letak NCHW
  /// (semua R dulu, lalu semua G, lalu semua B) tanpa mengalokasikan
  /// buffer baru setiap frame.
  Float32List? _nchwBuffer;
  Uint8List?   _nchwBytes;

  /// Deteksi rintangan dari tensor NHWC yang sudah disiapkan NavFrameConverter.
  ///
  /// [nhwcInput] adalah `tensors.yolo` dari NavFrameConverter:
  /// Float32List datar tata letak [1,640,640,3].
  Future<List<Detection>> detect(
    Float32List nhwcInput,
    int uprightW,
    int uprightH,
  ) async {
    if (!_loaded || _interpreter == null) return [];

    const pixels = _yoloSizeInt8 * _yoloSizeInt8; // 409600

    // Transpose NHWC → NCHW in-place di buffer yang sama.
    final nchw = _nchwBuffer ??= Float32List(3 * pixels);
    for (int i = 0; i < pixels; i++) {
      nchw[i]             = nhwcInput[i * 3];     // R
      nchw[pixels + i]    = nhwcInput[i * 3 + 1]; // G
      nchw[pixels * 2 + i]= nhwcInput[i * 3 + 2]; // B
    }
    final nchwBytes = _nchwBytes ??= nchw.buffer.asUint8List();

    final t0 = DateTime.now();
    try {
      final out      = _outputBuffer ??= Float32List(10 * 8400);
      final outBytes = _outputBytes  ??= out.buffer.asUint8List();

      await _interpreter!.runForMultipleInputs(
        [nchwBytes],
        {0: outBytes},
      );

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();
      return _postProcess(out, inferMs, uprightW, uprightH);
    } catch (e) {
      debugPrint('[YOLO-Int8] detect error: $e');
      return [];
    }
  }

  List<Detection> _postProcess(
    Float32List raw,
    double inferMs,
    int uprightW,
    int uprightH,
  ) {
    const numAnchors = 8400;
    final numClasses = _navLabelsInt8.length;

    final List<_BoxInt8> boxes = [];
    for (int i = 0; i < numAnchors; i++) {
      double maxScore = 0;
      int maxClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = raw[(4 + c) * numAnchors + i];
        if (score > maxScore) { maxScore = score; maxClass = c; }
      }
      if (maxScore < _confThreshInt8) continue;

      // Model ini menghasilkan koordinat pixel (onnx2tf konvensi).
      final cx = raw[i];
      final cy = raw[numAnchors + i];
      final bw = raw[numAnchors * 2 + i];
      final bh = raw[numAnchors * 3 + i];

      boxes.add(_BoxInt8(
        x1:       (cx - bw / 2).clamp(0, _yoloSizeInt8.toDouble()),
        y1:       (cy - bh / 2).clamp(0, _yoloSizeInt8.toDouble()),
        x2:       (cx + bw / 2).clamp(0, _yoloSizeInt8.toDouble()),
        y2:       (cy + bh / 2).clamp(0, _yoloSizeInt8.toDouble()),
        score:    maxScore,
        classIdx: maxClass,
      ));
    }

    if (boxes.isEmpty) return [];
    final kept = _nms(boxes);

    final scaleX = uprightW / _yoloSizeInt8;
    final scaleY = uprightH / _yoloSizeInt8;

    return kept.map((b) {
      final x1 = (b.x1 * scaleX).round().clamp(0, uprightW - 1);
      final y1 = (b.y1 * scaleY).round().clamp(0, uprightH - 1);
      final x2 = (b.x2 * scaleX).round().clamp(0, uprightW - 1);
      final y2 = (b.y2 * scaleY).round().clamp(0, uprightH - 1);
      final boxH = y2 - y1;
      final cx   = (x1 + x2) / 2.0;

      final label   = _navLabelsInt8[b.classIdx];
      final dist    = _estimateDist(label, boxH);
      final dir     = _direction(cx, uprightW);
      final danger  = _dangerLevel(label, dist);

      return Detection(
        labelEn:       label,
        labelId:       label,
        confidence:    b.score,
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
        inferenceMs:   inferMs,
        frameWidth:    uprightW,
        frameHeight:   uprightH,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));
  }

  List<_BoxInt8> _nms(List<_BoxInt8> boxes) {
    boxes.sort((a, b) => b.score.compareTo(a.score));
    final kept        = <_BoxInt8>[];
    final suppressed  = List<bool>.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j] || boxes[i].classIdx != boxes[j].classIdx) continue;
        if (_iou(boxes[i], boxes[j]) > _iouThreshInt8) suppressed[j] = true;
      }
    }
    return kept;
  }

  double _iou(_BoxInt8 a, _BoxInt8 b) {
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
    final realH = _realHeightsInt8[label] ?? 50;
    return (realH * _focalPxInt8) / (boxH * 100.0);
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

class _BoxInt8 {
  final double x1, y1, x2, y2, score;
  final int classIdx;
  const _BoxInt8({
    required this.x1, required this.y1,
    required this.x2, required this.y2,
    required this.score, required this.classIdx,
  });
}
