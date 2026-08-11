import 'package:flutter/foundation.dart';
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
        AppMode.ocr        => true,  // OCR teks panjang butuh server
        AppMode.navigasi   => true,  // segmentasi jalur, tapi rintangan on-device tetap jalan
        AppMode.voice      => true,  // LLM, ada fallback lokal
        AppMode.findObject => true,  // butuh server sepenuhnya
      };

  /// Mode Navigasi TIDAK PERNAH dinonaktifkan offline — deteksi rintangan
  /// on-device tetap hidup. Hanya Cari Objek yang benar-benar dinonaktifkan.
  bool get disabledWhenOffline => this == AppMode.findObject;
}

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.tuntun;
  AppMode get mode => _mode;

  /// Verbositas panduan menurun setelah 3 kali pemakaian pertama per mode.
  final Map<AppMode, int> _visitCount = {};
  int visitCountFor(AppMode m) => _visitCount[m] ?? 0;

  /// Umumkan masuk mode TANPA berpindah — dipakai mode default (Deteksi
  /// Objek) yang aktif sejak boot tanpa lewat [setMode], supaya DO-29
  /// "verbositas lengkap 3 pemakaian pertama" tetap berlaku untuknya juga.
  Future<void> announceEntry(AppMode mode) async {
    final count = (_visitCount[mode] ?? 0) + 1;
    _visitCount[mode] = count;
    final announcement = count <= 3 ? '${mode.label} aktif. ${mode.shortIntro}' : '${mode.label} aktif.';
    await TTSService.instance.speak(announcement);
  }

  /// NV-18 — satu-satunya konfirmasi wajib di seluruh app: keluar dari Mode
  /// Navigasi saat pengguna terdeteksi sedang berjalan. `navigasi_screen.dart`
  /// memasang hook ini selama aktif; kalau terpasang dan mengembalikan
  /// false, perpindahan mode dibatalkan. Ini titik tunggal yang dilewati
  /// SEMUA jalur ganti mode (ModePickerSheet maupun perintah suara).
  Future<bool> Function(AppMode from, AppMode to)? confirmLeave;

  Future<void> setMode(AppMode mode) async {
    if (_mode == mode) return;
    if (confirmLeave != null) {
      final ok = await confirmLeave!(_mode, mode);
      if (!ok) return;
    }
    _mode = mode;
    notifyListeners();

    final count = (_visitCount[mode] ?? 0) + 1;
    _visitCount[mode] = count;

    // Tiga kali pertama: panduan lengkap. Setelah itu: ringkas.
    final announcement = count <= 3 ? '${mode.label} aktif. ${mode.shortIntro}' : '${mode.label} aktif.';
    await TTSService.instance.speak(announcement);
  }
}
