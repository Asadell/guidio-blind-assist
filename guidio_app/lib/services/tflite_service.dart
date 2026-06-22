
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

// Label COCO — 80 kelas lengkap
const Map<int, String> _cocoLabels = {
  // Orang
  0:  'person',

  // Kendaraan
  1:  'bicycle',
  2:  'car',
  3:  'motorcycle',
  4:  'airplane',
  5:  'bus',
  6:  'train',
  7:  'truck',
  8:  'boat',

  // Outdoor / Jalanan
  9:  'traffic light',
  10: 'fire hydrant',
  11: 'stop sign',
  12: 'parking meter',
  13: 'bench',

  // Hewan
  14: 'bird',
  15: 'cat',
  16: 'dog',
  17: 'horse',
  18: 'sheep',
  19: 'cow',
  20: 'elephant',
  21: 'bear',
  22: 'zebra',
  23: 'giraffe',

  // Aksesoris
  24: 'backpack',
  25: 'umbrella',
  26: 'handbag',
  27: 'tie',
  28: 'suitcase',

  // Olahraga
  29: 'frisbee',
  30: 'skis',
  31: 'snowboard',
  32: 'sports ball',
  33: 'kite',
  34: 'baseball bat',
  35: 'baseball glove',
  36: 'skateboard',
  37: 'surfboard',
  38: 'tennis racket',

  // Dapur / Makanan
  39: 'bottle',
  40: 'wine glass',
  41: 'cup',
  42: 'fork',
  43: 'knife',
  44: 'spoon',
  45: 'bowl',
  46: 'banana',
  47: 'apple',
  48: 'sandwich',
  49: 'orange',
  50: 'broccoli',
  51: 'carrot',
  52: 'hot dog',
  53: 'pizza',
  54: 'donut',
  55: 'cake',

  // Furnitur / Ruangan
  56: 'chair',
  57: 'couch',
  58: 'potted plant',
  59: 'bed',
  60: 'dining table',
  61: 'toilet',

  // Elektronik
  62: 'tv',
  63: 'laptop',
  64: 'mouse',
  65: 'remote',
  66: 'keyboard',
  67: 'cell phone',

  // Peralatan Rumah
  68: 'microwave',
  69: 'oven',
  70: 'toaster',
  71: 'sink',
  72: 'refrigerator',

  // Lain-lain
  73: 'book',
  74: 'clock',
  75: 'vase',
  76: 'scissors',
  77: 'teddy bear',
  78: 'hair drier',
  79: 'toothbrush',
};

const Map<String, String> _labelId = {
  // Orang
  'person':         'orang',

  // Kendaraan
  'bicycle':        'sepeda',
  'car':            'mobil',
  'motorcycle':     'motor',
  'airplane':       'pesawat',
  'bus':            'bus',
  'train':          'kereta',
  'truck':          'truk',
  'boat':           'perahu',

  // Outdoor / Jalanan
  'traffic light':  'lampu lalu lintas',
  'fire hydrant':   'hidran',
  'stop sign':      'rambu berhenti',
  'parking meter':  'meteran parkir',
  'bench':          'bangku',

  // Hewan
  'bird':           'burung',
  'cat':            'kucing',
  'dog':            'anjing',
  'horse':          'kuda',
  'sheep':          'domba',
  'cow':            'sapi',
  'elephant':       'gajah',
  'bear':           'beruang',
  'zebra':          'zebra',
  'giraffe':        'jerapah',

  // Aksesoris
  'backpack':       'tas ransel',
  'umbrella':       'payung',
  'handbag':        'tas tangan',
  'tie':            'dasi',
  'suitcase':       'koper',

  // Olahraga
  'frisbee':        'frisbee',
  'skis':           'ski',
  'snowboard':      'snowboard',
  'sports ball':    'bola olahraga',
  'kite':           'layang-layang',
  'baseball bat':   'pemukul baseball',
  'baseball glove': 'sarung tangan baseball',
  'skateboard':     'skateboard',
  'surfboard':      'papan selancar',
  'tennis racket':  'raket tenis',

  // Dapur / Makanan
  'bottle':         'botol',
  'wine glass':     'gelas anggur',
  'cup':            'cangkir',
  'fork':           'garpu',
  'knife':          'pisau',
  'spoon':          'sendok',
  'bowl':           'mangkuk',
  'banana':         'pisang',
  'apple':          'apel',
  'sandwich':       'sandwich',
  'orange':         'jeruk',
  'broccoli':       'brokoli',
  'carrot':         'wortel',
  'hot dog':        'hot dog',
  'pizza':          'pizza',
  'donut':          'donat',
  'cake':           'kue',

  // Furnitur / Ruangan
  'chair':          'kursi',
  'couch':          'sofa',
  'potted plant':   'tanaman pot',
  'bed':            'tempat tidur',
  'dining table':   'meja makan',
  'toilet':         'toilet',

  // Elektronik
  'tv':             'televisi',
  'laptop':         'laptop',
  'mouse':          'tetikus',
  'remote':         'remote',
  'keyboard':       'keyboard',
  'cell phone':     'ponsel',

  // Peralatan Rumah
  'microwave':      'microwave',
  'oven':           'oven',
  'toaster':        'pemanggang roti',
  'sink':           'wastafel',
  'refrigerator':   'kulkas',

  // Lain-lain
  'book':           'buku',
  'clock':          'jam',
  'vase':           'vas',
  'scissors':       'gunting',
  'teddy bear':     'boneka beruang',
  'hair drier':     'pengering rambut',
  'toothbrush':     'sikat gigi',
};

const Set<String> _dangerHigh   = {'person', 'motorcycle', 'car', 'bus', 'truck', 'dog'};
const Set<String> _dangerMedium = {'bicycle', 'chair', 'dining table'};

const Map<String, int> _realHeightsCm = {
  // Orang
  'person':           170,

  // Kendaraan
  'bicycle':          100,
  'car':              150,
  'motorcycle':       120,
  'airplane':         400,
  'bus':              300,
  'train':            350,
  'truck':            280,
  'boat':             150,

  // Outdoor / Jalanan
  'traffic light':    250,
  'fire hydrant':      60,
  'stop sign':        200,
  'parking meter':    130,
  'bench':             90,

  // Hewan
  'bird':              20,
  'cat':               25,
  'dog':               60,
  'horse':            160,
  'sheep':             80,
  'cow':              140,
  'elephant':         280,
  'bear':             150,
  'zebra':            150,
  'giraffe':          450,

  // Aksesoris
  'backpack':          50,
  'umbrella':         100,
  'handbag':           30,
  'tie':               15,
  'suitcase':          70,

  // Olahraga
  'frisbee':            3,
  'skis':             150,
  'snowboard':        150,
  'sports ball':       22,
  'kite':              50,
  'baseball bat':     100,
  'baseball glove':    30,
  'skateboard':        15,
  'surfboard':         60,
  'tennis racket':     70,

  // Dapur / Makanan
  'bottle':            25,
  'wine glass':        20,
  'cup':               10,
  'fork':               2,
  'knife':              3,
  'spoon':              2,
  'bowl':              10,
  'banana':            15,
  'apple':             10,
  'sandwich':          10,
  'orange':            10,
  'broccoli':          20,
  'carrot':            20,
  'hot dog':           10,
  'pizza':              5,
  'donut':              5,
  'cake':              15,

  // Furnitur / Ruangan
  'chair':             90,
  'couch':             90,
  'potted plant':      50,
  'bed':               60,
  'dining table':      75,
  'toilet':            80,

  // Elektronik
  'tv':                60,
  'laptop':            30,  // tinggi layar saat terbuka
  'mouse':              4,  // tinggi fisik mouse
  'remote':            20,
  'keyboard':           4,  // flat, tinggi bodi
  'cell phone':        15,

  // Peralatan Rumah
  'microwave':         35,
  'oven':              60,
  'toaster':           20,
  'sink':              25,
  'refrigerator':     175,

  // Lain-lain
  'book':              25,
  'clock':             30,
  'vase':              30,
  'scissors':          20,
  'teddy bear':        30,
  'hair drier':        25,
  'toothbrush':        20,
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
      final byteData    = await rootBundle.load('assets/models/yolo11l_float32.tflite');
      _modelBytes       = byteData.buffer.asUint8List();

      final options     = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(_modelBytes!, options: options);

      // Debug: verifikasi shape tensor sesuai ekspektasi model export
      // Input  harus: [1, 320, 320, 3]
      // Output harus: [1, 84, 2100]  ← layout asli YOLO NCHW (bukan onnx2tf transpose)
      final inputShape  = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      print('[TFLite] input shape:  $inputShape');   // [1, 320, 320, 3]
      print('[TFLite] output shape: $outputShape');  // [1, 2100, 84]

      // Bungkus di IsolateInterpreter agar inference tidak freeze UI
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
      );

      _loaded = true;
      return true;
    } catch (e) {
      print('[TFLite] load error: $e');
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
    // Shape dikonfirmasi dari debug log — model ini BUKAN hasil onnx2tf,
    // sehingga TIDAK ada transpose. Layout tetap [channel, anchor]:
    //   output[0..3][i] = bbox (cx,cy,w,h)
    //   output[4..83][i] = class scores
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

  /// Post-process output tensor YOLO11l [84, 2100] → List<Detection>
  /// Layout asli (BUKAN onnx2tf): [channel][anchor]
  ///   output[0..3][i] = cx, cy, w, h (normalized)
  ///   output[4..83][i] = class scores (80 kelas COCO)
  List<Detection> _postProcess(
    List<List<double>> output,   // shape: [84][2100]
    int origWidth,
    int origHeight,
  ) {
    // conf 0.15 — filter utama ada di DetectionFilter (cooldown per tier)
    // Model YOLO11l di 320x320 sering return 0.2-0.3 untuk objek valid
    const double confThreshold = 0.25;
    const double iouThreshold  = 0.45;

    final List<_RawDet> candidates = [];

    // Debug: track score tertinggi per frame
    double debugMaxScore = 0;
    int    debugMaxClass = -1;

    // Loop 2100 anchors — tiap kolom = 1 anchor
    for (int i = 0; i < 2100; i++) {
      // Ambil class scores (index 4..83)
      double maxScore = 0;
      int    maxClass = -1;
      for (int c = 4; c < 84; c++) {
        if (output[c][i] > maxScore) {
          maxScore = output[c][i];
          maxClass = c - 4;
        }
      }

      // Simpan score tertinggi global untuk debug
      if (maxScore > debugMaxScore) {
        debugMaxScore = maxScore;
        debugMaxClass = maxClass;
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

    // Debug: log score tertinggi per ~30 frame untuk diagnosa
    // Jika debugMaxScore selalu < 0.1, berarti model tidak mengenali objek sama sekali
    if (debugMaxClass >= 0) {
      final label = _cocoLabels[debugMaxClass] ?? 'class$debugMaxClass';
      print('[Inference] best score: ${debugMaxScore.toStringAsFixed(3)} → $label '
          '(candidates: ${candidates.length})');
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
