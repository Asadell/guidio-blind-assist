import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Menyiapkan satu frame kamera menjadi DUA tensor sekaligus — PIDNet dan
/// YOLO navigasi — dalam satu lintasan, di isolate terpisah.
///
/// ## Kenapa ditulis ulang total
///
/// Versi sebelumnya melakukan ini untuk setiap frame, seluruhnya di isolate UI:
///
/// ```
/// YUV420 -> RGB frame penuh          307.200 piksel
/// Image.fromBytes                    salinan ~0,9 MB
/// copyRotate 90 derajat  (PIDNet)    salinan lagi
/// copyResize 640x384                 salinan lagi
/// List.generate bersarang            245.760 objek List kecil
/// copyRotate 90 derajat  (YOLO)      salinan lagi, frame yang SAMA
/// copyResize 640x640                 salinan lagi
/// List.generate bersarang            409.600 objek List kecil
/// ```
///
/// Diukur di CPU desktop: **136 ms per frame**, ditambah sekitar 3,5 MB gambar
/// antara dan **655.360 objek List kecil** yang langsung jadi sampah. Di HP
/// mid-low angkanya berkali lipat.
///
/// Dua akibatnya, dan keduanya persis yang ingin dihindari:
///
/// 1. **Preview tersendat.** Isolate UI terkunci ratusan milidetik setiap
///    siklus. Karena TTS juga dijadwalkan dari thread yang sama, suaranya ikut
///    tersendat — di mode yang tugasnya memperingatkan bahaya.
/// 2. **Model menerima frame yang sudah basi.** Frame yang datang saat isolate
///    UI sibuk dibuang. Modelnya bagus, tapi yang sampai ke dia gambar dari
///    beberapa ratus milidetik yang lalu — dan pengguna sudah melangkah.
///
/// Versi ini menggabungkan rotasi, crop, penskalaan, konversi warna, dan
/// normalisasi menjadi **pemetaan indeks**. Tidak ada gambar antara yang
/// dialokasikan sama sekali; setiap piksel keluaran dibaca langsung dari
/// bidang YUV mentah.
///
/// Diukur di mesin yang sama: **23 ms**, sekitar **6x lebih cepat**, dan
/// seluruhnya di luar isolate UI. Angkanya bukan 13x seperti pada purwarupa
/// awal karena purwarupa itu memakai nearest-neighbour; bilinear membaca
/// empat piksel alih-alih satu. Selisih itu dibayar dengan sengaja — lihat
/// catatan di [_YuvSampler].
///
/// Ukur ulang kapan saja: `flutter test test/nav_pipeline_bench_test.dart`.
///
/// ## Kenapa satu panggilan untuk dua tensor
///
/// Keduanya membaca frame yang sama. Dua panggilan berarti dua kali menyalin
/// bidang YUV melintasi batas isolate, dan membuka kemungkinan keduanya
/// memproses frame yang berbeda tanpa ada yang menyadarinya.
///
/// ## Kenapa `compute()` dan bukan isolate pekerja jangka panjang
///
/// Diukur juga: `Isolate.run` yang spawn tiap panggilan memakan 3,6 ms,
/// sementara isolate pekerja yang hidup terus memakan 5,2 ms untuk pekerjaan
/// yang sama. Dart modern berbagi heap dan kode antar isolate dalam satu grup,
/// jadi spawn-nya murah. Isolate pekerja menambah siklus hidup, penanganan
/// galat, dan tekanan balik yang harus dijaga sendiri — semuanya di mode yang
/// menyangkut keselamatan — tanpa satu pun keuntungan terukur.
class NavFrameConverter {
  NavFrameConverter._();

  /// Siapkan kedua tensor dari satu frame kamera.
  ///
  /// [pidnetBchw] mengikuti tata letak yang diminta model segmentasi:
  /// `true` untuk `[1,3,H,W]`, `false` untuk `[1,H,W,3]`.
  static Future<NavTensors> prepare(
    CameraImage image, {
    required bool pidnetBchw,
  }) {
    return compute(_prepareNavTensors, _NavPrepArgs.from(image, pidnetBchw));
  }

  /// Jalur yang sama, tapi dari bidang YUV mentah dan tanpa isolate.
  ///
  /// `CameraImage` tidak bisa dibuat di test — konstruktornya milik plugin dan
  /// butuh perangkat. Tanpa pintu ini, satu-satunya bagian yang menentukan
  /// apakah model menerima piksel yang benar justru tidak bisa diuji sama
  /// sekali, dan kesalahan pemetaan indeks di sini tidak memunculkan error:
  /// modelnya tetap jalan, hasilnya saja yang memburuk.
  @visibleForTesting
  static NavTensors prepareFromPlanes({
    required Uint8List yPlane,
    required Uint8List uPlane,
    required Uint8List vPlane,
    required int srcW,
    required int srcH,
    required int yRowStride,
    required int uvRowStride,
    required int uvPixelStride,
    required bool pidnetBchw,
  }) {
    return _prepareNavTensors(_NavPrepArgs(
      yPlane: yPlane,
      uPlane: uPlane,
      vPlane: vPlane,
      srcW: srcW,
      srcH: srcH,
      yRowStride: yRowStride,
      uvRowStride: uvRowStride,
      uvPixelStride: uvPixelStride,
      pidnetBchw: pidnetBchw,
    ));
  }
}

/// Dua tensor masukan, plus ukuran bingkai tegak yang jadi acuan koordinat.
class NavTensors {
  /// `[1,3,384,640]` atau `[1,384,640,3]`, ternormalisasi ImageNet.
  final Float32List pidnet;

  /// `[1,640,640,3]`, rentang 0..1.
  final Float32List yolo;

  /// Ukuran bingkai TEGAK — bingkai yang dilihat pengguna di preview, dan
  /// acuan koordinat kotak deteksi.
  final int uprightWidth;
  final int uprightHeight;

  const NavTensors({
    required this.pidnet,
    required this.yolo,
    required this.uprightWidth,
    required this.uprightHeight,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  Argumen yang menyeberang ke isolate
// ═══════════════════════════════════════════════════════════════════════════

class _NavPrepArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int srcW, srcH;
  final int yRowStride, uvRowStride, uvPixelStride;
  final bool pidnetBchw;

  const _NavPrepArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.srcW,
    required this.srcH,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.pidnetBchw,
  });

  factory _NavPrepArgs.from(CameraImage image, bool pidnetBchw) => _NavPrepArgs(
        yPlane: image.planes[0].bytes,
        uPlane: image.planes[1].bytes,
        vPlane: image.planes[2].bytes,
        srcW: image.width,
        srcH: image.height,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
        pidnetBchw: pidnetBchw,
      );
}

// Ukuran masukan kedua model. Disalin di sini, bukan diimpor dari service,
// supaya fungsi ini tetap murni dan bisa diuji sendirian.
const int _pidW = 640, _pidH = 384;
const int _yoloS = 640;

const List<double> _mean = [0.485, 0.456, 0.406];
const List<double> _std = [0.229, 0.224, 0.225];

/// Satu lintasan: YUV -> rotasi -> skala -> RGB -> normalisasi.
///
/// Berjalan di isolate. Tidak mengalokasikan apa pun selain dua buffer
/// keluaran — penting untuk HP 4 GB, di mana 655 ribu objek kecil per frame
/// memicu pengumpulan sampah yang terasa sebagai sentakan berkala.
NavTensors _prepareNavTensors(_NavPrepArgs a) {
  // Bingkai tegak = bingkai sensor diputar 90 derajat.
  final uprightW = a.srcH;
  final uprightH = a.srcW;

  final pid = Float32List(_pidW * _pidH * 3);
  final yolo = Float32List(_yoloS * _yoloS * 3);

  final sampler = _YuvSampler(a);

  // ── PIDNet ──
  const pidPlane = _pidW * _pidH; // hanya dipakai untuk tata letak BCHW
  for (var ty = 0; ty < _pidH; ty++) {
    // Sumbu vertikal bingkai tegak memetakan ke sumbu horizontal sensor.
    final syUpright = (ty * uprightH) / _pidH;
    for (var tx = 0; tx < _pidW; tx++) {
      final sxUpright = (tx * uprightW) / _pidW;
      final rgb = sampler.sampleUpright(sxUpright, syUpright);

      final r = (rgb.r / 255.0 - _mean[0]) / _std[0];
      final g = (rgb.g / 255.0 - _mean[1]) / _std[1];
      final b = (rgb.b / 255.0 - _mean[2]) / _std[2];

      if (a.pidnetBchw) {
        final i = ty * _pidW + tx;
        pid[i] = r;
        pid[pidPlane + i] = g;
        pid[pidPlane * 2 + i] = b;
      } else {
        final o = (ty * _pidW + tx) * 3;
        pid[o] = r;
        pid[o + 1] = g;
        pid[o + 2] = b;
      }
    }
  }

  // ── YOLO ──
  var o = 0;
  for (var ty = 0; ty < _yoloS; ty++) {
    final syUpright = (ty * uprightH) / _yoloS;
    for (var tx = 0; tx < _yoloS; tx++) {
      final sxUpright = (tx * uprightW) / _yoloS;
      final rgb = sampler.sampleUpright(sxUpright, syUpright);
      yolo[o++] = rgb.r / 255.0;
      yolo[o++] = rgb.g / 255.0;
      yolo[o++] = rgb.b / 255.0;
    }
  }

  return NavTensors(
    pidnet: pid,
    yolo: yolo,
    uprightWidth: uprightW,
    uprightHeight: uprightH,
  );
}

/// Pengambil sampel piksel dari bidang YUV, dengan koordinat bingkai TEGAK.
///
/// Luma diambil BILINEAR, kroma nearest.
///
/// Bilinear-nya bukan kemewahan. PIDNet mengecilkan sisi 640 piksel menjadi
/// 384 — pengecilan 1,7x. Dengan nearest, dua dari tiga baris piksel dibuang
/// begitu saja, dan tepi trotoar yang tipis bisa hilang atau berkedip antar
/// frame. Versi lama memakai `Interpolation.linear`; menggantinya dengan
/// nearest akan menurunkan akurasi diam-diam sambil laporan kecepatannya
/// terlihat bagus — persis jenis kesalahan yang membuat orang menyalahkan
/// modelnya.
///
/// Kroma tetap nearest karena U dan V memang sudah disubsampel 2x2 di sumber;
/// menginterpolasinya menambah pekerjaan tanpa menambah informasi.
class _YuvSampler {
  final Uint8List y, u, v;
  final int srcW, srcH;
  final int yRow, uvRow, uvPix;
  final int yLen, uLen, vLen;

  _YuvSampler(_NavPrepArgs a)
      : y = a.yPlane,
        u = a.uPlane,
        v = a.vPlane,
        srcW = a.srcW,
        srcH = a.srcH,
        yRow = a.yRowStride,
        uvRow = a.uvRowStride,
        uvPix = a.uvPixelStride,
        yLen = a.yPlane.length,
        uLen = a.uPlane.length,
        vLen = a.vPlane.length;

  int _y(int sx, int sy) {
    if (sx < 0 || sy < 0 || sx >= srcW || sy >= srcH) return 0;
    final i = sy * yRow + sx;
    return i >= 0 && i < yLen ? y[i] : 0;
  }

  /// [ux], [uy] adalah koordinat pecahan di bingkai TEGAK.
  ({double r, double g, double b}) sampleUpright(double ux, double uy) {
    // Rotasi 90 derajat: baris tegak -> kolom sensor, kolom tegak -> baris
    // sensor terbalik. Sama persis dengan `img.copyRotate(angle: 90)`.
    final sxF = uy;
    final syF = (srcH - 1) - ux;

    final sx0 = sxF.floor();
    final sy0 = syF.floor();
    final fx = sxF - sx0;
    final fy = syF - sy0;
    final sx1 = sx0 + 1 < srcW ? sx0 + 1 : sx0;
    final sy1 = sy0 + 1 < srcH ? sy0 + 1 : sy0;

    // Luma bilinear.
    final y00 = _y(sx0, sy0).toDouble();
    final y10 = _y(sx1, sy0).toDouble();
    final y01 = _y(sx0, sy1).toDouble();
    final y11 = _y(sx1, sy1).toDouble();
    final top = y00 + (y10 - y00) * fx;
    final bot = y01 + (y11 - y01) * fx;
    final yVal = top + (bot - top) * fy;

    // Kroma nearest.
    final cx = sx0 < 0 ? 0 : (sx0 >= srcW ? srcW - 1 : sx0);
    final cy = sy0 < 0 ? 0 : (sy0 >= srcH ? srcH - 1 : sy0);
    final uvIdx = (cy >> 1) * uvRow + (cx >> 1) * uvPix;
    final uVal = (uvIdx >= 0 && uvIdx < uLen ? u[uvIdx] : 128) - 128;
    final vVal = (uvIdx >= 0 && uvIdx < vLen ? v[uvIdx] : 128) - 128;

    return (
      r: (yVal + 1.402 * vVal).clamp(0.0, 255.0),
      g: (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0.0, 255.0),
      b: (yVal + 1.772 * uVal).clamp(0.0, 255.0),
    );
  }
}
