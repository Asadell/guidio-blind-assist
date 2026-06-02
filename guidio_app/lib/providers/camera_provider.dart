import 'dart:typed_data';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_health_service.dart';
import '../services/tts_service.dart';

/// CameraProvider — kelola kamera, stream, dan capture.
///
/// Fix dari doc 5 masalah 8 + 12:
/// - Mutex _capturing untuk race condition
/// - On-device brightness check (plane Y) setiap frame
/// - YUV420 → JPEG konversi yang benar via package 'image'
class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _initialized = false;
  bool _streaming   = false;
  bool _capturing   = false; // mutex race condition fix
  int  _frameCount  = 0;

  String? _healthMessage; // pesan camera health untuk UI

  CameraController? get controller     => _controller;
  bool              get isInitialized  => _initialized;
  bool              get isStreaming     => _streaming;
  String?           get healthMessage  => _healthMessage;

  // Callback — dipanggil dari CameraProvider ketika frame siap
  // DetectionProvider/InferenceProvider yang subscribe
  Function(CameraImage)? onFrameReady;

  Future<void> initCamera() async {
    // Request camera permission sebelum initialize — mencegah CameraAccessDenied
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('[CameraProvider] Camera permission denied: $status');
      _initialized = false;
      notifyListeners();
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium, // 640x480 cukup untuk YOLO
      enableAudio:    false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    CameraHealthService.instance.startListening();
    _initialized = true;
    notifyListeners();
  }

  void startStream() {
    if (!_initialized || _streaming || _controller == null) return;
    _streaming   = true;
    _frameCount  = 0;

    _controller!.startImageStream((CameraImage image) {
      // Skip frame jika sedang capture (race condition fix)
      if (_capturing) return;

      _frameCount++;

      // [1] On-device brightness check setiap frame — O(100) sangat ringan
      if (_isTooDark(image)) {
        if (_healthMessage != 'Kamera terlalu gelap') {
          _healthMessage = 'Kamera terlalu gelap';
          notifyListeners();
          TTSService.instance.speak('Kamera terlalu gelap');
        }
        return;
      }

      // [2] Cek orientasi dari accelerometer setiap 30 frame
      if (_frameCount % 30 == 0) {
        final health = CameraHealthService.instance.checkOrientation();
        if (!health.ok) {
          if (_healthMessage != health.message) {
            _healthMessage = health.message;
            notifyListeners();
            TTSService.instance.speak(health.message);
          }
          return;
        } else if (_healthMessage != null) {
          _healthMessage = null;
          notifyListeners();
        }
      }

      // [3] Callback ke DetectionProvider jika ada subscriber
      onFrameReady?.call(image);
    });
  }

  void stopStream() {
    if (!_streaming || _controller == null) return;
    _controller!.stopImageStream();
    _streaming = false;
  }

  /// Capture JPEG untuk OCR / Voice Assistant.
  /// Mutex: jika sedang capture, lempar exception (jangan double-capture).
  ///
  /// Fix dari doc 5 masalah 8.
  Future<Uint8List> captureJpeg() async {
    if (_capturing) throw Exception('Sedang capture, coba lagi');
    if (!_initialized || _controller == null) {
      throw Exception('Kamera belum siap');
    }

    _capturing = true;
    try {
      final wasStreaming = _streaming;
      if (wasStreaming) stopStream();

      final xfile = await _controller!.takePicture();
      final bytes = await xfile.readAsBytes();

      if (wasStreaming) {
        // Beri kamera sedikit waktu untuk settle sebelum restart stream
        await Future.delayed(const Duration(milliseconds: 200));
        startStream();
      }

      return bytes;
    } finally {
      _capturing = false;
    }
  }

  /// Konversi CameraImage YUV420 → JPEG untuk dikirim ke server.
  ///
  /// Fix dari doc 5 masalah 1: implementasi penuh, bukan hanya plane Y.
  Future<Uint8List> toJpeg(CameraImage cameraImage) async {
    final int width  = cameraImage.width;
    final int height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBytes      = yPlane.bytes;
    final uBytes      = uPlane.bytes;
    final vBytes      = vPlane.bytes;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStr  = uPlane.bytesPerPixel ?? 1;

    final rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIdx  = y * yPlane.bytesPerRow + x;
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStr;

        final yVal = yBytes[yIdx] & 0xFF;
        final uVal = (uBytes.length > uvIdx ? uBytes[uvIdx] : 128) & 0xFF;
        final vVal = (vBytes.length > uvIdx ? vBytes[uvIdx] : 128) & 0xFF;

        final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        final g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
        final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    // Encode ke JPEG quality 70 — cukup untuk YOLO server, tidak terlalu besar
    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 70));
  }

  /// On-device brightness check — sample 100 piksel dari plane Y (YUV420).
  /// O(100) sangat ringan, aman dipanggil setiap frame.
  ///
  /// Fix dari doc 5 masalah 12.
  bool _isTooDark(CameraImage image) {
    final yPlane = image.planes[0].bytes;
    final step   = yPlane.length ~/ 100;
    if (step <= 0) return false;

    int total = 0;
    for (int i = 0; i < yPlane.length; i += step) {
      total += yPlane[i] & 0xFF;
    }
    final avgBrightness = total / 100;
    return avgBrightness < 30; // < 30/255 = sangat gelap
  }

  @override
  void dispose() {
    CameraHealthService.instance.stopListening();
    _controller?.dispose();
    super.dispose();
  }
}
