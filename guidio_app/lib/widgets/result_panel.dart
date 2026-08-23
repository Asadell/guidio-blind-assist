import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ResultPanel (F9) - kontrol audio selalu di baris atas kanan supaya
/// posisinya tidak bergeser saat isi berubah panjang.
class ResultPanel extends StatelessWidget {
  final String title;
  final String text;
  final bool speaking;
  final bool paused;
  final bool failed;
  final VoidCallback? onReplay;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ResultPanel({
    super.key,
    this.title = 'Hasil baca',
    required this.text,
    this.speaking = false,
    this.paused = false,
    this.failed = false,
    this.onReplay,
    this.onTogglePlayback,
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return _panel(
        child: Stack(
          children: [
            Positioned(
              left: -4, top: 0, bottom: 0,
              child: Container(width: 3, decoration: BoxDecoration(color: AppColors.criticalFill, borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('GAGAL MEMUAT', style: AppTypography.eyebrow(color: AppColors.criticalLabel)),
                  const SizedBox(height: 6),
                  Text(text, style: AppTypography.body()),
                  const SizedBox(height: 14),
                  _pillButton('Coba lagi', filled: true, onTap: onRetry),
                ],
              ),
            ),
          ],
        ),
        semanticsLabel: 'Gagal memuat. $text. Coba lagi',
      );
    }

    if (text.isEmpty) {
      return _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(), style: AppTypography.eyebrow()),
            const SizedBox(height: 8),
            Text('Belum ada teks. Arahkan kamera ke tulisan, lalu tekan Baca teks.',
                style: AppTypography.body(color: AppColors.ink2)),
          ],
        ),
        semanticsLabel: title,
      );
    }

    final eyebrow = speaking ? 'Sedang dibacakan' : (paused ? 'Dijeda' : title.toUpperCase());
    final eyebrowColor = speaking ? AppColors.actionLabel : AppColors.ink2;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(eyebrow, style: AppTypography.eyebrow(color: eyebrowColor))),
              _audioControl(),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(text, style: AppTypography.body(color: speaking || paused ? AppColors.ink2 : AppColors.ink1)),
            ),
          ),
          if (!speaking && !paused) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _pillButton('Putar ulang', filled: false, icon: Icons.replay_rounded, onTap: onReplay),
                if (secondaryLabel != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  _pillButton(secondaryLabel!, filled: false, onTap: onSecondary),
                ],
              ],
            ),
          ],
        ],
      ),
      semanticsLabel: '$eyebrow. $text',
    );
  }

  Widget _audioControl() {
    if (!speaking && !paused) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTogglePlayback,
      child: Semantics(
        button: true,
        label: speaking ? 'Jeda pembacaan' : 'Lanjutkan pembacaan',
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: speaking ? AppColors.actionLabel : AppColors.actionTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: speaking ? AppColors.onDark : AppColors.actionLabel,
          ),
        ),
      ),
    );
  }

  Widget _pillButton(String label, {required bool filled, IconData? icon, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? AppColors.actionLabel : AppColors.actionTint,
            borderRadius: AppRadius.pillShape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: filled ? AppColors.onDark : AppColors.actionLabel),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.label(color: filled ? AppColors.onDark : AppColors.actionLabel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel({required Widget child, required String semanticsLabel}) {
    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: child,
      ),
    );
  }
}
