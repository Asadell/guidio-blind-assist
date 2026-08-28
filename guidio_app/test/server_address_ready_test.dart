import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/state/global_conditions.dart';
import 'package:guidio_app/providers/app_mode_provider.dart';
import 'package:guidio_app/providers/capabilities_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// SETELAH ALAMAT SERVER DISIMPAN, MODE BERSERVER HARUS LANGSUNG HIDUP
///
/// Alur yang bermasalah, dari lapangan: pengguna menekan "Uji koneksi",
/// mendengar "Terhubung, waktu tempuh 40 milidetik", menekan "Simpan
/// alamat" - lalu membuka Pilih Mode dan menemukan Cari Objek serta
/// Deskripsi Suasana MASIH ditandai tidak tersedia selama satu dua detik.
///
/// Dua penahannya:
///
///   1. `GlobalConditionsProvider` baru memeriksa ulang server tiap 15 detik,
///      jadi `isBackendDown` masih memegang jawaban lama walau aplikasi
///      barusan membuktikan sendiri servernya hidup.
///   2. `CapabilitiesProvider` menahan jawabannya 45 detik - termasuk
///      jawaban "server tidak menjawab", yang justru paling cepat basi.
///
/// Untuk pengguna tunanetra ini bukan sekadar lambat: aplikasi baru saja
/// mengucapkan "Terhubung", lalu lembarnya berkata "Tidak tersedia, butuh
/// internet". Dua kalimat yang saling membantah, tanpa cara memeriksa mana
/// yang benar.
/// ─────────────────────────────────────────────────────────────────────────
void main() {
  group('GlobalConditionsProvider.markServerReachable', () {
    test('hasil uji yang terbukti dipakai tanpa menunggu polling', () {
      final g = GlobalConditionsProvider();
      var kabar = 0;
      g.addListener(() => kabar++);

      // Keadaan awal sesudah satu polling gagal.
      g.markServerReachable(false);
      expect(g.isBackendDown, isTrue);

      // "Uji koneksi" berhasil, lalu alamatnya disimpan.
      g.markServerReachable(true);
      expect(g.isBackendDown, isFalse);
      expect(kabar, 2, reason: 'tiap perubahan harus mengabari layar');
    });

    test('nilai yang sama tidak memicu pembangunan ulang', () {
      final g = GlobalConditionsProvider();
      g.markServerReachable(true);

      var kabar = 0;
      g.addListener(() => kabar++);
      g.markServerReachable(true);

      expect(kabar, 0);
    });
  });

  group('CapabilitiesProvider - umur jawaban', () {
    test('sebelum pernah bertanya, mode berserver TIDAK dianggap mati', () {
      // Menebak "mati" akan mengunci pengguna dari mode yang sebenarnya sehat
      // hanya karena satu permintaan belum selesai.
      final c = CapabilitiesProvider();
      expect(c.isKnown, isFalse);
      expect(c.stateOf(AppMode.findObject, offline: false), CapState.up);
      expect(c.unavailableReason(AppMode.voice, offline: false), isNull);
    });

    test('offline: mode yang mati tanpa internet dikatakan apa adanya', () {
      final c = CapabilitiesProvider();
      expect(c.stateOf(AppMode.findObject, offline: true), CapState.down);
      expect(c.stateOf(AppMode.voice, offline: true), CapState.down);
      // Mode on-device tidak boleh ikut ditandai mati.
      expect(c.stateOf(AppMode.navigasi, offline: true), CapState.up);
      expect(c.stateOf(AppMode.tuntun, offline: true), CapState.up);
    });
  });
}
