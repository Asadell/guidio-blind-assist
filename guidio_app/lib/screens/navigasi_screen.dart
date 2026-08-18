import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../core/net/frame_codec.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Navigasi — bagian 10 IMPLEMENTASI.md, 25 state (NV-01..NV-25).
///
/// **On-device secara default**: segmentasi jalur via PIDNet-S TFLite dan
/// deteksi rintangan via YOLO11n TFLite berjalan langsung di HP tanpa upload
/// ke server. Server hanya dipakai jika model gagal dimuat (offline-fallback).
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

/// NV-19 dan NV-20 dihapus dari katalog: keduanya memodelkan kombinasi
/// "on-device mati, server hidup" yang tidak mungkin lagi terjadi sejak
/// rintangan dan jalur sama-sama dibaca server. Kegagalan server sekarang
/// selalu berarti NV-11.
const List<(String, String)> _nvDebugCatalog = [
  ('NV-14a', 'Telepon masuk'),
  ('NV-16', 'Kamera tertutup'),
  ('NV-21', 'Izin kamera dicabut'),
  ('NV-22', 'Senyap / TTS mati (arah lewat getar)'),
  ('NV-25', 'Sudut kamera bergeser'),
];

class _NavigasiScreenState extends State<NavigasiScreen> with WidgetsBindingObserver {
  final TextEditingController _destCtrl = TextEditingController();
  bool _hasCameraPermission = true;
  String? _debugOverride;
  bool _silentMode = false;

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
        // NV-22 — senyap/TTS mati: arah lewat getar, 1 ketuk kiri, 2 ketuk kanan.
        if (_silentMode) {
          final rec = _recommendedZone(nav);
          if (rec == 0) _fireDirectionHaptic(true);
          if (rec == 2) _fireDirectionHaptic(false);
          return;
        }
        context.read<TtsProvider>().speak(text, tier: tier);
      };
      nav.onTakeover = () => context.read<TtsProvider>().interruptByUser();
      // Server JPEG source (dipakai jika on-device gagal / dinonaktifkan)
      nav.frameSource = _grabFrame;
      // On-device source: CameraImage langsung ke PIDNet + YOLO
      nav.cameraSource = _grabCameraImage;
      nav.startCalibration();

      // NV-18 — satu-satunya konfirmasi wajib di seluruh app.
      context.read<AppModeProvider>().confirmLeave = _confirmLeaveNavigasi;

      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Frame terakhir dari stream, dikodekan hanya saat benar-benar dikirim.
  CameraImage? _latestFrame;

  /// [Server mode] Encode ke JPEG untuk upload.
  Future<Uint8List?> _grabFrame() async {
    final frame = _latestFrame;
    if (frame == null) return null;
    return FrameCodec.encodeForUpload(
      frame,
      maxEdge: UploadPreset.navigation.maxEdge,
      quality: UploadPreset.navigation.quality,
    );
  }

  /// [On-device mode] Kembalikan CameraImage mentah langsung ke PIDNet + YOLO.
  Future<CameraImage?> _grabCameraImage() async => _latestFrame;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final appMode = context.read<AppModeProvider>();
    if (identical(appMode.confirmLeave, _confirmLeaveNavigasi)) {
      appMode.confirmLeave = null;
    }
    final nav = context.read<NavigationProvider>();
    nav.onSpeak = null;
    nav.onTakeover = null;
    nav.frameSource = null;
    nav.cameraSource = null;  // on-device source
    nav.stopNavigation();
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
        if (!cam.isInitialized) await cam.initCamera();
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
      if (!cam.isInitialized) await cam.initCamera();
      cam.onFrameReady = (image) => _latestFrame = image;
      cam.startStream();
    }
  }

  /// NV-18 — satu-satunya konfirmasi wajib di seluruh app.
  ///
  /// **Lembar bawah, bukan dialog tengah layar.** Pengguna sedang berjalan;
  /// menjangkau tombol di tengah layar berarti berhenti dan menyesuaikan
  /// pegangan — dengan satu tangan yang lain memegang tongkat. Tombolnya
  /// karena itu menempel di dasar, mengikuti `zone/page-action`.
  ///
  /// Fokus terkunci di dalam lembar (bawaan `showModalBottomSheet`); setelah
  /// ditutup, fokus kembali ke tombol pemanggilnya, bukan ke atas layar.
  Future<bool> _confirmLeaveNavigasi(AppMode from, AppMode to) async {
    final stillWalking = context.read<NavigationProvider>().phase != NavPhase.paused;
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
              Text('Debug — Mode Navigasi', style: AppTypography.title()),
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
    final obstacles = nav.obstacles;
    final hasCriticalObstacle = obstacles.any((d) => d.isCritical);

    if (_debugOverride == 'NV-21') {
      // NV-21 — layar mengambil alih penuh, tidak ada BottomActionBar, jadi
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (nav.phase == NavPhase.active || nav.phase == NavPhase.serverWeak)
            Positioned.fill(child: ExcludeSemantics(child: _ZoneOverlay(left: nav.left, center: nav.center, right: nav.right))),

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
          else if (nav.phase == NavPhase.waitingServer)
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
                child: AlertCardStack(cards: obstacles.map((d) => DetectionCard(detection: d)).toList()),
              ),
          ],

          const Positioned(left: 0, right: 0, bottom: 0, child: BottomActionBar()),
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
            const Icon(Icons.phone_android_rounded, color: Colors.white, size: 40),
            const SizedBox(height: AppSpacing.s4),
            Text('Pegang ponsel tegak setinggi dada, kamera menghadap depan',
                textAlign: TextAlign.center, style: AppTypography.body(color: Colors.white)),
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
    // NV-11 — sejak segmentasi jalur DAN deteksi rintangan sama-sama di
    // server, "mode terbatas" tidak ada lagi: kalau server tidak terjangkau,
    // mode ini benar-benar tidak melihat apa pun. Bannernya Critical dan
    // menyuruh berhenti, bukan Warning yang menjanjikan sisa fungsi.
    if (nav.phase == NavPhase.serverDown) {
      return const StatusBanner(
        tier: AlertTier.critical,
        message: 'Berhenti jalan dulu, jalur tidak terbaca',
      );
    }
    if (nav.phase == NavPhase.serverWeak) {
      return const StatusBanner(tier: AlertTier.info, message: 'Sinyal lemah, arahan jalur mungkin tertinggal');
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
                    child: Center(child: Text('Mulai', style: AppTypography.label(color: Colors.white))),
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
