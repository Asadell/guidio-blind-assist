
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/voice/command_parser.dart';
import '../core/voice/voice_log.dart';
import '../services/server_service.dart';
import '../services/translation_service.dart';
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

  /// Prompt Inggris hasil ML Kit untuk [_target]. Null berarti terjemahan
  /// belum selesai atau tidak tersedia - dan itu BUKAN kegagalan: backend
  /// masih punya kamus manualnya sendiri.
  String? _targetEn;
  String? get targetEn => _targetEn;

  /// Terjemahan yang sedang berjalan untuk target aktif.
  Future<void>? _translating;

  /// Batas menunggu terjemahan saat tombol kirim ditekan.
  ///
  /// Terjemahannya dimulai di [setTarget], jauh sebelum ini - pengguna masih
  /// mendengarkan konfirmasi "Mencari tas merah, tekan tombol kirim" selama
  /// beberapa detik. Jadi dalam pemakaian normal batas ini tidak pernah
  /// tersentuh. Ia ada untuk kasus pengguna menekan tombol seketika saat
  /// model ML Kit kebetulan baru diunduh: pencarian yang telat dua detik
  /// jauh lebih baik daripada pencarian yang menggantung.
  static const Duration _translateBudget = Duration(seconds: 2);

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

  /// Kembali ke diam tanpa berkata apa-apa.
  ///
  /// Dipakai saat sesi dengar dibatalkan dari luar - misalnya batas tahan
  /// tercapai - di mana layar sudah mengucapkan sebabnya sendiri. Tanpa ini
  /// satu-satunya jalan keluar dari [FindObjectState.listening] adalah
  /// menyetorkan teks, dan sesi yang dibatalkan tidak punya teks untuk
  /// disetorkan: statusnya akan tinggal di "mendengarkan" selamanya.
  void backToIdle() {
    _stepTimer?.cancel();
    _set(FindObjectState.idle);
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

  /// [announce] dimatikan saat pemanggil sudah punya suaranya sendiri.
  ///
  /// `VoiceProvider._handleFindObjectTarget` memakai itu, dan bukan demi
  /// kerapian. Ia memanggil `setTarget` SEBELUM layar ini terpasang, jadi
  /// `onSpeak` masih null dan pengumuman di bawah hilang tanpa jejak - lalu
  /// `announceEntry` mengucapkan versinya sendiri sesudah layar hidup. Dua
  /// kalimat untuk satu kejadian, dan yang terdengar justru bukan yang
  /// ditulis di sini.
  ///
  /// Membiarkan keduanya menyala begitu layar sudah terpasang (mis. mengganti
  /// barang lewat mic dari dalam mode ini) menghasilkan masalah kebalikannya:
  /// pengguna mendengar barang yang sama disebut dua kali berturut-turut.
  void setTarget(String newTarget, {bool announce = true}) {
    final isChange = _target != null && _target != newTarget;
    _target = newTarget;
    _targetEn = null;
    // Diterjemahkan SEKARANG, bukan saat tombol kirim ditekan.
    //
    // Antara dua momen itu ada konfirmasi suara sepanjang beberapa detik
    // ("Mencari tas merah. Tekan tombol kirim untuk memindai"), dan itu
    // waktu yang sudah dibayar - dipakai atau tidak. Menunda terjemahan ke
    // saat tombol ditekan berarti menambahkan penundaannya ke satu-satunya
    // momen di alur ini yang pengguna benar-benar menunggu hasil.
    _translating = _resolveEnglishPrompt(newTarget);
    _matchCount = 1;
    _lastKnownPosition = null;
    _notFoundCount = 0;
    _isScanning = false;
    _set(FindObjectState.targetActive);

    if (!announce) return;
    _speak(
      isChange
          ? 'Ganti, sekarang mencari $newTarget. '
              'Tekan tombol kiri bawah untuk memindai.'
          : 'Mencari $newTarget. Tekan tombol kiri bawah untuk memindai.',
      tier: SpeechTier.info,
    );
  }

  /// Susun prompt Inggris untuk YOLOE lewat ML Kit on-device.
  ///
  /// Yang diterjemahkan HANYA frasa bendanya - "tolong carikan tas merah"
  /// sudah dipotong jadi "tas merah" oleh `CommandParser`, lalu dibersihkan
  /// sekali lagi oleh `normalizeSearchPhrase`. Menerjemahkan kalimat utuh
  /// akan menghasilkan prompt seperti "please find my red bag", dan encoder
  /// teks YOLOE mencocokkan SELURUH frasa itu dengan isi gambar - kata
  /// "please" dan "find" ikut jadi bagian dari yang dicari.
  Future<void> _resolveEnglishPrompt(String target) async {
    // Seluruh badan fungsi dijaga try/catch karena Future ini SENGAJA tidak
    // ditunggu di [setTarget] - ia berjalan sendiri selama konfirmasi suara
    // dibacakan. Exception di dalam future yang tidak ditunggu naik sebagai
    // unhandled zone error, dan itu menjatuhkan aplikasi karena satu prompt
    // yang gagal diterjemahkan - padahal pencariannya masih sanggup jalan
    // dengan kamus di backend.
    try {
      final phrase = CommandParser.normalizeSearchPhrase(target);
      if (phrase.isEmpty) return;

      final en = await TranslationService.instance.toEnglish(phrase);

      // Pengguna bisa mengganti barang saat terjemahan masih jalan. Tanpa
      // penjaga ini, "tas merah" yang datang telat menimpa "dompet" yang baru
      // diminta - dan pencariannya mencari benda yang salah tanpa satu pun
      // tanda di suara maupun di layar.
      if (_target != target) {
        VoiceLog.route(
          'cari-objek terjemahan "$phrase" -> "${en ?? "(null)"}" DIBUANG, '
          'target sudah berganti jadi "$_target"',
        );
        return;
      }
      _targetEn = en;
      VoiceLog.route('cari-objek mlkit "$phrase" -> "${en ?? "(null, kamus backend dipakai)"}"');
    } catch (e) {
      VoiceLog.warn('cari-objek terjemahan prompt gagal: $e');
    }
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
        // Sejak penilaian kualitas dilepas dari `_grabFrame`, frame null
        // TIDAK lagi berarti fotonya jelek - artinya kameranya belum siap
        // atau alirannya sudah mati. Pesan bawaannya ikut berubah: menyuruh
        // menyalakan senter untuk kamera yang belum menyala adalah instruksi
        // yang tidak akan pernah berhasil, dan pengguna tunanetra tidak punya
        // cara mengetahui bahwa dia menuruti saran yang salah.
        _isScanning = false;
        _set(FindObjectState.tooDark);
        _speak(
          frameRejectReason?.call() ??
              'Kamera belum siap. Tunggu sebentar lalu tekan lagi.',
          tier: SpeechTier.warning,
        );
        return;
      }

      // Terjemahan hampir selalu sudah selesai di sini; batasnya cuma jaring
      // pengaman. Kalau lewat, `_targetEn` tetap null dan backend memakai
      // kamus manualnya - hasilnya lebih kasar, bukan gagal.
      await _translating?.timeout(_translateBudget, onTimeout: () {});

      // Persis apa yang berangkat ke POST /api/cari-objek. Kalau hasil
      // pencarian terasa mencari benda yang salah, jawabannya ada di baris
      // ini - bukan di model, dan bukan di kamera.
      VoiceLog.route(
        'cari-objek KIRIM target="$target" prompt_en='
        '${_targetEn == null ? "(tidak ada, backend pakai kamusnya)" : "\"$_targetEn\""}',
      );

      final res = await ServerService.instance
          .cariObjek(jpeg, target, promptEn: _targetEn);
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
    _targetEn = null;
    _translating = null;
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
