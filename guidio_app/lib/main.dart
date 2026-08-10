import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/index.dart';
import 'screens/index.dart';
import 'services/tts_service.dart';
import 'theme/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only — sesuai PRD
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Init TTS di awal
  await TTSService.instance.init();

  runApp(const GuidioApp());
}

class GuidioApp extends StatelessWidget {
  const GuidioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AppMode — tidak ada dependency
        ChangeNotifierProvider(create: (_) => AppModeProvider()),

        // InferenceProvider — tidak ada dependency
        ChangeNotifierProvider(create: (_) => InferenceProvider()),

        // CameraProvider — tidak ada dependency
        ChangeNotifierProvider(create: (_) => CameraProvider()),

        // TtsProvider — tidak ada dependency
        ChangeNotifierProvider(create: (_) => TtsProvider()),

        // NavigationProvider — tidak ada dependency
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // DetectionProvider — butuh InferenceProvider + CameraProvider
        ChangeNotifierProxyProvider2<InferenceProvider, CameraProvider, DetectionProvider>(
          create: (ctx) => DetectionProvider(
            ctx.read<InferenceProvider>(),
            ctx.read<CameraProvider>(),
          ),
          update: (ctx, inf, cam, prev) =>
              prev ?? DetectionProvider(inf, cam),
        ),

        // VoiceProvider — butuh CameraProvider + DetectionProvider
        ChangeNotifierProxyProvider2<CameraProvider, DetectionProvider, VoiceProvider>(
          create: (ctx) => VoiceProvider(
            ctx.read<CameraProvider>(),
            ctx.read<DetectionProvider>(),
          ),
          update: (ctx, cam, det, prev) =>
              prev ?? VoiceProvider(cam, det),
        ),
      ],
      child: MaterialApp(
        title:           'Guidio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainScreen(),
      ),
    );
  }
}
