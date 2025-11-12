// lib/features/core_controllers/product_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/product_service.dart';

import '../models/product_model.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();

  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final res = await _service.fetchProducts();
      products.value = res;
    } catch (e) {
      // handle or forward error
      print('ProductController.loadAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadByCategory(String categoryId) async {
    try {
      isLoading.value = true;
      final res = await _service.fetchProductsByCategory(categoryId);
      products.value = res;
    } catch (e) {
      print('ProductController.loadByCategory error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product p) async {
    await _service.addProduct(p);
    await loadAll();
  }

  Future<void> updateProduct(String id, Product p) async {
    await _service.updateProduct(id, p);
    await loadAll();
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    products.removeWhere((x) => x.id == id);
  }
  /// 🟢 Dashboard reactive filters
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxString searchQuery = ''.obs;
  final RxnString selectedCategoryId = RxnString();

  @override
  void onReady() {
    super.onReady();
    ever(products, (_) => _applyFilters());
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<Product>.from(products);

    final catId = selectedCategoryId.value;
    if (catId != null && catId.isNotEmpty) {
      list = list.where((p) => p.categoryId == catId).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    filteredProducts.assignAll(list);
  }

}
