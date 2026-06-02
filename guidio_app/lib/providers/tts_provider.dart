import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

class TtsProvider extends ChangeNotifier {
  final _queue    = <String>[];
  bool  _playing  = false;
  String? _current;

  String? get current  => _current;
  bool    get isActive => _playing;

  static const int _maxQueue = 2; // sesuai PRD Cognitive Load Theory

  /// Enqueue pesan TTS.
  /// [critical] = true → clear queue, interrupt TTS saat ini, langsung speak.
  Future<void> enqueue(String message, {bool critical = false}) async {
    if (critical) {
      _queue.clear();
      _current = message;
      notifyListeners();
      await TTSService.instance.speak(message, interrupt: true);
      _playing = false;
      notifyListeners();
      return;
    }

    // Buang jika queue sudah penuh
    if (_queue.length >= _maxQueue) return;
    _queue.add(message);

    if (!_playing) await _processQueue();
  }

  Future<void> _processQueue() async {
    while (_queue.isNotEmpty) {
      _playing = true;
      _current = _queue.removeAt(0);
      notifyListeners();

      // speak() resolve saat selesai (awaitSpeakCompletion=true di TTSService)
      await TTSService.instance.speak(_current!);
    }
    _playing = false;
    _current = null;
    notifyListeners();
  }

  Future<void> stop() async {
    _queue.clear();
    await TTSService.instance.stop();
    _playing = false;
    _current = null;
    notifyListeners();
  }
}
