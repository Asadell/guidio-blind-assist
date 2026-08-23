import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/providers/voice_provider.dart';

/// Uji pemilihan bahasa untuk pengenalan suara.
///
/// Aturannya satu dan tidak boleh dilanggar: **Bahasa Indonesia adalah
/// bawaan.** Kalau daftar perangkat tidak bisa dibaca atau tidak memuat satu
/// pun varian Indonesia, pemanggil tetap memakai `kDefaultSttLocale`, bukan
/// menyerahkan pilihan ke bawaan perangkat.
///
/// Ini pernah jadi regresi nyata: pemilihnya nullable, `listen(localeId: null)`
/// jatuh ke bawaan perangkat yang di kebanyakan ponsel adalah Inggris, dan
/// pengguna yang bicara Bahasa Indonesia mendapat kata acak yang tidak pernah
/// cocok dengan satu pun frasa CommandParser.
List<({String id, String name})> _locales(List<String> ids) =>
    [for (final id in ids) (id: id, name: id)];

void main() {
  group('A. Varian Indonesia dikenali apa pun penulisannya', () {
    test('id_ID dengan garis bawah', () {
      expect(pickIndonesianLocale(_locales(['en_US', 'id_ID'])), 'id_ID');
    });

    test('id-ID dengan tanda hubung', () {
      expect(pickIndonesianLocale(_locales(['en-US', 'id-ID'])), 'id-ID');
    });

    test('in_ID, kode lama Android untuk Bahasa Indonesia', () {
      // Android masih memakai `in`, warisan ISO 639 sebelum 1989.
      expect(pickIndonesianLocale(_locales(['en_US', 'in_ID'])), 'in_ID');
    });

    test('dikenali dari nama walau kodenya tak terduga', () {
      expect(
        pickIndonesianLocale([
          (id: 'en_US', name: 'English (United States)'),
          (id: 'xx_YY', name: 'Bahasa Indonesia'),
        ]),
        'xx_YY',
      );
    });
  });

  group('B. Varian berkode negara didahulukan', () {
    test('id_ID menang atas id polos', () {
      expect(pickIndonesianLocale(_locales(['id', 'id_ID'])), 'id_ID');
    });
  });

  group('C. Tidak pernah salah pilih bahasa lain', () {
    test('daftar tanpa Indonesia mengembalikan null, bukan menebak', () {
      // Null adalah sinyal agar pemanggil memakai kDefaultSttLocale.
      // Mengembalikan 'en_US' di sini akan membuat mesin mendengarkan Inggris.
      expect(
        pickIndonesianLocale(_locales(['en_US', 'ja_JP', 'ko_KR'])),
        isNull,
      );
    });

    test('daftar kosong mengembalikan null', () {
      expect(pickIndonesianLocale(const []), isNull);
    });

    test('kode yang kebetulan berawalan id tidak ikut tertangkap', () {
      // `startsWith('id')` telanjang akan menangkap ini. Memilih bahasa yang
      // salah jauh lebih buruk daripada gagal memilih.
      expect(pickIndonesianLocale(_locales(['ido_XX', 'ida_YY'])), isNull);
    });
  });

  group('D. Bawaan tetap Bahasa Indonesia', () {
    test('kDefaultSttLocale adalah varian Indonesia', () {
      expect(kDefaultSttLocale, 'id_ID');
    });
  });
}
