// lib/core/controllers/sales_controller.dart

import 'package:get/get.dart';
import '../models/bill_model.dart';
import '../models/sale_model.dart';
import '../services/bill_service.dart';
import '../services/sales_service.dart';

class SalesController extends GetxController {
  final BillService _billService = BillService();
  final SalesService _salesService = SalesService();

  // ===========================================================================
  // REACTIVE STATES
  // ===========================================================================
  final RxList<Bill> bills = <Bill>[].obs;
  final RxList<Sale> billItems = <Sale>[].obs;

  final RxBool isLoadingBills = false.obs;
  final RxBool isLoadingBillItems = false.obs;

  final RxString errorMessage = ''.obs;

  // ===========================================================================
  // LOAD LAST 7 DAYS BILLS
  // ===========================================================================
  Future<void> loadLast7DaysBills() async {
    try {
      isLoadingBills.value = true;
      errorMessage.value = "";

      final data = await _billService.getLast7DaysBills();

      bills.assignAll(data);
    } catch (e) {
      errorMessage.value = "Failed to load bills: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ===========================================================================
  // SEARCH BILL BY NUMBER
  // ===========================================================================
  Future<void> searchBill(String billNo) async {
    final q = billNo.trim();

    if (q.isEmpty) {
      await loadLast7DaysBills();
      return;
    }

    try {
      isLoadingBills.value = true;
      errorMessage.value = "";

      final bill = await _billService.searchBill(q);

      if (bill == null) {
        bills.clear();
        errorMessage.value = "No bill found with number $q.";
        return;
      }

      bills.assignAll([bill]);
    } catch (e) {
      errorMessage.value = "Search failed: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ===========================================================================
  // FILTER BY SALESPERSON
  // ===========================================================================
  Future<void> filterBySalesperson(String salespersonId) async {
    if (salespersonId.trim().isEmpty) {
      await loadLast7DaysBills();
      return;
    }

    try {
      isLoadingBills.value = true;
      errorMessage.value = "";

      final data =
      await _billService.getBillsBySalesperson(salespersonId);

      bills.assignAll(data);
    } catch (e) {
      errorMessage.value = "Failed to filter: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ===========================================================================
  // LOAD BILL DETAILS (header + items)
  // ===========================================================================
  Future<void> loadBillDetails(String billId) async {
    try {
      isLoadingBillItems.value = true;
      errorMessage.value = "";

      final billData = await _billService.getBillWithItems(billId);

      // header already inside billData but your UI loads only items
      billItems.assignAll(billData['items']);
    } catch (e) {
      errorMessage.value = "Failed to load bill details: $e";
    } finally {
      isLoadingBillItems.value = false;
    }
  }
}
