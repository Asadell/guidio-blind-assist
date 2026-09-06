class Detection {
  final String labelEn;
  final String labelId;
  final double confidence;
  final double distanceMeter;
  final String direction;      // "kiri" | "depan" | "kanan"
  final String dangerLevel;    // "critical" | "warning" | "info"
  final Map<String, int> bbox;
  final double inferenceMs;
  final bool isApproaching;    // true jika bbox makin besar (dari SORT tracker)

  /// Identitas objek dari [ObjectTracker], stabil antar frame. `null` berarti
  /// deteksi ini belum melewati tracker (mis. hasil server single-shot).
  ///
  /// Dipakai [DetectionFilter] sebagai kunci cooldown dan streak. Sebelumnya
  /// kuncinya `labelEn`, sehingga dua orang berbeda dianggap satu: orang yang
  /// jauh diumumkan lebih dulu, lalu orang yang dekat dan mendekat dibungkam
  /// sampai cooldown label "person" habis.
  final int? trackId;

  /// Ukuran bingkai TEGAK tempat [bbox] diukur, dalam piksel.
  ///
  /// "Tegak" berarti bingkai setelah diputar mengikuti orientasi layar, jadi
  /// inilah bingkai yang sama dengan yang dilihat pengguna di preview kamera.
  /// Pada Android bingkai sensor datang dalam lanskap lalu diputar 90 derajat,
  /// sehingga lebar-tegak = tinggi-sensor dan sebaliknya.
  ///
  /// Tanpa dua angka ini, [bbox] tidak bisa digambar: koordinat piksel tidak
  /// punya arti sampai diketahui piksel itu dari bingkai sebesar apa. `null`
  /// berarti sumbernya tidak melaporkan ukuran bingkai (mis. hasil server),
  /// dan lapisan gambar akan melewatinya alih-alih menebak.
  final int? frameWidth;
  final int? frameHeight;

  const Detection({
    required this.labelEn,
    required this.labelId,
    required this.confidence,
    required this.distanceMeter,
    required this.direction,
    required this.dangerLevel,
    required this.bbox,
    required this.inferenceMs,
    this.isApproaching = false,
    this.trackId,
    this.frameWidth,
    this.frameHeight,
  });

  /// Kunci identitas untuk filter. Pakai trackId kalau ada; kalau tidak,
  /// jatuh ke label supaya jalur tanpa tracker tetap punya cooldown.
  String get filterKey => trackId != null ? 't$trackId' : 'l$labelEn';

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
        labelEn:       json['label_en'] as String? ?? '',
        labelId:       json['label_id'] as String? ?? '',
        confidence:    (json['confidence'] ?? 0).toDouble(),
        distanceMeter: (json['distance_meter'] ?? 999).toDouble(),
        direction:     json['direction'] as String? ?? 'depan',
        dangerLevel:   json['danger_level'] as String? ?? 'info',
        bbox:          Map<String, int>.from(json['bbox'] as Map? ?? {}),
        inferenceMs:   (json['inference_ms'] ?? 0).toDouble(),
        // isApproaching tidak dari JSON - hanya dari tracker lokal
      );

  /// Buat salinan Detection dengan field tertentu diubah.
  /// Digunakan DetectionProvider untuk menambahkan isApproaching + trackId
  /// dari tracker.
  Detection copyWith({bool? isApproaching, int? trackId, double? distanceMeter}) => Detection(
        labelEn:       labelEn,
        labelId:       labelId,
        confidence:    confidence,
        distanceMeter: distanceMeter ?? this.distanceMeter,
        direction:     direction,
        dangerLevel:   dangerLevel,
        bbox:          bbox,
        inferenceMs:   inferenceMs,
        isApproaching: isApproaching ?? this.isApproaching,
        trackId:       trackId ?? this.trackId,
        frameWidth:    frameWidth,
        frameHeight:   frameHeight,
      );

  /// Kotak deteksi dalam pecahan 0..1 terhadap bingkai tegak, siap dipetakan
  /// ke persegi mana pun di layar.
  ///
  /// Sengaja ternormalisasi, bukan piksel: yang menggambar tidak perlu tahu
  /// resolusi kamera, dan mengganti preset resolusi tidak menggeser satu pun
  /// kotak. `null` kalau sumbernya tidak melaporkan ukuran bingkai - lebih
  /// baik tidak menggambar apa-apa daripada menggambar di tempat yang salah.
  ({double left, double top, double right, double bottom})? get normalizedBox {
    final fw = frameWidth;
    final fh = frameHeight;
    if (fw == null || fh == null || fw <= 0 || fh <= 0) return null;

    final x1 = bbox['x1'];
    final y1 = bbox['y1'];
    final x2 = bbox['x2'];
    final y2 = bbox['y2'];
    if (x1 == null || y1 == null || x2 == null || y2 == null) return null;

    final l = (x1 < x2 ? x1 : x2) / fw;
    final r = (x1 < x2 ? x2 : x1) / fw;
    final t = (y1 < y2 ? y1 : y2) / fh;
    final b = (y1 < y2 ? y2 : y1) / fh;

    return (
      left:   l.clamp(0.0, 1.0),
      top:    t.clamp(0.0, 1.0),
      right:  r.clamp(0.0, 1.0),
      bottom: b.clamp(0.0, 1.0),
    );
  }

  // Computed getters dari bbox pixel (format x1/y1/x2/y2).
  // Dibutuhkan ObjectTracker untuk IoU matching antar frame.
  double get bboxCx   => ((bbox['x1']! + bbox['x2']!) / 2).toDouble();
  double get bboxCy   => ((bbox['y1']! + bbox['y2']!) / 2).toDouble();
  double get bboxW    => (bbox['x2']! - bbox['x1']!).toDouble();
  double get bboxH    => (bbox['y2']! - bbox['y1']!).toDouble();
  double get bboxArea => bboxW * bboxH;

  /// Nama objek yang layak diucapkan.
  ///
  /// Model sesekali mengembalikan kelas tanpa padanan Bahasa Indonesia, dan
  /// kalimat "Ada  di depan" yang bolong di tengah terdengar seperti mesin
  /// suara yang macet, bukan seperti objek yang tidak dikenal.
  String get _spokenLabel => labelId.isEmpty ? 'objek' : labelId;

  String get _spokenDistance => distanceMeter < 1.0
      ? 'kurang dari satu meter'
      : 'sekitar ${distanceMeter.toStringAsFixed(0)} meter';

  /// Kalimat untuk **Mode Deteksi Objek** - laporan, bukan peringatan.
  ///
  /// Mode itu menyebutkan apa yang ada di depan kamera: orang, laptop, kursi.
  /// Ia tidak tahu apakah benda itu berbahaya, dan tidak punya cara tahu -
  /// yang dimilikinya cuma nama kelas, kotak, dan jarak perkiraan. Menyebut
  /// "Bahaya!" atas dasar jarak saja berarti mengeluarkan penilaian yang
  /// tidak pernah dibuat siapa pun.
  ///
  /// Biayanya nyata dan menumpuk. Orang yang lewat di depan kamera adalah
  /// kejadian paling sering di mode ini, dan setiap kalinya dulu berbunyi
  /// "Bahaya! Ada orang". Pengguna yang mendengar itu puluhan kali sehari
  /// belajar satu hal: kata "bahaya" dari aplikasi ini tidak berarti apa-apa.
  /// Yang rusak sesudahnya bukan mode ini - melainkan Mode Navigasi, satu-
  /// satunya tempat kata itu benar-benar berarti lubang di depan kaki.
  ///
  /// [ttsMessage] sengaja TIDAK ikut diubah: ia dipakai Mode Navigasi, yang
  /// memang mengawasi bahaya jalanan dan memang harus terdengar mendesak.
  String get objectMessage => 'Ada $_spokenLabel di $direction, $_spokenDistance';

  /// Kalimat TTS singkat sesuai PRD UX - **Mode Navigasi**.
  ///
  /// Nada mendesaknya disengaja dan tetap dipertahankan di sini: yang
  /// diperingatkan mode itu adalah lubang, got terbuka, dan tangga, tepat di
  /// jalur kaki pengguna. Untuk sekadar menyebut isi ruangan, pakai
  /// [objectMessage].
  String get ttsMessage {
    final dist = distanceMeter < 1.0
        ? 'kurang dari 1 meter'
        : '${distanceMeter.toStringAsFixed(0)} meter';
    switch (dangerLevel) {
      case 'critical':
        return 'Bahaya! Ada $labelId $dist di $direction';
      case 'warning':
        return 'Hati-hati, ada $labelId di $direction';
      default:
        return '$labelId di $direction';
    }
  }

  bool get isCritical => dangerLevel == 'critical';
  bool get isWarning  => dangerLevel == 'warning';
}
