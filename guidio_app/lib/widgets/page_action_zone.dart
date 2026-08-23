import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/layout/zone_contract.dart';
import '../theme/index.dart';
import 'full_screen_button.dart';

/// `zone/page-action` - bagian 6 ALUR-DAN-TOMBOL.md.
///
/// Kontrak zona di IMPLEMENTASI.md dirancang untuk enam mode, yang semuanya
/// diakhiri `BottomActionBar` 112 dp. Layar penunjang - Pengaturan,
/// Onboarding, Izin - tidak punya bar itu, jadi tidak ada zona yang menampung
/// tombol aksi halaman; itu sebabnya tombol seperti "Uji koneksi" dulu
/// berakhir menempel di kolom isian, di sepertiga atas layar.
///
/// Zona ini menempel di dasar layar: 96 dp tombol + 24 dp safe area = 120 dp.
/// Isinya **satu** tombol aksi utama, opsional satu tombol sekunder 56 dp di
/// atasnya dengan jarak 8 dp.
///
/// **Tidak pernah hadir bersamaan dengan `BottomActionBar`.** Sebuah layar
/// punya salah satu, tidak pernah keduanya. Layar mode memakai
/// [bottomCardSlotOffset] sebagai gantinya.
///
/// Sekunder digambar **di atas** primer, dan karena itu juga dibaca TalkBack
/// lebih dulu - urutan fokus bagian 10 nomor 10 lalu 11. Urutan itu dipasang
/// eksplisit lewat [SemanticsSortKey]; di Flutter urutan fokus tidak otomatis
/// mengikuti posisi visual.
class PageActionZone extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDisabled;

  /// Wajib diisi saat [primaryDisabled] - bagian 5.4: tombol nonaktif selalu
  /// menyebut alasannya, dan alasan itu ikut dibacakan sebagai bagian nilai.
  final String? primaryDisabledReason;
  final IconData? primaryIcon;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Titik awal urutan fokus zona ini. Sekunder = [sortOrder], primer =
  /// [sortOrder] + 1. Baku 100 supaya selalu jatuh sesudah seluruh isi
  /// halaman, berapa pun jumlah kontrol inline di atasnya.
  final double sortOrder;

  const PageActionZone({
    super.key,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryDisabled = false,
    this.primaryDisabledReason,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.sortOrder = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondaryLabel != null) ...[
              Semantics(
                sortKey: OrdinalSortKey(sortOrder),
                child: VinaraSecondaryButton(
                  label: secondaryLabel!,
                  onTap: onSecondary,
                ),
              ),
              const SizedBox(height: ZoneHeights.pageActionGap),
            ],
            Semantics(
              sortKey: OrdinalSortKey(sortOrder + 1),
              child: FullScreenButton(
                label: primaryLabel,
                onTap: onPrimary,
                disabled: primaryDisabled,
                disabledReason: primaryDisabledReason,
                icon: primaryIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol sekunder 56 dp untuk `zone/page-action` - "Lewati panduan",
/// "Ulangi langkah ini", "Keluar dari aplikasi". Lebar penuh supaya target
/// sentuhnya sama besarnya dengan primer; yang membedakan hanya bobot visual,
/// bukan kemudahan dijangkau.
class VinaraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const VinaraSecondaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Ink(
            height: ZoneHeights.pageActionSecondary,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSunk,
              borderRadius: AppRadius.card,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.label(
                  color: onTap == null ? AppColors.disabledInk : AppColors.ink1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold layar penunjang: isi halaman + [PageActionZone] menempel di dasar.
/// Zona dipasang lewat `bottomNavigationBar` supaya ia sticky saat [body]
/// digulung - aksi utama halaman wajib terjangkau **tanpa** pengguna
/// menggulung (bagian 5 "Aturan penempatan").
class PageActionScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDisabled;
  final String? primaryDisabledReason;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Banner kondisi global (StatusBanner), digambar di atas [body] tanpa
  /// menggeser zona aksi.
  final Widget? statusBanner;

  const PageActionScaffold({
    super.key,
    required this.body,
    required this.primaryLabel,
    this.appBar,
    this.backgroundColor,
    this.onPrimary,
    this.primaryDisabled = false,
    this.primaryDisabledReason,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.statusBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.bgPage,
      appBar: appBar,
      body: statusBanner == null
          ? body
          : Column(children: [statusBanner!, Expanded(child: body)]),
      bottomNavigationBar: PageActionZone(
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        primaryDisabled: primaryDisabled,
        primaryDisabledReason: primaryDisabledReason,
        primaryIcon: primaryIcon,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
    );
  }
}
