import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/net/api_client.dart' show FramePacer;
import '../core/speech/tts_queue.dart';
import '../core/voice/narration_scheduler.dart';
import '../models/detection.dart';
import '../providers/camera_provider.dart';
import '../providers/settings_provider.dart' show Verbosity;
import '../services/detection_filter.dart';
import '../services/haptic_service.dart';
import '../services/object_tracker.dart';
import '../services/tflite_service.dart';

/// DetectionProvider - Mode Deteksi Objek, sepenuhnya on-device.
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

  /// Lapisan di atas [DetectionFilter]: filter memutuskan APA yang layak
  /// diucapkan, scheduler memutuskan KAPAN dan DALAM BENTUK APA.
  ///
  /// Keduanya dibutuhkan. Filter bekerja baik di kondisi mapan, tapi tidak
  /// menangani momen mode baru menyala - saat itu setiap objek adalah objek
  /// baru, tidak satu pun punya catatan cooldown, jadi semuanya lolos
  /// sekaligus. Enam objek berarti enam narasi dalam waktu kurang dari satu
  /// detik, dan yang terjadi berikutnya bukan cuma tumpang tindih: narasi
  /// yang kalah rebutan hilang tanpa jejak, tanpa pengguna pernah tahu.
  final _scheduler = NarrationScheduler();

  /// Satu inferensi dalam penerbangan, dan jeda minimum antar frame.
  ///
  /// Tanpa ini, callback kamera (~30 fps) memicu inferensi yang menumpuk tak
  /// terbatas: tiap frame tertunda memegang buffer sendiri, memori naik, dan
  /// peringatan yang akhirnya terdengar menggambarkan dunia beberapa detik
  /// lalu. 120 ms ≈ 8 fps - dengan `streakRequired = 2`, objek baru terucap
  /// sekitar 250 ms setelah masuk frame, masih di bawah target 500 ms.
  final _pacer = FramePacer(minInterval: const Duration(milliseconds: 120));

  /// PG-05 / PG-06 - diteruskan dari SettingsProvider setiap kali pengaturan
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
  /// - mode ini tidak punya cadangan lain, jadi diam berarti membiarkan orang
  /// berjalan menyangka dirinya dijaga.
  bool get isUnavailable => !TFLiteService.instance.isLoaded;

  /// Kapan terakhir kali pipeline benar-benar menghasilkan sesuatu. Dipakai
  /// layar untuk mendeteksi "hidup tapi bisu".
  DateTime? _lastInferenceAt;
  DateTime? get lastInferenceAt => _lastInferenceAt;

  /// True setelah [dispose]. ChangeNotifier melempar kalau [notifyListeners]
  /// dipanggil sesudah itu, dan [_notify] bisa menunda panggilannya ke frame
  /// berikutnya - jadi penanda ini yang memastikan penundaan itu tidak mendarat
  /// di provider yang sudah mati.
  bool _disposed = false;

  /// [notifyListeners] yang aman dipanggil dari mana saja, termasuk dari
  /// `dispose()` sebuah layar.
  ///
  /// Masalah yang diperbaiki, dari log perangkat:
  ///
  ///     The following assertion was thrown while dispatching notifications
  ///     for DetectionProvider:
  ///     setState() or markNeedsBuild() called when widget tree was locked.
  ///     #4  DetectionProvider.stopRealtime
  ///
  /// Runtutannya: pengguna keluar dari mode Tuntun, Navigator melepas
  /// layarnya SAAT fase build, `TuntunScreen.dispose()` memanggil
  /// [stopRealtime], dan `notifyListeners()` mencoba menandai widget lain
  /// perlu dibangun ulang. Di fase itu pohon widget terkunci, jadi Flutter
  /// melempar. Tidak ada yang rusak secara fungsional - itu sebabnya bug ini
  /// bertahan lama - tapi setiap kali mode ditutup, satu exception merah
  /// dituliskan ke log, dan log yang berisik membuat kegagalan sungguhan
  /// (misalnya `[PIDNet] Unable to create interpreter`) jadi mudah terlewat.
  ///
  /// Selama fase `persistentCallbacks` (build/layout/paint) pemberitahuannya
  /// ditunda ke sesudah frame selesai. Di luar fase itu - yang berlaku untuk
  /// hampir semua panggilan, karena datangnya dari callback kamera - tidak ada
  /// penundaan sama sekali.
  /// True kalau pohon widget sedang terkunci (fase build/layout/paint).
  ///
  /// `SchedulerBinding.instance` MELEMPAR kalau binding-nya belum ada, dan itu
  /// keadaan yang normal: `test/nav_phase_flapping_test.dart` dan kawan-kawan
  /// memakai `test()` biasa, bukan `testWidgets()`, jadi tidak pernah ada
  /// binding sama sekali. Di situ tidak ada pohon widget yang bisa terkunci,
  /// jadi jawabannya false dan pemberitahuannya dikirim langsung.
  bool get _pohonTerkunci {
    try {
      return SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks;
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (_disposed) return;
    if (_pohonTerkunci) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  // ── Real-time ──────────────────────────────────────────────────────────────

  void startRealtime() {
    if (_realtimeActive) return;
    _realtimeActive = true;
    _filter.reset();
    _tracker.reset();
    // Memulai masa tenang. Non-kritis ditahan sampai auto-exposure dan
    // autofocus stabil; bahaya kritis tetap lewat.
    _scheduler.beginSession();
    _cameraProvider.onFrameReady = _processFrame;
    _notify();
  }

  void stopRealtime() {
    _realtimeActive = false;
    _cameraProvider.onFrameReady = null;
    _tracker.reset();
    _filter.reset();
    _scheduler.reset();
    _detections = [];
    _notify();
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
          _notify();
        }
        // Scheduler tetap ditengok. Jendela pengelompokan yang sudah berisi
        // sesuatu harus bisa keluar walau frame ini kosong; kalau tidak,
        // ringkasan menggantung sampai ada deteksi berikutnya - dan kalau
        // pengguna sudah berpaling, deteksi berikutnya mungkin tidak pernah
        // datang, jadi yang sudah terlanjur dikumpulkan hilang begitu saja.
        final decision = _scheduler.process(const []);
        if (decision.shouldSpeak) {
          TtsQueue().speak(
            decision.message!,
            tier: decision.tier,
            dedupKey: decision.dedupKey,
            interruptible: decision.interruptible,
          );
        }
        return;
      }

      // Tracker memberi identitas stabil per objek. Pemetaannya per-indeks,
      // bukan per-label: dengan dua orang di frame, versi lama mengambil track
      // pertama berlabel "person" untuk keduanya, sehingga status "mendekat"
      // milik orang jauh bisa menempel ke orang dekat - dan status itulah yang
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
          // TFLiteService - yang dihaluskan hanya yang diucapkan.
          distanceMeter: track?.smoothedDistance,
        ));
      }

      final filtered = _filter.process(enriched);
      _updateAndSpeak(filtered);
    });
  }

  void _updateAndSpeak(List<Detection> filtered) {
    _detections = filtered;
    _notify();

    // Frame kosong tetap diumpankan ke scheduler: jendela pengelompokan yang
    // sudah berisi sesuatu harus tetap bisa keluar walau frame terakhir tidak
    // menemukan apa-apa. Kalau tidak, ringkasan bisa menggantung selamanya
    // hanya karena objeknya sempat hilang satu frame.
    final decision = _scheduler.process(filtered);

    if (decision.shouldSpeak) {
      TtsQueue().speak(
        decision.message!,
        tier: decision.tier,
        dedupKey: decision.dedupKey,
        interruptible: decision.interruptible,
      );
    }

    if (filtered.isEmpty) return;

    // Getar mendampingi suara - di pasar dan jalan raya, getar sering jadi
    // sinyal utama.
    //
    // Sengaja TIDAK diikat ke `decision.shouldSpeak`. Getar sampai ke
    // pengguna dalam ratusan milidetik sementara kalimat butuh dua sampai
    // tiga detik, jadi menahannya sampai scheduler siap bicara justru
    // membuang keunggulan utamanya. Yang diredam scheduler adalah banjir
    // KATA, bukan kehadiran bahaya.
    HapticService.instance.fromDangerLevel(
      filtered.first.dangerLevel,
    );
  }

  // `_composeNarration` dan `_narrationDirection` DIHAPUS di revisi ini.
  //
  // Penyusunan kalimat untuk mode deteksi realtime sekarang ada di
  // [NarrationScheduler._summarize], karena keputusan "kata apa" tidak bisa
  // dipisahkan dari keputusan "berapa banyak yang muat": scheduler punya
  // anggaran kata, dan anggaran itu yang menjaga satu ucapan tetap sekitar
  // empat detik.
  //
  // Konsekuensinya `narration_engine.dart` tidak lagi dipanggil dari sini.
  // Itu disengaja, bukan kelalaian: gaya naratifnya ("Di sekitarmu, ada dua
  // orang di sebelah kirimu sejauh sekitar tiga meter, serta ...") memang
  // enak didengar, tapi satu klausanya saja sudah menghabiskan hampir
  // seluruh anggaran kata. Gaya itu cocok untuk narasi YANG DIMINTA
  // pengguna, di mana dia sudah siap mendengarkan; bukan untuk aliran
  // deteksi yang datang tanpa diminta delapan kali per detik.
  //
  // Mesin narasi itu sendiri sengaja TIDAK dihapus - lihat catatan di
  // README soal ke mana sebaiknya dia disambungkan.

  @override
  void dispose() {
    // Ditandai SEBELUM [stopRealtime], supaya pembongkarannya tetap berjalan
    // (callback kamera dilepas, tracker dan filter direset) tapi tidak ada
    // satu pun pemberitahuan yang dikirim dari provider yang sedang mati.
    _disposed = true;
    stopRealtime();
    super.dispose();
  }
}
