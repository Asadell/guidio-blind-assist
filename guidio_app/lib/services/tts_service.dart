import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service - Text-to-Speech, satu-satunya pintu keluar suara aplikasi.
///
/// **Aturan mutlak: tidak ada ucapan yang dibuang diam-diam.**
///
/// Versi sebelumnya menjaga flag `_speaking` lalu membungkus `speak()` dengan
/// `if (!_speaking)`. Akibatnya setiap permintaan bicara yang datang saat TTS
/// sedang berjalan **hilang tanpa jejak** - termasuk peringatan rintangan -
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
  /// hanya dipanggil saat benar-benar berganti - pemanggilan berulang pada
  /// sebagian engine Android memotong ucapan yang sedang berjalan.
  String _engineLocale = localeId;

  /// Ekor rantai serial. Setiap [speak] menyambung di belakangnya.
  Future<void> _tail = Future<void>.value();

  /// Dinaikkan oleh [stop] dan oleh ucapan `interrupt: true`.
  int _generation = 0;

  bool _initialized = false;

  /// Apakah suara Bahasa Indonesia benar-benar ada di perangkat ini.
  ///
  /// `false` berarti seluruh aplikasi akan terdengar dengan fonetik bahasa
  /// lain, dan itu keadaan yang harus diberitahukan, bukan dibiarkan.
  bool _indonesianAvailable = false;
  bool get indonesianAvailable => _indonesianAvailable;

  /// Kode bahasa Indonesia yang BENAR-BENAR diterima mesin di perangkat ini.
  String _resolvedLocaleId = localeId;

  Future<void> init() async {
    if (_initialized) return;

    // Bahasa diperiksa SEBELUM dipasang, bukan dipasang lalu diharapkan.
    //
    // `setLanguage` pada bahasa yang tidak terpasang tidak melempar apa pun.
    // Mesin diam-diam jatuh ke bahasa bawaan perangkat, TTS tetap bersuara,
    // dan kalimat Bahasa Indonesia dibacakan dengan fonetik Inggris. Untuk
    // pengguna tunanetra yang seluruh antarmukanya adalah suara, itu bukan
    // penurunan kualitas - itu aplikasi yang berhenti bisa dipahami, tanpa
    // satu pun tanda kenapa.
    await _resolveIndonesianVoice();

    await _tts.setSpeechRate(0.5); // sedikit lambat, lebih terdengar saat berjalan
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // speak() baru resolve setelah engine benar-benar selesai bicara. Tanpa
    // ini, serialisasi di bawah tidak ada artinya: semua ucapan akan
    // "selesai" seketika dan saling menimpa di engine.
    await _resolveRateRange();

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

  /// Cari kode bahasa Indonesia yang diterima mesin, lalu pasang.
  ///
  /// Sama seperti di sisi pengenalan suara, kodenya tidak boleh dipatok.
  /// Android memakai kode lama `in` untuk Bahasa Indonesia, warisan ISO 639
  /// sebelum 1989 yang masih dipakai Java sampai hari ini, jadi mesin di satu
  /// perangkat bisa menerima `id-ID` sementara di perangkat lain hanya `in-ID`.
  ///
  /// Kalau tidak satu pun diterima, bahasa dibiarkan pada bawaan perangkat dan
  /// [indonesianAvailable] tetap false. Lapisan di atas yang memutuskan apa
  /// yang dikatakan kepada pengguna; yang penting di sini adalah keadaannya
  /// diketahui, bukan disembunyikan.
  Future<void> _resolveIndonesianVoice() async {
    const candidates = ['id-ID', 'id_ID', 'in-ID', 'in_ID', 'id', 'in'];

    for (final code in candidates) {
      try {
        final available = await _tts.isLanguageAvailable(code);
        if (available != true) continue;

        await _tts.setLanguage(code);
        _resolvedLocaleId = code;
        _engineLocale = code;
        _indonesianAvailable = true;

        // `isLanguageAvailable` true belum tentu berarti datanya sudah
        // terunduh. Android membedakan keduanya, dan bahasa yang "tersedia"
        // tapi belum terpasang tetap dibacakan dengan suara bawaan.
        try {
          final installed = await _tts.isLanguageInstalled(code);
          if (installed != true) {
            debugPrint('[TTS] $code tersedia tapi datanya belum terunduh. '
                'Suaranya bisa jatuh ke bahasa bawaan.');
          }
        } catch (_) {
          // Hanya ada di Android. Bukan alasan menggagalkan apa pun.
        }

        debugPrint('[TTS] bahasa dipakai: $code');
        return;
      } catch (e) {
        debugPrint('[TTS] gagal memeriksa $code: $e');
      }
    }

    _indonesianAvailable = false;
    debugPrint('[TTS] Bahasa Indonesia TIDAK tersedia di perangkat ini. '
        'Seluruh ucapan akan memakai fonetik bahasa bawaan.');
    try {
      debugPrint('[TTS] bahasa yang ada: ${await _tts.getLanguages}');
    } catch (_) {
      // Daftar bahasa cuma untuk diagnosis.
    }
  }

  /// Kalimat yang menjelaskan keadaan suara, atau null kalau semuanya normal.
  ///
  /// Sengaja dikembalikan sebagai teks, bukan diucapkan sendiri: yang tahu
  /// kapan waktunya bicara adalah lapisan mode, bukan mesin suaranya.
  String? get healthWarning => _indonesianAvailable
      ? null
      : 'Suara Bahasa Indonesia belum terpasang di ponsel ini, jadi ucapan '
          'saya mungkin sulit dipahami. Pasang paket suara Bahasa Indonesia '
          'lewat Pengaturan ponsel, bagian Text-to-speech.';

  // ── Penjaga jalur pintas ────────────────────────────────────────────────
  //
  // Kelas ini adalah MESIN suara, bukan pengatur giliran. Yang mengatur tier,
  // dedup, jeda bernapas, masa tenang, dan gerbang mikrofon adalah `TtsQueue`.
  // Memanggil [speak] atau [stop] langsung berarti melewati semuanya.
  //
  // Itu bukan larangan mutlak: layar splash, onboarding, dan izin bicara saat
  // belum ada satu pun mode yang bernarasi, dan memaksa mereka lewat antrean
  // tidak memberi apa-apa. Yang berbahaya adalah jalur pintas yang berjalan
  // SAAT antrean sedang bekerja - itu berarti dua sumber suara yang tidak
  // saling tahu, dan pengguna tunanetra yang tidak punya cara memilih.
  //
  // Kasus nyatanya pernah ada di `_handleDescribeScene`: deskripsi belasan
  // detik langsung ke mesin, narasi mode di antrean kedaluwarsa lalu dibuang
  // tanpa satu pun baris log. Tidak ada yang menyadarinya sampai jalurnya
  // ditelusuri satu per satu.
  //
  // Karena itu penjaganya bukan pencegah, melainkan pelapor: kalau ada jalur
  // pintas yang berjalan saat antrean aktif, dia menuliskannya ke log.

  /// Diisi [TtsQueue] saat pertama kali dipakai. Mengembalikan penjelasan
  /// singkat kalau antrean sedang bekerja, atau null kalau sedang senggang.
  static String? Function()? debugQueueBusyReason;

  void _laporJalurPintas(String metode) {
    if (!kDebugMode) return;
    final alasan = debugQueueBusyReason?.call();
    if (alasan == null) return;
    debugPrint('[TTS] JALUR PINTAS: $metode dipanggil langsung saat antrean '
        '$alasan. Ucapan ini tidak lewat arbitrase TtsQueue.');
  }

  /// Ucapkan [message]. Selalu tersampaikan kecuali dibatalkan [stop] atau
  /// oleh ucapan lain yang meminta [interrupt].
  ///
  /// [english] memakai locale `en-US` (hasil Moondream2), lalu mengembalikan
  /// engine ke `id-ID` - pengembaliannya di blok `finally`, jadi kegagalan di
  /// tengah tidak meninggalkan aplikasi berbicara Inggris selamanya.
  Future<void> speak(
    String message, {
    bool interrupt = false,
    bool english = false,
  }) {
    final text = message.trim();
    if (text.isEmpty) return Future<void>.value();
    _laporJalurPintas('speak');

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
    // Kembali ke kode yang terbukti diterima mesin, bukan ke konstanta.
    // Perangkat yang hanya menerima `in-ID` akan gagal diam-diam kalau di sini
    // dipaksa `id-ID`, dan sisa sesi terdengar dalam bahasa Inggris.
    final target = english ? localeEn : _resolvedLocaleId;

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
      if (english && _engineLocale != _resolvedLocaleId) {
        try {
          await _tts.setLanguage(_resolvedLocaleId);
          _engineLocale = _resolvedLocaleId;
        } catch (e) {
          debugPrint('[TTS] gagal kembali ke $_resolvedLocaleId: $e');
        }
      }
    }
  }

  /// Rentang kecepatan bicara yang benar-benar diterima mesin di perangkat ini.
  ///
  /// Ditanyakan, bukan dipatok. Rentangnya berbeda antar platform dan antar
  /// mesin TTS: nilai di luar rentang diam-diam dijepit atau diabaikan, jadi
  /// slider di Pengaturan bisa bergerak penuh sementara suaranya tidak berubah
  /// sama sekali - dan pengguna menyimpulkan pengaturannya rusak.
  double _rateMin = 0.1;
  double _rateMax = 1.0;

  Future<void> _resolveRateRange() async {
    try {
      final range = await _tts.getSpeechRateValidRange;
      _rateMin = range.min;
      _rateMax = range.max;
      debugPrint('[TTS] rentang kecepatan: $_rateMin..$_rateMax '
          '(normal ${range.normal})');
    } catch (e) {
      debugPrint('[TTS] rentang kecepatan tidak terbaca, pakai 0,1..1,0: $e');
    }
  }

  /// Kecepatan bicara - Pengaturan "Kecepatan bicara".
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(_rateMin, _rateMax));
  }

  /// Hentikan yang sedang bicara DAN batalkan yang masih mengantre.
  Future<void> stop() async {
    _laporJalurPintas('stop');
    _generation++;
    _tail = Future<void>.value();
    _speaking = false;
    await _tts.stop();
  }
}
