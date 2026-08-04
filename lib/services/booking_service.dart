import 'package:flutter/foundation.dart';
import 'package:fleetwise/models/booking.dart';
import 'package:fleetwise/main.dart'; // To access 'supabase' client

class BookingService {
  
  /// Fetches bookings for the current user's vehicles.
  /// Two-step approach:
  /// 1. Get all vehicle IDs owned by the current user.
  /// 2. Get bookings where vehicle_id is in that list.
  Future<List<Booking>> getBookings() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Step 1: Get all vehicle IDs owned by the current user
      final vehicleData = await supabase
          .from('vehicles')
          .select('id')
          .eq('owner_id', userId);
      
      final vehicleIds = (vehicleData as List<dynamic>)
          .map((v) => v['id'] as String)
          .toList();
      
      // If user has no vehicles, return empty list
      if (vehicleIds.isEmpty) {
        return [];
      }

      // Step 2: Get bookings for those vehicles with renter info
      final data = await supabase
          .from('bookings')
          .select('*, vehicles(brand, model, year, plate_number), profiles(full_name, contact_number)')
          .inFilter('vehicle_id', vehicleIds)
          .order('created_at', ascending: false);

      final bookings = (data as List<dynamic>)
          .map((json) => Booking.fromJson(json))
          .toList();
      
      return bookings;
    } catch (e) {
      // Log error
      debugPrint('Error fetching bookings: $e');
      return [];
    }
  }

  /// Fetches COMPLETED bookings for earnings calculation
  Future<List<Booking>> getCompletedBookings() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Step 1: Get all vehicle IDs owned by the current user
      final vehicleData = await supabase
          .from('vehicles')
          .select('id')
          .eq('owner_id', userId);
      
      final vehicleIds = (vehicleData as List<dynamic>)
          .map((v) => v['id'] as String)
          .toList();
      
      if (vehicleIds.isEmpty) {
        return [];
      }

      // Step 2: Get only completed bookings
      final data = await supabase
          .from('bookings')
          .select('*, vehicles(brand, model, year, plate_number), profiles(full_name, contact_number)')
          .inFilter('vehicle_id', vehicleIds)
          .eq('status', 'completed')
          .order('end_date', ascending: false);

      final bookings = (data as List<dynamic>)
          .map((json) => Booking.fromJson(json))
          .toList();
      
      return bookings;
    } catch (e) {
      debugPrint('Error fetching completed bookings: $e');
      return [];
    }
  }

  /// Updates the status of a booking (e.g., 'confirmed', 'rejected', 'cancelled')
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);
    } catch (e) {
      rethrow;
    }
  }
}
