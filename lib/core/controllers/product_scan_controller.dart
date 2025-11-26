// lib/features/core_controllers/product_scan_controller.dart

import 'package:get/get.dart';
import 'package:kwt/core/services/product_scan_service.dart';
import '../models/product_model.dart';

class ProductScanController extends GetxController {
  final ProductScanService _service = ProductScanService();

  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  /// Scan barcode → fetch product safely
  Future<Product?> find(String barcode) async {
    try {
      isScanning.value = true;
      errorMessage.value = '';

      final cleanCode = barcode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
      if (cleanCode.isEmpty) {
        errorMessage.value = "Invalid barcode";
        return null;
      }

      print("🔍 CLEAN BARCODE SENT TO DB → '$cleanCode'");
      final product = await _service.getProductByBarcode(cleanCode);

      if (product == null) {
        errorMessage.value = "Product not found";
      }

      return product;

    } catch (e) {
      errorMessage.value = "Scan failed: $e";
      print("❌ ProductScanController.find error: $e");
      return null;

    } finally {
      isScanning.value = false;
    }
  }

  /// Optional alias
  Future<Product?> scan(String barcode) async {
    return await find(barcode);
  }
}
