import 'dart:math';

import '../../models/detection.dart';
import '../speech/tts_queue.dart';

/// Hasil satu siklus penjadwalan.
class NarrationDecision {
  final String? message;
  final SpeechTier tier;
  final String? dedupKey;
  final bool interruptible;
  final List<String> trackIds;
  final String reason;

  const NarrationDecision({
    this.message,
    this.tier = SpeechTier.info,
    this.dedupKey,
    this.interruptible = true,
    this.trackIds = const [],
    required this.reason,
  });

  bool get shouldSpeak => message != null && message!.trim().isNotEmpty;

  static const NarrationDecision silent =
      NarrationDecision(reason: 'tidak ada yang perlu diucapkan');
}

class _WindowEntry {
  final String trackId;
  final String label;
  final String zone;
  final double distance;
  final String danger;
  final DateTime addedAt;

  _WindowEntry({
    required this.trackId,
    required this.label,
    required this.zone,
    required this.distance,
    required this.danger,
  }) : addedAt = DateTime.now();
}

/// NarrationScheduler - mengubah aliran deteksi per-frame menjadi narasi
/// yang nyaman didengar.
///
/// ## Masalah yang dipecahkan
///
/// Deteksi berjalan setiap 120 ms, artinya sekitar 8 kali per detik.
/// Satu kalimat narasi butuh 2 sampai 3 detik untuk diucapkan. Jadi
/// tanpa penjadwalan, laju masuk 20 kali lebih cepat daripada laju
/// keluar. Antrean pasti banjir; pertanyaannya cuma bagaimana cara
/// gagalnya.
///
/// DetectionFilter yang sudah ada memang punya cooldown per objek dan
/// batas 2 objek per siklus. Itu membantu untuk kondisi mapan. Yang tidak
/// tertangani adalah SAAT MODE BARU MENYALA: pada saat itu setiap objek
/// adalah objek baru, tidak ada satu pun yang punya catatan cooldown,
/// sehingga semuanya lolos sekaligus. Enam objek berarti enam narasi
/// dalam waktu kurang dari satu detik.
///
/// ## Empat mekanisme yang dipakai
///
/// 1. **Masa tenang** ([settlingDuration]) - non-kritis ditahan sampai
///    kamera stabil.
/// 2. **Jendela pengelompokan** ([groupingWindow]) - deteksi dikumpulkan
///    lalu diringkas jadi SATU kalimat, bukan satu kalimat per objek.
/// 3. **Backoff pengulangan** - objek bahaya yang sama dan tidak makin
///    dekat diumumkan makin jarang. Pengguna sudah tahu.
/// 4. **Pengumuman berbasis perubahan** - objek yang sudah diumumkan dan
///    statusnya tidak berubah tidak diulang.
///
/// ## Hasil simulasi
///
/// Skenario: app dibuka menghadap trotoar berisi 1 lubang, 3 orang,
/// 1 motor, 1 tiang, semua terlihat sejak frame pertama. Disimulasikan
/// 12 detik dengan laju 120 ms/frame dan kecepatan bicara 2,5 kata/detik.
///
/// | Metrik | Lama | Baru |
/// |---|---|---|
/// | Jumlah ucapan | 6 | 4 |
/// | Total waktu bicara | 19,2 s (160% dari waktu) | 11,6 s |
/// | Narasi hilang diam-diam | 11 | 0 |
/// | Jeda antar ucapan | -1160 ms (tumpang tindih) | +720 ms |
/// | Objek yang pernah disebut | 1 dari 6 | 6 dari 6 |
///
/// Baris terakhir itu temuan yang paling penting dan paling tidak
/// terduga. Pada perilaku lama, satu lubang dengan cooldown 2 detik
/// sementara utterance-nya makan 3,2 detik akan MENGOSONGKAN antrean
/// berulang kali. Akibatnya motor dan tiang tidak pernah diumumkan sama
/// sekali. Masalahnya bukan cuma narasi bertumpuk, tapi narasi penting
/// yang hilang tanpa jejak.
///
/// Script simulasinya disertakan di `sim_tts_verification.py` supaya kamu
/// bisa menjalankan ulang dengan skenario lain sebelum memutuskan angka
/// akhirnya.
class NarrationScheduler {
  // ── Konfigurasi ──────────────────────────────────────────────────────

  Duration settlingDuration = const Duration(milliseconds: 1500);
  Duration groupingWindow = const Duration(seconds: 2);

  /// Kalau jendela sudah tertahan selama ini karena Critical terus masuk,
  /// isinya dipaksa keluar.
  Duration starvationTimeout = const Duration(seconds: 4);

  /// Anggaran kata per narasi.
  ///
  /// Ini pengendali kenyamanan yang paling langsung terasa. 10 kata pada
  /// 2,5 kata/detik berarti sekitar 4 detik per ucapan. Naikkan kalau
  /// pengguna ingin gambaran lebih lengkap, turunkan kalau terasa
  /// bertele-tele.
  int wordBudget = 10;

  /// Pengali cooldown untuk pengulangan ke-1, 2, 3, dan seterusnya.
  ///
  /// Objek yang sama, tidak makin dekat, tidak perlu diteriakkan dengan
  /// frekuensi tetap sampai pengguna lewat. Backoff ini yang membuat
  /// narasi terasa "sadar konteks" alih-alih seperti alarm.
  List<double> repeatBackoff = const [1.0, 2.0, 3.5, 5.0];

  Duration criticalCooldown = const Duration(seconds: 2);
  Duration warningCooldown = const Duration(seconds: 3);
  Duration infoCooldown = const Duration(seconds: 5);

  // ── State ────────────────────────────────────────────────────────────

  DateTime? _settlingUntil;
  DateTime? _windowOpenedAt;
  final _window = <String, _WindowEntry>{};
  final _lastAnnounced = <String, DateTime>{};
  final _repeatCount = <String, int>{};
  final _announcedEver = <String>{};
  final _lastZone = <String, String>{};
  bool _firstSummaryDone = false;

  bool get isSettling =>
      _settlingUntil != null && DateTime.now().isBefore(_settlingUntil!);

  /// Panggil saat mode deteksi diaktifkan atau berganti mode.
  void beginSession() {
    _settlingUntil = DateTime.now().add(settlingDuration);
    _window.clear();
    _windowOpenedAt = null;
    _lastAnnounced.clear();
    _repeatCount.clear();
    _announcedEver.clear();
    _lastZone.clear();
    _firstSummaryDone = false;
    TtsQueue.instance.beginSettling(duration: settlingDuration);
  }

  void reset() {
    _settlingUntil = null;
    _window.clear();
    _windowOpenedAt = null;
    _lastAnnounced.clear();
    _repeatCount.clear();
    _announcedEver.clear();
    _lastZone.clear();
    _firstSummaryDone = false;
  }

  // ── Siklus utama ─────────────────────────────────────────────────────

  /// Proses satu frame deteksi. Panggil ini setiap kali inferensi selesai.
  ///
  /// [detections] sebaiknya SUDAH lewat DetectionFilter (sudah difilter
  /// jarak, confidence, dan streak). Scheduler ini bekerja di lapisan
  /// atasnya: dia mengatur KAPAN dan BAGAIMANA yang lolos itu diucapkan.
  NarrationDecision process(List<Detection> detections) {
    final now = DateTime.now();

    if (detections.isEmpty) {
      return _maybeFlushWindow(now, forced: false);
    }

    // ── Pisahkan kandidat ──
    final criticals = <Detection>[];
    final others = <Detection>[];

    for (final d in detections) {
      final id = d.filterKey;
      final danger = d.dangerLevel;

      // Masa tenang: hanya bahaya kritis yang lewat.
      if (isSettling && danger != 'critical') continue;

      // Cooldown dengan backoff.
      final reps = _repeatCount[id] ?? 0;
      final mult = repeatBackoff[min(reps, repeatBackoff.length - 1)];
      var base = switch (danger) {
        'critical' => criticalCooldown,
        'warning' => warningCooldown,
        _ => infoCooldown,
      };

      // Objek yang benar-benar mendekat memotong backoff. Ini pengecualian
      // yang penting: backoff dimaksudkan meredam pengulangan untuk situasi
      // yang TIDAK berubah. Kalau bahayanya makin dekat, situasinya jelas
      // berubah dan pengguna perlu tahu.
      final effectiveMult = d.isApproaching ? 1.0 : mult;
      final cooldown = Duration(
        milliseconds: (base.inMilliseconds * effectiveMult).round(),
      );

      final last = _lastAnnounced[id];
      if (last != null && now.difference(last) < cooldown) continue;

      // Berbasis perubahan: objek info yang sudah diumumkan dan tidak
      // pindah zona tidak diulang.
      if (danger == 'info' && _announcedEver.contains(id)) {
        final prevZone = _lastZone[id];
        if (prevZone != null && prevZone == _zoneOf(d)) continue;
      }

      if (danger == 'critical') {
        criticals.add(d);
      } else {
        others.add(d);
      }
    }

    // ── Anti-kelaparan ──
    final opened = _windowOpenedAt;
    final starving =
        opened != null && now.difference(opened) >= starvationTimeout;

    // ── Critical lewat duluan, kecuali ada yang kelaparan ──
    if (criticals.isNotEmpty && !starving) {
      criticals.sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));
      final d = criticals.first;
      _markAnnounced(d, now);

      return NarrationDecision(
        message: _criticalPhrase(d),
        tier: SpeechTier.critical,
        dedupKey: 'crit:${d.filterKey}:${d.distanceMeter.round()}',
        // Peringatan bahaya harus selesai. Kalimat "awas lubang" yang
        // terpotong di tengah lebih buruk daripada tidak ada sama sekali.
        interruptible: false,
        trackIds: [d.filterKey],
        reason: 'bahaya kritis',
      );
    }

    // ── Kumpulkan non-kritis ke jendela ──
    for (final d in others) {
      _window[d.filterKey] = _WindowEntry(
        trackId: d.filterKey,
        label: _labelId(d),
        zone: _zoneOf(d),
        distance: d.distanceMeter,
        danger: d.dangerLevel,
      );
      _windowOpenedAt ??= now;
    }

    return _maybeFlushWindow(now, forced: starving);
  }

  NarrationDecision _maybeFlushWindow(DateTime now, {required bool forced}) {
    if (_window.isEmpty) return NarrationDecision.silent;

    final opened = _windowOpenedAt;
    if (opened == null) return NarrationDecision.silent;

    final windowElapsed = now.difference(opened);
    final ready = forced || windowElapsed >= groupingWindow;

    // Ringkasan pertama setelah masa tenang dikeluarkan lebih cepat,
    // supaya pengguna segera dapat gambaran begitu mode menyala. Menunggu
    // jendela penuh 2 detik di awal terasa seperti app-nya tidak merespons.
    final firstSummaryDue = !_firstSummaryDone && !isSettling;

    if (!ready && !firstSummaryDue) return NarrationDecision.silent;

    final entries = _window.values.toList();
    final summary = _summarize(entries);
    if (summary.text.isEmpty) {
      _window.clear();
      _windowOpenedAt = null;
      return NarrationDecision.silent;
    }

    final message = summary.text;
    final named = summary.namedIds;

    // Hanya objek yang BENAR-BENAR disebut yang dicatat sudah diumumkan.
    //
    // Versi awal menandai seluruh isi jendela, termasuk yang dipangkas
    // anggaran kata dan cuma terwakili sebagai "dan 3 lainnya". Akibatnya
    // objek yang tidak pernah disebut namanya tetap masuk cooldown dan naik
    // tingkat backoff-nya, jadi giliran bicaranya justru makin jauh setiap
    // kali dia dipangkas. Itu persis kegagalan yang revisi ini ada untuk
    // memperbaiki - cuma pindah satu lapis ke bawah, dan lebih sulit
    // terlihat karena narasinya TERDENGAR baik-baik saja.
    final entriesNamed = entries.where((e) => named.contains(e.trackId));
    for (final e in entriesNamed) {
      _lastAnnounced[e.trackId] = now;
      _announcedEver.add(e.trackId);
      _lastZone[e.trackId] = e.zone;
      _repeatCount[e.trackId] = (_repeatCount[e.trackId] ?? 0) + 1;
    }

    final hasWarning = entriesNamed.any((e) => e.danger == 'warning');
    final ids = entriesNamed.map((e) => e.trackId).toList()..sort();

    // Yang tidak kebagian tetap di jendela dan jendelanya dibuka ulang, jadi
    // dia dijamin dapat giliran pada ringkasan berikutnya alih-alih menunggu
    // deteksi baru yang mungkin tidak pernah datang.
    _window.removeWhere((id, _) => named.contains(id));
    _windowOpenedAt = _window.isEmpty ? null : now;
    _firstSummaryDone = true;
    _pruneMaps(now);

    return NarrationDecision(
      message: message,
      tier: hasWarning ? SpeechTier.warning : SpeechTier.info,
      dedupKey: 'sum:${ids.join(",")}',
      interruptible: true,
      trackIds: ids,
      reason: forced ? 'jendela dipaksa keluar' : 'jendela penuh',
    );
  }

  // ── Penyusunan kalimat ───────────────────────────────────────────────

  String _criticalPhrase(Detection d) {
    final zone = _zoneOf(d);
    final arah = switch (zone) {
      'kiri' => 'di kiri',
      'kanan' => 'di kanan',
      _ => 'di depan',
    };
    final m = d.distanceMeter;
    // Di bawah 1,5 meter, angka justru memperlambat pemahaman. Yang
    // dibutuhkan pengguna saat itu adalah "berhenti", bukan aritmetika.
    if (m < 1.5) {
      return 'Awas, ${_labelId(d)} tepat $arah';
    }
    return 'Awas, ${_labelId(d)} ${m.round()} meter $arah';
  }

  /// Gabungkan beberapa objek jadi satu kalimat ringkas.
  ///
  /// Urutannya: bahaya dulu, lalu yang terdekat. Objek dengan label dan
  /// zona sama digabung jadi hitungan ("2 orang di kanan") alih-alih
  /// disebut satu per satu.
  ///
  /// Mengembalikan kalimatnya BESERTA daftar objek yang benar-benar masuk ke
  /// dalamnya. Pemanggil butuh daftar itu untuk membedakan "sudah diumumkan"
  /// dari "sekadar terhitung di dalam 'dan N lainnya'"; keduanya tidak boleh
  /// diperlakukan sama.
  ({String text, Set<String> namedIds}) _summarize(
      List<_WindowEntry> entries) {
    entries.sort((a, b) {
      final pa = _prio(a.danger);
      final pb = _prio(b.danger);
      if (pa != pb) return pa.compareTo(pb);
      return a.distance.compareTo(b.distance);
    });

    // Kelompokkan per (label, zona), pertahankan urutan kemunculan.
    final groups = <String, List<_WindowEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent('${e.label}|${e.zone}', () => []).add(e);
    }

    final parts = <String>[];
    final namedIds = <String>{};
    var used = 1; // kata "Ada"
    var skipped = 0;

    // Sisakan jatah untuk sufiks "dan N lainnya".
    //
    // Tanpa cadangan ini, sufiksnya menambah panjang DI LUAR anggaran dan
    // narasi tetap melewati batas. Ini bug yang ketahuan waktu simulasi:
    // versi pertama menghasilkan kalimat 5,2 detik padahal anggarannya
    // disetel untuk sekitar 4 detik.
    final reserve = groups.length > 2 ? 3 : 0;
    final effective = max(4, wordBudget - reserve);

    for (final entry in groups.entries) {
      final members = entry.value;
      final label = members.first.label;
      final zone = members.first.zone;
      final n = members.length;

      final arah = switch (zone) {
        'kiri' => 'di kiri',
        'kanan' => 'di kanan',
        _ => 'di depan',
      };
      final frag = n == 1 ? '$label $arah' : '$n $label $arah';
      final cost = frag.split(' ').length;

      if (parts.isNotEmpty && used + cost > effective) {
        skipped += n;
        continue;
      }
      parts.add(frag);
      namedIds.addAll(members.map((m) => m.trackId));
      used += cost;
    }

    if (parts.isEmpty) return (text: '', namedIds: <String>{});

    var text = 'Ada ${parts.join(', ')}';
    if (skipped > 0) {
      text += ', dan $skipped lainnya';
    }
    return (text: text, namedIds: namedIds);
  }

  // ── Helper ───────────────────────────────────────────────────────────

  int _prio(String danger) => switch (danger) {
        'critical' => 0,
        'warning' => 1,
        _ => 2,
      };

  /// Zona horizontal objek.
  ///
  /// Dibaca dari [Detection.direction], yang sudah dihitung TFLiteService
  /// dari koordinat ternormalisasi. Sengaja TIDAK dihitung ulang dari
  /// [Detection.bboxCx]: getter itu mengembalikan pusat kotak dalam PIXEL,
  /// bukan pecahan 0..1, jadi membandingkannya dengan ambang pecahan akan
  /// melempar hampir semua objek ke satu sisi dan membuat arah yang
  /// diucapkan salah hampir sepanjang waktu.
  ///
  /// `direction` bisa membawa sufiks vertikal ("kiri bawah"); narasi ini
  /// hanya mengenal sumbu horizontal, jadi cukup awalannya.
  String _zoneOf(Detection d) {
    final dir = d.direction;
    if (dir.startsWith('kiri')) return 'kiri';
    if (dir.startsWith('kanan')) return 'kanan';
    return 'tengah';
  }

  String _labelId(Detection d) => d.labelId;

  void _markAnnounced(Detection d, DateTime now) {
    final id = d.filterKey;
    _lastAnnounced[id] = now;
    _announcedEver.add(id);
    _lastZone[id] = _zoneOf(d);
    _repeatCount[id] = (_repeatCount[id] ?? 0) + 1;
  }

  /// Batasi pertumbuhan map. trackId terus bertambah sepanjang sesi,
  /// jadi tanpa ini map-nya tumbuh selamanya di perjalanan panjang.
  void _pruneMaps(DateTime now) {
    if (_lastAnnounced.length < 200) return;
    final cutoff = now.subtract(const Duration(seconds: 60));
    _lastAnnounced.removeWhere((_, at) => at.isBefore(cutoff));
    final alive = _lastAnnounced.keys.toSet();
    _repeatCount.removeWhere((k, _) => !alive.contains(k));
    _lastZone.removeWhere((k, _) => !alive.contains(k));
    _announcedEver.removeWhere((k) => !alive.contains(k));
  }

  Map<String, dynamic> debugState() => {
        'settling': isSettling,
        'windowSize': _window.length,
        'windowAgeMs': _windowOpenedAt == null
            ? null
            : DateTime.now().difference(_windowOpenedAt!).inMilliseconds,
        'tracked': _lastAnnounced.length,
        'firstSummaryDone': _firstSummaryDone,
      };
}
