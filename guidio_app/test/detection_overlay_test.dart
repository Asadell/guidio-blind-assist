import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/models/detection.dart';
import 'package:guidio_app/widgets/camera_stage.dart';
import 'package:guidio_app/widgets/detection_overlay.dart';
import 'package:guidio_app/widgets/segmentation_overlay.dart';

/// Tes untuk lapisan yang menggambar hasil deteksi di atas preview kamera.
///
/// Yang diuji di sini bukan "apakah kotaknya cantik", tapi apakah kotaknya
/// jatuh DI TEMPAT YANG BENAR. Kesalahan pemetaan koordinat tidak pernah
/// melempar error: kotaknya tetap muncul, tetap berwarna, tetap berlabel -
/// hanya menempel pada bagian layar yang salah. Satu-satunya cara menangkap
/// itu tanpa perangkat sungguhan adalah menghitungnya di sini.

Detection _det({
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  int? frameWidth,
  int? frameHeight,
  String danger = 'warning',
  double meter = 3.0,
}) =>
    Detection(
      labelEn: 'lubang',
      labelId: 'lubang',
      confidence: 0.9,
      distanceMeter: meter,
      direction: 'depan',
      dangerLevel: danger,
      bbox: {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2},
      inferenceMs: 10,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );

void main() {
  group('Detection.normalizedBox', () {
    test('membagi koordinat piksel dengan ukuran bingkai tegak', () {
      final d = _det(
        x1: 120, y1: 160, x2: 360, y2: 480,
        frameWidth: 480, frameHeight: 640,
      );
      final n = d.normalizedBox!;
      expect(n.left, closeTo(0.25, 1e-9));
      expect(n.top, closeTo(0.25, 1e-9));
      expect(n.right, closeTo(0.75, 1e-9));
      expect(n.bottom, closeTo(0.75, 1e-9));
    });

    test('null kalau ukuran bingkai tidak dilaporkan', () {
      // Deteksi dari server tidak membawa ukuran bingkai. Menebaknya berarti
      // menggambar kotak di tempat yang salah, dan kotak yang salah lebih
      // menyesatkan daripada tidak ada kotak sama sekali.
      expect(_det(x1: 10, y1: 10, x2: 50, y2: 50).normalizedBox, isNull);
      expect(
        _det(x1: 10, y1: 10, x2: 50, y2: 50, frameWidth: 480).normalizedBox,
        isNull,
        reason: 'lebar saja tanpa tinggi tetap tidak cukup',
      );
    });

    test('menolak ukuran bingkai nol alih-alih membagi nol', () {
      final d = _det(
        x1: 0, y1: 0, x2: 10, y2: 10,
        frameWidth: 0, frameHeight: 0,
      );
      expect(d.normalizedBox, isNull);
    });

    test('membetulkan koordinat yang terbalik', () {
      // x2 < x1 menghasilkan persegi dengan lebar negatif, yang digambar
      // sebagai apa pun kecuali kotak yang dimaksud.
      final d = _det(
        x1: 360, y1: 480, x2: 120, y2: 160,
        frameWidth: 480, frameHeight: 640,
      );
      final n = d.normalizedBox!;
      expect(n.left, lessThan(n.right));
      expect(n.top, lessThan(n.bottom));
      expect(n.left, closeTo(0.25, 1e-9));
      expect(n.bottom, closeTo(0.75, 1e-9));
    });

    test('mengurung koordinat yang melewati tepi bingkai', () {
      final d = _det(
        x1: -40, y1: -40, x2: 999, y2: 999,
        frameWidth: 480, frameHeight: 640,
      );
      final n = d.normalizedBox!;
      expect(n.left, 0.0);
      expect(n.top, 0.0);
      expect(n.right, 1.0);
      expect(n.bottom, 1.0);
    });

    test('copyWith mempertahankan ukuran bingkai', () {
      // DetectionProvider memanggil copyWith untuk menempelkan trackId dan
      // jarak yang dihaluskan. Kalau ukuran bingkai hilang di situ, seluruh
      // kotak berhenti tergambar tepat setelah tracker menyentuhnya -
      // gejalanya "kotaknya hilang sendiri" tanpa satu pun error.
      final d = _det(
        x1: 10, y1: 20, x2: 30, y2: 40,
        frameWidth: 480, frameHeight: 640,
      ).copyWith(trackId: 7, distanceMeter: 1.5);
      expect(d.frameWidth, 480);
      expect(d.frameHeight, 640);
      expect(d.normalizedBox, isNotNull);
    });
  });

  group('DetectionOverlay', () {
    testWidgets('tidak menggambar apa-apa saat daftar kosong', (tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: DetectionOverlay(detections: []),
      ));
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('melewati deteksi yang tidak tahu ukuran bingkainya',
        (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: DetectionOverlay(
          detections: [_det(x1: 1, y1: 1, x2: 9, y2: 9)],
        ),
      ));
      expect(find.byType(CustomPaint), findsNothing,
          reason: 'lebih baik kosong daripada kotak di posisi tebakan');
    });

    testWidgets('menggambar saat ada deteksi yang layak', (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 400,
          child: DetectionOverlay(
            detections: [
              _det(
                x1: 100, y1: 100, x2: 200, y2: 300,
                frameWidth: 480, frameHeight: 640,
                danger: 'critical',
              ),
            ],
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('tidak jatuh saat menggambar banyak deteksi sekaligus',
        (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 400,
          child: DetectionOverlay(
            detections: [
              for (var i = 0; i < 12; i++)
                _det(
                  x1: i * 30, y1: i * 40, x2: i * 30 + 60, y2: i * 40 + 80,
                  frameWidth: 480, frameHeight: 640,
                  danger: i.isEven ? 'critical' : 'info',
                  meter: 0.5 + i,
                ),
            ],
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('kotak mepet tepi atas tetap tergambar', (tester) async {
      // Label ditaruh di atas kotak; untuk kotak yang menempel di tepi atas
      // label itu akan keluar layar dan terpotong habis kalau tidak
      // dipindahkan ke dalam kotak.
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 400,
          child: DetectionOverlay(
            detections: [
              _det(
                x1: 0, y1: 0, x2: 470, y2: 20,
                frameWidth: 480, frameHeight: 640,
              ),
            ],
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CameraStage.uprightAspectOf', () {
    // Satu angka ini yang menentukan apakah kotak jatuh di tempat yang benar.
    // Kalau salah, hamparan memetakan koordinatnya ke persegi yang berbeda
    // dari gambar kameranya - dan setiap kotak meleset tanpa satu pun error.
    test('membalik rasio sensor lanskap jadi potret', () {
      expect(CameraStage.uprightAspectOf(4 / 3), closeTo(3 / 4, 1e-9));
      expect(CameraStage.uprightAspectOf(16 / 9), closeTo(9 / 16, 1e-9));
    });

    test('membiarkan rasio yang sudah potret', () {
      expect(CameraStage.uprightAspectOf(3 / 4), closeTo(3 / 4, 1e-9));
    });

    test('jatuh ke 3:4 untuk nilai tidak masuk akal', () {
      // Controller yang belum siap bisa melaporkan 0. Membaginya menghasilkan
      // infinity, dan AspectRatio dengan infinity melempar saat layout.
      expect(CameraStage.uprightAspectOf(0), closeTo(3 / 4, 1e-9));
      expect(CameraStage.uprightAspectOf(-1), closeTo(3 / 4, 1e-9));
      expect(CameraStage.uprightAspectOf(double.nan), closeTo(3 / 4, 1e-9));
      expect(CameraStage.uprightAspectOf(double.infinity), closeTo(3 / 4, 1e-9));
    });
  });

  group('maskToImage', () {
    test('menghasilkan gambar seukuran mask', () async {
      final mask = Uint8List.fromList([0, 1, 2, 1, 0, 2]);
      final img = await maskToImage(mask, 3, 2);
      expect(img.width, 3);
      expect(img.height, 2);
      img.dispose();
    });

    test('walkable terlihat, non-walkable tembus pandang', () async {
      // Kelas 0 sengaja transparan penuh supaya yang menonjol hanya jalurnya.
      // Kalau ini bocor jadi berwarna, seluruh layar tertutup kabut dan
      // hamparan yang harusnya menjelaskan justru menyembunyikan.
      final img = await maskToImage(Uint8List.fromList([0, 1, 2]), 3, 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = data!.buffer.asUint8List();

      expect(px[3], 0, reason: 'non-walkable harus alfa 0');
      expect(px[7], greaterThan(0), reason: 'walkable harus terlihat');
      expect(px[11], greaterThan(0), reason: 'hazard harus terlihat');
      expect(px[11], greaterThan(px[7]),
          reason: 'hazard harus lebih pekat daripada jalur biasa');
      img.dispose();
    });

    test('nilai kelas di luar jangkauan tidak menjatuhkan konversi', () async {
      // Mask datang dari argmax, jadi seharusnya selalu 0..2. "Seharusnya"
      // bukan jaminan, dan konversi yang melempar di sini akan mematikan
      // hamparan pada mode yang menyangkut keselamatan.
      final img = await maskToImage(Uint8List.fromList([9, 1, 200]), 3, 1);
      expect(img.width, 3);
      img.dispose();
    });
  });
}
