class StockEntry {
  final String id;
  final String productId;
  final int quantity;
  final double purchaseRate;
  final double sellingRate;
  final DateTime receivedDate;
  final DateTime? createdAt;

  StockEntry({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.purchaseRate,
    required this.sellingRate,
    required this.receivedDate,
    this.createdAt,
  });

  factory StockEntry.fromJson(Map<String, dynamic> json) => StockEntry(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    quantity: (json['quantity'] as num).toInt(),
    purchaseRate: (json['purchase_rate'] as num).toDouble(),
    sellingRate: (json['selling_rate'] as num).toDouble(),
    receivedDate: DateTime.parse(json['received_date'] as String),
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'purchase_rate': purchaseRate,
    'selling_rate': sellingRate,
    'received_date': receivedDate.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };

  StockEntry copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? purchaseRate,
    double? sellingRate,
    DateTime? receivedDate,
    DateTime? createdAt,
  }) =>
      StockEntry(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        purchaseRate: purchaseRate ?? this.purchaseRate,
        sellingRate: sellingRate ?? this.sellingRate,
        receivedDate: receivedDate ?? this.receivedDate,
        createdAt: createdAt ?? this.createdAt,
      );
}