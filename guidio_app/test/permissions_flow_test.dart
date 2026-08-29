/// Layar izin harus mengikuti ketukan pengguna, bukan antrean suara.
///
/// Gejalanya di perangkat: pengguna mempercepat panduan, lalu memberi izin
/// kamera - dan layar DIAM di langkah kamera. Izinnya sudah diberikan; yang
/// menahan adalah narasi panduan yang belum habis dibacakan.
///
/// Untuk pengguna tunanetra, tombol yang tidak menghasilkan apa-apa adalah
/// kegagalan yang tidak bisa dia diagnosis. Dia tidak melihat bahwa layarnya
/// tidak berubah, dan tidak tahu bahwa yang menahan adalah suara.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/screens/permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';

const _tts = MethodChannel('flutter_tts');
const _perm = MethodChannel('flutter.baseflow.com/permissions/methods');

// Kode status permission_handler.
const _denied = 0;
const _granted = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<int, int> status;
  late List<String> spoken;

  /// Mesin TTS dengan ucapan yang SANGAT panjang.
  ///
  /// Ini yang membuat testnya berarti: kalau perpindahan langkah masih
  /// menunggu suara, ia tidak akan pernah terjadi dalam rentang pump di
  /// bawah.
  void installTts({int utteranceMs = 5000}) {
    spoken = [];
    messenger.setMockMethodCallHandler(_tts, (call) async {
      if (call.method == 'speak') {
        spoken.add(call.arguments as String);
        await Future<void>.delayed(Duration(milliseconds: utteranceMs));
      }
      if (call.method == 'getSpeechRateValidRange') {
        return {'min': 0.0, 'normal': 0.5, 'max': 1.5};
      }
      return 1;
    });
  }

  void installPermissions() {
    status = {
      Permission.camera.value: _denied,
      Permission.microphone.value: _denied,
    };
    messenger.setMockMethodCallHandler(_perm, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          return status[call.arguments as int] ?? _denied;
        case 'requestPermissions':
          final asked = List<int>.from(call.arguments as List);
          for (final p in asked) {
            status[p] = _granted;
          }
          return {for (final p in asked) p: _granted};
        case 'shouldShowRequestPermissionRationale':
          return false;
      }
      return _denied;
    });
  }

  setUp(() {
    installTts();
    installPermissions();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_tts, null);
    messenger.setMockMethodCallHandler(_perm, null);
  });

  /// Habiskan seluruh ucapan yang masih berjalan.
  ///
  /// Wajib di akhir tiap test: mesin TTS palsu memakai timer, dan
  /// `flutter_test` menganggap timer yang masih menggantung sebagai
  /// kegagalan. Dipanggil SESUDAH semua assertion, jadi ia tidak pernah
  /// menutupi perilaku yang sedang diuji.
  Future<void> drainSpeech(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 20));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, {VoidCallback? onDone}) async {
    await tester.pumpWidget(MaterialApp(
      home: PermissionsScreen(onDone: onDone ?? () {}),
    ));
    await tester.pump(); // _resolveStartStep
    await tester.pump();
  }

  testWidgets('izin kamera diberikan -> langsung ke langkah mikrofon',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('Izin kamera'), findsOneWidget);

    await tester.tap(find.text('Izinkan kamera'));
    // Jauh lebih pendek daripada satu ucapan (30 detik). Kalau perpindahan
    // masih menunggu suara, langkah mikrofon tidak akan pernah muncul.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Izin mikrofon'), findsOneWidget,
        reason: 'layar masih menunggu antrean suara sebelum berpindah langkah');
    expect(find.text('Izin kamera'), findsNothing);

    await drainSpeech(tester);
  });

  testWidgets('izin mikrofon diberikan -> onDone dipanggil segera',
      (tester) async {
    var done = false;
    await pumpScreen(tester, onDone: () => done = true);

    await tester.tap(find.text('Izinkan kamera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Izinkan mikrofon'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(done, isTrue,
        reason: 'onDone tertahan antrean suara, aplikasi tidak pernah mulai');

    await drainSpeech(tester);
  });

  testWidgets('kamera sudah diizinkan sebelumnya -> mulai dari mikrofon',
      (tester) async {
    status[Permission.camera.value] = _granted;
    await pumpScreen(tester);

    expect(find.text('Izin mikrofon'), findsOneWidget);

    await drainSpeech(tester);
  });

  testWidgets('keduanya sudah diizinkan -> layar ini dilewati', (tester) async {
    var done = false;
    status[Permission.camera.value] = _granted;
    status[Permission.microphone.value] = _granted;
    await pumpScreen(tester, onDone: () => done = true);

    expect(done, isTrue);

    await drainSpeech(tester);
  });

  testWidgets('narasi langkah baru memotong, tidak mengantre', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Izinkan kamera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "Izin diberikan." memotong narasi langkah kamera yang masih berjalan,
    // lalu narasi mikrofon menyusul DI BELAKANGNYA - bukan menimpanya.
    expect(spoken, contains('Izin diberikan.'));

    await drainSpeech(tester);
  });
}
