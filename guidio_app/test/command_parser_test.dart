import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/command_parser.dart';
import 'package:guidio_app/core/voice/intents.dart';

/// Tes ini mengunci dua hal yang pernah rusak diam-diam:
///
/// 1. **Contoh ucapan di dokumen arsitektur harus benar-benar bekerja.**
///    Delapan di antaranya dulu tidak dikenali sama sekali, jadi siapa pun
///    yang menguji aplikasi dengan membaca dokumennya akan menyimpulkan
///    parsernya rusak.
/// 2. **Frasa spesifik menang atas kata umum.** "stop navigasi" dulu memicu
///    keluar dari mode karena kata 'stop' ada di `actionGoBack` yang
///    kebetulan dideklarasikan lebih awal di Map.
void main() {
  VoiceIntent? intentOf(String text) => CommandParser.parse(text).intent;

  group('contoh ucapan dari dokumen arsitektur', () {
    const cases = <String, VoiceIntent>{
      // Deteksi Objek
      'deteksi': VoiceIntent.modeDetection,
      'awasi jalan': VoiceIntent.modeDetection,
      'mode jalan': VoiceIntent.modeNavigation,
      'deteksi objek': VoiceIntent.modeDetection,
      'tuntun aku': VoiceIntent.modeDetection,
      // Kenali Uang
      'uang': VoiceIntent.modeMoney,
      'kenali uang': VoiceIntent.modeMoney,
      'cek duit': VoiceIntent.modeMoney,
      'duit berapa': VoiceIntent.modeMoney,
      // Baca Teks
      'baca teks': VoiceIntent.modeReadText,
      'tolong bacain': VoiceIntent.modeReadText,
      'baca dong': VoiceIntent.modeReadText,
      'tulung wacakno': VoiceIntent.modeReadText,
      // Navigasi
      'navigasi': VoiceIntent.modeNavigation,
      'jalan mana': VoiceIntent.modeNavigation,
      'arahan jalur': VoiceIntent.modeNavigation,
      // Asisten
      'asisten': VoiceIntent.modeAssistant,
      'ngobrol': VoiceIntent.modeAssistant,
      // Pengaturan
      'pengaturan': VoiceIntent.modeSettings,
      'seting': VoiceIntent.modeSettings,
    };

    cases.forEach((utterance, expected) {
      test('"$utterance" → $expected', () {
        expect(intentOf(utterance), expected);
      });
    });
  });

  group('cari objek dengan target dinamis', () {
    test('"cari dompet" mengekstrak target', () {
      final cmd = CommandParser.parse('cari dompet');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompet');
    });

    test('"cariin kunci dong" membuang kata pengisi', () {
      final cmd = CommandParser.parse('cariin kunci dong');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'kunci');
    });

    test('"teang dompu" (Sunda) dikenali', () {
      final cmd = CommandParser.parse('teang dompu');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompu');
    });

    test('"cari uang yang jatuh" mencari benda, bukan membuka mode uang', () {
      // Kata 'uang' ada di kamus modeMoney. Pola cari-objek diperiksa lebih
      // dulu justru supaya kasus ini tidak salah arah.
      final cmd = CommandParser.parse('cari uang yang jatuh');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
    });
  });

  group('frasa spesifik menang atas kata umum', () {
    test('"stop navigasi" menghentikan panduan, bukan keluar mode', () {
      expect(intentOf('stop navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti navigasi" sama', () {
      expect(intentOf('berhenti navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti dulu" adalah jeda suara', () {
      expect(intentOf('berhenti dulu'), VoiceIntent.playPause);
    });

    test('"kembali" tetap actionGoBack', () {
      expect(intentOf('kembali'), VoiceIntent.actionGoBack);
    });
  });

  group('prefiks transisi mode natural', () {
    test('"saya pengin pindah ke mode baca teks"', () {
      expect(
        intentOf('saya pengin pindah ke mode baca teks'),
        VoiceIntent.modeReadText,
      );
    });

    test('"ganti mode ke uang"', () {
      expect(intentOf('ganti mode ke uang'), VoiceIntent.modeMoney);
    });
  });

  group('pencocokan pada batas kata', () {
    test('kata yang hanya mengandung potongan frasa tidak ikut cocok', () {
      // 'uang' tidak boleh tercabut dari 'ruangan'.
      expect(intentOf('ruangan ini kayak gimana'), isNot(VoiceIntent.modeMoney));
    });
  });

  group('saran hanya berisi intent yang punya handler', () {
    test('setiap saran ada di suggestableIntents', () {
      const gibberish = [
        'anu itu yang tadi bagaimana',
        'coba yang begitu deh',
        'hmm apa ya kira-kira',
      ];
      for (final text in gibberish) {
        final cmd = CommandParser.parse(text);
        for (final s in cmd.suggestions) {
          expect(
            CommandParser.suggestableIntents.contains(s),
            isTrue,
            reason: '"$text" menyarankan $s yang tidak punya handler — '
                'inilah yang membuat "Maksudmu X?" → "X" → "belum saya kenali"',
          );
        }
      }
    });
  });
}
