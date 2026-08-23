/// Penggabung rintangan Mode Navigasi dari dua detektor yang berbeda watak.
///
/// ## Kenapa ada dua detektor, bukan satu
///
/// `YoloNavigasiService` dilatih khusus untuk enam kelas bahaya jalanan
/// Indonesia (lubang, got terbuka, tangga, orang, motor, tiang). Itu satu
/// satunya sumber untuk `lubang`, `got_terbuka`, dan `tangga`: tidak ada
/// padanannya di COCO, dan justru ketiganya yang paling berbahaya bagi
/// pengguna tunanetra karena tidak bisa dirasakan tongkat sampai sudah dekat.
///
/// Tapi model itu terbukti lemah pada kelas yang justru berlimpah di dataset
/// umum. Diuji lewat `test/run_corridor_test.py` pada fixture
/// `04_motor_dan_orang.png` - dua motor terparkir dan satu orang berjalan,
/// semuanya jelas terlihat mata - model custom melaporkan NOL motor dan NOL
/// orang, lalu mengeluarkan satu kotak `lubang` di atas paving kosong.
///
/// SSD MobileNet COCO tidak akan pernah tahu apa itu got terbuka, tapi
/// `person` dan `motorcycle` adalah dua kelas yang paling banyak contohnya di
/// seluruh COCO. Menggabungkan keduanya bukan menumpuk model demi menumpuk:
/// masing-masing menutup lubang yang tidak bisa ditutup yang lain.
///
/// ## Kenapa TIDAK semua 80 kelas COCO ikut
///
/// Mode Navigasi berjalan sekitar dua kali per detik sambil pengguna melangkah,
/// dan tiap deteksi berpotensi jadi ucapan yang memotong arahan jalur. Menyebut
/// "botol", "kursi makan", atau "ponsel" di tengah menyeberang bukan cuma
/// tidak berguna, ia menunda kalimat yang benar-benar menyangkut keselamatan.
///
/// Yang lolos hanya benda yang bisa **menghalangi atau membahayakan langkah**.
library;

import 'dart:math';

import '../models/detection.dart';

/// Kelas COCO yang relevan untuk berjalan, beserta padanan kelas navigasinya.
///
/// Nilai `null` berarti benda itu tidak punya padanan di model custom, jadi
/// tidak pernah dianggap kembar dan selalu dipertahankan.
const Map<String, String?> kCocoNavRelevant = {
  // Bergerak dan bisa menabrak. Inilah yang paling sering luput di model custom.
  'person': 'orang',
  'motorcycle': 'motor',
  'bicycle': null,
  'car': null,
  'bus': null,
  'truck': null,

  // Hewan besar yang lazim di jalan dan trotoar Indonesia.
  'dog': null,

  // Perabot jalan dan tiang. Model custom punya kelas `tiang`, jadi keempatnya
  // dianggap kembar dengannya kalau kotaknya bertindih.
  'traffic light': 'tiang',
  'fire hydrant': 'tiang',
  'stop sign': 'tiang',
  'parking meter': 'tiang',

  // Penghalang statis di trotoar: bangku taman, kursi dan meja warung, pot
  // tanaman besar. Semuanya benda yang membuat pengguna harus memutar.
  'bench': null,
  'chair': null,
  'dining table': null,
  'potted plant': null,
};

/// Ambang tindih untuk menganggap dua kotak menunjuk benda yang sama.
const double _dupIou = 0.45;

/// Saring keluaran SSD MobileNet COCO menjadi hanya yang menyangkut langkah.
List<Detection> filterCocoForNavigation(List<Detection> cocoDetections) =>
    cocoDetections
        .where((d) => kCocoNavRelevant.containsKey(d.labelEn))
        .toList();

/// Gabungkan rintangan dari model custom dan dari COCO.
///
/// Hasil model custom selalu menang saat keduanya menunjuk benda yang sama.
/// Bukan karena ia lebih akurat - bukti di atas menunjukkan sebaliknya untuk
/// orang dan motor - melainkan karena jarak dan tingkat bahayanya dihitung
/// dengan tinggi acuan yang disetel untuk konteks jalanan, dan mengganti
/// sumbernya di tengah jalan akan membuat angka jarak melompat antar frame
/// untuk benda yang tidak bergerak.
///
/// Yang ditambahkan COCO adalah benda yang **tidak terlihat sama sekali** oleh
/// model custom, dan itulah seluruh gunanya lapisan ini.
List<Detection> mergeNavObstacles(
  List<Detection> custom,
  List<Detection> coco,
) {
  final relevant = filterCocoForNavigation(coco);
  if (relevant.isEmpty) return custom;
  if (custom.isEmpty) return _sortByDistance(relevant);

  final merged = <Detection>[...custom];

  for (final c in relevant) {
    final twin = kCocoNavRelevant[c.labelEn];
    final duplicated = custom.any((k) {
      // Beda kelas dan tidak punya hubungan padanan: bukan kembar, walau
      // kotaknya bertindih. Motor yang terparkir di atas got terbuka adalah
      // dua bahaya berbeda, dan keduanya perlu disebut.
      final sameThing = k.labelEn == c.labelEn || (twin != null && k.labelEn == twin);
      if (!sameThing) return false;
      return _iou(k, c) > _dupIou;
    });
    if (!duplicated) merged.add(c);
  }

  return _sortByDistance(merged);
}

List<Detection> _sortByDistance(List<Detection> list) {
  final out = [...list];
  out.sort((a, b) => a.distanceMeter.compareTo(b.distanceMeter));
  return out;
}

double _iou(Detection a, Detection b) {
  final ax1 = (a.bbox['x1'] ?? 0).toDouble();
  final ay1 = (a.bbox['y1'] ?? 0).toDouble();
  final ax2 = (a.bbox['x2'] ?? 0).toDouble();
  final ay2 = (a.bbox['y2'] ?? 0).toDouble();
  final bx1 = (b.bbox['x1'] ?? 0).toDouble();
  final by1 = (b.bbox['y1'] ?? 0).toDouble();
  final bx2 = (b.bbox['x2'] ?? 0).toDouble();
  final by2 = (b.bbox['y2'] ?? 0).toDouble();

  final iw = max(0.0, min(ax2, bx2) - max(ax1, bx1));
  final ih = max(0.0, min(ay2, by2) - max(ay1, by1));
  final inter = iw * ih;
  if (inter <= 0) return 0;

  final areaA = (ax2 - ax1) * (ay2 - ay1);
  final areaB = (bx2 - bx1) * (by2 - by1);
  final union = areaA + areaB - inter;
  if (union <= 0) return 0;
  return inter / union;
}
