import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/nav_frame_converter.dart';
import 'package:image/image.dart' as img;

/// Benchmark pipeline frame Mode Navigasi, sekaligus penjaga regresi.
///
/// Angka absolutnya tidak berarti banyak - mesin ini bukan HP target. Yang
/// dijaga adalah PERBANDINGANNYA: jalur satu-lintasan harus tetap jauh lebih
/// murah daripada jalur lama yang membangun gambar antara dan `List`
/// bersarang. Kalau seseorang mengembalikan pola lama, tes ini merah sebelum
/// sempat sampai ke pengguna.
///
/// Jalankan sendiri untuk melihat angkanya:
///   flutter test test/nav_pipeline_bench_test.dart --reporter expanded


const srcW = 640, srcH = 480;
const pidW = 640, pidH = 384;
const yoloS = 640;
const mean = [0.485, 0.456, 0.406];
const std = [0.229, 0.224, 0.225];

late Uint8List yPlane, uPlane, vPlane;

void setup() {
  yPlane = Uint8List(srcW * srcH);
  uPlane = Uint8List(srcW * srcH ~/ 2);
  vPlane = Uint8List(srcW * srcH ~/ 2);
  for (var i = 0; i < yPlane.length; i++) {
    yPlane[i] = (i * 7) & 0xFF;
  }
  for (var i = 0; i < uPlane.length; i++) {
    uPlane[i] = (i * 3) & 0xFF;
    vPlane[i] = (i * 5) & 0xFF;
  }
}

// ── JALUR SEKARANG ────────────────────────────────────────────────────────
Uint8List yuvToRgb() {
  final rgb = Uint8List(srcW * srcH * 3);
  var idx = 0;
  for (var y = 0; y < srcH; y++) {
    for (var x = 0; x < srcW; x++) {
      final yIdx = y * srcW + x;
      final uvIdx = (y ~/ 2) * srcW + (x ~/ 2) * 2;
      final yVal = yPlane[yIdx] & 0xFF;
      final uVal = (uvIdx < uPlane.length ? uPlane[uvIdx] : 128) & 0xFF;
      final vVal = (uvIdx < vPlane.length ? vPlane[uvIdx] : 128) & 0xFF;
      rgb[idx++] = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
      rgb[idx++] = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
      rgb[idx++] = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);
    }
  }
  return rgb;
}

List currentPidnet(Uint8List rgb) {
  final raw = img.Image.fromBytes(
      width: srcW, height: srcH, bytes: rgb.buffer,
      format: img.Format.uint8, numChannels: 3);
  final rot = img.copyRotate(raw, angle: 90);
  final rs = img.copyResize(rot, width: pidW, height: pidH,
      interpolation: img.Interpolation.linear);
  return List.generate(1, (_) =>
      List.generate(pidH, (y) =>
          List.generate(pidW, (x) {
            final p = rs.getPixel(x, y);
            return [
              (p.r / 255.0 - mean[0]) / std[0],
              (p.g / 255.0 - mean[1]) / std[1],
              (p.b / 255.0 - mean[2]) / std[2],
            ];
          })));
}

List currentYolo(Uint8List rgb) {
  final raw = img.Image.fromBytes(
      width: srcW, height: srcH, bytes: rgb.buffer,
      format: img.Format.uint8, numChannels: 3);
  final rot = img.copyRotate(raw, angle: 90);
  final rs = img.copyResize(rot, width: yoloS, height: yoloS,
      interpolation: img.Interpolation.linear);
  return List.generate(1, (_) =>
      List.generate(yoloS, (y) =>
          List.generate(yoloS, (x) {
            final p = rs.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          })));
}



double timeIt(String label, int n, void Function() f) {
  f();
  final sw = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    f();
  }
  final ms = sw.elapsedMicroseconds / 1000 / n;
  // ignore: avoid_print
  print('  ${label.padRight(44)} ${ms.toStringAsFixed(1).padLeft(8)} ms');
  return ms;
}

void main() {
  test('jalur satu lintasan jauh lebih murah daripada jalur lama', () {
    setup();
    const n = 5;
    // ignore: avoid_print
    print('\nSatu frame navigasi $srcW x $srcH, rata-rata $n kali\n');

    // ignore: avoid_print
    print('JALUR LAMA (dulu berjalan di isolate UI):');
    var lama = timeIt('YUV->RGB frame penuh', n, () => yuvToRgb());
    final rgb = yuvToRgb();
    lama += timeIt('PIDNet: rotate+resize+List bersarang', n, () => currentPidnet(rgb));
    lama += timeIt('YOLO:   rotate+resize+List bersarang', n, () => currentYolo(rgb));
    // ignore: avoid_print
    print('  ${'TOTAL'.padRight(44)} ${lama.toStringAsFixed(1).padLeft(8)} ms\n');

    // ignore: avoid_print
    print('JALUR SEKARANG (NavFrameConverter, kode produksi):');
    final baru = timeIt('PIDNet + YOLO sekaligus, bilinear', n, () {
      NavFrameConverter.prepareFromPlanes(
        yPlane: yPlane, uPlane: uPlane, vPlane: vPlane,
        srcW: srcW, srcH: srcH,
        yRowStride: srcW, uvRowStride: srcW, uvPixelStride: 2,
        pidnetBchw: false,
      );
    });

    // ignore: avoid_print
    print('\n  Percepatan: ${(lama / baru).toStringAsFixed(1)}x\n');

    // Ambangnya sengaja LONGGAR. Yang dijaga bukan angka persisnya - mesin
    // uji bisa sedang sibuk - tapi bahwa pola lama tidak kembali. Selisih
    // terukurnya belasan kali lipat, jadi 3x masih jauh dari batas.
    expect(baru * 3, lessThan(lama),
        reason: 'jalur satu lintasan harus tetap jauh lebih murah; kalau '
            'tidak, kemungkinan pola List bersarang kembali dipakai');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
