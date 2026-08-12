import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Payload YUV420 yang **bisa dikirim antar isolate**.
///
/// `CameraImage` adalah objek platform dan tidak bisa menyeberang batas
/// isolate, jadi byte-nya disalin ke bentuk polos dulu. Penyalinan ini murah
/// dibanding konversi warnanya sendiri.
@immutable
class YuvFrame {
  final int width;
  final int height;
  final Uint8List y;
  final Uint8List u;
  final Uint8List v;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  const YuvFrame({
    required this.width,
    required this.height,
    required this.y,
    required this.u,
    required this.v,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  factory YuvFrame.fromCameraImage(CameraImage image) => YuvFrame(
        width: image.width,
        height: image.height,
        y: image.planes[0].bytes,
        u: image.planes[1].bytes,
        v: image.planes[2].bytes,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
      );
}

/// Parameter encode. Dibungkus jadi satu objek karena `compute` hanya
/// menerima satu argumen.
@immutable
class _EncodeRequest {
  final YuvFrame frame;
  final int maxEdge;
  final int quality;
  const _EncodeRequest(this.frame, this.maxEdge, this.quality);
}

/// Preset ukuran unggah per jenis pemakaian.
///
/// **Memperkecil gambar sebelum dikirim adalah keputusan yang paling
/// menentukan waktu unggah** — jauh lebih berpengaruh daripada pilihan
/// protokol, keep-alive, atau kompresi tambahan. Frame 640×480 pada kualitas
/// 70 sekitar 40–60 KB; frame 1920×1080 kualitas 90 bisa 400 KB. Di jaringan
/// seluler menengah itu selisih beberapa detik, tiap frame.
///
/// Angka di bawah dipilih dari apa yang model di server benar-benar pakai:
/// mengirim piksel lebih banyak daripada yang dikonsumsi model adalah biaya
/// murni tanpa perbaikan akurasi.
abstract final class UploadPreset {
  /// Segmentasi jalur & deteksi objek — model server memakai 640 px.
  static const navigation = (maxEdge: 640, quality: 70);

  /// Cari objek — butuh sedikit lebih tajam untuk barang kecil.
  static const findObject = (maxEdge: 800, quality: 75);

  /// OCR — teks butuh resolusi jauh lebih tinggi. Huruf kecil hancur di 640 px.
  static const ocr = (maxEdge: 1600, quality: 85);
}

/// Konversi dan kompresi frame kamera untuk dikirim ke server.
abstract final class FrameCodec {
  /// YUV420 → JPEG **di isolate terpisah**.
  ///
  /// Versi lama mengerjakan ini di UI thread: 640×480 berarti 307.200 iterasi
  /// Dart per frame. Pada laju streaming apa pun itu membuat antarmuka
  /// tersendat — dan di aplikasi yang dipakai sambil berjalan, tersendat
  /// berarti peringatan terlambat. `compute` memindahkannya ke isolate lain
  /// sehingga UI thread bebas menggambar dan TTS tetap lancar.
  static Future<Uint8List> encodeForUpload(
    CameraImage image, {
    int maxEdge = 640,
    int quality = 70,
  }) {
    final frame = YuvFrame.fromCameraImage(image);
    return compute(_encodeIsolate, _EncodeRequest(frame, maxEdge, quality));
  }

  /// Versi untuk JPEG yang sudah jadi (hasil `takePicture`) — hanya
  /// memperkecil dan mengompres ulang. Dipakai sebelum mengunggah foto OCR:
  /// kamera sering menghasilkan 4000 px yang tidak menambah akurasi apa pun.
  static Future<Uint8List> recompressJpeg(
    Uint8List jpeg, {
    int maxEdge = 1600,
    int quality = 85,
  }) =>
      compute(_recompressIsolate, (jpeg, maxEdge, quality));
}

Uint8List _encodeIsolate(_EncodeRequest req) {
  final f = req.frame;
  final rgb = img.Image(width: f.width, height: f.height);

  for (var y = 0; y < f.height; y++) {
    final yRow = y * f.yRowStride;
    final uvRow = (y >> 1) * f.uvRowStride;
    for (var x = 0; x < f.width; x++) {
      final uvIdx = uvRow + (x >> 1) * f.uvPixelStride;

      final yVal = f.y[yRow + x] & 0xFF;
      final uVal = (uvIdx < f.u.length ? f.u[uvIdx] : 128) & 0xFF;
      final vVal = (uvIdx < f.v.length ? f.v[uvIdx] : 128) & 0xFF;

      final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
      final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

      rgb.setPixelRgb(x, y, r, g, b);
    }
  }

  return _downscaleAndEncode(rgb, req.maxEdge, req.quality);
}

Uint8List _recompressIsolate((Uint8List, int, int) args) {
  final (bytes, maxEdge, quality) = args;
  final decoded = img.decodeJpg(bytes);
  if (decoded == null) return bytes; // biarkan apa adanya daripada gagal total
  return _downscaleAndEncode(decoded, maxEdge, quality);
}

Uint8List _downscaleAndEncode(img.Image src, int maxEdge, int quality) {
  final longEdge = src.width > src.height ? src.width : src.height;
  final out = longEdge <= maxEdge
      ? src
      : img.copyResize(
          src,
          width: src.width >= src.height ? maxEdge : null,
          height: src.height > src.width ? maxEdge : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}
