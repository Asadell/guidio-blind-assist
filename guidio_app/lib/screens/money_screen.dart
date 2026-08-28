import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Kenali Uang - bagian 9 IMPLEMENTASI.md, 18 state (UG-01..UG-18).
/// Sepenuhnya on-device, nol sentuhan: [MoneyProvider] menjalankan siklus
/// deteksi mock sendiri lewat Timer, layar ini murni merender.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

/// Satu entri per baris tabel bagian 9 - termasuk pemecahan UG-09a/UG-09b
/// dan UG-12a/UG-12b apa adanya, supaya panel debug bisa menunjukkan kedua
/// varian secara terpisah (mis. UG-09b: campuran Rp20.000×2 + Rp5.000×1).
enum MoneyDebugState {
  ug01, ug02, ug03, ug04, ug05, ug06, ug07, ug08,
  ug10, ug12a, ug12b, ug13, ug14, ug15, ug16, ug18,
}

extension _DebugMeta on MoneyDebugState {
  String get id => switch (this) {
        MoneyDebugState.ug01 => 'UG-01', MoneyDebugState.ug02 => 'UG-02',
        MoneyDebugState.ug03 => 'UG-03', MoneyDebugState.ug04 => 'UG-04',
        MoneyDebugState.ug05 => 'UG-05', MoneyDebugState.ug06 => 'UG-06',
        MoneyDebugState.ug07 => 'UG-07', MoneyDebugState.ug08 => 'UG-08',
        MoneyDebugState.ug10 => 'UG-10',
        MoneyDebugState.ug12a => 'UG-12a', MoneyDebugState.ug12b => 'UG-12b',
        MoneyDebugState.ug13 => 'UG-13', MoneyDebugState.ug14 => 'UG-14',
        MoneyDebugState.ug15 => 'UG-15', MoneyDebugState.ug16 => 'UG-16',
        MoneyDebugState.ug18 => 'UG-18',
      };

  String get title => switch (this) {
        MoneyDebugState.ug01 => 'Idle',
        MoneyDebugState.ug02 => 'Masuk sebagian',
        MoneyDebugState.ug03 => 'Uang terlihat utuh',
        MoneyDebugState.ug04 => 'Memproses',
        MoneyDebugState.ug05 => 'Terdeteksi yakin (Rp50.000)',
        MoneyDebugState.ug06 => 'Ragu',
        MoneyDebugState.ug07 => 'Bukan uang',
        MoneyDebugState.ug08 => 'Tidak terdeteksi (5 detik)',
        MoneyDebugState.ug10 => 'Terlipat / terpotong',
        MoneyDebugState.ug12a => 'Silau',
        MoneyDebugState.ug12b => 'Gelap',
        MoneyDebugState.ug13 => 'Offline',
        MoneyDebugState.ug14 => 'Izin kamera belum ada',
        MoneyDebugState.ug15 => 'Senyap / TTS mati',
        MoneyDebugState.ug16 => 'Font scale 200%',
        MoneyDebugState.ug18 => 'Uang asing / rusak',
      };
}

enum _CardPlacement { center, bottomSlot }

/// Deskripsi render untuk satu momen layar - dihasilkan baik dari
/// [MoneyProvider] (otomatis) maupun dari [MoneyDebugState] (paksa manual).
class _RenderSpec {
  /// Satu baris panduan di atas BottomActionBar.
  ///
  /// Menggantikan trio `frame` / `frameDefaultCaption` / `pillOverride` yang
  /// tertinggal setelah GuideFrame dihapus. Ketiganya masih diisi rajin oleh
  /// [_specForState] tapi tidak ada satu pun yang dibaca `build` lagi, jadi
  /// seluruh panduan mode ini - "Miringkan sedikit", "Dekatkan sedikit
  /// uangnya", rotasi [MoneyProvider.noCandidateHint] yang berganti tiap 5
  /// detik - hilang dari layar tanpa ada yang menghapusnya dengan sengaja.
  ///
  /// Kalimatnya ditulis ulang tanpa kata "bingkai": tidak ada lagi bingkai
  /// panduan di layar ini, kamera memotret seluruh gambar. Menyuruh pengguna
  /// menaruh uang "di dalam bingkai" berarti menyuruhnya mencari sesuatu yang
  /// tidak ada, lalu menunggu tanda yang tidak akan pernah muncul.
  final String? hint;
  final bool badgeBusy;
  final Widget? card;
  final _CardPlacement cardPlacement;
  final String? note;
  final bool healthToastDark;

  const _RenderSpec({
    this.hint,
    this.badgeBusy = false,
    this.card,
    this.cardPlacement = _CardPlacement.bottomSlot,
    this.note,
    this.healthToastDark = false,
  });
}

const _moneyAckPattern = [0, 40, 60, 40, 60, 40];
const _positivePattern = [0, 25, 45, 25];

/// Panduan satu baris di atas BottomActionBar.
///
/// Bentuknya sengaja pill gelap tanpa ikon dan tanpa tombol: ia bukan hasil,
/// bukan peringatan, dan tidak menuntut apa pun. Kalimatnya berganti mengikuti
/// keadaan, jadi ia TIDAK dipasang sebagai `liveRegion` - mode ini sudah
/// membacakan panduannya sendiri lewat TTS, dan node semantik yang berubah
/// tiap beberapa detik akan memotong ucapan itu di tengah jalan.
class _HintPill extends StatelessWidget {
  final String text;
  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          decoration: const BoxDecoration(
            color: AppColors.scrimText,
            borderRadius: AppRadius.pillShape,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.onDark),
          ),
        ),
      ),
    );
  }
}

class _MoneyScreenState extends State<MoneyScreen> with WidgetsBindingObserver {
  // ── Rujukan provider untuk dispose() ──────────────────────────────────
  //
  // `context.read` DILARANG di dalam dispose(): elemennya sudah tidak aktif,
  // jadi pencarian ancestor melempar "Looking up a deactivated widget's
  // ancestor is unsafe". Karena galatnya jatuh di baris PERTAMA yang membaca
  // provider, seluruh pelepasan sesudahnya tidak pernah berjalan - handler
  // dan stream kamera milik mode ini tetap hidup sesudah modenya ditinggalkan.
  // Rujukannya karena itu dicatat saat dependensi siap.
  late MoneyProvider _money;
  late VoiceProvider _voice;
  late CameraProvider _cam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _money = context.read<MoneyProvider>();
    _voice = context.read<VoiceProvider>();
    _cam = context.read<CameraProvider>();
  }

  MoneyDebugState? _debugOverride;
  bool _hasCameraPermission = true;
  bool _offlineBannerShownOnce = false;
  bool _offlineAutoHideScheduled = false;
  Timer? _offlineHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Prinsip 6 "umumkan saat tiba" - sesudah layar terpasang.
      context.read<AppModeProvider>().announceEntry(AppMode.money);
      final money = context.read<MoneyProvider>();
      money.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);

      // Kontrak tombol kiri: "jepret" lewat suara = menekan tombol kiri.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = money.snapAndAnnounce;
      voice.primaryActionLabel = () => 'mengenali uang';
      voice.onRepeatLast = () {
        if (money.lastAmount > 0) {
          context.read<TtsProvider>().speak(
                terbilangRupiah(money.lastAmount),
                tier: SpeechTier.info,
              );
        } else {
          context.read<TtsProvider>().speak(
                'Belum ada nominal yang terbaca.',
                tier: SpeechTier.info,
              );
        }
      };
      money.onHaptic = (p) {
        switch (p) {
          case MoneyHaptic.positive:
            _fireHaptic(_positivePattern);
        }
      };

      // Klasifikasi nominal berjalan SEPENUHNYA di perangkat. Kalau file
      // model belum ada, provider otomatis jatuh ke siklus mock supaya
      // seluruh 18 state tetap bisa diperiksa.
      final realModel = await money.enableRealModel();
      if (!mounted) return;
      debugPrint('[MoneyScreen] model on-device: ${realModel ? "aktif" : "belum ada, pakai mock"}');

      if (_hasCameraPermission) {
        final cam = context.read<CameraProvider>();
        if (realModel) cam.onFrameReady = money.submitFrame;
        cam.startStream();
        money.start();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineHideTimer?.cancel();
    _money.onSpeak = null;
    _money.onHaptic = null;
    _money.pause();
    _voice.clearModeHandlers();
    _cam.onFrameReady = null;
    _cam.onFramesInvalidated = null;
    _cam.stopStream();
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
        if (!mounted) return;
        cam.startStream();
        context.read<MoneyProvider>().start();
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
      if (!mounted) return;
      cam.startStream();
      context.read<MoneyProvider>().start();
      await context.read<TtsProvider>().speak('Izin diberikan.', tier: SpeechTier.info);
    } else {
      await context.read<TtsProvider>().speak('Izin kamera belum diberikan.', tier: SpeechTier.warning);
    }
  }

  Future<void> _fireHaptic(List<int> pattern) async {
    if (!mounted) return;
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (has) Vibration.vibrate(pattern: pattern);
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugStateSheet(
        current: _debugOverride,
        onSelect: (d) {
          Navigator.pop(sheetCtx);
          final money = context.read<MoneyProvider>();
          setState(() => _debugOverride = d);
          if (d == null) {
            money.start();
          } else {
            money.pause();
            if (d == MoneyDebugState.ug15) _fireHaptic(_moneyAckPattern);
          }
        },
      ),
    );
  }

  /// Putar ulang nominal terakhir.
  ///
  /// Pagarnya ikut diputar ulang. Kalau tidak, tombol replay jadi celah yang
  /// mengubah tebakan jadi kepastian hanya karena pengguna menekannya dua
  /// kali - persis bahaya yang dijaga [MoneyResult.certain].
  void _replay(int amount, {bool certain = true}) {
    context.read<TtsProvider>().speak(
          certain
              ? terbilangRupiah(amount)
              : 'Sepertinya ${terbilangRupiah(amount)}.',
          tier: certain ? SpeechTier.info : SpeechTier.warning,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final money = context.watch<MoneyProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final rawBottomInset = media.padding.bottom;

    final showPermissionCard =
        _debugOverride == MoneyDebugState.ug14 || (_debugOverride == null && !_hasCameraPermission);

    // Slot lampu: nominal uang tidak terbaca sama sekali di ruang gelap, jadi
    // mode ini termasuk yang lampunya menentukan berhasil atau tidak.
    final showTorchSlot =
        TorchSlot.visible(cam, hasCameraPermission: _hasCameraPermission);
    // Semua kartu dan panel di layar ini berpatokan pada `bottomInset`, jadi
    // menambahkan tinggi slot di satu tempat menggeser semuanya sekaligus.
    final bottomInset =
        rawBottomInset + (showTorchSlot ? TorchSlot.slotHeight : 0);

    final showOfflineBanner = _debugOverride == MoneyDebugState.ug13 ||
        (_debugOverride == null && offline && !_offlineBannerShownOnce);

    if (showOfflineBanner && _debugOverride == null && !_offlineAutoHideScheduled) {
      _offlineAutoHideScheduled = true;
      _offlineHideTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() => _offlineBannerShownOnce = true);
      });
    }

    final badgeTop = topInset +
        AppSpacing.s2 +
        (modeBadgeTopOffset(hasBanner: showOfflineBanner) - ZonePositions.modeBadgeY);
    final chipTop = topInset +
        AppSpacing.s2 +
        (secondaryChipTopOffset(hasBanner: showOfflineBanner) - ZonePositions.modeBadgeY);

    final spec = showPermissionCard
        ? null
        : _debugOverride != null
            ? _specForDebug(_debugOverride!)
            : _specForState(money);

    final fontScaleDemo = _debugOverride == MoneyDebugState.ug16;

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // z0 - kamera adalah lantai, full bleed.
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (showOfflineBanner)
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: MediaQuery(
                data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
                child: const StatusBanner(
                  tier: AlertTier.info,
                  message: 'Tanpa internet. Deteksi tetap berjalan di perangkat.',
                ),
              ),
            ),

          // z25 - ModeBadge, turun otomatis kalau banner hadir.
          Positioned(
            top: badgeTop,
            left: AppSpacing.screenMargin,
            child: MediaQuery(
              data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
              child: ModeBadge(
                mode: AppMode.money,
                busy: spec?.badgeBusy ?? false,
                onDebugActivate: _openDebugSheet,
              ),
            ),
          ),

          if (spec?.healthToastDark == true)
            Positioned(
              top: chipTop,
              left: AppSpacing.screenMargin,
              child: const CameraHealthToast(issue: CameraHealthIssue.dark),
            ),

          if (showPermissionCard)
            // UG-14 - kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera diperlukan',
              reason: 'Kenali Uang butuh kamera untuk melihat uang di depanmu. Semua diproses di perangkat.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (spec != null) ...[
            if (spec.card != null && spec.cardPlacement == _CardPlacement.center)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spec.card!,
                      if (spec.note != null) ...[
                        const SizedBox(height: AppSpacing.s3),
                        MediaQuery(
                          data: media.copyWith(
                            textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler,
                          ),
                          child: Text(
                            spec.note!,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption(color: AppColors.onDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (spec.card != null && spec.cardPlacement == _CardPlacement.bottomSlot)
              Positioned(
                left: AppSpacing.screenMargin,
                right: AppSpacing.screenMargin,
                bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
                child: MediaQuery(
                  data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
                  child: spec.card!,
                ),
              ),
          ],

          // Panduan satu baris. Hanya saat tidak ada kartu di slot bawah -
          // keduanya menempati tempat yang sama, dan kartu selalu membawa
          // kabar yang lebih penting daripada panduan mengarahkan kamera.
          if (spec?.hint != null && spec?.card == null)
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
              child: MediaQuery(
                data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
                child: _HintPill(text: spec!.hint!),
              ),
            ),

          if (showTorchSlot)
            Positioned(
              left: 0, right: 0,
              bottom: rawBottomInset + AppSizes.bottomActionBarHeight,
              child: TorchSlot(
                cam: cam,
                dismissMessage:
                    'Baik, lampu tidak dinyalakan. Kenali Uang tetap berjalan.',
              ),
            ),

          // z60 - BottomActionBar, selalu ada, selalu di tempat yang sama.
          // Tombol kiri = "Kenali Uang": snap frame saat ini, umumkan hasilnya.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery(
              data: media.copyWith(textScaler: fontScaleDemo ? const TextScaler.linear(2.0) : media.textScaler),
              child: BottomActionBar(
                cameraLabel: 'Kenali Uang',
                cameraEnabled: !showPermissionCard && !money.isUnavailable,
                cameraDisabledReason: showPermissionCard
                    ? 'izin kamera belum diberikan'
                    : 'model pengenalan uang belum siap',
                onCameraPressed: () {
                  if (_debugOverride != null) {
                    setState(() => _debugOverride = null);
                    money.start();
                    return;
                  }
                  money.snapAndAnnounce();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- auto → spec

  _RenderSpec _specForState(MoneyProvider p) {
    switch (p.state) {
      case MoneyState.idle:
        return const _RenderSpec(
          hint: 'Arahkan kamera ke uang, lalu tekan Kenali Uang',
          cardPlacement: _CardPlacement.bottomSlot,
        );
      case MoneyState.noCandidate:
        return _RenderSpec(hint: p.noCandidateHint);
      case MoneyState.partial:
        return const _RenderSpec(hint: 'Uangnya belum terlihat utuh, mundur sedikit');
      case MoneyState.folded:
        return const _RenderSpec(hint: 'Ratakan uangnya, ada bagian yang tertekuk');
      case MoneyState.fit:
        return const _RenderSpec(hint: 'Uang terlihat, tekan Kenali Uang');
      case MoneyState.glare:
        return const _RenderSpec(hint: 'Miringkan sedikit, ada pantulan cahaya');
      case MoneyState.dark:
        return const _RenderSpec(
          healthToastDark: true,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Terlalu gelap',
            description: 'Coba nyalakan senter kamera atau cari cahaya lebih terang.',
          ),
        );
      case MoneyState.processing:
        return const _RenderSpec(badgeBusy: true);
      case MoneyState.detected:
        return _RenderSpec(
          card: NominalCard(
            amount: p.lastAmount,
            certain: p.lastAnswerCertain,
            onReplay: () => _replay(p.lastAmount, certain: p.lastAnswerCertain),
          ),
        );
      case MoneyState.uncertain:
        // Pratinjau, BUKAN penghalang. Sebelumnya keadaan ini memunculkan
        // kartu peringatan "Belum yakin" yang menutup layar tanpa memberi
        // jalan keluar - uang yang tergeletak di meja lalu difoto sambil
        // berdiri hampir selalu berakhir di sini. Sekarang cuma pill netral:
        // tombolnya tetap bisa ditekan, dan tetap menjawab dengan nominal
        // berpagar.
        return const _RenderSpec(
          hint: 'Uang terlihat, tekan tombol untuk membaca nominal',
        );
      case MoneyState.notMoney:
        return _RenderSpec(
          card: AlertCard(
            tier: AlertTier.info,
            title: 'Ini sepertinya ${p.notMoneyLabel}',
            description: 'Bukan uang. Coba arahkan ke lembaran uang.',
          ),
        );
      case MoneyState.foreign:
        return const _RenderSpec(
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Uang asing atau rusak',
            description: 'Belum bisa membaca nilainya. Nilai tukar tidak ditebak.',
          ),
        );
    }
  }

  // -------------------------------------------------------- debug → spec

  _RenderSpec _specForDebug(MoneyDebugState d) {
    switch (d) {
      case MoneyDebugState.ug01:
        return const _RenderSpec(hint: 'Arahkan kamera ke uang, lalu tekan Kenali Uang');
      case MoneyDebugState.ug02:
        return const _RenderSpec(hint: 'Uangnya belum terlihat utuh, mundur sedikit');
      case MoneyDebugState.ug03:
        return const _RenderSpec(hint: 'Uang terlihat, tekan Kenali Uang');
      case MoneyDebugState.ug04:
        return const _RenderSpec(badgeBusy: true);
      case MoneyDebugState.ug05:
        return _RenderSpec(card: NominalCard(amount: 50000, onReplay: () => _replay(50000)));
      case MoneyDebugState.ug06:
        // UG-06 sekarang berwujud kartu nominal berpagar, bukan penolakan
        // menjawab. Panel debug harus menampilkan yang sama dengan produksi,
        // kalau tidak ia berhenti berguna untuk memeriksa keadaan ini.
        return _RenderSpec(
          card: NominalCard(
            amount: 50000,
            certain: false,
            onReplay: () => _replay(50000, certain: false),
          ),
        );
      case MoneyDebugState.ug07:
        return const _RenderSpec(
          card: AlertCard(tier: AlertTier.info, title: 'Ini sepertinya kartu', description: 'Bukan uang.'),
        );
      case MoneyDebugState.ug08:
        return const _RenderSpec(hint: 'Cari tempat yang lebih terang');
      case MoneyDebugState.ug10:
        return const _RenderSpec(hint: 'Ratakan uangnya, ada bagian yang tertekuk');
      case MoneyDebugState.ug12a:
        return const _RenderSpec(hint: 'Miringkan sedikit, ada pantulan cahaya');
      case MoneyDebugState.ug12b:
        return const _RenderSpec(
          healthToastDark: true,
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Terlalu gelap',
            description: 'Coba nyalakan senter kamera atau cari cahaya lebih terang.',
          ),
        );
      case MoneyDebugState.ug13:
        // Banner-nya sendiri dirender terpisah (showOfflineBanner) - konten
        // di baliknya tetap jalan normal (deteksi on-device tak terpengaruh).
        return _RenderSpec(card: NominalCard(amount: 20000, onReplay: () => _replay(20000)));
      case MoneyDebugState.ug14:
        return const _RenderSpec(); // ditangani lewat showPermissionCard
      case MoneyDebugState.ug15:
        return _RenderSpec(
          card: NominalCard(amount: 25000, onReplay: () => _replay(25000)),
          note: 'TTS senyap: kartu bertahan sampai deteksi berikutnya, getar 3× pendek menandai deteksi.',
        );
      case MoneyDebugState.ug16:
        return _RenderSpec(card: NominalCard(amount: 75000, onReplay: () => _replay(75000)));
      case MoneyDebugState.ug18:
        return const _RenderSpec(
          card: AlertCard(
            tier: AlertTier.warning,
            title: 'Uang asing atau rusak',
            description: 'Belum bisa membaca nilainya. Nilai tukar tidak ditebak.',
          ),
        );
    }
  }
}

class _DebugStateSheet extends StatelessWidget {
  final MoneyDebugState? current;
  final ValueChanged<MoneyDebugState?> onSelect;

  const _DebugStateSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            child: SheetHeader(
              title: 'Panel debug - Kenali Uang',
              closeLabel: 'Tutup panel debug',
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
              children: [
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded, color: AppColors.actionLabel),
                  title: const Text('Kembali ke mode otomatis'),
                  selected: current == null,
                  onTap: () => onSelect(null),
                ),
                const Divider(height: 1),
                for (final d in MoneyDebugState.values)
                  ListTile(
                    dense: true,
                    selected: current == d,
                    selectedTileColor: AppColors.actionTint,
                    title: Text('${d.id} - ${d.title}', style: AppTypography.body()),
                    onTap: () => onSelect(d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
