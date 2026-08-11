import 'dart:async';

import '../../services/tts_service.dart';

/// Prioritas tier suara — bagian 15 "Model interupsi dan antrean audio".
///
/// ```
/// Critical  → memotong semua, tidak bisa dipotong pengguna
/// Warning   → memotong Info, bisa dipotong pengguna
/// Info      → mengantre; dibuang kalau sudah lewat 2 detik
/// ```
enum SpeechTier { info, warning, critical }

class _QueuedSpeech {
  final String message;
  final SpeechTier tier;
  final DateTime queuedAt;
  _QueuedSpeech(this.message, this.tier) : queuedAt = DateTime.now();
}

/// TtsQueue — mesin antrean bertingkat yang dipakai [TtsProvider].
/// Aturan:
/// - Critical: kosongkan antrean, interrupt TTS berjalan, bicara langsung.
/// - Warning: interrupt Info yang sedang bicara; boleh disela pengguna lewat
///   [interruptByUser].
/// - Info: masuk antrean; dibuang jika sudah menunggu > 2 detik saat giliran
///   tiba (anti-banjir, bagian 15).
class TtsQueue {
  final _pending = <_QueuedSpeech>[];
  SpeechTier? _speakingTier;
  bool _draining = false;

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null;

  Future<void> speak(String message, {SpeechTier tier = SpeechTier.info}) async {
    if (tier == SpeechTier.critical) {
      _pending.clear();
      _speakingTier = SpeechTier.critical;
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = null;
      unawaited(_drain());
      return;
    }

    if (tier == SpeechTier.warning && _speakingTier == SpeechTier.info) {
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = SpeechTier.warning;
      _speakingTier = null;
      unawaited(_drain());
      return;
    }

    _pending.add(_QueuedSpeech(message, tier));
    unawaited(_drain());
  }

  /// Pengguna menimpa TTS yang sedang jalan (mis. menekan tombol) — tidak
  /// berlaku untuk peringatan Critical, yang "tidak bisa dipotong pengguna".
  Future<void> interruptByUser() async {
    if (_speakingTier == SpeechTier.critical) return;
    await TTSService.instance.stop();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        _pending.sort((a, b) => b.tier.index.compareTo(a.tier.index));
        final next = _pending.removeAt(0);

        // Info dibuang kalau sudah lewat 2 detik menunggu.
        if (next.tier == SpeechTier.info &&
            DateTime.now().difference(next.queuedAt) > const Duration(seconds: 2)) {
          continue;
        }

        _speakingTier = next.tier;
        await TTSService.instance.speak(next.message);
        _speakingTier = null;
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> stop() async {
    _pending.clear();
    await TTSService.instance.stop();
    _speakingTier = null;
  }
}
