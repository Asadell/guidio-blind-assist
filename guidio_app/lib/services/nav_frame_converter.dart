import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Konversi CameraImage (YUV420) → RGB888 bytes (Uint8List).
///
/// Dipakai oleh PidnetService dan YoloNavigasiService untuk preprocessing
/// frame kamera sebelum inference TFLite on-device.
///
/// Output: [R, G, B, R, G, B, ...] panjang = width × height × 3.
/// Caller meneruskan origW dan origH dari CameraImage.
class NavFrameConverter {
  NavFrameConverter._();

  static ({Uint8List rgb, int width, int height}) fromCameraImage(
    CameraImage image,
  ) {
    final int w = image.width;
    final int h = image.height;

    final yPlane  = image.planes[0];
    final uPlane  = image.planes[1];
    final vPlane  = image.planes[2];

    final yBytes      = yPlane.bytes;
    final uBytes      = uPlane.bytes;
    final vBytes      = vPlane.bytes;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixStride = uPlane.bytesPerPixel ?? 1;

    final rgb = Uint8List(w * h * 3);
    int idx = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yIdx  = y * yPlane.bytesPerRow + x;
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixStride;

        final yVal = yBytes[yIdx] & 0xFF;
        final uVal = (uBytes.length > uvIdx ? uBytes[uvIdx] : 128) & 0xFF;
        final vVal = (vBytes.length > uvIdx ? vBytes[uvIdx] : 128) & 0xFF;

        rgb[idx++] = (yVal + 1.402  * (vVal - 128)).round().clamp(0, 255);
        rgb[idx++] = (yVal - 0.344  * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
        rgb[idx++] = (yVal + 1.772  * (uVal - 128)).round().clamp(0, 255);
      }
    }

    return (rgb: rgb, width: w, height: h);
  }
}
