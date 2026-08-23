import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'distance_pill.dart';
import 'tier_icon.dart';

/// AlertCard - kartu melayang di sepertiga bawah layar (F2).
/// Kartu putih opaque + Pita Prioritas 3 dp di tepi kiri dalam, warna
/// mengikuti tier. Tier terbaca dari bentuk ikon, bukan cuma warna.
class AlertCard extends StatelessWidget {
  final AlertTier tier;
  final String title;
  final String? description;
  final double? distanceMeter;
  final bool dense;

  const AlertCard({
    super.key,
    required this.tier,
    required this.title,
    this.description,
    this.distanceMeter,
    this.dense = false,
  });

  String get _liveLabel {
    final dist = distanceMeter == null
        ? ''
        : distanceMeter! < 1
            ? ', kurang dari satu meter'
            : ', ${distanceMeter!.toStringAsFixed(1)} meter';
    return '${tier.label}. $title$dist';
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 34.0 : 40.0;
    final pad = dense ? 14.0 : 16.0;

    return Semantics(
      liveRegion: true,
      label: _liveLabel,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: description == null ? 88 : 112),
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad).copyWith(left: 20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: -pad + 8,
              top: 4,
              bottom: 4,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: tier.fillColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment:
                  description == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Center(child: TierIcon(tier: tier, size: iconSize - 6)),
                ),
                const SizedBox(width: AppSpacing.s3 + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tier.label.toUpperCase(),
                          style: AppTypography.eyebrow(color: tier.labelColor)),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppTypography.bodyStrong(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: AppTypography.body(color: AppColors.ink2).copyWith(fontSize: 14, height: 20 / 14),
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
                if (distanceMeter != null) ...[
                  const SizedBox(width: AppSpacing.s3 + 2),
                  DistancePill(distanceMeter: distanceMeter!, tier: tier, compact: dense),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tumpukan AlertCard - maksimum 2, gap 8, tier tertinggi di slot bawah
/// (paling dekat ibu jari / BottomActionBar).
class AlertCardStack extends StatelessWidget {
  final List<Widget> cards;

  const AlertCardStack({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final shown = cards.take(2).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s2),
          shown[i],
        ],
      ],
    );
  }
}
