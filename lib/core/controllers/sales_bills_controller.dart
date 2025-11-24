import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesBillController extends GetxController {
  final SupabaseClient client = Supabase.instance.client;

  RxList<Map<String, dynamic>> allBills = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredBills = <Map<String, dynamic>>[].obs;

  RxBool loading = false.obs;

  RxString activeSalesPerson = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadBills();
  }

  // ================================================================
  // LOAD ALL BILLS WITH SALESPERSON NAME
  // ================================================================
  Future<void> loadBills() async {
    loading.value = true;

    final res = await client
        .from("bills")
        .select("""
          *,
          salesperson:user_profiles(full_name)
        """)
        .order("created_at", ascending: false);

    allBills.value = List<Map<String, dynamic>>.from(res);
    filteredBills.value = allBills;

    loading.value = false;
  }

  // ================================================================
  // SEARCH BY BILL NUMBER
  // ================================================================
  void search(String query) {
    if (query.isEmpty) {
      filteredBills.value = allBills;
      return;
    }

    filteredBills.value = allBills
        .where((b) =>
        b['bill_no']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }

  // ================================================================
  // FILTER BY SALESPERSON
  // ================================================================
  void filterBySalesPerson(String salesPersonId) {
    activeSalesPerson.value = salesPersonId;

    filteredBills.value = allBills
        .where((b) => b['salesperson_id'] == salesPersonId)
        .toList();
  }

  // ================================================================
  // RESET FILTER
  // ================================================================
  void resetFilter() {
    activeSalesPerson.value = "";
    filteredBills.value = allBills;
  }
}
