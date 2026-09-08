import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/models/detection.dart';
import 'package:guidio_app/providers/navigation_provider.dart';
import 'package:guidio_app/services/pidnet_service.dart';
import 'package:guidio_app/widgets/zone_indicator.dart' show ZoneStatus;

/// ─────────────────────────────────────────────────────────────────────────
/// ARAHAN NAVIGASI HARUS MENYEBUT JALAN KELUARNYA
///
/// Dua cacat yang saling menutupi, keduanya terlihat di satu tangkapan layar
/// dari lapangan:
///
///   1. `_composeGuidance` memutuskan "berhenti" dari tiga rasio zona, bukan
///      dari ada tidaknya jalur. Pada trotoar sempit berpohon ketiga rasio
///      memang jelek sekaligus, padahal hamparan jalur di layar jelas
///      menggambar pita hijau yang bisa dilewati. Yang terucap: "Berhenti!
///      Jalur di depan tidak aman." Pengguna tunanetra berhenti di tengah
///      trotoar tanpa satu pun jalan keluar.
///
///   2. `ZoneAnalysis.ttsMessage` memakai satu ambang, 0,12. Di bawah itu
///      kalimatnya selalu "Jalur aman, jalan lurus." Padahal `pathShift`
///      SUDAH dinolkan oleh pemeriksaan bahu setiap kali badan pengguna muat
///      lurus ke depan - jadi nilai seperti -0,10 berarti "kamu tidak muat",
///      dan dijawab dengan "jalan lurus".
/// ─────────────────────────────────────────────────────────────────────────

/// Satu ruas jalur yang muat dilewati.
const _adaJalur = [PathPoint(x: 0.5, y: 1, width: 0.4)];

ZoneAnalysis _zona({
  required ZoneStatus kiri,
  required ZoneStatus tengah,
  required ZoneStatus kanan,
  double geser = 0,
  List<PathPoint> jalur = _adaJalur,
}) =>
    ZoneAnalysis(
      leftRatio: 0.3,
      centerRatio: 0.3,
      rightRatio: 0.3,
      left: kiri,
      center: tengah,
      right: kanan,
      recommendedZone: 1,
      inferenceMs: 10,
      path: jalur,
      pathShift: geser,
    );

List<String> _ucapanUntuk(ZoneAnalysis zona,
    [List<Detection> rintangan = const []]) {
  final ucapan = <String>[];
  final p = NavigationProvider();
  p.onSpeak = (teks, _) => ucapan.add(teks);
  p.debugApplyResult(zona, rintangan);
  return ucapan;
}

/// Satu lubang di depan kaki - deteksi yang paling sering memicu peringatan
/// di mode ini, dan yang tangkapan layarnya memulai perbaikan ini.
Detection _lubang({
  String arah = 'depan',
  double jarak = 0.6,
  String bahaya = 'critical',
}) =>
    Detection(
      labelEn: 'pothole',
      labelId: 'lubang',
      confidence: 0.8,
      distanceMeter: jarak,
      direction: arah,
      dangerLevel: bahaya,
      bbox: const {'x1': 100, 'y1': 400, 'x2': 380, 'y2': 620},
      inferenceMs: 12,
      frameWidth: 480,
      frameHeight: 640,
    );

void main() {
  _ujiTeksArahan();

  group('ZoneAnalysis.ttsMessage - perintah langkah, bukan kata sifat', () {
    test('geser nol berarti maju lurus ke depan', () {
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.safe,
        kanan: ZoneStatus.safe,
      ).ttsMessage;
      expect(m, 'Jalur aman. Maju lurus ke depan.');
    });

    test('geser kecil TIDAK boleh jadi "jalan lurus"', () {
      // Nilai persis dari log perangkat: geser=-0.10. Pemeriksaan bahu sudah
      // menjawab "tidak muat kalau lurus", jadi menyuruh lurus itu keliru.
      final m = _zona(
        kiri: ZoneStatus.danger,
        tengah: ZoneStatus.caution,
        kanan: ZoneStatus.danger,
        geser: -0.10,
      ).ttsMessage;
      expect(m, isNot(contains('lurus')));
      expect(m, 'Geser setengah langkah ke kiri.');
    });

    test('geser besar menuntut langkah yang lebih banyak', () {
      // Yang membedakan arahan dari penilaian: jumlahnya ikut naik, bukan
      // cuma kata sifatnya.
      final dekat = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.caution,
        kanan: ZoneStatus.danger,
        geser: -0.10,
      ).ttsMessage;
      final jauh = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.caution,
        kanan: ZoneStatus.danger,
        geser: -0.50,
      ).ttsMessage;

      expect(dekat, 'Geser setengah langkah ke kiri.');
      expect(jauh, 'Geser satu setengah langkah ke kiri.');
    });

    test('arahnya cuma kiri, kanan, atau depan - tidak pernah menyamping', () {
      // Mata angin dan "serong" menuntut pengguna menerjemahkan sendiri arah
      // peta jadi gerakan badan, dan itu yang tidak bisa dilakukan sambil
      // berjalan tanpa melihat.
      final semua = [
        for (final g in [0.0, -0.1, -0.3, 0.1, 0.3, 0.5])
          _zona(
            kiri: ZoneStatus.safe,
            tengah: ZoneStatus.safe,
            kanan: ZoneStatus.safe,
            geser: g,
          ).ttsMessage,
      ];

      for (final m in semua) {
        for (final terlarang in [
          'barat',
          'timur',
          'utara',
          'selatan',
          'serong',
          'menyamping',
          'samping',
        ]) {
          expect(m.toLowerCase(), isNot(contains(terlarang)), reason: m);
        }
      }
    });

    test('jumlah langkah dieja, bukan ditulis sebagai angka', () {
      // TTS Bahasa Indonesia membaca "1.5" sebagai "satu titik lima".
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.safe,
        kanan: ZoneStatus.safe,
        geser: 0.50,
      ).ttsMessage;
      expect(m, isNot(matches(RegExp(r'\d'))));
      expect(m, contains('satu setengah langkah'));
    });

    test('tengah tertutup tetap menyebut sisi mana yang bisa dilewati', () {
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.danger,
        kanan: ZoneStatus.danger,
        geser: -0.20,
      ).ttsMessage;
      expect(m, contains('tertutup'));
      expect(m, contains('kiri'));
    });

    test('tanpa jalur sama sekali, barulah "berhenti"', () {
      final m = _zona(
        kiri: ZoneStatus.danger,
        tengah: ZoneStatus.danger,
        kanan: ZoneStatus.danger,
        jalur: const [],
      ).ttsMessage;
      expect(m, startsWith('Berhenti'));
    });
  });

  group('_composeGuidance - berhenti hanya kalau memang buntu', () {
    test('tengah bahaya TAPI masih ada jalur: arah, bukan berhenti', () {
      // Persis keadaan di tangkapan layar: pita hijau masih ada, sedikit ke
      // kiri, sementara zona tengah dinilai bahaya.
      final ucapan = _ucapanUntuk(_zona(
        kiri: ZoneStatus.danger,
        tengah: ZoneStatus.danger,
        kanan: ZoneStatus.caution,
        geser: -0.20,
      ));

      expect(ucapan, isNotEmpty);
      expect(ucapan.last, isNot(contains('Berhenti')));
      expect(ucapan.last, contains('kiri'));
    });

    test('ketiga zona bahaya TAPI masih ada jalur: arah plus peringatan sempit',
        () {
      final ucapan = _ucapanUntuk(_zona(
        kiri: ZoneStatus.danger,
        tengah: ZoneStatus.danger,
        kanan: ZoneStatus.danger,
        geser: -0.20,
      ));

      expect(ucapan.last, isNot(startsWith('Berhenti')));
      expect(ucapan.last, contains('kiri'));
      expect(ucapan.last, contains('sempit'));
    });

    test('tidak ada jalur sama sekali: barulah berhenti', () {
      final ucapan = _ucapanUntuk(_zona(
        kiri: ZoneStatus.danger,
        tengah: ZoneStatus.danger,
        kanan: ZoneStatus.danger,
        jalur: const [],
      ));

      expect(ucapan.last, startsWith('Berhenti'));
    });

    test('frame yang tidak layak TIDAK pernah menyuruh melangkah', () {
      // Arahan melangkah tidak boleh disusun dari frame yang tidak terbaca -
      // kamera di dalam saku pun menghasilkan sumbu jalur.
      final ucapan = _ucapanUntuk(const ZoneAnalysis(
        leftRatio: 0,
        centerRatio: 0,
        rightRatio: 0,
        left: ZoneStatus.unknown,
        center: ZoneStatus.unknown,
        right: ZoneStatus.unknown,
        recommendedZone: 1,
        inferenceMs: 10,
        path: _adaJalur,
        pathShift: -0.20,
        doubt: SceneDoubt.degenerate,
      ));

      for (final u in ucapan) {
        expect(u, isNot(contains('ke kiri')));
        expect(u, isNot(contains('ke kanan')));
      }
    });
  });

  group('peringatan rintangan HARUS menyebut jalan keluarnya', () {
    test('lubang di depan ikut menyebut ke mana badan digeser', () {
      // Keadaan persis di tangkapan layar lapangan: YOLO menemukan lubang
      // kurang dari satu meter, dan pada frame yang SAMA garis jalur sudah
      // menikung ke kiri melewati lubang itu. Yang dulu terucap cuma
      // peringatannya; tikungan yang sudah dihitung tidak pernah diucapkan.
      final ucapan = _ucapanUntuk(
        _zona(
          kiri: ZoneStatus.safe,
          tengah: ZoneStatus.danger,
          kanan: ZoneStatus.caution,
          geser: -0.20,
        ),
        [_lubang()],
      );

      expect(ucapan, isNotEmpty);
      expect(ucapan.last, contains('lubang'));
      expect(ucapan.last, contains('Geser'));
      expect(ucapan.last, contains('ke kiri'));
    });

    test('jalan keluar ke kanan diucapkan ke kanan', () {
      final ucapan = _ucapanUntuk(
        _zona(
          kiri: ZoneStatus.danger,
          tengah: ZoneStatus.danger,
          kanan: ZoneStatus.safe,
          geser: 0.30,
        ),
        [_lubang()],
      );

      expect(ucapan.last, contains('ke kanan'));
      expect(ucapan.last, isNot(contains('ke kiri')));
    });

    test('rintangan hati-hati juga dapat jalan keluar', () {
      final ucapan = _ucapanUntuk(
        _zona(
          kiri: ZoneStatus.safe,
          tengah: ZoneStatus.caution,
          kanan: ZoneStatus.caution,
          geser: -0.30,
        ),
        [_lubang(bahaya: 'warning', arah: 'kanan', jarak: 2.0)],
      );

      // Warning butuh dua frame berturut-turut lewat histeresis, jadi yang
      // diperiksa cukup: kalau sampai terucap, jalan keluarnya ikut.
      for (final u in ucapan) {
        if (u.contains('lubang')) expect(u, contains('Geser'));
      }
    });

    test('bahaya tepat di depan tanpa geseran menyuruh berhenti, bukan maju',
        () {
      // `pathShift` nol berarti pemeriksaan bahu bilang badan muat lurus ke
      // depan - tapi rintangannya justru ada DI DALAM koridor lurus itu.
      // Menempelkan "maju lurus" di sini akan menuntun pengguna masuk lubang.
      final ucapan = _ucapanUntuk(
        _zona(
          kiri: ZoneStatus.safe,
          tengah: ZoneStatus.safe,
          kanan: ZoneStatus.safe,
        ),
        [_lubang()],
      );

      expect(ucapan.last, contains('Berhenti'));
      expect(ucapan.last, isNot(contains('Maju')));
    });

    test('frame yang tidak terbaca tidak menempelkan jalan keluar', () {
      // Jalan keluar diambil dari sumbu jalur, dan sumbu jalur dari frame
      // yang tidak terbaca tidak berarti apa-apa. Peringatan lubangnya tetap
      // harus lewat - itu datang dari YOLO, bukan dari segmentasi.
      final ucapan = _ucapanUntuk(
        const ZoneAnalysis(
          leftRatio: 0,
          centerRatio: 0,
          rightRatio: 0,
          left: ZoneStatus.unknown,
          center: ZoneStatus.unknown,
          right: ZoneStatus.unknown,
          recommendedZone: 1,
          inferenceMs: 10,
          path: _adaJalur,
          pathShift: -0.20,
          doubt: SceneDoubt.degenerate,
        ),
        [_lubang()],
      );

      expect(ucapan.last, contains('lubang'));
      expect(ucapan.last, isNot(contains('Geser')));
    });
  });

}

/// ─────────────────────────────────────────────────────────────────────────
/// ARAHAN JUGA HARUS ADA DALAM BENTUK TEKS
///
/// Sampai sekarang arahan mode ini hanya ada sebagai suara, jadi ia hilang
/// sama sekali bagi siapa pun yang tidak sedang mendengar: pendamping awas,
/// penguji lapangan, juri, dan pengguna low vision yang masih bisa membaca.
///
/// Yang dijaga di sini satu hal, dan itu yang paling mudah rusak: teks di
/// layar dan kalimat yang terucap harus SELALU sama. Arahan yang diredam rem
/// anti-banjir tidak boleh muncul di layar, karena layar akan menampilkan
/// kalimat yang tidak pernah diucapkan.
/// ─────────────────────────────────────────────────────────────────────────
void _ujiTeksArahan() {
  group('NavigationProvider.guidanceText', () {
    test('kosong sebelum ada arahan apa pun', () {
      expect(NavigationProvider().guidanceText, isEmpty);
    });

    test('berisi kalimat yang sama persis dengan yang diucapkan', () {
      final ucapan = <String>[];
      final p = NavigationProvider();
      p.onSpeak = (teks, _) => ucapan.add(teks);
      p.debugApplyResult(
        _zona(
          kiri: ZoneStatus.danger,
          tengah: ZoneStatus.danger,
          kanan: ZoneStatus.caution,
          geser: -0.20,
        ),
        const [],
      );

      expect(ucapan, isNotEmpty);
      expect(p.guidanceText, ucapan.last,
          reason: 'teks di layar dan suara harus berasal dari satu titik');
      expect(p.guidanceAt, isNotNull);
    });

    test('stopNavigation membuang arahan yang tertinggal', () {
      final p = NavigationProvider();
      p.onSpeak = (_, __) {};
      p.debugApplyResult(
        _zona(
          kiri: ZoneStatus.safe,
          tengah: ZoneStatus.safe,
          kanan: ZoneStatus.safe,
        ),
        const [],
      );
      p.stopNavigation();

      expect(p.guidanceText, isEmpty,
          reason: 'kalimat yang menyuruh melangkah tidak boleh tertinggal di '
              'mode yang sudah berhenti mengawasi');
      expect(p.guidanceAt, isNull);
    });
  });
}
