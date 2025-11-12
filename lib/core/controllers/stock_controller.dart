// lib/features/core_controllers/stock_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/stock_service.dart';

import '../models/stock_model.dart';

class StockController extends GetxController {
  final StockService _service = StockService();

  final RxList<StockEntry> history = <StockEntry>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadHistory(String productId) async {
    try {
      isLoading.value = true;
      final res = await _service.getStockHistory(productId);
      // convert to StockEntry models if needed:
      history.value = res.map((m) => StockEntry.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      print('StockController.loadHistory error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addStock({
    required String productId,
    required int quantity,
    required double purchaseRate,
    required double sellingRate,
  }) async {
    try {
      isLoading.value = true;
      await _service.addStock(
        productId: productId,
        quantity: quantity,
        purchaseRate: purchaseRate,
        sellingRate: sellingRate,
      );
      await loadHistory(productId);
    } catch (e) {
      print('StockController.addStock error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> currentStock(String productId) async {
    return await _service.getCurrentStock(productId);
  }
}
