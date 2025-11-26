class StockEntry {
  final String? id;                // uuid
  final String productId;          // FK to products.id
  final int quantity;              // batch quantity
  final double purchaseRate;       // batch purchase rate
  final double sellingRate;        // batch selling rate
  final DateTime receivedDate;     // date stock received
  final DateTime? createdAt;       // auto timestamp

  /// Joined fields (from StockService join)
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

  // ============================================================
  // FACTORY: SAFE PARSING (no crash even if db returns invalid dates)
  // ============================================================
  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'] as String?,
      productId: map['product_id'] as String,

      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      purchaseRate: (map['purchase_rate'] as num?)?.toDouble() ?? 0.0,
      sellingRate: (map['selling_rate'] as num?)?.toDouble() ?? 0.0,

      receivedDate: DateTime.tryParse(map['received_date']?.toString() ?? "") ??
          DateTime.now(),

      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,

      // joined fields
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
    );
  }

  // ============================================================
  // TO MAP — Used for INSERT
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'received_date': receivedDate.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================
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

  // ============================================================
  // ANALYTICS HELPERS
  // ============================================================
  double get totalCost => quantity * purchaseRate;

  double get potentialRevenue => quantity * sellingRate;

  double get potentialProfit => potentialRevenue - totalCost;
}
