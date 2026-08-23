import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// PermissionCard (5.16) - kartu izin yang mengambil zona konten. ModeBadge
/// dan BottomActionBar tetap di tempatnya (dipasang oleh screen pemanggil).
/// Alasan ditulis per izin, bukan satu paragraf gabungan - bagian 5.16.
///
/// **Kartu ini tidak lagi memuat tombolnya.** Dulu tombol "Berikan izin" ikut
/// di dalam kartu, dan karena kartunya berada di zona konten, tombol berakhir
/// di tengah layar - zona kuning/merah thumb zone, di luar jangkauan ibu jari
/// satu tangan. Tombolnya sekarang dipasang [PermissionPrompt] di slot kartu
/// bawah. Lihat bagian 5 & 8 ALUR-DAN-TOMBOL.md.
class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: AppColors.actionLabel),
            const SizedBox(height: AppSpacing.s4),
            Semantics(
              header: true,
              headingLevel: 2,
              child: Text(title, textAlign: TextAlign.center, style: AppTypography.title()),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(reason, textAlign: TextAlign.center, style: AppTypography.body(color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Permintaan izin di **layar mode** - DO-14, BT-17, UG-14, AS-02, CO-15,
/// NV-21.
///
/// Layar mode sudah memakai `BottomActionBar`, jadi menurut kontrak zona ia
/// tidak boleh juga memakai `zone/page-action`. Aksinya karena itu mendarat di
/// slot kartu bawah (bottom 120 dp, tepat di atas action bar) - tempat yang
/// sama dengan seluruh kartu hasil mode lain, dan tetap di sepertiga bawah
/// layar tempat ibu jari beristirahat.
///
/// Dipasang sebagai anak `Stack` layar mode; ia mengisi stack dan memposisikan
/// dirinya sendiri, jadi pemanggil tidak perlu mengatur apa pun.
class PermissionPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;
  final String actionLabel;
  final VoidCallback onAction;
  final bool actionDisabled;
  final String? actionDisabledReason;

  const PermissionPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.onAction,
    this.actionDisabled = false,
    this.actionDisabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final actionBottom = bottomCardSlotOffset(bottomInset);

    return Positioned.fill(
      child: Stack(
        children: [
          // Kartu tetap di zona konten - perannya memberi tahu, bukan
          // ditekan. Padding bawah menjaga ia tidak pernah menabrak tombol.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: actionBottom + ZoneHeights.pageActionPrimary,
            child: Center(
              child: SingleChildScrollView(
                child: Semantics(
                  sortKey: const OrdinalSortKey(5),
                  child: PermissionCard(icon: icon, title: title, reason: reason),
                ),
              ),
            ),
          ),

          // Aksi utama: slot kartu bawah, tepat di atas BottomActionBar.
          // Urutan fokus 6 - sesudah isi kartu, sebelum tiga tombol bar.
          Positioned(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            bottom: actionBottom,
            child: Semantics(
              sortKey: const OrdinalSortKey(6),
              child: FullScreenButton(
                label: actionLabel,
                onTap: onAction,
                disabled: actionDisabled,
                disabledReason: actionDisabledReason,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
