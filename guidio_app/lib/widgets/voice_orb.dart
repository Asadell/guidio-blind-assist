import 'package:flutter/material.dart';

import '../theme/index.dart';

/// VoiceOrb (F6) — setiap state punya bentuk/isi berbeda, bukan cuma warna.
enum VoiceOrbState { idle, listening, processing, success, failure, disabled }

class VoiceOrb extends StatelessWidget {
  final VoiceOrbState state;
  final double size;

  const VoiceOrb({super.key, required this.state, this.size = 96});

  String get _label => switch (state) {
        VoiceOrbState.idle       => 'Bicara',
        VoiceOrbState.listening  => 'Mendengarkan',
        VoiceOrbState.processing => 'Memproses',
        VoiceOrbState.success    => 'Selesai',
        VoiceOrbState.failure    => 'Belum terdengar, coba lagi',
        VoiceOrbState.disabled   => 'Bicara, tidak tersedia, izin mikrofon belum diberikan',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: state != VoiceOrbState.idle,
      label: _label,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: _content()),
      ),
    );
  }

  Widget _content() {
    switch (state) {
      case VoiceOrbState.idle:
        return _circle(
          diameter: size,
          color: AppColors.actionFill,
          shadow: [BoxShadow(color: AppColors.actionFill.withValues(alpha: .3), blurRadius: 12, offset: const Offset(0, 4))],
          child: Icon(Icons.mic_none_rounded, color: Colors.white, size: size * .44),
        );
      case VoiceOrbState.listening:
        return _circle(
          diameter: size,
          color: AppColors.actionFill,
          shadow: [
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .16), blurRadius: 0, spreadRadius: size * .14),
            BoxShadow(color: AppColors.actionFill.withValues(alpha: .08), blurRadius: 0, spreadRadius: size * .28),
          ],
          child: Icon(Icons.mic_rounded, color: Colors.white, size: size * .44),
        );
      case VoiceOrbState.processing:
        return _circle(
          diameter: size,
          color: AppColors.actionTint,
          child: SizedBox(
            width: size * .46, height: size * .46,
            child: const CircularProgressIndicator(strokeWidth: 4, color: AppColors.actionLabel),
          ),
        );
      case VoiceOrbState.success:
        return _circle(
          diameter: size,
          color: AppColors.positiveLabel,
          child: Icon(Icons.check_rounded, color: Colors.white, size: size * .48),
        );
      case VoiceOrbState.failure:
        return _circle(
          diameter: size,
          color: Colors.white,
          border: Border.all(color: AppColors.warningFill, width: 2),
          child: Icon(Icons.priority_high_rounded, color: AppColors.ink1, size: size * .42),
        );
      case VoiceOrbState.disabled:
        return _circle(
          diameter: size,
          color: AppColors.surfaceSunk,
          child: Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: size * .44),
        );
    }
  }

  Widget _circle({
    required double diameter,
    required Color color,
    Widget? child,
    List<BoxShadow>? shadow,
    BoxBorder? border,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: shadow,
        border: border,
      ),
      child: Center(child: child),
    );
  }
}
