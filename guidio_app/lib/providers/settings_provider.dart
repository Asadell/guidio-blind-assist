import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/haptic_service.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

enum Verbosity { ringkas, sedang, detail }
enum VibrationMode { active, criticalOnly, off }
enum AppThemeMode { light, dark, highContrast }

/// Delapan pengaturan baku (bagian 13, "Delapan pengaturan"), dipersist ke
/// SharedPreferences. Efek nyata: kecepatan TTS, ambang jarak, dan alamat
/// server langsung memengaruhi service terkait. Tema/ukuran teks diterapkan
/// lewat [AppTheme] + `MediaQuery.textScaler` di level MaterialApp.
class SettingsProvider extends ChangeNotifier {
  static const _kSpeechRate = 'speech_rate';
  static const _kVerbosity = 'verbosity';
  static const _kVibration = 'vibration_mode';
  static const _kDistanceThreshold = 'distance_threshold_m';
  static const _kThemeMode = 'theme_mode';
  static const _kFontScale = 'font_scale';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kServerHost = 'server_host';

  double _speechRate = 0.5;
  Verbosity _verbosity = Verbosity.sedang;
  VibrationMode _vibrationMode = VibrationMode.active;
  double _distanceThresholdM = 2.0;
  AppThemeMode _themeMode = AppThemeMode.light;
  double _fontScale = 1.0; // 1.0..2.0 (200%)
  bool _onboardingDone = false;
  String _serverHost = kDefaultServerHost;

  double get speechRate => _speechRate;
  Verbosity get verbosity => _verbosity;
  VibrationMode get vibrationMode => _vibrationMode;
  double get distanceThresholdM => _distanceThresholdM;
  AppThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get onboardingDone => _onboardingDone;
  String get serverHost => _serverHost;

  /// Apakah alamat server boleh terbaca di layar.
  ///
  /// SENGAJA tidak disimpan ke penyimpanan: tiap kali aplikasi dibuka,
  /// alamatnya kembali tersembunyi. Nilai ini dipakai saat memotret layar,
  /// merekam demo, dan presentasi di depan orang banyak - keadaan di mana
  /// "saya lupa menyembunyikannya lagi" adalah kegagalan yang tidak bisa
  /// ditarik kembali.
  ///
  /// Ditaruh di provider, bukan di `State` masing-masing layar, karena
  /// alamatnya muncul di DUA tempat: baris ringkasan di Pengaturan dan kolom
  /// isian di halaman Alamat Server. Dua saklar terpisah berarti pengguna
  /// menyembunyikannya di satu halaman lalu menemukannya masih terpampang di
  /// halaman satunya.
  bool _serverHostVisible = false;
  bool get serverHostVisible => _serverHostVisible;

  void toggleServerHostVisible() {
    _serverHostVisible = !_serverHostVisible;
    notifyListeners();
  }

  /// Alamat siap tampil: apa adanya kalau boleh terbaca, titik-titik kalau
  /// tidak.
  ///
  /// Panjang penyamarannya TETAP, tidak mengikuti panjang alamat aslinya.
  /// Titik sebanyak jumlah karakter tetap membocorkan apakah yang tersimpan
  /// itu `127.0.0.1:8000` atau `192.168.100.20:8000`.
  String get serverHostMasked => _serverHostVisible ? _serverHost : '••••••••';
  bool get isFontScale200 => _fontScale >= 1.9;
  bool get isLoaded => _prefs != null;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _speechRate = _prefs!.getDouble(_kSpeechRate) ?? 0.5;
    _verbosity = Verbosity.values[_prefs!.getInt(_kVerbosity) ?? Verbosity.sedang.index];
    _vibrationMode = VibrationMode.values[_prefs!.getInt(_kVibration) ?? VibrationMode.active.index];
    _distanceThresholdM = _prefs!.getDouble(_kDistanceThreshold) ?? 2.0;
    _themeMode = AppThemeMode.values[_prefs!.getInt(_kThemeMode) ?? AppThemeMode.light.index];
    _fontScale = _prefs!.getDouble(_kFontScale) ?? 1.0;
    _onboardingDone = _prefs!.getBool(_kOnboardingDone) ?? false;
    _serverHost = _prefs!.getString(_kServerHost) ?? kDefaultServerHost;
    await TTSService.instance.setRate(_speechRate);
    // Tanpa baris ini, pilihan "Getar: Mati" tersimpan ke disk tapi tidak
    // mematikan apa pun.
    HapticService.instance.setMode(_vibrationMode);
    // Alamat tersimpan diterapkan ke service SEBELUM permintaan pertama -
    // tanpa ini, alamat kustom baru berlaku setelah pengguna membukanya lagi.
    ServerService.instance.setHost(_serverHost);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await TTSService.instance.setRate(rate);
    await _prefs?.setDouble(_kSpeechRate, rate);
    notifyListeners();
  }

  Future<void> setVerbosity(Verbosity v) async {
    _verbosity = v;
    await _prefs?.setInt(_kVerbosity, v.index);
    notifyListeners();
  }

  Future<void> setVibrationMode(VibrationMode m) async {
    _vibrationMode = m;
    HapticService.instance.setMode(m);
    await _prefs?.setInt(_kVibration, m.index);
    notifyListeners();
  }

  Future<void> setDistanceThreshold(double meters) async {
    _distanceThresholdM = meters;
    await _prefs?.setDouble(_kDistanceThreshold, meters);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs?.setDouble(_kFontScale, scale);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool done) async {
    _onboardingDone = done;
    await _prefs?.setBool(_kOnboardingDone, done);
    notifyListeners();
  }

  Future<void> setServerHost(String host) async {
    _serverHost = host;
    // Terapkan ke service dulu, baru simpan, baru umumkan. Konfirmasi
    // "tersimpan" yang diucapkan pemanggil karena itu selalu menyusul
    // perubahan yang benar-benar terjadi (bagian 4.1).
    ServerService.instance.setHost(host);
    await _prefs?.setString(_kServerHost, host);
    notifyListeners();
  }
}
