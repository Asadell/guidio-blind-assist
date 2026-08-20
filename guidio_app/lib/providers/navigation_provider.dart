import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier, TtsQueue;
import '../models/detection.dart';
import '../services/nav_frame_converter.dart';
import '../services/pidnet_service.dart';
import '../services/yolo_navigasi_service.dart';
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
/// **Sepenuhnya on-device.** PIDNet-S (segmentasi 3 zona) dan YOLO11n
/// (rintangan) berjalan di ponsel; keduanya sudah dibundel di APK.
///
/// > Jalur server dihapus. `navigasi.router` memang sudah dinonaktifkan di
/// > `backend/main.py` sejak navigasi dipindah on-device, sehingga fallback
/// > `POST /api/navigasi` di sini hanya menghasilkan 404 — lalu diterjemahkan
/// > menjadi "Saya tidak bisa membaca jalur tanpa sambungan ke server".
/// > Kalimat itu menyalahkan jaringan untuk endpoint yang memang sengaja
/// > tidak disediakan, dan mendorong pengguna mencari sinyal yang tidak akan
/// > menolong. Sekarang mode ini hidup atau mati bersama modelnya sendiri,
/// > dan mengatakannya apa adanya.
enum NavPhase {
  calibrating, // NV-01
  loadingModels, // NV-02 — memuat PIDNet + YOLO on-device
  active, // NV-03..NV-09
  unavailable, // NV-11 — model on-device tidak bisa dipakai
  degraded, // NV-13 — model jalan tapi frame sering gagal dibaca
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
  final double _potholeSteps = 3;
  double get potholeSteps => _potholeSteps;

  /// Zona rawan dari laporan komunitas — informasi yang tidak terlihat kamera.
  String? _riskZoneWarning;
  String? get riskZoneWarning => _riskZoneWarning;

  /// Rintangan dari frame yang sama dengan zona. Datang bersama zona supaya
  /// keduanya tidak pernah menggambarkan momen yang berbeda.
  List<Detection> _obstacles = const [];
  List<Detection> get obstacles => _obstacles;

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 — mengambil alih layar

  /// Sumber frame kamera mentah (YUV) untuk PIDNet + YOLO on-device.
  Future<CameraImage?> Function()? cameraSource;

  /// Status loading model on-device.
  bool _modelsLoading = false;
  bool _modelsReady   = false;
  bool get modelsReady => _modelsReady;

  /// Satu permintaan in-flight; frame yang datang saat menunggu dibuang.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 700));

  Timer? _loopTimer;
  int _consecutiveFailures = 0;
  String _lastSpokenMessage = '';
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pesan yang sedang menunggu konfirmasi frame berikutnya, dan sudah berapa
  /// frame berturut-turut ia bertahan. Dipakai [_emitGuidance] sebagai
  /// histeresis — lihat alasannya di sana.
  String _candidateMessage = '';
  int _candidateStreak = 0;

  /// Jeda minimum antar ucapan berbeda (non-critical).
  static const _minGap = Duration(milliseconds: 1800);

  /// Jeda sebelum pesan non-critical yang SAMA boleh diulang.
  static const _sameMessageGap = Duration(seconds: 6);

  /// Jeda sebelum peringatan critical yang SAMA boleh diulang. Lebih pendek
  /// dari [_sameMessageGap] karena bahayanya nyata, tapi tidak nol — lihat
  /// [_emitGuidance].
  static const _criticalRepeatGap = Duration(seconds: 4);

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);

  void startCalibration() {
    _phase = NavPhase.calibrating;
    notifyListeners();
  }

  /// NV-01 selesai → muat model on-device → NV-03 jalur aman.
  void finishCalibration() {
    _phase = NavPhase.loadingModels;
    _left = _center = _right = ZoneStatus.unknown;
    notifyListeners();

    if (!_modelsReady && !_modelsLoading) {
      _loadOnDeviceModels();
    } else {
      _startLoop();
    }
  }

  /// Muat PIDNet + YOLO secara paralel di background.
  Future<void> _loadOnDeviceModels() async {
    _modelsLoading = true;
    debugPrint('[Nav] Memuat model on-device...');

    final results = await Future.wait([
      PidnetService.instance.tryLoad(),
      YoloNavigasiService.instance.tryLoad(),
    ]);

    _modelsLoading = false;
    _modelsReady = results[0] && results[1];

    if (!_modelsReady) {
      // Tidak ada cadangan server lagi. Katakan apa adanya — dan sebut mode
      // apa yang MASIH bisa dipakai, supaya ini bukan jalan buntu.
      debugPrint('[Nav] Model on-device gagal dimuat.');
      _phase = NavPhase.unavailable;
      _speak(
        'Panduan jalur tidak bisa dijalankan di perangkat ini. '
        'Mode Deteksi Objek tetap bisa memperingatkan rintangan.',
        tier: SpeechTier.critical,
      );
      notifyListeners();
      return;
    }

    debugPrint('[Nav] Model on-device siap. PIDNet + YOLO aktif.');
    _speak('Panduan jalur aktif.', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    _candidateMessage = '';
    _candidateStreak = 0;
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
    if (_phase == NavPhase.paused || !_modelsReady) return;
    await _pacer.run(_tickOnDevice);
  }

  // ── On-Device: PIDNet + YOLO di HP ──────────────────────────
  Future<void> _tickOnDevice() async {
    final camGrab = cameraSource;
    if (camGrab == null) return;
    final frame = await camGrab();
    if (frame == null) return;

    try {
      // Konversi YUV→RGB sekali, dipakai keduanya
      final conv = NavFrameConverter.fromCameraImage(frame);

      // Jalankan PIDNet dan YOLO secara paralel
      final results = await Future.wait([
        PidnetService.instance.analyze(conv.rgb, conv.width, conv.height),
        YoloNavigasiService.instance.detect(conv.rgb, conv.width, conv.height),
      ]);

      final zoneAnalysis = results[0] as ZoneAnalysis?;
      final obstacles    = results[1] as List<Detection>;

      if (zoneAnalysis == null) return;

      _consecutiveFailures = 0;
      _applyOnDeviceResult(zoneAnalysis, obstacles);
    } catch (e) {
      debugPrint('[Nav] on-device tick error: $e');
      _handleFailure();
    }
  }

  void _applyOnDeviceResult(ZoneAnalysis zones, List<Detection> obstacles) {
    final wasDown = _phase == NavPhase.degraded || _phase == NavPhase.loadingModels;

    _left   = zones.left;
    _center = zones.center;
    _right  = zones.right;
    _phase  = NavPhase.active;
    _obstacles = obstacles;
    _pothole = obstacles.any((d) =>
        (d.labelEn == 'lubang' || d.labelEn == 'got_terbuka') &&
        d.dangerLevel == 'critical');

    if (wasDown) _speak('Jalur terbaca lagi.', tier: SpeechTier.info);

    final guidance = _composeGuidance(zones, obstacles);
    _emitGuidance(guidance.$1, guidance.$2, takeover: guidance.$3);
    notifyListeners();
  }

  /// Susun satu pesan untuk frame ini: rintangan kritis didahulukan, lalu
  /// rintangan peringatan, baru arahan zona. Fungsi ini murni — tidak bicara
  /// dan tidak mengubah state — supaya keputusan "apa yang perlu dikatakan"
  /// terpisah dari keputusan "apakah sekarang saatnya mengatakannya".
  (String, SpeechTier, bool) _composeGuidance(ZoneAnalysis zones, List<Detection> obstacles) {
    final critical = obstacles.where((d) => d.dangerLevel == 'critical').toList();
    if (critical.isNotEmpty) {
      return (critical.first.ttsMessage, SpeechTier.critical, true);
    }

    final warning = obstacles.where((d) => d.dangerLevel == 'warning').toList();
    if (warning.isNotEmpty) {
      return (warning.first.ttsMessage, SpeechTier.warning, false);
    }

    final allDanger = _left == ZoneStatus.danger &&
        _center == ZoneStatus.danger &&
        _right == ZoneStatus.danger;
    if (allDanger) {
      return ('Berhenti dulu. Tidak ada jalur aman.', SpeechTier.critical, false);
    }
    if (_center == ZoneStatus.danger) {
      return ('Berhenti! Jalur di depan tidak aman.', SpeechTier.critical, true);
    }
    return (zones.ttsMessage, SpeechTier.info, false);
  }

  /// Anti-banjir suara. Loop menghasilkan pesan tiap frame; mengucapkan
  /// semuanya akan menutupi suara lalu lintas — hal terakhir yang boleh
  /// terjadi pada orang yang sedang menyeberang.
  ///
  /// Tiga rem, masing-masing menutup lubang yang berbeda:
  ///
  /// 1. **Histeresis.** PIDNet dan YOLO berkedip antar-frame; tanpa ini satu
  ///    kedipan model langsung jadi satu kedipan suara. Info dan Warning
  ///    butuh dua frame berturut-turut dengan pesan yang sama. Critical lewat
  ///    pada kemunculan pertama — menunda peringatan bahaya ~700 ms demi
  ///    kerapian suara adalah pertukaran yang salah di mode ini.
  ///
  /// 2. **Critical tidak memotong dirinya sendiri.** Sebelumnya kedua rem
  ///    waktu dilewati Critical sepenuhnya, jadi jalur tengah yang berbahaya
  ///    selama sepuluh detik memicu peringatan identik tiap ~700 ms. Tiap
  ///    pemicu menjalankan `TTSService.stop()` lalu `speak(interrupt: true)`,
  ///    sehingga kalimatnya diulang dari awal terus-menerus dan **tidak
  ///    pernah selesai diucapkan sekali pun**. Peringatan yang tidak pernah
  ///    utuh bukan peringatan. Critical tetap memotong Info/Warning; yang
  ///    dilarang hanya memotong Critical yang sama.
  ///
  /// 3. **Jangan menumpuk di atas ucapan yang belum habis.** [_lastSpokenAt]
  ///    dicatat saat pesan DIKIRIM, bukan saat selesai dibacakan. Satu
  ///    kalimat arahan zona ("Kiri aman, tengah hati-hati, kanan bahaya.
  ///    Geser ke kiri.") butuh ~4 detik pada `speechRate` 0,5 — jauh lebih
  ///    lama dari rem 1,8 detik. Tanpa cek [TtsQueue.isSpeaking], pesan
  ///    berikutnya selalu berangkat sebelum yang sekarang habis, lalu
  ///    dibuang antrean karena kedaluwarsa 2 detik. Itulah yang terdengar
  ///    sebagai suara buru-buru dan saling menimpa.
  void _emitGuidance(String message, SpeechTier tier, {required bool takeover}) {
    if (message == _candidateMessage) {
      _candidateStreak++;
    } else {
      _candidateMessage = message;
      _candidateStreak = 1;
    }
    if (tier != SpeechTier.critical && _candidateStreak < 2) return;

    final now = DateTime.now();
    final isRepeat = message == _lastSpokenMessage;
    final elapsed = now.difference(_lastSpokenAt);

    if (tier == SpeechTier.critical) {
      if (isRepeat && elapsed < _criticalRepeatGap) return;
    } else {
      if (isRepeat && elapsed < _sameMessageGap) return;
      if (elapsed < _minGap) return;
      if (TtsQueue.instance.isSpeaking) return;
    }

    _lastSpokenMessage = message;
    _lastSpokenAt = now;
    // Dipanggil hanya kalau pesannya benar-benar jadi diucapkan. Sebelumnya
    // takeover berjalan lebih dulu tanpa syarat, jadi ia tetap memotong
    // ucapan berjalan walau peringatannya kemudian diredam rem di atas.
    if (takeover) onTakeover?.call();
    _speak(message, tier: tier);
  }

  /// Frame gagal dianalisis berturut-turut.
  ///
  /// Penyebabnya sekarang lokal — lensa tertutup, terlalu gelap, model
  /// kehabisan memori — bukan jaringan. Naskahnya ikut berubah: menyalahkan
  /// "sambungan server" untuk masalah yang ada di tangan pengguna hanya
  /// mengirimnya mencari sinyal yang tidak akan menolong.
  void _handleFailure() {
    _consecutiveFailures++;

    // Satu kegagalan bisa jadi hanya satu frame buruk — jangan langsung
    // menakuti pengguna. Beberapa berturut-turut berarti mode ini memang
    // sedang tidak melihat apa-apa, dan itu harus dikatakan segera: diam
    // berarti membiarkan orang berjalan menyangka dirinya dituntun.
    if (_consecutiveFailures == 2 && _phase != NavPhase.degraded) {
      _phase = NavPhase.degraded;
      _speak('Jalur sulit dibaca, arahan mungkin tertinggal.', tier: SpeechTier.warning);
      notifyListeners();
      return;
    }

    if (_consecutiveFailures >= 4 && _phase != NavPhase.unavailable) {
      _phase = NavPhase.unavailable;
      _left = _center = _right = ZoneStatus.unknown;
      _speak(
        'Berhenti jalan dulu. Saya tidak bisa membaca jalur sekarang. '
        'Periksa apakah kamera tertutup, atau cari tempat yang lebih terang.',
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
    return zoneSummary();
  }

  /// Ringkasan tiga zona dalam kata, bukan warna.
  ///
  /// `ZoneIndicator` menampilkan tiga blok berwarna — tidak ada gunanya bagi
  /// pengguna yang tidak melihat layar. Ini padanan verbalnya, dan inilah yang
  /// dibacakan tombol kiri "Ulangi arahan".
  String zoneSummary() {
    if (_phase == NavPhase.calibrating || _phase == NavPhase.loadingModels) {
      return 'Jalur belum terbaca, tunggu sebentar.';
    }
    if (_left == ZoneStatus.unknown &&
        _center == ZoneStatus.unknown &&
        _right == ZoneStatus.unknown) {
      return 'Jalur belum terbaca.';
    }

    String word(ZoneStatus s) => switch (s) {
          ZoneStatus.safe => 'aman',
          ZoneStatus.caution => 'hati-hati',
          ZoneStatus.danger => 'bahaya',
          ZoneStatus.unknown => 'belum terbaca',
        };

    final parts = 'Kiri ${word(_left)}, tengah ${word(_center)}, kanan ${word(_right)}.';

    // Sebutkan rekomendasinya, bukan hanya keadaannya — pengguna butuh tahu
    // harus berbuat apa, bukan sekadar daftar status.
    final saran = _center == ZoneStatus.safe
        ? 'Tetap di tengah.'
        : _left == ZoneStatus.safe
            ? 'Geser ke kiri.'
            : _right == ZoneStatus.safe
                ? 'Geser ke kanan.'
                : 'Berhenti dulu, tidak ada jalur aman.';

    return '$parts $saran';
  }

  /// Tombol kiri Mode Navigasi / perintah suara "ulangi".
  ///
  /// Sengaja melewati anti-banjir [_announce]: ini permintaan eksplisit
  /// pengguna, bukan pesan otomatis yang berisiko menutupi suara lalu lintas.
  void repeatGuidance() {
    _speak(zoneSummary(), tier: SpeechTier.warning);
  }

  /// `actionStopWalking` — hentikan panduan tanpa keluar mode.
  /// Mengembalikan false kalau memang tidak ada yang berjalan.
  bool pauseGuidance() {
    if (_phase == NavPhase.paused) return false;
    autoPause();
    return true;
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
    _modelsReady   = false;
    _modelsLoading = false;
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
