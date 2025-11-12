
class CustomerPayment {
  final String id;
  final String customerId;
  final double paidAmount;
  final DateTime paymentDate;
  final double? remainingBalance;
  final DateTime? createdAt;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.paidAmount,
    required this.paymentDate,
    this.remainingBalance,
    this.createdAt,
  });

  factory CustomerPayment.fromJson(Map<String, dynamic> json) => CustomerPayment(
    id: json['id'] as String,
    customerId: json['customer_id'] as String,
    paidAmount: (json['paid_amount'] as num).toDouble(),
    paymentDate: DateTime.parse(json['payment_date'] as String),
    remainingBalance: json['remaining_balance'] == null ? null : (json['remaining_balance'] as num).toDouble(),
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'paid_amount': paidAmount,
    'payment_date': paymentDate.toIso8601String(),
    'remaining_balance': remainingBalance,
    'created_at': createdAt?.toIso8601String(),
  };

  CustomerPayment copyWith({
    String? id,
    String? customerId,
    double? paidAmount,
    DateTime? paymentDate,
    double? remainingBalance,
    DateTime? createdAt,
  }) =>
      CustomerPayment(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        paidAmount: paidAmount ?? this.paidAmount,
        paymentDate: paymentDate ?? this.paymentDate,
        remainingBalance: remainingBalance ?? this.remainingBalance,
        createdAt: createdAt ?? this.createdAt,
      );
}