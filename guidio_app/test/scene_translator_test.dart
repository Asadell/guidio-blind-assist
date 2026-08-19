import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/scene_translator.dart';

/// Dua hal yang dikunci tes ini:
///
/// 1. Caption khas Moondream2 benar-benar terterjemahkan, dengan urutan
///    kata Indonesia (kata benda dulu, sifat menyusul).
/// 2. Kalimat yang di luar jangkauan kamus **menyerah** alih-alih
///    menghasilkan Bahasa Indonesia yang kacau. Pengguna tunanetra tidak
///    punya layar untuk memverifikasi tebakan kita, jadi menyerah dengan
///    jujur lebih aman daripada menebak dengan percaya diri.
void main() {
  group('caption khas Moondream2 diterjemahkan', () {
    const cases = <String, List<String>>{
      'A man standing in front of a white building.':
          ['pria', 'berdiri', 'di depan', 'gedung putih'],
      'A table with a laptop and a cup of coffee.':
          ['meja', 'dengan', 'laptop', 'dan', 'cangkir kopi'],
      'Two people walking down a street.':
          ['dua', 'orang-orang', 'berjalan', 'jalan'],
      'A wooden table with some books on it.':
          ['meja kayu', 'dengan', 'beberapa', 'buku-buku'],
      'A dog sitting on the floor near a chair.':
          ['anjing', 'duduk', 'di atas', 'lantai', 'di dekat', 'kursi'],
      'A busy market with many people.':
          ['pasar ramai', 'dengan', 'banyak', 'orang-orang'],
    };

    cases.forEach((english, mustContain) {
      test('"$english"', () {
        final r = translateSceneCaption(english);
        expect(r.isUsable, isTrue,
            reason: 'cakupan hanya ${r.coverage.toStringAsFixed(2)}');
        final id = r.indonesian!.toLowerCase();
        for (final fragment in mustContain) {
          expect(id, contains(fragment));
        }
      });
    });
  });

  group('urutan kata Indonesia', () {
    test('kata sifat pindah SESUDAH kata benda', () {
      final r = translateSceneCaption('a white building');
      expect(r.indonesian, 'Gedung putih.');
    });

    test('bukan "putih gedung"', () {
      final r = translateSceneCaption('a large red car');
      expect(r.indonesian!.toLowerCase(), contains('mobil merah'));
    });
  });

  group('artikel Inggris dibuang', () {
    test('"a" dan "the" tidak muncul di hasil', () {
      final r = translateSceneCaption('The man is near the door.');
      final id = r.indonesian!.toLowerCase();
      expect(id.split(' '), isNot(contains('a')));
      expect(id.split(' '), isNot(contains('the')));
    });
  });

  group('menyerah saat di luar jangkauan', () {
    test('kalimat penuh kata asing mengembalikan null', () {
      final r = translateSceneCaption(
        'An intricate baroque chandelier suspended amidst ornate cornices.',
      );
      expect(r.isUsable, isFalse);
      expect(r.indonesian, isNull);
    });

    test('caption kosong tidak crash', () {
      expect(translateSceneCaption('').isUsable, isFalse);
      expect(translateSceneCaption('   ').isUsable, isFalse);
    });
  });

  group('hasil selalu kalimat yang layak diucapkan', () {
    test('diawali huruf besar dan diakhiri titik', () {
      final r = translateSceneCaption('a cat on a table');
      expect(r.indonesian!.startsWith(RegExp(r'[A-Z]')), isTrue);
      expect(r.indonesian!.endsWith('.'), isTrue);
    });

    test('tidak ada spasi ganda', () {
      final r = translateSceneCaption('A man with a bag and a hat.');
      expect(r.indonesian!, isNot(contains('  ')));
    });
  });
}
