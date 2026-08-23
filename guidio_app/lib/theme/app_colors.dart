import 'package:flutter/material.dart';

/// Token warna design system Vinara.
/// Aturan baku: `fill` hanya untuk ikon & bidang besar (syarat 3:1),
/// `label` untuk semua teks (syarat 4.5:1). Isian vibrant (action/fill,
/// positive/fill, critical/fill) TIDAK BOLEH memuat teks putih kecil.
abstract final class AppColors {
  // Action (biru)
  static const actionFill    = Color(0xFF3181E7); // 3.87:1 - ikon & bidang besar saja
  static const actionLabel   = Color(0xFF1A56B0); // 7.00:1 - teks & tombol bertulisan
  static const actionPressed = Color(0xFF1D5FC2); // 6.05:1 - state ditekan
  static const actionTint    = Color(0xFFEAF2FE); // isian lembut, item aktif

  // Positive (hijau - arah/aman)
  static const positiveFill  = Color(0xFF51B055); // ikon & bidang besar saja (putih gagal 2.75:1)
  static const positiveLabel = Color(0xFF1C6323); // teks "AMAN", isian chip zona aktif
  static const positiveTint  = Color(0xFFE8F4E9);

  // Critical (merah - bahaya)
  static const criticalFill  = Color(0xFFE5484D); // ikon oktagon, pita prioritas, garis bbox
  static const criticalLabel = Color(0xFFA82727); // teks "Bahaya", isian pill jarak
  static const criticalTint  = Color(0xFFFDECEC);

  // Warning (kuning - hati-hati). Kuning TIDAK PERNAH membawa teks putih.
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
  static const scrimDim  = Color(0x660B0D12); // #0B0D12 @ 40% - tidak pernah membawa teks

  // ── Foreground di atas bidang gelap/berwarna ────────────────────────────

  /// Teks & ikon di atas bidang gelap atau vibrant - scrim di atas kamera,
  /// [pillBg], dan isian `*Fill`.
  ///
  /// Ini yang dulu ditulis sebagai `Colors.white` mentah di 64 tempat.
  /// Nilainya memang putih, tapi menyebutnya lewat token membuat maksudnya
  /// terbaca - dan membuat tema kontras tinggi bisa menggesernya di **satu**
  /// tempat alih-alih di 64 tempat yang harus ditemukan satu per satu dulu.
  ///
  /// Aturan 3:1 di header berkas ini tetap berlaku: putih di atas isian
  /// vibrant hanya untuk teks besar/tebal dan ikon, tidak untuk teks kecil.
  static const onDark = Color(0xFFFFFFFF);

  // ── Latar kamera ────────────────────────────────────────────────────────

  /// Latar di belakang preview kamera, dan pengganti saat preview belum siap.
  ///
  /// Hitam pekat disengaja: apa pun selain hitam akan terbaca sebagai "ada
  /// sesuatu di layar" oleh pengguna low vision, padahal yang benar adalah
  /// "belum ada gambar".
  static const cameraVoid = Color(0xFF000000);

  // ── Tema gelap ──────────────────────────────────────────────────────────
  static const darkBg       = Color(0xFF15171E);
  static const darkSurface  = Color(0xFF1E212B);
  static const darkHairline = Color(0xFF2A2D38);

  // ── Abu netral untuk indikator non-teks ─────────────────────────────────
  /// Titik/segmen indikator yang tidak membawa teks (mis. penanda langkah).
  static const indicatorOn  = Color(0xFF9AA0AD);
  static const indicatorOff = Color(0xFFC4C9D2);

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
