import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/models/detection.dart';
import 'package:guidio_app/services/nav_obstacle_merger.dart';

/// Uji lapis ketiga Mode Navigasi: SSD MobileNet COCO yang disaring lalu
/// digabung dengan YOLO11n custom.
///
/// Yang dijaga di sini bukan akurasi model, melainkan **aturan penggabungan**:
/// benda yang sama tidak boleh disebut dua kali, benda yang tidak relevan
/// tidak boleh masuk sama sekali, dan benda yang hanya terlihat salah satu
/// model tidak boleh hilang.
Detection _det(
  String labelEn, {
  required double dist,
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  String? labelId,
  String danger = 'warning',
}) =>
    Detection(
      labelEn: labelEn,
      labelId: labelId ?? labelEn,
      confidence: 0.8,
      distanceMeter: dist,
      direction: 'depan',
      dangerLevel: danger,
      bbox: {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
      inferenceMs: 10,
      frameWidth: 480,
      frameHeight: 640,
    );

void main() {
  group('A. Penyaringan kelas COCO', () {
    test('kelas yang menghalangi langkah diloloskan', () {
      final input = [
        _det('person', dist: 2, x1: 0, y1: 0, x2: 10, y2: 10),
        _det('motorcycle', dist: 3, x1: 20, y1: 0, x2: 30, y2: 10),
        _det('bench', dist: 4, x1: 40, y1: 0, x2: 50, y2: 10),
        _det('dog', dist: 5, x1: 60, y1: 0, x2: 70, y2: 10),
      ];
      expect(filterCocoForNavigation(input).length, 4);
    });

    test('benda tak relevan dibuang, tidak pernah jadi ucapan', () {
      // Menyebut "botol" atau "ponsel" saat pengguna sedang menyeberang bukan
      // cuma tidak berguna: ia menunda kalimat yang menyangkut keselamatan.
      final input = [
        _det('bottle', dist: 1, x1: 0, y1: 0, x2: 10, y2: 10),
        _det('cell phone', dist: 1, x1: 0, y1: 0, x2: 10, y2: 10),
        _det('pizza', dist: 1, x1: 0, y1: 0, x2: 10, y2: 10),
        _det('tv', dist: 1, x1: 0, y1: 0, x2: 10, y2: 10),
      ];
      expect(filterCocoForNavigation(input), isEmpty);
    });
  });

  group('B. Penggabungan tanpa sebutan ganda', () {
    test('orang yang terlihat KEDUA model hanya disebut sekali', () {
      final custom = [_det('orang', dist: 2.0, x1: 100, y1: 100, x2: 200, y2: 400)];
      final coco = [_det('person', dist: 2.2, x1: 105, y1: 110, x2: 205, y2: 395)];

      final merged = mergeNavObstacles(custom, coco);

      expect(merged.length, 1);
      expect(merged.first.labelEn, 'orang',
          reason: 'hasil model custom yang dipertahankan, supaya angka jarak '
              'tidak melompat antar frame untuk benda yang sama');
    });

    test('motor yang terlihat KEDUA model hanya disebut sekali', () {
      final custom = [_det('motor', dist: 3.0, x1: 50, y1: 200, x2: 250, y2: 420)];
      final coco = [_det('motorcycle', dist: 3.1, x1: 55, y1: 205, x2: 245, y2: 415)];

      expect(mergeNavObstacles(custom, coco).length, 1);
    });

    test('rambu COCO dianggap kembar dengan tiang custom saat bertindih', () {
      final custom = [_det('tiang', dist: 4.0, x1: 300, y1: 50, x2: 340, y2: 500)];
      final coco = [_det('stop sign', dist: 4.2, x1: 302, y1: 55, x2: 338, y2: 495)];

      expect(mergeNavObstacles(custom, coco).length, 1);
    });
  });

  group('C. Menutup lubang yang tidak terlihat model custom', () {
    test('orang dan motor yang TERLEWAT model custom tetap sampai ke pengguna', () {
      // Inilah kasus yang menjadi alasan lapisan ini ada. Diuji lewat
      // `test/run_corridor_test.py` pada fixture `04_motor_dan_orang.png`,
      // model custom melaporkan nol motor dan nol orang padahal dua motor
      // terparkir dan satu orang berjalan di frame yang sama.
      final custom = <Detection>[];
      final coco = [
        _det('person', dist: 2.5, x1: 200, y1: 100, x2: 260, y2: 400),
        _det('motorcycle', dist: 1.8, x1: 50, y1: 250, x2: 300, y2: 450),
      ];

      final merged = mergeNavObstacles(custom, coco);

      expect(merged.length, 2);
      expect(merged.map((d) => d.labelEn), containsAll(['person', 'motorcycle']));
    });

    test('urutan hasil dari yang TERDEKAT, karena itu yang diucapkan lebih dulu', () {
      final custom = [_det('lubang', dist: 4.0, x1: 0, y1: 0, x2: 20, y2: 20)];
      final coco = [_det('person', dist: 1.2, x1: 300, y1: 0, x2: 340, y2: 300)];

      final merged = mergeNavObstacles(custom, coco);

      expect(merged.first.distanceMeter, 1.2);
    });
  });

  group('D. Bahaya berbeda di tempat yang sama tetap dua-duanya', () {
    test('motor terparkir di atas got terbuka disebut sebagai dua bahaya', () {
      // Kotaknya bertindih penuh, tapi kelasnya tidak berpadanan. Menggabung
      // keduanya akan menghapus salah satu bahaya nyata dari telinga pengguna.
      final custom = [_det('got_terbuka', dist: 1.0, x1: 100, y1: 300, x2: 300, y2: 450)];
      final coco = [_det('motorcycle', dist: 1.1, x1: 100, y1: 300, x2: 300, y2: 450)];

      final merged = mergeNavObstacles(custom, coco);

      expect(merged.length, 2);
    });
  });

  group('E. Jalur aman saat lapisan COCO kosong atau mati', () {
    test('COCO kosong mengembalikan hasil custom apa adanya', () {
      final custom = [_det('lubang', dist: 1.0, x1: 0, y1: 0, x2: 20, y2: 20)];
      expect(mergeNavObstacles(custom, const []), equals(custom));
    });

    test('keduanya kosong menghasilkan daftar kosong, bukan error', () {
      expect(mergeNavObstacles(const [], const []), isEmpty);
    });
  });
}
