// lib/core/models/customer_model.dart

import 'customer_debt_model.dart';
import 'customer_payment_model.dart';

/// Represents a registered customer in the store.
///
/// Maps to `public.customers` table:
/// id, name, phone, address, cnic, is_active, created_at
class Customer {
  final String? id;          // uuid (null before database insert)
  final String name;
  final String? phone;
  final String? address;
  final String? cnic;        // National ID number
  final bool isActive;
  final DateTime? createdAt;

  /// These fields are NOT stored in DB.
  /// They are calculated by the app or fetched via join queries.
  ///
  /// For "Registered Customers" page:
  /// totalPending = sum of (bills.total - bills.total_paid)
  final double? totalPending;

  /// Full transaction history (list of payments + debts)
  /// This is useful for customer detail page.
  final List<CustomerDebt>? debts;
  final List<CustomerPayment>? payments;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.cnic,
    this.isActive = true,
    this.createdAt,
    this.totalPending,
    this.debts,
    this.payments,
  });

  /// Create Customer from Supabase Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String?,
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
      cnic: map['cnic'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,

      // joined/calculated fields (optional)
      totalPending: map['total_pending'] != null
          ? (map['total_pending'] as num).toDouble()
          : null,
    );
  }

  /// Map for inserting/updating customer in DB
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'cnic': cnic,
      'is_active': isActive,
    };
  }

  /// For copying with modifications
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
