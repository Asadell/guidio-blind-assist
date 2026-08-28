import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/providers/money_provider.dart';
import 'package:guidio_app/services/money_tflite_service.dart';
import 'package:image/image.dart' as img;

import 'helpers/camera_frame.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MODE KENALI UANG - UJI UJUNG KE UJUNG, PERSIS SEPERTI PENGGUNA MEMAKAINYA
///
/// Suite lain memanggil `classifyJpeg`/`classifyCameraImage` langsung. Itu
/// menguji modelnya, BUKAN aplikasinya. Di antara model dan telinga pengguna
/// masih ada gerbang keyakinan, gerbang margin, voting tiga frame, mesin
/// state, dan pemilihan kalimat - dan setiap satu di antaranya bisa membuat
/// aplikasi menyebut nominal yang salah walaupun modelnya benar.
///
/// Di sini yang dijalankan adalah rantai yang sesungguhnya:
///
///     foto PNG dari kamera ponsel
///       -> CameraImage YUV420 (tata letak Android, kroma pixelStride 2)
///       -> MoneyProvider.submitFrame()      (yang dipasang MoneyScreen ke
///                                            CameraProvider.onFrameReady)
///       -> MoneyTFLiteService.classifyCameraImage()
///       -> gerbang keyakinan + margin
///       -> voting 3 frame
///       -> MoneyProvider.snapAndAnnounce()  (tombol kiri "Kenali Uang")
///       -> teks yang benar-benar diucapkan ke pengguna
///
/// Yang di-assert adalah KALIMAT YANG TERDENGAR, bukan angka di dalam tensor.
/// Itu satu-satunya keluaran yang dipakai pengguna tunanetra.
///
/// Frame diumpankan BERKALI-KALI dengan jeda 600 ms, sama seperti aliran
/// kamera sungguhan, supaya throttle inferensi dan voting tiga frame
/// benar-benar dilewati - bukan dilangkahi.
/// ─────────────────────────────────────────────────────────────────────────────

const _fixtureRoot = 'test/fixtures/rupiah_mobile';

/// Jeda inferensi di MoneyProvider 600 ms; diberi kelebihan sedikit supaya
/// frame kedua dan ketiga tidak tertolak throttle.
const _jedaFrame = Duration(milliseconds: 650);

/// Sama dengan `_kRequiredConsecutive` di MoneyProvider.
const _frameDiumpankan = 3;

int? _groundTruth(String folder, String file) {
  if (folder == 'non_rupiah') return null;
  if (folder == '20_ribuan') return 20000;
  const prefixes = {
    '100_ribu': 100000,
    '50_ribu': 50000,
    '20_ribu': 20000,
    '10_ribu': 10000,
    '5_ribu': 5000,
    '2_ribu': 2000,
    '1_ribu': 1000,
  };
  for (final e in prefixes.entries) {
    if (file.toLowerCase().startsWith(e.key)) return e.value;
  }
  return null;
}

class _Kasus {
  final String label;
  final File file;

  /// Null berarti HARUS DITOLAK (bukan uang), bukan "tidak diketahui".
  final int? harusnya;

  const _Kasus(this.label, this.file, this.harusnya);
  bool get uang => harusnya != null;
}

List<_Kasus> _kumpulkan() {
  final root = Directory(_fixtureRoot);
  if (!root.existsSync()) return const [];
  final out = <_Kasus>[];
  for (final sub in root.listSync().whereType<Directory>()) {
    final folder = sub.uri.pathSegments.where((s) => s.isNotEmpty).last;
    for (final f in sub.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.toLowerCase().endsWith('.png') &&
          !name.toLowerCase().endsWith('.jpg')) {
        continue;
      }
      out.add(_Kasus('$folder/$name', f, _groundTruth(folder, name)));
    }
  }
  out.sort((a, b) => a.label.compareTo(b.label));
  return out;
}

String _rp(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

/// Hasil satu sesi pemakaian: umpan beberapa frame, lalu tekan tombol.
class _Sesi {
  final MoneyState state;
  final int lastAmount;
  final List<String> diucapkan;

  const _Sesi(this.state, this.lastAmount, this.diucapkan);

  /// Aplikasi menyebut nominal ke pengguna.
  bool get menyebutNominal => state == MoneyState.detected;

  String get kalimat => diucapkan.isEmpty ? '(diam)' : diucapkan.last;
}

/// Jalankan mode Kenali Uang atas satu foto, persis seperti pengguna:
/// kamera mengalirkan frame, lalu pengguna menekan tombol kiri.
Future<_Sesi> _pakaiAplikasi(img.Image foto) async {
  final provider = MoneyProvider();
  final diucapkan = <String>[];
  provider.onSpeak =
      (text, tier, {bool langsung = false}) => diucapkan.add(text);

  final siap = await provider.enableRealModel();
  expect(siap, isTrue,
      reason: 'Model tidak termuat, jadi yang diuji bukan jalur sungguhan.');

  provider.start();

  // Aliran kamera: frame yang sama berulang, dengan jeda seperti aslinya.
  final frame = toCameraImage(foto);
  for (var i = 0; i < _frameDiumpankan; i++) {
    if (i > 0) await Future<void>.delayed(_jedaFrame);
    await provider.submitFrame(frame);
  }

  // Pengguna menekan tombol kiri "Kenali Uang".
  provider.snapAndAnnounce();

  final sesi = _Sesi(provider.state, provider.lastAmount, List.of(diucapkan));
  provider.dispose();
  return sesi;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kasus = _kumpulkan();
  var runtimeSehat = false;
  final laporan = <String>[];
  var benar = 0, salah = 0, bocor = 0, ragu = 0;

  setUpAll(() async {
    if (kasus.isEmpty) return;
    if (!await MoneyTFLiteService.instance.load()) return;

    // Runtime desktop dari tflite_flutter_plugin v0.5.0 memuat model INT8
    // tanpa mengeluh lalu mengembalikan distribusi rata untuk masukan apa pun.
    // Kalau itu yang terjadi, SEMUA foto berakhir "belum yakin" dan assert
    // keamanan di bawah lulus tanpa menguji apa pun. Penjelasan lengkap dan
    // buktinya ada di money_pipeline_test.dart.
    final svc = MoneyTFLiteService.instance;
    final hitam = img.Image(width: 224, height: 224);
    img.fill(hitam, color: img.ColorRgb8(0, 0, 0));
    final putih = img.Image(width: 224, height: 224);
    img.fill(putih, color: img.ColorRgb8(255, 255, 255));
    final a = await svc.classifyCameraImage(toCameraImage(hitam));
    final b = await svc.classifyCameraImage(toCameraImage(putih));
    final pa = a.probabilities, pb = b.probabilities;
    if (pa == null || pb == null) return;
    var beda = 0.0;
    for (var i = 0; i < pa.length; i++) {
      final d = (pa[i] - pb[i]).abs();
      if (d > beda) beda = d;
    }
    runtimeSehat = beda >= 1e-6;
  });

  test('prasyarat: fixture foto ponsel dan runtime yang sanggup', () {
    if (kasus.isEmpty) {
      markTestSkipped('Folder $_fixtureRoot tidak ada (di-gitignore). '
          'Salin dengan: cp -r ../../test/rupiah/. $_fixtureRoot/');
      return;
    }
    if (!runtimeSehat) {
      markTestSkipped(
          'Runtime TFLite desktop ini tidak bisa menjalankan model INT8 - '
          'keluarannya identik untuk masukan apa pun, jadi seluruh sesi di '
          'bawah dilewati agar tidak melaporkan kelulusan palsu. Uji di '
          'perangkat Android, atau pakai tool/eval_rupiah_litert.py.');
      return;
    }
    expect(kasus.length, greaterThanOrEqualTo(10));
  });

  group('sesi pemakaian nyata', () {
    for (final k in _kumpulkan()) {
      test(k.label, () async {
        if (!runtimeSehat) {
          markTestSkipped('Runtime tidak sanggup, lihat uji prasyarat.');
          return;
        }
        final foto = img.decodeImage(k.file.readAsBytesSync());
        expect(foto, isNotNull, reason: '${k.label} gagal didekode.');

        final sesi = await _pakaiAplikasi(foto!);

        final harusnya = k.uang ? _rp(k.harusnya!) : 'BUKAN UANG';
        final terdengar = sesi.menyebutNominal
            ? _rp(sesi.lastAmount)
            : 'belum yakin';
        laporan.add('${k.label.padRight(28)} ${harusnya.padLeft(10)}  '
            '-> ${terdengar.padRight(12)} "${sesi.kalimat}"');

        if (!sesi.menyebutNominal) {
          ragu++;
        } else if (!k.uang) {
          bocor++;
        } else if (sesi.lastAmount == k.harusnya) {
          benar++;
        } else {
          salah++;
        }

        // Satu-satunya assert yang tidak boleh gagal: kalau aplikasi
        // menyebutkan nominal, nominal itu harus benar. Pengguna tunanetra
        // tidak punya cara memeriksanya sendiri.
        if (sesi.menyebutNominal && k.uang) {
          expect(sesi.lastAmount, equals(k.harusnya),
              reason: 'BAHAYA: ${k.label} bernilai ${_rp(k.harusnya!)} tapi '
                  'aplikasi mengucapkan "${sesi.kalimat}".');
        }
        if (sesi.menyebutNominal && !k.uang) {
          fail('BOCOR: ${k.label} bukan uang, tapi aplikasi mengucapkan '
              '"${sesi.kalimat}" (${_rp(sesi.lastAmount)}).');
        }
      });
    }
  });

  tearDownAll(() {
    if (laporan.isEmpty) return;
    const bar = '═══════════════════════════════════════════════'
        '═══════════════════════════════════════════════';
    // ignore: avoid_print
    print('\n$bar\n  SESI KENALI UANG - apa yang BENAR-BENAR '
        'terdengar oleh pengguna\n$bar');
    for (final l in laporan) {
      // ignore: avoid_print
      print('  $l');
    }
    // ignore: avoid_print
    print('${'─' * 94}\n'
        '  disebut & benar   : $benar\n'
        '  DISEBUT SALAH     : $salah   (harus 0)\n'
        '  bukan uang, bocor : $bocor   (harus 0)\n'
        '  belum yakin       : $ragu\n$bar\n');
  });
}
