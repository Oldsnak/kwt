import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellController extends GetxController {
  final SupabaseClient _client = Supabase.instance.client;

  /// ITEMS stored exactly like your UI (map based)
  RxList<Map<String, dynamic>> billItems = <Map<String, dynamic>>[].obs;

  /// Customer name (optional)
  RxString customerName = ''.obs;

  /// Bill number (string pattern: A0000 → A0001 → …)
  RxString billNo = ''.obs;

  /// Flags
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // INIT – CALL AT START OR WHEN SELL PAGE OPENS
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    loadNextBillNo();
  }

  // ---------------------------------------------------------------------------
  // FETCH NEXT BILL NUMBER (RPC recommended)
  // ---------------------------------------------------------------------------

  Future<void> loadNextBillNo() async {
    try {
      isLoading.value = true;
      final result = await _client.rpc('generate_next_bill_no');

      billNo.value = (result as String?) ?? "A0000";
    } catch (e) {
      billNo.value = "A0000"; // fallback
      print("Bill No fetch error → $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // CALCULATE TOTALS
  // ---------------------------------------------------------------------------
  double get subTotal {
    double sum = 0;
    for (final item in billItems) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final pcs = (item['pieces'] as num?)?.toInt() ?? 0;
      sum += price * pcs;
    }
    return sum;
  }

  double get totalDiscount {
    double sum = 0;
    for (final item in billItems) {
      final disc = (item['discount'] as num?)?.toDouble() ?? 0.0;
      final pcs = (item['pieces'] as num?)?.toInt() ?? 0;
      sum += disc * pcs;
    }
    return sum;
  }

  double get total => subTotal - totalDiscount;

  // ---------------------------------------------------------------------------
  // ADD PRODUCT (after AddItemPage)
  // ---------------------------------------------------------------------------

  void addItem(Map<String, dynamic> newItem) {
    billItems.add(newItem);
  }

  // ---------------------------------------------------------------------------
  // UPDATE PRODUCT (edit existing item)
  // ---------------------------------------------------------------------------

  void updateItem(int index, Map<String, dynamic> updated) {
    billItems[index] = updated;
    billItems.refresh();
  }

  // ---------------------------------------------------------------------------
  // REMOVE PRODUCT
  // ---------------------------------------------------------------------------

  void removeItem(Map<String, dynamic> item) {
    billItems.remove(item);
  }

  // ---------------------------------------------------------------------------
  // FINALIZE BILL → CALL RPC create_sale_transaction
  // ---------------------------------------------------------------------------

  Future<String?> finalizeBill({
    required bool isFullyPaid,
    required double paidAmount,
    String? customerId,
    String? salespersonId,
  }) async {
    if (billItems.isEmpty) {
      errorMessage.value = "Bill empty.";
      return null;
    }

    try {
      isLoading.value = true;

      /// Prepare sales list exactly as RPC expects
      final List<Map<String, dynamic>> saleLines = billItems.map((item) {
        return {
          "product_id": item['id'],
          "quantity": item['pieces'],
          "selling_rate": item['price'],
          "discount_per_piece": item['discount'],
        };
      }).toList();

      /// RPC call
      final result = await _client.rpc(
        'create_sale_transaction',
        params: {
          "p_bill_no": billNo.value,
          "p_customer_id": customerId,       // can be null
          "p_salesperson_id": salespersonId, // owner or salesperson
          "p_total_items": _countTotalItems(),
          "p_sub_total": subTotal,
          "p_total_discount": totalDiscount,
          "p_total": total,
          "p_total_paid": paidAmount,
          "p_is_fully_paid": isFullyPaid,
          "p_sale_items": saleLines,
        },
      );

      /// Success → clear bill
      resetBill();

      /// Always generate new bill code
      await loadNextBillNo();

      return result.toString();
    } catch (e) {
      errorMessage.value = "Checkout failed: $e";
      print("Checkout error → $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  int _countTotalItems() {
    int totalPieces = 0;
    for (final item in billItems) {
      totalPieces += (item['pieces'] as num?)?.toInt() ?? 0;
    }
    return totalPieces;
  }

  // ---------------------------------------------------------------------------
  // RESET AFTER CHECKOUT
  // ---------------------------------------------------------------------------

  void resetBill() {
    billItems.clear();
    customerName.value = "";
  }
}
