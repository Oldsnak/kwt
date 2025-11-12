// lib/core/services/product_scan_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ProductScanService {
  final SupabaseClient _client = SupabaseService.client;

  /// Call this with scanned barcode string.
  /// It tries to find product by barcode and adds to cart (1 qty by default).
  Future<Map<String, dynamic>?> addScannedProductToCart(String barcode, {int qty = 1, double discountPerPiece = 0}) async {
    try {
      final product = await _client.from('products').select().eq('barcode', barcode).maybeSingle();
      if (product == null) return null;

      final prodMap = Map<String, dynamic>.from(product as Map);
      final productId = prodMap['id'] as String;

      final totalAmount = ((prodMap['selling_rate'] as num).toDouble() * qty) - (discountPerPiece * qty);

      final inserted = await _client.from('cart').insert({
        'product_id': productId,
        'quantity': qty,
        'discount_per_piece': discountPerPiece,
        'total_amount': totalAmount,
      }).select().single();

      return Map<String, dynamic>.from(inserted);
    } catch (e) {
      print('ProductScanService error: $e');
      rethrow;
    }
  }

  // helper: find product by barcode
  Future<Map<String, dynamic>?> findProductByBarcode(String barcode) async {
    final res = await _client.from('products').select().eq('barcode', barcode).maybeSingle();
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }
}
