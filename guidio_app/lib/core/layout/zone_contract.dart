/// Kontrak layout dan zona — bagian 4 IMPLEMENTASI.md.
/// Tidak ada elemen yang boleh menimpa elemen lain. Kalau dua elemen minta
/// ruang sama, yang prioritasnya lebih rendah digeser atau diperingkas.
abstract final class ZoneHeights {
  static const safeTop = 32.0;
  static const statusBannerOneLine = 56.0;
  static const statusBannerTwoLine = 64.0;
  static const modeBadge = 40.0;
  static const modeBadgeFontScale200 = 48.0;
  static const bottomActionBar = 112.0;
  static const safeBottom = 24.0;
  static const alertCardMax = 2;
}

/// Posisi baku (bagian 4, "Posisi baku") — offset relatif terhadap top-left
/// frame, sebelum ditambah safe-area inset perangkat nyata.
abstract final class ZonePositions {
  static const modeBadgeY = 40.0;
  static const modeBadgeYWithBanner = 96.0;
  static const secondaryChipY = 96.0;
  static const secondaryChipYWithBanner = 152.0;
  static const bottomCardSlotBottom = 120.0;
  static const fullScreenButtonBottom = 132.0;
}

/// Turunkan top-offset ModeBadge / chip sekunder saat StatusBanner hadir —
/// aturan tabrakan "Chip target + ModeBadge" & posisi baku di atas.
double modeBadgeTopOffset({required bool hasBanner}) =>
    hasBanner ? ZonePositions.modeBadgeYWithBanner : ZonePositions.modeBadgeY;

double secondaryChipTopOffset({required bool hasBanner}) =>
    hasBanner ? ZonePositions.secondaryChipYWithBanner : ZonePositions.secondaryChipY;
