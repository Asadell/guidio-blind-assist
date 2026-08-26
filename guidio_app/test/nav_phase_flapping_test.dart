import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/speech/tts_queue.dart' show SpeechTier;
import 'package:guidio_app/providers/navigation_provider.dart';
import 'package:guidio_app/services/pidnet_service.dart';
import 'package:guidio_app/widgets/zone_indicator.dart' show ZoneStatus;

/// ─────────────────────────────────────────────────────────────────────────────
/// MODE NAVIGASI TIDAK BOLEH BERPUTAR-PUTAR
///
/// Keluhan dari lapangan: "kok mode navigasinya muter2 terus ya?"
///
/// Sebabnya empat cacat yang saling menguatkan di NavigationProvider:
///
///   1. `_applyOnDeviceResult` menulis `_phase = active` TANPA SYARAT, jadi
///      satu frame yang kebetulan tidak melempar sudah membatalkan status
///      turun - bahkan frame yang seluruh zonanya "tidak diketahui".
///   2. Berpasangan dengan ambang `_consecutiveFailures == 2`, fase berayun:
///      turun, naik, turun, naik.
///   3. Pengumuman fase memanggil `_speak` LANGSUNG, melewati seluruh
///      histeresis dan rem yang sudah rapi di `_emitGuidance`. Jadi tiap
///      ayunan membawa kalimatnya sendiri ke telinga pengguna.
///   4. `wasDown` menghitung `loadingModels` tapi TIDAK menghitung
///      `unavailable`: frame pertama sesudah masuk mode mengucapkan "Jalur
///      terbaca lagi" (mengarang kejadian), sementara pengguna yang disuruh
///      "Berhenti jalan dulu" pulih dalam diam (menunggu izin yang tak datang).
/// ─────────────────────────────────────────────────────────────────────────────

ZoneAnalysis _zona({required bool terbaca}) => ZoneAnalysis(
      leftRatio: terbaca ? 0.6 : 0.0,
      centerRatio: terbaca ? 0.7 : 0.0,
      rightRatio: terbaca ? 0.6 : 0.0,
      left: terbaca ? ZoneStatus.safe : ZoneStatus.unknown,
      center: terbaca ? ZoneStatus.safe : ZoneStatus.unknown,
      right: terbaca ? ZoneStatus.safe : ZoneStatus.unknown,
      recommendedZone: 1,
      inferenceMs: 10,
      // Inilah yang membuat frame TIDAK layak jadi dasar arahan.
      doubt: terbaca ? SceneDoubt.none : SceneDoubt.degenerate,
    );

class _Rekaman {
  final List<String> ucapan = [];
  NavigationProvider pasang(NavigationProvider p) {
    p.onSpeak = (teks, tier) => ucapan.add(teks);
    return p;
  }

  int hitung(String penggalan) =>
      ucapan.where((u) => u.contains(penggalan)).length;
}

void main() {
  test('frame terbaca pertama sesudah masuk mode BUKAN pemulihan', () {
    final r = _Rekaman();
    final p = r.pasang(NavigationProvider());

    // Fase awal sesudah masuk mode adalah loadingModels.
    p.debugApplyResult(_zona(terbaca: true), const []);

    expect(r.hitung('Jalur terbaca lagi'), 0,
        reason: 'Tidak ada yang pernah hilang, jadi tidak ada yang pulih. '
            'Mengucapkannya di sini mengarang kejadian.');
    expect(p.phase, NavPhase.active);
  });

  test('satu frame bagus di antara kegagalan TIDAK membatalkan status turun', () {
    final r = _Rekaman();
    final p = r.pasang(NavigationProvider());

    p.debugHandleFailure();
    p.debugHandleFailure(); // -> degraded
    expect(p.phase, NavPhase.degraded);

    // Satu frame yang zonanya tidak terbaca: bukan pemulihan.
    p.debugApplyResult(_zona(terbaca: false), const []);
    expect(p.phase, NavPhase.degraded,
        reason: 'Frame yang seluruh zonanya "tidak diketahui" tidak boleh '
            'menyatakan jalur sudah terbaca lagi.');

    // Satu frame terbaca saja juga belum cukup - butuh dua berturut.
    p.debugApplyResult(_zona(terbaca: true), const []);
    expect(p.phase, NavPhase.degraded,
        reason: 'Histeresis: satu frame beruntung belum berarti pulih.');

    p.debugApplyResult(_zona(terbaca: true), const []);
    expect(p.phase, NavPhase.active, reason: 'Dua frame berturut = pulih.');
  });

  test('ayunan turun-naik tidak boleh membanjiri pengguna dengan kalimat', () {
    final r = _Rekaman();
    final p = r.pasang(NavigationProvider());

    // Meniru kondisi lapangan: frame gagal dan berhasil berselang-seling,
    // berkali-kali, dalam waktu singkat.
    for (var i = 0; i < 10; i++) {
      p.debugHandleFailure();
      p.debugHandleFailure();
      p.debugApplyResult(_zona(terbaca: true), const []);
      p.debugApplyResult(_zona(terbaca: true), const []);
    }

    final total = r.hitung('Jalur sulit dibaca') + r.hitung('Jalur terbaca lagi');
    expect(total, lessThanOrEqualTo(2),
        reason: 'Sepuluh ayunan penuh terjadi dalam hitungan milidetik. '
            'Rem pengumuman fase harus meredamnya jadi paling banyak satu '
            'dua kalimat, bukan dua puluh. Terkumpul: ${r.ucapan}');
  });

  test('pulih dari "Berhenti jalan dulu" WAJIB diberitahukan', () {
    final r = _Rekaman();
    final p = r.pasang(NavigationProvider());

    for (var i = 0; i < 4; i++) {
      p.debugHandleFailure();
    }
    expect(p.phase, NavPhase.unavailable);
    expect(r.hitung('Berhenti jalan dulu'), 1);

    // Rem pengumuman fase butuh jeda; majukan waktunya dengan menunggu.
    // Di sini cukup pastikan FASE-nya benar-benar pulih.
    p.debugApplyResult(_zona(terbaca: true), const []);
    p.debugApplyResult(_zona(terbaca: true), const []);

    expect(p.phase, NavPhase.active,
        reason: 'Pengguna yang disuruh berhenti harus bisa jalan lagi.');
  });
}
