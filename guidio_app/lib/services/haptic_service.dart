import 'package:vibration/vibration.dart';

import '../providers/settings_provider.dart' show VibrationMode;

/// HapticService - vibration feedback pendamping TTS.
///
/// Di lingkungan bising (pasar, jalan raya), haptic menjadi primary signal.
/// Tidak perlu init() - vibration package sudah handle internally
/// jika device tidak punya vibrator (fail silent).
///
/// Pola berdasarkan penelitian clock-based directional feedback:
/// - Critical: triple pulse cepat (400ms total)
/// - Warning:  double pulse sedang (500ms)
/// - Info:     single pulse panjang (300ms)
///
/// **Menghormati Pengaturan "Getar"** (Aktif / Hanya bahaya / Mati). Sebelum
/// ini, pilihan pengguna tersimpan ke SharedPreferences tapi tidak pernah
/// dibaca siapa pun: mematikan getar tidak mematikan apa pun. Pengaturan yang
/// berbohong lebih buruk daripada pengaturan yang tidak ada, karena pengguna
/// menyangka sudah menyelesaikan masalahnya.
class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  VibrationMode _mode = VibrationMode.active;
  VibrationMode get mode => _mode;

  /// Dipanggil [SettingsProvider] saat boot dan setiap kali pengaturan berubah.
  void setMode(VibrationMode mode) => _mode = mode;

  /// Apakah getar tier ini boleh dijalankan.
  bool _allowed({required bool isDanger}) => switch (_mode) {
        VibrationMode.active => true,
        VibrationMode.criticalOnly => isDanger,
        VibrationMode.off => false,
      };

  // ── Tier peringatan rintangan ─────────────────────────────────────────────

  /// Critical: orang/motor/mobil < 1.5m - triple pulse cepat.
  Future<void> critical() async {
    if (!_allowed(isDanger: true)) return;
    Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
  }

  /// Warning: objek < 3m - double pulse sedang.
  Future<void> warning() async {
    if (!_allowed(isDanger: true)) return;
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  /// Info: objek jauh/tidak berbahaya - single pulse pelan.
  Future<void> info() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 300]);
  }

  // ── Arah navigasi ─────────────────────────────────────────────────────────

  /// Belok kanan: 2 pulse cepat.
  Future<void> turnRight() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 80, 40, 80]);
  }

  /// Belok kiri: 2 pulse lambat.
  Future<void> turnLeft() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  /// Lurus: 1 pulse panjang.
  Future<void> goStraight() async {
    if (!_allowed(isDanger: false)) return;
    Vibration.vibrate(duration: 400);
  }

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
