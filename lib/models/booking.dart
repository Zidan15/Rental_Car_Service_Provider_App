class Booking {
  final String id;
  final String vehicleId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  
  // Optional: Renter details if joined
  final String? renterName;
  final String? renterPhone;
  final String? vehicleName;
  final String? vehiclePlate;
  final String? pickupLocation;
  final double? pickupLat;
  final double? pickupLng;

  Booking({
    required this.id,
    required this.vehicleId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.renterName,
    this.renterPhone,
    this.vehicleName,
    this.vehiclePlate,
    this.pickupLocation,
    this.pickupLat,
    this.pickupLng,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      renterId: json['renter_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      pickupLocation: json['pickup_location'] as String?,
      pickupLat: json['pickup_lat'] != null ? (json['pickup_lat'] as num).toDouble() : null,
      pickupLng: json['pickup_lng'] != null ? (json['pickup_lng'] as num).toDouble() : null,
      // Handle joined data if present
      renterName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      renterPhone: json['profiles'] != null ? json['profiles']['contact_number'] : null,
      vehicleName: json['vehicles'] != null 
          ? "${json['vehicles']['brand']} ${json['vehicles']['model']}"
          : null,
      vehiclePlate: json['vehicles'] != null ? json['vehicles']['plate_number'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'renter_id': renterId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
