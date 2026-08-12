import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../core/net/frame_codec.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Cari Objek — bagian 12 IMPLEMENTASI.md, 19 state (CO-01..CO-19).
/// **Sepenuhnya di server** lewat `POST /api/cari-objek`; layar ini hanya
/// memasok frame dan menggambar hasilnya. Karena itu ia benar-benar
/// dinonaktifkan saat offline (CO-14), dengan targetnya disimpan.
class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

enum _Debug { co03, co07, co09, co11, co12, co14, co15, co16, co17, co18, co19 }

extension on _Debug {
  String get id => switch (this) {
        _Debug.co03 => 'CO-03', _Debug.co07 => 'CO-07', _Debug.co09 => 'CO-09',
        _Debug.co11 => 'CO-11', _Debug.co12 => 'CO-12', _Debug.co14 => 'CO-14',
        _Debug.co15 => 'CO-15', _Debug.co16 => 'CO-16', _Debug.co17 => 'CO-17',
        _Debug.co18 => 'CO-18', _Debug.co19 => 'CO-19',
      };
  String get title => switch (this) {
        _Debug.co03 => 'Nama tidak jelas',
        _Debug.co07 => 'Lebih dari satu cocok',
        _Debug.co09 => 'Hilang dari pandangan',
        _Debug.co11 => 'Lama tidak ketemu',
        _Debug.co12 => 'Objek tak dikenali',
        _Debug.co14 => 'Offline (mode dinonaktifkan)',
        _Debug.co15 => 'Izin kamera belum ada',
        _Debug.co16 => 'Senyap / TTS mati',
        _Debug.co17 => 'Font scale 200%',
        _Debug.co18 => 'Server error',
        _Debug.co19 => 'Terlalu gelap',
      };
}

class _FindObjectScreenState extends State<FindObjectScreen> with WidgetsBindingObserver {
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _hasCameraPermission = true;
  _Debug? _debugOverride;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _stt.initialize().then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" — sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.findObject);
      final provider = context.read<FindObjectProvider>();
      provider.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);
      provider.onDirectionHaptic = _fireDirectionHaptic;
      provider.isOffline = () =>
          context.read<GlobalConditionsProvider>().isOffline;
      provider.frameSource = _grabFrame;
      provider.loadKnownTargets();
      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        cam.onFrameReady = (image) => _latestFrame = image;
        cam.startStream();
      }
    });
  }

  /// Status koneksi frame sebelumnya — dipakai mendeteksi transisi
  /// offline→online untuk menepati janji CO-14.
  bool _wasOffline = false;

  /// Frame terakhir dari stream kamera. Disimpan mentah dan baru dikodekan
  /// saat benar-benar akan dikirim — mengodekan tiap frame kamera padahal
  /// hanya sebagian kecil yang terkirim adalah pemborosan CPU dan baterai
  /// yang langsung terasa sebagai panas di tangan pengguna.
  CameraImage? _latestFrame;

  Future<Uint8List?> _grabFrame() async {
    final frame = _latestFrame;
    if (frame == null) return null;
    return FrameCodec.encodeForUpload(
      frame,
      maxEdge: UploadPreset.findObject.maxEdge,
      quality: UploadPreset.findObject.quality,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stt.cancel();
    final provider = context.read<FindObjectProvider>();
    provider.onSpeak = null;
    provider.onDirectionHaptic = null;
    provider.frameSource = null;
    provider.isOffline = null;
    provider.reset();
    final cam = context.read<CameraProvider>();
    cam.onFrameReady = null;
    cam.stopStream();
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
      cam.startStream();
    }
  }

  Future<void> _fireDirectionHaptic(String direction) async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    if (direction == 'kiri') {
      Vibration.vibrate(duration: 60);
    } else if (direction == 'kanan') {
      Vibration.vibrate(pattern: [0, 60, 60, 60]);
    }
  }

  Future<void> _startListening() async {
    final offline = context.read<GlobalConditionsProvider>().isOffline;
    if (offline) return; // CO-14 — mode benar-benar dinonaktifkan
    if (!_sttReady) return;
    setState(() => _debugOverride = null);
    final provider = context.read<FindObjectProvider>();
    provider.startListening();
    await _stt.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final command = CommandParser.parse(result.recognizedWords);
        final target = command.intent == VoiceIntent.findObjectTarget
            ? command.argument
            : result.recognizedWords;
        provider.submitHeardText(result.recognizedWords, parsedTarget: target);
      },
      listenFor: const Duration(seconds: 5),
      localeId: 'id_ID',
      cancelOnError: true,
    );
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
        onSelect: (d) {
          Navigator.pop(sheetCtx);
          setState(() => _debugOverride = d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final fo = context.watch<FindObjectProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // CO-14 — janji "saya coba lagi begitu internet kembali" hanya bernilai
    // kalau benar-benar ditepati tanpa pengguna menyebut ulang barangnya.
    if (_wasOffline && !offline && fo.savedTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<FindObjectProvider>().retrySavedTarget();
      });
    }
    _wasOffline = offline;

    final disabledOffline = offline && _debugOverride != _Debug.co14 ? true : _debugOverride == _Debug.co14;
    final banner = disabledOffline
        ? const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet, Cari Objek tidak tersedia')
        : null;
    final hasBanner = banner != null;
    final hasTarget = _debugOverride == null && fo.target != null && fo.state != FindObjectState.idle;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.findObject, onDebugActivate: _openDebugSheet),
          ),

          if (hasTarget || _debugOverride != null)
            Positioned(
              top: topInset + secondaryChipTopOffset(hasBanner: hasBanner),
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              child: TargetChip(itemName: _debugTarget ?? fo.target ?? ''),
            ),

          if (!_hasCameraPermission || _debugOverride == _Debug.co15)
            // CO-15 — kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mencari dan menunjukkan arah barang yang kamu sebutkan.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (disabledOffline)
            const SizedBox.shrink()
          else
            ..._buildContent(context, fo, bottomInset),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              onMicPressed: _startListening,
              listeningOverride: fo.state == FindObjectState.listening,
            ),
          ),
        ],
      ),
    );
  }

  String? get _debugTarget => switch (_debugOverride) {
        _Debug.co07 => 'kunci motor',
        _Debug.co09 => 'dompet',
        _Debug.co11 => 'ponsel',
        null => null,
        _ => 'barang',
      };

  List<Widget> _buildContent(BuildContext context, FindObjectProvider fo, double bottomInset) {
    if (_debugOverride != null) return _renderDebug(_debugOverride!, bottomInset);

    switch (fo.state) {
      case FindObjectState.idle:
        return [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VoiceOrb(state: VoiceOrbState.idle),
                const SizedBox(height: AppSpacing.s4),
                _pill('Sebutkan barang yang kamu cari'),
              ],
            ),
          ),
        ];
      case FindObjectState.listening:
        return [Center(child: VoiceOrb(state: VoiceOrbState.listening))];
      case FindObjectState.unclear:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s4),
          _pill('Cari apa?'),
        ]))];
      case FindObjectState.targetActive:
      case FindObjectState.scanning:
        return [
          Positioned(
            left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
            bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
            child: AlertCard(
              tier: AlertTier.info,
              title: fo.state == FindObjectState.scanning ? fo.scanMessage : 'Mulai memindai…',
              description: 'Mencari ${fo.target}',
            ),
          ),
        ];
      case FindObjectState.found:
        return [_bottomPanel(bottomInset, _foundCard(fo))];
      case FindObjectState.lostFromView:
        return [_bottomPanel(bottomInset, AlertCard(
          tier: AlertTier.warning,
          title: '${fo.target} sempat hilang dari pandangan',
          description: 'Terakhir terlihat: ${fo.lastKnownPosition}',
        ))];
      case FindObjectState.notFoundInFrame:
        return [_bottomPanel(bottomInset, AlertCard(tier: AlertTier.info, title: fo.notFoundMessage, description: 'Mencari ${fo.target}'))];
      case FindObjectState.longNotFound:
        return [_bottomPanel(bottomInset, AlertCard(
          tier: AlertTier.warning,
          title: 'Belum ketemu di ruangan ini',
          description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.',
        ))];
      case FindObjectState.unknownObject:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Coba sebutkan barang lain.'))];
      case FindObjectState.serverError:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case FindObjectState.tooDark:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
      case FindObjectState.offlineSaved:
        // CO-14 — targetnya disimpan, dan itu dikatakan. Bukan "perintah
        // gagal": perintahnya diterima, hanya pelaksanaannya yang menunggu.
        return [
          _bottomPanel(
            bottomInset,
            AlertCard(
              tier: AlertTier.warning,
              title: 'Cari objek butuh internet',
              description: 'Target ${fo.savedTarget ?? fo.target} disimpan. '
                  'Saya lanjutkan begitu internet kembali.',
            ),
          ),
        ];
    }
  }

  Widget _foundCard(FindObjectProvider fo) {
    final title = fo.matchCount > 1
        ? '${fo.matchCount} ${fo.target} terlihat, yang terdekat di ${fo.direction}'
        : '${fo.target} di ${fo.direction}';
    // CO-08 — panduan bertahap: dekat sekali menyebut "ulurkan tangan".
    final description = fo.distanceMeter < 1 ? 'Sudah sangat dekat, ulurkan tangan' : null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AlertCard(tier: AlertTier.positive, title: title, description: description, distanceMeter: fo.distanceMeter),
        if (fo.matchCount > 1)
          Positioned(
            top: -10, right: 12,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(color: AppColors.actionLabel, borderRadius: AppRadius.pillShape),
                child: Text('+${fo.matchCount - 1} lagi', style: AppTypography.caption(color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(String text) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Text(text, style: AppTypography.body(color: Colors.white)),
      ),
    );
  }

  Widget _bottomPanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }

  List<Widget> _renderDebug(_Debug d, double bottomInset) {
    switch (d) {
      case _Debug.co03:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure), const SizedBox(height: AppSpacing.s4), _pill('Cari apa?'),
        ]))];
      case _Debug.co07:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: '3 kunci motor terlihat, yang terdekat di kiri', distanceMeter: 1.4))];
      case _Debug.co09:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'dompet sempat hilang dari pandangan', description: 'Terakhir terlihat: kanan, sekitar satu meter'))];
      case _Debug.co11:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'Belum ketemu di ruangan ini', description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.'))];
      case _Debug.co12:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Saya bisa mencari dompet, misalnya.'))];
      case _Debug.co14:
        return [];
      case _Debug.co15:
        return [];
      case _Debug.co16:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di kiri', distanceMeter: 1.2, description: 'Senyap aktif — arah lewat getar: 1 ketuk kiri, 2 ketuk kanan'))];
      case _Debug.co17:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di depan', distanceMeter: 1.2))];
      case _Debug.co18:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case _Debug.co19:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
    }
  }
}

class _DebugSheet extends StatelessWidget {
  final _Debug? current;
  final ValueChanged<_Debug?> onSelect;
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
            Text('Debug — Mode Cari Objek', style: AppTypography.title()),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('Kembali ke mode otomatis'), onTap: () => onSelect(null)),
                  for (final d in _Debug.values)
                    ListTile(
                      leading: SizedBox(width: 56, child: Text(d.id, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                      title: Text(d.title),
                      selected: d == current,
                      onTap: () => onSelect(d),
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
