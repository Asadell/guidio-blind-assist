import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Preview kamera beserta hamparan-hamparannya, dalam SATU persegi.
///
/// ## Kenapa widget ini ada
///
/// Sebelumnya preview dipasang sebagai `Positioned.fill(child: CameraPreview(…))`
/// di dalam `Stack`. Yang tidak kentara: `CameraPreview` membungkus dirinya
/// dalam `AspectRatio`, jadi di dalam `Positioned.fill` dia TIDAK mengisi
/// seluruh persegi - dia mengecil sampai muat sambil menjaga rasio, dan
/// menyisakan pita kosong di atas-bawah atau kiri-kanan.
///
/// Selama tidak ada yang digambar di atasnya, itu tidak jadi soal. Begitu ada
/// kotak deteksi, jadi soal besar: hamparan yang memakai `Positioned.fill`
/// akan memetakan koordinatnya ke SELURUH persegi termasuk pita kosong,
/// sementara gambar kameranya cuma menempati sebagian. Hasilnya setiap kotak
/// bergeser dan meleset dari objeknya, makin parah makin beda rasio layar
/// dengan rasio kamera.
///
/// Yang membuatnya sulit dilacak: di satu HP bisa kelihatan hampir pas, di HP
/// lain meleset jauh - dan tidak ada error di mana pun.
///
/// Widget ini menaruh preview dan hamparan di dalam `AspectRatio` yang SAMA,
/// jadi keduanya selalu berbagi persegi yang identik. Penyelarasannya jadi
/// benar karena strukturnya, bukan karena perhitungan yang harus dijaga
/// konsisten di dua tempat.
class CameraStage extends StatelessWidget {
  final CameraController controller;

  /// Digambar di atas preview, berbagi persegi yang sama persis.
  /// Urutannya urutan gambar: yang belakang menimpa yang depan.
  final List<Widget> overlays;

  /// Ditumpuk mengisi seluruh layar, DI LUAR persegi preview.
  ///
  /// Untuk elemen antarmuka yang memang milik layar, bukan milik gambar
  /// kamera: banner, kartu, tombol. Kalau ini ikut dimasukkan ke [overlays],
  /// posisinya akan ikut menciut mengikuti rasio kamera.
  final List<Widget> children;

  const CameraStage({
    super.key,
    required this.controller,
    this.overlays = const [],
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.cameraVoid),
        Center(
          child: AspectRatio(
            // Rasio yang dipakai `CameraPreview` sendiri saat potret.
            // `controller.value.aspectRatio` dilaporkan dalam orientasi
            // sensor (lanskap), jadi dibalik untuk bingkai tegak.
            aspectRatio: _uprightAspect,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                // ExcludeSemantics: hamparan ini murni bantuan visual.
                // Pengguna tunanetra sudah menerima informasi yang sama lewat
                // narasi suara; membacakannya lagi hanya memperpanjang
                // antrean suara tanpa menambah satu pun informasi baru.
                for (final o in overlays) ExcludeSemantics(child: o),
              ],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  double get _uprightAspect => uprightAspectOf(controller.value.aspectRatio);

  /// Rasio bingkai tegak dari rasio yang dilaporkan controller.
  ///
  /// Dipisah jadi fungsi murni supaya bisa diuji tanpa perangkat: inilah satu
  /// angka yang menentukan apakah kotak deteksi jatuh di tempat yang benar,
  /// dan salah di sini tidak memunculkan error apa pun - kotaknya tetap
  /// tergambar, cuma meleset.
  ///
  /// `CameraController.value.aspectRatio` dilaporkan dalam orientasi SENSOR,
  /// yang pada ponsel selalu lanskap (mis. 4/3 = 1,33). Preview potret
  /// memakai kebalikannya. Nilai yang sudah < 1 dibiarkan apa adanya supaya
  /// perangkat yang melaporkan potret tidak ikut dibalik jadi lanskap.
  static double uprightAspectOf(double sensorAspect) {
    if (sensorAspect <= 0 || !sensorAspect.isFinite) return 3 / 4;
    return sensorAspect > 1 ? 1 / sensorAspect : sensorAspect;
  }
}
