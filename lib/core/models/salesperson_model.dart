class Salesperson {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime? createdAt;

  Salesperson({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.createdAt,
  });

  factory Salesperson.fromJson(Map<String, dynamic> json) => Salesperson(
    id: json['id'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'created_at': createdAt?.toIso8601String(),
  };

  Salesperson copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    DateTime? createdAt,
  }) =>
      Salesperson(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        createdAt: createdAt ?? this.createdAt,
      );
}
