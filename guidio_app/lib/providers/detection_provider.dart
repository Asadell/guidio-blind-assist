import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';
import '../providers/inference_provider.dart';
import '../providers/camera_provider.dart';
import '../services/detection_filter.dart';
import '../services/haptic_service.dart';
import '../services/object_tracker.dart';
import '../services/server_service.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';

class DetectionProvider extends ChangeNotifier {
  final InferenceProvider _inferenceProvider;
  final CameraProvider    _cameraProvider;

  DetectionProvider(this._inferenceProvider, this._cameraProvider);

  final _filter  = DetectionFilter();
  final _tracker = ObjectTracker(); // SORT tracker untuk isApproaching
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
    _tracker.reset(); // bersihkan semua track saat mode berganti
    _detections = [];
    _riskZone   = null;
    notifyListeners();
  }

  /// TFLite path — inference langsung di isolate
  Future<void> _processFrameTflite(CameraImage image) async {
    if (!_realtimeActive) return;
    final raw = await TFLiteService.instance.runInference(image);

    // Jika frame tidak menghasilkan deteksi apapun, skip filter sepenuhnya.
    // PENTING: jangan panggil _filter.process([]) — currentLabels akan kosong
    // dan semua streak akan di-reset, termasuk objek yang masih terdeteksi
    // di frame berikutnya. Ini penyebab streak selalu stuck di 1/2.
    if (raw.isEmpty) return;

    // Debug: log hasil raw inference
    debugPrint(
      '[Detection] raw (${raw.length}): '
      '${raw.map((d) => '${d.labelEn} '
        '${d.distanceMeter.toStringAsFixed(1)}m '
        '(${d.dangerLevel})').join(' | ')}',
    );

    // Update SORT tracker — dapat TrackedObject dengan info isApproaching
    final tracked = _tracker.update(raw);

    // Enrich setiap Detection dengan isApproaching dari tracker-nya
    final enriched = raw.map((det) {
      final t = tracked.firstWhere(
        (t) => t.label == det.labelEn,
        orElse: () => TrackedObject(
          id: -1, label: '', cx: 0, cy: 0, w: 0, h: 0,
        ),
      );
      return det.copyWith(isApproaching: t.isApproaching);
    }).toList();

    final filtered = _filter.process(enriched);

    // Debug: log apa yang akhirnya lolos ke TTS
    if (filtered.isNotEmpty) {
      debugPrint(
        '[Detection] lolos filter (${filtered.length}): '
        '${filtered.map((d) => '${d.labelEn}(${d.dangerLevel})').join(' | ')}',
      );
    }

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
      // Haptic berdampingan TTS — primary signal di lingkungan bising
      HapticService.instance.fromDangerLevel(det.dangerLevel);
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
