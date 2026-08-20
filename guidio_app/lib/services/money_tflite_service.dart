import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Klasifikasi nominal uang kertas rupiah — SEPENUHNYA ON-DEVICE.
///
/// Tidak pernah memanggil server. Tiga alasan yang tidak bisa ditawar:
/// transaksi tunai sering terjadi tanpa sinyal (pasar, warung), foto uang
/// tidak perlu meninggalkan perangkat, dan pengguna butuh umpan balik
/// seketika saat mengarahkan kamera.
///
/// Model: MobileNetV2 transfer learning (repo `rupiah-vision`), **7 kelas**,
/// varian INT8-quantized dengan I/O float32 — input 224x224x3, output [1,7]
/// softmax. Test accuracy 99,52%; varian INT8 ~98% pada sampel evaluasi.
///
/// **Rentang input: -1..1, BUKAN 0..255.** Ini berbeda dari model lama
/// (`uang_rupiah.tflite`) yang memanggang preprocessing `mobilenet_v2` ke
/// dalam grafnya sehingga menerima piksel mentah. Model ini tidak: di
/// `scripts/01_train.py` normalisasi `x/127.5 - 1` dilakukan di pipeline
/// `tf.data`, di luar model, dan `scripts/02_export_tflite.py` mengekspor
/// tanpa `inference_input_type` sehingga tensor masuk tetap float32 mentah
/// tanpa parameter kuantisasi.
///
/// Salah rentang di sini TIDAK memunculkan error apa pun — interpreter tetap
/// menerima float32 berapa pun nilainya, hanya prediksinya yang diam-diam
/// salah. Di mode uang itu berarti nominal keliru dibacakan ke pengguna
/// tunanetra. Jadi kalau model diganti lagi, periksa dulu apakah
/// preprocessing ada di dalam graf atau tidak, jangan diasumsikan.
///
/// ATURAN MUTLAK: nominal TIDAK PERNAH ditebak. Di bawah ambang keyakinan,
/// yang dikembalikan hanya instruksi perbaikan — salah menyebut nominal ke
/// pengguna tunanetra berarti kerugian uang nyata, jadi false positive di
/// sini jauh lebih berbahaya daripada false negative.
class MoneyTFLiteService {
  static final MoneyTFLiteService instance = MoneyTFLiteService._();
  MoneyTFLiteService._();

  static const String _modelAsset = 'assets/models/rupiah_classifier_int8.tflite';
  static const int _inputSize = 224;

  /// Ambang keyakinan sengaja tinggi. Precedent Seeing AI menyetel presisi
  /// pada confidence sangat tinggi justru untuk menekan false positive pada
  /// alat bantu uang.
  static const double confidenceThreshold = 0.85;

  /// Urutan kelas sesuai `CLASS_ORDER` di `scripts/02_export_tflite.py` dan
  /// isi `assets/models/rupiah_labels.txt` — sudah dicocokkan baris per
  /// baris, **jangan diubah**.
  ///
  /// Kalau model diganti, urutan ini WAJIB dicocokkan ulang: model
  /// mengeluarkan indeks, dan indeks yang dipetakan ke nominal yang salah
  /// menghasilkan jawaban yang percaya diri dan keliru — kegagalan paling
  /// mahal yang bisa dilakukan aplikasi ini.
  static const List<int> classValues = [1000, 2000, 5000, 10000, 20000, 50000, 100000];

  /// Model dilatih pada dataset gabungan Emisi 2016 & 2022 (7 pecahan lengkap).
  static const List<int> unsupportedValues = [];

  Interpreter? _interpreter;
  bool _loading = false;

  bool get isReady => _interpreter != null;

  Future<bool> load() async {
    if (_interpreter != null || _loading) return _interpreter != null;
    _loading = true;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
      debugPrint('[MoneyTFLite] Model siap: $_modelAsset');
      return true;
    } catch (e) {
      debugPrint('[MoneyTFLite] Gagal memuat model: $e');
      _interpreter = null;
      return false;
    } finally {
      _loading = false;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Klasifikasi dari frame kamera YUV420.
  ///
  /// [cropRatio] memanfaatkan bingkai panduan di layar: hanya area tengah
  /// yang dianalisis, jadi bebannya jauh lebih ringan daripada memeriksa
  /// seluruh frame, sekaligus menghilangkan latar yang membingungkan model.
  Future<MoneyResult> classifyCameraImage(
    CameraImage image, {
    double cropRatio = 0.7,
  }) async {
    if (_interpreter == null) {
      return const MoneyResult.unavailable();
    }
    try {
      final input = await compute(
        _prepareInput,
        _PrepareArgs(
          yPlane: image.planes[0].bytes,
          uPlane: image.planes[1].bytes,
          vPlane: image.planes[2].bytes,
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes[1].bytesPerRow,
          uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
          cropRatio: cropRatio,
        ),
      );
      return _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyCameraImage error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  /// Klasifikasi dari JPEG (dipakai tombol "paksa deteksi ulang").
  Future<MoneyResult> classifyJpeg(Uint8List jpegBytes, {double cropRatio = 0.7}) async {
    if (_interpreter == null) return const MoneyResult.unavailable();
    try {
      final input = await compute(
        _prepareJpeg,
        _JpegArgs(bytes: jpegBytes, cropRatio: cropRatio),
      );
      return _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyJpeg error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  MoneyResult _runInference(List<List<List<List<double>>>> input) {
    final output = List.generate(1, (_) => List<double>.filled(classValues.length, 0));
    _interpreter!.run(input, output);
    final probs = output[0];

    var bestIndex = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIndex]) bestIndex = i;
    }
    final confidence = probs[bestIndex];

    // UG-06 — ragu: nominal TIDAK ditampilkan, hanya instruksi perbaikan.
    if (confidence < confidenceThreshold) {
      return MoneyResult.uncertain(confidence);
    }
    return MoneyResult.detected(
      valueIdr: classValues[bestIndex],
      confidence: confidence,
    );
  }
}

/// Hasil klasifikasi. `detected == false` berarti layar HANYA boleh
/// menampilkan instruksi, tidak boleh menampilkan angka apa pun.
class MoneyResult {
  final bool detected;
  final int? valueIdr;
  final double confidence;
  final MoneyFailure? failure;
  final String? message;

  const MoneyResult.detected({required int this.valueIdr, required this.confidence})
      : detected = true,
        failure = null,
        message = null;

  const MoneyResult.uncertain(this.confidence)
      : detected = false,
        valueIdr = null,
        failure = MoneyFailure.lowConfidence,
        message = 'Belum yakin. Dekatkan sedikit dan tahan diam.';

  const MoneyResult.unavailable()
      : detected = false,
        valueIdr = null,
        confidence = 0,
        failure = MoneyFailure.modelUnavailable,
        message = 'Model pengenalan uang belum siap.';

  const MoneyResult.failure(this.message)
      : detected = false,
        valueIdr = null,
        confidence = 0,
        failure = MoneyFailure.error;
}

enum MoneyFailure { lowConfidence, modelUnavailable, error }

// ── Preprocessing di isolate ────────────────────────────────────────────
// Konversi + crop + resize dilakukan lewat `compute()` supaya UI thread
// tidak tersendat: pengguna sering memakai mode ini sambil berdiri di
// kasir, jadi layar harus tetap responsif.

class _PrepareArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int width, height, yRowStride, uvRowStride, uvPixelStride;
  final double cropRatio;

  const _PrepareArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.cropRatio,
  });
}

class _JpegArgs {
  final Uint8List bytes;
  final double cropRatio;
  const _JpegArgs({required this.bytes, required this.cropRatio});
}

const int _size = MoneyTFLiteService._inputSize;

/// Sampling langsung ke grid 224x224 dari area crop — piksel yang diproses
/// turun drastis dibanding mengonversi seluruh frame lalu me-resize.
List<List<List<List<double>>>> _prepareInput(_PrepareArgs a) {
  final cropW = (a.width * a.cropRatio).round();
  final cropH = (a.height * a.cropRatio).round();
  final offsetX = (a.width - cropW) ~/ 2;
  final offsetY = (a.height - cropH) ~/ 2;

  return [
    List.generate(_size, (ty) {
      final sy = offsetY + (ty * cropH ~/ _size);
      return List.generate(_size, (tx) {
        final sx = offsetX + (tx * cropW ~/ _size);
        final yIdx = sy * a.yRowStride + sx;
        final uvIdx = (sy ~/ 2) * a.uvRowStride + (sx ~/ 2) * a.uvPixelStride;

        final yVal = yIdx < a.yPlane.length ? a.yPlane[yIdx] & 0xFF : 0;
        final uVal = uvIdx < a.uPlane.length ? (a.uPlane[uvIdx] & 0xFF) - 128 : 0;
        final vVal = uvIdx < a.vPlane.length ? (a.vPlane[uvIdx] & 0xFF) - 128 : 0;

        final r = (yVal + 1.402 * vVal).clamp(0, 255).toDouble();
        final g = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toDouble();
        final b = (yVal + 1.772 * uVal).clamp(0, 255).toDouble();

        // Normalisasi ke [-1, 1] — preprocessing mobilenet_v2 TIDAK ada di
        // dalam graf model ini, jadi harus dikerjakan di sini.
        return [r / 127.5 - 1.0, g / 127.5 - 1.0, b / 127.5 - 1.0];
      });
    }),
  ];
}

List<List<List<List<double>>>> _prepareJpeg(_JpegArgs a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) {
    throw StateError('JPEG tidak bisa dibaca');
  }
  final side = (math.min(decoded.width, decoded.height) * a.cropRatio).round();
  final cropped = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = img.copyResize(cropped, width: _size, height: _size);

  return [
    List.generate(_size, (y) {
      return List.generate(_size, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 127.5 - 1.0, p.g / 127.5 - 1.0, p.b / 127.5 - 1.0];
      });
    }),
  ];
}
