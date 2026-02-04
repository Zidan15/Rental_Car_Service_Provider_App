// lib/models/vehicle.dart

// 1. You need an enum to define the vehicle's status
enum VehicleStatus { healthy, warning, critical }

class Vehicle {
  // These come from the 'vehicles' table
  final String id;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final String transmission;
  final String color;
  final String plateNumber;
  final String? category;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  
  // Listing fields (merged from listings table)
  final double pricePerDay;
  final bool isListed;
  
  // Location field
  final String? locationId;
  
  // These come from the 'sensor_data' table
  final VehicleStatus status;
  final DateTime lastReading;
  final double alcoholLevel;
  final double engineTemp;
  final double speed;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.transmission,
    required this.color,
    required this.plateNumber,
    this.category,
    this.imageUrl,
    this.pricePerDay = 0.0,
    this.isListed = false,
    this.locationId,
    required this.status,
    required this.lastReading,
    required this.alcoholLevel,
    required this.engineTemp,
    required this.speed,
    required this.latitude,
    required this.longitude,
  });

  // Helper to show "2022 Toyota Corolla"
  // Helper to show "Toyota Corolla" (Year removed to prevent overflow)
  String get displayName => '$brand $model';

  // --- THIS IS THE IMPORTANT PART ---
  // This "factory" is a translator that turns the 
  // data from Supabase into a Vehicle object.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    
    // Get the latest sensor readings (or set defaults if null)
    final double alcohol = (json['alcohol_level'] as num?)?.toDouble() ?? 0.0;
    final double temp = (json['engine_temperature'] as num?)?.toDouble() ?? 0.0;
    final double spd = (json['speed'] as num?)?.toDouble() ?? 0.0;
    final double lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lon = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final DateTime lastRead = json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(); // Use now as a fallback

    // Calculate the status based on the live data
    VehicleStatus calculatedStatus = VehicleStatus.healthy;
    if (alcohol > 0.08 || temp > 100.0) {
      calculatedStatus = VehicleStatus.critical;
    } else if (alcohol > 0.0 || temp > 90.0) {
      calculatedStatus = VehicleStatus.warning;
    }

    // Create the Vehicle object with all the data
    return Vehicle(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? 'Unknown',
      model: json['model'] as String? ?? 'Unknown',
      year: (json['year'] as num?)?.toInt() ?? 0,
      fuelType: json['fuel_type'] as String? ?? 'Unknown',
      transmission: json['transmission'] as String? ?? 'Unknown',
      color: json['color'] as String? ?? 'Unknown',
      plateNumber: json['plate_number'] as String? ?? 'No Plate',
      category: json['category'] as String?, // Source of truth
      imageUrl: json['image_url'] as String?,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      isListed: json['is_listed'] as bool? ?? false,
      locationId: json['location_id'] as String?,
      
      // Assign the live data
      status: calculatedStatus,
      lastReading: lastRead,
      alcoholLevel: alcohol,
      engineTemp: temp,
      speed: spd,
      latitude: lat,
      longitude: lon,
    );
  }

  // We also need a toJson() for the 'Add Vehicle' screen
  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'transmission': transmission,
      'color': color,
      'plate_number': plateNumber,
      'category': category,
      'image_url': imageUrl,
      'price_per_day': pricePerDay,
      'is_listed': isListed,
      'location_id': locationId,
    };
  }
}