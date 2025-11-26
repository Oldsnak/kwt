// lib/core/controllers/sell_controller.dart

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../services/bill_service.dart';
import '../services/sales_service.dart';
import '../utils/local_storage_helper.dart';

class SellController extends GetxController {
  final SupabaseClient _client = Supabase.instance.client;
  final BillService _billService = BillService();
  final SalesService _salesService = SalesService();

  RxList<Map<String, dynamic>> billItems = <Map<String, dynamic>>[].obs;
  RxString customerName = ''.obs;
  RxString billNo = ''.obs;

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  late final String userId;

  @override
  void onInit() {
    super.onInit();

    final user = _client.auth.currentUser;
    userId = user?.id ?? "unknown_user";

    loadReservedOrNewBill();
  }

  Future<void> loadReservedOrNewBill() async {
    try {
      isLoading.value = true;

      final reserved = await LocalStorageHelper.getReservedBillNo(userId: userId);

      if (reserved != null && reserved.isNotEmpty) {
        billNo.value = reserved;
        return;
      }

      final next = await _billService.getNextBillNumber();
      billNo.value = next;

      await LocalStorageHelper.saveReservedBillNo(
        userId: userId,
        billNo: next,
      );

    } catch (e) {
      print("❌ loadReservedOrNewBill error: $e");
      billNo.value = "A0000";
    } finally {
      isLoading.value = false;
    }
  }

  double get subTotal {
    return billItems.fold(0.0, (sum, i) {
      final rate = (i['price'] as num?)?.toDouble() ?? 0;
      final qty = (i['pieces'] as num?)?.toInt() ?? 0;
      return sum + (rate * qty);
    });
  }

  double get totalDiscount {
    return billItems.fold(0.0, (sum, i) {
      final disc = (i['discount'] as num?)?.toDouble() ?? 0;
      final qty = (i['pieces'] as num?)?.toInt() ?? 0;
      return sum + (disc * qty);
    });
  }

  double get total => subTotal - totalDiscount;

  int get totalPieces {
    return billItems.fold(0, (sum, i) {
      return sum + ((i['pieces'] as num?)?.toInt() ?? 0);
    });
  }

  void addItem(Map<String, dynamic> item) => billItems.add(item);

  void updateItem(int index, Map<String, dynamic> updated) {
    billItems[index] = updated;
    billItems.refresh();
  }

  void removeItem(Map<String, dynamic> item) => billItems.remove(item);

  // ===========================================================================
  // FINALIZE BILL (UPDATED)
  // ===========================================================================
  Future<String?> finalizeBill({
    required bool isFullyPaid,
    required double paidAmount,
    String? customerId,
    String? salespersonId,
  }) async {

    if (billItems.isEmpty) {
      errorMessage.value = "Bill is empty.";
      return null;
    }

    if (billNo.value.isEmpty) {
      errorMessage.value = "Bill number missing.";
      return null;
    }

    try {
      isLoading.value = true;

      final saleModels = billItems.map((i) {
        return Sale(
          id: null,
          billId: null,
          productId: i['product_id'] ?? i['id'],   // <-- FIXED
          quantity: (i['pieces'] as num?)?.toInt() ?? 0,
          sellingRate: (i['price'] as num?)?.toDouble() ?? 0,
          discountPerPiece: (i['discount'] as num?)?.toDouble() ?? 0,
          soldAt: DateTime.now(),
        );
      }).toList();


      // 🔥 FINAL — now passing billNo
      final billId = await _salesService.finalizeBill(
        billNo: billNo.value,              // <-- FIXED
        items: saleModels,
        customerId: customerId,
        salespersonId: salespersonId,
        isPaidFully: isFullyPaid,
        totalPaid: paidAmount,
      );

      // Clear reserved bill
      await LocalStorageHelper.clearReservedBillNo(userId: userId);

      resetBill();
      await loadReservedOrNewBill();

      return billId;

    } catch (e) {
      print("❌ finalizeBill error: $e");
      errorMessage.value = "Checkout failed: $e";
      return null;

    } finally {
      isLoading.value = false;
    }
  }

  void resetBill() {
    billItems.clear();
    customerName.value = "";
    // billNo refresh handled above in loadReservedOrNewBill()
  }
}
