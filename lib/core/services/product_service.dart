import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // FETCH ALL PRODUCTS (JOIN FIXED FOR SUPABASE V2)
  // ===========================================================================
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('''
          *,
          categories(name),
          sales (
            quantity,
            selling_rate,
            discount_per_piece,
            sold_at
          )
        ''')
          .order('created_at', ascending: false);

      return response.map<Product>((row) {
        final sales = row['sales'] as List<dynamic>? ?? [];

        int totalSold = 0;
        double totalProfit = 0;

        for (final s in sales) {
          final qty = (s['quantity'] as num?)?.toInt() ?? 0;
          final sellRate = (s['selling_rate'] as num?)?.toDouble() ?? 0;
          final disc = (s['discount_per_piece'] as num?)?.toDouble() ?? 0;

          // Purchase rate ALWAYS comes from product table
          final purchase = (row['purchase_rate'] as num?)?.toDouble() ?? 0;

          final profitPerItem = (sellRate - disc) - purchase;

          totalSold += qty;
          totalProfit += profitPerItem * qty;
        }

        double avgProfit = totalSold > 0 ? totalProfit / totalSold : 0;

        return Product.fromMap({
          ...row,
          "category_name": row["categories"]?["name"],
          "total_sold": totalSold,
          "total_profit": totalProfit,
          "avg_profit": avgProfit,
        });
      }).toList();
    } catch (e) {
      print("❌ fetchProducts ERROR: $e");
      throw Exception("Unable to load products: $e");
    }
  }


  // ===========================================================================
  // FETCH PRODUCTS BY CATEGORY
  // ===========================================================================
  Future<List<Product>> fetchProductsByCategory(String id) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category_id', id);

      return response.map<Product>((row) => Product.fromMap(row)).toList();
    } catch (e) {
      print("❌ fetchProductsByCategory ERROR: $e");
      throw Exception("Unable to load category-wise products: $e");
    }
  }


  // ===========================================================================
  // ADD NEW PRODUCT
  // ===========================================================================
  Future<String> addNewProduct({
    required String name,
    required String categoryId,
    required double purchaseRate,
    required double sellingRate,
    required int stockQuantity,
    required String barcode,
  }) async {
    try {
      final existing = await _client
          .from('products')
          .select('id')
          .eq('barcode', barcode)
          .maybeSingle();

      if (existing != null) {
        throw Exception("Barcode already exists.");
      }

      final response = await _client
          .from('products')
          .insert({
        'name': name,
        'category_id': categoryId,
        'purchase_rate': purchaseRate,
        'selling_rate': sellingRate,
        'stock_quantity': stockQuantity,
        'barcode': barcode,
      })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      print("❌ addNewProduct ERROR: $e");
      throw Exception("Failed to add product: $e");
    }
  }


  // ===========================================================================
  // FIND PRODUCT BY BARCODE
  // ===========================================================================
  Future<Product?> findByBarcode(String barcode) async {
    try {
      final res = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (res == null) return null;
      return Product.fromMap(res);
    } catch (e) {
      print("❌ findByBarcode ERROR: $e");
      return null;
    }
  }


  // ===========================================================================
  // BARCODE GENERATOR
  // ===========================================================================
  String generateBarcode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ===========================================================================
  // UPDATE PRODUCT
  // ===========================================================================
  Future<void> updateProduct(String id, Product p) async {
    try {
      await _client.from('products').update(p.toMap()).eq('id', id);
    } catch (e) {
      print("❌ updateProduct ERROR: $e");
      throw Exception("Failed to update product: $e");
    }
  }


  // ===========================================================================
  // DELETE PRODUCT
  // ===========================================================================
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      print("❌ deleteProduct ERROR: $e");
      throw Exception("Failed to delete product: $e");
    }
  }

}
