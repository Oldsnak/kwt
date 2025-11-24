// lib/core/services/bill_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';
import '../models/sale_model.dart';

class BillService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // GET LAST BILL NUMBER & GENERATE NEXT ONE LIKE: A0B9Z → A0B9A → A0B9B ...
  // ---------------------------------------------------------------------------

  Future<String> getNextBillNumber() async {
    final response = await _client
        .from('bills')
        .select('bill_no')
        .order('bill_no', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return "A0000"; // first bill
    }

    final last = response.first['bill_no'] as String;
    return _incrementBillNumber(last);
  }


  /// Logic for A0000 → A0001 → A0002 ... A0009 → A000A ... A000Z →
  /// A0010 → ... A00ZZ → ... A0ZZZ → A1000 ... → ZZZZZ
  String _incrementBillNumber(String input) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    List<String> arr = input.split("");
    int i = arr.length - 1;

    while (i >= 0) {
      int index = chars.indexOf(arr[i]);

      if (index == -1) break; // unexpected case
      if (index < chars.length - 1) {
        arr[i] = chars[index + 1];
        return arr.join();
      }

      arr[i] = chars[0];
      i--;
    }

    return "A0000"; // fallback (should never hit)
  }

  // ---------------------------------------------------------------------------
  // CREATE BILL HEADER (used by SalesService inside finalizeBill)
  // ---------------------------------------------------------------------------

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
    final insertData = {
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

    final response =
    await _client.from('bills').insert(insertData).select().single();

    return response['id'];
  }

  // ---------------------------------------------------------------------------
  // GET BILL DETAIL WITH ALL LINE ITEMS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getBillWithItems(String billId) async {
    final bill = await _client
        .from('bills')
        .select()
        .eq('id', billId)
        .maybeSingle();

    if (bill == null) {
      throw Exception("Bill not found");
    }

    final items = await _client
        .from('sales')
        .select(
        '*, products(name, barcode)') // join product info
        .eq('bill_id', billId);

    return {
      'bill': Bill.fromMap(bill),
      'items': items
          .map((e) => Sale.fromMap({
        ...e,
        'product_name': e['products']?['name'],
        'barcode': e['products']?['barcode'],
      }))
          .toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // LAST 7 DAYS BILLS
  // ---------------------------------------------------------------------------

  Future<List<Bill>> getLast7DaysBills() async {
    final response = await _client
        .from('bills')
        .select()
        .gte('created_at',
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
        .order('created_at', ascending: false);

    return response.map((e) => Bill.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // SEARCH BILL BY BILL NUMBER
  // ---------------------------------------------------------------------------

  Future<Bill?> searchBill(String billNo) async {
    final response = await _client
        .from('bills')
        .select()
        .eq('bill_no', billNo)
        .maybeSingle();

    if (response == null) return null;
    return Bill.fromMap(response);
  }

  // ---------------------------------------------------------------------------
  // FILTER BILLS BY SALESPERSON
  // ---------------------------------------------------------------------------

  Future<List<Bill>> getBillsBySalesperson(String salespersonId) async {
    final response = await _client
        .from('bills')
        .select()
        .eq('salesperson_id', salespersonId)
        .order('created_at', ascending: false);

    return response.map((e) => Bill.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // BILLS OF A SPECIFIC CUSTOMER (Registered Customer Detail Page)
  // ---------------------------------------------------------------------------

  Future<List<Bill>> getCustomerBills(String customerId) async {
    final response = await _client
        .from('bills')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return response.map((e) => Bill.fromMap(e)).toList();
  }
}
