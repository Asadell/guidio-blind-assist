import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../screens/settings_screen.dart';
import '../theme/index.dart';
import 'mode_badge.dart';
import 'sheet_header.dart';

/// ModePickerSheet (5.5) - enam mode, cadangan untuk situasi tidak bisa
/// bicara. Fokus terkunci di dalam sheet; setelah ditutup, fokus kembali ke
/// tombol Pilih Mode (ditangani otomatis oleh showModalBottomSheet).
///
/// Keputusan audit: Navigasi TIDAK PERNAH dinonaktifkan offline - deteksi
/// rintangan on-device tetap hidup, jadi statenya `limited` dengan alasan
/// "Tanpa internet: rintangan saja". Cari Objek yang benar-benar disabled.
void showModePickerSheet(BuildContext context) {
  // Ditanyakan saat sheet dibuka, bukan saat item ditekan - status harus
  // sudah terbaca sebelum pengguna memilih. Tidak di-await: sheet tampil
  // segera, dan item memperbarui dirinya begitu jawaban datang.
  context.read<CapabilitiesProvider>().refreshIfStale(
        offline: context.read<GlobalConditionsProvider>().isBackendDown,
      );

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceMuted,
    barrierColor: AppColors.scrimDim,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    // Tinggi mengikuti isinya, bukan dipatok 620 px.
    //
    // Angka tetap itu memaksa gulir walau isinya sebenarnya muat, dan menggulir
    // adalah gerakan yang paling mahal di aplikasi ini: pengguna sedang berdiri,
    // satu tangan memegang tongkat, dan daftar mode justru yang paling sering
    // dibuka. `isScrollControlled` melepas batas setengah layar bawaan
    // Flutter sehingga lembar boleh setinggi isinya.
    //
    // Batas 92% tinggi layar tetap ada, dan gulir tetap tersedia, TAPI hanya
    // sebagai katup pengaman. Aplikasi ini mendukung ukuran teks 200%, dan di
    // skala itu isinya memang tidak mungkin muat: yang harus dihindari adalah
    // meluap (garis kuning hitam dan tombol yang terpotong), bukan menggulir.
    isScrollControlled: true,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.92,
      ),
      child: const _ModePickerSheet(),
    ),
  );
}

/// Mode yang muncul sebagai pilihan di lembar ini.
///
/// Keenam-enamnya ikut, termasuk Deskripsi Suasana.
///
/// Ia sempat dikeluarkan dengan alasan tombol Bicara di tengah sudah jadi
/// pintu masuknya. Alasan itu tidak berlaku lagi setelah tombol Bicara dan
/// mode ini dipisah perannya: mic mengurus perintah suara, sedangkan tombol
/// kiri di mode ini mengirim foto ke VLM. Dua hal yang berbeda, jadi modenya
/// perlu pintu masuk sendiri.
///
/// Urutannya mengikuti seberapa sering dipakai sambil berjalan, bukan urutan
/// deklarasi enum.
const List<AppMode> _pickableModes = [
  AppMode.tuntun,
  AppMode.navigasi,
  AppMode.money,
  AppMode.ocr,
  AppMode.voice,
  AppMode.findObject,
];

class _ModePickerSheet extends StatelessWidget {
  const _ModePickerSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppModeProvider>().mode;
    // `isBackendDown`, bukan `isOffline`: mode yang butuh server sama-sama
    // tidak bisa dipakai entah karena tidak ada jaringan atau karena server
    // tidak menjawab. Yang penting bagi pengguna adalah statusnya sudah benar
    // SEBELUM ia menekan, bukan sesudah gagal.
    final offline = context.watch<GlobalConditionsProvider>().isBackendDown;
    final caps = context.watch<CapabilitiesProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Pilih Mode',
              closeLabel: 'Tutup pilihan mode',
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.actionTint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_none_rounded, size: 14, color: AppColors.actionLabel),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Atau ucapkan via tombol Bicara (Mic)',
                      style: AppTypography.caption(color: AppColors.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                // Menggulir hanya saat isinya memang tidak muat. Di ukuran teks
                // normal seluruh daftar tampil sekaligus; di 200% barulah ini
                // bekerja, dan itu jauh lebih baik daripada meluap.
                physics: const ClampingScrollPhysics(),
                itemCount: _pickableModes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
                itemBuilder: (_, i) {
                  final mode = _pickableModes[i];
                  // Status ditentukan jaringan DAN jawaban server, ditanyakan
                  // sebelum sheet dibuka - bukan ditebak dari koneksi saja.
                  final state = caps.stateOf(mode, offline: offline);
                  final disabled = state == CapState.down;
                  final limited = state == CapState.limited && mode != current;

                  return _ModeTile(
                    mode: mode,
                    isCurrent: mode == current,
                    disabled: disabled,
                    limited: limited,
                    reason: caps.unavailableReason(mode, offline: offline),
                    onTap: disabled
                        ? null
                        : () async {
                            // Nilai balik `setMode` WAJIB diperiksa. Tanpa ini,
                            // membatalkan konfirmasi keluar-Navigasi menutup
                            // sheet tanpa satu kata pun terucap: `announceEntry`
                            // tidak jalan karena mode tidak berubah, dan
                            // pengguna yang tidak melihat layar menyimpulkan
                            // modenya sudah berganti. VoiceProvider sudah
                            // menangani ini dengan benar sejak awal - hanya
                            // jalur sheet yang bocor.
                            final appMode = context.read<AppModeProvider>();
                            final tts = context.read<TtsProvider>();
                            final navigator = Navigator.of(context);
                            final previous = appMode.mode;

                            final changed = await appMode.setMode(mode);
                            if (!changed && appMode.mode == previous) {
                              tts.speak(
                                'Tetap di mode ${previous.label}.',
                                tier: SpeechTier.info,
                              );
                            }
                            navigator.pop();
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            // Layar penunjang bukan saudara mode, jadi ia TIDAK muncul sebagai
            // item mode. Tempatnya di paling bawah sheet, dipisah garis -
            // bagian 2 ALUR-DAN-TOMBOL.md. Tanpa ini Pengaturan sama sekali
            // tidak punya pintu masuk di layar: satu-satunya jalan adalah
            // perintah suara, dan itu memutus pengguna yang tidak bisa bicara.
            const Divider(height: AppSpacing.s4, color: AppColors.hairline),
              Semantics(
              button: true,
              label: 'Pengaturan',
              child: Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        ExcludeSemantics(
                          child: Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                            child: const Icon(Icons.tune_rounded, size: 22, color: AppColors.ink1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: ExcludeSemantics(child: Text('Pengaturan', style: AppTypography.body()))),
                        const ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup pilihan mode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final AppMode mode;
  final bool isCurrent;
  final bool disabled;
  final bool limited;

  /// Alasan dari server (`/api/capabilities`), supaya perbaikan naskah tidak
  /// perlu rilis ulang aplikasi.
  final String? reason;
  final VoidCallback? onTap;

  const _ModeTile({
    required this.mode,
    required this.isCurrent,
    required this.onTap,
    this.disabled = false,
    this.limited = false,
    this.reason,
  });

  String? get _reason => reason;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isCurrent
        ? '${mode.label}, sedang aktif. Perintah suara: ${mode.voiceHint}'
        : _reason != null
            ? '${mode.label}, ${_reason!.toLowerCase()}'
            : '${mode.label}. Perintah suara: ${mode.voiceHint}';

    return Semantics(
      button: true,
      enabled: !disabled,
      selected: isCurrent,
      label: semanticLabel,
      child: Opacity(
        opacity: disabled ? .6 : 1,
        child: Material(
          color: isCurrent ? AppColors.actionTint : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: isCurrent ? null : AppElevation.flat,
              ),
              child: Row(
                children: [
                  if (isCurrent)
                    Container(
                      width: 3, height: 40,
                      margin: const EdgeInsets.only(right: 11),
                      decoration: BoxDecoration(
                        color: AppColors.actionFill,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 14),
                  ExcludeSemantics(
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                      child: Icon(modeIcon(mode), size: 22, color: AppColors.ink1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            mode.label,
                            style: isCurrent ? AppTypography.bodyStrong() : AppTypography.body(),
                          ),
                        ),
                        if (_reason != null)
                          ExcludeSemantics(
                            child: Text(
                              _reason!,
                              style: AppTypography.caption(
                                color: limited ? AppColors.warningLabel : AppColors.disabledInk,
                              ),
                            ),
                          )
                        else
                          ExcludeSemantics(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.actionLabel),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      mode.voiceHint,
                                      style: AppTypography.caption(color: AppColors.ink2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.actionLabel,
                          borderRadius: AppRadius.pillShape,
                        ),
                        child: Text('AKTIF', style: AppTypography.eyebrow(color: AppColors.onDark)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
