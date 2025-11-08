enum AlertSeverity { critical, warning, info }

class Alert {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String sensorType;
  final AlertSeverity severity;
  final double reading;
  final double threshold;
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime createdAt;
  final DateTime updatedAt;

  Alert({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.sensorType,
    required this.severity,
    required this.reading,
    required this.threshold,
    required this.timestamp,
    this.acknowledged = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'vehicleName': vehicleName,
    'sensorType': sensorType,
    'severity': severity.name,
    'reading': reading,
    'threshold': threshold,
    'timestamp': timestamp.toIso8601String(),
    'acknowledged': acknowledged,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'],
    vehicleId: json['vehicleId'],
    vehicleName: json['vehicleName'],
    sensorType: json['sensorType'],
    severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
    reading: json['reading'],
    threshold: json['threshold'],
    timestamp: DateTime.parse(json['timestamp']),
    acknowledged: json['acknowledged'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Alert copyWith({
    String? id,
    String? vehicleId,
    String? vehicleName,
    String? sensorType,
    AlertSeverity? severity,
    double? reading,
    double? threshold,
    DateTime? timestamp,
    bool? acknowledged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Alert(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    vehicleName: vehicleName ?? this.vehicleName,
    sensorType: sensorType ?? this.sensorType,
    severity: severity ?? this.severity,
    reading: reading ?? this.reading,
    threshold: threshold ?? this.threshold,
    timestamp: timestamp ?? this.timestamp,
    acknowledged: acknowledged ?? this.acknowledged,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
