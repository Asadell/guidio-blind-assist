import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Panjang fokus kamera dalam piksel, dibaca dari perangkatnya sendiri.
///
/// Estimasi jarak memakai rumus pinhole:
/// ```
/// jarak_m = tinggi_asli_cm × fokus_px / (tinggi_kotak_px × 100)
/// ```
/// `fokus_px` bukan properti universal - ia tergantung lensa **dan** resolusi
/// keluaran. Konstanta 615 yang dipakai sebelumnya adalah rata-rata yang
/// kebetulan tidak benar untuk perangkat mana pun secara khusus: lensa
/// ultrawide dan telefoto bisa meleset jauh lebih dari 2×, dan seluruh
/// klasifikasi bahaya (`critical` di bawah 1,5 m) mewarisi kesalahannya.
///
/// Android menyimpan angka aslinya di `CameraCharacteristics`. Dari panjang
/// fokus (mm) dan ukuran fisik sensor (mm) kita dapat sudut pandang, dan dari
/// sudut pandang kita dapat fokus dalam piksel untuk resolusi apa pun:
/// ```
/// fokus_px = (lebar_px / 2) / tan(fov / 2)
/// ```
///
/// Ini menggantikan rencana kalibrasi manual dengan meteran di lapangan:
/// tanpa model baru, tanpa pengukuran, dan benar per-perangkat alih-alih
/// benar rata-rata.
///
/// **Gagal itu wajar dan aman.** Emulator, iOS, dan perangkat yang tidak
/// melaporkan intrinsik akan mengembalikan null; pemanggil lalu memakai
/// [fallbackFocalPx]. Deteksi tidak boleh mati hanya karena kalibrasi gagal.
class CameraIntrinsics {
  static final CameraIntrinsics instance = CameraIntrinsics._();
  CameraIntrinsics._();

  static const MethodChannel _channel = MethodChannel('vinara/camera_intrinsics');

  /// Nilai lama, dipertahankan sebagai jaring pengaman saat intrinsik tidak
  /// tersedia. Kira-kira benar untuk kamera ponsel 4:3 pada 640 px.
  static const double fallbackFocalPx = 615.0;

  double? _horizontalFovRad;
  double? _verticalFovRad;
  bool _queried = false;

  /// True kalau nilai berasal dari perangkat, bukan dari fallback.
  bool get isCalibrated => _horizontalFovRad != null;

  double? get horizontalFovDeg =>
      _horizontalFovRad == null ? null : _horizontalFovRad! * 180 / math.pi;

  double? get verticalFovDeg =>
      _verticalFovRad == null ? null : _verticalFovRad! * 180 / math.pi;

  /// Baca intrinsik sekali per proses. Aman dipanggil berkali-kali.
  Future<void> load() async {
    if (_queried) return;
    _queried = true;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('lensInfo');
      if (info == null) {
        debugPrint('[Intrinsics] perangkat tidak melaporkan intrinsik lensa - pakai fallback');
        return;
      }
      final h = (info['horizontalFovRad'] as num?)?.toDouble();
      final v = (info['verticalFovRad'] as num?)?.toDouble();
      // Sanity check: FOV kamera ponsel wajar di 30°–130°. Nilai di luar itu
      // lebih mungkin salah baca daripada lensa aneh, dan lebih baik memakai
      // fallback yang diketahui daripada angka yang diketahui ngawur.
      if (h == null || v == null || h <= 0.5 || h >= 2.3 || v <= 0.3 || v >= 2.3) {
        debugPrint('[Intrinsics] FOV di luar rentang wajar ($h, $v) - pakai fallback');
        return;
      }
      _horizontalFovRad = h;
      _verticalFovRad = v;
      debugPrint('[Intrinsics] FOV terbaca: '
          'H=${(h * 180 / math.pi).toStringAsFixed(1)}° '
          'V=${(v * 180 / math.pi).toStringAsFixed(1)}° '
          '(fokus ${info['focalLengthMm']}mm, sensor ${info['sensorWidthMm']}×${info['sensorHeightMm']}mm)');
    } catch (e) {
      debugPrint('[Intrinsics] gagal membaca intrinsik: $e - pakai fallback');
    }
  }

  /// Fokus dalam piksel pada sumbu **vertikal bingkai tegak**.
  ///
  /// Ponsel terkunci portrait sementara sensor memberi frame landscape, jadi
  /// sumbu vertikal yang dilihat pengguna adalah sumbu **horizontal** sensor.
  /// [srcWidth] adalah lebar frame sensor (mis. 640) - itulah yang menjadi
  /// tinggi bingkai tegak, dan itulah sumbu tempat tinggi kotak diukur.
  double focalPxForUprightFrame(int srcWidth) {
    final fov = _horizontalFovRad;
    if (fov == null) return fallbackFocalPx;
    return (srcWidth / 2) / math.tan(fov / 2);
  }
}
