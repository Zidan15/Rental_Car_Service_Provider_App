import 'package:flutter_test/flutter_test.dart';
import 'package:fleetwise/models/vehicle.dart';

void main() {
  group('Vehicle Model - JSON Deserialization & Defaults', () {
    test('parses full valid vehicle JSON payload', () {
      final json = {
        'id': 'v-101',
        'brand': 'Mahindra',
        'model': 'Thar',
        'year': 2023,
        'fuel_type': 'Diesel',
        'transmission': 'Manual',
        'color': 'Black',
        'plate_number': 'GA-01-A-1234',
        'category': 'SUV',
        'image_url': 'https://example.com/thar.jpg',
        'price_per_day': 3000.0,
        'is_listed': true,
        'location_id': 'loc-55',
        'alcohol_level': 'Sober',
        'engine_temperature': 86.4,
        'speed': 45.0,
        'latitude': 15.4989,
        'longitude': 73.8278,
        'created_at': '2026-03-15T10:00:00.000Z',
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.id, equals('v-101'));
      expect(vehicle.brand, equals('Mahindra'));
      expect(vehicle.model, equals('Thar'));
      expect(vehicle.displayName, equals('Mahindra Thar'));
      expect(vehicle.year, equals(2023));
      expect(vehicle.fuelType, equals('Diesel'));
      expect(vehicle.transmission, equals('Manual'));
      expect(vehicle.color, equals('Black'));
      expect(vehicle.plateNumber, equals('GA-01-A-1234'));
      expect(vehicle.category, equals('SUV'));
      expect(vehicle.imageUrl, equals('https://example.com/thar.jpg'));
      expect(vehicle.pricePerDay, equals(3000.0));
      expect(vehicle.isListed, isTrue);
      expect(vehicle.locationId, equals('loc-55'));
      expect(vehicle.alcoholLevel, equals('Sober'));
      expect(vehicle.alcoholSeverity, equals(AlcoholSeverity.sober));
      expect(vehicle.engineTemp, equals(86.4));
      expect(vehicle.speed, equals(45.0));
      expect(vehicle.latitude, equals(15.4989));
      expect(vehicle.longitude, equals(73.8278));
      expect(vehicle.status, equals(VehicleStatus.healthy));
    });

    test('handles numeric integer casting for double fields without exception', () {
      final json = {
        'id': 'v-int-cast',
        'price_per_day': 2500, // int
        'engine_temperature': 85, // int
        'speed': 60, // int
        'latitude': 15, // int
        'longitude': 73, // int
        'year': 2021,
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.pricePerDay, equals(2500.0));
      expect(vehicle.engineTemp, equals(85.0));
      expect(vehicle.speed, equals(60.0));
      expect(vehicle.latitude, equals(15.0));
      expect(vehicle.longitude, equals(73.0));
      expect(vehicle.year, equals(2021));
    });

    test('applies safe fallbacks for missing or null fields', () {
      final json = <String, dynamic>{};

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.id, equals(''));
      expect(vehicle.brand, equals('Unknown'));
      expect(vehicle.model, equals('Unknown'));
      expect(vehicle.displayName, equals('Unknown Unknown'));
      expect(vehicle.year, equals(0));
      expect(vehicle.fuelType, equals('Unknown'));
      expect(vehicle.transmission, equals('Unknown'));
      expect(vehicle.color, equals('Unknown'));
      expect(vehicle.plateNumber, equals('No Plate'));
      expect(vehicle.category, isNull);
      expect(vehicle.imageUrl, isNull);
      expect(vehicle.pricePerDay, equals(0.0));
      expect(vehicle.isListed, isFalse);
      expect(vehicle.locationId, isNull);
      expect(vehicle.alcoholLevel, equals('Sober'));
      expect(vehicle.alcoholSeverity, equals(AlcoholSeverity.sober));
      expect(vehicle.engineTemp, equals(0.0));
      expect(vehicle.speed, equals(0.0));
      expect(vehicle.latitude, equals(0.0));
      expect(vehicle.longitude, equals(0.0));
      expect(vehicle.status, equals(VehicleStatus.healthy));
    });
  });

  group('Vehicle Model - Serialization & copyWith', () {
    test('toJson serializes editable database fields correctly', () {
      final vehicle = Vehicle(
        id: 'v-save',
        brand: 'Tata',
        model: 'Nexon',
        year: 2024,
        fuelType: 'EV',
        transmission: 'Automatic',
        color: 'Teal',
        plateNumber: 'GA-08-E-7777',
        category: 'SUV',
        imageUrl: 'https://example.com/nexon.jpg',
        pricePerDay: 3500.0,
        isListed: true,
        locationId: 'loc-1',
        status: VehicleStatus.healthy,
        lastReading: DateTime.now(),
        alcoholLevel: 'Sober',
        engineTemp: 50.0,
        speed: 0.0,
        latitude: 15.5,
        longitude: 73.8,
      );

      final json = vehicle.toJson();

      expect(json['brand'], equals('Tata'));
      expect(json['model'], equals('Nexon'));
      expect(json['year'], equals(2024));
      expect(json['fuel_type'], equals('EV'));
      expect(json['transmission'], equals('Automatic'));
      expect(json['color'], equals('Teal'));
      expect(json['plate_number'], equals('GA-08-E-7777'));
      expect(json['category'], equals('SUV'));
      expect(json['image_url'], equals('https://example.com/nexon.jpg'));
      expect(json['price_per_day'], equals(3500.0));
      expect(json['is_listed'], isTrue);
      expect(json['location_id'], equals('loc-1'));
    });

    test('copyWith creates updated vehicle while preserving existing properties', () {
      final vehicle = Vehicle(
        id: 'v-original',
        brand: 'Hyundai',
        model: 'i20',
        year: 2022,
        fuelType: 'Petrol',
        transmission: 'Manual',
        color: 'White',
        plateNumber: 'GA-02-C-1111',
        status: VehicleStatus.healthy,
        lastReading: DateTime.parse('2026-03-01T10:00:00Z'),
        alcoholLevel: 'Sober',
        engineTemp: 80.0,
        speed: 30.0,
        latitude: 15.49,
        longitude: 73.82,
      );

      final updated = vehicle.copyWith(
        status: VehicleStatus.warning,
        alcoholLevel: 'Light drinking',
        speed: 45.0,
        engineTemp: 92.0,
      );

      expect(updated.id, equals('v-original'));
      expect(updated.brand, equals('Hyundai'));
      expect(updated.model, equals('i20'));
      expect(updated.plateNumber, equals('GA-02-C-1111'));
      expect(updated.status, equals(VehicleStatus.warning));
      expect(updated.alcoholLevel, equals('Light drinking'));
      expect(updated.alcoholSeverity, equals(AlcoholSeverity.light));
      expect(updated.speed, equals(45.0));
      expect(updated.engineTemp, equals(92.0));
      expect(updated.latitude, equals(15.49));
    });
  });
}
