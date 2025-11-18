// lib/core/controllers/product_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/product_service.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();

  /// All products fetched from DB
  final RxList<Product> products = <Product>[].obs;

  /// Dashboard filtered list
  final RxList<Product> filteredProducts = <Product>[].obs;

  /// For loader
  final RxBool isLoading = false.obs;

  /// Search and category filters
  final RxString searchQuery = ''.obs;
  final RxnString selectedCategoryId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();

    /// whenever `products` changes → apply filters again
    ever(products, (_) => _applyFilters());
  }

  // ===========================================================================
  // LOAD ALL PRODUCTS
  // ===========================================================================
  Future<void> loadAll() async {
    try {
      isLoading.value = true;

      final res = await _service.fetchProducts(); // full product list
      products.assignAll(res);

    } catch (e) {
      print("❌ ProductController.loadAll error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // LOAD PRODUCTS BY CATEGORY
  // ===========================================================================
  Future<void> loadByCategory(String categoryId) async {
    try {
      isLoading.value = true;

      final res = await _service.fetchProductsByCategory(categoryId);
      products.assignAll(res);

    } catch (e) {
      print("❌ ProductController.loadByCategory error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // ADD / UPDATE / DELETE PRODUCT
  // ===========================================================================
  Future<void> addProduct(Product p) async {
    try {
      await _service.addNewProduct(
        name: p.name,
        categoryId: p.categoryId!,
        purchaseRate: p.purchaseRate,
        sellingRate: p.sellingRate,
        stockQuantity: p.stockQuantity ?? 0,
        barcode: p.barcode,
      );

      await loadAll();
    } catch (e) {
      print("❌ addProduct error: $e");
    }
  }

  Future<void> updateProduct(String id, Product p) async {
    try {
      await _service.updateProduct(id, p);
      await loadAll();
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

  // ===========================================================================
  // DASHBOARD FILTER LOGIC (FINAL)
  // ===========================================================================
  void updateSearch(String query) {
    searchQuery.value = query.trim().toLowerCase();
    _applyFilters();
  }

  void filterByCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> list = List<Product>.from(products);

    // CATEGORY FILTER
    final catId = selectedCategoryId.value;
    if (catId != null && catId.isNotEmpty) {
      list = list.where((p) => p.categoryId == catId).toList();
    }

    // SEARCH FILTER
    final query = searchQuery.value;
    if (query.isNotEmpty) {
      list = list.where(
            (p) => p.name.toLowerCase().contains(query),
      ).toList();
    }

    filteredProducts.assignAll(list);
  }
}
