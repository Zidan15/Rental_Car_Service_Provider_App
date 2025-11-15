// In lib/models/alert.dart

  // ... (Your class properties and constructor stay the same) ...
  // ... (Your toJson and copyWith stay the same) ...

  // REPLACE your old fromJson with this new one
  factory Alert.fromJson(Map<String, dynamic> json) {
    
    // --- Translate from DB to App ---
    String sensorType = json['alert_type'] as String;
    String status = json['status'] as String;
    // The 'value' in your DB is a string, but your model needs a double
    double reading = double.tryParse(json['value'] as String? ?? '0.0') ?? 0.0;

    // --- Business Logic ---
    // We must calculate severity and threshold, as they aren't in the DB
    double threshold = 0.0;
    AlertSeverity severity = AlertSeverity.info;

    if (sensorType == 'Alcohol Sensor') {
      threshold = 0.08;
      if (reading > threshold) severity = AlertSeverity.critical;
    } else if (sensorType == 'Engine Temperature') {
      threshold = 100.0;
      if (reading > threshold) severity = AlertSeverity.critical;
    } else if (sensorType == 'Battery Voltage') {
        threshold = 12.0;
        if (reading < threshold) severity = AlertSeverity.warning;
    }
    // Add more rules here for other sensor types

    return Alert(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String, // DB snake_case -> app camelCase
      timestamp: DateTime.parse(json['timestamp']),
      sensorType: sensorType,
      reading: reading, // Use the parsed double
      acknowledged: status == 'acknowledged', // Convert string to bool
      
      // --- Data we don't have yet ---
      vehicleName: 'Loading...', // We'll fetch this in the service
      severity: severity, // Our calculated severity
      threshold: threshold, // Our calculated threshold
      createdAt: DateTime.parse(json['timestamp']), // Use timestamp as created_at
      updatedAt: DateTime.parse(json['timestamp']), // Use timestamp as updated_at
    );
  }

// ... (Your copyWith stays here) ...