import 'package:flutter/foundation.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/tts_service.dart';

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
        AppMode.voice      => 'Asisten Suara',
        AppMode.findObject => 'Cari Objek',
      };

  /// Satu kalimat "apa yang bisa dilakukan" — diumumkan saat masuk mode.
  String get shortIntro => switch (this) {
        AppMode.tuntun     => 'Arahkan ponsel ke depan, saya akan menyebut rintangan di jalurmu.',
        AppMode.money      => 'Letakkan uang di dalam bingkai, saya akan menyebut nominalnya.',
        AppMode.ocr        => 'Arahkan ponsel ke tulisan, lalu ambil gambar.',
        AppMode.navigasi   => 'Sebutkan atau ketik tujuanmu, saya akan menuntun jalan.',
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
        AppMode.tuntun     => false, // sepenuhnya on-device
        AppMode.money      => false, // model nominal on-device
        AppMode.ocr        => false, // ML Kit on-device — jalan penuh offline
        AppMode.navigasi   => true,  // segmentasi jalur + rintangan, keduanya di server
        AppMode.voice      => true,  // LLM, ada fallback lokal
        AppMode.findObject => true,  // butuh server sepenuhnya
      };

  /// Mode yang benar-benar mati tanpa internet.
  ///
  /// **Berubah dari desain awal.** Dokumen menetapkan Navigasi tidak pernah
  /// dinonaktifkan offline karena deteksi rintangan on-device tetap hidup
  /// (§2 dan §4.4 ALUR-DAN-TOMBOL.md). Sejak deteksi rintangan dan segmentasi
  /// jalur dipindah sepenuhnya ke server, alasan itu tidak berlaku lagi:
  /// offline berarti Navigasi benar-benar tidak bisa melihat apa pun, dan
  /// membiarkannya "terbatas" akan menjanjikan keselamatan yang tidak ada.
  ///
  /// Kalau deteksi rintangan on-device dikembalikan, kembalikan juga Navigasi
  /// ke state `limited` — itu satu baris di sini.
  bool get disabledWhenOffline =>
      this == AppMode.findObject || this == AppMode.navigasi;
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  /// Mode sebelum perpindahan terakhir — dipakai oleh fitur "kembali"
  /// (perintah suara atau tombol ✕ di VoiceScreen overlay).
  AppMode? _previousMode;
  AppMode? get previousMode => _previousMode;

  /// Verbositas panduan menurun setelah 3 kali pemakaian pertama per mode.
  final Map<AppMode, int> _visitCount = {};
  int visitCountFor(AppMode m) => _visitCount[m] ?? 0;

  /// Kata pembuka yang dititipkan [setMode] untuk diucapkan oleh
  /// [announceEntry] milik layar tujuan — mis. "Baik." dari perintah suara
  /// (AS-17). Dititipkan, bukan diucapkan di sini, supaya konfirmasi tidak
  /// pernah mendahului perpindahan state (bagian 4.1 ALUR-DAN-TOMBOL.md).
  String? _pendingPrefix;

  /// PG-05 — tingkat kecerewetan pengguna. Bekerja **bersama** verbositas
  /// menurun bawaan (tiga pemakaian pertama lebih panjang), bukan
  /// menggantikannya: "ringkas" memotong panduan sejak awal, "detail"
  /// mempertahankannya selamanya.
  Verbosity _verbosity = Verbosity.sedang;
  void applyVerbosity(Verbosity v) => _verbosity = v;

  /// Umumkan masuk mode. Dipanggil dari `initState` layar mode — artinya
  /// pengumuman selalu menyusul mode yang BENAR-BENAR terpasang, tidak pernah
  /// mendahuluinya. Mode default (Deteksi Objek) yang aktif sejak boot tanpa
  /// lewat [setMode] ikut lewat sini juga, supaya DO-29 "verbositas lengkap 3
  /// pemakaian pertama" tetap berlaku untuknya.
  Future<void> announceEntry(AppMode mode) async {
    if (mode != _mode) return; // layar basi (dispose berpapasan) — jangan bicara
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
    await TTSService.instance.speak(announcement);
  }

  /// NV-18 — satu-satunya konfirmasi wajib di seluruh app: keluar dari Mode
  /// Navigasi saat pengguna terdeteksi sedang berjalan. `navigasi_screen.dart`
  /// memasang hook ini selama aktif; kalau terpasang dan mengembalikan
  /// false, perpindahan mode dibatalkan. Ini titik tunggal yang dilewati
  /// SEMUA jalur ganti mode (ModePickerSheet maupun perintah suara).
  Future<bool> Function(AppMode from, AppMode to)? confirmLeave;

  /// Berpindah mode. Mengembalikan **true hanya kalau mode benar-benar
  /// berubah** — pemanggil wajib memeriksa nilai ini sebelum mengucapkan
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
    // Pengumuman kedatangan diucapkan `announceEntry` dari layar tujuan —
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
