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
    timestamp: DateTime.parse(json['timestamp']),
    value: json['value'],
  );
}
