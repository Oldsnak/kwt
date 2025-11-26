class CustomerDebt {
  final String id;
  final String customerId;
  final String billId;               // UUID of bill (correct field)

  final double debtAmount;
  final double paidAmount;
  final double remainingAmount;

  final DateTime? dueDate;
  final DateTime? createdAt;

  CustomerDebt({
    required this.id,
    required this.customerId,
    required this.billId,
    required this.debtAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.dueDate,
    this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // FROM MAP (SAFE)
  // ---------------------------------------------------------------------------
  factory CustomerDebt.fromJson(Map<String, dynamic> json) {
    return CustomerDebt(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      billId: json['bill_id'] as String,

      debtAmount: (json['debt_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,

      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON (FOR INSERT/UPDATE)
  // DO NOT send id or created_at → Supabase auto-generates
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'bill_id': billId,
      'debt_amount': debtAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  CustomerDebt copyWith({
    String? id,
    String? customerId,
    String? billId,
    double? debtAmount,
    double? paidAmount,
    double? remainingAmount,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return CustomerDebt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      billId: billId ?? this.billId,
      debtAmount: debtAmount ?? this.debtAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  bool get isPaid => remainingAmount <= 0;

  double get pendingAmount => remainingAmount;
}
