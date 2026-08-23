import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ContextualActionSlot - slot tombol kontekstual yang selalu duduk di posisi
/// yang sama: tepat di atas BottomActionBar, dari kiri ke kanan layar.
///
/// Dipakai untuk prompt situasional jangka pendek yang butuh respons segera:
/// - Tawaran nyalakan lampu saat gelap (TuntunScreen)
/// - Tombol "Kembali" saat VoiceScreen dimasuki sebagai overlay
///
/// **Aturan keamanan zona:**
/// Konten di atas slot (kartu deteksi, panel bubble) wajib membaca
/// [slotHeight] dan menggeser dirinya ke atas - bukan sebaliknya.
///
/// Slot ini diposisikan oleh pemanggil via [Positioned] karena tiap layar
/// punya cara berbeda mengelola Stack-nya.
class ContextualActionSlot extends StatelessWidget {
  /// Teks situasional kecil (opsional) di atas tombol.
  final String? message;

  /// Label tombol utama (kiri / satu-satunya).
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryIcon;
  final Color? primaryColor;

  /// Label tombol sekunder (kanan, opsional).
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;

  const ContextualActionSlot({
    super.key,
    this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryColor,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
  });

  /// Tinggi tombol saja (tanpa message) - pemanggil pakai ini untuk geser kartu.
  static const double slotHeight = 64.0;

  /// Tinggi total dengan message (pill + gap + tombol).
  static const double slotHeightWithMsg = 92.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.s2,
        AppSpacing.screenMargin,
        AppSpacing.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[
            Semantics(
              liveRegion: true,
              label: message,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.scrimText,
                  borderRadius: AppRadius.pillShape,
                ),
                child: Text(
                  message!,
                  style: AppTypography.caption(color: AppColors.onDark),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: _SlotButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  icon: primaryIcon,
                  fillColor: primaryColor ?? AppColors.actionFill,
                  labelColor: AppColors.onDark,
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _SlotButton(
                    label: secondaryLabel!,
                    onTap: onSecondary ?? () {},
                    icon: secondaryIcon,
                    fillColor: AppColors.surfaceSunk,
                    labelColor: AppColors.ink1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color fillColor;
  final Color labelColor;

  const _SlotButton({
    required this.label,
    required this.onTap,
    this.icon,
    required this.fillColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: AppRadius.card,
            boxShadow: AppElevation.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(child: Icon(icon, color: labelColor, size: 20)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.label(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
