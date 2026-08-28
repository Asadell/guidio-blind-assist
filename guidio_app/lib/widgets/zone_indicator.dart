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

  /// Sisi yang disarankan, dalam kata. Null kalau tidak ada saran.
  String? get _sisiDisarankan => switch (recommended) {
        0 => 'kiri',
        1 => 'tengah',
        2 => 'kanan',
        _ => null,
      };

  String get _liveLabel {
    if ([left, center, right].every((s) => s == ZoneStatus.unknown)) {
      return 'Kondisi jalur belum diketahui';
    }
    final kondisi = 'Kondisi jalur: kiri ${left.label.toLowerCase()}, '
        'tengah ${center.label.toLowerCase()}, '
        'kanan ${right.label.toLowerCase()}';

    // Sarannya ikut dibacakan, bukan hanya digambar.
    //
    // Tiga status saja cuma MENILAI. Pada trotoar sempit ketiganya bisa
    // berbunyi "bahaya, hati-hati, bahaya" sekaligus, dan pembacaan itu tidak
    // memberi satu pun hal untuk dikerjakan - padahal sistem sudah tahu sisi
    // mana yang masih bisa dilewati dan sudah menggambarnya sebagai chip
    // berisian pekat. Yang terlihat mata harus terdengar juga.
    final sisi = _sisiDisarankan;
    return sisi == null ? kondisi : '$kondisi. Lewat $sisi';
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
          // Chip yang disarankan ditandai panah di baris atasnya - lihat
          // [_ZoneChip]. Tanpa itu, "Tengah HATI-HATI" berisian pekat terbaca
          // sebagai peringatan, bukan sebagai anjuran lewat sana.
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
            // Baris atas: nama sisi, didahului panah kalau inilah sisi yang
            // disarankan. Panahnya duduk DI BARIS YANG SAMA, bukan sebagai
            // baris ketiga: chip ini tingginya tetap 56 dp dan aplikasi
            // mendukung ukuran teks 200%, jadi baris tambahan akan meluap
            // persis di pengaturan yang paling dibutuhkan pengguna low vision.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (solid) ...[
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: AppColors.onDark.withValues(alpha: .85)),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: solid
                          ? AppColors.onDark.withValues(alpha: .85)
                          : AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
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
