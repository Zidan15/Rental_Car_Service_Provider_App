// lib/models/vehicle.dart

// 1. You need an enum to define the vehicle's status
enum VehicleStatus { healthy, warning, critical }

// Alcohol severity derived from the string sent by the Pi
enum AlcoholSeverity { sober, light, drunk, intoxicated }

/// Maps a raw alcohol_level string from the Pi/Supabase to an [AlcoholSeverity].
AlcoholSeverity alcoholSeverityFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'light drinking':
      return AlcoholSeverity.light;
    case 'drunk':
      return AlcoholSeverity.drunk;
    case 'intoxicated':
      return AlcoholSeverity.intoxicated;
    case 'sober':
    default:
      return AlcoholSeverity.sober;
  }
}

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
  final String alcoholLevel;   // e.g. "Sober", "Light drinking", "Drunk", "Intoxicated"
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

  // Helper to show "Toyota Corolla"
  String get displayName => '$brand $model';

  // Derived severity enum from the string label
  AlcoholSeverity get alcoholSeverity => alcoholSeverityFromString(alcoholLevel);

  // --- THIS IS THE IMPORTANT PART ---
  // This "factory" is a translator that turns the
  // data from Supabase into a Vehicle object.
  factory Vehicle.fromJson(Map<String, dynamic> json) {

    // Alcohol level: Pi sends a string category
    final String alcohol = (json['alcohol_level'] as String?) ?? 'Sober';
    final double temp = (json['engine_temperature'] as num?)?.toDouble() ?? 0.0;
    final double spd = (json['speed'] as num?)?.toDouble() ?? 0.0;
    final double lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lon = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final DateTime lastRead = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    // Calculate the status based on the live data
    final severity = alcoholSeverityFromString(alcohol);
    VehicleStatus calculatedStatus = VehicleStatus.healthy;
    if (severity == AlcoholSeverity.drunk ||
        severity == AlcoholSeverity.intoxicated ||
        temp > 100.0) {
      calculatedStatus = VehicleStatus.critical;
    } else if (severity == AlcoholSeverity.light || temp > 90.0) {
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
      category: json['category'] as String?,
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

  // Create a copy with updated sensor values (for real-time updates)
  Vehicle copyWith({
    VehicleStatus? status,
    DateTime? lastReading,
    String? alcoholLevel,   // now String
    double? engineTemp,
    double? speed,
    double? latitude,
    double? longitude,
  }) {
    return Vehicle(
      id: id,
      brand: brand,
      model: model,
      year: year,
      fuelType: fuelType,
      transmission: transmission,
      color: color,
      plateNumber: plateNumber,
      category: category,
      imageUrl: imageUrl,
      pricePerDay: pricePerDay,
      isListed: isListed,
      locationId: locationId,
      status: status ?? this.status,
      lastReading: lastReading ?? this.lastReading,
      alcoholLevel: alcoholLevel ?? this.alcoholLevel,
      engineTemp: engineTemp ?? this.engineTemp,
      speed: speed ?? this.speed,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}