import 'package:flutter/material.dart';

import '../theme/index.dart';

/// Terbilang rupiah - "angka rupiah selalu dibacakan penuh dalam kata, tidak
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

/// NominalCard (5.13) - khusus Mode Kenali Uang. Satu-satunya tempat
/// `display` 56sp dipakai. Nominal WAJIB dua bentuk (angka + kata).
///
/// Kartu ini hanya menampilkan **satu nominal**: lembar yang sedang dihadapi
/// kamera. Tidak ada rincian lembar dan tidak ada total berjalan - mode ini
/// tidak menjumlahkan apa pun.
///
/// Sejak gerbang keyakinan berhenti menahan jawaban, kartu ini juga dipakai
/// untuk hasil yang BELUM yakin, lewat [certain]. Dulu kondisi itu dirender
/// sebagai kartu peringatan tanpa angka sama sekali, dan itu yang membuat
/// mode uang buntu di lapangan.
class NominalCard extends StatelessWidget {
  final int amount;
  final VoidCallback? onReplay;

  /// `false` berarti nominal ini tebakan terbaik model, bukan kepastian.
  ///
  /// Pagarnya harus terbaca SEBELUM angkanya, bukan sesudah: pengguna awas
  /// membaca kartu dari atas, dan pembaca layar mengumumkan label semantik
  /// sebagai satu kalimat utuh. Menaruh "Sepertinya" di bawah angka berarti
  /// sebagian orang tidak pernah sampai ke sana.
  final bool certain;

  const NominalCard({
    super.key,
    required this.amount,
    this.onReplay,
    this.certain = true,
  });

  @override
  Widget build(BuildContext context) {
    final words = terbilangRupiah(amount);
    final formatted = formatRupiah(amount);

    return Semantics(
      header: true,
      liveRegion: true,
      label: certain
          ? '$formatted, $words'
          : 'Sepertinya $formatted, $words. '
              'Keyakinan rendah, sebaiknya dicek ulang.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
          border: certain
              ? null
              : Border.all(color: AppColors.warningFill, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!certain) ...[
              ExcludeSemantics(
                child: Text(
                  'SEPERTINYA',
                  textAlign: TextAlign.center,
                  style: AppTypography.eyebrow(color: AppColors.warningLabel),
                ),
              ),
              const SizedBox(height: 4),
            ],
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
            if (!certain) ...[
              const SizedBox(height: AppSpacing.s2),
              ExcludeSemantics(
                child: Text(
                  'Keyakinan rendah. Dekatkan sedikit lalu tekan lagi kalau ragu.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: AppColors.warningLabel),
                ),
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
