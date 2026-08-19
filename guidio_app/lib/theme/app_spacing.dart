import 'package:flutter/material.dart';

/// Skala spacing 4-based. Jarak antar elemen interaktif = space2 (8),
/// antar blok informasi = space4 (16), antar kelompok = space6 (24).
abstract final class AppSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
  static const s8 = 40.0;
  static const s9 = 48.0;

  /// Margin kiri-kanan grid layar (393 dp frame → 20 dp margin, 353 dp konten).
  static const screenMargin = 20.0;
}

/// Skala radius. Kartu melayang r/lg, kartu-di-dalam-kartu r/sm,
/// pill & tombol bulat r/pill, bottom sheet r/sheet (dua sudut atas saja).
abstract final class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const sheet = 28.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const cardInner = BorderRadius.all(Radius.circular(sm));
  static const pillShape = BorderRadius.all(Radius.circular(pill));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Elevasi: elev/1 datar, elev/2 kartu, elev/3 sheet + FAB.
abstract final class AppElevation {
  static const flat = <BoxShadow>[
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .08), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const card = <BoxShadow>[
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .10), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .16), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -8),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .12), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color.fromRGBO(22, 24, 25, .26), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -12),
  ];
}

/// Target sentuh minimum & ukuran komponen tetap dari kontrak layout.
abstract final class AppSizes {
  static const minTouchTarget = 48.0;
  static const micButton = 64.0;
  static const fullScreenButtonHeight = 96.0;
  static const modeBadgeHeight = 40.0;
  static const bottomActionBarHeight = 88.0;
  static const statusBannerHeight = 56.0;
  static const alertCardShortHeight = 88.0;
  static const alertCardLongHeight = 112.0;
  static const iconStroke = 1.6;
}
