import 'package:flutter/foundation.dart';
import '../core/speech/tts_queue.dart';
import '../providers/settings_provider.dart' show Verbosity;

/// Enam mode sejajar, sesuai kontrak navigasi Vinara: tidak ada beranda,
/// mode mana pun bisa dicapai dalam maksimal dua langkah (suara = 1 langkah,
/// ModePickerSheet = 2 langkah).
enum AppMode { tuntun, money, ocr, navigasi, voice, findObject }

extension AppModeLabel on AppMode {
  String get label => switch (this) {
        AppMode.tuntun     => 'Deteksi Objek',
        AppMode.money      => 'Kenali Uang',
        AppMode.ocr        => 'Baca Teks',
        AppMode.navigasi   => 'Navigasi',
        AppMode.voice      => 'Deskripsi Suasana',
        AppMode.findObject => 'Cari Objek',
      };

  /// Satu kalimat "apa yang bisa dilakukan" - diumumkan saat masuk mode.
  String get shortIntro => switch (this) {
        AppMode.tuntun     => 'Arahkan ponsel ke depan, saya akan menyebut rintangan di jalurmu.',
        AppMode.money      => 'Letakkan uang di dalam bingkai, saya akan menyebut nominalnya.',
        AppMode.ocr        => 'Arahkan ponsel ke tulisan, lalu ambil gambar.',
        // JANGAN menjanjikan tujuan/GPS di sini. Kalimat lama berbunyi
        // "Sebutkan atau ketik tujuanmu, saya akan menuntun jalan." padahal
        // GPS belum ada: pengguna tunanetra menyebutkan tujuan, tidak ada yang
        // terjadi, mencoba lagi, tetap tidak ada. Kalimat pembuka yang
        // menjanjikan sesuatu yang tidak ada adalah cara tercepat kehilangan
        // kepercayaan pengguna terhadap seluruh aplikasi.
        AppMode.navigasi   => 'Saya akan menyebut jalur mana yang lebih aman: kiri, tengah, atau kanan.',
        AppMode.voice      => 'Ketuk lalu bicara, tanyakan apa saja tentang sekitarmu.',
        AppMode.findObject => 'Sebutkan barang yang kamu cari, saya akan membantu menemukannya.',
      };

  String get icon => switch (this) {
        AppMode.tuntun     => '👁',
        AppMode.money      => '💵',
        AppMode.ocr        => '📄',
        AppMode.navigasi   => '🧭',
        AppMode.voice      => '🎙️',
        AppMode.findObject => '🔍',
      };

  /// Butuh internet untuk berfungsi penuh. Dipakai ModePickerSheet untuk
  /// menandai state `limited` / `disabled` saat offline.
  bool get needsServer => switch (this) {
        AppMode.tuntun     => false, // SSD MobileNet TFLite, sepenuhnya on-device
        AppMode.money      => false, // MobileNetV2 TFLite, sepenuhnya on-device
        AppMode.ocr        => false, // ML Kit on-device - jalan penuh offline
        // Navigasi TIDAK butuh server sama sekali. Tiga model TFLite berjalan
        // di ponsel: PIDNet-S, YOLO11n custom, dan SSD MobileNet COCO.
        //
        // Nilai ini pernah `true` dengan alasan "server hanya cadangan",
        // padahal cadangan itu sudah dihapus: `navigasi.router` tidak lagi
        // didaftarkan di backend, dan `segmentasiJalur()` sudah dibuang dari
        // ServerService. Yang tersisa cuma akibatnya di layar - lembar Pilih
        // Mode menandai Navigasi "Tanpa internet: sebagian fitur mati" untuk
        // mode yang sebenarnya berjalan penuh tanpa jaringan, lalu pengguna
        // yang percaya berhenti memakainya justru saat ia paling dibutuhkan.
        AppMode.navigasi   => false,
        AppMode.voice      => true,  // butuh server untuk describe; intent parsing lokal, tanpa LLM
        AppMode.findObject => true,  // YOLOE open-vocab hanya ada di server
      };

  /// Mode yang benar-benar mati tanpa internet.
  ///
  /// Mode Navigasi tetap BERJALAN OFFLINE menggunakan model TFLite on-device
  /// (YOLO11n untuk bounding box rintangan & PIDNet-S untuk segmentasi 3-zona).
  bool get disabledWhenOffline => this == AppMode.findObject;

  /// Petunjuk kata kunci perintah suara untuk diumumkan atau ditampilkan di UI
  String get voiceHint => switch (this) {
        AppMode.tuntun     => 'Katakan: "Deteksi objek" atau "Tuntun aku"',
        AppMode.money      => 'Katakan: "Kenali uang" atau "Cek uang"',
        AppMode.ocr        => 'Katakan: "Baca teks" atau "Bacakan"',
        AppMode.navigasi   => 'Katakan: "Navigasi" atau "Jalan mana"',
        AppMode.voice      => 'Katakan: "Deskripsi suasana" atau "Tanya"',
        AppMode.findObject => 'Katakan: "Cari objek" atau "Cari kunci"',
      };
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  /// Mode sebelum perpindahan terakhir - dipakai oleh fitur "kembali"
  /// (perintah suara atau tombol ✕ di VoiceScreen overlay).
  AppMode? _previousMode;
  AppMode? get previousMode => _previousMode;

  /// Verbositas panduan menurun setelah 3 kali pemakaian pertama per mode.
  final Map<AppMode, int> _visitCount = {};
  int visitCountFor(AppMode m) => _visitCount[m] ?? 0;

  /// Kata pembuka yang dititipkan [setMode] untuk diucapkan oleh
  /// [announceEntry] milik layar tujuan - mis. "Baik." dari perintah suara
  /// (AS-17). Dititipkan, bukan diucapkan di sini, supaya konfirmasi tidak
  /// pernah mendahului perpindahan state (bagian 4.1 ALUR-DAN-TOMBOL.md).
  String? _pendingPrefix;

  /// PG-05 - tingkat kecerewetan pengguna. Bekerja **bersama** verbositas
  /// menurun bawaan (tiga pemakaian pertama lebih panjang), bukan
  /// menggantikannya: "ringkas" memotong panduan sejak awal, "detail"
  /// mempertahankannya selamanya.
  Verbosity _verbosity = Verbosity.sedang;
  void applyVerbosity(Verbosity v) => _verbosity = v;

  /// Umumkan masuk mode. Dipanggil dari `initState` layar mode - artinya
  /// pengumuman selalu menyusul mode yang BENAR-BENAR terpasang, tidak pernah
  /// mendahuluinya. Mode default (Deteksi Objek) yang aktif sejak boot tanpa
  /// lewat [setMode] ikut lewat sini juga, supaya DO-29 "verbositas lengkap 3
  /// pemakaian pertama" tetap berlaku untuknya.
  Future<void> announceEntry(AppMode mode) async {
    if (mode != _mode) return; // layar basi (dispose berpapasan) - jangan bicara
    final prefix = _pendingPrefix;
    _pendingPrefix = null;

    final count = (_visitCount[mode] ?? 0) + 1;
    _visitCount[mode] = count;

    // Verbositas menurun bawaan (tiga kali pertama lengkap) digeser oleh
    // pilihan pengguna: "ringkas" tidak pernah membacakan panduan, "detail"
    // selalu membacakannya.
    final withIntro = switch (_verbosity) {
      Verbosity.ringkas => false,
      Verbosity.sedang => count <= 3,
      Verbosity.detail => true,
    };

    final announcement = [
      if (prefix != null) prefix,
      '${mode.label} aktif.',
      if (withIntro) mode.shortIntro,
    ].join(' ');
    // Lewat antrean, tier Warning: pengumuman "di mana saya sekarang" tidak
    // boleh dibuang sebagai Info basi, tapi juga tidak boleh menahan
    // peringatan bahaya yang datang saat mode baru terpasang.
    //
    // Sumbernya ASISTEN, bukan mode. Kalimat inilah jawaban atas perintah
    // "pindah ke navigasi" yang barusan diucapkan pengguna; membungkamnya
    // bersama narasi mode berarti perpindahan mode terjadi tanpa satu pun
    // tanda bahwa perintahnya sampai. Ia juga tetap terdengar saat mode
    // dipilih lewat lembar Pilih Mode, di mana tidak ada gerbang sama sekali.
    await TtsQueue().speak(
      announcement,
      tier: SpeechTier.warning,
      source: SpeechSource.assistant,
    );
  }

  /// NV-18 - satu-satunya konfirmasi wajib di seluruh app: keluar dari Mode
  /// Navigasi saat pengguna terdeteksi sedang berjalan. `navigasi_screen.dart`
  /// memasang hook ini selama aktif; kalau terpasang dan mengembalikan
  /// false, perpindahan mode dibatalkan. Ini titik tunggal yang dilewati
  /// SEMUA jalur ganti mode (ModePickerSheet maupun perintah suara).
  Future<bool> Function(AppMode from, AppMode to)? confirmLeave;

  /// Berpindah mode. Mengembalikan **true hanya kalau mode benar-benar
  /// berubah** - pemanggil wajib memeriksa nilai ini sebelum mengucapkan
  /// konfirmasi apa pun. [spokenPrefix] dititipkan ke pengumuman kedatangan
  /// layar tujuan, bukan diucapkan di sini.
  Future<bool> setMode(AppMode mode, {String? spokenPrefix}) async {
    if (_mode == mode) return false;
    if (confirmLeave != null) {
      final ok = await confirmLeave!(_mode, mode);
      if (!ok) return false;
    }
    _previousMode = _mode; // simpan mode sebelumnya untuk goBack()
    _pendingPrefix = spokenPrefix;
    _mode = mode;
    notifyListeners();
    // Pengumuman kedatangan diucapkan `announceEntry` dari layar tujuan -
    // sesudah layarnya benar-benar terpasang.
    return true;
  }

  /// Kembali ke mode sebelumnya. Dipanggil oleh `VoiceIntent.actionGoBack`
  /// atau tombol ✕ di VoiceScreen overlay. Fallback ke [AppMode.tuntun]
  /// kalau tidak ada riwayat mode sebelumnya.
  Future<bool> goBack({String? spokenPrefix}) async {
    final target = _previousMode ?? AppMode.tuntun;
    return setMode(target, spokenPrefix: spokenPrefix);
  }
}
