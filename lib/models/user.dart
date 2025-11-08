class User {
  final String id;
  final String name;
  final String company;
  final String contactNumber;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.company,
    required this.contactNumber,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'company': company,
    'contactNumber': contactNumber,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    company: json['company'],
    contactNumber: json['contactNumber'],
    email: json['email'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  User copyWith({
    String? id,
    String? name,
    String? company,
    String? contactNumber,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    company: company ?? this.company,
    contactNumber: contactNumber ?? this.contactNumber,
    email: email ?? this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
