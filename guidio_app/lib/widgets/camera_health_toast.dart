import 'package:flutter/material.dart';

import '../theme/index.dart';

/// CameraHealthToast (5.10) — pill gelap melayang, instruksi fisik dan
/// konkret ("miringkan sedikit"), bukan abstrak. Tidak fokusable; live
/// region polite.
enum CameraHealthIssue { dark, blurry, covered, tilted }

extension CameraHealthIssueX on CameraHealthIssue {
  String get message => switch (this) {
        CameraHealthIssue.dark    => 'Terlalu gelap. Cari cahaya lebih terang.',
        CameraHealthIssue.blurry  => 'Gambar buram, tahan lebih stabil.',
        CameraHealthIssue.covered => 'Ada yang menutupi lensa.',
        CameraHealthIssue.tilted  => 'Angkat ponsel sedikit.',
      };
}

class CameraHealthToast extends StatelessWidget {
  final CameraHealthIssue issue;

  const CameraHealthToast({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: issue.message,
      focusable: false,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Center(
          child: Text(
            issue.message,
            style: AppTypography.body(color: Colors.white).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
