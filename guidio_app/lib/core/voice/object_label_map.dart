/// Peta label Indonesia → kelas COCO 80 dan tinggi fisik objek (cm).
///
/// Di-port dari `backend/services/find_object_constants.py`.
/// Dipakai [FindObjectOnnxService] untuk memfilter hasil inferensi YOLOE
/// berdasarkan target yang diucapkan pengguna.
library object_label_map;

// ─────────────────────────────────────────────────────────────────────────────
// COCO 80 class names (index 0..79)
// ─────────────────────────────────────────────────────────────────────────────

const List<String> cocoLabels = [
  'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train',
  'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign',
  'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
  'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag',
  'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite',
  'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
  'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana',
  'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza',
  'donut', 'cake', 'chair', 'couch', 'potted plant', 'bed', 'dining table',
  'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone',
  'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock',
  'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush',
];

// ─────────────────────────────────────────────────────────────────────────────
// Indonesian label → COCO class indices
// Beberapa kata Indonesia bisa cocok ke beberapa kelas COCO sekaligus,
// misalnya "tas" = backpack + handbag + suitcase.
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<int>> idToCocoIndices = {
  // Orang
  'orang': [0], 'manusia': [0],

  // Kendaraan
  'sepeda': [1],
  'mobil': [2],
  'motor': [3], 'sepeda motor': [3],
  'bus': [5],
  'kereta': [6],
  'truk': [7],
  'kapal': [8],

  // Furnitur & infrastruktur
  'bangku': [13], 'kursi taman': [13],
  'kursi': [56],
  'sofa': [57], 'kasur sofa': [57],
  'kasur': [59], 'ranjang': [59], 'tempat tidur': [59],
  'meja': [60], 'meja makan': [60],

  // Tas
  'tas ransel': [24], 'ransel': [24],
  'tas tangan': [26], 'tas selempang': [26], 'dompet besar': [26],
  'koper': [28],
  'tas': [24, 26, 28], // backpack + handbag + suitcase

  // Aksesori
  'payung': [25],
  'dasi': [27],

  // Olahraga / outdoor
  'skateboard': [36],
  'raket': [38], 'raket tenis': [38],
  'bola': [32],

  // Makanan & minuman
  'botol': [39], 'botol minum': [39], 'botol air': [39],
  'gelas': [41], 'cangkir': [41], 'mug': [41],
  'garpu': [42],
  'pisau': [43], 'pisau dapur': [43],
  'sendok': [44],
  'mangkuk': [45],
  'pisang': [46],
  'apel': [47],
  'jeruk': [49],
  'wortel': [51],

  // Elektronik
  'tv': [62], 'televisi': [62],
  'laptop': [63],
  'mouse': [64],
  'remote': [65], 'remot': [65], 'remote tv': [65],
  'keyboard': [66],
  'hp': [67], 'handphone': [67], 'ponsel': [67], 'smartphone': [67], 'gawai': [67],
  'microwave': [68],
  'oven': [69],
  'kulkas': [72], 'lemari es': [72],

  // Alat tulis & kantor
  'buku': [73],
  'gunting': [76],
  'sikat gigi': [79],
  'jam': [74], 'jam dinding': [74], 'jam tangan': [74],

  // Tanaman
  'tanaman': [58], 'pot bunga': [58],

  // Barang lain yang tidak ada di COCO → mapping terdekat
  'dompet': [26],       // handbag sebagai fallback
  'kacamata': [79],     // fallback ke toothbrush (keduanya kecil, bisa jadi FN)
  'helm': [24],         // fallback ke backpack
  'topi': [24],         // fallback
};

// ─────────────────────────────────────────────────────────────────────────────
// Tinggi fisik objek (cm) — untuk estimasi jarak via similar-triangle
// Key = nama kelas COCO (cocoLabels[i])
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, double> cocoHeightsCm = {
  'person': 170,
  'bicycle': 100,
  'car': 150,
  'motorcycle': 110,
  'bus': 300,
  'train': 350,
  'truck': 300,
  'boat': 120,
  'bench': 80,
  'backpack': 45,
  'umbrella': 90,
  'handbag': 25,
  'suitcase': 60,
  'sports ball': 22,
  'skateboard': 12,
  'tennis racket': 68,
  'bottle': 25,
  'wine glass': 20,
  'cup': 9,
  'fork': 18,
  'knife': 20,
  'spoon': 15,
  'bowl': 10,
  'banana': 18,
  'apple': 8,
  'orange': 7,
  'carrot': 18,
  'chair': 90,
  'couch': 80,
  'potted plant': 40,
  'bed': 50,
  'dining table': 75,
  'toilet': 80,
  'tv': 60,
  'laptop': 25,
  'mouse': 4,
  'remote': 18,
  'keyboard': 4,
  'cell phone': 15,
  'microwave': 30,
  'oven': 35,
  'refrigerator': 170,
  'book': 25,
  'clock': 25,
  'scissors': 18,
  'teddy bear': 30,
  'hair drier': 22,
  'toothbrush': 18,
};

const double _defaultHeightCm = 25.0;
const double _focalLengthPx = 615.0;  // approx for standard camera

/// Estimasi jarak (meter) dari bounding box height dalam piksel frame (640px tinggi).
double estimateDistance(double bboxHeightPx, String cocoLabel) {
  final heightCm = cocoHeightsCm[cocoLabel] ?? _defaultHeightCm;
  if (bboxHeightPx <= 0) return 3.0;
  return (_focalLengthPx * heightCm) / (bboxHeightPx * 100.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Warna — nama Indonesia → HSV range untuk color filter
// (H: 0..179, S: 0..255, V: 0..255 — skala OpenCV/standar)
// ─────────────────────────────────────────────────────────────────────────────

class HsvRange {
  final int hMin, hMax, sMin, vMin;
  final bool wrapHue; // true untuk merah yang wrap di 0/179
  const HsvRange(this.hMin, this.hMax, this.sMin, this.vMin, {this.wrapHue = false});
}

const Map<String, HsvRange> colorRanges = {
  'merah':  HsvRange(0, 10, 100, 50, wrapHue: true),   // juga 170..179
  'oranye': HsvRange(10, 25, 100, 50),
  'kuning': HsvRange(25, 35, 100, 50),
  'hijau':  HsvRange(35, 85, 80,  50),
  'biru':   HsvRange(100, 130, 80, 50),
  'ungu':   HsvRange(130, 160, 80, 50),
  'pink':   HsvRange(160, 175, 50, 100),
  'hitam':  HsvRange(0,   179, 0,  0),   // V < 50 dicheck terpisah
  'putih':  HsvRange(0,   179, 0,  200), // S < 30 dicheck terpisah
  'abu':    HsvRange(0,   179, 0,  50),  // S < 50, V in [50,200]
  'cokelat':HsvRange(10,  20,  50, 50),
};

/// Cek apakah warna yang disebutkan ada dalam pixel sampel (List<int> R,G,B).
/// Mengembalikan true jika tidak ada color constraint (warnanya null/kosong).
bool checkColorMatch(String? requestedColorId, List<List<int>> rgbSamples) {
  if (requestedColorId == null || requestedColorId.isEmpty) return true;

  final range = colorRanges[requestedColorId];
  if (range == null) return true; // warna tak dikenal = tidak filter

  int matchCount = 0;
  for (final rgb in rgbSamples) {
    if (_pixelMatchesColor(rgb[0], rgb[1], rgb[2], requestedColorId, range)) {
      matchCount++;
    }
  }
  return matchCount >= (rgbSamples.length * 0.25).ceil(); // min 25% pixel cocok
}

bool _pixelMatchesColor(int r, int g, int b, String colorId, HsvRange range) {
  final hsv = _rgbToHsv(r, g, b);
  final h = hsv[0], s = hsv[1], v = hsv[2];

  if (colorId == 'hitam') return v < 50;
  if (colorId == 'putih') return s < 30 && v > 200;
  if (colorId == 'abu') return s < 50 && v >= 50 && v <= 200;

  final hMatch = range.wrapHue
      ? (h <= range.hMax || h >= 170)
      : (h >= range.hMin && h <= range.hMax);
  return hMatch && s >= range.sMin && v >= range.vMin;
}

// Konversi RGB [0..255] → HSV [H:0..179, S:0..255, V:0..255]
List<int> _rgbToHsv(int r, int g, int b) {
  final rf = r / 255.0, gf = g / 255.0, bf = b / 255.0;
  final maxC = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
  final minC = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
  final delta = maxC - minC;

  double h = 0;
  if (delta > 0) {
    if (maxC == rf) {
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (maxC == gf) {
      h = 60 * ((bf - rf) / delta + 2);
    } else {
      h = 60 * ((rf - gf) / delta + 4);
    }
    if (h < 0) h += 360;
  }
  final s = maxC == 0 ? 0.0 : delta / maxC;
  return [
    (h / 2).round(),          // H: 0..179
    (s * 255).round(),        // S: 0..255
    (maxC * 255).round(),     // V: 0..255
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse query bahasa Indonesia → (objectKey, colorKey?)
// ─────────────────────────────────────────────────────────────────────────────

/// Pisahkan query seperti "tas merah" → ('tas', 'merah')
/// atau "botol" → ('botol', null).
(String object, String? color) parseQuery(String query) {
  final q = query.toLowerCase().trim();

  // Coba cocokkan warna di akhir string
  for (final colorId in colorRanges.keys) {
    if (q.endsWith(' $colorId')) {
      final obj = q.substring(0, q.length - colorId.length - 1).trim();
      return (obj, colorId);
    }
  }
  // Coba cari kata warna di mana saja
  for (final colorId in colorRanges.keys) {
    if (q.contains(colorId)) {
      final obj = q.replaceAll(colorId, '').trim();
      return (obj.isEmpty ? q : obj, colorId);
    }
  }
  return (q, null);
}

/// Cari COCO class indices untuk nama objek Indonesia.
/// Coba exact match dulu, lalu partial match.
List<int> resolveClassIndices(String objectKey) {
  final key = objectKey.toLowerCase().trim();
  if (idToCocoIndices.containsKey(key)) return idToCocoIndices[key]!;

  // Partial match — misal "tas ransel hitam" → "tas ransel"
  for (final entry in idToCocoIndices.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) return entry.value;
  }
  return [];
}
