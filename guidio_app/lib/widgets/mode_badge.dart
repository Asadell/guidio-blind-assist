import 'package:flutter/material.dart';

import '../providers/app_mode_provider.dart';
import '../theme/index.dart';

/// Ikon garis per mode — dipakai bersama oleh ModeBadge & ModePickerSheet.
IconData modeIcon(AppMode mode) => switch (mode) {
      AppMode.tuntun   => Icons.remove_red_eye_outlined,
      AppMode.ocr      => Icons.article_outlined,
      AppMode.navigasi => Icons.explore_outlined,
      AppMode.voice    => Icons.mic_none_rounded,
    };

/// ModeBadge (F1) — pill identitas mode, opaque #202432, di atas kamera.
/// Bukan tombol, cuma status; ganti mode lewat tombol Pilih Mode atau suara.
class ModeBadge extends StatelessWidget {
  final AppMode mode;
  final bool transitioning;

  const ModeBadge({super.key, required this.mode, this.transitioning = false});

  IconData get _icon => modeIcon(mode);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: transitioning ? 'Berpindah ke mode ${mode.label}' : 'Mode aktif: ${mode.label}',
      liveRegion: transitioning,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: Container(
          key: ValueKey('${mode.name}-$transitioning'),
          height: AppSizes.modeBadgeHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(color: AppColors.pillBg, borderRadius: AppRadius.pillShape),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: transitioning
                ? [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Beralih ke ${mode.label}…',
                        style: AppTypography.metricMono(
                            color: Colors.white.withValues(alpha: .9))),
                  ]
                : [
                    Icon(_icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Mode: ${mode.label}', style: AppTypography.label(color: Colors.white)),
                  ],
          ),
        ),
      ),
    );
  }
}
