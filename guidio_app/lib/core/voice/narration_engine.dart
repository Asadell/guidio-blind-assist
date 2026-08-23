import 'dart:math';

/// Narration Engine - Merangkai hasil deteksi YOLO menjadi narasi Bahasa Indonesia
/// yang alami untuk dibacakan TTS. 100% offline, tanpa LLM.
///
/// Menggantikan POST /api/narasi yang sebelumnya bergantung pada Qwen LLM di backend.
///
/// Sumber: guidio_bank_kata_dan_narasi_engine.md (Tugas 2)

// ── Kamus Objek COCO-80 ────────────────────────────────────────────────────

/// Info nama dan kata kerja konteks untuk setiap kelas objek COCO.
class ObjectInfo {
  final String nameId;     // nama umum Bahasa Indonesia
  final String actionVerb; // kata kerja/predikat natural untuk objek ini
  const ObjectInfo(this.nameId, this.actionVerb);
}

/// Kamus 80 kelas objek COCO: nama alami Bahasa Indonesia + kata kerja konteks.
const Map<String, ObjectInfo> cocoObjectDictionary = {
  'person':          ObjectInfo('orang', 'berjalan'),
  'bicycle':         ObjectInfo('sepeda', 'terparkir'),
  'car':             ObjectInfo('mobil', 'terparkir'),
  'motorcycle':      ObjectInfo('motor', 'terparkir'),
  'airplane':        ObjectInfo('pesawat', 'terlihat'),
  'bus':             ObjectInfo('bus', 'melintas'),
  'train':           ObjectInfo('kereta', 'melintas'),
  'truck':           ObjectInfo('truk', 'terparkir'),
  'boat':            ObjectInfo('perahu', 'bersandar'),
  'traffic light':   ObjectInfo('lampu lalu lintas', 'menyala'),
  'fire hydrant':    ObjectInfo('hidran', 'berdiri'),
  'stop sign':       ObjectInfo('rambu stop', 'terpasang'),
  'parking meter':   ObjectInfo('meteran parkir', 'terpasang'),
  'bench':           ObjectInfo('bangku', 'diletakkan'),
  'bird':            ObjectInfo('burung', 'hinggap'),
  'cat':             ObjectInfo('kucing', 'duduk'),
  'dog':             ObjectInfo('anjing', 'duduk'),
  'horse':           ObjectInfo('kuda', 'berdiri'),
  'sheep':           ObjectInfo('domba', 'berdiri'),
  'cow':             ObjectInfo('sapi', 'berdiri'),
  'elephant':        ObjectInfo('gajah', 'berdiri'),
  'bear':            ObjectInfo('beruang', 'berdiri'),
  'zebra':           ObjectInfo('zebra', 'berdiri'),
  'giraffe':         ObjectInfo('jerapah', 'berdiri'),
  'backpack':        ObjectInfo('tas ransel', 'diletakkan'),
  'umbrella':        ObjectInfo('payung', 'diletakkan'),
  'handbag':         ObjectInfo('tas tangan', 'diletakkan'),
  'tie':             ObjectInfo('dasi', 'tergantung'),
  'suitcase':        ObjectInfo('koper', 'diletakkan'),
  'frisbee':         ObjectInfo('piringan frisbee', 'tergeletak'),
  'skis':            ObjectInfo('papan ski', 'disandarkan'),
  'snowboard':       ObjectInfo('papan salju', 'disandarkan'),
  'sports ball':     ObjectInfo('bola', 'tergeletak'),
  'kite':            ObjectInfo('layang-layang', 'terbang'),
  'baseball bat':    ObjectInfo('pemukul bisbol', 'tergeletak'),
  'baseball glove':  ObjectInfo('sarung tangan bisbol', 'tergeletak'),
  'skateboard':      ObjectInfo('papan skateboard', 'tergeletak'),
  'surfboard':       ObjectInfo('papan selancar', 'disandarkan'),
  'tennis racket':   ObjectInfo('raket tenis', 'tergeletak'),
  'bottle':          ObjectInfo('botol', 'diletakkan'),
  'wine glass':      ObjectInfo('gelas anggur', 'diletakkan'),
  'cup':             ObjectInfo('gelas', 'diletakkan'),
  'fork':            ObjectInfo('garpu', 'diletakkan'),
  'knife':           ObjectInfo('pisau', 'diletakkan'),
  'spoon':           ObjectInfo('sendok', 'diletakkan'),
  'bowl':            ObjectInfo('mangkuk', 'diletakkan'),
  'banana':          ObjectInfo('pisang', 'diletakkan'),
  'apple':           ObjectInfo('apel', 'diletakkan'),
  'sandwich':        ObjectInfo('roti lapis', 'diletakkan'),
  'orange':          ObjectInfo('jeruk', 'diletakkan'),
  'broccoli':        ObjectInfo('brokoli', 'diletakkan'),
  'carrot':          ObjectInfo('wortel', 'diletakkan'),
  'hot dog':         ObjectInfo('hot dog', 'diletakkan'),
  'pizza':           ObjectInfo('pizza', 'diletakkan'),
  'donut':           ObjectInfo('donat', 'diletakkan'),
  'cake':            ObjectInfo('kue', 'diletakkan'),
  'chair':           ObjectInfo('kursi', 'disediakan'),
  'couch':           ObjectInfo('sofa', 'disediakan'),
  'potted plant':    ObjectInfo('tanaman pot', 'diletakkan'),
  'bed':             ObjectInfo('tempat tidur', 'disediakan'),
  'dining table':    ObjectInfo('meja makan', 'disediakan'),
  'toilet':          ObjectInfo('toilet', 'berada'),
  'tv':              ObjectInfo('televisi', 'menyala'),
  'laptop':          ObjectInfo('laptop', 'diletakkan'),
  'mouse':           ObjectInfo('mouse komputer', 'diletakkan'),
  'remote':          ObjectInfo('remote', 'diletakkan'),
  'keyboard':        ObjectInfo('keyboard', 'diletakkan'),
  'cell phone':      ObjectInfo('ponsel', 'diletakkan'),
  'microwave':       ObjectInfo('microwave', 'terpasang'),
  'oven':            ObjectInfo('oven', 'terpasang'),
  'toaster':         ObjectInfo('pemanggang roti', 'terpasang'),
  'sink':            ObjectInfo('wastafel', 'terpasang'),
  'refrigerator':    ObjectInfo('kulkas', 'berdiri'),
  'book':            ObjectInfo('buku', 'diletakkan'),
  'clock':           ObjectInfo('jam dinding', 'tergantung'),
  'vase':            ObjectInfo('vas bunga', 'diletakkan'),
  'scissors':        ObjectInfo('gunting', 'diletakkan'),
  'teddy bear':      ObjectInfo('boneka beruang', 'diletakkan'),
  'hair drier':      ObjectInfo('pengering rambut', 'diletakkan'),
  'toothbrush':      ObjectInfo('sikat gigi', 'diletakkan'),
};

// ── Mapper Jarak & Arah ────────────────────────────────────────────────────

/// Mengubah jarak numerik (meter) menjadi frasa jarak yang natural.
String mapDistancePhrase(double distanceMeter) {
  if (distanceMeter < 1.0) {
    // Variasi frasa jarak sangat dekat, dipilih acak agar tidak monoton
    final phrases = [
      'sangat dekat di depanmu',
      'di dekat langkahmu',
      'tepat di jangkauanmu',
    ];
    return phrases[(distanceMeter * 100).toInt() % phrases.length];
  } else if (distanceMeter <= 3.0) {
    return 'sekitar ${_formatMeter(distanceMeter)} meter';
  } else {
    return 'agak jauh sekitar ${_formatMeter(distanceMeter)} meter';
  }
}

/// Mengubah angka desimal jarak menjadi teks natural
/// (contoh: 1.5 → "satu setengah", 3.0 → "tiga").
String _formatMeter(double meter) {
  final intPart = meter.floor();
  final decimalPart = meter - intPart;

  const satuan = [
    'nol', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
  ];

  final intWord = (intPart >= 0 && intPart < satuan.length)
      ? satuan[intPart]
      : intPart.toString();

  if (decimalPart >= 0.4 && decimalPart <= 0.6) {
    return '$intWord setengah';
  }
  return intWord;
}

/// Mengubah kode arah menjadi frasa posisi natural.
String mapDirectionPhrase(String direction) {
  switch (direction.toLowerCase()) {
    case 'kiri':
      return 'di sebelah kirimu';
    case 'kanan':
      return 'di sebelah kananmu';
    case 'tengah':
    default:
      return 'tepat di depanmu';
  }
}

// ── Sentence Builder ───────────────────────────────────────────────────────

/// Data deteksi satu objek untuk narasi engine.
/// Berbeda dari model [Detection] utama - ini versi ringan khusus narasi.
class NarrationDetection {
  final String objectClass; // key dari cocoObjectDictionary, mis. "car"
  final double dist;        // jarak dalam meter
  final String dir;         // "kiri" | "tengah" | "kanan"
  final int count;          // jumlah objek sejenis pada kelompok yang sama

  const NarrationDetection({
    required this.objectClass,
    required this.dist,
    required this.dir,
    this.count = 1,
  });
}

final _random = Random();

/// Merangkai daftar deteksi objek mentah menjadi satu kalimat narasi
/// Bahasa Indonesia yang alami untuk dibacakan TTS - 100% tanpa LLM.
///
/// Menggantikan POST /api/narasi (backend Qwen).
///
/// Contoh output:
/// "Di sekitarmu, ada dua orang di sebelah kirimu sejauh satu setengah meter,
///  serta sebuah mobil di sebelah kananmu sejauh agak jauh sekitar tiga meter."
String generateNaturalNarration(List<NarrationDetection> detections) {
  if (detections.isEmpty) {
    return 'Tidak ada objek yang terdeteksi di sekitarmu saat ini.';
  }

  // Urutkan dari yang paling dekat - objek paling berbahaya disebut lebih dulu
  final sorted = [...detections]..sort((a, b) => a.dist.compareTo(b.dist));

  // Batasi maksimal 3 objek utama supaya kalimat tidak terlalu panjang
  final mainObjects = sorted.take(3).toList();

  const connectorsFirst = [
    'Di sekitarmu, ada',
    'Di depanmu terdapat',
    'Saat ini terdeteksi',
  ];
  const connectorsMiddle = [
    'sementara di sana ada',
    'lalu terdapat',
    'kemudian ada',
  ];
  const connectorsLast = ['serta', 'dan juga', 'ditambah'];

  final buffer = StringBuffer();
  buffer.write('${connectorsFirst[_random.nextInt(connectorsFirst.length)]} ');

  var writtenCount = 0;
  for (var i = 0; i < mainObjects.length; i++) {
    final det = mainObjects[i];
    final info = cocoObjectDictionary[det.objectClass];

    if (info == null) continue; // lewati kelas yang tidak dikenal

    final countPhrase = _countToWords(det.count, info.nameId);
    final distPhrase  = mapDistancePhrase(det.dist);
    final dirPhrase   = mapDirectionPhrase(det.dir);
    final clause      = '$countPhrase $dirPhrase sejauh $distPhrase';

    if (writtenCount == 0) {
      buffer.write(clause);
    } else if (i == mainObjects.length - 1) {
      buffer.write(
        ', ${connectorsLast[_random.nextInt(connectorsLast.length)]} $clause',
      );
    } else {
      buffer.write(
        ', ${connectorsMiddle[_random.nextInt(connectorsMiddle.length)]} $clause',
      );
    }
    writtenCount++;
  }

  if (writtenCount == 0) {
    return 'Area sekitar tampak aman.';
  }

  buffer.write('.');
  return buffer.toString();
}

/// Mengubah jumlah objek menjadi frasa natural, termasuk pluralisasi sederhana
/// khas Bahasa Indonesia (mis. "dua orang", "sebuah botol").
String _countToWords(int count, String nameId) {
  const angka = [
    '', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
  ];

  if (count <= 1) {
    if (nameId == 'orang') return nameId;
    return 'sebuah $nameId';
  }

  final numberWord = (count < angka.length) ? angka[count] : count.toString();
  return '$numberWord $nameId';
}

/// Lookup nama Indonesia dari label YOLO/model (fallback ke label asli).
/// Berguna untuk format cepat tanpa narasi penuh.
String labelToIndonesian(String label) {
  return cocoObjectDictionary[label]?.nameId ?? label;
}
