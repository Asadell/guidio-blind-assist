import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../theme/index.dart';
import 'mode_badge.dart';

/// ModePickerSheet (F5). Item tinggi 64, gap 8, radius r/sm. Item aktif
/// memakai action/tint + Pita Prioritas biru — bukan border tebal.
/// Sheet maksimum 620 dp; daftar mode yang menggulung, bukan sheet-nya.
void showModePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgPage,
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
              width: 36, height: 4,
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
            Text('atau ucapkan nama mode',
                style: AppTypography.caption()),
            const SizedBox(height: AppSpacing.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppMode.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
                itemBuilder: (_, i) {
                  final mode = AppMode.values[i];
                  return _ModeTile(
                    mode: mode,
                    isCurrent: mode == current,
                    onTap: () {
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
  final VoidCallback onTap;

  const _ModeTile({required this.mode, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isCurrent,
      label: isCurrent ? '${mode.label}, sedang aktif' : mode.label,
      child: Material(
        color: isCurrent ? AppColors.actionTint : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  decoration: const BoxDecoration(
                    color: AppColors.bgPage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(modeIcon(mode), size: 22, color: AppColors.ink1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mode.label,
                    style: isCurrent ? AppTypography.bodyStrong() : AppTypography.body(),
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
    );
  }
}
