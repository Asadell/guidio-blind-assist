import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/device_pace_watch.dart';

/// Uji pengawas kecepatan perangkat untuk Mode Navigasi.
///
/// Yang dijaga di sini: ponsel lama tidak boleh diam-diam memberi panduan
/// basi. Urutannya harus ukur, kurangi beban sendiri, baru bicara.
void main() {
  group('A. Ponsel yang mengejar tidak diganggu sama sekali', () {
    test('siklus cepat tidak memicu tindakan apa pun', () {
      final w = DevicePaceWatch();
      for (var i = 0; i < 30; i++) {
        expect(w.record(300), PaceAction.none);
      }
      expect(w.cocoDropped, isFalse);
      expect(w.warned, isFalse);
    });

    test('satu frame lambat sesaat tidak menjatuhkan lapis COCO', () {
      // Aplikasi lain menyalip sebentar bukan alasan menurunkan kualitas
      // panduan untuk sisa perjalanan.
      final w = DevicePaceWatch();
      for (var i = 0; i < 10; i++) {
        w.record(300);
      }
      expect(w.record(3000), PaceAction.none);
      expect(w.cocoDropped, isFalse);
    });
  });

  group('B. Ponsel lambat: kurangi beban sendiri dulu', () {
    test('lambat yang bertahan mematikan lapis COCO, bukan PIDNet atau YOLO', () {
      final w = DevicePaceWatch();
      var action = PaceAction.none;
      for (var i = 0; i < 40 && action != PaceAction.dropCocoLayer; i++) {
        action = w.record(1600);
      }
      expect(action, PaceAction.dropCocoLayer);
      expect(w.cocoDropped, isTrue);
      expect(w.warned, isFalse,
          reason: 'pengguna belum perlu diganggu selama aplikasi masih bisa '
              'memperbaiki dirinya sendiri');
    });

    test('lapis COCO hanya dijatuhkan sekali, tidak berulang', () {
      final w = DevicePaceWatch();
      var drops = 0;
      for (var i = 0; i < 60; i++) {
        if (w.record(1600) == PaceAction.dropCocoLayer) drops++;
      }
      expect(drops, 1);
    });
  });

  group('C. Ponsel sangat lambat: katakan apa adanya', () {
    test('pengguna diberi tahu saat pengurangan beban pun tidak cukup', () {
      final w = DevicePaceWatch();
      final seen = <PaceAction>[];
      for (var i = 0; i < 80; i++) {
        final a = w.record(4000);
        if (a != PaceAction.none) seen.add(a);
      }
      expect(seen, [PaceAction.dropCocoLayer, PaceAction.warnUser],
          reason: 'urutannya wajib: kurangi beban dulu, baru bicara');
    });

    test('peringatan diucapkan sekali saja per sesi', () {
      // Mengulanginya tiap frame justru memakan waktu bicara yang dibutuhkan
      // peringatan bahaya.
      final w = DevicePaceWatch();
      var warns = 0;
      for (var i = 0; i < 200; i++) {
        if (w.record(5000) == PaceAction.warnUser) warns++;
      }
      expect(warns, 1);
    });
  });

  group('D. Sesi baru mulai dari nol', () {
    test('reset mengembalikan lapis COCO dan izin bicara', () {
      final w = DevicePaceWatch();
      for (var i = 0; i < 80; i++) {
        w.record(5000);
      }
      expect(w.cocoDropped, isTrue);
      expect(w.warned, isTrue);

      w.reset();

      expect(w.emaMs, 0);
      expect(w.cocoDropped, isFalse);
      expect(w.warned, isFalse);
    });
  });

  group('E. Masukan tidak masuk akal tidak merusak apa pun', () {
    test('durasi negatif diabaikan', () {
      final w = DevicePaceWatch();
      expect(w.record(-5), PaceAction.none);
      expect(w.emaMs, 0);
    });
  });
}
