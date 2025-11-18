// lib/core/models/product_model.dart

/// Represents a product in the store.
///
/// Maps to `public.products` table:
/// id, category_id, name, purchase_rate, selling_rate,
/// stock_quantity, barcode, is_active, created_at
class Product {
  final String? id;                 // DB uuid (null before insert)
  final String? categoryId;         // FK to categories.id
  final String name;
  final double purchaseRate;        // current purchase rate
  final double sellingRate;         // current selling rate
  final int stockQuantity;          // remaining stock
  final String barcode;             // unique barcode
  final bool isActive;
  final DateTime? createdAt;

  /// These fields are NOT stored in DB — only joined/calculated.
  final String? categoryName;       // categories.name (joined)
  final int? totalSold;             // analytics
  final double? totalProfit;        // analytics

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
  });

  /// Factory: Convert Supabase row into Product model
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String?,
      categoryId: map['category_id'] as String?,
      name: map['name'] ?? '',
      purchaseRate: (map['purchase_rate'] as num).toDouble(),
      sellingRate: (map['selling_rate'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as int?) ?? 0,
      barcode: map['barcode'] ?? '',
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,

      // optional calculated / joined fields
      categoryName: map['category_name'],    // if joined
      totalSold: map['total_sold'],          // if aggregated
      totalProfit: map['total_profit'] != null
          ? (map['total_profit'] as num).toDouble()
          : null,
    );
  }

  /// For inserting & updating product
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
    );
  }
}
