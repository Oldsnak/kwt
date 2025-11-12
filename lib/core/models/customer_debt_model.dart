class CustomerDebt {
  final String id;
  final String customerId;
  final int? billNo;
  final double debtAmount;
  final DateTime? dueDate;
  final DateTime? createdAt;

  CustomerDebt({
    required this.id,
    required this.customerId,
    this.billNo,
    required this.debtAmount,
    this.dueDate,
    this.createdAt,
  });

  factory CustomerDebt.fromJson(Map<String, dynamic> json) => CustomerDebt(
    id: json['id'] as String,
    customerId: json['customer_id'] as String,
    billNo: json['bill_no'] == null ? null : (json['bill_no'] as num).toInt(),
    debtAmount: (json['debt_amount'] as num).toDouble(),
    dueDate: json['due_date'] == null ? null : DateTime.parse(json['due_date'] as String),
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'bill_no': billNo,
    'debt_amount': debtAmount,
    'due_date': dueDate?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };

  CustomerDebt copyWith({
    String? id,
    String? customerId,
    int? billNo,
    double? debtAmount,
    DateTime? dueDate,
    DateTime? createdAt,
  }) =>
      CustomerDebt(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        billNo: billNo ?? this.billNo,
        debtAmount: debtAmount ?? this.debtAmount,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
      );
}