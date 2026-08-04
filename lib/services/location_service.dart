// lib/services/location_service.dart
import 'package:flutter/foundation.dart';
import 'package:fleetwise/models/location.dart';
import 'package:fleetwise/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  /// Fetches all locations for the current provider.
  Future<List<ProviderLocation>> getLocations() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await supabase
          .from('provider_locations')
          .select('*')
          .eq('provider_id', userId)
          .order('name', ascending: true);

      return (data as List<dynamic>)
          .map((json) => ProviderLocation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }

  /// Adds a new location for the current provider.
  Future<void> addLocation(ProviderLocation location) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final locationData = location.toJson();
    locationData['provider_id'] = userId;

    try {
      await supabase.from('provider_locations').insert(locationData);
    } catch (e) {
      debugPrint('Error adding location: $e');
      rethrow;
    }
  }

  /// Deletes a location by its ID.
  Future<void> deleteLocation(String locationId) async {
    try {
      await supabase
          .from('provider_locations')
          .delete()
          .eq('id', locationId);
    } catch (e) {
      debugPrint('Error deleting location: $e');
      rethrow;
    }
  }

  /// Checks how many vehicles are currently assigned to this location.
  Future<int> getLocationUsageCount(String locationId) async {
    try {
      final response = await supabase
          .from('vehicles')
          .count(CountOption.exact)
          .eq('location_id', locationId);
      
      return response;
    } catch (e) {
      debugPrint('Error checking location usage: $e');
      return 0; // Default to 0 on error, though risky
    }
  }
}
