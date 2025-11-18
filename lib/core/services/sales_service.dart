// lib/core/services/sales_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../models/bill_model.dart';
import 'bill_service.dart';

class SalesService {
  final SupabaseClient _client = Supabase.instance.client;
  final BillService _billService = BillService();

  // ===========================================================================
  // FINALIZE BILL (Main function called on Checkout)
  // ===========================================================================

  Future<String> finalizeBill({
    required List<Sale> items,
    required String? customerId,
    required String? salespersonId,
    required bool isPaidFully,
    required double totalPaid,
  }) async {
    if (items.isEmpty) {
      throw Exception("Cannot finalize an empty bill.");
    }

    // ------------------------------------------------------------------------
    // CALCULATE BILL TOTALS
    // ------------------------------------------------------------------------
    double subTotal = 0;
    double totalDiscount = 0;

    for (var item in items) {
      subTotal += item.sellingRate * item.quantity;
      totalDiscount += item.discountPerPiece * item.quantity;
    }

    double finalTotal = subTotal - totalDiscount;

    if (totalPaid > finalTotal) {
      totalPaid = finalTotal; // prevent overpay
    }

    final bool isFullyPaid = isPaidFully ? true : (totalPaid >= finalTotal);

    // ------------------------------------------------------------------------
    // GET NEXT BILL NUMBER
    // ------------------------------------------------------------------------
    final String billNo = await _billService.getNextBillNumber();

    // ------------------------------------------------------------------------
    // CREATE BILL HEADER
    // ------------------------------------------------------------------------
    final String billId = await _billService.createBillHeader(
      billNo: billNo,
      customerId: customerId,
      salespersonId: salespersonId,
      totalItems: items.length,
      subTotal: subTotal,
      totalDiscount: totalDiscount,
      total: finalTotal,
      totalPaid: totalPaid,
      isFullyPaid: isFullyPaid,
    );

    // ------------------------------------------------------------------------
    // INSERT ALL ITEMS INTO sales TABLE
    // ------------------------------------------------------------------------
    for (var item in items) {
      final itemMap = item.copyWith(billId: billId).toMap();

      await _client.from('sales').insert(itemMap);

      // ------------------------------------------------------------
      // UPDATE PRODUCT STOCK
      // ------------------------------------------------------------
      await _client.rpc(
        'decrease_product_stock',
        params: {
          'p_product_id': item.productId,
          'p_qty': item.quantity,
        },
      );
    }

    // ------------------------------------------------------------------------
    // IF BILL NOT FULLY PAID → ADD INTO customer_debts TABLE
    // ------------------------------------------------------------------------
    if (!isFullyPaid && customerId != null) {
      final double pending = finalTotal - totalPaid;

      await _client.from('customer_debts').insert({
        'customer_id': customerId,
        'bill_id': billId,
        'debt_amount': pending,
      });
    }

    return billId; // helpful for UI
  }

  // ===========================================================================
  // GET SALES ITEMS OF A BILL (for Bill Detail Page)
  // ===========================================================================

  Future<List<Sale>> getBillItems(String billId) async {
    final response = await _client
        .from('sales')
        .select('*, products(name, barcode)')
        .eq('bill_id', billId);

    return response
        .map((row) => Sale.fromMap({
      ...row,
      'product_name': row['products']?['name'],
      'barcode': row['products']?['barcode'],
    }))
        .toList();
  }

  // ===========================================================================
  // GET TOTAL SALES & PROFIT OF A PRODUCT (Dashboard analytics)
  // ===========================================================================

  Future<Map<String, dynamic>> getProductSaleSummary(String productId) async {
    final response = await _client.rpc(
      'get_product_sales_summary',
      params: {'p_product_id': productId},
    );

    if (response == null) {
      return {
        'total_sold': 0,
        'total_revenue': 0.0,
        'total_profit': 0.0,
      };
    }

    return {
      'total_sold': response['total_sold'] ?? 0,
      'total_revenue': (response['total_revenue'] ?? 0).toDouble(),
      'total_profit': (response['total_profit'] ?? 0).toDouble(),
    };
  }

  // ===========================================================================
  // SALES OF LAST N DAYS (Useful for Dashboard Graph)
  // ===========================================================================

  Future<List<Sale>> getSalesOfLastDays(int days) async {
    final response = await _client
        .from('sales')
        .select('*, products(name, barcode)')
        .gte(
      'sold_at',
      DateTime.now().subtract(Duration(days: days)).toIso8601String(),
    )
        .order('sold_at', ascending: false);

    return response
        .map((row) => Sale.fromMap({
      ...row,
      'product_name': row['products']?['name'],
      'barcode': row['products']?['barcode'],
    }))
        .toList();
  }
}
