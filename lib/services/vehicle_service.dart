// lib/services/vehicle_service.dart
import 'package:flutter/foundation.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/sensor_reading.dart';
import 'package:fleetwise/main.dart'; // Import main.dart to get the 'supabase' helper

class VehicleService {
  
  /// Fetches the user's vehicles AND their latest sensor data, all in one go.
  Future<List<Vehicle>> getVehicles() async {
    try {
      final data = await supabase.rpc('get_vehicles_with_latest_reading');
      final vehicles = (data as List<dynamic>)
          .map((json) => Vehicle.fromJson(json))
          .toList();
      return vehicles;
    } catch (e) {
      // Log the error so we can debug
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }

  /// Adds a new vehicle to the database.
  Future<void> addVehicle(Vehicle vehicle) async {
    final userId = supabase.auth.currentUser!.id;
    final vehicleData = vehicle.toJson();
    vehicleData['owner_id'] = userId;

    try {
      await supabase.from('vehicles').insert(vehicleData);
    } catch (e) {
      // Log the error or handle it appropriately
      rethrow;
    }
  }

  /// Updates an existing vehicle in the database.
  Future<void> updateVehicle(Vehicle vehicle) async {
    final vehicleData = vehicle.toJson();

    try {
      await supabase
          .from('vehicles')
          .update(vehicleData)
          .eq('id', vehicle.id);
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    }
  }

  /// Toggles the listing status of a vehicle (publish/unpublish)
  Future<void> toggleListing(String vehicleId, bool isListed, {double? pricePerDay}) async {
    try {
      final updateData = <String, dynamic>{
        'is_listed': isListed,
      };
      if (pricePerDay != null) {
        updateData['price_per_day'] = pricePerDay;
      }
      
      await supabase
          .from('vehicles')
          .update(updateData)
          .eq('id', vehicleId);
    } catch (e) {
      debugPrint('Error toggling listing: $e');
      rethrow;
    }
  }

  /// Deletes a vehicle from the database
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await supabase
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      rethrow;
    }
  }

  // --- NEW CHART-SPECIFIC FUNCTIONS ---

  /// Fetches last 20 alcohol readings as {timestamp, label} maps.
  /// Returns string labels (e.g. "Sober", "Drunk") sent by the Pi.
  Future<List<Map<String, dynamic>>> getAlcoholHistory(String vehicleId) async {
    try {
      final data = await supabase
          .from('sensor_data')
          .select('created_at, alcohol_level')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetches historical data for the Engine Temp chart
  Future<List<SensorReading>> getEngineTempReadings(String vehicleId) async {
    try {
      // Select 'created_at' as 'timestamp' and 'engine_temperature' as 'value'
      final data = await supabase
          .from('sensor_data')
          .select('created_at as timestamp, engine_temperature as value')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false)
          .limit(50);

      final readings = (data as List<dynamic>)
          .map((json) => SensorReading.fromJson(json))
          .toList();
      return readings;
    } catch (e) {
      // Log the error or handle it appropriately
      return [];
    }
  }

  /// Fetches historical data for the Speed chart
  Future<List<SensorReading>> getSpeedReadings(String vehicleId) async {
    try {
      // Select 'created_at' as 'timestamp' and 'speed' as 'value'
      final data = await supabase
          .from('sensor_data')
          .select('created_at as timestamp, speed as value')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false)
          .limit(50);

      final readings = (data as List<dynamic>)
          .map((json) => SensorReading.fromJson(json))
          .toList();
      return readings;
    } catch (e) {
      // Log the error or handle it appropriately
      return [];
    }
  }
  
  // --- END NEW CHART FUNCTIONS ---

  // --- REAL-TIME SENSOR DATA STREAM ---
  /// Returns a real-time stream of sensor_data rows.
  /// Supabase Realtime will push updates whenever new rows are inserted.
  Stream<List<Map<String, dynamic>>> getSensorDataStream() {
    return supabase
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Your search function is perfect
  static List<Vehicle> searchVehicles(List<Vehicle> vehicles, String query) {
    if (query.isEmpty) return vehicles;
    
    final lowerQuery = query.toLowerCase();
    return vehicles.where((v) =>
      v.plateNumber.toLowerCase().contains(lowerQuery) ||
      v.model.toLowerCase().contains(lowerQuery) ||
      v.brand.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}