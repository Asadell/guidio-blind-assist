import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service — Text-to-Speech Bahasa Indonesia.
///
/// Fix dari doc 5 masalah 6:
/// - Gunakan awaitSpeakCompletion(true) dari flutter_tts (Context7 confirmed)
///   agar speak() benar-benar resolve saat TTS selesai bicara.
/// - Critical message menggunakan stop() dulu lalu speak (interrupt).
class TTSService {
  static final TTSService instance = TTSService._();
  TTSService._();

  final FlutterTts _tts     = FlutterTts();
  bool             _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> init() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.5);  // sedikit lambat untuk tunanetra
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // awaitSpeakCompletion(true): speak() akan resolve saat TTS benar-benar selesai
    // Ini dari Context7 flutter_tts docs — lebih simple dari Completer manual
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(()      => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(()    => _speaking = false);
    _tts.setErrorHandler((_)    => _speaking = false);
  }

  /// Speak pesan. Jika [interrupt] = true (untuk critical obstacle):
  /// stop TTS yang sedang jalan lalu langsung speak.
  Future<void> speak(String message, {bool interrupt = false}) async {
    if (interrupt) {
      await _tts.stop();
      _speaking = false;
    }
    if (!_speaking) {
      _speaking = true;
      await _tts.speak(message); // resolve saat selesai karena awaitSpeakCompletion(true)
    }
  }

  /// Konfirmasi saat ganti mode — "Mode baca teks aktif".
  Future<void> announceMode(String modeName) async {
    await stop();
    await speak('Mode $modeName aktif');
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }
}
