import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// StatusBanner (F7) — lebar penuh, tinggi 56, tanpa radius, menempel tepi
/// atas. Isian tint tier + Pita Prioritas horizontal 3 dp di tepi bawah.
/// Satu banner saja pada satu waktu; tier lebih tinggi menang.
class StatusBanner extends StatelessWidget {
  final AlertTier tier;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatusBanner({
    super.key,
    required this.tier,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: actionLabel == null ? message : '$message. $actionLabel',
      child: Container(
        width: double.infinity,
        height: AppSizes.statusBannerHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        decoration: BoxDecoration(
          color: tier.tintColor,
          border: Border(bottom: BorderSide(color: tier.fillColor, width: 3)),
        ),
        child: Row(
          children: [
            TierIcon(tier: tier, size: 22),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyStrong(color: tier.labelColor).copyWith(fontSize: 15, height: 20 / 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s3),
                  child: Text(actionLabel!, style: AppTypography.label(color: AppColors.actionLabel)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
