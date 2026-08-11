import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// IZ-01..IZ-07 — dua kartu alasan terpisah (kamera dulu, lalu mikrofon).
/// IZ-04: ditolak permanen dibacakan empat langkah bernomor, bertahap.
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionsScreen({super.key, required this.onDone});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

enum _Step { camera, microphone }

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  _Step _step = _Step.camera;
  bool _permanentlyDenied = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _announceStep();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // IZ-06 — kembali dari Pengaturan sistem, cek ulang status izin.
    if (state == AppLifecycleState.resumed && _permanentlyDenied) {
      _checkAfterSettingsReturn();
    }
  }

  Future<void> _checkAfterSettingsReturn() async {
    final granted = _step == _Step.camera
        ? await Permission.camera.isGranted
        : await Permission.microphone.isGranted;
    if (granted) {
      setState(() => _permanentlyDenied = false);
      await TTSService.instance.speak('Izin diberikan. Melanjutkan.');
      _advance();
    }
  }

  void _announceStep() {
    final label = _step == _Step.camera ? 'kamera' : 'mikrofon';
    TTSService.instance.speak('Vinara butuh izin $label untuk berfungsi.');
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    final permission = _step == _Step.camera ? Permission.camera : Permission.microphone;
    final status = await permission.request();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (status.isGranted) {
      await TTSService.instance.speak('Izin diberikan.');
      _advance();
    } else if (status.isPermanentlyDenied) {
      setState(() => _permanentlyDenied = true);
      // IZ-04 — empat langkah bernomor, dibacakan satu per satu, bertahap.
      await TTSService.instance.speak(
        'Izin ditolak permanen. Empat langkah untuk menyalakannya kembali. '
        'Langkah satu: buka Pengaturan ponsel.',
      );
    } else {
      await TTSService.instance.speak('Izin belum diberikan. Coba lagi kapan saja.');
    }
  }

  void _advance() {
    if (_step == _Step.camera) {
      setState(() {
        _step = _Step.microphone;
        _permanentlyDenied = false;
      });
      _announceStep();
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCamera = _step == _Step.camera;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
            child: _permanentlyDenied
                ? _PermanentlyDeniedCard(
                    label: isCamera ? 'kamera' : 'mikrofon',
                    onOpenSettings: () async {
                      await TTSService.instance.speak(
                        'Langkah dua: cari menu Izin aplikasi. '
                        'Langkah tiga: aktifkan izin ${isCamera ? 'Kamera' : 'Mikrofon'}. '
                        'Langkah empat: kembali ke Vinara.',
                      );
                      await openAppSettings();
                    },
                    onRetryStep: () async {
                      await TTSService.instance.speak('Mengulangi langkah ini.');
                    },
                  )
                : PermissionCard(
                    icon: isCamera ? Icons.camera_alt_outlined : Icons.mic_none_rounded,
                    title: isCamera ? 'Izin kamera' : 'Izin mikrofon',
                    reason: isCamera
                        ? 'Kamera dipakai untuk mendeteksi rintangan, membaca teks, mengenali uang, dan mencari barang.'
                        : 'Mikrofon dipakai untuk perintah suara dan Asisten Suara. Fitur lain tetap berjalan penuh tanpa mikrofon.',
                    actionLabel: _requesting ? 'Meminta izin…' : 'Izinkan ${isCamera ? 'kamera' : 'mikrofon'}',
                    actionDisabled: _requesting,
                    actionDisabledReason: _requesting ? 'Menunggu jawabanmu' : null,
                    onAction: _request,
                  ),
          ),
        ),
      ),
    );
  }
}

class _PermanentlyDeniedCard extends StatelessWidget {
  final String label;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetryStep;

  const _PermanentlyDeniedCard({
    required this.label,
    required this.onOpenSettings,
    required this.onRetryStep,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Buka Pengaturan ponsel',
      'Cari menu Izin aplikasi',
      'Aktifkan izin yang dibutuhkan',
      'Kembali ke Vinara',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, size: 34, color: AppColors.criticalLabel),
          const SizedBox(height: AppSpacing.s4),
          Text('Izin $label ditolak permanen', textAlign: TextAlign.center, style: AppTypography.title()),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Nyalakan lagi lewat Pengaturan ponsel, empat langkah:',
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.ink2),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}', style: AppTypography.caption(color: AppColors.actionLabel)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(child: Text(steps[i], style: AppTypography.body())),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s4),
          FullScreenButton(label: 'Buka Pengaturan ponsel', onTap: onOpenSettings, icon: Icons.settings_outlined),
          const SizedBox(height: AppSpacing.s3),
          TextButton(onPressed: onRetryStep, child: const Text('Ulangi langkah ini')),
        ],
      ),
    );
  }
}
