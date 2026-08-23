import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../core/voice/scene_translator.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/find_object_provider.dart';
import '../services/server_service.dart';
import '../services/tts_service.dart';

/// VoiceState - bagian 11 IMPLEMENTASI.md (AS-01..AS-25). Granular dari 4
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

/// VoiceProvider - STT → intent routing → API call → TTS.
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
  DetectionProvider get detection => _detection;
  int get consecutiveFailures => _consecutiveFailures;
  String get lastText => _lastText;
  String get response => _response;

  /// AS-18 - dua tebakan terdekat saat perintah tidak dikenali.
  List<VoiceIntent> _suggestions = [];
  List<VoiceIntent> get suggestions => _suggestions;
  String _heardRaw = '';
  String get heardRaw => _heardRaw;

  /// Dipasang layar untuk menyalurkan suara lewat antrean tier - menjaga
  /// provider ini tidak bergantung BuildContext, pola sama dengan mode lain.
  void Function(String text)? onSpeak;
  void Function()? onAllFeaturesFailed;

  /// Dipasang oleh VoiceScreen saat masuk sebagai overlay (push Navigator).
  /// Dipanggil setelah `actionGoBack` berhasil - agar layar bisa pop dirinya
  /// sendiri tanpa VoiceProvider bergantung pada BuildContext/Navigator.
  void Function()? onNavigateBack;

  /// Pengaturan adalah layar penunjang, bukan mode - pembukaannya butuh
  /// Navigator. Layar yang aktif memasang ini dan mengembalikan **true hanya
  /// kalau halaman benar-benar terbuka**; kalau null atau false, Vinara
  /// mengatakan yang sejujurnya alih-alih mengonfirmasi.
  Future<bool> Function()? onOpenSettings;

  // ── Kontrak aksi mode ──────────────────────────────────────────────────────
  //
  // Sepuluh intent punya bank kata lengkap tapi tidak punya handler sama
  // sekali; semuanya jatuh ke `default:` dan dijawab "Perintah itu belum saya
  // kenali di mode ini". Callback di bawah menyambungkannya ke mode yang
  // sedang aktif, sehingga perintah suara dan tombol kiri menjalankan hal
  // yang persis sama - satu model mental, dua cara memicunya.

  /// Aksi utama mode aktif - setara menekan tombol kiri.
  /// Dipasang tiap layar mode; `null` berarti mode ini memang tidak punya.
  void Function()? onPrimaryAction;

  /// Label aksi utama, untuk diucapkan saat mengonfirmasi.
  String Function()? primaryActionLabel;

  /// Ucapkan ulang hal penting terakhir di mode ini.
  void Function()? onRepeatLast;

  /// Jeda / lanjutkan pembacaan panjang (Mode Baca Teks).
  /// Mengembalikan true kalau mode aktif benar-benar menanganinya.
  bool Function()? onPauseSpeech;
  bool Function()? onResumeSpeech;

  /// Berhenti berjalan (Mode Navigasi).
  bool Function()? onStopWalking;

  /// Pengaturan kecepatan bicara - dipasang layar dari SettingsProvider.
  Future<double> Function(double delta)? onAdjustSpeechRate;

  /// Apakah mesin pengenal suara benar-benar siap dipakai.
  ///
  /// `initialize()` mengembalikan false kalau izin mikrofon ditolak atau tidak
  /// ada mesin STT di perangkat. Sebelumnya nilainya dibuang, jadi `listen()`
  /// berikutnya diam-diam tidak melakukan apa-apa: tidak ada status, tidak ada
  /// hasil, tidak ada error. Untuk pengguna yang tidak melihat layar, itu
  /// tombol yang ditekan lalu dunia hening.
  bool _sttAvailable = false;
  bool get sttAvailable => _sttAvailable;

  /// Sebab kegagalan terakhir dari mesin STT, apa adanya. Dipakai untuk
  /// membedakan "tidak terdengar apa pun" dari "mikrofonnya sedang dipakai".
  String _lastSttError = '';

  Future<void> init() async {
    _sttAvailable = await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (e) {
        _lastSttError = e.errorMsg;
        debugPrint('[STT] error: ${e.errorMsg} (permanent: ${e.permanent})');
      },
    );
    if (!_sttAvailable) {
      debugPrint('[STT] initialize() gagal: mesin atau izin tidak tersedia.');
      return;
    }
    await _resolveLocale();
  }

  /// Locale yang benar-benar akan dipakai `listen()`.
  ///
  /// `null` berarti serahkan ke bawaan perangkat.
  String? _localeId;

  /// Pilih locale Bahasa Indonesia yang BENAR-BENAR terpasang.
  ///
  /// Sebelumnya `'id_ID'` dipatok begitu saja. Dokumentasi paketnya menyuruh
  /// mengambil `localeId` dari daftar `locales()` milik perangkat, dan
  /// alasannya nyata: tiap pabrikan menuliskannya berbeda. Ada yang memberi
  /// `id-ID` dengan tanda hubung, ada yang `in_ID` karena Android memakai kode
  /// lama untuk Bahasa Indonesia (`in`, bukan `id`, warisan ISO 639 sebelum
  /// 1989 yang masih dipakai Java sampai hari ini).
  ///
  /// Locale yang tidak dikenali membuat mesin diam-diam jatuh ke bahasa
  /// bawaan perangkat. Untuk pengguna yang bicara Bahasa Indonesia ke mesin
  /// yang mendengarkan dalam Bahasa Inggris, hasilnya kata acak yang tidak
  /// pernah cocok dengan satu pun frasa di `CommandParser` - dan yang
  /// disalahkan biasanya parsernya.
  Future<void> _resolveLocale() async {
    try {
      final locales = await _stt.locales();
      for (final want in const ['id_ID', 'id-ID', 'in_ID', 'in-ID', 'id', 'in']) {
        final hit = locales.where((l) => l.localeId == want);
        if (hit.isNotEmpty) {
          _localeId = hit.first.localeId;
          debugPrint('[STT] locale dipakai: $_localeId (${hit.first.name})');
          return;
        }
      }
      // Cocokkan longgar sebagai jaring terakhir sebelum menyerah.
      final loose = locales.where((l) =>
          l.localeId.toLowerCase().startsWith('id') ||
          l.localeId.toLowerCase().startsWith('in_') ||
          l.name.toLowerCase().contains('indonesia'));
      if (loose.isNotEmpty) {
        _localeId = loose.first.localeId;
        debugPrint('[STT] locale dipakai (cocok longgar): $_localeId');
        return;
      }
      debugPrint('[STT] Bahasa Indonesia tidak terpasang, pakai bawaan '
          'perangkat. Tersedia: ${locales.map((l) => l.localeId).take(8).toList()}');
    } catch (e) {
      debugPrint('[STT] gagal membaca daftar locale: $e');
    }
  }

  /// True kalau perangkat memang punya Bahasa Indonesia untuk pengenalan suara.
  bool get hasIndonesianLocale => _localeId != null;

  /// AS-23 - riwayat kedaluwarsa setelah 15 menit tanpa aktivitas.
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
    // Mesin tidak siap: katakan, jangan diam. `listen()` pada mesin yang gagal
    // diinisialisasi tidak melakukan apa-apa dan tidak melaporkan apa-apa.
    if (!_sttAvailable) {
      _setState(VoiceState.allFailed);
      await _respond(
        'Pengenalan suara tidak tersedia di perangkat ini. '
        'Gunakan tombol Pilih mode untuk berpindah.',
        save: false,
      );
      return;
    }

    _lastText = '';
    _lastSttError = '';
    _setState(VoiceState.listening);
    onListeningStarted?.call();

    await _stt.listen(
      onResult: (result) {
        _lastText = result.recognizedWords;
        notifyListeners();
      },
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        // `cancelOnError` dimatikan. Android melempar galat sementara yang
        // wajar di tengah sesi (mis. `error_speech_timeout` saat pengguna
        // masih menarik napas), dan membatalkan sesi karenanya berarti
        // memotong orang yang baru mau bicara.
        cancelOnError: false,
        // 15 detik, naik dari 10. Batas ini hanya jaring pengaman; yang
        // sebenarnya menutup rekaman adalah `pauseFor`.
        listenFor: const Duration(seconds: 15),
        // 3 detik hening, naik dari 2.
        //
        // Dua detik terlalu ketat untuk sasaran aplikasi ini. Pengguna
        // tunanetra yang sedang berjalan sambil memegang tongkat, dan pengguna
        // lanjut usia, hampir selalu butuh jeda sebelum mulai bicara. Jeda itu
        // terbaca sebagai "sudah selesai", sesinya ditutup sebelum sepatah kata
        // pun keluar, dan yang terdengar adalah "belum terdengar apa pun" untuk
        // orang yang sebenarnya baru mau membuka mulut.
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  /// Ditandai layar untuk memberi penanda mulai dan berhenti mendengarkan.
  ///
  /// Untuk pengguna yang tidak melihat layar, ikon mikrofon yang berubah warna
  /// tidak berarti apa-apa. Batas sesi harus terasa: getar saat mulai, getar
  /// berbeda saat berhenti. Tanpa itu, satu-satunya cara tahu sesi sudah
  /// tertutup adalah mendengar jawabannya, dan kalau jawabannya tidak pernah
  /// datang, pengguna tidak punya cara membedakan "masih mendengarkan" dari
  /// "sudah menyerah".
  void Function()? onListeningStarted;
  void Function()? onListeningEnded;

  Future<void> stopListening() async {
    if (!_stt.isListening) return;
    await _stt.stop();
  }

  /// Hanya `done` yang menutup sesi. **Bukan** `notListening`.
  ///
  /// Ini penyebab keluhan "sudah ngomong tapi langsung bilang belum terdengar
  /// apa pun", dan letaknya ada di dalam paketnya sendiri
  /// (`speech_to_text/lib/speech_to_text.dart`, `_onNotifyStatus`):
  ///
  /// - `notListening` diteruskan APA ADANYA, dipancarkan begitu mikrofon
  ///   berhenti merekam. Mesin pengenal masih memproses audionya saat ini.
  /// - `done` sengaja DITAHAN paketnya sampai hasil akhirnya siap:
  ///   `case doneStatus: if (_latestResultType == ResultType.partial) return;`
  ///
  /// Versi sebelumnya menerima keduanya, jadi `notListening` yang datang lebih
  /// dulu selalu menang. Saat itu `_lastText` masih kosong karena hasil
  /// akhirnya belum tiba, dan aplikasi langsung menyimpulkan tidak ada yang
  /// bicara. Hasil yang sebenarnya tiba sepersekian detik kemudian, ke state
  /// yang sudah terlanjur menyerah.
  ///
  /// Itu juga menjelaskan "kadang bisa kadang tidak": kalau kebetulan ada
  /// hasil parsial yang sudah masuk sebelum mikrofon berhenti, teksnya ada dan
  /// semuanya bekerja. Kalau tidak, gagal. Yang menentukan cuma perlombaan.
  void _onSttStatus(String status) {
    if (status != 'done') return;
    onListeningEnded?.call();

    if (_lastText.trim().isNotEmpty) {
      _processText(_lastText);
      return;
    }
    _handleNothingHeard();
  }

  /// Tidak ada teks yang terkumpul. Sebutkan sebabnya, jangan menyamakan
  /// semuanya jadi "belum terdengar apa pun".
  ///
  /// Android membedakan galatnya, dan tindakan penggunanya berbeda-beda:
  /// mikrofon yang sedang dipakai aplikasi lain tidak akan membaik dengan
  /// bicara lebih keras, dan izin yang dicabut tidak akan membaik dengan
  /// mengulang sama sekali.
  void _handleNothingHeard() {
    final err = _lastSttError;
    final (message, state) = switch (err) {
      'error_busy' || 'error_client' => (
          'Mikrofon sedang dipakai aplikasi lain. Tutup aplikasi itu, lalu coba lagi.',
          VoiceState.allFailed,
        ),
      'error_insufficient_permissions' => (
          'Izin mikrofon belum diberikan. Buka Pengaturan untuk mengizinkannya.',
          VoiceState.allFailed,
        ),
      'error_network' || 'error_network_timeout' => (
          'Pengenalan suara butuh internet di perangkat ini, dan sambungannya '
              'sedang tidak ada. Gunakan tombol Pilih mode untuk berpindah.',
          VoiceState.allFailed,
        ),
      // `error_no_match` dan `error_speech_timeout` memang berarti tidak ada
      // yang terdengar. Kalimatnya dibuat instruktif, bukan sekadar laporan.
      _ => (
          'Saya belum menangkap suaranya. Tekan tombol bicara lalu ucapkan '
              'lagi, agak dekat ke ponsel.',
          VoiceState.noSpeech,
        ),
    };
    _setState(state);
    _respond(message, save: false);
  }

  Future<void> _processText(String text) async {
    _lastActivity = DateTime.now();
    _heardRaw = text;
    _history.add(ChatTurn(isUser: true, text: text));
    // AS-06 - jeda pendek "mentranskrip", tanpa kata "memproses".
    _setState(VoiceState.transcribing);
    await Future.delayed(const Duration(milliseconds: 250));

    final command = CommandParser.parse(text);

    if (!command.recognized) {
      if (command.suggestions.length >= 2) {
        // AS-19 - ambigu, pertanyaan pilihan dua.
        _suggestions = command.suggestions;
        _setState(VoiceState.ambiguous);
        _respond(
          'Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}, atau ${command.suggestions[1].spokenLabel}?',
          save: false,
        );
        return;
      }
      if (command.suggestions.isNotEmpty) {
        // AS-18 - tidak dikenali, satu tebakan tersedia.
        _suggestions = command.suggestions;
        _setState(VoiceState.unrecognized);
        _respond('Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}?', save: false);
        return;
      }
      // Tidak dikenali sama sekali - tidak ada saran.
      await _handleLocal('Maaf, saya tidak mengerti. Coba katakan lagi dengan cara berbeda.');
      return;
    }

    if (command.intent!.isModeChange) {
      // AS-17 - perintah ganti mode.
      await _applyModeChange(command.intent!);
      return;
    }

    // Perintah kembali ke mode sebelumnya.
    if (command.intent == VoiceIntent.actionGoBack) {
      await _handleGoBack();
      return;
    }

    // Perintah cari objek dengan target dinamis - pindah ke FindObject.
    if (command.intent == VoiceIntent.findObjectTarget && command.argument != null) {
      await _handleFindObjectTarget(command.argument!);
      return;
    }

    // Perintah nyalakan/matikan lampu - toggle torch.
    if (command.intent == VoiceIntent.actionTorch) {
      await _handleTorch();
      return;
    }

    // Perintah deskripsi suasana - Moondream2 via server.
    if (command.intent == VoiceIntent.describeScene) {
      await _handleDescribeScene();
      return;
    }

    switch (command.intent!) {
      case VoiceIntent.helpWhat:
        await _handleLocal('Aku bisa mendeteksi objek, membaca teks, mengenali uang, menuntun jalan, mencari barang, atau menjawab pertanyaan tentang sekitarmu.');

      case VoiceIntent.helpWhereAmI:
        // Sebutkan mode yang SEDANG aktif. Jawaban lama selalu "Kamu di mode
        // Asisten Suara" - benar hanya kalau Asisten sedang jadi mode, dan
        // menyesatkan setiap kali mic dibuka sebagai overlay dari mode lain.
        await _handleLocal('Kamu di mode ${_appMode.mode.label}.');

      case VoiceIntent.actionCapture:
        await _handlePrimaryAction();

      case VoiceIntent.actionReplay:
      case VoiceIntent.playRepeatSection:
        await _handleRepeatLast();

      case VoiceIntent.playPause:
        await _handlePlayback(pause: true);

      case VoiceIntent.playResume:
        await _handlePlayback(pause: false);

      case VoiceIntent.playFaster:
        await _handleSpeechRate(0.1);

      case VoiceIntent.playSlower:
        await _handleSpeechRate(-0.1);

      case VoiceIntent.actionStopWalking:
        await _handleStopWalking();

      default:
        await _handleLocal('Perintah itu belum saya kenali di mode ini.');
    }
  }

  /// `actionCapture` - "jepret", "ambil gambar". Menjalankan aksi utama mode
  /// aktif, yaitu hal yang sama dengan tombol kiri.
  Future<void> _handlePrimaryAction() async {
    final action = onPrimaryAction;
    if (action == null) {
      await _handleLocal('Mode ${_appMode.mode.label} tidak punya aksi ambil gambar.');
      return;
    }
    _setState(VoiceState.processingLocal);
    action();
    _consecutiveFailures = 0;
    final label = primaryActionLabel?.call();
    await _respond(label != null ? 'Baik, $label.' : 'Baik.', save: false);
  }

  Future<void> _handleRepeatLast() async {
    final repeat = onRepeatLast;
    if (repeat == null) {
      await _handleLocal('Tidak ada yang bisa diulang di mode ini.');
      return;
    }
    _setState(VoiceState.processingLocal);
    repeat();
    _consecutiveFailures = 0;
    _setState(VoiceState.responded);
  }

  Future<void> _handlePlayback({required bool pause}) async {
    final handler = pause ? onPauseSpeech : onResumeSpeech;
    final handled = handler?.call() ?? false;
    if (handled) {
      _consecutiveFailures = 0;
      await _respond(pause ? 'Dijeda.' : 'Dilanjutkan.', save: false);
      return;
    }
    // Tidak ada pembacaan panjang yang berjalan. Perlakukan "jeda" sebagai
    // permintaan menghentikan suara - itu maksud yang paling mungkin.
    if (pause) {
      await TTSService.instance.stop();
      _setState(VoiceState.responded);
      return;
    }
    await _handleLocal('Tidak ada pembacaan yang sedang dijeda.');
  }

  Future<void> _handleSpeechRate(double delta) async {
    final adjust = onAdjustSpeechRate;
    if (adjust == null) {
      await _handleLocal('Kecepatan bicara bisa diatur di Pengaturan.');
      return;
    }
    _setState(VoiceState.processingLocal);
    final applied = await adjust(delta);
    _consecutiveFailures = 0;
    final persen = (applied * 100).round();
    await _respond(
      delta > 0 ? 'Lebih cepat, $persen persen.' : 'Lebih pelan, $persen persen.',
      save: false,
    );
  }

  Future<void> _handleStopWalking() async {
    final stop = onStopWalking;
    if (stop == null || !stop()) {
      await _handleLocal('Kamu sedang tidak dalam panduan jalan.');
      return;
    }
    _consecutiveFailures = 0;
    await _respond('Panduan jalan dihentikan.', save: false);
  }

  /// AS-17 - ganti mode lewat suara. **Aturan mutlak bagian 4.1: suara Vinara
  /// tidak boleh pernah mengonfirmasi sesuatu yang tidak terjadi.** State
  /// dipindah dulu lewat [AppModeProvider.setMode]; konfirmasi "Baik."
  /// dititipkan sebagai prefiks pengumuman kedatangan, jadi ia baru terdengar
  /// setelah layar mode tujuan benar-benar terpasang. Kalau perpindahan
  /// dibatalkan (NV-18 saat pengguna masih berjalan), yang diucapkan adalah
  /// keadaan yang sebenarnya - bukan konfirmasi.
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
      // Dibatalkan konfirmasi NV-18 - pengguna tetap di tempatnya.
      await _respond('Tetap di mode ${_appMode.mode.label}.', save: false);
      return;
    }
    _consecutiveFailures = 0;
    // Tidak ada _respond di sini: pengumuman "Baik. <Mode> aktif. <panduan>"
    // diucapkan announceEntry milik layar tujuan, sesudah ia terpasang.
    _setState(VoiceState.responded);
  }

  Future<void> _handleLocal(String answer) async {
    // AS-08 - proses lokal, "Baik." lalu langsung hasilnya.
    _setState(VoiceState.processingLocal);
    await _respond('Baik. $answer');
  }

  /// Toggle flashlight - nyala jadi mati, mati jadi nyala.\n  /// Konfirmasi TTS menyebutkan status baru, bukan perintah.
  Future<void> _handleTorch() async {
    _setState(VoiceState.processingLocal);
    await _camera.toggleTorch();
    final msg = _camera.isTorchOn
        ? 'Baik, lampu dinyalakan.'
        : 'Baik, lampu dimatikan.';
    await _respond(msg, save: false);
  }

  /// Deskripsikan suasana di depan via Moondream2 (on-server).
  ///
  /// Moondream2 menjawab dalam Bahasa Inggris. Sebelum ini kalimatnya
  /// dibacakan apa adanya dengan TTS `en-US` - menuntut kemampuan Inggris
  /// lisan yang tidak bisa diasumsikan pada tunanetra di pasar dan warung
  /// Indonesia.
  ///
  /// Sekarang diterjemahkan lokal lewat [translateSceneCaption]: kamus + aturan
  /// urutan kata, 0 ms, offline, tanpa LLM - prinsip yang sama yang membuat
  /// `narration_engine` dan `CommandParser` menggantikan Qwen. Menambahkan LLM
  /// penerjemah akan mengembalikan tepat tiga masalah yang sudah dibuang:
  /// lambat, bisa berhalusinasi, dan butuh server.
  ///
  /// Kalau cakupan kamus terlalu rendah, penerjemah **menyerah** dan kalimat
  /// Inggrisnya dibacakan - didahului satu penanda singkat, supaya pengguna
  /// tahu bahasanya berganti dan tidak menyangka aplikasinya rusak. Bahasa
  /// Indonesia yang kacau lebih buruk daripada Bahasa Inggris yang benar.
  Future<void> _handleDescribeScene() async {
    _setState(VoiceState.processingLlm);
    onSpeak?.call('Saya foto sekitarmu dulu, tunggu sebentar.');

    if (!_camera.isInitialized) {
      await _handleLocal('Kamera tidak tersedia untuk mengambil foto.');
      return;
    }

    // Naikkan resolusi dulu. Deskripsi suasana dipanggil dari mode suara, yang
    // bisa dimasuki dari mode aliran mana pun - dan di sana kameranya masih
    // 640x480. Mengirim foto sekecil itu ke Moondream2 membuang detail yang
    // justru menentukan isi deskripsinya.
    //
    // Presetnya WAJIB dikembalikan setelah selesai. Alasan lama ("tiap mode
    // aliran sudah meminta presetnya sendiri saat dimasuki") hanya benar kalau
    // modenya dimasuki lagi - dan justru itu yang tidak terjadi di jalur yang
    // paling sering dipakai: mic dibuka sebagai OVERLAY di atas mode yang
    // sedang berjalan, lalu ditutup. Layar di bawahnya tidak pernah
    // di-`initState` ulang, jadi tidak ada satu pun yang mengembalikan preset,
    // dan Mode Deteksi melanjutkan hidupnya pada resolusi tiga kali lebih
    // berat di HP yang justru paling tidak sanggup.
    final previousPreset = _camera.activePreset;

    try {
      await _camera.initCamera(preset: CapturePreset.capture);

      final jpeg = await _camera.captureJpeg();
      final scene = await ServerService.instance.describeScene(jpeg);

      if (!scene.hasDescription) {
        // Kalau server menjelaskan APA yang salah, sampaikan itu apa adanya.
        // "Terlalu gelap, cari tempat yang lebih terang" memberi pengguna
        // sesuatu untuk dikerjakan; "maaf, tidak bisa mendeskripsikan" cuma
        // memberi tahu bahwa dia gagal, tanpa jalan keluar.
        await _handleLocal(
          scene.message.isNotEmpty
              ? scene.message
              : 'Maaf, saya tidak bisa mendeskripsikan suasana saat ini. Coba lagi.',
        );
        return;
      }

      _consecutiveFailures = 0;

      final description = scene.descriptionEn;
      final translated = translateSceneCaption(description);
      if (translated.isUsable) {
        _response = translated.indonesian!;
        _setState(VoiceState.responded);
        await TTSService.instance.speak(_response);
        await _speakQualityNote(scene);
        return;
      }

      debugPrint('[Describe] cakupan kamus ${translated.coverage.toStringAsFixed(2)} '
          '- dibacakan dalam Bahasa Inggris');
      _response = description;
      _setState(VoiceState.responded);
      await TTSService.instance.speak('Dalam bahasa Inggris.');
      await TTSService.instance.speakEnglish(description);
      await _speakQualityNote(scene);
    } on CaptureRejected catch (rejected) {
      // Foto ditolak sebelum dikirim. Instruksi perbaikannya sudah dibacakan
      // saat penolakan terjadi, jadi state cukup dikembalikan tanpa pesan
      // tambahan.
      //
      // Menolak di sini bukan sekadar menghemat kuota. Moondream2 tidak
      // pernah mengatakan "saya tidak bisa melihat" - dari foto gelap gulita
      // pun dia menghasilkan deskripsi yang terdengar meyakinkan. Untuk
      // pengguna yang tidak bisa memverifikasi sendiri, deskripsi halusinasi
      // jauh lebih berbahaya daripada penolakan yang jujur.
      debugPrint('[VoiceProvider] foto ditolak: $rejected');
      _response = rejected.message;
      _setState(VoiceState.responded);
    } catch (e) {
      debugPrint('[VoiceProvider] _handleDescribeScene error: $e');
      await _handleLocal('Gagal mendeskripsikan suasana. Coba lagi.');
    } finally {
      // Di `finally`, bukan di akhir jalur sukses: foto yang ditolak gerbang
      // kualitas adalah hasil yang PALING sering terjadi di tempat gelap, dan
      // meninggalkan kamera pada preset foto persis setelah itu berarti mode
      // aliran di bawahnya melanjutkan dengan beban tiga kali lipat.
      if (previousPreset != null && previousPreset != CapturePreset.capture) {
        await _camera.initCamera(preset: previousPreset);
      }
    }
  }

  /// Bacakan catatan kualitas dari server, kalau ada.
  ///
  /// Diucapkan SESUDAH deskripsinya dan sebagai utterance terpisah, dengan
  /// locale Bahasa Indonesia - deskripsinya sendiri mungkin baru dibacakan
  /// dalam Bahasa Inggris, dan menyambung dua bahasa dalam satu utterance
  /// membuat TTS mengucapkan salah satunya dengan fonetik yang keliru.
  ///
  /// Ini soal kejujuran sistem: kalau modelnya menjawab dari foto yang
  /// kurang bagus, pengguna berhak tahu supaya bisa memutuskan sendiri
  /// apakah mau memfoto ulang. Dia tidak punya cara lain memverifikasinya.
  Future<void> _speakQualityNote(SceneDescription scene) async {
    if (scene.message.trim().isEmpty) return;
    await TTSService.instance.speak(scene.message);
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

  /// AS-20 - pengguna menekan tombol Bicara lagi saat Vinara masih bicara:
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

  /// Lepas semua callback mode. Dipanggil layar saat dispose supaya aksi
  /// mode yang sudah ditinggalkan tidak ikut terbawa ke mode berikutnya.
  void clearModeHandlers() {
    onPrimaryAction = null;
    primaryActionLabel = null;
    onRepeatLast = null;
    onPauseSpeech = null;
    onResumeSpeech = null;
    onStopWalking = null;
  }

  @override
  void dispose() {
    onSpeak = null;
    onOpenSettings = null;
    onNavigateBack = null;
    onAllFeaturesFailed = null;
    onAdjustSpeechRate = null;
    clearModeHandlers();
    _stt.cancel();
    super.dispose();
  }
}
