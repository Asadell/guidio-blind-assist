import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image/image.dart' as img;

/// Ubah gambar RGB jadi [CameraImage] YUV420 bertata letak Android.
///
/// Dipakai bersama oleh `money_pipeline_test.dart` dan
/// `rupiah_kamera_e2e_test.dart`. Diekstrak ke sini supaya konversi YUV yang
/// rumit ini hanya ada di SATU tempat: kalau tata letak kroma di sini
/// menyimpang dari yang diindeks service, dua suite sekaligus akan diam-diam
/// menguji sesuatu yang tidak pernah terjadi di perangkat asli.
///
/// Tata letaknya ditiru persis, bukan disederhanakan: `YUV_420_888` di
/// mayoritas perangkat Android memberi bidang U dan V yang *interleaved*
/// dengan `pixelStride == 2`, dan [MoneyTFLiteService] mengindeksnya lewat
/// `(y~/2) * uvRowStride + (x~/2) * uvPixelStride`. Kalau test memakai tata
/// letak planar (`pixelStride == 1`) yang lebih gampang dibuat, bug indeks
/// kroma pada perangkat asli tidak akan pernah tertangkap.
///
/// Koefisien BT.601 full-range di sini adalah kebalikan tepat dari yang
/// dipakai service, jadi konversi bolak-balik tidak menyuntikkan pergeseran
/// warna yang bisa disalahartikan sebagai kesalahan model.
CameraImage toCameraImage(img.Image src) {
  final w = src.width - (src.width.isOdd ? 1 : 0);
  final h = src.height - (src.height.isOdd ? 1 : 0);

  final yPlane = Uint8List(w * h);
  final uvRowStride = w;
  const uvPixelStride = 2;
  final uPlane = Uint8List((h ~/ 2) * uvRowStride);
  final vPlane = Uint8List((h ~/ 2) * uvRowStride);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();

      yPlane[y * w + x] =
          (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);

      // Subsampling 4:2:0 - kroma hanya ditulis di piksel genap.
      if (y.isEven && x.isEven) {
        final u = (-0.168736 * r - 0.331264 * g + 0.5 * b) + 128.0;
        final v = (0.5 * r - 0.418688 * g - 0.081312 * b) + 128.0;
        final idx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        uPlane[idx] = u.round().clamp(0, 255);
        vPlane[idx] = v.round().clamp(0, 255);
      }
    }
  }

  return CameraImage.fromPlatformInterface(CameraImageData(
    format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
    width: w,
    height: h,
    planes: [
      CameraImagePlane(bytes: yPlane, bytesPerRow: w),
      CameraImagePlane(
          bytes: uPlane, bytesPerRow: uvRowStride, bytesPerPixel: uvPixelStride),
      CameraImagePlane(
          bytes: vPlane, bytesPerRow: uvRowStride, bytesPerPixel: uvPixelStride),
    ],
  ));
}
