import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_entry_model.dart';
import '../models/product_model.dart';
import 'package:flutter/material.dart';

class StockService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // ADD STOCK — SAFE VERSION (OWNER ONLY — RLS protected)
  // ===========================================================================
  Future<void> addStock({
    required String productId,
    required int quantity,
    required double purchaseRate,
    required double sellingRate,
    required DateTime receivedDate,
  }) async {
    if (quantity <= 0) {
      throw Exception("Quantity must be greater than zero.");
    }

    try {
      // Ensure only OWNER can add stock (RLS restriction)
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception("Not authenticated.");

      // Check role directly from user_profiles
      final role = await _client
          .from("user_profiles")
          .select("role")
          .eq("id", uid)
          .maybeSingle();

      if (role == null || role['role'] != 'owner') {
        throw Exception("Only owner can add stock.");
      }

      // Fetch current stock
      final product = await _client
          .from('products')
          .select('stock_quantity')
          .eq('id', productId)
          .maybeSingle();

      if (product == null) {
        throw Exception("Product not found.");
      }

      final currentQty = (product['stock_quantity'] ?? 0) as int;
      final newQty = currentQty + quantity;

      // ------------------------------------------
      // Insert stock entry
      // ------------------------------------------
      await _client.from('stock_entries').insert({
        'product_id': productId,
        'quantity': quantity,
        'purchase_rate': purchaseRate,
        'selling_rate': sellingRate,
        'received_date': receivedDate.toIso8601String(),
      });

      // ------------------------------------------
      // Update product stock levels
      // ------------------------------------------
      await _client
          .from('products')
          .update({
        'stock_quantity': newQty,
        'purchase_rate': purchaseRate,
        'selling_rate': sellingRate,
      })
          .eq('id', productId);

    } catch (e) {
      print("❌ StockService.addStock ERROR: $e");
      throw Exception("Stock update failed: $e");
    }
  }


  // ===========================================================================
  // GET STOCK HISTORY — For Owner + Salesperson (RLS handles restrictions)
  // ===========================================================================
  Future<List<StockEntry>> getStockHistory(String productId) async {
    try {
      final response = await _client
          .from('stock_entries')
          .select('*, products(name, barcode)')
          .eq('product_id', productId)
          .order('received_date', ascending: false);

      return response.map<StockEntry>((row) {
        return StockEntry.fromMap({
          ...row,
          'product_name': row['products']?['name'],
          'barcode': row['products']?['barcode'],
        });
      }).toList();

    } catch (e) {
      print("❌ getStockHistory ERROR: $e");
      throw Exception("Unable to load stock history: $e");
    }
  }


  // ===========================================================================
  // GET PRODUCT WITH LIVE STOCK
  // ===========================================================================
  Future<Product?> getProduct(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromMap(response);

    } catch (e) {
      print("❌ getProduct ERROR: $e");
      return null;
    }
  }


  // ===========================================================================
  // CALCULATE TOTAL STOCK VALUE (purchase & selling)
  // ===========================================================================
  Future<Map<String, double>> getProductStockValue(String productId) async {
    try {
      final p = await getProduct(productId);

      if (p == null) {
        return {
          'purchase_value': 0.0,
          'selling_value': 0.0,
        };
      }

      return {
        'purchase_value': (p.stockQuantity * p.purchaseRate).toDouble(),
        'selling_value': (p.stockQuantity * p.sellingRate).toDouble(),
      };

    } catch (e) {
      print("❌ getProductStockValue ERROR: $e");
      return {
        'purchase_value': 0.0,
        'selling_value': 0.0,
      };
    }
  }

}
