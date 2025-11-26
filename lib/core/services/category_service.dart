// lib/core/services/category_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import 'package:flutter/material.dart';

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
      SnackBar(content:Text("❌ CategoryService.fetchCategories ERROR: $e"),);
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
      SnackBar(content:Text("❌ CategoryService.addCategory ERROR: $e"),);
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
      SnackBar(content:Text("❌ CategoryService.updateCategory ERROR: $e"),);
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
      SnackBar(content:Text("❌ CategoryService.deleteCategory ERROR: $e"),);
      rethrow;
    }
  }
}
