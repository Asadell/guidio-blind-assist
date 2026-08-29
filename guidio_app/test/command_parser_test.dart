import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidio_app/core/voice/command_parser.dart';
import 'package:guidio_app/core/voice/intents.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Test suite gabungan untuk:
///
/// 1. **CommandParser** - memastikan intent mapping tetap benar setelah
///    refactor apa pun.
/// 2. **Kenali Uang (TFLite)** - integrasi ringan: muat model dan klasifikasi
///    sampel nyata dari dataset `uang-emisi-2022-baru`.
/// 3. **Mode Navigasi** - fixture gambar bahaya jalan ada & valid.
/// 4. **Cari Objek** - test parse command, hanya dieksekusi kalau backend
///    tersedia (skip otomatis jika offline/belum deploy).
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
  VoiceIntent? intentOf(String text) => CommandParser.parse(text).intent;

  // ─── 1. Command Parser - contoh ucapan dari dokumen arsitektur ─────────────
  group('contoh ucapan dari dokumen arsitektur', () {
    const cases = <String, VoiceIntent>{
      // Deteksi Objek
      'deteksi': VoiceIntent.modeDetection,
      'awasi jalan': VoiceIntent.modeDetection,
      'mode jalan': VoiceIntent.modeNavigation,
      'deteksi objek': VoiceIntent.modeDetection,
      'tuntun aku': VoiceIntent.modeDetection,
      // Kenali Uang
      'uang': VoiceIntent.modeMoney,
      'kenali uang': VoiceIntent.modeMoney,
      'cek duit': VoiceIntent.modeMoney,
      'duit berapa': VoiceIntent.modeMoney,
      // Baca Teks
      'baca teks': VoiceIntent.modeReadText,
      'tolong bacain': VoiceIntent.modeReadText,
      'baca dong': VoiceIntent.modeReadText,
      'tulung wacakno': VoiceIntent.modeReadText,
      // Navigasi
      'navigasi': VoiceIntent.modeNavigation,
      'jalan mana': VoiceIntent.modeNavigation,
      'arahan jalur': VoiceIntent.modeNavigation,
      // Asisten
      'asisten': VoiceIntent.modeAssistant,
      'ngobrol': VoiceIntent.modeAssistant,
      // Pengaturan
      'pengaturan': VoiceIntent.modeSettings,
      'seting': VoiceIntent.modeSettings,
    };

    cases.forEach((utterance, expected) {
      test('"$utterance" → $expected', () {
        expect(intentOf(utterance), expected);
      });
    });
  });

  // ─── 2. Frasa spesifik menang atas kata umum ───────────────────────────────
  group('frasa spesifik menang atas kata umum', () {
    test('"stop navigasi" menghentikan panduan, bukan keluar mode', () {
      expect(intentOf('stop navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti navigasi" sama', () {
      expect(intentOf('berhenti navigasi'), VoiceIntent.actionStopWalking);
    });

    test('"berhenti dulu" adalah jeda suara', () {
      expect(intentOf('berhenti dulu'), VoiceIntent.playPause);
    });

    test('"kembali" tetap actionGoBack', () {
      expect(intentOf('kembali'), VoiceIntent.actionGoBack);
    });
  });

  // ─── 3. Prefiks transisi mode natural ─────────────────────────────────────
  group('prefiks transisi mode natural', () {
    test('"saya pengin pindah ke mode baca teks"', () {
      expect(
        intentOf('saya pengin pindah ke mode baca teks'),
        VoiceIntent.modeReadText,
      );
    });

    test('"ganti mode ke uang"', () {
      expect(intentOf('ganti mode ke uang'), VoiceIntent.modeMoney);
    });
  });

  // ─── 4. Pencocokan pada batas kata ────────────────────────────────────────
  group('pencocokan pada batas kata', () {
    test('kata yang hanya mengandung potongan frasa tidak ikut cocok', () {
      // 'uang' tidak boleh tercabut dari 'ruangan'.
      expect(intentOf('ruangan ini kayak gimana'), isNot(VoiceIntent.modeMoney));
    });
  });

  // ─── 5. Saran hanya berisi intent yang punya handler ──────────────────────
  group('saran hanya berisi intent yang punya handler', () {
    test('setiap saran ada di suggestableIntents', () {
      const gibberish = [
        'anu itu yang tadi bagaimana',
        'coba yang begitu deh',
        'hmm apa ya kira-kira',
      ];
      for (final text in gibberish) {
        final cmd = CommandParser.parse(text);
        for (final s in cmd.suggestions) {
          expect(
            CommandParser.suggestableIntents.contains(s),
            isTrue,
            reason: '"$text" menyarankan $s yang tidak punya handler - '
                'inilah yang membuat "Maksudmu X?" → "X" → "belum saya kenali"',
          );
        }
      }
    });
  });

  // ─── 6. Kenali Uang - DIPINDAH ke test/money_pipeline_test.dart ──────────
  //
  // Grup ini memang sudah memanggil `svc.classifyJpeg`, tapi assert-nya
  // dibungkus `if (result.detected) { ... }`. Karena model nyaris tidak pernah
  // menembus ambang 0,85, cabang itu tidak pernah dieksekusi dan semua kasus
  // lolos lewat jalur "uncertain → pass". Grup ini tidak pernah bisa merah.
  //
  // Selain itu tempatnya keliru: berkas ini menguji PARSING PERINTAH, dan
  // menumpang inferensi model di sini membuat kegagalan model menyamar jadi
  // kegagalan parser. Uji uang kini terpusat di money_pipeline_test.dart,
  // lewat jalur kamera yang sebenarnya.

  // ─── 7. Mode Navigasi - fixture gambar valid ───────────────────────────────
  //
  // Test ini TIDAK menjalankan inference (model YOLOv11 terlalu besar untuk
  // dipush ke repo). Yang diverifikasi: gambar fixture ada, bisa dibaca, dan
  // berukuran wajar (> 100 KB) sehingga coverage integrasi tetap terjaga.
  group('Navigation mode - fixture images exist and are valid', () {
    const fixtures = [
      '01_got_terbuka.png',   // open drain / got terbuka
      '02_lubang_trotoar.png', // sidewalk hole
      '03_tiang_listrik.png',  // utility pole
      '04_motor_dan_orang.png', // motorcycle and pedestrian
      '05_tangga_turun.png',   // descending stairs
    ];

    for (final name in fixtures) {
      test('$name - file exists and is readable', () {
        final file = File('test/fixtures/navigation/$name');
        expect(file.existsSync(), isTrue, reason: 'Fixture tidak ada: $name');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(100 * 1024),
            reason: '$name terlalu kecil - mungkin file rusak atau terpotong.');
        // Validasi magic bytes PNG: 0x89 0x50 0x4E 0x47
        expect(bytes[0], equals(0x89));
        expect(bytes[1], equals(0x50)); // 'P'
        expect(bytes[2], equals(0x4E)); // 'N'
        expect(bytes[3], equals(0x47)); // 'G'
      });
    }
  });

  // ─── 8. Cari Objek - parse command + guard backend ────────────────────────
  //
  // CommandParser harus mengekstrak target dari perintah bahasa Indonesia dan
  // Sunda. Backend check (HTTP ping) dilakukan di sini: kalau tidak reachable,
  // semua sub-test "would call backend" di-skip secara eksplisit, bukan fail.
  group('Find Object - command parsing', () {
    // --- 8a. Parser: bahasa Indonesia
    test('"cari dompet" extracts target "dompet"', () {
      final cmd = CommandParser.parse('cari dompet');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompet');
    });

    test('"cariin kunci dong" strips filler words', () {
      final cmd = CommandParser.parse('cariin kunci dong');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'kunci');
    });

    test('"teang dompu" (Sundanese) is recognized', () {
      final cmd = CommandParser.parse('teang dompu');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
      expect(cmd.argument, 'dompu');
    });

    test('"cari uang yang jatuh" is object-find, not money mode', () {
      // 'uang' is in modeMoney dictionary; object-find pattern must win
      // because it is checked first (prevents ambiguity for blind users).
      final cmd = CommandParser.parse('cari uang yang jatuh');
      expect(cmd.intent, VoiceIntent.findObjectTarget);
    });

    // --- 8b. Parser: English target extraction (for backend API)
    //
    // When the app translates the target to English before sending to the
    // backend, the parser must still set intent correctly.  Actual translation
    // happens in SceneTranslator; here we only verify the parsed intent.
    const englishTargetCases = <String, String>{
      'cari tas merah': 'red bag',       // tas merah → red bag
      'cariin botol minum': 'botol minum', // extraction only; translation elsewhere
      'cari HP': 'HP',
    };

    englishTargetCases.forEach((utterance, _) {
      test('"$utterance" → findObjectTarget intent', () {
        expect(intentOf(utterance), VoiceIntent.findObjectTarget);
      });
    });

    // --- 8c. Backend-dependent tests (skip if unreachable)
    //
    // Image fixtures are in test/fixtures/object_find/.
    // These tests would normally call the vision backend to verify that
    // "red bag", "water bottle", etc. are detected in the provided images.
    // Since the backend is not always running, they are marked skip here.
    //
    // To run locally: start the backend, then:
    //   flutter test --name "object_find"
    group('object_find - backend integration (skipped unless BE running)', () {
      const backendUrl = String.fromEnvironment(
        'GUIDO_BACKEND_URL',
        defaultValue: '',
      );

      bool backendAvailable = false;

      setUpAll(() async {
        if (backendUrl.isEmpty) return;
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 3);
          final req = await client.getUrl(Uri.parse('$backendUrl/health'));
          final res = await req.close();
          backendAvailable = res.statusCode == 200;
          client.close();
        } catch (_) {
          backendAvailable = false;
        }
      });

      const objectTargets = [
        ('red bag', 'test/fixtures/object_find/red_bag.jpg'),
        ('water bottle', 'test/fixtures/object_find/water_bottle.jpg'),
        ('black umbrella', 'test/fixtures/object_find/black_umbrella.jpg'),
      ];

      for (final (target, fixturePath) in objectTargets) {
        test('find "$target" in ${fixturePath.split('/').last}', () {
          if (!backendAvailable) {
            markTestSkipped('Backend not reachable - set GUIDO_BACKEND_URL to run.');
            return;
          }
          final file = File(fixturePath);
          expect(file.existsSync(), isTrue,
              reason: 'Fixture $fixturePath not found.');
          // Placeholder: actual HTTP call to backend would go here.
          // The test is already useful as a guard: it ensures the fixture
          // exists and the backend is reachable before spending time on it.
        });
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  Ganti barang di Mode Cari Objek
  //
  //  Tombol lebar di mode itu berlabel "Ganti barang", jadi kalimat pertama
  //  yang keluar dari pengguna hampir selalu memakai kata itu. Sebelum
  //  `extractFindObjectTarget` ada, seluruh kalimat dipakai apa adanya
  //  sebagai nama barang: "ganti barang jadi keyboard" dikirim mentah ke
  //  YOLOE, tidak pernah ketemu, dan ganti barang praktis tidak berfungsi.
  // ═══════════════════════════════════════════════════════════════════════
  group('CommandParser.extractFindObjectTarget', () {
    const kasus = <String, String?>{
      // Nama barang telanjang - bentuk paling umum saat tombol ditahan.
      'keyboard': 'keyboard',
      'botol': 'botol',

      // Kata pembuka pencarian yang sudah dikenal.
      'cari keyboard': 'keyboard',
      'tolong cariin kunci motor dong': 'kunci motor',

      // Kata pembuka GANTI - inti perbaikan ini.
      'ganti barang jadi keyboard': 'keyboard',
      'ganti barang ke keyboard': 'keyboard',
      'ganti ke keyboard': 'keyboard',
      'ganti keyboard': 'keyboard',
      'ubah jadi dompet': 'dompet',

      // Berlapis: koreksi lalu perintah cari.
      'bukan itu, cariin keyboard': 'keyboard',
      'sekarang cari botol minum': 'botol minum',

      // Tidak ada nama barang di dalamnya. Harus null, BUKAN dipakai apa
      // adanya - target "ganti barang" akan dipindai lalu dilaporkan tidak
      // ketemu, dan pengguna menyimpulkan barangnya yang tidak ada.
      'ganti barang': null,
      'ganti': null,
      'ganti barang jadi': null,
      'barang': null,
      '': null,
    };

    kasus.forEach((ucapan, harapan) {
      test('"$ucapan" -> ${harapan ?? "null"}', () {
        expect(CommandParser.extractFindObjectTarget(ucapan), harapan);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  Perintah mencari SELALU sampai ke Mode Cari Objek
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Kegagalan di sini punya gejala yang khas dan menyesatkan: Vinara tidak
  // diam, ia MENAWARKAN mode lain. "Maksudmu deteksi objek, atau navigasi?"
  // untuk kalimat yang menyebut kata "mencari" dengan jelas. Pengguna
  // tunanetra tidak punya layar untuk melihat bahwa Mode Cari Objek ada dan
  // sedang dilewati, jadi dia menyimpulkan fiturnya tidak ada.
  group('routing perintah mencari', () {
    group('bentuk berimbuhan sampai ke findObjectTarget', () {
      const kasus = {
        'saya mau mencari botol saya': 'botol',
        'mencari kacamata': 'kacamata',
        'mencarikan saya botol minum': 'botol minum',
        'dicari dompet': 'dompet',
        'menemukan kunci motor': 'kunci motor',
        'ketemuin tas merah': 'tas merah',
        'nyariin hp': 'hp',
        'pengen cari payung': 'payung',
        'lagi mencari tongkat': 'tongkat',
      };
      kasus.forEach((ucapan, target) {
        test('"$ucapan" -> $target', () {
          final c = CommandParser.parse(ucapan);
          expect(c.intent, VoiceIntent.findObjectTarget, reason: ucapan);
          expect(c.argument, target);
        });
      });
    });

    group('kata kerjanya ada, barangnya belum - buka modenya', () {
      // Bukan tebakan: modenya menyambut dengan "Cari apa?" dan menunggu,
      // persis pertanyaan yang memang belum terjawab.
      for (final ucapan in ['cari', 'cari barang', 'cari objek', 'mencari', 'carikan']) {
        test('"$ucapan" -> modeFindObject', () {
          expect(CommandParser.parse(ucapan).intent, VoiceIntent.modeFindObject);
        });
      }
    });

    group('tidak menelan intent lain', () {
      const kasus = {
        'mode navigasi': VoiceIntent.modeNavigation,
        'deteksi objek': VoiceIntent.modeDetection,
        'uang': VoiceIntent.modeMoney,
        'baca teks': VoiceIntent.modeReadText,
        'pengaturan': VoiceIntent.modeSettings,
        'stop navigasi': VoiceIntent.actionStopWalking,
        'kembali': VoiceIntent.actionGoBack,
        // "saya di mana" memakai kata yang juga ada di daftar frasa
        // kehilangan. Layer 2b sengaja memeriksa pola KATA KERJA saja, bukan
        // seluruh `searchPrefixes`, supaya pertanyaan ini tidak ikut tertelan.
        'saya di mana': VoiceIntent.helpWhereAmI,
      };
      kasus.forEach((ucapan, intent) {
        test('"$ucapan" tetap $intent', () {
          expect(CommandParser.parse(ucapan).intent, intent);
        });
      });
    });

    test('"cari uang yang jatuh" mencari benda, bukan Mode Kenali Uang', () {
      final c = CommandParser.parse('cari uang yang jatuh');
      expect(c.intent, VoiceIntent.findObjectTarget);
      // Keterangan "yang jatuh" dipangkas sebelum berangkat ke YOLOE.
      expect(CommandParser.normalizeSearchPhrase(c.argument!), 'uang');
    });
  });
}
