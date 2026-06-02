import 'package:flutter/foundation.dart';
import '../services/tflite_service.dart';
import '../services/server_service.dart';

enum InferenceEngine { tflite, server }

class InferenceProvider extends ChangeNotifier {
  bool _tfliteReady = false;
  bool _serverReady = false;
  bool _initialized = false;

  bool get tfliteReady => _tfliteReady;
  bool get serverReady => _serverReady;
  bool get isReady     => _tfliteReady || _serverReady;

  /// Engine untuk real-time (Mode Tuntun, Navigasi):
  /// TFLite jika ready, server sebagai fallback.
  InferenceEngine get realtimeEngine =>
      _tfliteReady ? InferenceEngine.tflite : InferenceEngine.server;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load TFLite dan connect server secara parallel
    // GPS/koordinat tidak dipakai (sesuai request user)
    final results = await Future.wait([
      TFLiteService.instance.tryLoad(),
      _tryConnectServer(),
    ]);

    _tfliteReady = results[0];
    _serverReady = results[1];
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _tryConnectServer() async {
    try {
      // Connect tanpa koordinat GPS (risk zone tidak aktif, fitur lain tetap jalan)
      await ServerService.instance.connect();
      return true;
    } catch (_) {
      return false;
    }
  }

  void onServerConnected()    { _serverReady = true;  notifyListeners(); }
  void onServerDisconnected() { _serverReady = false; notifyListeners(); }
}
