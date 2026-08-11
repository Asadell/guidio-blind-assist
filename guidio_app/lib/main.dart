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
        // Providers tanpa dependency
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
        ChangeNotifierProvider(create: (_) => InferenceProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MoneyProvider()),
        ChangeNotifierProvider(create: (_) => FindObjectProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => GlobalConditionsProvider()..init()),

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
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          return MaterialApp(
            title: 'Guidio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: switch (settings.themeMode) {
              AppThemeMode.dark => AppTheme.dark,
              AppThemeMode.highContrast => AppTheme.highContrast,
              AppThemeMode.light => AppTheme.light,
            },
            themeMode: settings.themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
            builder: (context, child) {
              final scaler = TextScaler.linear(settings.fontScale);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaler),
                child: child!,
              );
            },
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
