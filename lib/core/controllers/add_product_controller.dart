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
  // LOAD CATEGORIES
  // --------------------------------------------------------------------------
  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      errorMessage.value = '';

      final data = await _categoryService.fetchCategories();
      categories.assignAll(data);

    } catch (e) {
      errorMessage.value = "Failed to load categories: $e";
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // SAVE NEW PRODUCT
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

      final selected = selectedCategory.value;

      if (selected == null || selected.id == null) {
        errorMessage.value = "Select a valid category.";
        return false;
      }

      // 1) generate unique barcode
      final barcode = _productService.generateBarcode();

      // 2) insert product
      final productId = await _productService.addNewProduct(
        name: name,
        categoryId: selected.id!, // safe because we've checked
        purchaseRate: purchaseRate,
        sellingRate: sellingRate,
        stockQuantity: quantity,
        barcode: barcode,
      );

      // 3) insert initial stock entry (if quantity > 0)
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
