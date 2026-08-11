import 'intents.dart';

/// CommandParser — varian ucapan → intent, sesuai tabel bagian 14.
/// Sengaja berbasis keyword lokal (0ms, aman offline) mengikuti pola
/// [VoiceProvider] yang sudah ada. Panggil [parse] dengan teks hasil STT.
class CommandParser {
  static const Map<VoiceIntent, List<String>> _phrases = {
    VoiceIntent.modeMoney: [
      'buka mode uang', 'kenali uang', 'ini uang berapa', 'mode uang', 'cek uang', 'berapa ini',
    ],
    VoiceIntent.modeReadText: [
      'baca teks', 'bacakan', 'buka mode baca', 'baca tulisan ini', 'apa tulisannya',
    ],
    VoiceIntent.modeDetection: [
      'deteksi objek', 'mode deteksi', 'ada apa di depan',
    ],
    VoiceIntent.modeNavigation: [
      'mode navigasi', 'mau jalan', 'bantu jalan', 'navigasi',
    ],
    VoiceIntent.modeAssistant: [
      'asisten', 'tanya', 'mode suara',
    ],
    VoiceIntent.modeFindObject: [
      'cari objek', 'cari barang', 'carikan',
    ],
    VoiceIntent.modeSettings: [
      'pengaturan', 'setelan', 'buka pengaturan',
    ],
    VoiceIntent.actionCapture: [
      'ambil gambar', 'jepret', 'foto',
    ],
    VoiceIntent.actionReplay: [
      'putar ulang', 'ulangi', 'baca lagi',
    ],
    VoiceIntent.actionSummary: [
      'ringkas', 'singkat saja', 'baca ringkasannya',
    ],
    VoiceIntent.actionStopWalking: [
      'selesai jalan', 'sudah sampai', 'berhenti navigasi',
    ],
    VoiceIntent.actionShowAll: [
      'lihat semua',
    ],
    VoiceIntent.actionTorch: [
      'nyalakan lampu', 'nyalakan senter', 'lampu kamera',
    ],
    VoiceIntent.playPause: [
      'jeda', 'berhenti dulu', 'stop',
    ],
    VoiceIntent.playResume: [
      'lanjut', 'terusin', 'lanjutkan',
    ],
    VoiceIntent.playFaster: [
      'lebih cepat', 'percepat',
    ],
    VoiceIntent.playSlower: [
      'lebih pelan', 'pelan-pelan',
    ],
    VoiceIntent.playRepeatSection: [
      'ulangi bagian', 'ulang yang tadi',
    ],
    VoiceIntent.helpWhat: [
      'bisa apa', 'apa saja', 'bantuan', 'tolong',
    ],
    VoiceIntent.helpWhereAmI: [
      'ini mode apa', 'saya di mana',
    ],
  };

  /// "cari [nama barang]" — pola khusus Cari Objek dengan argumen dinamis.
  static final RegExp _findObjectWithArg = RegExp(r'^cari (?!objek$|barang$)(.+)$');

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand(rawText: rawText);

    final argMatch = _findObjectWithArg.firstMatch(text);
    if (argMatch != null) {
      return VoiceCommand(
        rawText: rawText,
        intent: VoiceIntent.findObjectTarget,
        argument: argMatch.group(1)?.trim(),
      );
    }

    for (final entry in _phrases.entries) {
      for (final phrase in entry.value) {
        if (text.contains(phrase)) {
          return VoiceCommand(rawText: rawText, intent: entry.key);
        }
      }
    }

    return VoiceCommand(
      rawText: rawText,
      suggestions: _nearestGuesses(text),
    );
  }

  /// Dua tebakan terdekat berbasis jumlah kata yang beririsan — dipakai untuk
  /// naskah "Saya dengar X. Maksudmu Y, atau Z?" (bagian 14, "Tidak dikenali").
  static List<VoiceIntent> _nearestGuesses(String text) {
    final words = text.split(RegExp(r'\s+')).toSet();
    final scored = <MapEntry<VoiceIntent, int>>[];

    for (final entry in _phrases.entries) {
      var best = 0;
      for (final phrase in entry.value) {
        final phraseWords = phrase.split(RegExp(r'\s+')).toSet();
        final overlap = words.intersection(phraseWords).length;
        if (overlap > best) best = overlap;
      }
      if (best > 0) scored.add(MapEntry(entry.key, best));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(2).map((e) => e.key).toList();
  }
}

/// Label ucapan untuk ditawarkan balik ke pengguna, mis. "Maksudmu kenali
/// uang, atau cari uang yang jatuh?" — bagian 14.
extension VoiceIntentSpokenLabel on VoiceIntent {
  String get spokenLabel => switch (this) {
        VoiceIntent.modeMoney => 'kenali uang',
        VoiceIntent.modeReadText => 'baca teks',
        VoiceIntent.modeDetection => 'deteksi objek',
        VoiceIntent.modeNavigation => 'navigasi',
        VoiceIntent.modeAssistant => 'asisten suara',
        VoiceIntent.modeFindObject => 'cari objek',
        VoiceIntent.modeSettings => 'pengaturan',
        VoiceIntent.actionCapture => 'ambil gambar',
        VoiceIntent.actionReplay => 'putar ulang',
        VoiceIntent.actionSummary => 'ringkas',
        VoiceIntent.actionStopWalking => 'selesai jalan',
        VoiceIntent.actionShowAll => 'lihat semua',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.playPause => 'jeda',
        VoiceIntent.playResume => 'lanjut',
        VoiceIntent.playFaster => 'lebih cepat',
        VoiceIntent.playSlower => 'lebih pelan',
        VoiceIntent.playRepeatSection => 'ulangi bagian',
        VoiceIntent.helpWhat => 'bantuan',
        VoiceIntent.helpWhereAmI => 'saya di mana',
        VoiceIntent.findObjectTarget => 'cari barang',
      };
}
