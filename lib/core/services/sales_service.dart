import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import 'package:flutter/material.dart';

class SalesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // FINALIZE BILL
  // ===========================================================================
  Future<String> finalizeBill({
    required String billNo,
    required List<Sale> items,
    required String? customerId,
    required String? salespersonId,
    required bool isPaidFully,
    required double totalPaid,
  }) async {
    if (billNo.isEmpty) throw Exception("Bill number missing.");
    if (items.isEmpty) throw Exception("Cannot finalize empty bill.");

    try {
      // ---------- TOTALS ----------
      double subTotal = 0;
      double totalDiscount = 0;

      for (final item in items) {
        subTotal += item.sellingRate * item.quantity;
        totalDiscount += item.discountPerPiece * item.quantity;
      }

      double finalTotal = subTotal - totalDiscount;
      double adjustedPaid = totalPaid > finalTotal ? finalTotal : totalPaid;

      bool isFullyPaidFinal =
      isPaidFully ? true : adjustedPaid >= finalTotal;

      // ---------- BILL HEADER ----------
      final billRow = await _client.from('bills').insert({
        'bill_no': billNo,
        'customer_id': customerId,
        'salesperson_id': salespersonId ?? Supabase.instance.client.auth.currentUser!.id,
        'total_items': items.length,
        'sub_total': subTotal,
        'total_discount': totalDiscount,
        'total': finalTotal,
        'total_paid': adjustedPaid,
        'is_fully_paid': isFullyPaidFinal,
      }).select().single();

      final String billId = billRow['id'];

      // ---------- SALES ITEMS ----------
      for (final item in items) {
        final saleMap = {
          'bill_id': billId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'selling_rate': item.sellingRate,
          'discount_per_piece': item.discountPerPiece,
          'sold_at': DateTime.now().toIso8601String(),
        };

        await _client.from("sales").insert(saleMap);

        // ---------- STOCK RPC ----------
        final stockRes = await _client.rpc(
          'decrease_product_stock',
          params: {
            'p_product_id': item.productId,
            'p_qty': item.quantity,
          },
        );

        // Supabase RPC often returns integer, so check only null:
        if (stockRes == null) {
          throw Exception("Stock RPC failed for ${item.productId}");
        }
      }

      // ---------- DEBT HANDLING ----------
      if (!isFullyPaidFinal && customerId != null) {
        double pending = finalTotal - adjustedPaid;

        await _client.from('customer_debts').insert({
          'customer_id': customerId,
          'bill_id': billId,
          'debt_amount': pending,
          'paid_amount': 0,
          'remaining_amount': pending,
        });
      }

      return billId;
    } catch (e, stack) {
      print("❌ finalizeBill ERROR: $e");
      print(stack);
      throw Exception("Checkout failed: $e");
    }
  }


  // ===========================================================================
  // FETCH BILL ITEMS
  // ===========================================================================
  Future<List<Sale>> getBillItems(String billId) async {
    try {
      final response = await _client
          .from('sales')
          .select('*, products(name, barcode)')
          .eq('bill_id', billId);

      return response.map<Sale>((row) {
        return Sale.fromMap({
          ...row,
          'product_name': row['products']?['name'],
          'barcode': row['products']?['barcode'],
        });
      }).toList();
    } catch (e) {
      print("❌ getBillItems error: $e");
      SnackBar(content: Text("❌ Error loading bill items: $e"));
      rethrow;
    }
  }

  // ===========================================================================
  // PRODUCT SALE SUMMARY
  // ===========================================================================
  Future<Map<String, dynamic>> getProductSaleSummary(String productId) async {
    try {
      final res = await _client.rpc(
        'get_product_sales_summary',
        params: {'p_product_id': productId},
      );

      return {
        'total_sold': res?['total_sold'] ?? 0,
        'total_revenue': (res?['total_revenue'] ?? 0).toDouble(),
        'total_profit': (res?['total_profit'] ?? 0).toDouble(),
      };

    } catch (e) {
      print("❌ getProductSaleSummary error: $e");
      SnackBar(content: Text("❌ Error: $e"));
      return {
        'total_sold': 0,
        'total_revenue': 0.0,
        'total_profit': 0.0,
      };
    }
  }

  // ===========================================================================
  // SALES OF LAST N DAYS
  // ===========================================================================
  Future<List<Sale>> getSalesOfLastDays(int days) async {
    try {
      final response = await _client
          .from('sales')
          .select('*, products(name, barcode)')
          .gte(
        'sold_at',
        DateTime.now().subtract(Duration(days: days)).toIso8601String(),
      )
          .order('sold_at', ascending: false);

      return response.map<Sale>((row) {
        return Sale.fromMap({
          ...row,
          'product_name': row['products']?['name'],
          'barcode': row['products']?['barcode'],
        });
      }).toList();

    } catch (e) {
      print("❌ getSalesOfLastDays error: $e");
      SnackBar(content: Text("❌ Failed: $e"));
      rethrow;
    }
  }
}
