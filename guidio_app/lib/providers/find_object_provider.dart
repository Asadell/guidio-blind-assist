import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart' show FramePacer;
import '../core/speech/tts_queue.dart' show SpeechTier;
import '../services/find_object_onnx_service.dart';

/// State machine Mode Cari Objek.
///
/// **Sepenuhnya on-device** — inferensi YOLOE via ONNX Runtime, tidak ada
/// panggilan server. Bekerja 100% offline.
///
/// CO-15 (izin kamera), CO-16 (senyap), CO-17 (font scale 200%) sengaja TIDAK
/// dimodelkan di sini — itu murni keputusan lapisan UI, sama seperti pola
/// MoneyProvider.
enum FindObjectState {
  idle, // CO-01
  listening, // CO-02
  unclear, // CO-03
  targetActive, // CO-04
  scanning, // CO-05
  found, // CO-06 / CO-07 (lihat matchCount)
  lostFromView, // CO-09
  notFoundInFrame, // CO-10
  longNotFound, // CO-11
  unknownObject, // CO-12
  offlineSaved, // CO-14
  serverError, // CO-18
  tooDark, // CO-19
}

class FindObjectProvider extends ChangeNotifier {
  FindObjectState _state = FindObjectState.idle;
  FindObjectState get state => _state;

  String? _target;
  String? get target => _target;

  /// CO-14 — target yang disimpan saat offline, dipakai lagi begitu pulih.
  String? _savedTarget;
  String? get savedTarget => _savedTarget;

  int _matchCount = 1; // CO-07: >1 berarti "lebih dari satu cocok"
  int get matchCount => _matchCount;

  String _direction = 'depan';
  String get direction => _direction;

  double _distanceMeter = 3.0;
  double get distanceMeter => _distanceMeter;

  String? _lastKnownPosition; // CO-09
  String? get lastKnownPosition => _lastKnownPosition;

  /// Pesan terakhir dari server. Server yang menyusun kalimatnya supaya
  /// perbaikan naskah tidak perlu rilis ulang aplikasi.
  String _serverMessage = '';
  String get scanMessage =>
      _serverMessage.isEmpty ? 'Memindai sekitar…' : _serverMessage;
  String get notFoundMessage => scanMessage;

  /// Tidak digunakan lagi — label sekarang on-device.
  final List<String> _knownTargets = const [];
  List<String> get knownTargets => _knownTargets;

  /// Callback keluar — screen yang mengubahnya jadi suara/getar sungguhan.
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(String direction)? onDirectionHaptic; // CO-16

  /// Sumber frame. Screen memasang ini supaya provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;

  /// Dibaca sebelum mengirim — CO-14 menuntut mode ini benar-benar berhenti
  /// saat offline, bukan mencoba lalu gagal berkali-kali.
  bool Function()? isOffline;

  /// ONNX service — dimuat lazy saat mode aktif pertama kali.
  final _onnx = FindObjectOnnxService();

  /// Satu permintaan in-flight, frame lama dibuang. Untuk pencarian yang
  /// pengguna lakukan sambil memutar badan, jawaban untuk frame tiga detik
  /// lalu menunjuk ke arah yang sudah salah.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 600));

  Timer? _loopTimer;
  Timer? _stepTimer;
  int _consecutiveNotFound = 0;
  int _consecutiveErrors = 0;

  void _speak(String text, {SpeechTier tier = SpeechTier.info}) =>
      onSpeak?.call(text, tier);

  void _set(FindObjectState s) {
    _state = s;
    notifyListeners();
  }

  void _after(int ms, VoidCallback cb) {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: ms), cb);
  }

  /// Tidak dipakai lagi — label sekarang berasal dari object_label_map.dart.
  /// Dipertahankan agar tidak merusak layar yang masih memanggil ini.
  Future<void> loadKnownTargets() async {
    // no-op: on-device, tidak perlu fetch dari server
  }

  // -------------------------------------------------------------- CO-02/03

  void startListening() {
    _stopLoop();
    _set(FindObjectState.listening);
  }

  /// Dipanggil screen setelah STT selesai. [heardText] kosong/ambigu → CO-03.
  void submitHeardText(String heardText, {String? parsedTarget}) {
    final t = (parsedTarget ?? heardText).trim();
    if (t.isEmpty) {
      _set(FindObjectState.unclear);
      _speak('Cari apa?', tier: SpeechTier.info);
      _after(2500, () => _set(FindObjectState.idle));
      return;
    }
    setTarget(t);
  }

  // ------------------------------------------------------------------ CO-04

  /// Menetapkan target baru — juga dipakai CO-13 "ganti target" saat target
  /// sudah aktif (tidak perlu kembali ke CO-01 dulu).
  void setTarget(String newTarget) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _matchCount = 1;
    _lastKnownPosition = null;
    _consecutiveNotFound = 0;
    _consecutiveErrors = 0;
    _set(FindObjectState.targetActive);

    // On-device: tidak ada cek offline. Model ONNX selalu tersedia.
    _speak(
      isChange ? 'Ganti, sekarang mencari $newTarget.' : 'Mencari $newTarget.',
      tier: SpeechTier.info,
    );
    // Mulai load model ONNX di background (lazy, sekali saja)
    _onnx.ensureLoaded();
    _after(400, _beginScan);
  }

  /// Dipanggil screen saat koneksi pulih — CO-14 menjanjikan percobaan ulang,
  /// jadi janji itu harus benar-benar ditepati.
  void retrySavedTarget() {
    final saved = _savedTarget;
    if (saved == null) return;
    _savedTarget = null;
    _speak('Internet kembali. Melanjutkan mencari $saved.', tier: SpeechTier.info);
    setTarget(saved);
  }

  // -------------------------------------------------------------- CO-05..11

  void _beginScan() {
    if (_target == null) return;
    _set(FindObjectState.scanning);
    _startLoop();
  }

  void _startLoop() {
    _loopTimer?.cancel();
    _pacer.reset();
    // Laju pemindaian dipilih dari kecepatan orang memutar badan, bukan dari
    // kemampuan kamera: ~3 frame per detik sudah cukup rapat untuk mengikuti
    // putaran badan, dan tidak membanjiri server.
    _loopTimer = Timer.periodic(const Duration(milliseconds: 350), (_) => _tick());
    _tick();
  }

  void _stopLoop() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _stepTimer?.cancel();
    _pacer.reset();
  }

  Future<void> _tick() async {
    final target = _target;
    final grab = frameSource;
    if (target == null || grab == null) return;

    // Frame yang datang saat masih ada permintaan berjalan dibuang di sini,
    // bukan diantre. Lihat FramePacer.
    await _pacer.run(() async {
      final jpeg = await grab();
      if (jpeg == null || _target != target) return;

      try {
        final res = await _onnx.findObject(jpeg, target);
        if (_target != target) return;
        _consecutiveErrors = 0;
        _handleResponse(res, target);
      } catch (e) {
        _handleFailure(
          'Gagal memproses gambar. Coba lagi sebentar.',
          FindObjectState.serverError,
        );
      }
    });
  }

  void _handleResponse(Map<String, dynamic> res, String target) {
    _serverMessage = res['message'] as String? ?? '';
    final found = res['found'] == true;

    if (!found) {
      final reason = res['reason'] as String? ?? 'not_in_frame';

      if (reason == 'model_unavailable') {
        _handleFailure(_serverMessage, FindObjectState.serverError);
        return;
      }
      if (reason == 'invalid_frame') {
        // CO-19 — frame tidak terbaca; paling sering karena terlalu gelap.
        _set(FindObjectState.tooDark);
        _speak('Terlalu gelap. Nyalakan lampu.', tier: SpeechTier.warning);
        return;
      }

      _consecutiveNotFound++;
      // CO-10 lalu CO-11 — sesudah cukup lama tidak ketemu, berhenti menyuruh
      // memutar badan dan tawarkan jalan keluar. Mengulang instruksi yang sama
      // tanpa batas adalah bentuk jalan buntu.
      if (_consecutiveNotFound >= 18) {
        _stopLoop();
        _set(FindObjectState.longNotFound);
        _speak(
          'Belum ketemu di ruangan ini. Pindah ruangan, atau sebutkan barang lain?',
          tier: SpeechTier.warning,
        );
        return;
      }

      if (_state != FindObjectState.notFoundInFrame) {
        _set(FindObjectState.notFoundInFrame);
      } else {
        notifyListeners(); // pesan berputar dari server
      }
      // Instruksi diucapkan berkala, bukan tiap frame — kalau tidak, TTS
      // akan bicara terus-menerus dan menutupi suara lingkungan.
      if (_consecutiveNotFound % 6 == 1) {
        _speak(scanMessage, tier: SpeechTier.info);
      }
      return;
    }

    // ── Ketemu ───────────────────────────────────────────────────────────
    final nearest = res['nearest'] as Map<String, dynamic>?;
    final total = (res['total_match'] as num?)?.toInt() ?? 1;
    final wasLost = _state == FindObjectState.notFoundInFrame ||
        _state == FindObjectState.lostFromView;

    _consecutiveNotFound = 0;
    _matchCount = total;
    if (nearest != null) {
      _direction = nearest['direction'] as String? ?? _direction;
      _distanceMeter =
          (nearest['distance_meter'] as num?)?.toDouble() ?? _distanceMeter;
    }
    _lastKnownPosition = '$_direction, sekitar ${_distanceMeter.toStringAsFixed(1)} meter';

    final previous = _state;
    _set(FindObjectState.found);

    // CO-06/07/08 — umumkan saat pertama ketemu, saat ketemu lagi setelah
    // hilang, atau saat jaraknya berubah cukup jauh untuk berarti. Tanpa
    // aturan ini, jarak yang berubah tiap frame jadi banjir suara.
    final shouldAnnounce = previous != FindObjectState.found ||
        wasLost ||
        _crossedDistanceStep();
    if (shouldAnnounce) {
      _speak(_serverMessage.isNotEmpty ? _serverMessage : _composeFound(),
          tier: SpeechTier.info);
      onDirectionHaptic?.call(_direction);
    }
    _lastAnnouncedDistance = _distanceMeter;
  }

  double _lastAnnouncedDistance = -1;

  /// CO-08 — panduan bertahap. Diumumkan saat melewati ambang yang berarti
  /// ("dua meter" → "satu meter" → "setengah meter, ulurkan tangan"), bukan
  /// tiap kali angkanya bergeser sedikit.
  bool _crossedDistanceStep() {
    if (_lastAnnouncedDistance < 0) return true;
    const steps = [0.6, 1.0, 2.0, 3.0];
    for (final s in steps) {
      if (_lastAnnouncedDistance > s && _distanceMeter <= s) return true;
    }
    return false;
  }

  String _composeFound() {
    final distText = _distanceMeter < 1
        ? 'kurang dari satu meter'
        : '${_distanceMeter.toStringAsFixed(1)} meter';
    return _matchCount > 1
        ? 'Ada $_matchCount $_target. Yang terdekat di $_direction, sekitar $distText.'
        : '$_target ditemukan di $_direction, sekitar $distText.';
  }

  void _handleFailure(String message, FindObjectState state) {
    _consecutiveErrors++;
    _set(state);
    // Diucapkan sekali per rentetan kegagalan, bukan tiap frame.
    if (_consecutiveErrors == 1) {
      _speak(message, tier: SpeechTier.critical);
    }
    // Sesudah beberapa kegagalan berturut-turut, berhenti membebani server
    // dan baterai. Pengguna diberi tahu, bukan dibiarkan menunggu diam-diam.
    if (_consecutiveErrors >= 5) {
      _stopLoop();
      _speak(
        'Pencarian dihentikan. Ucapkan nama barangnya lagi untuk mencoba ulang.',
        tier: SpeechTier.warning,
      );
      _consecutiveErrors = 0;
    }
  }

  void reset() {
    _stopLoop();
    _target = null;
    _serverMessage = '';
    _consecutiveNotFound = 0;
    _consecutiveErrors = 0;
    _lastAnnouncedDistance = -1;
    _set(FindObjectState.idle);
  }

  @override
  void dispose() {
    _stopLoop();
    super.dispose();
  }
}
