import 'package:flutter/material.dart';

import '../models/detection.dart';
import 'alert_card.dart';
import 'tier_icon.dart';

/// Adapter: Detection (domain model) → AlertCard (design system).
class DetectionCard extends StatelessWidget {
  final Detection detection;
  const DetectionCard({super.key, required this.detection});

  String get _title {
    final label = detection.labelId.isEmpty ? 'Objek' : _capitalize(detection.labelId);
    return '$label di ${detection.direction}';
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return AlertCard(
      tier: AlertTierX.fromDangerLevel(detection.dangerLevel),
      title: _title,
      distanceMeter: detection.distanceMeter,
    );
  }
}
