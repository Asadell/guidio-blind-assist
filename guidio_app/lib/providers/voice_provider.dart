import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

enum VoiceState { idle, listening, processing, responding }

/// VoiceProvider — STT → intent routing → API call → TTS.
///
/// Fix dari doc 5 masalah 3 + 11:
/// - Logic intent ada di Provider (bukan di Screen)
/// - _processText() dipanggil dari onStatus callback (auto-trigger saat diam)
/// - _handleDescribeScene() lengkap: capture → detect → narasi Claude → speak
class VoiceProvider extends ChangeNotifier {
  final CameraProvider    _camera;
  final DetectionProvider _detection;

  VoiceProvider(this._camera, this._detection);

  final SpeechToText _stt      = SpeechToText();
  VoiceState         _state    = VoiceState.idle;
  String             _lastText = '';
  String             _response = '';

  VoiceState get state        => _state;
  bool       get isListening  => _state == VoiceState.listening;
  bool       get isProcessing => _state == VoiceState.processing;
  String     get lastText     => _lastText;
  String     get response     => _response;

  Future<void> init() async {
    await _stt.initialize(
      onStatus: _onSttStatus,
      onError:  (_) => _setState(VoiceState.idle),
    );
  }

  Future<void> startListening() async {
    if (_state != VoiceState.idle) return;
    _lastText = '';
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _lastText = result.recognizedWords;
        notifyListeners();
      },
      listenFor:    const Duration(seconds: 5),
      localeId:     'id_ID',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    if (!_stt.isListening) return;
    await _stt.stop();
  }

  /// Dipanggil otomatis saat STT selesai (timeout atau user diam).
  /// Fix masalah 11: bukan di Screen, tapi di sini.
  void _onSttStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_lastText.isNotEmpty) {
        _processText(_lastText);
      } else {
        _setState(VoiceState.idle);
      }
    }
  }

  /// Intent routing 2-lapis.
  ///
  /// Layer 1: keyword lokal (0ms latency, aman saat server offline).
  ///   Mendeteksi intent yang jelas tanpa ambiguitas.
  ///
  /// Layer 2: LLM routing via Claude Haiku (max_tokens=10, temperature=0.0).
  ///   Hanya dipanggil jika Layer 1 tidak match. Total latency < 1.5s.
  ///   Fallback ke describe_scene jika server gagal/timeout.
  Future<void> _processText(String text) async {
    _setState(VoiceState.processing);
    if (text.trim().isEmpty) {
      _setState(VoiceState.idle);
      return;
    }

    final lower = text.toLowerCase();

    // Layer 1: keyword lokal — langsung dispatch, tidak butuh server
    if (lower.contains('baca') ||
        lower.contains('tulisan') ||
        lower.contains('teks')) {
      await _respond('Membuka mode baca teks');
      _setState(VoiceState.idle);
      return;
    }
    if (lower.contains('pergi ke') ||
        lower.contains('navigasi ke') ||
        lower.contains('antar ke')) {
      await _respond('Membuka mode navigasi');
      _setState(VoiceState.idle);
      return;
    }

    // Layer 2: LLM routing untuk kasus ambigu
    final intent = await ServerService.instance.routeIntent(text);
    switch (intent) {
      case 'describe_scene':
        await _handleDescribeScene();
        break;
      case 'ocr':
        await _respond('Membuka mode baca teks');
        break;
      case 'navigation':
        await _respond('Membuka mode navigasi');
        break;
      case 'chitchat':
        await _handleChitchat();
        break;
      default:
        await _handleDescribeScene();
    }

    _setState(VoiceState.idle);
  }


  /// Fix dari doc 5 masalah 3 — implementasi penuh.
  Future<void> _handleDescribeScene() async {
    _response = 'Sedang menganalisis sekitar...';
    notifyListeners();
    await TTSService.instance.speak(_response);

    try {
      // 1. Capture JPEG dari kamera
      final jpeg = await _camera.captureJpeg();

      // 2. Detect via server (single-shot)
      final dets = await _detection.detectOnce(jpeg);

      // 3. Kirim deteksi (teks, BUKAN gambar) ke /api/narasi → Claude Haiku
      final narasi = await ServerService.instance.getNarasi(dets, context: 'voice');

      // 4. Speak kalimat natural dari Claude
      await _respond(narasi);
    } catch (e) {
      await _respond('Gagal menganalisis sekitar. Coba lagi.');
    }
  }

  Future<void> _handleChitchat() async {
    await _respond(
      'Maaf, saya hanya bisa membantu navigasi dan mendeskripsikan sekitar.',
    );
  }

  Future<void> _respond(String message) async {
    _response = message;
    _setState(VoiceState.responding);
    notifyListeners();
    await TTSService.instance.speak(message);
  }

  void _setState(VoiceState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }
}
