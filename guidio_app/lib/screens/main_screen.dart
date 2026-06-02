import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/index.dart';
import '../screens/index.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // [1] Request permission kamera lebih dulu (sequential) — hindari
    //     "Can request only one set of permissions at a time" warning
    await Permission.camera.request();

    // [2] Init paralel: kamera + inference + voice
    try {
      await Future.wait([
        context.read<CameraProvider>().initCamera(),
        context.read<InferenceProvider>().initialize(),
        context.read<VoiceProvider>().init(),
      ]);
    } catch (e) {
      debugPrint('[MainScreen] Init error: $e');
      // Lanjut meski ada error — biarkan UI menampilkan state yang ada
    }

    if (!mounted) return;
    setState(() => _booting = false);

    final cam = context.read<CameraProvider>();
    final inf = context.read<InferenceProvider>();

    if (!cam.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin kamera ditolak. Fitur kamera tidak tersedia.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
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
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const _BootScreen();
    }

    final mode = context.watch<AppModeProvider>().mode;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (mode) {
          AppMode.tuntun   => const TuntunScreen(),
          AppMode.ocr      => const OcrScreen(),
          AppMode.navigasi => const NavigasiScreen(),
          AppMode.voice    => const VoiceScreen(),
        },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final inf = context.watch<InferenceProvider>();

    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Memulai Guidio...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Menyiapkan kamera dan AI',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
