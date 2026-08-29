/// Pengumuman masuk mode - khususnya Mode Cari Objek.
///
/// Layar Cari Objek bisa dimasuki dari dua arah yang menuntut kalimat
/// berbeda, dan selama ini keduanya mendapat kalimat yang sama - yang benar
/// hanya untuk salah satunya.
///
/// Pengguna mengucapkan "carikan kacamata", layar menampilkan "Mencari
/// kacamata", tapi yang terdengar cuma "Cari Objek aktif. Sebutkan barang
/// yang kamu cari." Layarnya benar; suaranya - satu-satunya yang bisa
/// diakses pengguna tunanetra - menyuruhnya menyebutkan barang yang baru
/// saja dia sebutkan.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/providers/app_mode_provider.dart';

void main() {
  String compose({
    AppMode mode = AppMode.findObject,
    String? prefix,
    String? introOverride,
    bool withIntro = true,
  }) =>
      AppModeProvider.composeEntryAnnouncement(
        mode: mode,
        prefix: prefix,
        introOverride: introOverride,
        withIntro: withIntro,
      );

  group('masuk lewat lembar Pilih Mode (belum ada target)', () {
    test('kalimat pembuka bawaan mode dipakai', () {
      final out = compose();
      expect(out, contains('Cari Objek aktif.'));
      // Di jalur ini "Sebutkan barang yang kamu cari" memang tepat.
      expect(out, contains(AppMode.findObject.shortIntro));
    });

    test('verbositas ringkas memangkas kalimat pembuka', () {
      final out = compose(withIntro: false);
      expect(out, isNot(contains(AppMode.findObject.shortIntro)));
    });
  });

  group('masuk lewat perintah "carikan kacamata"', () {
    const intro = 'Mencari kacamata, tekan tombol kiri bawah '
        'untuk memindai sekitarmu.';

    test('menyebut barang dan tombolnya', () {
      final out = compose(prefix: 'Baik.', introOverride: intro);
      expect(out, contains('kacamata'));
      expect(out, contains('kiri bawah'));
    });

    test('kalimat pembuka bawaan TIDAK ikut terucap', () {
      // Inti perbaikannya. Keduanya bicara tentang hal yang sama dan saling
      // bertentangan: "Mencari kacamata" lalu "Sebutkan barang yang kamu
      // cari" - pengguna baru saja menyebutkannya.
      final out = compose(prefix: 'Baik.', introOverride: intro);
      expect(out, isNot(contains('Sebutkan barang')));
    });

    test('override menang bahkan saat verbositas memangkas panduan', () {
      // Bukan panduan umum yang boleh dilewati sesudah tiga kali pakai -
      // ini keadaan saat ini: barang apa yang dicari, tombol mana yang
      // harus ditekan.
      final out = compose(introOverride: intro, withIntro: false);
      expect(out, contains(intro));
    });

    test('barangnya tidak disebut dua kali', () {
      // Prefiks dari VoiceProvider sengaja cuma "Baik." - targetnya milik
      // `introOverride`, supaya kalimatnya tetap benar walau modenya
      // dimasuki tanpa prefiks sama sekali.
      final out = compose(prefix: 'Baik.', introOverride: intro);
      expect('kacamata'.allMatches(out).length, 1);
    });
  });

  group('mode lain tidak terpengaruh', () {
    test('tanpa override, perilakunya persis seperti sebelumnya', () {
      final out = compose(mode: AppMode.money, prefix: 'Baik.');
      expect(out, 'Baik. ${AppMode.money.label} aktif. '
          '${AppMode.money.shortIntro}');
    });
  });
}
