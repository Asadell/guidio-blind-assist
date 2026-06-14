import 'dart:async';
import 'dart:math'; // untuk atan2()
import 'package:sensors_plus/sensors_plus.dart';

class CameraHealthResult {
  final bool   ok;
  final String message;
  const CameraHealthResult({required this.ok, required this.message});
}

/// Camera Health Service — cek orientasi kamera via accelerometer.
/// Pengecekan gelap/buram/tertutup dilakukan di server (camera_health.py)
/// dan secara on-device di CameraProvider (brightness dari plane Y).
class CameraHealthService {
  static final CameraHealthService instance = CameraHealthService._();
  CameraHealthService._();

  AccelerometerEvent? _lastAccel;
  StreamSubscription? _accelSub;

  void startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      _lastAccel = event;
    });
  }

  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// Cek orientasi kamera dari data accelerometer.
  /// Flutter cek: posisi/orientasi.
  /// Server cek: gelap, buram, tertutup.
  CameraHealthResult checkOrientation() {
    final accel = _lastAccel;
    if (accel == null) {
      return const CameraHealthResult(ok: true, message: 'OK');
    }

    // Z axis besar + Y kecil = kamera menghadap lantai atau langit-langit
    if (accel.z.abs() > 8 && accel.y.abs() < 4) {
      return const CameraHealthResult(
        ok:      false,
        message: 'Arahkan kamera ke depan',
      );
    }

    // X axis besar = HP terlalu miring ke samping
    if (accel.x.abs() > 8) {
      return const CameraHealthResult(
        ok:      false,
        message: 'Pegang HP tegak',
      );
    }

    return const CameraHealthResult(ok: true, message: 'OK');
  }

  /// Sudut kemiringan kamera ke depan/belakang dalam radian.
  /// Dipakai TFLiteService untuk tilt correction estimasi jarak.
  /// Return 0.0 jika belum ada data accelerometer.
  double get lastTiltAngle {
    if (_lastAccel == null) return 0.0;
    return atan2(_lastAccel!.x, _lastAccel!.z);
  }
}
