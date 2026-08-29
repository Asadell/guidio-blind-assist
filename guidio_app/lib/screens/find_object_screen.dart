import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

import '../core/layout/zone_contract.dart';
import '../core/speech/tts_queue.dart';
import '../core/net/frame_codec.dart';
import '../core/voice/command_parser.dart';
import '../core/voice/intents.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// Mode Cari Objek - bagian 12 IMPLEMENTASI.md, 19 state (CO-01..CO-19).
/// **Sepenuhnya di server** lewat `POST /api/cari-objek`; layar ini hanya
/// memasok frame dan menggambar hasilnya. Karena itu ia benar-benar
/// dinonaktifkan saat offline (CO-14), dengan targetnya disimpan.
class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({super.key});

  @override
  State<FindObjectScreen> createState() => _FindObjectScreenState();
}

enum _Debug { co03, co07, co09, co11, co12, co14, co15, co16, co17, co18, co19 }

extension on _Debug {
  String get id => switch (this) {
        _Debug.co03 => 'CO-03', _Debug.co07 => 'CO-07', _Debug.co09 => 'CO-09',
        _Debug.co11 => 'CO-11', _Debug.co12 => 'CO-12', _Debug.co14 => 'CO-14',
        _Debug.co15 => 'CO-15', _Debug.co16 => 'CO-16', _Debug.co17 => 'CO-17',
        _Debug.co18 => 'CO-18', _Debug.co19 => 'CO-19',
      };
  String get title => switch (this) {
        _Debug.co03 => 'Nama tidak jelas',
        _Debug.co07 => 'Lebih dari satu cocok',
        _Debug.co09 => 'Hilang dari pandangan',
        _Debug.co11 => 'Lama tidak ketemu',
        _Debug.co12 => 'Objek tak dikenali',
        _Debug.co14 => 'Offline (mode dinonaktifkan)',
        _Debug.co15 => 'Izin kamera belum ada',
        _Debug.co16 => 'Senyap / TTS mati',
        _Debug.co17 => 'Font scale 200%',
        _Debug.co18 => 'Server error',
        _Debug.co19 => 'Terlalu gelap',
      };
}

class _FindObjectScreenState extends State<FindObjectScreen> with WidgetsBindingObserver {
  // ── Rujukan provider untuk dispose() ──────────────────────────────────
  //
  // `context.read` DILARANG di dalam dispose(): elemennya sudah tidak aktif,
  // jadi pencarian ancestor melempar "Looking up a deactivated widget's
  // ancestor is unsafe". Karena galatnya jatuh di baris PERTAMA yang membaca
  // provider, seluruh pelepasan sesudahnya tidak pernah berjalan - handler
  // dan stream kamera milik mode ini tetap hidup sesudah modenya ditinggalkan.
  // Rujukannya karena itu dicatat saat dependensi siap.
  late FindObjectProvider _findObject;
  late VoiceProvider _voice;
  late CameraProvider _cam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _findObject = context.read<FindObjectProvider>();
    _voice = context.read<VoiceProvider>();
    _cam = context.read<CameraProvider>();
  }

  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _hasCameraPermission = true;
  _Debug? _debugOverride;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _stt.initialize().then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<FindObjectProvider>();

      // Prinsip 6 "umumkan saat tiba" - sesudah layar terpasang.
      //
      // Kalau target sudah ada, pengumumannya menyebut target itu dan tombol
      // yang harus ditekan, BUKAN kalimat pembuka bawaan mode ini. Layar ini
      // bisa dimasuki dari dua arah yang sangat berbeda:
      //
      //   - lembar Pilih Mode, tanpa target  -> "Sebutkan barang yang kamu
      //     cari" adalah kalimat yang tepat
      //   - perintah "carikan kacamata"      -> kalimat itu keliru; pengguna
      //     baru saja menyebutkannya
      //
      // Yang kedua yang selama ini salah: pengguna mengucapkan "carikan
      // kacamata", layar menampilkan "Mencari kacamata", tapi yang terdengar
      // cuma "Cari Objek aktif. Sebutkan barang yang kamu cari." Layarnya
      // benar; suaranya - satu-satunya yang bisa diakses pengguna tunanetra -
      // tidak.
      final target = provider.target;
      context.read<AppModeProvider>().announceEntry(
            AppMode.findObject,
            introOverride: target == null
                ? null
                : 'Mencari $target, tekan tombol kiri bawah '
                    'untuk memindai sekitarmu.',
          );
      provider.onSpeak = (text, tier) => context.read<TtsProvider>().speak(text, tier: tier);
      provider.onDirectionHaptic = _fireDirectionHaptic;
      // Server tidak menjawab sama saja tidak bisa mencari - periksa sebelum
      // memotret, bukan sesudah permintaannya gagal.
      provider.isOffline = () =>
          context.read<GlobalConditionsProvider>().isBackendDown;
      provider.frameSource = _grabFrame;
      provider.frameRejectReason = () => _rejectedCaptureMessage;
      provider.loadKnownTargets();

      // Kontrak tombol kiri: "jepret" lewat suara = menekan tombol kirim.
      final voice = context.read<VoiceProvider>();
      voice.onPrimaryAction = _triggerScan;
      voice.primaryActionLabel = () => 'mencari ${provider.target ?? "barang"}';
      voice.onRepeatLast = () {
        final pos = provider.lastKnownPosition;
        context.read<TtsProvider>().speak(
              pos == null
                  ? 'Belum ada hasil pencarian.'
                  : '${provider.target ?? "Barang"} terakhir terlihat di $pos.',
              tier: SpeechTier.info,
            );
      };
      if (_hasCameraPermission) {
        // Preset foto diminta DI SINI, bukan hanya di `_checkPermission`.
        // Cabang di sana hanya jalan saat status izin BERUBAH, sementara
        // `_hasCameraPermission` bernilai true sejak awal - jadi pada kasus
        // paling umum (izin sudah lama diberikan) mode ini mengirim frame
        // 640x480 ke YOLOE, dan barang kecil di kejauhan hilang di resolusi
        // itu sebelum modelnya sempat menilai. Yang terdengar pengguna adalah
        // "barangnya tidak ada", padahal barangnya ada.
        final cam = context.read<CameraProvider>();
        await cam.initCamera(preset: CapturePreset.capture);
        if (!mounted) return;
        cam.onFrameReady = (image) => _latestFrame = image;
        // Frame simpanan dibuang saat kamera dilepas ke latar
        // belakang - pemandangan lama tidak boleh dipakai lagi.
        cam.onFramesInvalidated = () => _latestFrame = null;
        cam.startStream();
      }
    });
  }

  /// Status koneksi frame sebelumnya - dipakai mendeteksi transisi
  /// offline→online untuk menepati janji CO-14.
  bool _wasOffline = false;

  /// Frame terakhir dari stream kamera. Disimpan mentah dan baru dikodekan
  /// saat benar-benar akan dikirim - mengodekan tiap frame kamera padahal
  /// hanya sebagian kecil yang terkirim adalah pemborosan CPU dan baterai
  /// yang langsung terasa sebagai panas di tangan pengguna.
  CameraImage? _latestFrame;

  /// Ambil frame terakhir untuk dikirim, setelah dinilai ketajamannya.
  ///
  /// Penilaian dilakukan pada bidang luma (Y) dari `CameraImage` secara
  /// langsung, di isolate terpisah. Dua alasan teknisnya:
  ///
  /// - `YUV420` sudah memberi bidang Y terpisah, dan itu persis grayscale
  ///   yang dibutuhkan. Mengodekan ke JPEG dulu lalu mendekodenya kembali
  ///   berarti dua pekerjaan berat untuk hasil yang sama.
  /// - Perhitungan Laplacian pada frame 1280x720 cukup berat untuk
  ///   melewatkan beberapa frame UI kalau dikerjakan di thread utama, dan
  ///   gejalanya adalah preview yang tersendat persis saat pengguna membidik.
  ///
  /// Frame terakhir, dikirim APA ADANYA.
  ///
  /// Penilaian ketajaman dan cahaya sudah DILEPAS dari sini, mengikuti jalur
  /// Deskripsi Suasana yang lebih dulu melepasnya.
  ///
  /// Gerbang lamanya punya alasan yang masuk akal di atas kertas: YOLOE
  /// membalas `found=false` untuk frame gelap gulita, dan di telinga pengguna
  /// itu terdengar sama persis dengan "barangnya memang tidak ada di sini",
  /// padahal tindakan yang tepat berbeda total.
  ///
  /// Yang tidak masuk akal adalah harganya. Pengguna tunanetra sudah
  /// mengangkat ponsel, mengarahkannya ke sekeliling, dan menekan tombol -
  /// lalu ditolak sebelum satu byte pun terkirim, dan disuruh mengulang
  /// semuanya tanpa bisa melihat fotonya untuk tahu apa yang harus diperbaiki.
  /// Percobaan kedua tidak lebih terinformasi daripada yang pertama.
  ///
  /// Pembedaannya tidak hilang, hanya pindah ke tempat yang tidak membatalkan
  /// apa pun: server menilai kualitas foto dan mengirimkan `quality_note`
  /// ("Fotonya gelap, jadi hasilnya mungkin tidak tepat") bersama hasilnya.
  /// Jadi jawaban dari foto buruk tetap datang dengan keraguannya - yang
  /// hilang cuma penolakannya.
  Future<Uint8List?> _grabFrame() async {
    // Aliran mati = frame simpanan sudah basi. Mengirim pemandangan lama ke
    // YOLOE berarti melaporkan barang yang terlihat sebelum pengguna
    // meninggalkan aplikasi. Lihat catatan panjang di
    // `navigasi_screen._grabCameraImage`.
    if (!mounted || !context.read<CameraProvider>().isStreaming) return null;

    final frame = _latestFrame;
    if (frame == null) return null;

    return FrameCodec.encodeForUpload(
      frame,
      maxEdge: UploadPreset.findObject.maxEdge,
      quality: UploadPreset.findObject.quality,
    );
  }

  /// Alasan frame terakhir tidak bisa diambil.
  ///
  /// Sejak penilaian kualitas dilepas dari [_grabFrame], satu-satunya sebab
  /// frame null adalah kamera yang belum siap atau aliran yang sudah mati -
  /// bukan lagi soal gelap atau buram. Pesannya harus menyebut sebab yang
  /// benar: menyuruh menyalakan senter untuk kamera yang belum menyala adalah
  /// instruksi yang tidak akan pernah berhasil, dan pengguna tunanetra tidak
  /// punya cara mengetahui bahwa dia sedang menuruti saran yang salah.
  String? get _rejectedCaptureMessage =>
      'Kamera belum siap. Tunggu sebentar lalu tekan lagi.';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdCapTimer?.cancel();
    _finalWaitTimer?.cancel();
    _stt.cancel();
    // Layar yang ditinggalkan di tengah sesi tahan tidak akan pernah menutup
    // gerbang suaranya sendiri, dan mode berikutnya akan diam tanpa sebab
    // sampai penjaga waktu bertindak.
    TtsQueue.instance.endVoiceSession();
    _findObject.onSpeak = null;
    _findObject.onDirectionHaptic = null;
    _findObject.frameSource = null;
    _findObject.frameRejectReason = null;
    _findObject.isOffline = null;
    _findObject.reset();
    _voice.clearModeHandlers();
    _cam.onFrameReady = null;
    _cam.onFramesInvalidated = null;
    _cam.stopStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.camera.isGranted;
    if (!mounted) return;
    if (granted != _hasCameraPermission) {
      setState(() => _hasCameraPermission = granted);
      if (granted) {
        final cam = context.read<CameraProvider>();
        await cam.initCamera(preset: CapturePreset.capture);
        cam.startStream();
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      final cam = context.read<CameraProvider>();
      await cam.initCamera(preset: CapturePreset.capture);
      cam.startStream();
    }
  }

  Future<void> _fireDirectionHaptic(String direction) async {
    final mode = context.read<SettingsProvider>().vibrationMode;
    if (mode == VibrationMode.off) return;
    final has = await Vibration.hasVibrator();
    if (!has) return;
    if (direction == 'kiri') {
      Vibration.vibrate(duration: 60);
    } else if (direction == 'kanan') {
      Vibration.vibrate(pattern: [0, 60, 60, 60]);
    }
  }

  // ── Tombol "Sebutkan barang": tekan-tahan, STT milik layar ini ───────────
  //
  // Mode ini tidak bisa ikut jalur `VoiceProvider`: yang diucapkan pengguna di
  // sini adalah NAMA BARANG bebas ("kunci motor", "dompet cokelat"), bukan
  // salah satu frasa di bank kata.
  //
  // Sesinya tetap milik layar ini, TAPI ia tidak lagi membajak tombol tengah.
  // Dulu begitu, dan harganya baru terlihat saat dipakai: di mode inilah
  // pengguna paling mungkin ingin menyerah dan pindah ke mode lain - barangnya
  // tidak ketemu juga, tangannya penuh, matanya tidak bisa mencari tombol
  // Pilih mode - dan justru di sini satu-satunya jalan pindah lewat suara
  // ditutup.
  //
  // Sekarang: tombol tengah = perintah suara (sama seperti lima mode lain),
  // tombol lebar di atas bar = nama barang. Gestur keduanya identik karena
  // sama-sama memakai `HoldToTalkGesture`.

  /// Teks parsial untuk pill di atas tombol.
  String _heardPartial = '';

  /// Hasil akhir sudah tiba dan sudah disetorkan ke provider.
  bool _gotFinalResult = false;

  /// Batas atas satu sesi tahan, sepadan dengan [kHoldToTalkMaxHold].
  Timer? _holdCapTimer;

  /// Jaring pengaman kalau hasil akhir tidak pernah datang setelah `stop()`.
  Timer? _finalWaitTimer;

  Future<void> _onMicHoldStart() async {
    final offline = context.read<GlobalConditionsProvider>().isOffline;
    if (offline) return; // CO-14 - mode benar-benar dinonaktifkan
    if (!_sttReady) return;

    HapticService.instance.info();
    _gotFinalResult = false;
    setState(() {
      _debugOverride = null;
      _heardPartial = '';
    });

    // Provider diambil SEBELUM `await` di bawah. Sesudah await, widget ini
    // bisa saja sudah dilepas dan `context`-nya tidak lagi sah.
    final provider = context.read<FindObjectProvider>();

    // Bungkam mode SEBELUM mikrofon dibuka, persis seperti jalur
    // `VoiceProvider`. Sesi ini memakai mesin pengenal yang berbeda, tapi
    // mikrofonnya sama dan masalahnya sama: petunjuk mode yang terucap saat
    // pengguna menyebut "kunci motor" ikut terekam sebagai bagian namanya.
    await TtsQueue.instance.beginVoiceSession();
    if (!mounted) {
      TtsQueue.instance.endVoiceSession();
      return;
    }

    provider.startListening();

    _holdCapTimer?.cancel();
    _holdCapTimer = Timer(kHoldToTalkMaxHold, _onHoldCapReached);

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _heardPartial = result.recognizedWords);
        if (!result.finalResult) return;
        _gotFinalResult = true;
        _submitHeard(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        cancelOnError: true,
        // Sengaja melebihi batas tahan, supaya yang memotong sesi selalu
        // [_holdCapTimer] - satu penjelasan untuk satu peristiwa.
        listenFor: kHoldToTalkMaxHold + kHoldToTalkGrace,
        pauseFor: kHoldToTalkMaxHold + kHoldToTalkGrace,
      ),
    );
  }

  Future<void> _onMicHoldEnd() async {
    _holdCapTimer?.cancel();
    _holdCapTimer = null;
    HapticService.instance.warning();
    if (_stt.isListening) await _stt.stop();

    // Gerbang dilepas begitu mikrofon tertutup, bukan setelah hasilnya tiba.
    //
    // Jawaban mode ini ("Baik, mencari dompet.") bersumber `mode`, bukan
    // `assistant` - kalau gerbang masih tertutup saat jawaban itu berangkat,
    // ia akan dibuang tanpa jejak dan pengguna menyebut barangnya ke ruang
    // hampa. Risiko kontaminasi mikrofon sudah nol di titik ini.
    TtsQueue.instance.endVoiceSession();

    // `stop()` meminta hasil akhir, tapi tidak menjaminnya: kalau tidak ada
    // satu kata pun tertangkap, tidak ada apa pun yang datang - dan provider
    // tinggal di FindObjectState.listening selamanya, dengan pill yang terus
    // menyala dan tombol Kirim yang tetap mati. Untuk pengguna yang tidak
    // melihat layar itu jalan buntu yang hening.
    _finalWaitTimer?.cancel();
    _finalWaitTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _gotFinalResult) return;
      setState(() => _heardPartial = '');
      // String kosong sengaja: provider menjawabnya dengan "Cari apa?" lalu
      // kembali ke idle.
      context.read<FindObjectProvider>().submitHeardText('');
    });
  }

  Future<void> _onHoldCapReached() async {
    if (!mounted) return;
    await _stt.cancel();
    TtsQueue.instance.endVoiceSession();
    HapticService.instance.warning();
    if (!mounted) return;
    setState(() => _heardPartial = '');
    context.read<TtsProvider>().speak(
          'Waktu habis, silakan coba lagi.',
          tier: SpeechTier.info,
        );
    context.read<FindObjectProvider>().backToIdle();
  }

  /// Tombol "Sebutkan barang" ditekan, bukan ditahan - atau ditekan saat mati.
  ///
  /// Selalu bersuara. Tombol yang ditekan lalu hening tidak bisa dibedakan
  /// dari aplikasi yang macet oleh pengguna yang tidak melihat layar.
  void _explainSpeakButton() {
    HapticService.instance.info();
    final reason = _speakButtonDisabledReason;
    TtsQueue.instance.speak(
      reason == null
          ? 'Tahan tombolnya, lalu sebutkan barangnya.'
          : 'Sebutkan barang, tidak tersedia. $reason.',
      tier: SpeechTier.info,
      source: SpeechSource.assistant,
    );
  }

  /// Null berarti tombol "Sebutkan barang" hidup.
  String? get _speakButtonDisabledReason {
    if (!_sttReady) return 'pengenalan suara belum siap di ponsel ini';
    return null;
  }

  void _submitHeard(String heard) {
    _finalWaitTimer?.cancel();
    if (mounted) setState(() => _heardPartial = '');

    // Perintah ganti mode tidak boleh jadi nama barang.
    //
    // Tombol ini cuma menampung nama barang, tapi pengguna yang menyerah
    // mencari sering mengucapkan "pindah ke navigasi" ke tombol mana pun yang
    // sedang dipegangnya. Tanpa penjagaan ini kalimat itu jadi target harfiah,
    // dipindai, dan dilaporkan tidak ketemu - jawaban yang membuatnya
    // menyimpulkan perintah pindah mode pun sudah rusak.
    final command = CommandParser.parse(heard);
    if (command.intent?.isModeChange ?? false) {
      TtsQueue.instance.speak(
        'Tombol ini untuk menyebut barang. Untuk pindah mode, pakai tombol '
        'bicara di tengah.',
        tier: SpeechTier.info,
        source: SpeechSource.assistant,
      );
      return;
    }

    // Seluruh ucapan di tombol ini memang dimaksudkan sebagai nama barang,
    // jadi yang dipakai bukan hasil [CommandParser.parse] - ia mengembalikan
    // intent kosong untuk "keyboard" - melainkan pengupas kata pembuka.
    //
    // Sebelumnya kalimat yang tidak diawali kata seperti "cari" dipakai APA
    // ADANYA. Itu yang membuat ganti barang tidak pernah bekerja: tombolnya
    // sendiri berlabel "Ganti barang", jadi pengguna mengucapkan "ganti
    // barang jadi keyboard", dan seluruh kalimat itu yang dikirim ke YOLOE
    // sebagai nama barang.
    final target = CommandParser.extractFindObjectTarget(heard);

    // `null` diteruskan sebagai string kosong: provider menjawabnya dengan
    // "Cari apa?" lalu kembali ke idle. Itu jauh lebih baik daripada memasang
    // kalimat pembuka sebagai target dan memindai sesuatu yang tidak ada.
    context.read<FindObjectProvider>()
        .submitHeardText(heard, parsedTarget: target ?? '');
  }

  /// Dipanggil saat tombol kiri (📷 / "Kirim") ditekan.
  /// Ambil satu foto dari frame kamera terakhir → kirim ke backend YOLOE.
  Future<void> _triggerScan() async {
    final fo = context.read<FindObjectProvider>();
    if (fo.isScanning || fo.target == null) return;
    await fo.triggerScan();
  }

  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMuted,
      barrierColor: AppColors.scrimDim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      constraints: const BoxConstraints(maxHeight: 620),
      builder: (sheetCtx) => _DebugSheet(
        current: _debugOverride,
        onSelect: (d) {
          Navigator.pop(sheetCtx);
          setState(() => _debugOverride = d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final fo = context.watch<FindObjectProvider>();
    final offline = context.watch<GlobalConditionsProvider>().isOffline;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // CO-14 - janji "saya coba lagi begitu internet kembali" hanya bernilai
    // kalau benar-benar ditepati tanpa pengguna menyebut ulang barangnya.
    if (_wasOffline && !offline && fo.savedTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<FindObjectProvider>().retrySavedTarget();
      });
    }
    _wasOffline = offline;

    final disabledOffline = offline && _debugOverride != _Debug.co14 ? true : _debugOverride == _Debug.co14;
    final banner = disabledOffline
        ? const StatusBanner(tier: AlertTier.warning, message: 'Tanpa internet, Cari Objek tidak tersedia')
        : null;
    final hasBanner = banner != null;
    final hasTarget = _debugOverride == null && fo.target != null && fo.state != FindObjectState.idle;

    // Tombol "Sebutkan barang" ikut hilang bersama kontennya: saat izin kamera
    // belum ada, atau saat mode ini benar-benar dimatikan karena offline.
    // Tombol yang hidup di layar yang modenya mati adalah janji yang tidak
    // bisa ditepati.
    final showSpeakButton = _hasCameraPermission &&
        _debugOverride != _Debug.co15 &&
        !disabledOffline;

    // Slot lampu, ditumpuk DI ATAS tombol "Sebutkan barang".
    //
    // Urutannya dipilih supaya tombol yang paling sering dipakai tetap paling
    // dekat ke ibu jari: mencari barang adalah pekerjaan mode ini, menyalakan
    // lampu cuma persiapannya. Slot lampu juga datang dan pergi mengikuti
    // cahaya, sedangkan tombol Sebutkan barang selalu ada - menaruh yang
    // berubah-ubah di bawah akan menggeser yang tetap.
    final showTorchSlot = TorchSlot.visible(
          cam,
          hasCameraPermission: _hasCameraPermission,
        ) &&
        !disabledOffline &&
        _debugOverride != _Debug.co15;

    final slotStack = (showSpeakButton ? HoldToTalkButton.slotHeight : 0.0) +
        (showTorchSlot ? TorchSlot.slotHeight : 0.0);

    return Scaffold(
      backgroundColor: AppColors.cameraVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCameraPermission && cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: AppColors.cameraVoid),

          if (banner != null) Positioned(top: topInset, left: 0, right: 0, child: banner),

          Positioned(
            top: topInset + modeBadgeTopOffset(hasBanner: hasBanner),
            left: AppSpacing.screenMargin,
            child: ModeBadge(mode: AppMode.findObject, onDebugActivate: _openDebugSheet),
          ),

          if (hasTarget || _debugOverride != null)
            Positioned(
              top: topInset + secondaryChipTopOffset(hasBanner: hasBanner),
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              child: TargetChip(itemName: _debugTarget ?? fo.target ?? ''),
            ),

          if (!_hasCameraPermission || _debugOverride == _Debug.co15)
            // CO-15 - kartu di zona konten, tombolnya di slot kartu bawah.
            PermissionPrompt(
              icon: Icons.camera_alt_outlined,
              title: 'Izin kamera',
              reason: 'Kamera dipakai untuk mencari dan menunjukkan arah barang yang kamu sebutkan.',
              actionLabel: 'Izinkan kamera',
              onAction: _requestPermission,
            )
          else if (disabledOffline)
            const SizedBox.shrink()
          else
            // Konten digeser ke atas setinggi tombol "Sebutkan barang".
            // Slot itu duduk di antara konten dan bar, dan kartu hasil
            // pencarian yang tertutup tombol sama saja dengan tidak ada.
            ..._buildContent(context, fo, bottomInset + slotStack),

          if (showTorchSlot)
            Positioned(
              left: 0, right: 0,
              bottom: bottomInset +
                  AppSizes.bottomActionBarHeight +
                  (showSpeakButton ? HoldToTalkButton.slotHeight : 0.0),
              child: TorchSlot(
                cam: cam,
                dismissMessage:
                    'Baik, lampu tidak dinyalakan. Cari Objek tetap berjalan.',
              ),
            ),

          // Tombol "Sebutkan barang" - tekan-tahan, memakai STT layar ini.
          //
          // Bentuknya sengaja sama dengan tombol izin kamera dan mikrofon di
          // layar pembuka: satu blok selebar layar, 96 dp, tidak mungkin
          // meleset dijangkau satu tangan sambil memegang tongkat.
          if (showSpeakButton)
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s3,
              child: HoldToTalkButton(
                label: fo.target == null ? 'Sebutkan barang' : 'Ganti barang',
                listeningLabel: 'Mendengarkan…',
                icon: Icons.record_voice_over_outlined,
                liveTranscript: _heardPartial,
                listening: fo.state == FindObjectState.listening,
                onHoldStart: _speakButtonDisabledReason == null ? _onMicHoldStart : null,
                onHoldEnd: _speakButtonDisabledReason == null ? _onMicHoldEnd : null,
                disabledReason: _speakButtonDisabledReason,
                onTooShort: _explainSpeakButton,
              ),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
              // Tombol kiri: aktif hanya saat ada target DAN tidak sedang scanning.
              // Label berubah jadi 'Kirim' supaya jelas fungsinya (bukan
              // "ambil foto" biasa, melainkan "kirim ke server untuk dicari").
              onCameraPressed: (fo.target != null && !fo.isScanning && _debugOverride == null)
                  ? _triggerScan
                  : null,
              cameraEnabled: fo.target != null && !fo.isScanning && _debugOverride == null,
              cameraDisabledReason: fo.target == null
                  ? 'tahan tombol Sebutkan barang di atas'
                  : 'sedang memindai',
              cameraLabel: fo.target != null ? 'Kirim - cari ${fo.target}' : 'Sebutkan barang dulu',
              // Tombol tengah TIDAK ditimpa lagi. Di mode ini pun ia berarti
              // perintah suara, sama seperti lima mode lain.
            ),
          ),
        ],
      ),
    );
  }

  String? get _debugTarget => switch (_debugOverride) {
        _Debug.co07 => 'kunci motor',
        _Debug.co09 => 'dompet',
        _Debug.co11 => 'ponsel',
        null => null,
        _ => 'barang',
      };

  List<Widget> _buildContent(BuildContext context, FindObjectProvider fo, double bottomInset) {
    if (_debugOverride != null) return _renderDebug(_debugOverride!, bottomInset);

    switch (fo.state) {
      case FindObjectState.idle:
        return [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VoiceOrb(state: VoiceOrbState.idle),
                const SizedBox(height: AppSpacing.s4),
                _pill('Sebutkan barang yang kamu cari'),
              ],
            ),
          ),
        ];
      case FindObjectState.listening:
        return [const Center(child: VoiceOrb(state: VoiceOrbState.listening))];
      case FindObjectState.unclear:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure),
          const SizedBox(height: AppSpacing.s4),
          _pill('Cari apa?'),
        ]))];
      case FindObjectState.targetActive:
      case FindObjectState.scanning:
        return [
          Positioned(
            left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
            bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
            child: AlertCard(
              tier: AlertTier.info,
              title: fo.state == FindObjectState.scanning
                  ? 'Memindai ke server…'
                  : 'Tekan tombol kirim untuk memindai',
              description: 'Mencari ${fo.target}',
            ),
          ),
          if (fo.state == FindObjectState.scanning)
            const Center(
              child: SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.onDark,
                ),
              ),
            ),
        ];
      case FindObjectState.found:
        return [_bottomPanel(bottomInset, _foundCard(fo))];
      case FindObjectState.lostFromView:
        return [_bottomPanel(bottomInset, AlertCard(
          tier: AlertTier.warning,
          title: '${fo.target} sempat hilang dari pandangan',
          description: 'Terakhir terlihat: ${fo.lastKnownPosition}',
        ))];
      case FindObjectState.notFoundInFrame:
        return [_bottomPanel(bottomInset, AlertCard(tier: AlertTier.info, title: fo.notFoundMessage, description: 'Mencari ${fo.target}'))];
      case FindObjectState.longNotFound:
        return [_bottomPanel(bottomInset, const AlertCard(
          tier: AlertTier.warning,
          title: 'Belum ketemu di ruangan ini',
          description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.',
        ))];
      case FindObjectState.unknownObject:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Coba sebutkan barang lain.'))];
      case FindObjectState.serverError:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case FindObjectState.tooDark:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
      case FindObjectState.offlineSaved:
        // CO-14 - targetnya disimpan, dan itu dikatakan. Bukan "perintah
        // gagal": perintahnya diterima, hanya pelaksanaannya yang menunggu.
        return [
          _bottomPanel(
            bottomInset,
            AlertCard(
              tier: AlertTier.warning,
              title: 'Cari objek butuh internet',
              description: 'Target ${fo.savedTarget ?? fo.target} disimpan. '
                  'Saya lanjutkan begitu internet kembali.',
            ),
          ),
        ];
    }
  }

  Widget _foundCard(FindObjectProvider fo) {
    final title = fo.matchCount > 1
        ? '${fo.matchCount} ${fo.target} terlihat, yang terdekat di ${fo.direction}'
        : '${fo.target} di ${fo.direction}';
    // CO-08 - panduan bertahap: dekat sekali menyebut "ulurkan tangan".
    final description = fo.distanceMeter < 1 ? 'Sudah sangat dekat, ulurkan tangan' : null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AlertCard(tier: AlertTier.positive, title: title, description: description, distanceMeter: fo.distanceMeter),
        if (fo.matchCount > 1)
          Positioned(
            top: -10, right: 12,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(color: AppColors.actionLabel, borderRadius: AppRadius.pillShape),
                child: Text('+${fo.matchCount - 1} lagi', style: AppTypography.caption(color: AppColors.onDark)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(String text) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
        child: Text(text, style: AppTypography.body(color: AppColors.onDark)),
      ),
    );
  }

  Widget _bottomPanel(double bottomInset, Widget child) {
    return Positioned(
      left: AppSpacing.screenMargin, right: AppSpacing.screenMargin,
      bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
      child: child,
    );
  }

  List<Widget> _renderDebug(_Debug d, double bottomInset) {
    switch (d) {
      case _Debug.co03:
        return [Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const VoiceOrb(state: VoiceOrbState.failure), const SizedBox(height: AppSpacing.s4), _pill('Cari apa?'),
        ]))];
      case _Debug.co07:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: '3 kunci motor terlihat, yang terdekat di kiri', distanceMeter: 1.4))];
      case _Debug.co09:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'dompet sempat hilang dari pandangan', description: 'Terakhir terlihat: kanan, sekitar satu meter'))];
      case _Debug.co11:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.warning, title: 'Belum ketemu di ruangan ini', description: 'Coba pindah ruangan, atau ucapkan barang lain untuk ganti target.'))];
      case _Debug.co12:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.info, title: 'Barang belum dikenali', description: 'Saya bisa mencari dompet, misalnya.'))];
      case _Debug.co14:
        return [];
      case _Debug.co15:
        return [];
      case _Debug.co16:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di kiri', distanceMeter: 1.2, description: 'Senyap aktif - arah lewat getar: 1 ketuk kiri, 2 ketuk kanan'))];
      case _Debug.co17:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.positive, title: 'kunci di depan', distanceMeter: 1.2))];
      case _Debug.co18:
        return [_bottomPanel(bottomInset, const AlertCard(tier: AlertTier.critical, title: 'Bukan karena kameramu', description: 'Server pencarian sedang bermasalah.'))];
      case _Debug.co19:
        return [_bottomPanel(bottomInset, const CameraHealthToast(issue: CameraHealthIssue.dark))];
    }
  }
}

class _DebugSheet extends StatelessWidget {
  final _Debug? current;
  final ValueChanged<_Debug?> onSelect;
  const _DebugSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Debug - Mode Cari Objek',
              closeLabel: 'Tutup panel debug',
            ),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('Kembali ke mode otomatis'), onTap: () => onSelect(null)),
                  for (final d in _Debug.values)
                    ListTile(
                      leading: SizedBox(width: 56, child: Text(d.id, style: AppTypography.metricMono(color: AppColors.actionLabel))),
                      title: Text(d.title),
                      selected: d == current,
                      onTap: () => onSelect(d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
