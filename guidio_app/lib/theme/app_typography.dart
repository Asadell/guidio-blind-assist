import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi design system Vinara.
/// IBM Plex Sans untuk semua teks, IBM Plex Mono untuk angka teknis
/// (jarak, persentase, waktu) - dipakai bersama `tabularFigures` supaya
/// nominal tidak bergeser saat berubah.
///
/// **Fontnya DIBUNDEL, bukan diunduh.** Versi sebelumnya memakai
/// `GoogleFonts.ibmPlexSans()`, yang mengambil berkasnya dari
/// fonts.gstatic.com saat dipakai pertama kali dan MELEMPAR tanpa penangkap
/// kalau jaringan mati - muncul di log perangkat sebagai `Unhandled
/// Exception` di layar pertama. Aplikasi ini empat dari enam modenya
/// dirancang jalan penuh tanpa jaringan, jadi menyandera hurufnya pada
/// unduhan adalah kontradiksi. Lihat blok `fonts:` di pubspec.yaml.
abstract final class AppTypography {
  /// Nama family HARUS sama persis dengan `family:` di pubspec.yaml.
  /// Kalau meleset, Flutter diam-diam jatuh ke font sistem tanpa satu pun
  /// galat - jadi keduanya dijadikan konstanta di sini supaya hanya ada satu
  /// tempat yang perlu dicocokkan.
  static const String sansFamily = 'IBM Plex Sans';
  static const String monoFamily = 'IBM Plex Mono';

  static TextStyle _sans({
    required double fontSize,
    required double height,
    required FontWeight weight,
    required double letterSpacing,
    Color color = AppColors.ink1,
  }) =>
      TextStyle(
        fontFamily: sansFamily,
        fontSize: fontSize,
        height: height / fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _mono({
    required double fontSize,
    required double height,
    required FontWeight weight,
    Color color = AppColors.ink1,
  }) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: fontSize,
        height: height / fontSize,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle displayMoney({Color color = AppColors.ink1}) =>
      _sans(fontSize: 56, height: 60, weight: FontWeight.w700, letterSpacing: -1.5, color: color)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle headline({Color color = AppColors.ink1}) =>
      _sans(fontSize: 28, height: 34, weight: FontWeight.w700, letterSpacing: -0.4, color: color);

  static TextStyle title({Color color = AppColors.ink1}) =>
      _sans(fontSize: 22, height: 28, weight: FontWeight.w600, letterSpacing: -0.2, color: color);

  static TextStyle body({Color color = AppColors.ink1}) =>
      _sans(fontSize: 16, height: 24, weight: FontWeight.w400, letterSpacing: 0, color: color);

  static TextStyle bodyStrong({Color color = AppColors.ink1}) =>
      _sans(fontSize: 16, height: 24, weight: FontWeight.w600, letterSpacing: 0, color: color);

  static TextStyle label({Color color = AppColors.ink1}) =>
      _sans(fontSize: 14, height: 20, weight: FontWeight.w600, letterSpacing: 0.1, color: color);

  static TextStyle caption({Color color = AppColors.ink2}) =>
      _sans(fontSize: 12, height: 16, weight: FontWeight.w500, letterSpacing: 0.2, color: color);

  static TextStyle eyebrow({Color color = AppColors.ink2}) => _sans(
        fontSize: 12,
        height: 16,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle metricMono({Color color = AppColors.ink1}) =>
      _mono(fontSize: 14, height: 20, weight: FontWeight.w500, color: color);
}
