// lib/core/services/category_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // FETCH ALL CATEGORIES
  // ===========================================================================
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final List<dynamic> response =
      await _client.from('categories').select().order('name');

      return response
          .map((json) => CategoryModel.fromMap(json))
          .toList();
    } catch (e) {
      print("❌ CategoryService.fetchCategories error: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // ADD CATEGORY
  // ===========================================================================
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _client.from('categories').insert(category.toMap());
    } catch (e) {
      print("❌ CategoryService.addCategory error: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // UPDATE CATEGORY
  // ===========================================================================
  Future<void> updateCategory(String id, CategoryModel category) async {
    try {
      await _client
          .from('categories')
          .update(category.toMap())
          .eq('id', id);
    } catch (e) {
      print("❌ CategoryService.updateCategory error: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // DELETE CATEGORY
  // ===========================================================================
  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      print("❌ CategoryService.deleteCategory error: $e");
      rethrow;
    }
  }
}
