// lib/features/core_controllers/product_scan_controller.dart

import 'package:get/get.dart';
import 'package:kwt/core/services/product_scan_service.dart';
import '../models/product_model.dart';

class ProductScanController extends GetxController {
  final ProductScanService _service = ProductScanService();

  final RxBool isScanning = false.obs;

  /// Scan barcode → return Product or null
  Future<Product?> find(String barcode) async {
    try {
      isScanning.value = true;

      // ✔ ProductScanService already returns Product
      final product = await _service.getProductByBarcode(barcode);

      return product;

    } catch (e) {
      print("ProductScanController.find error: $e");
      return null;
    } finally {
      isScanning.value = false;
    }
  }

  /// Optional helper alias for scanning
  Future<Product?> scan(String barcode) async {
    return await find(barcode);
  }
}
