import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/luma_contrast.dart';

/// Uji perbaikan kontras selektif untuk kamera ponsel berumur.
///
/// Yang dijaga di sini bukan "apakah gambarnya jadi bagus", melainkan
/// **gerbangnya**: frame yang sudah sehat tidak boleh disentuh sama sekali.
/// Riset yang mendasarinya menunjukkan enhancement tanpa syarat justru
/// menurunkan akurasi pada citra jernih, jadi gerbang inilah fiturnya.

/// Bidang luma buatan dengan rentang nilai [lo]..[hi] tersebar merata.
Uint8List _plane({required int lo, required int hi, int n = 8192}) {
  final out = Uint8List(n);
  final span = hi - lo;
  for (var i = 0; i < n; i++) {
    out[i] = (lo + (span * i / (n - 1)).round()).clamp(0, 255);
  }
  return out;
}

void main() {
  group('A. Gerbang: frame sehat tidak disentuh', () {
    test('rentang lebar khas kamera sehat dilewatkan', () {
      // Terukur pada fixture kamera bagus di repo ini: p2 = 9, p98 = 231.
      expect(measureLumaStretch(_plane(lo: 5, hi: 250)), isNull);
    });

    test('tepat di ambang tetap dilewatkan', () {
      expect(measureLumaStretch(_plane(lo: 20, hi: 240)), isNull);
    });
  });

  group('B. Frame berkabut khas kamera lama diperbaiki', () {
    test('titik hitam terangkat memicu peregangan', () {
      // Terukur pada foto Samsung A30s: p2 = 50, p98 = 212, rentang 162.
      final st = measureLumaStretch(_plane(lo: 50, hi: 212));
      expect(st, isNotNull);
      expect(st!.lo, greaterThan(40));
      expect(st.gain, greaterThan(1.0),
          reason: 'peregangan harus melebarkan, bukan menyempitkan');
    });

    test('pemetaan mengembalikan hitam ke nol dan putih ke sekitar 255', () {
      final st = measureLumaStretch(_plane(lo: 50, hi: 212))!;
      final black = (50 - st.lo) * st.gain;
      final white = (212 - st.lo) * st.gain;
      expect(black, closeTo(0, 12));
      expect(white, closeTo(255, 25));
    });
  });

  group('C. Kondisi ekstrem tidak diperbesar jadi derau', () {
    test('frame nyaris rata (lensa tertutup) tidak diregangkan', () {
      // Mengalikan derau dengan faktor besar cuma menghasilkan derau besar.
      // Kondisi ini sudah ditangani penjaga gelap di CameraProvider.
      expect(measureLumaStretch(_plane(lo: 100, hi: 110)), isNull);
    });

    test('bidang kosong atau terlalu kecil dikembalikan null, bukan error', () {
      expect(measureLumaStretch(Uint8List(0)), isNull);
      expect(measureLumaStretch(Uint8List(10)), isNull);
    });

    test('seluruh frame satu nilai tidak menghasilkan pembagian nol', () {
      final flat = Uint8List(4096)..fillRange(0, 4096, 128);
      expect(measureLumaStretch(flat), isNull);
    });
  });
}
