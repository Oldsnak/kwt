class Product {
  final String? id;                 // uuid
  final String? categoryId;         // FK -> categories.id

  final String name;
  final double purchaseRate;
  final double sellingRate;
  final int stockQuantity;
  final String barcode;
  final bool isActive;
  final DateTime? createdAt;

  // ------------------------------------------------------------
  // OPTIONAL (joined / computed only)
  // ------------------------------------------------------------
  final String? categoryName;       // categories(name)
  final int? totalSold;             // computed in service
  final double? totalProfit;        // computed in service
  final double? avgProfit;          // computed in service (if needed)

  Product({
    this.id,
    this.categoryId,
    required this.name,
    required this.purchaseRate,
    required this.sellingRate,
    required this.stockQuantity,
    required this.barcode,
    this.isActive = true,
    this.createdAt,
    this.categoryName,
    this.totalSold,
    this.totalProfit,
    this.avgProfit,
  });

  // ============================================================
  // SAFE FROM MAP (Null-safe, type-safe, dynamic joins-safe)
  // ============================================================
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String?,
      categoryId: map['category_id'] as String?,
      name: map['name'] ?? '',

      purchaseRate: _toDouble(map['purchase_rate']),
      sellingRate: _toDouble(map['selling_rate']),
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,

      barcode: map['barcode'] ?? '',
      isActive: map['is_active'] ?? true,

      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,

      // Joined fields (from category join)
      categoryName: map['category_name'] ??
          (map['categories'] is Map
              ? map['categories']['name']
              : null),

      // Analytics (null-safe)
      totalSold: (map['total_sold'] as num?)?.toInt(),
      totalProfit: map['total_profit'] != null
          ? _toDouble(map['total_profit'])
          : null,
      avgProfit: map['avg_profit'] != null
          ? _toDouble(map['avg_profit'])
          : null,
    );
  }

  // ============================================================
  // TO MAP → Used for product insert & update
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
      'is_active': isActive,
    };
  }

  // ============================================================
  // COPY-WITH
  // ============================================================
  Product copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? purchaseRate,
    double? sellingRate,
    int? stockQuantity,
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    String? categoryName,
    int? totalSold,
    double? totalProfit,
    double? avgProfit,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      sellingRate: sellingRate ?? this.sellingRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      totalSold: totalSold ?? this.totalSold,
      totalProfit: totalProfit ?? this.totalProfit,
      avgProfit: avgProfit ?? this.avgProfit,
    );
  }
}

// ===================================================================
// HELPER → Safely convert dynamic values to double
// (Supabase sometimes returns int, double, or string depending on query)
// ===================================================================
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
