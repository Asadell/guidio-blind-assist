import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/money_tflite_service.dart';
import '../widgets/nominal_card.dart' show terbilangRupiah;

/// State machine "nol sentuhan" Mode Kenali Uang — bagian 9 IMPLEMENTASI.md
/// (UG-01..UG-12, UG-17, UG-18). Sepenuhnya on-device dan sepenuhnya MOCK:
/// tidak ada model nominal sungguhan, deteksi disimulasikan lewat Timer.
///
/// UG-13 (offline banner), UG-14 (izin kamera), UG-15 (senyap/TTS mati), dan
/// UG-16 (font scale 200%) sengaja TIDAK dimodelkan di sini — itu murni
/// keputusan lapisan UI (screen membaca GlobalConditionsProvider / izin
/// sistem / MediaQuery langsung), sesuai instruksi agar provider ini tetap
/// murni state-machine mock.
enum MoneyState {
  idle,        // UG-01
  noCandidate, // UG-08
  partial,     // UG-02
  folded,      // UG-10
  fit,         // UG-03
  glare,       // UG-12a
  dark,        // UG-12b
  processing,  // UG-04
  detected,    // UG-05 (lembar pertama sesi)
  multiple,    // UG-09a/UG-09b (≥2 lembar, breakdown ditampilkan)
  consecutive, // UG-11 (lembar berturut-turut, total berjalan)
  uncertain,   // UG-06
  notMoney,    // UG-07
  foreign,     // UG-18
  resetAnnounce, // UG-17
}

/// Pola getar bagian 3.6 — `positive` (2×25ms) untuk bingkai pas,
/// `moneyAck` (3×40ms) khusus UG-15 (dipicu dari layar, bukan dari sini).
enum MoneyHaptic { positive }

const _kNoCandidateHints = [
  'Dekatkan sedikit uangnya ke kamera',
  'Cari tempat yang lebih terang',
  'Posisikan uang rata di tengah bingkai',
];

const _kDenoms = [1000, 2000, 5000, 10000, 20000, 50000, 100000];
const _kNotMoneyLabels = ['kartu', 'kwitansi', 'tiket', 'nota belanja'];

class MoneyProvider extends ChangeNotifier {
  final _rand = Random();

  MoneyState _state = MoneyState.idle;
  MoneyState get state => _state;

  /// Rincian lembar dalam sesi berjalan: denominasi → jumlah lembar.
  final Map<int, int> _breakdown = {};
  Map<int, int>? get sessionBreakdown => _breakdown.isEmpty ? null : Map.unmodifiable(_breakdown);
  int get sessionTotal => _breakdown.entries.fold(0, (sum, e) => sum + e.key * e.value);
  int get sheetCount => _breakdown.values.fold(0, (sum, v) => sum + v);

  int _lastAmount = 0;
  int get lastAmount => _lastAmount;

  int _noCandidateHintIndex = 0;
  String get noCandidateHint => _kNoCandidateHints[_noCandidateHintIndex];

  String _notMoneyLabel = _kNotMoneyLabels.first;
  String get notMoneyLabel => _notMoneyLabel;

  int _resetAnnounceTotal = 0;
  int get resetAnnounceTotal => _resetAnnounceTotal;

  bool get busy => _state == MoneyState.processing;

  /// Callback keluar — screen yang mengubahnya jadi suara/getar sungguhan
  /// lewat TtsProvider/Vibration, supaya provider ini tetap tidak bergantung
  /// pada BuildContext (pola sama dengan `CameraProvider.onFrameReady`).
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(MoneyHaptic pattern)? onHaptic;

  Timer? _stepTimer;
  Timer? _hintRotateTimer;
  Timer? _sessionResetTimer;
  bool _running = false;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) => onSpeak?.call(text, tier);
  void _haptic(MoneyHaptic p) => onHaptic?.call(p);

  void _set(MoneyState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  /// Masuk mode (UG-01) — mulai siklus otomatis dari awal.
  void start() {
    if (_running) return;
    _running = true;
    _breakdown.clear();
    _lastAmount = 0;
    _set(MoneyState.idle);
    if (!_useRealModel) _scheduleFromIdle();
  }

  /// Keluar mode — hentikan semua timer, jangan bicara lagi.
  void pause() {
    _running = false;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    _sessionResetTimer?.cancel();
  }

  /// Dipanggil dari tombol kamera BottomActionBar — "paksa deteksi ulang".
  void forceRedetect() {
    if (!_running) return;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    if (_useRealModel) {
      _consecutiveMiss = 0;
      _set(MoneyState.fit);
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

  /// Hasil buffer terbaru dari model — diperbarui tiap frame, dipakai saat
  /// snapAndAnnounce() dipanggil. Tidak pernah auto-diumumkan.
  MoneyResult? _latestResult;

  /// Jeda antar inferensi. Klasifikasi 224x224 ringan, tapi tidak ada
  /// gunanya berjalan tiap frame: pengguna butuh waktu memposisikan uang.
  static const _inferenceInterval = Duration(milliseconds: 600);

  /// Coba muat model on-device. Mengembalikan false kalau file belum ada —
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

  /// Umpan frame kamera. Aman dipanggil tiap frame — di-throttle sendiri.
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

    // Selalu perbarui buffer — snapAndAnnounce() akan membaca ini saat user
    // menekan tombol, sehingga hasilnya selalu mencerminkan apa yang kamera
    // lihat saat itu tanpa delay inferensi tambahan.
    _latestResult = result;

    if (result.detected && result.valueIdr != null) {
      _consecutiveMiss = 0;
      // Update visual state ke "fit" (bingkai hijau) agar user tahu
      // kamera sudah melihat uang dan siap di-snap — tapi TIDAK bicara.
      if (_state != MoneyState.fit && _state != MoneyState.detected) {
        _set(MoneyState.fit);
      }
      return;
    }

    switch (result.failure) {
      case MoneyFailure.lowConfidence:
        // UG-06 — ragu. Tampilkan bingkai + indikator tapi tidak bicara
        // secara otomatis; pesan muncul saat user snap.
        _consecutiveMiss = 0;
        if (_state != MoneyState.uncertain) {
          _set(MoneyState.uncertain);
        }
      case MoneyFailure.modelUnavailable:
        _useRealModel = false;
        if (!_running) return;
        _scheduleFromIdle();
      case MoneyFailure.error:
      case null:
        // UG-08 — tidak ada kandidat: pill instruksi berputar tiap 5 detik.
        _consecutiveMiss++;
        if (_consecutiveMiss >= 8 && _state != MoneyState.noCandidate) {
          _set(MoneyState.noCandidate);
          _startHintRotation();
        }
    }
  }

  /// Dipanggil saat user menekan tombol kiri — umumkan hasil buffer terbaru.
  ///
  /// Tidak ada delay inferensi: model sudah berjalan di background tiap 600ms,
  /// jadi _latestResult selalu segar. User mendapat jawaban instan.
  void snapAndAnnounce() {
    if (!_running) return;

    if (!_useRealModel) {
      // Jalur mock: paksa siklus deteksi ulang seperti semula.
      forceRedetect();
      return;
    }

    final result = _latestResult;
    if (result == null || !result.detected || result.valueIdr == null) {
      // Tidak ada uang di frame saat ini — beri tahu user.
      final msg = (result?.failure == MoneyFailure.lowConfidence)
          ? 'Belum yakin, dekatkan sedikit dan tahan diam.'
          : 'Tidak ada uang terdeteksi. Arahkan kamera ke uang.';
      _speak(msg, tier: SpeechTier.warning);
      return;
    }

    // Ada uang — masuk ke alur deteksi normal (session tracking + TTS).
    _enterDetected(result.valueIdr!);
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

  void _enterUncertain() {
    _set(MoneyState.uncertain);
    _speak('Belum yakin, dekatkan sedikit dan tahan diam.', tier: SpeechTier.warning);
    _after(2200, _enterProcessing);
  }

  void _enterNotMoney() {
    _notMoneyLabel = _kNotMoneyLabels[_rand.nextInt(_kNotMoneyLabels.length)];
    _set(MoneyState.notMoney);
    _speak('Ini sepertinya $_notMoneyLabel, bukan uang.', tier: SpeechTier.info);
    // Aturan #3: total yang sudah ada tidak boleh hilang diam-diam.
    _after(2200, () => _breakdown.isEmpty ? _scheduleFromIdle() : _settleSession());
  }

  void _enterForeign() {
    _set(MoneyState.foreign);
    _speak('Ini sepertinya uang asing atau rusak, saya belum bisa membacanya.', tier: SpeechTier.warning);
    _after(2200, () => _breakdown.isEmpty ? _scheduleFromIdle() : _settleSession());
  }

  // -------------------------------------------------------------- detected

  void _enterDetected(int amount) {
    _lastAmount = amount;
    _breakdown.update(amount, (v) => v + 1, ifAbsent: () => 1);
    _armSessionResetTimer();

    if (sheetCount == 1) {
      _set(MoneyState.detected);
      _speak(terbilangRupiah(amount), tier: SpeechTier.info);
      _scheduleNextSheetOrWait();
    } else {
      _set(MoneyState.multiple);
      _speak('Total ${terbilangRupiah(sessionTotal)}, dari $sheetCount lembar.', tier: SpeechTier.info);
      _after(2600, () {
        _set(MoneyState.consecutive);
        _scheduleNextSheetOrWait();
      });
    }
  }

  /// Lembar berikutnya bisa masuk kapan saja dalam jendela 60 detik — atau
  /// tidak sama sekali, sehingga jatuh ke UG-17.
  void _scheduleNextSheetOrWait() {
    if (_rand.nextDouble() < 0.5) {
      _after(4000 + _rand.nextInt(9000), () {
        if (_state == MoneyState.detected || _state == MoneyState.consecutive) {
          _enterPartial();
        }
      });
    }
    // Kalau tidak dijadwalkan lembar baru, layar tetap diam di
    // detected/consecutive sampai timer 60 detik (UG-17) menyala sendiri.
  }

  void _armSessionResetTimer() {
    _sessionResetTimer?.cancel();
    _sessionResetTimer = Timer(const Duration(seconds: 60), () {
      if (_breakdown.isNotEmpty) _settleSession();
    });
  }

  /// UG-17 — total yang hilang WAJIB diumumkan, tidak pernah hilang diam-diam.
  void _settleSession() {
    _sessionResetTimer?.cancel();
    _resetAnnounceTotal = sessionTotal;
    _set(MoneyState.resetAnnounce);
    _speak('Total ${terbilangRupiah(_resetAnnounceTotal)} direset.', tier: SpeechTier.info);
    _after(2400, () {
      _breakdown.clear();
      _scheduleFromIdle();
    });
  }
}
