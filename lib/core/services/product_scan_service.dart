// lib/core/services/product_scan_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class ProductScanService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch a single product by its barcode.
  ///
  /// Used on Sell Page when salesperson scans a product.
  /// Returns `Product` if found, otherwise `null`.
  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    final response = await _client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;

    return Product.fromMap(response);
  }

  /// Fetch product by its id.
  ///
  /// Useful when you already have product_id from sales/stock tables
  /// and want to show product detail.
  Future<Product?> getProductById(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();

    if (response == null) return null;

    return Product.fromMap(response);
  }

  /// Search products by name (for search box on dashboard / add item popup).
  ///
  /// This is optional but very handy for:
  /// - search bar on Dashboard
  /// - manual item selection when barcode not available.
  Future<List<Product>> searchProductsByName(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final response = await _client
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .eq('is_active', true)
        .order('name');

    return response.map<Product>((row) => Product.fromMap(row)).toList();
  }
}
