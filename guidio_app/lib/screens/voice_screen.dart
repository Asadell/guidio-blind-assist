import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/layout/zone_contract.dart';
import '../providers/index.dart';
import '../services/haptic_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import 'settings_screen.dart';

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

/// Mode Asisten Suara - bagian 11 IMPLEMENTASI.md, 25 state (AS-01..AS-25).
/// [isOverlay] = true saat dimasukkan via Navigator push dari mode lain
/// (fitur "Jarvis Global Mic"). Dalam mode overlay:
/// - Tampil tombol ✕ (tutup) di pojok kanan atas.
/// - VoiceProvider.onNavigateBack dipasang untuk pop otomatis setelah
///   perintah suara yang mengubah mode dieksekusi.
class VoiceScreen extends StatefulWidget {
  final bool isOverlay;
  const VoiceScreen({super.key, this.isOverlay = false});

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
        // AS-23 - riwayat kedaluwarsa, sudah dibersihkan oleh provider.
        context.read<TtsProvider>().speak('Percakapan tadi sudah saya hapus.', tier: SpeechTier.info);
      }

      voice.onSpeak = (text) => context.read<TtsProvider>().speak(text, tier: SpeechTier.info);
      voice.onOpenSettings = _openSettings;

      // Batas sesi harus TERASA, bukan cuma terlihat.
      //
      // Ikon mikrofon yang berubah warna tidak berarti apa-apa bagi pengguna
      // yang tidak melihat layar. Tanpa penanda fisik, satu-satunya cara tahu
      // sesinya sudah tertutup adalah menunggu jawaban - dan kalau jawabannya
      // tidak kunjung datang, tidak ada cara membedakan "masih mendengarkan"
      // dari "sudah menyerah". Dua pola sengaja dibedakan supaya mulai dan
      // berhenti tidak tertukar.
      voice.onListeningStarted = HapticService.instance.info;
      voice.onListeningEnded = HapticService.instance.warning;
      voice.onAllFeaturesFailed = () {};

      // "lebih cepat" / "lebih pelan" - dulu keduanya punya bank kata lengkap
      // tapi tidak ada yang menjalankannya.
      voice.onAdjustSpeechRate = (delta) async {
        final settings = context.read<SettingsProvider>();
        final next = (settings.speechRate + delta).clamp(0.2, 1.0);
        await settings.setSpeechRate(next);
        return next;
      };

      // Sebagai MODE (bukan overlay), aksi utamanya mendeskripsikan suasana -
      // sama persis dengan tombol kiri, mengikuti kontrak "jepret lewat suara
      // = menekan tombol kiri".
      //
      // Sebagai OVERLAY, handler mode di bawahnya sengaja TIDAK ditimpa:
      // "jepret" saat mic terbuka harus menjalankan aksi mode aslinya.
      if (!widget.isOverlay) {
        voice.onPrimaryAction = _describeScene;
        voice.primaryActionLabel = () => 'mendeskripsikan suasana';
        // "ulangi" tetap mengulang jawaban. Perintah itu punya arti sendiri
        // yang tidak tergantikan tombol mana pun.
        voice.onRepeatLast = _repeatLastAnswer;
      }

      // Overlay: pasang callback agar VoiceProvider bisa meminta pop Navigator
      // tanpa perlu tahu tentang BuildContext.
      if (widget.isOverlay) {
        voice.onNavigateBack = () {
          if (mounted) Navigator.of(context).pop();
        };
        // Mulai mendengar langsung saat overlay dibuka.
        if (!voice.isListening && voice.state == VoiceState.idle) {
          voice.startListening();
        }
      }
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
    voice.onListeningStarted = null;
    voice.onListeningEnded = null;
    voice.onOpenSettings = null;
    voice.onAllFeaturesFailed = null;
    voice.onAdjustSpeechRate = null;
    if (widget.isOverlay) {
      voice.onNavigateBack = null;
    } else {
      // Hanya lepas handler yang dipasang layar ini. Sebagai overlay, handler
      // milik mode di bawahnya harus tetap utuh.
      voice.clearModeHandlers();
    }
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

  /// `mode.settings` - Pengaturan layar penunjang, bukan mode. Mengembalikan
  /// true hanya kalau halamannya benar-benar terdorong ke Navigator, supaya
  /// VoiceProvider tidak mengonfirmasi pembukaan yang tidak terjadi.
  Future<bool> _openSettings() async {
    if (!mounted) return false;
    // Rute sudah masuk tumpukan begitu `push` dipanggil; Future-nya baru
    // selesai saat halaman DITUTUP, jadi ia sengaja tidak ditunggu - kalau
    // ditunggu, konfirmasinya baru terdengar setelah pengguna keluar lagi.
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ));
    return true;
  }

  /// Tombol kiri Mode Asisten Suara - baca ulang jawaban terakhir.
  ///
  /// Rencana perbaikan menyarankan tombol ini dinonaktifkan dengan label jujur.
  /// Itu benar dan jujur, tapi menyisakan satu tombol mati dari enam mode dan
  /// membuat aturan tombol kiri punya pengecualian. "Ulangi jawaban" berguna
  /// nyata: pengguna yang tidak menangkap jawaban cukup menekan tombol yang
  /// posisinya sudah ia hafal - tanpa bertanya ulang, dan tanpa memicu
  /// panggilan Moondream2 kedua yang makan lima detik dan kuota.
  void _repeatLastAnswer() {
    final voice = context.read<VoiceProvider>();
    final answer = voice.response;
    if (answer.isEmpty) {
      context.read<TtsProvider>().speak(
            'Belum ada jawaban untuk diulang. Tekan tombol bicara dulu.',
            tier: SpeechTier.info,
          );
      return;
    }
    context.read<TtsProvider>().speak(answer, tier: SpeechTier.info);
  }

  Future<void> _onMicPressed() async {
    final voice = context.read<VoiceProvider>();
    setState(() => _debugOverride = null);
    if (voice.isListening) {
      await voice.stopListening();
    } else if (voice.state == VoiceState.responded) {
      // AS-20 - menekan lagi saat masih bicara: potong tanpa nada khusus.
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
              Text('Debug - Mode Asisten Suara', style: AppTypography.title()),
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

    // AS-25 - Critical dari mode lain menyela jawaban yang sedang dibacakan.
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
            child: ModeBadge(mode: AppMode.voice, onDebugActivate: _openDebugSheet),
          ),

          if (voice.state == VoiceState.responded && !_silentMode)
            Positioned(
              top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
              right: AppSpacing.screenMargin,
              child: const SpeakingIndicator(),
            ),

          if (!_hasMicPermission && _debugOverride == null)
            // AS-02 - kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.mic_none_rounded,
              title: 'Izin mikrofon',
              reason: 'Mikrofon dipakai untuk mendengarkan pertanyaanmu. Mode lain tetap berfungsi tanpa izin ini.',
              actionLabel: 'Izinkan mikrofon',
              onAction: _requestMicPermission,
            )
          else
            ..._buildContent(context, voice, bottomInset),

          Positioned(
            left: 0, right: 0, bottom: 0,
            // Tombol kiri di mode ini = KIRIM foto ke VLM.
            //
            // Inilah hal utama mode ini, jadi ia yang menempati tombol kiri,
            // sesuai kontrak "tombol kiri melakukan hal utama mode ini".
            // Deskripsi TIDAK berjalan otomatis saat masuk mode: tiap
            // panggilan mengunggah satu foto sekitar pengguna dan membangunkan
            // Moondream2, dan itu tidak boleh terjadi hanya karena seseorang
            // salah membuka mode.
            //
            // Slot "Kembali" yang dulu menumpang di atas bar tetap tidak
            // dikembalikan: ia menggeser posisi tombol kiri dan tengah,
            // padahal kekekalan posisi tiga tombol itu satu-satunya peta yang
            // dimiliki pengguna yang tidak melihat layar. Keluar dari mode ini
            // lewat tombol Pilih mode di kanan, sama seperti mode lain.
            child: BottomActionBar(
              cameraLabel: 'Deskripsikan',
              cameraIcon: Icons.image_search_rounded,
              onCameraPressed: _describeScene,
              cameraEnabled: !voice.isProcessing,
              cameraDisabledReason: 'sedang memproses',
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

  /// Kirim foto sekarang ke VLM di server, lalu bacakan hasilnya.
  ///
  /// Sama persis dengan perintah suara "deskripsikan", mengikuti kontrak
  /// "jepret lewat suara = menekan tombol kiri". Satu jalur, dua cara
  /// memicunya, jadi keduanya tidak pernah berbeda perilaku.
  void _describeScene() {
    context.read<VoiceProvider>().describeSceneNow();
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
      // AS-21 - senyap: seluruh jawaban ditampilkan penuh.
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
        child: Text(voice.response, style: AppTypography.body().copyWith(fontSize: 18, height: 26 / 18)),
      );
    }

    // HANYA giliran terakhir yang ditampilkan.
    //
    // Transkrip berjalan adalah pola dari aplikasi obrolan, dan di sini ia
    // salah tempat. Pengguna aplikasi ini tidak sedang membaca percakapan; ia
    // baru saja mengucapkan satu perintah dan ingin tahu satu hal: apa yang
    // ditangkap, dan apa jawabannya. Menumpuk enam giliran sebelumnya
    // membuat yang paling baru terdorong ke bawah, dan untuk pengguna low
    // vision yang memakai ukuran teks besar, jawaban yang barusan justru
    // yang pertama keluar layar.
    //
    // Riwayat di provider TIDAK dihapus: `checkAndExpireHistory` dan perintah
    // "ulangi" masih memakainya. Yang berubah cuma berapa banyak yang
    // digambar.
    final history = voice.history;
    if (history.isEmpty) return const SizedBox.shrink();

    final lastUser = history.lastWhere((t) => t.isUser, orElse: () => history.last);
    final lastReply = history.lastWhere((t) => !t.isUser, orElse: () => history.last);
    final replyIsNewer = history.lastIndexOf(lastReply) > history.lastIndexOf(lastUser);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatTranscript(
            turns: [
              // Ucapan pengguna tetap ditampilkan, karena itu satu-satunya
              // cara ia memeriksa apakah suaranya tertangkap dengan benar.
              // Kalau yang terdengar meleset, di sinilah kelihatannya.
              ChatBubble(
                speaker: ChatSpeaker.user,
                text: lastUser.text,
                isLatest: false,
              ),
              if (replyIsNewer)
                ChatBubble(
                  speaker: ChatSpeaker.vinara,
                  text: lastReply.text,
                  isLatest: true,
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
        child: Text(text, style: AppTypography.body(color: AppColors.onDark)),
      ),
    );
  }

  Widget _bubblePanel(double bottomInset, Widget child) {
    // Slot 'Kembali' sudah dihapus, jadi tidak ada lagi yang menumpang di atas
    // BottomActionBar dan tidak ada yang perlu digeser.
    const slotExtra = 0.0;
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2 + slotExtra,
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
