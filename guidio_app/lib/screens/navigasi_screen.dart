import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../models/detection.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Navigasi - bagian 10 IMPLEMENTASI.md, 25 state (NV-01..NV-25).
///
/// **Sepenuhnya on-device**: segmentasi jalur via PIDNet-S TFLite dan deteksi
/// rintangan via YOLO11n TFLite berjalan langsung di HP. Tidak ada upload
/// frame, tidak ada cadangan server - kalau model gagal dimuat, mode ini
/// mengatakannya apa adanya lewat NavPhase.unavailable.
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

/// NV-19 dan NV-20 dihapus dari katalog: keduanya memodelkan kombinasi
/// "on-device mati, server hidup", yang tidak mungkin lagi terjadi karena
/// mode ini tidak punya jalur server sama sekali. Kegagalan model sekarang
/// selalu berarti NV-11 (NavPhase.unavailable).
const List<(String, String)> _nvDebugCatalog = [
  ('NV-14a', 'Telepon masuk'),
  ('NV-16', 'Kamera tertutup'),
  ('NV-21', 'Izin kamera dicabut'),
  ('NV-22', 'Senyap / TTS mati (arah lewat getar)'),
  ('NV-25', 'Sudut kamera bergeser'),
];

/// Berapa lama satu kartu rintangan bertahan di layar setelah objeknya tidak
/// lagi terdeteksi.
///
/// Tanpa penahan ini, kartu terikat langsung pada `nav.obstacles`, yang
/// diganti utuh tiap siklus inferensi (sekitar 700 ms). Satu frame yang
/// meleset - dan deteksi memang berkedip, apalagi pada objek kecil di
/// kejauhan - membuat kartunya lenyap seketika lalu muncul lagi. Yang terlihat
/// pengguna adalah popup yang berkedip terlalu cepat untuk sempat dibaca.
///
/// Masa tahannya ditampilkan sebagai garis yang menyusut di dasar kartu, jadi
/// hilangnya kartu tidak pernah mengejutkan: pendamping awas bisa melihat
/// kartu itu akan pergi sebelum ia benar-benar pergi.
const Duration _kObstacleHold = Duration(milliseconds: 1500);

/// Maksimal kartu rintangan yang boleh tampil sekaligus.
///
/// Tiga, dan tidak lebih. Tumpukan yang lebih tinggi menutupi preview kamera,
/// dan untuk pengguna yang mendengarkan, kartu keempat toh tidak pernah sempat
/// diucapkan sebelum frame berikutnya datang.
const int _kMaxObstacleCards = 3;

/// Identitas satu kartu, diambil dari apa yang BENAR-BENAR dibaca pengguna.
///
/// `DetectionCard` menulis judulnya sebagai `"<labelId> di <arah>"`, jadi
/// itulah yang menentukan dua kartu terlihat kembar atau tidak.
///
/// Memakai `labelEn` di sini pernah menghasilkan duplikat yang kasatmata.
/// Sejak lapis SSD COCO ditambahkan, satu orang yang sama bisa datang dari dua
/// model: YOLO custom melaporkannya sebagai `labelEn: 'orang'`, SSD sebagai
/// `labelEn: 'person'` dengan `labelId: 'orang'`. Penggabung di
/// `nav_obstacle_merger.dart` membuang yang kembar lewat tindih kotak, tapi
/// kalau kedua kotak bentuknya cukup berbeda, keduanya lolos - dan layar
/// menampilkan dua kartu yang huruf demi hurufnya sama persis.
String cardIdentity(Detection d) =>
    '${d.labelId.isEmpty ? d.labelEn : d.labelId}|${d.direction}';

/// Satu kartu yang sedang ditahan di layar.
class _HeldObstacle {
  final Detection detection;
  final DateTime lastSeen;
  const _HeldObstacle(this.detection, this.lastSeen);

  /// Sisa masa tahan, 1,0 saat baru terlihat menuju 0,0 saat kartu pergi.
  double get remaining {
    final gone = DateTime.now().difference(lastSeen).inMilliseconds;
    final total = _kObstacleHold.inMilliseconds;
    return (1.0 - gone / total).clamp(0.0, 1.0);
  }
}

/// Kartu rintangan dengan hitung mundur yang terlihat di dasarnya.
///
/// Garisnya menyusut dari penuh ke kosong selama [_kObstacleHold]. Begitu
/// objeknya terlihat lagi, `lastSeen` berganti, kunci animasinya ikut berganti,
/// dan hitungannya mulai dari penuh lagi - jadi kartu yang objeknya masih ada
/// di depan mata tidak pernah benar-benar habis.
class _ExpiringDetectionCard extends StatelessWidget {
  final _HeldObstacle held;
  const _ExpiringDetectionCard({super.key, required this.held});

  @override
  Widget build(BuildContext context) {
    final tier = AlertTierX.fromDangerLevel(held.detection.dangerLevel);
    final color = switch (tier) {
      AlertTier.critical => AppColors.criticalFill,
      AlertTier.warning => AppColors.warningFill,
      AlertTier.positive => AppColors.positiveFill,
      AlertTier.info => AppColors.actionLabel,
    };

    return Stack(
      children: [
        DetectionCard(detection: held.detection),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 4,
          // Dikecualikan dari pembaca layar: ini penanda visual untuk pendamping
          // awas. Bagi pengguna yang mendengarkan, hitung mundurnya tidak
          // menambah apa pun selain gangguan.
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.sm),
              ),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${cardIdentity(held.detection)}'
                    '|${held.lastSeen.millisecondsSinceEpoch}'),
                tween: Tween(begin: held.remaining, end: 0.0),
                duration: Duration(
                  milliseconds:
                      (_kObstacleHold.inMilliseconds * held.remaining).round(),
                ),
                builder: (_, value, __) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigasiScreenState extends State<NavigasiScreen> with WidgetsBindingObserver {
  final TextEditingController _destCtrl = TextEditingController();
  bool _hasCameraPermission = true;
  String? _debugOverride;
  bool _silentMode = false;

  /// Kartu rintangan yang sedang tampil, dikunci per identitas objek.
  ///
  /// Identitasnya `label|arah`, bukan jarak: jarak bergoyang tiap frame dan
  /// akan membuat objek yang sama dianggap objek baru terus-menerus.
  final Map<String, _HeldObstacle> _heldObstacles = {};
  Timer? _holdSweeper;

  /// Perbarui daftar tahan dari hasil frame terbaru, lalu kembalikan yang
  /// masih layak tampil, terdekat lebih dulu.
  List<_HeldObstacle> _stickyObstacles(List<Detection> fresh) {
    final now = DateTime.now();
    // Objek yang masih terlihat selalu memakai detail TERBARU (jarak, arah,
    // tingkat bahaya), tapi kunci kartunya tetap sama sehingga yang berubah
    // cuma isinya, bukan kartunya. Itulah bedanya dengan mengganti seluruh
    // daftar: kartu tidak pernah dibongkar lalu dipasang lagi.
    for (final d in fresh) {
      _heldObstacles[cardIdentity(d)] = _HeldObstacle(d, now);
    }
    _heldObstacles.removeWhere((_, h) => now.difference(h.lastSeen) > _kObstacleHold);

    final out = _heldObstacles.values.toList()
      ..sort((a, b) => a.detection.distanceMeter.compareTo(b.detection.distanceMeter));
    return out.length <= _kMaxObstacleCards
        ? out
        : out.sublist(0, _kMaxObstacleCards);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.navigasi);

      final nav = context.read<NavigationProvider>();
      nav.onSpeak = (text, tier) {
        // NV-22 - senyap/TTS mati: arah lewat getar, 1 ketuk kiri, 2 ketuk kanan.
        if (_silentMode) {
          // Critical selalu bergetar, apa pun rekomendasinya. Sebelum ini
          // hanya rekomendasi kiri/kanan yang menghasilkan getar, sehingga
          // "Berhenti! Jalur di depan tidak aman" - yang rekomendasinya
          // tengah atau tidak ada sama sekali - lewat tanpa suara DAN tanpa
          // getar. Dibisukan tidak boleh berarti peringatan bahaya hilang.
          if (tier == SpeechTier.critical) {
            _fireCriticalHaptic();
            return;
          }
          final rec = _recommendedZone(nav);
          if (rec == 0) _fireDirectionHaptic(true);
          if (rec == 2) _fireDirectionHaptic(false);
          return;
        }
        context.read<TtsProvider>().speak(text, tier: tier);
      };
      nav.onTakeover = () => context.read<TtsProvider>().interruptByUser();
      // Sumber frame on-device: CameraImage langsung ke PIDNet + YOLO.
      nav.cameraSource = _grabCameraImage;
      // Hamparan jalur baru dihitung saat layar ini benar-benar terlihat.
      // Inferensinya sendiri tetap berjalan tanpa ini - yang menjaga pengguna
      // adalah arahan suaranya, bukan gambarnya.
      nav.wantsSegmentationOverlay = true;
      nav.startCalibration();

      // NV-18 - satu-satunya konfirmasi wajib di seluruh app.
      context.read<AppModeProvider>().confirmLeave = _confirmLeaveNavigasi;

      // Kontrak tombol kiri: perintah suara "jepret" menjalankan hal yang
      // sama persis dengan menekan tombol kiri - di mode ini, membisukan dan
      // menyalakan kembali suara panduan.
      //
      // "Ulangi arahan" tidak hilang, hanya pindah: tetap tersedia lewat
      // perintah suara "ulangi" (`onRepeatLast`).
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _toggleGuidanceVoice;
      voice.primaryActionLabel = () =>
          _silentMode ? 'menyalakan suara panduan' : 'mematikan suara panduan';
      voice.onRepeatLast = nav.repeatGuidance;
      voice.onStopWalking = nav.pauseGuidance;

      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });

    // Tanpa sapuan ini, kartu yang masa tahannya sudah lewat baru hilang saat
    // provider kebetulan memberi tahu lagi. Kalau rintangannya berhenti
    // terdeteksi sama sekali, notifikasi itu bisa tidak pernah datang dan
    // kartunya menggantung di layar selamanya.
    // 250 ms, bukan 500. Dengan masa tahan 1,5 detik, sapuan yang terlalu
    // jarang membuat kartu masih menggantung sampai setengah detik sesudah
    // garis hitung mundurnya habis - dan garis yang berbohong soal kapan
    // kartunya pergi lebih buruk daripada tidak ada garis sama sekali.
    _holdSweeper = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _heldObstacles.isEmpty) return;
      final now = DateTime.now();
      final expired = _heldObstacles.entries
          .where((e) => now.difference(e.value.lastSeen) > _kObstacleHold)
          .map((e) => e.key)
          .toList();
      if (expired.isEmpty) return;
      setState(() => _heldObstacles.removeWhere((k, _) => expired.contains(k)));
    });
  }

  /// Frame terakhir dari stream, dikodekan hanya saat benar-benar dikirim.
  CameraImage? _latestFrame;

  /// Kembalikan CameraImage mentah langsung ke PIDNet + YOLO.
  /// Serahkan frame terakhir ke pipeline navigasi, sekalian mengabarkan
  /// kondisi kameranya.
  ///
  /// Kondisi dikirim DI SINI, bukan dari `build()`, karena mengubah provider
  /// saat membangun widget memicu notifikasi di tengah fase build. Metode ini
  /// dipanggil tepat sekali per siklus inferensi, jadi kondisinya selalu
  /// berasal dari momen yang sama dengan frame yang dianalisis - bukan dari
  /// beberapa frame sebelumnya.
  Future<CameraImage?> _grabCameraImage() async {
    if (!mounted) return _latestFrame;
    final cam = context.read<CameraProvider>();
    context.read<NavigationProvider>().updateCameraCondition(
          tooDark: cam.isDark,
          misaimed: cam.healthMessage,
        );
    return _latestFrame;
  }

  @override
  void dispose() {
    _holdSweeper?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final appMode = context.read<AppModeProvider>();
    if (identical(appMode.confirmLeave, _confirmLeaveNavigasi)) {
      appMode.confirmLeave = null;
    }
    final nav = context.read<NavigationProvider>();
    nav.onSpeak = null;
    nav.onTakeover = null;
    nav.cameraSource = null;
    // Melepas gambar hamparan sekalian: `ui.Image` memegang memori di luar
    // heap Dart dan tidak ikut dibersihkan pengumpul sampah.
    nav.wantsSegmentationOverlay = false;
    nav.stopNavigation();
    context.read<VoiceProvider>().clearModeHandlers();
    final cam = context.read<CameraProvider>();
    cam.onFrameReady = null;
    cam.stopStream();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        await cam.initCamera(preset: CapturePreset.realtime);
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      await cam.initCamera(preset: CapturePreset.realtime);
      cam.onFrameReady = (image) => _latestFrame = image;
      cam.startStream();
    }
  }

  /// NV-18 - satu-satunya konfirmasi wajib di seluruh app.
  ///
  /// **Lembar bawah, bukan dialog tengah layar.** Pengguna sedang berjalan;
  /// menjangkau tombol di tengah layar berarti berhenti dan menyesuaikan
  /// pegangan - dengan satu tangan yang lain memegang tongkat. Tombolnya
  /// karena itu menempel di dasar, mengikuti `zone/page-action`.
  ///
  /// Fokus terkunci di dalam lembar (bawaan `showModalBottomSheet`); setelah
  /// ditutup, fokus kembali ke tombol pemanggilnya, bukan ke atas layar.
  Future<bool> _confirmLeaveNavigasi(AppMode from, AppMode to) async {
    // Hanya fase yang benar-benar SEDANG memandu yang boleh menghadang.
    //
    // Syarat lamanya `phase != paused`, dan itu menjaring tiga fase yang sama
    // sekali bukan "sedang berjalan dituntun": `calibrating` (kartu "Pegang
    // ponsel tegak" masih terbuka, panduan belum pernah mulai),
    // `loadingModels`, dan `unavailable` (model gagal dimuat - justru saat
    // pengguna paling perlu cepat pindah ke Mode Deteksi Objek, dan itu
    // persis mode yang disarankan sendiri oleh pesan kegagalannya).
    //
    // Di ketiga fase itu, siapa pun yang masuk Navigasi karena salah dengar
    // lalu mencoba keluar akan ditahan lembar konfirmasi yang mengklaim dia
    // "masih terdeteksi berjalan" - klaim yang tidak pernah diukur dari apa
    // pun, dan yang tidak bisa dia bantah karena tidak melihat layar.
    final phase = context.read<NavigationProvider>().phase;
    final stillWalking =
        phase == NavPhase.active || phase == NavPhase.degraded;
    if (!stillWalking) return true;

    await context.read<TtsProvider>().speak(
          'Kamu masih terdeteksi berjalan. Berhenti dulu sebelum keluar dari Navigasi.',
          tier: SpeechTier.critical,
        );
    if (!mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.bgPage,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin, AppSpacing.s6, AppSpacing.screenMargin, AppSpacing.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Keluar dari Navigasi?', style: AppTypography.title()),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'Kamu masih terdeteksi berjalan. Berhenti dulu dan pastikan aman sebelum ganti mode.',
                    style: AppTypography.body(color: AppColors.ink2),
                  ),
                ],
              ),
            ),
            // Pilihan aman ("Tetap di Navigasi") jadi tombol utama di dasar:
            // ia yang paling mudah dijangkau, dan ia yang paling sering benar.
            PageActionZone(
              primaryLabel: 'Tetap di Navigasi',
              onPrimary: () => Navigator.pop(ctx, false),
              secondaryLabel: 'Ya, keluar dari Navigasi',
              onSecondary: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _startNav() async {
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) return;
    await context.read<NavigationProvider>().startNavigation(dest);
  }

  /// Tombol kiri BottomActionBar - membisukan / menyalakan suara panduan.
  ///
  /// **Hanya suaranya.** PIDNet dan YOLO tetap berjalan dan indikator zona di
  /// layar tetap hidup, jadi pendamping yang melihat layar tetap terbantu,
  /// dan panduan arah tetap sampai lewat getar (NV-22). Membisukan di sini
  /// bukan mematikan panduan - itu sebabnya loop-nya sengaja tidak disentuh.
  void _toggleGuidanceVoice() {
    final tts = context.read<TtsProvider>();
    if (_silentMode) {
      setState(() => _silentMode = false);
      tts.speak('Suara panduan dinyalakan.', tier: SpeechTier.warning);
      return;
    }
    // Konfirmasinya diucapkan SEBELUM bisu menyala. Kalau urutannya dibalik,
    // kalimat ini ikut tertelan dan pengguna yang tidak melihat layar tidak
    // punya cara tahu tombolnya bekerja.
    tts.speak(
      'Suara panduan dimatikan. Arah tetap terasa lewat getar. '
      'Tekan tombol kiri bawah lagi untuk menyalakan.',
      tier: SpeechTier.warning,
    );
    _fireCriticalHaptic();
    setState(() => _silentMode = true);
  }

  Future<void> _fireCriticalHaptic() async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    Vibration.vibrate(pattern: [0, 400, 120, 400]);
  }

  Future<void> _fireDirectionHaptic(bool left) async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    Vibration.vibrate(pattern: left ? [0, 200] : [0, 80, 60, 80]);
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                  decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
              Text('Debug - Mode Navigasi', style: AppTypography.title()),
              const SizedBox(height: 4),
              Text('NV-01..13,15,17,22..24 tercapai lewat kalibrasi/simulasi/kondisi nyata',
                  textAlign: TextAlign.center, style: AppTypography.caption()),
              const SizedBox(height: AppSpacing.s3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(title: const Text('Kembali (bersihkan override)'), onTap: () {
                      Navigator.pop(sheetCtx);
                      setState(() { _debugOverride = null; _silentMode = false; });
                    }),
                    for (final entry in _nvDebugCatalog)
                      ListTile(
                        leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                        title: Text(entry.$2),
                        selected: entry.$1 == _debugOverride,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _applyDebug(entry.$1);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyDebug(String id) {
    setState(() => _debugOverride = id);
    final nav = context.read<NavigationProvider>();
    switch (id) {
      case 'NV-14a':
        nav.simulateIncomingCall();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) nav.endSimulatedCall();
        });
        break;
      case 'NV-22':
        setState(() => _silentMode = !_silentMode);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final cam = context.watch<CameraProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    final banner = _resolveBanner(context, nav, global, cam);
    final hasBanner = banner != null;
    // Rintangan datang dari server bersama zona, dari frame yang sama.
    // Kartu memakai daftar yang DITAHAN, bukan hasil frame mentah. Hamparan
    // kotak di atas preview tetap memakai `nav.obstacles` yang segar: kotak
    // yang menggantung akan menggambar sesuatu di tempat yang sudah kosong,
    // sementara kartu teks hanya perlu cukup lama untuk sempat dibaca.
    final obstacles = _stickyObstacles(nav.obstacles);
    final hasCriticalObstacle = obstacles.any((h) => h.detection.isCritical);

    if (_debugOverride == 'NV-21') {
      // NV-21 - layar mengambil alih penuh, tidak ada BottomActionBar, jadi
      // aksinya memakai `zone/page-action`. Ini layar yang paling mungkin
      // muncul saat pengguna sedang memegang tongkat: tombol wajib di dasar.
      return const PageActionScaffold(
        primaryLabel: 'Buka pengaturan izin',
        onPrimary: openAppSettings,
        body: Center(
          child: PermissionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Izin kamera dicabut',
            reason: 'Berhenti jalan dulu. Navigasi butuh kamera untuk membaca rintangan dan jalur.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview dan hamparannya dibungkus CameraStage supaya berbagi
          // persegi yang sama persis. Tanpa itu, kotak deteksi memetakan
          // koordinatnya ke seluruh layar sementara gambar kameranya hanya
          // menempati sebagian - dan setiap kotak meleset dari objeknya.
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            CameraStage(
              controller: cam.controller!,
              overlays: [
                if (nav.phase == NavPhase.active || nav.phase == NavPhase.degraded) ...[
                  // Urutan gambar disengaja: segmentasi jalur paling bawah
                  // sebagai konteks permukaan, tint zona di atasnya, lalu
                  // kotak rintangan paling atas supaya tidak pernah tertutup.
                  SegmentationOverlay(image: nav.segmentationImage),
                  _ZoneOverlay(left: nav.left, center: nav.center, right: nav.right),
                  DetectionOverlay(detections: nav.obstacles),
                ],
              ],
            )
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.navigasi, onDebugActivate: _openDebugSheet),
          ),

          if (!_hasCameraPermission)
            // Kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk membaca rintangan dan jalur di depanmu.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (nav.phase == NavPhase.calibrating)
            _calibrationCard(nav)
          else if (nav.phase == NavPhase.loadingModels)
            Positioned(
              top: topInset + AppSizes.modeBadgeHeight + AppSpacing.s4,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: const ZoneIndicator(left: ZoneStatus.unknown, center: ZoneStatus.unknown, right: ZoneStatus.unknown),
            )
          else ...[
            Positioned(
              top: topInset + modeBadgeTopOffset(hasBanner: hasBanner) + AppSizes.modeBadgeHeight + AppSpacing.s3,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: SizedBox(
                height: hasCriticalObstacle ? 40 : 52,
                child: ZoneIndicator(
                  left: nav.left, center: nav.center, right: nav.right,
                  recommended: _recommendedZone(nav),
                ),
              ),
            ),
            Positioned(
              top: topInset + modeBadgeTopOffset(hasBanner: hasBanner) + AppSizes.modeBadgeHeight + AppSpacing.s3 + (hasCriticalObstacle ? 40 : 52) + AppSpacing.s3,
              left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
              child: nav.isNavigating && nav.currentStep != null
                  ? _NavCard(step: nav.currentStep!, onStop: () => context.read<NavigationProvider>().stopNavigation())
                  : _DestInput(ctrl: _destCtrl, onStart: _startNav, favorites: nav.favorites),
            ),
            if (nav.pothole)
              Positioned(
                left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 100,
                child: AlertCard(tier: AlertTier.warning, title: 'Permukaan tidak rata', description: 'Sekitar ${nav.potholeSteps.toStringAsFixed(0)} langkah di depan'),
              ),
            if (obstacles.isNotEmpty)
              Positioned(
                left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
                child: AlertCardStack(
                  cards: obstacles
                      .map((h) => _ExpiringDetectionCard(
                            key: ValueKey(cardIdentity(h.detection)),
                            held: h,
                          ))
                      .toList(),
                ),
              ),

            // Legenda warna hamparan. Muncul hanya saat ada yang digambar,
            // supaya tidak menjanjikan sesuatu yang belum terlihat.
            if (nav.segmentationImage != null)
              Positioned(
                right: AppSpacing.screenMargin,
                bottom: bottomInset +
                    AppSizes.bottomActionBarHeight +
                    AppSpacing.s6 +
                    (obstacles.isNotEmpty ? 100 : 0),
                child: const SegmentationLegend(),
              ),
          ],

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              // Dulu `const BottomActionBar()` - labelnya jatuh ke bawaan
              // "Ambil gambar", tombolnya tampak aktif, dan menekannya tidak
              // melakukan apa pun. Lalu sempat "Ulangi arahan". Sekarang:
              // saklar bisu untuk suara panduan, sesuai kontrak tombol kiri
              // di mode lain (Deteksi Objek memakai pola yang sama).
              cameraLabel: _silentMode ? 'Nyalakan Suara' : 'Matikan Suara',
              onCameraPressed: _toggleGuidanceVoice,
            ),
          ),
        ],
      ),
    );
  }

  int _recommendedZone(NavigationProvider nav) {
    if (nav.center == ZoneStatus.safe) return 1;
    if (nav.left == ZoneStatus.safe) return 0;
    if (nav.right == ZoneStatus.safe) return 2;
    return -1;
  }

  Widget _calibrationCard(NavigationProvider nav) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android_rounded, color: AppColors.onDark, size: 40),
            const SizedBox(height: AppSpacing.s4),
            Text('Pegang ponsel tegak setinggi dada, kamera menghadap depan',
                textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.onDark)),
            const SizedBox(height: AppSpacing.s6),
            FullScreenButton(label: 'Siap, mulai', onTap: nav.finishCalibration),
          ],
        ),
      ),
    );
  }

  Widget? _resolveBanner(BuildContext context, NavigationProvider nav, GlobalConditionsProvider global, CameraProvider cam) {
    if (_debugOverride == 'NV-16' || (cam.healthMessage?.contains('menutupi') ?? false)) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Berhenti, saya tidak bisa melihat');
    }
    if (_debugOverride == 'NV-25' || (cam.healthMessage?.contains('tegak') ?? false)) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Angkat ponsel sedikit');
    }
    if (nav.phase == NavPhase.paused && _debugOverride == 'NV-14a') {
      return const StatusBanner(tier: AlertTier.info, message: 'Panggilan masuk, peringatan pindah ke getar');
    }
    // NV-11 - mode ini sepenuhnya on-device. Kalau modelnya tidak bisa
    // dipakai atau frame tidak terbaca, tidak ada cadangan apa pun: bannernya
    // Critical dan menyuruh berhenti, bukan Warning yang menjanjikan sisa
    // fungsi yang sebenarnya tidak ada.
    if (nav.phase == NavPhase.unavailable) {
      return const StatusBanner(
        tier: AlertTier.critical,
        message: 'Berhenti jalan dulu, jalur tidak terbaca',
      );
    }
    if (nav.phase == NavPhase.degraded) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Jalur sulit dibaca, arahan mungkin tertinggal');
    }
    if (nav.left == ZoneStatus.danger && nav.center == ZoneStatus.danger && nav.right == ZoneStatus.danger) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Tidak ada jalur aman, berhenti dulu');
    }
    if (nav.center == ZoneStatus.danger) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Berhenti! Jalur kendaraan di depan');
    }
    final merged = global.merged;
    if (merged != null) {
      return StatusBanner(tier: merged.tier, message: merged.message, actionLabel: merged.actionLabel);
    }
    return null;
  }
}

class _ZoneOverlay extends StatelessWidget {
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;
  const _ZoneOverlay({required this.left, required this.center, required this.right});

  Color _color(ZoneStatus s) => switch (s) {
        ZoneStatus.safe => AppColors.positiveFill,
        ZoneStatus.caution => AppColors.warningFill,
        ZoneStatus.danger => AppColors.criticalFill,
        ZoneStatus.unknown => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.16,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: _color(left))),
          Expanded(child: ColoredBox(color: _color(center))),
          Expanded(child: ColoredBox(color: _color(right))),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final NavigationStep step;
  final VoidCallback onStop;
  const _NavCard({required this.step, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: step.instruction,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_rounded, color: AppColors.actionLabel, size: 28),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(step.instruction, style: AppTypography.bodyStrong())),
            Semantics(
              button: true,
              label: 'Hentikan navigasi',
              child: IconButton(icon: const Icon(Icons.close, color: AppColors.ink2), onPressed: onStop),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestInput extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onStart;
  final Map<String, String> favorites;
  const _DestInput({required this.ctrl, required this.onStart, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: AppTypography.body(),
                  decoration: InputDecoration(
                    hintText: 'Mau ke mana? (opsional)',
                    hintStyle: AppTypography.body(color: AppColors.ink2),
                    prefixIcon: const Icon(Icons.search, color: AppColors.ink2),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Semantics(
                button: true,
                label: 'Mulai navigasi',
                child: GestureDetector(
                  onTap: onStart,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: const BoxDecoration(color: AppColors.actionLabel, borderRadius: AppRadius.pillShape),
                    child: Center(child: Text('Mulai', style: AppTypography.label(color: AppColors.onDark))),
                  ),
                ),
              ),
            ],
          ),
          if (favorites.isNotEmpty) ...[
            const Divider(height: AppSpacing.s6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('FAVORIT', style: AppTypography.eyebrow()),
            ),
            const SizedBox(height: AppSpacing.s2),
            ...favorites.entries.map(
              (e) => Semantics(
                button: true,
                label: 'Navigasi ke ${e.key}',
                child: InkWell(
                  onTap: () {
                    ctrl.text = e.key;
                    onStart();
                  },
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warningFill, size: 20),
                        const SizedBox(width: AppSpacing.s3),
                        Text(e.key, style: AppTypography.body()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
