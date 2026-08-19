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
        // isApproaching tidak dari JSON — hanya dari tracker lokal
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
      );

  // Computed getters dari bbox pixel (format x1/y1/x2/y2).
  // Dibutuhkan ObjectTracker untuk IoU matching antar frame.
  double get bboxCx   => ((bbox['x1']! + bbox['x2']!) / 2).toDouble();
  double get bboxCy   => ((bbox['y1']! + bbox['y2']!) / 2).toDouble();
  double get bboxW    => (bbox['x2']! - bbox['x1']!).toDouble();
  double get bboxH    => (bbox['y2']! - bbox['y1']!).toDouble();
  double get bboxArea => bboxW * bboxH;

  /// Kalimat TTS singkat sesuai PRD UX
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
