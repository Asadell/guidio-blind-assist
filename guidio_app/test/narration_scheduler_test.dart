import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/speech/tts_queue.dart';
import 'package:guidio_app/core/voice/narration_scheduler.dart';
import 'package:guidio_app/models/detection.dart';

/// Tes untuk [NarrationScheduler] - lapisan yang memutuskan KAPAN dan DALAM
/// BENTUK APA hasil deteksi diucapkan.
///
/// Simulasi Python (`sim_tts_verification.py`) memverifikasi ALGORITMANYA.
/// Berkas ini memverifikasi KODE DART-nya, dan bedanya nyata: port Python
/// tidak memakai `Detection` sungguhan, jadi dia tidak akan pernah menangkap
/// kesalahan pembacaan field dari model deteksi yang sebenarnya.
Detection _det({
  required String labelId,
  required String direction,
  required String danger,
  required double meter,
  int? trackId,
  bool approaching = false,
}) =>
    Detection(
      labelEn: labelId,
      labelId: labelId,
      confidence: 0.9,
      distanceMeter: meter,
      direction: direction,
      dangerLevel: danger,
      // Nilai pixel yang sengaja BESAR. Versi awal scheduler menghitung zona
      // dari `bboxCx` (yang bersatuan pixel) lalu membandingkannya dengan
      // ambang pecahan 0,35/0,65 - dengan bbox seperti ini semua objek jatuh
      // ke "kanan". Tes arah di bawah akan gagal kalau itu terulang.
      bbox: const {'x1': 400, 'y1': 200, 'x2': 700, 'y2': 600},
      inferenceMs: 12,
      isApproaching: approaching,
      trackId: trackId,
    );

void main() {
  group('Mode Deteksi Objek melaporkan, tidak memvonis', () {
    // Mode ini menjalankan pengenal objek COCO. Ia tahu ada orang satu meter
    // di depan; ia tidak tahu, dan tidak punya cara tahu, apakah itu
    // berbahaya. Kata "Bahaya" dan "Awas" karena itu tidak boleh keluar dari
    // jalur ini sama sekali.
    //
    // Yang dijaga bukan kerapian bahasa. Orang yang lewat di depan kamera
    // adalah kejadian paling sering di mode ini; peringatan bahaya yang
    // terucap puluhan kali sehari mengajari pengguna mengabaikan kata itu,
    // dan yang ikut runtuh adalah Mode Navigasi - satu-satunya tempat kata
    // itu benar-benar berarti lubang di depan kaki.
    const vonis = ['bahaya', 'awas', 'hati-hati'];

    test('objek sangat dekat pun disebut "Ada ...", bukan "Awas ..."', () {
      final s = NarrationScheduler()..beginSession();
      final d = s.process([
        _det(labelId: 'orang', direction: 'depan', danger: 'critical',
            meter: 0.8, trackId: 1),
      ]);

      expect(d.shouldSpeak, isTrue);
      expect(d.message, startsWith('Ada orang'),
          reason: 'kalimatnya laporan: "Ada orang tepat di depan"');
      for (final kata in vonis) {
        expect(d.message!.toLowerCase(), isNot(contains(kata)),
            reason: 'mode deteksi objek tidak berhak mengeluarkan vonis '
                '"$kata" - yang dimilikinya cuma nama kelas dan jarak.');
      }
      // Yang TETAP dipertahankan: kecepatannya. Objek sedekat ini masih
      // memotong antrean; ia cuma tidak lagi dibungkus vonis.
      expect(d.tier, SpeechTier.critical);
      expect(d.interruptible, isFalse);
    });

    test('Detection.objectMessage menyebut objek dan lokasinya, tanpa vonis',
        () {
      final dekat = _det(labelId: 'orang', direction: 'depan',
          danger: 'critical', meter: 0.8);
      expect(dekat.objectMessage,
          'Ada orang di depan, kurang dari satu meter');

      final jauh = _det(labelId: 'laptop', direction: 'kiri',
          danger: 'warning', meter: 2.4);
      expect(jauh.objectMessage, 'Ada laptop di kiri, sekitar 2 meter');

      for (final d in [dekat, jauh]) {
        for (final kata in vonis) {
          expect(d.objectMessage.toLowerCase(), isNot(contains(kata)));
        }
      }
    });

    test('kelas tanpa nama Indonesia tidak menghasilkan kalimat bolong', () {
      // "Ada  di depan" terdengar seperti mesin suara yang macet, bukan
      // seperti objek yang tidak dikenal - dan pengguna tidak punya layar
      // untuk memeriksa mana di antara keduanya yang terjadi.
      final anonim = _det(labelId: '', direction: 'kanan',
          danger: 'info', meter: 3);
      expect(anonim.objectMessage, 'Ada objek di kanan, sekitar 3 meter');
    });

    test('Mode Navigasi TETAP boleh mendesak - ttsMessage tidak ikut berubah',
        () {
      // Pemisahan inilah gunanya dua getter. Kalau suatu saat keduanya
      // disatukan "supaya konsisten", yang hilang adalah nada mendesak pada
      // satu-satunya kalimat yang memang harus menghentikan langkah kaki.
      final lubang = _det(labelId: 'lubang', direction: 'depan',
          danger: 'critical', meter: 0.9);
      expect(lubang.ttsMessage, startsWith('Bahaya!'));
    });
  });

  group('NarrationScheduler - masa tenang', () {
    test('menahan non-kritis tapi meloloskan bahaya kritis', () {
      final s = NarrationScheduler()..beginSession();

      final info = s.process([
        _det(labelId: 'orang', direction: 'kiri', danger: 'info',
            meter: 4, trackId: 1),
      ]);
      expect(info.shouldSpeak, isFalse,
          reason: 'narasi info tidak boleh lolos saat kamera belum stabil');

      final crit = s.process([
        _det(labelId: 'lubang', direction: 'depan', danger: 'critical',
            meter: 2, trackId: 2),
      ]);
      expect(crit.shouldSpeak, isTrue,
          reason: 'lubang di depan kaki tidak boleh ditunda oleh masa tenang');
      expect(crit.tier, SpeechTier.critical);
      expect(crit.interruptible, isFalse,
          reason: 'peringatan bahaya yang terpotong di tengah lebih buruk '
              'daripada tidak ada sama sekali');
    });
  });

  group('NarrationScheduler - arah', () {
    test('membaca arah dari `direction`, bukan dari bbox pixel', () {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..beginSession();

      final kiri = s.process([
        _det(labelId: 'motor', direction: 'kiri', danger: 'critical',
            meter: 3, trackId: 1),
      ]);
      expect(kiri.message, contains('di kiri'));

      final kanan = s.process([
        _det(labelId: 'tiang', direction: 'kanan bawah', danger: 'critical',
            meter: 3, trackId: 2),
      ]);
      expect(kanan.message, contains('di kanan'),
          reason: 'sufiks vertikal ("kanan bawah") harus tetap terbaca kanan');

      final depan = s.process([
        _det(labelId: 'lubang', direction: 'depan', danger: 'critical',
            meter: 2, trackId: 3),
      ]);
      expect(depan.message, contains('di depan'));
    });
  });

  group('NarrationScheduler - pengelompokan', () {
    test('meringkas banyak objek jadi SATU kalimat, bukan satu per objek',
        () async {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..groupingWindow = const Duration(milliseconds: 80)
        ..beginSession();

      final scene = [
        _det(labelId: 'tiang', direction: 'depan', danger: 'warning',
            meter: 3, trackId: 1),
        _det(labelId: 'motor', direction: 'kiri', danger: 'warning',
            meter: 4, trackId: 2),
        _det(labelId: 'orang', direction: 'kanan', danger: 'info',
            meter: 5, trackId: 3),
        _det(labelId: 'orang', direction: 'kanan', danger: 'info',
            meter: 6, trackId: 4),
      ];

      // Ringkasan pertama keluar cepat supaya mode terasa merespons.
      final first = s.process(scene);
      expect(first.shouldSpeak, isTrue);
      expect(first.message!.split(RegExp(r'[.!?]')).where((p) => p.trim().isNotEmpty).length,
          1,
          reason: 'empat objek harus jadi satu kalimat, bukan empat ucapan');
      expect(first.tier, SpeechTier.warning,
          reason: 'tier mengikuti bahaya tertinggi di dalam kelompok');
      expect(first.trackIds.length, greaterThan(1));
    });

    test('menggabungkan objek sejenis di zona sama jadi hitungan', () {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..beginSession();

      final d = s.process([
        _det(labelId: 'orang', direction: 'kanan', danger: 'warning',
            meter: 3, trackId: 1),
        _det(labelId: 'orang', direction: 'kanan', danger: 'warning',
            meter: 4, trackId: 2),
        _det(labelId: 'orang', direction: 'kanan', danger: 'warning',
            meter: 5, trackId: 3),
      ]);

      expect(d.message, contains('3 orang di kanan'),
          reason: 'tiga orang di arah yang sama disebut sekali dengan '
              'hitungannya, bukan diulang tiga kali');
    });
  });

  group('NarrationScheduler - tidak ada narasi yang hilang diam-diam', () {
    test('semua objek akhirnya pernah disebut, bukan cuma yang kritis',
        () async {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..groupingWindow = const Duration(milliseconds: 50)
        ..beginSession();

      final scene = [
        _det(labelId: 'lubang', direction: 'depan', danger: 'critical',
            meter: 2, trackId: 1),
        _det(labelId: 'tiang', direction: 'depan', danger: 'warning',
            meter: 3, trackId: 2),
        _det(labelId: 'motor', direction: 'kiri', danger: 'warning',
            meter: 4, trackId: 3),
        _det(labelId: 'orang', direction: 'kanan', danger: 'info',
            meter: 5, trackId: 4),
      ];

      final disebut = <String>{};
      // ~2,4 detik pada laju 120 ms/frame.
      for (var frame = 0; frame < 20; frame++) {
        final d = s.process(scene);
        if (d.shouldSpeak) {
          for (final label in ['lubang', 'tiang', 'motor', 'orang']) {
            if (d.message!.contains(label)) disebut.add(label);
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      // Inti perbaikannya. Pada perilaku lama, satu lubang dengan cooldown
      // 2 detik sementara utterance-nya makan 3 detik akan mengosongkan
      // antrean berulang kali, sehingga motor dan tiang TIDAK PERNAH
      // diumumkan sama sekali - dan pengguna tidak punya cara tahu.
      expect(disebut, containsAll(['lubang', 'tiang', 'motor', 'orang']),
          reason: 'setiap objek harus pernah terdengar; yang hilang '
              'diam-diam justru yang paling berbahaya');
    });
  });

  group('NarrationScheduler - backoff pengulangan', () {
    test('objek yang mendekat memotong backoff', () async {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..criticalCooldown = const Duration(milliseconds: 60)
        ..beginSession();

      final diam = [
        _det(labelId: 'lubang', direction: 'depan', danger: 'critical',
            meter: 3, trackId: 1),
      ];
      final mendekat = [
        _det(labelId: 'lubang', direction: 'depan', danger: 'critical',
            meter: 2, trackId: 1, approaching: true),
      ];

      expect(s.process(diam).shouldSpeak, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Backoff pengulangan kedua = 2x60 = 120 ms, jadi objek DIAM masih
      // dibungkam pada 80 ms.
      expect(s.process(diam).shouldSpeak, isFalse);

      // Objek yang benar-benar mendekat memotong backoff: situasinya
      // berubah, dan meredam peringatan justru saat bahayanya bertambah
      // adalah kegagalan yang paling mahal.
      expect(s.process(mendekat).shouldSpeak, isTrue);
    });
  });

  group('NarrationScheduler - anggaran kata', () {
    test('kalimat tidak melewati anggaran, sisanya jadi "dan N lainnya"', () {
      final s = NarrationScheduler()
        ..settlingDuration = Duration.zero
        ..wordBudget = 10
        ..beginSession();

      final d = s.process([
        for (var i = 0; i < 8; i++)
          _det(
            labelId: 'objek$i',
            direction: i.isEven ? 'kiri' : 'kanan',
            danger: 'warning',
            meter: 3.0 + i,
            trackId: i,
          ),
      ]);

      expect(d.shouldSpeak, isTrue);
      final kata = d.message!.split(' ').length;
      // Anggaran 10 kata pada 2,5 kata/detik berarti sekitar 4 detik. Sufiks
      // "dan N lainnya" sudah punya jatah sendiri di dalam anggaran; bug yang
      // ketahuan saat simulasi adalah sufiks itu menambah panjang DI LUAR
      // anggaran sehingga narasi 4 detik jadi 5,2 detik.
      expect(kata, lessThanOrEqualTo(12),
          reason: 'narasi $kata kata terlalu panjang: "${d.message}"');
      expect(d.message, contains('lainnya'));
    });
  });
}
