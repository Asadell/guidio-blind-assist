import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart';

export '../core/speech/tts_queue.dart' show SpeechTier, SpeechSource;

/// TtsProvider - pembungkus [TtsQueue] tier-based (bagian 15). Dipakai
/// screen/mode baru lewat `context.read<TtsProvider>().speak(msg, tier: ...)`
/// alih-alih memanggil TTSService langsung, supaya aturan interupsi
/// Critical/Warning/Info dan anti-banjir Info konsisten di seluruh app.
class TtsProvider extends ChangeNotifier {
  final _queue = TtsQueue();

  bool get isActive => _queue.isSpeaking;
  SpeechTier? get speakingTier => _queue.speakingTier;

  /// [source] menentukan apakah ucapan ini ikut dibungkam saat pengguna
  /// sedang menahan tombol Bicara. Bawaannya [SpeechSource.mode] - lihat
  /// alasan pemilihan bawaan itu di `SpeechSource`.
  Future<void> speak(
    String message, {
    SpeechTier tier = SpeechTier.info,
    SpeechSource source = SpeechSource.mode,
  }) async {
    notifyListeners();
    await _queue.speak(message, tier: tier, source: source);
    notifyListeners();
  }

  /// Kompatibel dengan pemanggil lama: `critical: true` ≈ `tier: critical`.
  Future<void> enqueue(String message, {bool critical = false}) =>
      speak(message, tier: critical ? SpeechTier.critical : SpeechTier.info);

  Future<void> interruptByUser() => _queue.interruptByUser();

  Future<void> stop() async {
    await _queue.stop();
    notifyListeners();
  }
}
