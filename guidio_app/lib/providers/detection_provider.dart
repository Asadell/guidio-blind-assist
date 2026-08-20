import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/net/api_client.dart' show FramePacer;
import '../core/speech/tts_queue.dart';
import '../core/voice/narration_engine.dart';
import '../models/detection.dart';
import '../providers/camera_provider.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/detection_filter.dart';
import '../services/haptic_service.dart';
import '../services/object_tracker.dart';
import '../services/tflite_service.dart';

/// DetectionProvider — Mode Deteksi Objek, sepenuhnya on-device.
///
/// **Jalur server dihapus.** Sebelumnya ada dua jalur (TFLite dan WebSocket
/// `/ws/detect`) yang dipilih dari `InferenceProvider.realtimeEngine`. Itu
/// menggandakan kode di mode paling kritis keselamatan tanpa menambah
/// keandalan: modelnya sudah dibundel di APK, dan hasil server melewati
/// [DetectionFilter] yang sama sehingga mewarisi perilaku yang sama persis.
/// Yang tersisa hanyalah ketergantungan diam-diam pada laptop yang menyala.
/// Sekarang: TFLite gagal muat = dikatakan apa adanya lewat [isUnavailable].
class DetectionProvider extends ChangeNotifier {
  final CameraProvider _cameraProvider;

  DetectionProvider(this._cameraProvider);

  final _filter  = DetectionFilter();
  final _tracker = ObjectTracker();

  /// Satu inferensi dalam penerbangan, dan jeda minimum antar frame.
  ///
  /// Tanpa ini, callback kamera (~30 fps) memicu inferensi yang menumpuk tak
  /// terbatas: tiap frame tertunda memegang buffer sendiri, memori naik, dan
  /// peringatan yang akhirnya terdengar menggambarkan dunia beberapa detik
  /// lalu. 120 ms ≈ 8 fps — dengan `streakRequired = 2`, objek baru terucap
  /// sekitar 250 ms setelah masuk frame, masih di bawah target 500 ms.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 120));

  /// PG-05 / PG-06 — diteruskan dari SettingsProvider setiap kali pengaturan
  /// berubah, supaya slider dan segmented benar-benar mengubah perilaku
  /// deteksi alih-alih hanya tersimpan ke disk.
  void applySettings({required double maxDistanceM, required Verbosity verbosity}) {
    _filter.applySettings(maxDistanceM: maxDistanceM, verbosity: verbosity);
  }

  bool _realtimeActive = false;
  bool get isRealtimeActive => _realtimeActive;

  List<Detection> _detections = [];
  List<Detection> get detections => _detections;

  /// True kalau model on-device tidak bisa dipakai. Layar wajib mengatakannya
  /// — mode ini tidak punya cadangan lain, jadi diam berarti membiarkan orang
  /// berjalan menyangka dirinya dijaga.
  bool get isUnavailable => !TFLiteService.instance.isLoaded;

  /// Kapan terakhir kali pipeline benar-benar menghasilkan sesuatu. Dipakai
  /// layar untuk mendeteksi "hidup tapi bisu".
  DateTime? _lastInferenceAt;
  DateTime? get lastInferenceAt => _lastInferenceAt;

  // ── Real-time ──────────────────────────────────────────────────────────────

  void startRealtime() {
    if (_realtimeActive) return;
    _realtimeActive = true;
    _filter.reset();
    _tracker.reset();
    _cameraProvider.onFrameReady = _processFrame;
    notifyListeners();
  }

  void stopRealtime() {
    _realtimeActive = false;
    _cameraProvider.onFrameReady = null;
    _tracker.reset();
    _filter.reset();
    _detections = [];
    notifyListeners();
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_realtimeActive) return;

    await _pacer.run(() async {
      final raw = await TFLiteService.instance.runInference(image);
      if (!_realtimeActive) return;

      _lastInferenceAt = DateTime.now();

      // Frame kosong tetap diumpankan ke tracker supaya objek yang menghilang
      // benar-benar dianggap hilang setelah beberapa frame. Filter sengaja
      // dilewati: `process([])` hanya akan membersihkan streak, dan itu sudah
      // ditangani tracker.
      if (raw.isEmpty) {
        _tracker.update(const []);
        if (_detections.isNotEmpty) {
          _detections = [];
          notifyListeners();
        }
        return;
      }

      // Tracker memberi identitas stabil per objek. Pemetaannya per-indeks,
      // bukan per-label: dengan dua orang di frame, versi lama mengambil track
      // pertama berlabel "person" untuk keduanya, sehingga status "mendekat"
      // milik orang jauh bisa menempel ke orang dekat — dan status itulah yang
      // memotong cooldown 50%.
      if (!_realtimeActive) return;

      _tracker.update(raw);
      final assignment = _tracker.lastAssignment;

      final enriched = <Detection>[];
      for (var i = 0; i < raw.length; i++) {
        final track = i < assignment.length ? assignment[i] : null;
        enriched.add(raw[i].copyWith(
          isApproaching: track?.isApproaching ?? false,
          trackId: track?.id,
          // Jarak yang DIHALUSKAN, bukan hasil mentah satu frame. Ponsel yang
          // mengayun saat berjalan membuat kotak deteksi membesar-mengecil
          // sendiri; tanpa penghalusan, objek diam terucap "dua meter… satu
          // meter… dua meter" dan pengguna tidak punya cara tahu mana yang
          // benar. Nilai mentah tetap dipakai untuk klasifikasi tier di
          // TFLiteService — yang dihaluskan hanya yang diucapkan.
          distanceMeter: track?.smoothedDistance,
        ));
      }

      final filtered = _filter.process(enriched);
      _updateAndSpeak(filtered);
    });
  }

  void _updateAndSpeak(List<Detection> filtered) {
    _detections = filtered;
    notifyListeners();
    if (filtered.isEmpty) return;

    // Tier = bahaya tertinggi di antara yang lolos. Satu kalimat, satu tier —
    // bukan satu ucapan terpisah per objek yang saling berebut antrean.
    final tier = filtered.any((d) => d.isCritical)
        ? SpeechTier.critical
        : filtered.any((d) => d.isWarning)
            ? SpeechTier.warning
            : SpeechTier.info;

    TtsQueue().speak(_composeNarration(filtered), tier: tier);

    // Getar mendampingi suara — di pasar dan jalan raya, getar sering jadi
    // sinyal utama. Cukup sekali, sesuai tier tertinggi.
    HapticService.instance.fromDangerLevel(
      filtered.first.dangerLevel,
    );
  }

  /// Rangkai satu kalimat dari objek yang lolos filter.
  ///
  /// Fix temuan 2A: `narration_engine.dart` akhirnya tersambung. Selama ini
  /// 265 baris itu tidak pernah dipanggil dari mana pun — yang benar-benar
  /// terucap adalah `det.ttsMessage`, satu kalimat datar per objek, sehingga
  /// dua objek berarti dua ucapan yang saling menyusul tanpa konektor.
  ///
  /// Untuk tier Critical kalimatnya sengaja tetap pendek dan langsung: saat
  /// ada bahaya < 1,5 m, kalimat bernuansa natural justru menunda informasi
  /// yang menentukan.
  String _composeNarration(List<Detection> filtered) {
    final critical = filtered.where((d) => d.isCritical).toList();
    if (critical.isNotEmpty) {
      return critical.first.ttsMessage;
    }

    // Gabungkan objek sekelas dengan arah sama supaya narasinya menyebut
    // "dua orang", bukan "orang" dua kali.
    final grouped = <String, NarrationDetection>{};
    for (final d in filtered) {
      final key = '${d.labelEn}|${d.direction}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = NarrationDetection(
          objectClass: d.labelEn,
          dist: d.distanceMeter,
          dir: _narrationDirection(d.direction),
        );
      } else {
        grouped[key] = NarrationDetection(
          objectClass: existing.objectClass,
          dist: existing.dist < d.distanceMeter ? existing.dist : d.distanceMeter,
          dir: existing.dir,
          count: existing.count + 1,
        );
      }
    }

    final narration = generateNaturalNarration(grouped.values.toList());
    // Kelas di luar kamus 80 COCO membuat narasi kosong. Jangan diam —
    // sampaikan versi datarnya daripada tidak menyebut objeknya sama sekali.
    if (narration.trim().isEmpty || grouped.isEmpty) {
      return filtered.map((d) => d.ttsMessage).join('. ');
    }
    return narration;
  }

  /// `_getDirection` bisa menghasilkan "kiri bawah"; narasi hanya mengenal
  /// sumbu horizontal.
  String _narrationDirection(String direction) {
    if (direction.startsWith('kiri')) return 'kiri';
    if (direction.startsWith('kanan')) return 'kanan';
    return 'tengah';
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}
