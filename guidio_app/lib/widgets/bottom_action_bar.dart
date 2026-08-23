import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../core/speech/tts_queue.dart';
import '../providers/index.dart';
import '../screens/voice_screen.dart';
import '../services/haptic_service.dart';
import '../theme/index.dart';
import 'mode_picker_sheet.dart';

/// BottomActionBar (F3) - selalu ada, selalu di tempat yang sama, tidak
/// pernah menggulung. Tiga slot: Aksi Utama 48, Bicara 64, Pilih Mode 48.
/// Saat mic aktif, dua tombol lain nonaktif - supaya tidak ada aksi
/// tabrakan sambil berjalan.
///
/// ## Kontrak tombol kiri
///
/// **Tombol kiri = lakukan hal utama mode ini, sekarang. Kalau mode itu tidak
/// punya "hal utama", ia mengulang hal penting terakhir yang diucapkan.**
///
/// Bagian kedua yang membuat aturannya utuh: dengan itu tidak ada satu pun
/// mode dengan tombol kiri mati, dan pengguna punya jaring pengaman - kalau
/// lupa tombol kiri melakukan apa di mode ini, paling buruk ia mengulang
/// sesuatu. Tidak pernah merusak, tidak pernah hening.
///
/// | Mode          | Label                        | Aksi                     |
/// |---------------|------------------------------|--------------------------|
/// | Deteksi Objek | "Hentikan" / "Lanjutkan"     | Toggle deteksi           |
/// | Kenali Uang   | "Kenali Uang"                | 1 tap = 1 analisis       |
/// | Baca Teks     | "Baca teks" → "Jeda bacaan"  | Kontekstual              |
/// | Navigasi      | "Matikan Suara" / "Nyalakan" | Bisu/nyala suara panduan |
/// | Deskripsi Suasana | "Deskripsikan"           | Kirim foto ke VLM server |
/// | Cari Objek    | "Kirim - cari [X]"           | Scan                     |
///
/// Aturan pendukung: label berupa kata kerja + objek maksimal 3 kata (TalkBack
/// membacanya tiap fokus mendarat), tombol nonaktif tetap bersuara saat
/// ditekan, dan setiap tekan memberi getar konfirmasi.
///
/// [cameraLabel] sengaja **wajib**. Nilai bawaan lamanya "Ambil gambar" membuat
/// dua mode (Navigasi dan Deskripsi Suasana) menampilkan tombol aktif yang dibacakan
/// TalkBack sebagai "Ambil gambar, tombol" padahal menekannya tidak melakukan
/// apa pun - label yang berbohong, dan jalan buntu yang hening.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;
  final bool cameraEnabled;
  final String cameraLabel;

  /// Ikon tombol kiri. Bawaannya kamera, karena di sebagian besar mode aksi
  /// utamanya memang memotret atau menyalakan pengawasan.
  ///
  /// Mode Deskripsi Suasana memakai ikon cari-gambar: aksinya memang
  /// memotret, tapi hasilnya deskripsi, bukan foto yang disimpan. Ikon yang keliru di
  /// posisi tetap justru lebih membingungkan daripada tidak ada ikon.
  final IconData cameraIcon;

  /// Alasan tombol kiri nonaktif, diucapkan saat ditekan.
  final String? cameraDisabledReason;

  /// DO-24 - izin mikrofon dicabut: nonaktifkan tombol Bicara sepenuhnya.
  final bool micEnabled;
  /// Saat mode aktif punya STT sendiri (mis. Cari Objek), timpa visual
  /// listening/processing bawaan `VoiceProvider` supaya tombol tetap sesuai
  /// dengan apa yang sesungguhnya sedang berjalan.
  final bool? listeningOverride;
  final bool? processingOverride;

  const BottomActionBar({
    super.key,
    required this.cameraLabel,
    this.cameraIcon = Icons.camera_alt_outlined,
    this.onCameraPressed,
    this.onMicPressed,
    this.cameraEnabled = true,
    this.cameraDisabledReason,
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
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .06), blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .18), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -12),
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
              icon: cameraIcon,
              label: cameraLabel,
              // Tanpa handler = tidak aktif. Tidak ada lagi `?? () {}` yang
              // membuat tombol tampak hidup lalu diam saat ditekan.
              enabled: sideButtonsEnabled && onCameraPressed != null,
              disabledReason: listening
                  ? 'sedang mendengarkan'
                  : cameraDisabledReason,
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
          child: const ExcludeSemantics(
            child: Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: 28),
          ),
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

                // Sudah di mode voice - perilaku bawaan
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
              : ExcludeSemantics(
              child: Icon(listening ? Icons.mic : Icons.mic_none_rounded, color: AppColors.onDark, size: 30),
            ),
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

  /// Alasan tombol nonaktif - diucapkan saat ditekan, bukan didiamkan.
  final String? disabledReason;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.disabledReason,
  });

  /// Menekan tombol nonaktif TIDAK boleh hening.
  ///
  /// Untuk pengguna yang tidak melihat layar, tombol yang diam saat ditekan
  /// tidak bisa dibedakan dari aplikasi yang macet - dan satu-satunya cara
  /// menguji dugaannya adalah menekan lagi. Katakan alasannya, sekali, dengan
  /// getar pendek supaya jelas tekanannya terdaftar.
  void _explainDisabled() {
    final reason = disabledReason;
    TtsQueue().speak(
      reason == null ? '$label tidak tersedia sekarang.' : '$label. $reason',
      tier: SpeechTier.info,
    );
    HapticService.instance.info();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? label
          : disabledReason == null
              ? '$label, tidak tersedia'
              : '$label, tidak tersedia, $disabledReason',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : _explainDisabled,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 26,
                color: enabled ? AppColors.ink1 : AppColors.disabledInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
