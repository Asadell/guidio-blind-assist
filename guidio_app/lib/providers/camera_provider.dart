import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../core/speech/tts_queue.dart';
import '../services/camera_health_service.dart';
import '../services/tflite_service.dart';

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
  bool    _isDark         = false; // hasil on-device brightness check
  bool    _darkDismissed  = false; // true = jangan tampilkan tawaran lampu lagi
  bool    _isTorchOn      = false; // status flashlight

  // Fix 2.1: Timer peringatan gelap berkala — ucap setiap 30 detik jika masih gelap
  Timer?   _darkWarningTimer;

  /// Sejak kapan kondisi gelap berlangsung — dibaca layar/telemetri untuk
  /// membedakan "baru saja gelap" dari "sudah lama tidak melihat apa-apa".
  DateTime? _darkSince;
  DateTime? get darkSince => _darkSince;

  CameraController? get controller    => _controller;
  bool              get isInitialized => _initialized;
  bool              get isStreaming    => _streaming;
  String?           get healthMessage => _healthMessage;

  /// True saat rata-rata kecerahan frame < threshold.
  /// UI menampilkan ContextualActionSlot tawaran lampu HANYA jika
  /// [isDark] && ![darkDismissed].
  bool get isDark         => _isDark;

  /// True saat pengguna menekan "Lewati" — tawaran lampu tidak tampil,
  /// TAPI deteksi tetap berjalan (Fix 2.1).
  bool get darkDismissed  => _darkDismissed;

  /// True saat flashlight sedang menyala.
  bool get isTorchOn => _isTorchOn;

  // Callback — dipanggil dari CameraProvider ketika frame siap
  // DetectionProvider/InferenceProvider yang subscribe
  Function(CameraImage)? onFrameReady;

  /// Dipasang MainScreen supaya kamera yang gagal muncul sebagai banner
  /// global Critical, bukan hanya layar hitam tanpa penjelasan.
  void Function(bool hasError)? onErrorChanged;

  bool _hasError = false;
  bool get hasError => _hasError;

  void _setError(bool value) {
    if (_hasError == value) return;
    _hasError = value;
    onErrorChanged?.call(value);
    notifyListeners();
  }

  Future<void> initCamera() async {
    // Request camera permission sebelum initialize — mencegah CameraAccessDenied
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('[CameraProvider] Camera permission denied: $status');
      _initialized = false;
      notifyListeners();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[CameraProvider] Tidak ada kamera pada perangkat ini');
        _setError(true);
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium, // 640x480 cukup untuk YOLO
        enableAudio:    false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      CameraHealthService.instance.startListening();
      _initialized = true;
      _setError(false);
      notifyListeners();
    } catch (e) {
      // Kamera gagal disiapkan = mode utama benar-benar buta. Kegagalan yang
      // ditelan diam-diam di sini akan tampil sebagai aplikasi yang terlihat
      // normal tapi tidak pernah memperingatkan apa pun.
      debugPrint('[CameraProvider] initCamera error: $e');
      _initialized = false;
      _setError(true);
    }
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
      final tooDark = _isTooDark(image);
      if (tooDark != _isDark) {
        _isDark = tooDark;
        if (tooDark) {
          // Mulai timer peringatan gelap (Fix 2.1)
          _darkSince = DateTime.now();
          _startDarkWarningTimer();
        } else {
          // Kondisi terang kembali — reset semua
          _cancelDarkWarningTimer();
          _darkDismissed = false;
          _darkSince = null;
        }
        // Notifikasi UI: ContextualActionSlot tampil/sembunyikan tawaran lampu
        notifyListeners();
      }
      // Fix 2.1: JANGAN return di sini — inference tetap berjalan di kondisi gelap.
      // Pengguna perlu tahu ada rintangan meski gelap.
      // UI yang memutuskan apakah tawaran lampu tampil (isDark && !darkDismissed).

      // [2] Cek orientasi dari accelerometer setiap 30 frame
      if (_frameCount % 30 == 0) {
        // Kirim tilt ke TFLiteService untuk koreksi estimasi jarak
        TFLiteService.instance.updateTilt(
          CameraHealthService.instance.lastTiltAngle,
        );
        final health = CameraHealthService.instance.checkOrientation();
        if (!health.ok) {
          if (_healthMessage != health.message) {
            _healthMessage = health.message;
            notifyListeners();
            // Gunakan TtsQueue agar tunduk pada sistem 3-tier (Fix 1C)
            TtsQueue().speak(health.message, tier: SpeechTier.warning);
          }
          // Sengaja TIDAK `return` — ini kelas bug yang sama dengan kondisi
          // gelap (Fix 2.1). Ponsel yang miring membuat estimasi jarak kurang
          // akurat, tapi objek di depan tetap terlihat. Menghentikan inference
          // berarti menukar "peringatan yang agak meleset" dengan "tidak ada
          // peringatan sama sekali" — dan yang kedua jauh lebih berbahaya.
        } else if (_healthMessage != null) {
          _healthMessage = null;
          notifyListeners();
        }
      }

      // [3] Callback ke DetectionProvider jika ada subscriber
      onFrameReady?.call(image);
    });
  }

  /// Dismiss tawaran lampu tanpa mematikan deteksi (Fix 2.1).
  /// Dipanggil saat pengguna menekan "Lewati" di ContextualActionSlot.
  void dismissDarkOffer() {
    _darkDismissed = true;
    notifyListeners();
  }

  void stopStream() {
    if (!_streaming || _controller == null) return;
    _controller!.stopImageStream();
    _streaming = false;
    _cancelDarkWarningTimer();
    // Reset dark state saat stream berhenti
    if (_isDark) {
      _isDark = false;
      _darkDismissed = false;
      notifyListeners();
    }
  }

  // ── Dark warning timer (Fix 2.1) ─────────────────────────────────────────

  void _startDarkWarningTimer() {
    _cancelDarkWarningTimer();
    // Ucapkan peringatan pertama setelah 3 detik gelap
    _darkWarningTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDark) return;
      TtsQueue().speak(
        'Terlalu gelap, saya tidak bisa melihat jalur dengan jelas. '
        'Nyalakan lampu atau berhenti sejenak.',
        tier: SpeechTier.warning,
      );
      Vibration.vibrate(pattern: [0, 100, 100, 100]);
      // Ulangi setiap 30 detik selama masih gelap
      _darkWarningTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (!_isDark) {
            _cancelDarkWarningTimer();
            return;
          }
          TtsQueue().speak(
            'Masih gelap. Saya tetap berjalan tapi penglihatan terbatas.',
            tier: SpeechTier.info,
          );
        },
      );
    });
  }

  void _cancelDarkWarningTimer() {
    _darkWarningTimer?.cancel();
    _darkWarningTimer = null;
  }

  /// Nyalakan atau matikan flashlight secara eksplisit.
  /// Aman dipanggil saat stream berjalan maupun tidak.
  Future<void> setTorch(bool on) async {
    if (_controller == null || !_initialized) return;
    try {
      await _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _isTorchOn = on;
      notifyListeners();
    } catch (e) {
      debugPrint('[CameraProvider] setTorch($on) error: $e');
    }
  }

  /// Toggle flashlight — nyala → mati, mati → nyala.
  Future<void> toggleTorch() => setTorch(!_isTorchOn);

  /// Ambil foto dan kembalikan **path berkas**, bukan byte-nya.
  ///
  /// Dipakai OCR ML Kit, yang membaca langsung dari berkas. Untuk foto 4 MP,
  /// tidak membaca byte ke memori Dart menghemat satu salinan besar yang
  /// tidak pernah dipakai untuk apa pun.
  Future<String> captureFile() async {
    if (_capturing) throw Exception('Sedang capture, coba lagi');
    if (!_initialized || _controller == null) {
      throw Exception('Kamera belum siap');
    }

    _capturing = true;
    try {
      final wasStreaming = _streaming;
      if (wasStreaming) stopStream();

      final xfile = await _controller!.takePicture();

      if (wasStreaming) {
        await Future.delayed(const Duration(milliseconds: 200));
        startStream();
      }
      return xfile.path;
    } finally {
      _capturing = false;
    }
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
    _cancelDarkWarningTimer();
    CameraHealthService.instance.stopListening();
    _controller?.dispose();
    super.dispose();
  }
}
