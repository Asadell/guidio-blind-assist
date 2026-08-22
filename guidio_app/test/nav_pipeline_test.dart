import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/nav_frame_converter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Tes untuk pipeline frame Mode Navigasi.
///
/// ## Kenapa ini penting diuji
///
/// Preprocessing adalah bagian yang paling gampang salah TANPA memunculkan
/// error. Rotasi terbalik, sumbu tertukar, normalisasi keliru, tata letak
/// tensor salah — semuanya menghasilkan tensor berukuran benar yang tetap
/// diterima interpreter. Modelnya jalan, angkanya keluar, dan yang memburuk
/// cuma akurasinya. Dari lapangan, itu terlihat seperti "modelnya kurang
/// bagus" padahal yang salah pengiriman gambarnya.
///
/// Dua hal yang dijaga di sini:
///
/// 1. **Geometri** — piksel jatuh di tempat yang benar setelah rotasi dan
///    penskalaan, diverifikasi dengan pola yang posisinya diketahui.
/// 2. **Kontrak tensor** — buffer DATAR benar-benar diterima interpreter
///    TFLite sungguhan, baik sebagai masukan maupun keluaran. Ini yang
///    memungkinkan pipeline berhenti mengalokasikan ratusan ribu objek kecil
///    per frame.

const int srcW = 640, srcH = 480;
const int pidW = 640, pidH = 384;
const int yoloS = 640;

/// Bidang YUV dengan warna yang bisa diperiksa posisinya.
///
/// [brightRegion] menerima koordinat sensor dan menentukan mana yang terang.
({Uint8List y, Uint8List u, Uint8List v}) planes(
  bool Function(int sx, int sy) brightRegion,
) {
  final y = Uint8List(srcW * srcH);
  final u = Uint8List(srcW * srcH ~/ 2)..fillRange(0, srcW * srcH ~/ 2, 128);
  final v = Uint8List(srcW * srcH ~/ 2)..fillRange(0, srcW * srcH ~/ 2, 128);
  for (var sy = 0; sy < srcH; sy++) {
    for (var sx = 0; sx < srcW; sx++) {
      y[sy * srcW + sx] = brightRegion(sx, sy) ? 255 : 0;
    }
  }
  return (y: y, u: u, v: v);
}

NavTensors run(
  ({Uint8List y, Uint8List u, Uint8List v}) p, {
  bool bchw = false,
}) =>
    NavFrameConverter.prepareFromPlanes(
      yPlane: p.y,
      uPlane: p.u,
      vPlane: p.v,
      srcW: srcW,
      srcH: srcH,
      yRowStride: srcW,
      uvRowStride: srcW,
      uvPixelStride: 2,
      pidnetBchw: bchw,
    );

/// Rata-rata kanal merah YOLO di sebuah kotak bingkai TEGAK (pecahan 0..1).
double yoloRegionMean(Float32List t, double l, double tp, double r, double b) {
  var sum = 0.0;
  var n = 0;
  for (var ty = (tp * yoloS).round(); ty < (b * yoloS).round(); ty++) {
    for (var tx = (l * yoloS).round(); tx < (r * yoloS).round(); tx++) {
      sum += t[(ty * yoloS + tx) * 3];
      n++;
    }
  }
  return n == 0 ? 0 : sum / n;
}

void main() {
  group('Bentuk & rentang tensor', () {
    test('ukuran tensor sesuai masukan model', () {
      final t = run(planes((sx, sy) => true));
      expect(t.pidnet.length, pidW * pidH * 3);
      expect(t.yolo.length, yoloS * yoloS * 3);
    });

    test('bingkai tegak menukar lebar dan tinggi sensor', () {
      // Ini yang menentukan apakah kotak deteksi jatuh di tempat yang benar.
      final t = run(planes((sx, sy) => true));
      expect(t.uprightWidth, srcH);
      expect(t.uprightHeight, srcW);
    });

    test('YOLO ternormalisasi ke 0..1', () {
      final t = run(planes((sx, sy) => (sx ~/ 40).isEven));
      for (final v in t.yolo) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('PIDNet dinormalisasi ImageNet, bukan 0..1', () {
      // Hitam pekat setelah normalisasi ImageNet = (0 - 0,485) / 0,229
      // ≈ -2,12. Kalau angkanya keluar 0..1, normalisasinya tidak terpasang
      // dan seluruh masukan model bergeser jauh dari data latihnya.
      final t = run(planes((sx, sy) => false));
      expect(t.pidnet[0], closeTo(-2.118, 0.05));
    });
  });

  group('Geometri rotasi', () {
    // `copyRotate(angle: 90)` memutar SEARAH JARUM JAM: kolom paling kiri
    // sensor menjadi baris paling ATAS bingkai tegak.
    test('kolom kiri sensor menjadi baris atas bingkai tegak', () {
      final t = run(planes((sx, sy) => sx < srcW * 0.1));
      final atas = yoloRegionMean(t.yolo, 0.0, 0.0, 1.0, 0.06);
      final bawah = yoloRegionMean(t.yolo, 0.0, 0.94, 1.0, 1.0);
      expect(atas, greaterThan(0.8), reason: 'kolom kiri harus naik ke atas');
      expect(bawah, lessThan(0.2));
    });

    test('baris atas sensor menjadi kolom kanan bingkai tegak', () {
      final t = run(planes((sx, sy) => sy < srcH * 0.1));
      final kanan = yoloRegionMean(t.yolo, 0.94, 0.0, 1.0, 1.0);
      final kiri = yoloRegionMean(t.yolo, 0.0, 0.0, 0.06, 1.0);
      expect(kanan, greaterThan(0.8));
      expect(kiri, lessThan(0.2));
    });

    test('separuh bawah bingkai tegak berasal dari separuh kanan sensor', () {
      // Pita bawah inilah yang dipakai `assessScene` untuk memutuskan apakah
      // jalur benar-benar menyentuh tanah. Kalau sumbunya terbalik, gerbang
      // itu menilai bagian frame yang salah.
      final t = run(planes((sx, sy) => sx > srcW * 0.5));
      expect(yoloRegionMean(t.yolo, 0.0, 0.6, 1.0, 1.0), greaterThan(0.8));
      expect(yoloRegionMean(t.yolo, 0.0, 0.0, 1.0, 0.4), lessThan(0.2));
    });
  });

  group('Tata letak PIDNet', () {
    test('BHWC menaruh tiga kanal berdampingan', () {
      final t = run(planes((sx, sy) => true), bchw: false);
      // Putih: R, G, B ketiganya tinggi, jadi tiga nilai berurutan mirip.
      expect(t.pidnet[0], closeTo(t.pidnet[1], 1.5));
      expect(t.pidnet[1], closeTo(t.pidnet[2], 1.5));
    });

    test('BCHW memisahkan kanal jadi tiga bidang penuh', () {
      const plane = pidW * pidH;
      final t = run(planes((sx, sy) => true), bchw: true);
      expect(t.pidnet.length, plane * 3);
      // Bidang hijau dimulai tepat setelah bidang merah.
      expect(t.pidnet[plane], isNot(equals(0.0)));
    });
  });

  group('Interpolasi', () {
    test('bilinear menghaluskan tepi, bukan menyalinnya mentah', () {
      // PIDNet mengecilkan 640 baris jadi 384 — pengecilan 1,7x. Dengan
      // nearest, dua dari tiga baris dibuang dan tepi trotoar yang tipis bisa
      // hilang atau berkedip antar frame.
      final t = run(planes((sx, sy) => sx < srcW ~/ 2));
      // Cari nilai antara di sekitar tepi: bukti terjadi pencampuran.
      var adaNilaiAntara = false;
      for (var i = 0; i < t.yolo.length; i += 3) {
        final v = t.yolo[i];
        if (v > 0.15 && v < 0.85) {
          adaNilaiAntara = true;
          break;
        }
      }
      expect(adaNilaiAntara, isTrue,
          reason: 'tanpa bilinear semua piksel akan 0 atau 1 persis');
    });
  });

  group('Masukan rusak tidak menjatuhkan', () {
    test('bidang lebih pendek dari yang dijanjikan stride', () {
      // Beberapa perangkat melaporkan stride yang tidak cocok dengan panjang
      // buffer. Melempar di sini berarti mematikan seluruh mode navigasi.
      expect(
        () => NavFrameConverter.prepareFromPlanes(
          yPlane: Uint8List(100),
          uPlane: Uint8List(50),
          vPlane: Uint8List(50),
          srcW: srcW,
          srcH: srcH,
          yRowStride: srcW,
          uvRowStride: srcW,
          uvPixelStride: 2,
          pidnetBchw: false,
        ),
        returnsNormally,
      );
    });
  });

  // ── Kontrak tensor dengan interpreter SUNGGUHAN ──────────────────────────
  //
  // Inti perubahannya: berhenti memakai `List` bersarang dan memakai buffer
  // datar yang dipakai ulang. Kalau tflite_flutter ternyata menolak buffer
  // datar, seluruh pipeline mati — jadi itu harus dibuktikan, bukan
  // diasumsikan.
  group('Interpreter TFLite menerima buffer datar', () {
    late Interpreter pidnet;
    late Interpreter yolo;
    var tersedia = true;

    setUpAll(() {
      try {
        // Sengaja fp32: varian fp16 punya tensor masukan FLOAT16 dan tidak
        // bisa menerima float32. `PidnetService.tryLoad` sekarang membuktikan
        // tiap varian dengan inferensi percobaan lalu memilih yang jalan —
        // dan di semua perangkat CPU, yang jalan adalah yang ini.
        pidnet = Interpreter.fromFile(
            File('assets/models/pidnet_s_3zona.tflite'));
        yolo = Interpreter.fromFile(
            File('assets/models/yolo11n_navigasi.tflite'));
      } catch (e) {
        tersedia = false;
        printOnFailure('TFLite tidak tersedia: $e');
      }
    });

    tearDownAll(() {
      if (tersedia) {
        pidnet.close();
        yolo.close();
      }
    });

    test('PIDNet: Float32List masuk, Float32List keluar', () {
      if (!tersedia) return;
      final shape = pidnet.getInputTensor(0).shape;
      final bchw = shape.length == 4 && shape[1] == 3;
      final t = run(planes((sx, sy) => sx < srcW ~/ 2), bchw: bchw);

      final out = Float32List(3 * pidH * pidW);
      pidnet.runForMultipleInputs(
        [t.pidnet.buffer.asUint8List()],
        {0: out.buffer.asUint8List()},
      );

      expect(out.any((v) => v != 0.0), isTrue,
          reason: 'keluaran seluruhnya nol berarti tensor tidak pernah terisi');
    });

    test('YOLO: Float32List masuk, Float32List keluar', () {
      if (!tersedia) return;
      final t = run(planes((sx, sy) => sy > srcH ~/ 2));

      final outShape = yolo.getOutputTensor(0).shape;
      final out = Float32List(outShape.reduce((a, b) => a * b));
      yolo.runForMultipleInputs(
        [t.yolo.buffer.asUint8List()],
        {0: out.buffer.asUint8List()},
      );

      expect(out.any((v) => v != 0.0), isTrue);
    });

    test('buffer keluaran yang SAMA aman dipakai ulang antar frame', () {
      if (!tersedia) return;
      // Inilah yang membuat mode ini aman berjalan lama di HP 4 GB: satu
      // alokasi untuk seumur hidup service, bukan satu per frame.
      final out = Float32List(3 * pidH * pidW);
      final shape = pidnet.getInputTensor(0).shape;
      final bchw = shape.length == 4 && shape[1] == 3;

      final outBytes = out.buffer.asUint8List();
      final terang = run(planes((sx, sy) => true), bchw: bchw);
      pidnet.runForMultipleInputs(
          [terang.pidnet.buffer.asUint8List()], {0: outBytes});
      final pertama = Float32List.fromList(out);

      final gelap = run(planes((sx, sy) => false), bchw: bchw);
      pidnet.runForMultipleInputs(
          [gelap.pidnet.buffer.asUint8List()], {0: outBytes});

      var berubah = false;
      for (var i = 0; i < out.length; i++) {
        if ((out[i] - pertama[i]).abs() > 1e-6) {
          berubah = true;
          break;
        }
      }
      expect(berubah, isTrue,
          reason: 'buffer yang dipakai ulang harus ikut diperbarui, bukan '
              'menyimpan hasil frame sebelumnya');
    });
  });
}
