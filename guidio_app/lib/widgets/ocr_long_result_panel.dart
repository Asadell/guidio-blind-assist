import 'package:flutter/material.dart';

import '../theme/index.dart';
import 'tier_icon.dart';

/// Satu blok siap-render untuk [OcrLongResultPanel] — kalimatnya sudah
/// dipecah oleh pemanggil (ocr_screen.dart) supaya panel ini tidak perlu
/// tahu aturan pemisahan kalimat, cuma menyorot kalimat aktif.
class OcrRenderBlock {
  final String heading;
  final String? language;
  final bool ok;
  final List<String> sentences;

  /// Index kalimat aktif di dalam blok ini, -1 kalau tidak ada yang aktif.
  final int activeLocalIndex;

  const OcrRenderBlock({
    required this.heading,
    required this.sentences,
    this.language,
    this.ok = true,
    this.activeLocalIndex = -1,
  });
}

/// OcrLongResultPanel — varian ResultPanel khusus hasil panjang/dua
/// bahasa/sebagian-gagal/senyap Mode Baca Teks (BT-07/08/09/10/12a/19).
/// ResultPanel (komponen sistem, read-only) sengaja tidak dipakai di sini
/// karena butuh: blok berheading, progress baca, dan kontrol yang berubah
/// bentuk saat senyap — di luar API ResultPanel.
class OcrLongResultPanel extends StatelessWidget {
  final List<OcrRenderBlock> blocks;
  final bool speaking;
  final bool paused;
  final double? progress; // null = sembunyikan progress bar
  final double maxContentHeight;
  final bool muted; // BT-19: kontrol jadi tombol gulung, bukan audio
  final bool vertical; // BT-18: font scale 200% → kontrol 56dp, susun vertikal
  final ScrollController? scrollController;

  final VoidCallback? onTogglePlayback; // jeda / lanjut
  final VoidCallback? onReplay; // ulangi dari awal
  final String? tertiaryLabel; // mis. "Bicara ke Asisten"
  final VoidCallback? onTertiary;

  const OcrLongResultPanel({
    super.key,
    required this.blocks,
    this.speaking = false,
    this.paused = false,
    this.progress,
    this.maxContentHeight = 280,
    this.muted = false,
    this.vertical = false,
    this.scrollController,
    this.onTogglePlayback,
    this.onReplay,
    this.tertiaryLabel,
    this.onTertiary,
  });

  int get _controlSize => vertical ? 56 : 48;

  @override
  Widget build(BuildContext context) {
    final eyebrow = speaking
        ? 'Sedang dibacakan'
        : paused
            ? 'Dijeda'
            : 'HASIL BACA';
    final eyebrowColor = speaking ? AppColors.actionLabel : AppColors.ink2;
    final failedCount = blocks.where((b) => !b.ok).length;

    return Semantics(
      liveRegion: true,
      label: '$eyebrow. ${blocks.where((b) => b.ok).map((b) => b.sentences.join(' ')).join(' ')}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(eyebrow, eyebrowColor),
            if (failedCount > 0) ...[
              const SizedBox(height: AppSpacing.s2),
              _partialBanner(failedCount, blocks.length),
            ],
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _progressBar(),
            ],
            const SizedBox(height: AppSpacing.s3),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxContentHeight),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < blocks.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.s4),
                      _block(blocks[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            muted ? _scrollControls() : _audioControls(),
          ],
        ),
      ),
    );
  }

  Widget _header(String eyebrow, Color eyebrowColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(eyebrow, style: AppTypography.eyebrow(color: eyebrowColor))),
        if (!muted && (speaking || paused)) _playPauseButton(),
      ],
    );
  }

  Widget _partialBanner(int failedCount, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AlertTier.warning.tintColor, borderRadius: AppRadius.cardInner),
      child: Row(
        children: [
          TierIcon(tier: AlertTier.warning, size: 20),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              '${total - failedCount} dari $total bagian terbaca. Bagian lain buram atau tertutup.',
              style: AppTypography.body(color: AlertTier.warning.labelColor).copyWith(fontSize: 14, height: 20 / 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final v = progress!.clamp(0.0, 1.0);
    return Semantics(
      label: 'Progres baca ${(v * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: AppColors.surfaceSunk,
          valueColor: const AlwaysStoppedAnimation(AppColors.actionLabel),
        ),
      ),
    );
  }

  Widget _block(OcrRenderBlock block) {
    final baseColor = block.ok ? AppColors.ink1 : AppColors.disabledInk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(block.heading.toUpperCase(),
                  style: AppTypography.caption(color: AppColors.ink2).copyWith(fontWeight: FontWeight.w700)),
            ),
            if (block.language != null) ...[
              const SizedBox(width: AppSpacing.s2),
              _languagePill(block.language!),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (!block.ok)
          Text('Bagian ini tidak terbaca.', style: AppTypography.body(color: AppColors.disabledInk))
        else
          RichText(
            text: TextSpan(
              style: AppTypography.body(color: baseColor),
              children: [
                for (var i = 0; i < block.sentences.length; i++)
                  TextSpan(
                    text: '${block.sentences[i]} ',
                    style: i == block.activeLocalIndex
                        ? const TextStyle(backgroundColor: AppColors.actionTint, color: AppColors.ink1)
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _languagePill(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.actionTint, borderRadius: AppRadius.pillShape),
      child: Text(language, style: AppTypography.caption(color: AppColors.actionLabel)),
    );
  }

  Widget _playPauseButton() {
    return GestureDetector(
      onTap: onTogglePlayback,
      child: Semantics(
        button: true,
        label: speaking ? 'Jeda pembacaan' : 'Lanjutkan pembacaan',
        child: Container(
          width: _controlSize.toDouble(),
          height: _controlSize.toDouble(),
          decoration: BoxDecoration(
            color: speaking ? AppColors.actionLabel : AppColors.actionTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: speaking ? Colors.white : AppColors.actionLabel,
          ),
        ),
      ),
    );
  }

  Widget _audioControls() {
    final buttons = [
      _pill(
        label: paused ? 'Lanjut' : (speaking ? 'Jeda' : 'Putar'),
        icon: paused || !speaking ? Icons.play_arrow_rounded : Icons.pause_rounded,
        filled: true,
        onTap: onTogglePlayback,
      ),
      _pill(label: 'Ulangi', icon: Icons.replay_rounded, filled: false, onTap: onReplay),
      if (tertiaryLabel != null) _pill(label: tertiaryLabel!, icon: Icons.mic_none_rounded, filled: false, onTap: onTertiary),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s2),
                buttons[i],
              ],
            ],
          )
        : Wrap(spacing: AppSpacing.s2, runSpacing: AppSpacing.s2, children: buttons);
  }

  Widget _scrollControls() {
    final buttons = [
      _pill(
        label: 'Gulir naik',
        icon: Icons.keyboard_arrow_up_rounded,
        filled: false,
        onTap: () => scrollController?.animateTo(
          (scrollController!.offset - 200).clamp(0, scrollController!.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      ),
      _pill(
        label: 'Gulir turun',
        icon: Icons.keyboard_arrow_down_rounded,
        filled: false,
        onTap: () => scrollController?.animateTo(
          (scrollController!.offset + 200).clamp(0, scrollController!.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      ),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(height: AppSpacing.s2), buttons[1]],
          )
        : Row(children: [Expanded(child: buttons[0]), const SizedBox(width: AppSpacing.s2), Expanded(child: buttons[1])]);
  }

  Widget _pill({required String label, required IconData icon, required bool filled, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _controlSize.toDouble(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.actionLabel : AppColors.actionTint,
            borderRadius: AppRadius.pillShape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: filled ? Colors.white : AppColors.actionLabel),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.label(color: filled ? Colors.white : AppColors.actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
