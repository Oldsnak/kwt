class CategoryModel {
  final String? id;
  final String name;
  final DateTime? createdAt;

  CategoryModel({
    this.id,
    required this.name,
    this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // FROM MAP (SAFE)
  // ---------------------------------------------------------------------------
  factory CategoryModel.fromMap(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      name: (json['name'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP (INSERT)
  // DO NOT include id or created_at. Supabase generates them.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
