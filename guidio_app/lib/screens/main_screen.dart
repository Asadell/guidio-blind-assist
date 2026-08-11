import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/index.dart';
import '../screens/index.dart';
import '../theme/index.dart';

enum _BootStage { splash, onboarding, permissions, initializing, ready }

/// MainScreen — mengelola alur boot (bagian 6 & 13): Splash → Onboarding
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

    final cam = context.read<CameraProvider>();
    final inf = context.read<InferenceProvider>();

    if (!cam.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin kamera ditolak. Fitur kamera tidak tersedia.'),
          backgroundColor: AppColors.criticalLabel,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Pengaturan',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
    } else if (!inf.serverReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend tidak terhubung. Berjalan di Mode Lokal (TFLite). Fitur Voice & OCR mungkin tidak tersedia.'),
          backgroundColor: AppColors.warningLabel,
          duration: Duration(seconds: 4),
        ),
      );
    }
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
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (mode) {
              AppMode.tuntun     => const TuntunScreen(),
              AppMode.money      => const MoneyScreen(),
              AppMode.ocr        => const OcrScreen(),
              AppMode.navigasi   => const NavigasiScreen(),
              AppMode.voice      => const VoiceScreen(),
              AppMode.findObject => const FindObjectScreen(),
            },
          ),
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
              Text('Memulai Vinara…', style: AppTypography.title(color: Colors.white)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Menyiapkan kamera dan AI',
                style: AppTypography.body(color: Colors.white.withValues(alpha: .6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
