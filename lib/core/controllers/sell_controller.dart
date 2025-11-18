// lib/core/controllers/sell_controller.dart

import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../services/product_scan_service.dart';
import '../services/bill_service.dart';
import '../services/sales_service.dart';

class SellController extends GetxController {
  final ProductScanService _productService = ProductScanService();
  final BillService _billService = BillService();
  final SalesService _salesService = SalesService();

  // ---------------------------------------------------------------------------
  // STATES
  // ---------------------------------------------------------------------------

  final RxList<Sale> items = <Sale>[].obs;

  final RxDouble subTotal = 0.0.obs;
  final RxDouble totalDiscount = 0.0.obs;
  final RxDouble finalTotal = 0.0.obs;

  /// MUST USE RxnString for nullable String
  final RxnString customerId = RxnString();
  final RxnString salespersonId = RxnString();

  final RxString billNo = "-----".obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNextBillNo();
  }

  // ---------------------------------------------------------------------------
  // LOAD NEXT BILL #
  // ---------------------------------------------------------------------------

  Future<void> loadNextBillNo() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final next = await _billService.getNextBillNumber();
      billNo.value = next;

    } catch (e) {
      errorMessage.value = "Failed to load bill number: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SCAN BARCODE → PRODUCT → ADD TO LIST
  // ---------------------------------------------------------------------------

  Future<void> addScannedProduct(String barcode) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final product = await _productService.getProductByBarcode(barcode);

      if (product == null) {
        errorMessage.value = "No product found for barcode: $barcode";
        return;
      }

      addNewItem(
        product: product,
        quantity: 1,
        discount: 0,
      );

    } catch (e) {
      errorMessage.value = "Scan failed: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ADD NEW ITEM (MANUAL OR SCANNED)
  // ---------------------------------------------------------------------------

  void addNewItem({
    required Product product,
    required int quantity,
    required double discount,
  }) {
    final rate = product.sellingRate ?? 0;
    final lineTotal = (rate - discount) * quantity;

    items.add(
      Sale(
        id: null,
        billId: "TEMP",
        productId: product.id!,
        quantity: quantity,
        sellingRate: rate,
        discountPerPiece: discount,
        lineTotal: lineTotal,
        productName: product.name ?? "",
        barcode: product.barcode ?? "",
      ),
    );

    _recalculateTotals();
  }

  // ---------------------------------------------------------------------------
  // REMOVE ITEM
  // ---------------------------------------------------------------------------

  void removeItem(int index) {
    items.removeAt(index);
    _recalculateTotals();
  }

  // ---------------------------------------------------------------------------
  // TOTAL CALCULATION
  // ---------------------------------------------------------------------------

  void _recalculateTotals() {
    double st = 0;
    double td = 0;

    for (var item in items) {
      st += item.sellingRate * item.quantity;
      td += item.discountPerPiece * item.quantity;
    }

    subTotal.value = st;
    totalDiscount.value = td;
    finalTotal.value = st - td;
  }

  // ---------------------------------------------------------------------------
  // FINALIZE BILL
  // ---------------------------------------------------------------------------

  Future<String?> finalizeBill({
    required bool isPaidFully,
    required double? paidAmount,
  }) async {
    if (items.isEmpty) {
      errorMessage.value = "Cannot finalize an empty bill.";
      return null;
    }

    try {
      isLoading.value = true;

      final billId = await _salesService.finalizeBill(
        items: items.toList(),
        customerId: customerId.value,
        salespersonId: salespersonId.value,
        isPaidFully: isPaidFully,
        totalPaid: paidAmount ?? 0.0,
      );

      resetBill();
      await loadNextBillNo();
      return billId;

    } catch (e) {
      errorMessage.value = "Checkout failed: $e";
      return null;

    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // RESET AFTER CHECKOUT
  // ---------------------------------------------------------------------------

  void resetBill() {
    items.clear();
    subTotal.value = 0;
    totalDiscount.value = 0;
    finalTotal.value = 0;

    customerId.value = null;
    salespersonId.value = null;
  }
}
