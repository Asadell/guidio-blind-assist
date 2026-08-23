import 'package:flutter/material.dart';

import '../theme/index.dart';

/// FullScreenButton (5.4) - tombol aksi tunggal yang sangat besar, 96 dp.
/// Dipakai untuk aksi utama satu-jari: jepret di Mode Baca Teks, izin di
/// PermissionCard, dst.
class FullScreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  /// Wajib diisi saat [disabled] - bagian 5.4: tombol disabled selalu
  /// menyebut alasannya sebagai baris di bawah teks.
  final String? disabledReason;
  final IconData? icon;

  const FullScreenButton({
    super.key,
    required this.label,
    this.onTap,
    this.disabled = false,
    this.disabledReason,
    this.icon,
  }) : assert(!disabled || disabledReason != null,
            'disabledReason wajib diisi saat tombol disabled');

  @override
  Widget build(BuildContext context) {
    final semanticLabel = disabled ? '$label, tidak tersedia, $disabledReason' : label;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppRadius.card,
          child: Ink(
            height: AppSizes.fullScreenButtonHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: disabled ? AppColors.surfaceSunk : AppColors.actionLabel,
              borderRadius: AppRadius.card,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.actionLabel.withValues(alpha: .32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: disabled ? AppColors.disabledInk : AppColors.onDark, size: 26),
                        const SizedBox(width: AppSpacing.s3),
                      ],
                      Text(
                        label,
                        style: AppTypography.title(
                          color: disabled ? AppColors.disabledInk : AppColors.onDark,
                        ),
                      ),
                    ],
                  ),
                  if (disabled && disabledReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      disabledReason!,
                      style: AppTypography.caption(color: AppColors.disabledInk),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
