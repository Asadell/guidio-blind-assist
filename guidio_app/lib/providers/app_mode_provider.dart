import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

enum AppMode { tuntun, ocr, navigasi, voice }

extension AppModeLabel on AppMode {
  String get label => switch (this) {
        AppMode.tuntun   => 'Deteksi Objek',
        AppMode.ocr      => 'Baca Teks',
        AppMode.navigasi => 'Navigasi',
        AppMode.voice    => 'Asisten Suara',
      };

  String get icon => switch (this) {
        AppMode.tuntun   => '👁',
        AppMode.ocr      => '📄',
        AppMode.navigasi => '🧭',
        AppMode.voice    => '🎙️',
      };
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  Future<void> setMode(AppMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    // Feedback suara saat ganti mode (sesuai PRD UX)
    await TTSService.instance.announceMode(mode.label);
  }
}
