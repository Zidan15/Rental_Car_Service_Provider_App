// lib/models/alert.dart

// --- ADDED ENUM ---
enum AlertSeverity { critical, warning, info } 
// ------------------

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

  // Helper to get severity from string names (used in status_badge)
  AlertSeverity get calculatedSeverity =>
      AlertSeverity.values.firstWhere((e) => e.name == severity.name); 

  // --- UPDATED FROMJSON ---
  factory Alert.fromJson(Map<String, dynamic> json) {
    // Note: All custom fields (vehicleName, severity, threshold) will be calculated in the service
    // and updated using copyWith, or calculated here based on raw data.
    
    // We will calculate severity and threshold here based on the database data.
    String sensorType = json['alert_type'] as String? ?? 'info';
    double reading = double.tryParse(json['value'] as String? ?? '0.0') ?? 0.0;
    
    double threshold = 0.0;
    AlertSeverity calculatedSeverity = AlertSeverity.info;

    // Simplified business logic for severity:
    // ONLY Alcohol Sensor is critical now, per user request.
    if (sensorType == 'Alcohol Sensor') {
      threshold = 0.08;
      if (reading > threshold) calculatedSeverity = AlertSeverity.critical;
    } 
    // Other sensors (Engine Temp, Battery) are currently ignored for alerts
    // as requested. They will default to 'info' severity.

    return Alert(
      // We assume the DB returns UUID as String 'id' (PK)
      id: json['id'] as String, 
      vehicleId: json['vehicle_id'] as String,
      vehicleName: 'Unknown', // Placeholder, will be updated in service
      sensorType: sensorType,
      severity: calculatedSeverity, // Calculated from raw data
      reading: reading,
      threshold: threshold, // Calculated from raw data
      timestamp: DateTime.parse(json['timestamp']),
      acknowledged: json['status'] == 'acknowledged', // Convert status string to bool
      createdAt: DateTime.parse(json['timestamp']),
      updatedAt: DateTime.parse(json['timestamp']),
    );
  }

  // --- ADDED COPYWITH ---
  Alert copyWith({
    String? id, String? vehicleId, String? vehicleName, String? sensorType,
    AlertSeverity? severity, double? reading, double? threshold, DateTime? timestamp,
    bool? acknowledged, DateTime? createdAt, DateTime? updatedAt,
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
  
  // (Your toJson method can remain as-is for now, or be deleted if not used)
}