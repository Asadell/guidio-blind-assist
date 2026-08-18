import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../widgets/zone_indicator.dart' show ZoneStatus;

// ─────────────────────────────────────────────────────────────
// Hasil segmentasi 3 zona dari PIDNet-S
// ─────────────────────────────────────────────────────────────
class ZoneAnalysis {
  /// Rasio piksel walkable (0.0 – 1.0) per zona.
  final double leftRatio;
  final double centerRatio;
  final double rightRatio;

  /// Status per zona berdasarkan threshold.
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;

  /// Indeks zona yang direkomendasikan (0=kiri, 1=tengah, 2=kanan).
  final int recommendedZone;

  /// Waktu inference dalam milidetik.
  final double inferenceMs;

  const ZoneAnalysis({
    required this.leftRatio,
    required this.centerRatio,
    required this.rightRatio,
    required this.left,
    required this.center,
    required this.right,
    required this.recommendedZone,
    required this.inferenceMs,
  });

  /// Pesan TTS sederhana berdasarkan zona — sama dengan yang dipakai backend.
  String get ttsMessage {
    // Rintangan akan ditangani lapisan atas (NavigationProvider).
    // Di sini hanya beri arahan zona jalur.
    if (left == ZoneStatus.danger &&
        center == ZoneStatus.danger &&
        right == ZoneStatus.danger) {
      return 'Berhenti dulu. Tidak ada jalur aman di sekitar sini.';
    }
    if (center == ZoneStatus.danger) {
      return 'Jalur di depan tidak aman.';
    }
    return switch (recommendedZone) {
      0 => 'Tetap di kiri.',
      2 => 'Geser ke kanan.',
      _ => 'Jalur aman, jalan lurus.',
    };
  }

  ZoneStatus get recommendedStatus => switch (recommendedZone) {
        0 => left,
        2 => right,
        _ => center,
      };
}

// ─────────────────────────────────────────────────────────────
// Konfigurasi PIDNet-S
// ─────────────────────────────────────────────────────────────

// Dimensi input model: H=384, W=640 (sesuai training)
const int _pidnetH = 384;
const int _pidnetW = 640;

// Kelas output: 0=non-walkable, 1=walkable/trotoar, 2=hazard
// Hanya kelas 1 (walkable) yang dihitung untuk rasio zona.
const int _classWalkable = 1;

// Threshold rasio walkable per zona
const double _threshSafe    = 0.50; // ≥50% walkable → AMAN
const double _threshCaution = 0.30; // ≥30% walkable → HATI-HATI, sisanya BAHAYA

// ImageNet normalisasi (sama persis dengan preprocessing Python)
const List<double> _mean = [0.485, 0.456, 0.406];
const List<double> _std  = [0.229, 0.224, 0.225];

// ─────────────────────────────────────────────────────────────
// PidnetService — segmentasi jalur 3 zona on-device
// ─────────────────────────────────────────────────────────────
class PidnetService {
  static final PidnetService instance = PidnetService._();
  PidnetService._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Input shape: [1, 384, 640, 3] (BHWC — TFLite default)
  // Atau [1, 3, 384, 640] (BCHW — jika model tidak di-transpose saat export)
  // Akan dideteksi otomatis saat load.
  bool _isBHWC = true;

  /// Muat model pidnet_s_3zona.tflite dari assets.
  /// Gunakan FP16 jika tersedia (lebih kecil, lebih cepat di A30S),
  /// fallback ke FP32 jika tidak.
  Future<bool> tryLoad() async {
    try {
      // Coba FP16 dulu — lebih efisien di Mali-G71 (Samsung A30S)
      Uint8List? modelBytes;
      try {
        final bd = await rootBundle.load('assets/models/pidnet_s_3zona_fp16.tflite');
        modelBytes = bd.buffer.asUint8List();
        debugPrint('[PIDNet] Memuat FP16 model (${(modelBytes.length / 1024).toStringAsFixed(0)} KB)');
      } catch (_) {
        // FP16 tidak ada, pakai FP32
        final bd = await rootBundle.load('assets/models/pidnet_s_3zona.tflite');
        modelBytes = bd.buffer.asUint8List();
        debugPrint('[PIDNet] Memuat FP32 model (${(modelBytes.length / 1024).toStringAsFixed(0)} KB)');
      }

      // GPU delegate — coba aktifkan di Android; jika gagal, CPU saja
      InterpreterOptions options;
      try {
        if (Platform.isAndroid) {
          options = InterpreterOptions()
            ..addDelegate(GpuDelegateV2())
            ..threads = 2;
          debugPrint('[PIDNet] GPU delegate aktif');
        } else {
          options = InterpreterOptions()..threads = 2;
        }
      } catch (_) {
        options = InterpreterOptions()..threads = 2;
        debugPrint('[PIDNet] GPU delegate gagal, pakai CPU');
      }

      final interpreter = Interpreter.fromBuffer(modelBytes, options: options);

      // Deteksi input format: BHWC atau BCHW
      final inputShape = interpreter.getInputTensor(0).shape;
      debugPrint('[PIDNet] Input shape: $inputShape');
      // BHWC: [1, H, W, C] → shape[1]=384, shape[2]=640, shape[3]=3
      // BCHW: [1, C, H, W] → shape[1]=3,   shape[2]=384, shape[3]=640
      _isBHWC = (inputShape.length == 4 && inputShape[3] == 3);
      debugPrint('[PIDNet] Format: ${_isBHWC ? "BHWC" : "BCHW"}');

      final outputShape = interpreter.getOutputTensor(0).shape;
      debugPrint('[PIDNet] Output shape: $outputShape');

      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[PIDNet] Model siap.');
      return true;
    } catch (e) {
      debugPrint('[PIDNet] Gagal load: $e');
      _loaded = false;
      return false;
    }
  }

  /// Analisis frame kamera → ZoneAnalysis (3 zona jalur).
  ///
  /// [rgbBytes] adalah bytes RGB888 dari frame kamera (setelah konversi YUV).
  /// [origW] dan [origH] adalah dimensi asli frame sebelum resize.
  Future<ZoneAnalysis?> analyze(
    Uint8List rgbBytes,
    int origW,
    int origH,
  ) async {
    if (!_loaded || _interpreter == null) return null;

    final t0 = DateTime.now();

    try {
      // Decode bytes ke img.Image untuk resize
      final rawImg = img.Image.fromBytes(
        width: origW,
        height: origH,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );

      // Resize ke 640×384 (W×H) — cv2.resize pakai (W, H)
      // Untuk rotasi Android: rotate 90° dulu sebelum resize
      img.Image resized;
      if (Platform.isAndroid) {
        final rotated = img.copyRotate(rawImg, angle: 90);
        resized = img.copyResize(rotated, width: _pidnetW, height: _pidnetH,
            interpolation: img.Interpolation.linear);
      } else {
        resized = img.copyResize(rawImg, width: _pidnetW, height: _pidnetH,
            interpolation: img.Interpolation.linear);
      }

      // Bangun tensor input sesuai format model
      final List input;
      if (_isBHWC) {
        // [1, 384, 640, 3] — float32 normalized
        input = _buildBHWC(resized);
      } else {
        // [1, 3, 384, 640] — float32 normalized
        input = _buildBCHW(resized);
      }

      // Output: [1, numClasses, H, W] atau [1, H, W, numClasses]
      // Deteksi output shape saat runtime
      final outTensor  = _interpreter!;
      // Perkiraan output: [1, 3, 384, 640] atau [1, 384, 640, 3]
      // Kita simpan sebagai flat Float32List lalu argmax manual
      final outputFlat = List.filled(1 * 3 * _pidnetH * _pidnetW, 0.0);

      final outputs = {0: outputFlat.reshape([1, 3, _pidnetH, _pidnetW])};
      await outTensor.runForMultipleInputs([input], outputs);

      // Argmax per-piksel → mask [H*W]
      final logits4D = outputs[0] as List; // [1][3][H][W] atau [1][H][W][3]
      final mask = _argmax(logits4D);

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();
      return _computeZones(mask, inferMs);
    } catch (e) {
      debugPrint('[PIDNet] analyze error: $e');
      return null;
    }
  }

  // ── Build input BHWC [1][H][W][3] ──────────────────────────
  List _buildBHWC(img.Image img_) {
    return List.generate(1, (_) =>
      List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) {
          final p = img_.getPixel(x, y);
          final r = (p.r / 255.0 - _mean[0]) / _std[0];
          final g = (p.g / 255.0 - _mean[1]) / _std[1];
          final b = (p.b / 255.0 - _mean[2]) / _std[2];
          return [r, g, b];
        }),
      ),
    );
  }

  // ── Build input BCHW [1][3][H][W] ──────────────────────────
  List _buildBCHW(img.Image img_) {
    final r = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).r / 255.0 - _mean[0]) / _std[0]));
    final g = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).g / 255.0 - _mean[1]) / _std[1]));
    final b_ = List.generate(_pidnetH, (y) =>
        List.generate(_pidnetW, (x) =>
          (img_.getPixel(x, y).b / 255.0 - _mean[2]) / _std[2]));
    return [[r, g, b_]];
  }

  // ── Argmax [1][3][H][W] → flat Int List panjang H*W ─────────
  List<int> _argmax(List logits4D) {
    // logits4D[0][c][h][w]
    final classes = logits4D[0] as List; // [3][H][W]
    final mask = List<int>.filled(_pidnetH * _pidnetW, 0);
    for (int h = 0; h < _pidnetH; h++) {
      for (int w = 0; w < _pidnetW; w++) {
        double maxVal = double.negativeInfinity;
        int maxC = 0;
        for (int c = 0; c < 3; c++) {
          final val = (classes[c] as List)[h][w] as double;
          if (val > maxVal) { maxVal = val; maxC = c; }
        }
        mask[h * _pidnetW + w] = maxC;
      }
    }
    return mask;
  }

  // ── Hitung rasio 3 zona & hasilkan ZoneAnalysis ─────────────
  ZoneAnalysis _computeZones(List<int> mask, double inferMs) {
    // Bagi gambar jadi 3 kolom vertikal (kiri, tengah, kanan)
    const zoneW  = _pidnetW ~/ 3;

    int leftWalk = 0, leftTotal = 0;
    int centWalk = 0, centTotal = 0;
    int rightWalk = 0, rightTotal = 0;

    for (int h = 0; h < _pidnetH; h++) {
      for (int w = 0; w < _pidnetW; w++) {
        final cls = mask[h * _pidnetW + w];
        // _classWalkable=1 → layak jalan; _classNonWalkable=0 & _classHazard=2 → tidak
        final isWalk = cls == _classWalkable;
        if (w < zoneW) {
          leftTotal++;
          if (isWalk) { leftWalk++; }
        } else if (w < zoneW * 2) {
          centTotal++;
          if (isWalk) { centWalk++; }
        } else {
          rightTotal++;
          if (isWalk) { rightWalk++; }
        }
      }
    }

    final lRatio = leftWalk  / max(leftTotal,  1);
    final cRatio = centWalk  / max(centTotal,  1);
    final rRatio = rightWalk / max(rightTotal, 1);

    ZoneStatus toStatus(double ratio) {
      if (ratio >= _threshSafe)    { return ZoneStatus.safe; }
      if (ratio >= _threshCaution) { return ZoneStatus.caution; }
      return ZoneStatus.danger;
    }

    final lStatus = toStatus(lRatio);
    final cStatus = toStatus(cRatio);
    final rStatus = toStatus(rRatio);

    // Rekomendasi zona: pilih yang paling aman, prioritas tengah
    int recommended = 1; // tengah default
    if (cStatus == ZoneStatus.safe) {
      recommended = 1;
    } else if (lRatio >= rRatio && lStatus != ZoneStatus.danger) {
      recommended = 0;
    } else if (rStatus != ZoneStatus.danger) {
      recommended = 2;
    } else {
      // Semua bahaya — pilih yang paling tinggi rasionya
      if (lRatio >= cRatio && lRatio >= rRatio) {
        recommended = 0;
      } else if (rRatio >= cRatio) {
        recommended = 2;
      } else {
        recommended = 1;
      }
    }

    debugPrint('[PIDNet] L=${lRatio.toStringAsFixed(2)} '
        'C=${cRatio.toStringAsFixed(2)} R=${rRatio.toStringAsFixed(2)} '
        '→ rec=$recommended  (${inferMs.toStringAsFixed(0)}ms)');

    return ZoneAnalysis(
      leftRatio:       lRatio,
      centerRatio:     cRatio,
      rightRatio:      rRatio,
      left:            lStatus,
      center:          cStatus,
      right:           rStatus,
      recommendedZone: recommended,
      inferenceMs:     inferMs,
    );
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}
