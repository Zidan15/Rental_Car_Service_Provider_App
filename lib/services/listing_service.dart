import 'package:fleetwise/models/listing.dart';
import 'package:fleetwise/main.dart'; // To access 'supabase' client

class ListingService {
  
  /// Fetches the listing for a specific vehicle. Returns null if not found.
  Future<Listing?> getListingForVehicle(String vehicleId) async {
    try {
      final data = await supabase
          .from('listings')
          .select()
          .eq('vehicle_id', vehicleId)
          .maybeSingle();

      if (data == null) return null;
      return Listing.fromJson(data);
    } catch (e) {
      // Log error or rethrow
      return null;
    }
  }

  /// Creates or updates a listing for a vehicle.
  Future<void> publishListing(String vehicleId, double price) async {
    try {
      // Check if listing exists
      final existing = await getListingForVehicle(vehicleId);

      if (existing != null) {
        // Update
        await supabase.from('listings').update({
          'price_per_day': price,
          'is_active': true,
        }).eq('id', existing.id);
      } else {
        // Create
        await supabase.from('listings').insert({
          'vehicle_id': vehicleId,
          'price_per_day': price,
          'is_active': true,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deactivates a listing (Unpublish)
  Future<void> unpublishListing(String vehicleId) async {
    try {
      await supabase
          .from('listings')
          .update({'is_active': false})
          .eq('vehicle_id', vehicleId);
    } catch (e) {
      rethrow;
    }
  }
}
