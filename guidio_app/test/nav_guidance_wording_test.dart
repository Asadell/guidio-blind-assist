import 'package:flutter_test/flutter_test.dart';
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

List<String> _ucapanUntuk(ZoneAnalysis zona) {
  final ucapan = <String>[];
  final p = NavigationProvider();
  p.onSpeak = (teks, _) => ucapan.add(teks);
  p.debugApplyResult(zona, const []);
  return ucapan;
}

void main() {
  group('ZoneAnalysis.ttsMessage - arah bertingkat', () {
    test('geser nol berarti benar-benar lurus', () {
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.safe,
        kanan: ZoneStatus.safe,
      ).ttsMessage;
      expect(m, 'Jalur aman, jalan lurus.');
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
      expect(m, contains('kiri'));
      expect(m, contains('Sedikit'));
    });

    test('geser sedang menyebut arah dengan kata "agak"', () {
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.caution,
        kanan: ZoneStatus.danger,
        geser: -0.20,
      ).ttsMessage;
      expect(m, 'Agak ke kiri.');
    });

    test('geser besar menyuruh pindah sisi', () {
      final m = _zona(
        kiri: ZoneStatus.safe,
        tengah: ZoneStatus.caution,
        kanan: ZoneStatus.danger,
        geser: 0.40,
      ).ttsMessage;
      expect(m, 'Ambil sebelah kanan.');
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
}
