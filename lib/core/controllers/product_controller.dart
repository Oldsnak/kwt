// lib/core/controllers/product_controller.dart

import 'package:get/get.dart';
import 'package:kwt/core/services/product_service.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();

  /// All products (with analytics)
  RxList<Product> products = <Product>[].obs;

  /// Filtered list (dashboard)
  RxList<Product> filteredProducts = <Product>[].obs;

  /// Loaders
  RxBool isLoading = false.obs;

  /// Search & category filters
  String _searchQuery = "";
  final RxnString selectedCategoryId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProducts();

    /// when products update → re-filter
    ever(products, (_) => _applyFilters());
  }

  // ---------------------------------------------------------------------------
  // LOAD ALL PRODUCTS WITH ANALYTICS (ONLY ONCE)
  // ---------------------------------------------------------------------------
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      final list = await _service.fetchProducts(); // analytics included
      products.assignAll(list);

      _applyFilters();

    } catch (e) {
      print("❌ loadProducts error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH FILTER
  // ---------------------------------------------------------------------------
  void updateSearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // ---------------------------------------------------------------------------
  // CATEGORY FILTER
  // ---------------------------------------------------------------------------
  void filterByCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilters();
  }

  // ---------------------------------------------------------------------------
  // APPLY FILTERS (SEARCH + CATEGORY)
  // ---------------------------------------------------------------------------
  void _applyFilters() {
    List<Product> list = List<Product>.from(products);

    // CATEGORY FILTER
    final catId = selectedCategoryId.value;
    if (catId != null && catId.isNotEmpty) {
      list = list.where((p) => p.categoryId == catId).toList();
    }

    // SEARCH FILTER
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
      p.name.toLowerCase().contains(_searchQuery) ||
          (p.categoryName ?? "").toLowerCase().contains(_searchQuery) ||
          p.barcode.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    filteredProducts.assignAll(list);
  }

  // ---------------------------------------------------------------------------
  // ADD / UPDATE / DELETE
  // ---------------------------------------------------------------------------
  Future<void> addProduct(Product p) async {
    try {
      await _service.addNewProduct(
        name: p.name,
        categoryId: p.categoryId!,
        purchaseRate: p.purchaseRate,
        sellingRate: p.sellingRate,
        stockQuantity: p.stockQuantity,
        barcode: p.barcode,
      );

      await loadProducts();
    } catch (e) {
      print("❌ addProduct error: $e");
    }
  }

  Future<void> updateProduct(String id, Product p) async {
    try {
      await _service.updateProduct(id, p);
      await loadProducts();
    } catch (e) {
      print("❌ updateProduct error: $e");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      products.removeWhere((x) => x.id == id);
      _applyFilters();
    } catch (e) {
      print("❌ deleteProduct error: $e");
    }
  }
}
