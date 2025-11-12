// lib/features/core_controllers/category_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/category_service.dart';

import '../models/category_model.dart';

class CategoryController extends GetxController {
  final CategoryService _service = CategoryService();

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      final res = await _service.fetchCategories();
      categories.value = res;
    } catch (e) {
      print('CategoryController.load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> add(Category c) async {
    await _service.addCategory(c);
    await load();
  }

  Future<void> updateCategory(String id, Category c) async {
    await _service.updateCategory(id, c);
    await load();
  }

  Future<void> remove(String id) async {
    await _service.deleteCategory(id);
    categories.removeWhere((x) => x.id == id);
  }

  final RxnString selectedCategoryId = RxnString();

  void selectCategory(String? id) {
    selectedCategoryId.value = id;
  }

}
