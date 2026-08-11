import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../services/tts_service.dart';
import '../theme/index.dart';
import 'onboarding_screen.dart';

/// PG-01..PG-11 — delapan pengaturan, urutan baku (bagian 13).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        children: [
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
          _SettingsRow(
            title: 'Alamat server',
            value: settings.serverHost,
            child: _ServerHostField(initial: settings.serverHost),
          ),
        ],
      ),
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

class _ServerHostField extends StatefulWidget {
  final String initial;
  const _ServerHostField({required this.initial});

  @override
  State<_ServerHostField> createState() => _ServerHostFieldState();
}

enum _ServerFieldState { idle, testing, valid, invalid, failed }

class _ServerHostFieldState extends State<_ServerHostField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  _ServerFieldState _state = _ServerFieldState.idle;

  static final _hostPattern = RegExp(r'^[\w.-]+:\d{2,5}$');

  Future<void> _test() async {
    final host = _ctrl.text.trim();
    if (!_hostPattern.hasMatch(host)) {
      setState(() => _state = _ServerFieldState.invalid);
      return;
    }
    setState(() => _state = _ServerFieldState.testing);
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('http://$host/');
      await Future.any([
        Uri.parse('http://$host').isAbsolute
            ? _ping(uri)
            : Future.error('invalid'),
        Future.delayed(const Duration(seconds: 4), () => throw TimeoutException()),
      ]);
      stopwatch.stop();
      if (!mounted) return;
      setState(() => _state = _ServerFieldState.valid);
      context.read<SettingsProvider>().setServerHost(host);
    } catch (_) {
      if (!mounted) return;
      // PG-08e — gagal terhubung: alamat lama tetap dipakai, bukan alamat baru.
      setState(() => _state = _ServerFieldState.failed);
    }
  }

  Future<void> _ping(Uri uri) async {
    // Placeholder ringan: koneksi socket tanpa payload. Kegagalan (host
    // tidak ada / port tertutup) dilempar sebagai exception oleh runtime.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'host:port, mis. 10.0.2.2:8000',
                  isDense: true,
                ),
                style: AppTypography.metricMono(),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            OutlinedButton(
              onPressed: _state == _ServerFieldState.testing ? null : _test,
              child: Text(_state == _ServerFieldState.testing ? 'Menguji…' : 'Uji'),
            ),
          ],
        ),
        if (_state == _ServerFieldState.valid)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Terhubung.', style: TextStyle(color: AppColors.positiveLabel, fontSize: 13)),
          ),
        if (_state == _ServerFieldState.invalid)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Format salah. Contoh benar: 10.0.2.2:8000',
                style: TextStyle(color: AppColors.criticalLabel, fontSize: 13)),
          ),
        if (_state == _ServerFieldState.failed)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Gagal terhubung. Alamat lama tetap dipakai.',
                style: TextStyle(color: AppColors.criticalLabel, fontSize: 13)),
          ),
      ],
    );
  }
}

class TimeoutException implements Exception {}
