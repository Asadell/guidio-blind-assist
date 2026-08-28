/// Penyaringan frasa benda sebelum berangkat ke penerjemah dan YOLOE.
///
/// Yang dijaga di sini satu hal: **hanya nama barangnya yang boleh lewat.**
///
/// Encoder teks YOLOE mencocokkan SELURUH frasa prompt dengan isi gambar,
/// bukan kata kuncinya saja. Jadi setiap kata yang lolos - "tolong", "yang",
/// "di meja" - bukan sekadar bising: ia mempersempit pencarian ke sesuatu
/// yang harus serentak cocok dengan semuanya, dan tas yang sebenarnya ada di
/// depan pengguna dilaporkan tidak ketemu.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/command_parser.dart';

void main() {
  String f(String s) => CommandParser.normalizeSearchPhrase(s);

  group('kata pembuka dibuang', () {
    test('bentuk baku', () {
      expect(f('cari tas merah'), 'tas merah');
      expect(f('tolong carikan tas merah'), 'tas merah');
      expect(f('temukan dompet'), 'dompet');
    });

    test('bentuk sehari-hari dan slang', () {
      expect(f('cariin dong dompet saya'), 'dompet');
      expect(f('eh cariin gue kunci motor'), 'kunci motor');
      expect(f('saya kehilangan kacamata hitam'), 'kacamata hitam');
    });

    test('kata pembuka ganti barang', () {
      expect(f('ganti barang jadi keyboard'), 'keyboard');
    });

    test('ucapan koreksi tidak menyisakan "bukan"', () {
      // Menghapus kata pembuka di tempat akan menyisakan "bukan itu
      // keyboard", dan "bukan" jadi "not" di prompt YOLOE.
      expect(f('bukan itu, cariin keyboard'), 'keyboard');
    });
  });

  group('derau frasa benda', () {
    test('kata "warna" dibuang, warnanya dipertahankan', () {
      // "warna" jadi kata benda "color" di Inggris, dan itu menggeser arti
      // frasanya dari "botol yang biru" jadi "warna botol".
      expect(f('tolong cariin botol minum warna biru dong'),
          'botol minum biru');
    });

    test('kepemilikan dan penegas dibuang', () {
      expect(f('laptop punya saya yang warna abu-abu'), 'laptop abu-abu');
    });
  });

  group('keterangan tempat dan waktu dipotong', () {
    test('potong di preposisi tempat', () {
      expect(f('tas merah di atas meja tadi'), 'tas merah');
    });

    test('potong di kata kerja penyimpanan', () {
      expect(f('cari kunci yang saya taruh di dekat pintu tadi pagi'), 'kunci');
    });

    test('keterangan tempat tanpa nama barang tidak dikirim', () {
      expect(f('cari di meja'), '');
    });
  });

  group('tidak ada benda yang disebut', () {
    test('kata penunjuk kosong', () {
      expect(f('cariin dong barangnya'), '');
      expect(f('ganti barang'), '');
      expect(f(''), '');
      expect(f('   '), '');
    });
  });

  group('frasa yang sudah bersih tidak dirusak', () {
    test('idempoten', () {
      // Target bisa datang dari tiga jalur, dan hanya dua yang sudah lewat
      // pengupas kata pembuka. Filter ini harus aman dijalankan dua kali.
      for (final s in ['tas merah', 'termos', 'hp', 'kunci motor']) {
        expect(f(s), s);
        expect(f(f(s)), s);
      }
    });
  });

  group('panjang dibatasi', () {
    test('maksimal empat kata', () {
      final out = f('botol minum plastik biru kecil bening bermerek');
      expect(out.split(' ').length, lessThanOrEqualTo(4));
    });
  });
}
