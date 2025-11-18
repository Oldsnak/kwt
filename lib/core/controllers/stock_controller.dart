// lib/core/controllers/stock_controller.dart

import 'package:get/get.dart';

import '../models/product_model.dart';
import '../models/stock_entry_model.dart';
import '../services/stock_service.dart';

class StockController extends GetxController {
  final StockService _stockService = StockService();

  // ---------------------------------------------------------------------------
  // REACTIVE STATES
  // ---------------------------------------------------------------------------

  /// Full stock history of a specific product
  final RxList<StockEntry> stockHistory = <StockEntry>[].obs;

  /// Current product information (updated after stock add)
  final Rxn<Product> product = Rxn<Product>();

  /// Loading states
  final RxBool isLoadingHistory = false.obs;
  final RxBool isAddingStock = false.obs;

  /// Error message holder
  final RxString errorMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // LOAD STOCK HISTORY FOR PRODUCT
  // ---------------------------------------------------------------------------

  Future<void> loadStockHistory(String productId) async {
    try {
      isLoadingHistory.value = true;
      errorMessage.value = '';

      // fetch live product info
      final p = await _stockService.getProduct(productId);
      product.value = p;

      // fetch history list
      final history = await _stockService.getStockHistory(productId);
      stockHistory.assignAll(history);
    } catch (e) {
      errorMessage.value = "Failed to load stock history: $e";
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ADD STOCK FOR A PRODUCT
  // ---------------------------------------------------------------------------

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

      // Add stock using service
      await _stockService.addStock(
        productId: productId,
        quantity: quantity,
        purchaseRate: purchaseRate,
        sellingRate: sellingRate,
        receivedDate: receivedDate,
      );

      // Reload updated product + stock history
      await loadStockHistory(productId);

      return true;
    } catch (e) {
      errorMessage.value = "Failed to add stock: $e";
      return false;
    } finally {
      isAddingStock.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // GET STOCK VALUE FOR PRODUCT (for analytics / dashboard)
  // ---------------------------------------------------------------------------

  Future<Map<String, double>> getStockValue(String productId) async {
    try {
      return await _stockService.getProductStockValue(productId);
    } catch (_) {
      return {
        'purchase_value': 0.0,
        'selling_value': 0.0,
      };
    }
  }
}
