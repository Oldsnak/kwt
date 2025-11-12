// Bill model (add to lib/core/models/models.dart or lib/core/models/bill_model.dart)

import 'package:kwt/core/models/sale_model.dart';

class Bill {
  final String id;
  final int? billNo;
  final String? customerId;
  final String? salespersonId;
  final DateTime createdAt;

  // line items (use Sale model for each item)
  final List<Sale> items;

  // money summary
  final double subTotal;       // sum of (price_per_unit * qty) before discounts
  final double totalDiscount;  // sum of discounts
  final double total;          // subTotal - totalDiscount
  final double totalPaid;      // amount paid at checkout
  final bool isPaid;           // true if fully paid, false if some due remains

  Bill({
    required this.id,
    this.billNo,
    this.customerId,
    this.salespersonId,
    DateTime? createdAt,
    required this.items,
    required this.subTotal,
    required this.totalDiscount,
    required this.total,
    required this.totalPaid,
    required this.isPaid,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    billNo: json['bill_no'] == null ? null : (json['bill_no'] as num).toInt(),
    customerId: json['customer_id'] as String?,
    salespersonId: json['salesperson_id'] as String?,
    createdAt: json['created_at'] == null ? DateTime.now() : DateTime.parse(json['created_at'] as String),
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => e is Sale ? e : Sale.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ??
        <Sale>[],
    subTotal: (json['sub_total'] ?? 0).toDouble(),
    totalDiscount: (json['total_discount'] ?? 0).toDouble(),
    total: (json['total'] ?? 0).toDouble(),
    totalPaid: (json['total_paid'] ?? 0).toDouble(),
    isPaid: json['is_paid'] == null ? false : (json['is_paid'] as bool),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bill_no': billNo,
    'customer_id': customerId,
    'salesperson_id': salespersonId,
    'created_at': createdAt.toIso8601String(),
    'items': items.map((s) => s.toJson()).toList(),
    'sub_total': subTotal,
    'total_discount': totalDiscount,
    'total': total,
    'total_paid': totalPaid,
    'is_paid': isPaid,
  };

  Bill copyWith({
    String? id,
    int? billNo,
    String? customerId,
    String? salespersonId,
    DateTime? createdAt,
    List<Sale>? items,
    double? subTotal,
    double? totalDiscount,
    double? total,
    double? totalPaid,
    bool? isPaid,
  }) =>
      Bill(
        id: id ?? this.id,
        billNo: billNo ?? this.billNo,
        customerId: customerId ?? this.customerId,
        salespersonId: salespersonId ?? this.salespersonId,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        subTotal: subTotal ?? this.subTotal,
        totalDiscount: totalDiscount ?? this.totalDiscount,
        total: total ?? this.total,
        totalPaid: totalPaid ?? this.totalPaid,
        isPaid: isPaid ?? this.isPaid,
      );
}
