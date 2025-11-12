// lib/features/core_controllers/product_scan_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/product_scan_service.dart';
import '../models/product_model.dart';

class ProductScanController extends GetxController {
  final ProductScanService _service = ProductScanService();

  final RxBool isScanning = false.obs;

  /// Returns the inserted cart item map or null if product not found.
  Future<Map<String, dynamic>?> scanAndAddToCart(String barcode, {int qty = 1, double discountPerPiece = 0}) async {
    try {
      isScanning.value = true;
      final inserted = await _service.addScannedProductToCart(barcode, qty: qty, discountPerPiece: discountPerPiece);
      return inserted;
    } catch (e) {
      print('ProductScanController.scanAndAddToCart error: $e');
      rethrow;
    } finally {
      isScanning.value = false;
    }
  }

  Future<Product?> find(String barcode) async {
    final p = await _service.findProductByBarcode(barcode);
    if (p == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(p));
  }
}
