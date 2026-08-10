import 'package:flutter/material.dart';

import '../theme/index.dart';

/// GuideFrame (F11) — empat busur sudut yang mengencang saat objek makin
/// pas, bukan persegi putus-putus statis (itu pola kamera QR dan tidak
/// mengabarkan apa pun).
enum FrameFit { empty, partial, fit, tooClose }

extension FrameFitX on FrameFit {
  Color get color => switch (this) {
        FrameFit.empty   => Colors.white,
        FrameFit.partial => AppColors.warningFill,
        FrameFit.fit     => AppColors.positiveFill,
        FrameFit.tooClose => AppColors.criticalFill,
      };

  double get armLength => switch (this) {
        FrameFit.empty    => 28,
        FrameFit.partial  => 32,
        FrameFit.fit      => 40,
        FrameFit.tooClose => 40,
      };

  double get inset => switch (this) {
        FrameFit.empty    => 34,
        FrameFit.partial  => 32,
        FrameFit.fit      => 30,
        FrameFit.tooClose => 14,
      };

  String get caption => switch (this) {
        FrameFit.empty    => 'Arahkan ke objek',
        FrameFit.partial  => 'Geser ponsel ke tengah',
        FrameFit.fit      => 'Posisi pas, tahan sebentar',
        FrameFit.tooClose => 'Terlalu dekat, jauhkan sedikit',
      };
}

class GuideFrame extends StatelessWidget {
  final FrameFit fit;
  final bool showCaption;

  const GuideFrame({super.key, required this.fit, this.showCaption = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: fit.caption,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CornerPainter(inset: fit.inset, arm: fit.armLength, color: fit.color)),
          ),
          if (showCaption)
            Positioned(
              left: 0, right: 0, bottom: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(color: AppColors.scrimText, borderRadius: AppRadius.pillShape),
                  child: Text(fit.caption, style: AppTypography.caption(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double inset;
  final double arm;
  final Color color;

  _CornerPainter({required this.inset, required this.arm, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const r = 14.0;

    void corner(Offset origin, {required bool right, required bool bottom}) {
      final dx = right ? -1.0 : 1.0;
      final dy = bottom ? -1.0 : 1.0;
      final path = Path()
        ..moveTo(origin.dx, origin.dy + dy * arm)
        ..lineTo(origin.dx, origin.dy + dy * r)
        ..arcToPoint(
          Offset(origin.dx + dx * r, origin.dy),
          radius: const Radius.circular(r),
          clockwise: right != bottom,
        )
        ..lineTo(origin.dx + dx * arm, origin.dy);
      canvas.drawPath(path, paint);
    }

    corner(Offset(inset, inset), right: false, bottom: false);
    corner(Offset(size.width - inset, inset), right: true, bottom: false);
    corner(Offset(inset, size.height - inset), right: false, bottom: true);
    corner(Offset(size.width - inset, size.height - inset), right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.inset != inset || oldDelegate.arm != arm || oldDelegate.color != color;
}
