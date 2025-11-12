import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    final response = await _client.from('products').select('*, categories(*)');
    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('category_id', categoryId);
    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    await _client.from('products').insert(product.toJson());
  }

  Future<void> updateProduct(String id, Product product) async {
    await _client.from('products').update(product.toJson()).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
