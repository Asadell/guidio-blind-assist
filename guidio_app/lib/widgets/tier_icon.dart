import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tier alert: Critical / Warning / Info / Positive.
/// Setiap tier punya BENTUK ikon yang berbeda (bukan cuma warna berbeda),
/// supaya tetap terbaca oleh pengguna low vision / buta warna:
/// oktagon = Critical, segitiga = Warning, persegi membulat = Info,
/// centang = Positive.
enum AlertTier { critical, warning, info, positive }

extension AlertTierX on AlertTier {
  Color get fillColor => switch (this) {
        AlertTier.critical  => AppColors.criticalFill,
        AlertTier.warning   => AppColors.warningFill,
        AlertTier.info      => AppColors.actionFill,
        AlertTier.positive  => AppColors.positiveLabel,
      };

  Color get labelColor => switch (this) {
        AlertTier.critical  => AppColors.criticalLabel,
        AlertTier.warning   => AppColors.warningLabel,
        AlertTier.info      => AppColors.actionLabel,
        AlertTier.positive  => AppColors.positiveLabel,
      };

  Color get tintColor => switch (this) {
        AlertTier.critical  => AppColors.criticalTint,
        AlertTier.warning   => AppColors.warningTint,
        AlertTier.info      => AppColors.actionTint,
        AlertTier.positive  => AppColors.positiveTint,
      };

  String get label => switch (this) {
        AlertTier.critical  => 'Bahaya',
        AlertTier.warning   => 'Hati-hati',
        AlertTier.info      => 'Info',
        AlertTier.positive  => 'Aman',
      };

  static AlertTier fromDangerLevel(String dangerLevel) => switch (dangerLevel) {
        'critical' => AlertTier.critical,
        'warning'  => AlertTier.warning,
        _          => AlertTier.info,
      };
}

class TierIcon extends StatelessWidget {
  final AlertTier tier;
  final double size;

  const TierIcon({super.key, required this.tier, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TierIconPainter(tier)),
    );
  }
}

class _TierIconPainter extends CustomPainter {
  final AlertTier tier;
  _TierIconPainter(this.tier);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final fill = Paint()
      ..color = tier == AlertTier.positive ? tier.fillColor : tier.fillColor
      ..style = PaintingStyle.fill;

    switch (tier) {
      case AlertTier.critical:
        canvas.drawPath(_octagon(scale), fill);
        _mark(canvas, scale, AppColors.onDark, dotFirst: false);
        break;
      case AlertTier.warning:
        canvas.drawPath(_triangle(scale), fill);
        _mark(canvas, scale, AppColors.ink1, dotFirst: false);
        break;
      case AlertTier.info:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2.4 * scale, 2.4 * scale, 19.2 * scale, 19.2 * scale),
            Radius.circular(6 * scale),
          ),
          fill,
        );
        _mark(canvas, scale, AppColors.onDark, dotFirst: true);
        break;
      case AlertTier.positive:
        final stroke = Paint()
          ..color = AppColors.onDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawCircle(Offset(12 * scale, 12 * scale), 12 * scale, fill);
        final path = Path()
          ..moveTo(7.5 * scale, 12.5 * scale)
          ..lineTo(10.7 * scale, 15.7 * scale)
          ..lineTo(16.5 * scale, 8.5 * scale);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  /// Tanda seru (garis + titik) — tier Critical/Warning garis-lalu-titik,
  /// tier Info titik-lalu-garis (menyerupai huruf "i").
  void _mark(Canvas canvas, double scale, Color color, {required bool dotFirst}) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    if (dotFirst) {
      canvas.drawLine(Offset(12 * scale, 7.4 * scale), Offset(12 * scale, 7.5 * scale), stroke);
      canvas.drawLine(Offset(12 * scale, 10.6 * scale), Offset(12 * scale, 16.8 * scale), stroke);
    } else {
      canvas.drawLine(Offset(12 * scale, 7 * scale), Offset(12 * scale, 13 * scale), stroke);
      canvas.drawLine(Offset(12 * scale, 16.2 * scale), Offset(12 * scale, 16.3 * scale), stroke);
    }
  }

  Path _octagon(double s) => Path()
    ..moveTo(8.2 * s, 2 * s)
    ..lineTo(15.8 * s, 2 * s)
    ..lineTo(22 * s, 8.2 * s)
    ..lineTo(22 * s, 15.8 * s)
    ..lineTo(15.8 * s, 22 * s)
    ..lineTo(8.2 * s, 22 * s)
    ..lineTo(2 * s, 15.8 * s)
    ..lineTo(2 * s, 8.2 * s)
    ..close();

  Path _triangle(double s) => Path()
    ..moveTo(12 * s, 2.6 * s)
    ..lineTo(22 * s, 20.4 * s)
    ..lineTo(2 * s, 20.4 * s)
    ..close();

  @override
  bool shouldRepaint(covariant _TierIconPainter oldDelegate) => oldDelegate.tier != tier;
}
