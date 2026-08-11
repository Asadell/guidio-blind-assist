import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';

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

/// OB-01..OB-07 — panduan awal 3 langkah. Bisa dilewati (OB-05, menyebut
/// apa yang dilewatkan) dan diulang dari Pengaturan (OB-06).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  /// True saat dipanggil ulang dari Pengaturan (OB-06) — menampilkan tombol
  /// kembali alih-alih alur pertama-kali.
  final bool fromSettings;

  const OnboardingScreen({super.key, required this.onDone, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _announce();
  }

  void _announce() {
    final step = _steps[_index];
    TTSService.instance.speak('${step.title}. ${step.body}');
  }

  void _next() {
    if (_index < _steps.length - 1) {
      setState(() => _index++);
      // Transisi 240ms, narasi ditunda (OB-04).
      Future.delayed(const Duration(milliseconds: 240), _announce);
    } else {
      _finish();
    }
  }

  void _skip() {
    final skipped = _steps.length - 1 - _index;
    TTSService.instance.speak(
      skipped > 0
          ? 'Panduan dilewati. Bisa diulang kapan saja dari Pengaturan.'
          : 'Panduan selesai.',
    );
    _finish();
  }

  void _finish() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Column(
            children: [
              if (widget.fromSettings)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Kembali ke Pengaturan'),
                  ),
                ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Column(
                  key: ValueKey(_index),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                      child: Icon(step.icon, size: 44, color: AppColors.actionLabel),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(step.title, textAlign: TextAlign.center, style: AppTypography.headline()),
                    const SizedBox(height: AppSpacing.s3),
                    Text(step.body, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
                  ],
                ),
              ),
              const Spacer(),
              Row(
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
              const SizedBox(height: AppSpacing.s6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_index == _steps.length - 1 ? 'Mulai pakai Vinara' : 'Lanjut'),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              if (!widget.fromSettings)
                TextButton(onPressed: _skip, child: const Text('Lewati panduan')),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}
