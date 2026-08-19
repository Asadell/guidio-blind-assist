import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service — Text-to-Speech, satu-satunya pintu keluar suara aplikasi.
///
/// **Aturan mutlak: tidak ada ucapan yang dibuang diam-diam.**
///
/// Versi sebelumnya menjaga flag `_speaking` lalu membungkus `speak()` dengan
/// `if (!_speaking)`. Akibatnya setiap permintaan bicara yang datang saat TTS
/// sedang berjalan **hilang tanpa jejak** — termasuk peringatan rintangan —
/// dan pemanggilnya tetap menerima Future yang selesai normal, jadi
/// [TtsQueue] mengira pesannya sudah tersampaikan. Untuk pengguna yang
/// berjalan sambil mengandalkan suara, itu bukan bug performa; itu peringatan
/// bahaya yang tidak pernah terdengar.
///
/// Sekarang ucapan diserialkan lewat rantai Future ([_tail]). Yang datang
/// belakangan menunggu gilirannya, bukan dibuang. Interupsi tetap mungkin dan
/// bersifat eksplisit lewat `interrupt: true` / [stop], yang menaikkan
/// [_generation] sehingga ucapan yang masih mengantre membatalkan dirinya
/// sendiri alih-alih terlanjur bicara sesudah pengguna menghentikannya.
class TTSService {
  static final TTSService instance = TTSService._();
  TTSService._();

  static const String localeId = 'id-ID';
  static const String localeEn = 'en-US';

  final FlutterTts _tts = FlutterTts();

  bool _speaking = false;
  bool get isSpeaking => _speaking;

  /// Locale yang sedang terpasang di engine. Dilacak supaya `setLanguage`
  /// hanya dipanggil saat benar-benar berganti — pemanggilan berulang pada
  /// sebagian engine Android memotong ucapan yang sedang berjalan.
  String _engineLocale = localeId;

  /// Ekor rantai serial. Setiap [speak] menyambung di belakangnya.
  Future<void> _tail = Future<void>.value();

  /// Dinaikkan oleh [stop] dan oleh ucapan `interrupt: true`.
  int _generation = 0;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.5); // sedikit lambat, lebih terdengar saat berjalan
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // speak() baru resolve setelah engine benar-benar selesai bicara. Tanpa
    // ini, serialisasi di bawah tidak ada artinya: semua ucapan akan
    // "selesai" seketika dan saling menimpa di engine.
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((msg) {
      _speaking = false;
      debugPrint('[TTS] error: $msg');
    });

    _initialized = true;
  }

  /// Ucapkan [message]. Selalu tersampaikan kecuali dibatalkan [stop] atau
  /// oleh ucapan lain yang meminta [interrupt].
  ///
  /// [english] memakai locale `en-US` (hasil Moondream2), lalu mengembalikan
  /// engine ke `id-ID` — pengembaliannya di blok `finally`, jadi kegagalan di
  /// tengah tidak meninggalkan aplikasi berbicara Inggris selamanya.
  Future<void> speak(
    String message, {
    bool interrupt = false,
    bool english = false,
  }) {
    final text = message.trim();
    if (text.isEmpty) return Future<void>.value();

    if (interrupt) {
      _generation++;
      // Rantai lama ditinggalkan: ucapan yang masih mengantre di belakangnya
      // akan melihat generasi yang sudah berubah lalu berhenti sendiri.
      _tail = Future<void>.value();
    }

    final myGeneration = _generation;
    final previous = _tail;

    final next = previous.then((_) async {
      if (myGeneration != _generation) return; // dibatalkan saat mengantre
      await _utter(text, english: english, interrupt: interrupt);
    }).catchError((Object e) {
      debugPrint('[TTS] speak gagal: $e');
    });

    _tail = next;
    return next;
  }

  /// Baca hasil deskripsi Moondream2 dalam Bahasa Inggris.
  Future<void> speakEnglish(String message, {bool interrupt = false}) =>
      speak(message, interrupt: interrupt, english: true);

  Future<void> _utter(String text, {required bool english, required bool interrupt}) async {
    final target = english ? localeEn : localeId;

    if (interrupt) {
      await _tts.stop();
      _speaking = false;
    }

    try {
      if (_engineLocale != target) {
        await _tts.setLanguage(target);
        _engineLocale = target;
      }
      _speaking = true;
      await _tts.speak(text);
    } finally {
      _speaking = false;
      // Bahasa Inggris hanya berlaku untuk satu ucapan. Dikembalikan di
      // `finally` supaya exception di tengah tidak mengunci locale.
      if (english && _engineLocale != localeId) {
        try {
          await _tts.setLanguage(localeId);
          _engineLocale = localeId;
        } catch (e) {
          debugPrint('[TTS] gagal kembali ke $localeId: $e');
        }
      }
    }
  }

  /// Kecepatan bicara — Pengaturan "Kecepatan bicara".
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  /// Hentikan yang sedang bicara DAN batalkan yang masih mengantre.
  Future<void> stop() async {
    _generation++;
    _tail = Future<void>.value();
    _speaking = false;
    await _tts.stop();
  }
}
