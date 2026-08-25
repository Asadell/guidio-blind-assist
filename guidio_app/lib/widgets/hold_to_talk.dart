import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Gestur tekan-tahan untuk semua tombol bicara di aplikasi ini.
///
/// Dipakai dua tempat: tombol Bicara di tengah `BottomActionBar`, dan
/// [HoldToTalkButton] yang duduk di atas bar. Keduanya WAJIB berbagi kelas
/// ini, bukan menyalin logikanya.
///
/// Alasannya bukan kerapian. Pengguna yang tidak melihat layar menghafal satu
/// hal tentang tombol bicara: **tahan, ucapkan, lepas.** Kalau dua tombol
/// yang sama-sama berarti "bicara" berbeda dalam satu detail saja - ambang
/// tahannya, apa yang terjadi saat jari bergeser keluar, apa yang terdengar
/// saat ditekan terlalu singkat - yang runtuh bukan salah satu tombol,
/// melainkan kepercayaan pada keduanya.
///
/// | Peristiwa | Yang terjadi |
/// |---|---|
/// | Tahan >= 500 ms | [onHoldStart] |
/// | Lepas | [onHoldEnd] |
/// | Gestur direbut widget lain | [onHoldEnd] |
/// | Lepas < 500 ms | [onTooShort] - tidak merekam, tapi tidak diam |
/// | Jari bergeser keluar tombol | **tidak terjadi apa-apa**, rekaman jalan terus |
///
/// Rendering diserahkan sepenuhnya ke [child]: kelas ini hanya mengurus
/// gestur, semantik, dan ingatan siapa yang memulai sesi.
class HoldToTalkGesture extends StatefulWidget {
  /// Jari menempel melewati ambang tahan.
  final Future<void> Function() onHoldStart;

  /// Jari diangkat, atau gestur direbut widget lain.
  final Future<void> Function() onHoldEnd;

  /// Ditahan terlalu singkat untuk dianggap tekan-tahan.
  ///
  /// Wajib bersuara. Tombol yang ditekan lalu hening tidak bisa dibedakan
  /// dari aplikasi yang macet oleh pengguna yang tidak melihat layar, dan
  /// satu-satunya cara mengujinya adalah menekan lagi.
  final VoidCallback onTooShort;

  /// Jalur cadangan TalkBack, yang memakai **ketuk**, bukan tahan.
  ///
  /// Kalau null, [onHoldStart]/[onHoldEnd] yang dipakai. Isi keduanya hanya
  /// kalau sesi ketuk memang berbeda dari sesi tahan - misalnya sesi yang
  /// menutup dirinya sendiri setelah beberapa detik hening, sehingga
  /// pengguna tidak wajib mengetuk kedua kali.
  final Future<void> Function()? onScreenReaderStart;
  final Future<void> Function()? onScreenReaderStop;

  /// Sesi sedang berjalan, menurut sumber kebenaran milik pemanggil.
  final bool listening;

  /// Perintahnya sedang diproses - gestur dimatikan sementara.
  final bool processing;

  /// Label TalkBack, sudah jadi. Pemanggil yang menyusunnya karena hanya dia
  /// yang tahu tombol ini berarti apa di modenya.
  final String semanticLabel;

  final Widget child;

  const HoldToTalkGesture({
    super.key,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onTooShort,
    required this.semanticLabel,
    required this.child,
    this.onScreenReaderStart,
    this.onScreenReaderStop,
    this.listening = false,
    this.processing = false,
  });

  @override
  State<HoldToTalkGesture> createState() => _HoldToTalkGestureState();
}

class _HoldToTalkGestureState extends State<HoldToTalkGesture> {
  /// Sesi yang sedang berjalan dimulai oleh tekanan jari yang belum diangkat.
  ///
  /// Tanpa ingatan ini, pelepasan jari sesudah sesi ditutup batas waktu akan
  /// menutup sesi yang sudah tidak ada - dan di jalur Cari Objek itu berarti
  /// satu "Cari apa?" yang tidak pernah diminta siapa pun.
  bool _holding = false;

  /// Ambang 500 ms tidak diukur di sini. `onLongPressStart` dipanggil
  /// framework tepat saat `kLongPressTimeout` terlewati, jadi menahan lebih
  /// singkat dari itu tidak akan pernah sampai ke fungsi ini - dan tidak ada
  /// timer kedua yang bisa berselisih dengan timer framework.
  Future<void> _start() async {
    if (_holding) return;
    setState(() => _holding = true);
    await widget.onHoldStart();
  }

  Future<void> _end() async {
    if (!_holding) return;
    setState(() => _holding = false);
    await widget.onHoldEnd();
  }

  Future<void> _toggleForScreenReader() async {
    if (widget.listening) {
      _holding = false;
      await (widget.onScreenReaderStop ?? widget.onHoldEnd)();
      return;
    }
    await (widget.onScreenReaderStart ?? widget.onHoldStart)();
  }

  @override
  Widget build(BuildContext context) {
    final screenReader = MediaQuery.of(context).accessibleNavigation;

    // Tekan-tahan satu jari adalah gestur yang sudah dimiliki screen reader:
    // dengan TalkBack aktif, sentuhan pertama memindahkan fokus dan tidak
    // pernah sampai ke widget sebagai `onLongPressStart`. Jadi tombol ini
    // kembali menjadi saklar.
    if (screenReader) {
      return Semantics(
        button: true,
        label: widget.semanticLabel,
        onTap: widget.processing ? null : _toggleForScreenReader,
        child: GestureDetector(
          onTap: widget.processing ? null : _toggleForScreenReader,
          child: widget.child,
        ),
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        // `onTap` di sini HANYA berarti "diangkat sebelum 500 ms". Begitu
        // ambangnya terlewat, framework beralih ke pengenal tekan-tahan dan
        // `onTap` tidak lagi dipanggil, jadi keduanya tidak pernah bertabrakan.
        onTap: widget.processing ? null : widget.onTooShort,
        onLongPressStart: widget.processing ? null : (_) => _start(),
        // Ketiganya menutup sesi. `onLongPressEnd` untuk jari yang diangkat,
        // `onLongPressCancel` untuk gestur yang direbut widget lain, dan
        // `onLongPressMoveUpdate` sengaja TIDAK dipakai: menggeser jari keluar
        // tombol sambil bicara adalah hal yang wajar bagi pengguna yang tidak
        // melihat layar, dan itu tidak boleh memotong rekamannya.
        onLongPressEnd: widget.processing ? null : (_) => _end(),
        onLongPressCancel: widget.processing ? null : _end,
        child: widget.child,
      ),
    );
  }
}

/// Tombol bicara selebar layar, duduk tepat di atas `BottomActionBar`.
///
/// Bentuknya sengaja disamakan dengan [FullScreenButton] yang dipakai layar
/// izin kamera dan mikrofon: tinggi 96 dp, satu blok penuh, tidak mungkin
/// meleset dijangkau satu tangan sambil memegang tongkat.
///
/// ## Kenapa tombol ini ada
///
/// Mode Cari Objek punya DUA hal yang sama-sama diucapkan, dan keduanya tidak
/// bisa berbagi satu tombol:
///
/// - **Nama barang** ("kunci motor", "dompet cokelat") - kosakata bebas,
///   dikenali mesin STT milik layar itu sendiri.
/// - **Perintah aplikasi** ("pindah ke navigasi") - salah satu frasa di
///   `CommandParser`, dikenali `VoiceProvider`.
///
/// Sebelum ini, tombol tengah di mode itu dibajak untuk nama barang, sehingga
/// satu-satunya cara berpindah mode lewat suara justru hilang persis di mode
/// yang paling mungkin membuat pengguna ingin pindah - saat barangnya tidak
/// ketemu juga.
///
/// Pembagiannya sekarang: **tombol tengah selalu berarti perintah suara, di
/// keenam mode.** Yang khusus modelah yang pindah ke tombol ini.
class HoldToTalkButton extends StatelessWidget {
  /// Label saat menganggur, mis. "Sebutkan barang".
  final String label;

  /// Label saat sedang mendengarkan. Kalau null, [label] tetap dipakai.
  final String? listeningLabel;

  final IconData icon;

  /// Teks parsial yang sedang ditangkap. Murni untuk mata - lihat catatan
  /// `ExcludeSemantics` di bawah.
  final String liveTranscript;

  final bool listening;
  final bool processing;

  /// Null berarti tombol mati. Alasannya WAJIB diisi di [disabledReason].
  final Future<void> Function()? onHoldStart;
  final Future<void> Function()? onHoldEnd;
  final String? disabledReason;

  /// Ditekan terlalu singkat.
  final VoidCallback onTooShort;

  const HoldToTalkButton({
    super.key,
    required this.label,
    required this.onTooShort,
    this.listeningLabel,
    this.icon = Icons.mic_none_rounded,
    this.liveTranscript = '',
    this.listening = false,
    this.processing = false,
    this.onHoldStart,
    this.onHoldEnd,
    this.disabledReason,
  })  : assert(
          (onHoldStart == null) == (onHoldEnd == null),
          'onHoldStart dan onHoldEnd harus dipasang berpasangan: sesi yang '
          'dibuka satu sisi hanya bisa ditutup sisi lainnya.',
        ),
        assert(
          onHoldStart != null || disabledReason != null,
          'disabledReason wajib diisi saat tombol dimatikan - tombol mati '
          'yang tidak bisa menyebutkan alasannya tidak bisa dibedakan dari '
          'aplikasi yang macet.',
        );

  bool get _enabled => onHoldStart != null && !processing;

  @override
  Widget build(BuildContext context) {
    final shownLabel = listening ? (listeningLabel ?? label) : label;

    final semanticLabel = !_enabled
        ? '$label, tidak tersedia, $disabledReason'
        : listening
            ? MediaQuery.of(context).accessibleNavigation
                ? '$label, ketuk untuk berhenti mendengarkan'
                : '$label, sedang mendengarkan, lepaskan untuk mengirim'
            : MediaQuery.of(context).accessibleNavigation
                ? '$label, ketuk untuk mulai bicara'
                : '$label, tahan lalu ucapkan';

    final body = _body(shownLabel);

    if (!_enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: semanticLabel,
        // Tombol mati tetap bisa diketuk, dan ketukannya tetap menjelaskan
        // alasannya. Tombol yang benar-benar tidak merespons apa pun adalah
        // jalan buntu yang hening.
        child: GestureDetector(onTap: onTooShort, child: body),
      );
    }

    return HoldToTalkGesture(
      onHoldStart: onHoldStart!,
      onHoldEnd: onHoldEnd!,
      onTooShort: onTooShort,
      listening: listening,
      processing: processing,
      semanticLabel: semanticLabel,
      child: body,
    );
  }

  Widget _body(String shownLabel) {
    final subtitle = !_enabled
        ? disabledReason
        : listening
            ? (liveTranscript.trim().isEmpty
                ? 'Ucapkan sekarang…'
                : '${liveTranscript.trim()}…')
            : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: AppSizes.fullScreenButtonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: !_enabled
            ? AppColors.surfaceSunk
            : listening
                // Merah saat merekam - sama dengan tombol Bicara di tengah
                // dan setiap indikator rekaman lain di aplikasi ini.
                ? AppColors.criticalFill
                : AppColors.actionLabel,
        borderRadius: AppRadius.card,
        boxShadow: _enabled
            ? [
                BoxShadow(
                  color: (listening ? AppColors.criticalFill : AppColors.actionLabel)
                      .withValues(alpha: .32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  listening ? Icons.mic : icon,
                  color: _enabled ? AppColors.onDark : AppColors.disabledInk,
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.s3),
                Flexible(
                  child: Text(
                    shownLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(
                      color: _enabled ? AppColors.onDark : AppColors.disabledInk,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              // `ExcludeSemantics` dipasang dengan sengaja untuk teks parsial:
              // isinya berubah beberapa kali per detik, dan setiap perubahan
              // pada node semantik yang hidup akan memotong ucapan TalkBack
              // yang sedang berjalan. Pengguna yang tidak melihat layar sudah
              // mendapat isi perintahnya lewat jawaban lisan.
              ExcludeSemantics(
                excluding: listening,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: _enabled ? AppColors.onDark : AppColors.disabledInk,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tinggi total yang dipesan tombol ini, dipakai layar untuk menggeser
  /// konten di atasnya. Sama polanya dengan `ContextualActionSlot.slotHeight`.
  static const double slotHeight =
      AppSizes.fullScreenButtonHeight + AppSpacing.s3;
}
