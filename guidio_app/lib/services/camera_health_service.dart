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

  /// Seberapa banyak ponsel bergoyang, 0 (diam) sampai 1 (ayunan kuat).
  ///
  /// Saat pengguna berjalan, ponsel yang dipegang ikut mengayun naik-turun.
  /// Ayunan itu membuat kotak deteksi membesar-mengecil sendiri, sehingga
  /// objek yang diam terbaca "maju-mundur" — dan `isApproaching` yang memotong
  /// cooldown 50% ikut menyala tanpa ada yang benar-benar mendekat.
  ///
  /// Diukur dari perubahan percepatan antar sampel. Ini bukan pengganti
  /// gyroscope, tapi cukup untuk **membedakan tangan diam dari tangan
  /// mengayun** — dan itulah satu-satunya yang dibutuhkan: saat goyang, ambang
  /// "mendekat" dinaikkan dan penghalusan jarak diperlambat.
  double _motionLevel = 0.0;
  double get motionLevel => _motionLevel;

  /// True saat ayunan cukup kuat sehingga sinyal jarak tidak bisa dipercaya
  /// begitu saja.
  bool get isShaky => _motionLevel > 0.35;

  void startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      final prev = _lastAccel;
      if (prev != null) {
        final dx = event.x - prev.x;
        final dy = event.y - prev.y;
        final dz = event.z - prev.z;
        final delta = sqrt(dx * dx + dy * dy + dz * dz);
        // Normalisasi kasar: Δ 4 m/s² antar sampel sudah tergolong ayunan
        // penuh saat berjalan. EMA menahan lonjakan satu sampel agar satu
        // sentakan tidak langsung dianggap goyang terus-menerus.
        final instant = (delta / 4.0).clamp(0.0, 1.0);
        _motionLevel = _motionLevel * 0.7 + instant * 0.3;
      }
      _lastAccel = event;
    });
  }

  void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _motionLevel = 0.0;
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
