import 'dart:typed_data';

/// Perbaikan kontras selektif untuk kamera ponsel yang sudah berumur.
///
/// Kamera ponsel berumur kehilangan kontras karena veiling glare: cahaya
/// menyebar di dalam lensa yang sudah tergores dan berdebu, lalu mengangkat
/// titik hitam. Diukur pada foto Samsung A30s berusia lima tahun di repo ini:
///
///     kamera sehat   p2 =  9   p98 = 231   rentang 220
///     A30s           p2 = 50   p98 = 212   rentang 162
///
/// Tidak ada piksel yang benar-benar hitam. Seluruh histogram terdorong ke
/// tengah, dan tepi objek yang dipakai detektor jadi tipis.
///
/// ## Kenapa SELEKTIF, bukan selalu
///
/// Godaannya memasang perbaikan ini di semua frame. Riset menunjukkan itu
/// justru merugikan: model yang menerima citra sudah jernih lalu "diperbaiki"
/// menerima distorsi, bukan perbaikan ("From Fog to Failure", arXiv 2502.02027).
///
/// Diukur di repo ini juga: pada lima foto kamera sehat, gerbang melewatkan
/// kelimanya dan skor deteksi tidak berubah sama sekali. Itulah gunanya
/// gerbang - perbaikan yang tidak pernah menyentuh frame yang tidak
/// membutuhkannya.
///
/// ## Kenapa peregangan titik hitam, bukan CLAHE
///
/// CLAHE bekerja per ubin dan butuh histogram per ubin. Fungsi ini sudah berupa
/// pemetaan indeks satu lintasan tanpa satu pun gambar antara; menyisipkan
/// CLAHE berarti membongkar seluruhnya dan mengalokasikan buffer tiap frame -
/// persis yang paling mahal di ponsel lama yang justru jadi sasarannya.
///
/// Peregangan linier cuma butuh dua angka dan satu perkalian per piksel, dan
/// biayanya satu lintasan jarang atas bidang luma yang sudah ada di memori.

/// Di bawah rentang ini, frame dianggap berkabut dan layak diperbaiki.
/// 190 duduk di antara dua kelompok terukur di atas (162 lawan 220).
const int kLowContrastRange = 190;

/// Persentil pemotongan, dalam perseribu. 2% dan 98%, bukan 0 dan 100, supaya
/// satu piksel nyasar (pantulan lampu, sensor mati) tidak menentukan seluruh
/// pemetaan.
const double kClipLoFrac = 0.02;
const double kClipHiFrac = 0.98;

/// Jumlah sampel luma untuk menaksir histogram. Cukup kasar: yang dibutuhkan
/// cuma dua titik potong, bukan histogram yang presisi.
const int kContrastSamples = 4096;

/// Hitung peregangan kontras untuk satu frame, atau null kalau tidak perlu.
///
/// Mengembalikan `(lo, gain)` sehingga `nilai_baru = (nilai_lama - lo) * gain`.
({double lo, double gain})? measureLumaStretch(Uint8List yPlane) {
  final len = yPlane.length;
  if (len < 256) return null;

  final hist = Int32List(256);
  final step = (len ~/ kContrastSamples).clamp(1, len);
  var n = 0;
  for (var i = 0; i < len; i += step) {
    hist[yPlane[i]]++;
    n++;
  }
  if (n < 64) return null;

  final loTarget = (n * kClipLoFrac).floor();
  final hiTarget = (n * kClipHiFrac).ceil();

  var cum = 0;
  var lo = 0;
  var hi = 255;
  for (var v = 0; v < 256; v++) {
    cum += hist[v];
    if (cum > loTarget) { lo = v; break; }
  }
  cum = 0;
  for (var v = 0; v < 256; v++) {
    cum += hist[v];
    if (cum >= hiTarget) { hi = v; break; }
  }

  // Frame yang kontrasnya sudah sehat dilewatkan apa adanya. Ini gerbangnya.
  if (hi - lo >= kLowContrastRange) return null;
  // Frame yang nyaris rata (lensa tertutup, gelap total) tidak diregangkan:
  // mengalikan derau dengan faktor besar cuma menghasilkan derau yang besar,
  // dan kondisi itu sudah ditangani penjaga gelap di CameraProvider.
  if (hi - lo < 24) return null;

  return (lo: lo.toDouble(), gain: 255.0 / (hi - lo));
}

