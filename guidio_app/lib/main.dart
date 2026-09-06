import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/index.dart';
import 'screens/index.dart';
import 'services/translation_service.dart';
import 'services/tts_service.dart';
import 'theme/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only - sesuai PRD
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Init TTS di awal
  await TTSService.instance.init();

  // Model terjemahan Inggris → Indonesia (mode Deskripsi Sekitar) diunduh di
  // LATAR, sengaja tanpa `await`.
  //
  // Unduhan pertamanya sekitar 30 MB per bahasa dan hanya terjadi sekali
  // seumur pemasangan. Menahan `runApp` untuk itu berarti pengguna tunanetra
  // menatap - lebih tepatnya mendengar - layar kosong tanpa penjelasan di
  // pembukaan pertama, pada fitur yang bahkan mungkin tidak dia pakai hari itu.
  //
  // Selama unduhannya belum selesai, `toIndonesian` mengembalikan null dan
  // mode Deskripsi Sekitar jatuh ke jalur lamanya (caption Bahasa Inggris
  // dengan penanda lisan). Jadi keterlambatan di sini menurunkan kualitas
  // jawaban, tidak pernah mematikan fiturnya.
  unawaited(TranslationService.instance.prewarm());

  runApp(const GuidioApp());
}

class GuidioApp extends StatelessWidget {
  const GuidioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // SettingsProvider didaftarkan paling awal: ia sumber kebenaran untuk
        // alamat server, kecerewetan, dan ambang jarak - dan provider lain
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

        // DetectionProvider - hanya butuh CameraProvider (jalur deteksi
        // sepenuhnya on-device), dan ikut mendengarkan SettingsProvider supaya
        // PG-05 (kecerewetan) dan PG-06 (ambang jarak) benar-benar mengubah
        // perilaku deteksi. Tanpa sambungan ini keduanya hanya tersimpan ke disk.
        ChangeNotifierProxyProvider2<CameraProvider, SettingsProvider, DetectionProvider>(
          create: (ctx) => DetectionProvider(ctx.read<CameraProvider>()),
          update: (ctx, cam, settings, prev) {
            final provider = prev ?? DetectionProvider(cam);
            provider.applySettings(
              maxDistanceM: settings.distanceThresholdM,
              verbosity: settings.verbosity,
            );
            return provider;
          },
        ),

        // VoiceProvider - butuh CameraProvider + DetectionProvider +
        // AppModeProvider + FindObjectProvider. AppModeProvider ikut disuntik
        // supaya perintah suara "buka mode X" memindah state SENDIRI, tanpa
        // bergantung layar yang sedang aktif memasang callback (bagian 4.1:
        // konfirmasi TTS tidak boleh mendahului perubahan state).
        // FindObjectProvider disuntik untuk mendukung perintah suara
        // "carikan [barang]" dari mode mana pun (fitur Jarvis Global Mic).
        ChangeNotifierProxyProvider4<CameraProvider, DetectionProvider, AppModeProvider, FindObjectProvider, VoiceProvider>(
          create: (ctx) => VoiceProvider(
            ctx.read<CameraProvider>(),
            ctx.read<DetectionProvider>(),
            ctx.read<AppModeProvider>(),
            ctx.read<FindObjectProvider>(),
          ),
          update: (ctx, cam, det, appMode, findObj, prev) =>
              prev ?? VoiceProvider(cam, det, appMode, findObj),
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          return MaterialApp(
            title: 'Guidio',
            debugShowCheckedModeBanner: false,

            // ── Bahasa antarmuka DIKUNCI ke Bahasa Indonesia ───────────────
            //
            // Bukan preferensi gaya. Seluruh antarmuka aplikasi ini adalah
            // SUARA, dan suaranya Bahasa Indonesia (`TTSService.localeId`).
            // Tanpa baris-baris ini MaterialApp jatuh ke
            // `DefaultMaterialLocalizations`, yang hanya punya bahasa
            // Inggris, dan setiap label bawaan yang tidak kita tulis sendiri
            // ikut keluar dalam bahasa itu: pengumuman lembar bawah, tombol
            // tutup dialog, label dismiss di balik scrim, nama peran kontrol.
            //
            // Yang membaca label-label itu adalah TalkBack lewat mesin suara
            // Bahasa Indonesia. "Dismiss" dibacakan dengan fonetik Indonesia
            // bukan menjadi kata Inggris beraksen - ia menjadi bunyi yang
            // bukan kata dalam bahasa mana pun. Pengguna tunanetra Indonesia
            // tidak punya layar untuk memeriksa apa yang barusan disebut.
            //
            // `locale` sengaja dipatok, bukan dibiarkan mengikuti perangkat:
            // ponsel yang bahasanya masih Inggris tetap harus menjalankan
            // aplikasi ini dalam Bahasa Indonesia, karena suaranya memang
            // hanya ada dalam Bahasa Indonesia.
            locale: const Locale('id', 'ID'),
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

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
