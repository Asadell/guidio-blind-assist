import 'package:vibration/vibration.dart';

/// HapticService — vibration feedback pendamping TTS.
///
/// Di lingkungan bising (pasar, jalan raya), haptic menjadi primary signal.
/// Tidak perlu init() — vibration package sudah handle internally
/// jika device tidak punya vibrator (fail silent).
///
/// Pola berdasarkan penelitian clock-based directional feedback:
/// - Critical: triple pulse cepat (400ms total)
/// - Warning:  double pulse sedang (500ms)
/// - Info:     single pulse panjang (300ms)
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  // ── Tier peringatan rintangan ─────────────────────────────────────────────

  /// Critical: orang/motor/mobil < 1.5m — triple pulse cepat.
  Future<void> critical() async =>
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);

  /// Warning: objek < 3m — double pulse sedang.
  Future<void> warning() async =>
      Vibration.vibrate(pattern: [0, 200, 100, 200]);

  /// Info: objek jauh/tidak berbahaya — single pulse pelan.
  Future<void> info() async =>
      Vibration.vibrate(pattern: [0, 300]);

  // ── Arah navigasi ─────────────────────────────────────────────────────────

  /// Belok kanan: 2 pulse cepat.
  Future<void> turnRight() async =>
      Vibration.vibrate(pattern: [0, 80, 40, 80]);

  /// Belok kiri: 2 pulse lambat.
  Future<void> turnLeft() async =>
      Vibration.vibrate(pattern: [0, 200, 100, 200]);

  /// Lurus: 1 pulse panjang.
  Future<void> goStraight() async =>
      Vibration.vibrate(duration: 400);

  // ── Utility ───────────────────────────────────────────────────────────────

  Future<void> cancel() async => Vibration.cancel();

  /// Dispatch otomatis berdasarkan danger level string.
  /// Dipanggil dari DetectionProvider berdampingan TTS.
  Future<void> fromDangerLevel(String level) async {
    switch (level) {
      case 'critical':
        await critical();
        break;
      case 'warning':
        await warning();
        break;
      case 'info':
        await info();
        break;
    }
  }
}
