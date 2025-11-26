// lib/core/controllers/add_product_controller.dart

import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';
import '../services/stock_service.dart';
import '../services/category_service.dart';

class AddProductController extends GetxController {
  final ProductService _productService = ProductService();
  final StockService _stockService = StockService();
  final CategoryService _categoryService = CategoryService();

  // categories list
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  // selected category
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);

  // state
  final RxBool isLoadingCategories = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  // --------------------------------------------------------------------------
  // LOAD CATEGORIES (safe with RLS + error handling)
  // --------------------------------------------------------------------------
  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      errorMessage.value = '';

      final list = await _categoryService.fetchCategories();
      categories.assignAll(list);

    } catch (e) {
      errorMessage.value = "Failed to load categories: $e";
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // SAVE NEW PRODUCT
  //
  // STEPS:
  // 1) generate unique barcode
  // 2) insert product (returns productId)
  // 3) insert initial stock entry (and product auto-update handled in StockService)
  // --------------------------------------------------------------------------
  Future<bool> saveProduct({
    required String name,
    required double purchaseRate,
    required double sellingRate,
    required int quantity,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final cat = selectedCategory.value;

      if (cat == null || cat.id == null) {
        errorMessage.value = "Select a valid category.";
        return false;
      }

      // 1) generate barcode
      final barcode = _productService.generateBarcode();

      // 2) create product
      final productId = await _productService.addNewProduct(
        name: name,
        categoryId: cat.id!,
        purchaseRate: purchaseRate,
        sellingRate: sellingRate,
        stockQuantity: 0, // ⚠ stock is added via StockService, not here
        barcode: barcode,
      );

      // 3) add initial stock batch
      if (quantity > 0) {
        await _stockService.addStock(
          productId: productId,
          quantity: quantity,
          purchaseRate: purchaseRate,
          sellingRate: sellingRate,
          receivedDate: DateTime.now(),
        );
      }

      return true;

    } catch (e) {
      errorMessage.value = "Failed to save product: $e";
      return false;

    } finally {
      isSaving.value = false;
    }
  }
}
