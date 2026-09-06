import 'package:flutter/material.dart';

import '../models/detection.dart';
import 'alert_card.dart';
import 'tier_icon.dart';

/// Adapter: Detection (domain model) → AlertCard (design system).
///
/// Kartu ini melaporkan, tidak memvonis. Judulnya berbunyi "Ada orang di
/// depan", bukan "Orang di depan" di bawah eyebrow "BAHAYA" - persis kalimat
/// yang diucapkan mode ini lewat [Detection.objectMessage], supaya yang
/// terbaca pendamping awas dan yang terdengar penggunanya adalah hal yang
/// sama.
///
/// Warna dan ikon tier tetap dipertahankan. Keduanya menjawab "seberapa
/// dekat", yang memang diketahui model; yang dilepaskan hanya kata "Bahaya",
/// yang menjawab "seberapa berbahaya" - pertanyaan yang tidak pernah
/// dijawab siapa pun di jalur ini.
class DetectionCard extends StatelessWidget {
  final Detection detection;
  const DetectionCard({super.key, required this.detection});

  String get _title {
    final label = detection.labelId.isEmpty ? 'objek' : detection.labelId;
    return 'Ada $label di ${detection.direction}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertCard(
      tier: AlertTierX.fromDangerLevel(detection.dangerLevel),
      eyebrow: 'Terdeteksi',
      title: _title,
      distanceMeter: detection.distanceMeter,
    );
  }
}
