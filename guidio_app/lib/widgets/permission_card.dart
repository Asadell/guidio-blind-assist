import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'full_screen_button.dart';

/// PermissionCard (5.16) — kartu izin yang mengambil zona konten. ModeBadge
/// dan BottomActionBar tetap di tempatnya (dipasang oleh screen pemanggil).
/// Alasan ditulis per izin, bukan satu paragraf gabungan — bagian 5.16.
class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;
  final String actionLabel;
  final VoidCallback onAction;
  final bool actionDisabled;
  final String? actionDisabledReason;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.onAction,
    this.actionDisabled = false,
    this.actionDisabledReason,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: AppColors.actionLabel),
            const SizedBox(height: AppSpacing.s4),
            Text(title, textAlign: TextAlign.center, style: AppTypography.title()),
            const SizedBox(height: AppSpacing.s2),
            Text(reason, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
            const SizedBox(height: AppSpacing.s6),
            FullScreenButton(
              label: actionLabel,
              onTap: onAction,
              disabled: actionDisabled,
              disabledReason: actionDisabledReason,
            ),
          ],
        ),
      ),
    );
  }
}
