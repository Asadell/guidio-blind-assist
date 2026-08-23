import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/models/detection.dart';
import 'package:guidio_app/screens/navigasi_screen.dart';

/// Uji identitas kartu rintangan Mode Navigasi.
///
/// Yang dijaga: dua kartu tidak boleh pernah terlihat kembar di layar. Sejak
/// lapis SSD COCO ditambahkan, satu objek yang sama bisa datang dari dua model
/// dengan `labelEn` berbeda tapi `labelId` sama, dan kalau identitasnya
/// diambil dari `labelEn`, layar menampilkan dua kartu yang huruf demi
/// hurufnya identik.
Detection _det({
  required String labelEn,
  required String labelId,
  required String direction,
  double dist = 2.0,
}) =>
    Detection(
      labelEn: labelEn,
      labelId: labelId,
      confidence: 0.7,
      distanceMeter: dist,
      direction: direction,
      dangerLevel: 'warning',
      bbox: const {'x1': 0, 'y1': 0, 'x2': 10, 'y2': 10},
      inferenceMs: 10,
      frameWidth: 480,
      frameHeight: 640,
    );

void main() {
  group('A. Kembar dari dua model dianggap satu kartu', () {
    test('person dari COCO dan orang dari YOLO custom berbagi identitas', () {
      final coco = _det(labelEn: 'person', labelId: 'orang', direction: 'depan');
      final custom = _det(labelEn: 'orang', labelId: 'orang', direction: 'depan');

      expect(cardIdentity(coco), cardIdentity(custom),
          reason: 'keduanya tampil sebagai "Orang di depan", jadi satu kartu');
    });

    test('motorcycle dan motor berbagi identitas', () {
      expect(
        cardIdentity(_det(labelEn: 'motorcycle', labelId: 'motor', direction: 'kanan')),
        cardIdentity(_det(labelEn: 'motor', labelId: 'motor', direction: 'kanan')),
      );
    });

    test('jarak yang bergoyang tidak mengubah identitas', () {
      // Jarak dihitung dari tinggi kotak dan bergoyang tiap frame. Kalau ia
      // ikut menentukan identitas, objek diam akan dianggap objek baru terus.
      expect(
        cardIdentity(_det(labelEn: 'orang', labelId: 'orang', direction: 'depan', dist: 1.4)),
        cardIdentity(_det(labelEn: 'orang', labelId: 'orang', direction: 'depan', dist: 1.9)),
      );
    });
  });

  group('B. Objek yang benar-benar berbeda tetap dipisah', () {
    test('label sama tapi arah berbeda adalah dua kartu', () {
      expect(
        cardIdentity(_det(labelEn: 'orang', labelId: 'orang', direction: 'kiri')),
        isNot(cardIdentity(_det(labelEn: 'orang', labelId: 'orang', direction: 'kanan'))),
      );
    });

    test('arah sama tapi benda berbeda adalah dua kartu', () {
      expect(
        cardIdentity(_det(labelEn: 'lubang', labelId: 'lubang', direction: 'depan')),
        isNot(cardIdentity(_det(labelEn: 'motor', labelId: 'motor', direction: 'depan'))),
      );
    });
  });

  group('C. Label kosong tidak menabrakkan benda tak sejenis', () {
    test('labelId kosong jatuh ke labelEn, bukan ke string kosong', () {
      // Kalau keduanya jatuh ke '' , dua benda asing akan dianggap satu kartu.
      final a = _det(labelEn: 'bench', labelId: '', direction: 'kanan');
      final b = _det(labelEn: 'chair', labelId: '', direction: 'kanan');
      expect(cardIdentity(a), isNot(cardIdentity(b)));
    });
  });
}
