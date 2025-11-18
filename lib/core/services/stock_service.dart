// lib/core/services/stock_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stock_entry_model.dart';
import '../models/product_model.dart';

class StockService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // ADD NEW STOCK FOR A PRODUCT
  //
  // RULE (your requirement):
  // 1. Insert a new row in stock_entries (batch history)
  // 2. Update product table:
  //      - stock_quantity += new quantity
  //      - purchase_rate  = latest batch purchase_rate
  //      - selling_rate   = latest batch selling_rate
  // ===========================================================================

  Future<void> addStock({
    required String productId,
    required int quantity,
    required double purchaseRate,
    required double sellingRate,
    required DateTime receivedDate,
  }) async {
    // -------------------------
    // Insert into stock_entries
    // -------------------------
    await _client.from('stock_entries').insert({
      'product_id': productId,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'received_date': receivedDate.toIso8601String(),
    });

    // -------------------------
    // Update product
    // -------------------------
    await _client.rpc(
      'increase_product_stock',
      params: {
        'p_product_id': productId,
        'p_qty': quantity,
        'p_purchase_rate': purchaseRate,
        'p_selling_rate': sellingRate,
      },
    );
  }

  // ===========================================================================
  // GET FULL STOCK HISTORY OF A PRODUCT (Latest First)
  // ===========================================================================

  Future<List<StockEntry>> getStockHistory(String productId) async {
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
  }

  // ===========================================================================
  // GET PRODUCT WITH LIVE STOCK FROM products TABLE
  // ===========================================================================

  Future<Product?> getProduct(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromMap(response);
  }

  // ===========================================================================
  // GET TOTAL STOCK VALUE (purchase_value & selling_value)
  // Useful for analytics or future dashboard features.
  // ===========================================================================

  Future<Map<String, double>> getProductStockValue(String productId) async {
    final product = await getProduct(productId);

    if (product == null) {
      return {
        'purchase_value': 0.0,
        'selling_value': 0.0,
      };
    }

    final purchaseValue = product.stockQuantity * product.purchaseRate;
    final sellingValue = product.stockQuantity * product.sellingRate;

    return {
      'purchase_value': purchaseValue.toDouble(),
      'selling_value': sellingValue.toDouble(),
    };
  }
}
