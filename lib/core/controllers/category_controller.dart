// lib/core/controllers/category_controller.dart

import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {
  final CategoryService _service = CategoryService();

  /// All categories loaded from Supabase
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  /// Active loading state
  final RxBool isLoading = false.obs;

  /// Selected category for filtering products in dashboard
  /// null = "All categories"
  final RxnString selectedCategoryId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  // ===========================================================================
  // LOAD CATEGORIES (Safe + Error-Handled + RLS Compliant)
  // ===========================================================================
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;

      final list = await _service.fetchCategories();
      categories.assignAll(list);
    } catch (e) {
      print("❌ CategoryController.loadCategories error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // ADD CATEGORY
  // ===========================================================================
  Future<bool> addCategory(CategoryModel c) async {
    try {
      await _service.addCategory(c);
      await loadCategories();
      return true;
    } catch (e) {
      print("❌ CategoryController.addCategory error: $e");
      return false;
    }
  }

  // ===========================================================================
  // UPDATE CATEGORY
  // ===========================================================================
  Future<bool> updateCategory(String id, CategoryModel c) async {
    try {
      await _service.updateCategory(id, c);
      await loadCategories();
      return true;
    } catch (e) {
      print("❌ CategoryController.updateCategory error: $e");
      return false;
    }
  }

  // ===========================================================================
  // DELETE CATEGORY
  // ===========================================================================
  Future<bool> removeCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      categories.removeWhere((x) => x.id == id);
      return true;
    } catch (e) {
      print("❌ CategoryController.removeCategory error: $e");
      return false;
    }
  }

  // ===========================================================================
  // SELECT CATEGORY FOR DASHBOARD FILTER
  // ===========================================================================
  void selectCategory(String? id) {
    selectedCategoryId.value = id; // null = show all items
  }
}
