import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'luma_contrast.dart';

/// Satu blok teks hasil pengenalan, sudah diurutkan sesuai urutan baca.
@immutable
class OcrTextBlock {
  final String heading;
  final List<String> sentences;

  /// Perkiraan jumlah kata - dipakai BT-08 untuk menghitung durasi bacaan
  /// sebelum mulai, supaya tawaran "ringkas / penuh / pilih bagian" muncul
  /// sebelum pengguna terjebak mendengarkan tiga menit teks.
  final int wordCount;

  const OcrTextBlock({
    required this.heading,
    required this.sentences,
    required this.wordCount,
  });
}

@immutable
class OcrResult {
  final List<OcrTextBlock> blocks;
  final String fullText;

  const OcrResult({required this.blocks, required this.fullText});

  bool get isEmpty => fullText.trim().isEmpty;
  int get totalWords => blocks.fold(0, (sum, b) => sum + b.wordCount);

  /// BT-08 - perkiraan durasi baca. ~150 kata per menit adalah laju TTS
  /// Bahasa Indonesia yang wajar pada kecepatan bawaan.
  Duration get estimatedDuration =>
      Duration(seconds: (totalWords / 150 * 60).round());
}

/// Pengenalan teks **sepenuhnya di perangkat** lewat ML Kit.
///
/// Ini menggantikan OCR di server. Tiga akibat langsung, semuanya perbaikan:
///
/// 1. **Baca Teks jalan tanpa internet.** BT-02 ("tombol nonaktif + alasan")
///    tidak berlaku lagi - tidak ada alasan menonaktifkan tombol untuk kerja
///    yang tidak butuh jaringan sama sekali.
/// 2. **Tidak ada gambar yang meninggalkan perangkat.** Foto dokumen, resep,
///    surat - semuanya tetap di ponsel.
/// 3. **Hasil datang dalam ratusan milidetik**, bukan detik. BT-05 (banner
///    lambat 8 detik) dan BT-15 (timeout 15 detik) praktis tidak pernah kena.
///
/// Yang hilang: ML Kit tidak melakukan koreksi berbasis LLM, jadi teks
/// bersudut miring atau tulisan tangan lebih sering meleset daripada OCR
/// server. Untuk menu, label harga, dan papan nama - kasus pemakaian utama
/// mode ini - itu pertukaran yang menguntungkan.
class OcrService {
  static final OcrService instance = OcrService._();
  OcrService._();

  TextRecognizer? _recognizer;

  TextRecognizer get _engine =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Mengenali teks dari berkas gambar hasil `takePicture`.
  ///
  /// ML Kit membaca langsung dari path berkas, jadi byte-nya **tidak perlu**
  /// dibaca ke memori Dart lebih dulu - untuk foto 4 MP itu menghemat satu
  /// salinan besar yang tidak ada gunanya. `InputImage.fromFilePath` juga
  /// mengurus orientasi EXIF sendiri, yang tidak dilakukan `fromBytes`.
  ///
  /// [boostContrast] menyalakan perbaikan kontras selektif sebelum gambar
  /// diserahkan ke ML Kit. Lihat [_boostIfHazy] soal kapan itu berguna dan
  /// kapan justru merugikan.
  Future<OcrResult> recognizeFile(String imagePath, {bool boostContrast = true}) async {
    final path = boostContrast ? await _boostIfHazy(imagePath) : imagePath;
    try {
      final input = InputImage.fromFilePath(path);
      final recognized = await _engine.processImage(input);
      return _toResult(recognized);
    } finally {
      // Berkas hasil perbaikan adalah salinan sementara. Menumpuknya di
      // penyimpanan akan memperburuk kondisi yang sudah dikeluhkan BT-21.
      if (path != imagePath) {
        try {
          final tmp = File(path);
          if (await tmp.exists()) await tmp.delete();
        } catch (_) {
          // Gagal membersihkan berkas sementara tidak boleh menggagalkan
          // pembacaan yang sudah berhasil.
        }
      }
    }
  }

  /// Regangkan kontras HANYA kalau fotonya memang berkabut.
  ///
  /// Kamera ponsel berumur kehilangan kontras karena veiling glare, dan huruf
  /// kecil adalah yang pertama hilang: tepinya melebur ke latar sebelum ML Kit
  /// sempat melihatnya. Terukur pada Samsung A30s lima tahun di repo ini,
  /// titik hitamnya naik dari 9 ke 50 dan rentang dinamisnya turun dari 220 ke
  /// sekitar 160.
  ///
  /// Gerbangnya penting, bukan sekadar hemat: memperbaiki foto yang sudah
  /// jernih menambahkan distorsi alih-alih perbaikan. Logika dan ambangnya
  /// dipakai bersama jalur navigasi lewat [measureLumaStretch], jadi kedua
  /// mode tidak pernah punya dua definisi "berkabut" yang berbeda.
  ///
  /// Mengembalikan path asli kalau tidak ada yang perlu diperbaiki.
  Future<String> _boostIfHazy(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath;

      // Luma disusun sekali, dipakai untuk mengukur sekaligus jadi dasar
      // keputusan. `measureLumaStretch` menyampel jarang, jadi biayanya tetap
      // kecil walau fotonya beresolusi penuh.
      final luma = Uint8List(decoded.width * decoded.height);
      var i = 0;
      for (final px in decoded) {
        luma[i++] = px.luminance.toInt().clamp(0, 255);
      }
      final stretch = measureLumaStretch(luma);
      if (stretch == null) return imagePath;

      for (final px in decoded) {
        px
          ..r = ((px.r - stretch.lo) * stretch.gain).clamp(0, 255)
          ..g = ((px.g - stretch.lo) * stretch.gain).clamp(0, 255)
          ..b = ((px.b - stretch.lo) * stretch.gain).clamp(0, 255);
      }

      final out = File('${Directory.systemTemp.path}/vinara_ocr_boost_'
          '${DateTime.now().microsecondsSinceEpoch}.jpg');
      await out.writeAsBytes(img.encodeJpg(decoded, quality: 92), flush: true);
      debugPrint('[OCR] kontras diperbaiki (lo=${stretch.lo.toStringAsFixed(0)}, '
          'gain=${stretch.gain.toStringAsFixed(2)})');
      return out.path;
    } catch (e) {
      // Perbaikan kontras adalah bonus, bukan syarat. Kalau gagal, baca saja
      // foto aslinya - jauh lebih baik daripada tidak membaca sama sekali.
      debugPrint('[OCR] perbaikan kontras dilewati: $e');
      return imagePath;
    }
  }

  /// Varian untuk byte yang sudah ada di memori. Menulis berkas sementara
  /// karena `InputImage.fromBytes` menuntut metadata format yang tidak kita
  /// punya untuk JPEG sembarang.
  Future<OcrResult> recognizeBytes(Uint8List jpeg) async {
    final dir = Directory.systemTemp;
    final file = await File(
      '${dir.path}/vinara_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).writeAsBytes(jpeg, flush: true);
    try {
      return await recognizeFile(file.path);
    } finally {
      // Foto tidak ditinggalkan di penyimpanan - BT-21 mengeluh soal ruang,
      // dan menumpuk berkas sementara akan memperburuknya.
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  OcrResult _toResult(RecognizedText recognized) {
    final blocks = <OcrTextBlock>[];

    for (final block in recognized.blocks) {
      final lines = block.lines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).toList();
      if (lines.isEmpty) continue;

      // ML Kit sudah mengelompokkan teks jadi blok berdasarkan tata letak.
      // Baris pertama tiap blok dipakai sebagai heading - itu yang membuat
      // ResultPanel/long punya heading nyata, bukan satu blok "Hasil baca"
      // untuk seluruh halaman seperti waktu memakai OCR server.
      final heading = _asHeading(lines.first);
      final body = lines.length > 1 ? lines.sublist(1) : lines;
      final sentences = _splitSentences(body.join(' '));

      blocks.add(OcrTextBlock(
        heading: heading,
        sentences: sentences,
        wordCount: sentences.fold(0, (n, s) => n + s.split(RegExp(r'\s+')).length),
      ));
    }

    return OcrResult(blocks: blocks, fullText: recognized.text);
  }

  /// Heading dipotong supaya tetap satu baris saat dibacakan sebagai penanda
  /// bagian; teks utuhnya tetap ada di dalam kalimat blok.
  String _asHeading(String line) {
    final clean = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 42) return clean;
    return '${clean.substring(0, 39)}…';
  }

  List<String> _splitSentences(String text) => text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
