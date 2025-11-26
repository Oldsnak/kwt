// lib/core/models/sale_model.dart

/// Represents a single line item inside a bill.
///
/// Maps to public.sales:
/// id, bill_id, product_id, quantity, selling_rate,
/// discount_per_piece, line_total, sold_at
class Sale {
  final String? id;               // uuid (null before insert)
  final String? billId;           // FK to bills.id
  final String productId;         // FK to products.id
  final int quantity;             // number of pieces
  final double sellingRate;       // rate per piece
  final double discountPerPiece;  // discount per piece
  final double lineTotal;         // auto-calculated if missing
  final DateTime? soldAt;

  // Optional UI convenience fields
  final String? productName;
  final String? barcode;

  Sale({
    this.id,
    this.billId,
    required this.productId,
    required this.quantity,
    required this.sellingRate,
    required this.discountPerPiece,
    double? lineTotal,
    this.soldAt,
    this.productName,
    this.barcode,
  }) : lineTotal = lineTotal ??
      ((sellingRate - discountPerPiece) * quantity);

  /// Unit price after discount
  double get finalUnitPrice => sellingRate - discountPerPiece;

  /// Total discount
  double get totalDiscount => discountPerPiece * quantity;

  /// Factory from Supabase row
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String?,
      billId: map['bill_id'] as String?,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      sellingRate: (map['selling_rate'] as num?)?.toDouble() ?? 0,
      discountPerPiece:
      (map['discount_per_piece'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['line_total'] as num?)?.toDouble(),
      soldAt: map['sold_at'] != null
          ? DateTime.tryParse(map['sold_at'].toString())
          : null,
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
    );
  }

  /// Convert to insert map for Supabase
  Map<String, dynamic> toMap() {
    return {
      if (billId != null) 'bill_id': billId,
      'product_id': productId,
      'quantity': quantity,
      'selling_rate': sellingRate,
      'discount_per_piece': discountPerPiece,
      'line_total': lineTotal,
    };
  }

  /// Clone
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
      discountPerPiece:
      discountPerPiece ?? this.discountPerPiece,
      lineTotal: lineTotal ?? this.lineTotal,
      soldAt: soldAt ?? this.soldAt,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
    );
  }
}
