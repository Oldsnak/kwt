// lib/core/services/sales_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../services/supabase_service.dart';

class SalesService {
  final SupabaseClient _client = SupabaseService.client;

  /// ✅ Fetch all sales, optionally filtered by salesperson
// lib/core/services/sales_service.dart (only fetchSales shown)
  Future<List<Sale>> fetchSales({String? salespersonId}) async {
    // 1) fetch all sales rows from Supabase
    final response = await _client.from('sales').select();

    if (response == null) return <Sale>[];

    // ensure we have a List
    final List rows = response is List ? response : [response];

    // 2) optional client-side filter by salespersonId
    Iterable<Map<String, dynamic>> filtered = rows.cast<Map<String, dynamic>>();
    if (salespersonId != null && salespersonId.isNotEmpty) {
      filtered = filtered.where((r) => (r['salesperson_id'] ?? '') == salespersonId);
    }

    // 3) client-side sort by created_at desc (if field exists)
    final List<Map<String, dynamic>> finalList = filtered.map((e) => Map<String, dynamic>.from(e)).toList();
    finalList.sort((a, b) {
      final aTime = a['created_at'] == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(a['created_at'].toString());
      final bTime = b['created_at'] == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(b['created_at'].toString());
      return bTime.compareTo(aTime); // descending
    });

    // 4) map to Sale models and return
    return finalList.map((row) => Sale.fromJson(row)).toList();
  }






  /// ✅ Finalize bill: convert cart items into sales rows, decrement product stock, and return bill meta
  Future<Map<String, dynamic>> finalizeBill({
    required String? customerId,
    required String? salespersonId,
    required double totalPaid,
    required bool isPaid,
  }) async {
    // 1) Fetch cart items
    final cartRes = await _client.from('cart').select();
    final List cartItems = (cartRes as List<dynamic>?) ?? [];

    if (cartItems.isEmpty) throw Exception('Cart is empty');

    // 2) Insert each into sales and update product stock
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

      final inserted =
      await _client.from('sales').insert(saleMap).select().single();
      insertedSales.add(inserted);

      // Decrement product stock
      final prodRes =
      await _client.from('products').select().eq('id', productId).single();
      if (prodRes != null) {
        final int cur = (prodRes['stock_quantity'] ?? 0) as int;
        final int newStock = cur - qty;
        await _client
            .from('products')
            .update({'stock_quantity': newStock}).eq('id', productId);
      }
    }

    // 3) Clear cart
    await _client.from('cart').delete();

    // 4) Compose bill meta
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
