// lib/core/controllers/sales_controller.dart

import 'package:get/get.dart';
import '../models/bill_model.dart';
import '../models/sale_model.dart';
import '../services/bill_service.dart';
import '../services/sales_service.dart';

class SalesController extends GetxController {
  final BillService _billService = BillService();
  final SalesService _salesService = SalesService();

  // ---------------------------------------------------------------------------
  // REACTIVE STATES
  // ---------------------------------------------------------------------------

  /// All bills (last 7 days OR filtered)
  final RxList<Bill> bills = <Bill>[].obs;

  /// Items of a specific bill
  final RxList<Sale> billItems = <Sale>[].obs;

  /// Loading states
  final RxBool isLoadingBills = false.obs;
  final RxBool isLoadingBillItems = false.obs;

  /// For errors
  final RxString errorMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // LOAD LAST 7 DAYS BILLS
  // ---------------------------------------------------------------------------

  Future<void> loadLast7DaysBills() async {
    try {
      isLoadingBills.value = true;
      errorMessage.value = '';

      final data = await _billService.getLast7DaysBills();
      bills.assignAll(data);
    } catch (e) {
      errorMessage.value = "Failed to load bills: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH BILL BY BILL NUMBER (A0001, B0Z23 etc.)
  // ---------------------------------------------------------------------------

  Future<void> searchBill(String billNo) async {
    if (billNo.trim().isEmpty) {
      await loadLast7DaysBills();
      return;
    }

    try {
      isLoadingBills.value = true;
      errorMessage.value = '';

      final bill = await _billService.searchBill(billNo);

      if (bill == null) {
        bills.clear();
        errorMessage.value = "No bill found with number $billNo.";
        return;
      }

      bills.assignAll([bill]);
    } catch (e) {
      errorMessage.value = "Search failed: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER BILLS BY SALESPERSON
  // ---------------------------------------------------------------------------

  Future<void> filterBySalesperson(String salespersonId) async {
    try {
      isLoadingBills.value = true;
      errorMessage.value = '';

      final data =
      await _billService.getBillsBySalesperson(salespersonId);

      bills.assignAll(data);
    } catch (e) {
      errorMessage.value = "Failed to filter: $e";
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD FULL BILL DETAILS (bill + items)
  // For Bill Detail Page or popup
  // ---------------------------------------------------------------------------

  Future<void> loadBillDetails(String billId) async {
    try {
      isLoadingBillItems.value = true;
      errorMessage.value = '';

      final billData = await _billService.getBillWithItems(billId);

      Bill bill = billData['bill'];
      List<Sale> items = billData['items'];

      billItems.assignAll(items);

    } catch (e) {
      errorMessage.value = "Failed to load bill details: $e";
    } finally {
      isLoadingBillItems.value = false;
    }
  }
}
