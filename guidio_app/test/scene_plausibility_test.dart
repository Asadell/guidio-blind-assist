import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/pidnet_service.dart';
import 'package:guidio_app/widgets/zone_indicator.dart' show ZoneStatus;

/// Tes untuk gerbang kelayakan pemandangan di Mode Navigasi.
///
/// ## Kenapa gerbang ini ada
///
/// PIDNet selalu menjawab. Diarahkan ke langit-langit kamar, tembok polos,
/// atau bagian dalam saku, dia tetap memberi label ke setiap piksel - dan
/// permukaan polos yang luas gampang jatuh ke kelas "walkable". Dari sana
/// rasio zona terbaca "tengah 100% layak jalan", dan aplikasi mengucapkan
/// **"Jalur aman, jalan lurus"** untuk foto langit-langit.
///
/// Kalimat itu menyuruh orang yang tidak bisa memverifikasi apa pun untuk
/// melangkah maju. Ini kelas kesalahan yang sama dengan halusinasi VLM di
/// endpoint deskripsi, cuma taruhannya langkah kaki alih-alih kalimat.
///
/// Ambang di sini sengaja LONGGAR: menolak terlalu sering di mode navigasi
/// lebih merugikan daripada di mode lain, karena pengguna sedang berjalan.
/// Yang dikejar hanya frame yang benar-benar tidak masuk akal.

const int _w = 64;
const int _h = 48;

/// Bangun mask uji dari fungsi per-piksel.
List<int> _mask(int Function(int x, int y) f) => [
      for (var y = 0; y < _h; y++)
        for (var x = 0; x < _w; x++) f(x, y),
    ];

/// Pemandangan trotoar yang wajar: jalur di bawah, bangunan/langit di atas.
List<int> _sidewalk() => _mask((x, y) => y > _h * 0.45 ? 1 : 0);

void main() {
  group('assessScene - pemandangan wajar diterima', () {
    test('trotoar biasa lolos', () {
      expect(assessScene(_sidewalk(), _w, _h), SceneDoubt.none);
    });

    test('trotoar dengan lubang tetap lolos', () {
      // Hazard TIDAK boleh membuat frame dianggap meragukan - justru inilah
      // frame yang paling penting untuk diproses sampai tuntas.
      final m = _mask((x, y) {
        if (y > _h * 0.7 && x > _w * 0.4 && x < _w * 0.6) return 2;
        return y > _h * 0.45 ? 1 : 0;
      });
      expect(assessScene(m, _w, _h), SceneDoubt.none);
    });

    test('jalur sempit di satu sisi tetap lolos', () {
      // Trotoar sempit terjepit tembok: sedikit walkable, tapi menyentuh
      // bagian bawah frame. Ini kondisi nyata, bukan kesalahan.
      final m = _mask((x, y) => (y > _h * 0.5 && x < _w * 0.3) ? 1 : 0);
      expect(assessScene(m, _w, _h), SceneDoubt.none);
    });

    test('tidak ada jalur sama sekali BUKAN keraguan', () {
      // Berdiri menghadap tembok pagar: jawaban "tidak ada jalur aman" itu
      // sah dan berguna. Menandainya sebagai "tidak terbaca" akan menukar
      // peringatan yang benar dengan permintaan membetulkan kamera - dan
      // pengguna akan sibuk mengatur ponsel alih-alih memutar badan.
      final m = _mask((x, y) => (y > _h * 0.8 && x > _w * 0.45 && x < _w * 0.55) ? 1 : 0);
      expect(assessScene(m, _w, _h), isNot(SceneDoubt.degenerate));
    });

    test('frame seluruhnya non-walkable atau hazard tidak dijaga di sini', () {
      // Keduanya sudah gagal ke arah yang AMAN: status zonanya jadi `danger`
      // dan pengguna mendengar "Berhenti dulu, tidak ada jalur aman". Gerbang
      // ini sengaja asimetris - yang dijaga cuma bentuk yang menghasilkan
      // lampu hijau palsu.
      expect(assessScene(_mask((x, y) => 0), _w, _h), SceneDoubt.none);
      expect(assessScene(_mask((x, y) => 2), _w, _h), SceneDoubt.none);
    });
  });

  group('assessScene - frame tanpa struktur ditolak', () {
    test('seluruhnya walkable: lantai polos, tembok, atau lensa tertutup', () {
      // Inilah kasus yang paling berbahaya. Tanpa gerbang ini, frame seperti
      // ini menghasilkan "tengah 100% layak jalan" → "Jalur aman, jalan lurus".
      expect(assessScene(_mask((x, y) => 1), _w, _h), SceneDoubt.degenerate);
    });

    test('99% walkable masih dianggap tanpa struktur', () {
      var n = 0;
      final m = _mask((x, y) => (n++ % 100 == 0) ? 0 : 1);
      expect(assessScene(m, _w, _h), SceneDoubt.degenerate);
    });
  });

  group('assessScene - jalur yang tidak menyentuh tanah', () {
    test('kamera menghadap ke atas: jalur hanya di bagian atas frame', () {
      // Jalur terlihat jauh di depan, tapi tepat di depan kaki tidak ada
      // apa-apa yang terbaca. Menyuruh maju berdasarkan ini berarti menyuruh
      // melangkah ke bagian yang justru tidak dilihat sistem.
      final m = _mask((x, y) => y < _h * 0.35 ? 1 : 0);
      expect(assessScene(m, _w, _h), SceneDoubt.notGrounded);
    });

    test('jalur menyentuh pita bawah tetap lolos', () {
      final m = _mask((x, y) => y > _h * 0.6 ? 1 : 0);
      expect(assessScene(m, _w, _h), SceneDoubt.none);
    });
  });

  group('assessScene - masukan rusak tidak menjatuhkan', () {
    test('mask kosong', () {
      expect(assessScene(const [], _w, _h), SceneDoubt.degenerate);
    });

    test('dimensi tidak cocok dengan panjang mask', () {
      // Kalau ukuran model berubah tapi konstanta di sini tidak ikut, lebih
      // baik menolak terang-terangan daripada membaca di luar batas array
      // atau menilai geometri yang salah tanpa ada yang tahu.
      expect(assessScene(List.filled(10, 1), _w, _h), SceneDoubt.degenerate);
    });

    test('dimensi nol', () {
      expect(assessScene(List.filled(10, 1), 0, 0), SceneDoubt.degenerate);
    });

    test('nilai kelas di luar 0..2 tidak melempar', () {
      // Mask datang dari argmax jadi seharusnya selalu 0..2. "Seharusnya"
      // bukan jaminan, dan fungsi yang melempar di sini akan mematikan
      // seluruh arahan navigasi.
      expect(() => assessScene(_mask((x, y) => 7), _w, _h), returnsNormally);
    });
  });

  group('ZoneAnalysis.isUntrustworthy', () {
    ZoneAnalysis build(SceneDoubt d) => ZoneAnalysis(
          leftRatio: 0.9, centerRatio: 0.9, rightRatio: 0.9,
          left: ZoneStatus.safe, center: ZoneStatus.safe, right: ZoneStatus.safe,
          recommendedZone: 1, inferenceMs: 10, doubt: d,
        );

    test('pemandangan wajar boleh dipercaya', () {
      expect(build(SceneDoubt.none).isUntrustworthy, isFalse);
    });

    test('zona hijau semua TIDAK cukup kalau frame-nya meragukan', () {
      // Justru kombinasi inilah yang berbahaya: rasio zona terlihat sempurna
      // PERSIS karena frame-nya satu warna polos.
      expect(build(SceneDoubt.degenerate).isUntrustworthy, isTrue);
      expect(build(SceneDoubt.notGrounded).isUntrustworthy, isTrue);
    });
  });
}
