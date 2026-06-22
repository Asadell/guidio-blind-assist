
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

// Label Bahasa Indonesia — kunci adalah label Inggris dari labelmap.txt
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
  'person':           170,
  'bicycle':          100,
  'car':              150,
  'motorcycle':       120,
  'airplane':         400,
  'bus':              300,
  'train':            350,
  'truck':            280,
  'boat':             150,
  'traffic light':    250,
  'fire hydrant':      60,
  'stop sign':        200,
  'parking meter':    130,
  'bench':             90,
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
  'backpack':          50,
  'umbrella':         100,
  'handbag':           30,
  'tie':               15,
  'suitcase':          70,
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
  'chair':             90,
  'couch':             90,
  'potted plant':      50,
  'bed':               60,
  'dining table':      75,
  'toilet':            80,
  'tv':                60,
  'laptop':            30,
  'mouse':              4,
  'remote':            20,
  'keyboard':           4,
  'cell phone':        15,
  'microwave':         35,
  'oven':              60,
  'toaster':           20,
  'sink':              25,
  'refrigerator':     175,
  'book':              25,
  'clock':             30,
  'vase':              30,
  'scissors':          20,
  'teddy bear':        30,
  'hair drier':        25,
  'toothbrush':        20,
};

// Focal length piksel (kalibrasi default)
const int _focalLengthPx = 615;

// SSD MobileNet: input 300×300
const int _inputSize = 300;

class TFLiteService {
  static final TFLiteService instance = TFLiteService._();
  TFLiteService._();

  IsolateInterpreter? _isolateInterpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Labels dimuat dinamis dari labelmap.txt
  List<String> _labels = [];

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
      // Load model SSD MobileNet
      final byteData    = await rootBundle.load('assets/models/ssd_mobilenet.tflite');
      _modelBytes       = byteData.buffer.asUint8List();

      // Load labelmap dinamis dari file teks
      final labelRaw = await rootBundle.loadString('assets/models/labelmap.txt');
      _labels = labelRaw.trim().split('\n').map((l) => l.trim()).toList();
      debugPrint('[TFLite] Loaded ${_labels.length} labels dari labelmap.txt');

      final options     = InterpreterOptions()..threads = 4;
      final interpreter = Interpreter.fromBuffer(_modelBytes!, options: options);

      // Debug: verifikasi shape tensor
      // SSD MobileNet: input [1, 300, 300, 3]
      final inputShape  = interpreter.getInputTensor(0).shape;
      debugPrint('[TFLite] input shape: $inputShape');  // [1, 300, 300, 3]

      // Bungkus di IsolateInterpreter agar inference tidak freeze UI
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
      );

      _loaded = true;
      return true;
    } catch (e) {
      debugPrint('[TFLite] load error: $e');
      _loaded = false;
      return false;
    }
  }

  /// Jalankan inference dari CameraImage (YUV420).
  /// Menggunakan IsolateInterpreter — tidak freeze UI.
  Future<List<Detection>> runInference(CameraImage image) async {
    if (!_loaded || _isolateInterpreter == null) return [];

    // Konversi YUV420 → RGB → resize 300×300 → nested List [1][300][300][3]
    final inputTensor = _prepareInput(image);
    if (inputTensor == null) return [];

    // SSD MobileNet output 4 tensor terpisah:
    //   tensor[0]: locations [1][10][4]   — [ymin, xmin, ymax, xmax] normalized
    //   tensor[1]: classes   [1][10]      — class index (float)
    //   tensor[2]: scores    [1][10]      — confidence score
    //   tensor[3]: count     [1]          — jumlah deteksi valid
    final outputLocations = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
    final outputClasses   = List.generate(1, (_) => List.filled(10, 0.0));
    final outputScores    = List.generate(1, (_) => List.filled(10, 0.0));
    final outputCount     = List.filled(1, 0.0);

    final outputs = {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: outputCount,
    };

    await _isolateInterpreter!.runForMultipleInputs([inputTensor], outputs);

    return _postProcess(
      outputLocations[0],
      outputClasses[0],
      outputScores[0],
      image.width,
      image.height,
    );
  }

  /// Konversi YUV420 → RGB → resize 300×300 → nested List [1][300][300][3]
  ///
  /// SSD MobileNet membutuhkan pixel range 0..255 (BUKAN 0..1 seperti YOLO).
  /// TFLite Flutter membutuhkan nested List sesuai shape tensor [1, 300, 300, 3].
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

      // Resize ke 300×300 (SSD MobileNet input size)
      final resized = img.copyResize(
        rgbImage,
        width:         _inputSize,
        height:        _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Build nested List [1][H][W][3] — pixel range 0..255 (tidak dinormalisasi)
      final input = List.generate(1, (_) =>
        List.generate(_inputSize, (y) =>
          List.generate(_inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),  // 0..255 — sesuai spesifikasi SSD MobileNet
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          }),
        ),
      );

      return input;
    } catch (_) {
      return null;
    }
  }

  /// Post-process output SSD MobileNet → List<Detection>
  ///
  /// Output tensor SSD:
  ///   locations[i] = [ymin, xmin, ymax, xmax] normalized 0..1
  ///   classes[i]   = class index (float, bukan int)
  ///   scores[i]    = confidence score
  ///
  /// NMS sudah dilakukan di dalam model — tidak perlu NMS manual.
  List<Detection> _postProcess(
    List<List<double>> locations, // [10][4]: ymin, xmin, ymax, xmax
    List<double> classes,
    List<double> scores,
    int origWidth,
    int origHeight,
  ) {
    const double confThreshold = 0.5;
    final List<Detection> results = [];

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] < confThreshold) continue;

      final classIdx = classes[i].toInt();
      if (classIdx < 0 || classIdx >= _labels.length) continue;

      final labelEn = _labels[classIdx];
      // Skip entry '???' di labelmap — bukan kelas valid
      if (labelEn == '???') continue;

      final labelId = _labelId[labelEn] ?? labelEn;

      // SSD output: [ymin, xmin, ymax, xmax] normalized 0..1
      final ymin = locations[i][0];
      final xmin = locations[i][1];
      final ymax = locations[i][2];
      final xmax = locations[i][3];

      // Konversi ke pixel koordinat, clamp ke batas frame
      final x1 = (xmin * origWidth).clamp(0.0, (origWidth - 1).toDouble()).toInt();
      final y1 = (ymin * origHeight).clamp(0.0, (origHeight - 1).toDouble()).toInt();
      final x2 = (xmax * origWidth).clamp(0.0, (origWidth - 1).toDouble()).toInt();
      final y2 = (ymax * origHeight).clamp(0.0, (origHeight - 1).toDouble()).toInt();

      final boxH = y2 - y1;
      final cx   = (x1 + x2) / 2.0;
      final cy   = (y1 + y2) / 2.0;

      final dist   = _estimateDistance(labelEn, boxH);
      final dir    = _getDirection(cx, cy, origWidth, origHeight);
      final danger = _getDanger(labelEn, dist);

      // Debug: log tiap deteksi yang lolos threshold
      debugPrint('[Inference] ${scores[i].toStringAsFixed(2)} → $labelEn | $dir | ${dist.toStringAsFixed(1)}m | $danger');

      results.add(Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    scores[i],
        distanceMeter: dist,
        direction:     dir,
        dangerLevel:   danger,
        bbox:          {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
        inferenceMs:   0, // tidak diukur di sini
      ));
    }

    return results;
  }

  double _estimateDistance(String label, int boxH) {
    if (boxH <= 0) return 999.0;
    final realH = _realHeightsCm[label] ?? 100;
    double dist = (realH * _focalLengthPx) / (boxH * 100);

    // Tilt correction: jika HP miring > 15° (0.26 rad), koreksi jarak.
    if (_lastTiltAngle.abs() > 0.26) {
      dist = dist * cos(_lastTiltAngle.abs());
    }

    return dist;
  }

  /// Tentukan arah berdasarkan posisi horizontal DAN vertikal bounding box.
  ///
  /// Horizontal: kiri / depan / kanan (trisection horizontal)
  /// Vertikal: atas / tengah / bawah (trisection vertikal)
  ///
  /// Jika vertikal = tengah → kembalikan arah horizontal saja ("depan")
  /// Jika vertikal != tengah → gabungkan: "kiri atas", "depan bawah", dll.
  String _getDirection(double cx, double cy, int width, int height) {
    final hThird = width / 3;
    final vThird = height / 3;

    final horiz = cx < hThird ? 'kiri' : cx < hThird * 2 ? 'depan' : 'kanan';
    final vert  = cy < vThird ? 'atas' : cy < vThird * 2 ? 'tengah' : 'bawah';

    // Jika objek di zona tengah vertikal, cukup sebut arah horizontal
    if (vert == 'tengah') return horiz;
    return '$horiz $vert';
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
