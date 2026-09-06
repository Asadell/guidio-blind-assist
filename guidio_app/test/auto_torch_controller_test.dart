import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/auto_torch_controller.dart';

/// Uji [AutoTorchController] - aturan "kapan lampu senter menyala dan mati
/// sendiri".
///
/// Yang diuji di sini bukan kerapian kode, melainkan satu kegagalan yang
/// sangat mungkin terjadi dan sangat sulit dilihat dari membaca kodenya:
/// **lampu yang menyala membuat frame terang, lalu keterangan itu dipakai
/// sebagai alasan mematikan lampu.** Akibatnya bagi pengguna tunanetra bukan
/// lampu yang berkedip - itu bahkan tidak dia lihat - melainkan aplikasi yang
/// mengucapkan "Lampu dinyalakan / Lampu dimatikan" tanpa henti sambil
/// menutupi setiap peringatan rintangan di antaranya.
///
/// Semua waktu di sini palsu. Menguji jeda dua sampai lima detik dengan
/// `Future.delayed` akan membuat berkas ini berjalan setengah menit dan
/// sesekali gagal karena mesin CI sedang sibuk.
void main() {
  const gelap = 10.0;   // ruangan gelap
  const terang = 150.0; // siang hari
  final t0 = DateTime(2026, 1, 1, 12);

  /// Simulasi ruangan yang JUJUR: kamera melihat cahaya sekitar DITAMBAH
  /// sumbangan lampu senter kalau ia sedang menyala.
  ///
  /// Umpan luma yang tetap - "terang terus" atau "gelap terus" - tidak bisa
  /// menguji fitur ini sama sekali, karena justru sambungan balik itulah
  /// masalahnya: lampu yang menyala mengubah angka yang dipakai untuk
  /// memutuskan apakah lampu harus menyala. Tanpa memodelkannya, uji
  /// "ruangan gelap" sebenarnya menguji "ruangan yang ajaibnya tetap gelap
  /// walau senter menyala di dalamnya".
  ///
  /// Versi pertama berkas ini melakukan persis kesalahan itu dan menuduh
  /// kodenya salah.
  const ruangan = _Ruangan.new;

  /// Umpankan [luma] berulang sampai [durasi] terlewati, kembalikan SEMUA aksi
  /// yang bukan `none`. Frame kamera datang sekitar 8 kali per detik.
  ///
  /// Dipakai untuk uji yang TIDAK bergantung pada sumbangan lampu - aturan
  /// perbuatan pengguna dan saklar Pengaturan.
  List<AutoTorchAction> alirkan(
    AutoTorchController c, {
    required double luma,
    required Duration durasi,
    required DateTime mulai,
  }) {
    final hasil = <AutoTorchAction>[];
    for (var ms = 0; ms <= durasi.inMilliseconds; ms += 125) {
      final aksi = c.update(
        luma: luma,
        now: mulai.add(Duration(milliseconds: ms)),
      );
      if (aksi != AutoTorchAction.none) hasil.add(aksi);
    }
    return hasil;
  }

  group('menyalakan saat gelap', () {
    test('gelap sesaat TIDAK menyalakan lampu', () {
      final c = AutoTorchController();
      // Tangan yang menutupi kamera sepersekian detik, atau berjalan melewati
      // bayangan. Lampu yang menyala untuk itu menyala sepanjang hari.
      final aksi = alirkan(c,
          luma: gelap, durasi: kAutoTorchOnDwell - const Duration(milliseconds: 300), mulai: t0);
      expect(aksi, isEmpty);
      expect(c.state, AutoTorchState.idle);
    });

    test('gelap yang bertahan menyalakan lampu, TEPAT SEKALI', () {
      final c = AutoTorchController();
      final aksi = alirkan(c,
          luma: gelap, durasi: const Duration(seconds: 30), mulai: t0);
      expect(aksi, [AutoTorchAction.turnOn],
          reason: 'gelap yang terus-menerus adalah SATU keadaan, bukan '
              'ratusan keputusan - satu per frame yang masuk');
      expect(c.ownsTorch, isTrue);
    });

    test('menyala sebelum peringatan "terlalu gelap" berbunyi', () {
      // CameraProvider mengucapkan "Terlalu gelap ... Nyalakan lampu" pada
      // detik ketiga. Kalau lampu otomatis lebih lambat dari itu, pengguna
      // disuruh menyalakan lampu yang semilidetik kemudian menyala sendiri.
      expect(kAutoTorchOnDwell, lessThan(const Duration(seconds: 3)));
    });
  });

  group('mematikan saat terang - dan tidak sebelum dipastikan', () {
    test('terang sesaat tidak mengusik lampu yang sudah menyala', () {
      final r = ruangan(sekitar: gelap, sumbanganLampu: 40, mulai: t0)
        ..jalankan(kAutoTorchOnDwell + const Duration(milliseconds: 200));
      expect(r.aksi, [AutoTorchAction.turnOn]);

      // Lampu ruangan menyala sekejap lalu padam lagi (pintu terbuka, mobil
      // lewat). Belum cukup lama untuk mengubah keputusan apa pun.
      r.sekitar = terang;
      r.jalankan(kAutoTorchOffDwell - const Duration(milliseconds: 500));
      expect(r.aksi, [AutoTorchAction.turnOn]);
      expect(r.c.state, AutoTorchState.lit);
      expect(r.lampuNyala, isTrue);
    });

    test('cahaya sekitar benar-benar kembali: ukur dulu, baru matikan', () {
      final r = ruangan(sekitar: gelap, sumbanganLampu: 40, mulai: t0)
        ..jalankan(kAutoTorchOnDwell + const Duration(milliseconds: 200));

      // Pengguna keluar ke halaman - cahaya sekitar yang berubah, bukan
      // lampunya.
      r.sekitar = terang;
      r.jalankan(kAutoTorchOffDwell + kAutoTorchProbeWindow +
          const Duration(seconds: 1));

      expect(r.aksi, [
        AutoTorchAction.turnOn,
        // Lampu dimatikan dulu tanpa suara untuk mengukur ...
        AutoTorchAction.probeOff,
        // ... barulah "Lampu dimatikan." boleh diucapkan.
        AutoTorchAction.confirmOff,
      ]);
      expect(r.lampuNyala, isFalse);
      expect(r.c.ownsTorch, isFalse);
    });

    test(
        'KEGAGALAN UTAMA: frame yang terang KARENA lampunya sendiri tidak '
        'pernah menghasilkan pengumuman', () {
      // Kamera menempel di permukaan terang di ruangan gelap: lampu senter
      // menjenuhkan frame sampai jauh melebihi siang hari. Inilah kasus yang
      // membuat histeresis setinggi apa pun gagal - tidak ada ambang yang
      // bisa memisahkan "terang karena matahari" dari "terang karena senter".
      final r = ruangan(sekitar: gelap, sumbanganLampu: 245, mulai: t0)
        ..jalankan(const Duration(minutes: 3));

      expect(r.aksi.where((a) => a == AutoTorchAction.confirmOff), isEmpty,
          reason: 'JANGAN PERNAH mengumumkan "Lampu dimatikan." di ruangan '
              'yang masih gelap - itu satu-satunya hal yang tidak bisa '
              'diperiksa sendiri oleh pengguna tunanetra');
      expect(r.aksi.first, AutoTorchAction.turnOn);
      expect(r.aksi.where((a) => a == AutoTorchAction.turnOn).length, 1,
          reason: 'satu keadaan gelap = satu pengumuman, bukan satu per '
              'putaran pengukuran');
      expect(r.c.state, AutoTorchState.lit);
      expect(r.lampuNyala, isTrue, reason: 'lampunya harus tetap menyala');
    });

    test('pengukuran yang gagal makin jarang diulang', () {
      // Konsekuensi praktis dari kasus di atas: kedipan pengukuran tidak
      // berubah jadi kedipan tiap setengah menit selamanya.
      final r = ruangan(sekitar: gelap, sumbanganLampu: 245, mulai: t0)
        ..jalankan(const Duration(minutes: 10));

      final jarak = <Duration>[];
      for (var i = 1; i < r.waktuProbe.length; i++) {
        jarak.add(r.waktuProbe[i].difference(r.waktuProbe[i - 1]));
      }
      expect(jarak.length, greaterThanOrEqualTo(3),
          reason: 'butuh beberapa jarak untuk membuktikan ia melebar lalu '
              'berhenti melebar');
      for (var i = 1; i < jarak.length; i++) {
        expect(jarak[i], greaterThanOrEqualTo(jarak[i - 1]),
            reason: 'jarak antar pengukuran tidak boleh mengecil - kalau ia '
                'mengecil, kasus terburuknya justru makin sering berkedip');
      }
      // Mulai rapat, berakhir di batas atas. Dua sisinya sama-sama disengaja:
      // rapat di awal supaya lampu cepat padam saat cahaya benar-benar
      // kembali, dan berbatas di akhir supaya pengguna yang keluar ke tempat
      // terang sesudah lama menempel di dinding tidak menunggu berjam-jam.
      expect(jarak.first, lessThan(const Duration(seconds: 90)));
      expect(jarak.last, greaterThanOrEqualTo(const Duration(minutes: 2)));
      expect(jarak.last, lessThan(const Duration(minutes: 3)),
          reason: 'batas atasnya harus benar-benar mengikat');
    });

    test('gelap lagi sesudah lampu dimatikan: fitur bekerja lagi', () {
      final r = ruangan(sekitar: gelap, sumbanganLampu: 40, mulai: t0)
        ..jalankan(kAutoTorchOnDwell + const Duration(milliseconds: 200));
      r.sekitar = terang;
      r.jalankan(kAutoTorchOffDwell + kAutoTorchProbeWindow +
          const Duration(seconds: 1));
      expect(r.lampuNyala, isFalse);

      // Masuk ruangan gelap berikutnya - lorong, kamar mandi, tangga.
      r.aksi.clear();
      r.sekitar = gelap;
      r.jalankan(kAutoTorchOnDwell + const Duration(milliseconds: 200));
      expect(r.aksi, [AutoTorchAction.turnOn]);
    });
  });

  group('perbuatan pengguna selalu menang', () {
    test('mematikan lampu sendiri menghentikan fitur sampai terang lagi', () {
      final c = AutoTorchController();
      expect(alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0),
          [AutoTorchAction.turnOn]);

      c.onManualTorchChange(false);
      expect(c.state, AutoTorchState.suppressed);

      // Ruangan yang sama, masih gelap, satu menit penuh. Lampu TIDAK boleh
      // menyala lagi: pengguna yang harus mematikan hal yang sama dua kali
      // menyimpulkan tombolnya tidak bekerja.
      final aksi = alirkan(c,
          luma: gelap,
          durasi: const Duration(minutes: 1),
          mulai: t0.add(const Duration(seconds: 5)));
      expect(aksi, isEmpty);
      expect(c.state, AutoTorchState.suppressed);
    });

    test('fitur pulih sesudah pengguna kembali ke tempat terang', () {
      final c = AutoTorchController()..onManualTorchChange(false);

      // Keluar ke tempat terang - penangguhannya batal.
      alirkan(c, luma: terang, durasi: const Duration(seconds: 2), mulai: t0);
      expect(c.state, AutoTorchState.idle);

      // Masuk ruangan gelap berikutnya: fitur bekerja lagi.
      final aksi = alirkan(c,
          luma: gelap,
          durasi: kAutoTorchOnDwell,
          mulai: t0.add(const Duration(seconds: 10)));
      expect(aksi, [AutoTorchAction.turnOn]);
    });

    test('"Lewati" pada tawaran lampu diperlakukan sebagai penolakan', () {
      final c = AutoTorchController()..onLightDeclined();
      expect(
        alirkan(c, luma: gelap, durasi: const Duration(seconds: 30), mulai: t0),
        isEmpty,
        reason: 'tawaran yang ditolak lalu dijawab sendiri oleh aplikasi '
            'membuat pilihan yang ditawarkan berhenti berarti',
      );
    });

    test('menyalakan lampu sendiri TIDAK diambil alih fitur ini', () {
      final c = AutoTorchController()..onManualTorchChange(true);
      // Lampunya milik pengguna. Fitur ini tidak berhak mematikan sesuatu
      // yang tidak dinyalakannya.
      expect(c.ownsTorch, isFalse);
      final aksi = alirkan(c,
          luma: terang, durasi: const Duration(minutes: 1), mulai: t0);
      expect(aksi, isEmpty);
    });
  });

  group('saklar di Pengaturan', () {
    test('dimatikan selagi lampu menyala: lampunya ikut padam', () {
      final c = AutoTorchController();
      alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0);
      expect(c.ownsTorch, isTrue);

      // Pengguna masuk bioskop dan mematikan fiturnya. Yang dia inginkan
      // adalah lampunya padam, bukan lampu yang sudah menyala dibiarkan
      // menyala sampai dia menemukan tombol keduanya.
      expect(c.setEnabled(false), AutoTorchAction.confirmOff);
      expect(c.state, AutoTorchState.idle);
    });

    test('dimatikan saat lampu memang mati: tidak ada yang perlu dikerjakan',
        () {
      final c = AutoTorchController();
      expect(c.setEnabled(false), AutoTorchAction.none);
    });

    test('mati berarti benar-benar diam, sekelam apa pun ruangannya', () {
      final c = AutoTorchController()..setEnabled(false);
      expect(
        alirkan(c, luma: 0, durasi: const Duration(minutes: 5), mulai: t0),
        isEmpty,
      );
    });

    test('dinyalakan lagi: mulai dari keadaan bersih', () {
      final c = AutoTorchController()
        ..onManualTorchChange(false) // suppressed
        ..setEnabled(false)
        ..setEnabled(true);
      expect(c.state, AutoTorchState.idle,
          reason: 'menyalakan ulang fitur adalah permintaan eksplisit supaya '
              'ia bekerja - penangguhan lama tidak boleh ikut terbawa');
      expect(alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0),
          [AutoTorchAction.turnOn]);
    });
  });

  group('keadaan yang tidak boleh menggantung', () {
    test('aliran frame berhenti di tengah pengukuran: lampu dinyalakan lagi',
        () {
      final c = AutoTorchController();
      alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0);
      final t = t0.add(kAutoTorchOnDwell);
      alirkan(c,
          luma: terang,
          durasi: kAutoTorchOffDwell + const Duration(milliseconds: 200),
          mulai: t);
      expect(c.state, AutoTorchState.probing);

      // Pengguna berpindah mode / memotret: aliran frame berhenti persis di
      // sini. Tanpa pembereskan, lampu tinggal mati dan tidak ada satu frame
      // pun lagi yang akan datang untuk menyalakannya kembali.
      expect(c.onFramesStopped(), AutoTorchAction.revertOn);
      expect(c.state, AutoTorchState.lit);
    });

    test('aliran berhenti di luar pengukuran: lampu tidak diusik', () {
      final c = AutoTorchController();
      alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0);
      expect(c.onFramesStopped(), AutoTorchAction.none);
      expect(c.state, AutoTorchState.lit);
    });

    test('perangkat tanpa lampu: fitur tidak macet selamanya', () {
      final c = AutoTorchController();
      expect(alirkan(c, luma: gelap, durasi: kAutoTorchOnDwell, mulai: t0),
          [AutoTorchAction.turnOn]);

      // `setTorch` mengembalikan false - lampunya tidak pernah menyala.
      c.onTorchFailed(AutoTorchAction.turnOn);
      expect(c.ownsTorch, isFalse,
          reason: 'jangan mengira memegang lampu yang tidak pernah menyala - '
              'kalau tidak, fitur ini akan menunggu selamanya untuk '
              'mematikan sesuatu yang memang sudah mati');

      // Dan ia masih boleh mencoba lagi nanti.
      expect(
        alirkan(c,
            luma: gelap,
            durasi: kAutoTorchOnDwell,
            mulai: t0.add(const Duration(seconds: 10))),
        [AutoTorchAction.turnOn],
      );
    });
  });
}


/// Ruangan buatan: kamera melihat [sekitar] ditambah [sumbanganLampu] kalau
/// lampu senter menyala.
///
/// [sumbanganLampu] yang berbeda memodelkan dua keadaan yang sangat berbeda
/// dan keduanya nyata: senter yang menerangi lorong panjang menyumbang sedikit
/// (frame tetap remang), senter yang mengarah ke dinding sejarak sejengkal
/// menjenuhkan seluruh frame.
class _Ruangan {
  double sekitar;
  final double sumbanganLampu;

  final AutoTorchController c = AutoTorchController();
  final List<AutoTorchAction> aksi = [];
  final List<DateTime> waktuProbe = [];

  bool lampuNyala = false;
  DateTime now;

  _Ruangan({
    required this.sekitar,
    required this.sumbanganLampu,
    required DateTime mulai,
  }) : now = mulai;

  void jalankan(Duration durasi) {
    final akhir = now.add(durasi);
    while (now.isBefore(akhir)) {
      final luma =
          (sekitar + (lampuNyala ? sumbanganLampu : 0)).clamp(0.0, 255.0);
      final a = c.update(luma: luma, now: now);
      switch (a) {
        case AutoTorchAction.turnOn:
        case AutoTorchAction.revertOn:
          lampuNyala = true;
        case AutoTorchAction.probeOff:
          lampuNyala = false;
          waktuProbe.add(now);
        case AutoTorchAction.confirmOff:
        case AutoTorchAction.none:
          break;
      }
      if (a != AutoTorchAction.none) aksi.add(a);
      // Aliran frame kamera, sekitar 8 kali per detik.
      now = now.add(const Duration(milliseconds: 125));
    }
  }
}
