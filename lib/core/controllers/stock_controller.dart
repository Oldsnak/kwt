// lib/core/controllers/stock_controller.dart

import 'package:get/get.dart';

import '../models/product_model.dart';
import '../models/stock_entry_model.dart';
import '../services/stock_service.dart';

class StockController extends GetxController {
  final StockService _stockService = StockService();

  // ===========================================================================
  // REACTIVE STATES
  // ===========================================================================
  final RxList<StockEntry> stockHistory = <StockEntry>[].obs;

  final Rxn<Product> product = Rxn<Product>();

  final RxBool isLoadingHistory = false.obs;
  final RxBool isAddingStock = false.obs;

  final RxString errorMessage = ''.obs;

  // ===========================================================================
  // LOAD STOCK HISTORY FOR PRODUCT
  // ===========================================================================
  Future<void> loadStockHistory(String productId) async {
    try {
      isLoadingHistory.value = true;
      errorMessage.value = '';

      // Fetch updated live product
      final p = await _stockService.getProduct(productId);
      if (p == null) {
        errorMessage.value = "Product not found.";
        product.value = null;
        stockHistory.clear();
        return;
      }

      product.value = p;

      // Fetch stock batch history
      final history = await _stockService.getStockHistory(productId);
      stockHistory.assignAll(history);

    } catch (e) {
      errorMessage.value = "Failed to load stock history: $e";
      print("❌ StockController.loadStockHistory error: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ===========================================================================
  // ADD STOCK FOR PRODUCT
  // ===========================================================================
  Future<bool> addStock({
    required String productId,
    required int quantity,
    required double purchaseRate,
    required double sellingRate,
    required DateTime receivedDate,
  }) async {
    try {
      isAddingStock.value = true;
      errorMessage.value = '';

      await _stockService.addStock(
        productId: productId,
        quantity: quantity,
        purchaseRate: purchaseRate,
        sellingRate: sellingRate,
        receivedDate: receivedDate,
      );

      // Reload updated info
      await loadStockHistory(productId);

      return true;

    } catch (e) {
      errorMessage.value = "Failed to add stock: $e";
      print("❌ StockController.addStock error: $e");
      return false;

    } finally {
      isAddingStock.value = false;
    }
  }

  // ===========================================================================
  // GET STOCK VALUE SUMMARY
  // ===========================================================================
  Future<Map<String, double>> getStockValue(String productId) async {
    try {
      return await _stockService.getProductStockValue(productId);
    } catch (e) {
      print("❌ StockController.getStockValue error: $e");
      return {
        'purchase_value': 0.0,
        'selling_value': 0.0,
      };
    }
  }
}
