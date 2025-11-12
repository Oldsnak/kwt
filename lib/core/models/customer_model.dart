class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? cnic;
  final DateTime? createdAt;

  Customer({required this.id, required this.name, this.phone, this.address, this.cnic, this.createdAt});

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    cnic: json['cnic'] as String?,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'cnic': cnic,
    'created_at': createdAt?.toIso8601String(),
  };

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? cnic,
    DateTime? createdAt,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        cnic: cnic ?? this.cnic,
        createdAt: createdAt ?? this.createdAt,
      );
}