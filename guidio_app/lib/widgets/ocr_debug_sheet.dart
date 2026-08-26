import 'package:flutter/material.dart';

import '../mock/ocr_mock_data.dart';
import '../theme/index.dart';
import 'sheet_header.dart';

/// OcrDebugSheet - bottom sheet QA khusus Mode Baca Teks: daftar 22 state
/// BT-01..BT-22 (bagian 8). Memilih satu item memaksa tampilan lokal
/// `ocr_screen.dart` ke kondisi itu (data mock) sampai dibatalkan - dibuka
/// lewat ketuk 5× pada [ModeBadge] (`onDebugActivate`).
Future<void> showOcrDebugSheet(
  BuildContext context, {
  required String? activeId,
  required ValueChanged<String> onSelect,
  required VoidCallback onCancel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OcrDebugSheetContent(
      activeId: activeId,
      onSelect: (id) {
        Navigator.of(ctx).pop();
        onSelect(id);
      },
      onCancel: () {
        Navigator.of(ctx).pop();
        onCancel();
      },
    ),
  );
}

class _OcrDebugSheetContent extends StatelessWidget {
  final String? activeId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCancel;

  const _OcrDebugSheetContent({
    required this.activeId,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(bottom: media.viewInsets.bottom),
        constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.sheetTop,
          boxShadow: AppElevation.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: AppSpacing.s3),
                decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Debug - Mode Baca Teks', style: AppTypography.title()),
                    ),
                  ),
                  if (activeId != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    GestureDetector(
                      onTap: onCancel,
                      child: Semantics(
                        button: true,
                        label: 'Batalkan mode debug',
                        child: Container(
                          height: AppSizes.minTouchTarget,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: const BoxDecoration(color: AppColors.criticalTint, borderRadius: AppRadius.pillShape),
                          child: Text('Batalkan', style: AppTypography.label(color: AppColors.criticalLabel)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.s2),
                  // "Batalkan" membuang override debug; tombol ini menutup
                  // lembarnya. Dua hal berbeda, jadi dua tombol - lembar yang
                  // sedang memakai override tidak boleh cuma bisa ditutup
                  // dengan cara yang sekaligus membatalkan override itu.
                  const SheetCloseButton(label: 'Tutup panel debug'),
                ],
              ),
            ),
            if (activeId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Aktif: $activeId', style: AppTypography.caption(color: AppColors.actionLabel)),
                ),
              ),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
                itemCount: ocrDebugCatalog.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairline),
                itemBuilder: (context, i) {
                  final entry = ocrDebugCatalog[i];
                  final active = entry.id == activeId;
                  return Semantics(
                    button: true,
                    label: '${entry.id}, ${entry.title}. ${entry.hint}',
                    child: ListTile(
                      onTap: () => onSelect(entry.id),
                      tileColor: active ? AppColors.actionTint : Colors.transparent,
                      leading: SizedBox(
                        width: 52,
                        child: Text(entry.id, style: AppTypography.metricMono(color: AppColors.actionLabel)),
                      ),
                      title: Text(entry.title, style: AppTypography.bodyStrong()),
                      subtitle: Text(entry.hint, style: AppTypography.caption()),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.s3 + media.padding.bottom),
          ],
        ),
      ),
    );
  }
}
