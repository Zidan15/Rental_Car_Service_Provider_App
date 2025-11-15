// lib/services/alert_service.dart
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/main.dart'; // Import main.dart to get the 'supabase' helper
import 'package:supabase_flutter/supabase_flutter.dart'; // Import for CountOption

class AlertService {
  
  /// Fetches the count of all 'new' alerts.
  Future<int> getActiveAlertsCount() async {
    try {
      // Fetch alerts where status is 'new' and get the count
      final response = await supabase
          .from('alerts')
          .select('id', const CountOption())
          .eq('status', 'new');
          
      return response.count;
    } catch (e) {
      print('Error fetching alerts count: $e');
      return 0;
    }
  }
  
  /// Fetches the full list of alerts (newest first).
  /// This also fetches the vehicle names to match your mock data.
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
          .select('id, brand, model, year'); // Only get what we need

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
      print('Error fetching alerts: $e');
      return [];
    }
  }

  /// Acknowledges an alert by updating its status in the database.
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await supabase
          .from('alerts')
          .update({'status': 'acknowledged'})
          .eq('id', alertId);
    } catch (e) {
      print('Error acknowledging alert: $e');
      rethrow;
    }
  }
}