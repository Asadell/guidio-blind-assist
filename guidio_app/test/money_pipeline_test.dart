import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/money_tflite_service.dart';
import 'package:image/image.dart' as img;

import 'helpers/camera_frame.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// UJI PIPELINE UANG - LEWAT FUNGSI YANG BENAR-BENAR DIPAKAI APLIKASI
///
/// Test ini memanggil [MoneyTFLiteService.classifyCameraImage] - jalur yang
/// sama persis dengan yang berjalan waktu pengguna mengarahkan kamera. Frame
/// kamera palsu dibangun dari fixture PNG: RGB dikonversi balik ke YUV420
/// dengan tata letak Android (`YUV_420_888`, pixelStride 2), lalu dibungkus
/// jadi [CameraImage] asli.
///
/// KENAPA HARUS BEGINI, bukan `interpreter.run()` langsung
/// ────────────────────────────────────────────────────────
/// Suite lama (`model_inference_test.dart`) membangun preprocessing-nya
/// SENDIRI dan memanggil interpreter langsung. Preprocessing itu memakai
/// `img.copyResize(source, width: 224, height: 224)` - PEREGANGAN, bukan
/// letterbox, dan tanpa center-crop. Artinya suite itu menguji pipeline yang
/// tidak pernah dijalankan aplikasi, sementara bug pada pipeline yang NYATA
/// lolos tanpa terdeteksi. Dokumentasi service sendiri memperingatkan
/// tepat kesalahan ini (lihat `money_tflite_service.dart`, poin 2).
///
/// Konsekuensinya bukan teori: aplikasi bisa dikirim dengan preprocessing
/// rusak sementara seluruh suite hijau.
///
/// KENAPA ASSERT-NYA KERAS
/// ───────────────────────
/// Suite lama menulis `if (result.detected) { expect(...) }`. Karena model
/// saat ini nyaris tidak pernah menembus ambang 0,85, cabang itu tidak pernah
/// dieksekusi - setiap gambar jatuh ke "uncertain → lulus". Model yang
/// mengeluarkan 20% untuk SEMUA masukan pun lulus 100%. Itulah sebabnya
/// akurasi "98%" bisa hidup berdampingan dengan aplikasi yang salah baca.
///
/// Di sini dipisah dua kelompok:
///   - KEAMANAN  : tidak boleh yakin-tapi-salah. Wajib hijau selamanya.
///   - KEMAMPUAN : harus benar-benar mengenali uangnya. Ini RATCHET -
///                 sekarang merah, dan memang harus merah sampai modelnya
///                 diperbaiki. Jangan dilonggarkan; naikkan modelnya.
/// ─────────────────────────────────────────────────────────────────────────────

// ── Ground truth dari nama berkas ────────────────────────────────────────────

/// `5000.png` → 5000, `5rb.png` → 5000, `20rb.png` → 20000.
/// Tidak ada tabel hard-coded: kalau nama berkas menyimpang, regex gagal dan
/// test langsung merah alih-alih diam-diam menguji hal yang salah.
int? _valueFromFilename(String filename) {
  final m = RegExp(r'^(\d+)(rb|ribu)?\.png$').firstMatch(filename);
  if (m == null) return null;
  final n = int.tryParse(m.group(1)!);
  if (n == null) return null;
  return m.group(2) != null ? n * 1000 : n;
}

String _fmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

// ── Fixture ──────────────────────────────────────────────────────────────────

class _Fixture {
  final String dir;
  final String name;
  const _Fixture(this.dir, this.name);

  String get path => 'test/fixtures/$dir/$name';
  String get label => '$dir/$name';
  int get expected => _valueFromFilename(name)!;
}

/// Sengaja memuat DUA sumber:
///   - money_new  : screenshot layar (uang kecil di frame, tertimpa UI overlay)
///   - money_new2 : foto biasa (uang mengisi hampir selebar frame)
/// Keduanya kondisi nyata yang harus ditangani aplikasi.
const _fixtures = <_Fixture>[
  _Fixture('money_new', '5000.png'),
  _Fixture('money_new', '10000.png'),
  _Fixture('money_new2', '5rb.png'),
  _Fixture('money_new2', '10rb.png'),
  _Fixture('money_new2', '20rb.png'),
];

// ── Fabrikasi frame kamera ───────────────────────────────────────────────────


// ── Pelaporan ────────────────────────────────────────────────────────────────

/// Chance level 7 kelas. Prediksi "benar" di sekitar angka ini bukan model
/// yang bekerja - itu model yang menebak dan kebetulan beruntung.
const double _chance = 1.0 / 7.0;

class _Reading {
  final _Fixture fx;
  final MoneyResult result;
  const _Reading(this.fx, this.result);

  int? get top => result.topValueIdr;
  bool get argmaxCorrect => top == fx.expected;

  /// Selisih probabilitas juara satu dan juara dua. Ini pembeda paling jujur
  /// antara model yakin dan model yang sekadar unggul tipis secara acak.
  double get margin {
    final p = result.probabilities;
    if (p == null || p.length < 2) return 0;
    final s = [...p]..sort((a, b) => b.compareTo(a));
    return s[0] - s[1];
  }

  /// Entropi ternormalisasi: 0 = yakin penuh, 1 = seragam total.
  double get entropy {
    final p = result.probabilities;
    if (p == null || p.isEmpty) return 1;
    var e = 0.0;
    for (final v in p) {
      if (v > 0) e -= v * math.log(v);
    }
    return e / math.log(p.length);
  }

  String get verdict {
    if (result.confidence < 0.30 || margin < 0.10) return 'MENEBAK';
    if (!result.detected) return 'ragu';
    return 'yakin';
  }

  String get distribution {
    final p = result.probabilities;
    if (p == null) return '(tidak ada distribusi)';
    return List.generate(
      p.length,
      (i) => '${_fmt(MoneyTFLiteService.classValues[i])}:'
          '${(p[i] * 100).toStringAsFixed(1)}%',
    ).join('  ');
  }

  @override
  String toString() {
    final head = '${fx.label.padRight(22)} '
        'asli=Rp${_fmt(fx.expected).padLeft(7)}  '
        'top=${top == null ? "-" : "Rp${_fmt(top!)}"}';
    return '${head.padRight(58)}'
        'conf=${(result.confidence * 100).toStringAsFixed(1)}%  '
        'margin=${(margin * 100).toStringAsFixed(1)}  '
        'H=${entropy.toStringAsFixed(2)}  $verdict';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Kalau di-set "1", suite boleh menyerah diam-diam saat runtime TFLite
/// tidak ada. TANPA env var ini, ketiadaan runtime dianggap KEGAGALAN.
///
/// Defaultnya sengaja keras. Di host Linux/macOS, `tflite_flutter` butuh
/// `libtensorflowlite_c-<platform>.so` yang harus disediakan manual - kalau
/// tidak ada, `svc.load()` mengembalikan false dan SETIAP uji inferensi
/// meloncat ke `markTestSkipped`. Hasilnya "All tests passed!" berwarna hijau
/// di layar yang sebenarnya tidak menguji satu piksel pun.
///
/// Itu bukan skenario hipotetis: suite ini pertama kali dijalankan persis
/// dalam kondisi tersebut - 20 uji ter-skip, dan ringkasannya tetap hijau.
/// Pipeline uang bisa rusak total tanpa satu pun test berubah warna.
const _allowSkipEnv = 'GUIDIO_ALLOW_SKIP_TFLITE';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final svc = MoneyTFLiteService.instance;
  final allowSkip = Platform.environment[_allowSkipEnv] == '1';
  var modelLoaded = false;
  final readings = <_Reading>[];

  setUpAll(() async {
    modelLoaded = await svc.load();
  });

  // Dijalankan lebih dulu supaya kegagalan infrastruktur muncul sebagai satu
  // baris merah yang jelas, bukan sebagai dua puluh baris abu-abu.
  test('runtime TFLite tersedia (prasyarat semua uji inferensi)', () {
    if (modelLoaded) return;
    if (allowSkip) {
      markTestSkipped(
          'Runtime TFLite tidak ada, dilewati karena $_allowSkipEnv=1.');
      return;
    }
    fail('Runtime TFLite tidak tersedia, jadi TIDAK ADA uji inferensi uang '
        'yang benar-benar berjalan.\n\n'
        'Di host desktop, tflite_flutter memerlukan pustaka native yang harus '
        'disediakan manual. Jalankan: tool/setup_tflite_linux.sh\n'
        '(pustaka itu dipasang ke direktori artifacts engine Flutter, yang '
        'ikut terhapus setiap flutter upgrade / ganti versi FVM - jadi skrip '
        'itu perlu dijalankan lagi setelahnya).\n\n'
        'Untuk sengaja melewati (mis. CI yang memang hanya memeriksa lint), '
        'jalankan dengan $_allowSkipEnv=1 - tapi sadari suite itu tidak '
        'memvalidasi model sama sekali.');
  });

  // Gerbang kedua, dan ini bukan paranoia - kondisinya PERNAH terjadi dan
  // menghasilkan diagnosis yang salah total.
  //
  // Runtime desktop di `blobs/libtensorflowlite_c-linux.so` berasal dari
  // tflite_flutter_plugin v0.5.0 (2021). Dia memuat model terkuantisasi tanpa
  // mengeluh, mengalokasikan tensornya, menjalankan inferensinya, lalu
  // mengembalikan distribusi RATA 1/7 untuk masukan APA PUN - gambar uang,
  // gambar hitam, maupun noise acak. Tidak ada exception, tidak ada peringatan.
  //
  // Android TIDAK terpengaruh: tflite_flutter 0.12.1 memakai LiteRT 1.4.0
  // (`com.google.ai.edge.litert:litert`), yang menjalankan model yang sama
  // dengan benar. Ini murni keterbatasan pustaka desktop.
  //
  // Tanpa gerbang ini, suite melaporkan "0/5 argmax benar, 5/5 MENEBAK" dan
  // pembacanya menyimpulkan modelnya rusak, lalu mengganti model yang
  // sebenarnya sehat dengan model lain. Itu persis yang sempat terjadi.
  test('runtime bisa menjalankan model terkuantisasi', () async {
    if (!modelLoaded) {
      if (allowSkip) {
        markTestSkipped('Runtime TFLite tidak ada.');
        return;
      }
      return; // sudah dilaporkan oleh uji prasyarat di atas
    }

    final hitam = img.Image(width: 224, height: 224);
    img.fill(hitam, color: img.ColorRgb8(0, 0, 0));
    final putih = img.Image(width: 224, height: 224);
    img.fill(putih, color: img.ColorRgb8(255, 255, 255));

    final a = await svc.classifyCameraImage(toCameraImage(hitam));
    final b = await svc.classifyCameraImage(toCameraImage(putih));
    final pa = a.probabilities;
    final pb = b.probabilities;

    expect(pa, isNotNull, reason: 'Inferensi tidak mengembalikan distribusi.');
    expect(pb, isNotNull, reason: 'Inferensi tidak mengembalikan distribusi.');

    var beda = 0.0;
    for (var i = 0; i < pa!.length; i++) {
      beda = math.max(beda, (pa[i] - pb![i]).abs());
    }

    if (beda < 1e-6) {
      fail('Runtime TFLite ini TIDAK bisa menjalankan model terkuantisasi.\n\n'
          'Gambar hitam polos dan gambar putih polos menghasilkan distribusi '
          'yang identik (selisih maksimum ${beda.toStringAsExponential(2)}), '
          'artinya keluaran model tidak bergantung sama sekali pada '
          'masukannya:\n'
          '  hitam: ${pa.map((v) => v.toStringAsFixed(4)).join(", ")}\n'
          '  putih: ${pb!.map((v) => v.toStringAsFixed(4)).join(", ")}\n\n'
          'Ini BUKAN bukti modelnya rusak. blobs/libtensorflowlite_c-linux.so '
          'berasal dari tflite_flutter_plugin v0.5.0 (2021) dan tidak sanggup '
          'menjalankan model INT8, sementara Android memakai LiteRT 1.4.0 dan '
          'menjalankannya dengan benar.\n\n'
          'Jangan menilai kualitas model dari angka-angka di bawah ini. '
          'Verifikasi di perangkat Android, atau lewat runtime LiteRT modern '
          'di Python (paket pip `ai-edge-litert`).');
    }
  });

  tearDownAll(() {
    if (readings.isEmpty) return;
    readings.sort((a, b) => a.fx.label.compareTo(b.fx.label));
    final ok = readings.where((r) => r.argmaxCorrect).length;
    final confident = readings.where((r) => r.result.detected).length;
    final guessing = readings.where((r) => r.verdict == 'MENEBAK').length;

    // ignore: avoid_print
    print('\n${'═' * 78}\n  RINGKASAN PIPELINE UANG (lewat classifyCameraImage)\n${'═' * 78}');
    for (final r in readings) {
      // ignore: avoid_print
      print('  $r');
    }
    // ignore: avoid_print
    print('${'─' * 78}\n'
        '  argmax benar        : $ok/${readings.length}\n'
        '  tembus ambang 0,85  : $confident/${readings.length}\n'
        '  di zona MENEBAK     : $guessing/${readings.length}   '
        '(chance level = ${(_chance * 100).toStringAsFixed(1)}%)\n'
        '${'═' * 78}\n');
  });

  // ── A. KEAMANAN - wajib hijau selamanya ───────────────────────────────────
  //
  // Aturan tunggal yang tidak bisa ditawar: aplikasi tidak boleh menyebut
  // nominal yang salah dengan yakin. Pengguna tunanetra tidak punya cara
  // memverifikasi, jadi false positive di sini berarti kerugian uang nyata.
  // Diam ("belum yakin") selalu lebih baik daripada salah.
  group('A. KEAMANAN - tidak pernah yakin-tapi-salah', () {
    for (final fx in _fixtures) {
      test('${fx.label} tidak dibacakan sebagai nominal keliru', () async {
        if (!modelLoaded) {
          markTestSkipped('Model TFLite tidak termuat.');
          return;
        }
        final file = File(fx.path);
        expect(file.existsSync(), isTrue, reason: 'Fixture hilang: ${fx.path}');

        final decoded = img.decodeImage(file.readAsBytesSync());
        expect(decoded, isNotNull, reason: 'Gagal decode ${fx.path}');

        final result =
            await svc.classifyCameraImage(toCameraImage(decoded!));
        readings.add(_Reading(fx, result));

        if (result.detected) {
          expect(result.valueIdr, equals(fx.expected),
              reason: 'BAHAYA: ${fx.label} dibacakan sebagai '
                  'Rp${_fmt(result.valueIdr!)} dengan keyakinan '
                  '${(result.confidence * 100).toStringAsFixed(1)}%, '
                  'padahal aslinya Rp${_fmt(fx.expected)}.');
        } else {
          // Di bawah ambang, UI wajib bungkam soal angka.
          expect(result.valueIdr, isNull,
              reason: 'valueIdr harus null saat tidak yakin - UI memakainya '
                  'untuk memutuskan boleh/tidaknya menyebut nominal.');
          expect(result.message, isNotNull,
              reason: 'Saat ragu, pengguna harus dapat instruksi perbaikan.');
        }
      });
    }
  });

  // ── B. KEMAMPUAN - ratchet, sekarang MERAH ────────────────────────────────
  //
  // Kelompok ini mengukur apakah modelnya benar-benar bisa mengenali uang
  // lewat jalur produksi. Saat ditulis, model gagal di sini.
  //
  // JANGAN melonggarkan assert di bawah supaya hijau. Merahnya adalah
  // informasi: sinyal bahwa pipeline uang belum layak dipakai pengguna.
  // Yang dinaikkan adalah modelnya (lihat rupiah_vision_revised: simulasi
  // framing + `--bg-dir`), bukan ambangnya.
  group('B. KEMAMPUAN - benar-benar mengenali nominal', () {
    for (final fx in _fixtures) {
      test('${fx.label} → argmax harus Rp${_fmt(fx.expected)}', () async {
        if (!modelLoaded) {
          markTestSkipped('Model TFLite tidak termuat.');
          return;
        }
        final decoded =
            img.decodeImage(File(fx.path).readAsBytesSync())!;
        final r = _Reading(
            fx, await svc.classifyCameraImage(toCameraImage(decoded)));

        // ignore: avoid_print
        print('[${fx.label}] ${r.distribution}');

        expect(r.argmaxCorrect, isTrue,
            reason: '${fx.label}: kelas dengan probabilitas tertinggi adalah '
                '${r.top == null ? "-" : "Rp${_fmt(r.top!)}"}, '
                'seharusnya Rp${_fmt(fx.expected)}.\n'
                '  Distribusi: ${r.distribution}');
      });

      // Yang diuji: apakah nominalnya BENAR-BENAR sampai ke pengguna.
      //
      // Sebelumnya tes ini membandingkan `confidence` mentah dengan
      // `confidenceThreshold`. Itu berhenti mengukur produksi begitu gerbang
      // kedua berbasis margin ditambahkan: `10rb` dan `20rb` sekarang lolos
      // lewat margin, diucapkan ke pengguna, tapi tesnya tetap merah karena
      // keyakinannya di bawah 0,85.
      //
      // Tes yang mengukur ambang, bukan hasil, akan memaksa orang berikutnya
      // memilih antara melonggarkan gerbang atau mengabaikan tesnya. Yang
      // benar adalah menguji `detected`, karena itulah yang menentukan apakah
      // mode ini berfungsi bagi penggunanya.
      test('${fx.label} → nominalnya benar-benar diucapkan ke pengguna', () async {
        if (!modelLoaded) {
          markTestSkipped('Model TFLite tidak termuat.');
          return;
        }
        final decoded =
            img.decodeImage(File(fx.path).readAsBytesSync())!;
        final r = _Reading(
            fx, await svc.classifyCameraImage(toCameraImage(decoded)));

        final margin = r.result.margin;
        expect(r.result.detected, isTrue,
            reason: '${fx.label}: keyakinan '
                '${(r.result.confidence * 100).toStringAsFixed(1)}%'
                '${margin == null ? "" : ", margin ${(margin * 100).toStringAsFixed(1)} poin"} '
                '(gerbang: keyakinan >= ${(MoneyTFLiteService.confidenceThreshold * 100).toStringAsFixed(0)}% '
                'ATAU margin >= ${(MoneyTFLiteService.marginThreshold * 100).toStringAsFixed(0)} poin '
                'dengan keyakinan >= ${(MoneyTFLiteService.marginPathMinConfidence * 100).toStringAsFixed(0)}%; '
                'chance level ${(_chance * 100).toStringAsFixed(1)}%). '
                'Aplikasi akan bilang "belum yakin" dan tidak pernah '
                'menyebutkan nominal - mode Kenali Uang praktis tidak berfungsi.\n'
                '  Distribusi: ${r.distribution}');
      });
    }
  });

  // ── C. PARITAS - dua jalur masuk harus sepakat ────────────────────────────
  //
  // `classifyCameraImage` (kamera langsung) dan `classifyJpeg` (tombol "paksa
  // deteksi ulang") punya preprocessing TERPISAH. Keduanya pernah memakai
  // aturan crop yang berbeda, sehingga lembar yang sama bisa menghasilkan
  // dua jawaban berbeda tergantung tombol mana yang ditekan - kegagalan yang
  // mustahil didiagnosis dari laporan pengguna.
  //
  // Test ini mengunci keduanya supaya tidak menyimpang lagi.
  group('C. PARITAS - jalur kamera vs jalur JPEG sepakat', () {
    for (final fx in _fixtures) {
      test('${fx.label} konsisten antar dua jalur', () async {
        if (!modelLoaded) {
          markTestSkipped('Model TFLite tidak termuat.');
          return;
        }
        final bytes = File(fx.path).readAsBytesSync();
        final decoded = img.decodeImage(bytes)!;

        final fromCamera = await svc.classifyCameraImage(toCameraImage(decoded));
        // JPEG dibuat ulang dari sumber yang sama supaya perbedaan yang
        // terlihat murni berasal dari preprocessing, bukan dari format berkas.
        final fromJpeg = await svc.classifyJpeg(
            Uint8List.fromList(img.encodeJpg(decoded, quality: 95)));

        expect(fromJpeg.topValueIdr, equals(fromCamera.topValueIdr),
            reason: '${fx.label}: jalur kamera menebak '
                '${fromCamera.topValueIdr} tapi jalur JPEG menebak '
                '${fromJpeg.topValueIdr}. Preprocessing kedua jalur sudah '
                'menyimpang.');

        // Toleransi 0,15 menampung kompresi JPEG + pembulatan YUV; menyimpang
        // lebih jauh dari itu berarti geometri crop/letterbox-nya yang beda.
        expect((fromJpeg.confidence - fromCamera.confidence).abs(),
            lessThan(0.15),
            reason: '${fx.label}: keyakinan kamera '
                '${fromCamera.confidence.toStringAsFixed(3)} vs JPEG '
                '${fromJpeg.confidence.toStringAsFixed(3)} - terlalu jauh.');
      });
    }
  });

  // ── D. KONTRAK - hal yang membuat model diam-diam salah ───────────────────
  group('D. KONTRAK model', () {
    test('urutan kelas cocok dengan rupiah_class_info.json', () {
      final f = File('assets/models/rupiah_class_info.json');
      expect(f.existsSync(), isTrue);
      final text = f.readAsStringSync();

      // Indeks yang dipetakan ke nominal salah menghasilkan jawaban yang
      // percaya diri dan keliru - kegagalan termahal yang bisa dilakukan
      // aplikasi ini. Jadi urutannya dicocokkan, bukan diasumsikan.
      for (var i = 0; i < MoneyTFLiteService.classValues.length; i++) {
        expect(text, contains('"$i": "${MoneyTFLiteService.classValues[i]}"'),
            reason: 'Indeks $i harus memetakan ke '
                '${MoneyTFLiteService.classValues[i]} sesuai class_info.');
      }
    });

    test('semua fixture punya ground-truth yang bisa diurai', () {
      for (final fx in _fixtures) {
        expect(_valueFromFilename(fx.name), isNotNull,
            reason: 'Nama berkas ${fx.name} tidak cocok pola ground-truth.');
        expect(File(fx.path).existsSync(), isTrue, reason: 'Hilang: ${fx.path}');
      }
    });
  });
}
