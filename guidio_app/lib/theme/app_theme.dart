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
}
