// lib/core/services/bill_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';
import '../models/sale_model.dart';

class BillService {
  final SupabaseClient _client = Supabase.instance.client;

  // =======================================================================
  // GET NEXT BILL NUMBER (Universal handler for RPC variations)
  // =======================================================================
  Future<String> getNextBillNumber() async {
    try {
      final res = await _client.rpc('generate_next_bill_no');

      if (res == null) {
        throw Exception("RPC returned NULL for generate_next_bill_no");
      }

      // Direct string result
      if (res is String) {
        if (res.trim().isEmpty) throw Exception("Bill number empty.");
        return res.trim();
      }

      // Returned record { bill_no: "A1234" }
      if (res is Map && res['bill_no'] != null) {
        final num = res['bill_no'].toString().trim();
        if (num.isEmpty) throw Exception("bill_no is empty");
        return num;
      }

      throw Exception("Unexpected RPC format: $res");

    } catch (e) {
      print("❌ getNextBillNumber ERROR: $e");
      throw Exception("Failed to fetch next bill number: $e");
    }
  }


  // =======================================================================
  // CREATE BILL HEADER
  // =======================================================================
  Future<String> createBillHeader({
    required String billNo,
    required String? customerId,
    required String? salespersonId,
    required int totalItems,
    required double subTotal,
    required double totalDiscount,
    required double total,
    required double totalPaid,
    required bool isFullyPaid,
  }) async {
    try {
      // Ensure salesperson is always set (RLS requirement)
      final String spId =
          salespersonId ?? _client.auth.currentUser?.id ?? '';

      if (spId.isEmpty) {
        throw Exception("Salesperson ID missing. Cannot create bill.");
      }

      final data = {
        'bill_no': billNo,
        'customer_id': customerId,
        'salesperson_id': spId,
        'total_items': totalItems,
        'sub_total': subTotal,
        'total_discount': totalDiscount,
        'total': total,
        'total_paid': totalPaid,
        'is_fully_paid': isFullyPaid,
      };

      final row =
      await _client.from('bills').insert(data).select().single();

      return row['id'];

    } catch (e) {
      print("❌ createBillHeader ERROR: $e");
      throw Exception("Failed to create bill header: $e");
    }
  }


  // =======================================================================
  // GET BILL WITH ITEMS (JOIN)
  // =======================================================================
  Future<Map<String, dynamic>> getBillWithItems(String billId) async {
    try {
      final bill = await _client
          .from('bills')
          .select()
          .eq('id', billId)
          .maybeSingle();

      if (bill == null) {
        throw Exception("Bill not found ($billId).");
      }

      final items = await _client
          .from('sales')
          .select('*, products(name, barcode)')
          .eq('bill_id', billId);

      return {
        'bill': Bill.fromMap(bill),
        'items': items.map((e) {
          return Sale.fromMap({
            ...e,
            'product_name': e['products']?['name'],
            'barcode': e['products']?['barcode'],
          });
        }).toList(),
      };


    } catch (e) {
      print("❌ getBillWithItems error: $e");
      SnackBar(content: Text("❌ Error loading bill: $e"));
      rethrow;
    }
  }

  // =======================================================================
  // LAST 7 DAYS
  // =======================================================================
  Future<List<Bill>> getLast7DaysBills() async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      )
          .order('created_at', ascending: false);

      return response.map<Bill>((e) => Bill.fromMap(e)).toList();

    } catch (e) {
      print("❌ getLast7DaysBills error: $e");
      SnackBar(content: Text("❌ Failed to load bills: $e"));
      rethrow;
    }
  }

  // =======================================================================
  // SEARCH A BILL
  // =======================================================================
  Future<Bill?> searchBill(String billNo) async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('bill_no', billNo)
          .maybeSingle();

      if (response == null) return null;
      return Bill.fromMap(response);

    } catch (e) {
      print("❌ searchBill error: $e");
      SnackBar(content: Text("❌ Search error: $e"));
      return null;
    }
  }

  // =======================================================================
  // BILLS BY SALESPERSON
  // =======================================================================
  Future<List<Bill>> getBillsBySalesperson(String salespersonId) async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('salesperson_id', salespersonId)
          .order('created_at', ascending: false);

      return response.map<Bill>((e) => Bill.fromMap(e)).toList();

    } catch (e) {
      print("❌ getBillsBySalesperson error: $e");
      SnackBar(content: Text("❌ Error: $e"));
      rethrow;
    }
  }

  // =======================================================================
  // BILLS OF A REGISTERED CUSTOMER
  // =======================================================================
  Future<List<Bill>> getCustomerBills(String customerId) async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return response.map<Bill>((e) => Bill.fromMap(e)).toList();

    } catch (e) {
      print("❌ getCustomerBills error: $e");
      SnackBar(content: Text("❌ Error loading customer bills: $e"));
      rethrow;
    }
  }
}
