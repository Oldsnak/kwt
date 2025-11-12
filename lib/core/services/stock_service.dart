// lib/core/services/stock_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StockService {
  final SupabaseClient _client = SupabaseService.client;

  // Insert a stock entry and update product stock + rates
  Future<void> addStock({
    required String productId,
    required int quantity,
    required double purchaseRate,
    required double sellingRate,
  }) async {
    final nowDate = DateTime.now().toIso8601String();

    // 1) Insert stock entry
    await _client.from('stock_entries').insert({
      'product_id': productId,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'received_date': nowDate,
    });

    // 2) Read current product, compute new stock and update product
    final prodRes = await _client.from('products').select().eq('id', productId).single();
    if (prodRes != null) {
      final int currentStock = (prodRes['stock_quantity'] ?? 0) as int;
      final int newStock = currentStock + quantity;

      await _client.from('products').update({
        'stock_quantity': newStock,
        'purchase_rate': purchaseRate,
        'selling_rate': sellingRate,
      }).eq('id', productId);
    } else {
      // Optional: create product if not exists - or throw
      throw Exception('Product not found for id: $productId');
    }
  }

  Future<List<Map<String, dynamic>>> getStockHistory(String productId) async {
    final res = await _client
        .from('stock_entries')
        .select()
        .eq('product_id', productId)
        .order('received_date', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<int> getCurrentStock(String productId) async {
    final prod = await _client.from('products').select('stock_quantity').eq('id', productId).maybeSingle();
    if (prod == null) return 0;
    return (prod['stock_quantity'] as num).toInt();
  }
}
