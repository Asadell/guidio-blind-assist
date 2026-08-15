import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/find_object_provider.dart';
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
  final AppModeProvider _appMode;
  final FindObjectProvider _findObject;

  VoiceProvider(this._camera, this._detection, this._appMode, this._findObject);

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

  /// Dipasang layar untuk menyalurkan suara lewat antrean tier — menjaga
  /// provider ini tidak bergantung BuildContext, pola sama dengan mode lain.
  void Function(String text)? onSpeak;
  void Function()? onAllFeaturesFailed;

  /// Dipasang oleh VoiceScreen saat masuk sebagai overlay (push Navigator).
  /// Dipanggil setelah `actionGoBack` berhasil — agar layar bisa pop dirinya
  /// sendiri tanpa VoiceProvider bergantung pada BuildContext/Navigator.
  void Function()? onNavigateBack;

  /// Pengaturan adalah layar penunjang, bukan mode — pembukaannya butuh
  /// Navigator. Layar yang aktif memasang ini dan mengembalikan **true hanya
  /// kalau halaman benar-benar terbuka**; kalau null atau false, Vinara
  /// mengatakan yang sejujurnya alih-alih mengonfirmasi.
  Future<bool> Function()? onOpenSettings;

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
      // Tidak dikenali sama sekali — tidak ada saran.
      await _handleLocal('Maaf, saya tidak mengerti. Coba katakan lagi dengan cara berbeda.');
      return;
    }

    if (command.intent!.isModeChange) {
      // AS-17 — perintah ganti mode.
      await _applyModeChange(command.intent!);
      return;
    }

    // Perintah kembali ke mode sebelumnya.
    if (command.intent == VoiceIntent.actionGoBack) {
      await _handleGoBack();
      return;
    }

    // Perintah cari objek dengan target dinamis — pindah ke FindObject.
    if (command.intent == VoiceIntent.findObjectTarget && command.argument != null) {
      await _handleFindObjectTarget(command.argument!);
      return;
    }

    // Perintah nyalakan/matikan lampu — toggle torch.
    if (command.intent == VoiceIntent.actionTorch) {
      await _handleTorch();
      return;
    }

    // Perintah deskripsi suasana — Moondream2 via server.
    if (command.intent == VoiceIntent.describeScene) {
      await _handleDescribeScene();
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
        await _handleLocal('Perintah itu belum saya kenali di mode ini.');
    }
  }

  /// AS-17 — ganti mode lewat suara. **Aturan mutlak bagian 4.1: suara Vinara
  /// tidak boleh pernah mengonfirmasi sesuatu yang tidak terjadi.** State
  /// dipindah dulu lewat [AppModeProvider.setMode]; konfirmasi "Baik."
  /// dititipkan sebagai prefiks pengumuman kedatangan, jadi ia baru terdengar
  /// setelah layar mode tujuan benar-benar terpasang. Kalau perpindahan
  /// dibatalkan (NV-18 saat pengguna masih berjalan), yang diucapkan adalah
  /// keadaan yang sebenarnya — bukan konfirmasi.
  Future<void> _applyModeChange(VoiceIntent intent) async {
    if (intent == VoiceIntent.modeSettings) {
      final opened = await onOpenSettings?.call() ?? false;
      if (opened) {
        _consecutiveFailures = 0;
        // Diucapkan sesudah rutenya benar-benar masuk tumpukan.
        await _respond('Pengaturan terbuka.', save: false);
      } else {
        await _respond(
          'Pengaturan belum bisa dibuka dari sini. Tekan Pilih mode, lalu buka Pengaturan.',
          save: false,
        );
      }
      return;
    }

    final target = switch (intent) {
      VoiceIntent.modeMoney => AppMode.money,
      VoiceIntent.modeReadText => AppMode.ocr,
      VoiceIntent.modeDetection => AppMode.tuntun,
      VoiceIntent.modeNavigation => AppMode.navigasi,
      VoiceIntent.modeAssistant => AppMode.voice,
      VoiceIntent.modeFindObject => AppMode.findObject,
      _ => null,
    };
    if (target == null) {
      await _respond('Saya belum bisa membuka itu. Coba sebutkan nama modenya.', save: false);
      return;
    }

    // Sudah berada di mode yang diminta: katakan apa adanya, jangan berpura-pura
    // berpindah dan jangan mengumumkan ulang panduan mode.
    if (_appMode.mode == target) {
      _consecutiveFailures = 0;
      await _respond('Kamu sudah di mode ${target.label}.', save: false);
      return;
    }

    final changed = await _appMode.setMode(target, spokenPrefix: 'Baik.');
    if (!changed || _appMode.mode != target) {
      // Dibatalkan konfirmasi NV-18 — pengguna tetap di tempatnya.
      await _respond('Tetap di mode ${_appMode.mode.label}.', save: false);
      return;
    }
    _consecutiveFailures = 0;
    // Tidak ada _respond di sini: pengumuman "Baik. <Mode> aktif. <panduan>"
    // diucapkan announceEntry milik layar tujuan, sesudah ia terpasang.
    _setState(VoiceState.responded);
  }

  Future<void> _handleLocal(String answer) async {
    // AS-08 — proses lokal, "Baik." lalu langsung hasilnya.
    _setState(VoiceState.processingLocal);
    await _respond('Baik. $answer');
  }

  /// Toggle flashlight — nyala jadi mati, mati jadi nyala.\n  /// Konfirmasi TTS menyebutkan status baru, bukan perintah.
  Future<void> _handleTorch() async {
    _setState(VoiceState.processingLocal);
    await _camera.toggleTorch();
    final msg = _camera.isTorchOn
        ? 'Baik, lampu dinyalakan.'
        : 'Baik, lampu dimatikan.';
    await _respond(msg, save: false);
  }

  /// Deskripsikan suasana di depan via Moondream2 (on-server).
  /// AS-09 style: umumkan dulu bahwa perlu waktu, lalu ambil gambar & kirim.
  Future<void> _handleDescribeScene() async {
    _setState(VoiceState.processingLlm);
    onSpeak?.call('Saya foto sekitarmu dulu, tunggu sebentar.');

    if (!_camera.isInitialized) {
      await _handleLocal('Kamera tidak tersedia untuk mengambil foto.');
      return;
    }

    try {
      final jpeg = await _camera.captureJpeg();
      final deskripsi = await ServerService.instance.describeScene(jpeg);

      if (deskripsi == null || deskripsi.isEmpty) {
        await _handleLocal('Maaf, saya tidak bisa mendeskripsikan suasana saat ini. Coba lagi.');
        return;
      }

      _consecutiveFailures = 0;
      await _respond(deskripsi, save: true);
    } catch (e) {
      debugPrint('[VoiceProvider] _handleDescribeScene error: $e');
      await _handleLocal('Gagal mendeskripsikan suasana. Coba lagi.');
    }
  }

  Future<void> _handleChitchat() async {
    await _respond('Saya belum bisa melihat sekarang (izin kamera dicabut), tapi tetap bisa bicara atau ganti mode.');
  }

  /// Perintah suara "kembali" \u2014 kembali ke mode sebelumnya via AppModeProvider.
  /// Jika ada onNavigateBack (masuk sebagai overlay push), callback dipanggil
  /// sesudah mode berubah agar Navigator bisa pop layar ini.
  Future<void> _handleGoBack() async {
    _setState(VoiceState.processingLocal);
    final previous = _appMode.previousMode;
    final label = previous?.label ?? AppMode.tuntun.label;
    final changed = await _appMode.goBack(spokenPrefix: 'Kembali.');
    if (changed) {
      _consecutiveFailures = 0;
      _setState(VoiceState.responded);
      // Pop dilakukan setelah mode berubah supaya announceEntry di layar tujuan
      // terucap sebelum layar ini ditutup.
      onNavigateBack?.call();
    } else {
      await _respond('Sudah di mode $label, tidak bisa kembali lebih jauh.', save: false);
    }
  }

  /// Perintah suara "carikan [barang]" dari mode mana pun:
  /// - Set target ke FindObjectProvider
  /// - Pindah mode ke findObject
  /// - Pop VoiceScreen overlay jika ada (via onNavigateBack)
  Future<void> _handleFindObjectTarget(String target) async {
    _setState(VoiceState.processingLocal);
    _findObject.setTarget(target);
    final changed = await _appMode.setMode(AppMode.findObject, spokenPrefix: 'Baik, mencari $target.');
    if (changed) {
      _consecutiveFailures = 0;
      _setState(VoiceState.responded);
      onNavigateBack?.call();
    } else {
      await _respond('Sudah di mode Cari Objek. Target diperbarui ke $target.', save: false);
      onNavigateBack?.call();
    }
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
    onSpeak = null;
    onOpenSettings = null;
    onNavigateBack = null;
    onAllFeaturesFailed = null;
    _stt.cancel();
    super.dispose();
  }
}
