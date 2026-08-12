import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier;
import '../models/detection.dart';
import '../services/server_service.dart';
import '../widgets/zone_indicator.dart' show ZoneStatus;

/// NavigationStep — placeholder tanpa GPS/Google Maps (belum diimplementasi,
/// menyusul sprint lain).
class NavigationStep {
  final String instruction;
  final int distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

/// Fase segmentasi jalur — bagian 10 IMPLEMENTASI.md (NV-01..NV-13).
///
/// **Sepenuhnya di server.** Frame dikirim ke `POST /api/navigasi`, yang
/// mengembalikan status tiga zona plus zona rawan dari laporan komunitas.
///
/// > **Perubahan dari desain awal, disengaja.** Dokumen merancang mode ini
/// > dengan dua proses paralel: segmentasi jalur di server DAN deteksi
/// > rintangan on-device yang tetap hidup saat offline (§2, §4.4). Sejak
/// > keduanya dipindah ke server, NV-19 dan NV-20 tidak punya arti lagi —
/// > tidak ada lagi "on-device mati sementara server hidup". Offline sekarang
/// > berarti mode ini benar-benar buta, dan itu dikatakan apa adanya
/// > ketimbang dijanjikan setengah.
enum NavPhase {
  calibrating, // NV-01
  waitingServer, // NV-02
  active, // NV-03..NV-09
  serverDown, // NV-11 — sekarang berarti mode benar-benar berhenti
  serverWeak, // NV-13
  paused, // NV-15
}

class NavigationProvider extends ChangeNotifier {
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

  /// Zona rawan dari laporan komunitas — informasi yang tidak terlihat kamera.
  String? _riskZoneWarning;
  String? get riskZoneWarning => _riskZoneWarning;

  /// Rintangan dari server, dari frame yang sama dengan zona. Datang bersama
  /// zona supaya keduanya tidak pernah menggambarkan momen yang berbeda.
  List<Detection> _obstacles = const [];
  List<Detection> get obstacles => _obstacles;

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 — mengambil alih layar

  /// Sumber frame dan koordinat, dipasang screen. Provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;
  ({double lat, double lng})? Function()? locationSource;

  /// Satu permintaan in-flight; frame yang datang saat menunggu dibuang.
  /// Untuk mode yang menuntun orang berjalan, arahan untuk pemandangan tiga
  /// detik lalu lebih berbahaya daripada tidak ada arahan sama sekali.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 500));

  Timer? _loopTimer;
  int _consecutiveFailures = 0;
  String _lastSpokenMessage = '';
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void startCalibration() {
    _phase = NavPhase.calibrating;
    notifyListeners();
  }

  /// NV-01 selesai → NV-02 menunggu server → NV-03 jalur aman.
  ///
  /// NV-02 sekarang benar-benar menunggu jawaban server pertama, bukan timer
  /// tetap: pengguna tidak diberi tahu "siap" sebelum jalurnya sungguh terbaca.
  void finishCalibration() {
    _phase = NavPhase.waitingServer;
    _left = _center = _right = ZoneStatus.unknown;
    notifyListeners();
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    // ~2 frame per detik. Kecepatan jalan kaki sekitar 1,4 m/s, jadi tiap
    // frame mewakili kurang dari satu meter perjalanan — cukup rapat untuk
    // memperingatkan sebelum terlambat, cukup jarang untuk tidak menguras
    // baterai dan kuota di sepanjang perjalanan.
    _loopTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    _tick();
  }

  void _stopLoop() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _pacer.reset();
  }

  Future<void> _tick() async {
    if (_phase == NavPhase.paused) return;
    final grab = frameSource;
    if (grab == null) return;

    await _pacer.run(() async {
      final jpeg = await grab();
      if (jpeg == null) return;
      final loc = locationSource?.call();

      try {
        final res = await ServerService.instance.segmentasiJalur(
          jpeg,
          lat: loc?.lat ?? 0,
          lng: loc?.lng ?? 0,
        );
        _consecutiveFailures = 0;
        _handleZones(res);
      } on ApiStatusException {
        _handleFailure();
      } on ApiUnreachableException {
        _handleFailure();
      }
    });
  }

  void _handleZones(Map<String, dynamic> res) {
    final wasDown = _phase == NavPhase.serverDown || _phase == NavPhase.waitingServer;

    if (res['ok'] != true) {
      // Frame tidak terbaca (lensa tertutup, terlalu gelap) — beda dari
      // server mati, dan naskahnya juga beda.
      _left = _center = _right = ZoneStatus.unknown;
      _phase = NavPhase.serverDown;
      _announce(
        res['message'] as String? ?? 'Jalur tidak terbaca. Berhenti jalan dulu.',
        SpeechTier.critical,
      );
      notifyListeners();
      return;
    }

    final zones = res['zones'] as Map<String, dynamic>?;
    if (zones == null) return;

    _left = _statusFrom(zones['kiri']);
    _center = _statusFrom(zones['tengah']);
    _right = _statusFrom(zones['kanan']);
    _phase = NavPhase.active;

    // Rintangan dari frame yang sama — lihat catatan di routers/navigasi.py.
    final rawObstacles = res['obstacles'];
    _obstacles = rawObstacles is List
        ? rawObstacles
            .map((e) => Detection.fromJson(e as Map<String, dynamic>))
            .toList()
        : const [];

    // NV-09 — lubang dilaporkan server sebagai zona danger yang sempit;
    // sementara backend belum memisahkannya, tandai lewat field opsional.
    _pothole = res['pothole'] == true;
    if (_pothole) {
      _potholeSteps = (res['pothole_steps'] as num?)?.toDouble() ?? 3;
    }

    // Zona rawan komunitas — disebut sekali saat masuk radius, tidak diulang.
    final risk = res['risk_zone'] as Map<String, dynamic>?;
    final riskWarning = risk?['warning'] as String?;
    if (riskWarning != null && riskWarning != _riskZoneWarning) {
      _riskZoneWarning = riskWarning;
      _speak(riskWarning, tier: SpeechTier.warning);
    } else if (risk == null) {
      _riskZoneWarning = null;
    }

    if (wasDown) {
      _speak('Jalur terbaca lagi.', tier: SpeechTier.info);
    }

    final message = res['message'] as String? ?? '';
    final allDanger = _left == ZoneStatus.danger &&
        _center == ZoneStatus.danger &&
        _right == ZoneStatus.danger;

    if (allDanger) {
      // NV-07 — berdiri diam adalah tindakan yang sah.
      _announce('Berhenti dulu. Tidak ada jalur aman di sekitar sini.', SpeechTier.critical);
    } else if (_center == ZoneStatus.danger) {
      // NV-06 — mengambil alih layar dan memotong antrean suara.
      onTakeover?.call();
      _announce(
        message.isNotEmpty ? message : 'Berhenti! Jalur di depan tidak aman.',
        SpeechTier.critical,
      );
    } else if (message.isNotEmpty) {
      _announce(message, SpeechTier.warning);
    }

    notifyListeners();
  }

  /// Anti-banjir suara. Server mengirim pesan tiap frame; mengucapkan semuanya
  /// akan menutupi suara lalu lintas — hal terakhir yang boleh terjadi pada
  /// orang yang sedang menyeberang. Pesan yang sama hanya diulang setelah
  /// jeda, kecuali Critical yang selalu lewat.
  void _announce(String message, SpeechTier tier) {
    final now = DateTime.now();
    final isRepeat = message == _lastSpokenMessage;
    final elapsed = now.difference(_lastSpokenAt);

    if (tier != SpeechTier.critical && isRepeat && elapsed < const Duration(seconds: 6)) {
      return;
    }
    if (tier != SpeechTier.critical && elapsed < const Duration(milliseconds: 1800)) {
      return;
    }
    _lastSpokenMessage = message;
    _lastSpokenAt = now;
    _speak(message, tier: tier);
  }

  ZoneStatus _statusFrom(dynamic zone) {
    final status = (zone is Map<String, dynamic>) ? zone['status'] as String? : null;
    return switch (status) {
      'safe' => ZoneStatus.safe,
      'caution' => ZoneStatus.caution,
      'danger' => ZoneStatus.danger,
      _ => ZoneStatus.unknown,
    };
  }

  void _handleFailure() {
    _consecutiveFailures++;

    // Satu kegagalan bisa jadi hanya satu paket hilang — jangan langsung
    // menakuti pengguna. Tiga berturut-turut berarti sambungannya memang
    // putus, dan itu harus dikatakan segera: mode ini tidak punya cadangan
    // on-device lagi, jadi diam berarti membiarkan orang berjalan buta.
    if (_consecutiveFailures == 2) {
      _phase = NavPhase.serverWeak;
      _speak('Sinyal lemah, arahan jalur mungkin tertinggal.', tier: SpeechTier.warning);
      notifyListeners();
      return;
    }

    if (_consecutiveFailures >= 4 && _phase != NavPhase.serverDown) {
      _phase = NavPhase.serverDown;
      _left = _center = _right = ZoneStatus.unknown;
      _speak(
        'Berhenti jalan dulu. Saya tidak bisa membaca jalur tanpa sambungan ke server.',
        tier: SpeechTier.critical,
      );
      notifyListeners();
    }
  }

  /// NV-14a/b — telepon masuk (disimulasikan manual dari panel debug).
  void simulateIncomingCall() {
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void endSimulatedCall() {
    _phase = NavPhase.active;
    // NV-14b — status jalur SEKARANG, bukan yang tadi. Karena itu loop-nya
    // dijalankan lagi lebih dulu dan ringkasannya menyusul dari frame baru.
    _speak('Navigasi lanjut. ${_summaryPhrase()}', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  String _summaryPhrase() {
    if (_left == ZoneStatus.safe && _center == ZoneStatus.safe && _right == ZoneStatus.safe) return 'Jalur aman.';
    return 'Periksa arahan jalur di layar.';
  }

  /// NV-15 — jeda otomatis (berhenti berjalan / ponsel diturunkan).
  /// Menghentikan loop juga menghentikan unggahan frame: berhenti berjalan
  /// berarti berhenti membakar kuota dan baterai.
  void autoPause() {
    if (_phase != NavPhase.active) return;
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void resumeFromPause() {
    if (_phase != NavPhase.paused) return;
    _phase = NavPhase.active;
    notifyListeners();
    _startLoop();
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
    _riskZoneWarning = null;
    _consecutiveFailures = 0;
    _lastSpokenMessage = '';
    _stopLoop();
    notifyListeners();
  }

  void saveFavorite(String name, String destination) {
    _favorites[name] = destination;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLoop();
    super.dispose();
  }
}
