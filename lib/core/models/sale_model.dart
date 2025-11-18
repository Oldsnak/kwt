// lib/core/models/sale_model.dart

/// Represents a single line item inside a bill.
///
/// Maps to `public.sales` table:
/// id, bill_id, product_id, quantity, selling_rate,
/// discount_per_piece, line_total, sold_at
class Sale {
  final String? id;               // uuid (null before insert)
  final String billId;            // FK to bills.id
  final String productId;         // FK to products.id
  final int quantity;             // number of pieces sold
  final double sellingRate;       // selling rate per piece at sale time
  final double discountPerPiece;  // discount applied per piece
  final double lineTotal;         // (sellingRate - discount) * quantity
  final DateTime? soldAt;         // auto generated

  /// Optional fields for UI convenience (NOT stored in DB)
  final String? productName;      // product.name (joined)
  final String? barcode;          // product.barcode (joined)

  Sale({
    this.id,
    required this.billId,
    required this.productId,
    required this.quantity,
    required this.sellingRate,
    required this.discountPerPiece,
    required this.lineTotal,
    this.soldAt,
    this.productName,
    this.barcode,
  });

  /// Compute unit price after discount.
  double get finalUnitPrice => sellingRate - discountPerPiece;

  /// Total discount for this item.
  double get totalDiscount => discountPerPiece * quantity;

  /// Factory: from Supabase row (sales + optional product join)
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String?,
      billId: map['bill_id'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as int?) ?? 0,
      sellingRate: (map['selling_rate'] as num).toDouble(),
      discountPerPiece: (map['discount_per_piece'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
      soldAt: map['sold_at'] != null
          ? DateTime.parse(map['sold_at'] as String)
          : null,

      // Joined fields (if service used select with relation)
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
    );
  }

  /// Convert to Supabase insert/update map.
  Map<String, dynamic> toMap() {
    return {
      'bill_id': billId,
      'product_id': productId,
      'quantity': quantity,
      'selling_rate': sellingRate,
      'discount_per_piece': discountPerPiece,
      'line_total': lineTotal,
    };
  }

  /// For cloning with modifications.
  Sale copyWith({
    String? id,
    String? billId,
    String? productId,
    int? quantity,
    double? sellingRate,
    double? discountPerPiece,
    double? lineTotal,
    DateTime? soldAt,
    String? productName,
    String? barcode,
  }) {
    return Sale(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      sellingRate: sellingRate ?? this.sellingRate,
      discountPerPiece: discountPerPiece ?? this.discountPerPiece,
      lineTotal: lineTotal ?? this.lineTotal,
      soldAt: soldAt ?? this.soldAt,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
    );
  }
}
