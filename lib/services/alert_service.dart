// lib/services/alert_service.dart
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/main.dart'; // Import main.dart to get the 'supabase' helper
import 'package:supabase_flutter/supabase_flutter.dart'; // Re-add for PostgrestFilterBuilder

class AlertService {
  
  /// Fetches the count of all 'new' alerts.
  Future<int> getActiveAlertsCount() async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .eq('status', 'new')
          .count();
      final int count = response.count ?? 0;
      return count;
    } catch (e) {
      // Log the error or handle it appropriately
      return 0;
    }
  }
  
  /// Fetches the full list of alerts (newest first).
  Future<List<Alert>> getAlerts() async {
    try {
      // 1. Fetch all alerts
      final alertData = await supabase
          .from('alerts')
          .select('*')
          .order('timestamp', ascending: false);
      
      final alerts = (alertData as List<dynamic>)
          .map((json) => Alert.fromJson(json))
          .toList();

      // 2. Fetch all vehicles (just to get their names)
      final vehicleData = await supabase
          .from('vehicles')
          .select('id, brand, model, year');

      // 3. Create a quick lookup map of Vehicle ID -> Vehicle Name
      final vehicleMap = {
        for (var v in (vehicleData as List<dynamic>)) 
          v['id']: "${v['year']} ${v['brand']} ${v['model']}"
      };
      
      // 4. Enrich alerts with vehicle names
      final enrichedAlerts = alerts.map((alert) {
        return alert.copyWith(
          vehicleName: vehicleMap[alert.vehicleId] ?? 'Unknown Vehicle'
        );
      }).toList();
          
      return enrichedAlerts;

    } catch (e) {
      // Log the error or handle it appropriately
      return [];
    }
  }

  /// Returns a real-time stream of alerts.
  Stream<List<Alert>> getAlertsStream() {
    return supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .asyncMap((data) async {
          // 1. Convert to Alert objects
          final alerts = data.map((json) => Alert.fromJson(json)).toList();

          // 2. Fetch vehicles for enrichment
          // Note: In a production app, you might cache this or use a separate stream for vehicles.
          final vehicleData = await supabase
              .from('vehicles')
              .select('id, brand, model, year');
          
          final vehicleMap = {
            for (var v in (vehicleData as List<dynamic>)) 
              v['id']: "${v['year']} ${v['brand']} ${v['model']}"
          };

          // 3. Enrich
          return alerts.map((alert) {
            return alert.copyWith(
              vehicleName: vehicleMap[alert.vehicleId] ?? 'Unknown Vehicle'
            );
          }).toList();
        });
  }

  /// Acknowledges an alert by DELETING it from the database.
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await supabase
          .from('alerts')
          .delete()
          .eq('id', alertId);
    } catch (e) {
      // Log the error or handle it appropriately
      rethrow;
    }
  }
}