import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../core/speech/tts_queue.dart';
import '../providers/index.dart';
import '../services/haptic_service.dart';
import '../theme/index.dart';
import 'hold_to_talk.dart';
import 'mode_picker_sheet.dart';

/// BottomActionBar (F3) - selalu ada, selalu di tempat yang sama, tidak
/// pernah menggulung. Tiga slot: Aksi Utama 48, Bicara 64, Pilih Mode 48.
/// Saat mic aktif, dua tombol lain nonaktif - supaya tidak ada aksi
/// tabrakan sambil berjalan.
///
/// ## Kontrak tombol tengah: tekan-tahan, seperti walkie-talkie
///
/// **Tahan = mendengarkan. Lepas = jalankan.** Tidak ada layar yang berganti,
/// tidak ada popup, tidak ada konfirmasi.
///
/// **Artinya SAMA PERSIS di keenam mode: perintah suara.** Tidak ada mode yang
/// boleh membajaknya untuk keperluan sendiri. Mode Cari Objek dulu memakainya
/// untuk menampung nama barang, dan akibatnya satu-satunya cara berpindah mode
/// lewat suara justru hilang di mode yang paling mungkin membuat pengguna
/// ingin pindah. Kebutuhan khusus mode punya tempatnya sendiri sekarang:
/// `HoldToTalkButton`, selebar layar, tepat di atas bar ini.
///
/// Ini bukan soal kerapian. Pengguna yang tidak melihat layar tidak bisa
/// memeriksa tombol mana yang sedang berarti apa; yang dia punya cuma posisi
/// dan hafalan. Satu tombol yang berubah arti di satu mode merusak hafalan itu
/// untuk keenam-enamnya.
///
/// Sebelumnya tombol ini mendorong `VoiceScreen` sebagai overlay layar penuh
/// lebih dulu, lalu baru mulai mendengarkan setelah overlay itu ditutup. Untuk
/// satu perintah dua kata seperti "kenali uang", itu berarti satu transisi
/// layar, satu layar penuh yang menutupi mode yang sedang dipakai, dan satu
/// pengumuman TalkBack tentang layar baru - semuanya sebelum mikrofon menyala.
///
/// Yang membuat pola ini bisa dipercaya justru batasnya, bukan kecepatannya:
/// selama jari menempel, mikrofon menyala; begitu diangkat, mati. Pengguna
/// tidak pernah perlu menebak apakah aplikasi masih merekam - jarinya sendiri
/// yang menjawab.
///
/// | Peristiwa                    | Yang terjadi                            |
/// |------------------------------|-----------------------------------------|
/// | Tahan >= 500 ms              | Getar, mikrofon menyala, TTS dipotong, **mode dibungkam** |
/// | Bicara sambil menahan        | Teks parsial muncul di atas tombol      |
/// | Lepas                        | Getar, mikrofon mati, perintah dijalankan |
/// | Lepas < 500 ms               | Tidak merekam; "Tahan tombolnya, lalu bicara." |
/// | Menahan lewat 10 detik       | Audio dibuang; "Waktu habis, silakan coba lagi." |
///
/// ### Mode yang sedang berjalan ikut dibungkam
///
/// Menahan tombol ini menutup gerbang suara di `TtsQueue`: narasi rintangan,
/// arahan jalur, dan petunjuk mode berhenti sampai jawaban asisten selesai.
/// Dua alasan, dan keduanya menentukan apakah perintahnya sampai:
///
/// 1. Suara aplikasi masuk ke mikrofonnya sendiri, dan mesin pengenal
///    menerima dua suara sekaligus.
/// 2. Orang tidak bisa menyusun kalimat sambil mendengarkan kalimat lain.
///
/// **Peringatan bahaya tetap menembus.** Lubang di depan kaki tidak menunggu
/// sampai pengguna selesai bicara. Rinciannya di `TtsQueue.beginVoiceSession`.
///
/// ### Kenapa TalkBack dapat jalur sendiri
///
/// Tekan-tahan satu jari adalah gestur yang sudah dimiliki screen reader:
/// dengan TalkBack aktif, sentuhan pertama memindahkan fokus dan tidak pernah
/// sampai ke widget sebagai `onLongPressStart`. Jadi saat
/// `MediaQuery.accessibleNavigation` menyala, tombol ini kembali menjadi
/// saklar: ketuk untuk mulai, ketuk lagi untuk berhenti - memakai sesi tap
/// sekali `VoiceProvider` yang menutup dirinya sendiri setelah 3 detik hening,
/// sehingga pengguna tidak wajib mengetuk kedua kali.
///
/// ## Kontrak tombol kiri
///
/// **Tombol kiri = lakukan hal utama mode ini, sekarang. Kalau mode itu tidak
/// punya "hal utama", ia mengulang hal penting terakhir yang diucapkan.**
///
/// Bagian kedua yang membuat aturannya utuh: dengan itu tidak ada satu pun
/// mode dengan tombol kiri mati, dan pengguna punya jaring pengaman - kalau
/// lupa tombol kiri melakukan apa di mode ini, paling buruk ia mengulang
/// sesuatu. Tidak pernah merusak, tidak pernah hening.
///
/// | Mode          | Label                        | Aksi                     |
/// |---------------|------------------------------|--------------------------|
/// | Deteksi Objek | "Hentikan" / "Lanjutkan"     | Toggle deteksi           |
/// | Kenali Uang   | "Kenali Uang"                | 1 tap = 1 analisis       |
/// | Baca Teks     | "Baca teks" → "Jeda bacaan"  | Kontekstual              |
/// | Navigasi      | "Matikan Suara" / "Nyalakan" | Bisu/nyala suara panduan |
/// | Deskripsi Suasana | "Deskripsikan"           | Kirim foto ke VLM server |
/// | Cari Objek    | "Kirim - cari [X]"           | Scan                     |
///
/// Aturan pendukung: label berupa kata kerja + objek maksimal 3 kata (TalkBack
/// membacanya tiap fokus mendarat), tombol nonaktif tetap bersuara saat
/// ditekan, dan setiap tekan memberi getar konfirmasi.
///
/// [cameraLabel] sengaja **wajib**. Nilai bawaan lamanya "Ambil gambar" membuat
/// dua mode (Navigasi dan Deskripsi Suasana) menampilkan tombol aktif yang dibacakan
/// TalkBack sebagai "Ambil gambar, tombol" padahal menekannya tidak melakukan
/// apa pun - label yang berbohong, dan jalan buntu yang hening.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final bool cameraEnabled;
  final String cameraLabel;

  /// Ikon tombol kiri. Bawaannya kamera, karena di sebagian besar mode aksi
  /// utamanya memang memotret atau menyalakan pengawasan.
  ///
  /// Mode Deskripsi Suasana memakai ikon cari-gambar: aksinya memang
  /// memotret, tapi hasilnya deskripsi, bukan foto yang disimpan. Ikon yang keliru di
  /// posisi tetap justru lebih membingungkan daripada tidak ada ikon.
  final IconData cameraIcon;

  /// Alasan tombol kiri nonaktif, diucapkan saat ditekan.
  final String? cameraDisabledReason;

  /// DO-24 - izin mikrofon dicabut: nonaktifkan tombol Bicara sepenuhnya.
  final bool micEnabled;

  // Penimpa mik per-mode (`onMicHoldStart`, `onMicHoldEnd`,
  // `liveTranscriptOverride`, `listeningOverride`, `processingOverride`)
  // SUDAH DIHAPUS. Lihat catatan kontrak tombol tengah di atas.
  //
  // Satu-satunya pemakainya adalah Mode Cari Objek, yang membajak tombol ini
  // untuk menampung nama barang. Akibatnya satu-satunya cara berpindah mode
  // lewat suara justru hilang di mode yang paling mungkin membuat pengguna
  // ingin pindah - saat barangnya tidak ketemu juga, sementara tangannya
  // penuh dan matanya tidak bisa mencari tombol Pilih mode.
  //
  // Nama barang sekarang punya tombolnya sendiri, `HoldToTalkButton`, yang
  // duduk di atas bar ini.

  const BottomActionBar({
    super.key,
    required this.cameraLabel,
    this.cameraIcon = Icons.camera_alt_outlined,
    this.onCameraPressed,
    this.cameraEnabled = true,
    this.cameraDisabledReason,
    this.micEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final listening = voice.isListening;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sideButtonsEnabled = cameraEnabled && !listening;

    // Bar-nya tetap setinggi semula; pill tumbuh KE ATAS di luar tinggi itu.
    // Semua layar menaruh bar ini di `Positioned(bottom: 0)` tanpa tinggi
    // tetap, jadi Column yang membungkusnya memanjang ke atas dan tidak satu
    // piksel pun dari ketiga tombol bergeser saat pill muncul - posisi tombol
    // adalah satu-satunya peta yang dihafal pengguna.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LiveTranscriptPill(text: voice.lastText, visible: listening),
        _bar(context, bottomInset, sideButtonsEnabled, listening),
      ],
    );
  }

  Widget _bar(
    BuildContext context,
    double bottomInset,
    bool sideButtonsEnabled,
    bool listening,
  ) {
    return Container(
      height: AppSizes.bottomActionBarHeight + bottomInset,
      padding: EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s3, AppSpacing.s8, bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgPage,
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .06), blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(color: Color.fromRGBO(22, 24, 25, .18), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -12),
        ],
      ),
      // Urutan fokus 7-8-9 (bagian 10) dipasang eksplisit: reposisi tombol di
      // layar lain tidak boleh menggeser urutan tiga tombol ini, karena
      // kekekalannya adalah satu-satunya peta yang dimiliki pengguna.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            sortKey: const OrdinalSortKey(7),
            child: _SquareButton(
              icon: cameraIcon,
              label: cameraLabel,
              // Tanpa handler = tidak aktif. Tidak ada lagi `?? () {}` yang
              // membuat tombol tampak hidup lalu diam saat ditekan.
              enabled: sideButtonsEnabled && onCameraPressed != null,
              disabledReason: listening
                  ? 'sedang mendengarkan'
                  : cameraDisabledReason,
              onTap: onCameraPressed ?? () {},
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(8),
            child: _MicButton(enabled: micEnabled),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(9),
            child: _SquareButton(
              icon: Icons.apps_rounded,
              label: 'Pilih mode',
              enabled: !listening,
              onTap: () => showModePickerSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol Bicara - tekan-tahan.
///
/// Stateful karena denyut cincinnya butuh ticker, dan karena tombol ini harus
/// mengingat satu hal yang tidak ada di provider mana pun: apakah sesi yang
/// sekarang berjalan dimulai oleh JARI INI. Tanpa ingatan itu, pelepasan jari
/// setelah sesi ditutup batas waktu akan menutup sesi yang sudah tidak ada.
class _MicButton extends StatefulWidget {
  final bool enabled;

  const _MicButton({this.enabled = true});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse(bool listening) {
    if (listening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  // Gestur tekan-tahan tidak lagi ditulis di sini. Ia pindah ke
  // `HoldToTalkGesture`, dan dibagi dengan `HoldToTalkButton` di atas bar.
  // Menyalin logikanya ke dua tempat berarti dua tombol yang sama-sama
  // berarti "bicara" bisa menyimpang dalam satu detail tanpa ada yang
  // menyadarinya - dan yang runtuh bukan salah satunya, melainkan
  // kepercayaan pengguna pada keduanya.

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Semantics(
        button: true,
        label: 'Bicara, tidak tersedia, izin mikrofon belum diberikan',
        child: Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceSunk),
          child: const ExcludeSemantics(
            child: Icon(Icons.mic_off_rounded, color: AppColors.disabledInk, size: 28),
          ),
        ),
      );
    }

    final voice = context.watch<VoiceProvider>();
    final listening = voice.isListening;
    final processing = voice.isProcessing;
    final screenReader = MediaQuery.of(context).accessibleNavigation;
    _syncPulse(listening);

    // Label TalkBack menyebut cara memicunya, karena caranya berbeda dari
    // tombol lain di bar ini dan tidak ada isyarat visual yang menjelaskannya.
    final semanticLabel = processing
        ? 'Bicara, sedang memproses'
        : listening
            ? screenReader
                ? 'Berhenti mendengarkan'
                : 'Sedang mendengarkan, lepaskan untuk mengirim'
            : screenReader
                ? 'Bicara, ketuk untuk mulai mendengarkan'
                : 'Bicara, tahan lalu ucapkan perintah';

    return HoldToTalkGesture(
      listening: listening,
      processing: processing,
      semanticLabel: semanticLabel,
      onHoldStart: () => context.read<VoiceProvider>().startHoldToTalk(),
      onHoldEnd: () => context.read<VoiceProvider>().finishHoldToTalk(),
      onTooShort: () => context.read<VoiceProvider>().explainHoldRequired(),
      // Jalur TalkBack memakai sesi tap sekali, bukan sesi tahan: ia menutup
      // dirinya sendiri setelah 3 detik hening, jadi pengguna tidak WAJIB
      // mengetuk kedua kali untuk mematikan mikrofon.
      onScreenReaderStart: () => context.read<VoiceProvider>().startListening(),
      onScreenReaderStop: () => context.read<VoiceProvider>().stopListening(),
      child: _circle(listening: listening, processing: processing),
    );
  }

  Widget _circle({required bool listening, required bool processing}) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        // Cincin denyut: 8 -> 14 px. Tetap di dalam jarak antar tombol supaya
        // tidak pernah menutupi dua tombol di sisinya.
        final spread = 8 + (_pulse.value * 6);
        return Container(
          width: AppSizes.micButton,
          height: AppSizes.micButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: processing
                ? AppColors.actionTint
                : listening
                    // Merah saat merekam - sama dengan titik rekam di
                    // _EngineCard dan indikator rekaman di mana pun.
                    ? AppColors.criticalFill
                    : AppColors.actionFill,
            boxShadow: listening
                ? [
                    BoxShadow(color: AppColors.criticalFill.withValues(alpha: .20), blurRadius: 0, spreadRadius: spread),
                    BoxShadow(color: AppColors.criticalFill.withValues(alpha: .10), blurRadius: 0, spreadRadius: spread * 2),
                  ]
                : [
                    BoxShadow(color: AppColors.actionFill.withValues(alpha: .36), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.actionLabel),
                )
              : ExcludeSemantics(
                  child: Icon(listening ? Icons.mic : Icons.mic_none_rounded, color: AppColors.onDark, size: 30),
                ),
        );
      },
    );
  }
}

/// Pill teks yang sedang didengar, duduk di atas tombol Bicara.
///
/// `ExcludeSemantics` dipasang dengan sengaja. Teks parsial berubah beberapa
/// kali per detik, dan setiap perubahan pada node semantik yang hidup akan
/// memotong ucapan TalkBack yang sedang berjalan - termasuk jawaban Vinara
/// sendiri. Pengguna yang tidak melihat layar sudah mendapat isi perintahnya
/// lewat jawaban lisan; yang ini murni untuk mata.
class _LiveTranscriptPill extends StatelessWidget {
  final String text;
  final bool visible;

  const _LiveTranscriptPill({required this.text, required this.visible});

  @override
  Widget build(BuildContext context) {
    final shown = text.trim();
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: !visible
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: const ValueKey('pill'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s2,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: AppSpacing.s2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.pillBg,
                    borderRadius: AppRadius.pillShape,
                  ),
                  child: Text(
                    shown.isEmpty ? 'Mendengarkan…' : '$shown…',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(color: AppColors.onDark),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  /// Alasan tombol nonaktif - diucapkan saat ditekan, bukan didiamkan.
  final String? disabledReason;

  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.disabledReason,
  });

  /// Menekan tombol nonaktif TIDAK boleh hening.
  ///
  /// Untuk pengguna yang tidak melihat layar, tombol yang diam saat ditekan
  /// tidak bisa dibedakan dari aplikasi yang macet - dan satu-satunya cara
  /// menguji dugaannya adalah menekan lagi. Katakan alasannya, sekali, dengan
  /// getar pendek supaya jelas tekanannya terdaftar.
  void _explainDisabled() {
    final reason = disabledReason;
    TtsQueue().speak(
      reason == null ? '$label tidak tersedia sekarang.' : '$label. $reason',
      tier: SpeechTier.info,
    );
    HapticService.instance.info();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? label
          : disabledReason == null
              ? '$label, tidak tersedia'
              : '$label, tidak tersedia, $disabledReason',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : _explainDisabled,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 26,
                color: enabled ? AppColors.ink1 : AppColors.disabledInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
