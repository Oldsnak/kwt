class Product {
  final String id;
  final String? categoryId;
  final String name;
  final double purchaseRate;
  final double sellingRate;
  final int stockQuantity;
  final String? barcode;
  final DateTime? createdAt;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.purchaseRate,
    required this.sellingRate,
    required this.stockQuantity,
    this.barcode,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    categoryId: json['category_id'] as String?,
    name: json['name'] as String,
    purchaseRate: (json['purchase_rate'] is int) ? (json['purchase_rate'] as int).toDouble() : (json['purchase_rate'] as num).toDouble(),
    sellingRate: (json['selling_rate'] is int) ? (json['selling_rate'] as int).toDouble() : (json['selling_rate'] as num).toDouble(),
    stockQuantity: (json['stock_quantity'] as num).toInt(),
    barcode: json['barcode'] as String?,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'purchase_rate': purchaseRate,
    'selling_rate': sellingRate,
    'stock_quantity': stockQuantity,
    'barcode': barcode,
    'created_at': createdAt?.toIso8601String(),
  };

  Product copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? purchaseRate,
    double? sellingRate,
    int? stockQuantity,
    String? barcode,
    DateTime? createdAt,
  }) =>
      Product(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        purchaseRate: purchaseRate ?? this.purchaseRate,
        sellingRate: sellingRate ?? this.sellingRate,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        barcode: barcode ?? this.barcode,
        createdAt: createdAt ?? this.createdAt,
      );
}