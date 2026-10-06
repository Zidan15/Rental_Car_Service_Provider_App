class SensorReading {
  final DateTime timestamp;
  final double value;

  SensorReading({
    required this.timestamp,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
  };

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
        : DateTime.now(),
    value: (json['value'] as num?)?.toDouble() ?? 0.0,
  );
}
