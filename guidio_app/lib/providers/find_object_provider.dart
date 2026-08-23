
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/server_service.dart';
import '../core/speech/tts_queue.dart' show SpeechTier;

/// State machine Mode Cari Objek.
///
/// **Trigger-based via backend YOLOE** - pengguna tekan tombol kiri,
/// satu foto dikirim ke POST /api/cari-objek, hasilnya diucapkan via TTS.
/// Backend menggunakan YOLOE open-vocabulary (300+ barang Bahasa Indonesia).
///
/// Berbeda dari versi on-device sebelumnya yang berjalan real-time (loop
/// 350 ms), versi ini hanya berjalan sekali per tap - lebih hemat baterai
/// dan bisa mendeteksi jauh lebih banyak jenis barang.
///
/// CO-15 (izin kamera), CO-16 (senyap), CO-17 (font scale 200%) sengaja TIDAK
/// dimodelkan di sini - itu murni keputusan lapisan UI.
enum FindObjectState {
  idle,            // CO-01
  listening,       // CO-02
  unclear,         // CO-03
  targetActive,    // CO-04 - target aktif, menunggu tombol kiri ditekan
  scanning,        // CO-05 - sedang mengirim ke backend
  found,           // CO-06 / CO-07 (lihat matchCount)
  lostFromView,    // CO-09
  notFoundInFrame, // CO-10
  longNotFound,    // CO-11
  unknownObject,   // CO-12
  offlineSaved,    // CO-14
  serverError,     // CO-18
  tooDark,         // CO-19
}

class FindObjectProvider extends ChangeNotifier {
  FindObjectState _state = FindObjectState.idle;
  FindObjectState get state => _state;

  String? _target;
  String? get target => _target;

  /// CO-14 - target yang disimpan saat offline, dipakai lagi begitu pulih.
  String? _savedTarget;
  String? get savedTarget => _savedTarget;

  int _matchCount = 1;
  int get matchCount => _matchCount;

  String _direction = 'depan';
  String get direction => _direction;

  double _distanceMeter = 3.0;
  double get distanceMeter => _distanceMeter;

  String? _lastKnownPosition;
  String? get lastKnownPosition => _lastKnownPosition;

  /// Pesan terakhir dari server.
  String _serverMessage = '';
  String get scanMessage =>
      _serverMessage.isEmpty ? 'Memindai sekitar…' : _serverMessage;
  String get notFoundMessage => scanMessage;

  /// True saat sedang menunggu respons backend - tombol kiri di-disable.
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final List<String> _knownTargets = const [];
  List<String> get knownTargets => _knownTargets;

  /// Callback keluar - screen yang mengubahnya jadi suara/getar sungguhan.
  void Function(String text, SpeechTier tier)? onSpeak;
  void Function(String direction)? onDirectionHaptic;

  /// Sumber frame. Screen memasang ini supaya provider tetap bebas dari
  /// BuildContext dan bebas dari paket kamera.
  Future<Uint8List?> Function()? frameSource;

  /// Kenapa [frameSource] mengembalikan null, kalau layar tahu alasannya.
  ///
  /// Sebelumnya null selalu diterjemahkan jadi "terlalu gelap", karena itu
  /// satu-satunya sebab yang terpikir waktu itu. Setelah frame dinilai
  /// ketajamannya, sebab yang mungkin bertambah: buram karena tangan
  /// bergerak, atau silau karena menghadap cahaya. Ketiganya butuh tindakan
  /// yang berbeda dari pengguna, jadi ketiganya harus terdengar berbeda -
  /// menyuruh menyalakan lampu saat masalahnya tangan bergetar hanya
  /// membuang tenaga orang yang sedang mencari barangnya.
  String? Function()? frameRejectReason;

  /// Dibaca sebelum mengirim - CO-14 menuntut mode ini benar-benar berhenti
  /// saat offline, bukan mencoba lalu gagal berkali-kali.
  bool Function()? isOffline;

  int _notFoundCount = 0;
  Timer? _stepTimer;

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

  /// Tidak dipakai lagi - dipertahankan agar tidak merusak layar yang masih
  /// memanggil ini.
  Future<void> loadKnownTargets() async {
    // no-op
  }

  // -------------------------------------------------------------- CO-02/03

  void startListening() {
    _set(FindObjectState.listening);
  }

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

  void setTarget(String newTarget) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _matchCount = 1;
    _lastKnownPosition = null;
    _notFoundCount = 0;
    _isScanning = false;
    _set(FindObjectState.targetActive);

    _speak(
      isChange
          ? 'Ganti, sekarang mencari $newTarget. Tekan tombol kirim untuk memindai.'
          : 'Mencari $newTarget. Tekan tombol kirim untuk memindai.',
      tier: SpeechTier.info,
    );
  }

  void retrySavedTarget() {
    final saved = _savedTarget;
    if (saved == null) return;
    _savedTarget = null;
    _speak('Internet kembali. Tekan tombol kirim untuk mencari $saved.',
        tier: SpeechTier.info);
    setTarget(saved);
  }

  // --------------------------------------------------------- Trigger (CO-05)

  /// Dipanggil oleh screen saat tombol kiri (📷 / "Kirim") ditekan.
  /// Ambil satu frame → kirim ke backend → proses respons.
  Future<void> triggerScan() async {
    final target = _target;
    if (target == null || _isScanning) return;

    // CO-14 - benar-benar berhenti saat offline
    final offline = isOffline?.call() ?? false;
    if (offline) {
      _savedTarget = target;
      _set(FindObjectState.offlineSaved);
      _speak(
        'Tanpa internet, pencarian tidak bisa dijalankan. '
        'Saya akan ingatkan saat internet kembali.',
        tier: SpeechTier.warning,
      );
      return;
    }

    final grab = frameSource;
    if (grab == null) return;

    _isScanning = true;
    _set(FindObjectState.scanning);

    try {
      final jpeg = await grab();
      if (jpeg == null) {
        _isScanning = false;
        _set(FindObjectState.tooDark);
        _speak(
          frameRejectReason?.call() ?? 'Terlalu gelap. Nyalakan lampu.',
          tier: SpeechTier.warning,
        );
        return;
      }

      final res = await ServerService.instance.cariObjek(jpeg, target);
      _isScanning = false;
      _handleResponse(res, target);
    } catch (e) {
      _isScanning = false;
      _set(FindObjectState.serverError);
      // Warning, bukan Critical. Tier Critical dicadangkan untuk bahaya fisik
      // dan tidak bisa dipotong pengguna - kegagalan jaringan tidak pernah
      // setara dengan motor yang melaju ke arahmu.
      _speak(
        'Gagal menghubungi server. Periksa koneksi dan coba lagi.',
        tier: SpeechTier.warning,
      );
    }
  }

  void _handleResponse(Map<String, dynamic> res, String target) {
    _serverMessage = res['message'] as String? ?? '';
    final found = res['found'] == true;

    if (!found) {
      final reason = res['reason'] as String? ?? 'not_in_frame';

      // `server_error` ikut di sini, bukan jatuh ke cabang "tidak ketemu".
      //
      // Backend mengembalikannya saat inferensinya sendiri gagal, dan
      // sebelumnya ia lolos ke bawah: statenya jadi `notFoundInFrame` (kartu
      // Info "Mencari …") dan `_notFoundCount` ikut naik, sehingga empat
      // kegagalan server berturut-turut memicu tawaran CO-11 "pindah ruangan,
      // atau sebutkan barang lain". Pengguna disuruh berjalan ke ruangan lain
      // untuk masalah yang sepenuhnya ada di server, dan barang yang dicarinya
      // mungkin ada tepat di depannya.
      if (reason == 'model_unavailable' || reason == 'server_error') {
        _set(FindObjectState.serverError);
        _speak(
          _serverMessage.isNotEmpty
              ? _serverMessage
              : 'Pencari objek tidak tersedia di server.',
          tier: SpeechTier.warning,
        );
        return;
      }
      // Masalah kualitas gambar, BUKAN "barangnya tidak ada di sini".
      //
      // Bedanya menentukan tindakan pengguna, dan dulu keduanya terdengar
      // sama. Kalau server menyarankan foto ulang, menyuruh pengguna memutar
      // badan justru membuang tenaganya: yang perlu diperbaiki adalah kondisi
      // pengambilan gambar, bukan arah kamera. Karena itu penghitung
      // `_notFoundCount` juga TIDAK dinaikkan di sini - percobaan yang
      // gagal karena fotonya tidak terbaca bukan bukti barangnya tidak ada,
      // dan menghitungnya akan memicu tawaran menyerah CO-11 terlalu cepat.
      //
      // `invalid_frame` dipertahankan demi server versi lama yang belum
      // dimutakhirkan.
      if (res['retry_suggested'] == true || reason == 'invalid_frame') {
        _set(FindObjectState.tooDark);
        _speak(
          _serverMessage.isNotEmpty
              ? _serverMessage
              : 'Terlalu gelap. Nyalakan lampu.',
          tier: SpeechTier.warning,
        );
        return;
      }

      _notFoundCount++;
      if (_notFoundCount >= 4) {
        // CO-11 - setelah 4 kali tidak ketemu, tawarkan jalan keluar
        _set(FindObjectState.longNotFound);
        _speak(
          'Belum ketemu di sini. Pindah posisi, lalu tekan kirim lagi. '
          'Atau sebutkan barang lain.',
          tier: SpeechTier.warning,
        );
        return;
      }

      _set(FindObjectState.notFoundInFrame);
      _speak(
        _serverMessage.isNotEmpty
            ? _serverMessage
            : '$target tidak terlihat. Coba arahkan kamera ke tempat lain lalu tekan kirim.',
        tier: SpeechTier.info,
      );
      return;
    }

    // ── Ketemu ──────────────────────────────────────────────────────────────
    final nearest = res['nearest'] as Map<String, dynamic>?;
    final total = (res['total_match'] as num?)?.toInt() ?? 1;

    _notFoundCount = 0;
    _matchCount = total;
    if (nearest != null) {
      _direction = nearest['direction'] as String? ?? _direction;
      _distanceMeter =
          (nearest['distance_meter'] as num?)?.toDouble() ?? _distanceMeter;
    }
    _lastKnownPosition =
        '$_direction, sekitar ${_distanceMeter.toStringAsFixed(1)} meter';

    _set(FindObjectState.found);

    final msg = _serverMessage.isNotEmpty ? _serverMessage : _composeFound();
    _speak(msg, tier: SpeechTier.info);
    onDirectionHaptic?.call(_direction);
  }

  String _composeFound() {
    final distText = _distanceMeter < 1
        ? 'kurang dari satu meter'
        : '${_distanceMeter.toStringAsFixed(1)} meter';
    return _matchCount > 1
        ? 'Ada $_matchCount $_target. Yang terdekat di $_direction, sekitar $distText.'
        : '$_target ditemukan di $_direction, sekitar $distText.';
  }

  void reset() {
    _stepTimer?.cancel();
    _target = null;
    _serverMessage = '';
    _isScanning = false;
    _notFoundCount = 0;
    _set(FindObjectState.idle);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }
}
