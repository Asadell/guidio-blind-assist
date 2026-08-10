import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../providers/index.dart';
import '../theme/index.dart';
import 'mode_picker_sheet.dart';

/// BottomActionBar (F3) — selalu ada, selalu di tempat yang sama, tidak
/// pernah menggulung. Tiga slot: Ambil Gambar 48, Bicara 64, Pilih Mode 48.
/// Saat mic aktif, dua tombol lain nonaktif — supaya tidak ada aksi
/// tabrakan sambil berjalan.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;
  final bool cameraEnabled;
  final String cameraLabel;

  const BottomActionBar({
    super.key,
    this.onCameraPressed,
    this.onMicPressed,
    this.cameraEnabled = true,
    this.cameraLabel = 'Ambil gambar',
  });

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sideButtonsEnabled = cameraEnabled && !voice.isListening;

    return Container(
      height: AppSizes.bottomActionBarHeight + bottomInset,
      padding: EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s3, AppSpacing.s8, bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgPage,
        boxShadow: [
          BoxShadow(color: Color(0x0F161819), blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(color: Color(0x2E161819), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -12),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SquareButton(
            icon: Icons.camera_alt_outlined,
            label: cameraLabel,
            enabled: sideButtonsEnabled,
            onTap: onCameraPressed ?? () {},
          ),
          _MicButton(onTap: onMicPressed),
          _SquareButton(
            icon: Icons.apps_rounded,
            label: 'Pilih mode',
            enabled: !voice.isListening,
            onTap: () => showModePickerSheet(context),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _MicButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final listening = voice.isListening;
    final processing = voice.isProcessing;

    final semanticLabel = processing
        ? 'Bicara, sedang memproses'
        : listening
            ? 'Berhenti bicara'
            : 'Bicara';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: processing
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                final v = context.read<VoiceProvider>();
                final hasVib = await Vibration.hasVibrator();
                if (hasVib) Vibration.vibrate(duration: 100);
                if (onTap != null) {
                  onTap!();
                } else if (v.isListening) {
                  v.stopListening();
                } else {
                  v.startListening();
                }
              },
        child: Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: processing ? AppColors.actionTint : AppColors.actionFill,
            boxShadow: listening
                ? [
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .18), blurRadius: 0, spreadRadius: 8),
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .10), blurRadius: 0, spreadRadius: 16),
                  ]
                : [
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .36), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.actionLabel),
                )
              : Icon(listening ? Icons.mic : Icons.mic_none_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, tidak tersedia',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 26,
              color: enabled ? AppColors.ink1 : AppColors.disabledInk,
            ),
          ),
        ),
      ),
    );
  }
}
