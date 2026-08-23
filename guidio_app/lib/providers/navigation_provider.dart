import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart';
import '../core/speech/tts_queue.dart' show SpeechTier, TtsQueue;
import '../models/detection.dart';
import '../services/nav_frame_converter.dart';
import '../services/device_pace_watch.dart';
import '../services/nav_obstacle_merger.dart';
import '../services/pidnet_service.dart';
import '../services/tflite_service.dart';
import '../services/yolo_nav_int8_service.dart';
import '../services/yolo_navigasi_service.dart';
import '../widgets/segmentation_overlay.dart' show maskToImage;
import '../widgets/zone_indicator.dart' show ZoneStatus;

/// NavigationStep - placeholder tanpa GPS/Google Maps (belum diimplementasi,
/// menyusul sprint lain).
class NavigationStep {
  final String instruction;
  final int distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

/// Fase segmentasi jalur - bagian 10 IMPLEMENTASI.md (NV-01..NV-13).
///
/// **Sepenuhnya on-device.** PIDNet-S (segmentasi 3 zona) dan YOLO11n
/// (rintangan) berjalan di ponsel; keduanya sudah dibundel di APK.
///
/// > Jalur server dihapus. `navigasi.router` memang sudah dinonaktifkan di
/// > `backend/main.py` sejak navigasi dipindah on-device, sehingga fallback
/// > `POST /api/navigasi` di sini hanya menghasilkan 404 - lalu diterjemahkan
/// > menjadi "Saya tidak bisa membaca jalur tanpa sambungan ke server".
/// > Kalimat itu menyalahkan jaringan untuk endpoint yang memang sengaja
/// > tidak disediakan, dan mendorong pengguna mencari sinyal yang tidak akan
/// > menolong. Sekarang mode ini hidup atau mati bersama modelnya sendiri,
/// > dan mengatakannya apa adanya.
enum NavPhase {
  calibrating, // NV-01
  loadingModels, // NV-02 - memuat PIDNet + YOLO on-device
  active, // NV-03..NV-09
  unavailable, // NV-11 - model on-device tidak bisa dipakai
  degraded, // NV-13 - model jalan tapi frame sering gagal dibaca
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

  /// Zona rawan dari laporan komunitas - informasi yang tidak terlihat kamera.
  String? _riskZoneWarning;
  String? get riskZoneWarning => _riskZoneWarning;

  /// Rintangan dari frame yang sama dengan zona. Datang bersama zona supaya
  /// keduanya tidak pernah menggambarkan momen yang berbeda.
  List<Detection> _obstacles = const [];
  List<Detection> get obstacles => _obstacles;

  // ── Hamparan segmentasi jalur ─────────────────────────────────────────

  /// Gambar jalur hasil segmentasi PIDNet, siap ditumpuk di atas preview.
  ///
  /// `null` berarti belum ada yang bisa digambar. Diperbarui hanya kalau
  /// [wantsSegmentationOverlay] menyala, supaya jalur yang tidak menampilkan
  /// apa pun tidak membayar konversi dan salinan mask-nya.
  ui.Image? _segmentationImage;
  ui.Image? get segmentationImage => _segmentationImage;

  /// Layar menyalakan ini saat hamparan jalur benar-benar terlihat.
  ///
  /// Dipisah dari sekadar "mode navigasi aktif" karena inferensi tetap harus
  /// berjalan walau layar mati atau tertutup - arahan suaranya yang menjaga
  /// pengguna, bukan gambarnya.
  bool _wantsSegmentationOverlay = false;
  bool get wantsSegmentationOverlay => _wantsSegmentationOverlay;

  set wantsSegmentationOverlay(bool value) {
    if (_wantsSegmentationOverlay == value) return;
    _wantsSegmentationOverlay = value;
    if (!value) _disposeSegmentationImage();
    notifyListeners();
  }

  /// Satu konversi mask dalam penerbangan.
  ///
  /// Tanpa penjaga ini, inferensi yang lebih cepat daripada konversi akan
  /// menumpuk `ui.Image` yang tidak pernah sempat ditampilkan - masing-masing
  /// memegang memori GPU sampai dibuang.
  bool _convertingMask = false;

  void _disposeSegmentationImage() {
    _segmentationImage?.dispose();
    _segmentationImage = null;
  }

  /// Ubah mask PIDNet jadi gambar, lalu buang gambar sebelumnya.
  ///
  /// `ui.Image` memegang memori di luar heap Dart dan TIDAK dibersihkan
  /// pengumpul sampah. Melewatkan `dispose()` di sini berarti kebocoran
  /// yang tumbuh delapan kali per detik selama mode navigasi menyala.
  Future<void> _updateSegmentationImage(ZoneAnalysis zones) async {
    final mask = zones.mask;
    if (mask == null || zones.maskWidth == 0 || zones.maskHeight == 0) return;
    if (_convertingMask) return;

    _convertingMask = true;
    try {
      final img = await maskToImage(mask, zones.maskWidth, zones.maskHeight);
      // Mode bisa saja sudah dimatikan selama konversi berjalan.
      if (!_wantsSegmentationOverlay) {
        img.dispose();
        return;
      }
      _segmentationImage?.dispose();
      _segmentationImage = img;
      notifyListeners();
    } catch (e) {
      debugPrint('[Nav] konversi mask gagal: $e');
    } finally {
      _convertingMask = false;
    }
  }

  void Function(String text, SpeechTier tier)? onSpeak;
  void Function()? onTakeover; // NV-06 - mengambil alih layar

  /// Sumber frame kamera mentah (YUV) untuk PIDNet + YOLO on-device.
  Future<CameraImage?> Function()? cameraSource;

  // ── Kondisi kamera yang ikut menentukan boleh-tidaknya memberi arahan ──
  //
  // `CameraProvider` sudah mendeteksi frame gelap dan ponsel yang salah arah,
  // lalu mengucapkannya sendiri. Yang TIDAK terjadi sebelumnya: kondisi itu
  // tidak pernah sampai ke lapisan yang menyusun arahan jalur. Akibatnya
  // pengguna bisa mendengar "Arahkan kamera ke depan" dan "Jalur aman, jalan
  // lurus" berselang beberapa detik - dua kalimat yang saling membantah, dan
  // yang terdengar paling bisa ditindaklanjuti justru yang salah.

  bool _cameraTooDark = false;
  String? _cameraMisaimed;

  /// Dipanggil layar tiap kali kondisi kamera berubah.
  ///
  /// [misaimed] berisi kalimat perbaikan dari `CameraHealthService`
  /// ("Arahkan kamera ke depan", "Pegang HP tegak"), atau null kalau
  /// orientasinya wajar.
  void updateCameraCondition({required bool tooDark, String? misaimed}) {
    if (_cameraTooDark == tooDark && _cameraMisaimed == misaimed) return;
    _cameraTooDark = tooDark;
    _cameraMisaimed = misaimed;
    notifyListeners();
  }

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
  /// histeresis - lihat alasannya di sana.
  String _candidateMessage = '';
  int _candidateStreak = 0;

  // ── Pengawas kecepatan perangkat ────────────────────────────────────────
  //
  // Logikanya ada di [DevicePaceWatch], kelas murni tanpa Timer maupun TTS,
  // supaya keputusan "kapan pengguna diberi tahu bahwa panduannya tertinggal"
  // bisa diuji tanpa perangkat. Lihat `test/device_pace_watch_test.dart`.
  final _pace = DevicePaceWatch();

  /// Lapis COCO dimatikan otomatis karena perangkat tidak mengejar.
  bool get cocoDisabledForSpeed => _pace.cocoDropped;

  /// Rata-rata durasi satu siklus inferensi, milidetik. Dibaca panel debug.
  double get tickMsEma => _pace.emaMs;

  /// Catat durasi satu siklus, lalu turunkan beban atau beri tahu pengguna.
  void _recordTickDuration(int ms) {
    switch (_pace.record(ms)) {
      case PaceAction.dropCocoLayer:
        debugPrint('[Nav] Perangkat lambat (${_pace.emaMs.toStringAsFixed(0)} ms), '
            'lapis COCO dimatikan otomatis.');
        notifyListeners();
      case PaceAction.warnUser:
        _speak(
          'Ponsel ini memproses jalur lebih lambat dari biasanya. '
          'Jalan lebih pelan, arahan bisa datang terlambat.',
          tier: SpeechTier.warning,
        );
        notifyListeners();
      case PaceAction.none:
        break;
    }
  }

  /// Jeda minimum antar ucapan berbeda (non-critical).
  static const _minGap = Duration(milliseconds: 1800);

  /// Jeda sebelum pesan non-critical yang SAMA boleh diulang.
  static const _sameMessageGap = Duration(seconds: 6);

  /// Jeda sebelum peringatan critical yang SAMA boleh diulang. Lebih pendek
  /// dari [_sameMessageGap] karena bahayanya nyata, tapi tidak nol - lihat
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

  /// True kalau lapis ketiga (SSD MobileNet COCO) ikut hidup di mode ini.
  ///
  /// Dibaca layar untuk menampilkan apa adanya, dan dipakai [_tickOnDevice]
  /// untuk melewati inferensi ketiga saat modelnya tidak tersedia.
  bool _cocoReady = false;
  bool get cocoReady => _cocoReady;

  /// True kalau lapis keempat (YOLO INT8, yolo11n.tflite) ikut hidup.
  ///
  /// Model ini terbukti lebih kuat mendeteksi `tiang` dibanding model FP16
  /// utama. Bersifat optional: jika gagal dimuat mode tetap aktif penuh.
  bool _int8Ready = false;
  bool get int8Ready => _int8Ready;

  /// Muat PIDNet + YOLO FP16 + YOLO INT8 + SSD MobileNet COCO secara paralel.
  Future<void> _loadOnDeviceModels() async {
    _modelsLoading = true;
    debugPrint('[Nav] Memuat model on-device...');

    final results = await Future.wait([
      PidnetService.instance.tryLoad(),
      YoloNavigasiService.instance.tryLoad(),
      // Lapis ketiga. `TFLiteService` adalah singleton yang juga dipakai Mode
      // Deteksi Objek, jadi kalau modelnya sudah termuat dari sana, jangan
      // membangun interpreter kedua: di HP 4 GB dua interpreter menganggur
      // sudah terasa, dan keduanya memegang memori native yang sama.
      TFLiteService.instance.isLoaded
          ? Future.value(true)
          : TFLiteService.instance.tryLoad(),
      // Lapis keempat: YOLO INT8 (yolo11n.tflite). Terbukti lebih akurat
      // untuk `tiang` dibanding model FP16. Optional - gagal muat tidak
      // menjatuhkan mode.
      YoloNavInt8Service.instance.tryLoad(),
    ]);

    _modelsLoading = false;

    // Lapis ketiga dan keempat sengaja TIDAK ikut menentukan `_modelsReady`.
    //
    // Keduanya menambah cakupan, bukan menopang mode ini. Kalau SSD atau
    // YOLO INT8 gagal dimuat, panduan jalur dan enam kelas bahaya custom
    // tetap berjalan penuh.
    _cocoReady = results[2];
    _int8Ready  = results[3];
    _modelsReady = results[0] && results[1];

    if (!_modelsReady) {
      // Tidak ada cadangan server lagi. Katakan apa adanya - dan sebut mode
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

    debugPrint('[Nav] Model on-device siap. PIDNet + YOLO FP16'
        '${_int8Ready ? " + YOLO INT8" : ""}'
        '${_cocoReady ? " + SSD COCO" : ""} aktif.');
    _speak('Panduan jalur aktif.', tier: SpeechTier.info);
    notifyListeners();
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    _candidateMessage = '';
    _candidateStreak = 0;
    // Pengawas kecepatan mulai dari nol tiap sesi: ponsel yang tadi lambat
    // karena aplikasi lain sedang berat belum tentu lambat sekarang, dan
    // menghukumnya selamanya berarti membuang lapis COCO tanpa alasan.
    _pace.reset();
    // ~2 frame per detik. Kecepatan jalan kaki sekitar 1,4 m/s, jadi tiap
    // frame mewakili kurang dari satu meter perjalanan - cukup rapat untuk
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

  // ── On-Device: PIDNet + YOLO + SSD COCO di HP ───────────────
  Future<void> _tickOnDevice() async {
    final camGrab = cameraSource;
    if (camGrab == null) return;
    final frame = await camGrab();
    if (frame == null) return;

    // Diukur dari SEBELUM penyiapan tensor sampai sesudah hasilnya dipakai,
    // bukan hanya inferensinya. Di ponsel lama, konversi YUV dan tekanan
    // pengumpul sampah sering lebih mahal daripada modelnya sendiri, dan
    // mengukur inferensi saja akan menyembunyikan justru bagian yang berat.
    final t0 = DateTime.now();

    try {
      // Satu lintasan di isolate menyiapkan KEDUA tensor sekaligus.
      //
      // Sebelumnya bagian ini berjalan di isolate UI: YUV→RGB frame penuh,
      // lalu masing-masing service memutar dan menskalakan ulang frame yang
      // SAMA, lalu membangun `List` bersarang. Diukur 136 ms per frame di CPU
      // desktop - di HP mid-low berkali lipat, dan seluruhnya menahan thread
      // yang juga menjadwalkan TTS.
      final tensors = await NavFrameConverter.prepare(
        frame,
        pidnetBchw: PidnetService.instance.wantsBchw,
      );

      // Tiga model berjalan paralel dari SATU frame yang sama.
      //
      // Frame yang sama itu syarat, bukan penghematan: zona jalur, rintangan
      // custom, dan rintangan COCO harus menggambarkan momen yang identik.
      // Kalau salah satunya terlambat satu frame, pengguna bisa mendengar
      // "jalur tengah aman" bersamaan dengan "ada motor di depan" dari
      // pemandangan yang sudah lewat.
      //
      // SSD MobileNet menyiapkan tensornya sendiri dari `CameraImage` (crop
      // persegi di tengah + rotasi, lihat `tflite_service.dart`), jadi ia
      // tidak ikut `NavFrameConverter`. Keluarannya tetap dalam koordinat
      // bingkai TEGAK yang sama dengan YOLO custom, sehingga kotaknya bisa
      // langsung dibandingkan dan digambar tanpa konversi tambahan.
      final results = await Future.wait([
        PidnetService.instance.analyze(
          tensors.pidnet,
          // Mask hanya diminta kalau memang akan digambar.
          withMask: _wantsSegmentationOverlay,
        ),
        YoloNavigasiService.instance.detect(
          tensors.yolo,
          tensors.uprightWidth,
          tensors.uprightHeight,
        ),
        if (_cocoReady)
          TFLiteService.instance.runInference(frame)
        else
          Future.value(const <Detection>[]),
        // Lapis keempat: YOLO INT8 memakai tensor NHWC yang sama dengan
        // model FP16 (ditranspose ke NCHW di dalam service).
        if (_int8Ready)
          YoloNavInt8Service.instance.detect(
            tensors.yolo,
            tensors.uprightWidth,
            tensors.uprightHeight,
          )
        else
          Future.value(const <Detection>[]),
      ]);

      final zoneAnalysis = results[0] as ZoneAnalysis?;
      final custom       = results[1] as List<Detection>;
      final coco         = results[2] as List<Detection>;
      final int8         = results[3] as List<Detection>;

      if (zoneAnalysis == null) return;

      // Gabung semua sumber: custom FP16 + YOLO INT8 + COCO.
      // YOLO INT8 digabung dulu ke custom (label setara, IoU-dedup),
      // baru hasilnya digabung dengan COCO.
      final customPlusInt8 = mergeNavObstacles(custom, int8);
      final obstacles      = mergeNavObstacles(customPlusInt8, coco);

      _consecutiveFailures = 0;
      _applyOnDeviceResult(zoneAnalysis, obstacles);
      _recordTickDuration(DateTime.now().difference(t0).inMilliseconds);

      // Sengaja TIDAK di-await: konversi mask jadi gambar tidak boleh menunda
      // arahan suara. Kalau frame berikutnya datang lebih dulu, hamparannya
      // yang tertinggal satu frame - bukan peringatannya.
      if (_wantsSegmentationOverlay) {
        unawaited(_updateSegmentationImage(zoneAnalysis));
      }
    } catch (e) {
      debugPrint('[Nav] on-device tick error: $e');
      _handleFailure();
    }
  }

  void _applyOnDeviceResult(ZoneAnalysis zones, List<Detection> obstacles) {
    final wasDown = _phase == NavPhase.degraded || _phase == NavPhase.loadingModels;

    // Saat frame tidak layak jadi dasar arahan, zonanya ditandai TIDAK
    // DIKETAHUI, bukan dibiarkan menampilkan hasil mentahnya.
    //
    // Kalau tidak, suara berkata "jalur belum terbaca" sementara layar
    // menampilkan tiga pita hijau bertuliskan AMAN. Untuk pengguna
    // low-vision atau pendamping awas yang melihat layar, kontradiksi itu
    // menghapus gunanya kedua-duanya: yang mana yang dipercaya?
    final untrusted = zones.isUntrustworthy || _cameraTooDark;
    _left   = untrusted ? ZoneStatus.unknown : zones.left;
    _center = untrusted ? ZoneStatus.unknown : zones.center;
    _right  = untrusted ? ZoneStatus.unknown : zones.right;
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
  /// rintangan peringatan, baru arahan zona. Fungsi ini murni - tidak bicara
  /// dan tidak mengubah state - supaya keputusan "apa yang perlu dikatakan"
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

    // ── Frame tidak layak jadi dasar arahan berjalan ──
    //
    // Diletakkan SESUDAH cabang bahaya dan rintangan, bukan sebelumnya. Kalau
    // ada motor mendekat atau lubang di depan, pengguna tetap harus diberi
    // tahu - terlepas dari apakah jalurnya terbaca dengan yakin. Yang ditahan
    // di sini HANYA klaim positif "jalur aman, jalan lurus", karena itulah
    // satu-satunya kalimat yang menyuruh orang melangkah.
    //
    // Tanpa cabang ini, kamera yang menghadap langit-langit kamar, tembok
    // polos, atau bagian dalam saku tetap menghasilkan "Jalur aman, jalan
    // lurus". PIDNet tidak pernah berkata "saya tidak bisa melihat"; dia
    // memberi label ke setiap piksel apa pun yang masuk, dan sebagian besar
    // permukaan polos jatuh ke kelas walkable.
    final doubtMessage = _doubtMessage(zones);
    if (doubtMessage != null) {
      // Warning, bukan Info: pengguna sedang berjalan dan perlu tahu bahwa
      // panduannya sedang tidak bekerja. Tapi juga bukan Critical - tidak ada
      // bahaya yang terdeteksi, yang hilang cuma penglihatan sistem.
      return (doubtMessage, SpeechTier.warning, false);
    }

    return (zones.ttsMessage, SpeechTier.info, false);
  }

  /// Kalimat untuk kondisi "sistem tidak bisa membaca jalur", atau null kalau
  /// pembacaannya bisa dipercaya.
  ///
  /// Pesannya sengaja INSTRUKTIF, bukan sekadar laporan. "Jalur tidak terbaca"
  /// memberi tahu pengguna bahwa ada yang salah tanpa memberinya satu pun hal
  /// untuk dikerjakan. Yang berguna adalah tindakan konkret: arahkan kamera ke
  /// depan bawah, nyalakan senter, tegakkan ponsel.
  String? _doubtMessage(ZoneAnalysis zones) {
    // Urutannya menentukan. Frame gelap otomatis menghasilkan mask yang aneh,
    // jadi kalau kegelapan dicek belakangan, pengguna akan disuruh membetulkan
    // arah kamera padahal yang kurang cahayanya - tindakan yang salah, dan
    // dia akan mengulanginya sampai menyerah.
    if (_cameraTooDark) {
      return 'Terlalu gelap untuk membaca jalur. Nyalakan senter.';
    }
    if (_cameraMisaimed != null) {
      return '${_cameraMisaimed!}. Jalur belum terbaca.';
    }

    return switch (zones.doubt) {
      SceneDoubt.degenerate =>
        'Jalur belum terbaca. Arahkan kamera ke depan bawah, sekitar dua '
            'langkah di depanmu.',
      SceneDoubt.notGrounded =>
        'Kamera terlalu ke atas. Turunkan sedikit supaya jalur di depan '
            'kakimu terlihat.',
      SceneDoubt.none => null,
    };
  }

  /// Anti-banjir suara. Loop menghasilkan pesan tiap frame; mengucapkan
  /// semuanya akan menutupi suara lalu lintas - hal terakhir yang boleh
  /// terjadi pada orang yang sedang menyeberang.
  ///
  /// Tiga rem, masing-masing menutup lubang yang berbeda:
  ///
  /// 1. **Histeresis.** PIDNet dan YOLO berkedip antar-frame; tanpa ini satu
  ///    kedipan model langsung jadi satu kedipan suara. Info dan Warning
  ///    butuh dua frame berturut-turut dengan pesan yang sama. Critical lewat
  ///    pada kemunculan pertama - menunda peringatan bahaya ~700 ms demi
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
  ///    Geser ke kiri.") butuh ~4 detik pada `speechRate` 0,5 - jauh lebih
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
  /// Penyebabnya sekarang lokal - lensa tertutup, terlalu gelap, model
  /// kehabisan memori - bukan jaringan. Naskahnya ikut berubah: menyalahkan
  /// "sambungan server" untuk masalah yang ada di tangan pengguna hanya
  /// mengirimnya mencari sinyal yang tidak akan menolong.
  void _handleFailure() {
    _consecutiveFailures++;

    // Satu kegagalan bisa jadi hanya satu frame buruk - jangan langsung
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

  /// NV-14a/b - telepon masuk (disimulasikan manual dari panel debug).
  void simulateIncomingCall() {
    _phase = NavPhase.paused;
    _stopLoop();
    notifyListeners();
  }

  void endSimulatedCall() {
    _phase = NavPhase.active;
    // NV-14b - status jalur SEKARANG, bukan yang tadi. Karena itu loop-nya
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
  /// `ZoneIndicator` menampilkan tiga blok berwarna - tidak ada gunanya bagi
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

    // Sebutkan rekomendasinya, bukan hanya keadaannya - pengguna butuh tahu
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

  /// `actionStopWalking` - hentikan panduan tanpa keluar mode.
  /// Mengembalikan false kalau memang tidak ada yang berjalan.
  bool pauseGuidance() {
    if (_phase == NavPhase.paused) return false;
    autoPause();
    return true;
  }

  /// NV-15 - jeda otomatis (berhenti berjalan / ponsel diturunkan).
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
    // Hanya benderanya yang direset. `TFLiteService` sengaja TIDAK di-dispose:
    // ia singleton yang dipakai bersama Mode Deteksi Objek, dan menutupnya di
    // sini akan mematikan deteksi rintangan di mode itu tanpa satu pun tanda.
    _cocoReady     = false;
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
    // `ui.Image` memegang memori di luar heap Dart; pengumpul sampah tidak
    // membersihkannya.
    _disposeSegmentationImage();
    super.dispose();
  }
}
