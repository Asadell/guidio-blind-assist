import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../widgets/zone_indicator.dart' show ZoneStatus;

// ─────────────────────────────────────────────────────────────
// Hasil segmentasi 3 zona dari PIDNet-S
// ─────────────────────────────────────────────────────────────
/// Kenapa satu frame TIDAK bisa dipercaya sebagai pemandangan jalur.
///
/// PIDNet selalu mengeluarkan jawaban. Diarahkan ke tembok polos, langit,
/// langit-langit kamar, atau bagian dalam saku, dia tetap memberi label ke
/// setiap piksel - dan sebagian besarnya bisa jatuh ke "walkable". Dari sana
/// rasio zona terbaca "tengah 100% layak jalan" dan aplikasi mengucapkan
/// "Jalur aman, jalan lurus" untuk foto langit-langit.
///
/// Ini kelas kesalahan yang sama dengan halusinasi VLM di endpoint deskripsi:
/// modelnya tidak pernah berkata "saya tidak bisa melihat", dia menghasilkan
/// jawaban yang terdengar meyakinkan apa pun masukannya. Bedanya, di sini
/// jawabannya adalah perintah berjalan maju kepada orang yang tidak bisa
/// memverifikasi sendiri.
enum SceneDoubt {
  /// Pemandangan wajar, arahan boleh diucapkan.
  none,

  /// Hampir seluruh frame satu kelas. Tembok, langit, aspal polos tanpa tepi,
  /// atau lensa tertutup - bukan pemandangan berjalan yang punya struktur.
  degenerate,

  /// Ada jalur terdeteksi, tapi TIDAK di bagian bawah frame.
  ///
  /// Pada pemandangan berjalan yang benar, permukaan tepat di depan kaki
  /// selalu ada di pita bawah. Kalau pita bawah kosong sementara bagian atas
  /// penuh "walkable", kamera kemungkinan menghadap ke atas - dan jalur yang
  /// "ditemukan" itu bukan yang akan diinjak.
  notGrounded,
}

/// Satu ruas jalur yang bisa dilewati, di satu kedalaman.
///
/// Koordinatnya ternormalisasi 0..1 terhadap frame model, jadi lapisan gambar
/// bisa memakainya langsung berapa pun ukuran layarnya.
class PathPoint {
  /// Titik tengah jalur secara horizontal. 0 = tepi kiri, 1 = tepi kanan.
  final double x;

  /// Kedalaman. 1 = tepat di depan kaki, mengecil ke arah kejauhan.
  final double y;

  /// Lebar jalur di kedalaman ini, sebagai pecahan lebar frame.
  final double width;

  const PathPoint({required this.x, required this.y, required this.width});
}

class ZoneAnalysis {
  /// Rasio piksel walkable (0.0 – 1.0) per zona.
  final double leftRatio;
  final double centerRatio;
  final double rightRatio;

  /// Status per zona berdasarkan threshold.
  final ZoneStatus left;
  final ZoneStatus center;
  final ZoneStatus right;

  /// Indeks zona yang direkomendasikan (0=kiri, 1=tengah, 2=kanan).
  final int recommendedZone;

  /// Sumbu jalur yang bisa dilewati, dari yang terdekat ke kaki ke arah jauh.
  ///
  /// Kosong berarti tidak ada ruas layak jalan yang cukup lebar di pita bawah -
  /// itulah satu-satunya kondisi yang benar-benar berarti "berhenti".
  ///
  /// Ini yang membuat mode ini bisa MENYARANKAN, bukan cuma menilai. Tiga
  /// rasio zona hanya bisa bilang "kanan buruk"; sumbu jalur bisa bilang
  /// "jalurnya menikung ke kiri di depan tiang itu", dan itu yang sebenarnya
  /// dibutuhkan orang yang sedang berjalan.
  final List<PathPoint> path;

  /// Pergeseran yang disarankan, -1 (mepet kiri) sampai +1 (mepet kanan).
  ///
  /// Selisih antara posisi jalur beberapa langkah di depan dan posisi jalur
  /// tepat di depan kaki. Nol berarti jalurnya lurus.
  final double pathShift;

  /// Waktu inference dalam milidetik.
  final double inferenceMs;

  /// Mask kelas per-piksel yang sudah dikecilkan, ukuran
  /// [maskWidth] x [maskHeight], satu byte per piksel berisi 0, 1, atau 2
  /// (non-walkable / walkable / hazard).
  ///
  /// Inilah yang digambar sebagai hamparan jalur di layar. Sebelumnya mask
  /// dihitung penuh lalu dibuang begitu rasio zonanya selesai dihitung -
  /// pekerjaan terberat di pipeline ini dikerjakan lalu hasilnya tidak
  /// dipakai untuk apa pun selain tiga angka.
  ///
  /// `null` kalau pemanggil meminta tanpa mask (lihat `analyze(withMask:)`),
  /// supaya jalur yang cuma butuh arahan suara tidak membayar salinannya.
  final Uint8List? mask;
  final int maskWidth;
  final int maskHeight;

  /// Apakah frame ini layak dijadikan dasar arahan berjalan.
  ///
  /// Dihitung dari mask penuh, jadi tidak menambah inferensi apa pun.
  final SceneDoubt doubt;

  /// True kalau arahan zona TIDAK boleh diucapkan sebagai fakta.
  ///
  /// Peringatan rintangan dari YOLO tetap harus lewat: kalau ada motor
  /// mendekat, pengguna perlu tahu terlepas dari apakah jalurnya terbaca.
  bool get isUntrustworthy => doubt != SceneDoubt.none;

  const ZoneAnalysis({
    required this.leftRatio,
    required this.centerRatio,
    required this.rightRatio,
    required this.left,
    required this.center,
    required this.right,
    required this.recommendedZone,
    required this.inferenceMs,
    this.path = const [],
    this.pathShift = 0,
    this.doubt = SceneDoubt.none,
    this.mask,
    this.maskWidth = 0,
    this.maskHeight = 0,
  });

  /// Arahan suara. SELALU menyebut ke mana harus melangkah kalau masih ada
  /// jalur, bukan cuma menilai apa yang di depan.
  ///
  /// Versi sebelumnya berhenti di "Jalur di depan tidak aman." dan diam soal
  /// jalan keluarnya. Untuk pengguna awas kalimat itu cukup, karena dia
  /// melihat sendiri bahwa sebelah kirinya kosong. Pengguna tunanetra tidak
  /// punya sumber kedua: kalimat yang cuma melarang membuatnya berhenti tanpa
  /// tahu harus bagaimana, dan berhenti di tengah trotoar bukan keadaan aman.
  ///
  /// Karena itu "berhenti" sekarang hanya diucapkan kalau [path] benar-benar
  /// kosong - tidak ada satu pun ruas layak jalan yang cukup lebar di pita
  /// bawah. Selama masih ada ruas, yang keluar adalah arah.
  String get ttsMessage {
    if (path.isEmpty) {
      return 'Berhenti dulu. Tidak ada jalur aman di sekitar sini.';
    }

    // Ambang 0,12 kira-kira seperlima lebar jalur pada trotoar biasa: cukup
    // besar untuk berarti "geser", cukup kecil untuk tidak menyuruh pengguna
    // bergerak setiap kali sumbu jalur bergoyang satu piksel.
    if (pathShift <= -0.12) {
      return center == ZoneStatus.danger
          ? 'Jalur di depan tertutup. Ambil sebelah kiri.'
          : 'Agak ke kiri.';
    }
    if (pathShift >= 0.12) {
      return center == ZoneStatus.danger
          ? 'Jalur di depan tertutup. Ambil sebelah kanan.'
          : 'Agak ke kanan.';
    }
    return 'Jalur aman, jalan lurus.';
  }

  ZoneStatus get recommendedStatus => switch (recommendedZone) {
        0 => left,
        2 => right,
        _ => center,
      };
}

// ─────────────────────────────────────────────────────────────
// Konfigurasi PIDNet-S
// ─────────────────────────────────────────────────────────────

// Dimensi input model: H=384, W=640 (sesuai training)
const int _pidnetH = 384;
const int _pidnetW = 640;

// Kelas output: 0=non-walkable, 1=walkable/trotoar, 2=hazard
// Urutannya dari `SEG_NON_WALKABLE, SEG_WALKABLE, SEG_HAZARD = 0, 1, 2`
// di `src/pidnet/dataset.py` repo training - jangan diubah tanpa mengubah
// training-nya juga.
// Hanya kelas 1 (walkable) yang dihitung untuk rasio zona.
const int _classWalkable = 1;

// ── Ambang kelayakan pemandangan ────────────────────────────────────────────
//
// Angka-angka ini TITIK AWAL, bukan hasil optimasi. Sengaja dibuat longgar:
// menolak terlalu sering di mode navigasi jauh lebih merugikan daripada di
// mode lain, karena pengguna sedang berjalan dan menggantungkan langkahnya di
// sini. Yang dikejar cuma kasus yang benar-benar tidak masuk akal, bukan
// pemandangan yang sekadar tidak biasa.
//
// Setel ulang setelah uji lapangan: kalau pengguna sungguhan sering kena
// "tidak yakin" padahal jalurnya jelas, naikkan _degenerateRatio dan turunkan
// _groundBandMinWalk.

/// Porsi satu kelas yang bikin frame dianggap tanpa struktur.
///
/// Pemandangan berjalan yang benar selalu punya campuran: permukaan di bawah,
/// bangunan atau langit di atas. 97% satu kelas berarti lensanya tertutup,
/// menghadap tembok polos, atau menghadap langit.
const double _degenerateRatio = 0.97;

/// Tinggi pita bawah yang dianggap "tepat di depan kaki".
const double _groundBandFrac = 0.25;

/// Porsi walkable minimum di pita bawah sebelum jalur dianggap benar-benar
/// menyentuh tanah.
const double _groundBandMinWalk = 0.10;

/// Nilai apakah sebuah mask masuk akal sebagai pemandangan berjalan.
///
/// Dua pemeriksaan, keduanya dari mask yang SUDAH dihitung - jadi tidak ada
/// inferensi tambahan, biayanya satu lintasan atas array yang sama.
///
/// Sengaja TIDAK memakai model kedua atau klasifikasi pemandangan. Yang
/// dibutuhkan cuma menjawab "apakah bentuk mask ini mungkin datang dari
/// trotoar", dan bentuknya sudah cukup untuk itu. Menambah model berarti
/// menambah satu hal lagi yang bisa gagal di mode yang paling tidak boleh
/// gagal.
///
/// Fungsi murni supaya bisa diuji tanpa perangkat maupun model: ini keputusan
/// yang menentukan apakah pengguna disuruh melangkah maju, dan keputusan
/// seperti itu tidak boleh cuma dibuktikan lewat uji lapangan.
SceneDoubt assessScene(List<int> mask, int width, int height) {
  final total = mask.length;
  if (total == 0 || width <= 0 || height <= 0) return SceneDoubt.degenerate;
  if (total != width * height) return SceneDoubt.degenerate;

  var nWalk = 0;
  for (var i = 0; i < total; i++) {
    if (mask[i] == _classWalkable) nWalk++;
  }

  // ── 1. Frame walkable seragam ──
  //
  // Pemeriksaannya ASIMETRIS, dan itu disengaja.
  //
  // Frame yang hampir seluruhnya walkable adalah satu-satunya bentuk yang
  // berbahaya: dia menghasilkan "tiga zona aman" lalu "Jalur aman, jalan
  // lurus" - lampu hijau untuk melangkah, dari langit-langit kamar atau
  // lensa yang tertutup telapak tangan.
  //
  // Frame yang hampir seluruhnya NON-walkable atau hazard tidak perlu
  // dijaga di sini, karena keduanya sudah gagal ke arah yang aman: status
  // zonanya jadi `danger` dan pengguna mendengar "Berhenti dulu, tidak ada
  // jalur aman". Menandainya "tidak terbaca" justru menukar pesan yang benar
  // dengan permintaan membetulkan kamera - dan pengguna yang sebenarnya
  // sedang berdiri menghadap tembok akan sibuk mengatur ponsel alih-alih
  // memutar badan.
  if (nWalk / total >= _degenerateRatio) return SceneDoubt.degenerate;

  // ── 2. Jalur yang tidak menyentuh tanah ──
  //
  // Hanya diperiksa kalau memang ADA jalur yang terdeteksi. Frame tanpa jalur
  // sama sekali bukan kasus meragukan - itu jawaban yang sah ("tidak ada jalur
  // aman") dan sudah ditangani status zona.
  if (nWalk > 0) {
    final bandStart = height - (height * _groundBandFrac).round();
    var bandWalk = 0;
    var bandTotal = 0;
    for (var h = bandStart; h < height; h++) {
      final row = h * width;
      for (var w = 0; w < width; w++) {
        bandTotal++;
        if (mask[row + w] == _classWalkable) bandWalk++;
      }
    }
    if (bandTotal > 0 && bandWalk / bandTotal < _groundBandMinWalk) {
      return SceneDoubt.notGrounded;
    }
  }

  return SceneDoubt.none;
}

/// Ukuran mask yang dikirim ke lapisan gambar.
///
/// Mask penuh 640x384 berisi 245 ribu piksel. Menyalinnya utuh ke UI delapan
/// kali per detik memindahkan 2 MB per detik untuk hamparan tembus pandang
/// yang toh diperhalus saat digambar - pemborosan yang langsung terasa
/// sebagai panas di tangan pengguna.
///
/// 160x96 (seperdelapan belas jumlah piksel) sudah lebih dari cukup: yang
/// digambar cuma siluet jalur, bukan detail tepinya.
const int _maskOutW = 160;
const int _maskOutH = 96;

// Threshold rasio walkable per zona
const double _threshSafe    = 0.50; // ≥50% walkable → AMAN
const double _threshCaution = 0.30; // ≥30% walkable → HATI-HATI, sisanya BAHAYA

/// Pita bawah frame yang dipakai untuk menilai zona DAN menyusun sumbu jalur.
///
/// Ini perbaikan paling menentukan di berkas ini. Versi sebelumnya menghitung
/// rasio zona atas SELURUH tinggi frame, termasuk langit, pucuk pohon, pagar
/// tanaman, dan jalan raya di kejauhan. Tidak satu pun dari itu akan diinjak
/// dalam sepuluh langkah ke depan, tapi semuanya masuk hitungan sebagai
/// "tidak layak jalan" dan menenggelamkan trotoar yang benar-benar ada di
/// sepertiga kiri dan kanan.
///
/// Akibatnya terukur di log perangkat: `L=0.21 C=0.35 R=0.13`. Dengan ambang
/// 0,30 dan 0,50, kiri dan kanan SELALU jatuh ke BAHAYA - bahkan pada frame
/// yang hamparannya jelas menunjukkan trotoar hijau melebar ke kiri. Pengguna
/// membaca "Kiri BAHAYA, Kanan BAHAYA" di atas gambar yang isinya jalan mulus.
///
/// 0,45 kira-kira delapan langkah ke depan pada tinggi pegang ponsel biasa.
/// Naikkan kalau arahannya terasa terlalu pendek pandang; turunkan kalau
/// kejauhan mulai ikut mempengaruhi keputusan langkah berikutnya.
const double _zoneBandFrac = 0.45;

/// Jumlah irisan kedalaman di dalam pita. 14 irisan pada 211 baris berarti
/// tiap ruas setebal ~15 baris - cukup halus untuk mengikuti tikungan
/// trotoar, cukup tebal untuk tidak goyah oleh derau satu-dua piksel.
const int _pathSlices = 14;

/// Lebar minimum satu ruas jalur, sebagai pecahan lebar frame.
///
/// Di bawah ini ruasnya tidak dianggap jalur sama sekali. Celah selebar 5%
/// frame pada trotoar 2 meter kira-kira 10 cm - bukan jalan, itu retakan.
/// Menyarankannya sebagai jalur jauh lebih berbahaya daripada diam.
const double _pathMinWidthFrac = 0.06;

/// Celah sesempit ini di dalam koridor ditutup sebelum ruas dicari.
///
/// Nat ubin, garis sambungan beton, dan bayangan tipis sering terbaca sebagai
/// satu-dua kolom bukan-jalur di tengah trotoar yang sebenarnya utuh. Tanpa
/// penutupan celah, koridor selebar dua meter terbelah jadi dua ruas satu
/// meter, dan arahannya berubah jadi "pilih sisi" untuk masalah yang tidak
/// ada.
///
/// Batasnya sengaja kecil. Celah yang lebih lebar dari ini - ubin pemandu
/// yang menonjol, got terbuka, kaki tiang - memang harus tetap membelah
/// koridor, karena memang tidak boleh diinjak.
const double _pathGapFrac = 0.04;

/// Setengah lebar badan pengguna, sebagai pecahan lebar frame.
///
/// Dipakai untuk satu pertanyaan: apakah koridor di depan masih memuat badan
/// pengguna kalau dia terus lurus? Kalau ya, dia TIDAK disuruh bergeser.
///
/// Tanpa ambang ini, arahan ikut bergoyang mengikuti titik hilang perspektif:
/// trotoar lurus pun sumbunya bergeser di dalam frame saat kamera miring
/// sedikit, dan pengguna terus-menerus disuruh "agak ke kanan" lalu "agak ke
/// kiri" untuk jalan yang sebenarnya lurus.
const double _shoulderFrac = 0.10;

// Normalisasi ImageNet-nya sekarang dikerjakan NavFrameConverter, sekaligus
// dengan rotasi dan penskalaan, dalam satu lintasan di isolate.

// ─────────────────────────────────────────────────────────────
// PidnetService - segmentasi jalur 3 zona on-device
// ─────────────────────────────────────────────────────────────
class PidnetService {
  static final PidnetService instance = PidnetService._();
  PidnetService._();

  IsolateInterpreter? _interpreter;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Input shape: [1, 384, 640, 3] (BHWC - TFLite default)
  // Atau [1, 3, 384, 640] (BCHW - jika model tidak di-transpose saat export)
  // Akan dideteksi otomatis saat load.
  bool _isBHWC = true;

  /// Buffer keluaran yang dipakai ulang selama service hidup.
  ///
  /// Dialokasikan sekali (sekitar 2,9 MB), bukan tiap frame. Inilah yang
  /// membuat mode navigasi aman dijalankan lama di HP 4 GB.
  Float32List? _outputBuffer;

  /// View byte di atas [_outputBuffer]. Keduanya menunjuk memori yang sama.
  Uint8List? _outputBytes;

  /// Muat model segmentasi jalur, dengan pilihan varian yang DIBUKTIKAN jalan.
  ///
  /// ## Kenapa tiap kandidat harus dicoba, bukan sekadar dimuat
  ///
  /// Versi sebelumnya memilih FP16 lebih dulu dan hanya jatuh ke FP32 kalau
  /// BERKASNYA gagal dibaca. Padahal `pidnet_s_3zona_fp16.tflite` punya tensor
  /// masukan bertipe FLOAT16, sementara pipeline mengirim FLOAT32 - dan
  /// `tflite_flutter` menyalin byte tanpa memeriksa tipe.
  ///
  /// Akibatnya berkasnya termuat dengan mulus, `tryLoad()` melaporkan sukses,
  /// lalu SETIAP panggilan `analyze()` melempar di dalam interpreter. Blok
  /// `catch` menelannya, `analyze` mengembalikan null, dan mode navigasi
  /// berjalan tanpa segmentasi jalur sama sekali - tanpa satu pun tanda di
  /// layar bahwa ada yang salah.
  ///
  /// Sekarang tiap kandidat dijalankan sekali dengan tensor percobaan sebelum
  /// diterima. Satu inferensi saat muat jauh lebih murah daripada mode
  /// keselamatan yang diam-diam mati.
  Future<bool> tryLoad() async {
    // Urutannya masih FP16 dulu - kalau memang jalan di perangkat ini, dia
    // lebih kecil dan lebih cepat. Yang berubah: sekarang harus membuktikannya.
    const kandidat = [
      'assets/models/pidnet_s_3zona_fp16.tflite',
      'assets/models/pidnet_s_3zona.tflite',
    ];

    // Tiap kandidat dicoba DUA KALI: sekali dengan GPU delegate, sekali murni
    // CPU. Lihat [_coba] untuk alasannya - urutan ini yang dulu membuat mode
    // navigasi mati total di perangkat nyata.
    //
    // Berkasnya dibaca sekali di sini, bukan di dalam tiap percobaan. Kandidat
    // yang tidak dibundel (fp16) gagal satu kali dengan satu baris log, bukan
    // dua kali dengan pesan yang sama.
    for (final aset in kandidat) {
      final Uint8List modelBytes;
      try {
        modelBytes = (await rootBundle.load(aset)).buffer.asUint8List();
      } catch (e) {
        debugPrint('[PIDNet] $aset tidak ada di bundel: $e');
        continue;
      }
      if (await _coba(aset, modelBytes, gpu: true)) return true;
      if (await _coba(aset, modelBytes, gpu: false)) return true;
    }

    debugPrint('[PIDNet] Tidak ada varian model yang bisa dijalankan.');
    _loaded = false;
    return false;
  }

  /// Satu percobaan muat: satu berkas, satu pilihan delegate.
  ///
  /// ## Kenapa GPU dan CPU harus jadi dua percobaan terpisah
  ///
  /// Versi sebelumnya membungkus GPU delegate dalam `try/catch`, tapi yang
  /// dibungkus cuma PEMBUATAN `InterpreterOptions` - dan itu tidak pernah
  /// melempar. Yang melempar adalah `Interpreter.fromBuffer`, saat TFLite
  /// menerapkan delegate ke graf. Jadi `catch`-nya menangkap kegagalan yang
  /// tidak pernah terjadi, sementara kegagalan yang sungguhan jatuh ke `catch`
  /// terluar dan menghapus seluruh kandidat itu. Tidak ada jalan mundur ke CPU
  /// sama sekali.
  ///
  /// Ini bukan skenario teoretis. Di log perangkat:
  ///
  ///     W/tflite: Attempting to use a delegate that only supports
  ///               static-sized tensors with a graph that has dynamic-sized
  ///               tensors (tensor#9 is a dynamic-sized tensor).
  ///     [PIDNet] assets/models/pidnet_s_3zona.tflite tidak bisa dipakai:
  ///              Invalid argument(s): Unable to create interpreter.
  ///     [Nav] Model on-device gagal dimuat: PIDNet segmentasi jalur
  ///
  /// Modelnya sendiri sehat: 73 dari 218 tensornya bersumbu batch dinamis
  /// (`shape_signature` dimulai -1) karena `scripts/07_export_onnx.py` di repo
  /// `vinara-sidewalk-cv2` selalu menandai `{"input": {0: "batch"}}`. Runtime
  /// CPU menerima itu tanpa keluhan - makanya pengujian Python di
  /// `test/navigation/` lulus - tapi GPU delegate menolak graf dengan tensor
  /// dinamis, dan penolakannya menggagalkan pembuatan interpreter.
  ///
  /// Perbaikan tuntasnya ada di sisi ekspor: batch dipatok 1 supaya tidak ada
  /// tensor dinamis sama sekali, lalu GPU delegate bisa dipakai lagi. Sampai
  /// itu terjadi, jatuh ke CPU jauh lebih baik daripada mode navigasi yang
  /// tidak pernah menyala.
  Future<bool> _coba(String aset, Uint8List modelBytes,
      {required bool gpu}) async {
    // Di luar Android tidak ada GpuDelegateV2 yang relevan, jadi percobaan
    // GPU-nya dilewati alih-alih dijalankan dua kali dengan hasil sama.
    if (gpu && !Platform.isAndroid) return false;

    Interpreter? interpreter;
    try {
      final options = InterpreterOptions()..threads = 2;
      if (gpu) options.addDelegate(GpuDelegateV2());

      interpreter = Interpreter.fromBuffer(modelBytes, options: options);

      // Sumbu batch model ini dinamis. Interpreter memang memakai [1, ...]
      // sebagai bentuk bawaan, tapi mematoknya di sini membuat alokasi
      // tensornya pasti dan menghilangkan satu sumber kegagalan diam-diam.
      try {
        interpreter.resizeInputTensor(0, interpreter.getInputTensor(0).shape);
        interpreter.allocateTensors();
      } catch (_) {
        // Sebagian build menolak resize ke bentuk yang sama persis. Tidak
        // masalah: bentuk bawaannya memang sudah yang kita mau.
      }

      // Deteksi input format: BHWC atau BCHW
      final inputShape = interpreter.getInputTensor(0).shape;
      // BHWC: [1, H, W, C] → shape[1]=384, shape[2]=640, shape[3]=3
      // BCHW: [1, C, H, W] → shape[1]=3,   shape[2]=384, shape[3]=640
      final bhwc = inputShape.length == 4 && inputShape[3] == 3;

      // Inferensi percobaan. Inilah yang membedakan "berkasnya terbaca" dari
      // "modelnya benar-benar bisa dipakai".
      final probeIn = Float32List(_pidnetH * _pidnetW * 3);
      final probeOut = Float32List(3 * _pidnetH * _pidnetW);
      interpreter.runForMultipleInputs(
        [probeIn.buffer.asUint8List()],
        {0: probeOut.buffer.asUint8List()},
      );

      _isBHWC = bhwc;
      _interpreter = await IsolateInterpreter.create(address: interpreter.address);
      _loaded = true;
      debugPrint('[PIDNet] Model siap: $aset '
          '(${(modelBytes.length / 1024).toStringAsFixed(0)} KB, '
          '${bhwc ? "BHWC" : "BCHW"}, ${gpu ? "GPU" : "CPU"})');
      return true;
    } catch (e) {
      // Varian ini tidak bisa dipakai di perangkat ini. Interpreter-nya
      // ditutup supaya tidak menyisakan memori native yang tidak akan
      // dipakai - penting di HP 4 GB, di mana dua interpreter menganggur
      // sudah terasa.
      try {
        interpreter?.close();
      } catch (_) {
        // Menutup yang gagal disiapkan boleh saja ikut gagal.
      }
      debugPrint('[PIDNet] $aset lewat ${gpu ? "GPU" : "CPU"} '
          'tidak bisa dipakai: $e');
      _loaded = false;
      return false;
    }
  }

  /// Tata letak tensor masukan yang diminta model.
  ///
  /// Dibaca [NavFrameConverter] supaya piksel ditulis langsung dalam susunan
  /// yang benar, alih-alih disusun ulang setelahnya.
  bool get wantsBchw => !_isBHWC;

  /// Analisis satu frame yang SUDAH disiapkan → ZoneAnalysis (3 zona jalur).
  ///
  /// [input] adalah tensor datar dari [NavFrameConverter.prepare]. Preprocessing
  /// sengaja TIDAK dilakukan di sini lagi: dulu metode ini menerima RGB mentah
  /// lalu memutar, menskalakan, dan membangun `List` bersarang di isolate UI -
  /// sekitar 57 ms per frame ditambah 245.760 objek List kecil. Sekarang
  /// semuanya sudah selesai di isolate sebelum sampai ke sini.
  ///
  /// [withMask] true ikut mengembalikan mask kelas per-piksel yang sudah
  /// dikecilkan, untuk digambar sebagai hamparan jalur. Dibuat opsional
  /// supaya jalur yang cuma butuh arahan suara tidak membayar salinannya.
  Future<ZoneAnalysis?> analyze(
    Float32List input, {
    bool withMask = false,
  }) async {
    if (!_loaded || _interpreter == null) return null;

    final t0 = DateTime.now();

    try {
      // Buffer keluaran datar, dipakai ulang antar frame.
      //
      // Versi sebelumnya mengalokasikan `List.filled(737.280, 0.0)` lalu
      // memanggil `.reshape()` untuk membuat struktur bersarang - ratusan ribu
      // double ter-boxing yang langsung jadi sampah tiap frame, lalu dibaca
      // kembali lewat pencarian `List` dinamis ber-cast satu per satu.
      //
      // Di HP 4 GB, sampah sebesar ini tiap 700 ms memicu pengumpulan yang
      // terasa sebagai sentakan berkala pada preview maupun suara.
      final out = _outputBuffer ??= Float32List(3 * _pidnetH * _pidnetW);
      // Tensor diserahkan ke TFLite sebagai VIEW byte di atas memori yang
      // sama, bukan sebagai Float32List.
      //
      // Ini bukan gaya penulisan, ini syarat. `tflite_flutter` melewati
      // konversi HANYA untuk `Uint8List` dan `ByteBuffer`; tipe lain
      // dihitung ulang bentuknya lewat `computeShapeOf`, dan `Float32List`
      // datar terbaca sebagai tensor 1 dimensi. Interpreter lalu mengubah
      // ukuran tensor masukan jadi `[737280]` dan grafnya gagal disiapkan.
      //
      // Lewat view byte, tidak ada penyalinan, tidak ada perubahan bentuk,
      // dan `Float32List`-nya tetap bisa dibaca sebagai angka.
      final outBytes = _outputBytes ??= out.buffer.asUint8List();
      final outputs = {0: outBytes};
      await _interpreter!.runForMultipleInputs(
        [input.buffer.asUint8List()],
        outputs,
      );

      // Argmax per-piksel → mask [H*W]
      final mask = _argmaxFlat(out);

      final inferMs = DateTime.now().difference(t0).inMilliseconds.toDouble();
      return _computeZones(
        mask,
        inferMs,
        doubt: assessScene(mask, _pidnetW, _pidnetH),
        small: withMask ? _downsampleMask(mask) : null,
      );
    } catch (e) {
      debugPrint('[PIDNet] analyze error: $e');
      return null;
    }
  }

  /// Argmax per-piksel dari buffer keluaran DATAR.
  ///
  /// Menggantikan versi yang membaca `List` bersarang lewat pencarian dinamis
  /// ber-cast (`(classes[c] as List)[h][w] as double`) sebanyak 737.280 kali
  /// per frame. Di sini indeksnya dihitung langsung ke `Float32List`, tanpa
  /// cast dan tanpa boxing.
  ///
  /// Tata letak keluaran mengikuti tata letak masukan: model BCHW menghasilkan
  /// `[1,3,H,W]`, model BHWC menghasilkan `[1,H,W,3]`. Keduanya ditangani di
  /// sini supaya tidak ada penyusunan ulang tensor terpisah.
  List<int> _argmaxFlat(Float32List out) {
    const n = _pidnetH * _pidnetW;
    final mask = List<int>.filled(n, 0);

    if (_isBHWC) {
      // [H][W][3] - tiga kelas satu piksel berdampingan.
      for (var i = 0; i < n; i++) {
        final o = i * 3;
        final c0 = out[o], c1 = out[o + 1], c2 = out[o + 2];
        var best = 0;
        var bestVal = c0;
        if (c1 > bestVal) { bestVal = c1; best = 1; }
        if (c2 > bestVal) { best = 2; }
        mask[i] = best;
      }
    } else {
      // [3][H][W] - tiap kelas satu bidang penuh.
      for (var i = 0; i < n; i++) {
        final c0 = out[i], c1 = out[n + i], c2 = out[n * 2 + i];
        var best = 0;
        var bestVal = c0;
        if (c1 > bestVal) { bestVal = c1; best = 1; }
        if (c2 > bestVal) { best = 2; }
        mask[i] = best;
      }
    }
    return mask;
  }

  /// Kecilkan mask 640x384 ke [_maskOutW]x[_maskOutH] dengan MODUS, bukan
  /// pengambilan sampel titik.
  ///
  /// Bedanya penting untuk hazard. Lubang sering cuma menempati 1-3% piksel,
  /// jadi kalau tiap sel keluaran hanya membaca satu piksel sumber, hazard
  /// yang tipis punya peluang besar terlewat sama sekali - dan yang hilang
  /// justru satu-satunya kelas yang wajib terlihat.
  ///
  /// Modus per blok mempertahankannya, dengan pengecualian yang disengaja:
  /// kalau satu blok mengandung hazard sama sekali, blok itu ditandai hazard
  /// walau bukan mayoritas. Untuk hamparan peringatan, melebihkan sedikit
  /// jauh lebih aman daripada menghilangkannya.
  Uint8List _downsampleMask(List<int> mask) {
    final out = Uint8List(_maskOutW * _maskOutH);
    const blockW = _pidnetW / _maskOutW;
    const blockH = _pidnetH / _maskOutH;

    for (int oy = 0; oy < _maskOutH; oy++) {
      final y0 = (oy * blockH).floor();
      final y1 = ((oy + 1) * blockH).ceil().clamp(y0 + 1, _pidnetH);
      for (int ox = 0; ox < _maskOutW; ox++) {
        final x0 = (ox * blockW).floor();
        final x1 = ((ox + 1) * blockW).ceil().clamp(x0 + 1, _pidnetW);

        int nNon = 0, nWalk = 0, nHaz = 0;
        for (int y = y0; y < y1; y++) {
          final row = y * _pidnetW;
          for (int x = x0; x < x1; x++) {
            switch (mask[row + x]) {
              case 0:
                nNon++;
              case _classWalkable:
                nWalk++;
              default:
                nHaz++;
            }
          }
        }

        final int cls;
        if (nHaz > 0) {
          cls = 2;
        } else if (nWalk >= nNon) {
          cls = _classWalkable;
        } else {
          cls = 0;
        }
        out[oy * _maskOutW + ox] = cls;
      }
    }
    return out;
  }

  /// Susun sumbu jalur dari histogram kolom per irisan.
  ///
  /// Tiga aturan, dan ketiganya lahir dari melihat maskanya sendiri, bukan
  /// dari teori. Mask nyata `01_got_terbuka.png` berbentuk begini (`#` layak
  /// jalan, baris bawah = tepat di depan kaki):
  ///
  ///     ....###########......####..#######......
  ///     #############........##############.....
  ///     ##############.......######...#######...
  ///     ################.....##################.
  ///     ########################################
  ///
  /// **1. Celah sempit ditutup dulu.** Nat ubin dan garis sambungan membelah
  /// koridor yang sebenarnya utuh. Lihat [_pathGapFrac].
  ///
  /// **2. Ruas dipilih yang BERSAMBUNG dengan ruas di bawahnya**, bukan yang
  /// terlebar di tiap irisan. Perhatikan gambar di atas: got di tengah membuat
  /// dua cabang, dan yang lebih lebar berganti-ganti sisi dari satu kedalaman
  /// ke kedalaman berikutnya. Memilih "terlebar" tiap irisan menghasilkan
  /// sumbu yang melompat kiri-kanan dan garis panduan yang menembus got.
  /// Menyambung dari ruas terdekat ke kaki membuat sumbu itu mengikuti SATU
  /// koridor yang benar-benar bisa ditempuh dari tempat pengguna berdiri.
  ///
  /// **3. Penelusuran berhenti kalau tidak ada ruas yang bersambung.** Jalur
  /// yang muncul lagi di kejauhan tapi terputus di dekat kaki bukan jalur yang
  /// bisa ditempuh dari sini.
  List<PathPoint> _tracePath(
    List<Uint16List> sliceCols,
    List<int> sliceRows,
    int sliceH,
  ) {
    final minRun = (_pidnetW * _pathMinWidthFrac).round();
    final maxGap = (_pidnetW * _pathGapFrac).round();
    final points = <PathPoint>[];

    int prevStart = -1, prevEnd = -1;

    for (int sIdx = 0; sIdx < _pathSlices; sIdx++) {
      final rows = sliceRows[sIdx];
      if (rows == 0) break;
      final cols = sliceCols[sIdx];

      // Kolom dihitung jalur kalau MAYORITAS baris di irisan ini layak jalan.
      final layak = List<bool>.generate(
          _pidnetW, (x) => cols[x] * 2 >= rows,
          growable: false);

      // Tutup celah sempit di antara dua bagian yang layak.
      var x = 0;
      while (x < _pidnetW) {
        if (layak[x]) {
          x++;
          continue;
        }
        var j = x;
        while (j < _pidnetW && !layak[j]) {
          j++;
        }
        if (x > 0 && j < _pidnetW && j - x <= maxGap) {
          for (var k = x; k < j; k++) {
            layak[k] = true;
          }
        }
        x = j;
      }

      // Kumpulkan ruas yang cukup lebar.
      int pickStart = -1, pickEnd = -1, pickScore = -1;
      int runStart = -1;
      for (int i = 0; i <= _pidnetW; i++) {
        final isWalk = i < _pidnetW && layak[i];
        if (isWalk) {
          if (runStart < 0) runStart = i;
          continue;
        }
        if (runStart < 0) continue;

        final len = i - runStart;
        if (len >= minRun) {
          // Irisan terdekat kaki: ambil yang terlebar, itu titik berangkatnya.
          // Sesudahnya: ambil yang paling banyak bertumpuk dengan ruas
          // sebelumnya, supaya sumbunya mengikuti satu koridor.
          final int score = prevStart < 0
              ? len
              : (i < prevEnd ? i : prevEnd) -
                  (runStart > prevStart ? runStart : prevStart);
          if (score > pickScore) {
            pickScore = score;
            pickStart = runStart;
            pickEnd = i;
          }
        }
        runStart = -1;
      }

      // Skor <= 0 berarti tidak ada ruas yang menyentuh koridor sebelumnya.
      if (pickStart < 0 || (prevStart >= 0 && pickScore <= 0)) break;

      final yMid = _pidnetH - (sIdx + 0.5) * sliceH;
      points.add(PathPoint(
        x: (pickStart + pickEnd) / 2 / _pidnetW,
        y: (yMid / _pidnetH).clamp(0.0, 1.0),
        width: (pickEnd - pickStart) / _pidnetW,
      ));
      prevStart = pickStart;
      prevEnd = pickEnd;
    }
    return points;
  }

  // ── Hitung rasio 3 zona, sumbu jalur, dan rekomendasi ───────────────────
  //
  // Satu lintasan atas pita bawah menghasilkan histogram kolom per irisan
  // kedalaman. Rasio zona dan sumbu jalur sama-sama dibaca dari histogram itu,
  // jadi keduanya tidak pernah bisa saling bertentangan - dan biayanya tetap
  // satu lintasan, bukan dua.
  ZoneAnalysis _computeZones(List<int> mask, double inferMs,
      {SceneDoubt doubt = SceneDoubt.none, Uint8List? small}) {
    const zoneW = _pidnetW ~/ 3;
    final bandStart = _pidnetH - (_pidnetH * _zoneBandFrac).round();
    final bandRows = _pidnetH - bandStart;
    final sliceH = (bandRows / _pathSlices).ceil();

    // sliceCols[s][x] = berapa baris walkable di irisan s, kolom x.
    // Irisan 0 adalah yang PALING DEKAT ke kaki.
    final sliceCols = List.generate(
        _pathSlices, (_) => Uint16List(_pidnetW),
        growable: false);
    final sliceRows = List<int>.filled(_pathSlices, 0);

    for (int h = bandStart; h < _pidnetH; h++) {
      final s = ((_pidnetH - 1 - h) ~/ sliceH).clamp(0, _pathSlices - 1);
      sliceRows[s]++;
      final row = h * _pidnetW;
      final cols = sliceCols[s];
      for (int w = 0; w < _pidnetW; w++) {
        if (mask[row + w] == _classWalkable) cols[w]++;
      }
    }

    int leftWalk = 0, centWalk = 0, rightWalk = 0;
    for (int s = 0; s < _pathSlices; s++) {
      final cols = sliceCols[s];
      for (int w = 0; w < _pidnetW; w++) {
        final n = cols[w];
        if (n == 0) continue;
        if (w < zoneW) {
          leftWalk += n;
        } else if (w < zoneW * 2) {
          centWalk += n;
        } else {
          rightWalk += n;
        }
      }
    }

    final perZone = max(bandRows * zoneW, 1);
    final lRatio = leftWalk / perZone;
    final cRatio = centWalk / perZone;
    final rRatio = rightWalk / (bandRows * (_pidnetW - zoneW * 2)).clamp(1, 1 << 30);

    ZoneStatus toStatus(double ratio) {
      if (ratio >= _threshSafe)    { return ZoneStatus.safe; }
      if (ratio >= _threshCaution) { return ZoneStatus.caution; }
      return ZoneStatus.danger;
    }

    final lStatus = toStatus(lRatio);
    final cStatus = toStatus(cRatio);
    final rStatus = toStatus(rRatio);

    final path = _tracePath(sliceCols, sliceRows, sliceH);

    // ── Rekomendasi ──
    //
    // Diambil dari sumbu jalur, bukan dari perbandingan tiga rasio. Bedanya
    // justru pada kasus yang paling penting: tiang di tengah trotoar membuat
    // ketiga rasio jelek sekaligus, dan perbandingan rasio lalu memilih "yang
    // paling tidak jelek" - jawaban yang tidak berhubungan dengan letak celah
    // yang sebenarnya. Sumbu jalur melihat celahnya langsung.
    var recommended = 1;
    var shift = 0.0;
    if (path.isNotEmpty) {
      // Beberapa langkah di depan, bukan ruas terjauh: ujung jalur yang jauh
      // paling banyak derainya, dan pengguna toh cuma perlu tahu langkah
      // berikutnya.
      final tuju = path[min(4, path.length - 1)];
      final kiri = tuju.x - tuju.width / 2;
      final kanan = tuju.x + tuju.width / 2;

      // Pertanyaannya BUKAN "di mana tengah koridor", melainkan "kalau saya
      // terus lurus, badan saya masih muat?". Dua pertanyaan itu memberi
      // jawaban berbeda pada trotoar lurus yang lebar, dan yang pertama
      // memberi jawaban yang salah: sumbu koridor selalu bergeser sedikit
      // mengikuti titik hilang perspektif, jadi pengguna terus disuruh
      // bergeser padahal jalannya lurus.
      const lurus = 0.5;
      if (kiri + _shoulderFrac <= lurus && lurus <= kanan - _shoulderFrac) {
        recommended = 1;
        shift = 0.0;
      } else {
        shift = (tuju.x - lurus).clamp(-1.0, 1.0);
        recommended = tuju.x < 1 / 3
            ? 0
            : tuju.x < 2 / 3
                ? 1
                : 2;
      }
    } else {
      // Tidak ada jalur sama sekali. Rasio dipakai hanya supaya chip zona
      // tetap menunjuk sisi yang paling lapang, tapi arahannya tetap
      // "berhenti" - lihat [ZoneAnalysis.ttsMessage].
      if (lRatio >= cRatio && lRatio >= rRatio) {
        recommended = 0;
      } else if (rRatio >= cRatio) {
        recommended = 2;
      }
    }

    debugPrint('[PIDNet] L=${lRatio.toStringAsFixed(2)} '
        'C=${cRatio.toStringAsFixed(2)} R=${rRatio.toStringAsFixed(2)} '
        'jalur=${path.length} geser=${shift.toStringAsFixed(2)} '
        '→ rec=$recommended  (${inferMs.toStringAsFixed(0)}ms)');

    return ZoneAnalysis(
      leftRatio:       lRatio,
      centerRatio:     cRatio,
      rightRatio:      rRatio,
      left:            lStatus,
      center:          cStatus,
      right:           rStatus,
      recommendedZone: recommended,
      inferenceMs:     inferMs,
      path:            path,
      pathShift:       shift,
      doubt:           doubt,
      mask:            small,
      maskWidth:       small == null ? 0 : _maskOutW,
      maskHeight:      small == null ? 0 : _maskOutH,
    );
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}
