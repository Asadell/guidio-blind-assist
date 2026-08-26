import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Kepala lembar bawah: pegangan, judul, keterangan, dan **tombol tutup**.
///
/// ## Kenapa tombol tutupnya wajib, bukan hiasan
///
/// Lembar bawah Flutter bisa ditutup dengan dua gestur bawaan: menyeret ke
/// bawah, dan mengetuk area gelap di luar lembar. Keduanya tidak terlihat, dan
/// keduanya bisa dimatikan (`enableDrag`, `isDismissible`) tanpa meninggalkan
/// jejak apa pun di layar.
///
/// Untuk aplikasi ini keduanya juga tidak bisa diandalkan:
///
/// - Dengan TalkBack menyala, seret satu jari sudah punya arti lain - ia
///   memindahkan fokus baca, bukan menutup lembar. Ketukan di luar lembar juga
///   tidak pernah sampai sebagai "tutup"; yang terjadi hanyalah fokus pindah ke
///   sesuatu di belakang tirai.
/// - Pengguna yang tidak melihat layar tidak punya cara menemukan tepi lembar
///   untuk diseret. Yang bisa dia temukan adalah simpul yang dibacakan berisi
///   kata "Tutup".
///
/// Jadi setiap lembar di aplikasi ini punya jalan keluar yang **terlihat,
/// terbaca, dan bisa ditekan**, bukan yang harus ditebak.
class SheetHeader extends StatelessWidget {
  final String title;

  /// Baris keterangan di bawah judul. Boleh kosong.
  final String? subtitle;

  /// Dibacakan TalkBack sebagai label tombol tutup, mis. "Tutup panel debug".
  /// Sengaja menyebut APA yang ditutup: satu kata "Tutup" tidak berarti apa-apa
  /// bagi orang yang tidak melihat lembar mana yang sedang terbuka.
  final String closeLabel;

  /// Bawaannya `Navigator.pop`. Diisi hanya kalau menutup lembar ini perlu
  /// melakukan sesuatu yang lain lebih dulu.
  final VoidCallback? onClose;

  const SheetHeader({
    super.key,
    required this.title,
    required this.closeLabel,
    this.subtitle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pegangan seret murni isyarat visual - ia sudah diwakili tombol tutup
        // bagi pengguna TalkBack, dan membacakannya cuma menambah satu simpul
        // tanpa arti di antrean.
        ExcludeSemantics(
          child: Center(
            child: Container(
              width: 34,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AppTypography.title()),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            SheetCloseButton(label: closeLabel, onClose: onClose),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTypography.caption()),
        ],
      ],
    );
  }
}

/// Tombol silang penutup lembar - 48 dp penuh, bukan ikon 20 dp yang kebetulan
/// bisa ditekan.
///
/// Dipisah dari [SheetHeader] supaya lembar yang kepalanya sudah punya bentuk
/// sendiri tetap bisa memakai tombol yang sama persis.
class SheetCloseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onClose;

  const SheetCloseButton({super.key, required this.label, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surfaceSunk,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onClose ?? () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            child: ExcludeSemantics(
              child: Icon(Icons.close_rounded, size: 24, color: AppColors.ink1),
            ),
          ),
        ),
      ),
    );
  }
}
