import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../widgets/zone_indicator.dart' show ZoneStatus;

/// NavigationStep — placeholder tanpa GPS/Google Maps (belum diimplementasi,
/// menyusul sprint lain).
class NavigationStep {
  final String instruction;
  final int distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

/// Fase segmentasi jalur — bagian 10 IMPLEMENTASI.md (NV-01..NV-13).
/// Server segmentasi 3-zona belum ada, jadi zona kiri/tengah/kanan
/// disimulasikan lewat Timer sejak kalibrasi selesai. Deteksi rintangan
/// on-device TETAP NYATA — itu dikonsumsi langsung dari DetectionProvider
/// oleh navigasi_screen.dart, bukan dari sini.
enum NavPhase {
  calibrating, // NV-01
  waitingServer, // NV-02
  active, // NV-03..NV-09 (lihat left/center/right + vehicleDanger + pothole)
  serverDown, // NV-11
  serverWeak, // NV-13
  paused, // NV-15
  onDeviceDown, // NV-19 (di-set dari luar oleh screen)
  bothDown, // NV-20
}

class NavigationProvider extends ChangeNotifier {
  final _rand = Random();

  bool _navigating = false;
  String? _destination;
  List<NavigationStep> _steps = [];
  int _currentIdx = 0;
  final Map<String, String> _favorites = {};

  bool get isNavigating => _navigating;
  String? get destination => _destination;
  NavigationStep? get currentStep =>
      (_navigating && _steps.isNotEmpty && _currentIdx < _steps.length) ? _steps[_currentIdx] : null;
  Map<String, String> get favorites => Map.unmodifiable(_favorites);

  NavPhase _phase = NavPhase.calibrating;
  NavPhase get phase => _phase;

  ZoneStatus _left = ZoneStatus.unknown;
  ZoneStatus _center = ZoneStatus.unknown;
  ZoneStatus _right = ZoneStatus.unknown;
  ZoneStatus get left => _left;
  ZoneStatus get center => _center;
  ZoneStatus get right => _right;

  bool _pothole = false;
  bool get pothole => _pothole;
  double _potholeSteps = 3;
  double get potholeSteps => _potholeSteps;

  bool _onDeviceOk = true;
  bool get onDeviceOk => _onDeviceOk;

  /// Dipanggil screen berdasarkan status nyata DetectionProvider — kalau
  /// mati, kombinasikan dengan [_phase] server untuk NV-19/NV-20.
  void reportOnDeviceStatus(bool ok) {
    if (_onDeviceOk == ok) return;
    _onDeviceOk = ok;
    _recomputeCombinedPhase();
  }

  void _recomputeCombinedPhase() {
    final serverOk = _phase != NavPhase.serverDown && _phase != NavPhase.bothDown && _phase != NavPhase.onDeviceDown;
    if (!_onDeviceOk && !serverOk) {
      _phase = NavPhase.bothDown;
      _speak('Berhenti jalan dulu. Deteksi rintangan dan jalur sama-sama tidak bisa dibaca sekarang.', tier: SpeechTier.critical);
    } else if (!_onDeviceOk) {
      _phase = NavPhase.onDeviceDown;
      _speak('Peringatan rintangan sempat tidak tersedia. Arahan jalur tetap ada.', tier: SpeechTier.warning);
    } else if (_phase == NavPhase.onDeviceDown || _phase == NavPhase.bothDown) {
      _phase = NavPhase.active;
    }
    notifyListeners();
  }

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 — mengambil alih layar

  Timer? _zoneTimer;
  Timer? _serverFlakyTimer;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void startCalibration() {
    _phase = NavPhase.calibrating;
    notifyListeners();
  }

  /// NV-01 selesai → NV-02 menunggu server → NV-03 jalur aman.
  void finishCalibration() {
    _phase = NavPhase.waitingServer;
    notifyListeners();
    Timer(const Duration(milliseconds: 1200), () {
      _phase = NavPhase.active;
      _left = _center = _right = ZoneStatus.safe;
      notifyListeners();
      _startZoneSimulation();
    });
  }

  void _startZoneSimulation() {
    _zoneTimer?.cancel();
    _zoneTimer = Timer.periodic(const Duration(seconds: 4), (_) => _stepZones());
    _serverFlakyTimer?.cancel();
    _serverFlakyTimer = Timer.periodic(const Duration(seconds: 20), (_) => _maybeServerHiccup());
  }

  void _stepZones() {
    if (_phase != NavPhase.active) return;
    final r = _rand.nextDouble();
    _pothole = false;

    if (r < 0.55) {
      _left = _center = _right = ZoneStatus.safe;
    } else if (r < 0.72) {
      // Satu zona bermasalah (NV-04).
      final zones = [ZoneStatus.safe, ZoneStatus.safe, ZoneStatus.safe];
      final i = _rand.nextInt(3);
      zones[i] = ZoneStatus.caution;
      _left = zones[0]; _center = zones[1]; _right = zones[2];
      _speak('Geser sedikit, ${_zoneLabel(i)} kurang rata.', tier: SpeechTier.warning);
    } else if (r < 0.85) {
      // Dua zona bermasalah (NV-05) — sisakan satu sisi aman.
      final safeIdx = _rand.nextInt(3);
      final zones = List.generate(3, (i) => i == safeIdx ? ZoneStatus.safe : ZoneStatus.caution);
      _left = zones[0]; _center = zones[1]; _right = zones[2];
      _speak('Jalur sempit, tetap di ${_zoneLabel(safeIdx)}.', tier: SpeechTier.warning);
    } else if (r < 0.92) {
      // NV-06 — bahaya jalur kendaraan, zona tengah merah, mengambil alih.
      _left = ZoneStatus.caution; _center = ZoneStatus.danger; _right = ZoneStatus.caution;
      onTakeover?.call();
      _speak('Berhenti! Jalur kendaraan di depan.', tier: SpeechTier.critical);
    } else if (r < 0.96) {
      // NV-07 — semua zona bahaya, tidak ada jalur aman.
      _left = _center = _right = ZoneStatus.danger;
      _speak('Berhenti dulu. Tidak ada jalur aman di sekitar sini.', tier: SpeechTier.critical);
    } else {
      // NV-09 — lubang / permukaan rusak.
      _pothole = true;
      _potholeSteps = 2 + _rand.nextInt(3).toDouble();
      _left = _center = _right = ZoneStatus.safe;
      _speak('Ada lubang, sekitar ${_potholeSteps.toStringAsFixed(0)} langkah di depan.', tier: SpeechTier.warning);
    }
    notifyListeners();
  }

  String _zoneLabel(int i) => switch (i) { 0 => 'kiri', 1 => 'tengah', _ => 'kanan' };

  void _maybeServerHiccup() {
    if (_phase != NavPhase.active && _phase != NavPhase.serverWeak) return;
    final r = _rand.nextDouble();
    if (r < 0.12) {
      _phase = NavPhase.serverDown;
      _zoneTimer?.cancel();
      _left = _center = _right = ZoneStatus.unknown;
      _speak('Jalur tidak terbaca. Mode terbatas: hanya rintangan yang diperingatkan.', tier: SpeechTier.warning);
      notifyListeners();
      Timer(const Duration(seconds: 6), _recoverServer);
    } else if (r < 0.2) {
      _phase = NavPhase.serverWeak;
      _speak('Sinyal lemah, arahan jalur mungkin tertinggal.', tier: SpeechTier.info);
      notifyListeners();
      Timer(const Duration(seconds: 5), () {
        if (_phase == NavPhase.serverWeak) {
          _phase = NavPhase.active;
          notifyListeners();
        }
      });
    }
  }

  void _recoverServer() {
    if (_phase != NavPhase.serverDown) return;
    _phase = NavPhase.active;
    _left = _center = _right = ZoneStatus.safe;
    _speak('Jalur terbaca lagi.', tier: SpeechTier.info);
    notifyListeners();
  }

  /// NV-14a/b — telepon masuk (disimulasikan manual dari panel debug).
  void simulateIncomingCall() {
    _phase = NavPhase.paused;
    _zoneTimer?.cancel();
    notifyListeners();
  }

  void endSimulatedCall() {
    _phase = NavPhase.active;
    _speak('Navigasi lanjut. ${_summaryPhrase()}', tier: SpeechTier.info);
    notifyListeners();
    _startZoneSimulation();
  }

  String _summaryPhrase() {
    if (_left == ZoneStatus.safe && _center == ZoneStatus.safe && _right == ZoneStatus.safe) return 'Jalur aman.';
    return 'Periksa arahan jalur di layar.';
  }

  /// NV-15 — jeda otomatis (berhenti berjalan / ponsel diturunkan).
  void autoPause() {
    if (_phase != NavPhase.active) return;
    _phase = NavPhase.paused;
    _zoneTimer?.cancel();
    notifyListeners();
  }

  void resumeFromPause() {
    if (_phase != NavPhase.paused) return;
    _phase = NavPhase.active;
    notifyListeners();
    _startZoneSimulation();
  }

  Future<void> startNavigation(String dest) async {
    _destination = dest;
    _currentIdx = 0;
    _navigating = true;
    _steps = [
      NavigationStep(instruction: 'Navigasi ke $dest belum tersedia. GPS akan ditambahkan.', distanceM: 0),
    ];
    notifyListeners();
    _speak('Tujuan disimpan: $dest. Fitur navigasi GPS segera hadir, arahan jalur dan rintangan tetap aktif.', tier: SpeechTier.info);
  }

  void stopNavigation() {
    _navigating = false;
    _destination = null;
    _steps = [];
    _currentIdx = 0;
    _zoneTimer?.cancel();
    _serverFlakyTimer?.cancel();
    notifyListeners();
  }

  void saveFavorite(String name, String destination) {
    _favorites[name] = destination;
    notifyListeners();
  }

  @override
  void dispose() {
    _zoneTimer?.cancel();
    _serverFlakyTimer?.cancel();
    super.dispose();
  }
}
