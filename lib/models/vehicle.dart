import 'package:fleetwise/models/sensor_reading.dart';

enum VehicleStatus { healthy, warning, critical }

class Vehicle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final String color;
  final String plateNumber;
  final List<String> deviceIds;
  final List<String> photoUrls;
  final VehicleStatus status;
  final DateTime lastReading;
  final double? alcoholLevel;
  final double? engineTemp;
  final double? batteryVoltage;
  final double? speed;
  final List<SensorReading> alcoholReadings;
  final List<SensorReading> engineTempReadings;
  final List<SensorReading> batteryReadings;
  final List<SensorReading> speedReadings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.color,
    required this.plateNumber,
    required this.deviceIds,
    required this.photoUrls,
    required this.status,
    required this.lastReading,
    this.alcoholLevel,
    this.engineTemp,
    this.batteryVoltage,
    this.speed,
    this.alcoholReadings = const [],
    this.engineTempReadings = const [],
    this.batteryReadings = const [],
    this.speedReadings = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$brand $model';

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'year': year,
    'fuelType': fuelType,
    'color': color,
    'plateNumber': plateNumber,
    'deviceIds': deviceIds,
    'photoUrls': photoUrls,
    'status': status.name,
    'lastReading': lastReading.toIso8601String(),
    'alcoholLevel': alcoholLevel,
    'engineTemp': engineTemp,
    'batteryVoltage': batteryVoltage,
    'speed': speed,
    'alcoholReadings': alcoholReadings.map((r) => r.toJson()).toList(),
    'engineTempReadings': engineTempReadings.map((r) => r.toJson()).toList(),
    'batteryReadings': batteryReadings.map((r) => r.toJson()).toList(),
    'speedReadings': speedReadings.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    brand: json['brand'],
    model: json['model'],
    year: json['year'],
    fuelType: json['fuelType'],
    color: json['color'],
    plateNumber: json['plateNumber'],
    deviceIds: List<String>.from(json['deviceIds']),
    photoUrls: List<String>.from(json['photoUrls']),
    status: VehicleStatus.values.firstWhere((e) => e.name == json['status']),
    lastReading: DateTime.parse(json['lastReading']),
    alcoholLevel: json['alcoholLevel'],
    engineTemp: json['engineTemp'],
    batteryVoltage: json['batteryVoltage'],
    speed: json['speed'],
    alcoholReadings: (json['alcoholReadings'] as List?)?.map((r) => SensorReading.fromJson(r)).toList() ?? [],
    engineTempReadings: (json['engineTempReadings'] as List?)?.map((r) => SensorReading.fromJson(r)).toList() ?? [],
    batteryReadings: (json['batteryReadings'] as List?)?.map((r) => SensorReading.fromJson(r)).toList() ?? [],
    speedReadings: (json['speedReadings'] as List?)?.map((r) => SensorReading.fromJson(r)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Vehicle copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? fuelType,
    String? color,
    String? plateNumber,
    List<String>? deviceIds,
    List<String>? photoUrls,
    VehicleStatus? status,
    DateTime? lastReading,
    double? alcoholLevel,
    double? engineTemp,
    double? batteryVoltage,
    double? speed,
    List<SensorReading>? alcoholReadings,
    List<SensorReading>? engineTempReadings,
    List<SensorReading>? batteryReadings,
    List<SensorReading>? speedReadings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Vehicle(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    year: year ?? this.year,
    fuelType: fuelType ?? this.fuelType,
    color: color ?? this.color,
    plateNumber: plateNumber ?? this.plateNumber,
    deviceIds: deviceIds ?? this.deviceIds,
    photoUrls: photoUrls ?? this.photoUrls,
    status: status ?? this.status,
    lastReading: lastReading ?? this.lastReading,
    alcoholLevel: alcoholLevel ?? this.alcoholLevel,
    engineTemp: engineTemp ?? this.engineTemp,
    batteryVoltage: batteryVoltage ?? this.batteryVoltage,
    speed: speed ?? this.speed,
    alcoholReadings: alcoholReadings ?? this.alcoholReadings,
    engineTempReadings: engineTempReadings ?? this.engineTempReadings,
    batteryReadings: batteryReadings ?? this.batteryReadings,
    speedReadings: speedReadings ?? this.speedReadings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
