class HealthStatus {
  final double weight;
  final double height;
  final double bmi;
  final String note;

  HealthStatus({
    required this.weight,
    required this.height,
    required this.bmi,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'note': note,
    };
  }

  factory HealthStatus.fromMap(Map<String, dynamic> d) {
    return HealthStatus(
      weight: (d['weight'] ?? 0).toDouble(),
      height: (d['height'] ?? 0).toDouble(),
      bmi: (d['bmi'] ?? 0).toDouble(),
      note: d['note'] ?? "",
    );
  }
}
