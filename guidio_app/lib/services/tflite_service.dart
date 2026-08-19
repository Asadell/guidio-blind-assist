
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';
import 'camera_intrinsics.dart';

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
  'mouse':          'mouse',
  'remote':         'remote kontrol',
  'keyboard':       'papan ketik',
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
  ///
  /// Preprocessing berjalan di isolate lewat [compute] dan menghasilkan
  /// **buffer datar** `Uint8List` yang langsung disalin ke tensor uint8.
  ///
  /// Versi sebelumnya melakukan seluruhnya di isolate UI: loop 640×480
  /// YUV→RGB dengan `setPixelRgb()` per piksel, lalu `copyResize`, lalu
  /// `copyRotate`, lalu membangun `List<List<List<List<num>>>>` berisi
  /// 270.000 angka ter-boxing. Hanya interpreter-nya yang ada di isolate;
  /// bagian yang jauh lebih mahal justru menghalangi thread UI — dan karena
  /// TTS dijadwalkan dari thread yang sama, suaralah yang ikut tersendat.
  Future<List<Detection>> runInference(CameraImage image) async {
    if (!_loaded || _isolateInterpreter == null) return [];

    final geo = _FrameGeometry.of(image.width, image.height);
    final Uint8List inputTensor;
    try {
      inputTensor = await compute(_prepareSsdInput, _SsdPrepArgs.from(image, geo));
    } catch (e) {
      debugPrint('[TFLite] preprocessing gagal: $e');
      return [];
    }

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
      geo,
    );
  }

  /// Post-process output SSD MobileNet → List<Detection>
  ///
  /// Output tensor SSD:
  ///   locations[i] = [ymin, xmin, ymax, xmax] normalized 0..1
  ///                  **relatif terhadap kotak crop tegak**, bukan frame mentah
  ///   classes[i]   = class index (float, bukan int)
  ///   scores[i]    = confidence score
  ///
  /// NMS sudah dilakukan di dalam model — tidak perlu NMS manual.
  List<Detection> _postProcess(
    List<List<double>> locations, // [10][4]: ymin, xmin, ymax, xmax
    List<double> classes,
    List<double> scores,
    _FrameGeometry geo,
  ) {
    const double confThreshold = 0.5;
    // Fokus per-perangkat, dihitung ulang dari lebar frame yang benar-benar
    // dipakai — bukan konstanta yang mengasumsikan satu lensa untuk semua HP.
    final focalPx = CameraIntrinsics.instance.focalPxForUprightFrame(geo.srcW);
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
      final ymin = locations[i][0].clamp(0.0, 1.0);
      final xmin = locations[i][1].clamp(0.0, 1.0);
      final ymax = locations[i][2].clamp(0.0, 1.0);
      final xmax = locations[i][3].clamp(0.0, 1.0);

      // Koordinat piksel di ruang **bingkai tegak**. Karena crop-nya persegi
      // dan skalanya seragam, tinggi kotak di sini sebanding lurus dengan
      // tinggi objek sebenarnya — syarat yang tidak dipenuhi versi lama, yang
      // meregangkan 640×480 menjadi 300×300 (rasio berubah) lalu memutarnya,
      // sehingga "tinggi" kotak sebenarnya mengukur lebar objek.
      final x1 = (geo.offsetX + xmin * geo.cropSide).round();
      final y1 = (geo.offsetY + ymin * geo.cropSide).round();
      final x2 = (geo.offsetX + xmax * geo.cropSide).round();
      final y2 = (geo.offsetY + ymax * geo.cropSide).round();

      final boxH = (ymax - ymin) * geo.cropSide;

      final dist   = _estimateDistance(labelEn, boxH, focalPx);
      final dir    = _getDirection((xmin + xmax) / 2, (ymin + ymax) / 2);
      final danger = _getDanger(labelEn, dist);

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

  /// Estimasi jarak dari tinggi kotak dalam piksel bingkai tegak.
  ///
  /// [focalPx] dibaca dari intrinsik lensa perangkat lewat [CameraIntrinsics];
  /// kalau perangkat tidak melaporkannya, nilainya jatuh ke fallback yang
  /// sama seperti konstanta lama.
  double _estimateDistance(String label, double boxHpx, double focalPx) {
    if (boxHpx <= 0) return 999.0;
    final realH = _realHeightsCm[label] ?? 100;
    double dist = (realH * focalPx) / (boxHpx * 100);

    // Tilt correction: jika HP miring > 15° (0.26 rad), koreksi jarak.
    if (_lastTiltAngle.abs() > 0.26) {
      dist = dist * cos(_lastTiltAngle.abs());
    }

    return dist;
  }

  /// Tentukan arah dari posisi kotak dalam koordinat ternormalisasi (0..1)
  /// pada kotak crop tegak.
  ///
  /// Horizontal: kiri / depan / kanan (trisection horizontal)
  /// Vertikal: atas / tengah / bawah (trisection vertikal)
  ///
  /// Jika vertikal = tengah → kembalikan arah horizontal saja ("depan")
  /// Jika vertikal != tengah → gabungkan: "kiri atas", "depan bawah", dll.
  String _getDirection(double cxNorm, double cyNorm) {
    final horiz = cxNorm < 1 / 3 ? 'kiri' : cxNorm < 2 / 3 ? 'depan' : 'kanan';
    final vert  = cyNorm < 1 / 3 ? 'atas' : cyNorm < 2 / 3 ? 'tengah' : 'bawah';

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

// ── Geometri bingkai ────────────────────────────────────────────────────────

/// Pemetaan antara frame sensor (landscape) dan bingkai tegak yang dilihat
/// pengguna, plus kotak crop persegi yang dikirim ke model.
///
/// Kamera Android memberi frame landscape (mis. 640×480) sementara aplikasi
/// terkunci portrait, jadi bingkai tegaknya 480×640. Model butuh masukan
/// persegi 300×300; supaya rasio tidak berubah, yang diambil adalah **crop
/// persegi di tengah** bingkai tegak, bukan seluruh frame yang diregangkan.
class _FrameGeometry {
  /// Lebar & tinggi frame sensor mentah.
  final int srcW, srcH;

  /// Sisi kotak crop, dalam piksel bingkai tegak.
  final int cropSide;

  /// Posisi kiri-atas kotak crop di dalam bingkai tegak.
  final int offsetX, offsetY;

  const _FrameGeometry({
    required this.srcW,
    required this.srcH,
    required this.cropSide,
    required this.offsetX,
    required this.offsetY,
  });

  factory _FrameGeometry.of(int srcW, int srcH) {
    // Bingkai tegak = frame sensor diputar 90°.
    final uprightW = srcH;
    final uprightH = srcW;
    final side = uprightW < uprightH ? uprightW : uprightH;
    return _FrameGeometry(
      srcW: srcW,
      srcH: srcH,
      cropSide: side,
      offsetX: (uprightW - side) ~/ 2,
      offsetY: (uprightH - side) ~/ 2,
    );
  }
}

/// Argumen preprocessing — semua sudah berupa data biasa supaya bisa dikirim
/// ke isolate lewat [compute].
class _SsdPrepArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int yRowStride, uvRowStride, uvPixelStride;
  final int srcH;
  final int cropSide, offsetX, offsetY;

  const _SsdPrepArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.srcH,
    required this.cropSide,
    required this.offsetX,
    required this.offsetY,
  });

  factory _SsdPrepArgs.from(CameraImage image, _FrameGeometry geo) => _SsdPrepArgs(
        yPlane: image.planes[0].bytes,
        uPlane: image.planes[1].bytes,
        vPlane: image.planes[2].bytes,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
        srcH: geo.srcH,
        cropSide: geo.cropSide,
        offsetX: geo.offsetX,
        offsetY: geo.offsetY,
      );
}

/// YUV420 → RGB langsung ke grid 300×300, dalam satu lintasan, di isolate.
///
/// Rotasi 90° dan crop persegi dilakukan lewat pemetaan indeks — tidak ada
/// gambar antara yang dialokasikan, dan piksel yang disentuh hanya 90.000
/// alih-alih 307.200. Hasilnya buffer datar `Uint8List` yang disalin apa
/// adanya ke tensor uint8 (`ByteConversionUtils` memakai jalur cepat untuk
/// `Uint8List`), jadi tidak ada 270.000 angka ter-boxing seperti sebelumnya.
Uint8List _prepareSsdInput(_SsdPrepArgs a) {
  final out = Uint8List(_inputSize * _inputSize * 3);
  final yLen = a.yPlane.length;
  final uLen = a.uPlane.length;
  final vLen = a.vPlane.length;
  var o = 0;

  for (int ty = 0; ty < _inputSize; ty++) {
    // Sumbu vertikal bingkai tegak = sumbu horizontal sensor.
    final uy = a.offsetY + (ty * a.cropSide) ~/ _inputSize;
    final sx = uy;
    final uvCol = (sx >> 1) * a.uvPixelStride;

    for (int tx = 0; tx < _inputSize; tx++) {
      final ux = a.offsetX + (tx * a.cropSide) ~/ _inputSize;
      final sy = a.srcH - 1 - ux;

      final yIdx = sy * a.yRowStride + sx;
      final uvIdx = (sy >> 1) * a.uvRowStride + uvCol;

      final yVal = yIdx >= 0 && yIdx < yLen ? a.yPlane[yIdx] : 0;
      final uVal = (uvIdx >= 0 && uvIdx < uLen ? a.uPlane[uvIdx] : 128) - 128;
      final vVal = (uvIdx >= 0 && uvIdx < vLen ? a.vPlane[uvIdx] : 128) - 128;

      out[o++] = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
      out[o++] = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toInt();
      out[o++] = (yVal + 1.772 * uVal).clamp(0, 255).toInt();
    }
  }
  return out;
}
