// lib/core/models/bill_model.dart

class Bill {
  final String? id;
  final String billNo;

  final String? customerId;
  final String? salespersonId;

  final int totalItems;
  final double subTotal;
  final double totalDiscount;
  final double total;
  final double totalPaid;

  final bool isFullyPaid;
  final DateTime? createdAt;

  // Optional (joined) fields for UI
  final String? customerName;
  final String? salespersonName;

  const Bill({
    this.id,
    required this.billNo,
    this.customerId,
    this.salespersonId,
    required this.totalItems,
    required this.subTotal,
    required this.totalDiscount,
    required this.total,
    required this.totalPaid,
    required this.isFullyPaid,
    this.createdAt,
    this.customerName,
    this.salespersonName,
  });

  // ---------------------------------------------------------------------------
  // COMPUTED
  // ---------------------------------------------------------------------------
  double get pendingAmount {
    final p = total - totalPaid;
    return p < 0 ? 0 : p;
  }

  bool get hasPendingAmount => !isFullyPaid && pendingAmount > 0;

  // ---------------------------------------------------------------------------
  // COPYWITH
  // ---------------------------------------------------------------------------
  Bill copyWith({
    String? id,
    String? billNo,
    String? customerId,
    String? salespersonId,
    int? totalItems,
    double? subTotal,
    double? totalDiscount,
    double? total,
    double? totalPaid,
    bool? isFullyPaid,
    DateTime? createdAt,
    String? customerName,
    String? salespersonName,
  }) {
    return Bill(
      id: id ?? this.id,
      billNo: billNo ?? this.billNo,
      customerId: customerId ?? this.customerId,
      salespersonId: salespersonId ?? this.salespersonId,
      totalItems: totalItems ?? this.totalItems,
      subTotal: subTotal ?? this.subTotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      total: total ?? this.total,
      totalPaid: totalPaid ?? this.totalPaid,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      salespersonName: salespersonName ?? this.salespersonName,
    );
  }

  // ---------------------------------------------------------------------------
  // FROM MAP (SAFE)
  // ---------------------------------------------------------------------------
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as String?,
      billNo: (map['bill_no'] ?? '').toString(),

      customerId: map['customer_id'] as String?,
      salespersonId: map['salesperson_id'] as String?,

      totalItems: (map['total_items'] as num?)?.toInt() ?? 0,

      subTotal: (map['sub_total'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (map['total_discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,

      isFullyPaid: map['is_fully_paid'] == true,

      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,

      // FROM JOINED TABLES (OPTIONAL)
      customerName: map['customers']?['name'] as String?,
      salespersonName: map['user_profiles']?['full_name'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP (FOR INSERT / UPDATE)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'bill_no': billNo,
      'customer_id': customerId,
      'salesperson_id': salespersonId,
      'total_items': totalItems,
      'sub_total': subTotal,
      'total_discount': totalDiscount,
      'total': total,
      'total_paid': totalPaid,
      'is_fully_paid': isFullyPaid,
    };
  }
}
