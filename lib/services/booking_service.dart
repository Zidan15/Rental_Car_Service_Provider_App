import 'package:fleetwise/models/booking.dart';
import 'package:fleetwise/main.dart'; // To access 'supabase' client

class BookingService {
  
  /// Fetches bookings for the current user's vehicles.
  /// This requires a complex query: 
  /// 1. Get all vehicles owned by user.
  /// 2. Get bookings for those vehicles.
  /// OR: Use a Supabase view or RLS policy that allows querying 'bookings' directly.
  /// Assuming RLS allows "select * from bookings where vehicle_id in (select id from vehicles where owner_id = me)"
  Future<List<Booking>> getBookings() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // We need to fetch bookings where the related vehicle belongs to the current user.
      // Supabase query:
      // select *, vehicles!inner(owner_id), profiles(full_name)
      // where vehicles.owner_id = userId
      
      final data = await supabase
          .from('bookings')
          .select('*, vehicles!inner(owner_id, brand, model, year), profiles(full_name)')
          .eq('vehicles.owner_id', userId)
          .order('created_at', ascending: false);

      final bookings = (data as List<dynamic>)
          .map((json) => Booking.fromJson(json))
          .toList();
      
      return bookings;
    } catch (e) {
      // Log error
      print('Error fetching bookings: $e');
      return [];
    }
  }

  /// Updates the status of a booking (e.g., 'confirmed', 'rejected')
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
