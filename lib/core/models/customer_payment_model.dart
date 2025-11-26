class CustomerPayment {
  final String id;                // uuid
  final String customerId;        // FK → customers.id
  final String? billId;           // FK → bills.id (nullable for advance payments)
  final double paidAmount;        // amount paid
  final DateTime paymentDate;     // when payment was made
  final DateTime? createdAt;      // Supabase auto-timestamp

  // Optional joined fields (NOT in DB)
  final String? billNo;           // from bills.bill_no

  CustomerPayment({
    required this.id,
    required this.customerId,
    this.billId,
    required this.paidAmount,
    required this.paymentDate,
    this.createdAt,
    this.billNo,
  });

  // ---------------------------------------------------------------------------
  // FROM JSON (safe)
  // ---------------------------------------------------------------------------
  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      billId: json['bill_id'] as String?,

      paidAmount: (json['paid_amount'] as num).toDouble(),

      paymentDate: DateTime.tryParse(json['payment_date'].toString()) ??
          DateTime.now(),

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      // Joined field (optional)
      billNo: json['bills']?['bill_no']?.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON (insert/update)
  // Note: Do NOT send id, created_at — Supabase auto-generates
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'bill_id': billId,
      'paid_amount': paidAmount,
      'payment_date': paymentDate.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  CustomerPayment copyWith({
    String? id,
    String? customerId,
    String? billId,
    double? paidAmount,
    DateTime? paymentDate,
    DateTime? createdAt,
    String? billNo,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      billId: billId ?? this.billId,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      billNo: billNo ?? this.billNo,
    );
  }
}
