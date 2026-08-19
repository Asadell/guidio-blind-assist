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
///
/// Fix race condition (temuan 2.4):
/// - Tambahkan [_drainGeneration] token: setiap kali Critical masuk, token
///   dinaikkan sehingga drain lama yang sedang await langsung berhenti saat
///   tiba gilirannya untuk set `_speakingTier = null`.
/// - Critical tidak lagi set `_speakingTier` langsung — cukup invalidasi
///   drain lama + stop + speak dengan interrupt.
/// - Warning juga memakai token yang sama untuk keamanan.
/// - `_pending` dibatasi 8 item; item terlama dibuang saat penuh (anti-OOM).
///
/// Aturan:
/// - Critical: kosongkan antrean, interrupt TTS berjalan, bicara langsung.
/// - Warning: interrupt Info yang sedang bicara; boleh disela pengguna lewat
///   [interruptByUser].
/// - Info: masuk antrean; dibuang jika sudah menunggu > 2 detik saat giliran
///   tiba (anti-banjir, bagian 15).
class TtsQueue {
  /// Singleton — semua caller (DetectionProvider, CameraProvider, TtsProvider,
  /// NavigationProvider, dll) memakai antrian yang sama: "satu pintu suara".
  static final TtsQueue instance = TtsQueue._internal();
  factory TtsQueue() => instance;
  TtsQueue._internal();

  static const int _maxPending = 8;

  final _pending = <_QueuedSpeech>[];
  SpeechTier? _speakingTier;
  bool _draining = false;
  int _drainGeneration = 0; // Fix 2.4: token untuk stop drain lama

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null || _draining;

  Future<void> speak(String message, {SpeechTier tier = SpeechTier.info}) async {
    if (tier == SpeechTier.critical) {
      // Invalidasi semua drain yang sedang berjalan
      _pending.clear();
      _drainGeneration++;
      // Stop TTS yang sedang bicara (Info/Warning) agar Critical langsung terdengar
      await TTSService.instance.stop();
      _speakingTier = SpeechTier.critical;
      await TTSService.instance.speak(message, interrupt: true);
      _speakingTier = null;
      // Drain mungkin ada item baru yang masuk saat critical berbicara
      unawaited(_drain());
      return;
    }

    if (tier == SpeechTier.warning) {
      if (_speakingTier == SpeechTier.info) {
        // Invalidasi drain lama agar tidak lanjut setelah warning selesai
        _drainGeneration++;
        _speakingTier = SpeechTier.warning;
        await TTSService.instance.speak(message, interrupt: true);
        _speakingTier = null;
        unawaited(_drain());
        return;
      }
      // Info belum bicara — cukup antrean sebagai warning
    }

    _pending.add(_QueuedSpeech(message, tier));

    // Batasi 8 item — buang item terlama (Info) saat penuh (anti-OOM)
    if (_pending.length > _maxPending) {
      // Buang item Info terlama; kalau semua Warning, buang yang terlama
      final oldestInfoIdx = _pending.indexWhere((q) => q.tier == SpeechTier.info);
      if (oldestInfoIdx >= 0) {
        _pending.removeAt(oldestInfoIdx);
      } else {
        _pending.removeAt(0);
      }
    }

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
    final myGeneration = _drainGeneration; // snapshot token saat drain dimulai

    try {
      while (_pending.isNotEmpty) {
        // Cek apakah drain ini sudah diinvalidasi oleh Critical/Warning baru
        if (_drainGeneration != myGeneration) break;

        _pending.sort((a, b) => b.tier.index.compareTo(a.tier.index));
        final next = _pending.removeAt(0);

        // Info dibuang kalau sudah lewat 2 detik menunggu.
        if (next.tier == SpeechTier.info &&
            DateTime.now().difference(next.queuedAt) > const Duration(seconds: 2)) {
          continue;
        }

        _speakingTier = next.tier;
        await TTSService.instance.speak(next.message);

        // Setelah await selesai, cek lagi apakah generasi masih valid
        // (mencegah _speakingTier = null menimpa Critical yang sedang bicara)
        if (_drainGeneration == myGeneration) {
          _speakingTier = null;
        }
      }
    } finally {
      _draining = false;
      // Hanya reset _speakingTier jika drain ini masih valid
      if (_drainGeneration == myGeneration && _speakingTier != SpeechTier.critical) {
        _speakingTier = null;
      }
    }
  }

  Future<void> stop() async {
    _pending.clear();
    _drainGeneration++;
    await TTSService.instance.stop();
    _speakingTier = null;
  }
}
