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
  final String? imageUrl;
  
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
    this.imageUrl,
    required this.status,
    required this.lastReading,
    required this.alcoholLevel,
    required this.engineTemp,
    required this.speed,
  });

  // Helper to show "2022 Toyota Corolla"
  String get displayName => '$year $brand $model';

  // --- THIS IS THE IMPORTANT PART ---
  // This "factory" is a translator that turns the 
  // data from Supabase into a Vehicle object.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    
    // Get the latest sensor readings (or set defaults if null)
    final double alcohol = (json['alcohol_level'] as num?)?.toDouble() ?? 0.0;
    final double temp = (json['engine_temperature'] as num?)?.toDouble() ?? 0.0;
    final double spd = (json['speed'] as num?)?.toDouble() ?? 0.0;
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
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      fuelType: json['fuel_type'] as String,
      transmission: json['transmission'] as String,
      color: json['color'] as String,
      plateNumber: json['plate_number'] as String,
      imageUrl: json['image_url'] as String?,
      
      // Assign the live data
      status: calculatedStatus,
      lastReading: lastRead,
      alcoholLevel: alcohol,
      engineTemp: temp,
      speed: spd,
    );
  }

  // We also need a toJson() for the 'Add Vehicle' screen
  // You can ignore this for now, but it's good to have.
  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'transmission': transmission,
      'color': color,
      'plate_number': plateNumber,
      'image_url': imageUrl,
    };
  }
}