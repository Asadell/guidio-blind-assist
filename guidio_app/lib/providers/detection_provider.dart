import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';
import '../providers/inference_provider.dart';
import '../providers/camera_provider.dart';
import '../services/detection_filter.dart';
import '../services/server_service.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';

class DetectionProvider extends ChangeNotifier {
  final InferenceProvider _inferenceProvider;
  final CameraProvider    _cameraProvider;

  DetectionProvider(this._inferenceProvider, this._cameraProvider);

  final _filter = DetectionFilter();
  StreamSubscription? _serverSub;
  bool _realtimeActive = false;

  List<Detection> _detections = [];
  RiskZone?       _riskZone;

  List<Detection> get detections => _detections;
  RiskZone?       get riskZone   => _riskZone;

  // ── Real-time Mode (Tuntun + Navigasi) ────────────────────────────────────

  void startRealtime() {
    if (_realtimeActive) return;
    _realtimeActive = true;
    _filter.reset();

    if (_inferenceProvider.realtimeEngine == InferenceEngine.tflite) {
      // TFLite path: pasang callback ke CameraProvider
      _cameraProvider.onFrameReady = _processFrameTflite;
    } else {
      // Server path: subscribe ke WebSocket stream
      _serverSub = ServerService.instance.detectionStream.listen(
        _handleServerResult,
      );
      // Pasang callback ke CameraProvider untuk kirim frame ke server
      _cameraProvider.onFrameReady = _processFrameServer;
    }
  }

  void stopRealtime() {
    _realtimeActive = false;
    _cameraProvider.onFrameReady = null;
    _serverSub?.cancel();
    _serverSub = null;
    _detections = [];
    _riskZone   = null;
    notifyListeners();
  }

  /// TFLite path — inference langsung di isolate
  Future<void> _processFrameTflite(CameraImage image) async {
    if (!_realtimeActive) return;
    final raw      = await TFLiteService.instance.runInference(image);
    final filtered = _filter.process(raw);
    _updateAndSpeak(filtered);
  }

  /// Server path — encode JPEG dan kirim ke WebSocket
  Future<void> _processFrameServer(CameraImage image) async {
    if (!_realtimeActive) return;
    try {
      final jpeg = await _cameraProvider.toJpeg(image);
      ServerService.instance.sendFrame(jpeg);
    } catch (_) {}
  }

  void _handleServerResult(ServerDetectionResult result) {
    if (!_realtimeActive) return;
    final filtered = _filter.process(result.detections);
    _riskZone = result.riskZone;
    _updateAndSpeak(filtered);
  }

  void _updateAndSpeak(List<Detection> filtered) {
    _detections = filtered;
    notifyListeners();

    for (final det in filtered) {
      TTSService.instance.speak(
        det.ttsMessage,
        interrupt: det.isCritical, // critical selalu interrupt TTS lain
      );
    }
  }

  // ── Single-shot untuk Voice Assistant ─────────────────────────────────────

  /// Detect sekali dari JPEG — tanpa stability filter (langsung hasilkan raw)
  Future<List<Detection>> detectOnce(Uint8List jpegBytes) async {
    return ServerService.instance.detectOnce(jpegBytes);
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}
