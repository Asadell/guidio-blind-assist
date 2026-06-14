import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

// Label COCO yang diprioritaskan Guidio (15 kelas navigasi)
const Map<int, String> _cocoLabels = {
  0:  'person',
  1:  'bicycle',
  2:  'car',
  3:  'motorcycle',
  5:  'bus',
  7:  'truck',
  15: 'cat',
  16: 'dog',
  24: 'backpack',
  26: 'umbrella',
  56: 'chair',
  57: 'couch',
  59: 'bed',
  60: 'dining table',
  62: 'tv',
};

const Map<String, String> _labelId = {
  'person':       'orang',
  'bicycle':      'sepeda',
  'car':          'mobil',
  'motorcycle':   'motor',
  'bus':          'bus',
  'truck':        'truk',
  'cat':          'kucing',
  'dog':          'anjing',
  'chair':        'kursi',
  'dining table': 'meja',
  'backpack':     'tas',
  'umbrella':     'payung',
};

const Set<String> _dangerHigh   = {'person', 'motorcycle', 'car', 'bus', 'truck', 'dog'};
const Set<String> _dangerMedium = {'bicycle', 'chair', 'dining table'};

const Map<String, int> _realHeightsCm = {
  'person':     170,
  'motorcycle': 120,
  'car':        150,
  'bicycle':    100,
  'bus':        300,
  'truck':      280,
  'dog':         60,
  'cat':         25,
  'chair':       90,
};
const int _focalLengthPx = 615;
const int _inputSize     = 320; // imgsz saat export TFLite

class TFLiteService {
  static final TFLiteService instance = TFLiteService._();
  TFLiteService._();

  // IsolateInterpreter dari tflite_flutter — lebih simple dari spawn isolate manual
  // Berdasarkan Context7 docs: Interpreter.fromAsset + IsolateInterpreter.create
  IsolateInterpreter? _isolateInterpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Model bytes disimpan agar bisa dikirim ke isolate
  Uint8List? _modelBytes;

  // Tilt correction — sudut kemiringan kamera dari accelerometer (radian)
  double _lastTiltAngle = 0.0;

  /// Dipanggil CameraProvider setiap 30 frame saat orientasi di-check.
  void updateTilt(double angleRadians) {
    _lastTiltAngle = angleRadians;
  }

  Future<bool> tryLoad() async {
    try {
      // Load model bytes via rootBundle (hanya bisa di main thread)
      final byteData  = await rootBundle.load('assets/models/yolo11l_float32.tflite');
      _modelBytes     = byteData.buffer.asUint8List();

      final options   = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(_modelBytes!, options: options);

      // Bungkus di IsolateInterpreter agar inference tidak freeze UI
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
      );

      _loaded = true;
      return true;
    } catch (e) {
      _loaded = false;
      return false;
    }
  }

  /// Jalankan inference dari CameraImage (YUV420).
  /// Menggunakan IsolateInterpreter — tidak freeze UI.
  Future<List<Detection>> runInference(CameraImage image) async {
    if (!_loaded || _isolateInterpreter == null) return [];

    // Konversi YUV420 → RGB → resize 320×320 → Float32 normalized
    final inputTensor = _prepareInput(image);
    if (inputTensor == null) return [];

    // Output tensor YOLO11l (imgsz=320): [1, 84, 2100]
    // 84 = 4 bbox coords (cx,cy,w,h) + 80 class scores
    final output = List.generate(1, (_) =>
        List.generate(84, (_) => List.filled(2100, 0.0)));

    await _isolateInterpreter!.run(inputTensor, output);

    return _postProcess(output[0], image.width, image.height);
  }

  /// Konversi YUV420 → RGB → resize 320×320 → nested List [1][320][320][3]
  ///
  /// TFLite Flutter membutuhkan input sebagai nested List yang persis sesuai
  /// shape tensor model ([1, 320, 320, 3]), bukan flat Float32List.
  /// Jika dikirim flat, PAD kernel akan gagal dengan "dims mismatch".
  List<List<List<List<double>>>>? _prepareInput(CameraImage image) {
    try {
      final int width  = image.width;
      final int height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final yBytes      = yPlane.bytes;
      final uBytes      = uPlane.bytes;
      final vBytes      = vPlane.bytes;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStr  = uPlane.bytesPerPixel ?? 1;

      // Buat img.Image RGB
      final rgbImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex  = y * yPlane.bytesPerRow + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStr;

          final int yVal = yBytes[yIndex] & 0xFF;
          final int uVal = (uBytes.length > uvIndex ? uBytes[uvIndex] : 128) & 0xFF;
          final int vVal = (vBytes.length > uvIndex ? vBytes[uvIndex] : 128) & 0xFF;

          final int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
          final int g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
          final int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      // Resize ke 320×320
      final resized = img.copyResize(
        rgbImage,
        width:         _inputSize,
        height:        _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Build nested List [1][H][W][3] — wajib untuk TFLite Flutter
      // agar shape tensor terbaca benar oleh allocateTensors()
      final input = List.generate(1, (_) =>
        List.generate(_inputSize, (y) =>
          List.generate(_inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          }),
        ),
      );

      return input;
    } catch (_) {
      return null;
    }
  }

  /// Post-process output tensor YOLO11l [84, 8400] → List<Detection>
  /// 84 = 4 bbox (cx,cy,w,h normalized) + 80 class scores
  List<Detection> _postProcess(
    List<List<double>> output,
    int origWidth,
    int origHeight,
  ) {
    const double confThreshold = 0.5;
    const double iouThreshold  = 0.45;

    final List<_RawDet> candidates = [];

    // Loop 2100 anchors
    for (int i = 0; i < 2100; i++) {
      // Ambil class scores (index 4..83)
      double maxScore = 0;
      int    maxClass = -1;
      for (int c = 4; c < 84; c++) {
        final score = output[c][i];
        if (score > maxScore) {
          maxScore = score;
          maxClass = c - 4;
        }
      }

      if (maxScore < confThreshold) continue;
      if (!_cocoLabels.containsKey(maxClass)) continue;

      // Bbox: cx, cy, w, h (normalized 0..1)
      final cx = output[0][i];
      final cy = output[1][i];
      final bw = output[2][i];
      final bh = output[3][i];

      // Konversi ke pixel koordinat
      final x1 = ((cx - bw / 2) * origWidth).clamp(0, origWidth - 1).toInt();
      final y1 = ((cy - bh / 2) * origHeight).clamp(0, origHeight - 1).toInt();
      final x2 = ((cx + bw / 2) * origWidth).clamp(0, origWidth - 1).toInt();
      final y2 = ((cy + bh / 2) * origHeight).clamp(0, origHeight - 1).toInt();

      candidates.add(_RawDet(
        classIdx:   maxClass,
        confidence: maxScore,
        x1: x1, y1: y1, x2: x2, y2: y2,
      ));
    }

    // NMS — Non-Maximum Suppression
    final nmsResult = _applyNms(candidates, iouThreshold);

    // Konversi ke Detection model
    return nmsResult.map((raw) {
      final labelEn  = _cocoLabels[raw.classIdx]!;
      final labelId  = _labelId[labelEn] ?? labelEn;
      final boxH     = raw.y2 - raw.y1;
      final dist     = _estimateDistance(labelEn, boxH);
      final dir      = _getDirection((raw.x1 + raw.x2) / 2, origWidth);
      final danger   = _getDanger(labelEn, dist);

      return Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    raw.confidence,
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': raw.x1, 'y1': raw.y1, 'x2': raw.x2, 'y2': raw.y2},
        inferenceMs:   0, // tidak diukur di sini
      );
    }).toList();
  }

  List<_RawDet> _applyNms(List<_RawDet> dets, double iouThreshold) {
    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final result  = <_RawDet>[];
    final removed = <int>{};

    for (int i = 0; i < dets.length; i++) {
      if (removed.contains(i)) continue;
      result.add(dets[i]);
      for (int j = i + 1; j < dets.length; j++) {
        if (removed.contains(j)) continue;
        if (_iou(dets[i], dets[j]) > iouThreshold) {
          removed.add(j);
        }
      }
    }
    return result;
  }

  double _iou(_RawDet a, _RawDet b) {
    final ix1 = a.x1 > b.x1 ? a.x1 : b.x1;
    final iy1 = a.y1 > b.y1 ? a.y1 : b.y1;
    final ix2 = a.x2 < b.x2 ? a.x2 : b.x2;
    final iy2 = a.y2 < b.y2 ? a.y2 : b.y2;

    final iw = (ix2 - ix1).clamp(0, double.maxFinite.toInt());
    final ih = (iy2 - iy1).clamp(0, double.maxFinite.toInt());
    final inter = iw * ih;
    if (inter == 0) return 0;

    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    return inter / (areaA + areaB - inter);
  }

  double _estimateDistance(String label, int boxH) {
    if (boxH <= 0) return 999.0;
    final realH = _realHeightsCm[label] ?? 100;
    double dist = (realH * _focalLengthPx) / (boxH * 100);

    // Tilt correction: jika HP miring > 15° (0.26 rad), koreksi jarak.
    // cos(tilt) < 1 → jarak aktual lebih pendek dari hasil Similar Triangle.
    if (_lastTiltAngle.abs() > 0.26) {
      dist = dist * cos(_lastTiltAngle.abs());
    }

    return dist;
  }

  String _getDirection(double cx, int width) {
    final t = width / 3;
    if (cx < t)      return 'kiri';
    if (cx < t * 2)  return 'depan';
    return 'kanan';
  }

  String _getDanger(String label, double dist) {
    if (_dangerHigh.contains(label)) {
      if (dist < 1.5) return 'critical';
      if (dist < 3.0) return 'warning';
    } else if (_dangerMedium.contains(label)) {
      if (dist < 2.0) return 'critical';
      if (dist < 4.0) return 'warning';
    }
    return 'info';
  }

  void dispose() {
    _isolateInterpreter?.close();
    _loaded = false;
  }
}

/// Helper internal untuk NMS
class _RawDet {
  final int    classIdx;
  final double confidence;
  final int    x1, y1, x2, y2;
  const _RawDet({
    required this.classIdx,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}
