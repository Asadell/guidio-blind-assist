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
        // SettingsProvider didaftarkan paling awal: ia sumber kebenaran untuk
        // alamat server, kecerewetan, dan ambang jarak — dan provider lain
        // membacanya lewat proxy di bawah.
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),

        // Providers tanpa dependency
        ChangeNotifierProvider(create: (_) => InferenceProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MoneyProvider()),
        ChangeNotifierProvider(create: (_) => FindObjectProvider()),
        ChangeNotifierProvider(create: (_) => GlobalConditionsProvider()..init()),
        ChangeNotifierProvider(create: (_) => CapabilitiesProvider()),

        // AppModeProvider ikut PG-05: kecerewetan mengubah panjang pengumuman
        // saat masuk mode.
        ChangeNotifierProxyProvider<SettingsProvider, AppModeProvider>(
          create: (_) => AppModeProvider(),
          update: (_, settings, prev) =>
              (prev ?? AppModeProvider())..applyVerbosity(settings.verbosity),
        ),

        // DetectionProvider — butuh InferenceProvider + CameraProvider, dan
        // ikut mendengarkan SettingsProvider supaya PG-05 (kecerewetan) dan
        // PG-06 (ambang jarak) benar-benar mengubah perilaku deteksi. Tanpa
        // sambungan ini keduanya hanya tersimpan ke disk.
        ChangeNotifierProxyProvider3<InferenceProvider, CameraProvider, SettingsProvider, DetectionProvider>(
          create: (ctx) => DetectionProvider(
            ctx.read<InferenceProvider>(),
            ctx.read<CameraProvider>(),
          ),
          update: (ctx, inf, cam, settings, prev) {
            final provider = prev ?? DetectionProvider(inf, cam);
            provider.applySettings(
              maxDistanceM: settings.distanceThresholdM,
              verbosity: settings.verbosity,
            );
            return provider;
          },
        ),

        // VoiceProvider — butuh CameraProvider + DetectionProvider +
        // AppModeProvider. AppModeProvider ikut disuntik supaya perintah suara
        // "buka mode X" memindah state SENDIRI, tanpa bergantung layar yang
        // sedang aktif memasang callback (bagian 4.1: konfirmasi TTS tidak
        // boleh mendahului perubahan state).
        ChangeNotifierProxyProvider3<CameraProvider, DetectionProvider, AppModeProvider, VoiceProvider>(
          create: (ctx) => VoiceProvider(
            ctx.read<CameraProvider>(),
            ctx.read<DetectionProvider>(),
            ctx.read<AppModeProvider>(),
          ),
          update: (ctx, cam, det, appMode, prev) =>
              prev ?? VoiceProvider(cam, det, appMode),
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
