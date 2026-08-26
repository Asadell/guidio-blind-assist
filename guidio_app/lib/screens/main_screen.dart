import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/index.dart';
import '../screens/index.dart';
import '../theme/index.dart';

enum _BootStage { splash, onboarding, permissions, initializing, ready }

/// MainScreen - mengelola alur boot (bagian 6 & 13): Splash → Onboarding
/// (hanya pertama kali) → Izin → mode default (Deteksi Objek). Tidak ada
/// layar beranda: setelah boot, aplikasi langsung berada di salah satu dari
/// enam mode sejajar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  _BootStage _stage = _BootStage.splash;

  Future<void> _afterSplash() async {
    // Tunggu SettingsProvider selesai memuat onboarding_done dari disk.
    final settings = context.read<SettingsProvider>();
    while (!settings.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    if (!mounted) return;
    setState(() => _stage = settings.onboardingDone ? _BootStage.permissions : _BootStage.onboarding);
    if (_stage == _BootStage.permissions) await _checkPermissions();
  }

  Future<void> _afterOnboarding() async {
    await context.read<SettingsProvider>().setOnboardingDone(true);
    setState(() => _stage = _BootStage.permissions);
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraGranted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (cameraGranted) {
      setState(() => _stage = _BootStage.initializing);
      await _initServices();
    } else {
      setState(() => _stage = _BootStage.permissions);
    }
  }

  Future<void> _afterPermissions() async {
    setState(() => _stage = _BootStage.initializing);
    await _initServices();
  }

  Future<void> _initServices() async {
    // Kamera error jadi kondisi global (banner Critical), bukan kegagalan
    // diam-diam yang hanya terlihat sebagai layar hitam.
    final globals = context.read<GlobalConditionsProvider>();
    context.read<CameraProvider>().onErrorChanged = globals.setCameraError;

    try {
      await Future.wait([
        context.read<CameraProvider>().initCamera(),
        context.read<InferenceProvider>().initialize(),
        context.read<VoiceProvider>().init(),
      ]);
    } catch (e) {
      debugPrint('[MainScreen] Init error: $e');
    }

    if (!mounted) return;
    setState(() => _stage = _BootStage.ready);
    // Status kamera & backend offline ditangani oleh StatusBanner
    // dan GlobalConditionsProvider di tiap mode screen - tidak perlu
    // SnackBar di sini yang menutupi BottomActionBar.
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _BootStage.splash:
        return SplashScreen(onDone: _afterSplash);
      case _BootStage.onboarding:
        return OnboardingScreen(onDone: _afterOnboarding);
      case _BootStage.permissions:
        return PermissionsScreen(onDone: _afterPermissions);
      case _BootStage.initializing:
        return const _BootScreen();
      case _BootStage.ready:
        final mode = context.watch<AppModeProvider>().mode;
        // Tidak ada AnimatedSwitcher di sini, dan itu disengaja.
        //
        // AnimatedSwitcher menahan layar mode LAMA tetap hidup selama animasi
        // (300 ms) sementara layar mode BARU sudah terpasang dan sudah
        // menjalankan post-frame callback-nya. Dua akibatnya nyata, dan
        // keduanya sampai ke pengguna:
        //
        // 1. `dispose()` layar lama - yang memanggil `cam.stopStream()`,
        //    `cam.onFrameReady = null`, dan `voice.clearModeHandlers()` -
        //    berjalan SESUDAH layar baru memasang miliknya. Mode yang baru
        //    dibuka kehilangan aliran frame dan handler tombol kirinya tanpa
        //    satu pun error: layarnya terlihat normal, tombolnya tidak
        //    melakukan apa-apa.
        // 2. Kedua layar sama-sama menggambar `CameraPreview` dari controller
        //    yang sama. Saat mode baru meminta preset berbeda - Baca Teks dan
        //    Cari Objek meminta `capture` - controller lama dibuang sementara
        //    layar lama masih memegangnya, dan Flutter melempar
        //    "A CameraController was used after being disposed". Itulah kotak
        //    merah yang berkedip sesaat lalu hilang begitu animasinya habis.
        //
        // Tanpa AnimatedSwitcher, layar lama di-dispose di frame yang sama,
        // sebelum post-frame callback layar baru berjalan. Urutannya benar
        // karena strukturnya, bukan karena kebetulan waktu.
        return Scaffold(
          body: switch (mode) {
            AppMode.tuntun     => const TuntunScreen(),
            AppMode.money      => const MoneyScreen(),
            AppMode.ocr        => const OcrScreen(),
            AppMode.navigasi   => const NavigasiScreen(),
            AppMode.voice      => const VoiceScreen(),
            AppMode.findObject => const FindObjectScreen(),
          },
        );
    }
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink1,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.actionFill,
                strokeWidth: 3,
              ),
              const SizedBox(height: AppSpacing.s6),
              Text('Memulai Vinara…', style: AppTypography.title(color: AppColors.onDark)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Menyiapkan kamera dan AI',
                style: AppTypography.body(color: AppColors.onDark.withValues(alpha: .6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
