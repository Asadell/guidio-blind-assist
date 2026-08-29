import 'dart:async';

import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

class _Step {
  final IconData icon;
  final String title;
  final String body;
  const _Step({required this.icon, required this.title, required this.body});
}

const _steps = [
  _Step(
    icon: Icons.remove_red_eye_outlined,
    title: 'Vinara melihat untukmu',
    body: 'Kamera membaca dunia di depanmu, Vinara menjelaskannya lewat suara dan getar.',
  ),
  _Step(
    icon: Icons.apps_rounded,
    title: 'Tiga tombol yang tidak pernah pindah',
    body: 'Ambil gambar, Bicara, dan Pilih mode selalu ada di posisi yang sama, di bawah layar.',
  ),
  _Step(
    icon: Icons.mic_none_rounded,
    title: 'Cukup bicara',
    body: 'Ucapkan nama mode atau perintah, Vinara langsung melompat ke sana. Menu hanya cadangan.',
  ),
];

/// OB-01..OB-07 - panduan awal 3 langkah. Bisa dilewati (OB-05, menyebut
/// apa yang dilewatkan) dan diulang dari Pengaturan (OB-06).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  /// True saat dipanggil ulang dari Pengaturan (OB-06) - menampilkan tombol
  /// kembali alih-alih alur pertama-kali.
  final bool fromSettings;

  const OnboardingScreen({super.key, required this.onDone, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  /// Narasi halaman yang menunggu transisi 240 ms selesai.
  ///
  /// Dibatalkan setiap kali pengguna maju lagi. Tanpa itu, mengetuk "Lanjut"
  /// dua kali dalam 240 ms meninggalkan satu timer basi yang tetap berbunyi
  /// sesudah halamannya berganti.
  Timer? _announceTimer;

  @override
  void initState() {
    super.initState();
    _announce();
  }

  @override
  void dispose() {
    _announceTimer?.cancel();
    super.dispose();
  }

  /// Narasi halaman ini, MEMOTONG narasi halaman sebelumnya.
  ///
  /// `interrupt: true` bukan pilihan gaya. `TTSService.speak` merantai setiap
  /// ucapan di belakang ucapan sebelumnya, jadi tanpa pemotongan, mengetuk
  /// "Lanjut" tiga kali dengan cepat menumpuk tiga narasi panjang yang harus
  /// habis satu per satu - dan tumpukan itu terbawa keluar dari layar ini,
  /// ke layar izin, sampai ke keputusan pindah langkah di sana.
  ///
  /// Narasi halaman yang sudah ditinggalkan tidak lagi menggambarkan apa pun
  /// yang ada di layar. Bagi pengguna tunanetra itu lebih buruk daripada
  /// diam: satu-satunya sumber informasinya sedang menjelaskan halaman lain.
  void _announce() {
    final step = _steps[_index];
    TTSService.instance.speak('${step.title}. ${step.body}', interrupt: true);
  }

  void _next() {
    _announceTimer?.cancel();
    if (_index < _steps.length - 1) {
      setState(() => _index++);
      // Transisi 240ms, narasi ditunda (OB-04).
      _announceTimer =
          Timer(const Duration(milliseconds: 240), () {
        if (mounted) _announce();
      });
    } else {
      _finish('Panduan selesai.');
    }
  }

  void _skip() {
    final skipped = _steps.length - 1 - _index;
    _finish(skipped > 0
        ? 'Panduan dilewati. Bisa diulang kapan saja dari Pengaturan.'
        : 'Panduan selesai.');
  }

  /// Tutup panduan dan pindah SEKARANG.
  ///
  /// `onDone` dipanggil tanpa menunggu [message] selesai diucapkan. Yang
  /// menentukan posisi pengguna adalah ketukannya, bukan panjang kalimat yang
  /// sedang dibacakan - kalimatnya menyusul di layar berikutnya.
  void _finish(String message) {
    _announceTimer?.cancel();
    TTSService.instance.speak(message, interrupt: true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    // OB-01..OB-07 - layar penunjang, memakai `zone/page-action`. "Lewati
    // panduan" (dan "Kembali ke Pengaturan" pada OB-06) adalah tombol sekunder
    // 56 dp tepat di atas primer, **tidak pernah di pojok kanan atas**: pojok
    // atas adalah zona merah thumb zone, butuh ganti pegangan.
    return PageActionScaffold(
      primaryLabel: isLast ? 'Mulai pakai Vinara' : 'Lanjut',
      onPrimary: _next,
      secondaryLabel: widget.fromSettings ? 'Kembali ke Pengaturan' : 'Lewati panduan',
      onSecondary: widget.fromSettings ? () => Navigator.of(context).pop() : _skip,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Column(
            children: [
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Column(
                  key: ValueKey(_index),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                        child: Icon(step.icon, size: 44, color: AppColors.actionLabel),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Semantics(
                      header: true,
                      // Eyebrow langkah dibaca sebagai bagian judul - bagian 10
                      // nomor 5, bukan simpul fokus tersendiri.
                      label: 'Langkah ${_index + 1} dari ${_steps.length}. ${step.title}',
                      child: ExcludeSemantics(
                        child: Text(step.title, textAlign: TextAlign.center, style: AppTypography.headline()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(step.body, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
                  ],
                ),
              ),
              const Spacer(),
              // Titik langkah: ExcludeSemantics wajib (bagian 16) - maknanya
              // sudah dibawa label judul di atas.
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (i) => Container(
                      width: i == _index ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.actionLabel : AppColors.surfaceSunk,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
            ],
          ),
        ),
      ),
    );
  }
}
