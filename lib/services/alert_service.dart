import 'package:fleetwise/models/alert.dart';

class AlertService {
  // Use a static list to hold and modify the mock data globally.
  static final List<Alert> _mockAlerts = _generateMockAlerts();

  static List<Alert> _generateMockAlerts() {
    final now = DateTime.now();
    
    return [
      Alert(
        id: '1',
        vehicleId: '3',
        vehicleName: 'Hyundai Creta',
        sensorType: 'Alcohol Sensor',
        severity: AlertSeverity.critical,
        reading: 0.12,
        threshold: 0.08,
        timestamp: now.subtract(const Duration(minutes: 2)),
        // acknowledged: false is default now
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
      ),
      Alert(
        id: '2',
        vehicleId: '3',
        vehicleName: 'Hyundai Creta',
        sensorType: 'Engine Temperature',
        severity: AlertSeverity.critical,
        reading: 105.0,
        threshold: 100.0,
        timestamp: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now,
      ),
      Alert(
        id: '3',
        vehicleId: '2',
        vehicleName: 'Honda City',
        sensorType: 'Battery Voltage',
        severity: AlertSeverity.warning,
        reading: 11.8,
        threshold: 12.0,
        timestamp: now.subtract(const Duration(minutes: 10)),
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now,
      ),
      Alert(
        id: '4',
        vehicleId: '7',
        vehicleName: 'Kia Seltos',
        sensorType: 'Alcohol Sensor',
        severity: AlertSeverity.warning,
        reading: 0.04,
        threshold: 0.03,
        timestamp: now.subtract(const Duration(minutes: 15)),
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now,
      ),
      Alert(
        id: '5',
        vehicleId: '1',
        vehicleName: 'Toyota Corolla',
        sensorType: 'Speed',
        severity: AlertSeverity.info,
        reading: 85.0,
        threshold: 80.0,
        timestamp: now.subtract(const Duration(hours: 1)),
        acknowledged: true,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 50)),
      ),
      Alert(
        id: '6',
        vehicleId: '4',
        vehicleName: 'Maruti Swift',
        sensorType: 'Engine Temperature',
        severity: AlertSeverity.info,
        reading: 92.0,
        threshold: 90.0,
        timestamp: now.subtract(const Duration(hours: 2)),
        acknowledged: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      ),
    ];
  }

  // Returns the shared, mutable list (of immutable Alert objects)
  static List<Alert> getMockAlerts() => _mockAlerts;

  // FIXED FUNCTION: Uses copyWith to replace the immutable object
  static void acknowledgeAlert(Alert alert) {
    // Find the alert in the global mock list by ID
    final index = _mockAlerts.indexWhere((a) => a.id == alert.id);
    
    if (index != -1) {
      // 1. Create a new Alert object with the updated 'acknowledged' status.
      final updatedAlert = alert.copyWith(
        acknowledged: true,
        updatedAt: DateTime.now(), // Optionally update the timestamp
      );
      
      // 2. Replace the old alert object in the list with the new one.
      _mockAlerts[index] = updatedAlert; 
    }
  }

  // Count logic remains the same (counts CRITICAL and UNACKNOWLEDGED alerts).
  static int getActiveAlertsCount(List<Alert> alerts) =>
    alerts.where((a) => 
      a.severity == AlertSeverity.critical && 
      !a.acknowledged).length;
}