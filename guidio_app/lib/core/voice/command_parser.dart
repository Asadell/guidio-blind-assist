import 'intents.dart';

/// CommandParser — varian ucapan → intent, sesuai tabel bagian 14.
/// Sengaja berbasis keyword lokal (0ms, aman offline) mengikuti pola
/// [VoiceProvider] yang sudah ada. Panggil [parse] dengan teks hasil STT.
class CommandParser {
  static const Map<VoiceIntent, List<String>> _phrases = {
    VoiceIntent.modeMoney: [
      'buka mode uang', 'kenali uang', 'ini uang berapa', 'mode uang', 'cek uang', 'berapa ini',
      'uang ini nominal berapa', 'berapa nih duitnya', 'identifikasi uang', 'ini duit berapa ribu',
      'cek duit', 'berapa nominal ini', 'ini pecahan berapa', 'uang berapa ini', 'tolong cek uangnya',
      'lembaran berapa ini', 'duit iki piro', 'duit ieu sabaraha',
    ],
    VoiceIntent.modeReadText: [
      'baca teks', 'bacakan', 'buka mode baca', 'baca tulisan ini', 'apa tulisannya',
      'bacain ini', 'tolong bacain', 'ini tulisan apa', 'baca dong', 'scan teks', 'scan ini',
      'bacakan surat ini', 'apa isinya ini', 'baca kemasan ini', 'cek label ini', 'ini tulisannya apa ya',
      'baca komposisinya', 'baca tanggal kadaluarsanya', 'baca dokumen ini', 'wacaan ieu naon', 'wacanen iki',
    ],
    VoiceIntent.modeDetection: [
      'deteksi objek', 'mode deteksi', 'ada apa di depan',
      'tuntun aku', 'tuntun saya jalan', 'bantu jalan', 'apa itu di depan', 'awas ada apa',
      'ada rintangan gak', 'ada penghalang gak', 'deteksi rintangan', 'tolong tuntun',
      'jalanin mode tuntun', 'aktifkan deteksi', 'nyalain deteksi', 'cek depan',
      'aman gak jalan di depan', 'ada orang gak di depan', 'hati-hati ada apa', 'bantuin lihat depan',
      'ada apa di ngarep', 'ono opo neng ngarep', 'aya naon di hareup',
    ],
    VoiceIntent.modeNavigation: [
      'mode navigasi', 'mau jalan', 'bantu jalan', 'navigasi',
      'kemana ya arahnya', 'tolong arahin', 'navigasi ke', 'gimana caranya ke', 'arahin aku ke',
      'arahin saya ke', 'petunjuk jalan ke', 'rute ke', 'jalan ke mana', 'belok kemana',
      'tunjukin jalan ke', 'ke arah mana ya', 'piye carane menyang', 'kumaha carana ka',
    ],
    VoiceIntent.modeAssistant: [
      'asisten', 'tanya', 'mode suara',
      'halo guidio', 'hei guidio', 'oy guidio', 'guidio', 'jarvis', 'hei jarvis', 'halo jarvis',
      'tolong asisten', 'eh guidio', 'guidio tolong', 'woy guidio', 'eh jarvis tolong',
    ],
    VoiceIntent.modeFindObject: [
      'cari objek', 'cari barang', 'carikan',
    ],
    VoiceIntent.modeSettings: [
      'pengaturan', 'setelan', 'buka pengaturan',
    ],
    VoiceIntent.actionCapture: [
      'ambil gambar', 'jepret', 'foto',
    ],
    VoiceIntent.actionReplay: [
      'putar ulang', 'ulangi', 'baca lagi',
    ],
    VoiceIntent.actionGoBack: [
      'kembali', 'balik', 'kembali ke sebelumnya', 'mode sebelumnya',
      'balik ke mode lain', 'tutup', 'keluar', 'close', 'exit',
      'batal', 'stop', 'berhenti', 'gak jadi', 'ga usah', 'cancel', 'udah cukup',
      'matiin', 'berhentiin', 'jangan', 'udah stop aja', 'gausah lanjut', 'wis mari', 'geus cukup',
    ],
    VoiceIntent.actionSummary: [
      'ringkas', 'singkat saja', 'baca ringkasannya',
    ],
    VoiceIntent.actionStopWalking: [
      'selesai jalan', 'sudah sampai', 'berhenti navigasi',
    ],
    VoiceIntent.actionShowAll: [
      'lihat semua',
    ],
    VoiceIntent.describeScene: [
      // --- Kata tunggal / trigger ---
      'deskripsikan', 'jelaskan', 'ceritakan', 'lihatkan', 'gambarkan', 'terangkan',
      'liatin', 'tunjukin', 'gambarin', 'jelasin', 'ceritain', 'terangin',
      'intipin', 'potret', 'fotoin', 'jepretin', 'pemandangan', 'sekitarku',
      'depanku', 'suasana sekitar', 'kondisi sekitar', 'ada apa',
      // --- Frasa resmi / formal ---
      'deskripsikan yang ada di depan saya sekarang',
      'tolong jelaskan pemandangan di depan',
      'berikan deskripsi suasana tempat ini',
      'sebutkan objek dan keadaan di sekitar saya',
      'gambarkan kondisi di depan saya',
      'mohon jelaskan situasi di sekitar saya saat ini',
      'tolong deskripsikan ruangan ini',
      'silakan jelaskan apa yang ada di hadapan saya',
      'tolong ceritakan suasana di tempat ini',
      'jelaskan kondisi lingkungan sekitar saya',
      'sebutkan apa saja yang terlihat di depan',
      'berikan gambaran suasana ruangan ini',
      'jelaskan situasi di depan saya sekarang',
      'mohon deskripsikan pemandangan di sekitar saya',
      // --- Frasa santai / informal ---
      'lihat depan dong', 'depan ada apa aja sih', 'coba intip depan',
      'ceritakan sekitarku', 'liatin depan bentar', 'ada pemandangan apa di depan',
      'fotoin depan terus jelasin', 'terangin sekitar dong', 'kasi tau depan ada apaan',
      'depan ada apaan sih', 'coba liat depan dong', 'cerita dong depan kayak gimana',
      'sini jelasin depan', 'ini tempat apaan sih', 'sekitar gue ada apa aja',
      'depan gue kayak gimana', 'liat dulu depan', 'cek depan dong',
      'foto depan terus critain', 'jelasin dong ini tempat apa',
      'sini liatin sekitar', 'sekitar sini kayak apa', 'coba liatin sekeliling gue',
      // --- Tanya kondisi ---
      'pemandangan di depan seperti apa', 'ruangan ini kayak gimana',
      'lagi suasana gimana ini', 'di depan ramai atau sepi',
      'apa aja yang kelihatan di depan', 'ini tempat kayak gimana ya',
      'suasana disini gimana', 'di sini ada orang gak', 'depan itu ada apa ya',
      'ini di luar apa di dalam ya', 'ada barang apa aja disini',
      // --- Bahasa Daerah ---
      'ono opo neng ngarep', 'coba sawang ngarep', 'ceritakno neng ngarep',
      'kahanan kepiye iki', 'aya naon di hareup', 'jelaskeun di hareup',
      'tingali di hareup aya naon', 'kumaha kaayaan didieu',
      'ada apaan di depan gue', 'ceritain dong depan', 'intipin depan napa',
      'kondisi depan gimana bang', 'apo nan di adok den', 'aha na di jolo',
      // --- Typo / STT variasi ---
      'deskripsiin', 'deskripsikn', 'critain', 'liyatin', 'trangin', 'gambrkan',
      'pemandanan', 'skitarku', 'keadan', 'kondsi', 'sutuasi', 'lngkungan',
      'deskripsi kan', 'cerita kan', 'lihat kan',
    ],
    VoiceIntent.actionTorch: [
      // nyalakan
      'nyalakan lampu', 'nyalakan senter', 'nyalakan flash',
      'hidupkan lampu', 'hidupkan senter',
      'lampu kamera', 'nyalain lampu', 'nyalain senter',
      'tolong nyalakan lampu', 'tolong nyalain lampu',
      // matikan
      'matikan lampu', 'matikan senter', 'matikan flash',
      'padamkan lampu', 'padamkan senter',
      'matiin lampu', 'matiin senter',
      'tolong matikan lampu', 'tolong matiin lampu',
      // toggle generic
      'toggle lampu', 'toggle senter',
    ],
    VoiceIntent.playPause: [
      'jeda', 'berhenti dulu', 'stop',
    ],
    VoiceIntent.playResume: [
      'lanjut', 'terusin', 'lanjutkan',
    ],
    VoiceIntent.playFaster: [
      'lebih cepat', 'percepat',
    ],
    VoiceIntent.playSlower: [
      'lebih pelan', 'pelan-pelan',
    ],
    VoiceIntent.playRepeatSection: [
      'ulangi bagian', 'ulang yang tadi',
    ],
    VoiceIntent.helpWhat: [
      'bisa apa', 'apa saja', 'bantuan', 'tolong',
    ],
    VoiceIntent.helpWhereAmI: [
      'ini mode apa', 'saya di mana',
    ],
  };

  static const List<String> searchPrefixes = [
    // --- Frasa resmi ---
    'cari',
    'carikan',
    'carilah',
    'tolong cari',
    'tolong carikan',
    'mohon cari',
    'mohon carikan',
    'bantu cari',
    'bantu carikan',
    'coba cari',
    'coba carikan',
    'silakan cari',
    'silakan carikan',
    'temukan',
    'temuin',
    'tunjukin',
    'tunjukkan',
    'deteksi',
    'scan',
    'pindai',

    // --- Frasa gaul / informal ---
    'cariin',
    'cariin dong',
    'cariin deh',
    'cariin dong ya',
    'cariin napa',
    'cariin woy',
    'cariin bentar',
    'cariin sini',
    'cariin cepetan',
    'tolong cariin',
    'tolong cariin dong',
    'tolong cariin ya',
    'bantu cariin',
    'bantu cariin dong',
    'bantuin cari',
    'bantuin cariin',
    'bantuin dong cariin',
    'bantuin nyari',
    'bantu nemuin',
    'tolong temuin',
    'gan cariin',
    'bro cariin',
    'woy cariin',
    'eh cariin',
    'nyari',
    'nyariin',
    'nyari-nyari',
    'lagi nyari',
    'lagi nyariin',
    'lagi cariin',

    // --- Frasa kondisi / kehilangan (resmi) ---
    'kehilangan',
    'saya kehilangan',
    'aku kehilangan',
    'hilang',
    'ilang',
    'kemana',
    'ke mana',
    'dimana',
    'di mana',
    'dimanakah',
    'di manakah',
    'mana',
    'ada dimana',

    // --- Frasa kondisi / kehilangan (informal / slang) ---
    'gue kehilangan',
    'gua kehilangan',
    'ane kehilangan',
    'gw kehilangan',
    'ilangan',
    'ngilang',
    'kemana ya',
    'kemana sih',
    'mana ya',
    'mana sih',
    'mana nih',
    'kaga ketemu',
    'kagak ketemu',
    'gak ketemu',
    'ga ketemu',
    'nggak ketemu',
    'tidak ketemu',
    'belum ketemu',
    'susah nemu',
    'ga nemu',
    'gak nemu',
    'gak nemu-nemu',
    'gak bisa nemu',
    'kok gak ada ya',
    'kok hilang ya',
    'tadi taruh dimana ya',
    'ilang kemana ini',

    // --- Bahasa Daerah (Jawa, Sunda, Betawi, Minang, Batak, Bali, Makassar, Madura) ---
    'ilang kemane',
    'digoleki',
    'goleki',
    'ora ono',
    'ilang neng ndi',
    'diteangan',
    'milarian',
    'leungit dimana',
    'ilang kama',
    'ilang dima',
    'dima yo',
    'ilang huta dison',
    'alai pileh',
    'kija alangan',
    'kemma battu',
    'keng gun edimma',

    // --- Lupa naruh / lupa simpan ---
    'lupa naro',
    'lupa naruh',
    'lupa nataro',
    'lupa taro',
    'lupa taruh',
    'lupa ditaruh',
    'lupa meletakkan',
    'lupa nyimpen',
    'lupa nyimpan',
    'lupa menyimpan',
    'lupa simpen dimana',
    'lupa taro dimana',
    'lupa naro dimana',
    'lupa naruh dimana',

    // --- Minta konfirmasi orang lain / ada yang liat ---
    'ada yang liat',
    'ada yang lihat',
    'ada yg liat',
    'ada yg lihat',
    'ada yang nemu',
    'nemu',
    'nampak',
    'kelihatan',
    'keliatan',
    'kliatan',
    'keliatan gak',
    'keliatan ga',
  ];

  static const List<String> fillerWords = [
    // --- Kata ganti orang / kepemilikan ---
    'saya punya',
    'aku punya',
    'punya saya',
    'punya aku',
    'punya gue',
    'punya gua',
    'punya ane',
    'punyanya',
    'punyaku',
    'saya',
    'aku',
    'gue',
    'gua',
    'gw',
    'ane',
    'kamu',
    'kau',
    'anda',
    'ku',
    'mu',
    'nya',

    // --- Kata seru / partikel / basa-basi & Daerah ---
    'bentar ya',
    'sebentar',
    'bentar',
    'tolong',
    'yaudah',
    'please',
    'dong',
    'deh',
    'nih',
    'tuh',
    'sih',
    'ya',
    'kah',
    'tah',
    'kek',
    'lah',
    'pun',
    'dulu',
    'woy',
    'woi',
    'eh',
    'nah',
    'kok',
    'toh',
    'kan',
    'loh',
    'lho',
    'lo',
    'gitu',
    'gini',
    'aja',
    'saja',
    'juga',
    'napa',
    'plis',
    'yuk',
    'udah',
    'gan',
    'bro',
    'sis',
    'cuy',
    'kayaknya',
    'yah',
    'banget',
    'coba',
    'anu',
    'mmm',
    'eee',
    'e',
    'je',
    'rek',
    'atuh',
    'euy',
    'teh',
    'mah',
    'dah',
    'noh',
    'yee',
    'bang',
    'pole',
  ];

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand(rawText: rawText);

    // 1. Cek pencocokan frasa mode generik / perintah tindakan dulu
    for (final entry in _phrases.entries) {
      if (entry.key == VoiceIntent.modeFindObject) continue; // handle secara dinamis di bawah
      for (final phrase in entry.value) {
        if (text.contains(phrase)) {
          return VoiceCommand(rawText: rawText, intent: entry.key);
        }
      }
    }

    // 2. Cek pencocokan dynamic findObjectTarget menggunakan searchPrefixes
    String? matchedTarget;
    final sortedPrefixes = List<String>.from(searchPrefixes)..sort((a, b) => b.length.compareTo(a.length));
    for (final prefix in sortedPrefixes) {
      if (text.startsWith('$prefix ') || text == prefix) {
        matchedTarget = text.substring(prefix.length).trim();
        break;
      } else if (text.contains(prefix)) {
        final idx = text.indexOf(prefix);
        matchedTarget = text.substring(idx + prefix.length).trim();
        break;
      }
    }

    if (matchedTarget != null && matchedTarget.isNotEmpty) {
      // Clean filler words dari target
      String cleaned = matchedTarget;
      final sortedFillers = List<String>.from(fillerWords)..sort((a, b) => b.length.compareTo(a.length));
      for (final filler in sortedFillers) {
        cleaned = cleaned.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ').trim();
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned.isNotEmpty && cleaned != 'objek' && cleaned != 'barang') {
        return VoiceCommand(
          rawText: rawText,
          intent: VoiceIntent.findObjectTarget,
          argument: cleaned,
        );
      }
    }

    return VoiceCommand(
      rawText: rawText,
      suggestions: _nearestGuesses(text),
    );
  }

  /// Dua tebakan terdekat berbasis jumlah kata yang beririsan — dipakai untuk
  /// naskah "Saya dengar X. Maksudmu Y, atau Z?" (bagian 14, "Tidak dikenali").
  static List<VoiceIntent> _nearestGuesses(String text) {
    final words = text.split(RegExp(r'\s+')).toSet();
    final scored = <MapEntry<VoiceIntent, int>>[];

    for (final entry in _phrases.entries) {
      var best = 0;
      for (final phrase in entry.value) {
        final phraseWords = phrase.split(RegExp(r'\s+')).toSet();
        final overlap = words.intersection(phraseWords).length;
        if (overlap > best) best = overlap;
      }
      if (best > 0) scored.add(MapEntry(entry.key, best));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(2).map((e) => e.key).toList();
  }
}

/// Label ucapan untuk ditawarkan balik ke pengguna, mis. "Maksudmu kenali
/// uang, atau cari uang yang jatuh?" — bagian 14.
extension VoiceIntentSpokenLabel on VoiceIntent {
  String get spokenLabel => switch (this) {
        VoiceIntent.modeMoney => 'kenali uang',
        VoiceIntent.modeReadText => 'baca teks',
        VoiceIntent.modeDetection => 'deteksi objek',
        VoiceIntent.modeNavigation => 'navigasi',
        VoiceIntent.modeAssistant => 'asisten suara',
        VoiceIntent.modeFindObject => 'cari objek',
        VoiceIntent.modeSettings => 'pengaturan',
        VoiceIntent.actionCapture => 'ambil gambar',
        VoiceIntent.actionReplay => 'putar ulang',
        VoiceIntent.actionGoBack => 'kembali',
        VoiceIntent.actionSummary => 'ringkas',
        VoiceIntent.actionStopWalking => 'selesai jalan',
        VoiceIntent.actionShowAll => 'lihat semua',
        VoiceIntent.actionTorch => 'nyalakan lampu',
        VoiceIntent.describeScene => 'deskripsikan suasana',
        VoiceIntent.playPause => 'jeda',
        VoiceIntent.playResume => 'lanjut',
        VoiceIntent.playFaster => 'lebih cepat',
        VoiceIntent.playSlower => 'lebih pelan',
        VoiceIntent.playRepeatSection => 'ulangi bagian',
        VoiceIntent.helpWhat => 'bantuan',
        VoiceIntent.helpWhereAmI => 'saya di mana',
        VoiceIntent.findObjectTarget => 'cari barang',
      };
}
