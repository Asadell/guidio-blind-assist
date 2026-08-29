import 'intents.dart';

/// CommandParser - varian ucapan → intent, sesuai tabel bagian 14.
/// Sengaja berbasis keyword lokal (0ms, aman offline) mengikuti pola
/// [VoiceProvider] yang sudah ada. Panggil [parse] dengan teks hasil STT.
class CommandParser {
  static const Map<VoiceIntent, List<String>> _phrases = {
    VoiceIntent.modeMoney: [
      'buka mode uang', 'kenali uang', 'ini uang berapa', 'mode uang', 'cek uang', 'berapa ini',
      'uang ini nominal berapa', 'berapa nih duitnya', 'identifikasi uang', 'ini duit berapa ribu',
      'cek duit', 'berapa nominal ini', 'ini pecahan berapa', 'uang berapa ini', 'tolong cek uangnya',
      'lembaran berapa ini', 'duit iki piro', 'duit ieu sabaraha',
      // bank kata tambahan
      'aktifkan mode uang', 'deteksi nominal uang', 'kenali uang ini', 'pecahan berapa nih',
      'liatin duit ini dong', 'ini duit berapa sih', 'berapaan nih duitnya', 'duit gue berapa ya',
      'nih duit apaan', 'berapa nih lembaran ini', 'nominal berapa ini', 'ini uang berapa',
      'cek duit dong', 'nominal uang',
      'ono piro duite', 'iki duit piro', 'piro iki duite',
      'sabaraha ieu artos', 'artosna sabaraha',
      'iko doih barapo', 'berape nih duit',
      'mod uang', 'mode uwang', 'cek uwang', 'nominl uang', 'moda uang', 'mode uan',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'duit berapa', 'berapa duit', 'uang', 'duit',
    ],
    VoiceIntent.modeReadText: [
      'baca teks', 'bacakan', 'buka mode baca', 'baca tulisan ini', 'apa tulisannya',
      'bacain ini', 'tolong bacain', 'ini tulisan apa', 'baca dong', 'scan teks', 'scan ini',
      'bacakan surat ini', 'apa isinya ini', 'baca kemasan ini', 'cek label ini', 'ini tulisannya apa ya',
      'baca komposisinya', 'baca tanggal kadaluarsanya', 'baca dokumen ini', 'wacaan ieu naon', 'wacanen iki',
      // bank kata tambahan
      'aktifkan mode baca dokumen', 'pindai teks', 'baca label kemasan', 'pindai dokumen ini',
      'bacain dong ini', 'baca dong tulisannya', 'ini tulisan apaan', 'scan teks dong',
      'bacain kemasan ini', 'ini tulisan apa ya', 'nih tulisan apaan sih',
      'wacakno tulisan iki', 'moco tulisan iki', 'iki tulisane opo',
      'bacakeun ieu tulisan', 'ieu naon tulisanana',
      'bacoan tulisan ko', 'ko tulisan apo',
      'bacain nih tulisan bang', 'ini tulisan apaan bang',
      'mode bacaa teks', 'bca teks', 'mode ocr', 'baca text ini', 'moda baca teks',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'tulung wacakno', 'wacakno', 'bacakeun',
    ],
    VoiceIntent.modeDetection: [
      'deteksi objek', 'mode deteksi', 'ada apa di depan',
      'tuntun aku', 'tuntun saya jalan', 'bantu jalan', 'apa itu di depan', 'awas ada apa',
      'ada rintangan gak', 'ada penghalang gak', 'deteksi rintangan', 'tolong tuntun',
      'jalanin mode tuntun', 'aktifkan deteksi', 'nyalain deteksi', 'cek depan',
      'aman gak jalan di depan', 'ada orang gak di depan', 'hati-hati ada apa', 'bantuin lihat depan',
      'ada apa di ngarep', 'ono opo neng ngarep', 'aya naon di hareup',
      // bank kata tambahan
      'aktifkan pendeteksi objek', 'kenali objek di sekitar', 'deteksi sekeliling',
      'apa saja yang ada di depan saya', 'liatin depan dong', 'apaan tuh di depan', 'liat depan dong',
      'ada apa aja di depan', 'cek sekitar dong', 'liat sekeliling dong', 'apaan sih di depan gue',
      'ada apaan tuh di depan', 'liatin sekitar dong',
      'ndelok ngarep opo ono', 'iki ono opo ngarepe',
      'aya naon di payun', 'tulung tingali payuneun',
      'apo tu di adok an', 'caliak lah adok an',
      'ada ape tuh di depan', 'apaan tuh di depan bang',
      'mode deteski', 'deteksi obek', 'mode dtksi', 'cek skeliling',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'awasi jalan', 'deteksi',
    ],
    VoiceIntent.modeNavigation: [
      'mode navigasi', 'mau jalan', 'bantu jalan', 'navigasi',
      'kemana ya arahnya', 'tolong arahin', 'navigasi ke', 'gimana caranya ke', 'arahin aku ke',
      'arahin saya ke', 'petunjuk jalan ke', 'rute ke', 'jalan ke mana', 'belok kemana',
      'tunjukin jalan ke', 'ke arah mana ya', 'piye carane menyang', 'kumaha carana ka',
      // bank kata tambahan
      'aktifkan navigasi jalan', 'pandu saya berjalan', 'aktifkan panduan jalan',
      'anterin gue jalan', 'pandu gue jalan dong', 'bantuin gue jalan', 'gue mau jalan nih',
      'bantu gue nyebrang', 'pandu jalan dong', 'temenin gue jalan dong',
      'tulung tuntun mlaku', 'kancani aku mlaku',
      'tulung antar abdi leumpang', 'antosan abdi leumpang',
      'tolong anta ambo jalan', 'anterin gue jalan bang',
      'mode navigsi', 'mode navigasii', 'bantu jalann', 'aktifkan navgasi',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'jalan mana', 'mode jalan', 'arahan jalur', 'jalur mana',
    ],
    VoiceIntent.modeAssistant: [
      // Nama modenya kini "Deskripsi Sekitar", tapi frasa lama TETAP
      // dikenali. Label di layar bisa diganti sepihak; kebiasaan bicara
      // pengguna tidak. Membuang "suasana" berarti perintah yang kemarin
      // bekerja hari ini dijawab "belum saya kenali" - dan pengguna
      // tunanetra tidak punya layar untuk melihat bahwa namanya berubah.
      'deskripsi sekitar', 'deskripsikan sekitar', 'mode deskripsi sekitar',
      'deskripsi suasana', 'deskripsikan suasana', 'mode deskripsi suasana',
      'asisten', 'tanya', 'mode suara',
      'halo guidio', 'hei guidio', 'oy guidio', 'guidio', 'jarvis', 'hei jarvis', 'halo jarvis',
      'tolong asisten', 'eh guidio', 'guidio tolong', 'woy guidio', 'eh jarvis tolong',
      // bank kata tambahan
      'buka mode asisten suara', 'aktifkan asisten', 'saya ingin bertanya', 'buka mode tanya jawab',
      'bisa bantu saya', 'gue mau nanya', 'nanya dong', 'lu bisa jawab gak', 'bisa bantu gak',
      'gue mau ngobrol', 'boleh nanya gak', 'mau nanya sesuatu nih',
      'aku arep takon', 'iso mbantu ora',
      'abdi bade naros', 'tiasa ngabantosan teu',
      'ambo nio batanyo', 'gue mau nanye bang',
      'mode asisten suaraa', 'aktifkan asistem', 'buka asistenn',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'ngobrol', 'bicara', 'nanya',
    ],
    VoiceIntent.modeFindObject: [
      'cari objek', 'cari barang', 'carikan',
      // bank kata tambahan
      'aktifkan pencarian barang', 'bantu saya cari barang', 'cari barang saya yang hilang',
      'tolong bantu temukan barang saya', 'cariin dong', 'bantu carinya dong',
      'gue kehilangan barang', 'barang gue ilang nih',
      'tulung goleki barangku', 'barangku ilang golekno',
      'tulung pilarian barang', 'barang abdi leungit',
      'tolong cari barang ambo', 'ilang nih barang gue',
      'mode cari barangg', 'cariinn dong', 'aktifkan carii barang',
    ],
    VoiceIntent.modeSettings: [
      'pengaturan', 'setelan', 'buka pengaturan',
      // bank kata tambahan
      'mode pengaturan', 'aktifkan menu pengaturan', 'buka menu konfigurasi',
      'buka setting dong', 'buka setelan dong', 'gue mau atur aplikasi', 'masuk setting dong',
      'buka setelan yo', 'muka setelan atuh',
      'buka pengaturann', 'mode setingan', 'buka stelan',
      // Frasa yang dijanjikan dokumen tapi dulu tidak pernah cocok.
      'seting', 'setting', 'setelan',
    ],
    VoiceIntent.actionCapture: [
      'ambil gambar', 'jepret', 'foto',
    ],
    VoiceIntent.actionReplay: [
      'putar ulang', 'ulangi', 'baca lagi',
      // bank kata tambahan
      'ulangi instruksi', 'ulangi perkataan terakhir', 'tolong ulangi', 'ulangi lagi',
      'ulang dong', 'bilang lagi dong', 'ulangin dong', 'apa tadi bilangnya', 'coba ulang deh',
      'baleni maneh', 'baleni sing mau',
      'ulang deui', 'ulangan anu tadi',
      'ulangi lai', 'ulangin dong bang',
      'ulangii instruksi', 'ulangi lgi',
    ],
    VoiceIntent.actionGoBack: [
      'kembali', 'balik', 'kembali ke sebelumnya', 'mode sebelumnya',
      'balik ke mode lain', 'tutup', 'keluar', 'close', 'exit',
      'batal', 'stop', 'berhenti', 'gak jadi', 'ga usah', 'cancel', 'udah cukup',
      'matiin', 'berhentiin', 'jangan', 'udah stop aja', 'gausah lanjut', 'wis mari', 'geus cukup',
    ],
    VoiceIntent.actionSummary: [
      'ringkas', 'singkat saja', 'baca ringkasannya',
      // bank kata tambahan
      'berikan rangkuman objek', 'rangkum objek di sekitar', 'buat ringkasan objek sekitar',
      'rangkum dong', 'kasih ringkasan dong', 'ringkes dong sekitar gue', 'rangkumin dong',
      'kasih tau intinya aja', 'summary dong',
      'ringkes o wae kahanane', 'ringkeskeun kaayaan sabudeureun',
      'ringkasan objekk', 'rangkum objekk sekitar',
    ],
    VoiceIntent.actionStopWalking: [
      'selesai jalan', 'sudah sampai', 'berhenti navigasi',
      // bank kata tambahan
      'hentikan panduan', 'stop navigasi', 'jeda panduan jalan', 'tolong berhenti dulu',
      'pause navigasi', 'stop dulu', 'berenti dulu', 'berhenti bentar', 'jeda dulu dong',
      'mandeg disik', 'mandeg dhisik yo',
      'eureun heula', 'eureun sakedap',
      'baranti sabanta', 'stop dulu bang',
      'berhentii navigasi', 'hentikn panduan', 'stop navigasii',
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
      'berikan deskripsi sekitar tempat ini',
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
      // bank kata tambahan
      'aktifkan lampu kamera', 'nyalakan lampu kamera', 'matikan lampu kamera',
      'nonaktifkan senter', 'idupin senter', 'matiin lampu dong', 'nyalain lampu dong',
      'urupno senter', 'patenono senter', 'tulung urupno lampu',
      'hurungkeun senter', 'pareuman senter',
      'nyalain senter bang', 'matiin senter bang',
      'nyalain sentr', 'aktifkn senter', 'nyalakan sentar',
    ],
    VoiceIntent.playPause: [
      'jeda', 'berhenti dulu', 'stop',
      // bank kata tambahan
      'jeda suara', 'pause suara', 'hentikan sebentar suaranya', 'jeda dong',
      'stop bentar suaranya', 'pause dulu',
      'mandeg disik swarane', 'eureun heula sorana', 'baranti sabanta suaronyo',
      'jeda suaraa', 'pauze suara',
    ],
    VoiceIntent.playResume: [
      'lanjut', 'terusin', 'lanjutkan',
    ],
    VoiceIntent.playFaster: [
      'lebih cepat', 'percepat',
      // bank kata tambahan
      'percepat suara', 'percepat laju bicara', 'naikkan kecepatan suara',
      'cepetin dong', 'gasin dong suaranya', 'lebih cepet dong',
      'kebutno swarane', 'gancangkeun sorana',
      'cepetin bang suaranye',
      'percepat suaraa', 'cepetin suarane',
    ],
    VoiceIntent.playSlower: [
      'lebih pelan', 'pelan-pelan',
      // bank kata tambahan
      'perlambat suara', 'perlambat laju bicara', 'turunkan kecepatan suara',
      'pelanin dong', 'pelanin suaranya dong', 'lebih pelan dong', 'jangan cepet-cepet dong',
      'alonno swarane', 'lambatkeun sorana',
      'pelanin bang suaranye',
      'perlambat suaraa', 'pelanin suarane',
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
    // --- Bentuk berimbuhan me- (BAKU, dan yang paling sering diucapkan) ---
    //
    // Ini pernah HILANG sama sekali dari daftar, dan akibatnya bukan sekadar
    // satu ucapan yang meleset. "Saya mau mencari botol saya" tidak cocok
    // dengan satu pun frasa di seluruh kamus, jadi `parse` mengembalikan
    // intent kosong dan Vinara jatuh ke tebakan kemiripan kata - lalu
    // bertanya "Maksudmu deteksi objek, atau navigasi?" untuk kalimat yang
    // menyebut kata "mencari" dengan jelas.
    //
    // Untuk pengguna tunanetra, ditawari dua mode yang sama-sama salah lebih
    // buruk daripada tidak dimengerti: dia tidak punya layar untuk melihat
    // bahwa Mode Cari Objek ada dan sedang dilewati.
    'mencari',
    'mencarikan',
    'menemukan',
    'mencari-cari',
    'menyari',
    'nemuin',
    'nemu',
    'ketemuin',

    // --- Bentuk berniat ("saya mau ...", "pengen ...") ---
    //
    // Diletakkan sebagai frasa utuh, bukan mengandalkan "cari" saja, supaya
    // yang terpotong benar-benar sampai kata kerjanya. Tanpa ini "mau cari
    // botol" tetap ketemu lewat "cari", tapi "mau mencari botol" tidak.
    'mau cari',
    'mau carikan',
    'mau mencari',
    'mau nyari',
    'ingin cari',
    'ingin mencari',
    'pengen cari',
    'pengen mencari',
    'pengen nyari',
    'pingin cari',
    'pingin nyari',
    'kepengen cari',
    'lagi cari',
    'lagi mencari',
    'sedang mencari',
    'butuh cari',

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
    'teangan',
    'teang',
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

  /// Kata pembuka "ganti barang" di Mode Cari Objek.
  ///
  /// Bedanya dengan [searchPrefixes]: yang ini bukan cara MEMULAI pencarian,
  /// melainkan cara MENGGANTI barang yang sedang dicari. Tombol lebar di mode
  /// itu berlabel "Ganti barang", jadi kalimat pertama yang keluar dari
  /// pengguna hampir selalu memakai kata-kata ini - dan sebelum daftar ini
  /// ada, seluruh kalimatnya dipakai apa adanya sebagai nama barang. Ucapan
  /// "ganti barang jadi keyboard" berakhir sebagai target harfiah "ganti
  /// barang jadi keyboard", dikirim mentah ke YOLOE, dan tidak pernah ketemu.
  ///
  /// Diurutkan dari yang terpanjang saat dipakai, supaya "ganti barang jadi"
  /// menang atas "ganti" dan sisa kalimatnya tidak ikut terbawa.
  static const List<String> changeTargetPrefixes = [
    // --- Ganti target, bentuk lengkap ---
    'ganti barang jadi',
    'ganti barang ke',
    'ganti barang menjadi',
    'ganti barangnya jadi',
    'ganti barangnya ke',
    'ganti target jadi',
    'ganti target ke',
    'ganti objek jadi',
    'ganti objek ke',
    'ganti cari',
    'ganti carikan',

    // --- Ganti target, bentuk pendek ---
    'ganti barangnya',
    'ganti barang',
    'ganti target',
    'ganti objek',
    'ganti menjadi',
    'ganti dengan',
    'ganti jadi',
    'ganti ke',
    'gantian',
    'ganti',

    // --- Ubah / tukar ---
    'ubah barang jadi',
    'ubah barang ke',
    'ubah barangnya',
    'ubah barang',
    'ubah menjadi',
    'ubah jadi',
    'ubah ke',
    'ubah',
    'tukar jadi',
    'tukar ke',
    'tukar',

    // --- Koreksi: "bukan itu, yang saya cari ..." ---
    'bukan itu tapi',
    'bukan itu',
    'bukan yang itu',
    'salah bukan itu',
    'bukan',
    'salah',

    // --- Beralih ke barang lain ---
    'sekarang cari',
    'sekarang carikan',
    'sekarang',
    'gantinya',
    'lanjut cari',
    'terus cari',
    'berikutnya',
    'yang lain',
    'barang lain',
    'objek lain',
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

  /// Prefiks pengantar mode alami bahasa Indonesia yang sering diucapkan pengguna
  static const List<String> modeTransitionPrefixes = [
    'saya pengin pindah ke mode',
    'saya mau pindah ke mode',
    'pengin pindah ke mode',
    'mau pindah ke mode',
    'pindah ke mode',
    'pindah mode ke',
    'pindah mode',
    'pindahin ke mode',
    'pindahin ke',
    'ganti mode ke',
    'ganti ke mode',
    'ganti mode',
    'masuk ke mode',
    'masuk mode',
    'buka mode',
    'tolong buka mode',
    'tolong pindah ke',
    'tolong ganti ke',
    'mau ke mode',
    'pengin ke mode',
    'aktifkan mode',
    'nyalakan mode',
    'jalankan mode',
  ];

  // ===========================================================================
  // Normalisasi & pencocokan batas kata
  //
  // Versi lama memakai `text.contains(phrase)` mentah dan menelusuri `_phrases`
  // **mengikuti urutan deklarasi Map**. Dua akibatnya nyata:
  //
  //   1. `actionGoBack` memuat 'stop' dan 'berhenti', dan ia dideklarasikan
  //      sebelum `actionStopWalking` dan `playPause`. Maka "stop navigasi" -
  //      yang jelas dimaksudkan untuk menghentikan panduan - malah **keluar
  //      dari Mode Navigasi**. Sebagian besar frasa kedua intent itu tidak
  //      pernah bisa tercapai.
  //   2. `contains` tanpa batas kata membuat potongan kata ikut cocok.
  //
  // Sekarang: frasa dicocokkan pada batas kata, dan **yang paling panjang
  // diperiksa lebih dulu** - yang spesifik selalu menang atas yang umum,
  // terlepas dari urutan deklarasi.
  // ===========================================================================

  static String _normalize(String s) {
    final lowered = s.toLowerCase();
    final buf = StringBuffer(' ');
    for (final rune in lowered.runes) {
      final c = String.fromCharCode(rune);
      final isWordChar = (rune >= 97 && rune <= 122) || // a-z
          (rune >= 48 && rune <= 57) || // 0-9
          c == '-';
      buf.write(isWordChar ? c : ' ');
    }
    buf.write(' ');
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// True kalau [phrase] muncul di [normalized] sebagai rangkaian kata utuh.
  static bool _containsPhrase(String normalized, String phrase) =>
      normalized.contains(' ${_normalize(phrase).trim()} ');

  /// Semua (frasa, intent) diurutkan dari yang terpanjang. Dibangun sekali.
  static List<MapEntry<String, VoiceIntent>>? _sortedPhrasesCache;

  static List<MapEntry<String, VoiceIntent>> get _sortedPhrases {
    final cached = _sortedPhrasesCache;
    if (cached != null) return cached;
    final all = <MapEntry<String, VoiceIntent>>[];
    for (final entry in _phrases.entries) {
      // modeFindObject ditangani dinamis lewat searchPrefixes.
      if (entry.key == VoiceIntent.modeFindObject) continue;
      for (final phrase in entry.value) {
        all.add(MapEntry(phrase, entry.key));
      }
    }
    all.sort((a, b) => b.key.length.compareTo(a.key.length));
    return _sortedPhrasesCache = all;
  }

  static int _wordCount(String phrase) => phrase.trim().split(' ').length;

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand(rawText: rawText);
    final norm = _normalize(rawText);

    // =========================================================================
    // [Fuzzy Matching Layer 0] - Natural Conversational Mode Transition
    // Handles natural spoken sentences like: "Saya pengin pindah ke mode baca teks"
    // Strips conversational prefixes and extracts target keywords (baca, uang, etc).
    // =========================================================================
    for (final prefix in modeTransitionPrefixes) {
      if (text.contains(prefix)) {
        final targetPart = text.substring(text.indexOf(prefix) + prefix.length).trim();
        if (targetPart.contains('uang') || targetPart.contains('duit') || targetPart.contains('money')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeMoney);
        }
        if (targetPart.contains('baca') || targetPart.contains('teks') || targetPart.contains('tulisan') || targetPart.contains('ocr')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeReadText);
        }
        if (targetPart.contains('deteksi') || targetPart.contains('tuntun') || targetPart.contains('objek') || targetPart.contains('rintangan')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeDetection);
        }
        if (targetPart.contains('navigasi') || targetPart.contains('jalan') || targetPart.contains('rute')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeNavigation);
        }
        if (targetPart.contains('asisten') || targetPart.contains('suara') || targetPart.contains('tanya') || targetPart.contains('voice')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeAssistant);
        }
        if (targetPart.contains('cari') || targetPart.contains('barang') || targetPart.contains('find')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeFindObject);
        }
        if (targetPart.contains('pengaturan') || targetPart.contains('setelan') || targetPart.contains('setting')) {
          return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeSettings);
        }
      }
    }

    // =========================================================================
    // [Layer 1] - Frasa kamus MULTI-KATA, terpanjang lebih dulu.
    //
    // Frasa banyak kata mengungkap maksud jauh lebih tegas daripada satu kata
    // lepas, jadi ia diperiksa sebelum apa pun. Di sinilah "stop navigasi"
    // menemukan `actionStopWalking` sebelum kata 'stop' sempat membawanya ke
    // `actionGoBack`.
    // =========================================================================
    for (final entry in _sortedPhrases) {
      if (_wordCount(entry.key) < 2) continue;
      if (_containsPhrase(norm, entry.key)) {
        return VoiceCommand(rawText: rawText, intent: entry.value);
      }
    }

    // =========================================================================
    // [Layer 2] - Pola cari-objek dinamis ("cari [barang]").
    //
    // Sengaja SEBELUM kata tunggal: "cari uang yang jatuh" harus berarti
    // mencari benda, bukan membuka Mode Kenali Uang hanya karena kata 'uang'
    // muncul di dalamnya.
    // =========================================================================
    final target = _extractSearchTarget(norm);
    if (target != null) {
      return VoiceCommand(
        rawText: rawText,
        intent: VoiceIntent.findObjectTarget,
        argument: target,
      );
    }

    // =========================================================================
    // [Layer 2b] - Kata kerja mencari terdengar, barangnya belum disebut.
    //
    // "cari barang", "cari", "mencari" - tidak satu pun punya nama benda yang
    // bisa dipakai, jadi Layer 2 menolaknya. Tapi maksudnya sama sekali tidak
    // kabur: pengguna sedang minta MENCARI.
    //
    // Tanpa cabang ini kalimat-kalimat itu jatuh sampai ke tebakan kemiripan
    // kata, dan Vinara menawarkan "deteksi objek, atau navigasi?" - dua mode
    // yang sama-sama bukan yang diminta. `_phrases[modeFindObject]` sengaja
    // TIDAK ikut `_sortedPhrases` (mode ini ditangani dinamis lewat
    // `searchPrefixes`), jadi bahkan frasa harfiah "cari barang" yang tertulis
    // di sana tidak pernah punya kesempatan cocok di Layer 1 maupun Layer 3.
    //
    // Membuka modenya adalah jawaban yang benar, bukan tebakan: Mode Cari
    // Objek menyambut dengan "Cari apa?" dan menunggu - persis pertanyaan yang
    // memang belum terjawab.
    //
    // Diperiksa dengan pola kata kerja, BUKAN seluruh `searchPrefixes`. Daftar
    // itu memuat frasa kehilangan seperti "dimana" dan "mana", dan
    // memperlakukannya sebagai perintah mencari akan menelan pertanyaan yang
    // artinya lain sama sekali.
    // =========================================================================
    if (norm.split(' ').any((w) => w.isNotEmpty && _searchVerb.hasMatch(w))) {
      return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeFindObject);
    }

    // =========================================================================
    // [Layer 3] - Kata tunggal ("uang", "deteksi", "navigasi", "asisten").
    // =========================================================================
    for (final entry in _sortedPhrases) {
      if (_wordCount(entry.key) != 1) continue;
      if (_containsPhrase(norm, entry.key)) {
        return VoiceCommand(rawText: rawText, intent: entry.value);
      }
    }

    // =========================================================================
    // [Layer 4] - Kombinasi kata kunci longgar ("baca" + "mode").
    // =========================================================================
    bool has(String w) => _containsPhrase(norm, w);
    if (has('mode') || has('buka') || has('aktifkan')) {
      if (has('baca') || has('teks') || has('tulisan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeReadText);
      }
      if (has('uang') || has('duit')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeMoney);
      }
      if (has('deteksi') || has('tuntun') || has('rintangan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeDetection);
      }
      if (has('navigasi') || has('jalur') || has('jalan')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeNavigation);
      }
      if (has('asisten') || has('suara') || has('tanya')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeAssistant);
      }
      if (has('cari') || has('barang')) {
        return VoiceCommand(rawText: rawText, intent: VoiceIntent.modeFindObject);
      }
    }

    return VoiceCommand(
      rawText: rawText,
      suggestions: _nearestGuesses(norm),
    );
  }

  /// Ambil nama barang sesudah prefiks pencarian, lalu buang kata pengisi.
  /// Mengembalikan null kalau tidak ada prefiks atau sisanya kosong.
  /// Nama barang dari satu ucapan di Mode Cari Objek.
  ///
  /// Dipakai tombol "Sebutkan barang" / "Ganti barang", yang berbeda dari
  /// tombol perintah suara di tengah: di sini SELURUH ucapan memang
  /// dimaksudkan sebagai nama barang, bukan perintah. Karena itu ia tidak
  /// lewat [parse] penuh - "keyboard" saja harus sah, padahal [parse]
  /// mengembalikan intent kosong untuknya.
  ///
  /// Yang dikerjakannya cuma satu: membuang kata pembuka sampai yang tersisa
  /// benar-benar nama barang.
  ///
  ///     'keyboard'                     -> 'keyboard'
  ///     'cari keyboard'                -> 'keyboard'
  ///     'ganti barang jadi keyboard'   -> 'keyboard'
  ///     'bukan itu, cariin keyboard'   -> 'keyboard'
  ///     'ganti barang'                 -> null
  ///
  /// `null` berarti tidak ada nama barang di dalamnya. Itu jawaban yang
  /// BERGUNA, bukan kegagalan: pemanggil menjawabnya dengan "Cari apa?" dan
  /// menunggu, alih-alih memasang kalimat pembuka sebagai nama barang lalu
  /// memindai sesuatu yang tidak pernah ada.
  static String? extractFindObjectTarget(String rawText) {
    var norm = _normalize(rawText);
    if (norm.trim().isEmpty) return null;

    // Kupas kata pembuka berlapis: "ganti, sekarang cari keyboard" punya dua.
    // Dibatasi supaya kalimat yang isinya HANYA kata pembuka berhenti sebagai
    // kosong, bukan berputar.
    final sorted = List<String>.from(changeTargetPrefixes)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (var putaran = 0; putaran < 3; putaran++) {
      var terkupas = false;
      for (final prefix in sorted) {
        final needle = ' ${_normalize(prefix).trim()} ';
        if (!norm.startsWith(needle)) continue;
        norm = _normalize(norm.substring(needle.length - 1));
        terkupas = true;
        break;
      }
      if (!terkupas || norm.trim().isEmpty) break;
    }

    if (norm.trim().isEmpty) return null;

    // Sisanya bisa saja masih berbentuk "cari keyboard" - itu urusan
    // [_extractSearchTarget], yang sudah tahu semua cara orang menyebutnya.
    final viaPrefix = _extractSearchTarget(norm);
    if (viaPrefix != null) return viaPrefix;

    var cleaned = norm.trim();
    for (final filler in _sortedFillers) {
      cleaned = cleaned.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Kata yang tidak menunjuk benda apa pun. Memakainya sebagai target
    // berarti memindai "itu" dan melaporkan tidak ketemu.
    const kosong = {'', 'barang', 'barangnya', 'objek', 'objeknya', 'benda',
      'bendanya', 'itu', 'ini', 'apa', 'apapun', 'sesuatu'};
    if (kosong.contains(cleaned)) return null;

    return cleaned;
  }

  /// Kata yang tidak menyebut benda maupun sifatnya, dan cuma membuat
  /// terjemahan mesin melenceng.
  ///
  /// Ini lapisan tambahan di atas [fillerWords], bukan penggantinya. Yang
  /// tersisa di sini spesifik untuk frasa benda, dan baru terasa saat
  /// frasanya diserahkan ke penerjemah mesin:
  ///
  ///   "botol minum warna biru" → ML Kit → "blue color drinking bottle"
  ///   "botol minum biru"       → ML Kit → "blue drinking bottle"
  ///
  /// Prompt kedua yang dimengerti encoder teks YOLOE. Kata "warna" benar
  /// secara Bahasa Indonesia tapi jadi kata benda "color" di Inggris, dan
  /// itu menggeser arti frasanya dari "botol yang biru" jadi "warna botol".
  static const List<String> _searchNoiseWords = [
    'warna', 'warnanya', 'berwarna',
    'yang', 'yg',
    'kesayangan', 'kesayanganku', 'favorit', 'favoritku',
    'milik', 'miliknya', 'kepunyaan', 'punya',
    'tadi', 'barusan', 'kemarin', 'sekarang',
    'buat', 'untuk', 'sama', 'pakai', 'pake',
  ];

  /// Kata yang menandai BATAS akhir nama barang.
  ///
  /// Sesudahnya bukan lagi deskripsi bendanya, melainkan keterangan tempat
  /// atau waktu - "tas merah **di** meja", "kunci **dekat** pintu". Encoder
  /// teks YOLOE mencocokkan SELURUH frasa dengan isi gambar, jadi "red bag
  /// on the table" mencari sesuatu yang serentak tas, merah, DAN meja.
  /// Kalau meja yang dimaksud kebetulan tidak masuk frame, tasnya ikut
  /// tidak ketemu - padahal tasnya ada.
  ///
  /// Dipotong, bukan dibuang kata per kata: yang di belakang penanda ini
  /// hampir tidak pernah menambah informasi tentang bendanya.
  static const List<String> _phraseCutMarkers = [
    'di', 'didalam', 'diatas', 'dibawah', 'disebelah', 'didekat',
    'dalam', 'atas', 'bawah', 'sebelah', 'dekat', 'deket', 'samping',
    'depan', 'belakang', 'antara', 'sekitar',
    'waktu', 'ketika', 'saat', 'pas',
    // Kata kerja penyimpanan/kehilangan. Sesudahnya selalu keterangan, bukan
    // bendanya: "kunci yang saya **taruh** di meja", "uang yang **jatuh**".
    // Tanpa ini "taruh" ikut terbawa dan jadi "put" di prompt YOLOE.
    'taruh', 'naruh', 'taro', 'naro', 'ditaruh', 'ditaro',
    'simpan', 'nyimpan', 'nyimpen', 'disimpan',
    'letakkan', 'meletakkan', 'diletakkan',
    'lupa', 'ketinggalan', 'tertinggal', 'jatuh', 'kejatuhan',
    'kebawa', 'terbawa', 'ketuker', 'tertukar',
  ];

  /// Kata yang menunjuk "benda" tanpa menyebut benda apa pun.
  ///
  /// Kalau yang tersisa sesudah semua penyaringan cuma ini, artinya pengguna
  /// belum menyebutkan barangnya. Mengirimnya ke YOLOE berarti memindai kata
  /// "itu" lalu melaporkan tidak ketemu - jawaban yang terdengar seperti
  /// barangnya tidak ada, padahal pertanyaannya yang belum lengkap.
  static const Set<String> _nonObjectWords = {
    'barang', 'barangnya', 'objek', 'objeknya', 'benda', 'bendanya',
    'itu', 'ini', 'apa', 'apapun', 'sesuatu', 'sesuatunya', 'anu',
  };

  /// Batas jumlah kata yang berangkat ke YOLOE.
  ///
  /// Frasa benda Bahasa Indonesia menaruh kata bendanya di DEPAN, lalu
  /// sifatnya: "botol minum plastik biru" sudah empat kata dan itu sudah
  /// sangat spesifik. Yang melewati batas ini bukan nama barang yang lebih
  /// tepat, melainkan kalimat yang lolos dari penyaringan di atas - dan
  /// setiap kata tambahan MEMPERSEMPIT hasil YOLOE, bukan memperjelasnya.
  static const int _maxPhraseWords = 4;

  /// Saring frasa benda sampai yang tersisa benar-benar cuma nama barang,
  /// siap diterjemahkan lalu dikirim ke YOLOE.
  ///
  /// Sengaja dibuat MANDIRI dan idempoten - aman dijalankan pada teks yang
  /// sudah bersih maupun pada ucapan mentah. Alasannya bukan kerapian:
  /// `_target` bisa datang dari tiga jalur berbeda (perintah suara global,
  /// tombol "Ganti barang" di layar, dan target tersimpan saat offline), dan
  /// hanya dua di antaranya yang sudah lewat pengupas kata pembuka. Filter
  /// yang mengandalkan pemanggilnya sudah bersih akan bocor tepat di jalur
  /// ketiga, diam-diam.
  ///
  ///     'tolong carikan tas merah'        -> 'tas merah'
  ///     'ganti barang jadi keyboard'      -> 'keyboard'
  ///     'botol minum warna biru'          -> 'botol minum biru'
  ///     'tas merah di atas meja tadi'     -> 'tas merah'
  ///     'cariin dong barangnya'           -> ''      (belum menyebut benda)
  ///
  /// String kosong berarti **jangan kirim apa pun**: tidak ke penerjemah,
  /// tidak ke YOLOE.
  static String normalizeSearchPhrase(String raw) {
    var norm = _normalize(raw);
    if (norm.trim().isEmpty) return '';

    // 1. Kupas kata pembuka - "cari", "cariin dong", "ganti barang jadi".
    //
    //    Yang diambil adalah sisa kalimat SESUDAH kata pembuka, bukan
    //    kalimat yang kata pembukanya dihapus di tempat. Bedanya nyata pada
    //    ucapan koreksi: "bukan itu, cariin keyboard". Menghapus "cariin"
    //    saja menyisakan "bukan itu keyboard", dan "bukan" ikut berangkat ke
    //    penerjemah lalu jadi "not" di prompt YOLOE. Mengambil sisa
    //    sesudahnya menyisakan tepat "keyboard".
    //
    //    Berlapis karena satu kalimat bisa punya dua kata pembuka ("ganti,
    //    sekarang cari keyboard"), dan dibatasi supaya kalimat yang isinya
    //    HANYA kata pembuka berhenti sebagai kosong alih-alih berputar.
    final openers = <String>[...changeTargetPrefixes, ...searchPrefixes]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (var putaran = 0; putaran < 3; putaran++) {
      var terkupas = false;
      for (final prefix in openers) {
        final needle = ' ${_normalize(prefix).trim()} ';
        final idx = norm.indexOf(needle);
        if (idx < 0) continue;
        norm = _normalize(norm.substring(idx + needle.length - 1));
        terkupas = true;
        break;
      }
      if (!terkupas || norm.trim().isEmpty) break;
    }

    // 1b. Bentuk imbuhan yang tidak ada di daftar harfiah.
    final viaVerb = _afterSearchVerb(norm);
    if (viaVerb != null) norm = _normalize(viaVerb);

    // 2. Basa-basi percakapan dan derau frasa benda.
    for (final w in [..._sortedFillers, ..._searchNoiseWords]) {
      final needle = ' ${_normalize(w).trim()} ';
      while (norm.contains(needle)) {
        norm = norm.replaceAll(needle, ' ');
      }
    }

    var words = norm.split(' ').where((w) => w.isNotEmpty).toList();

    // 3. Potong di penanda keterangan tempat/waktu.
    //
    //    Penanda di posisi PERTAMA berarti tidak ada nama barang sebelumnya
    //    ("cari di meja"). Yang tersisa cuma keterangan tempat, dan
    //    menerjemahkannya membuat YOLOE mencari mejanya - bukan barang yang
    //    sebenarnya diminta, yang memang belum disebut.
    final cut = words.indexWhere(_phraseCutMarkers.contains);
    if (cut == 0) return '';
    if (cut > 0) words = words.sublist(0, cut);

    // 4. Buang kata yang tidak menunjuk benda apa pun.
    words = words.where((w) => !_nonObjectWords.contains(w)).toList();

    // 5. Batasi panjangnya.
    if (words.length > _maxPhraseWords) {
      words = words.sublist(0, _maxPhraseWords);
    }

    return words.join(' ');
  }

  /// Kata kerja "mencari" dalam segala imbuhannya.
  ///
  /// [searchPrefixes] adalah daftar frasa harfiah, dan daftar harfiah untuk
  /// bahasa yang berimbuhan seperti Bahasa Indonesia tidak akan pernah
  /// lengkap. Yang hilang darinya bukan kasus pinggiran: "mencari" - bentuk
  /// paling baku dari kata itu - pernah TIDAK ADA di sana, dan setiap kalimat
  /// yang memakainya berakhir di tebakan kemiripan kata yang menawarkan mode
  /// yang sama sekali berbeda.
  ///
  /// Pola ini jaring pengaman untuk bentuk yang belum terdaftar. Ia dicoba
  /// SESUDAH daftar harfiah, bukan menggantikannya: daftar itu tahu frasa
  /// panjang ("bantuin dong cariin") yang tidak bisa diungkapkan sebagai satu
  /// kata, dan pencocokan terpanjang di sana yang menjaga sisa kalimatnya
  /// tidak ikut terbawa.
  ///
  ///     cari · carikan · cariin · carilah · mencari · mencarikan · dicari
  ///     nyari · nyariin · menyari
  ///     temukan · temuin · menemukan · nemuin · ketemuin
  static final RegExp _searchVerb = RegExp(
    r'^(?:di|me|men|meng|nge|ke)?'
    r'(?:cari|ncari|nyari|temu|nemu)'
    r'(?:kan|in|i|lah|nya)?$',
  );

  /// Sisa kalimat sesudah kata kerja mencari, atau null kalau tidak ada.
  static String? _afterSearchVerb(String norm) {
    final words = norm.split(' ').where((w) => w.isNotEmpty).toList();
    final idx = words.indexWhere(_searchVerb.hasMatch);
    if (idx < 0 || idx == words.length - 1) return null;
    return words.sublist(idx + 1).join(' ');
  }

  static String? _extractSearchTarget(String norm) {
    final sortedPrefixes = List<String>.from(searchPrefixes)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final prefix in sortedPrefixes) {
      final needle = ' ${_normalize(prefix).trim()} ';
      final idx = norm.indexOf(needle);
      if (idx < 0) continue;

      var cleaned = norm.substring(idx + needle.length - 1).trim();
      if (cleaned.isEmpty) continue;

      for (final filler in _sortedFillers) {
        cleaned = cleaned.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ');
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned.isEmpty || cleaned == 'objek' || cleaned == 'barang') continue;
      return cleaned;
    }

    // Daftar harfiah tidak kenal bentuk imbuhannya - coba polanya.
    final viaVerb = _afterSearchVerb(norm);
    if (viaVerb == null) return null;

    var cleaned = viaVerb;
    for (final filler in _sortedFillers) {
      cleaned = cleaned.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty || cleaned == 'objek' || cleaned == 'barang') return null;
    return cleaned;
  }

  static List<String>? _sortedFillersCache;
  static List<String> get _sortedFillers => _sortedFillersCache ??=
      (List<String>.from(fillerWords)..sort((a, b) => b.length.compareTo(a.length)));

  // =========================================================================
  // [Fuzzy Matching Layer 3] - Word Overlap Similarity Scoring (Jaccard-like)
  // Calculates word intersection overlap between raw STT input and phrase database.
  // Returns top 2 nearest guesses for fallback voice prompts ("Saya dengar X. Maksudmu Y, atau Z?").
  // =========================================================================
  /// Intent yang boleh ditawarkan balik ke pengguna.
  ///
  /// **Hanya yang benar-benar punya handler.** Sebelumnya seluruh isi
  /// `_phrases` bisa disarankan, termasuk 10 intent tanpa handler - sehingga
  /// Vinara bisa bertanya "Maksudmu jeda?", pengguna menjawab "jeda", dan
  /// jawabannya "Perintah itu belum saya kenali di mode ini". Lingkaran buntu
  /// yang diciptakan aplikasi sendiri, dan pengguna tunanetra tidak punya
  /// layar untuk keluar darinya.
  ///
  /// Menambah intent ke sini tanpa menambahkan handler di
  /// `VoiceProvider._processText` akan menghidupkan lagi lingkaran itu.
  static const Set<VoiceIntent> suggestableIntents = {
    VoiceIntent.modeMoney,
    VoiceIntent.modeReadText,
    VoiceIntent.modeDetection,
    VoiceIntent.modeNavigation,
    VoiceIntent.modeAssistant,
    VoiceIntent.modeFindObject,
    VoiceIntent.modeSettings,
    VoiceIntent.actionGoBack,
    VoiceIntent.actionReplay,
    VoiceIntent.actionStopWalking,
    VoiceIntent.actionCapture,
    VoiceIntent.actionTorch,
    VoiceIntent.describeScene,
    VoiceIntent.playPause,
    VoiceIntent.playResume,
    VoiceIntent.playFaster,
    VoiceIntent.playSlower,
    VoiceIntent.playRepeatSection,
    VoiceIntent.helpWhat,
    VoiceIntent.helpWhereAmI,
  };

  static List<VoiceIntent> _nearestGuesses(String normalized) {
    final words = normalized.trim().split(' ').where((w) => w.isNotEmpty).toSet();
    if (words.isEmpty) return const [];

    final scored = <MapEntry<VoiceIntent, int>>[];

    for (final entry in _phrases.entries) {
      if (!suggestableIntents.contains(entry.key)) continue;
      var best = 0;
      for (final phrase in entry.value) {
        final phraseWords = _normalize(phrase).trim().split(' ').toSet();
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
/// uang, atau cari uang yang jatuh?" - bagian 14.
extension VoiceIntentSpokenLabel on VoiceIntent {
  String get spokenLabel => switch (this) {
        VoiceIntent.modeMoney => 'kenali uang',
        VoiceIntent.modeReadText => 'baca teks',
        VoiceIntent.modeDetection => 'deteksi objek',
        VoiceIntent.modeNavigation => 'navigasi',
        VoiceIntent.modeAssistant => 'deskripsi sekitar',
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
