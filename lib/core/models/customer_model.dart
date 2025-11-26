import 'customer_debt_model.dart';
import 'customer_payment_model.dart';

/// Represents a registered customer in the store.
///
/// Maps to `public.customers` table:
/// id, name, phone, address, cnic, is_active, created_at
class Customer {
  final String? id;               // uuid
  final String name;
  final String? phone;
  final String? address;
  final String? cnic;
  final bool isActive;
  final DateTime? createdAt;

  /// Derived/Joined Fields (NOT stored in `customers` table)
  final double totalPending;          // sum of remaining_amount for this customer
  final List<CustomerDebt>? debts;    // list from customer_debts
  final List<CustomerPayment>? payments;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.cnic,
    this.isActive = true,
    this.createdAt,
    this.totalPending = 0.0,
    this.debts,
    this.payments,
  });

  // ---------------------------------------------------------------------------
  // FROM MAP (Safe)
  // ---------------------------------------------------------------------------
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String?,
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
      cnic: map['cnic'],
      isActive: map['is_active'] ?? true,

      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,

      // If join query added `total_pending`
      totalPending: map['total_pending'] != null
          ? (map['total_pending'] as num).toDouble()
          : 0.0,

      // If join query returns debts list
      debts: map['debts'] != null
          ? (map['debts'] as List)
          .map((d) => CustomerDebt.fromJson(d))
          .toList()
          : null,

      // If join query returns payments list
      payments: map['payments'] != null
          ? (map['payments'] as List)
          .map((p) => CustomerPayment.fromJson(p))
          .toList()
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP (Insert/Update)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'cnic': cnic,
      'is_active': isActive,
      // DO NOT send created_at (Supabase auto)
      // DO NOT send id (auto uuid)
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? cnic,
    bool? isActive,
    DateTime? createdAt,
    double? totalPending,
    List<CustomerDebt>? debts,
    List<CustomerPayment>? payments,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cnic: cnic ?? this.cnic,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      totalPending: totalPending ?? this.totalPending,
      debts: debts ?? this.debts,
      payments: payments ?? this.payments,
    );
  }
}
