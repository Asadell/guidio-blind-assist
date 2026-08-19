import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../core/speech/tts_queue.dart';
import '../models/detection.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Deteksi Objek — bagian 7 IMPLEMENTASI.md, 29 state (DO-01..DO-29).
/// Kamera, TFLite/server, filter kestabilan, dan SORT tracker SUDAH nyata
/// lewat [DetectionProvider]. State yang tak bisa dipicu dari kondisi nyata
/// (multi-objek serentak, kelas tak dikenal, dst.) dicapai lewat panel debug
/// (ketuk 5× ModeBadge), sesuai bagian 2 "boleh dipalsukan".
class TuntunScreen extends StatefulWidget {
  const TuntunScreen({super.key});

  @override
  State<TuntunScreen> createState() => _TuntunScreenState();
}

class _GhostDetection {
  final Detection detection;
  _GhostDetection(this.detection);
}

const List<(String, String)> _doDebugCatalog = [
  ('DO-06', 'Deteksi ganda (critical + warning)'),
  ('DO-07', 'Empat objek sekaligus'),
  ('DO-13', 'Model warm-up'),
  ('DO-15', 'Izin kamera dicabut saat jalan'),
  ('DO-19', 'Kelas objek tidak dikenal'),
  ('DO-20', 'Objek critical menghilang (fade)'),
  ('DO-21', 'Jarak tidak bisa diperkirakan'),
  ('DO-22', 'Ponsel panas'),
  ('DO-23', 'Antrean suara menumpuk'),
  ('DO-24', 'Izin mikrofon dicabut'),
  ('DO-25', 'Penyimpanan penuh'),
  ('DO-26', 'Senyap / TTS mati'),
  ('DO-29', 'Verbositas lengkap (3 pemakaian pertama)'),
];

class _TuntunScreenState extends State<TuntunScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = true;
  bool _hasMicPermission = true;
  bool _warmingUp = true;
  bool _speaking = false;
  bool _silentMode = false;
  // Keadaan gelap & dismiss-nya dimiliki CameraProvider (lihat
  // `cam.isDark` / `cam.darkDismissed`), supaya deteksi tetap berjalan saat
  // gelap dan "Lewati" hanya menyembunyikan tawaran lampu.
  String? _debugOverride;

  /// Apakah deteksi objek sedang aktif (jalan) atau dijeda.
  /// Dimulai true — deteksi langsung jalan saat mode dibuka.
  bool _detectionActive = true;

  final List<_GhostDetection> _ghosts = [];
  List<Detection> _prevCritical = [];

  Timer? _warmupTimer;
  Timer? _speakingPoll;

  /// DO — pengingat berkala saat deteksi dijeda.
  ///
  /// Tanpa ini, "Deteksi dijeda." terucap sekali lalu hening permanen. Untuk
  /// pengguna yang tidak melihat layar, aplikasi yang dijeda **tidak bisa
  /// dibedakan** dari aplikasi yang aktif tapi kebetulan tidak melihat apa
  /// pun — dan ia berjalan menyangka masih dijaga.
  Timer? _pausedReminder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.tuntun);
      if (_hasCameraPermission) {
        _startDetection();
        context.read<CameraProvider>().startStream();
      }
      // Listener dark detection — TTS satu kali saat transisi gelap
      context.read<CameraProvider>().addListener(_onCameraDarkChanged);

      // Kontrak tombol kiri: perintah suara "jepret" menjalankan hal yang
      // sama persis dengan menekan tombol kiri.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _toggleDetection;
      voice.primaryActionLabel = () =>
          _detectionActive ? 'menjeda deteksi' : 'melanjutkan deteksi';
      voice.onRepeatLast = _repeatLastDetection;

      // Model gagal muat = mode ini tidak punya cadangan apa pun. Katakan,
      // jangan biarkan layar terlihat normal sementara tidak ada yang mengawasi.
      if (context.read<DetectionProvider>().isUnavailable) {
        TtsQueue().speak(
          'Deteksi rintangan tidak tersedia di perangkat ini. '
          'Mode lain tetap bisa dipakai.',
          tier: SpeechTier.critical,
        );
      }
    });

    _warmupTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _warmingUp = false);
    });

    _speakingPoll = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final s = TTSService.instance.isSpeaking;
      if (s != _speaking && mounted) setState(() => _speaking = s);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _warmupTimer?.cancel();
    _speakingPoll?.cancel();
    _pausedReminder?.cancel();
    context.read<CameraProvider>().removeListener(_onCameraDarkChanged);
    context.read<DetectionProvider>().stopRealtime();
    context.read<CameraProvider>().stopStream();
    context.read<VoiceProvider>().clearModeHandlers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // DO-18 — kembali dari latar belakang.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      if (mounted) {
        setState(() => _warmingUp = true);
        context.read<CameraProvider>().startStream();
        // Hormati keadaan jeda. Sebelumnya `startRealtime()` dipanggil tanpa
        // memeriksa apa pun, jadi deteksi hidup lagi diam-diam sementara
        // tombol tetap bertuliskan "Lanjutkan" — label dan keadaan berbohong
        // ke arah yang berlawanan.
        if (_detectionActive) {
          _startDetection();
        } else {
          _armPausedReminder();
        }
        _warmupTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _warmingUp = false);
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // Jangan bicara ke layar yang tidak dilihat siapa pun.
      _pausedReminder?.cancel();
    }
  }

  Future<void> _checkPermissions() async {
    final cam = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    if (!mounted) return;
    final camChanged = cam != _hasCameraPermission;
    setState(() {
      _hasCameraPermission = cam;
      _hasMicPermission = mic;
    });
    if (camChanged && cam) {
      final camProvider = context.read<CameraProvider>();
      if (!camProvider.isInitialized) await camProvider.initCamera();
      if (!mounted) return;
      camProvider.startStream();
      if (_detectionActive) _startDetection();
    }
  }

  /// "ulangi" di Mode Deteksi — sebutkan lagi apa yang terlihat sekarang.
  void _repeatLastDetection() {
    final det = context.read<DetectionProvider>();
    if (!_detectionActive) {
      TtsQueue().speak('Deteksi sedang dijeda.', tier: SpeechTier.info);
      return;
    }
    final dets = det.detections;
    TtsQueue().speak(
      dets.isEmpty
          ? 'Tidak ada rintangan di depanmu saat ini.'
          : dets.map((d) => d.ttsMessage).join('. '),
      tier: SpeechTier.warning,
    );
  }

  void _startDetection() {
    _pausedReminder?.cancel();
    _pausedReminder = null;
    context.read<DetectionProvider>().startRealtime();
  }

  /// Ingatkan tiap 30 detik selama dijeda — suara + getar, karena di jalan
  /// yang ramai getar sering lebih terdengar daripada suara.
  void _armPausedReminder() {
    _pausedReminder?.cancel();
    _pausedReminder = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _detectionActive) return;
      TtsQueue().speak('Deteksi masih dijeda.', tier: SpeechTier.info);
      HapticService.instance.info();
    });
  }

  /// Dipanggil setiap kali CameraProvider notify.
  ///
  /// Pengumuman gelap **tidak** lagi diucapkan di sini: [CameraProvider] yang
  /// memilikinya (peringatan setelah 3 detik + pengulangan tiap 30 detik),
  /// karena kondisi itu berlaku di semua mode berkamera, bukan hanya mode ini.
  /// Dua sumber untuk satu kondisi hanya menghasilkan ucapan ganda.
  void _onCameraDarkChanged() {
    if (!mounted) return;
    setState(() {}); // slot tawaran lampu muncul/hilang mengikuti provider
  }

  /// Toggle deteksi ON/OFF dari tombol kiri BottomActionBar.
  ///
  /// Menjeda deteksi adalah satu-satunya cara pengguna mematikan pengawasan
  /// rintangan, jadi konfirmasinya naik ke tier Warning: ia harus terdengar
  /// meski ada narasi lain yang sedang mengantre.
  void _toggleDetection() {
    final det = context.read<DetectionProvider>();
    if (_detectionActive) {
      det.stopRealtime();
      setState(() => _detectionActive = false);
      TtsQueue().speak(
        'Deteksi dijeda. Saya tidak akan memperingatkan rintangan sampai dilanjutkan.',
        tier: SpeechTier.warning,
      );
      HapticService.instance.warning();
      _armPausedReminder();
    } else {
      _startDetection();
      setState(() => _detectionActive = true);
      TtsQueue().speak('Deteksi dilanjutkan.', tier: SpeechTier.warning);
      HapticService.instance.info();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      if (!cam.isInitialized) await cam.initCamera();
      if (!mounted) return;
      cam.startStream();
      if (_detectionActive) _startDetection();
    }
  }

  void _updateGhosts(List<Detection> current) {
    final currentCritical = current.where((d) => d.isCritical).toList();
    for (final prev in _prevCritical) {
      final stillThere = currentCritical.any((d) => d.labelEn == prev.labelEn && d.direction == prev.direction);
      final alreadyGhost = _ghosts.any((g) => g.detection.labelEn == prev.labelEn && g.detection.direction == prev.direction);
      if (!stillThere && !alreadyGhost) {
        final ghost = _GhostDetection(prev);
        _ghosts.add(ghost);
        // DO-20 — memudar tanpa suara "objek hilang", dibersihkan setelah animasi.
        Timer(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _ghosts.remove(ghost));
        });
      }
    }
    _prevCritical = currentCritical;
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugSheet(
        current: _debugOverride,
        onSelect: (id) {
          Navigator.pop(sheetCtx);
          setState(() {
            _debugOverride = id;
            _silentMode = id == 'DO-26';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final det = context.watch<DetectionProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    var dets = det.detections;
    if (_debugOverride == 'DO-06') dets = _mockDouble;
    if (_debugOverride == 'DO-07') dets = _mockQuad;
    if (_debugOverride == 'DO-19') dets = _mockUnknownClass;
    if (_debugOverride != 'DO-06' && _debugOverride != 'DO-07' && _debugOverride != 'DO-19') {
      _updateGhosts(dets);
    }

    // Tawaran lampu. Perhatikan: ini HANYA mengatur tampil/tidaknya slot —
    // deteksi tetap berjalan saat gelap, dan "Lewati" tidak mematikannya.
    final isDark = cam.isDark && !cam.isTorchOn && !cam.darkDismissed && _hasCameraPermission;

    final banner = _resolveBanner(global, cam);
    final hasBanner = banner != null;
    final warmingUp = _warmingUp || _debugOverride == 'DO-13';
    final micDisabled = !_hasMicPermission || _debugOverride == 'DO-24';

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.tuntun, busy: warmingUp, onDebugActivate: _openDebugSheet),
          ),

          if (_speaking && !warmingUp)
            Positioned(
              top: topInset + 52,
              right: 24,
              child: SpeakingIndicator(silent: _silentMode),
            ),

          if (!_hasCameraPermission)
            // DO-14 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mendeteksi rintangan di depanmu tanpa internet.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestCameraPermission,
            )
          else if (!warmingUp)
            ..._buildDetectionZone(context, bottomInset, dets, cam, isDark),

          // ContextualActionSlot — tawaran nyalakan lampu saat gelap.
          // Selalu di posisi yang sama: tepat di atas BottomActionBar.
          if (isDark)
            Positioned(
              left: 0, right: 0,
              bottom: bottomInset + AppSizes.bottomActionBarHeight,
              child: ContextualActionSlot(
                message: 'Sekitar gelap — perlu nyalakan lampu?',
                primaryLabel: 'Nyalakan Lampu',
                primaryIcon: Icons.flashlight_on_rounded,
                onPrimary: () {
                  cam.setTorch(true);
                  TtsQueue().speak('Lampu dinyalakan.', tier: SpeechTier.info);
                },
                secondaryLabel: 'Lewati',
                secondaryIcon: Icons.close_rounded,
                onSecondary: () {
                  // Hanya menyembunyikan tawaran. Deteksi tetap jalan, dan
                  // peringatan gelap berkala tetap terdengar — pengguna berhak
                  // tahu penglihatan aplikasi sedang terbatas.
                  cam.dismissDarkOffer();
                  TtsQueue().speak(
                    'Baik, lampu tidak dinyalakan. Deteksi tetap berjalan.',
                    tier: SpeechTier.info,
                  );
                },
              ),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              micEnabled: !micDisabled,
              cameraLabel: _detectionActive ? 'Hentikan' : 'Lanjutkan',
              onCameraPressed: _hasCameraPermission ? _toggleDetection : null,
              cameraEnabled: _hasCameraPermission,
              cameraDisabledReason: 'izin kamera belum diberikan',
            ),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(GlobalConditionsProvider global, CameraProvider cam) {
    if (_debugOverride == 'DO-15') {
      return const StatusBanner(tier: AlertTier.critical, message: 'Izin kamera dicabut. Deteksi berhenti sampai izin dinyalakan lagi.');
    }
    if (_debugOverride == 'DO-22') {
      return const StatusBanner(tier: AlertTier.warning, message: 'Ponsel panas, laju deteksi diturunkan');
    }
    if (_debugOverride == 'DO-25') {
      return const StatusBanner(tier: AlertTier.warning, message: 'Penyimpanan hampir penuh, deteksi tetap jalan');
    }
    if (_debugOverride == 'DO-23') {
      return const StatusBanner(tier: AlertTier.info, message: 'Antrean suara menumpuk, info dibuang');
    }
    final merged = global.merged;
    if (merged != null) {
      return StatusBanner(tier: merged.tier, message: merged.message, actionLabel: merged.actionLabel);
    }
    return null;
  }

  List<Widget> _buildDetectionZone(BuildContext context, double bottomInset, List<Detection> dets, CameraProvider cam, bool isDark) {
    final widgets = <Widget>[];
    // Jika slot lampu aktif, geser semua kartu ke atas sejumlah tinggi slot.
    final slotExtra = isDark ? ContextualActionSlot.slotHeightWithMsg : 0.0;

    if (_debugOverride == 'DO-21') {
      widgets.add(_bottomSlot(bottomInset, const AlertCard(
        tier: AlertTier.info,
        title: 'Ada objek di depan',
        description: 'Jarak tidak bisa diperkirakan, tetap waspada',
      )));
      return widgets;
    }

    final health = cam.healthMessage;
    if (health != null && dets.isEmpty && _debugOverride == null) {
      widgets.add(Positioned(
        left: 0, right: 0,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 44 + slotExtra,
        child: Center(child: CameraHealthToast(issue: _mapHealthIssue(health))),
      ));
    }

    final cards = dets.map((d) => DetectionCard(detection: d)).toList();
    final extra = dets.length - 2;

    if (cards.isNotEmpty || _ghosts.isNotEmpty) {
      widgets.add(Positioned(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2 + slotExtra,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in _ghosts) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 900),
                builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
                child: DetectionCard(detection: g.detection),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            if (cards.isNotEmpty) AlertCardStack(cards: cards),
            if (extra > 0) ...[
              const SizedBox(height: AppSpacing.s2),
              Semantics(
                liveRegion: true,
                label: 'dan $extra objek lain',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
                  child: Text('dan $extra objek lain', style: AppTypography.caption(color: AppColors.onDark)),
                ),
              ),
            ],
          ],
        ),
      ));
    }

    return widgets;
  }

  CameraHealthIssue _mapHealthIssue(String message) {
    if (message.contains('gelap')) return CameraHealthIssue.dark;
    if (message.contains('menutupi')) return CameraHealthIssue.covered;
    if (message.contains('tegak') || message.contains('depan')) return CameraHealthIssue.tilted;
    return CameraHealthIssue.blurry;
  }

  Widget _bottomSlot(double bottomInset, Widget child) => Positioned(
        left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
        bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
        child: child,
      );

  static final _mockDouble = [
    const Detection(labelEn: 'person', labelId: 'orang', confidence: .9, distanceMeter: .8, direction: 'depan', dangerLevel: 'critical', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'motorcycle', labelId: 'motor', confidence: .8, distanceMeter: 1.6, direction: 'kanan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
  ];

  static final _mockQuad = [
    const Detection(labelEn: 'person', labelId: 'orang', confidence: .9, distanceMeter: .7, direction: 'depan', dangerLevel: 'critical', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'motorcycle', labelId: 'motor', confidence: .8, distanceMeter: 1.4, direction: 'kanan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'chair', labelId: 'kursi', confidence: .7, distanceMeter: 2.3, direction: 'kiri', dangerLevel: 'info', bbox: {}, inferenceMs: 12),
    const Detection(labelEn: 'bicycle', labelId: 'sepeda', confidence: .6, distanceMeter: 3.1, direction: 'depan', dangerLevel: 'info', bbox: {}, inferenceMs: 12),
  ];

  static final _mockUnknownClass = [
    const Detection(labelEn: 'unknown', labelId: '', confidence: .6, distanceMeter: 1.8, direction: 'depan', dangerLevel: 'warning', bbox: {}, inferenceMs: 12),
  ];
}

class _DebugSheet extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onSelect;
  const _DebugSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 34, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(color: AppColors.surfaceSunk, borderRadius: BorderRadius.circular(2))),
            Text('Debug — Mode Deteksi Objek', style: AppTypography.title()),
            const SizedBox(height: 4),
            Text('DO-01..05,08..12,14,16..18,27,28 sudah tercapai lewat kamera/izin/koneksi nyata',
                textAlign: TextAlign.center, style: AppTypography.caption()),
            const SizedBox(height: AppSpacing.s3),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('Kembali ke mode nyata'), onTap: () => onSelect(null)),
                  for (final entry in _doDebugCatalog)
                    ListTile(
                      leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                      title: Text(entry.$2),
                      selected: entry.$1 == current,
                      onTap: () => onSelect(entry.$1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
