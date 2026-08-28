import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/speech/tts_queue.dart';

/// Uji jalur "jawab sekarang" - `TtsQueue.answerNow`.
///
/// Yang dijaga di sini satu hal, dan hal itu menentukan apakah mode Kenali
/// Uang terasa menjawab atau terasa rusak: **tekanan tombol harus terdengar
/// jawabannya sekarang, bukan sesudah antrean habis.**
///
/// Sebelum jalur ini ada, jawaban nominal masuk ke antrean seperti narasi
/// biasa. Pengguna memegang uang di depan kamera, menekan tombol, lalu
/// mendengar sisa narasi lama dulu, jeda bernapas 700 ms, baru nominalnya.
/// Untuk pengguna tunanetra jeda itu tidak bisa dibedakan dari tombol yang
/// tidak terbaca, dan yang terjadi berikutnya selalu sama: dia menekan lagi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> spoken;
  late List<String> calls;

  setUp(() {
    spoken = [];
    calls = [];
    TtsQueue.instance.minGap = Duration.zero;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      calls.add(call.method);
      if (call.method == 'speak') spoken.add(call.arguments as String);
      return 1;
    });
  });

  tearDown(() async {
    await TtsQueue.instance.stop();
    TtsQueue.instance.minGap = const Duration(milliseconds: 700);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  test('jawaban tombol terdengar walau antrean sedang berisi', () async {
    // Tiga narasi mode menumpuk, seperti saat panduan mode berganti cepat.
    unawaited(TtsQueue.instance.speak('Panduan satu.'));
    unawaited(TtsQueue.instance.speak('Panduan dua.'));
    unawaited(TtsQueue.instance.speak('Panduan tiga.'));

    await TtsQueue.instance.answerNow('Lima puluh ribu rupiah.');
    await settle();

    expect(spoken, contains('Lima puluh ribu rupiah.'));
  });

  test('narasi mode yang menunggu dibuang, tidak menyusul di belakang jawaban',
      () async {
    unawaited(TtsQueue.instance.speak('Panduan satu.'));
    unawaited(TtsQueue.instance.speak('Panduan dua.'));
    unawaited(TtsQueue.instance.speak('Panduan tiga.'));

    await TtsQueue.instance.answerNow('Lima puluh ribu rupiah.');
    await settle();

    // Kalimat basi yang menyusul SESUDAH jawaban justru paling
    // membingungkan: pengguna sudah dapat jawabannya, lalu mendengar
    // panduan yang menggambarkan keadaan beberapa detik lalu.
    final setelahJawaban =
        spoken.sublist(spoken.indexOf('Lima puluh ribu rupiah.') + 1);
    expect(setelahJawaban, isEmpty);
  });

  test('tidak menunggu jeda bernapas', () async {
    // Jeda 700 ms itu benar untuk dua narasi yang datang sendiri. Untuk
    // jawaban yang sudah diminta, ia cuma penundaan.
    TtsQueue.instance.minGap = const Duration(seconds: 5);

    await TtsQueue.instance.speak('Panduan satu.');

    final t0 = DateTime.now();
    await TtsQueue.instance.answerNow('Lima puluh ribu rupiah.');
    final elapsed = DateTime.now().difference(t0);

    expect(spoken, contains('Lima puluh ribu rupiah.'));
    expect(elapsed, lessThan(const Duration(seconds: 1)),
        reason: 'jawaban tombol tidak boleh menunggu minGap');
  });

  test('menekan lagi di tengah kalimat menimpa kalimat itu', () async {
    unawaited(TtsQueue.instance.answerNow('Sepuluh ribu rupiah.'));
    await TtsQueue.instance.answerNow('Lima puluh ribu rupiah.');
    await settle();

    expect(spoken.last, 'Lima puluh ribu rupiah.');
    expect(calls, contains('stop'),
        reason: 'mesin harus benar-benar dihentikan, bukan menunggu selesai');
  });

  test('peringatan bahaya yang tidak bisa dipotong TIDAK ditimpa', () async {
    // Satu-satunya kalimat yang lebih mendesak daripada nominal uang.
    unawaited(TtsQueue.instance.speak(
      'Awas, lubang di depan.',
      tier: SpeechTier.critical,
      interruptible: false,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await TtsQueue.instance.answerNow('Lima puluh ribu rupiah.');
    await settle();

    expect(spoken.first, 'Awas, lubang di depan.',
        reason: 'peringatan bahaya harus selesai lebih dulu');
    expect(spoken, contains('Lima puluh ribu rupiah.'),
        reason: 'jawabannya menunggu, bukan hilang');
  });
}
