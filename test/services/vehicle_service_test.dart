import 'package:flutter_test/flutter_test.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/vehicle_service.dart';

void main() {
  Vehicle createDummyVehicle({
    String id = '1',
    String brand = 'Mahindra',
    String model = 'Thar',
    String plateNumber = 'GA-01-A-1234',
    VehicleStatus status = VehicleStatus.healthy,
    String alcoholLevel = 'Sober',
    double engineTemp = 85.0,
  }) {
    return Vehicle(
      id: id,
      brand: brand,
      model: model,
      year: 2022,
      fuelType: 'Diesel',
      transmission: 'Manual',
      color: 'Black',
      plateNumber: plateNumber,
      status: status,
      lastReading: DateTime.now(),
      alcoholLevel: alcoholLevel,
      engineTemp: engineTemp,
      speed: 0.0,
      latitude: 15.4989,
      longitude: 73.8278,
    );
  }

  group('VehicleService.searchVehicles', () {
    late List<Vehicle> testFleet;

    setUp(() {
      testFleet = [
        createDummyVehicle(
          id: 'v1',
          brand: 'Mahindra',
          model: 'Thar',
          plateNumber: 'GA-01-A-1234',
        ),
        createDummyVehicle(
          id: 'v2',
          brand: 'Maruti Suzuki',
          model: 'Swift',
          plateNumber: 'GA-02-B-5678',
        ),
        createDummyVehicle(
          id: 'v3',
          brand: 'Hyundai',
          model: 'Creta',
          plateNumber: 'GA-03-C-9999',
        ),
        createDummyVehicle(
          id: 'v4',
          brand: 'Honda',
          model: 'Activa 6G',
          plateNumber: 'GA-07-D-4321',
        ),
      ];
    });

    test('returns original list unmodified when search query is empty', () {
      final results = VehicleService.searchVehicles(testFleet, '');
      expect(results.length, equals(4));
      expect(results, equals(testFleet));
    });

    test('filters vehicles by model case-insensitively', () {
      final resultsLower = VehicleService.searchVehicles(testFleet, 'thar');
      expect(resultsLower.length, equals(1));
      expect(resultsLower.first.model, equals('Thar'));

      final resultsUpper = VehicleService.searchVehicles(testFleet, 'SWIFT');
      expect(resultsUpper.length, equals(1));
      expect(resultsUpper.first.model, equals('Swift'));
    });

    test('filters vehicles by brand case-insensitively', () {
      final results = VehicleService.searchVehicles(testFleet, 'hyundai');
      expect(results.length, equals(1));
      expect(results.first.brand, equals('Hyundai'));
    });

    test('filters vehicles by plate number case-insensitively', () {
      final results = VehicleService.searchVehicles(testFleet, 'ga-01');
      expect(results.length, equals(1));
      expect(results.first.plateNumber, equals('GA-01-A-1234'));
    });

    test('returns empty list when no vehicles match query', () {
      final results = VehicleService.searchVehicles(testFleet, 'Ferrari');
      expect(results, isEmpty);
    });
  });

  group('Alcohol Severity Mapping', () {
    test('maps sober and empty or null values to AlcoholSeverity.sober', () {
      expect(alcoholSeverityFromString('sober'), equals(AlcoholSeverity.sober));
      expect(alcoholSeverityFromString('Sober'), equals(AlcoholSeverity.sober));
      expect(alcoholSeverityFromString(''), equals(AlcoholSeverity.sober));
      expect(alcoholSeverityFromString(null), equals(AlcoholSeverity.sober));
      expect(alcoholSeverityFromString('unknown'), equals(AlcoholSeverity.sober));
    });

    test('maps light drinking variants to AlcoholSeverity.light', () {
      expect(alcoholSeverityFromString('light drinking'), equals(AlcoholSeverity.light));
      expect(alcoholSeverityFromString('Light drinking'), equals(AlcoholSeverity.light));
      expect(alcoholSeverityFromString('LIGHT DRINKING'), equals(AlcoholSeverity.light));
    });

    test('maps drunk variants to AlcoholSeverity.drunk', () {
      expect(alcoholSeverityFromString('drunk'), equals(AlcoholSeverity.drunk));
      expect(alcoholSeverityFromString('Drunk'), equals(AlcoholSeverity.drunk));
      expect(alcoholSeverityFromString('DRUNK'), equals(AlcoholSeverity.drunk));
    });

    test('maps intoxicated variants to AlcoholSeverity.intoxicated', () {
      expect(alcoholSeverityFromString('intoxicated'), equals(AlcoholSeverity.intoxicated));
      expect(alcoholSeverityFromString('Intoxicated'), equals(AlcoholSeverity.intoxicated));
      expect(alcoholSeverityFromString('INTOXICATED'), equals(AlcoholSeverity.intoxicated));
    });
  });

  group('Vehicle Status Calculation via JSON Deserialization', () {
    test('calculates healthy status for sober driver and normal temperature', () {
      final json = {
        'id': 'v-healthy',
        'alcohol_level': 'Sober',
        'engine_temperature': 82.5,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.healthy));
    });

    test('calculates warning status when alcohol is light drinking', () {
      final json = {
        'id': 'v-warn-alcohol',
        'alcohol_level': 'Light drinking',
        'engine_temperature': 80.0,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.warning));
    });

    test('calculates warning status when engine temperature exceeds 90C but below 100C', () {
      final json = {
        'id': 'v-warn-temp',
        'alcohol_level': 'Sober',
        'engine_temperature': 95.0,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.warning));
    });

    test('calculates critical status when driver is drunk', () {
      final json = {
        'id': 'v-crit-drunk',
        'alcohol_level': 'Drunk',
        'engine_temperature': 85.0,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.critical));
    });

    test('calculates critical status when driver is intoxicated', () {
      final json = {
        'id': 'v-crit-intoxicated',
        'alcohol_level': 'Intoxicated',
        'engine_temperature': 85.0,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.critical));
    });

    test('calculates critical status when engine temperature exceeds 100C even if sober', () {
      final json = {
        'id': 'v-crit-overheat',
        'alcohol_level': 'Sober',
        'engine_temperature': 105.0,
      };
      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.status, equals(VehicleStatus.critical));
    });
  });
}
