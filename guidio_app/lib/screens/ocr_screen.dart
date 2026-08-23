import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../mock/ocr_mock_data.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import '../widgets/ocr_debug_sheet.dart';
import '../widgets/ocr_long_result_panel.dart';

/// Mode Baca Teks - bagian 8 IMPLEMENTASI.md, 22 state (BT-01..BT-22).
/// Alur nyata (jepret → ServerService.readText → TTS) tetap dipakai untuk
/// state dasar; state yang butuh data server yang belum ada (dua bahasa,
/// sebagian gagal, sangat panjang) dicapai lewat panel debug (lib/mock/
/// ocr_mock_data.dart), sesuai bagian 2 dokumen "boleh dipalsukan".
class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

enum _FailKind { none, zeroText, offline, server, timeout }

class _OcrScreenState extends State<OcrScreen> with WidgetsBindingObserver {
  bool _hasCameraPermission = true;
  bool _scanning = false;
  bool _speaking = false;
  bool _paused = false;
  bool _nearTimeout = false;
  int _elapsedSeconds = 0;
  _FailKind _fail = _FailKind.none;
  // BT-10 (terbaca sebagian) tidak bisa dipicu dari server nyata saat ini
  // (ServerService.readText tidak mengembalikan status per-blok) - dicapai
  // lewat panel debug saja (lihat _resolveBanner / _renderDebug 'BT-10').
  static const _partialRead = false;

  List<OcrRenderBlock> _blocks = [];
  int _activeSentenceGlobal = -1;
  DateTime? _completedAt;

  String? _debugOverride; // BT-xx id

  Timer? _elapsedTicker;
  Timer? _hardTimeoutTimer;
  Timer? _sentenceTicker;
  Timer? _expiryTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" - diucapkan di sini, sesudah layarnya
      // benar-benar terpasang, bukan oleh pemanggil setMode.
      context.read<AppModeProvider>().announceEntry(AppMode.ocr);
      if (_hasCameraPermission) {
        // Preset foto diminta DI SINI, bukan hanya di `_checkPermission`.
        //
        // `_checkPermission` hanya menyiapkan kamera saat status izinnya
        // BERUBAH, dan `_hasCameraPermission` bernilai true sejak awal - jadi
        // pada kasus yang paling umum (izin sudah diberikan sejak lama)
        // cabang itu tidak pernah jalan, dan mode ini memotret pada preset
        // `realtime` 640x480 warisan mode sebelumnya. Untuk huruf kecil,
        // resolusi itu menghapus informasinya sebelum ML Kit sempat melihat:
        // sekurus apa pun fotonya, teksnya memang tidak akan terbaca, dan
        // kegagalannya terlihat seperti masalah cahaya.
        final cam = context.read<CameraProvider>();
        await cam.initCamera(preset: CapturePreset.capture);
        if (!mounted) return;
        cam.startStream();
      }

      // Kontrak tombol kiri + perintah suara. `playPause` / `playResume` /
      // `actionReplay` punya bank kata lengkap sejak awal tapi tidak pernah
      // punya handler - di mode inilah ketiganya paling masuk akal.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = () => (_speaking || _paused) ? _togglePause() : _scan();
      voice.primaryActionLabel = () =>
          _speaking ? 'menjeda bacaan' : _paused ? 'melanjutkan bacaan' : 'membaca teks';
      voice.onRepeatLast = () { if (_blocks.isNotEmpty) _replay(); };
      voice.onPauseSpeech = () {
        if (!_speaking) return false;
        _togglePause();
        return true;
      };
      voice.onResumeSpeech = () {
        if (!_paused) return false;
        _togglePause();
        return true;
      };
    });
    // BT-20 - cek kedaluwarsa tiap 30 detik.
    _expiryTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTicker?.cancel();
    _hardTimeoutTimer?.cancel();
    _sentenceTicker?.cancel();
    _expiryTicker?.cancel();
    context.read<CameraProvider>().stopStream();
    context.read<VoiceProvider>().clearModeHandlers();
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
        await cam.initCamera(preset: CapturePreset.capture);
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
      await cam.initCamera(preset: CapturePreset.capture);
      cam.startStream();
    } else {
      await context.read<TtsProvider>().speak('Izin kamera belum diberikan.', tier: SpeechTier.warning);
    }
  }

  List<String> _splitSentences(String text) =>
      text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();

  Future<void> _scan() async {
    if (_scanning) return;
    if (_debugOverride != null) setState(() => _debugOverride = null);

    // Tidak ada lagi penghalang offline di sini. Pengenalan teks berjalan
    // sepenuhnya di perangkat lewat ML Kit, jadi BT-02 ("butuh internet")
    // tidak berlaku: melarang jepret saat offline berarti mematikan fitur
    // yang sebenarnya masih hidup - kesalahan yang sama seperti mematikan
    // Mode Navigasi offline.

    final cameraProvider = context.read<CameraProvider>();
    final ttsProvider = context.read<TtsProvider>();

    setState(() {
      _scanning = true;
      _fail = _FailKind.none;
      _blocks = [];
      _nearTimeout = false;
      _elapsedSeconds = 0;
    });

    await Vibration.hasVibrator().then((has) {
      if (has) Vibration.vibrate(duration: 15);
    });
    if (!mounted) return;

    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= 8) setState(() => _nearTimeout = true);
    });
    _hardTimeoutTimer?.cancel();
    _hardTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_scanning) return;
      _elapsedTicker?.cancel();
      setState(() {
        _scanning = false;
        _nearTimeout = false;
        _fail = _FailKind.timeout;
      });
      ttsProvider.speak('Terlalu lama, coba lagi.', tier: SpeechTier.warning);
    });

    try {
      final path = await cameraProvider.captureFile();
      final result = await OcrService.instance.recognizeFile(path);

      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      setState(() => _scanning = false);

      if (result.isEmpty) {
        // BT-11 - instruksi jarak konkret, bukan "tidak ada teks".
        setState(() => _fail = _FailKind.zeroText);
        await context.read<TtsProvider>().speak(
              'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal, pastikan tulisan rata di tengah.',
              tier: SpeechTier.warning,
            );
        return;
      }

      setState(() {
        // ML Kit sudah memisahkan teks per blok tata letak, jadi heading
        // ResultPanel/long jadi nyata - bukan satu blok "Hasil baca" untuk
        // seluruh halaman seperti waktu OCR dikerjakan server.
        _blocks = [
          for (final b in result.blocks)
            OcrRenderBlock(heading: b.heading, sentences: b.sentences),
        ];
        _completedAt = null;
      });

      // BT-08 - kalau bacaannya panjang, sebut durasinya SEBELUM mulai,
      // supaya pengguna sempat memilih ringkasan.
      final secs = result.estimatedDuration.inSeconds;
      if (secs > 90) {
        await context.read<TtsProvider>().speak(
              'Teksnya panjang, sekitar ${(secs / 60).round()} menit dibacakan. '
              'Ucapkan "ringkas" kalau mau ringkasannya saja.',
              tier: SpeechTier.info,
            );
      }
      await _speak();
    } on CaptureRejected catch (rejected) {
      // Foto ditolak SEBELUM sempat masuk ML Kit: terlalu buram, terlalu
      // gelap, atau terlalu silau. Instruksi perbaikannya sudah dibacakan
      // saat penolakan terjadi, jadi di sini cukup mengembalikan layar ke
      // keadaan siap. Membacakan ulang hanya membuat pengguna mendengar
      // kalimat yang sama dua kali dan mengira dia salah dengar yang pertama.
      //
      // Ini beda dari "tidak ada teks terdeteksi", dan bedanya penting:
      // di sana yang perlu diubah adalah jarak atau posisi tulisan, di sini
      // kondisi pengambilan gambarnya.
      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      debugPrint('[OCR] foto ditolak: $rejected');
      setState(() {
        _scanning = false;
        _fail = _FailKind.zeroText;
      });
    } catch (e) {
      _hardTimeoutTimer?.cancel();
      _elapsedTicker?.cancel();
      if (!mounted) return;
      // Tidak ada lagi cabang offline/server: pengenalan on-device hanya gagal
      // karena kamera atau berkasnya, dan itu yang dikatakan.
      setState(() {
        _scanning = false;
        _fail = _FailKind.zeroText;
      });
      await context.read<TtsProvider>().speak(
            'Gagal membaca gambar. Coba ambil ulang.',
            tier: SpeechTier.warning,
          );
    }
  }

  Future<void> _speak() async {
    if (_blocks.isEmpty) return;
    setState(() {
      _speaking = true;
      _paused = false;
    });
    final flat = <String>[];
    for (final b in _blocks) {
      if (b.ok) flat.addAll(b.sentences);
    }
    final fullText = flat.join(' ');
    unawaited(_animateActiveSentence(flat.length));
    // Warning, bukan Info: pembacaan ini diminta pengguna secara eksplisit dan
    // bisa berlangsung menit-menitan - membiarkannya dibuang sebagai "Info
    // basi" karena antre 2 detik akan membatalkan permintaan yang disengaja.
    // Tetap bisa dipotong pengguna lewat tombol "Jeda bacaan".
    if (!mounted) return;
    await context.read<TtsProvider>().speak(fullText, tier: SpeechTier.warning);
    _sentenceTicker?.cancel();
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _activeSentenceGlobal = -1;
      _completedAt = DateTime.now();
    });
  }

  Future<void> _animateActiveSentence(int count) async {
    if (count == 0) return;
    _sentenceTicker?.cancel();
    var i = 0;
    setState(() => _activeSentenceGlobal = 0);
    _sentenceTicker = Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted || !_speaking) {
        t.cancel();
        return;
      }
      i++;
      if (i >= count) {
        t.cancel();
        return;
      }
      setState(() => _activeSentenceGlobal = i);
    });
  }

  Future<void> _togglePause() async {
    if (_speaking) {
      await context.read<TtsProvider>().interruptByUser();
      _sentenceTicker?.cancel();
      setState(() {
        _speaking = false;
        _paused = true;
      });
    } else if (_paused) {
      setState(() => _paused = false);
      await _speak();
    }
  }

  Future<void> _replay() async {
    if (_blocks.isEmpty) return;
    await _speak();
  }

  Future<void> _copy() async {
    final flat = _blocks.expand((b) => b.ok ? b.sentences : <String>[]).join(' ');
    if (flat.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: flat));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks disalin ke clipboard')),
      );
    }
  }

  void _goToAssistant() {
    context.read<AppModeProvider>().setMode(AppMode.voice);
  }

  Future<void> _readTitleOnly() async {
    setState(() {
      _blocks = [OcrRenderBlock(heading: 'Judul', sentences: [mockShortText()])];
      _fail = _FailKind.none;
    });
    await _speak();
  }

  void _openDebugSheet() {
    showOcrDebugSheet(
      context,
      activeId: _debugOverride,
      onSelect: (id) => setState(() {
        _debugOverride = id;
        _scanning = false;
        _speaking = false;
        _paused = false;
        _fail = _FailKind.none;
      }),
      onCancel: () => setState(() => _debugOverride = null),
    );
  }

  bool get _isSilent => _debugOverride == 'BT-19';
  bool get _isFontScale200 => _debugOverride == 'BT-18';
  bool get _hasExpired =>
      _completedAt != null && DateTime.now().difference(_completedAt!) > const Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final storageLow = context.watch<GlobalConditionsProvider>().isStorageLow;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    final banner = _resolveBanner(offline, storageLow);
    final hasBanner = banner != null;

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: _cameraWithGuide(cam))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.ocr, onDebugActivate: _openDebugSheet),
          ),

          if (_debugOverride == 'BT-22' || (cam.healthMessage != null && _debugOverride == null && !_scanning))
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 60,
              child: const Center(child: CameraHealthToast(issue: CameraHealthIssue.blurry)),
            ),

          if (!_hasCameraPermission)
            // BT-17 - kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk memotret tulisan yang ingin dibacakan.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else
            ..._buildContentZone(context, bottomInset, offline),

          Positioned(
            left: 0, right: 0, bottom: 0,
            // Tombol kiri kontekstual: di mode ini "hal utama" memang berubah
            // sepanjang alur. Sebelum jepret yang dibutuhkan adalah memotret;
            // saat sedang dibacakan, yang dibutuhkan adalah menjeda.
            child: BottomActionBar(
              cameraLabel: _speaking
                  ? 'Jeda bacaan'
                  : _paused
                      ? 'Lanjutkan bacaan'
                      : 'Baca teks',
              onCameraPressed:
                  (_speaking || _paused) ? _togglePause : (_scanning ? null : _scan),
              cameraEnabled: !_scanning,
              cameraDisabledReason: 'sedang memindai',
            ),
          ),
        ],
      ),
    );
  }

  Widget? _resolveBanner(bool offline, bool storageLow) {
    if (_debugOverride == 'BT-14') {
      return const StatusBanner(tier: AlertTier.critical, message: 'Server tidak bisa dihubungi. Bukan karena gambarmu.');
    }
    if (_fail == _FailKind.server) {
      return const StatusBanner(tier: AlertTier.critical, message: 'Server tidak bisa dihubungi. Bukan karena gambarmu.');
    }
    if (_debugOverride == 'BT-10' || _partialRead) {
      return const StatusBanner(tier: AlertTier.warning, message: '2 dari 4 bagian terbaca. Bagian lain buram.', actionLabel: 'Foto ulang');
    }
    if (_debugOverride == 'BT-21' || storageLow) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Penyimpanan hampir penuh, pembacaan tetap berjalan');
    }
    if (_debugOverride == 'BT-05' || _nearTimeout) {
      return StatusBanner(tier: AlertTier.warning, message: 'Koneksi lambat, ${_elapsedSeconds}d…', actionLabel: 'Batalkan', onAction: () {
        _hardTimeoutTimer?.cancel();
        _elapsedTicker?.cancel();
        setState(() { _scanning = false; _nearTimeout = false; });
      });
    }
    if (_debugOverride != 'BT-02' && offline) {
      return const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet, baca judul saja tetap bisa dipakai');
    }
    return null;
  }

  List<Widget> _buildContentZone(BuildContext context, double bottomInset, bool offline) {
    if (_debugOverride != null) return [_renderDebug(context, bottomInset, _debugOverride!)];

    if (_fail == _FailKind.offline) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Gambar tersimpan, akan dikirim ulang saat online.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.timeout) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Terlalu lama merespons. Foto tetap tersimpan.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.server) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Server tidak bisa dihubungi. Coba lagi.', failed: true, onRetry: _scan))];
    }
    if (_fail == _FailKind.zeroText) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal.', failed: true, onRetry: _scan))];
    }

    if (_scanning) {
      return [const Center(child: CircularProgressIndicator(color: AppColors.onDark))];
    }

    if (_hasExpired) {
      return [_bottomPanel(bottomInset, ResultPanel(text: 'Hasil sudah lebih dari 15 menit. Foto ulang untuk membaca lagi.', failed: true, onRetry: _scan))];
    }

    if (_blocks.isEmpty) {
      return [
        Positioned(
          left: AppSpacing.screenMargin,
          right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 96 + AppSpacing.s3,
          child: FullScreenButton(
            label: 'Baca teks',
            icon: Icons.document_scanner_outlined,
            onTap: offline ? null : _scan,
            disabled: offline,
            disabledReason: offline ? 'Butuh internet untuk teks panjang' : null,
          ),
        ),
        if (offline)
          Positioned(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s3,
            child: Center(
              child: TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: AppColors.onDark))),
            ),
          ),
      ];
    }

    final singleShort = _blocks.length == 1 && _blocks.first.ok && _blocks.first.sentences.length <= 2;
    if (singleShort) {
      final text = _blocks.first.sentences.join(' ');
      return [
        _bottomPanel(
          bottomInset,
          ResultPanel(
            text: text,
            speaking: _speaking,
            paused: _paused,
            onReplay: _replay,
            onTogglePlayback: _togglePause,
            secondaryLabel: 'Salin teks',
            onSecondary: _copy,
          ),
        ),
      ];
    }

    return [_bottomPanel(bottomInset, _renderLongPanel())];
  }

  Widget _renderLongPanel() {
    final activeBlocks = <OcrRenderBlock>[];
    var counted = 0;
    for (final b in _blocks) {
      final localActive = b.ok && _activeSentenceGlobal >= counted && _activeSentenceGlobal < counted + b.sentences.length
          ? _activeSentenceGlobal - counted
          : -1;
      activeBlocks.add(OcrRenderBlock(
        heading: b.heading, sentences: b.sentences, language: b.language, ok: b.ok, activeLocalIndex: localActive,
      ));
      if (b.ok) counted += b.sentences.length;
    }
    final totalSentences = _blocks.where((b) => b.ok).fold(0, (s, b) => s + b.sentences.length);
    final progress = totalSentences == 0 ? null : (_activeSentenceGlobal < 0 ? (_speaking || _paused ? 0.0 : null) : (_activeSentenceGlobal + 1) / totalSentences);

    if (_isSilent) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.card, boxShadow: AppElevation.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('HASIL BACA', style: AppTypography.eyebrow()),
              const SizedBox(height: AppSpacing.s3),
              for (final b in _blocks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: Text(b.ok ? b.sentences.join(' ') : 'Bagian ini tidak terbaca.',
                      style: AppTypography.body().copyWith(fontSize: 18, height: 26 / 18)),
                ),
            ],
          ),
        ),
      );
    }

    return OcrLongResultPanel(
      blocks: activeBlocks,
      speaking: _speaking,
      paused: _paused,
      progress: progress,
      muted: false,
      vertical: _isFontScale200,
      onTogglePlayback: _togglePause,
      onReplay: _replay,
      tertiaryLabel: (!_speaking && !_paused) ? 'Bicara ke Asisten' : null,
      onTertiary: _goToAssistant,
    );
  }

  Widget _bottomPanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin,
      right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }

  Widget _renderDebug(BuildContext context, double bottomInset, String id) {
    switch (id) {
      case 'BT-01':
        return Positioned(
          left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s6 + 96 + AppSpacing.s3,
          child: const FullScreenButton(label: 'Baca teks', icon: Icons.document_scanner_outlined),
        );
      case 'BT-02':
        return Positioned(
          left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
          bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s3,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const FullScreenButton(label: 'Baca teks', disabled: true, disabledReason: 'Butuh internet untuk teks panjang'),
            const SizedBox(height: AppSpacing.s3),
            TextButton(onPressed: _readTitleOnly, child: const Text('Baca judul saja', style: TextStyle(color: AppColors.onDark))),
          ]),
        );
      case 'BT-03':
        return const Center(
          child: ColoredBox(color: AppColors.bgPage, child: SizedBox(width: double.infinity, height: double.infinity)),
        );
      case 'BT-04':
        return _bottomPanel(bottomInset, const ResultPanel(text: '', title: 'Membaca teks…'));
      case 'BT-06':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Salin teks', onSecondary: () {}));
      case 'BT-07':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockLongBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
          progress: 0.4, onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-08':
        return _bottomPanel(bottomInset, Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: AppSpacing.s3),
            decoration: BoxDecoration(color: AlertTier.warning.tintColor, borderRadius: AppRadius.card),
            child: Text('Dokumen ini panjang, perkiraan lebih dari 90 detik. Baca ringkasan, baca penuh, atau pilih bagian?',
                style: AppTypography.body(color: AlertTier.warning.labelColor)),
          ),
          OcrLongResultPanel(
            blocks: mockVeryLongBlocks().take(3).map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
            onTogglePlayback: () {}, onReplay: () {},
          ),
        ]));
      case 'BT-09':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockBilingualBlocks().map((b) => OcrRenderBlock(heading: b.heading, language: b.language, sentences: _splitSentences(b.text))).toList(),
          onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-10':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockPartialBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text), ok: b.ok)).toList(),
          onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-11':
        return _bottomPanel(bottomInset, ResultPanel(text: 'Tidak ada teks terdeteksi. Dekatkan sekitar satu jengkal.', failed: true, onRetry: () {}));
      case 'BT-12a':
        return _bottomPanel(bottomInset, OcrLongResultPanel(
          blocks: mockLongBlocks().map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList(),
          paused: true, progress: 0.3, onTogglePlayback: () {}, onReplay: () {},
        ));
      case 'BT-12b':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Bicara ke Asisten', onSecondary: _goToAssistant));
      case 'BT-13':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Gambar tersimpan, akan dikirim ulang saat online.', failed: true));
      case 'BT-14':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Server tidak bisa dihubungi. Bukan karena gambarmu.', failed: true));
      case 'BT-15':
        return _bottomPanel(bottomInset, const ResultPanel(text: 'Terlalu lama merespons. Foto tetap tersimpan.', failed: true));
      case 'BT-16':
        return _bottomPanel(bottomInset, ResultPanel(text: mockShortText(), onReplay: () {}, secondaryLabel: 'Bicara ke Asisten', onSecondary: _goToAssistant));
      case 'BT-19':
        return _renderLongPanelWithSentences(mockLongBlocks());
      case 'BT-20':
        return _bottomPanel(bottomInset, ResultPanel(text: 'Hasil sudah lebih dari 15 menit. Foto ulang untuk membaca lagi.', failed: true, onRetry: () {}));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _renderLongPanelWithSentences(List<OcrBlock> src) {
    _blocks = src.map((b) => OcrRenderBlock(heading: b.heading, sentences: _splitSentences(b.text))).toList();
    return _bottomPanel(0, _renderLongPanel());
  }

  Widget _cameraWithGuide(CameraProvider cam) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CameraPreview(cam.controller!)),
        Center(
          child: SizedBox(
            width: 280,
            height: 190,
            child: GuideFrame(fit: _scanning ? FrameFit.fit : FrameFit.empty),
          ),
        ),
      ],
    );
  }
}
