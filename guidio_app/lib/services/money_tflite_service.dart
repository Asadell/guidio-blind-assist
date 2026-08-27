import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Klasifikasi nominal uang kertas rupiah - SEPENUHNYA ON-DEVICE.
///
/// Tidak pernah memanggil server. Tiga alasan yang tidak bisa ditawar:
/// transaksi tunai sering terjadi tanpa sinyal (pasar, warung), foto uang
/// tidak perlu meninggalkan perangkat, dan pengguna butuh umpan balik
/// seketika saat mengarahkan kamera.
///
/// Model: MobileNetV2 transfer learning (Stage 2, repo `vinara-money-classifier`),
/// **7 kelas**, INT8 quantized dengan I/O float32 - input 224x224x3, output
/// [1,7] softmax. Val accuracy 96,41% (Stage 2), test 95,25%.
///
/// ## Tiga hal yang HARUS cocok, dan tidak satu pun akan melempar error
///
/// Semua kesalahan di bawah ini menghasilkan angka yang tampak wajar. Tidak
/// ada exception, tidak ada yang aneh di log - hanya prediksi yang diam-diam
/// salah. Di mode uang itu berarti nominal keliru dibacakan ke pengguna
/// tunanetra, yang tidak punya cara memverifikasinya sendiri.
///
/// **1. Rentang input -1..1, BUKAN 0..255.** Preprocessing `mobilenet_v2`
/// TIDAK dipanggang ke dalam graf: di `scripts/01_train.py` normalisasi
/// `x/127.5 - 1` dilakukan di pipeline `tf.data`, di luar model.
///
/// **2. Letterbox, BUKAN peregangan.** Training memakai
/// `tf.image.resize_with_pad` (lihat `assets/models/rupiah_class_info.json`),
/// jadi rasio aspek dipertahankan dan sisanya diberi bantalan bernilai -1,0
/// setelah normalisasi. Uang kertas aspeknya sekitar 2:1; meregangkannya jadi
/// persegi memberi model proporsi yang tidak pernah dilihatnya saat training.
///
/// **3. Keluaran softmax, BUKAN logit.** Layer terakhir model Keras aslinya
/// `Dense(activation="linear")`, jadi berkas `.keras` mengeluarkan logit
/// mentah. Softmax DITAMBAHKAN saat konversi ke TFLite, dan itu wajib:
/// [confidenceThreshold] membandingkan keluaran dengan 0,85, sementara logit
/// rutin melewati angka itu bahkan saat tebakannya salah. Tanpa softmax,
/// pengaman "nominal tidak pernah ditebak" lumpuh total.
///
/// Bukti bahwa pembedaan itu bekerja, dari berkas uji `test/fixtures/money`:
/// pada `uang_10000_b.jpg` model salah menebak 2000 dengan keyakinan 0,44.
/// Angka itu jauh di bawah ambang, jadi jawabannya keluar sebagai tebakan
/// berpagar, bukan pernyataan yakin. Dengan logit angkanya 1,75 dan nominal
/// keliru itu akan dibacakan dengan penuh percaya diri.
///
/// Jadi kalau model diganti lagi: periksa ketiganya, jangan diasumsikan.
///
/// ## Aturan jawaban: SELALU menjawab, TIDAK selalu dengan nada yakin
///
/// Versi sebelumnya menolak menjawab di bawah ambang: nominalnya dibuang dan
/// yang keluar cuma instruksi "Belum yakin, dekatkan sedikit". Di atas kertas
/// itu terdengar seperti pengaman. Di lapangan justru itu yang mematikan
/// fiturnya - kasus paling biasa, uang tergeletak di meja lalu difoto sambil
/// berdiri, berakhir buntu di kartu peringatan tanpa jalan keluar, dan
/// pengguna yang tidak melihat layar tidak punya cara menebak apa yang kurang.
///
/// Sekarang [_runInference] selalu mengembalikan nominal, dan [MoneyResult.certain]
/// yang membedakan dua nada jawaban:
///
/// - `certain == true`  -> lolos gerbang, boleh dibacakan lugas ("Lima puluh
///   ribu rupiah").
/// - `certain == false` -> di bawah gerbang, WAJIB dibacakan berpagar
///   ("Sepertinya lima puluh ribu rupiah") plus ajakan mengecek ulang.
///
/// Risikonya tidak dihapus, hanya dipindah, dan itu disengaja: nominal di
/// bawah ambang memang masih bisa salah. Yang menahannya sekarang bukan diam,
/// melainkan kata "sepertinya". Lapisan atas TIDAK BOLEH mengabaikan
/// [MoneyResult.certain] - membacakan hasil berpagar dengan nada lugas
/// mengembalikan persis bahaya yang dulu ditahan oleh penolakan menjawab.
class MoneyTFLiteService {
  static final MoneyTFLiteService instance = MoneyTFLiteService._();
  MoneyTFLiteService._();

  static const String _modelAsset = 'assets/models/rupiah_classifier_int8.tflite';
  static const int _inputSize = 224;

  /// Ambang keyakinan sengaja tinggi. Precedent Seeing AI menyetel presisi
  /// pada confidence sangat tinggi justru untuk menekan false positive pada
  /// alat bantu uang.
  static const double confidenceThreshold = 0.85;

  // ── Gerbang kedua: MARGIN ke juara dua ──────────────────────────────────
  //
  // Keyakinan sendirian ternyata gerbang yang salah untuk model ini, dan
  // datanya ada di `test/money_pipeline_test.dart`:
  //
  //     fixture            benar?  keyakinan   margin
  //     5_ribu_b.png         ya       90,2%     85,5
  //     50_ribu_b.png        ya       87,5%     82,4
  //     10_ribu_b.png        ya       77,0%     67,6
  //     image copy 3.png     ya       95,3%     93,8   (folder 20rb)
  //     10_ribu_a.png        ya       61,7%     41,4
  //     50_ribu_a.png      TIDAK      73,0%     61,3   ← false positive kuat
  //     20_ribu_a.png      TIDAK      48,0%     28,9
  //
  // Model Stage 2 (INT8) memiliki distribusi softmax yang tidak terkalibrasi:
  // probabilitas sering rendah di semua kelas sekaligus. Yang tetap bisa
  // dipercaya adalah SELISIHNYA (margin). Namun margin 0.40 terlalu longgar:
  // `50_ribu_a.png` (SALAH) punya margin 61.3% dan lolos gerbang. Threshold
  // dinaikkan ke 0.50 untuk memperketat filter prediksi ambang bawah.
  //
  // Satu-satunya solusi tuntas untuk false positive non-rupiah adalah data
  // training non-rupiah yang lebih banyak di iterasi training berikutnya.
  // Threshold hanya mengatur trade-off, bukan menghilangkan akar masalahnya.
  //
  // Batasnya konkret: `non_rupiah/copy3` (BUKAN uang) disebut "Rp5.000" pada
  // keyakinan 89,1% dengan margin 84,8 - di ATAS lima jawaban yang benar.
  // Entropinya (0,52) pun jatuh persis di tengah kelompok yang benar. Tidak
  // ada ambang keyakinan, margin, maupun entropi yang memisahkannya tanpa
  // ikut membuang jawaban benar. Perbaikannya harus di training: tambahkan
  // kelas "bukan uang" (OOD) di `scripts/01_train.py` repo training.

  /// Selisih minimum antara juara satu dan juara dua.
  ///
  /// Dinaikkan 0.40 → 0.50 berdasarkan benchmark model Stage 2: nilai lama
  /// meloloskan `50_ribu_a` (salah prediksi, margin 61.3%) sebagai "yakin".
  /// Nilai 0.50 masih meloloskan semua prediksi benar dengan margin ≥ 53%.
  static const double marginThreshold = 0.50;

  /// Keyakinan minimum yang tetap wajib dipenuhi walau marginnya lebar.
  /// Menjaga kasus "semua kelas rendah tapi satu kebetulan menonjol".
  ///
  /// **0.60 TIDAK cukup, dan ini terukur.** Kenaikan 0.55 → 0.60 dilakukan
  /// untuk menutup `50_ribu_a` (prediksi SALAH "Rp10.000"), tapi kasus itu
  /// tetap lolos: keyakinannya 75,8% dan marginnya 65,6, jadi dua-duanya
  /// masih di atas gerbang 0,60/0,50. Gerbangnya naik, lubangnya tidak
  /// tertutup.
  ///
  /// Diukur atas 20 foto di `test/fixtures/rupiah_mobile/` lewat JALUR
  /// KAMERA - YUV420 kroma 4:2:0 lalu nearest neighbour, persis seperti
  /// `_prepareInput` di bawah. Ini penting: pengukuran lewat jalur JPEG
  /// (`_prepareJpeg`, bilinear, warna penuh) memberi angka yang TERLALU
  /// OPTIMISTIS - `5_ribu_a` misalnya 84,8% di jalur JPEG tapi cuma 73,4% di
  /// jalur kamera. Yang berjalan di ponsel adalah yang kedua.
  ///
  ///     kelompok                          keyakinan   margin
  ///     BENAR   20_ribuan/copy3               95,3%     93,8
  ///     BUKAN   non_rupiah/copy3              87,1%     83,2   <- bocor
  ///     BENAR   50_ribu_b                     86,3%     80,1
  ///     BENAR   5_ribu_b                      84,8%     79,7
  ///     BENAR   20_ribuan/copy                84,0%     78,1
  ///     ────────────────────────────── batas 0,80 ────────────────────
  ///     BENAR   20_ribuan/image               77,7%     69,9
  ///     BUKAN   non_rupiah/image              77,0%     63,7
  ///     BENAR   20_ribuan/copy5               74,6%     64,5
  ///     BENAR   5_ribu_a                      73,4%     66,4
  ///     BENAR   10_ribu_b                     72,7%     62,5
  ///     SALAH   50_ribu_a -> "Rp10.000"       69,9%     53,9
  ///     BENAR   10_ribu_a                     65,2%     48,4
  ///
  /// Sweep di jalur kamera memberi dua titik kerja yang sama-sama bebas
  /// jawaban salah:
  ///
  ///     minConf   benar   SALAH   bocor
  ///       0,70      8       0       2
  ///       0,80      4       0       1
  ///
  /// 0,70 memang meloloskan dua kali lipat jawaban benar, tapi jaraknya ke
  /// `50_ribu_a` (69,9%, jawaban SALAH) cuma 0,1 poin - satu frame yang
  /// sedikit berbeda sudah cukup untuk membuat aplikasi menyebut "Rp10.000"
  /// atas selembar Rp50.000. Di 0,80 jaraknya 10 poin.
  ///
  /// Jadi yang dibeli dengan 0,80 bukan angka statistik, melainkan JARAK dari
  /// tepi jurang, pada sampel yang cuma 20 gambar. Kalau nanti ada ratusan
  /// foto lapangan, titik ini layak diukur ulang - jangan diwarisi begitu
  /// saja. Ukur dengan `tool/eval_rupiah_litert.py` (bawaannya jalur kamera).
  static const double marginPathMinConfidence = 0.80;

  /// Urutan kelas sesuai `idx_to_class` di
  /// `assets/models/rupiah_class_info.json`, yang ikut diturunkan bersama
  /// model - sudah dicocokkan indeks per indeks, **jangan diubah**.
  ///
  /// Kalau model diganti, urutan ini WAJIB dicocokkan ulang: model
  /// mengeluarkan indeks, dan indeks yang dipetakan ke nominal yang salah
  /// menghasilkan jawaban yang percaya diri dan keliru - kegagalan paling
  /// mahal yang bisa dilakukan aplikasi ini.
  static const List<int> classValues = [1000, 2000, 5000, 10000, 20000, 50000, 100000];

  /// Model dilatih pada dataset gabungan Emisi 2016 & 2022 (7 pecahan lengkap).
  static const List<int> unsupportedValues = [];

  /// Inferensi dijalankan lewat [IsolateInterpreter], bukan [Interpreter]
  /// langsung, supaya tidak menahan thread UI.
  ///
  /// Ini penting bukan karena alasan estetika. Antrean suara dijadwalkan dari
  /// thread yang sama, jadi setiap milidetik yang dihabiskan interpreter di
  /// thread UI muncul sebagai TTS yang tersendat. Untuk pengguna tunanetra,
  /// suara yang patah-patah lebih merusak daripada gambar yang patah-patah,
  /// karena suara itulah satu-satunya keluaran yang mereka pakai.
  ///
  /// Tiga service inferensi lain di aplikasi ini (`tflite_service`,
  /// `yolo_navigasi_service`, `pidnet_service`) sudah memakai pola ini.
  /// Service uang tertinggal, dan itu tidak disengaja.
  IsolateInterpreter? _isolate;
  Interpreter? _interpreter;
  bool _loading = false;

  bool get isReady => _isolate != null;

  Future<bool> load() async {
    if (_isolate != null || _loading) return _isolate != null;
    _loading = true;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
      _isolate = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );
      debugPrint('[MoneyTFLite] Model siap: $_modelAsset');
      return true;
    } catch (e) {
      debugPrint('[MoneyTFLite] Gagal memuat model: $e');
      _interpreter = null;
      _isolate = null;
      return false;
    } finally {
      _loading = false;
    }
  }

  void dispose() {
    _isolate?.close();
    _isolate = null;
    _interpreter?.close();
    _interpreter = null;
  }

  /// Klasifikasi dari frame kamera YUV420.
  ///
  /// **Frame dikirim UTUH.** Versi sebelumnya hanya menganalisis 70% area
  /// tengah dengan asumsi pengguna menaruh uang pas di dalam bingkai panduan.
  /// Asumsi itu tidak berlaku untuk pengguna tunanetra: mereka tidak bisa
  /// melihat bingkai itu, jadi lembar yang sedikit bergeser kehilangan tepi -
  /// justru tempat angka nominal berada - dan model menjawab salah atau ragu
  /// tanpa satu pun tanda bahwa penyebabnya cuma framing.
  Future<MoneyResult> classifyCameraImage(CameraImage image) async {
    if (_isolate == null) {
      return const MoneyResult.unavailable();
    }
    try {
      final input = await compute(
        _prepareInput,
        _PrepareArgs(
          yPlane: image.planes[0].bytes,
          uPlane: image.planes[1].bytes,
          vPlane: image.planes[2].bytes,
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes[1].bytesPerRow,
          uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
        ),
      );
      return await _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyCameraImage error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  /// Klasifikasi dari JPEG (dipakai tombol "paksa deteksi ulang").
  ///
  /// Sama seperti jalur kamera: gambar dipakai utuh, tanpa crop.
  Future<MoneyResult> classifyJpeg(Uint8List jpegBytes) async {
    if (_isolate == null) return const MoneyResult.unavailable();
    try {
      final input = await compute(_prepareJpeg, _JpegArgs(bytes: jpegBytes));
      return await _runInference(input);
    } catch (e) {
      debugPrint('[MoneyTFLite] classifyJpeg error: $e');
      return const MoneyResult.failure('Gagal membaca gambar. Coba lagi.');
    }
  }

  Future<MoneyResult> _runInference(Float32List input) async {
    final output = List.generate(1, (_) => List<double>.filled(classValues.length, 0));

    // Tensor dikirim sebagai VIEW Uint8List di atas buffer Float32List yang
    // sama, bukan sebagai Float32List itu sendiri. Tidak ada penyalinan: yang
    // berubah cuma tipe statis yang dilihat tflite_flutter.
    //
    // Alasannya ada di `Tensor.getInputShapeIfDifferent`, yang hanya
    // mengecualikan `ByteBuffer` dan `Uint8List` dari penyimpulan bentuk.
    // Buffer datar bertipe lain akan disimpulkan berbentuk [150528], lalu
    // tensor masukan di-resize dan model gagal: "Node number 108 (CONV_2D)
    // failed to prepare".
    //
    // Yang berbahaya: lewat IsolateInterpreter kegagalan itu TIDAK melempar
    // apa pun. Tensor keluaran cuma tidak pernah ditulis, jadi `output` tetap
    // berisi nol dan setiap pecahan terbaca sebagai Rp1.000 dengan keyakinan
    // 0%. Persis jenis kegagalan diam-diam yang membuat mode uang berbahaya.
    await _isolate!.runForMultipleInputs(
      [input.buffer.asUint8List()],
      {0: output},
    );
    final probs = output[0];

    var bestIndex = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIndex]) bestIndex = i;
    }
    final confidence = probs[bestIndex];

    // Margin ke juara dua. Lihat catatan panjang di [marginThreshold].
    var runnerUp = 0.0;
    for (var i = 0; i < probs.length; i++) {
      if (i != bestIndex && probs[i] > runnerUp) runnerUp = probs[i];
    }
    final margin = confidence - runnerUp;

    final passesConfidence = confidence >= confidenceThreshold;
    final passesMargin =
        margin >= marginThreshold && confidence >= marginPathMinConfidence;

    // Gerbang ini TIDAK LAGI menahan jawaban, hanya menentukan nadanya.
    // Lihat catatan panjang di dokumentasi kelas: menahan jawaban membuat
    // mode ini buntu pada kasus pemakaian yang paling umum.
    return MoneyResult.detected(
      valueIdr: classValues[bestIndex],
      confidence: confidence,
      certain: passesConfidence || passesMargin,
      probabilities: List.unmodifiable(probs),
      margin: margin,
    );
  }
}

/// Hasil klasifikasi.
///
/// `detected == false` sekarang HANYA berarti tidak ada hasil sama sekali -
/// model belum siap, atau frame-nya gagal dibaca. Keraguan model TIDAK lagi
/// muncul sebagai `detected == false`; itu dibawa oleh [certain].
class MoneyResult {
  final bool detected;
  final int? valueIdr;
  final double confidence;
  final MoneyFailure? failure;
  final String? message;

  /// Nominalnya lolos gerbang keyakinan atau tidak.
  ///
  /// `false` berarti angkanya tetap ada dan tetap boleh disampaikan, tapi
  /// WAJIB berpagar ("sepertinya") dan tidak boleh dibacakan seolah pasti.
  /// Ini satu-satunya pembeda antara jawaban yang bisa dipegang dan tebakan
  /// terbaik model, jadi mengabaikannya di lapisan UI sama saja menghapus
  /// pengamannya.
  final bool certain;

  /// Nominal dengan probabilitas TERTINGGI. Sekarang selalu sama dengan
  /// [valueIdr]; dipertahankan karena suite uji memakainya untuk memisahkan
  /// "argmax benar" dari "argmax benar DAN yakin" - dua kondisi yang butuh
  /// perbaikan sangat berbeda, dan menyamakannya membuat test lolos terus.
  final int? topValueIdr;

  /// Distribusi softmax lengkap, urutannya sesuai
  /// [MoneyTFLiteService.classValues]. Dipakai pengujian untuk menghitung
  /// margin ke juara dua - top-1 saja tidak bisa membedakan model yang
  /// bekerja dari model yang sedang menebak di antara 7 kelas.
  final List<double>? probabilities;

  /// Selisih probabilitas juara satu ke juara dua. Null kalau tidak dihitung.
  final double? margin;

  /// Nominal terbaca. [certain] menentukan nada penyampaiannya, BUKAN boleh
  /// atau tidaknya angka itu disampaikan.
  const MoneyResult.detected({
    required int this.valueIdr,
    required this.confidence,
    required this.certain,
    this.probabilities,
    this.margin,
  })  : detected = true,
        failure = null,
        message = null,
        topValueIdr = valueIdr;

  const MoneyResult.unavailable()
      : detected = false,
        valueIdr = null,
        confidence = 0,
        certain = false,
        topValueIdr = null,
        probabilities = null,
        margin = null,
        failure = MoneyFailure.modelUnavailable,
        message = 'Model pengenalan uang belum siap.';

  const MoneyResult.failure(this.message)
      : detected = false,
        valueIdr = null,
        confidence = 0,
        certain = false,
        topValueIdr = null,
        probabilities = null,
        margin = null,
        failure = MoneyFailure.error;
}

/// `lowConfidence` sengaja DIHAPUS. Keraguan model bukan lagi kegagalan yang
/// menghentikan jawaban - itu sekarang dibawa oleh [MoneyResult.certain].
/// Yang tersisa di sini murni kondisi "tidak ada hasil sama sekali".
enum MoneyFailure { modelUnavailable, error }

// ── Preprocessing di isolate ────────────────────────────────────────────
// Konversi + resize dilakukan lewat `compute()` supaya UI thread
// tidak tersendat: pengguna sering memakai mode ini sambil berdiri di
// kasir, jadi layar harus tetap responsif.

class _PrepareArgs {
  final Uint8List yPlane, uPlane, vPlane;
  final int width, height, yRowStride, uvRowStride, uvPixelStride;

  const _PrepareArgs({
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });
}

class _JpegArgs {
  final Uint8List bytes;
  const _JpegArgs({required this.bytes});
}

const int _size = MoneyTFLiteService._inputSize;

/// Nilai piksel untuk area bantalan, SETELAH normalisasi.
///
/// Dipakai lewat `Float32List.fillRange` sebelum kotak gambar ditimpa.
/// Float32List lahir berisi 0,0, jadi langkah pengisian itu tidak bisa
/// dilewati: 0,0 berarti abu-abu tengah, bukan hitam.
///
/// Training memakai `tf.image.resize_with_pad`, yang mengisi bantalan dengan
/// 0 pada rentang mentah [0,255]. Setelah `x/127.5 - 1` itu jadi -1,0. Nilai
/// inilah yang harus dipakai di sini - mengisi bantalan dengan 0,0 (abu-abu
/// tengah) memberi model bingkai yang tidak pernah dilihatnya saat training.
const double _padValue = -1.0;

/// Geometri letterbox: skala dan offset untuk memasukkan [srcW]x[srcH] ke
/// dalam kotak [_size]x[_size] tanpa mengubah rasio aspek.
class _Letterbox {
  final double scale;
  final int padX;
  final int padY;
  final int dstW;
  final int dstH;

  factory _Letterbox(int srcW, int srcH) {
    final scale = math.min(_size / srcW, _size / srcH);
    final dstW = math.max(1, (srcW * scale).round());
    final dstH = math.max(1, (srcH * scale).round());
    return _Letterbox._(
      scale: scale,
      dstW: dstW,
      dstH: dstH,
      padX: (_size - dstW) ~/ 2,
      padY: (_size - dstH) ~/ 2,
    );
  }

  const _Letterbox._({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.dstW,
    required this.dstH,
  });

  bool contains(int tx, int ty) =>
      tx >= padX && tx < padX + dstW && ty >= padY && ty < padY + dstH;

  int srcX(int tx) => ((tx - padX) / scale).floor();
  int srcY(int ty) => ((ty - padY) / scale).floor();
}

/// Sampling langsung ke grid 224x224 dari SELURUH frame - piksel yang
/// diproses tetap 224x224 berapa pun resolusi sumbernya, jadi tidak ada
/// biaya konversi frame penuh lalu me-resize.
///
/// **Memakai letterbox, bukan peregangan.** Model dilatih dengan
/// `tf.image.resize_with_pad` (lihat `rupiah_class_info.json`), jadi rasio
/// aspek dipertahankan dan sisanya diberi bantalan. Versi sebelumnya
/// meregangkan frame 4:3 menjadi 1:1 - uang kertas yang aspeknya sekitar
/// 2:1 masuk ke model dalam proporsi yang tidak pernah dilihatnya saat
/// training.
///
/// Kesalahan seperti ini tidak memunculkan error apa pun. Interpreter tetap
/// menerima tensornya, hanya prediksinya yang diam-diam memburuk - dan di
/// mode uang itu berarti nominal keliru dibacakan ke pengguna tunanetra.
Float32List _prepareInput(_PrepareArgs a) {
  final out = Float32List(_size * _size * 3);
  final lb = _Letterbox(a.width, a.height);
  final yLen = a.yPlane.length;
  final uLen = a.uPlane.length;
  final vLen = a.vPlane.length;

  // Bantalan diisi lebih dulu, lalu hanya kotak dalamnya yang ditimpa.
  // Float32List lahir berisi 0,0 dan bantalan harus -1,0, jadi pengisian
  // ini wajib; melewatkannya memberi model bingkai abu-abu yang tidak
  // pernah dilihatnya saat training.
  out.fillRange(0, out.length, _padValue);

  var o = (lb.padY * _size + lb.padX) * 3;
  final rowSkip = (_size - lb.dstW) * 3;

  for (int ty = 0; ty < lb.dstH; ty++) {
    final sy = (ty / lb.scale).floor().clamp(0, a.height - 1);
    final yRow = sy * a.yRowStride;
    final uvRow = (sy >> 1) * a.uvRowStride;

    for (int tx = 0; tx < lb.dstW; tx++) {
      final sx = (tx / lb.scale).floor().clamp(0, a.width - 1);

      final yIdx = yRow + sx;
      final uvIdx = uvRow + (sx >> 1) * a.uvPixelStride;

      final yVal = yIdx < yLen ? a.yPlane[yIdx] & 0xFF : 0;
      final uVal = (uvIdx < uLen ? a.uPlane[uvIdx] & 0xFF : 128) - 128;
      final vVal = (uvIdx < vLen ? a.vPlane[uvIdx] & 0xFF : 128) - 128;

      // Normalisasi ke [-1, 1]. Praproses mobilenet_v2 TIDAK ada di dalam
      // graf model ini, jadi harus dikerjakan di sini.
      out[o++] = ((yVal + 1.402 * vVal).clamp(0, 255)) / 127.5 - 1.0;
      out[o++] = ((yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255)) / 127.5 - 1.0;
      out[o++] = ((yVal + 1.772 * uVal).clamp(0, 255)) / 127.5 - 1.0;
    }
    o += rowSkip;
  }
  return out;
}

Float32List _prepareJpeg(_JpegArgs a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) {
    throw StateError('JPEG tidak bisa dibaca');
  }

  // TANPA CROP, sama seperti jalur kamera - dua jalur ini harus melihat
  // area yang identik. Kalau salah satunya memotong dan yang lain tidak,
  // "paksa deteksi ulang" bisa menjawab lain dari deteksi langsung pada
  // lembar yang sama. Kegagalan seperti itu mustahil didiagnosis dari
  // lapangan: pengguna cuma tahu aplikasinya "kadang benar kadang tidak".
  final lb = _Letterbox(decoded.width, decoded.height);
  final resized = img.copyResize(
    decoded,
    width: lb.dstW,
    height: lb.dstH,
    interpolation: img.Interpolation.linear,
  );
  final out = Float32List(_size * _size * 3);
  out.fillRange(0, out.length, _padValue);

  var o = (lb.padY * _size + lb.padX) * 3;
  final rowSkip = (_size - lb.dstW) * 3;

  for (int y = 0; y < lb.dstH; y++) {
    for (int x = 0; x < lb.dstW; x++) {
      final p = resized.getPixel(x, y);
      out[o++] = p.r / 127.5 - 1.0;
      out[o++] = p.g / 127.5 - 1.0;
      out[o++] = p.b / 127.5 - 1.0;
    }
    o += rowSkip;
  }
  return out;
}
