import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionCard extends StatelessWidget {
  final Detection detection;
  const DetectionCard({super.key, required this.detection});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [const BoxShadow(color: Colors.black26, blurRadius: 8)],
        border:       Border(left: BorderSide(color: _borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _borderColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              detection.ttsMessage,
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor => switch (detection.dangerLevel) {
        'critical' => Colors.red,
        'warning'  => Colors.orange,
        _          => Colors.green,
      };

  IconData get _icon => switch (detection.dangerLevel) {
        'critical' => Icons.warning_rounded,
        'warning'  => Icons.info_rounded,
        _          => Icons.check_circle_rounded,
      };
}
