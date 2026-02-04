// lib/models/location.dart

class ProviderLocation {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  ProviderLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ProviderLocation.fromJson(Map<String, dynamic> json) {
    return ProviderLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'lat': latitude,
      'lng': longitude,
    };
  }
}
