import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// Pill jarak bertulisan mono, dipakai di AlertCard & label bounding box.
/// Warna isian & teks mengikuti aturan kontras per tier:
/// Critical → isian pekat + teks putih, Warning → isian vibrant + teks ink
/// (putih gagal 2:1 di atas kuning), Info → isian tint + teks label.
class DistancePill extends StatelessWidget {
  final double distanceMeter;
  final AlertTier tier;
  final bool compact;

  const DistancePill({
    super.key,
    required this.distanceMeter,
    required this.tier,
    this.compact = false,
  });

  Color get _bg => switch (tier) {
        AlertTier.critical => AppColors.criticalLabel,
        AlertTier.warning  => AppColors.warningFill,
        AlertTier.info     => AppColors.actionTint,
        AlertTier.positive => AppColors.positiveLabel,
      };

  Color get _fg => switch (tier) {
        AlertTier.critical => Colors.white,
        AlertTier.warning  => AppColors.ink1,
        AlertTier.info     => AppColors.actionLabel,
        AlertTier.positive => Colors.white,
      };

  String get _text {
    final value = distanceMeter < 1.0
        ? '${(distanceMeter * 100).round()} cm'
        : '${distanceMeter.toStringAsFixed(1)} m';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 10, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(color: _bg, borderRadius: AppRadius.pillShape),
      child: Text(_text, style: AppTypography.metricMono(color: _fg)),
    );
  }
}
