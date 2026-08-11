import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Terbilang rupiah — "angka rupiah selalu dibacakan penuh dalam kata, tidak
/// pernah 'seratus rb'" (bagian 9 & 17). Dipakai NominalCard dan naskah TTS.
String terbilangRupiah(int amount) {
  if (amount == 0) return 'nol rupiah';
  return '${_terbilang(amount)} rupiah';
}

const _satuan = [
  '', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan',
  'sepuluh', 'sebelas',
];

String _terbilang(int n) {
  if (n < 12) return _satuan[n];
  if (n < 20) return '${_terbilang(n - 10)} belas';
  if (n < 100) {
    final sisa = n % 10;
    return '${_terbilang(n ~/ 10)} puluh${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 200) return 'seratus${n == 100 ? '' : ' ${_terbilang(n - 100)}'}';
  if (n < 1000) {
    final sisa = n % 100;
    return '${_terbilang(n ~/ 100)} ratus${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 2000) return 'seribu${n == 1000 ? '' : ' ${_terbilang(n - 1000)}'}';
  if (n < 1000000) {
    final sisa = n % 1000;
    return '${_terbilang(n ~/ 1000)} ribu${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  if (n < 1000000000) {
    final sisa = n % 1000000;
    return '${_terbilang(n ~/ 1000000)} juta${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
  }
  final sisa = n % 1000000000;
  return '${_terbilang(n ~/ 1000000000)} miliar${sisa == 0 ? '' : ' ${_terbilang(sisa)}'}';
}

String formatRupiah(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

/// NominalCard (5.13) — khusus Mode Kenali Uang. Satu-satunya tempat
/// `display` 56sp dipakai. Nominal WAJIB dua bentuk (angka + kata), dan
/// tidak pernah ditampilkan saat keyakinan rendah — pemanggil bertanggung
/// jawab tidak me-render kartu ini pada kondisi itu.
class NominalCard extends StatelessWidget {
  final int amount;
  /// Rincian per lembar, mis. {20000: 2, 5000: 1} — opsional, untuk
  /// UG-09b "beberapa lembar berbeda".
  final Map<int, int>? breakdown;
  /// Total berjalan (UG-11 "lembar berturut-turut") — opsional.
  final int? runningTotal;
  final VoidCallback? onReplay;

  const NominalCard({
    super.key,
    required this.amount,
    this.breakdown,
    this.runningTotal,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final words = terbilangRupiah(amount);
    final formatted = formatRupiah(amount);

    return Semantics(
      header: true,
      liveRegion: true,
      label: '$formatted, $words',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: AppTypography.displayMoney(),
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                words,
                textAlign: TextAlign.center,
                style: AppTypography.title(color: AppColors.ink2),
              ),
            ),
            if (breakdown != null && breakdown!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.s2,
                runSpacing: 4,
                children: breakdown!.entries
                    .map((e) => Text(
                          '${e.value} × ${formatRupiah(e.key)}',
                          style: AppTypography.metricMono(color: AppColors.ink2),
                        ))
                    .toList(),
              ),
            ],
            if (runningTotal != null) ...[
              const SizedBox(height: AppSpacing.s3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
                decoration: const BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.pillShape),
                child: Text('Total: ${formatRupiah(runningTotal!)}',
                    style: AppTypography.label().copyWith(fontSize: 14)),
              ),
            ],
            if (onReplay != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Semantics(
                button: true,
                label: 'Putar ulang nominal',
                child: InkWell(
                  onTap: onReplay,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.actionTint, shape: BoxShape.circle),
                    child: const Icon(Icons.replay_rounded, color: AppColors.actionLabel),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
