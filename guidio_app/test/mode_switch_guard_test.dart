import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PERPINDAHAN MODE TIDAK BOLEH BISA TERKUNCI
///
/// Regresi yang dijaga di sini pernah terjadi di perangkat: `NavigasiScreen`
/// memasang `AppModeProvider.confirmLeave`, lalu `dispose()`-nya GAGAL
/// melepasnya karena dua sebab sekaligus:
///
///   1. `context.read` di dalam dispose() melempar - elemennya sudah tidak
///      aktif - sehingga seluruh baris pelepasan sesudahnya tidak berjalan.
///   2. Syarat `identical(hook, _confirmLeaveNavigasi)` tidak pernah benar,
///      karena tear-off metode instans TIDAK dikanonikalisasi Dart.
///
/// Hook itu lalu tertinggal menunjuk ke State mati. Setiap perpindahan mode
/// berikutnya memanggilnya, tiap panggilan melempar, dan pengguna terkunci di
/// modenya sekarang tanpa satu pun penjelasan.
/// ─────────────────────────────────────────────────────────────────────────────

void main() {
  test('tear-off metode instans TIDAK identical - dasar bug lama', () {
    final o = _Dummy();
    expect(identical(o.hook, o.hook), isFalse,
        reason: 'Kalau ini berubah jadi true di versi Dart mendatang, syarat '
            'identical pada tear-off langsung boleh dipakai lagi. Selama '
            'false, tear-off WAJIB disimpan sekali di field.');
    final tersimpan = o.hook;
    expect(identical(tersimpan, tersimpan), isTrue,
        reason: 'Tear-off yang disimpan sekali aman dibandingkan.');
  });

  test('confirmLeave yang melempar tidak boleh membatalkan perpindahan', () async {
    final p = AppModeProvider();
    p.confirmLeave = (from, to) async => throw StateError('layar sudah mati');

    final pindah = await p.setMode(AppMode.navigasi);

    expect(pindah, isTrue, reason: 'Gerbang WAJIB gagal-terbuka.');
    expect(p.mode, AppMode.navigasi);
    expect(p.confirmLeave, isNull,
        reason: 'Hook yang rusak harus dilepas supaya tidak melukai '
            'perpindahan berikutnya.');
  });

  test('setelah hook rusak dilepas, mode berikutnya tetap bisa dituju', () async {
    final p = AppModeProvider();
    p.confirmLeave = (from, to) async => throw StateError('layar sudah mati');

    await p.setMode(AppMode.navigasi);
    final lagi = await p.setMode(AppMode.money);

    expect(lagi, isTrue);
    expect(p.mode, AppMode.money);
  });

  test('konfirmasi yang SAH tetap boleh menahan perpindahan', () async {
    final p = AppModeProvider();
    var ditanya = 0;
    p.confirmLeave = (from, to) async {
      ditanya++;
      return false;
    };

    final pindah = await p.setMode(AppMode.money);

    expect(pindah, isFalse, reason: 'NV-18 harus tetap berfungsi.');
    expect(ditanya, 1);
    expect(p.confirmLeave, isNotNull,
        reason: 'Hook yang sehat tidak boleh ikut dilepas.');
  });

  // ── Mode yang mati tanpa server ────────────────────────────────────────────
  //
  // Satu bendera, `AppMode.disabledWhenOffline`, memberi makan DUA jalan masuk
  // yang berbeda:
  //
  //   1. Lembar Pilih Mode - itemnya dinonaktifkan dan kalimatnya berbunyi
  //      "Tidak tersedia, butuh internet", bukan "sebagian fitur mati".
  //   2. Perintah suara - `VoiceProvider` menolak berpindah dan menjelaskan
  //      alasannya.
  //
  // Yang kedua justru jalan utama bagi pengguna tunanetra. Kalau bendera ini
  // dilonggarkan tanpa sengaja, keduanya ikut jebol sekaligus dan tidak ada
  // yang merah - dia cuma masuk ke mode yang diam saja lalu menyimpulkan
  // aplikasinya rusak. Karena itu benderanya diuji di sini, bukan efeknya di
  // masing-masing layar.
  group('mode yang butuh server', () {
    test('Cari Objek dan Deskripsi Suasana mati total tanpa server', () {
      expect(AppMode.findObject.disabledWhenOffline, isTrue);
      expect(AppMode.voice.disabledWhenOffline, isTrue,
          reason: 'Deskripsi Suasana hanya punya satu isi, yaitu mengirim '
              'foto ke Moondream2 di server. Tanpa itu tidak ada sisanya.');
    });

    test('mode on-device TIDAK pernah dimatikan tanpa server', () {
      // Navigasi yang paling menentukan di sini: ia berjalan penuh dengan
      // empat model TFLite di ponsel, dan mematikannya saat sinyal hilang
      // berarti mencabut panduan jalan justru di tempat yang tidak bersinyal.
      for (final mode in [
        AppMode.navigasi,
        AppMode.tuntun,
        AppMode.money,
        AppMode.ocr,
      ]) {
        expect(mode.disabledWhenOffline, isFalse, reason: mode.label);
        expect(mode.needsServer, isFalse, reason: mode.label);
      }
    });
  });

  testWidgets('dispose layar tidak boleh meninggalkan hook menggantung',
      (tester) async {
    final appMode = AppModeProvider();

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: appMode,
      child: const MaterialApp(home: _PemasangHook()),
    ));
    await tester.pump();
    expect(appMode.confirmLeave, isNotNull, reason: 'hook harus terpasang');

    // Meniru perpindahan mode: layar pemasang dibuang.
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: appMode,
      child: const MaterialApp(home: SizedBox()),
    ));
    await tester.pump();

    expect(appMode.confirmLeave, isNull,
        reason: 'dispose() WAJIB melepas hook-nya. Kalau ini gagal, setiap '
            'perpindahan mode berikutnya memanggil State yang sudah mati.');
  });
}

class _Dummy {
  Future<bool> hook(AppMode a, AppMode b) async => true;
}

/// Meniru pola NavigasiScreen: catat rujukan provider di
/// didChangeDependencies, simpan tear-off sekali, lepas di dispose.
class _PemasangHook extends StatefulWidget {
  const _PemasangHook();
  @override
  State<_PemasangHook> createState() => _PemasangHookState();
}

class _PemasangHookState extends State<_PemasangHook> {
  late AppModeProvider _appMode;
  late final Future<bool> Function(AppMode, AppMode) _guard = _confirm;

  Future<bool> _confirm(AppMode from, AppMode to) async => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appMode = context.read<AppModeProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppModeProvider>().confirmLeave = _guard;
    });
  }

  @override
  void dispose() {
    if (identical(_appMode.confirmLeave, _guard)) _appMode.confirmLeave = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
