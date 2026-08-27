import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/speech/tts_queue.dart';

/// Uji gerbang suara: apa yang dibungkam saat pengguna menahan tombol Bicara.
///
/// Yang dijaga di sini bukan kerapian, melainkan dua hal yang menentukan
/// apakah perintah suara sampai atau tidak:
///
/// 1. **Narasi mode berhenti selama mikrofon terbuka.** Suara aplikasi yang
///    terus berjalan masuk ke mikrofonnya sendiri, dan mesin pengenal
///    menerima dua suara sekaligus.
/// 2. **Jawaban asisten tidak pernah ikut terbungkam.** Kalau ikut, pengguna
///    menahan tombol, bicara, lalu tidak mendengar apa pun - dan tidak punya
///    cara lain memeriksa apakah perintahnya diterima.
///
/// Peringatan bahaya sengaja diuji **menembus** gerbang. Itu keputusan sadar:
/// lubang di depan kaki tidak menunggu sampai pengguna selesai bicara.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Kalimat yang benar-benar sampai ke mesin TTS, urut.
  late List<String> spoken;

  setUp(() {
    spoken = [];
    // Jeda bernapas 700 ms antar ucapan itu benar untuk telinga, tapi di sini
    // ia cuma membuat tiap uji menunggu tanpa menguji apa pun.
    TtsQueue.instance.minGap = Duration.zero;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
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

  /// Beri antrean waktu untuk menguras dirinya.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  group('A. Selama mikrofon terbuka', () {
    test('narasi mode dibuang, tidak sekadar ditunda', () async {
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance.speak('Ada orang di depan.');
      await settle();

      expect(spoken, isEmpty, reason: 'narasi mode tidak boleh terdengar');
      expect(TtsQueue.instance.pendingCount, 0,
          reason: 'dibuang, bukan diantre - narasi yang menumpuk lalu tumpah '
              'setelah gerbang lepas justru lebih membingungkan');
    });

    test('arahan jalur bertier Warning ikut dibungkam', () async {
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance.speak('Geser ke kiri.', tier: SpeechTier.warning);
      await settle();

      expect(spoken, isEmpty);
    });

    test('jawaban asisten TETAP terdengar', () async {
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance.speak(
        'Baik. Kenali Uang aktif.',
        source: SpeechSource.assistant,
      );
      await settle();

      expect(spoken, contains('Baik. Kenali Uang aktif.'));
    });

    test('peringatan bahaya menembus gerbang', () async {
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance.speak(
        'Bahaya! Ada lubang di depan.',
        tier: SpeechTier.critical,
      );
      await settle();

      expect(spoken, contains('Bahaya! Ada lubang di depan.'),
          reason: 'lubang di depan kaki tidak menunggu sampai pengguna '
              'selesai bicara');
    });

    test('kalimat yang dibuang masih bisa terdengar sesudah gerbang lepas',
        () async {
      // Kalau kalimat yang dibuang ikut tercatat di dedup, ia tidak akan bisa
      // masuk lagi selama jendela dedup - narasi yang dibungkam jadi hilang
      // sesudahnya, bukan cuma tertunda.
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance
          .speak('Ada motor di kanan.', dedupKey: 'motor:kanan');
      TtsQueue.instance.endVoiceSession();
      await TtsQueue.instance
          .speak('Ada motor di kanan.', dedupKey: 'motor:kanan');
      await settle();

      expect(spoken, contains('Ada motor di kanan.'));
    });
  });

  group('B. Penutupan gerbang', () {
    test('endVoiceSession menahan gerbang sampai jawaban habis', () async {
      await TtsQueue.instance.beginVoiceSession();
      // Jawaban masuk antrean DULU, baru sesi ditutup - urutan yang sama
      // dengan `VoiceProvider._respond`.
      unawaited(TtsQueue.instance.speak(
        'Baik. Navigasi aktif.',
        source: SpeechSource.assistant,
      ));
      TtsQueue.instance.endVoiceSession();

      expect(TtsQueue.instance.voiceGateClosed, isTrue,
          reason: 'gerbang harus bertahan selama jawaban belum habis, supaya '
              'arahan jalur tidak memotong konfirmasi perintah');

      await settle();
      expect(TtsQueue.instance.voiceGateClosed, isFalse);
      expect(spoken, contains('Baik. Navigasi aktif.'));
    });

    test('tanpa jawaban yang mengantre, gerbang lepas seketika', () async {
      await TtsQueue.instance.beginVoiceSession();
      TtsQueue.instance.endVoiceSession();
      expect(TtsQueue.instance.voiceGateClosed, isFalse);
    });

    test('narasi mode jalan lagi setelah gerbang lepas', () async {
      await TtsQueue.instance.beginVoiceSession();
      TtsQueue.instance.endVoiceSession();
      await TtsQueue.instance.speak('Jalur aman, jalan lurus.');
      await settle();

      expect(spoken, contains('Jalur aman, jalan lurus.'));
    });

    test('stop() ikut melepas gerbang', () async {
      await TtsQueue.instance.beginVoiceSession();
      await TtsQueue.instance.stop();
      expect(TtsQueue.instance.voiceGateClosed, isFalse,
          reason: 'menahan gerbang untuk jawaban yang barusan dibuang hanya '
              'membungkam mode sampai penjaga waktu bertindak');
    });
  });

  group('C. Aksi mode yang diminta lewat suara', () {
    test('berbicara sebagai asisten, jadi tidak terbungkam gerbangnya sendiri',
        () async {
      await TtsQueue.instance.beginVoiceSession();

      // Persis yang terjadi saat pengguna berkata "jepret" di Mode Navigasi:
      // `VoiceProvider` menjalankan aksi milik mode, dan aksi itu bicara.
      TtsQueue.instance.speakModeAsAssistant(() {
        TtsQueue.instance.speak('Suara panduan dimatikan.');
      });
      await settle();

      expect(spoken, contains('Suara panduan dimatikan.'),
          reason: 'jawaban atas perintah pengguna, bukan narasi mode yang '
              'kebetulan lewat');
    });

    test('di luar cakupannya, narasi mode tetap dibungkam', () async {
      await TtsQueue.instance.beginVoiceSession();
      TtsQueue.instance.speakModeAsAssistant(() {});
      await TtsQueue.instance.speak('Ada tiang di kiri.');
      await settle();

      expect(spoken, isEmpty);
    });
  });

  group('D. Jawaban asisten tidak pernah dibuang karena kadaluarsa', () {
    // Narasi mode menggambarkan dunia yang bergerak, jadi yang terlambat
    // memang lebih baik dibuang. Jawaban atas perintah pengguna tidak begitu:
    // dia menahan tombol, bicara, lalu menunggu. Jawaban yang hilang karena
    // antreannya kebetulan panjang terdengar sama persis seperti aplikasi yang
    // tidak mendengar perintahnya, dan dia tidak punya cara membedakannya.
    //
    // Kasus nyata yang dijaga di sini: deskripsi suasana Moondream2 bisa
    // memakan belasan detik, sementara `infoMaxAge` cuma 2 detik. Catatan
    // kualitas yang mengantre di belakangnya - "fotonya agak gelap" - akan
    // SELALU jatuh tempo sebelum gilirannya tiba.
    test('jawaban yang menunggu lebih lama dari infoMaxAge tetap terucap',
        () async {
      TtsQueue.instance.infoMaxAge = const Duration(milliseconds: 40);

      await TtsQueue.instance.speak(
        'Deskripsi panjang.',
        source: SpeechSource.assistant,
      );
      await TtsQueue.instance.speak(
        'Fotonya agak gelap.',
        source: SpeechSource.assistant,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await settle();

      expect(spoken, ['Deskripsi panjang.', 'Fotonya agak gelap.'],
          reason: 'Jawaban asisten kedua dibuang karena dianggap basi. '
              'Pengguna mendengar deskripsinya tapi tidak pernah diberi tahu '
              'bahwa fotonya kurang bagus.');

      TtsQueue.instance.infoMaxAge = const Duration(seconds: 2);
    });

    test('narasi mode yang basi TETAP dibuang', () async {
      // Sisi lain dari aturan yang sama, dan tanpa ini aturan di atas bisa
      // dilonggarkan sampai berlaku untuk semua orang. Narasi rintangan yang
      // sudah lewat harus hilang, bukan menumpuk lalu terucap terlambat.
      //
      // Antrean yang kosong langsung mengucapkan item pertama, jadi tidak ada
      // yang sempat basi. Supaya jalur kadaluarsanya benar-benar dilewati,
      // ucapan pertama dibuat lambat agar yang kedua harus menunggu.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
              (call) async {
        if (call.method == 'speak') {
          spoken.add(call.arguments as String);
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        return 1;
      });
      TtsQueue.instance.infoMaxAge = const Duration(milliseconds: 60);

      await TtsQueue.instance.speak('Kalimat penahan.');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await TtsQueue.instance.speak('Ada orang di depan.');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(spoken, isNot(contains('Ada orang di depan.')),
          reason: 'Narasi mode yang sudah kadaluarsa harus dibuang - '
              'dunia yang digambarkannya sudah berpindah.');

      TtsQueue.instance.infoMaxAge = const Duration(seconds: 2);
    });
  });

  group('E. Penjaga waktu', () {
    test('gerbang tidak pernah tertutup selamanya', () async {
      // Jaring pengaman terakhir. Satu jalur yang lupa menutup sesi akan
      // membuat aplikasi bisu bagi orang yang seluruh antarmukanya adalah
      // suara - kegagalan yang jauh lebih buruk daripada narasi yang lolos
      // beberapa detik terlalu cepat.
      TtsQueue.instance.gateMaxLife = const Duration(milliseconds: 80);
      await TtsQueue.instance.beginVoiceSession();
      expect(TtsQueue.instance.voiceGateClosed, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(TtsQueue.instance.voiceGateClosed, isFalse);

      TtsQueue.instance.gateMaxLife = const Duration(seconds: 30);
    });
  });
}
