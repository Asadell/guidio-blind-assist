import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Inferensi on-device - TIDAK membutuhkan Flutter binding / rootBundle.
///
/// Berkas ini kini HANYA menguji navigasi. Uji uang pindah ke
/// `test/money_pipeline_test.dart` karena harus lewat fungsi aplikasi
/// (`MoneyTFLiteService`), bukan memanggil interpreter langsung - lihat
/// catatan panjang di posisi bekas grup A di bawah.
///
/// **B. Navigasi YOLO11n (INT8)**
///   - Model  : assets/models/yolo11n_navigasi.tflite
///   - Input  : [1,640,640,3] float32, rentang 0..1
///   - Output : [1,10,8400] - 4 box + 6 class scores
///   - Fixture: test/fixtures/navigation/ (PNG gambar bahaya jalan)
///   - Validasi: setidaknya satu Detection terdeteksi, dan labelnya
///              ada di daftar kelas yang diketahui dari gambar itu
///              (diambil dari nama file via regex).
///
/// Grup ini skip otomatis kalau shared library TFLite tidak ada
/// (contoh: CI Linux tanpa libtensorflowlite_c-linux.so).
/// ─────────────────────────────────────────────────────────────────────────────

// ── Konstanta model ──────────────────────────────────────────────────────────

const _kYoloModelPath  = 'assets/models/yolo11n_navigasi.tflite';


/// Kelas navigasi - urutan sesuai training (lihat yolo_navigasi_service.dart).
const List<String> _navLabels = [
  'lubang', 'got_terbuka', 'tangga', 'orang', 'motor', 'tiang',
];

// Confidence threshold production (sama dengan service)
const double _yoloConfThresh  = 0.30;
const double _yoloIouThresh   = 0.45;
const int    _yoloSize        = 640;

// ── Helper: parse ground-truth dari nama file ────────────────────────────────

/// Ekstrak label yang DIHARAPKAN ada di gambar navigasi dari nama file.
/// Pola: {seq}_{label_dengan_underscore}.png
/// Contoh: "02_lubang_trotoar.png" → hint 'lubang'
///         "01_got_terbuka.png"    → hint 'got_terbuka'
///         "04_motor_dan_orang.png"→ hint 'motor', 'orang'
List<String> _navLabelsFromFilename(String filename) {
  // Hapus ekstensi dan sequence prefix (mis. "01_")
  final bare = filename.replaceFirst(RegExp(r'^\d+_'), '').replaceAll('.png', '');
  // bare mis: "got_terbuka", "lubang_trotoar", "motor_dan_orang", "tiang_listrik", "tangga_turun"
  return _navLabels.where((label) => bare.contains(label)).toList();
}

// ── Helper: load TFLite interpreter dari file ────────────────────────────────

Interpreter? _loadInterpreter(String assetRelPath, {int threads = 2}) {
  final file = File(assetRelPath);
  if (!file.existsSync()) return null;
  try {
    final bytes = file.readAsBytesSync();
    final opts  = InterpreterOptions()..threads = threads;
    return Interpreter.fromBuffer(bytes, options: opts);
  } catch (_) {
    return null;
  }
}

// ── Helper: preprocessing gambar untuk YOLO (0..1) ──────────────────────────

List<List<List<List<double>>>> _preprocessYolo(img.Image source) {
  final resized = img.copyResize(source,
      width: _yoloSize, height: _yoloSize,
      interpolation: img.Interpolation.linear);

  return List.generate(1, (_) =>
    List.generate(_yoloSize, (y) =>
      List.generate(_yoloSize, (x) {
        final p = resized.getPixel(x, y);
        return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
      }),
    ),
  );
}

// ── Helper: NMS sederhana ────────────────────────────────────────────────────

double _iou(List<double> a, List<double> b) {
  final ix1 = math.max(a[0], b[0]);
  final iy1 = math.max(a[1], b[1]);
  final ix2 = math.min(a[2], b[2]);
  final iy2 = math.min(a[3], b[3]);
  final iw = math.max(0.0, ix2 - ix1);
  final ih = math.max(0.0, iy2 - iy1);
  final inter = iw * ih;
  if (inter == 0) return 0;
  final aA = (a[2]-a[0]) * (a[3]-a[1]);
  final aB = (b[2]-b[0]) * (b[3]-b[1]);
  return inter / (aA + aB - inter);
}

class _Box {
  final int classIdx;
  final double conf;
  final List<double> xyxy;
  const _Box(this.classIdx, this.conf, this.xyxy);
}

List<_Box> _postProcessYolo(List<List<double>> raw) {
  // raw shape: [10][8400], layout: [cx,cy,w,h, score0..score5]
  final boxes = <_Box>[];
  for (var i = 0; i < 8400; i++) {
    double bestScore = 0;
    int bestCls = 0;
    for (var c = 0; c < _navLabels.length; c++) {
      final s = raw[4 + c][i];
      if (s > bestScore) { bestScore = s; bestCls = c; }
    }
    if (bestScore < _yoloConfThresh) continue;
    final cx = raw[0][i], cy = raw[1][i],
          w  = raw[2][i], h  = raw[3][i];
    boxes.add(_Box(bestCls, bestScore, [cx-w/2, cy-h/2, cx+w/2, cy+h/2]));
  }

  // Sort by confidence desc
  boxes.sort((a, b) => b.conf.compareTo(a.conf));

  // NMS
  final keep = <_Box>[];
  final suppressed = List.filled(boxes.length, false);
  for (var i = 0; i < boxes.length; i++) {
    if (suppressed[i]) continue;
    keep.add(boxes[i]);
    for (var j = i + 1; j < boxes.length; j++) {
      if (suppressed[j]) continue;
      if (boxes[i].classIdx == boxes[j].classIdx &&
          _iou(boxes[i].xyxy, boxes[j].xyxy) > _yoloIouThresh) {
        suppressed[j] = true;
      }
    }
  }
  return keep;
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ─── A. Kenali Uang - DIPINDAH ke test/money_pipeline_test.dart ──────────
  //
  // Grup uang yang dulu ada di sini SENGAJA dihapus, bukan dipindah apa adanya.
  // Dua cacatnya membuat suite ini hijau sementara mode uang rusak:
  //
  //   1. Ia membangun preprocessing SENDIRI:
  //        img.copyResize(source, width: 224, height: 224)
  //      Itu MEREGANGKAN gambar jadi persegi. Model dilatih dengan
  //      `tf.image.resize_with_pad` (letterbox) dan aplikasi memakai letterbox
  //      + center-crop 0,7. Jadi suite ini mengukur pipeline yang tidak pernah
  //      dijalankan siapa pun, sementara pipeline sungguhan tidak diuji.
  //
  //   2. Assert-nya tidak bisa gagal: di bawah ambang 0,85 ia hanya mencetak
  //      peringatan lalu lulus. Karena model nyaris tidak pernah menembus
  //      0,85, SETIAP gambar lewat cabang itu - model yang mengeluarkan 20%
  //      untuk semua masukan pun lulus 100%.
  //
  // Penggantinya memanggil MoneyTFLiteService.classifyCameraImage - fungsi
  // yang benar-benar dipakai aplikasi - dan assert-nya keras.

  // ─── B. Navigasi YOLO11n ───────────────────────────────────────────────────
  group('B. Navigasi YOLO11n - hazard detection inference', () {
    late Interpreter? interp;

    setUpAll(() {
      interp = _loadInterpreter(_kYoloModelPath, threads: 4);
      if (interp == null) {
        // ignore: avoid_print
        print('[TEST] TFLite SO tidak ada - semua test YOLO akan di-skip.');
      }
    });

    tearDownAll(() => interp?.close());

    /// Fixture + label yang DIHARAPKAN terdeteksi (dari nama file).
    /// Regex dipakai oleh _navLabelsFromFilename() - tidak ada hard-coded list.
    const navFixtures = [
      '01_got_terbuka.png',    // → got_terbuka
      '02_lubang_trotoar.png', // → lubang
      '03_tiang_listrik.png',  // → tiang
      '04_motor_dan_orang.png',// → motor, orang
      '05_tangga_turun.png',   // → tangga
    ];

    for (final fixture in navFixtures) {
      final expectedLabels = _navLabelsFromFilename(fixture);

      test('$fixture → mendeteksi: $expectedLabels', () {
        if (interp == null) {
          markTestSkipped('TFLite SO tidak tersedia (non-Android host).');
          return;
        }

        // 1. Baca & decode PNG
        final file = File('test/fixtures/navigation/$fixture');
        expect(file.existsSync(), isTrue,
            reason: 'Fixture tidak ada: $fixture');

        final decoded = img.decodeImage(file.readAsBytesSync());
        expect(decoded, isNotNull, reason: 'Gagal decode $fixture');

        // 2. Preprocessing: resize ke 640×640, normalisasi 0..1
        final input = _preprocessYolo(decoded!);

        // 3. Inferensi - output [1][10][8400]
        final rawOutput = [List.generate(10, (_) => List.filled(8400, 0.0))];
        final outputs = {0: rawOutput};
        interp!.runForMultipleInputs([input], outputs);

        // 4. Post-process
        final detections = _postProcessYolo(rawOutput[0]);
        final detectedLabels = detections.map((d) => _navLabels[d.classIdx]).toSet();

        // ignore: avoid_print
        print('[$fixture] deteksi: ${detections.map((d) =>
            '${_navLabels[d.classIdx]}(${(d.conf*100).toStringAsFixed(1)}%)').toList()}');

        // 5. Validasi: setidaknya satu label dari yang diharapkan harus muncul
        if (expectedLabels.isEmpty) {
          // Gambar tidak punya mapping label yang diketahui → skip validasi label,
          // cukup pastikan inference tidak crash
          // ignore: avoid_print
          print('  ⚠ Tidak ada expected label dari nama file "$fixture" - skip label check.');
          return;
        }

        final intersection = detectedLabels.intersection(expectedLabels.toSet());
        expect(
          intersection.isNotEmpty,
          isTrue,
          reason: '$fixture: tidak ada label yang diharapkan ($expectedLabels) '
                  'terdeteksi. Yang terdeteksi: $detectedLabels\n'
                  'Periksa apakah confidence threshold ($_yoloConfThresh) '
                  'terlalu tinggi atau model perlu di-retrain.',
        );
      });
    }

    // Extra: pastikan inference tidak crash pada gambar "normal" (bukan bahaya)
    test('inference tidak crash pada gambar arbitrary', () {
      if (interp == null) {
        markTestSkipped('TFLite SO tidak tersedia.');
        return;
      }

      // Buat gambar solid 640x640 (simulasi frame kosong)
      final blank = img.Image(width: _yoloSize, height: _yoloSize);
      img.fill(blank, color: img.ColorFloat16.rgb(128, 128, 128));

      final input = _preprocessYolo(blank);
      final rawOutput = [List.generate(10, (_) => List.filled(8400, 0.0))];
      final outputs = {0: rawOutput};

      // Tidak boleh throw
      expect(
        () => interp!.runForMultipleInputs([input], outputs),
        returnsNormally,
      );
    });
  });
}

