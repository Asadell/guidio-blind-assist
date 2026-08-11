import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

/// VoiceState — bagian 11 IMPLEMENTASI.md (AS-01..AS-25). Granular dari 4
/// fase asli (idle/listening/processing/responding) supaya tiap sub-state
/// yang dipisah dokumen (mendengarkan vs tanpa suara vs berisik, proses
/// lokal vs LLM, dst.) punya representasi sendiri.
enum VoiceState {
  idle, // AS-01
  listening, // AS-03
  noSpeech, // AS-04
  tooNoisy, // AS-05
  transcribing, // AS-06
  transcribeFailed, // AS-07
  processingLocal, // AS-08
  processingLlm, // AS-09
  responded, // AS-10
  fallbackActive, // AS-14
  allFailed, // AS-15
  unrecognized, // AS-18
  ambiguous, // AS-19
}

class ChatTurn {
  final bool isUser;
  final String text;
  final DateTime at;
  ChatTurn({required this.isUser, required this.text}) : at = DateTime.now();
}

/// VoiceProvider — STT → intent routing → API call → TTS.
///
/// Intent routing 2-lapis dipertahankan dari implementasi awal:
/// - Layer 1: keyword lokal (0ms latency, aman offline) via [CommandParser].
/// - Layer 2: LLM routing via ServerService.routeIntent, hanya dipanggil
///   kalau Layer 1 tidak match.
class VoiceProvider extends ChangeNotifier {
  final CameraProvider _camera;
  final DetectionProvider _detection;

  VoiceProvider(this._camera, this._detection);

  final SpeechToText _stt = SpeechToText();
  VoiceState _state = VoiceState.idle;
  String _lastText = '';
  String _response = '';
  int _consecutiveFailures = 0;

  final List<ChatTurn> _history = [];
  List<ChatTurn> get history => List.unmodifiable(_history);
  DateTime? _lastActivity;

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isProcessing => _state == VoiceState.transcribing || _state == VoiceState.processingLocal || _state == VoiceState.processingLlm;
  String get lastText => _lastText;
  String get response => _response;

  /// AS-18 — dua tebakan terdekat saat perintah tidak dikenali.
  List<VoiceIntent> _suggestions = [];
  List<VoiceIntent> get suggestions => _suggestions;
  String _heardRaw = '';
  String get heardRaw => _heardRaw;

  /// Dipasang layar untuk menjalankan efek suara/pindah mode — menjaga
  /// provider ini tidak bergantung BuildContext, pola sama dengan mode lain.
  void Function(String text)? onSpeak;
  void Function(VoiceIntent modeIntent)? onModeChangeRequested;
  void Function()? onAllFeaturesFailed;

  Future<void> init() async {
    await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (_) => _setState(VoiceState.noSpeech),
    );
  }

  /// AS-23 — riwayat kedaluwarsa setelah 15 menit tanpa aktivitas.
  bool checkAndExpireHistory() {
    if (_history.isEmpty || _lastActivity == null) return false;
    if (DateTime.now().difference(_lastActivity!) > const Duration(minutes: 15)) {
      _history.clear();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> startListening() async {
    if (_state != VoiceState.idle &&
        _state != VoiceState.responded &&
        _state != VoiceState.unrecognized &&
        _state != VoiceState.ambiguous &&
        _state != VoiceState.noSpeech &&
        _state != VoiceState.transcribeFailed &&
        _state != VoiceState.allFailed) {
      return;
    }
    _lastText = '';
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _lastText = result.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 5),
      localeId: 'id_ID',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    if (!_stt.isListening) return;
    await _stt.stop();
  }

  void _onSttStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_lastText.trim().isNotEmpty) {
        _processText(_lastText);
      } else {
        _setState(VoiceState.noSpeech);
      }
    }
  }

  Future<void> _processText(String text) async {
    _lastActivity = DateTime.now();
    _heardRaw = text;
    _history.add(ChatTurn(isUser: true, text: text));
    // AS-06 — jeda pendek "mentranskrip", tanpa kata "memproses".
    _setState(VoiceState.transcribing);
    await Future.delayed(const Duration(milliseconds: 250));

    final command = CommandParser.parse(text);

    if (!command.recognized) {
      if (command.suggestions.length >= 2) {
        // AS-19 — ambigu, pertanyaan pilihan dua.
        _suggestions = command.suggestions;
        _setState(VoiceState.ambiguous);
        _respond(
          'Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}, atau ${command.suggestions[1].spokenLabel}?',
          save: false,
        );
        return;
      }
      if (command.suggestions.isNotEmpty) {
        // AS-18 — tidak dikenali, satu tebakan tersedia.
        _suggestions = command.suggestions;
        _setState(VoiceState.unrecognized);
        _respond('Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}?', save: false);
        return;
      }
      await _handleDescribeScene();
      return;
    }

    if (command.intent!.isModeChange) {
      // AS-17 — perintah ganti mode.
      _consecutiveFailures = 0;
      onModeChangeRequested?.call(command.intent!);
      _respond('Baik, mode ${command.intent!.spokenLabel}.', save: false);
      return;
    }

    switch (command.intent!) {
      case VoiceIntent.helpWhat:
        await _handleLocal('Aku bisa mendeteksi objek, membaca teks, mengenali uang, menuntun jalan, mencari barang, atau menjawab pertanyaan tentang sekitarmu.');
        break;
      case VoiceIntent.helpWhereAmI:
        await _handleLocal('Kamu di mode Asisten Suara.');
        break;
      default:
        await _handleDescribeScene();
    }
  }

  Future<void> _handleLocal(String answer) async {
    // AS-08 — proses lokal, "Baik." lalu langsung hasilnya.
    _setState(VoiceState.processingLocal);
    await _respond('Baik. $answer');
  }

  /// Implementasi lengkap describe_scene: capture → detect → narasi Claude
  /// → speak. AS-09 mengumumkan jeda 3-5 detik sebelum hasil datang.
  Future<void> _handleDescribeScene() async {
    _setState(VoiceState.processingLlm);
    onSpeak?.call('Saya lihat sekitarmu dulu, sekitar tiga sampai lima detik.');

    if (!_camera.isInitialized) {
      // AS-24 — izin kamera dicabut: tetap bisa menjawab yang tidak butuh penglihatan.
      await _handleChitchat();
      return;
    }

    try {
      final jpeg = await _camera.captureJpeg();
      final dets = await _detection.detectOnce(jpeg);
      final narasi = await ServerService.instance.getNarasi(dets, context: 'voice');
      _consecutiveFailures = 0;
      await _respond(narasi);
    } catch (e) {
      _consecutiveFailures++;
      if (_consecutiveFailures == 1) {
        // AS-14 — fallback lokal sederhana sebelum menyerah total.
        _setState(VoiceState.fallbackActive);
        await _respond('Saya belum bisa melihat detail sekarang. Coba lagi sebentar, atau tanyakan hal lain.');
      } else {
        // AS-15 — semua gagal, tidak buntu.
        _setState(VoiceState.allFailed);
        onAllFeaturesFailed?.call();
        await _respond('Fitur suara sedang bermasalah. Deteksi objek tetap jalan di mode lain.');
        _consecutiveFailures = 0;
      }
    }
  }

  Future<void> _handleChitchat() async {
    await _respond('Saya belum bisa melihat sekarang (izin kamera dicabut), tapi tetap bisa bicara atau ganti mode.');
  }

  Future<void> _respond(String message, {bool save = true}) async {
    _response = message;
    _lastActivity = DateTime.now();
    if (save) _history.add(ChatTurn(isUser: false, text: message));
    _setState(VoiceState.responded);
    if (onSpeak != null) {
      onSpeak!(message);
    } else {
      await TTSService.instance.speak(message);
    }
  }

  /// AS-20 — pengguna menekan tombol Bicara lagi saat Vinara masih bicara:
  /// memotong tanpa nada khusus, langsung mulai dengar lagi.
  Future<void> interruptAndListenAgain() async {
    await TTSService.instance.stop();
    await startListening();
  }

  void _setState(VoiceState state) {
    _state = state;
    notifyListeners();
  }

  void backToIdle() => _setState(VoiceState.idle);

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }
}
