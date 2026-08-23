import 'dart:async';
import 'dart:math' as math;
// Offset dipakai untuk titik fokus. `package:flutter/foundation.dart`
// tidak mengekspornya, jadi diimpor eksplisit di sini supaya file ini
// tidak bergantung pada import material/painting dari file lain.
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;

/// Hasil penilaian ketajaman satu frame.
class SharpnessResult {
  final double score;
  final double brightness;
  final int width;
  final int height;
  final int elapsedMs;

  const SharpnessResult({
    required this.score,
    required this.brightness,
    required this.width,
    required this.height,
    required this.elapsedMs,
  });
}

/// Verdict kualitas sebelum kirim.
enum CaptureVerdict { good, acceptable, blurry, tooDark, tooBright }

extension CaptureVerdictX on CaptureVerdict {
  /// Layak dikirim ke model atau server.
  ///
  /// `acceptable` sengaja ikut lolos: gambar yang kurang tajam masih bisa
  /// memberi hasil berguna, dan menolaknya membuat fitur terasa rewel.
  /// Yang ditolak hanya yang benar-benar tidak mungkin dibaca.
  bool get isUsable =>
      this == CaptureVerdict.good || this == CaptureVerdict.acceptable;
}

class CaptureResult {
  final XFile? file;
  final Uint8List? bytes;
  final CaptureVerdict verdict;
  final SharpnessResult? sharpness;
  final int attempts;
  final String message;
  final int totalMs;

  const CaptureResult({
    this.file,
    this.bytes,
    required this.verdict,
    this.sharpness,
    required this.attempts,
    required this.message,
    required this.totalMs,
  });

  bool get isUsable => verdict.isUsable;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Perhitungan di isolate
// ═══════════════════════════════════════════════════════════════════════════

class _SharpnessRequest {
  final Uint8List luma;
  final int width;
  final int height;
  final int rowStride;

  const _SharpnessRequest(this.luma, this.width, this.height, this.rowStride);
}

/// Variance of Laplacian pada bidang luma.
///
/// ## Kenapa memakai bidang Y mentah, bukan mendekode JPEG
///
/// Format `YUV420` dari `CameraImage` sudah memberi bidang luma (Y) secara
/// terpisah. Itu persis grayscale yang dibutuhkan. Mendekode JPEG dulu lalu
/// mengonversi ke grayscale berarti melakukan dua pekerjaan berat yang
/// hasilnya sama, dan pada HP mid-low itu bisa memakan ratusan milidetik
/// per frame.
///
/// ## Kenapa dinormalisasi ke tinggi tetap
///
/// Variance of Laplacian berskala dengan resolusi. Foto 12 MP yang sedikit
/// buram bisa memberi skor lebih tinggi daripada foto 2 MP yang tajam.
/// Tanpa normalisasi, satu ambang tidak akan pernah bekerja lintas
/// perangkat, dan itu persis kondisi yang dihadapi: HP mid-low bercampur
/// HP bagus. Di sini normalisasi dilakukan dengan subsampling ke sekitar
/// 480 baris.
SharpnessResult _computeSharpness(_SharpnessRequest req) {
  final sw = Stopwatch()..start();

  const targetHeight = 480;
  final step = math.max(1, (req.height / targetHeight).floor());

  final w = req.width ~/ step;
  final h = req.height ~/ step;

  if (w < 8 || h < 8) {
    return SharpnessResult(
      score: 0, brightness: 0, width: w, height: h,
      elapsedMs: sw.elapsedMilliseconds,
    );
  }

  // Subsample ke buffer rapat
  final gray = Uint8List(w * h);
  var sum = 0;
  for (var y = 0; y < h; y++) {
    final srcRow = (y * step) * req.rowStride;
    final dstRow = y * w;
    for (var x = 0; x < w; x++) {
      final v = req.luma[srcRow + x * step];
      gray[dstRow + x] = v;
      sum += v;
    }
  }
  final brightness = sum / (w * h);

  // Laplacian 3x3: [[0,1,0],[1,-4,1],[0,1,0]]
  //
  // Mean dan variance dihitung dalam satu lintasan (rumus E[x^2]-E[x]^2)
  // supaya tidak perlu menyimpan seluruh peta Laplacian di memori.
  var lapSum = 0.0;
  var lapSumSq = 0.0;
  var count = 0;

  for (var y = 1; y < h - 1; y++) {
    final row = y * w;
    final up = (y - 1) * w;
    final down = (y + 1) * w;
    for (var x = 1; x < w - 1; x++) {
      final lap = gray[up + x] +
          gray[down + x] +
          gray[row + x - 1] +
          gray[row + x + 1] -
          4 * gray[row + x];
      final v = lap.toDouble();
      lapSum += v;
      lapSumSq += v * v;
      count++;
    }
  }

  if (count == 0) {
    return SharpnessResult(
      score: 0, brightness: brightness, width: w, height: h,
      elapsedMs: sw.elapsedMilliseconds,
    );
  }

  final mean = lapSum / count;
  final variance = (lapSumSq / count) - (mean * mean);

  return SharpnessResult(
    score: variance < 0 ? 0 : variance,
    brightness: brightness,
    width: w,
    height: h,
    elapsedMs: sw.elapsedMilliseconds,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service
// ═══════════════════════════════════════════════════════════════════════════

/// CameraCaptureService - memastikan foto yang dikirim ke backend sudah
/// setajam yang bisa didapat dari perangkat ini.
///
/// ## Kenapa ini lebih penting daripada sharpening di backend
///
/// Blur menghilangkan informasi frekuensi tinggi secara permanen. Unsharp
/// masking di server tidak mengembalikan detail yang hilang; dia cuma
/// menaikkan kontras di tepi yang masih tersisa. Untuk teks kecil yang
/// sudah lumer, tidak ada yang bisa dipertajam.
///
/// Jadi urutan prioritas yang benar adalah: cegah di sumbernya (di sini),
/// baru tambal seadanya di server.
///
/// ## Tiga lapis pencegahan
///
/// 1. **Kunci fokus & eksposur sebelum jepret.** Autofocus HP mid-low
///    lambat, dan `takePicture()` tidak menunggu AF selesai. Hasilnya
///    foto diambil di tengah proses fokus.
/// 2. **Multi-frame, pilih yang tertajam.** Mengambil beberapa frame lalu
///    memilih yang skor Laplacian-nya tertinggi. Ini teknik yang sama
///    dengan yang dipakai aplikasi kamera untuk memilih frame terbaik
///    dari burst.
/// 3. **Gerbang sebelum kirim.** Kalau yang tertajam pun masih di bawah
///    ambang, jangan kirim. Beri instruksi konkret ke pengguna.
///
/// ## Catatan kompatibilitas
///
/// Beberapa perangkat Android bermasalah dengan perpindahan mode fokus
/// terkunci ke otomatis, dan sebagian lain tidak menerapkan titik fokus
/// tanpa mode terkunci lebih dulu. Semua panggilan fokus di sini dibungkus
/// `try-catch` dan kegagalannya tidak menghentikan pengambilan gambar:
/// lebih baik dapat foto tanpa penguncian fokus daripada tidak dapat foto
/// sama sekali.
class CameraCaptureService {
  static final CameraCaptureService instance = CameraCaptureService._();
  CameraCaptureService._();

  // ── Ambang ─────────────────────────────────────────────────────────
  //
  // WAJIB DIKALIBRASI dengan HP target sebelum produksi. Angka ini titik
  // awal, bukan konstanta universal: skor Laplacian sangat bergantung isi
  // gambar. Foto tembok polos yang tajam bisa berskor lebih rendah
  // daripada foto rerumputan yang buram.
  //
  // Pakai [collectCalibrationSamples] untuk mengumpulkan skor dari foto
  // asli, lalu setel ambang di sekitar persentil 10-30.

  double blurRejectThreshold = 45.0;
  double blurWarnThreshold = 100.0;
  double darkThreshold = 45.0;
  double brightThreshold = 240.0;

  /// Berapa frame yang diambil lalu dipilih yang tertajam.
  int burstFrames = 3;

  /// Jeda setelah mengunci fokus, sebelum menjepret.
  ///
  /// Autofocus butuh waktu konvergen. Tanpa jeda ini, penguncian fokus
  /// praktis tidak ada gunanya karena foto diambil sebelum lensanya
  /// selesai bergerak. 450 ms adalah kompromi; HP yang sangat lambat
  /// mungkin butuh lebih.
  Duration focusSettleDelay = const Duration(milliseconds: 450);

  /// Berapa kali mencoba ulang kalau hasilnya masih buram.
  int maxRetries = 1;

  bool _busy = false;
  final _recentScores = <double>[];

  List<double> get recentScores => List.unmodifiable(_recentScores);

  // ── Fokus & eksposur ───────────────────────────────────────────────

  /// Kunci fokus dan eksposur di tengah frame lalu tunggu konvergen.
  ///
  /// Return true kalau penguncian berhasil. Kegagalan bukan alasan untuk
  /// membatalkan pengambilan gambar.
  Future<bool> lockFocusAndExposure(
    CameraController controller, {
    Offset point = const Offset(0.5, 0.5),
  }) async {
    if (!controller.value.isInitialized) return false;

    var ok = true;

    try {
      await controller.setFocusPoint(point);
    } catch (e) {
      debugPrint('[capture] setFocusPoint gagal: $e');
      ok = false;
    }

    try {
      await controller.setExposurePoint(point);
    } catch (e) {
      debugPrint('[capture] setExposurePoint gagal: $e');
    }

    // Beri waktu AF/AE konvergen SEBELUM mengunci. Mengunci lebih dulu
    // akan membekukan lensa di posisi yang belum tentu benar.
    await Future<void>.delayed(focusSettleDelay);

    try {
      await controller.setFocusMode(FocusMode.locked);
    } catch (e) {
      debugPrint('[capture] setFocusMode(locked) gagal: $e');
      ok = false;
    }

    try {
      await controller.setExposureMode(ExposureMode.locked);
    } catch (e) {
      debugPrint('[capture] setExposureMode(locked) gagal: $e');
    }

    return ok;
  }

  /// Kembalikan ke mode otomatis.
  ///
  /// Selalu panggil ini setelah selesai. Membiarkan fokus terkunci
  /// membuat mode deteksi realtime berikutnya memakai fokus yang salah
  /// untuk jarak yang berbeda, dan gejalanya sulit dilacak: deteksi
  /// tiba-tiba memburuk tanpa sebab yang jelas.
  Future<void> unlockFocusAndExposure(CameraController controller) async {
    if (!controller.value.isInitialized) return;
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('[capture] setFocusMode(auto) gagal: $e');
    }
    try {
      await controller.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('[capture] setExposureMode(auto) gagal: $e');
    }
  }

  // ── Penilaian ketajaman ────────────────────────────────────────────

  /// Hitung ketajaman dari `CameraImage` (stream), di isolate terpisah.
  ///
  /// Menjalankan ini di isolate itu wajib, bukan optimasi. Perhitungan
  /// Laplacian pada frame 1280x720 memakan waktu yang cukup untuk
  /// melewatkan beberapa frame UI kalau dikerjakan di thread utama, dan
  /// gejalanya adalah preview kamera yang tersendat persis saat pengguna
  /// sedang membidik.
  Future<SharpnessResult?> assessCameraImage(CameraImage image) async {
    if (image.planes.isEmpty) return null;
    try {
      final plane = image.planes.first;
      final req = _SharpnessRequest(
        plane.bytes,
        image.width,
        image.height,
        plane.bytesPerRow,
      );
      return await compute(_computeSharpness, req);
    } catch (e) {
      debugPrint('[capture] assessCameraImage gagal: $e');
      return null;
    }
  }

  /// Versi sinkron untuk dipakai DI DALAM isolate atau saat sudah di
  /// background. Jangan panggil dari thread UI pada frame besar.
  SharpnessResult assessLumaSync(
    Uint8List luma,
    int width,
    int height,
    int rowStride,
  ) =>
      _computeSharpness(_SharpnessRequest(luma, width, height, rowStride));

  CaptureVerdict verdictFor(SharpnessResult s) {
    // Eksposur dicek DULUAN.
    //
    // Foto yang sangat gelap otomatis berskor Laplacian rendah, karena
    // tidak ada kontras untuk dideteksi tepinya. Kalau blur dicek lebih
    // dulu, sistem akan bilang "buram" padahal masalahnya gelap, dan
    // pengguna lalu menahan ponsel lebih diam (tindakan yang salah)
    // alih-alih menyalakan lampu.
    if (s.brightness < darkThreshold) return CaptureVerdict.tooDark;
    if (s.brightness > brightThreshold) return CaptureVerdict.tooBright;
    if (s.score < blurRejectThreshold) return CaptureVerdict.blurry;
    if (s.score < blurWarnThreshold) return CaptureVerdict.acceptable;
    return CaptureVerdict.good;
  }

  String messageFor(CaptureVerdict v) => switch (v) {
        CaptureVerdict.good => '',
        CaptureVerdict.acceptable => '',
        CaptureVerdict.blurry =>
          'Gambar buram. Tahan ponsel lebih diam sebentar, lalu coba lagi.',
        CaptureVerdict.tooDark =>
          'Terlalu gelap. Cari tempat yang lebih terang atau nyalakan senter.',
        CaptureVerdict.tooBright =>
          'Terlalu silau. Coba ubah posisi supaya tidak menghadap cahaya langsung.',
      };

  // ── Pengambilan gambar ─────────────────────────────────────────────

  /// Ambil foto tertajam yang bisa didapat, dengan penguncian fokus,
  /// burst, dan percobaan ulang.
  ///
  /// [onFeedback] dipanggil dengan pesan Bahasa Indonesia saat perlu
  /// memberi tahu pengguna. Sambungkan ke TtsQueue.
  Future<CaptureResult> captureSharpest(
    CameraController controller, {
    void Function(String message)? onFeedback,
    bool lockFocus = true,
    int? burstOverride,
  }) async {
    final sw = Stopwatch()..start();

    if (_busy) {
      return const CaptureResult(
        verdict: CaptureVerdict.blurry,
        attempts: 0,
        message: 'Masih memproses foto sebelumnya.',
        totalMs: 0,
      );
    }
    if (!controller.value.isInitialized) {
      return const CaptureResult(
        verdict: CaptureVerdict.blurry,
        attempts: 0,
        message: 'Kamera belum siap.',
        totalMs: 0,
      );
    }

    _busy = true;
    var attempts = 0;

    try {
      if (lockFocus) {
        await lockFocusAndExposure(controller);
      }

      XFile? bestFile;
      Uint8List? bestBytes;
      SharpnessResult? bestSharp;

      final n = burstOverride ?? burstFrames;

      for (var retry = 0; retry <= maxRetries; retry++) {
        for (var i = 0; i < n; i++) {
          attempts++;
          XFile file;
          try {
            file = await controller.takePicture();
          } catch (e) {
            debugPrint('[capture] takePicture gagal: $e');
            continue;
          }

          final bytes = await file.readAsBytes();
          final sharp = await _assessJpegBytes(bytes);
          if (sharp == null) continue;

          if (bestSharp == null || sharp.score > bestSharp.score) {
            bestSharp = sharp;
            bestFile = file;
            bestBytes = bytes;
          }

          // Sudah cukup tajam, tidak perlu frame tambahan.
          if (sharp.score >= blurWarnThreshold) break;
        }

        if (bestSharp == null) break;

        final verdict = verdictFor(bestSharp);
        if (verdict != CaptureVerdict.blurry) break;

        // Masih buram: beri instruksi lalu coba lagi.
        if (retry < maxRetries) {
          onFeedback?.call('Tahan ponsel lebih diam sebentar.');
          await Future<void>.delayed(const Duration(milliseconds: 900));
          if (lockFocus) {
            await unlockFocusAndExposure(controller);
            await lockFocusAndExposure(controller);
          }
        }
      }

      if (bestSharp == null || bestBytes == null) {
        const msg = 'Gagal mengambil foto. Coba lagi.';
        onFeedback?.call(msg);
        return CaptureResult(
          verdict: CaptureVerdict.blurry,
          attempts: attempts,
          message: msg,
          totalMs: sw.elapsedMilliseconds,
        );
      }

      _recordScore(bestSharp.score);

      final verdict = verdictFor(bestSharp);
      final message = messageFor(verdict);
      if (message.isNotEmpty) onFeedback?.call(message);

      debugPrint('[capture] skor=${bestSharp.score.toStringAsFixed(1)} '
          'terang=${bestSharp.brightness.toStringAsFixed(0)} '
          'verdict=${verdict.name} percobaan=$attempts '
          '${sw.elapsedMilliseconds}ms');

      return CaptureResult(
        file: bestFile,
        bytes: bestBytes,
        verdict: verdict,
        sharpness: bestSharp,
        attempts: attempts,
        message: message,
        totalMs: sw.elapsedMilliseconds,
      );
    } finally {
      if (lockFocus) {
        await unlockFocusAndExposure(controller);
      }
      _busy = false;
    }
  }

  /// Nilai ketajaman dari bytes JPEG.
  ///
  /// Ini jalur yang lebih lambat daripada [assessCameraImage] karena harus
  /// mendekode JPEG lebih dulu. Dipakai hanya untuk foto hasil
  /// `takePicture()`, yang memang sudah dalam bentuk JPEG.
  ///
  /// Implementasinya sengaja dipisah supaya kamu bisa menggantinya dengan
  /// dekoder yang lebih cepat (misal lewat platform channel ke
  /// `BitmapFactory` dengan `inSampleSize`) tanpa menyentuh sisa kelas ini.
  Future<SharpnessResult?> _assessJpegBytes(Uint8List jpeg) async {
    try {
      return await compute(_decodeAndAssess, jpeg);
    } catch (e) {
      debugPrint('[capture] _assessJpegBytes gagal: $e');
      return null;
    }
  }

  void _recordScore(double score) {
    _recentScores.add(score);
    if (_recentScores.length > 100) _recentScores.removeAt(0);
  }

  /// Kumpulkan sampel untuk kalibrasi ambang.
  ///
  /// Cara pakai: aktifkan mode ini, minta beberapa pengguna memakai app
  /// secara normal (termasuk saat hasilnya gagal), lalu panggil
  /// [calibrationSuggestion].
  ///
  /// Kumpulkan foto APA ADANYA, termasuk yang gagal. Kalau kamu kalibrasi
  /// dengan foto pilihan yang semuanya bagus, ambangnya akan terlalu
  /// longgar dan gerbangnya jadi tidak ada gunanya.
  void collectCalibrationSamples() => _recentScores.clear();

  Map<String, double> calibrationSuggestion() {
    if (_recentScores.length < 20) {
      return const {};
    }
    final sorted = List<double>.from(_recentScores)..sort();
    double p(double q) => sorted[(sorted.length * q).floor().clamp(
          0,
          sorted.length - 1,
        )];
    return {
      'p10': p(0.10),
      'p30': p(0.30),
      'p50': p(0.50),
      'p70': p(0.70),
      'saran_blurReject': p(0.10),
      'saran_blurWarn': p(0.30),
      'n_sampel': _recentScores.length.toDouble(),
    };
  }
}

/// Dekode JPEG lalu hitung ketajaman. Berjalan di isolate.
///
/// Memakai `package:image` yang murni Dart, jadi tidak butuh dependensi
/// native tambahan.
///
/// ## Kenapa mendekode dengan pengecilan
///
/// Dekode JPEG penuh pada foto 12 MP memakan waktu lama di HP mid-low,
/// dan hasilnya tidak dibutuhkan: skor ketajaman toh dinormalisasi ke
/// sekitar 480 baris. `decodeJpg` dengan parameter `frame` tidak
/// menyediakan pengecilan, jadi pengecilan dilakukan setelah dekode
/// memakai pembacaan piksel berjarak. Itu tetap jauh lebih murah daripada
/// membangun buffer luma penuh lalu mengecilkannya.
///
/// Saran tambahan: pakai `ResolutionPreset.high` (1280x720) alih-alih
/// `veryHigh` atau `max`. Resolusi lebih tinggi tidak membantu OCR maupun
/// deteksi objek pada kasus ini, tapi memperlambat setiap langkah
/// sesudahnya, termasuk unggahan ke server.
SharpnessResult _decodeAndAssess(Uint8List jpeg) {
  final sw = Stopwatch()..start();

  final decoded = im.decodeJpg(jpeg);
  if (decoded == null) {
    return SharpnessResult(
      score: 0,
      brightness: 0,
      width: 0,
      height: 0,
      elapsedMs: sw.elapsedMilliseconds,
    );
  }

  final srcW = decoded.width;
  final srcH = decoded.height;

  const targetHeight = 480;
  final step = math.max(1, (srcH / targetHeight).floor());
  final w = srcW ~/ step;
  final h = srcH ~/ step;

  if (w < 8 || h < 8) {
    return SharpnessResult(
      score: 0,
      brightness: 0,
      width: w,
      height: h,
      elapsedMs: sw.elapsedMilliseconds,
    );
  }

  // Bangun buffer luma langsung pada resolusi target.
  final luma = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    final srcY = y * step;
    final dstRow = y * w;
    for (var x = 0; x < w; x++) {
      final pixel = decoded.getPixel(x * step, srcY);
      luma[dstRow + x] = im.getLuminance(pixel).toInt().clamp(0, 255);
    }
  }

  final result = _computeSharpness(_SharpnessRequest(luma, w, h, w));

  return SharpnessResult(
    score: result.score,
    brightness: result.brightness,
    width: result.width,
    height: result.height,
    elapsedMs: sw.elapsedMilliseconds,
  );
}
