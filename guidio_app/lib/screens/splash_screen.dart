import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';

/// SP-01 — Splash. Logo tampil, narasi TTS mulai di milidetik pertama,
/// durasi maksimum 900 ms sebelum lanjut ke langkah berikutnya.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    TTSService.instance.speak('Vinara. Menyiapkan…');
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink1,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.actionFill, shape: BoxShape.circle),
              child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text('Vinara', style: AppTypography.headline(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
