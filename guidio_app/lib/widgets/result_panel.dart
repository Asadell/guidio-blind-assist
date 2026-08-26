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

  /// Hentikan pembacaan sepenuhnya.
  ///
  /// Terpisah dari [onTogglePlayback] dengan sengaja. Jeda menyimpan niat
  /// melanjutkan; stop menutup pembacaan. Tanpa yang kedua, satu-satunya cara
  /// mendiamkan halaman yang terlanjur dibacakan adalah menjeda lalu berharap
  /// tidak menekan lanjut - keadaan yang terdengar seperti suara yang tidak
  /// bisa dimatikan.
  final VoidCallback? onStop;

  /// Tutup panel hasil dan kembalikan layar ke keadaan siap memotret.
  ///
  /// Panel ini menutupi sepertiga bawah layar termasuk sebagian pratinjau
  /// kamera, dan ia bertahan sampai foto berikutnya diambil. Tanpa jalan
  /// keluar yang terlihat, satu-satunya cara menyingkirkannya adalah memotret
  /// lagi - yaitu menjalankan pekerjaan yang justru tidak diinginkan pengguna.
  final VoidCallback? onDismiss;
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
    this.onStop,
    this.onDismiss,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text('GAGAL MEMUAT',
                            style: AppTypography.eyebrow(color: AppColors.criticalLabel)),
                      ),
                      // Panel gagal juga menutupi layar, dan "Coba lagi" bukan
                      // jalan keluar - ia menjalankan ulang hal yang barusan
                      // gagal. Menutup harus tetap mungkin tanpa memotret lagi.
                      if (onDismiss != null) _dismissControl(),
                    ],
                  ),
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
              if ((speaking || paused) && onStop != null) ...[
                _stopControl(),
                const SizedBox(width: AppSpacing.s2),
              ],
              _audioControl(),
              if (onDismiss != null) ...[
                const SizedBox(width: AppSpacing.s2),
                _dismissControl(),
              ],
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

  /// Tombol stop duduk di baris atas, bersebelahan dengan jeda/lanjut.
  ///
  /// Posisinya tetap - tidak ikut berpindah saat isi panel berubah panjang -
  /// karena tombol yang bergeser adalah tombol yang harus dicari ulang setiap
  /// kali, dan pengguna yang tidak melihat layar hanya punya posisi untuk
  /// dihafal.
  Widget _stopControl() {
    return Semantics(
      button: true,
      label: 'Hentikan pembacaan',
      child: GestureDetector(
        onTap: onStop,
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            color: AppColors.criticalTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.stop_rounded, color: AppColors.criticalLabel),
        ),
      ),
    );
  }

  /// Silang penutup panel. Selalu di ujung kanan baris atas, apa pun kontrol
  /// lain yang sedang tampil di sebelahnya - jalan keluar tidak boleh berpindah
  /// tempat mengikuti keadaan.
  Widget _dismissControl() {
    return Semantics(
      button: true,
      label: 'Tutup hasil baca',
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            color: AppColors.surfaceSunk,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: AppColors.ink1),
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
