import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Penanda tunggal "sedang mengawasi atau tidak" untuk Mode Deteksi Objek.
///
/// ## Kenapa ini ada
///
/// Sebelum widget ini, satu-satunya beda antara deteksi menyala dan mati
/// adalah label tombol kiri - dan label itu tidak pernah digambar, hanya
/// dibacakan TalkBack. Untuk mata, kedua keadaan identik: ikon yang sama,
/// warna yang sama, preview kamera yang sama. Kotak deteksi memang cuma
/// muncul saat aktif, tapi kotak juga tidak muncul saat aktif dan kebetulan
/// tidak ada objek di depan kamera, jadi ia tidak bisa dipakai sebagai bukti.
///
/// Yang paling menyesatkan justru keadaan ketiga itu: **aktif tapi belum
/// melihat apa-apa**. Tanpa penanda, ia tidak bisa dibedakan dari mati, dan
/// pendamping awas yang memeriksa layar akan menyimpulkan tombolnya tidak
/// bekerja lalu menekannya lagi - mematikan pengawasan yang sebenarnya
/// sedang berjalan.
///
/// Karena itu pill ini tidak berhenti pada "aktif/mati". Saat aktif ia
/// menampilkan usia inferensi terakhir, sebuah angka yang bergerak: bukti
/// bahwa pipeline benar-benar berjalan, bukan janji bahwa ia berjalan.
///
/// ## Untuk siapa
///
/// Untuk mata - pendamping awas, penguji, juri. Pengguna tunanetra sudah
/// mendapat kabar yang sama lewat TTS dan pengingat berkala di
/// `TuntunScreen`. Karena itu angka yang berubah dua kali per detik
/// **dikecualikan dari semantik**: node semantik yang hidup memotong ucapan
/// TalkBack yang sedang berjalan, termasuk peringatan rintangan itu sendiri.
/// Yang dibacakan hanya kalimat keadaan yang stabil.
class DetectionStatusPill extends StatefulWidget {
  /// Deteksi rintangan sedang berjalan.
  final bool active;

  /// Jumlah objek di frame terakhir - ditampilkan sebagai ganti usia
  /// inferensi saat ada isinya, karena angka ini lebih berguna.
  final int objectCount;

  /// Kapan pipeline terakhir menghasilkan sesuatu. Sumbernya
  /// `DetectionProvider.lastInferenceAt`.
  final DateTime? lastInferenceAt;

  /// Model gagal dimuat - mode ini tidak punya cadangan apa pun.
  final bool unavailable;

  const DetectionStatusPill({
    super.key,
    required this.active,
    this.objectCount = 0,
    this.lastInferenceAt,
    this.unavailable = false,
  });

  @override
  State<DetectionStatusPill> createState() => _DetectionStatusPillState();
}

class _DetectionStatusPillState extends State<DetectionStatusPill>
    with SingleTickerProviderStateMixin {
  /// Denyut titik. Titik diam masih bisa dikira hiasan; yang bergerak
  /// terbaca sebagai "ada yang sedang jalan".
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Penyegar teks usia inferensi. Terpisah dari [_pulse] supaya teksnya
  /// tidak ikut dibangun ulang 60 kali per detik.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DetectionStatusPill old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.unavailable != widget.unavailable) {
      _sync();
    }
  }

  void _sync() {
    final hidup = widget.active && !widget.unavailable;
    if (hidup) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      _ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _pulse.stop();
      _pulse.value = 0;
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// Usia inferensi terakhir. `null` kalau belum ada satu pun.
  Duration? get _usia {
    final t = widget.lastInferenceAt;
    return t == null ? null : DateTime.now().difference(t);
  }

  /// Pipeline hidup tapi belum menghasilkan apa pun yang segar. Ambangnya
  /// sama dengan yang dipakai `_repeatLastDetection` di TuntunScreen, supaya
  /// yang terlihat di layar dan yang terdengar lewat "ulangi" tidak pernah
  /// bertentangan.
  bool get _basi {
    final u = _usia;
    return u == null || u > const Duration(seconds: 3);
  }

  @override
  Widget build(BuildContext context) {
    final (warna, judul, rincian, semantik) = _tampilan();

    return Semantics(
      // Label keadaan saja, tanpa angka: node yang berubah dua kali per
      // detik akan memotong ucapan TalkBack yang sedang berjalan.
      label: semantik,
      child: ExcludeSemantics(
        child: Container(
          height: AppSizes.modeBadgeHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: AppColors.pillBg,
            borderRadius: AppRadius.pillShape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _titik(warna),
              const SizedBox(width: 10),
              Text(judul, style: AppTypography.label(color: AppColors.onDark)),
              if (rincian != null) ...[
                const SizedBox(width: 8),
                Text(
                  rincian,
                  style: AppTypography.metricMono(
                    color: AppColors.onDark.withValues(alpha: .72),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Titik keadaan. Saat aktif ia berdenyut lewat cincin di sekelilingnya,
  /// bukan lewat perubahan ukuran titiknya sendiri - titik yang membesar
  /// mengecil menggeser teks di sebelahnya.
  Widget _titik(Color warna) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final berdenyut = _pulse.isAnimating;
        final spread = berdenyut ? 2 + (_pulse.value * 4) : 0.0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: warna,
            boxShadow: spread == 0
                ? null
                : [
                    BoxShadow(
                      color: warna.withValues(alpha: .35),
                      blurRadius: 0,
                      spreadRadius: spread,
                    ),
                  ],
          ),
        );
      },
    );
  }

  /// (warna titik, judul, rincian, label semantik)
  (Color, String, String?, String) _tampilan() {
    if (widget.unavailable) {
      return (
        AppColors.criticalFill,
        'Deteksi tidak tersedia',
        null,
        'Deteksi rintangan tidak tersedia di perangkat ini',
      );
    }

    if (!widget.active) {
      return (
        AppColors.onDark.withValues(alpha: .38),
        'Deteksi mati',
        'tekan tombol kiri',
        'Deteksi rintangan mati. Tekan tombol kiri bawah untuk mulai mengawasi',
      );
    }

    if (_basi) {
      // Aktif, tapi belum ada hasil yang segar. Ini keadaan nyata beberapa
      // ratus milidetik pertama sesudah tombol ditekan, dan juga keadaan
      // saat pipeline macet - keduanya tidak boleh terlihat seperti berhasil.
      return (
        AppColors.warningFill,
        'Menyiapkan…',
        null,
        'Deteksi rintangan menyala, sedang menyiapkan kamera',
      );
    }

    if (widget.objectCount > 0) {
      return (
        AppColors.positiveFill,
        'Mengawasi',
        '${widget.objectCount} objek',
        'Deteksi rintangan menyala, ${widget.objectCount} objek terlihat',
      );
    }

    final ms = _usia!.inMilliseconds;
    final detik = (ms / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return (
      AppColors.positiveFill,
      'Mengawasi',
      '$detik dtk lalu',
      'Deteksi rintangan menyala, belum ada rintangan yang terlihat',
    );
  }
}
