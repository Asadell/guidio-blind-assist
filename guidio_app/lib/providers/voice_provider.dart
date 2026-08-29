import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/speech/tts_queue.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/find_object_provider.dart';
import '../services/haptic_service.dart';
import '../services/server_service.dart';
import '../services/translation_service.dart';

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

  /// Apakah server sedang tidak terjangkau.
  ///
  /// Dipasang lapisan yang punya akses `GlobalConditionsProvider` (lihat
  /// `MainScreen._initServices`), memakai pola callback yang sama dengan
  /// `FindObjectProvider.isOffline`. Disuntik lewat konstruktor akan memaksa
  /// `ChangeNotifierProxyProvider4` di `main.dart` jadi lima dependensi hanya
  /// untuk satu bacaan boolean.
  ///
  /// Null berarti tidak diketahui, dan yang tidak diketahui TIDAK menghalangi:
  /// mengunci mode karena status yang belum terbaca lebih merugikan daripada
  /// membiarkan satu percobaan gagal dengan pesan yang jelas.
  bool Function()? isBackendDown;

  /// Mode ini butuh server DAN servernya sedang tidak ada.
  ///
  /// Dipakai sebelum berpindah mode lewat suara. Lembar Pilih Mode sudah
  /// menonaktifkan itemnya sejak awal, tapi lembar itu jalan KEDUA - untuk
  /// pengguna tunanetra, suara adalah jalan utama ganti mode. Tanpa penjagaan
  /// di sini, dia berpindah ke mode yang tidak bisa menjawab apa pun, mencoba
  /// beberapa kali, lalu menyimpulkan aplikasinya rusak.
  bool _butuhServerTapiMati(AppMode target) =>
      target.disabledWhenOffline && (isBackendDown?.call() ?? false);

  String _pesanButuhServer(AppMode target) =>
      '${target.label} butuh internet, dan server sedang tidak terhubung. '
      'Mode lain tetap bisa dipakai.';

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

  /// Locale yang dipakai `listen()`.
  ///
  /// **Tidak pernah null.** Nilai awalnya `id_ID`, dan penelusuran daftar
  /// perangkat hanya boleh MENGGANTINYA dengan kode lain yang terbukti ada,
  /// tidak pernah mengosongkannya.
  ///
  /// Ini pernah nullable, dan itu regresi yang nyata: kalau `locales()` gagal
  /// dibaca atau daftarnya belum lengkap saat init, nilainya tinggal null,
  /// `listen(localeId: null)` menyerahkan pilihan ke bawaan perangkat, dan di
  /// sebagian besar ponsel bawaannya Inggris. Pengguna bicara Bahasa Indonesia
  /// ke mesin yang mendengarkan Inggris: hasilnya kata acak yang tidak pernah
  /// cocok dengan satu pun frasa `CommandParser`.
  ///
  /// Menebak `id_ID` lalu gagal jauh lebih baik daripada diam-diam pindah ke
  /// bahasa lain. Yang pertama masih punya peluang benar; yang kedua tidak
  /// pernah benar, dan tidak meninggalkan satu pun petunjuk kenapa.
  String _localeId = kDefaultSttLocale;

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
      final picked = pickIndonesianLocale(
        [for (final l in locales) (id: l.localeId, name: l.name)],
      );
      if (picked != null) {
        _localeId = picked;
        _indonesianConfirmed = true;
        debugPrint('[STT] locale dipakai: $_localeId');
        return;
      }
      debugPrint('[STT] Bahasa Indonesia tidak ada di daftar perangkat. '
          'Tetap mencoba $_localeId. '
          'Tersedia: ${locales.map((l) => l.localeId).take(8).toList()}');
    } catch (e) {
      debugPrint('[STT] gagal membaca daftar locale, tetap memakai '
          '$_localeId: $e');
    }
  }

  /// True kalau Bahasa Indonesia benar-benar ditemukan di daftar perangkat.
  ///
  /// False bukan berarti pengenalan tidak jalan: [_localeId] tetap dicoba.
  /// Nilai ini hanya menandakan bahwa keberhasilannya tidak dijamin.
  bool _indonesianConfirmed = false;
  bool get hasIndonesianLocale => _indonesianConfirmed;

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

  /// Sesi tap sekali: yang menutupnya adalah hening, bukan jari.
  ///
  /// Dipakai jalur cadangan TalkBack, yang tidak bisa memakai tekan-tahan
  /// karena gestur satu jarinya sudah dipakai screen reader.
  Future<void> startListening() => _beginListening(hold: false);

  Future<void> _beginListening({required bool hold}) async {
    if (_state != VoiceState.idle &&
        _state != VoiceState.responded &&
        _state != VoiceState.unrecognized &&
        _state != VoiceState.ambiguous &&
        _state != VoiceState.noSpeech &&
        _state != VoiceState.transcribeFailed &&
        _state != VoiceState.allFailed) {
      return;
    }

    // Bungkam mode yang sedang berjalan, SEBELUM mikrofon dibuka.
    //
    // Urutannya penting: narasi yang sempat berangkat sesudah mikrofon
    // menyala akan terekam sebagai bagian dari perintah pengguna. Ini juga
    // yang memotong ucapan yang sedang berjalan - pengguna yang menahan
    // tombol sudah memutuskan untuk bicara, dan memaksanya menunggu Vinara
    // selesai berarti separuh perintahnya jatuh ke mikrofon yang belum siap.
    await TtsQueue.instance.beginVoiceSession();

    // Mesin tidak siap: katakan, jangan diam. `listen()` pada mesin yang gagal
    // diinisialisasi tidak melakukan apa-apa dan tidak melaporkan apa-apa.
    if (!_sttAvailable) {
      _setState(VoiceState.allFailed, keepVoiceGate: true);
      await _respond(
        'Pengenalan suara tidak tersedia di perangkat ini. '
        'Gunakan tombol Pilih mode untuk berpindah.',
        save: false,
      );
      return;
    }

    _lastText = '';
    _lastSttError = '';
    _sessionIsHold = hold;
    _setState(VoiceState.listening);
    // Satu-satunya pemilik getar batas sesi. Sebelumnya ini callback yang
    // hanya dipasang VoiceScreen, jadi di lima mode lain menahan tombol tidak
    // menghasilkan getar apa pun - dan getar itulah satu-satunya cara pengguna
    // yang tidak melihat layar tahu mikrofonnya sudah menyala.
    HapticService.instance.info();

    if (hold) {
      _holdCapTimer?.cancel();
      _holdCapTimer = Timer(kHoldToTalkMaxHold, _onHoldCapReached);
    }

    await _stt.listen(
      onResult: (result) {
        _lastText = result.recognizedWords;
        notifyListeners();
      },
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        // Dikembalikan ke true.
        //
        // Sempat saya matikan dengan alasan "galat sementara tidak boleh
        // memotong orang yang baru mau bicara". Itu keliru: galat yang
        // dilempar Android di sini, `error_speech_timeout` dan
        // `error_no_match`, keduanya PERMANEN dan memang menandakan sesi
        // selesai. Membiarkan sesi hidup setelahnya berarti mikrofon terus
        // merekam derau sekitar sampai `listenFor` habis, lalu mengembalikan
        // apa pun yang terakhir tertangkap - hasilnya justru lebih ngawur
        // daripada mengakui tidak ada yang terdengar.
        cancelOnError: true,
        // Sesi tekan-tahan sengaja diberi batas MELEBIHI [kHoldToTalkMaxHold],
        // supaya yang memotongnya selalu [_holdCapTimer] - bukan paketnya.
        // Bedanya nyata: timer itu MEMBUANG audionya lalu mengatakan waktunya
        // habis, sementara `listenFor` menutup sesi dengan mengirim hasil
        // separuh, yang lalu diproses seolah-olah itu perintah utuh. Perintah
        // separuh yang dijalankan lebih buruk daripada perintah yang gagal.
        //
        // 15 detik untuk sesi tap sekali; batas itu hanya jaring pengaman,
        // yang sebenarnya menutup rekaman adalah `pauseFor`.
        listenFor: hold
            ? kHoldToTalkMaxHold + kHoldToTalkGrace
            : const Duration(seconds: 15),
        // 3 detik hening, naik dari 2.
        //
        // Dua detik terlalu ketat untuk sasaran aplikasi ini. Pengguna
        // tunanetra yang sedang berjalan sambil memegang tongkat, dan pengguna
        // lanjut usia, hampir selalu butuh jeda sebelum mulai bicara. Jeda itu
        // terbaca sebagai "sudah selesai", sesinya ditutup sebelum sepatah kata
        // pun keluar, dan yang terdengar adalah "belum terdengar apa pun" untuk
        // orang yang sebenarnya baru mau membuka mulut.
        //
        // Di sesi tekan-tahan nilainya ikut dipanjangkan dengan alasan
        // berbeda: yang menutup sesi adalah jari yang diangkat. Pengguna yang
        // berhenti sejenak mengumpulkan kata sambil tetap menahan tombol tidak
        // boleh diputus di tengah kalimat.
        pauseFor: hold
            ? kHoldToTalkMaxHold + kHoldToTalkGrace
            : const Duration(seconds: 3),
      ),
    );
  }

  // ── Tekan-tahan untuk bicara ───────────────────────────────────────────────
  //
  // Sesi tekan-tahan berbeda dari sesi tap sekali di satu hal yang menentukan
  // segalanya: **batas sesinya ditentukan jari, bukan hening.** Semua yang di
  // bawah ini turun dari kalimat itu.

  /// Jenis sesi yang sedang/terakhir berjalan.
  ///
  /// Dipakai untuk menentukan siapa yang memberi getar penutup: di sesi
  /// tekan-tahan getarnya harus jatuh saat jari diangkat, bukan saat
  /// pengenalan selesai beberapa ratus milidetik kemudian.
  bool _sessionIsHold = false;
  bool get isHoldSession => _sessionIsHold;

  Timer? _holdCapTimer;

  /// True dari jari menempel sampai sesi tekan-tahan benar-benar ditutup.
  bool _holdActive = false;
  bool get isHoldActive => _holdActive;

  /// Sesi ini sudah dipotong batas waktu. Pelepasan jari sesudahnya tidak
  /// boleh memproses apa pun lagi - jawabannya sudah diberikan timer.
  bool _holdTimedOut = false;

  /// Tombol Bicara mulai ditahan.
  ///
  /// TTS yang sedang berjalan dipotong seketika. Pengguna yang menahan tombol
  /// sudah memutuskan untuk bicara; memaksanya menunggu Vinara selesai bicara
  /// dulu berarti separuh perintahnya jatuh ke mikrofon yang belum menyala.
  Future<void> startHoldToTalk() async {
    _holdActive = true;
    _holdTimedOut = false;
    // Pemotongan TTS tidak lagi dikerjakan di sini. `_beginListening` membuka
    // gerbang suara, dan gerbang itulah yang menghentikan ucapan berjalan
    // sekaligus membuang antrean milik mode. Dua tempat yang menghentikan
    // hal yang sama hanya akan berselisih saat salah satunya diubah.
    await _beginListening(hold: true);
    // Sesi tidak jadi dibuka - mesin belum siap, atau state belum
    // mengizinkan. Jangan tinggalkan tanda tahan yang menyala, karena
    // pelepasan jari sesudahnya akan menutup sesi yang tidak pernah ada.
    if (_state != VoiceState.listening) _holdActive = false;
  }

  /// Jari diangkat. Tutup mikrofon, lalu proses apa yang tertangkap.
  Future<void> finishHoldToTalk() async {
    _holdCapTimer?.cancel();
    _holdCapTimer = null;
    if (!_holdActive) return;
    _holdActive = false;

    if (_holdTimedOut) {
      _holdTimedOut = false;
      return;
    }

    // Getar penutup jatuh DI SINI, bukan saat status `done` tiba. Untuk
    // pengguna yang tidak melihat layar, getar itu adalah jawaban atas
    // "apakah pelepasan jariku terdaftar?" - dan pertanyaan itu muncul saat
    // jari diangkat, bukan setengah detik kemudian setelah pengenalan selesai.
    HapticService.instance.warning();

    // Mesin sudah menutup sesinya sendiri (galat permanen, misalnya mikrofon
    // dipakai aplikasi lain). Alurnya sudah berjalan; jangan ditumpuk.
    if (!_stt.isListening) return;

    // `stop()`, bukan `cancel()`: stop meminta hasil akhir, cancel
    // membuangnya. Hasil akhir itulah perintah penggunanya.
    await _stt.stop();
  }

  /// Batas tahan tercapai - tombol tertekan di dalam tas, atau jari lupa
  /// diangkat. Buang audionya dan katakan apa yang terjadi.
  ///
  /// `cancel()` dipilih dengan sengaja: ia tidak menghasilkan hasil akhir,
  /// jadi `_onSttStatus` tidak akan ikut menjawab dan menimpa pesan ini.
  Future<void> _onHoldCapReached() async {
    if (!_holdActive || _state != VoiceState.listening) return;
    _holdTimedOut = true;
    await _stt.cancel();
    HapticService.instance.warning();
    _setState(VoiceState.noSpeech, keepVoiceGate: true);
    await _respond('Waktu habis, silakan coba lagi.', save: false);
  }

  /// Ditahan terlalu singkat untuk dianggap tekan-tahan.
  ///
  /// Tidak merekam apa pun, tapi juga TIDAK diam: tombol yang ditekan lalu
  /// hening tidak bisa dibedakan dari aplikasi yang macet oleh pengguna yang
  /// tidak melihat layar, dan satu-satunya cara mengujinya adalah menekan lagi.
  Future<void> explainHoldRequired() async {
    HapticService.instance.info();
    await TtsQueue().speak(
      'Tahan tombolnya, lalu bicara.',
      tier: SpeechTier.info,
      source: SpeechSource.assistant,
    );
  }

  // Penanda batas sesi (getar mulai & getar berhenti) dulu berupa dua callback
  // yang HANYA dipasang VoiceScreen. Sejak tombol mic bekerja langsung dari
  // semua mode tanpa membuka VoiceScreen, callback itu tinggal null di lima
  // mode lain: menahan tombol tidak menghasilkan getar apa pun, padahal getar
  // itulah satu-satunya cara pengguna yang tidak melihat layar tahu mikrofonnya
  // menyala. Sekarang provider ini yang memegangnya, satu pemilik untuk semua
  // mode, lewat HapticService yang menghormati pengaturan "Getar".

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
    _holdCapTimer?.cancel();
    _holdCapTimer = null;
    // Sesi tekan-tahan sudah bergetar saat jari diangkat. Bergetar lagi di
    // sini berarti dua getar untuk satu peristiwa, dan pengguna kehilangan
    // arti keduanya.
    if (!_sessionIsHold) HapticService.instance.warning();

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
    _setState(state, keepVoiceGate: true);
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
        _setState(VoiceState.ambiguous, keepVoiceGate: true);
        _respond(
          'Saya dengar "$text". Maksudmu ${command.suggestions[0].spokenLabel}, atau ${command.suggestions[1].spokenLabel}?',
          save: false,
        );
        return;
      }
      if (command.suggestions.isNotEmpty) {
        // AS-18 - tidak dikenali, satu tebakan tersedia.
        _suggestions = command.suggestions;
        _setState(VoiceState.unrecognized, keepVoiceGate: true);
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
    // Aksi mode berbicara sebagai asisten: kalimat yang keluar darinya
    // ("Suara panduan dimatikan.") adalah jawaban atas perintah ini, bukan
    // narasi mode yang kebetulan lewat.
    TtsQueue.instance.speakModeAsAssistant(action);
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
    // Isi ulangannya sendiri yang jadi jawaban - tidak ada `_respond` di
    // jalur ini, jadi kalau ucapan itu ikut terbungkam, "ulangi" berbuah
    // hening total.
    TtsQueue.instance.speakModeAsAssistant(repeat);
    _consecutiveFailures = 0;
    _setState(VoiceState.responded);
  }

  Future<void> _handlePlayback({required bool pause}) async {
    final handler = pause ? onPauseSpeech : onResumeSpeech;
    final handled = handler == null
        ? false
        : TtsQueue.instance.speakModeAsAssistant(handler);
    if (handled) {
      _consecutiveFailures = 0;
      await _respond(pause ? 'Dijeda.' : 'Dilanjutkan.', save: false);
      return;
    }
    // Tidak ada pembacaan panjang yang berjalan. Perlakukan "jeda" sebagai
    // permintaan menghentikan suara - itu maksud yang paling mungkin.
    if (pause) {
      // Lewat antrean, BUKAN `TTSService.stop()` langsung.
      //
      // Menghentikan mesin di belakang punggung antrean menyisakan
      // `_pending` yang masih berisi dan gerbang suara yang masih tertutup:
      // ucapan yang sedang berjalan terpotong, lalu antrean langsung
      // melanjutkan ke item berikutnya - yang justru berlawanan dengan
      // maksud "jeda". `TtsQueue.stop()` mengosongkan keduanya sekaligus.
      await TtsQueue.instance.stop();
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
    if (stop == null || !TtsQueue.instance.speakModeAsAssistant(stop)) {
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

    if (_butuhServerTapiMati(target)) {
      _consecutiveFailures = 0;
      await _respond(_pesanButuhServer(target), save: false);
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
    final wantOn = !_camera.isTorchOn;
    final changed = await _camera.toggleTorch();
    // Konfirmasi hanya diucapkan kalau lampunya BENAR-BENAR berubah. Aturan
    // yang sama dengan perpindahan mode: suara Vinara tidak boleh pernah
    // mengonfirmasi sesuatu yang tidak terjadi - dan lampu adalah hal yang
    // paling tidak bisa diperiksa sendiri oleh penggunanya.
    final msg = changed
        ? (wantOn ? 'Baik, lampu dinyalakan.' : 'Baik, lampu dimatikan.')
        : (wantOn
            ? 'Lampu tidak bisa dinyalakan sekarang.'
            : 'Lampu tidak bisa dimatikan sekarang.');
    await _respond(msg, save: false);
  }

  /// Deskripsikan suasana di depan via Moondream2 (on-server).
  ///
  /// Moondream2 menjawab dalam Bahasa Inggris. Sebelum ini kalimatnya
  /// dibacakan apa adanya dengan TTS `en-US` - menuntut kemampuan Inggris
  /// lisan yang tidak bisa diasumsikan pada tunanetra di pasar dan warung
  /// Indonesia.
  ///
  /// Captionnya dibacakan **apa adanya dalam Bahasa Inggris**, didahului satu
  /// penanda singkat Bahasa Indonesia supaya perpindahan bahasanya tidak
  /// mengejutkan.
  ///
  /// Penerjemah kamus lokal pernah dipasang di sini lalu dilepas. Ia
  /// menerjemahkan sebagian kalimat dan menyerah pada sisanya, sehingga satu
  /// mode yang sama bisa menjawab dalam Bahasa Indonesia, Inggris, atau
  /// campuran keduanya tergantung foto - dan ketidakkonsistenan itu lebih
  /// sulit diikuti telinga daripada satu bahasa yang tetap.
  ///
  /// Menambahkan LLM penerjemah bukan jalan keluarnya: itu mengembalikan tepat
  /// tiga masalah yang sudah dibuang dari proyek ini, yaitu lambat, bisa
  /// berhalusinasi, dan butuh server.
  /// Ambil foto dan minta deskripsi suasana ke VLM di server.
  ///
  /// Pintu masuk publik untuk tombol kiri Mode Deskripsi Suasana. Isinya sama
  /// persis dengan yang dijalankan perintah suara "deskripsikan", jadi tombol
  /// dan ucapan tidak pernah bercabang jadi dua perilaku yang berbeda.
  ///
  /// Sengaja dipicu MANUAL, tidak otomatis saat masuk mode. Tiap panggilan
  /// mengunggah satu foto dan membangunkan Moondream2, dan menjalankannya
  /// tanpa diminta berarti mengirim foto sekitar pengguna ke jaringan setiap
  /// kali ia tidak sengaja membuka mode ini.
  // ═══════════════════════════════════════════════════════════════════════
  //  Deskripsi suasana: satu kirim, satu deskripsi
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Mode ini punya siklus yang jauh lebih panjang daripada perintah suara
  // biasa: foto → unggah → Moondream2 → terjemah → dibacakan belasan detik.
  // Selama itu berlangsung, mengirim foto kedua bukan mempercepat apa pun -
  // ia membuang deskripsi yang sedang dibacakan di tengah kalimat, dan
  // pengguna yang tidak melihat layar cuma mendengar suaranya berhenti
  // mendadak lalu diganti kalimat yang tidak dia minta.
  //
  // Karena itu tombolnya dijaga di DUA lapis: `VoiceState` tidak cukup.
  // `_setState(VoiceState.responded)` terjadi tepat sebelum antrean suara
  // diisi, jadi `isProcessing` sudah kembali false sementara deskripsinya
  // baru mulai dibacakan - dan itu persis celah yang membuat tombol kiri
  // bisa ditekan lagi di tengah narasi.

  /// Teks deskripsi terakhir, disimpan supaya bisa dibacakan ulang sesudah
  /// dihentikan. Null berarti belum ada deskripsi sama sekali.
  String? _sceneNarration;
  bool _sceneNarrationEnglish = false;
  String _sceneQualityNote = '';

  /// Sedang memotret dan menunggu jawaban server.
  bool _sceneBusy = false;

  /// Deskripsinya sedang dibacakan.
  bool _sceneNarrating = false;

  /// Dihentikan pengguna dan menunggu dilanjutkan.
  bool _scenePaused = false;

  /// Pengawas selesainya narasi.
  ///
  /// Dipakai polling, BUKAN callback dari `TtsQueue`. Antrean suara itu
  /// arbiter keselamatan - ia yang memutuskan peringatan bahaya boleh
  /// memotong apa - dan menambah jalur pemberitahuan baru ke dalamnya berarti
  /// menambah tempat baru untuk salah. Satu timer 250 ms yang hanya hidup
  /// selama narasi berlangsung membaca keadaan dari luar tanpa menyentuh
  /// arbitrasenya sama sekali.
  Timer? _sceneWatch;

  /// Sedang memotret / menunggu server.
  bool get isDescribingScene => _sceneBusy;

  /// Deskripsi sedang dibacakan.
  bool get isNarratingScene => _sceneNarrating;

  /// Narasi dihentikan pengguna dan bisa dilanjutkan.
  bool get scenePaused => _scenePaused;

  /// Tombol Berhenti/Lanjut layak ditampilkan.
  bool get hasSceneNarration =>
      _sceneNarration != null && (_sceneNarrating || _scenePaused);

  /// Boleh mengirim foto baru.
  ///
  /// Saat dijeda JUSTRU boleh: itu cara pengguna berpindah ke suasana baru
  /// tanpa harus menunggu deskripsi lama selesai dibacakan sampai habis.
  bool get canDescribeScene => !_sceneBusy && !_sceneNarrating;

  /// Alasan tombol kiri sedang mati - dibacakan pembaca layar.
  String? get describeDisabledReason {
    if (_sceneBusy) return 'sedang memproses';
    if (_sceneNarrating) return 'sedang membacakan, tekan Berhenti dulu';
    return null;
  }

  /// Tombol Berhenti / Lanjut.
  ///
  /// "Lanjut" mengulang deskripsinya dari AWAL, bukan dari kata terakhir yang
  /// terdengar. Mesin TTS tidak menyimpan posisi baca yang bisa diandalkan di
  /// semua perangkat, dan menebaknya berarti kadang melompati kalimat -
  /// kesalahan yang tidak bisa disadari pengguna yang tidak melihat layar.
  /// Deskripsi suasana hanya satu sampai dua kalimat, jadi mengulang dari awal
  /// justru jawaban yang paling bisa dipercaya.
  Future<void> toggleSceneNarration() async {
    if (_sceneNarrating) {
      _sceneWatch?.cancel();
      _sceneWatch = null;
      _sceneNarrating = false;
      _scenePaused = true;
      notifyListeners();
      await TtsQueue.instance.stop();
      return;
    }

    if (!_scenePaused || _sceneNarration == null) return;
    _scenePaused = false;
    await _narrateScene();
  }

  /// Masukkan deskripsi ke antrean lalu awasi sampai benar-benar habis.
  Future<void> _narrateScene() async {
    final text = _sceneNarration;
    if (text == null) return;

    _sceneNarrating = true;
    notifyListeners();

    if (_sceneNarrationEnglish) {
      await TtsQueue.instance.speak(
        'Dalam bahasa Inggris.',
        source: SpeechSource.assistant,
      );
    }
    await TtsQueue.instance.speak(
      text,
      source: SpeechSource.assistant,
      english: _sceneNarrationEnglish,
    );
    if (_sceneQualityNote.trim().isNotEmpty) {
      await TtsQueue.instance.speak(
        _sceneQualityNote,
        source: SpeechSource.assistant,
      );
    }

    _watchNarration();
  }

  void _watchNarration() {
    _sceneWatch?.cancel();
    _sceneWatch = Timer.periodic(const Duration(milliseconds: 250), (t) {
      // Dijeda pengguna: `toggleSceneNarration` sudah membereskan semuanya.
      if (!_sceneNarrating) {
        t.cancel();
        _sceneWatch = null;
        return;
      }
      if (TtsQueue.instance.isSpeaking) return;

      // Selesai wajar. Deskripsinya dilupakan supaya tombol Berhenti/Lanjut
      // ikut hilang: tidak ada lagi yang bisa dihentikan, dan menyisakan
      // tombol yang tidak melakukan apa-apa lebih membingungkan daripada
      // tidak ada tombol sama sekali.
      t.cancel();
      _sceneWatch = null;
      _sceneNarrating = false;
      _scenePaused = false;
      _sceneNarration = null;
      notifyListeners();
    });
  }

  Future<void> describeSceneNow() => _handleDescribeScene();

  Future<void> _handleDescribeScene() async {
    // Gerbang masuk, bukan sekadar tombol yang dimatikan di layar.
    //
    // Jalur ini punya DUA pemicu - tombol kiri dan perintah suara
    // "deskripsikan" - dan mematikan tombolnya saja meninggalkan pintu kedua
    // terbuka lebar. Penjaganya harus di sini, di satu tempat yang dilewati
    // keduanya.
    if (!canDescribeScene) return;

    _sceneBusy = true;
    // Deskripsi lama dibuang SEKARANG, sebelum yang baru diminta. Kalau
    // pengguna menekan foto saat narasi lama dijeda, yang dijeda itu tidak
    // boleh hidup lagi sesudahnya - dia sudah pindah ke suasana lain.
    _sceneWatch?.cancel();
    _sceneWatch = null;
    _sceneNarration = null;
    _sceneQualityNote = '';
    _scenePaused = false;
    _sceneNarrating = false;
    notifyListeners();

    _setState(VoiceState.processingLlm);
    // Lewat `_speakResponse`, bukan `onSpeak?.call` langsung. `onSpeak` hanya
    // dipasang VoiceScreen; dipanggil dari mode lain lewat perintah suara
    // "deskripsikan", kalimat ini dulu hilang tanpa jejak dan pengguna
    // menunggu dalam diam selama Moondream2 dibangunkan.
    unawaited(_speakResponse('Saya foto sekitarmu dulu, tunggu sebentar.'));

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

      // Gerbang kualitas di sisi ponsel DIMATIKAN untuk jalur ini.
      //
      // Fotonya selalu dikirim. Dulu `captureJpeg` menilai ketajaman dan
      // cahaya lebih dulu, dan foto yang tidak lolos berhenti di sini tanpa
      // pernah sampai ke Moondream2 - lengkap dengan percobaan ulang yang
      // membuat satu permintaan memakan beberapa detik sebelum akhirnya
      // menyerah. Untuk pengguna, itu terasa seperti aplikasi yang menolak
      // bekerja tanpa sebab yang bisa dia perbaiki.
      //
      // Kejujurannya tidak ikut hilang, hanya pindah tempat: server tetap
      // menilai kualitas foto dan mengirim catatannya kembali, dan catatan
      // itu dibacakan `_speakQualityNote` di akhir jawaban ("Fotonya gelap,
      // jadi hasilnya mungkin tidak tepat"). Jadi deskripsi dari foto buruk
      // tetap datang dengan keraguannya, bukan sebagai kepastian - yang
      // hilang cuma penolakannya.
      final jpeg = await _camera.captureJpeg(gateQuality: false);
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

      // Caption Moondream2 diterjemahkan ke Bahasa Indonesia di perangkat.
      //
      // Penerjemah kamus kata-per-kata buatan sendiri sudah dibuang dari
      // repo ini. Ia menerjemahkan sebagian kalimat lalu menyerah pada
      // sisanya, dan yang dihasilkan adalah campuran dua bahasa yang tidak
      // konsisten dari satu foto ke foto berikutnya: kadang Indonesia,
      // kadang Inggris, kadang setengah. Untuk pengguna yang mengandalkan
      // telinga, tebakan yang tidak konsisten lebih sulit diikuti daripada
      // satu bahasa yang tetap.
      //
      // ML Kit Translate menyelesaikan justru bagian itu: kalimat utuh atau
      // tidak sama sekali. `toIndonesian` mengembalikan null - tidak pernah
      // separuh - kalau modelnya belum terunduh atau terjemahannya tidak
      // layak, dan di jalur itu kita kembali persis ke perilaku lama:
      // penanda "Dalam bahasa Inggris." plus caption aslinya.
      final englishCaption = scene.descriptionEn;
      final translated =
          await TranslationService.instance.toIndonesian(englishCaption);
      final speakInEnglish = translated == null;
      final description = translated ?? englishCaption;

      _response = description;
      _setState(VoiceState.responded);

      // Penanda "Dalam bahasa Inggris." hanya diucapkan di jalur mundur,
      // dan itu bukan basa-basi.
      //
      // Di jalur itu TTS berpindah locale ke en-US tepat sesudah kalimat ini.
      // Tanpa aba-aba, pengguna tunanetra mendengar suaranya tiba-tiba
      // berganti bahasa di tengah aplikasi yang seluruhnya Bahasa Indonesia,
      // dan kesimpulan pertama yang wajar adalah aplikasinya rusak.
      //
      // Sebaliknya, kalau terjemahan berhasil, penanda itu HARUS hilang:
      // mengumumkan "Dalam bahasa Inggris" lalu berbicara Indonesia adalah
      // kebingungan yang kita ciptakan sendiri.
      //
      // Semuanya lewat ANTREAN, bukan langsung ke mesin.
      //
      // Dulu jalur ini memanggil `TTSService` langsung karena antrean belum
      // bisa membawa bahasa. Akibatnya deskripsi sepanjang belasan detik
      // duduk di luar seluruh arbitrase: narasi mode yang mengantre di
      // belakangnya kedaluwarsa lalu dibuang diam-diam, gerbang suara lepas
      // lebih awal karena antreannya tampak kosong, dan peringatan bahaya
      // memotong deskripsinya lewat `stop()` yang membatalkan SISA rantainya
      // sekalian - kalimat kedua dan ketiga hilang tanpa jejak.
      //
      // Sebagai `assistant`, ketiganya kebal gerbang, kebal kedaluwarsa, dan
      // menahan gerbang sampai selesai. Bahaya kritis tetap boleh memotong,
      // tapi sekarang sisanya tetap di antrean dan tetap terucap sesudahnya.
      _sceneNarration = description;
      _sceneNarrationEnglish = speakInEnglish;
      _sceneQualityNote = scene.message.trim();
      await _narrateScene();
    } on CaptureRejected catch (rejected) {
      // Jaring pengaman, bukan jalur biasa.
      //
      // Dengan `gateQuality: false` di atas, penilaian kualitas tidak lagi
      // menolak apa pun, jadi cabang ini praktis tidak pernah tercapai. Ia
      // dipertahankan karena `CameraCaptureService` masih bisa melemparnya
      // untuk sebab lain - kamera yang tidak mengembalikan satu frame pun,
      // misalnya - dan menghapusnya berarti kegagalan itu naik sebagai
      // exception mentah ke `catch` di bawah, yang kalimatnya jauh lebih
      // tidak berguna bagi pengguna.
      debugPrint('[VoiceProvider] foto ditolak: $rejected');
      _response = rejected.message;
      _setState(VoiceState.responded);
    } catch (e) {
      debugPrint('[VoiceProvider] _handleDescribeScene error: $e');
      await _handleLocal('Gagal mendeskripsikan suasana. Coba lagi.');
    } finally {
      // Dilepas di sini, bukan sesudah narasi selesai: sejak `_narrateScene`
      // berjalan, yang menjaga tombol kiri adalah `_sceneNarrating`. Menahan
      // `_sceneBusy` sampai narasi habis berarti tombol Berhenti tidak pernah
      // punya kesempatan mengembalikan kendali ke pengguna.
      _sceneBusy = false;
      notifyListeners();

      // Di `finally`, bukan di akhir jalur sukses: foto yang ditolak gerbang
      // kualitas adalah hasil yang PALING sering terjadi di tempat gelap, dan
      // meninggalkan kamera pada preset foto persis setelah itu berarti mode
      // aliran di bawahnya melanjutkan dengan beban tiga kali lipat.
      if (previousPreset != null && previousPreset != CapturePreset.capture) {
        await _camera.initCamera(preset: previousPreset);
      }
    }
  }

  // Catatan kualitas server ("Fotonya gelap, jadi hasilnya mungkin tidak
  // tepat") sekarang ikut disimpan di `_sceneQualityNote` dan diucapkan
  // `_narrateScene` sebagai utterance ketiga.
  //
  // Digabung ke sana, bukan dibiarkan berdiri sendiri, karena ia bagian dari
  // jawaban yang sama: kalau pengguna menghentikan lalu melanjutkan narasi,
  // keraguan itu harus ikut terdengar lagi. Dipisah, pengguna mendengar
  // deskripsi dari foto gelap sebagai kepastian pada pemutaran kedua.
  //
  // Tetap utterance TERPISAH dari deskripsinya, dengan locale Bahasa
  // Indonesia: deskripsinya sendiri mungkin dibacakan dalam Bahasa Inggris,
  // dan menyambung dua bahasa dalam satu utterance membuat TTS mengucapkan
  // salah satunya dengan fonetik yang keliru.



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

    // Jalur pintas "carikan [barang]" ikut dijaga. Ia memindahkan mode tanpa
    // lewat `_handleModeSwitch`, jadi penjagaan di sana tidak menutupinya -
    // dan justru perintah inilah yang paling sering dipakai untuk masuk Cari
    // Objek.
    if (_butuhServerTapiMati(AppMode.findObject)) {
      _consecutiveFailures = 0;
      await _respond(_pesanButuhServer(AppMode.findObject), save: false);
      return;
    }

    // `announce: false` - suaranya diurus di sini, satu kalimat untuk satu
    // kejadian. Lihat catatan di [FindObjectProvider.setTarget].
    _findObject.setTarget(target, announce: false);

    // Prefiksnya sengaja TIDAK menyebut targetnya.
    //
    // `announceEntry` di FindObjectScreen sudah menyebutnya, dan ia yang
    // harus - dari sana kalimatnya tetap benar walau modenya dimasuki lewat
    // lembar Pilih Mode, tanpa prefiks sama sekali. Menyebutkannya di kedua
    // tempat menghasilkan "Baik, mencari kacamata. Cari Objek aktif. Mencari
    // kacamata..." - satu barang, dua kali, dalam satu tarikan napas.
    final changed = await _appMode.setMode(
      AppMode.findObject,
      spokenPrefix: 'Baik.',
    );
    if (changed) {
      // Sisanya diucapkan `announceEntry` di FindObjectScreen sesudah layarnya
      // terpasang: "Baik. Cari Objek aktif. Mencari kacamata, tekan tombol
      // kiri bawah untuk memindai sekitarmu."
      _consecutiveFailures = 0;
      _setState(VoiceState.responded);
      onNavigateBack?.call();
    } else {
      // Sudah di mode ini, jadi tidak ada `announceEntry` yang akan datang -
      // kalimat lengkapnya harus keluar dari sini. Tombolnya ikut disebut:
      // mengganti barang tanpa memberi tahu cara memindainya meninggalkan
      // pengguna dengan target baru dan tidak ada isyarat untuk melanjutkan.
      await _respond(
        'Sekarang mencari $target. '
        'Tekan tombol kiri bawah untuk memindai sekitarmu.',
        save: false,
      );
      onNavigateBack?.call();
    }
  }

  Future<void> _respond(String message, {bool save = true}) async {
    _response = message;
    _lastActivity = DateTime.now();
    if (save) _history.add(ChatTurn(isUser: false, text: message));

    // Urutannya dibalik dari versi sebelumnya, dan itu yang membuat gerbang
    // suara bekerja.
    //
    // `_setState(responded)` adalah yang menutup gerbang, dan `endVoiceSession`
    // hanya menahan gerbang kalau jawabannya SUDAH ada di antrean. Kalau state
    // dipindahkan lebih dulu seperti dulu, antreannya masih kosong pada saat
    // itu, gerbang lepas seketika, dan narasi mode yang tertahan langsung
    // berebut dengan jawaban yang baru menyusul sepersekian detik kemudian.
    final speaking = _speakResponse(message);
    _setState(VoiceState.responded);
    await speaking;
  }

  /// Ucapkan jawaban asisten. Selalu bersumber [SpeechSource.assistant],
  /// jadi ia tidak pernah ikut terbungkam gerbang suaranya sendiri.
  Future<void> _speakResponse(String message) async {
    if (onSpeak != null) {
      onSpeak!(message);
      return;
    }
    // Cadangan ini dulu menembak langsung ke mesin TTS, melewati antrean.
    // `onSpeak` hanya dipasang VoiceScreen, jadi sejak mic bekerja dari
    // semua mode, jalur inilah yang dipakai Mode Deteksi dan Navigasi -
    // tempat narasi rintangan sedang berjalan. Dua sumber suara yang tidak
    // saling tahu berarti jawaban Vinara dan peringatan "ada orang di depan"
    // saling menimpa. Lewat antrean, keduanya bergiliran.
    await TtsQueue().speak(
      message,
      tier: SpeechTier.info,
      source: SpeechSource.assistant,
    );
  }

  /// AS-20 - pengguna menekan tombol Bicara lagi saat Vinara masih bicara:
  /// memotong tanpa nada khusus, langsung mulai dengar lagi.
  Future<void> interruptAndListenAgain() async {
    // `TtsQueue.interruptByUser()`, bukan `TTSService.stop()`.
    //
    // Bedanya satu hal, dan hal itu soal keselamatan: antrean menolak
    // memotong Critical yang ditandai tidak bisa dipotong. "Awas, lubang di
    // depan" yang terpenggal jadi "awas, lu-" lebih buruk daripada tidak ada,
    // dan pengguna tunanetra tidak punya layar untuk memeriksa sisanya.
    // `TTSService.stop()` tidak tahu apa-apa soal tier, jadi ia memotong
    // semuanya tanpa kecuali.
    await TtsQueue.instance.interruptByUser();
    await startListening();
  }

  /// State yang berarti "asisten sudah selesai mengurus perintah ini".
  ///
  /// Dipakai sebagai satu-satunya titik penutup gerbang suara. Menyebarnya
  /// ke tiap jalur - jawaban, galat, batas waktu, perintah tak dikenali -
  /// berarti setiap jalur baru yang ditambahkan nanti berpeluang lupa
  /// menutupnya, dan gerbang yang tidak pernah tertutup membuat aplikasi
  /// bisu bagi orang yang seluruh antarmukanya adalah suara.
  static const _terminalStates = {
    VoiceState.idle,
    VoiceState.responded,
    VoiceState.noSpeech,
    VoiceState.tooNoisy,
    VoiceState.transcribeFailed,
    VoiceState.unrecognized,
    VoiceState.ambiguous,
    VoiceState.allFailed,
    VoiceState.fallbackActive,
  };

  /// [keepVoiceGate] dipakai jalur yang berpindah ke state akhir **sebelum**
  /// jawabannya diucapkan - state-nya spesifik (`noSpeech`, `allFailed`) dan
  /// dipakai layar, jadi tidak bisa diserahkan begitu saja ke `_respond` yang
  /// selalu memasang `responded`.
  ///
  /// Tanpa penanda ini, gerbang lepas satu langkah terlalu awal: kalimat
  /// "Waktu habis, silakan coba lagi." berangkat ke antrean yang sudah
  /// terbuka lagi, dan arahan jalur bertier Warning memotongnya.
  void _setState(VoiceState state, {bool keepVoiceGate = false}) {
    _state = state;
    // Gerbang tidak lepas seketika di sini: kalau jawabannya sudah masuk
    // antrean, `endVoiceSession` menahannya sampai jawaban itu habis
    // diucapkan. Karena itu `_respond` memasukkan ucapannya DULU, baru
    // memanggil fungsi ini.
    if (!keepVoiceGate && _terminalStates.contains(state)) {
      TtsQueue.instance.endVoiceSession();
    }
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
    _holdCapTimer?.cancel();
    // Pengawas narasi berdetak tiap 250 ms dan memanggil `notifyListeners`.
    // Dibiarkan hidup sesudah provider mati, ia memanggil listener di objek
    // yang sudah dibuang - satu-satunya jejaknya di rilis adalah kebocoran
    // yang tidak pernah kelihatan.
    _sceneWatch?.cancel();
    _stt.cancel();
    // Sesi yang mati bersama providernya tidak akan pernah menutup gerbangnya
    // sendiri. Penjaga waktu memang menangkapnya, tapi 30 detik hening bagi
    // orang yang seluruh antarmukanya suara adalah 30 detik terlalu lama.
    TtsQueue.instance.endVoiceSession();
    super.dispose();
  }
}

/// Durasi minimum jari menempel sebelum mikrofon menyala.
///
/// Nilainya sengaja disamakan dengan `kLongPressTimeout` Flutter (500 ms),
/// karena yang benar-benar mengukurnya adalah pengenal gestur tekan-tahan
/// milik framework, bukan kode ini. Dua angka yang berbeda untuk satu ambang
/// yang sama hanya akan berselisih tanpa ada yang menyadarinya.
const Duration kHoldToTalkMinPress = Duration(milliseconds: 500);

/// Batas atas satu sesi tekan-tahan.
///
/// Ini bukan soal panjang perintah - frasa terpanjang di [CommandParser] cuma
/// tiga kata. Ini soal tombol yang tertekan tanpa sengaja di dalam tas atau
/// saku: tanpa batas, mikrofonnya menyala sampai baterainya habis.
const Duration kHoldToTalkMaxHold = Duration(seconds: 10);

/// Kelonggaran di atas [kHoldToTalkMaxHold] untuk `listenFor`/`pauseFor`.
///
/// Gunanya memastikan timer aplikasi selalu yang memotong sesi lebih dulu,
/// bukan batas internal paketnya.
const Duration kHoldToTalkGrace = Duration(seconds: 2);

/// Kode locale Bahasa Indonesia bawaan, dipakai kalau daftar perangkat tidak
/// bisa dibaca atau tidak memuat satu pun varian Indonesia.
const String kDefaultSttLocale = 'id_ID';

/// Pilih varian Bahasa Indonesia dari daftar locale perangkat.
///
/// Mengembalikan null kalau tidak ada yang cocok. Pemanggil WAJIB tetap
/// memakai [kDefaultSttLocale] dalam kasus itu, bukan menyerahkan pilihan ke
/// bawaan perangkat.
///
/// Urutan kandidatnya disengaja. Android masih memakai kode lama `in` untuk
/// Bahasa Indonesia, warisan ISO 639 sebelum 1989 yang tidak pernah diperbarui
/// karena Java sudah terlanjur memakainya, jadi satu perangkat bisa menuliskan
/// `id_ID` sementara perangkat lain hanya menerima `in_ID`. Varian berkode
/// negara didahulukan karena model bahasanya lebih spesifik.
String? pickIndonesianLocale(List<({String id, String name})> locales) {
  const exact = ['id_ID', 'id-ID', 'in_ID', 'in-ID', 'id', 'in'];
  for (final want in exact) {
    for (final l in locales) {
      if (l.id == want) return l.id;
    }
  }

  // Jaring terakhir: cocokkan awalan kode ATAU nama yang menyebut Indonesia.
  //
  // Awalannya diperiksa dengan pemisah, bukan `startsWith('id')` telanjang.
  // Tanpa itu `ida` atau `in-GB` hipotetis ikut tertangkap, dan memilih
  // bahasa yang salah jauh lebih buruk daripada gagal memilih.
  for (final l in locales) {
    final id = l.id.toLowerCase();
    final isIdPrefix = id == 'id' ||
        id == 'in' ||
        id.startsWith('id_') ||
        id.startsWith('id-') ||
        id.startsWith('in_') ||
        id.startsWith('in-');
    if (isIdPrefix || l.name.toLowerCase().contains('indonesia')) {
      return l.id;
    }
  }
  return null;
}
