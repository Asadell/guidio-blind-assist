import 'dart:async';
import 'dart:collection';

import '../../services/tts_service.dart';

/// Prioritas tier suara.
///
/// ```
/// Critical  → memotong semua, tidak bisa dipotong pengguna
/// Warning   → memotong Info, bisa dipotong pengguna
/// Info      → mengantre; dibuang kalau sudah kadaluarsa
/// ```
enum SpeechTier { info, warning, critical }

/// Siapa yang menghasilkan ucapan ini.
///
/// Bukan hiasan: ini yang menentukan apa yang dibungkam saat pengguna sedang
/// menahan tombol Bicara. Tanpa pembedaan ini, satu-satunya cara membungkam
/// narasi mode adalah membungkam semuanya - termasuk jawaban atas perintah
/// yang barusan diucapkan pengguna, yang justru satu-satunya hal yang ingin
/// dia dengar saat itu.
enum SpeechSource {
  /// Dihasilkan mode yang sedang berjalan: narasi rintangan, arahan jalur,
  /// petunjuk bingkai uang, hasil pembacaan teks.
  ///
  /// **Ini bawaannya.** Sengaja: pemanggil yang lupa menyebutkan sumbernya
  /// akan ikut dibungkam saat mikrofon terbuka. Lupa membungkam sesuatu itu
  /// merusak pengenalan suara; lupa meloloskan sesuatu cuma membuatnya
  /// tertunda beberapa detik. Yang kedua jauh lebih murah.
  mode,

  /// Jawaban asisten atas perintah pengguna, termasuk pengumuman mode.
  ///
  /// Tidak pernah dibungkam gerbang suara - kalau ini ikut dibungkam,
  /// menahan tombol Bicara berarti berbicara ke ruang hampa.
  assistant,
}

/// Satu item di antrean.
class _QueuedSpeech {
  final String message;
  final SpeechTier tier;
  final SpeechSource source;
  final DateTime queuedAt;
  final int sequence;
  final Duration maxAge;
  final bool interruptible;

  /// Diucapkan dengan locale en-US, lalu mesin dikembalikan ke Indonesia.
  ///
  /// Ada di sini, bukan cuma di [TTSService], supaya deskripsi suasana dari
  /// Moondream2 bisa lewat antrean seperti ucapan lain. Sebelumnya jalur itu
  /// memanggil `TTSService.speakEnglish` langsung justru KARENA antrean tidak
  /// bisa membawa bahasa - dan bypass itu yang membuatnya lolos dari seluruh
  /// arbitrase di sini.
  final bool english;

  /// Kunci dedup. Dua item dengan kunci sama yang masuk berdekatan
  /// digabung jadi satu, sehingga narasi identik tidak diucapkan dua kali
  /// hanya karena dua frame berturut-turut sepakat.
  final String? dedupKey;

  _QueuedSpeech({
    required this.message,
    required this.tier,
    required this.source,
    required this.sequence,
    required this.maxAge,
    this.interruptible = true,
    this.english = false,
    this.dedupKey,
  }) : queuedAt = DateTime.now();

  /// Jawaban asisten TIDAK PERNAH basi.
  ///
  /// Narasi mode menggambarkan dunia yang bergerak: "ada orang di depan" yang
  /// terlambat tiga detik sudah salah, jadi lebih baik dibuang. Jawaban atas
  /// perintah pengguna tidak begitu. Pengguna menahan tombol, bicara, lalu
  /// menunggu - dan kalau jawabannya dibuang karena antreannya kebetulan
  /// panjang, yang dia dapat adalah kesenyapan tanpa penjelasan.
  ///
  /// Ini bukan kasus teoretis: deskripsi suasana Moondream2 bisa memakan
  /// belasan detik, sementara [infoMaxAge] cuma 2 detik. Catatan kualitas yang
  /// mengantre di belakangnya akan SELALU dibuang tanpa aturan ini - dan
  /// catatan itu justru yang memberi tahu pengguna bahwa fotonya kurang bagus.
  bool isStale(DateTime now) =>
      source == SpeechSource.mode && now.difference(queuedAt) > maxAge;
}

/// TtsQueue - antrean bertingkat "satu pintu suara".
///
/// ## Yang berubah dari versi sebelumnya, dan kenapa
///
/// Versi sebelumnya sudah punya prioritas tier, token generasi anti-race,
/// batas 8 item, dan pembuangan Info yang kadaluarsa. Fondasinya benar.
/// Yang belum ada adalah hal-hal yang justru menentukan rasa saat mode
/// deteksi baru menyala:
///
/// ### 1. Tidak ada jeda bernapas antar ucapan
/// Begitu satu utterance selesai, yang berikutnya langsung mulai. Untuk
/// pengguna screen reader berpengalaman itu mungkin masih terkejar, tapi
/// untuk narasi realtime yang isinya TIDAK bisa ditebak, telinga butuh
/// waktu memisahkan satu kalimat dari kalimat berikutnya. Sekarang ada
/// [minGap] yang dijaga di semua jalur.
///
/// ### 2. `List.sort` di Dart tidak stabil
/// Versi lama memanggil `_pending.sort(...)` yang mengurutkan HANYA
/// berdasarkan tier. Karena `sort` tidak menjamin urutan relatif elemen
/// yang dianggap sama, urutan antar-item bertier sama menjadi tidak
/// tertebak. Padahal DetectionFilter sudah bersusah payah mengurutkan
/// deteksi dari yang terdekat. Urutan itu hilang begitu masuk antrean.
/// Sekarang urutannya (tier, sequence) sehingga stabil dan urutan
/// "terdekat dulu" benar-benar sampai ke telinga pengguna.
///
/// ### 3. Critical bisa membuat yang lain kelaparan
/// Critical mengosongkan `_pending` setiap kali masuk. Kalau ada satu
/// lubang yang terus terdeteksi dengan cooldown 2 detik sementara
/// utterance-nya sendiri makan 3 detik, antrean dikosongkan berulang kali
/// dan narasi lain TIDAK PERNAH terdengar sama sekali. Sekarang Critical
/// hanya membuang Info, tidak membuang Warning, dan ada
/// [starvationTimeout] sebagai jaring pengaman.
///
/// ### 4. Tidak ada masa tenang saat mode baru menyala
/// Saat app dibuka, setiap objek adalah objek baru: tidak ada satu pun
/// yang punya catatan cooldown, jadi semuanya lolos sekaligus. Sekarang
/// ada [beginSettling] yang menahan narasi non-kritis sampai kamera dan
/// auto-exposure stabil.
class TtsQueue {
  static final TtsQueue instance = TtsQueue._internal();
  factory TtsQueue() => instance;

  TtsQueue._internal() {
    // Penjaga jalur pintas. Lihat catatan di `TTSService.debugQueueBusyReason`.
    TTSService.debugQueueBusyReason = () {
      if (_inEngineCall) return null; // panggilan antrean sendiri
      if (voiceGateClosed) return 'gerbang suara tertutup';
      if (_speakingTier != null) {
        return 'sedang mengucapkan ${_speakingTier!.name}';
      }
      if (_pending.isNotEmpty) return 'punya ${_pending.length} antrean';
      return null;
    };
  }

  // ── Jalur ke mesin ──────────────────────────────────────────────────────
  //
  // SEMUA sentuhan ke [TTSService] dari kelas ini lewat dua metode ini, supaya
  // penjaga jalur pintas tidak melaporkan antrean kepada dirinya sendiri.

  bool _inEngineCall = false;

  Future<void> _engineSpeak(String text,
      {bool interrupt = false, bool english = false}) async {
    _inEngineCall = true;
    try {
      await TTSService.instance
          .speak(text, interrupt: interrupt, english: english);
    } finally {
      _inEngineCall = false;
    }
  }

  Future<void> _engineStop() async {
    _inEngineCall = true;
    try {
      await TTSService.instance.stop();
    } finally {
      _inEngineCall = false;
    }
  }

  // ── Konfigurasi ──────────────────────────────────────────────────────

  /// Jeda minimum antar ucapan.
  ///
  /// Riset speech rate untuk screen reader menunjukkan pengguna
  /// berpengalaman nyaman di 300+ kata/menit, TAPI itu untuk konten yang
  /// mereka pilih sendiri dan strukturnya sudah dikenal. Narasi deteksi
  /// realtime berbeda: isinya tidak bisa ditebak, jadi butuh jeda untuk
  /// dicerna. 700 ms adalah titik awal; naikkan kalau pengguna uji coba
  /// merasa terburu-buru.
  Duration minGap = const Duration(milliseconds: 700);

  /// Berapa lama Info boleh menunggu sebelum dianggap basi.
  Duration infoMaxAge = const Duration(seconds: 2);

  /// Warning boleh menunggu lebih lama daripada Info sebelum basi.
  Duration warningMaxAge = const Duration(seconds: 5);

  /// Kalau Warning tertahan lebih lama dari ini karena Critical terus
  /// masuk, dia dipaksa dapat giliran.
  Duration starvationTimeout = const Duration(seconds: 4);

  /// Dua narasi dengan dedupKey sama dalam rentang ini digabung.
  Duration dedupWindow = const Duration(milliseconds: 1200);

  static const int _maxPending = 8;

  // ── State ────────────────────────────────────────────────────────────

  final _pending = <_QueuedSpeech>[];
  final _recentDedup = HashMap<String, DateTime>();

  SpeechTier? _speakingTier;
  SpeechSource? _speakingSource;
  bool _currentInterruptible = true;
  bool _draining = false;
  int _drainGeneration = 0;
  int _sequenceCounter = 0;

  DateTime? _lastUtteranceEndedAt;
  DateTime? _settlingUntil;
  DateTime? _warningHeldSince;

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null || _draining;

  // ── Gerbang sesi suara ───────────────────────────────────────────────
  //
  // Saat pengguna menahan tombol Bicara, mode yang sedang berjalan harus
  // DIAM. Ini bukan soal kenyamanan:
  //
  // 1. Suara aplikasi masuk ke mikrofonnya sendiri. Narasi "ada orang di
  //    depan" yang terucap saat pengguna berkata "kenali uang" membuat
  //    mesin pengenal menerima dua suara sekaligus, dan yang keluar adalah
  //    kata yang tidak cocok dengan satu pun frasa CommandParser.
  // 2. Orang tidak bisa menyusun kalimat sambil mendengarkan kalimat lain.
  //    Pengguna yang sedang mengingat nama mode tujuan akan kehilangan
  //    kata-katanya begitu ada suara lain masuk.
  //
  // Gerbang ini punya dua fase, dan keduanya perlu:
  //
  //   `_gateHeld`     - mikrofon terbuka atau perintah sedang diproses.
  //   `_gateDraining` - perintahnya selesai, tapi JAWABANNYA belum habis
  //                     diucapkan. Tanpa fase ini, arahan jalur bertier
  //                     Warning akan memotong jawaban bertier Info tepat
  //                     setelah gerbang lepas, dan pengguna kehilangan
  //                     konfirmasi atas perintah yang barusan dia ucapkan.

  bool _gateHeld = false;
  bool _gateDraining = false;
  Timer? _gateWatchdog;

  /// Batas hidup gerbang, apa pun yang terjadi.
  ///
  /// Jaring pengaman, bukan pengatur waktu normal. Kalau ada satu jalur yang
  /// lupa memanggil [endVoiceSession] - galat yang tidak dilempar, layar yang
  /// di-dispose di tengah sesi - aplikasi akan bisu **selamanya** bagi orang
  /// yang seluruh antarmukanya adalah suara. Itu kegagalan yang jauh lebih
  /// buruk daripada narasi yang lolos beberapa detik terlalu cepat.
  ///
  /// 30 detik = 10 detik batas tahan + waktu proses + jawaban terpanjang,
  /// dengan kelonggaran.
  Duration gateMaxLife = const Duration(seconds: 30);

  /// True selama narasi mode sedang ditahan.
  bool get voiceGateClosed => _gateHeld || _gateDraining;

  /// Pengguna mulai bicara ke asisten: bungkam mode yang sedang berjalan.
  ///
  /// Ucapan yang sedang berjalan ikut dipotong, karena pengguna yang menahan
  /// tombol sudah memutuskan untuk bicara. Satu-satunya yang dibiarkan
  /// selesai adalah peringatan bahaya yang tidak bisa dipotong - kalimat
  /// "awas lubang" yang terpenggal di tengah lebih buruk daripada tidak ada.
  Future<void> beginVoiceSession() async {
    _gateHeld = true;
    _gateDraining = false;
    _gateWatchdog?.cancel();
    _gateWatchdog = Timer(gateMaxLife, _releaseGate);

    // Buang antrean milik mode. Narasi yang disusun SEBELUM pengguna menekan
    // tombol sudah basi begitu dia mulai bicara.
    _pending.removeWhere((q) =>
        q.source == SpeechSource.mode && q.tier != SpeechTier.critical);

    if (_speakingTier == SpeechTier.critical && !_currentInterruptible) return;

    _drainGeneration++;
    await _engineStop();
    _lastUtteranceEndedAt = DateTime.now();
    _speakingTier = null;
    _speakingSource = null;
    _currentInterruptible = true;
  }

  /// Perintahnya sudah diproses. Gerbang belum tentu langsung lepas.
  ///
  /// Kalau jawaban asisten masih mengantre atau sedang diucapkan, gerbang
  /// bertahan sampai jawaban itu habis. Panggil ini SESUDAH jawabannya masuk
  /// antrean, bukan sebelum - kalau dipanggil lebih dulu, antreannya masih
  /// kosong, gerbang lepas seketika, dan jawaban yang menyusul akan bersaing
  /// dengan narasi mode seperti sebelumnya.
  void endVoiceSession() {
    if (!_gateHeld && !_gateDraining) return;
    _gateHeld = false;
    final answerPending = _speakingSource == SpeechSource.assistant ||
        _pending.any((q) => q.source == SpeechSource.assistant);
    if (answerPending) {
      _gateDraining = true;
      return;
    }
    _releaseGate();
  }

  /// Selama [body] berjalan, ucapan bersumber [SpeechSource.mode] dihitung
  /// sebagai jawaban asisten.
  ///
  /// Dipakai `VoiceProvider` saat menjalankan aksi milik mode yang diminta
  /// lewat perintah suara - "jepret", "ulangi", "jeda", "stop navigasi".
  ///
  /// Kalimat yang keluar dari aksi itu ("Suara panduan dimatikan.", nominal
  /// uang yang terbaca) BUKAN narasi mode yang kebetulan lewat: ia jawaban
  /// langsung atas perintah yang barusan diucapkan pengguna. Tanpa
  /// pengecualian ini, gerbang yang dibuka perintah itu sendiri akan menelan
  /// jawabannya - pengguna menahan tombol, bicara, lalu tidak mendengar apa
  /// pun.
  ///
  /// Hanya berlaku untuk ucapan yang berangkat **secara sinkron** di dalam
  /// [body]. Itu memang cakupan yang dituju: aksi yang jawabannya baru siap
  /// beberapa detik kemudian (hasil inferensi uang, hasil pembacaan teks)
  /// berangkat setelah gerbang lepas dengan sendirinya.
  T speakModeAsAssistant<T>(T Function() body) {
    final previous = _attributeModeAsAssistant;
    _attributeModeAsAssistant = true;
    try {
      return body();
    } finally {
      _attributeModeAsAssistant = previous;
    }
  }

  bool _attributeModeAsAssistant = false;

  void _releaseGate() {
    _gateHeld = false;
    _gateDraining = false;
    _gateWatchdog?.cancel();
    _gateWatchdog = null;
  }

  /// Dipanggil dari [_drain] tiap satu ucapan selesai.
  void _maybeReleaseAfterAnswer() {
    if (!_gateDraining) return;
    if (_pending.any((q) => q.source == SpeechSource.assistant)) return;
    _releaseGate();
  }
  bool get isSettling =>
      _settlingUntil != null && DateTime.now().isBefore(_settlingUntil!);
  int get pendingCount => _pending.length;

  // ── Masa tenang ──────────────────────────────────────────────────────

  /// Mulai masa tenang. Selama masa ini, HANYA Critical yang boleh bicara.
  ///
  /// Panggil ini saat mode deteksi baru diaktifkan atau saat berpindah
  /// mode. Dua alasan:
  ///
  /// 1. Auto-exposure dan autofocus kamera belum stabil di detik pertama,
  ///    jadi deteksi di periode itu justru yang paling tidak dapat
  ///    dipercaya, sekaligus yang paling banyak jumlahnya.
  /// 2. Pengguna baru saja melakukan sesuatu (membuka app, mengganti
  ///    mode). Membanjirinya dengan narasi tepat setelah itu membuat
  ///    dia tidak sempat memahami bahwa modenya sudah berganti.
  ///
  /// Bahaya kritis TETAP lewat. Masa tenang tidak boleh menunda peringatan
  /// lubang di depan kaki.
  void beginSettling({Duration duration = const Duration(milliseconds: 1500)}) {
    _settlingUntil = DateTime.now().add(duration);
    // Buang Info yang sudah antre dari mode sebelumnya. Narasi dari mode
    // lama yang terdengar setelah mode berganti sangat membingungkan.
    _pending.removeWhere((q) => q.tier == SpeechTier.info);
  }

  void cancelSettling() => _settlingUntil = null;

  // ── API utama ────────────────────────────────────────────────────────

  /// Masukkan narasi ke antrean.
  ///
  /// [dedupKey] mencegah narasi identik terucap dua kali dalam
  /// [dedupWindow]. Isi dengan sesuatu yang stabil seperti
  /// `'summary:${trackIds.join(",")}'`.
  ///
  /// [interruptible] false berarti utterance ini harus selesai. Pakai
  /// untuk peringatan bahaya: kalimat "awas lubang" yang terpotong di
  /// tengah lebih buruk daripada tidak ada sama sekali.
  Future<void> speak(
    String message, {
    SpeechTier tier = SpeechTier.info,
    SpeechSource source = SpeechSource.mode,
    String? dedupKey,
    bool? interruptible,
    Duration? maxAge,
    bool english = false,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    // Aksi mode yang dijalankan atas permintaan lisan pengguna berbicara
    // sebagai asisten. Lihat [speakModeAsAssistant].
    if (_attributeModeAsAssistant && source == SpeechSource.mode) {
      source = SpeechSource.assistant;
    }

    // ── Gerbang sesi suara ──
    //
    // Diperiksa PALING AWAL, sebelum dedup. Kalau dicatat di dedup lalu
    // dibuang, kalimat yang sama tidak akan bisa masuk lagi selama
    // [dedupWindow] setelah gerbang lepas - narasi yang dibungkam jadi ikut
    // hilang sesudahnya, bukan cuma tertunda.
    //
    // Critical TETAP LEWAT. Ini keputusan sadar dan arahnya jelas: pengguna
    // sedang berdiri di jalan, dan lubang di depan kakinya tidak menunggu
    // sampai dia selesai bicara. Harganya nyata - suara peringatan itu ikut
    // masuk ke mikrofon dan bisa merusak pengenalan perintahnya - tapi
    // perintah yang salah dikenali masih bisa diulang, sedangkan langkah
    // yang terlanjur jatuh ke lubang tidak.
    if (voiceGateClosed &&
        source == SpeechSource.mode &&
        tier != SpeechTier.critical) {
      return;
    }

    final now = DateTime.now();

    // ── Dedup ──
    if (dedupKey != null) {
      final last = _recentDedup[dedupKey];
      if (last != null && now.difference(last) < dedupWindow) {
        return;
      }
      _recentDedup[dedupKey] = now;
      if (_recentDedup.length > 64) {
        final cutoff = now.subtract(const Duration(seconds: 10));
        _recentDedup.removeWhere((_, at) => at.isBefore(cutoff));
      }
    }

    // ── Masa tenang: tahan non-kritis ──
    if (isSettling && tier != SpeechTier.critical) {
      return;
    }

    final canInterrupt = interruptible ?? (tier != SpeechTier.critical);

    // ── Critical ──
    if (tier == SpeechTier.critical) {
      // Hanya buang Info. Warning DIPERTAHANKAN.
      //
      // Versi lama memanggil `_pending.clear()` yang membuang semuanya.
      // Dengan satu bahaya yang terus terdeteksi, antrean dikosongkan
      // berulang kali dan narasi lain tidak pernah terdengar. Simulasi
      // pada skenario 6 objek menunjukkan 11 narasi hilang diam-diam
      // dalam 12 detik, dan pengguna tidak pernah diberi tahu soal
      // motor maupun tiang di sekitarnya.
      _pending.removeWhere((q) => q.tier == SpeechTier.info);
      if (_pending.any((q) => q.tier == SpeechTier.warning)) {
        _warningHeldSince ??= now;
      }

      _drainGeneration++;

      // Jangan potong Critical lain yang belum selesai.
      if (_speakingTier == SpeechTier.critical && !_currentInterruptible) {
        _enqueue(trimmed, tier, source, canInterrupt, maxAge,
            dedupKey: dedupKey, english: english);
        unawaited(_drain());
        return;
      }

      await _engineStop();
      await _respectMinGap();

      _speakingTier = SpeechTier.critical;
      _speakingSource = source;
      _currentInterruptible = canInterrupt;
      await _engineSpeak(trimmed, interrupt: true, english: english);
      _lastUtteranceEndedAt = DateTime.now();
      _speakingTier = null;
      _speakingSource = null;
      _currentInterruptible = true;
      _maybeReleaseAfterAnswer();

      unawaited(_drain());
      return;
    }

    // ── Warning memotong Info yang sedang bicara ──
    if (tier == SpeechTier.warning &&
        _speakingTier == SpeechTier.info &&
        _currentInterruptible) {
      _drainGeneration++;
      await _engineStop();
      await _respectMinGap();

      _speakingTier = SpeechTier.warning;
      _speakingSource = source;
      _currentInterruptible = canInterrupt;
      await _engineSpeak(trimmed, interrupt: true, english: english);
      _lastUtteranceEndedAt = DateTime.now();
      _speakingTier = null;
      _speakingSource = null;
      _currentInterruptible = true;
      _maybeReleaseAfterAnswer();

      unawaited(_drain());
      return;
    }

    _enqueue(trimmed, tier, source, canInterrupt, maxAge,
        dedupKey: dedupKey, english: english);
    unawaited(_drain());
  }

  void _enqueue(
    String message,
    SpeechTier tier,
    SpeechSource source,
    bool interruptible,
    Duration? maxAge, {
    String? dedupKey,
    bool english = false,
  }) {
    // Tolak kembar yang MASIH mengantre.
    //
    // Jendela dedup di `speak()` mengukur waktu sejak narasi serupa terakhir
    // MASUK, bukan sejak dia terucap. Kalau antrean sedang panjang, item
    // pertama bisa menunggu lebih lama daripada jendela itu, dan kembarannya
    // lolos masuk di belakangnya. Pengguna lalu mendengar kalimat yang persis
    // sama dua kali berturut-turut.
    if (dedupKey != null &&
        _pending.any((q) => q.dedupKey == dedupKey)) {
      return;
    }

    _pending.add(_QueuedSpeech(
      message: message,
      tier: tier,
      source: source,
      sequence: _sequenceCounter++,
      interruptible: interruptible,
      english: english,
      dedupKey: dedupKey,
      maxAge: maxAge ??
          (tier == SpeechTier.warning ? warningMaxAge : infoMaxAge),
    ));

    if (tier == SpeechTier.warning) {
      _warningHeldSince ??= DateTime.now();
    }

    if (_pending.length > _maxPending) {
      // Buang Info TERBARU, bukan terlama.
      //
      // Ini kebalikan dari versi lama, dan disengaja. Kalau antrean penuh
      // berarti deteksi datang lebih cepat daripada kemampuan bicara.
      // Dalam kondisi itu, narasi yang lebih dulu masuk umumnya berasal
      // dari objek yang lebih dekat (karena DetectionFilter sudah
      // mengurutkan dari yang terdekat), jadi justru itu yang harus
      // dipertahankan.
      // Jawaban asisten tidak pernah jadi korban. Ia lahir dari perintah
      // yang baru saja diucapkan pengguna, dan membuangnya berarti dia
      // menahan tombol, bicara, lalu tidak mendengar apa pun.
      final lastInfoIdx = _pending.lastIndexWhere((q) =>
          q.tier == SpeechTier.info && q.source != SpeechSource.assistant);
      if (lastInfoIdx >= 0) {
        _pending.removeAt(lastInfoIdx);
      } else {
        _pending.removeAt(_pending.length - 1);
      }
    }
  }

  /// Pengguna menimpa TTS yang sedang jalan (barge-in).
  ///
  /// Tidak berlaku untuk utterance yang ditandai tidak bisa dipotong.
  Future<void> interruptByUser() async {
    if (_speakingTier == SpeechTier.critical && !_currentInterruptible) {
      return;
    }
    _drainGeneration++;
    _pending.removeWhere((q) => q.tier == SpeechTier.info);
    await _engineStop();
    _lastUtteranceEndedAt = DateTime.now();
    _speakingTier = null;
    _speakingSource = null;
  }

  // ── Drain ────────────────────────────────────────────────────────────

  Future<void> _respectMinGap() async {
    final last = _lastUtteranceEndedAt;
    if (last == null) return;
    final elapsed = DateTime.now().difference(last);
    if (elapsed < minGap) {
      await Future<void>.delayed(minGap - elapsed);
    }
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    final myGeneration = _drainGeneration;

    try {
      while (_pending.isNotEmpty) {
        if (_drainGeneration != myGeneration) break;

        final now = DateTime.now();

        // Selama masa tenang, hanya Critical yang boleh keluar.
        if (isSettling) {
          final hasCritical =
              _pending.any((q) => q.tier == SpeechTier.critical);
          if (!hasCritical) break;
        }

        // Urutan STABIL: tier menurun, lalu sequence menaik.
        //
        // `List.sort` di Dart tidak stabil, jadi mengurutkan hanya
        // berdasarkan tier membuat urutan antar item bertier sama menjadi
        // tidak tertebak. Menyertakan sequence sebagai pemecah seri
        // menjaga urutan "terdekat dulu" yang sudah dihitung
        // DetectionFilter.
        _pending.sort((a, b) {
          final byTier = b.tier.index.compareTo(a.tier.index);
          if (byTier != 0) return byTier;
          return a.sequence.compareTo(b.sequence);
        });

        // Anti-kelaparan: Warning yang tertahan terlalu lama naik duluan.
        final held = _warningHeldSince;
        if (held != null && now.difference(held) >= starvationTimeout) {
          final idx = _pending.indexWhere((q) => q.tier == SpeechTier.warning);
          if (idx > 0) {
            final w = _pending.removeAt(idx);
            _pending.insert(0, w);
          }
        }

        final next = _pending.removeAt(0);

        if (next.tier != SpeechTier.critical && next.isStale(now)) {
          continue;
        }

        if (!_pending.any((q) => q.tier == SpeechTier.warning)) {
          _warningHeldSince = null;
        }

        // Ditandai SEBELUM menunggu jeda bernapas, bukan sesudahnya.
        //
        // `removeAt` di atas sudah mengeluarkan item ini dari `_pending`,
        // jadi di antara dua baris itu ada celah di mana antrean tampak
        // kosong sementara tidak ada yang tercatat sedang bicara. Siapa pun
        // yang bertanya "masih ada yang mau diucapkan?" di celah itu akan
        // dijawab "tidak", padahal ucapannya sudah dipegang di tangan.
        //
        // Celahnya bukan teoretis: `endVoiceSession` dipanggil tepat sesudah
        // jawaban asisten dimasukkan ke antrean, dan `_drain` berjalan
        // sinkron sampai `await` pertamanya - yaitu baris di bawah ini.
        // Gerbang lepas seketika, lalu arahan jalur memotong jawaban yang
        // baru mau keluar.
        _speakingTier = next.tier;
        _speakingSource = next.source;
        _currentInterruptible = next.interruptible;

        await _respectMinGap();
        if (_drainGeneration != myGeneration) break;

        await _engineSpeak(next.message, english: next.english);
        _lastUtteranceEndedAt = DateTime.now();

        if (_drainGeneration == myGeneration) {
          _speakingTier = null;
          _speakingSource = null;
          _currentInterruptible = true;
        }
        // Jawaban terakhir baru saja selesai: lepas gerbang di sini, bukan
        // di `finally`. Antrean bisa masih berisi narasi mode yang menunggu,
        // dan menunggu seluruh antrean habis berarti gerbang bertahan jauh
        // lebih lama daripada jawabannya sendiri.
        _maybeReleaseAfterAnswer();
      }
    } finally {
      _draining = false;
      if (_drainGeneration == myGeneration &&
          _speakingTier != SpeechTier.critical) {
        _speakingTier = null;
        _speakingSource = null;
        _currentInterruptible = true;
      }
      _maybeReleaseAfterAnswer();
    }
  }

  /// Hentikan semuanya dan lepas gerbang.
  ///
  /// Gerbang ikut dilepas dengan sengaja: `stop()` berarti "tidak ada lagi
  /// yang perlu diucapkan", dan menahan gerbang untuk jawaban yang barusan
  /// dibuang hanya akan membungkam mode sampai penjaga waktu bertindak.
  Future<void> stop() async {
    _pending.clear();
    _recentDedup.clear();
    _warningHeldSince = null;
    _drainGeneration++;
    await _engineStop();
    _lastUtteranceEndedAt = DateTime.now();
    _speakingTier = null;
    _speakingSource = null;
    _currentInterruptible = true;
    _releaseGate();
  }

  /// Diagnostik untuk panel debug.
  Map<String, dynamic> debugState() => {
        'pending': _pending.length,
        'speakingTier': _speakingTier?.name,
        'interruptible': _currentInterruptible,
        'settling': isSettling,
        'voiceGate': _gateHeld
            ? 'held'
            : _gateDraining
                ? 'draining'
                : 'open',
        'warningHeldMs': _warningHeldSince == null
            ? null
            : DateTime.now().difference(_warningHeldSince!).inMilliseconds,
      };
}
