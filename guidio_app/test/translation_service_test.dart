/// Pengganti `scene_translator_test.dart`.
///
/// Yang diuji di sini BUKAN kualitas terjemahannya - itu milik ML Kit dan
/// tidak berjalan di test host. Yang diuji adalah kontrak yang dipegang
/// `VoiceProvider._handleDescribeScene`: kapan `toIndonesian` boleh menjawab,
/// dan kapan ia WAJIB mengembalikan null supaya deskripsinya tetap keluar
/// dalam Bahasa Inggris alih-alih hilang sama sekali.
///
/// Bagi pengguna tunanetra, kegagalan yang paling mahal di jalur ini bukan
/// terjemahan yang kaku - melainkan mode yang diam karena penerjemahnya
/// melempar exception atau menggantung menunggu unduhan.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/services/translation_service.dart';

const _channel = MethodChannel('google_mlkit_on_device_translator');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Pasang plugin palsu. [downloaded] menentukan jawaban `check`,
  /// [downloadOk] jawaban `download`, [translation] hasil terjemahan.
  /// `null` pada [translation] berarti plugin melempar - meniru kegagalan
  /// native, bukan hasil kosong.
  void installFake({
    bool downloaded = true,
    bool downloadOk = true,
    String? translation = 'Seorang pria berdiri di depan gedung putih.',
    List<String>? log,
  }) {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      log?.add(call.method);
      switch (call.method) {
        case 'nlp#manageLanguageModelModels':
          final task = (call.arguments as Map)['task'];
          if (task == 'check') return downloaded;
          if (task == 'download') return downloadOk ? 'success' : 'failure';
          return 'success';
        case 'nlp#startLanguageTranslator':
          if (translation == null) {
            throw PlatformException(code: 'error', message: 'native gagal');
          }
          return translation;
        case 'nlp#closeLanguageTranslator':
          return null;
      }
      return null;
    });
  }

  setUp(() => TranslationService.instance.resetForTest());
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  group('jalur sehat', () {
    test('caption Inggris jadi Bahasa Indonesia', () async {
      installFake();
      final out = await TranslationService.instance
          .toIndonesian('A man standing in front of a white building');
      expect(out, 'Seorang pria berdiri di depan gedung putih.');
      expect(TranslationService.instance.ready, isTrue);
    });

    test('model yang sudah ada tidak diunduh ulang', () async {
      final log = <String>[];
      installFake(downloaded: true, log: log);
      await TranslationService.instance.prewarm();
      // Dua `check` (en + id), nol `download`.
      expect(log.where((m) => m == 'nlp#manageLanguageModelModels').length, 2);
    });

    test('prewarm bersamaan hanya menyiapkan sekali', () async {
      final log = <String>[];
      installFake(downloaded: false, log: log);
      await Future.wait([
        TranslationService.instance.prewarm(),
        TranslationService.instance.prewarm(),
        TranslationService.instance.prewarm(),
      ]);
      // 2 check + 2 download = 4. Kalau ketiganya jalan sendiri-sendiri
      // angkanya 12, dan pengguna mengunduh 60 MB tiga kali.
      expect(log.length, 4);
    });
  });

  group('arah sebaliknya: nama barang id → en (Mode Cari Objek)', () {
    test('frasa benda jadi prompt Inggris', () async {
      installFake(translation: 'red bag');
      expect(await TranslationService.instance.toEnglish('tas merah'),
          'red bag');
    });

    test('kata yang sama di dua bahasa TIDAK ditolak', () async {
      // Kebalikan aturan di `toIndonesian`. "laptop", "sofa", "helm" memang
      // sama di kedua bahasa; memulangkan null untuk itu berarti menolak
      // terjemahan yang justru sudah benar, lalu YOLOE kehilangan prompt
      // yang sebenarnya sudah siap pakai.
      installFake(translation: 'laptop');
      expect(await TranslationService.instance.toEnglish('laptop'), 'laptop');
    });

    test('tidak menambah unduhan model', () async {
      // Model ML Kit disimpan per BAHASA, bukan per arah. Kedua arah memakai
      // pasangan en+id yang sama, jadi Mode Cari Objek tidak membebani
      // pengguna dengan unduhan kedua.
      final log = <String>[];
      installFake(downloaded: false, log: log);
      await TranslationService.instance.toIndonesian('a red car');
      final afterFirst = log.length;
      await TranslationService.instance.toEnglish('tas merah');
      // Hanya satu panggilan tambahan: terjemahannya sendiri.
      expect(log.length, afterFirst + 1);
    });

    test('menyerah kalau model tidak tersedia', () async {
      expect(await TranslationService.instance.toEnglish('tas merah'), isNull);
    });
  });

  group('menyerah dengan jujur (pemanggil jatuh ke Bahasa Inggris)', () {
    test('plugin tidak terpasang sama sekali', () async {
      // Tanpa mock handler, MethodChannel melempar MissingPluginException.
      final out = await TranslationService.instance.toIndonesian('a red car');
      expect(out, isNull);
      expect(TranslationService.instance.ready, isFalse);
    });

    test('unduhan model gagal', () async {
      installFake(downloaded: false, downloadOk: false);
      expect(await TranslationService.instance.toIndonesian('a red car'),
          isNull);
      expect(TranslationService.instance.lastAttemptFailed, isTrue);
    });

    test('kegagalan tercatat, permintaan berikutnya menyerah cepat', () async {
      installFake(downloaded: false, downloadOk: false);
      await TranslationService.instance.toIndonesian('a red car');

      final log = <String>[];
      installFake(downloaded: false, downloadOk: false, log: log);
      final out = await TranslationService.instance.toIndonesian('a blue car');

      expect(out, isNull);
      // Tidak menyentuh channel lagi: kalau ia mencoba ulang tiap permintaan,
      // setiap deskripsi menunggu unduhan gagal sebelum bicara.
      expect(log, isEmpty);
    });

    test('inferensi native melempar', () async {
      installFake(translation: null);
      expect(await TranslationService.instance.toIndonesian('a red car'),
          isNull);
    });

    test('hasil kosong bukan terjemahan', () async {
      installFake(translation: '   ');
      expect(await TranslationService.instance.toIndonesian('a red car'),
          isNull);
    });

    test('teks sumber dipulangkan apa adanya bukan terjemahan', () async {
      // ML Kit kadang memulangkan input tanpa perubahan. Membacakannya dengan
      // locale id-ID berarti TTS mengeja kalimat Inggris dengan fonetik
      // Indonesia - lebih buruk daripada mengakuinya sebagai Bahasa Inggris.
      installFake(translation: 'A Red Car');
      expect(await TranslationService.instance.toIndonesian('a red car'),
          isNull);
    });

    test('caption kosong tidak dikirim ke plugin', () async {
      final log = <String>[];
      installFake(log: log);
      expect(await TranslationService.instance.toIndonesian('   '), isNull);
      expect(log, isEmpty);
    });
  });
}
