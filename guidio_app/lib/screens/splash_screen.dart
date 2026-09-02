import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';

/// SP-01 - Splash. Logo tampil, narasi TTS mulai di milidetik pertama,
/// durasi maksimum 2000 ms sebelum lanjut ke langkah berikutnya.
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

    // Kalau suara Bahasa Indonesia tidak terpasang, katakan SEKARANG.
    //
    // Ini satu-satunya momen yang tepat: sesudahnya seluruh aplikasi adalah
    // suara, dan kalau suaranya sendiri yang bermasalah, pengguna tunanetra
    // tidak punya cara lain mengetahuinya. Peringatannya diucapkan dengan
    // mesin yang bermasalah itu juga, dan memang begitu adanya - fonetiknya
    // mungkin aneh, tapi setidaknya ada yang terdengar dan bisa ditindaklanjuti
    // oleh pendamping awas di dekatnya.
    final warning = TTSService.instance.healthWarning;
    if (warning != null) {
      TTSService.instance.speak(warning);
    }

    // Splash tidak boleh menutup di tengah peringatan. 2000 ms cukup untuk
    // "Vinara. Menyiapkan"; kalimat peringatannya jauh lebih panjang.
    Future.delayed(
      Duration(milliseconds: warning == null ? 2000 : 7000),
      () {
        if (mounted) widget.onDone();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          child: Image.asset(
            'assets/icons/app_splash_screen.png',
            fit: BoxFit.contain,
            width: 280,
          ),
        ),
      ),
    );
  }
}
