import 'package:fleetwise/models/alert.dart';

class AlertService {
  static List<Alert> getMockAlerts() {
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
        acknowledged: false,
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
        acknowledged: false,
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
        acknowledged: false,
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
        acknowledged: false,
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

  static int getActiveAlertsCount(List<Alert> alerts) =>
    alerts.where((a) => !a.acknowledged && 
      (a.severity == AlertSeverity.critical || a.severity == AlertSeverity.warning)).length;
}
