class Sale {
  final String id;
  final int? billNo; // serial integer
  final String productId;
  final int quantity;
  final double discountPerPiece;
  final double totalAmount;
  final DateTime soldAt;
  final String? salespersonId;

  Sale({
    required this.id,
    this.billNo,
    required this.productId,
    required this.quantity,
    required this.discountPerPiece,
    required this.totalAmount,
    required this.soldAt,
    this.salespersonId,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] as String,
    billNo: json['bill_no'] == null ? null : (json['bill_no'] as num).toInt(),
    productId: json['product_id'] as String,
    quantity: (json['quantity'] as num).toInt(),
    discountPerPiece: (json['discount_per_piece'] as num).toDouble(),
    totalAmount: (json['total_amount'] as num).toDouble(),
    soldAt: DateTime.parse(json['sold_at'] as String),
    salespersonId: json['salesperson_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bill_no': billNo,
    'product_id': productId,
    'quantity': quantity,
    'discount_per_piece': discountPerPiece,
    'total_amount': totalAmount,
    'sold_at': soldAt.toIso8601String(),
    'salesperson_id': salespersonId,
  };

  Sale copyWith({
    String? id,
    int? billNo,
    String? productId,
    int? quantity,
    double? discountPerPiece,
    double? totalAmount,
    DateTime? soldAt,
    String? salespersonId,
  }) =>
      Sale(
        id: id ?? this.id,
        billNo: billNo ?? this.billNo,
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        discountPerPiece: discountPerPiece ?? this.discountPerPiece,
        totalAmount: totalAmount ?? this.totalAmount,
        soldAt: soldAt ?? this.soldAt,
        salespersonId: salespersonId ?? this.salespersonId,
      );
}