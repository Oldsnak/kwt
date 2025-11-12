class Salesperson {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final DateTime? createdAt;

  Salesperson({required this.id, required this.name, this.email, this.phone, this.createdAt});

  factory Salesperson.fromJson(Map<String, dynamic> json) => Salesperson(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'created_at': createdAt?.toIso8601String(),
  };

  Salesperson copyWith({String? id, String? name, String? email, String? phone, DateTime? createdAt}) =>
      Salesperson(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        createdAt: createdAt ?? this.createdAt,
      );
}