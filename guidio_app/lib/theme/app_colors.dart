import 'package:flutter/material.dart';

/// Token warna design system Vinara.
/// Aturan baku: `fill` hanya untuk ikon & bidang besar (syarat 3:1),
/// `label` untuk semua teks (syarat 4.5:1). Isian vibrant (action/fill,
/// positive/fill, critical/fill) TIDAK BOLEH memuat teks putih kecil.
abstract final class AppColors {
  // Action (biru)
  static const actionFill    = Color(0xFF3181E7); // 3.87:1 — ikon & bidang besar saja
  static const actionLabel   = Color(0xFF1A56B0); // 7.00:1 — teks & tombol bertulisan
  static const actionPressed = Color(0xFF1D5FC2); // 6.05:1 — state ditekan
  static const actionTint    = Color(0xFFEAF2FE); // isian lembut, item aktif

  // Positive (hijau — arah/aman)
  static const positiveFill  = Color(0xFF51B055); // ikon & bidang besar saja (putih gagal 2.75:1)
  static const positiveLabel = Color(0xFF1C6323); // teks "AMAN", isian chip zona aktif
  static const positiveTint  = Color(0xFFE8F4E9);

  // Critical (merah — bahaya)
  static const criticalFill  = Color(0xFFE5484D); // ikon oktagon, pita prioritas, garis bbox
  static const criticalLabel = Color(0xFFA82727); // teks "Bahaya", isian pill jarak
  static const criticalTint  = Color(0xFFFDECEC);

  // Warning (kuning — hati-hati). Kuning TIDAK PERNAH membawa teks putih.
  static const warningFill   = Color(0xFFF2A93C);
  static const warningLabel  = Color(0xFF7A4A00);
  static const warningTint   = Color(0xFFFFF6E9);

  // Pill / overlay di atas kamera
  static const pillBg = Color(0xFF202432); // ModeBadge, opaque

  // Netral
  static const bgPage      = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const ink1        = Color(0xFF16181F); // teks primer 17.8:1
  static const ink2        = Color(0xFF4A4E5A); // teks sekunder 8.3:1

  static const surfaceMuted = Color(0xFFF6F7F9); // panel abu lembut
  static const surfaceSunk  = Color(0xFFECEEF2); // disabled/bg, progress track
  static const disabledInk  = Color(0xFF6B707C);
  static const hairline     = Color(0xFFECEEF2);

  // Scrim di atas video kamera
  static const scrimText = Color(0xDB0B0D12); // #0B0D12 @ 86%
  static const scrimDim  = Color(0x660B0D12); // #0B0D12 @ 40% — tidak pernah membawa teks

  static Color dangerColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalFill,
        'warning'  => warningFill,
        _          => actionFill,
      };

  static Color dangerLabelColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalLabel,
        'warning'  => warningLabel,
        _          => actionLabel,
      };

  static Color dangerTintColor(String dangerLevel) => switch (dangerLevel) {
        'critical' => criticalTint,
        'warning'  => warningTint,
        _          => actionTint,
      };
}
