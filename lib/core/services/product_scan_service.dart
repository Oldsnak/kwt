// lib/core/services/product_scan_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'package:flutter/material.dart';

class ProductScanService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // FETCH PRODUCT BY BARCODE (Sell Page Scan)
  // ===========================================================================
  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    try {
      // print("📦 DB QUERY BARCODE → '$barcode'");
      final response = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .eq('is_active', true)
          .maybeSingle();
      // print("📦 DB RESPONSE ROW → $response");

      if (response == null) return null;

      return Product.fromMap(response);
    } catch (e) {
      SnackBar(content:Text("❌ getProductByBarcode ERROR: $e"),);
      return null; // salesperson should not see errors
    }
  }

  // ===========================================================================
  // FETCH PRODUCT BY ID (used in stock/sales lookup)
  // ===========================================================================
  Future<Product?> getProductById(String productId) async {
    if (productId.trim().isEmpty) return null;

    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      return Product.fromMap(response);
    } catch (e) {
      SnackBar(content:Text("❌ getProductById ERROR: $e"),);
      return null;
    }
  }

  // ===========================================================================
  // SEARCH PRODUCTS BY NAME (Dashboard search / Add Item Popup)
  // ===========================================================================
  Future<List<Product>> searchProductsByName(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .order('name');

      return response
          .map<Product>((row) => Product.fromMap(row))
          .toList();
    } catch (e) {
      SnackBar(content:Text("❌ searchProductsByName ERROR: $e"),);
      return [];
    }
  }
}
