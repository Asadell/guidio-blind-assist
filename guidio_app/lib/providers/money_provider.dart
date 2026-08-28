import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/money_tflite_service.dart';
import '../widgets/nominal_card.dart' show terbilangRupiah;

/// State machine Mode Kenali Uang - bagian 9 IMPLEMENTASI.md
/// (UG-01..UG-12, UG-18). Sepenuhnya on-device.
///
/// **Tidak ada akumulasi sesi.** Mode ini menjawab satu pertanyaan saja:
/// "lembar yang sedang saya hadapkan ke kamera ini nominalnya berapa?"
/// Tombol kiri mengumumkan nominal frame saat itu, lalu selesai - tidak ada
/// total berjalan, tidak ada rincian lembar, tidak ada kartu "total direset".
/// Penjumlahan otomatis justru berbahaya di sini: pengguna tunanetra tidak
/// bisa melihat lembar mana yang sudah terhitung, jadi satu lembar yang
/// ter-scan dua kali menghasilkan total yang salah tanpa satu pun tanda.
///
/// **Jalur mock hanya hidup di build debug.** Simulasi Timer-nya memanggil
/// `_enterDetected(_kDenoms[_rand.nextInt(...)])` - yaitu **mengucapkan
/// nominal acak dengan nada yakin**. Di rilis, jalur itu bisa tercapai hanya
/// karena model gagal dimuat, dan pengguna tunanetra tidak punya cara
/// membedakannya dari hasil sungguhan. Salah menyebut nominal berarti
/// kerugian uang nyata, jadi di rilis kegagalan model berakhir di satu
/// kalimat jujur: fiturnya tidak tersedia. Titik.
///
/// UG-13 (offline banner), UG-14 (izin kamera), UG-15 (senyap/TTS mati), dan
/// UG-16 (font scale 200%) sengaja TIDAK dimodelkan di sini - itu murni
/// keputusan lapisan UI (screen membaca GlobalConditionsProvider / izin
/// sistem / MediaQuery langsung).
enum MoneyState {
  idle,        // UG-01
  noCandidate, // UG-08
  partial,     // UG-02
  folded,      // UG-10
  fit,         // UG-03
  glare,       // UG-12a
  dark,        // UG-12b
  processing,  // UG-04
  detected,    // UG-05 (nominal lembar yang sedang dihadapi kamera)
  uncertain,   // UG-06 (model belum yakin - pratinjau saja, TIDAK memblokir)
  notMoney,    // UG-07
  foreign,     // UG-18
}

/// Pola getar bagian 3.6 - `positive` (2×25ms) untuk uang yang terlihat utuh,
/// `moneyAck` (3×40ms) khusus UG-15 (dipicu dari layar, bukan dari sini).
enum MoneyHaptic { positive }

const _kNoCandidateHints = [
  'Dekatkan sedikit uangnya ke kamera',
  'Cari tempat yang lebih terang',
  'Ratakan uangnya, jangan sampai tertekuk',
];

const _kDenoms = [1000, 2000, 5000, 10000, 20000, 50000, 100000];
const _kNotMoneyLabels = ['kartu', 'kwitansi', 'tiket', 'nota belanja'];

class MoneyProvider extends ChangeNotifier {
  final _rand = Random();

  MoneyState _state = MoneyState.idle;
  MoneyState get state => _state;

  int _lastAmount = 0;
  int get lastAmount => _lastAmount;

  /// Jawaban terakhir lolos gerbang keyakinan atau tidak.
  ///
  /// Layar memakainya untuk memilih antara kartu nominal biasa dan kartu
  /// berpagar "Sepertinya". Nilainya menyusul [lastAmount], jadi keduanya
  /// selalu bicara tentang lembar yang sama.
  bool _lastAnswerCertain = true;
  bool get lastAnswerCertain => _lastAnswerCertain;

  int _noCandidateHintIndex = 0;
  String get noCandidateHint => _kNoCandidateHints[_noCandidateHintIndex];

  String _notMoneyLabel = _kNotMoneyLabels.first;
  String get notMoneyLabel => _notMoneyLabel;

  bool get busy => _state == MoneyState.processing;

  /// Callback keluar - screen yang mengubahnya jadi suara/getar sungguhan
  /// lewat TtsProvider/Vibration, supaya provider ini tetap tidak bergantung
  /// pada BuildContext (pola sama dengan `CameraProvider.onFrameReady`).
  /// [langsung] true berarti kalimat ini adalah jawaban atas tekanan tombol,
  /// jadi ia harus menimpa apa pun yang sedang bicara alih-alih mengantre.
  /// Layar meneruskannya ke `TtsProvider.answerNow`. Lihat catatan di
  /// `TtsQueue.answerNow` soal kenapa jawaban tekanan tombol tidak boleh
  /// lewat arbitrase yang sama dengan narasi yang datang sendiri.
  void Function(String text, SpeechTier tier, {bool langsung})? onSpeak;
  void Function(MoneyHaptic pattern)? onHaptic;

  Timer? _stepTimer;
  Timer? _hintRotateTimer;
  bool _running = false;

  void _speak(String text,
          {SpeechTier tier = SpeechTier.info, bool langsung = false}) =>
      onSpeak?.call(text, tier, langsung: langsung);
  void _haptic(MoneyHaptic p) => onHaptic?.call(p);

  void _set(MoneyState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  /// Simulasi hanya boleh hidup di build debug. `kDebugMode` dikompilasi
  /// menjadi konstanta, jadi di rilis seluruh cabang mock ikut tereliminasi.
  static bool get _mockAllowed => kDebugMode;

  /// True kalau model tidak tersedia DAN mock tidak boleh jalan - layar
  /// memakai ini untuk menonaktifkan tombol dengan alasan yang jujur.
  bool get isUnavailable => !_useRealModel && !_mockAllowed;

  /// Masuk mode (UG-01) - mulai siklus otomatis dari awal.
  void start() {
    if (_running) return;
    _running = true;
    _lastAmount = 0;
    _lastAnswerCertain = true;
    _set(MoneyState.idle);
    if (!_useRealModel) _fallbackWhenModelMissing();
  }

  /// Satu titik keputusan untuk "model tidak ada": simulasi di debug,
  /// pengakuan jujur di rilis. Tidak ada jalan ketiga yang menyebut angka.
  void _fallbackWhenModelMissing() {
    if (_mockAllowed) {
      _scheduleFromIdle();
      return;
    }
    _set(MoneyState.idle);
    _speak(
      'Pengenalan uang tidak tersedia saat ini. Model belum siap di perangkat ini.',
      tier: SpeechTier.warning,
    );
  }

  /// Keluar mode - hentikan semua timer, jangan bicara lagi.
  void pause() {
    _running = false;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
  }

  /// Dipanggil dari tombol kamera BottomActionBar - "paksa deteksi ulang".
  void forceRedetect() {
    if (!_running) return;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    if (_useRealModel) {
      _consecutiveMiss = 0;
      _set(MoneyState.fit);
      return;
    }
    if (!_mockAllowed) {
      _speak(
        'Pengenalan uang tidak tersedia saat ini.',
        tier: SpeechTier.warning,
        langsung: true,
      );
      return;
    }
    _enterFit();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Jalur inferensi NYATA (on-device TFLite)
  //
  // Saat model tersedia, siklus mock berbasis Timer dimatikan total dan
  // state digerakkan oleh hasil klasifikasi frame sungguhan. Mock tetap
  // dipertahankan sebagai cadangan supaya seluruh 18 state tetap bisa
  // diperiksa walau file model belum ada di perangkat.
  // ─────────────────────────────────────────────────────────────────────

  bool _useRealModel = false;
  bool get useRealModel => _useRealModel;

  bool _inferring = false;
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveMiss = 0;

  // ── Multi-frame voting ────────────────────────────────────────────────────
  //
  // Satu frame yang kebetulan diprediksi salah (mis. sudut ekstrem, gerakan)
  // tidak boleh langsung memindahkan state ke "fit". Tiga frame berturut-turut
  // yang sepakat pada nominal yang sama memberi kepastian yang jauh lebih kuat
  // dan sangat murah - classifikasi 224x224 berjalan tiap 600ms, jadi 3 frame
  // hanya menambah ~1,2 detik penundaan dalam kasus terburuk.
  //
  // Trade-off yang diterima: user yang menggerakkan kamera cepat perlu sedikit
  // lebih lama menunggu panduan "Uang terlihat, tekan Kenali Uang".
  // Manfaatnya: prediksi sesaat pada foto yang susah (50rb_a yang terdeteksi
  // sebagai 10rb) tidak pernah memunculkan panduan itu dan mendorong user
  // menekan tombol snap.
  static const int _kRequiredConsecutive = 3;
  int _consecutiveDetections = 0;
  int? _lastDetectedValue;

  /// Hasil buffer terbaru dari model - diperbarui tiap frame, dipakai saat
  /// snapAndAnnounce() dipanggil. Tidak pernah auto-diumumkan.
  MoneyResult? _latestResult;

  /// Jeda antar inferensi. Klasifikasi 224x224 ringan, tapi tidak ada
  /// gunanya berjalan tiap frame: pengguna butuh waktu memposisikan uang.
  static const _inferenceInterval = Duration(milliseconds: 600);

  /// Coba muat model on-device. Mengembalikan false kalau file belum ada -
  /// pemanggil lalu membiarkan siklus mock yang jalan.
  Future<bool> enableRealModel() async {
    final ok = await MoneyTFLiteService.instance.load();
    _useRealModel = ok;
    if (ok) {
      _stepTimer?.cancel();
      _hintRotateTimer?.cancel();
      _set(MoneyState.idle);
    }
    return ok;
  }

  /// Umpan frame kamera. Aman dipanggil tiap frame - di-throttle sendiri.
  Future<void> submitFrame(CameraImage image) async {
    if (!_useRealModel || !_running || _inferring) return;
    if (DateTime.now().difference(_lastInference) < _inferenceInterval) return;

    _inferring = true;
    _lastInference = DateTime.now();
    try {
      final result = await MoneyTFLiteService.instance.classifyCameraImage(image);
      _applyRealResult(result);
    } finally {
      _inferring = false;
    }
  }

  void _applyRealResult(MoneyResult result) {
    if (!_running) return;

    // Selalu perbarui buffer - snapAndAnnounce() akan membaca ini saat user
    // menekan tombol, sehingga hasilnya selalu mencerminkan apa yang kamera
    // lihat saat itu tanpa delay inferensi tambahan.
    _latestResult = result;

    if (result.detected && result.valueIdr != null) {
      _consecutiveMiss = 0;

      // Multi-frame voting: hitung frame berturut-turut yang sepakat.
      // Reset counter kalau nominal berubah di antara frame.
      if (result.valueIdr == _lastDetectedValue) {
        _consecutiveDetections++;
      } else {
        _consecutiveDetections = 1;
        _lastDetectedValue = result.valueIdr;
      }

      // State `fit` tetap dijaga ketat: hanya untuk hasil yang YAKIN dan
      // sudah stabil N frame. Ia yang memunculkan panduan "Uang terlihat,
      // tekan Kenali Uang" - sebuah janji visual "posisi pas", dan janji itu
      // tidak boleh diberikan pada tebakan berpagar.
      //
      // Dulu janji itu berupa bingkai panduan yang berubah hijau. Bingkainya
      // sudah dihapus (kamera memotret seluruh gambar, tidak ada area yang
      // harus dibidik), yang tersisa kalimat panduannya.
      //
      // Yang berubah: hasil berpagar tidak lagi memblokir apa pun. Dulu ia
      // memunculkan kartu "Belum yakin" yang menutup layar dan membuat
      // pengguna mengulang gerakan tanpa tahu apa yang salah. Sekarang ia
      // cuma pratinjau bernada netral - tombolnya tetap bisa ditekan kapan
      // saja dan tetap menjawab.
      final steady = _consecutiveDetections >= _kRequiredConsecutive;
      if (_state == MoneyState.detected) return;

      if (result.certain && steady) {
        if (_state != MoneyState.fit) _set(MoneyState.fit);
      } else if (!result.certain && _state != MoneyState.uncertain) {
        _set(MoneyState.uncertain);
      }
      return;
    }

    // Tidak ada hasil sama sekali - reset voting counter.
    _consecutiveDetections = 0;
    _lastDetectedValue = null;

    switch (result.failure) {
      case MoneyFailure.modelUnavailable:
        _useRealModel = false;
        if (!_running) return;
        _fallbackWhenModelMissing();
      case MoneyFailure.error:
      case null:
        // UG-08 - tidak ada kandidat: pill instruksi berputar tiap 5 detik.
        _consecutiveMiss++;
        if (_consecutiveMiss >= 8 && _state != MoneyState.noCandidate) {
          _set(MoneyState.noCandidate);
          _startHintRotation();
        }
    }
  }

  /// Dipanggil saat user menekan tombol kiri - umumkan hasil buffer terbaru.
  ///
  /// Tidak ada delay inferensi: model sudah berjalan di background tiap 600ms,
  /// jadi _latestResult selalu segar. User mendapat jawaban instan.
  void snapAndAnnounce() {
    if (!_running) return;

    if (!_useRealModel) {
      // Tanpa model: di debug jatuh ke simulasi, di rilis mengaku tidak bisa.
      // Yang tidak pernah terjadi di rilis adalah menyebut angka.
      forceRedetect();
      return;
    }

    final result = _latestResult;
    if (result == null || !result.detected || result.valueIdr == null) {
      _speak(_noReadingAdvice(result),
          tier: SpeechTier.warning, langsung: true);
      return;
    }

    // Selalu menjawab. Yang membedakan cuma nadanya, dan itu dibawa
    // `result.certain` sampai ke kalimat TTS dan kartu di layar.
    _enterDetected(result.valueIdr!, certain: result.certain, langsung: true);
  }

  /// Instruksi saat model TIDAK mengeluarkan hasil apa pun.
  ///
  /// Cakupannya sekarang sempit dan itu disengaja. Keraguan model bukan lagi
  /// urusan fungsi ini: hasil berpagar tetap dijawab dengan nominalnya lewat
  /// [_enterDetected]. Yang tersisa di sini hanya dua keadaan yang benar-benar
  /// tidak punya angka untuk disampaikan - model belum siap, atau belum ada
  /// satu pun frame yang selesai diproses.
  String _noReadingAdvice(MoneyResult? result) {
    if (result == null) {
      return 'Belum ada yang terbaca. Arahkan kamera ke uang, lalu tekan lagi.';
    }
    if (result.failure == MoneyFailure.modelUnavailable) {
      return 'Pengenalan uang tidak tersedia saat ini.';
    }
    return 'Gambar belum bisa dibaca. Arahkan kamera ke uang, lalu tekan lagi.';
  }

  void _startHintRotation() {
    _hintRotateTimer?.cancel();
    _hintRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _noCandidateHintIndex = (_noCandidateHintIndex + 1) % _kNoCandidateHints.length;
      notifyListeners();
    });
  }

  /// Nominal yang TIDAK didukung model (emisi/pecahan di luar 6 kelas).
  /// Dipakai layar untuk menyusun pesan keterbatasan yang jujur (UG-18).
  List<int> get unsupportedValues => MoneyTFLiteService.unsupportedValues;

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  // ---------------------------------------------------------------- idle

  void _scheduleFromIdle() {
    _set(MoneyState.idle);
    _after(2200 + _rand.nextInt(2000), () {
      if (_rand.nextDouble() < 0.22) {
        _enterNoCandidate();
      } else {
        _enterPartial();
      }
    });
  }

  void _enterNoCandidate() {
    _noCandidateHintIndex = 0;
    _set(MoneyState.noCandidate);
    _hintRotateTimer?.cancel();
    _hintRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _noCandidateHintIndex = (_noCandidateHintIndex + 1) % _kNoCandidateHints.length;
      notifyListeners();
    });
    _after(7000 + _rand.nextInt(4000), () {
      _hintRotateTimer?.cancel();
      _enterPartial();
    });
  }

  // -------------------------------------------------------------- partial

  void _enterPartial() {
    _set(MoneyState.partial);
    _after(1200 + _rand.nextInt(900), () {
      if (_rand.nextDouble() < 0.15) {
        _enterFolded();
      } else {
        _enterFit();
      }
    });
  }

  void _enterFolded() {
    _set(MoneyState.folded);
    _after(1600 + _rand.nextInt(700), _enterFit);
  }

  // ------------------------------------------------------------------ fit

  void _enterFit() {
    _set(MoneyState.fit);
    _haptic(MoneyHaptic.positive);
    _after(550 + _rand.nextInt(400), () {
      final r = _rand.nextDouble();
      if (r < 0.08) {
        _enterGlare();
      } else if (r < 0.16) {
        _enterDark();
      } else {
        _enterProcessing();
      }
    });
  }

  void _enterGlare() {
    _set(MoneyState.glare);
    _after(1400 + _rand.nextInt(500), _enterFit);
  }

  void _enterDark() {
    _set(MoneyState.dark);
    _speak('Terlalu gelap. Coba nyalakan senter kamera.', tier: SpeechTier.warning);
    _after(1700 + _rand.nextInt(600), _enterFit);
  }

  // ------------------------------------------------------------ processing

  void _enterProcessing() {
    _set(MoneyState.processing);
    _after(380 + _rand.nextInt(80), _resolveDetection);
  }

  void _resolveDetection() {
    // Pertahanan berlapis: satu-satunya tempat di seluruh aplikasi yang bisa
    // mengucapkan nominal tanpa melihat uang sungguhan. Kalau suatu saat ada
    // jalur baru yang lolos ke sini di rilis, ia berhenti di sini.
    if (!_mockAllowed) {
      _set(MoneyState.idle);
      return;
    }
    final r = _rand.nextDouble();
    if (r < 0.70) {
      _enterDetected(_kDenoms[_rand.nextInt(_kDenoms.length)]);
    } else if (r < 0.82) {
      _enterUncertain();
    } else if (r < 0.92) {
      _enterNotMoney();
    } else {
      _enterForeign();
    }
  }

  /// Jalur mock saja. Di jalur nyata keadaan ini tidak pernah bicara sendiri
  /// dan tidak pernah menahan jawaban - lihat [_applyRealResult].
  void _enterUncertain() {
    _set(MoneyState.uncertain);
    _after(2200, _enterProcessing);
  }

  void _enterNotMoney() {
    _notMoneyLabel = _kNotMoneyLabels[_rand.nextInt(_kNotMoneyLabels.length)];
    _set(MoneyState.notMoney);
    _speak('Ini sepertinya $_notMoneyLabel, bukan uang.', tier: SpeechTier.info);
    // Aturan #3: total yang sudah ada tidak boleh hilang diam-diam.
    _after(2200, _scheduleFromIdle);
  }

  void _enterForeign() {
    _set(MoneyState.foreign);
    _speak('Ini sepertinya uang asing atau rusak, saya belum bisa membacanya.', tier: SpeechTier.warning);
    _after(2200, _scheduleFromIdle);
  }

  // -------------------------------------------------------------- detected

  /// Satu lembar, satu jawaban. Menekan tombol lagi pada lembar yang sama
  /// hanya mengulang nominal yang sama - tidak pernah menambah apa pun.
  ///
  /// [certain] menentukan NADA, bukan boleh atau tidaknya menjawab. Pagarnya
  /// harus terdengar di kalimat pertama, bukan disimpan di akhir: pengguna
  /// tunanetra sering menekan tombol berikutnya sebelum kalimat selesai, jadi
  /// "Sepertinya" wajib jadi kata pembuka. Tier warning ikut dipakai supaya
  /// antrean suara tidak menyamakannya dengan jawaban yang pasti.
  void _enterDetected(int amount,
      {bool certain = true, bool langsung = false}) {
    _lastAmount = amount;
    _lastAnswerCertain = certain;
    _set(MoneyState.detected);
    _speak(
      certain
          ? terbilangRupiah(amount)
          : 'Sepertinya ${terbilangRupiah(amount)}. Kalau ragu, dekatkan '
              'sedikit lalu tekan lagi.',
      tier: certain ? SpeechTier.info : SpeechTier.warning,
      // Jalur nyata SELALU berangkat dari tekanan tombol, jadi pemanggilnya
      // menyalakan ini. Jalur mock berjalan sendiri lewat Timer dan tetap
      // mengantre seperti narasi biasa.
      langsung: langsung,
    );
  }
}
