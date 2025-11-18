class CategoryModel {
  final String? id;
  final String name;
  final DateTime? createdAt;

  CategoryModel({
    this.id,
    required this.name,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'created_at': createdAt?.toIso8601String(),
  };
}
