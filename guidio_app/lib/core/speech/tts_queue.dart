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

/// Satu item di antrean.
class _QueuedSpeech {
  final String message;
  final SpeechTier tier;
  final DateTime queuedAt;
  final int sequence;
  final Duration maxAge;
  final bool interruptible;

  /// Kunci dedup. Dua item dengan kunci sama yang masuk berdekatan
  /// digabung jadi satu, sehingga narasi identik tidak diucapkan dua kali
  /// hanya karena dua frame berturut-turut sepakat.
  final String? dedupKey;

  _QueuedSpeech({
    required this.message,
    required this.tier,
    required this.sequence,
    required this.maxAge,
    this.interruptible = true,
    this.dedupKey,
  }) : queuedAt = DateTime.now();

  bool isStale(DateTime now) => now.difference(queuedAt) > maxAge;
}

/// TtsQueue — antrean bertingkat "satu pintu suara".
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
  TtsQueue._internal();

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
  bool _currentInterruptible = true;
  bool _draining = false;
  int _drainGeneration = 0;
  int _sequenceCounter = 0;

  DateTime? _lastUtteranceEndedAt;
  DateTime? _settlingUntil;
  DateTime? _warningHeldSince;

  SpeechTier? get speakingTier => _speakingTier;
  bool get isSpeaking => _speakingTier != null || _draining;
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
    String? dedupKey,
    bool? interruptible,
    Duration? maxAge,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

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
        _enqueue(trimmed, tier, canInterrupt, maxAge, dedupKey: dedupKey);
        unawaited(_drain());
        return;
      }

      await TTSService.instance.stop();
      await _respectMinGap();

      _speakingTier = SpeechTier.critical;
      _currentInterruptible = canInterrupt;
      await TTSService.instance.speak(trimmed, interrupt: true);
      _lastUtteranceEndedAt = DateTime.now();
      _speakingTier = null;
      _currentInterruptible = true;

      unawaited(_drain());
      return;
    }

    // ── Warning memotong Info yang sedang bicara ──
    if (tier == SpeechTier.warning &&
        _speakingTier == SpeechTier.info &&
        _currentInterruptible) {
      _drainGeneration++;
      await TTSService.instance.stop();
      await _respectMinGap();

      _speakingTier = SpeechTier.warning;
      _currentInterruptible = canInterrupt;
      await TTSService.instance.speak(trimmed, interrupt: true);
      _lastUtteranceEndedAt = DateTime.now();
      _speakingTier = null;
      _currentInterruptible = true;

      unawaited(_drain());
      return;
    }

    _enqueue(trimmed, tier, canInterrupt, maxAge, dedupKey: dedupKey);
    unawaited(_drain());
  }

  void _enqueue(
    String message,
    SpeechTier tier,
    bool interruptible,
    Duration? maxAge, {
    String? dedupKey,
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
      sequence: _sequenceCounter++,
      interruptible: interruptible,
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
      final lastInfoIdx =
          _pending.lastIndexWhere((q) => q.tier == SpeechTier.info);
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
    await TTSService.instance.stop();
    _lastUtteranceEndedAt = DateTime.now();
    _speakingTier = null;
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

        await _respectMinGap();
        if (_drainGeneration != myGeneration) break;

        _speakingTier = next.tier;
        _currentInterruptible = next.interruptible;
        await TTSService.instance.speak(next.message);
        _lastUtteranceEndedAt = DateTime.now();

        if (_drainGeneration == myGeneration) {
          _speakingTier = null;
          _currentInterruptible = true;
        }
      }
    } finally {
      _draining = false;
      if (_drainGeneration == myGeneration &&
          _speakingTier != SpeechTier.critical) {
        _speakingTier = null;
        _currentInterruptible = true;
      }
    }
  }

  Future<void> stop() async {
    _pending.clear();
    _recentDedup.clear();
    _warningHeldSince = null;
    _drainGeneration++;
    await TTSService.instance.stop();
    _lastUtteranceEndedAt = DateTime.now();
    _speakingTier = null;
    _currentInterruptible = true;
  }

  /// Diagnostik untuk panel debug.
  Map<String, dynamic> debugState() => {
        'pending': _pending.length,
        'speakingTier': _speakingTier?.name,
        'interruptible': _currentInterruptible,
        'settling': isSettling,
        'warningHeldMs': _warningHeldSince == null
            ? null
            : DateTime.now().difference(_warningHeldSince!).inMilliseconds,
      };
}
