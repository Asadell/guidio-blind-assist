/// Terjemahan Inggris → Indonesia on-device untuk caption Moondream2.
///
/// LATAR
/// -----
/// Moondream2 di backend hanya berbahasa Inggris. Sebelum berkas ini ada,
/// mode Deskripsi Sekitar adalah satu-satunya mode di seluruh Vinara yang
/// menjawab dalam bahasa yang tidak bisa diasumsikan dimengerti target
/// penggunanya - tunanetra di pasar dan warung Indonesia - dan aplikasi
/// menambal itu dengan penanda lisan "Dalam bahasa Inggris." sebelum
/// membacakan caption apa adanya.
///
/// Penggantinya yang lama, `core/voice/scene_translator.dart`, adalah kamus
/// kata-per-kata buatan sendiri. Kamus itu dilepas dari jalur produksi karena
/// cakupannya tidak konsisten: satu foto diterjemahkan penuh, foto berikutnya
/// setengah, foto ketiga menyerah - dan pengguna yang mengandalkan telinga
/// tidak punya cara menebak versi mana yang sedang dia dengar.
///
/// ML Kit Translate menyelesaikan justru bagian itu. Ia menerjemahkan kalimat
/// utuh atau tidak sama sekali, bukan sebagian, sehingga jawabannya konsisten
/// dari foto ke foto.
///
/// KENAPA BUKAN LLM
/// ---------------
/// Sama seperti keputusan-keputusan lain di proyek ini: LLM penerjemah lambat
/// (1-3 detik), butuh server, dan bisa berhalusinasi. ML Kit berjalan penuh
/// di perangkat sesudah modelnya terunduh sekali, tidak menyentuh jaringan
/// saat dipakai, dan tidak mengarang isi baru - paling buruk ia menerjemahkan
/// dengan kaku, bukan menambahkan benda yang tidak ada di foto. Untuk pengguna
/// yang TIDAK BISA memverifikasi jawaban dengan mata, perbedaan itu bukan soal
/// kualitas bahasa, tapi soal keselamatan.
///
/// KALAU TIDAK SIAP, IA MENYERAH - TAPI TIDAK UNTUK SELAMANYA
/// ----------------------------------------------------------
/// [toIndonesian] mengembalikan null - bukan melempar, bukan menunggu tanpa
/// batas - kalau modelnya belum terunduh, unduhannya gagal, atau terjemahannya
/// kosong.
///
/// Yang berubah dari versi sebelumnya adalah APA ARTI null itu bagi pemanggil.
/// Dulu `VoiceProvider` membacakan caption Inggrisnya dengan penanda "Dalam
/// bahasa Inggris."; sekarang mode Deskripsi Sekitar TIDAK PERNAH membacakan
/// Bahasa Inggris sama sekali, dan null berarti pengguna diberi tahu bahwa
/// penerjemahnya belum siap. Kalimat Inggris yang tidak dimengerti bukan
/// informasi yang lebih sedikit, melainkan nol informasi yang terdengar
/// seperti jawaban.
///
/// Konsekuensinya: kesiapan service ini sekarang menentukan apakah fiturnya
/// menghasilkan sesuatu, jadi kegagalan persiapan TIDAK BOLEH permanen dalam
/// satu sesi. Lihat [_retryCooldown].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  /// Waktu tunggu terjemahan satu kalimat. Inferensinya sendiri puluhan
  /// milidetik; batas ini murni jaring pengaman kalau platform channel
  /// menggantung. Deskripsi yang telat 6 detik sudah tidak berguna - lebih
  /// baik jatuh ke bahasa Inggris tepat waktu.
  static const Duration _translateTimeout = Duration(seconds: 6);

  /// Batas menunggu unduhan model untuk permintaan LATAR, mis. `toEnglish`
  /// yang dimulai saat target Cari Objek ditetapkan. Bukan batas unduhannya
  /// sendiri: unduhan tetap berjalan di latar dan permintaan BERIKUTNYA akan
  /// menikmatinya. Ini cuma batas kesabaran satu permintaan yang kebetulan
  /// datang duluan.
  static const Duration _readyWaitTimeout = Duration(seconds: 8);

  /// Batas menunggu untuk permintaan yang DIMINTA pengguna, yaitu deskripsi
  /// suasana.
  ///
  /// Jauh lebih panjang dari [_readyWaitTimeout], dan itu disengaja. Pengguna
  /// menekan tombol lalu sudah menunggu satu perjalanan jaringan ke Moondream2
  /// sebelum sampai di sini; menyerah pada detik kedelapan berarti membuang
  /// seluruh penantian itu demi jawaban yang tidak dia mengerti. Menunggu
  /// lebih lama dan menjawab dalam Bahasa Indonesia adalah pertukaran yang
  /// benar di jalur ini.
  static const Duration _onDemandWaitTimeout = Duration(seconds: 25);

  /// Jeda sebelum persiapan yang gagal boleh dicoba lagi.
  ///
  /// Ini yang menggantikan penanda gagal permanen. Sebab tersering kegagalan
  /// adalah tidak ada jaringan pada detik aplikasi dibuka, dan itu keadaan
  /// yang berubah beberapa saat kemudian. Menguncinya untuk seluruh sesi
  /// berarti satu kegagalan sekejap di pembukaan membuat mode Deskripsi
  /// Sekitar berbahasa Inggris sampai aplikasinya dimatikan, tanpa satu pun
  /// cara bagi pengguna untuk memulihkannya.
  ///
  /// Jedanya tetap ada supaya kegagalan yang benar-benar menetap (perangkat
  /// tanpa Play Services) tidak membuat tiap permintaan menunggu unduhan yang
  /// pasti gagal.
  static const Duration _retryCooldown = Duration(seconds: 15);

  final OnDeviceTranslatorModelManager _models =
      OnDeviceTranslatorModelManager();

  /// Dua penerjemah, dua arah, TAPI model bahasanya sama.
  ///
  /// ML Kit menyimpan model per BAHASA, bukan per pasangan arah. Jadi begitu
  /// `en` dan `id` terunduh untuk caption Moondream2, arah sebaliknya -
  /// nama barang Indonesia jadi prompt Inggris untuk YOLOE - tidak menambah
  /// satu byte pun unduhan. Itu alasan keduanya duduk di service yang sama
  /// alih-alih dipisah per fitur.
  OnDeviceTranslator? _enToId;
  OnDeviceTranslator? _idToEn;

  /// Unduhan/persiapan yang sedang berjalan. Dipegang supaya dua pemanggil
  /// bersamaan ikut menunggu SATU unduhan, bukan memulai dua.
  Future<bool>? _preparing;

  bool _ready = false;

  /// Kapan persiapan terakhir gagal. Null berarti belum pernah gagal, atau
  /// sudah berhasil sesudahnya. Lihat [_retryCooldown].
  DateTime? _failedAt;

  /// Model kedua bahasa sudah ada di perangkat dan penerjemah siap dipakai.
  bool get ready => _ready;

  /// Sedang mengunduh model. Untuk diagnostik / indikator, bukan untuk
  /// memblokir apa pun.
  bool get preparing => _preparing != null;

  /// Percobaan persiapan terakhir gagal dan jeda coba-ulangnya belum lewat.
  bool get lastAttemptFailed => _failedAt != null;

  /// Boleh mencoba menyiapkan lagi: belum pernah gagal, atau kegagalannya
  /// sudah cukup lama.
  bool get _retryAllowed {
    final failed = _failedAt;
    if (failed == null) return true;
    return DateTime.now().difference(failed) >= _retryCooldown;
  }

  String get _en => TranslateLanguage.english.bcpCode;
  String get _id => TranslateLanguage.indonesian.bcpCode;

  /// Unduh model kedua bahasa kalau belum ada, lalu siapkan penerjemah.
  ///
  /// Dipanggil di latar saat aplikasi start. TIDAK untuk di-`await` di jalur
  /// yang menahan UI: unduhan pertama sekitar 30 MB per bahasa.
  ///
  /// [wifiOnly] sengaja default `false`, berlawanan dengan default ML Kit.
  /// Default ML Kit (`isWifiRequired: true`) berarti unduhan diam-diam tidak
  /// pernah terjadi pada pengguna yang hanya punya data seluler - dan mereka
  /// justru mayoritas target aplikasi ini. Gagal diam adalah mode kegagalan
  /// paling buruk di sini: fiturnya tampak menyala tapi selamanya menjawab
  /// dalam bahasa Inggris, tanpa satu pun petunjuk kenapa.
  Future<bool> prewarm({bool wifiOnly = false}) {
    if (_ready) return Future.value(true);
    return _preparing ??= _prepare(wifiOnly: wifiOnly).whenComplete(() {
      _preparing = null;
    });
  }

  Future<bool> _prepare({required bool wifiOnly}) async {
    try {
      for (final code in [_en, _id]) {
        if (await _models.isModelDownloaded(code)) continue;
        debugPrint('[Translation] mengunduh model "$code"...');
        final ok = await _models.downloadModel(code, isWifiRequired: wifiOnly);
        if (!ok) {
          debugPrint('[Translation] unduhan model "$code" gagal.');
          _failedAt = DateTime.now();
          return false;
        }
      }

      _enToId ??= OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.indonesian,
      );
      _idToEn ??= OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.indonesian,
        targetLanguage: TranslateLanguage.english,
      );
      _ready = true;
      _failedAt = null;
      debugPrint('[Translation] siap (en → id, on-device).');
      return true;
    } catch (e) {
      debugPrint('[Translation] persiapan gagal: $e');
      _failedAt = DateTime.now();
      return false;
    }
  }

  /// Terjemahkan satu kalimat Inggris ke Indonesia.
  ///
  /// Mengembalikan null kalau tidak ada hasil yang layak diucapkan - model
  /// belum siap, unduhan gagal, atau terjemahannya kosong. Pemanggil WAJIB
  /// menyiapkan jalur mundur ke teks Inggrisnya; null di sini bukan kesalahan,
  /// melainkan jawaban jujur bahwa terjemahan tidak tersedia sekarang.
  Future<String?> toIndonesian(String english) async {
    return _translate(
      english,
      () => _enToId,
      rejectEcho: true,
      readyWait: _onDemandWaitTimeout,
    );
  }

  /// Terjemahkan nama barang Bahasa Indonesia ke Inggris - dipakai Mode Cari
  /// Objek untuk menyusun prompt teks YOLOE ("tas merah" → "red bag").
  ///
  /// YOLOE open-vocabulary menerima prompt teks bebas, tapi encoder teksnya
  /// (MobileCLIP) dilatih pada Bahasa Inggris. Mengirim "termos" apa adanya
  /// bukan menghasilkan pencarian yang buruk, melainkan pencarian yang
  /// SALAH ARAH - dan pengguna cuma mendengar "tidak ketemu", tanpa satu pun
  /// petunjuk bahwa yang gagal adalah promptnya, bukan barangnya.
  ///
  /// Sama seperti [toIndonesian], null berarti menyerah. Pemanggil kembali ke
  /// kamus manual di backend, yang tetap jadi sumber utama untuk nama barang
  /// sehari-hari.
  ///
  /// [rejectEcho] sengaja `false` di sini, berbeda dengan [toIndonesian].
  /// Banyak nama barang memang sama di kedua bahasa - "laptop", "sofa",
  /// "helm" - dan memulangkan null untuk itu berarti menolak terjemahan yang
  /// justru sudah benar.
  Future<String?> toEnglish(String indonesian) {
    return _translate(
      indonesian,
      () => _idToEn,
      rejectEcho: false,
      readyWait: _readyWaitTimeout,
    );
  }

  Future<String?> _translate(
    String input,
    OnDeviceTranslator? Function() pick, {
    required bool rejectEcho,
    required Duration readyWait,
  }) async {
    final source = input.trim();
    if (source.isEmpty) return null;

    if (!_ready) {
      var inFlight = _preparing;
      if (inFlight == null) {
        // Kegagalan yang masih hangat: menunggu tidak akan mengubah apa pun,
        // dan menahan pemanggil di sini berarti tiap permintaan membayar
        // ulang unduhan yang baru saja gagal. Menyerah cepat supaya jalur
        // mundurnya tetap tepat waktu.
        if (!_retryAllowed) return null;
        // Belum pernah disiapkan, atau kegagalannya sudah cukup lama untuk
        // dicoba lagi. Dimulai di sini, bukan dilewatkan: yang paling sering
        // terjadi adalah aplikasi dibuka tanpa jaringan lalu jaringannya
        // menyala beberapa saat kemudian.
        inFlight = prewarm();
      }
      final okay = await inFlight.timeout(readyWait, onTimeout: () => false);
      if (!okay || !_ready) return null;
    }

    final translator = pick();
    if (translator == null) return null;

    try {
      final result = await translator
          .translateText(source)
          .timeout(_translateTimeout);
      final trimmed = result.trim();
      if (trimmed.isEmpty) return null;

      // ML Kit kadang memulangkan kalimat sumbernya apa adanya ketika ia
      // tidak menemukan apa pun untuk diterjemahkan. Untuk caption suasana
      // itu bukan terjemahan: membacakannya dengan locale id-ID membuat TTS
      // mengeja kalimat Inggris dengan fonetik Indonesia, lebih sulit
      // dipahami daripada kalau sejak awal dibacakan sebagai bahasa Inggris.
      //
      // Untuk nama barang justru sebaliknya - lihat catatan di [toEnglish].
      if (rejectEcho && trimmed.toLowerCase() == source.toLowerCase()) {
        return null;
      }

      return trimmed;
    } catch (e) {
      debugPrint('[Translation] translateText gagal: $e');
      return null;
    }
  }

  /// Kembalikan ke keadaan awal. HANYA untuk test: singleton ini menyimpan
  /// hasil persiapan antar pemanggilan, dan tanpa reset satu kasus uji
  /// mewarisi kesiapan (atau kegagalan) kasus sebelumnya.
  @visibleForTesting
  void resetForTest() {
    _enToId = null;
    _idToEn = null;
    _preparing = null;
    _ready = false;
    _failedAt = null;
  }

  /// Majukan jeda coba-ulang seolah kegagalannya sudah lama. HANYA untuk test:
  /// tanpa ini, menguji bahwa kegagalan TIDAK permanen berarti membuat suite
  /// menunggu [_retryCooldown] dalam waktu nyata.
  @visibleForTesting
  void expireRetryCooldownForTest() {
    if (_failedAt != null) {
      _failedAt = DateTime.now().subtract(_retryCooldown * 2);
    }
  }

  /// Lepaskan penerjemah. Model yang sudah terunduh TIDAK ikut dihapus -
  /// itu milik perangkat dan dipakai lagi di sesi berikutnya.
  Future<void> dispose() async {
    await _enToId?.close();
    await _idToEn?.close();
    _enToId = null;
    _idToEn = null;
    _ready = false;
  }
}
