import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../core/speech/tts_queue.dart';
import '../services/camera_capture_service.dart';
import '../services/camera_health_service.dart';
import '../services/tflite_service.dart';

/// CameraProvider - kelola kamera, stream, dan capture.
///
/// Fix dari doc 5 masalah 8 + 12:
/// - Mutex _capturing untuk race condition
/// - On-device brightness check (plane Y) setiap frame
/// - YUV420 → JPEG konversi yang benar via package 'image'
class CameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  CameraProvider() {
    // Siklus hidup diurus DI SINI, di pemilik kameranya, bukan di enam layar
    // mode. Lihat catatan panjang di [didChangeAppLifecycleState].
    WidgetsBinding.instance.addObserver(this);
  }

  CameraController? _controller;
  bool _initialized = false;
  bool _streaming   = false;
  bool _capturing   = false; // mutex race condition fix
  int  _frameCount  = 0;

  String? _healthMessage; // pesan camera health untuk UI
  bool    _isDark         = false; // hasil on-device brightness check
  bool    _darkDismissed  = false; // true = jangan tampilkan tawaran lampu lagi
  bool    _isTorchOn      = false; // status flashlight

  // Fix 2.1: Timer peringatan gelap berkala - ucap setiap 30 detik jika masih gelap
  Timer?   _darkWarningTimer;

  /// Sejak kapan kondisi gelap berlangsung - dibaca layar/telemetri untuk
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

  /// True saat pengguna menekan "Lewati" - tawaran lampu tidak tampil,
  /// TAPI deteksi tetap berjalan (Fix 2.1).
  bool get darkDismissed  => _darkDismissed;

  /// True saat flashlight sedang menyala.
  bool get isTorchOn => _isTorchOn;

  // Callback - dipanggil dari CameraProvider ketika frame siap
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

  /// Resolusi yang sedang aktif. Null berarti kamera belum disiapkan.
  CapturePreset? _activePreset;
  CapturePreset? get activePreset => _activePreset;

  /// Siapkan kamera pada [preset] yang diminta.
  ///
  /// Aman dipanggil berulang: kalau kamera sudah hidup pada preset yang sama,
  /// metode ini tidak melakukan apa-apa. Kalau presetnya BERBEDA, controller
  /// dibuat ulang - itulah yang membuat satu kamera bisa melayani dua
  /// kebutuhan yang bertentangan.
  ///
  /// Kenapa dua preset, bukan satu:
  ///
  /// - **Mode aliran** (deteksi, navigasi, kenali uang) menjalankan inferensi
  ///   pada SETIAP frame, sekitar delapan kali per detik. Di 1280x720 itu
  ///   tiga kali lebih banyak pixel per frame dibanding 640x480, dan di HP
  ///   mid-low selisih itu terasa langsung sebagai frame yang terlewat - di
  ///   mode yang justru menyangkut keselamatan.
  /// - **Mode foto** (baca teks, deskripsi sekitar, cari objek) mengambil
  ///   satu gambar lalu berhenti. Di sini resolusi menentukan batas atas
  ///   kualitas hasilnya, dan 640x480 memang tidak menyisakan cukup pixel
  ///   untuk huruf kecil: berapa pun tajamnya foto itu, teksnya tetap tidak
  ///   akan terbaca.
  ///
  /// Memakai satu preset berarti memilih salah satu untuk dikorbankan.
  /// Biayanya adalah controller dibuat ulang saat berpindah antar dua
  /// kelompok mode, dan itu dibayar sekali per perpindahan, bukan per frame.
  Future<void> initCamera({
    CapturePreset preset = CapturePreset.realtime,
  }) async {
    if (_initialized && _activePreset == preset && _controller != null) {
      return;
    }

    // Request camera permission sebelum initialize - mencegah CameraAccessDenied
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

      // Bongkar controller lama sebelum membangun yang baru. Stream harus
      // dihentikan lebih dulu: membuang controller yang masih mengalirkan
      // frame membuat callback menembak ke objek yang sudah tidak ada.
      //
      // `wasStreaming` dicatat supaya alirannya bisa DINYALAKAN LAGI di akhir.
      // Sebelumnya tidak: siapa pun yang mengganti preset di tengah mode
      // aliran - dan itu persis yang dilakukan "deskripsikan suasana" -
      // meninggalkan kamera mati tanpa ada yang menyalakannya kembali.
      // Layarnya tetap terlihat normal, `onFrameReady` tetap terpasang, tapi
      // tidak ada satu frame pun yang datang lagi. Di Mode Deteksi itu berarti
      // berhenti memperingatkan rintangan tanpa sepatah kata; di Mode Navigasi
      // lebih buruk, karena frame terakhir membeku di `_latestFrame` dan
      // panduan terus disusun dari pemandangan yang sudah lewat.
      final wasStreaming = _streaming;
      final previous = _controller;
      if (previous != null) {
        if (_streaming) {
          try {
            await previous.stopImageStream();
          } catch (e) {
            debugPrint('[CameraProvider] stopImageStream saat ganti preset: $e');
          }
          _streaming = false;
        }
        _initialized = false;
        _controller = null;
        // Diumumkan SEBELUM controller lama dibuang, lalu ditunggu satu frame.
        //
        // `CameraPreview` mendaftarkan listener pada controller-nya dan
        // `CameraStage` membaca `controller.value.aspectRatio` saat build.
        // Keduanya melempar begitu controller itu di-dispose. Membuangnya di
        // sini tanpa memberi pohon widget satu kesempatan menggambar ulang
        // berarti layar yang masih memegangnya akan rebuild di atas objek yang
        // sudah mati - "A CameraController was used after being disposed",
        // kotak merah yang berkedip tepat saat mode berpindah ke preset lain.
        //
        // `notifyListeners()` saja tidak cukup: ia hanya menjadwalkan rebuild
        // untuk frame berikutnya, sementara baris di bawahnya berjalan lebih
        // dulu. `endOfFrame` yang membuat urutannya benar.
        notifyListeners();
        await SchedulerBinding.instance.endOfFrame;
        await previous.dispose();
      }

      _controller = CameraController(
        cameras.first,
        preset.resolution,
        enableAudio:    false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _activePreset = preset;
      CameraHealthService.instance.startListening();
      _initialized = true;
      _setError(false);
      notifyListeners();

      // Senter ikut dipulihkan, karena controller baru selalu lahir dengan
      // lampu MATI.
      //
      // Tanpa ini, `_isTorchOn` bertahan `true` sementara lampunya sudah
      // padam - dan tidak ada satu pun yang memberi tahu. Jalurnya bukan
      // teoretis: "deskripsikan suasana" mengganti preset di tengah mode
      // aliran, jadi pengguna yang menyalakan lampu di ruang gelap lalu
      // meminta deskripsi akan menemukan lampunya mati, tombolnya masih
      // bertuliskan "Matikan Lampu", dan menekannya tidak mengubah apa pun.
      //
      // Kalau pemulihannya gagal, statusnya diturunkan supaya layar dan
      // lampu tidak saling membantah.
      if (_isTorchOn) {
        _isTorchOn = false;
        final restored = await setTorch(true);
        if (!restored) {
          debugPrint('[CameraProvider] senter tidak bisa dipulihkan setelah '
              'kamera dibangun ulang');
          notifyListeners();
        }
      }

      // Nyalakan lagi aliran frame kalau tadi memang sedang mengalir.
      // `onFrameReady` sengaja tidak disentuh - pelanggannya tetap yang sama,
      // hanya controller di bawahnya yang berganti.
      if (wasStreaming) startStream();
    } catch (e) {
      // Kamera gagal disiapkan = mode utama benar-benar buta. Kegagalan yang
      // ditelan diam-diam di sini akan tampil sebagai aplikasi yang terlihat
      // normal tapi tidak pernah memperingatkan apa pun.
      debugPrint('[CameraProvider] initCamera error: $e');
      _initialized = false;
      _activePreset = null;
      // Controller lamanya sudah dibuang, jadi lampunya pasti padam. Status
      // yang tertinggal menyala akan membuat tombol menawarkan "Matikan
      // Lampu" untuk lampu yang sudah mati.
      _isTorchOn = false;
      _setError(true);
    }
  }

  void startStream() {
    if (!_initialized || _streaming || _controller == null) return;
    _streaming   = true;
    _frameCount  = 0;

    // Kegagalan membuka aliran tidak boleh menguap sebagai error asinkron yang
    // tidak tertangkap: `_streaming` harus dikembalikan ke false, kalau tidak
    // setiap `startStream()` berikutnya berhenti di penjaga di atas dan
    // kamera tidak akan pernah mengalir lagi selama aplikasi hidup.
    _controller!.startImageStream(_onFrame).catchError((Object e) {
      debugPrint('[CameraProvider] startImageStream error: $e');
      _streaming = false;
      _setError(true);
    });
  }

  void _onFrame(CameraImage image) {
    {
      // Skip frame jika sedang capture (race condition fix)
      if (_capturing) return;

      _frameCount++;

      // [1] On-device brightness check setiap frame - O(100) sangat ringan
      final tooDark = _isTooDark(image);
      if (tooDark != _isDark) {
        _isDark = tooDark;
        if (tooDark) {
          // Mulai timer peringatan gelap (Fix 2.1)
          _darkSince = DateTime.now();
          _startDarkWarningTimer();
        } else {
          // Kondisi terang kembali - reset semua
          _cancelDarkWarningTimer();
          _darkDismissed = false;
          _darkSince = null;
        }
        // Notifikasi UI: ContextualActionSlot tampil/sembunyikan tawaran lampu
        notifyListeners();
      }
      // Fix 2.1: JANGAN return di sini - inference tetap berjalan di kondisi gelap.
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
          // Sengaja TIDAK `return` - ini kelas bug yang sama dengan kondisi
          // gelap (Fix 2.1). Ponsel yang miring membuat estimasi jarak kurang
          // akurat, tapi objek di depan tetap terlihat. Menghentikan inference
          // berarti menukar "peringatan yang agak meleset" dengan "tidak ada
          // peringatan sama sekali" - dan yang kedua jauh lebih berbahaya.
        } else if (_healthMessage != null) {
          _healthMessage = null;
          notifyListeners();
        }
      }

      // [3] Callback ke DetectionProvider jika ada subscriber
      onFrameReady?.call(image);
    }
  }

  /// Dismiss tawaran lampu tanpa mematikan deteksi (Fix 2.1).
  /// Dipanggil saat pengguna menekan "Lewati" di ContextualActionSlot.
  void dismissDarkOffer() {
    _darkDismissed = true;
    notifyListeners();
  }

  /// Hentikan aliran frame. **Mengembalikan Future yang benar-benar selesai
  /// saat alirannya berhenti**, bukan saat perintah berhentinya dikirim.
  ///
  /// Bedanya menentukan di [_capture]: `takePicture()` yang dipanggil sementara
  /// aliran masih hidup gagal di sebagian perangkat Android. Versi sebelumnya
  /// membuang Future ini, jadi pemotretan berpacu dengan penghentian aliran dan
  /// kalah sesekali - persis kelas kegagalan sesekali yang paling sulit
  /// ditelusuri karena tidak pernah muncul di emulator.
  Future<void> stopStream() async {
    if (!_streaming || _controller == null) return;
    // Ditandai berhenti LEBIH DULU supaya `_onFrame` yang masih menyusul
    // selama penghentian tidak lagi memicu apa pun.
    _streaming = false;
    try {
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('[CameraProvider] stopImageStream error: $e');
    }
    _cancelDarkWarningTimer();
    // Reset dark state saat stream berhenti
    if (_isDark) {
      _isDark = false;
      _darkDismissed = false;
      _darkSince = null;
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
  ///
  /// Mengembalikan **false kalau lampunya tidak jadi berubah**, dan itu yang
  /// paling penting dari fungsi ini.
  ///
  /// Sebelumnya ia `void`, dan kedua jalur gagalnya - kamera belum siap, dan
  /// `setFlashMode` melempar - berakhir diam-diam. Pemanggilnya tetap
  /// mengucapkan "Lampu dinyalakan." karena tidak punya cara tahu bahwa
  /// tidak ada yang menyala. Untuk pengguna tunanetra itu bukan pesan yang
  /// kurang tepat, melainkan pesan yang **berbohong** tentang satu-satunya
  /// hal yang tidak bisa dia periksa sendiri: apakah sekitarnya sudah terang.
  Future<bool> setTorch(bool on) async {
    if (_controller == null || !_initialized) {
      debugPrint('[CameraProvider] setTorch($on) diabaikan: kamera belum siap');
      return false;
    }
    try {
      await _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _isTorchOn = on;
      notifyListeners();
      return true;
    } catch (e) {
      // Sebagian perangkat menolak `torch` saat aliran frame berjalan, dan
      // sebagian lagi tidak punya lampu sama sekali. Apa pun sebabnya,
      // status yang dicatat harus tetap sama dengan lampu yang sebenarnya.
      debugPrint('[CameraProvider] setTorch($on) error: $e');
      return false;
    }
  }

  /// Toggle flashlight - nyala → mati, mati → nyala.
  Future<bool> toggleTorch() => setTorch(!_isTorchOn);

  /// Ambil foto dan kembalikan **path berkas**, bukan byte-nya.
  ///
  /// Dipakai OCR ML Kit, yang membaca langsung dari berkas. Untuk foto 4 MP,
  /// tidak membaca byte ke memori Dart menghemat satu salinan besar yang
  /// tidak pernah dipakai untuk apa pun.
  Future<String> captureFile({bool gateQuality = true}) async {
    final result = await _capture(gateQuality: gateQuality);
    final path = result.file?.path;
    if (path == null) throw Exception('Gagal mengambil foto');
    return path;
  }

  /// Capture JPEG untuk OCR / Voice Assistant.
  /// Mutex: jika sedang capture, lempar exception (jangan double-capture).
  ///
  /// Fix dari doc 5 masalah 8.
  Future<Uint8List> captureJpeg({bool gateQuality = true}) async {
    final result = await _capture(gateQuality: gateQuality);
    final bytes = result.bytes;
    if (bytes == null) throw Exception('Gagal mengambil foto');
    return bytes;
  }

  /// Hasil penilaian foto terakhir - dibaca layar untuk menampilkan status
  /// tanpa harus mengulang perhitungannya.
  CaptureResult? _lastCapture;
  CaptureResult? get lastCapture => _lastCapture;

  /// Jalur tunggal pengambilan foto, dipakai [captureFile] dan [captureJpeg].
  ///
  /// Menggantikan `takePicture()` telanjang dengan [CameraCaptureService], dan
  /// itu tiga perubahan sekaligus:
  ///
  /// 1. **Fokus dan eksposur dikunci lebih dulu, setelah diberi waktu
  ///    konvergen.** `takePicture()` tidak menunggu autofocus selesai, jadi
  ///    di HP mid-low foto sering diambil persis di tengah lensa bergerak.
  /// 2. **Beberapa frame diambil, yang paling tajam dipilih.**
  /// 3. **Foto yang tetap tidak layak tidak dikirim.** Pengguna diberi
  ///    instruksi konkret lewat TTS alih-alih menunggu hasil dari foto yang
  ///    memang tidak mungkin terbaca.
  ///
  /// Lapis ketiga itu yang paling menentukan: buram menghilangkan informasi
  /// secara permanen, jadi tidak ada penajaman di server yang bisa
  /// mengembalikannya. Satu-satunya perbaikan nyata adalah foto ulang, dan
  /// itu cuma bisa diminta dari sini.
  ///
  /// [gateQuality] false berarti byte-nya tetap dikembalikan apa pun
  /// hasilnya - dipakai jalur yang lebih suka mencoba daripada menolak.
  Future<CaptureResult> _capture({required bool gateQuality}) async {
    if (_capturing) throw Exception('Sedang capture, coba lagi');
    final controller = _controller;
    if (!_initialized || controller == null) {
      throw Exception('Kamera belum siap');
    }

    _capturing = true;
    try {
      final wasStreaming = _streaming;
      // Ditunggu sampai benar-benar berhenti - lihat catatan di [stopStream].
      if (wasStreaming) await stopStream();

      final result = await CameraCaptureService.instance.captureSharpest(
        controller,
        // Instruksi perbaikan ("tahan ponsel lebih diam") harus terdengar
        // sebelum pengguna menekan tombol lagi, jadi tier Warning: boleh
        // memotong narasi Info, tapi tidak menyalip peringatan bahaya.
        onFeedback: (msg) =>
            TtsQueue().speak(msg, tier: SpeechTier.warning),
      );
      _lastCapture = result;

      if (wasStreaming) {
        // Beri kamera sedikit waktu untuk settle sebelum restart stream
        await Future.delayed(const Duration(milliseconds: 200));
        startStream();
      }

      if (gateQuality && !result.isUsable) {
        // Pesannya sudah dibacakan lewat onFeedback; melemparnya di sini
        // menghentikan unggahan tanpa perlu tiap pemanggil memeriksa sendiri.
        throw CaptureRejected(result);
      }

      return result;
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

    // Encode ke JPEG quality 70 - cukup untuk YOLO server, tidak terlalu besar
    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 70));
  }

  /// On-device brightness check - sample 100 piksel dari plane Y (YUV420).
  /// O(100) sangat ringan, aman dipanggil setiap frame.
  ///
  /// Fix dari doc 5 masalah 12.
  bool _isTooDark(CameraImage image) {
    final yPlane = image.planes[0].bytes;
    final step   = yPlane.length ~/ 100;
    if (step <= 0) return false;

    // Pembaginya adalah jumlah sampel yang BENAR-BENAR diambil, bukan 100.
    // `step` dibulatkan ke bawah, jadi jumlah putaran hampir selalu sedikit
    // lebih banyak dari 100 dan membagi dengan 100 menaikkan rata-ratanya -
    // artinya frame yang sesungguhnya gelap bisa lolos dari ambang dan
    // peringatan "terlalu gelap" tidak pernah muncul.
    int total = 0;
    int samples = 0;
    for (int i = 0; i < yPlane.length; i += step) {
      total += yPlane[i] & 0xFF;
      samples++;
    }
    if (samples == 0) return false;
    final avgBrightness = total / samples;
    return avgBrightness < 30; // < 30/255 = sangat gelap
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelDarkWarningTimer();
    CameraHealthService.instance.stopListening();
    _controller?.dispose();
    super.dispose();
  }

  // ── Siklus hidup aplikasi ───────────────────────────────────────────────

  /// Preset yang sedang dipakai saat aplikasi ditinggalkan, dan apakah
  /// frame sedang mengalir. Keduanya yang dipulihkan saat kembali.
  CapturePreset? _presetSebelumSuspend;
  bool _mengalirSebelumSuspend = false;
  bool _torchSebelumSuspend = false;
  bool _suspended = false;

  /// Sedang membangun ulang kamera sesudah kembali dari latar belakang.
  /// Menahan panggilan kedua yang datang saat yang pertama belum selesai.
  bool _memulihkan = false;

  /// Kamera dilepas saat aplikasi ditinggalkan, dan dibangun ulang saat
  /// kembali.
  ///
  /// ## Kenapa ini wajib ada, dan kenapa tempatnya di sini
  ///
  /// Android mengambil kembali kamera dari aplikasi yang tidak di depan.
  /// Yang TIDAK terjadi dengan sendirinya adalah pemberitahuannya: `_streaming`
  /// dan `_initialized` tetap `true`, `_controller` tetap ada, dan
  /// `CameraPreview` tetap terpasang. Dari dalam kode, semuanya tampak sehat.
  ///
  /// Akibatnya persis bug yang dilaporkan: pengguna meninggalkan aplikasi
  /// tanpa menutupnya, lalu kembali, dan mode Navigasi berhenti bekerja.
  /// Layar tetap terlihat normal, tapi tidak ada satu frame pun yang datang.
  /// Dua penjaga di awal metode yang menutup jalan keluarnya:
  ///
  ///   * `initCamera` pulang lebih awal karena `_initialized` masih true dan
  ///     presetnya sama;
  ///   * `startStream` pulang lebih awal karena `_streaming` masih true.
  ///
  /// Jadi memanggil keduanya lagi saat kembali - yang memang dilakukan
  /// `TuntunScreen` - tidak memperbaiki apa pun. Keduanya no-op.
  ///
  /// Tempatnya di sini, bukan di layar mode, karena enam mode memakai kamera
  /// yang sama dan hanya satu dari mereka yang sempat menuliskan penanganan
  /// resume - itu pun yang tidak bekerja. Menyalinnya ke lima layar lain
  /// berarti lima salinan yang bisa menyimpang satu per satu, dan mode yang
  /// mati sesudah pengguna kembali adalah kegagalan yang paling sulit
  /// disadari: tidak ada pesan galat, tidak ada layar yang berubah, cuma
  /// aplikasi yang berhenti menjaga tanpa mengatakannya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // `inactive` SENGAJA TIDAK melepas kamera.
      //
      // Di Android ia berarti "jendela kehilangan fokus", bukan "aplikasi
      // ditinggalkan". Ia menyala untuk hal-hal yang berlangsung sedetik dan
      // tidak menyentuh kamera sama sekali: bilah notifikasi ditarik turun,
      // notifikasi melayang, panel volume, dialog sistem, pratinjau daftar
      // aplikasi.
      //
      // Ini bukan kehati-hatian teoretis. Di log perangkat, tepat sebelum
      // kamera mati saat pengguna baru membuka Mode Navigasi:
      //
      //     MSG_WINDOW_FOCUS_CHANGED 0 1
      //     ...
      //     [CameraProvider] kamera dilepas, aplikasi ke latar belakang
      //
      // Aplikasinya tidak pernah ke latar belakang. Yang hilang cuma fokus
      // jendela, dan `inactive` di daftar ini membongkar kamera yang masih
      // sepenuhnya milik kita. Layarnya tidak menghitam - preview-nya saja
      // yang mati - jadi dari luar terlihat seperti kamera yang rusak sendiri.
      //
      // Perpindahan yang SUNGGUHAN ke latar belakang selalu melewati `paused`
      // sesudah `inactive`, jadi tidak ada yang terlewat dengan menunggu.
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_lepasUntukLatarBelakang());
      case AppLifecycleState.resumed:
        unawaited(_bangunUlangSetelahKembali());
    }
  }

  /// Dipanggil saat frame yang sudah tersimpan di layar TIDAK BOLEH dipakai
  /// lagi - kamera dilepas, dan frame terakhir menggambarkan pemandangan
  /// sebelum aplikasi ditinggalkan.
  ///
  /// Dua layar menyimpan frame terakhirnya sendiri (`_latestFrame` di
  /// `navigasi_screen.dart` dan `find_object_screen.dart`). Tanpa
  /// pemberitahuan ini, Mode Navigasi akan terus menyusun panduan dari
  /// pemandangan yang membeku - dan pengguna yang baru kembali ke aplikasi
  /// mendengar arahan tentang jalan yang sudah dia tinggalkan beberapa menit
  /// lalu. Untuk alat bantu jalan, panduan yang basi lebih berbahaya
  /// daripada panduan yang tidak ada.
  void Function()? onFramesInvalidated;

  Future<void> _lepasUntukLatarBelakang() async {
    if (_suspended) return;
    _suspended = true;

    // `_activePreset` sengaja dibaca dengan cadangan. Kalau pengguna
    // meninggalkan aplikasi lagi TEPAT saat pembangunan ulang sedang
    // berjalan, presetnya sudah dinolkan di sana - dan kehilangan nilainya di
    // sini berarti kamera tidak pernah dibangun ulang lagi sesudahnya.
    _presetSebelumSuspend = _activePreset ?? _presetSebelumSuspend;
    _mengalirSebelumSuspend = _streaming || _mengalirSebelumSuspend;
    _torchSebelumSuspend = _isTorchOn;

    if (_controller == null) return;

    await stopStream();

    // Diberitahukan SESUDAH aliran berhenti, supaya tidak ada frame baru yang
    // menyusul mengisi ulang apa yang barusan dikosongkan.
    onFramesInvalidated?.call();

    final lama = _controller;
    _controller = null;
    _initialized = false;
    _isTorchOn = false;
    _cancelDarkWarningTimer();

    // Diumumkan SEBELUM controller dibuang, lalu ditunggu satu frame - alasan
    // yang sama dengan pergantian preset di [initCamera]: `CameraPreview` dan
    // `CameraStage` melempar begitu controller yang mereka pegang di-dispose.
    notifyListeners();
    try {
      await SchedulerBinding.instance.endOfFrame;
    } catch (_) {
      // Tidak ada binding (uji unit) - tidak ada pohon widget yang perlu
      // digambar ulang, jadi tidak ada yang perlu ditunggu.
    }
    try {
      await lama?.dispose();
    } catch (e) {
      debugPrint('[CameraProvider] dispose saat ke latar belakang: $e');
    }
    debugPrint('[CameraProvider] kamera dilepas, aplikasi ke latar belakang');
  }

  Future<void> _bangunUlangSetelahKembali() async {
    if (!_suspended || _memulihkan) return;
    _memulihkan = true;
    try {
      final preset = _presetSebelumSuspend;
      _suspended = false;
      if (preset == null) return;

      // Izin bisa saja dicabut dari Pengaturan sementara aplikasi di latar
      // belakang. Diperiksa TANPA meminta: memunculkan dialog izin di detik
      // pengguna kembali ke aplikasi adalah kejutan, dan layar mode sudah
      // punya kartu izinnya sendiri untuk keadaan itu.
      if (!await Permission.camera.isGranted) {
        debugPrint('[CameraProvider] izin kamera dicabut selama di latar '
            'belakang - kamera tidak dibangun ulang');
        _initialized = false;
        notifyListeners();
        return;
      }

      // `_activePreset` dinolkan supaya penjaga "sudah siap" di awal
      // [initCamera] tidak memulangkan panggilan ini.
      _activePreset = null;
      _isTorchOn = _torchSebelumSuspend;
      await initCamera(preset: preset);

      // Aliran frame dinyalakan lagi kalau tadi memang mengalir.
      //
      // `initCamera` punya pemulihan alirannya sendiri, tapi ia membaca
      // `_streaming` yang sudah dimatikan `stopStream` di atas. Jadi yang
      // dipakai di sini catatan terpisah, bukan nilai yang sudah berubah.
      if (_mengalirSebelumSuspend && _initialized) {
        startStream();
      }
      debugPrint('[CameraProvider] kamera dibangun ulang '
          '(preset=$preset, aliran=$_mengalirSebelumSuspend)');
    } finally {
      _memulihkan = false;
    }

    // Pengguna sempat pergi lagi selama pembangunan ulang berjalan. Tanpa
    // pemeriksaan ini kameranya tetap hidup di latar belakang, karena
    // `_lepasUntukLatarBelakang` tadi menemukan `_controller` masih null lalu
    // pulang tanpa melepas apa pun.
    if (_suspended) {
      _suspended = false;
      await _lepasUntukLatarBelakang();
    }
  }
}


/// Dua kebutuhan resolusi yang bertentangan, dinamai supaya pilihannya
/// terlihat di tempat pemakaian alih-alih terkubur sebagai konstanta.
enum CapturePreset {
  /// Mode yang menjalankan inferensi pada setiap frame. 640x480 sudah cukup
  /// untuk deteksi objek dan segmentasi jalur, dan menahan beban tetap ringan
  /// di HP mid-low.
  realtime(ResolutionPreset.medium),

  /// Mode yang mengambil satu foto lalu berhenti. 1280x720 memberi cukup
  /// pixel untuk huruf kecil; lebih tinggi dari ini tidak menambah akurasi
  /// tapi memperlambat setiap langkah sesudahnya - dekode, penilaian
  /// ketajaman, dan unggahan.
  capture(ResolutionPreset.high);

  const CapturePreset(this.resolution);
  final ResolutionPreset resolution;
}

/// Foto ditolak gerbang kualitas sebelum sempat dikirim.
///
/// Pesan untuk pengguna SUDAH dibacakan saat pengecualian ini dilempar, jadi
/// pemanggil cukup berhenti dengan tenang. Membacakannya sekali lagi di
/// penangkap error justru membuat pengguna mendengar instruksi yang sama dua
/// kali dan mengira dia salah dengar yang pertama.
class CaptureRejected implements Exception {
  final CaptureResult result;
  const CaptureRejected(this.result);

  String get message => result.message;

  @override
  String toString() => 'CaptureRejected(${result.verdict.name}): $message';
}
