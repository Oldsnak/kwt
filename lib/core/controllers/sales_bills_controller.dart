// lib/core/controllers/sales_bill_controller.dart

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesBillController extends GetxController {
  final SupabaseClient client = Supabase.instance.client;

  final RxList<Map<String, dynamic>> allBills = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredBills = <Map<String, dynamic>>[].obs;

  final RxBool loading = false.obs;

  /// active salesperson filter (id)
  final RxString activeSalesPerson = "".obs;

  /// search query
  final RxString searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadBills();
  }

  // ===========================================================================
  // LOAD BILLS WITH CORRECT JOIN
  // RLS SAFE: only owner will see all, salesperson will see own
  // ===========================================================================
  Future<void> loadBills() async {
    try {
      loading.value = true;

      final res = await client
          .from("bills")
          .select("""
            *,
            salesperson: user_profiles!bills_salesperson_id_fkey (
              full_name
            )
          """)
          .order("created_at", ascending: false);

      final list = List<Map<String, dynamic>>.from(res);

      // Normalize: salesperson may be null
      for (var b in list) {
        b['salesperson_name'] = b['salesperson']?['full_name'] ?? "Unknown";
      }

      allBills.assignAll(list);
      _applyFilters();

    } catch (e) {
      print("❌ SalesBillController.loadBills error: $e");
    } finally {
      loading.value = false;
    }
  }

  // ===========================================================================
  // SEARCH FILTER
  // ===========================================================================
  void search(String query) {
    searchQuery.value = query.trim().toLowerCase();
    _applyFilters();
  }

  // ===========================================================================
  // FILTER BY SALESPERSON
  // ===========================================================================
  void filterBySalesPerson(String salespersonId) {
    activeSalesPerson.value = salespersonId;
    _applyFilters();
  }

  // ===========================================================================
  // RESET FILTERS
  // ===========================================================================
  void resetFilter() {
    activeSalesPerson.value = "";
    searchQuery.value = "";
    filteredBills.assignAll(allBills);
  }

  // ===========================================================================
  // APPLY COMBINED FILTERS (SEARCH + SALESPERSON)
  // ===========================================================================
  void _applyFilters() {
    List<Map<String, dynamic>> list = [...allBills]; // clone list

    final spId = activeSalesPerson.value;
    final q = searchQuery.value;

    // salesperson filter
    if (spId.isNotEmpty) {
      list = list.where((b) => b['salesperson_id'] == spId).toList();
    }

    // search filter
    if (q.isNotEmpty) {
      list = list
          .where((b) =>
      b['bill_no'].toString().toLowerCase().contains(q) ||
          b['salesperson_name'].toString().toLowerCase().contains(q))
          .toList();
    }

    filteredBills.assignAll(list);
  }
}
