// lib/core/controllers/product_controller.dart

import 'package:get/get.dart';
import 'package:kwt/core/services/product_service.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();

  /// All products for dashboard + analytics
  final RxList<Product> products = <Product>[].obs;

  /// Filtered products (after category + search)
  final RxList<Product> filteredProducts = <Product>[].obs;

  /// Loader
  final RxBool isLoading = false.obs;

  /// Filters
  String _searchQuery = "";
  final RxnString selectedCategoryId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProducts();

    /// Jab products refresh hote hain → filters apply
    ever(products, (_) => _applyFilters());
  }

  // ===========================================================================
  // LOAD ALL PRODUCTS (with analytics from Supabase)
  // ===========================================================================
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      final list = await _service.fetchProducts();
      products.assignAll(list);

      _applyFilters();
    } catch (e) {
      print("❌ ProductController.loadProducts error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================
  void updateSearch(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
  }

  // ===========================================================================
  // CATEGORY FILTER
  // ===========================================================================
  void filterByCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilters();
  }

  // ===========================================================================
  // APPLY FILTERS
  // ===========================================================================
  void _applyFilters() {
    List<Product> list = List<Product>.from(products);

    final cat = selectedCategoryId.value;
    if (cat != null && cat.isNotEmpty) {
      list = list.where((p) => p.categoryId == cat).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final name = p.name.toLowerCase();
        final catName = (p.categoryName ?? "").toLowerCase();
        final barcode = p.barcode.toLowerCase();

        return name.contains(_searchQuery) ||
            catName.contains(_searchQuery) ||
            barcode.contains(_searchQuery);
      }).toList();
    }

    filteredProducts.assignAll(list);
  }

  // ===========================================================================
  // CRUD: ADD PRODUCT
  // ===========================================================================
  Future<bool> addProduct(Product p) async {
    try {
      final id = await _service.addNewProduct(
        name: p.name,
        categoryId: p.categoryId!,
        purchaseRate: p.purchaseRate,
        sellingRate: p.sellingRate,
        stockQuantity: p.stockQuantity,
        barcode: p.barcode,
      );

      if (id.isNotEmpty) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ addProduct error: $e");
      return false;
    }
  }

  // ===========================================================================
  // UPDATE PRODUCT
  // ===========================================================================
  Future<bool> updateProduct(String id, Product p) async {
    try {
      await _service.updateProduct(id, p);
      await loadProducts();
      return true;
    } catch (e) {
      print("❌ updateProduct error: $e");
      return false;
    }
  }

  // ===========================================================================
  // DELETE PRODUCT
  // ===========================================================================
  Future<bool> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      products.removeWhere((x) => x.id == id);
      _applyFilters();
      return true;
    } catch (e) {
      print("❌ deleteProduct error: $e");
      return false;
    }
  }
}
