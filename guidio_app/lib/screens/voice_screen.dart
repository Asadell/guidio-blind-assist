import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../core/voice/intents.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

const List<(String, String)> _asDebugCatalog = [
  ('AS-05', 'Terlalu berisik'),
  ('AS-07', 'Transkrip gagal'),
  ('AS-13', 'Delapan giliran (riwayat diringkas)'),
  ('AS-16', 'Offline'),
  ('AS-21', 'Senyap / TTS mati'),
  ('AS-23', 'Riwayat kedaluwarsa'),
  ('AS-24', 'Izin kamera dicabut'),
  ('AS-25', 'Critical menyela jawaban'),
];

/// Mode Asisten Suara — bagian 11 IMPLEMENTASI.md, 25 state (AS-01..AS-25).
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with WidgetsBindingObserver {
  bool _hasMicPermission = true;
  bool _hasCameraPermission = true;
  String? _debugOverride;
  bool _silentMode = false;
  bool _longAnswerOffer = false;
  Timer? _longAnswerTimer;
  Timer? _expiryCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppModeProvider>().announceEntry(AppMode.voice);
      final voice = context.read<VoiceProvider>();

      if (voice.checkAndExpireHistory()) {
        // AS-23 — riwayat kedaluwarsa, sudah dibersihkan oleh provider.
        context.read<TtsProvider>().speak('Percakapan tadi sudah saya hapus.', tier: SpeechTier.info);
      }

      voice.onSpeak = (text) => context.read<TtsProvider>().speak(text, tier: SpeechTier.info);
      voice.onModeChangeRequested = _handleModeChange;
      voice.onAllFeaturesFailed = () {};
    });

    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _longAnswerTimer?.cancel();
    _expiryCheckTimer?.cancel();
    final voice = context.read<VoiceProvider>();
    voice.onSpeak = null;
    voice.onModeChangeRequested = null;
    voice.onAllFeaturesFailed = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.isGranted;
    final cam = await Permission.camera.isGranted;
    if (!mounted) return;
    setState(() {
      _hasMicPermission = mic;
      _hasCameraPermission = cam;
    });
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (status.isGranted) setState(() => _hasMicPermission = true);
  }

  void _handleModeChange(VoiceIntent intent) {
    final mode = switch (intent) {
      VoiceIntent.modeMoney => AppMode.money,
      VoiceIntent.modeReadText => AppMode.ocr,
      VoiceIntent.modeDetection => AppMode.tuntun,
      VoiceIntent.modeNavigation => AppMode.navigasi,
      VoiceIntent.modeFindObject => AppMode.findObject,
      _ => null,
    };
    if (mode == null) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.read<AppModeProvider>().setMode(mode);
    });
  }

  Future<void> _onMicPressed() async {
    final voice = context.read<VoiceProvider>();
    setState(() => _debugOverride = null);
    if (voice.isListening) {
      await voice.stopListening();
    } else if (voice.state == VoiceState.responded) {
      // AS-20 — menekan lagi saat masih bicara: potong tanpa nada khusus.
      await voice.interruptAndListenAgain();
    } else {
      await voice.startListening();
    }
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
              Text('Debug — Mode Asisten Suara', style: AppTypography.title()),
              const SizedBox(height: 4),
              Text('AS-01..04,06,08..12,14,15,17..20,22 tercapai lewat alur bicara nyata',
                  textAlign: TextAlign.center, style: AppTypography.caption()),
              const SizedBox(height: AppSpacing.s3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(title: const Text('Kembali'), onTap: () {
                      Navigator.pop(sheetCtx);
                      setState(() { _debugOverride = null; _silentMode = false; });
                    }),
                    for (final entry in _asDebugCatalog)
                      ListTile(
                        leading: SizedBox(width: 56, child: Text(entry.$1, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                        title: Text(entry.$2),
                        selected: entry.$1 == _debugOverride,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          setState(() {
                            _debugOverride = entry.$1;
                            _silentMode = entry.$1 == 'AS-21';
                          });
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

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final cam = context.watch<CameraProvider>();
    final det = context.watch<DetectionProvider>();
    final global = context.watch<GlobalConditionsProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // AS-25 — Critical dari mode lain menyela jawaban yang sedang dibacakan.
    if (voice.state == VoiceState.responded && det.detections.any((d) => d.isCritical) && !_hasCameraPermission == false) {
      final critical = det.detections.firstWhere((d) => d.isCritical);
      context.read<TtsProvider>().speak(critical.ttsMessage, tier: SpeechTier.critical);
    }

    if (voice.state == VoiceState.responded && !_longAnswerOffer && voice.response.length > 220) {
      _longAnswerTimer?.cancel();
      _longAnswerTimer = Timer(const Duration(seconds: 20), () {
        if (mounted && voice.state == VoiceState.responded) setState(() => _longAnswerOffer = true);
      });
    }
    if (voice.state != VoiceState.responded && _longAnswerOffer) {
      _longAnswerOffer = false;
    }

    final banner = _resolveBanner(global);
    final hasBanner = banner != null;

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
            child: ModeBadge(mode: AppMode.voice, onDebugActivate: _openDebugSheet),
          ),

          if (voice.state == VoiceState.responded && !_silentMode)
            Positioned(top: topInset + 52, right: 24, child: const SpeakingIndicator()),

          if (!_hasMicPermission && _debugOverride == null)
            Center(
              child: PermissionCard(
                icon: Icons.mic_none_rounded,
                title: 'Izin mikrofon',
                reason: 'Mikrofon dipakai untuk mendengarkan pertanyaanmu. Mode lain tetap berfungsi tanpa izin ini.',
                actionLabel: 'Izinkan mikrofon',
                onAction: _requestMicPermission,
              ),
            )
          else
            ..._buildContent(context, voice, bottomInset),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              onMicPressed: _onMicPressed,
              micEnabled: _hasMicPermission,
              listeningOverride: voice.isListening,
              processingOverride: voice.isProcessing,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(GlobalConditionsProvider global) {
    if (_debugOverride == 'AS-16' || global.isOffline) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet');
    }
    return null;
  }

  List<Widget> _buildContent(BuildContext context, VoiceProvider voice, double bottomInset) {
    if (_debugOverride == 'AS-24' || (!_hasCameraPermission && _debugOverride == null)) {
      return [_bubblePanel(bottomInset, const _StaticNotice(text: 'Izin kamera dicabut. Saya masih bisa menjawab pertanyaan yang tidak butuh penglihatan atau ganti mode.'))];
    }
    if (_debugOverride == 'AS-16') {
      return [_bubblePanel(bottomInset, const _StaticNotice(
        text: 'Tanpa internet. Masih bisa: ganti mode, deteksi objek, kenali uang.',
      ))];
    }
    if (_debugOverride == 'AS-05') {
      return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const VoiceOrb(state: VoiceOrbState.failure),
        const SizedBox(height: AppSpacing.s3),
        _pill('Terlalu berisik, dekatkan ponsel ke mulutmu'),
      ]))];
    }
    if (_debugOverride == 'AS-07') {
      return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const VoiceOrb(state: VoiceOrbState.failure),
        const SizedBox(height: AppSpacing.s3),
        _pill('Belum jelas. Coba: "kenali uang" atau "baca teks"'),
      ]))];
    }
    if (_debugOverride == 'AS-13') {
      return [_bubblePanel(bottomInset, _mockHistoryTranscript())];
    }
    if (_debugOverride == 'AS-23') {
      return [_bubblePanel(bottomInset, const _StaticNotice(text: 'Percakapan tadi sudah saya hapus.'))];
    }
    if (_debugOverride == 'AS-25') {
      return [_bubblePanel(bottomInset, const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ChatBubble(speaker: ChatSpeaker.vinara, text: 'Di depanmu ada meja panjang, lalu di sebelah kanan ada...', isLatest: true),
        AlertCard(tier: AlertTier.critical, title: 'Orang! Di depan, kurang dari satu meter', distanceMeter: .8),
      ]))];
    }

    switch (voice.state) {
      case VoiceState.idle:
        return [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const VoiceOrb(state: VoiceOrbState.idle),
              const SizedBox(height: AppSpacing.s4),
              _pill('Ketuk lalu bicara'),
            ]),
          ),
        ];
      case VoiceState.listening:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.listening))];
      case VoiceState.noSpeech:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s3),
          _pill('Belum terdengar apa pun'),
        ]))];
      case VoiceState.tooNoisy:
        return [Center(child: _pill('Terlalu berisik, dekatkan ponsel ke mulutmu'))];
      case VoiceState.transcribing:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.processing))];
      case VoiceState.transcribeFailed:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s3),
          _pill('Belum jelas. Coba: "kenali uang" atau "baca teks"'),
        ]))];
      case VoiceState.processingLocal:
      case VoiceState.processingLlm:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.processing))];
      case VoiceState.fallbackActive:
      case VoiceState.allFailed:
      case VoiceState.responded:
      case VoiceState.unrecognized:
      case VoiceState.ambiguous:
        return [_bubblePanel(bottomInset, _historyTranscript(voice))];
    }
  }

  Widget _historyTranscript(VoiceProvider voice) {
    if (_silentMode) {
      // AS-21 — senyap: seluruh jawaban ditampilkan penuh.
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
        child: Text(voice.response, style: AppTypography.body().copyWith(fontSize: 18, height: 26 / 18)),
      );
    }

    final history = voice.history;
    final recent = history.length > 8 ? history.sublist(history.length - 6) : history;
    final summarizedCount = history.length - recent.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summarizedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Text('$summarizedCount giliran sebelumnya diringkas. Ucapkan "ulangi" untuk dengar lagi.',
                  style: AppTypography.caption()),
            ),
          ChatTranscript(
            turns: [
              for (var i = 0; i < recent.length; i++)
                ChatBubble(
                  speaker: recent[i].isUser ? ChatSpeaker.user : ChatSpeaker.vinara,
                  text: recent[i].text,
                  isLatest: i == recent.length - 1 && !recent[i].isUser,
                ),
            ],
          ),
          if (_longAnswerOffer) ...[
            const SizedBox(height: AppSpacing.s2),
            TextButton(onPressed: () {}, child: const Text('Ringkas saja?')),
          ],
        ],
      ),
    );
  }

  Widget _mockHistoryTranscript() {
    final mock = [
      ChatTurn(isUser: true, text: 'ada apa di depan'),
      ChatTurn(isUser: false, text: 'Ada meja dan dua kursi di depanmu.'),
      ChatTurn(isUser: true, text: 'kenali uang'),
      ChatTurn(isUser: false, text: 'Baik, mode Kenali Uang.'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4 giliran sebelumnya diringkas. Ucapkan "ulangi" untuk dengar lagi.', style: AppTypography.caption()),
          const SizedBox(height: AppSpacing.s3),
          ChatTranscript(turns: [
            for (var i = 0; i < mock.length; i++)
              ChatBubble(speaker: mock[i].isUser ? ChatSpeaker.user : ChatSpeaker.vinara, text: mock[i].text, isLatest: i == mock.length - 1),
          ]),
        ],
      ),
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

  Widget _bubblePanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }
}

class _StaticNotice extends StatelessWidget {
  final String text;
  const _StaticNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
        child: Text(text, style: AppTypography.body()),
      ),
    );
  }
}
