import 'package:flutter/material.dart';

import '../theme/index.dart';

/// SpeakingIndicator (5.15) - pil kecil kanan atas menandakan TTS berjalan.
/// Varian senyap: ikon speaker dicoret + "Getar saja".
class SpeakingIndicator extends StatefulWidget {
  final bool silent;

  const SpeakingIndicator({super.key, this.silent = false});

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.silent ? 'Getar saja' : 'Vinara bicara';

    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        height: AppSizes.modeBadgeHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(color: AppColors.pillBg, borderRadius: AppRadius.pillShape),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.silent
                ? const Icon(Icons.volume_off_rounded, size: 18, color: AppColors.onDark)
                : _Bars(controller: _controller),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.label(color: AppColors.onDark)),
          ],
        ),
      ),
    );
  }
}

class _Bars extends AnimatedWidget {
  final AnimationController controller;
  const _Bars({required this.controller}) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final phase = (controller.value + i * .22) % 1.0;
          final h = 4 + (10 * (0.5 + 0.5 * (phase < .5 ? phase * 2 : (1 - phase) * 2)));
          return Container(width: 2.4, height: h, color: AppColors.onDark);
        }),
      ),
    );
  }
}
