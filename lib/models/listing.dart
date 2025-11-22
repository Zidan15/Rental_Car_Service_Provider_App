class Listing {
  final String id;
  final String vehicleId;
  final double pricePerDay;
  final bool isActive;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.vehicleId,
    required this.pricePerDay,
    required this.isActive,
    required this.createdAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'price_per_day': pricePerDay,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
