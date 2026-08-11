import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../mock/mock_find_object.dart';

/// State machine Mode Cari Objek — bagian 12 IMPLEMENTASI.md (CO-01..CO-13,
/// CO-18, CO-19). Server pencarian objek belum ada, jadi seluruh "penemuan"
/// disimulasikan lewat Timer begitu target ditetapkan (dari hasil STT yang
/// dilakukan di layer screen, sama seperti VoiceProvider).
///
/// CO-14 (offline), CO-15 (izin kamera), CO-16 (senyap), CO-17 (font scale
/// 200%) sengaja TIDAK dimodelkan di sini — itu murni keputusan lapisan UI
/// (screen membaca GlobalConditionsProvider / izin sistem / MediaQuery
/// langsung), sama seperti pola MoneyProvider.
enum FindObjectState {
  idle, // CO-01
  listening, // CO-02
  unclear, // CO-03
  targetActive, // CO-04
  scanning, // CO-05
  found, // CO-06 / CO-07 (lihat matchCount)
  lostFromView, // CO-09
  notFoundInFrame, // CO-10
  longNotFound, // CO-11
  unknownObject, // CO-12
  serverError, // CO-18
  tooDark, // CO-19
}

class FindObjectProvider extends ChangeNotifier {
  final _rand = Random();

  FindObjectState _state = FindObjectState.idle;
  FindObjectState get state => _state;

  String? _target;
  String? get target => _target;

  int _matchCount = 1; // CO-07: >1 berarti "lebih dari satu cocok"
  int get matchCount => _matchCount;

  String _direction = 'depan';
  String get direction => _direction;

  double _distanceMeter = 3.0;
  double get distanceMeter => _distanceMeter;

  String? _lastKnownPosition; // CO-09
  String? get lastKnownPosition => _lastKnownPosition;

  int _scanMessageIndex = 0;
  String get scanMessage => FindObjectMockData.scanMessages[_scanMessageIndex % FindObjectMockData.scanMessages.length];

  int _notFoundMessageIndex = 0;
  String get notFoundMessage =>
      FindObjectMockData.notFoundMessages[_notFoundMessageIndex % FindObjectMockData.notFoundMessages.length];

  /// Callback keluar — screen yang mengubahnya jadi suara/getar sungguhan,
  /// pola sama dengan MoneyProvider.onSpeak.
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(String direction)? onDirectionHaptic; // CO-16: getar arah saat senyap

  Timer? _stepTimer;
  Timer? _messageRotateTimer;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void _set(FindObjectState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  // -------------------------------------------------------------- CO-02/03

  void startListening() {
    _stepTimer?.cancel();
    _messageRotateTimer?.cancel();
    _set(FindObjectState.listening);
  }

  /// Dipanggil screen setelah STT selesai. [heardText] kosong/ambigu → CO-03.
  void submitHeardText(String heardText, {String? parsedTarget}) {
    final t = (parsedTarget ?? heardText).trim();
    if (t.isEmpty) {
      _set(FindObjectState.unclear);
      _speak('Cari apa?', tier: SpeechTier.info);
      _after(2500, () => _set(FindObjectState.idle));
      return;
    }
    setTarget(t);
  }

  // ------------------------------------------------------------------ CO-04

  /// Menetapkan target baru — juga dipakai untuk CO-13 "ganti target" saat
  /// target sudah aktif (tidak perlu kembali ke CO-01 dulu).
  void setTarget(String newTarget) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _matchCount = 1;
    _lastKnownPosition = null;
    _set(FindObjectState.targetActive);

    if (isChange) {
      _speak('Ganti, sekarang mencari $newTarget.', tier: SpeechTier.info);
    } else if (!FindObjectMockData.isKnown(newTarget)) {
      // CO-12 — objek tak dikenali, sebut yang dikenal sebagai gantinya.
      final fallback = FindObjectMockData.randomFallback(_rand);
      _speak('Saya belum kenal "$newTarget". Saya bisa mencari $fallback, misalnya.', tier: SpeechTier.warning);
      _set(FindObjectState.unknownObject);
      _after(2600, () => _set(FindObjectState.idle));
      return;
    } else {
      _speak('Mencari $newTarget.', tier: SpeechTier.info);
    }

    _after(500, _beginScan);
  }

  // -------------------------------------------------------------- CO-05..11

  void _beginScan() {
    _scanMessageIndex = 0;
    _set(FindObjectState.scanning);
    _messageRotateTimer?.cancel();
    _messageRotateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _scanMessageIndex++;
      notifyListeners();
    });
    _after(3000 + _rand.nextInt(3000), _resolveScan);
  }

  void _resolveScan() {
    _messageRotateTimer?.cancel();
    final r = _rand.nextDouble();
    if (r < 0.10) {
      _set(FindObjectState.serverError);
      _speak('Bukan karena kameramu. Coba lagi sebentar lagi.', tier: SpeechTier.critical);
      _after(2500, _beginScan);
    } else if (r < 0.18) {
      _set(FindObjectState.tooDark);
      _speak('Terlalu gelap. Nyalakan lampu.', tier: SpeechTier.warning);
      _after(2500, _beginScan);
    } else if (r < 0.55) {
      _enterNotFound();
    } else {
      _enterFound();
    }
  }

  void _enterNotFound() {
    _notFoundMessageIndex = 0;
    _set(FindObjectState.notFoundInFrame);
    _messageRotateTimer?.cancel();
    _messageRotateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _notFoundMessageIndex++;
      notifyListeners();
      if (_notFoundMessageIndex >= 2) {
        _messageRotateTimer?.cancel();
        _set(FindObjectState.longNotFound);
        _speak('Belum ketemu di ruangan ini. Pindah ruangan, atau ganti target?', tier: SpeechTier.warning);
      }
    });
    _after(7000, _beginScan);
  }

  void _enterFound() {
    _matchCount = _rand.nextDouble() < 0.25 ? 2 + _rand.nextInt(2) : 1;
    _direction = ['kiri', 'depan', 'kanan'][_rand.nextInt(3)];
    _distanceMeter = 2.0 + _rand.nextDouble() * 3;
    _set(FindObjectState.found);

    final distText = _distanceMeter < 1
        ? 'kurang dari satu meter'
        : '${_distanceMeter.toStringAsFixed(1)} meter';
    if (_matchCount > 1) {
      _speak('Ada $_matchCount $_target. Yang terdekat di $_direction, sekitar $distText.', tier: SpeechTier.info);
    } else {
      _speak('$_target ditemukan di $_direction, sekitar $distText.', tier: SpeechTier.info);
    }
    onDirectionHaptic?.call(_direction);

    _after(1800, _narrowDistance);
  }

  /// CO-08 — panduan bertahap "dua meter" → "satu meter" → "setengah meter".
  void _narrowDistance() {
    if (_state != FindObjectState.found) return;
    if (_distanceMeter > 0.6) {
      _distanceMeter = (_distanceMeter - (0.7 + _rand.nextDouble() * 0.8)).clamp(0.4, 10);
      notifyListeners();
      final distText = _distanceMeter < 1 ? 'setengah meter, ulurkan tangan' : '${_distanceMeter.toStringAsFixed(0)} meter';
      _speak(distText, tier: SpeechTier.info);
      _after(2200, _narrowDistance);
      return;
    }

    // Sesekali objek "hilang dari pandangan" (CO-09) sebelum akhirnya diam di CO-06.
    if (_rand.nextDouble() < 0.2) {
      _lastKnownPosition = '$_direction, sekitar satu meter';
      _set(FindObjectState.lostFromView);
      _speak('$_target sempat hilang dari pandangan, terakhir di $_lastKnownPosition.', tier: SpeechTier.warning);
      _after(2500, _enterFound);
    }
  }

  void reset() {
    _stepTimer?.cancel();
    _messageRotateTimer?.cancel();
    _target = null;
    _set(FindObjectState.idle);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _messageRotateTimer?.cancel();
    super.dispose();
  }
}
