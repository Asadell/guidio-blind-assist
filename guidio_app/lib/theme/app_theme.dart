import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData Vinara — dirakit dari token di app_colors / app_typography /
/// app_spacing. Dipasang sekali di MaterialApp.theme.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.actionLabel,
        primary: AppColors.actionLabel,
        secondary: AppColors.actionFill,
        error: AppColors.criticalLabel,
        surface: AppColors.bgPage,
      ),
      scaffoldBackgroundColor: AppColors.bgPage,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTypography.headline(),
        titleLarge: AppTypography.title(),
        bodyLarge: AppTypography.body(),
        bodyMedium: AppTypography.body(),
        labelLarge: AppTypography.label(),
        bodySmall: AppTypography.caption(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.ink1,
        elevation: 0,
        titleTextStyle: AppTypography.title(),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink1, size: 24),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionLabel,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          textStyle: AppTypography.label(color: Colors.white),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillShape),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.actionLabel,
          side: const BorderSide(color: AppColors.actionLabel),
          minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          textStyle: AppTypography.label(color: AppColors.actionLabel),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionLabel,
          textStyle: AppTypography.label(color: AppColors.actionLabel),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: AppTypography.body(color: AppColors.ink2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.pillBg,
        contentTextStyle: AppTypography.body(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  /// Tema gelap — chrome Material (AppBar, tombol, snackbar, scaffold).
  /// Catatan: komponen desain sistem (AlertCard, ModeBadge, dst.) memakai
  /// token AppColors langsung sehingga tetap tampil dengan palet terang di
  /// atas kamera — itu memang benar untuk pill/kartu yang melayang di atas
  /// video, tapi permukaan non-kamera (Settings, Onboarding) mengikuti tema
  /// gelap lewat ThemeData ini.
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.actionFill,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF15171E),
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF15171E), elevation: 0),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2D38), thickness: 1, space: 1),
    );
  }

  /// Tema kontras tinggi — seluruh bayangan diganti garis 2 dp putih (bagian
  /// 3.4): kedalaman lewat bayangan tidak terbaca oleh sensitivitas kontras
  /// rendah.
  static ThemeData get highContrast {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        primary: Colors.white,
        surface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.black,
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
      dividerTheme: const DividerThemeData(color: Colors.white, thickness: 1, space: 1),
    );
  }
}
