// lib/core/controllers/category_controller.dart
import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {
  final CategoryService _service = CategoryService();

  /// All categories
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  /// Loading flag
  final RxBool isLoading = false.obs;

  /// Selected category for dashboard filter
  final RxnString selectedCategoryId = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ===========================================================================
  // LOAD CATEGORIES
  // ===========================================================================
  Future<void> load() async {
    try {
      isLoading.value = true;
      final List<CategoryModel> res = await _service.fetchCategories();
      categories.assignAll(res);
    } catch (e) {
      print("❌ CategoryController.load error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // CRUD OPERATIONS
  // ===========================================================================
  Future<void> add(CategoryModel c) async {
    try {
      await _service.addCategory(c);
      await load();
    } catch (e) {
      print("❌ CategoryController.add error: $e");
    }
  }

  Future<void> updateCategory(String id, CategoryModel c) async {
    try {
      await _service.updateCategory(id, c);
      await load();
    } catch (e) {
      print("❌ CategoryController.updateCategory error: $e");
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.deleteCategory(id);
      categories.removeWhere((x) => x.id == id);
    } catch (e) {
      print("❌ CategoryController.remove error: $e");
    }
  }

  // ===========================================================================
  // SELECT CATEGORY FOR DASHBOARD
  // ===========================================================================
  void selectCategory(String? id) {
    selectedCategoryId.value = id; // ← null means "All"
  }
}
