// lib/core/services/sales_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SalesService {
  final SupabaseClient _client = SupabaseService.client;

  // Finalize bill: convert cart items into sales rows, decrement product stock, return bill meta
  Future<Map<String, dynamic>> finalizeBill({
    required String? customerId,
    required String? salespersonId,
    required double totalPaid,
    required bool isPaid,
  }) async {
    // 1) fetch cart items (no .execute())
    final cartRes = await _client.from('cart').select();
    final List cartItems = (cartRes as List<dynamic>?) ?? [];

    if (cartItems.isEmpty) throw Exception('Cart is empty');

    // 2) insert each into sales and update product stock
    List insertedSales = [];
    for (final item in cartItems) {
      final productId = item['product_id'] as String;
      final qty = (item['quantity'] as num).toInt();
      final discountPerPiece = (item['discount_per_piece'] ?? 0) as num;
      final total = (item['total_amount'] as num).toDouble();

      final saleMap = {
        'product_id': productId,
        'quantity': qty,
        'discount_per_piece': discountPerPiece,
        'total_amount': total,
        'salesperson_id': salespersonId,
        'customer_id': customerId,
      };

      final inserted = await _client.from('sales').insert(saleMap).select().single();
      insertedSales.add(inserted);

      // decrement product stock: read -> compute -> update
      final prodRes = await _client.from('products').select().eq('id', productId).single();
      if (prodRes != null) {
        final int cur = (prodRes['stock_quantity'] ?? 0) as int;
        final int newStock = cur - qty;
        await _client.from('products').update({'stock_quantity': newStock}).eq('id', productId);
      }
    }

    // 3) clear cart
    await _client.from('cart').delete();

    // 4) Compose bill meta (you can also store in a bills table)
    final billMeta = {
      'items_count': cartItems.length,
      'total_paid': totalPaid,
      'is_paid': isPaid,
      'sales_generated': insertedSales.length,
      'sales': insertedSales,
      'created_at': DateTime.now().toIso8601String(),
    };

    return billMeta;
  }
}
