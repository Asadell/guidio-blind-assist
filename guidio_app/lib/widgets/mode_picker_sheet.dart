import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../theme/index.dart';
import 'mode_badge.dart';

/// ModePickerSheet (5.5) — enam mode, cadangan untuk situasi tidak bisa
/// bicara. Fokus terkunci di dalam sheet; setelah ditutup, fokus kembali ke
/// tombol Pilih Mode (ditangani otomatis oleh showModalBottomSheet).
///
/// Keputusan audit: Navigasi TIDAK PERNAH dinonaktifkan offline — deteksi
/// rintangan on-device tetap hidup, jadi statenya `limited` dengan alasan
/// "Tanpa internet: rintangan saja". Cari Objek yang benar-benar disabled.
void showModePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceMuted,
    barrierColor: AppColors.scrimDim,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    constraints: const BoxConstraints(maxHeight: 620),
    builder: (_) => const _ModePickerSheet(),
  );
}

class _ModePickerSheet extends StatelessWidget {
  const _ModePickerSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppModeProvider>().mode;
    final offline = context.watch<GlobalConditionsProvider>().isOffline;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, AppSpacing.s3, AppSpacing.screenMargin, AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Semantics(
              header: true,
              child: Text('Pilih Mode', style: AppTypography.title()),
            ),
            const SizedBox(height: 4),
            Text('atau ucapkan nama mode', style: AppTypography.caption()),
            const SizedBox(height: AppSpacing.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppMode.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
                itemBuilder: (_, i) {
                  final mode = AppMode.values[i];
                  final disabled = offline && mode.disabledWhenOffline;
                  final limited = offline && mode.needsServer && !mode.disabledWhenOffline && mode != current;

                  return _ModeTile(
                    mode: mode,
                    isCurrent: mode == current,
                    disabled: disabled,
                    limited: limited,
                    onTap: disabled
                        ? null
                        : () {
                            context.read<AppModeProvider>().setMode(mode);
                            Navigator.pop(context);
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
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
  final VoidCallback? onTap;

  const _ModeTile({
    required this.mode,
    required this.isCurrent,
    required this.onTap,
    this.disabled = false,
    this.limited = false,
  });

  String? get _reason {
    if (disabled) return 'Tidak tersedia, butuh internet';
    if (limited) return 'Tanpa internet: rintangan saja';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isCurrent
        ? '${mode.label}, sedang aktif'
        : _reason != null
            ? '${mode.label}, ${_reason!.toLowerCase()}'
            : mode.label;

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
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.bgPage, shape: BoxShape.circle),
                    child: Icon(modeIcon(mode), size: 22, color: AppColors.ink1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mode.label,
                          style: isCurrent ? AppTypography.bodyStrong() : AppTypography.body(),
                        ),
                        if (_reason != null)
                          Text(
                            _reason!,
                            style: AppTypography.caption(
                              color: limited ? AppColors.warningLabel : AppColors.disabledInk,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.actionLabel,
                        borderRadius: AppRadius.pillShape,
                      ),
                      child: Text('AKTIF', style: AppTypography.eyebrow(color: Colors.white)),
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
