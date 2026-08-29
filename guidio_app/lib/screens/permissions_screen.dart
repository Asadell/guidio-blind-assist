import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tts_service.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// IZ-01..IZ-07 - dua kartu alasan terpisah (kamera dulu, lalu mikrofon).
/// IZ-04: ditolak permanen dibacakan empat langkah bernomor, bertahap.
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionsScreen({super.key, required this.onDone});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

enum _Step { camera, microphone }

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  _Step _step = _Step.camera;
  bool _permanentlyDenied = false;
  bool _requesting = false;

  /// Langkah pembuka belum ditentukan - layar belum boleh merender kartu apa
  /// pun. Tanpa penjaga ini kartu "Izin kamera" sempat berkedip satu frame
  /// bagi pengguna yang kameranya sudah lama diizinkan dan sebenarnya hanya
  /// perlu ditanya soal mikrofon.
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveStartStep();
  }

  /// Menentukan langkah pembuka dari status izin yang SEBENARNYA.
  ///
  /// Sebelumnya layar ini selalu mulai dari kamera, dan `MainScreen` hanya
  /// memanggilnya kalau kamera belum diizinkan. Akibatnya pengguna yang
  /// mengizinkan kamera tapi menolak mikrofon TIDAK PERNAH ditanya lagi soal
  /// mikrofon: layar ini tidak pernah tampil, `VoiceProvider.init()` gagal
  /// diam-diam, dan perintah suara - jalur utama aplikasi ini - mati tanpa
  /// satu pun kalimat yang menjelaskan kenapa.
  Future<void> _resolveStartStep() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    if (!mounted) return;
    if (!camera) {
      setState(() {
        _step = _Step.camera;
        _resolving = false;
      });
      // Memotong: apa pun yang masih dibacakan berasal dari panduan yang
      // sudah ditinggalkan pengguna.
      _announceStep(interrupt: true);
    } else if (!mic) {
      setState(() {
        _step = _Step.microphone;
        _resolving = false;
      });
      _announceStep(interrupt: true);
    } else {
      widget.onDone();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // IZ-06 - kembali dari Pengaturan sistem, cek ulang status izin.
    if (state == AppLifecycleState.resumed && _permanentlyDenied) {
      _checkAfterSettingsReturn();
    }
  }

  Future<void> _checkAfterSettingsReturn() async {
    final granted = _step == _Step.camera
        ? await Permission.camera.isGranted
        : await Permission.microphone.isGranted;
    if (granted) {
      setState(() => _permanentlyDenied = false);
      unawaited(TTSService.instance
          .speak('Izin diberikan. Melanjutkan.', interrupt: true));
      _advance();
    }
  }

  /// [interrupt] hanya saat MASUK layar ini, bukan saat berpindah langkah.
  ///
  /// Masuk berarti apa pun yang masih dibacakan berasal dari panduan yang
  /// sudah ditinggalkan - potong. Berpindah langkah berarti "Izin diberikan."
  /// baru saja diucapkan dan masih berlaku - kalimat ini menyusul di
  /// belakangnya, tidak menimpanya.
  void _announceStep({bool interrupt = false}) {
    final label = _step == _Step.camera ? 'kamera' : 'mikrofon';
    TTSService.instance
        .speak('Vinara butuh izin $label untuk berfungsi.', interrupt: interrupt);
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    final permission = _step == _Step.camera ? Permission.camera : Permission.microphone;
    final status = await permission.request();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (status.isGranted) {
      // TIDAK di-`await`, dan itu inti perbaikannya.
      //
      // `TTSService.speak` merantai tiap ucapan di belakang ucapan sebelumnya
      // lalu mengembalikan Future yang baru selesai saat GILIRANNYA habis
      // diucapkan. Menunggunya sebelum `_advance()` berarti perpindahan
      // langkah dibayar dengan seluruh sisa antrean suara - dan antrean itu
      // bisa panjang justru pada pengguna yang paling cepat: mengetuk
      // "Lanjut" tiga kali di panduan menumpuk tiga narasi, lalu izin kamera
      // diberikan, lalu layar ini DIAM DI LANGKAH KAMERA sampai semuanya
      // habis dibacakan. Dari sisi pengguna, tombol yang barusan dia tekan
      // tidak melakukan apa-apa.
      //
      // Yang menentukan posisi pengguna adalah izin yang sudah diberikan,
      // bukan panjang kalimat yang sedang dibacakan.
      unawaited(TTSService.instance.speak('Izin diberikan.', interrupt: true));
      _advance();
    } else if (status.isPermanentlyDenied) {
      setState(() => _permanentlyDenied = true);
      // IZ-04 - empat langkah bernomor, dibacakan satu per satu, bertahap.
      // Memotong: instruksi pemulihan tidak boleh mengantre di belakang
      // narasi panduan yang sudah tidak relevan.
      unawaited(TTSService.instance.speak(
        'Izin ditolak permanen. Empat langkah untuk menyalakannya kembali. '
        'Langkah satu: buka Pengaturan ponsel.',
        interrupt: true,
      ));
    } else {
      unawaited(TTSService.instance
          .speak('Izin belum diberikan. Coba lagi kapan saja.', interrupt: true));
    }
  }

  Future<void> _advance() async {
    if (_step != _Step.camera) {
      widget.onDone();
      return;
    }
    // Mikrofon bisa saja sudah diizinkan di pemasangan sebelumnya - jangan
    // menanyakan ulang sesuatu yang jawabannya sudah ada.
    if (await Permission.microphone.isGranted) {
      widget.onDone();
      return;
    }
    if (!mounted) return;
    setState(() {
      _step = _Step.microphone;
      _permanentlyDenied = false;
    });
    _announceStep();
  }

  /// Mikrofon BOLEH dilewati, kamera tidak.
  ///
  /// Kartu langkah mikrofon sudah menjanjikan "fitur lain tetap berjalan
  /// penuh tanpa mikrofon", tapi sebelumnya tidak ada satu pun tombol yang
  /// menepati janji itu: menolak sekali (bukan permanen) meninggalkan
  /// pengguna di layar dengan satu tombol "Izinkan mikrofon" dan tidak ada
  /// jalan maju. Untuk pengguna tunanetra itu jalan buntu total.
  ///
  /// ── SEDANG TIDAK DIPASANG DI UI (permintaan eksplisit) ──────────────────
  ///
  /// Kedua tombol yang memanggilnya di [build] sudah dikomentari, jadi fungsi
  /// ini utuh tapi tidak punya pemanggil. Yang perlu diketahui sebelum
  /// keadaan ini dibiarkan lama:
  ///
  /// `PermissionsScreen` adalah SATU-SATUNYA gerbang menuju aplikasi -
  /// `MainScreen` menahan `_BootStage.permissions` sampai `onDone` dipanggil,
  /// dan layar ini tidak punya tombol kembali. Tanpa tombol lewat, pengguna
  /// yang menolak izin mikrofon SEKALI saja (penolakan biasa, bukan permanen)
  /// tinggal di layar ini dengan satu tombol "Izinkan mikrofon" dan tidak ada
  /// jalan maju sama sekali. Menolak cuma satu ketukan jauhnya, dan pengguna
  /// tunanetra tidak punya layar untuk menemukan jalan keluarnya sendiri.
  ///
  /// Kalau nanti tombolnya perlu dihidupkan lagi, ada dua tempat di [build]
  /// yang tinggal ditukar kembali ke baris yang sudah tertulis di sana.
  // ignore: unused_element
  Future<void> _skipMicrophone() async {
    unawaited(TTSService.instance.speak(
      'Melanjutkan tanpa mikrofon. Perintah suara mati, mode tetap bisa '
      'dipilih lewat tombol Pilih mode.',
      interrupt: true,
    ));
    widget.onDone();
  }

  /// IZ-04 - dibacakan bertahap. Membacakan empat langkah sekaligus tidak
  /// mungkin diikuti.
  ///
  /// Pengaturan dibuka SEKARANG, tanpa menunggu kalimatnya habis. Mesin TTS
  /// terus berbicara di atas aplikasi Pengaturan, jadi tidak ada yang hilang -
  /// yang hilang kalau ditunggu justru sambungan sebab-akibatnya: pengguna
  /// menekan tombol, lalu enam detik tidak terjadi apa-apa, dan satu-satunya
  /// kesimpulan yang tersedia baginya adalah tombolnya tidak berfungsi.
  Future<void> _openSystemSettings(bool isCamera) async {
    unawaited(TTSService.instance.speak(
      'Langkah dua: cari menu Izin aplikasi. '
      'Langkah tiga: aktifkan izin ${isCamera ? 'Kamera' : 'Mikrofon'}. '
      'Langkah empat: kembali ke Vinara.',
      interrupt: true,
    ));
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SizedBox.expand(),
      );
    }
    final isCamera = _step == _Step.camera;

    // IZ-01..IZ-04 - layar penunjang tanpa BottomActionBar, jadi seluruh
    // aksinya memakai `zone/page-action`: primer di dasar layar, sekunder 56 dp
    // tepat di atasnya. Kartu tetap di zona konten; perannya memberi tahu.
    if (_permanentlyDenied) {
      return PageActionScaffold(
        primaryLabel: 'Buka Pengaturan ponsel',
        primaryIcon: Icons.settings_outlined,
        onPrimary: () => _openSystemSettings(isCamera),
        // TOMBOL "Lanjut tanpa mikrofon" DISEMBUNYIKAN - lihat catatan di
        // atas [_skipMicrophone] sebelum membiarkannya begini.
        secondaryLabel: isCamera ? 'Ulangi langkah ini' : null,
        onSecondary: isCamera
            ? () => TTSService.instance.speak('Mengulangi langkah ini.')
            : null,
        // Versi yang menampilkannya:
        // secondaryLabel: isCamera ? 'Ulangi langkah ini' : 'Lanjut tanpa mikrofon',
        // onSecondary: isCamera
        //     ? () => TTSService.instance.speak('Mengulangi langkah ini.')
        //     : _skipMicrophone,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
              child: _PermanentlyDeniedCard(label: isCamera ? 'kamera' : 'mikrofon'),
            ),
          ),
        ),
      );
    }

    return PageActionScaffold(
      primaryLabel: _requesting ? 'Meminta izin…' : 'Izinkan ${isCamera ? 'kamera' : 'mikrofon'}',
      primaryDisabled: _requesting,
      primaryDisabledReason: _requesting ? 'Menunggu jawabanmu' : null,
      onPrimary: _request,
      // TOMBOL "Lanjut tanpa mikrofon" DISEMBUNYIKAN - lihat catatan di atas
      // [_skipMicrophone] sebelum membiarkannya begini.
      secondaryLabel: null,
      onSecondary: null,
      // Versi yang menampilkannya:
      // secondaryLabel: isCamera ? null : 'Lanjut tanpa mikrofon',
      // onSecondary: isCamera ? null : _skipMicrophone,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
            child: PermissionCard(
              icon: isCamera ? Icons.camera_alt_outlined : Icons.mic_none_rounded,
              title: isCamera ? 'Izin kamera' : 'Izin mikrofon',
              reason: isCamera
                  ? 'Kamera dipakai untuk mendeteksi rintangan, membaca teks, mengenali uang, dan mencari barang.'
                  : 'Mikrofon dipakai untuk perintah suara dan Deskripsi Suasana. Fitur lain tetap berjalan penuh tanpa mikrofon.',
            ),
          ),
        ),
      ),
    );
  }
}

/// IZ-04 - kartu penjelasan saja. Kedua tombolnya ("Buka Pengaturan ponsel",
/// "Ulangi langkah ini") dipasang pemanggil di `zone/page-action`.
class _PermanentlyDeniedCard extends StatelessWidget {
  final String label;

  const _PermanentlyDeniedCard({required this.label});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Buka Pengaturan ponsel',
      'Cari menu Izin aplikasi',
      'Aktifkan izin yang dibutuhkan',
      'Kembali ke Vinara',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, size: 34, color: AppColors.criticalLabel),
          const SizedBox(height: AppSpacing.s4),
          Text('Izin $label ditolak permanen', textAlign: TextAlign.center, style: AppTypography.title()),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Nyalakan lagi lewat Pengaturan ponsel, empat langkah:',
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.ink2),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}', style: AppTypography.caption(color: AppColors.actionLabel)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(child: Text(steps[i], style: AppTypography.body())),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
