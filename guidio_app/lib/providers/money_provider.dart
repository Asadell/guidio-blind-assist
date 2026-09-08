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
/// **Nol sentuhan.** Mode ini tidak menunggu tombol. Selama layarnya terbuka,
/// setiap frame kamera diklasifikasi dan nominal yang lolos gerbang keyakinan
/// diumumkan sendiri. Alasannya sederhana dan tidak bisa disiasati dari sisi
/// antarmuka: pengguna yang memegang lembar uang di satu tangan dan ponsel di
/// tangan lain tidak punya jari ketiga untuk mencari tombol, dan mencari
/// tombol berarti menggoyang kamera tepat pada saat gambarnya harus diam.
///
/// Dua pagar menjaga supaya "bicara sendiri" tidak berubah jadi "bicara
/// terus-menerus":
///
/// 1. **Hanya hasil yang YAKIN yang bersuara.** Tebakan berpagar
///    ("sepertinya") tetap tergambar di layar untuk pengguna awas, tapi tidak
///    pernah diucapkan. Nominal yang salah sebut berarti kerugian uang nyata,
///    dan pengguna tunanetra tidak punya cara memeriksanya.
/// 2. **Jeda [_announceGap] sesudah ucapan sebelumnya SELESAI.** Bukan sejak
///    ucapan sebelumnya dimulai - kalau dihitung dari mulainya, kalimat
///    berikutnya menimpa ekor kalimat sebelumnya dan angkanya justru jadi
///    paling sulit didengar.
///
/// Suaranya bisa dimatikan lewat [voiceOn] (tombol kiri bawah), sama seperti
/// saklar suara Mode Navigasi. Deteksi tetap berjalan saat dimatikan, jadi
/// menyalakannya kembali langsung berbunyi tanpa perlu mengarahkan ulang.
///
/// **Tidak ada akumulasi sesi.** Mode ini menjawab satu pertanyaan saja:
/// "lembar yang sedang saya hadapkan ke kamera ini nominalnya berapa?"
/// Yang diumumkan selalu nominal frame saat itu - tidak ada total berjalan,
/// tidak ada rincian lembar, tidak ada kartu "total direset".
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

  /// Ditanya berkala: apakah mesin suara MASIH berbunyi?
  ///
  /// Disuntik layar (dari `TtsProvider.isActive`) supaya provider ini tetap
  /// tidak menyentuh BuildContext maupun TtsQueue langsung - pola yang sama
  /// dengan [onSpeak]. Kalau tidak dipasang, jeda antar pengumuman jatuh
  /// kembali ke jarak waktu murni, yang lebih longgar tapi tidak pernah
  /// berbahaya.
  bool Function()? isSpeaking;

  // ── Saklar suara ────────────────────────────────────────────────────────
  //
  // Menyala sejak awal, dan itu keputusan yang disengaja: mode ini dibuka
  // justru untuk mendengar nominalnya. Mode Deteksi Objek memilih sebaliknya
  // (mulai mati) karena ia layar pertama aplikasi dan peringatan pertama dari
  // ponsel yang masih di saku hampir selalu keliru. Di sini tidak ada
  // taruhan seperti itu: pengguna sudah sengaja masuk sambil memegang uang.
  bool _voiceOn = true;
  bool get voiceOn => _voiceOn;

  /// Nyalakan / matikan pengumuman otomatis.
  ///
  /// Deteksi TIDAK ikut berhenti. Yang dimatikan hanya suaranya, jadi
  /// menyalakannya lagi langsung menjawab dengan lembar yang sedang dihadapi
  /// kamera alih-alih menunggu tiga frame kesepakatan dari nol.
  void setVoiceOn(bool value) {
    if (_voiceOn == value) return;
    _voiceOn = value;
    // Jeda dihitung ulang dari sekarang: kalimat konfirmasi saklarnya sendiri
    // ("Suara dinyalakan") adalah ucapan, dan nominal yang menyusulnya harus
    // ikut menunggu gilirannya seperti ucapan lain.
    _speechEndedAt = DateTime.now();
    notifyListeners();
  }

  /// Jeda minimum antara satu pengumuman nominal dan pengumuman berikutnya,
  /// dihitung sejak ucapan sebelumnya SELESAI.
  static const _announceGap = Duration(seconds: 1);

  Timer? _speechWatch;
  bool _wasSpeaking = false;
  DateTime _speechEndedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pengamat akhir ucapan.
  ///
  /// Dipisah dari siklus inferensi karena keduanya berdenyut pada laju yang
  /// berbeda: inferensi tiap 600 ms, sementara "kapan persisnya kalimat tadi
  /// selesai" butuh resolusi yang lebih halus. Tanpa pengamat sendiri, jeda
  /// satu detik akan diukur dari titik pemeriksaan terdekat dan melar jadi
  /// satu setengah detik yang terasa seperti mode ini berhenti bekerja.
  void _startSpeechWatch() {
    _speechWatch?.cancel();
    _speechWatch = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = isSpeaking?.call() ?? false;
      if (_wasSpeaking && !now) _speechEndedAt = DateTime.now();
      _wasSpeaking = now;
    });
  }

  /// Umumkan nominal kalau semua pagarnya lolos.
  ///
  /// Diam adalah hasil yang sah di sini, dan sengaja tidak diberi tanda apa
  /// pun: getar atau nada tiap kali jeda belum lewat justru mengembalikan
  /// kebisingan yang jedanya ada untuk menghilangkan.
  void _maybeAutoAnnounce(int amount) {
    if (!_voiceOn) return;
    if (_wasSpeaking || (isSpeaking?.call() ?? false)) return;
    final now = DateTime.now();
    if (now.difference(_speechEndedAt) < _announceGap) return;

    // Dicatat SEBELUM bicara, bukan sesudah. Mesin suara butuh waktu untuk
    // benar-benar mulai berbunyi, dan selama tenggang itu `isSpeaking` masih
    // false - tanpa catatan ini, pemeriksaan berikutnya 600 ms kemudian
    // melihat "tidak ada yang bicara, jedanya sudah lewat" dan mengucapkan
    // nominal kedua di atas nominal pertama yang baru saja dimulai.
    _speechEndedAt = now;
    _enterDetected(amount);
  }

  Timer? _stepTimer;
  Timer? _hintRotateTimer;
  bool _running = false;
  int _epoch = 0;

  void _speak(String text,
          {SpeechTier tier = SpeechTier.info, bool langsung = false}) {
    if (!_running) return;
    onSpeak?.call(text, tier, langsung: langsung);
  }
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
    _speechEndedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _wasSpeaking = false;
    _startSpeechWatch();
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
    _epoch++;
    _running = false;
    _stepTimer?.cancel();
    _hintRotateTimer?.cancel();
    _speechWatch?.cancel();
    _speechWatch = null;
    _wasSpeaking = false;
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
  // lebih lama sebelum nominalnya terucap.
  //
  // Manfaatnya jauh lebih besar sesudah mode ini jadi nol sentuhan. Dulu
  // prediksi sesaat yang keliru cuma memunculkan panduan yang salah dan
  // pengguna masih harus menekan tombol untuk mendengar angkanya. Sekarang
  // tidak ada tombol yang menyaring apa pun: satu frame yang salah tebak
  // langsung terucap sebagai nominal. Kesepakatan tiga frame inilah yang
  // menggantikan perbuatan sadar menekan tombol.
  static const int _kRequiredConsecutive = 3;
  int _consecutiveDetections = 0;
  int? _lastDetectedValue;

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
    final myEpoch = _epoch;
    try {
      final result = await MoneyTFLiteService.instance.classifyCameraImage(image);
      if (_epoch != myEpoch) {
        _inferring = false;
        return;
      }
      _applyRealResult(result);
    } finally {
      _inferring = false;
    }
  }

  void _applyRealResult(MoneyResult result) {
    if (!_running) return;

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

      // Gerbangnya sekarang menentukan BOLEH ATAU TIDAKNYA BICARA, bukan
      // sekadar kalimat panduan mana yang tampil. Itu menaikkan taruhannya:
      // yakin + stabil N frame berarti nominalnya langsung terucap tanpa ada
      // perbuatan pengguna di antaranya, jadi keduanya dijaga apa adanya dan
      // tidak boleh dilonggarkan "supaya lebih responsif".
      final steady = _consecutiveDetections >= _kRequiredConsecutive;

      if (result.certain && steady) {
        // Nol sentuhan: kesepakatan tiga frame pada nominal yang sama sudah
        // cukup untuk menjawab. `fit` bukan lagi terminal yang menunggu
        // tombol - ia cuma jendela penghitungan yang dilewati, dan keadaan
        // ini langsung menyusul di frame berikutnya.
        //
        // Pagar jedanya ada di dalam [_maybeAutoAnnounce]; kalau belum
        // waktunya bicara, keadaannya tetap berpindah supaya kartu di layar
        // tidak tertinggal di belakang apa yang dilihat kamera.
        _maybeAutoAnnounce(result.valueIdr!);
        // Kartu di layar disamakan dengan apa yang dilihat kamera SEKARANG,
        // tidak menunggu jedanya lewat. Kalau pengguna berganti lembar di
        // detik yang sama, kartu yang masih menampilkan nominal sebelumnya
        // akan dibaca pendamping awas sebagai jawaban untuk lembar yang baru.
        if (_lastAmount != result.valueIdr || _state != MoneyState.detected) {
          _lastAmount = result.valueIdr!;
          _lastAnswerCertain = true;
          _set(MoneyState.detected);
        }
      } else if (result.certain) {
        // Yakin tapi belum stabil tiga frame. Ini jendela sekitar 1,8 detik,
        // dan dulu tidak terlihat sama sekali - layar tetap berbunyi "Arahkan
        // kamera ke uang" sementara uangnya sudah tepat di depan kamera dan
        // sistem sebenarnya sedang menghitung. Pengguna yang membaca panduan
        // itu justru menggeser kameranya dan menghapus kesepakatan frame yang
        // hampir terkumpul.
        if (_state != MoneyState.fit) _set(MoneyState.fit);
      } else {
        // Kategori "sepertinya" LEWAT TANPA SUARA - ini pagar utama mode ini.
        //
        // Layar tetap memberi panduan tertulis ("dekatkan sedikit") untuk
        // pengguna awas, tapi tidak satu kata pun diucapkan. Pengumuman
        // otomatis menghapus satu hal yang dulu
        // selalu ada: perbuatan sadar pengguna menekan tombol, yang menandai
        // bahwa dia siap menilai jawabannya sendiri. Tanpa penanda itu,
        // tebakan yang diucapkan dengan nada yang sama dengan kepastian tidak
        // bisa dibedakan darinya, dan salah menyebut nominal berarti kerugian
        // uang yang nyata.
        //
        // [_lastAmount] sengaja TIDAK ikut diperbarui di sini. Ia yang dibaca
        // perintah "ulangi", dan mengulang berarti mengucapkan - menaruh
        // tebakan yang belum pernah lolos gerbang ke dalamnya membuka pintu
        // belakang untuk menyebut nominal yang justru diputuskan tidak layak
        // disebut.
        if (_state != MoneyState.uncertain) _set(MoneyState.uncertain);
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

  /// UG-08 - panduan berputar saat kamera tidak menemukan uang sama sekali.
  ///
  /// Pillnya berganti kalimat tiap 5 detik untuk mata, dan tiap panduan
  /// KEDUA diucapkan - jadi satu kalimat tiap 10 detik.
  ///
  /// Bagian yang diucapkan ini wajib ada sejak mode ini kehilangan tombolnya.
  /// Selama masih ada tombol, keheningan punya arti yang jelas: pengguna
  /// belum menekan apa pun. Tanpa tombol, keheningan adalah satu-satunya
  /// keluaran mode ini saat gagal, dan pengguna tunanetra tidak punya cara
  /// membedakan "kamera tidak melihat uang" dari "aplikasinya berhenti
  /// bekerja". Yang pertama bisa dia perbaiki; yang kedua membuatnya keluar
  /// dari mode dan berhenti percaya.
  ///
  /// Sepuluh detik, bukan lima: kalimat panduan yang datang tiap lima detik
  /// menempati hampir separuh waktu bicara mode ini, dan pengumuman nominal
  /// yang menyusul harus menunggu di belakangnya.
  void _startHintRotation() {
    _hintRotateTimer?.cancel();
    var tick = 0;
    _hintRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _noCandidateHintIndex =
          (_noCandidateHintIndex + 1) % _kNoCandidateHints.length;
      notifyListeners();
      tick++;
      if (tick.isOdd) return;
      if (!_voiceOn || _state != MoneyState.noCandidate) return;
      if (_wasSpeaking || (isSpeaking?.call() ?? false)) return;
      _speechEndedAt = DateTime.now();
      _speak(noCandidateHint, tier: SpeechTier.info);
    });
  }

  /// Nominal yang TIDAK didukung model (emisi/pecahan di luar 6 kelas).
  /// Dipakai layar untuk menyusun pesan keterbatasan yang jujur (UG-18).
  List<int> get unsupportedValues => MoneyTFLiteService.unsupportedValues;

  @override
  void dispose() {
    pause();
    _speechWatch?.cancel();
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

  /// Satu lembar, satu jawaban. Lembar yang sama yang terus terlihat hanya
  /// mengulang nominal yang sama - tidak pernah menambah apa pun.
  ///
  /// [certain] menentukan NADA, bukan boleh atau tidaknya menjawab. Pagarnya
  /// harus terdengar di kalimat pertama, bukan disimpan di akhir, dan tier
  /// warning ikut dipakai supaya antrean suara tidak menyamakannya dengan
  /// jawaban yang pasti.
  ///
  /// Di jalur nyata `certain: false` sudah tidak pernah sampai ke sini -
  /// [_applyRealResult] membiarkan hasil berpagar lewat tanpa suara. Parameter
  /// ini tinggal dipakai jalur mock, dan sengaja tidak dihapus: kalau suatu
  /// saat ada yang memutuskan tebakan boleh diucapkan lagi, kalimatnya harus
  /// tetap membuka dengan "Sepertinya", bukan disusun ulang dari nol.
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
