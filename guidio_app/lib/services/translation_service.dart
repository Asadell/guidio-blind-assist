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
/// KALAU TIDAK SIAP, IA MENYERAH
/// -----------------------------
/// [toIndonesian] mengembalikan null - bukan melempar, bukan menunggu tanpa
/// batas - kalau modelnya belum terunduh, unduhannya gagal, atau terjemahannya
/// kosong. Pemanggil lalu kembali ke jalur lama: penanda "Dalam bahasa
/// Inggris." plus caption aslinya. Deskripsi Inggris yang benar lebih berguna
/// daripada keheningan.
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

  /// Batas menunggu unduhan model saat permintaan datang di tengah [prewarm].
  /// Bukan batas unduhannya sendiri: unduhan tetap berjalan di latar dan
  /// permintaan BERIKUTNYA akan menikmatinya. Ini cuma batas kesabaran satu
  /// permintaan yang kebetulan datang duluan.
  static const Duration _readyWaitTimeout = Duration(seconds: 8);

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

  /// Persiapan yang sudah pernah gagal. Tidak permanen: [prewarm] boleh
  /// mencoba lagi, karena sebab tersering kegagalannya sementara - tidak ada
  /// jaringan saat aplikasi dibuka pertama kali.
  bool _lastAttemptFailed = false;

  /// Model kedua bahasa sudah ada di perangkat dan penerjemah siap dipakai.
  bool get ready => _ready;

  /// Sedang mengunduh model. Untuk diagnostik / indikator, bukan untuk
  /// memblokir apa pun.
  bool get preparing => _preparing != null;

  /// Percobaan persiapan terakhir gagal. Selama ini true, [toIndonesian]
  /// langsung menyerah tanpa menunggu.
  bool get lastAttemptFailed => _lastAttemptFailed;

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
          _lastAttemptFailed = true;
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
      _lastAttemptFailed = false;
      debugPrint('[Translation] siap (en → id, on-device).');
      return true;
    } catch (e) {
      debugPrint('[Translation] persiapan gagal: $e');
      _lastAttemptFailed = true;
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
    return _translate(english, () => _enToId, rejectEcho: true);
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
    return _translate(indonesian, () => _idToEn, rejectEcho: false);
  }

  Future<String?> _translate(
    String input,
    OnDeviceTranslator? Function() pick, {
    required bool rejectEcho,
  }) async {
    final source = input.trim();
    if (source.isEmpty) return null;

    if (!_ready) {
      // Kalau tidak ada persiapan yang berjalan dan yang terakhir gagal,
      // menunggu tidak akan mengubah apa pun. Menyerah sekarang supaya
      // pemanggil tetap dapat jawaban tepat waktu lewat jalur mundurnya.
      final inFlight = _preparing;
      if (inFlight == null) {
        if (_lastAttemptFailed) return null;
        // Belum pernah disiapkan sama sekali (mis. prewarm di main() tidak
        // sempat jalan). Mulai sekarang, tapi tetap dengan batas kesabaran.
        unawaited(prewarm());
      }
      final okay = await (_preparing ?? Future.value(false))
          .timeout(_readyWaitTimeout, onTimeout: () => false);
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
    _lastAttemptFailed = false;
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
