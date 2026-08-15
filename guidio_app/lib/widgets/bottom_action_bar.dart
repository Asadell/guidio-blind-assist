import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../providers/index.dart';
import '../screens/voice_screen.dart';
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
  /// DO-24 — izin mikrofon dicabut: nonaktifkan tombol Bicara sepenuhnya.
  final bool micEnabled;
  /// Saat mode aktif punya STT sendiri (mis. Cari Objek), timpa visual
  /// listening/processing bawaan `VoiceProvider` supaya tombol tetap sesuai
  /// dengan apa yang sesungguhnya sedang berjalan.
  final bool? listeningOverride;
  final bool? processingOverride;

  const BottomActionBar({
    super.key,
    this.onCameraPressed,
    this.onMicPressed,
    this.cameraEnabled = true,
    this.cameraLabel = 'Ambil gambar',
    this.micEnabled = true,
    this.listeningOverride,
    this.processingOverride,
  });

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final listening = listeningOverride ?? voice.isListening;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sideButtonsEnabled = cameraEnabled && !listening;

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
      // Urutan fokus 7-8-9 (bagian 10) dipasang eksplisit: reposisi tombol di
      // layar lain tidak boleh menggeser urutan tiga tombol ini, karena
      // kekekalannya adalah satu-satunya peta yang dimiliki pengguna.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            sortKey: const OrdinalSortKey(7),
            child: _SquareButton(
              icon: Icons.camera_alt_outlined,
              label: cameraLabel,
              enabled: sideButtonsEnabled,
              onTap: onCameraPressed ?? () {},
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(8),
            child: _MicButton(
              onTap: onMicPressed,
              enabled: micEnabled,
              listeningOverride: listeningOverride,
              processingOverride: processingOverride,
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(9),
            child: _SquareButton(
              icon: Icons.apps_rounded,
              label: 'Pilih mode',
              enabled: !listening,
              onTap: () => showModePickerSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;
  final bool? listeningOverride;
  final bool? processingOverride;
  const _MicButton({this.onTap, this.enabled = true, this.listeningOverride, this.processingOverride});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    if (!enabled) {
      return Semantics(
        button: true,
        label: 'Bicara, tidak tersedia, izin mikrofon belum diberikan',
        child: Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceSunk),
          child: const Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: 28),
        ),
      );
    }
    final listening = listeningOverride ?? voice.isListening;
    final processing = processingOverride ?? voice.isProcessing;

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
                final appMode = context.read<AppModeProvider>();
                final hasVib = await Vibration.hasVibrator();
                if (hasVib) Vibration.vibrate(duration: 100);

                // Jika bukan di mode voice, push VoiceScreen sebagai overlay
                // (fitur "Jarvis Global Mic") alih-alih langsung ke onTap.
                if (appMode.mode != AppMode.voice) {
                  if (context.mounted) {
                    await Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierDismissible: false,
                        pageBuilder: (_, __, ___) =>
                            const VoiceScreen(isOverlay: true),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                    // Setelah pop, mulai listen segera
                    if (!v.isListening) v.startListening();
                  }
                  return;
                }

                // Sudah di mode voice — perilaku bawaan
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
