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
  final String? vehicleName;

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
    this.vehicleName,
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
      // Handle joined data if present
      renterName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      vehicleName: json['vehicles'] != null 
          ? "${json['vehicles']['year']} ${json['vehicles']['brand']} ${json['vehicles']['model']}"
          : null,
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
