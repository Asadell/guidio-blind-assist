class RiskZone {
  final double distanceMeter;
  final int count;
  final String commonLabel;
  final String warning;

  const RiskZone({
    required this.distanceMeter,
    required this.count,
    required this.commonLabel,
    required this.warning,
  });

  factory RiskZone.fromJson(Map<String, dynamic> json) => RiskZone(
        distanceMeter: (json['distance_meter'] ?? 0).toDouble(),
        count:         json['count'] as int? ?? 0,
        commonLabel:   json['common_label'] as String? ?? '',
        warning:       json['warning'] as String? ?? 'Area ini sering ada hambatan, hati-hati',
      );
}
