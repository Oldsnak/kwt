class Category {
  final String id;
  final String name;
  final DateTime? createdAt;

  Category({required this.id, required this.name, this.createdAt});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt?.toIso8601String(),
  };

  Category copyWith({String? id, String? name, DateTime? createdAt}) =>
      Category(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
}