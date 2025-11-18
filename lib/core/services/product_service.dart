import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'dart:math';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    final response = await _client
        .from('products')
        .select('*, categories(name)')
        .order('created_at', ascending: false);

    return response.map<Product>((row) {
      return Product.fromMap({
        ...row,
        'category_name': row['categories']?['name'],
      });
    }).toList();
  }

  Future<List<Product>> fetchProductsByCategory(String id) async {
    final response = await _client
        .from('products')
        .select()
        .eq('category_id', id);

    return response.map<Product>((row) => Product.fromMap(row)).toList();
  }

  Future<String> addNewProduct({
    required String name,
    required String categoryId,
    required double purchaseRate,
    required double sellingRate,
    required int stockQuantity,
    required String barcode,
  }) async {
    final data = {
      'name': name,
      'category_id': categoryId,
      'purchase_rate': purchaseRate,
      'selling_rate': sellingRate,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
    };

    final response =
    await _client.from('products').insert(data).select().single();

    return response['id'];
  }

  Future<Product?> findByBarcode(String barcode) async {
    final res = await _client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();

    if (res == null) return null;

    return Product.fromMap(res);
  }

  String generateBarcode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> updateProduct(String id, Product p) async {
    await _client.from('products').update(p.toMap()).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
