import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Klasifikasi nominal uang kertas rupiah - SEPENUHNYA ON-DEVICE.
///
/// Tidak pernah memanggil server. Tiga alasan yang tidak bisa ditawar:
/// transaksi tunai sering terjadi tanpa sinyal (pasar, warung), foto uang
/// tidak perlu meninggalkan perangkat, dan pengguna butuh umpan balik
/// seketika saat mengarahkan kamera.
///
/// Model: MobileNetV2 transfer learning (repo `rupiah_vision_revised`),
/// **7 kelas**, varian float16 dengan I/O float32 - input 224x224x3, output
/// [1,7] softmax. Val accuracy 98,76%, test 97,98%, test_hard 94,40%.
///
/// ## Tiga hal yang HARUS cocok, dan tidak satu pun akan melempar error
///
/// Semua kesalahan di bawah ini menghasilkan angka yang tampak wajar. Tidak
/// ada exception, tidak ada yang aneh di log - hanya prediksi yang diam-diam
/// salah. Di mode uang itu berarti nominal keliru dibacakan ke pengguna
/// tunanetra, yang tidak punya cara memverifikasinya sendiri.
///
/// **1. Rentang input -1..1, BUKAN 0..255.** Preprocessing `mobilenet_v2`
/// TIDAK dipanggang ke dalam graf: di `scripts/01_train.py` normalisasi
/// `x/127.5 - 1` dilakukan di pipeline `tf.data`, di luar model.
///
/// **2. Letterbox, BUKAN peregangan.** Training memakai
/// `tf.image.resize_with_pad` (lihat `assets/models/rupiah_class_info.json`),
/// jadi rasio aspek dipertahankan dan sisanya diberi bantalan bernilai -1,0
/// setelah normalisasi. Uang kertas aspeknya sekitar 2:1; meregangkannya jadi
/// persegi memberi model proporsi yang tidak pernah dilihatnya saat training.
///
/// **3. Keluaran softmax, BUKAN logit.** Layer terakhir model Keras aslinya
/// `Dense(activation="linear")`, jadi berkas `.keras` mengeluarkan logit
/// mentah. Softmax DITAMBAHKAN saat konversi ke TFLite, dan itu wajib:
/// [confidenceThreshold] membandingkan keluaran dengan 0,85, sementara logit
/// rutin melewati angka itu bahkan saat tebakannya salah. Tanpa softmax,
/// pengaman "nominal tidak pernah ditebak" lumpuh total.
///
/// Bukti bahwa pengaman itu bekerja, dari berkas uji `test/fixtures/money`:
/// pada `uang_10000_b.jpg` model salah menebak 2000, tapi keyakinannya
/// 0,44 - di bawah ambang, jadi aplikasi bilang "ragu" alih-alih menyebut
/// nominal yang salah. Dengan logit angkanya 1,75 dan nominal keliru itu
/// akan dibacakan dengan penuh percaya diri.
///
/// Jadi kalau model diganti lagi: periksa ketiganya, jangan diasumsikan.
///
/// ATURAN MUTLAK: nominal TIDAK PERNAH ditebak. Di bawah ambang keyakinan,
/// yang dikembalikan hanya instruksi perbaikan - salah menyebut nominal ke
/// pengguna tunanetra berarti kerugian uang nyata, jadi false positive di
/// sini jauh lebih berbahaya daripada false negative.
class MoneyTFLiteService {
  static final MoneyTFLiteService instance = MoneyTFLiteService._();
  MoneyTFLiteService._();

  static const String _modelAsset = 'assets/models/rupiah_classifier_fp16.tflite';
  static const int _inputSize = 224;

  /// Ambang keyakinan sengaja tinggi. Precedent Seeing AI menyetel presisi
  /// pada confidence sangat tinggi justru untuk menekan false positive pada
  /// alat bantu uang.
  static const double confidenceThreshold = 0.85;

  /// Urutan kelas sesuai `idx_to_class` di
  /// `assets/models/rupiah_class_info.json`, yang ikut diturunkan bersama
  /// model - sudah dicocokkan indeks per indeks, **jangan diubah**.
  ///
  /// Kalau model diganti, urutan ini WAJIB dicocokkan ulang: model
  /// mengeluarkan indeks, dan indeks yang dipetakan ke nominal yang salah
  /// menghasilkan jawaban yang percaya diri dan keliru - kegagalan paling
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

    // UG-06 - ragu: nominal TIDAK ditampilkan, hanya instruksi perbaikan.
    if (confidence < confidenceThreshold) {
      return MoneyResult.uncertain(
        confidence,
        topValueIdr: classValues[bestIndex],
        probabilities: List.unmodifiable(probs),
      );
    }
    return MoneyResult.detected(
      valueIdr: classValues[bestIndex],
      confidence: confidence,
      probabilities: List.unmodifiable(probs),
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

  /// Nominal dengan probabilitas TERTINGGI, terisi juga saat `detected == false`.
  ///
  /// UI TIDAK BOLEH memakai field ini - itu justru melanggar aturan "nominal
  /// tidak pernah ditebak" yang dijaga [MoneyTFLiteService.confidenceThreshold].
  /// Gunanya khusus diagnostik dan pengujian: tanpa ini, test tidak bisa
  /// membedakan "model ragu tapi tebakan teratasnya benar" dari "model ragu
  /// DAN tebakan teratasnya salah". Dua kondisi itu butuh perbaikan yang
  /// sangat berbeda, dan menyamakannya membuat suite uji lolos terus.
  final int? topValueIdr;

  /// Distribusi softmax lengkap, urutannya sesuai
  /// [MoneyTFLiteService.classValues]. Dipakai pengujian untuk menghitung
  /// margin ke juara dua - top-1 saja tidak bisa membedakan model yang
  /// bekerja dari model yang sedang menebak di antara 7 kelas.
  final List<double>? probabilities;

  const MoneyResult.detected({
    required int this.valueIdr,
    required this.confidence,
    this.probabilities,
  })  : detected = true,
        failure = null,
        message = null,
        topValueIdr = valueIdr;

  const MoneyResult.uncertain(
    this.confidence, {
    this.topValueIdr,
    this.probabilities,
  })  : detected = false,
        valueIdr = null,
        failure = MoneyFailure.lowConfidence,
        message = 'Belum yakin. Dekatkan sedikit dan tahan diam.';

  const MoneyResult.unavailable()
      : detected = false,
        valueIdr = null,
        confidence = 0,
        topValueIdr = null,
        probabilities = null,
        failure = MoneyFailure.modelUnavailable,
        message = 'Model pengenalan uang belum siap.';

  const MoneyResult.failure(this.message)
      : detected = false,
        valueIdr = null,
        confidence = 0,
        topValueIdr = null,
        probabilities = null,
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

/// Nilai piksel untuk area padding, SETELAH normalisasi.
///
/// Training memakai `tf.image.resize_with_pad`, yang mengisi bantalan dengan
/// 0 pada rentang mentah [0,255]. Setelah `x/127.5 - 1` itu jadi -1,0. Nilai
/// inilah yang harus dipakai di sini - mengisi bantalan dengan 0,0 (abu-abu
/// tengah) memberi model bingkai yang tidak pernah dilihatnya saat training.
const double _padValue = -1.0;

/// Geometri letterbox: skala dan offset untuk memasukkan [srcW]x[srcH] ke
/// dalam kotak [_size]x[_size] tanpa mengubah rasio aspek.
class _Letterbox {
  final double scale;
  final int padX;
  final int padY;
  final int dstW;
  final int dstH;

  factory _Letterbox(int srcW, int srcH) {
    final scale = math.min(_size / srcW, _size / srcH);
    final dstW = math.max(1, (srcW * scale).round());
    final dstH = math.max(1, (srcH * scale).round());
    return _Letterbox._(
      scale: scale,
      dstW: dstW,
      dstH: dstH,
      padX: (_size - dstW) ~/ 2,
      padY: (_size - dstH) ~/ 2,
    );
  }

  const _Letterbox._({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.dstW,
    required this.dstH,
  });

  bool contains(int tx, int ty) =>
      tx >= padX && tx < padX + dstW && ty >= padY && ty < padY + dstH;

  int srcX(int tx) => ((tx - padX) / scale).floor();
  int srcY(int ty) => ((ty - padY) / scale).floor();
}

/// Sampling langsung ke grid 224x224 dari area crop - piksel yang diproses
/// turun drastis dibanding mengonversi seluruh frame lalu me-resize.
///
/// **Memakai letterbox, bukan peregangan.** Model dilatih dengan
/// `tf.image.resize_with_pad` (lihat `rupiah_class_info.json`), jadi rasio
/// aspek dipertahankan dan sisanya diberi bantalan. Versi sebelumnya
/// meregangkan area crop 4:3 menjadi 1:1 - uang kertas yang aspeknya sekitar
/// 2:1 masuk ke model dalam proporsi yang tidak pernah dilihatnya saat
/// training.
///
/// Kesalahan seperti ini tidak memunculkan error apa pun. Interpreter tetap
/// menerima tensornya, hanya prediksinya yang diam-diam memburuk - dan di
/// mode uang itu berarti nominal keliru dibacakan ke pengguna tunanetra.
List<List<List<List<double>>>> _prepareInput(_PrepareArgs a) {
  final cropW = math.max(1, (a.width * a.cropRatio).round());
  final cropH = math.max(1, (a.height * a.cropRatio).round());
  final offsetX = (a.width - cropW) ~/ 2;
  final offsetY = (a.height - cropH) ~/ 2;

  final lb = _Letterbox(cropW, cropH);
  final pad = List<double>.filled(3, _padValue, growable: false);

  return [
    List.generate(_size, (ty) {
      return List.generate(_size, (tx) {
        if (!lb.contains(tx, ty)) return pad;

        final sy = offsetY + lb.srcY(ty).clamp(0, cropH - 1);
        final sx = offsetX + lb.srcX(tx).clamp(0, cropW - 1);

        final yIdx = sy * a.yRowStride + sx;
        final uvIdx = (sy ~/ 2) * a.uvRowStride + (sx ~/ 2) * a.uvPixelStride;

        final yVal = yIdx < a.yPlane.length ? a.yPlane[yIdx] & 0xFF : 0;
        final uVal = uvIdx < a.uPlane.length ? (a.uPlane[uvIdx] & 0xFF) - 128 : 0;
        final vVal = uvIdx < a.vPlane.length ? (a.vPlane[uvIdx] & 0xFF) - 128 : 0;

        final r = (yVal + 1.402 * vVal).clamp(0, 255).toDouble();
        final g = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toDouble();
        final b = (yVal + 1.772 * uVal).clamp(0, 255).toDouble();

        // Normalisasi ke [-1, 1] - preprocessing mobilenet_v2 TIDAK ada di
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

  // Crop MENGIKUTI RASIO SUMBER, sama seperti jalur kamera.
  //
  // Versi sebelumnya memotong persegi di tengah (sisi = min(w,h) * cropRatio)
  // sementara `_prepareInput` memotong `cropRatio` dari lebar DAN tinggi,
  // yang mempertahankan rasio frame. Untuk foto lanskap 4:3 kedua aturan itu
  // memilih area yang berbeda: yang persegi membuang sisi kiri dan kanan -
  // persis tempat angka nominal berada pada uang kertas.
  //
  // Akibatnya "paksa deteksi ulang" bisa menjawab lain dari deteksi langsung
  // pada lembar yang sama. Kegagalan seperti itu mustahil didiagnosis dari
  // lapangan: pengguna cuma tahu aplikasinya "kadang benar kadang tidak".
  final cropW = math.max(1, (decoded.width * a.cropRatio).round());
  final cropH = math.max(1, (decoded.height * a.cropRatio).round());
  final cropped = img.copyCrop(
    decoded,
    x: (decoded.width - cropW) ~/ 2,
    y: (decoded.height - cropH) ~/ 2,
    width: cropW,
    height: cropH,
  );

  final lb = _Letterbox(cropped.width, cropped.height);
  final resized = img.copyResize(
    cropped,
    width: lb.dstW,
    height: lb.dstH,
    interpolation: img.Interpolation.linear,
  );
  final pad = List<double>.filled(3, _padValue, growable: false);

  return [
    List.generate(_size, (y) {
      return List.generate(_size, (x) {
        if (!lb.contains(x, y)) return pad;
        final p = resized.getPixel(
          (x - lb.padX).clamp(0, lb.dstW - 1),
          (y - lb.padY).clamp(0, lb.dstH - 1),
        );
        return [p.r / 127.5 - 1.0, p.g / 127.5 - 1.0, p.b / 127.5 - 1.0];
      });
    }),
  ];
}
