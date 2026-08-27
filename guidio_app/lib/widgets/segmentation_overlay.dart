import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Warna hamparan segmentasi jalur.
///
/// Alfa-nya sengaja rendah. Hamparan ini dibaca oleh pendamping awas, juri,
/// atau pengguna low-vision - bukan oleh pengguna tunanetra total - jadi dia
/// harus menjelaskan apa yang dilihat sistem TANPA menutupi permukaan asli
/// yang sedang dinilai. Hamparan pekat justru menyembunyikan bukti yang
/// membuatnya berguna.
class SegmentationPalette {
  /// Jalur yang layak dilewati.
  final Color walkable;

  /// Lubang, tangga, dan bahaya permukaan lain.
  final Color hazard;

  /// Bukan jalur, TAPI sejajar dengan jalur.
  ///
  /// Dulu transparan penuh. Sekarang merah tipis, dan pembatasnya penting:
  /// hanya dicat mulai dari baris tempat jalur pertama muncul ke bawah - lihat
  /// [maskToImage]. Tanpa pembatas itu, langit dan pucuk pohon ikut memerah
  /// dan seluruh layar jadi merah kecuali secarik hijau, yang justru
  /// menghilangkan kontras yang mau dibangun.
  ///
  /// Dengan pembatas itu, yang memerah persis rumput, pagar tanaman, dan aspal
  /// di kiri-kanan trotoar. Untuk pengguna low-vision, "hijau tempat kaki
  /// boleh mendarat, merah tidak" terbaca dalam sekali lihat.
  final Color nonWalkable;

  const SegmentationPalette({
    this.walkable = const Color(0x4451B055),
    this.hazard = const Color(0x66E5484D),
    this.nonWalkable = const Color(0x2EE5484D),
  });

  static const SegmentationPalette standard = SegmentationPalette();
}

/// Ubah mask kelas per-piksel jadi [ui.Image] RGBA siap gambar.
///
/// ## Kenapa jadi gambar, bukan ribuan persegi
///
/// Mask 160x96 berisi 15.360 sel. Menggambarnya sebagai `drawRect` per sel
/// berarti belasan ribu perintah gambar setiap frame, dan pada HP mid-low itu
/// membuat preview kamera tersendat persis saat pengguna sedang berjalan.
///
/// Satu `ui.Image` digambar sebagai satu perintah, dan GPU yang mengurus
/// penskalaannya. Biayanya praktis tidak bergantung pada resolusi mask.
///
/// Konversinya berjalan di luar thread UI lewat [ui.decodeImageFromPixels],
/// jadi frame kamera tidak menunggu.
Future<ui.Image> maskToImage(
  Uint8List mask,
  int width,
  int height, {
  SegmentationPalette palette = SegmentationPalette.standard,
}) {
  final rgba = Uint8List(width * height * 4);

  // Diambil sekali di luar loop: membaca properti Color per piksel di dalam
  // loop 15 ribu iterasi itu biaya yang tidak perlu dibayar.
  final colors = <List<int>>[
    _rgba(palette.nonWalkable),
    _rgba(palette.walkable),
    _rgba(palette.hazard),
  ];
  const kosong = <int>[0, 0, 0, 0];

  // Baris teratas yang masih mengandung jalur. Di atasnya tidak ada apa pun
  // yang akan diinjak, jadi tidak ada gunanya diwarnai - itu langit, pohon,
  // dan bangunan di kejauhan.
  var barisJalurTeratas = height;
  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      if (mask[row + x] == 1) {
        barisJalurTeratas = y;
        break;
      }
    }
    if (barisJalurTeratas != height) break;
  }

  for (var i = 0; i < mask.length; i++) {
    final cls = mask[i] < colors.length ? mask[i] : 0;
    // Bukan jalur DAN di atas garis jalur teratas -> dibiarkan bening.
    final c = (cls == 0 && i ~/ width < barisJalurTeratas)
        ? kosong
        : colors[cls];
    final o = i * 4;
    rgba[o] = c[0];
    rgba[o + 1] = c[1];
    rgba[o + 2] = c[2];
    rgba[o + 3] = c[3];
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

List<int> _rgba(Color c) {
  // Alfa dikalikan ke tiap kanal (premultiplied): `decodeImageFromPixels`
  // dengan rgba8888 memperlakukan datanya sebagai premultiplied, dan tanpa
  // ini warnanya keluar jauh lebih terang daripada yang diminta.
  final a = (c.a * 255).round();
  final f = a / 255.0;
  return [
    (c.r * 255 * f).round(),
    (c.g * 255 * f).round(),
    (c.b * 255 * f).round(),
    a,
  ];
}

/// Hamparan segmentasi jalur di atas preview kamera.
///
/// Menggambar [image] meregang penuh mengisi ruang yang diberikan. Itu benar
/// selama pemanggil menempatkannya pada persegi yang SAMA dengan preview
/// kamera - lihat `CameraStage`, yang ada justru untuk menjamin hal itu.
///
/// Kenapa meregang penuh dan bukan menjaga rasio: mask memang dihasilkan dari
/// frame yang diregangkan ke ukuran masukan model (640x384), jadi posisi
/// relatif tiap piksel mask sama persis dengan posisi relatifnya di frame
/// kamera. Meregangkannya kembali mengembalikannya ke tempat asalnya.
class SegmentationOverlay extends StatelessWidget {
  final ui.Image? image;

  /// Ikut memudar saat jalur tidak lagi terbaca, alih-alih hilang mendadak.
  final double opacity;

  /// Sumbu jalur yang disarankan, dari `ZoneAnalysis.path`.
  ///
  /// Titiknya ternormalisasi 0..1 terhadap frame, jadi tidak perlu tahu ukuran
  /// layar. Kosong berarti tidak ada jalur, dan tidak ada garis yang digambar -
  /// menggambar garis "kira-kira" di keadaan itu justru menyarankan langkah
  /// yang tidak punya dasar.
  final List<({double x, double y, double width})> path;

  const SegmentationOverlay({
    super.key,
    required this.image,
    this.opacity = 1.0,
    this.path = const [],
  });

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SegmentationPainter(img, opacity, path),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SegmentationPainter extends CustomPainter {
  final ui.Image image;
  final double opacity;
  final List<({double x, double y, double width})> path;

  _SegmentationPainter(this.image, this.opacity, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      // Interpolasi halus: mask 160x96 diperbesar berkali-kali lipat, dan
      // tanpa penghalusan tepinya jadi bergerigi seperti kotak-kotak besar
      // alih-alih terbaca sebagai jalur.
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;
    if (opacity < 1.0) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: opacity.clamp(0.0, 1.0));
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      paint,
    );

    _gambarJalur(canvas, size);
  }

  /// Garis sumbu jalur, dari kaki ke arah jauh.
  ///
  /// Hamparan hijau menjawab "permukaan mana yang layak". Garis ini menjawab
  /// pertanyaan yang berbeda dan lebih berguna: "lewat mana". Pada trotoar
  /// yang terbelah tiang, hamparannya menunjukkan dua bidang hijau dan
  /// menyerahkan pilihan ke pembaca; garisnya menunjuk satu.
  ///
  /// Dua goresan, gelap dulu lalu terang di atasnya. Garis hijau tunggal
  /// hilang di atas rumput dan daun yang warnanya senada - dan latar itu
  /// justru yang paling sering ada di kiri-kanan trotoar.
  void _gambarJalur(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final p = Path();
    var pertama = true;
    for (final titik in path) {
      final o = Offset(titik.x * size.width, titik.y * size.height);
      if (pertama) {
        p.moveTo(o.dx, o.dy);
        pertama = false;
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }

    final a = opacity.clamp(0.0, 1.0);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = const Color(0xFF10361A).withValues(alpha: 0.55 * a),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = const Color(0xFF4CE664).withValues(alpha: a),
    );
  }

  @override
  bool shouldRepaint(_SegmentationPainter old) =>
      old.image != image || old.opacity != opacity || old.path != path;
}

/// Legenda kecil untuk menjelaskan arti warna hamparan.
///
/// Hamparan berwarna tanpa keterangan itu tebak-tebakan bagi siapa pun yang
/// baru melihat aplikasi ini - termasuk juri dan penguji. Sengaja dibungkus
/// [ExcludeSemantics]: ini murni bantuan visual, dan pembaca layar sudah
/// mendapat informasi yang sama lewat narasi suara. Membacakannya lagi hanya
/// menambah panjang antrean suara tanpa menambah informasi.
class SegmentationLegend extends StatelessWidget {
  final SegmentationPalette palette;

  const SegmentationLegend({super.key, this.palette = SegmentationPalette.standard});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.scrimText,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(AppColors.positiveFill),
              const _LegendText('Jalur'),
              const SizedBox(width: 10),
              _dot(AppColors.criticalFill),
              const _LegendText('Bahaya'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _LegendText extends StatelessWidget {
  final String text;
  const _LegendText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.onDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );
}
