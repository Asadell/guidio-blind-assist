import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/index.dart';

/// TargetChip (5.14) — khusus Mode Cari Objek. Baris sendiri di bawah
/// ModeBadge, TIDAK PERNAH berbagi baris dengannya. Elipsis hanya pada nama
/// barang; kata "Mencari:" selalu utuh.
class TargetChip extends StatelessWidget {
  final String itemName;

  const TargetChip({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 4 — bagian 10, baris sendiri di bawah ModeBadge.
      sortKey: const OrdinalSortKey(4),
      liveRegion: true,
      label: 'Mencari: $itemName',
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        decoration: const BoxDecoration(color: AppColors.actionFill, borderRadius: AppRadius.pillShape),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Text('Mencari: ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Expanded(
              child: Text(
                itemName,
                style: AppTypography.label(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
