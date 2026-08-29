import 'package:flutter/foundation.dart';
import '../services/camera_intrinsics.dart';
import '../services/tflite_service.dart';
import '../services/server_service.dart';

/// InferenceProvider - kesiapan model on-device dan server saat boot.
///
/// Sejak jalur deteksi via WebSocket dihapus, tidak ada lagi "engine yang
/// dipilih": Mode Deteksi Objek selalu on-device. Server hanya dibutuhkan
/// untuk yang memang tidak ada di perangkat (Cari Objek, Deskripsi Sekitar,
/// dan segmentasi jalur sebagai cadangan), jadi kesiapannya diperiksa lewat
/// `/health` - bukan dengan membuka soket deteksi yang tidak akan dipakai.
class InferenceProvider extends ChangeNotifier {
  bool _tfliteReady = false;
  bool _serverReady = false;
  bool _initialized = false;

  bool get tfliteReady => _tfliteReady;
  bool get serverReady => _serverReady;

  /// Deteksi rintangan siap. Ini satu-satunya yang menentukan mode utama
  /// bisa berjalan - server tidak lagi jadi cadangannya.
  bool get isReady => _tfliteReady;

  Future<void> initialize() async {
    if (_initialized) return;

    // Intrinsik lensa dibaca sekali di sini: estimasi jarak butuh panjang
    // fokus perangkat ini, bukan rata-rata semua ponsel. Kegagalannya tidak
    // memblokir apa pun - nilainya jatuh ke fallback.
    final results = await Future.wait([
      TFLiteService.instance.tryLoad(),
      _probeServer(),
      CameraIntrinsics.instance.load().then((_) => true),
    ]);

    _tfliteReady = results[0];
    _serverReady = results[1];
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _probeServer() async {
    try {
      final health = await ServerService.instance.healthAt(
        ServerService.instance.host,
        timeout: const Duration(seconds: 2),
      );
      return health != null;
    } catch (_) {
      return false;
    }
  }

  void onServerConnected()    { _serverReady = true;  notifyListeners(); }
  void onServerDisconnected() { _serverReady = false; notifyListeners(); }
}
