/// Perpindahan langkah TIDAK BOLEH menunggu suara selesai.
///
/// Gejalanya di perangkat: pengguna mengetuk "Lanjut" tiga kali dengan cepat
/// di panduan, lalu memberi izin kamera - dan layar izin DIAM di langkah
/// kamera, tidak pernah pindah ke mikrofon. Izinnya sudah diberikan; yang
/// menahan adalah antrean suara yang belum habis.
///
/// Sebabnya ada di `TTSService.speak`, yang merantai tiap ucapan di belakang
/// ucapan sebelumnya lalu mengembalikan Future yang baru selesai saat
/// GILIRANNYA tiba. Menunggu Future itu sebelum berpindah langkah berarti
/// membayar perpindahan dengan seluruh sisa antrean - dan antrean paling
/// panjang justru dimiliki pengguna yang paling cepat mengetuk.
///
/// Yang diuji di sini bukan layarnya (butuh mock permission_handler), tapi
/// mekanisme yang diandalkan perbaikannya: `interrupt: true` benar-benar
/// membuang antrean, bukan ikut mengantre di belakangnya.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/tts_service.dart';

const _channel = MethodChannel('flutter_tts');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> spoken;
  late List<String> stopped;

  /// Mesin TTS palsu: tiap ucapan makan [utteranceMs].
  void installEngine({int utteranceMs = 200}) {
    spoken = [];
    stopped = [];
    messenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'speak':
          spoken.add(call.arguments as String);
          await Future<void>.delayed(Duration(milliseconds: utteranceMs));
          return 1;
        case 'stop':
          stopped.add('stop');
          return 1;
        case 'getSpeechRateValidRange':
          return {'min': 0.0, 'normal': 0.5, 'max': 1.5};
        case 'getLanguages':
          return <String>['id-ID', 'en-US'];
      }
      return 1;
    });
  }

  setUp(() => installEngine());
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('ucapan berurutan diserialkan - tidak ada yang dibuang', () async {
    // Kontrak lama yang HARUS tetap berlaku: peringatan bahaya tidak boleh
    // hilang hanya karena TTS sedang sibuk.
    await Future.wait([
      TTSService.instance.speak('satu'),
      TTSService.instance.speak('dua'),
      TTSService.instance.speak('tiga'),
    ]);
    expect(spoken, ['satu', 'dua', 'tiga']);
  });

  test('interrupt membuang antrean, bukan mengantre di belakangnya', () async {
    installEngine(utteranceMs: 2000);

    // Tiga narasi panduan menumpuk - pengguna mengetuk "Lanjut" cepat.
    final backlog = [
      TTSService.instance.speak('panduan satu'),
      TTSService.instance.speak('panduan dua'),
      TTSService.instance.speak('panduan tiga'),
    ];

    final watch = Stopwatch()..start();
    await TTSService.instance.speak('Izin diberikan.', interrupt: true);
    watch.stop();

    // Kalau ia ikut mengantre, ini butuh 6+ detik. Yang ditunggu hanya
    // ucapannya sendiri.
    expect(watch.elapsed.inMilliseconds, lessThan(4000),
        reason: 'interrupt ikut mengantre di belakang backlog');
    expect(spoken.last, 'Izin diberikan.');
    // Yang belum sempat bicara membatalkan dirinya sendiri.
    expect(spoken, isNot(contains('panduan tiga')));

    await Future.wait(backlog);
  });

  test('ucapan sesudah interrupt tetap menyusul, tidak ikut terbuang',
      () async {
    // Ini yang membuat "Izin diberikan." lalu "Vinara butuh izin mikrofon"
    // terdengar berurutan: yang pertama memotong antrean lama, yang kedua
    // menyambung di belakangnya - bukan menimpanya.
    final granted = TTSService.instance.speak('Izin diberikan.', interrupt: true);
    final next = TTSService.instance.speak('Vinara butuh izin mikrofon.');
    await Future.wait([granted, next]);

    expect(spoken, ['Izin diberikan.', 'Vinara butuh izin mikrofon.']);
  });

  test('stop membatalkan seluruh antrean', () async {
    installEngine(utteranceMs: 1500);
    final pending = [
      TTSService.instance.speak('satu'),
      TTSService.instance.speak('dua'),
    ];
    await TTSService.instance.stop();
    await Future.wait(pending);

    expect(stopped, isNotEmpty);
    expect(spoken, isNot(contains('dua')));
  });
}
