/// Penerjemah kalimat deskripsi suasana Inggris ke Indonesia, **tanpa LLM**.
///
/// > **TIDAK DIPAKAI di jalur produksi.** `VoiceProvider._handleDescribeScene`
/// > sekarang membacakan caption Moondream2 apa adanya dalam Bahasa Inggris,
/// > didahului penanda "Dalam bahasa Inggris."
/// >
/// > Alasannya bukan kualitas kamusnya, melainkan konsistensinya: penerjemah
/// > ini menerjemahkan sebagian kalimat lalu menyerah pada sisanya, sehingga
/// > satu mode yang sama bisa menjawab dalam Bahasa Indonesia, Inggris, atau
/// > campuran keduanya tergantung foto. Untuk pengguna yang mengandalkan
/// > telinga, tebakan yang tidak konsisten lebih sulit diikuti daripada satu
/// > bahasa yang tetap.
/// >
/// > Berkasnya dan `test/scene_translator_test.dart` sengaja dipertahankan.
/// > Kalau nanti kamusnya diperluas sampai cakupannya konsisten, jalurnya
/// > tinggal disambung lagi di satu tempat.
///
/// Moondream2 mengeluarkan caption Bahasa Inggris ("A man standing in front of
/// a white building"). Selama ini kalimat itu dibacakan apa adanya dengan TTS
/// `en-US`, dan itu menuntut kemampuan Inggris lisan yang tidak bisa
/// diasumsikan pada target pengguna: tunanetra di pasar dan warung Indonesia.
///
/// Menambahkan LLM penerjemah akan melanggar prinsip yang sudah dipegang
/// proyek ini - lambat (1–3 detik), bisa berhalusinasi, dan butuh server.
/// Jadi pendekatannya sama persis dengan [generateNaturalNarration]: kamus
/// lokal + aturan urutan kata. 0 ms, offline, dan tidak pernah mengarang.
///
/// **Kalau tidak yakin, ia menyerah.** Caption yang cakupan kamusnya di bawah
/// [_minCoverage] mengembalikan null, dan pemanggil membacakan versi
/// Inggrisnya. Bahasa Indonesia yang kacau lebih buruk daripada Bahasa Inggris
/// yang benar - pengguna tidak punya layar untuk memverifikasi tebakan kita.
library;

/// Ambang cakupan kamus. Di bawah ini, hasilnya tidak layak diucapkan.
const double _minCoverage = 0.72;

/// Frasa banyak kata - dicocokkan lebih dulu, terpanjang menang.
const Map<String, String> _phrases = {
  'in front of': 'di depan',
  'next to': 'di sebelah',
  'close to': 'di dekat',
  'on top of': 'di atas',
  'in the middle of': 'di tengah',
  'to the left of': 'di sebelah kiri',
  'to the right of': 'di sebelah kanan',
  'a couple of': 'beberapa',
  'a lot of': 'banyak',
  'a group of': 'sekelompok',
  'a pair of': 'sepasang',
  'a close-up': 'gambar dekat',
  'close-up': 'gambar dekat',
  'there is': 'ada',
  'there are': 'ada',
  'is standing': 'sedang berdiri',
  'is sitting': 'sedang duduk',
  'is walking': 'sedang berjalan',
  'living room': 'ruang tamu',
  'dining room': 'ruang makan',
  'traffic light': 'lampu lalu lintas',
  'cell phone': 'ponsel',
  'potted plant': 'tanaman pot',
  'dining table': 'meja makan',
  'teddy bear': 'boneka beruang',
  'city street': 'jalan kota',
  'parking lot': 'tempat parkir',
  'sidewalk': 'trotoar',
  'wine glass': 'gelas anggur',
  'cup of coffee': 'cangkir kopi',
  'cup of tea': 'cangkir teh',
  'each other': 'satu sama lain',
};

/// Kata yang dibuang: Bahasa Indonesia tidak memakai artikel, dan kopula
/// "is/are" umumnya tidak diterjemahkan.
const Set<String> _dropped = {
  'a', 'an', 'the', 'is', 'are', 'that', 'which', 'it', 'its', 'be', 'being',
};

/// Kata sifat - di Bahasa Indonesia posisinya SESUDAH kata benda.
const Map<String, String> _adjectives = {
  'white': 'putih', 'black': 'hitam', 'red': 'merah', 'blue': 'biru',
  'green': 'hijau', 'yellow': 'kuning', 'brown': 'cokelat', 'gray': 'abu-abu',
  'grey': 'abu-abu', 'orange': 'oranye', 'purple': 'ungu', 'pink': 'merah muda',
  'dark': 'gelap', 'bright': 'terang', 'light': 'terang',
  'large': 'besar', 'big': 'besar', 'small': 'kecil', 'tiny': 'mungil',
  'long': 'panjang', 'short': 'pendek', 'tall': 'tinggi', 'wide': 'lebar',
  'old': 'tua', 'young': 'muda', 'new': 'baru',
  'wooden': 'kayu', 'metal': 'logam', 'plastic': 'plastik', 'glass': 'kaca',
  'empty': 'kosong', 'full': 'penuh', 'open': 'terbuka', 'closed': 'tertutup',
  'busy': 'ramai', 'quiet': 'sepi', 'clean': 'bersih', 'dirty': 'kotor',
  'wet': 'basah', 'dry': 'kering', 'narrow': 'sempit', 'crowded': 'padat',
};

/// Kata benda, kata kerja, preposisi, angka.
const Map<String, String> _words = {
  // Orang
  'man': 'seorang pria', 'woman': 'seorang wanita', 'men': 'beberapa pria',
  'women': 'beberapa wanita', 'person': 'seseorang', 'people': 'orang-orang',
  'boy': 'anak laki-laki', 'girl': 'anak perempuan', 'child': 'seorang anak',
  'children': 'anak-anak', 'crowd': 'kerumunan',

  // Tempat & bangunan
  'building': 'gedung', 'buildings': 'gedung-gedung', 'house': 'rumah',
  'wall': 'dinding', 'door': 'pintu', 'window': 'jendela', 'floor': 'lantai',
  'ceiling': 'langit-langit', 'room': 'ruangan', 'kitchen': 'dapur',
  'street': 'jalan', 'road': 'jalan', 'path': 'jalur', 'stairs': 'tangga',
  'shop': 'toko', 'store': 'toko', 'market': 'pasar', 'restaurant': 'restoran',
  'office': 'kantor', 'park': 'taman', 'garden': 'kebun', 'bridge': 'jembatan',
  'sky': 'langit', 'ground': 'tanah', 'grass': 'rumput', 'tree': 'pohon',
  'trees': 'pepohonan', 'sign': 'papan tanda', 'fence': 'pagar',

  // Perabot & benda
  'table': 'meja', 'chair': 'kursi', 'chairs': 'kursi', 'desk': 'meja',
  'bed': 'tempat tidur', 'couch': 'sofa', 'sofa': 'sofa', 'shelf': 'rak',
  'laptop': 'laptop', 'computer': 'komputer', 'phone': 'ponsel',
  'keyboard': 'papan ketik', 'screen': 'layar', 'monitor': 'monitor',
  'book': 'buku', 'books': 'buku-buku', 'paper': 'kertas', 'bag': 'tas',
  'backpack': 'tas ransel', 'box': 'kotak', 'bottle': 'botol',
  'cup': 'cangkir', 'glass': 'gelas', 'plate': 'piring', 'bowl': 'mangkuk',
  'food': 'makanan', 'coffee': 'kopi', 'tea': 'teh', 'water': 'air',
  'clock': 'jam', 'lamp': 'lampu', 'light': 'lampu', 'picture': 'gambar',
  'mirror': 'cermin', 'curtain': 'tirai', 'carpet': 'karpet', 'rug': 'karpet',
  'basket': 'keranjang', 'umbrella': 'payung', 'hat': 'topi', 'shirt': 'baju',
  'money': 'uang', 'wallet': 'dompet', 'key': 'kunci', 'keys': 'kunci',
  'glasses': 'kacamata', 'watch': 'jam tangan', 'camera': 'kamera',

  // Kendaraan
  'car': 'mobil', 'cars': 'mobil-mobil', 'bus': 'bus', 'truck': 'truk',
  'motorcycle': 'motor', 'bicycle': 'sepeda', 'bike': 'sepeda',
  'train': 'kereta', 'boat': 'perahu', 'vehicle': 'kendaraan',

  // Hewan
  'dog': 'anjing', 'cat': 'kucing', 'bird': 'burung', 'animal': 'hewan',

  // Kata kerja (bentuk -ing)
  'standing': 'berdiri', 'sitting': 'duduk', 'walking': 'berjalan',
  'running': 'berlari', 'holding': 'memegang', 'wearing': 'memakai',
  'looking': 'melihat', 'talking': 'berbicara', 'eating': 'makan',
  'drinking': 'minum', 'reading': 'membaca', 'working': 'bekerja',
  'lying': 'tergeletak', 'hanging': 'tergantung', 'parked': 'terparkir',
  'placed': 'diletakkan', 'sitting_on': 'duduk di',
  'facing': 'menghadap', 'crossing': 'menyeberang', 'waiting': 'menunggu',

  // Preposisi & penghubung
  'on': 'di atas', 'in': 'di dalam', 'at': 'di', 'near': 'di dekat',
  'behind': 'di belakang', 'under': 'di bawah', 'above': 'di atas',
  'beside': 'di samping', 'between': 'di antara', 'with': 'dengan',
  'and': 'dan', 'or': 'atau', 'of': 'dari', 'from': 'dari', 'to': 'ke',
  'over': 'di atas', 'across': 'di seberang', 'down': 'menyusuri',
  'while': 'sambil', 'front': 'depan', 'side': 'sisi', 'top': 'atas',

  // Angka & kuantitas
  'one': 'satu', 'two': 'dua', 'three': 'tiga', 'four': 'empat',
  'five': 'lima', 'six': 'enam', 'seven': 'tujuh', 'eight': 'delapan',
  'nine': 'sembilan', 'ten': 'sepuluh',
  'some': 'beberapa', 'several': 'beberapa', 'many': 'banyak',
  'few': 'sedikit', 'other': 'lain', 'another': 'satu lagi',
  'his': 'nya', 'her': 'nya', 'their': 'mereka', 'this': 'ini', 'these': 'ini',
};

/// Hasil penerjemahan.
class SceneTranslation {
  /// Kalimat Bahasa Indonesia, atau null kalau cakupan kamus terlalu rendah.
  final String? indonesian;

  /// Berapa bagian kata isi yang berhasil dikenali (0..1). Untuk diagnostik.
  final double coverage;

  const SceneTranslation({required this.indonesian, required this.coverage});

  bool get isUsable => indonesian != null;
}

/// Terjemahkan caption suasana. Mengembalikan [SceneTranslation.indonesian]
/// null kalau hasilnya tidak layak diucapkan.
SceneTranslation translateSceneCaption(String englishCaption) {
  var text = englishCaption.toLowerCase().trim();
  if (text.isEmpty) return const SceneTranslation(indonesian: null, coverage: 0);

  // Buang tanda baca akhir & normalisasi spasi.
  text = text.replaceAll(RegExp(r'[.!?]+$'), '');
  text = text.replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Frasa multi-kata lebih dulu - ditandai dengan token khusus supaya tidak
  // ikut dipecah tahap berikutnya.
  final placeholders = <String, String>{};
  final sortedPhrases = _phrases.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  var i = 0;
  for (final phrase in sortedPhrases) {
    if (!text.contains(phrase)) continue;
    final token = ' ${i++} ';
    placeholders[token] = _phrases[phrase]!;
    text = text.replaceAll(phrase, token);
  }

  final tokens = text.split(' ').where((t) => t.isNotEmpty).toList();
  final out = <String>[];
  var contentWords = 0;
  var known = 0;

  for (var t = 0; t < tokens.length; t++) {
    final token = tokens[t];

    if (placeholders.containsKey(token)) {
      out.add(placeholders[token]!);
      contentWords++;
      known++;
      continue;
    }

    if (_dropped.contains(token)) continue;

    contentWords++;

    // Kata sifat + kata benda → urutannya dibalik: "white building" jadi
    // "gedung putih". Ini satu-satunya aturan tata bahasa yang benar-benar
    // dibutuhkan; sisanya sudah cukup dekat kalau diterjemahkan urut.
    if (_adjectives.containsKey(token)) {
      final next = t + 1 < tokens.length ? tokens[t + 1] : null;
      if (next != null && _words.containsKey(next)) {
        out.add('${_words[next]} ${_adjectives[token]}');
        known += 2;
        contentWords++; // kata benda ikut dihitung
        t++; // lewati kata benda yang sudah dipakai
        continue;
      }
      out.add(_adjectives[token]!);
      known++;
      continue;
    }

    final word = _words[token];
    if (word != null) {
      out.add(word);
      known++;
      continue;
    }

    // Angka tetap angka.
    if (RegExp(r'^\d+$').hasMatch(token)) {
      out.add(token);
      known++;
      continue;
    }

    // Tidak dikenal - pertahankan apa adanya, tapi hitung sebagai tidak
    // tercakup supaya ambang cakupan bisa menolak kalimat yang terlalu asing.
    out.add(token);
  }

  final coverage = contentWords == 0 ? 0.0 : known / contentWords;
  if (coverage < _minCoverage || out.isEmpty) {
    return SceneTranslation(indonesian: null, coverage: coverage);
  }

  var sentence = out.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  sentence = sentence[0].toUpperCase() + sentence.substring(1);
  return SceneTranslation(indonesian: '$sentence.', coverage: coverage);
}
