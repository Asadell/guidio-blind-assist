import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';
import 'onboarding_screen.dart';
import 'server_address_screen.dart';

/// PG-01..PG-11 — delapan pengaturan, urutan baku (bagian 13).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// PG-11 — penyimpanan penuh. Kartu error tetap di atas karena perannya
  /// memberi tahu, tapi aksinya **diulang di dasar layar**: aksi yang hanya
  /// ada di kartu atas memaksa pengguna low vision menjangkau zona merah.
  Future<void> _manageStorage() async {
    await TTSService.instance.speak(
      'Membuka Pengaturan ponsel. Cari menu Penyimpanan, lalu hapus cache Vinara.',
    );
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final storageLow = context.watch<GlobalConditionsProvider>().isStorageLow;

    final list = ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        children: [
          if (storageLow) const _StorageFullCard(),
          _SettingsRow(
            title: 'Kecepatan bicara TTS',
            value: '${(settings.speechRate * 200).round()}%',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.speechRate,
                    min: 0.25,
                    max: 1.0,
                    onChanged: (v) => context.read<SettingsProvider>().setSpeechRate(v),
                  ),
                ),
                TextButton(
                  onPressed: () => TTSService.instance.speak(
                    'Motor di sebelah kanan atas, sekitar dua koma delapan meter.',
                  ),
                  child: const Text('Coba dengar'),
                ),
              ],
            ),
          ),
          _SettingsRow(
            title: 'Tingkat kecerewetan',
            value: _verbosityLabel(settings.verbosity),
            child: SegmentedButton<Verbosity>(
              segments: const [
                ButtonSegment(value: Verbosity.ringkas, label: Text('Ringkas')),
                ButtonSegment(value: Verbosity.sedang, label: Text('Sedang')),
                ButtonSegment(value: Verbosity.detail, label: Text('Detail')),
              ],
              selected: {settings.verbosity},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setVerbosity(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Getar',
            value: _vibrationLabel(settings.vibrationMode),
            child: SegmentedButton<VibrationMode>(
              segments: const [
                ButtonSegment(value: VibrationMode.active, label: Text('Aktif')),
                ButtonSegment(value: VibrationMode.criticalOnly, label: Text('Critical saja')),
                ButtonSegment(value: VibrationMode.off, label: Text('Mati')),
              ],
              selected: {settings.vibrationMode},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setVibrationMode(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Ambang jarak peringatan',
            value: '${settings.distanceThresholdM.toStringAsFixed(1)} m',
            child: Slider(
              value: settings.distanceThresholdM,
              min: 1,
              max: 5,
              divisions: 8,
              label: '${settings.distanceThresholdM.toStringAsFixed(1)} m',
              onChanged: (v) => context.read<SettingsProvider>().setDistanceThreshold(v),
            ),
          ),
          _SettingsRow(
            title: 'Tema',
            value: _themeLabel(settings.themeMode),
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.light, label: Text('Terang')),
                ButtonSegment(value: AppThemeMode.dark, label: Text('Gelap')),
                ButtonSegment(value: AppThemeMode.highContrast, label: Text('Kontras tinggi')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => context.read<SettingsProvider>().setThemeMode(s.first),
            ),
          ),
          _SettingsRow(
            title: 'Ukuran teks',
            value: '${(settings.fontScale * 100).round()}%',
            child: Slider(
              value: settings.fontScale,
              min: 1.0,
              max: 2.0,
              divisions: 4,
              label: '${(settings.fontScale * 100).round()}%',
              onChanged: (v) => context.read<SettingsProvider>().setFontScale(v),
            ),
          ),
          _SettingsRow(
            title: 'Ulangi panduan awal',
            value: null,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(fromSettings: true, onDone: () {}),
                ),
              ),
              child: const Text('Mulai panduan'),
            ),
          ),
          // PG-08 — halaman kontrol sendiri, bukan kontrol inline. Aksinya
          // ("Uji koneksi" / "Simpan alamat") butuh `zone/page-action`, dan
          // zona itu tidak bisa hadir di tengah daftar.
          _SettingsRow(
            title: 'Alamat server',
            value: settings.serverHost,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerAddressScreen()),
              ),
              child: const Text('Ubah alamat server'),
            ),
          ),
        ],
      );

    // PG-11 — selama penyimpanan penuh, aksinya diulang di `zone/page-action`
    // supaya terjangkau tanpa menggulung dan tanpa menjangkau kartu di atas.
    // Di luar kondisi itu Pengaturan tidak punya aksi halaman, jadi tidak ada
    // zona aksi sama sekali — daftar boleh memenuhi layar.
    if (storageLow) {
      return PageActionScaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(title: const Text('Pengaturan')),
        primaryLabel: 'Kelola penyimpanan',
        primaryIcon: Icons.folder_open_rounded,
        onPrimary: _manageStorage,
        body: list,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: list,
    );
  }

  String _verbosityLabel(Verbosity v) => switch (v) {
        Verbosity.ringkas => 'Ringkas',
        Verbosity.sedang => 'Sedang',
        Verbosity.detail => 'Detail',
      };

  String _vibrationLabel(VibrationMode m) => switch (m) {
        VibrationMode.active => 'Aktif',
        VibrationMode.criticalOnly => 'Hanya Critical',
        VibrationMode.off => 'Mati',
      };

  String _themeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.light => 'Terang',
        AppThemeMode.dark => 'Gelap',
        AppThemeMode.highContrast => 'Kontras tinggi',
      };
}

/// PG-11 — kartu error penyimpanan penuh. Tetap di atas: perannya memberi
/// tahu, dan pemberitahuan harus terbaca lebih dulu. Aksinya diulang di
/// `zone/page-action` oleh [SettingsScreen], bukan hanya ada di sini.
class _StorageFullCard extends StatelessWidget {
  const _StorageFullCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Penyimpanan hampir penuh. Pengaturan baru mungkin gagal disimpan '
          'dan nilai lama akan tetap dipakai. Tombol Kelola penyimpanan ada di dasar layar.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin, AppSpacing.s1, AppSpacing.screenMargin, AppSpacing.s3,
          ),
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: const BoxDecoration(
            color: AppColors.warningTint,
            borderRadius: AppRadius.cardInner,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sd_storage_outlined, size: 22, color: AppColors.warningLabel),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penyimpanan hampir penuh',
                        style: AppTypography.bodyStrong(color: AppColors.warningLabel)),
                    const SizedBox(height: 2),
                    Text(
                      'Pengaturan baru mungkin gagal disimpan, dan nilai lama akan tetap dipakai.',
                      style: AppTypography.caption(color: AppColors.warningLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? value;
  final Widget child;

  const _SettingsRow({required this.title, required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: value == null ? title : '$title, $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.s1),
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.cardInner,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppTypography.bodyStrong())),
                if (value != null) Text(value!, style: AppTypography.label(color: AppColors.ink2)),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            child,
          ],
        ),
      ),
    );
  }
}

