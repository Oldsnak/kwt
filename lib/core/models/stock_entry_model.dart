// lib/core/models/stock_entry_model.dart

/// Represents a single stock entry (batch) for a product.
///
/// Maps to `public.stock_entries` table:
/// id, product_id, quantity, purchase_rate, selling_rate,
/// received_date, created_at
class StockEntry {
  final String? id;                // uuid (null before insert)
  final String productId;          // FK to products.id
  final int quantity;              // how many pieces added in this batch
  final double purchaseRate;       // purchase rate of this batch
  final double sellingRate;        // selling rate of this batch
  final DateTime receivedDate;     // the date stock was received
  final DateTime? createdAt;       // record creation timestamp (from DB)

  /// These fields are NOT stored in DB — only used for UI joins.
  final String? productName;
  final String? barcode;

  StockEntry({
    this.id,
    required this.productId,
    required this.quantity,
    required this.purchaseRate,
    required this.sellingRate,
    required this.receivedDate,
    this.createdAt,
    this.productName,
    this.barcode,
  });

  /// Factory: convert Supabase row into StockEntry model
  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'] as String?,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as int?) ?? 0,
      purchaseRate: (map['purchase_rate'] as num).toDouble(),
      sellingRate: (map['selling_rate'] as num).toDouble(),
      receivedDate: map['received_date'] != null
          ? DateTime.parse(map['received_date'])
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,

      /// Optional joined fields:
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
    );
  }

  /// For inserting a new stock batch
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'received_date': receivedDate.toIso8601String(),
    };
  }

  StockEntry copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? purchaseRate,
    double? sellingRate,
    DateTime? receivedDate,
    DateTime? createdAt,
    String? productName,
    String? barcode,
  }) {
    return StockEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      sellingRate: sellingRate ?? this.sellingRate,
      receivedDate: receivedDate ?? this.receivedDate,
      createdAt: createdAt ?? this.createdAt,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
    );
  }

  /// Utility: total cost of this batch (quantity * purchase rate)
  double get totalCost => quantity * purchaseRate;

  /// Utility: value if sold at selling rate (quantity * selling rate)
  double get potentialRevenue => quantity * sellingRate;

  /// Utility: potential profit (if entire batch sold)
  double get potentialProfit => potentialRevenue - totalCost;
}
