/// Intent perintah suara - bagian 14 IMPLEMENTASI.md. 20 intent baku.
enum VoiceIntent {
  // Ganti mode
  modeMoney,
  modeReadText,
  modeDetection,
  modeNavigation,
  modeAssistant,
  modeFindObject,
  modeSettings,
  // Tindakan dalam mode
  actionCapture,
  actionReplay,
  actionGoBack,
  actionSummary,
  actionStopWalking,
  actionShowAll,
  actionTorch,
  describeScene,
  // Kontrol pemutaran
  playPause,
  playResume,
  playFaster,
  playSlower,
  playRepeatSection,
  // Bantuan
  helpWhat,
  helpWhereAmI,
  // Cari Objek - target dinamis, tangkap terpisah dari intent
  findObjectTarget,
}

extension VoiceIntentX on VoiceIntent {
  bool get isModeChange => switch (this) {
        VoiceIntent.modeMoney ||
        VoiceIntent.modeReadText ||
        VoiceIntent.modeDetection ||
        VoiceIntent.modeNavigation ||
        VoiceIntent.modeAssistant ||
        VoiceIntent.modeFindObject ||
        VoiceIntent.modeSettings =>
          true,
        _ => false,
      };
  String? get commandPhrase => switch (this) {
        VoiceIntent.modeMoney => 'mode uang',
        VoiceIntent.modeReadText => 'mode baca',
        VoiceIntent.modeDetection => 'mode deteksi',
        VoiceIntent.modeNavigation => 'mode navigasi',
        VoiceIntent.modeAssistant => 'mode asisten',
        VoiceIntent.modeFindObject => 'mode cari objek',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.describeScene => 'deskripsikan suasana',
        _ => null,
      };
}

/// Hasil parsing satu ucapan.
class VoiceCommand {
  final VoiceIntent? intent;
  final String rawText;
  /// Untuk `findObjectTarget` / `mode.findObject "cari [nama barang]"` -
  /// nama barang yang diekstrak dari ucapan.
  final String? argument;
  /// Dua tebakan terdekat saat tidak dikenali - bagian 14 "Tidak dikenali".
  final List<VoiceIntent> suggestions;

  const VoiceCommand({
    required this.rawText,
    this.intent,
    this.argument,
    this.suggestions = const [],
  });

  bool get recognized => intent != null;
}
