import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../models/detection.dart';
import '../theme/app_colors.dart';

/// Hamparan kotak deteksi di atas preview kamera.
///
/// ## Untuk siapa ini
///
/// Pengguna utama aplikasi ini tunanetra dan tidak melihat kotaknya sama
/// sekali - informasinya sampai lewat suara dan getar. Hamparan ini untuk
/// orang lain: pendamping awas, penguji lapangan, juri, dan pengembang yang
/// perlu tahu apakah model benar-benar melihat yang seharusnya.
///
/// Itu bukan alasan untuk menganggapnya hiasan. Tanpa cara melihat apa yang
/// dideteksi model, satu-satunya cara memeriksa kesalahan adalah menebak dari
/// kalimat yang terucap - dan kalau kotaknya meleset, tidak ada yang tahu
/// sampai ada yang tersandung.
///
/// ## Koordinat
///
/// Digambar dari [Detection.normalizedBox], pecahan 0..1 terhadap bingkai
/// tegak. Deteksi yang tidak melaporkan ukuran bingkai DILEWATI, bukan
/// ditebak posisinya: kotak di tempat yang salah lebih menyesatkan daripada
/// tidak ada kotak.
///
/// Pemanggil wajib menempatkan widget ini pada persegi yang sama dengan
/// preview kamera. `CameraStage` ada untuk menjamin itu.
class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;

  /// Batas jumlah kotak yang digambar sekaligus.
  ///
  /// Frame ramai bisa menghasilkan belasan deteksi, dan menggambar semuanya
  /// menghasilkan tumpukan kotak yang justru tidak terbaca. Yang terdekat
  /// didahulukan karena itu yang paling menentukan langkah berikutnya.
  final int maxBoxes;

  /// Tampilkan pill jarak di atas kotak.
  final bool showDistance;

  const DetectionOverlay({
    super.key,
    required this.detections,
    this.maxBoxes = 6,
    this.showDistance = true,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    // Hanya yang tahu ukuran bingkainya sendiri yang bisa digambar.
    final drawable = detections
        .where((d) => d.normalizedBox != null)
        .toList()
      ..sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));

    if (drawable.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      // Kotak berubah tiap frame inferensi; tanpa batas repaint, seluruh
      // pohon widget di bawahnya ikut digambar ulang delapan kali per detik.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DetectionPainter(
            detections: drawable.take(maxBoxes).toList(),
            showDistance: showDistance,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final bool showDistance;

  _DetectionPainter({required this.detections, required this.showDistance});

  static const double _minSide = 12.0;

  Color _colorOf(String danger) => switch (danger) {
        'critical' => AppColors.criticalFill,
        'warning' => AppColors.warningFill,
        _ => AppColors.positiveFill,
      };

  Color _labelBgOf(String danger) => switch (danger) {
        'critical' => AppColors.criticalLabel,
        'warning' => AppColors.warningLabel,
        _ => AppColors.positiveLabel,
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    for (final d in detections) {
      final n = d.normalizedBox;
      if (n == null) continue;

      var rect = Rect.fromLTRB(
        n.left * size.width,
        n.top * size.height,
        n.right * size.width,
        n.bottom * size.height,
      );

      // Kotak yang terlalu kecil tidak terbaca sebagai kotak, cuma sebagai
      // titik. Dilebarkan seperlunya supaya tetap kelihatan sebagai deteksi.
      if (rect.width < _minSide || rect.height < _minSide) {
        rect = Rect.fromCenter(
          center: rect.center,
          width: rect.width < _minSide ? _minSide : rect.width,
          height: rect.height < _minSide ? _minSide : rect.height,
        );
      }

      final color = _colorOf(d.dangerLevel);
      final critical = d.dangerLevel == 'critical';

      // Isian sangat tipis: menandai area tanpa menutupi permukaan yang
      // justru sedang dinilai orang yang melihat layar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = color.withValues(alpha: critical ? 0.16 : 0.10),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = critical ? 3.0 : 2.0
          ..color = color,
      );

      // Sudut dipertegas untuk yang kritis - bentuk kurung siku terbaca
      // lebih cepat daripada garis seragam saat layar penuh objek.
      if (critical) _drawCorners(canvas, rect, color);

      _drawLabel(canvas, size, rect, d);
    }
  }

  void _drawCorners(Canvas canvas, Rect r, Color color) {
    final arm = (r.shortestSide * 0.28).clamp(6.0, 22.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = color;

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(arm * dx, 0), p);
      canvas.drawLine(o, o.translate(0, arm * dy), p);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);
  }

  void _drawLabel(Canvas canvas, Size size, Rect box, Detection d) {
    final parts = <String>[d.labelId.isNotEmpty ? d.labelId : d.labelEn];
    if (showDistance) {
      parts.add(d.distanceMeter < 1.0
          ? '<1 m'
          : '~${d.distanceMeter.toStringAsFixed(1)} m');
    }
    final text = parts.join('  ');

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.onDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 8);

    const padH = 7.0;
    const padV = 4.0;
    final chipW = tp.width + padH * 2;
    final chipH = tp.height + padV * 2;

    // Ditaruh di atas kotak; kalau mepat tepi atas layar, dipindah ke dalam
    // kotak supaya labelnya tidak terpotong dan jadi tidak terbaca.
    var left = box.left;
    var top = box.top - chipH - 3;
    if (top < 0) top = box.top + 3;
    if (left + chipW > size.width) left = size.width - chipW;
    if (left < 0) left = 0;

    final chip = Rect.fromLTWH(left, top, chipW, chipH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, const Radius.circular(6)),
      Paint()..color = _labelBgOf(d.dangerLevel),
    );
    tp.paint(canvas, Offset(chip.left + padH, chip.top + padV));
  }

  @override
  bool shouldRepaint(_DetectionPainter old) =>
      old.showDistance != showDistance ||
      old.detections.length != detections.length ||
      !_sameBoxes(old.detections, detections);

  /// Bandingkan isi kotaknya, bukan identitas daftarnya.
  ///
  /// Pipeline membangun `List<Detection>` baru setiap frame, jadi
  /// membandingkan referensi akan selalu bilang "berubah" dan memaksa
  /// gambar ulang delapan kali per detik walau objeknya diam di tempat.
  bool _sameBoxes(List<Detection> a, List<Detection> b) {
    for (var i = 0; i < a.length; i++) {
      final x = a[i].normalizedBox;
      final y = b[i].normalizedBox;
      if (x == null || y == null) return false;
      if (a[i].dangerLevel != b[i].dangerLevel) return false;
      if (a[i].labelId != b[i].labelId) return false;
      if ((a[i].distanceMeter - b[i].distanceMeter).abs() > 0.05) return false;
      if ((x.left - y.left).abs() > 0.002) return false;
      if ((x.top - y.top).abs() > 0.002) return false;
      if ((x.right - y.right).abs() > 0.002) return false;
      if ((x.bottom - y.bottom).abs() > 0.002) return false;
    }
    return true;
  }
}
