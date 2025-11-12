import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Category>> fetchCategories() async {
    final response = await _client.from('categories').select();
    return (response as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }

  Future<void> addCategory(Category category) async {
    await _client.from('categories').insert(category.toJson());
  }

  Future<void> updateCategory(String id, Category category) async {
    await _client.from('categories').update(category.toJson()).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
