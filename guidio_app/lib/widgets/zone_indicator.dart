import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Status per zona (Kiri / Tengah / Kanan) di ZoneIndicator (F8).
enum ZoneStatus { safe, caution, danger, unknown }

extension ZoneStatusX on ZoneStatus {
  String get label => switch (this) {
        ZoneStatus.safe    => 'AMAN',
        ZoneStatus.caution => 'HATI-HATI',
        ZoneStatus.danger  => 'BAHAYA',
        ZoneStatus.unknown => '',
      };

  Color get tint => switch (this) {
        ZoneStatus.safe    => AppColors.positiveTint,
        ZoneStatus.caution => AppColors.warningTint,
        ZoneStatus.danger  => AppColors.criticalTint,
        ZoneStatus.unknown => AppColors.surfaceSunk,
      };

  Color get ink => switch (this) {
        ZoneStatus.safe    => AppColors.positiveLabel,
        ZoneStatus.caution => AppColors.warningLabel,
        ZoneStatus.danger  => AppColors.criticalLabel,
        ZoneStatus.unknown => AppColors.ink2,
      };
}

/// ZoneIndicator (F8) - tiga chip 111 × 56, gap 8. Chip yang sedang
/// direkomendasikan memakai isian pekat (bukan hijau vibrant) supaya
/// teks putih di atasnya lolos 7.35:1.
class ZoneIndicator extends StatelessWidget {
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;
  final int recommended; // -1 none, 0 left, 1 center, 2 right

  const ZoneIndicator({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.recommended = -1,
  });

  String get _liveLabel {
    if ([left, center, right].every((s) => s == ZoneStatus.unknown)) {
      return 'Kondisi jalur belum diketahui';
    }
    return 'Kondisi jalur: kiri ${left.label.toLowerCase()}, '
        'tengah ${center.label.toLowerCase()}, '
        'kanan ${right.label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _liveLabel,
      child: Row(
        children: [
          Expanded(child: _ZoneChip(label: 'Kiri', status: left, recommended: recommended == 0)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: _ZoneChip(label: 'Tengah', status: center, recommended: recommended == 1)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(child: _ZoneChip(label: 'Kanan', status: right, recommended: recommended == 2)),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final ZoneStatus status;
  final bool recommended;

  const _ZoneChip({required this.label, required this.status, required this.recommended});

  @override
  Widget build(BuildContext context) {
    final solid = recommended && status != ZoneStatus.unknown;
    final bg = solid ? status.ink : status.tint;
    final fg = solid ? AppColors.onDark : status.ink;

    return Container(
      height: 56,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.caption(color: solid ? AppColors.onDark.withValues(alpha: .85) : AppColors.ink2)),
            const SizedBox(height: 1),
            status == ZoneStatus.unknown
                ? _UnknownDots()
                : Text(
                    status.label,
                    style: AppTypography.bodyStrong(color: fg).copyWith(fontSize: 15, letterSpacing: .4),
                  ),
          ],
        ),
      ),
    );
  }
}

class _UnknownDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 0 ? AppColors.indicatorOn : AppColors.indicatorOff,
            ),
          ),
        );
      }),
    );
  }
}
