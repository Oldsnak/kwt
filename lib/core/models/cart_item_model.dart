class CartItem {
  final String id;
  final String productId;
  final int quantity;
  final double discountPerPiece;
  final double? totalAmount;
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.discountPerPiece,
    this.totalAmount,
    this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    quantity: (json['quantity'] as num).toInt(),
    discountPerPiece: (json['discount_per_piece'] as num).toDouble(),
    totalAmount: json['total_amount'] == null ? null : (json['total_amount'] as num).toDouble(),
    addedAt: json['added_at'] == null ? null : DateTime.parse(json['added_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'discount_per_piece': discountPerPiece,
    'total_amount': totalAmount,
    'added_at': addedAt?.toIso8601String(),
  };

  CartItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? discountPerPiece,
    double? totalAmount,
    DateTime? addedAt,
  }) =>
      CartItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        discountPerPiece: discountPerPiece ?? this.discountPerPiece,
        totalAmount: totalAmount ?? this.totalAmount,
        addedAt: addedAt ?? this.addedAt,
      );
}