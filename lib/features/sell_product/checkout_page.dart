import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

import '../../../core/services/thermal_printer_service.dart';
import '../../../core/services/whatsapp_share_service.dart';
import '../../../core/utils/mobile_number_formatter.dart';
import '../registered_customers/add_customer_page.dart';

// 👇 NEW: use SellController as single source of truth for sale RPC
import '../../../core/controllers/sell_controller.dart';

class CheckoutPage extends StatefulWidget {
  final String billNo;
  final List<Map<String, dynamic>> items;
  final String customerName;
  final double subTotal;
  final double totalDiscount;
  final double total;

  /// If null → new bill, if not null → editing existing bill
  final String? editingBillId;

  CheckoutPage({
    super.key,
    required this.billNo,
    required this.items,
    required this.customerName,
    required this.subTotal,
    required this.totalDiscount,
    required this.total,
    this.editingBillId,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final SupabaseClient _client = Supabase.instance.client;

  /// Use the same SellController we put in SellPage
  final SellController sellController = Get.find<SellController>();

  bool isPaid = true;
  bool isSaving = false;

  // Unpaid bill customer fields
  final TextEditingController debtCustomerNameCtrl = TextEditingController();
  final TextEditingController debtCustomerPhoneCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();

  // ===================================================================
  // SAVE BILL
  //  - NEW BILL  → SellController.finalizeBill (RPC)
  //  - EDIT BILL → manual update (no stock change)
  // ===================================================================
  // ===================================================================
// SAVE BILL
//  - NEW BILL  → SellController.finalizeBill
//  - EDIT BILL → manual update (no stock change)
// ===================================================================
  Future<void> _saveBill() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    String? billId = widget.editingBillId;
    String? customerId;

    // yahan hum wo bill no store karenge jo actually DB me use hoga
    String? usedBillNo;

    try {
      // Logged in user
      final user = _client.auth.currentUser;
      if (user == null) {
        Get.snackbar("Auth error", "User not logged in.");
        setState(() => isSaving = false);
        return;
      }
      final String salespersonId = user.id;

      // -------------------------------
      // 1) CUSTOMER (paid / unpaid)
      // -------------------------------
      if (isPaid) {
        customerId = await _handlePaidBillCustomer();
      } else {
        final validated = await _handleUnpaidCustomer();
        if (validated == null) {
          setState(() => isSaving = false);
          return;
        }
        customerId = validated;
      }

      final double paidAmount = isPaid
          ? widget.total
          : (double.tryParse(paidAmountCtrl.text) ?? 0);

      // ==============================================================
      // 2) NEW BILL → USE SellController.finalizeBill
      // ==============================================================
      if (billId == null) {
        // SellController ke items ko uski expected shape me map karo
        final List<Map<String, dynamic>> formattedItems =
        widget.items.map((i) {
          return {
            "id": i["id"],           // product id
            "product_id": i["id"],
            "pieces": i["pieces"],
            "price": i["price"],
            "discount": i["discount"],
          };
        }).toList();

        // controller ki list replace
        sellController.billItems.assignAll(formattedItems);

        // ⚠ IMPORTANT:
        // Yahan billNo ko dubara set NAHIN kar rahe.
        // Jo SellController.loadReservedOrNewBill ne generate kia tha,
        // wohi use hoga.
        usedBillNo = sellController.billNo.value;

        final String? newBillId = await sellController.finalizeBill(
          isFullyPaid: isPaid,
          paidAmount: paidAmount,
          customerId: customerId,
          salespersonId: salespersonId,
        );

        if (newBillId == null) {
          Get.snackbar("Error", "Failed to save bill.");
          setState(() => isSaving = false);
          return;
        }

        billId = newBillId;
      }

      // ==============================================================
      // 3) EDIT EXISTING BILL (NO STOCK CHANGE)
      // ==============================================================
      else {
        // edit mode me bill no already DB me hai → UI se lo
        usedBillNo = sellController.billNo.value;

        await _client.from("sales").delete().eq('bill_id', billId);

        await _client.from("bills").update({
          'customer_id': customerId,
          'total_items': widget.items.length,
          'sub_total': widget.subTotal,
          'total_discount': widget.totalDiscount,
          'total': widget.total,
          'total_paid': paidAmount,
          'is_fully_paid': isPaid,
        }).eq('id', billId);

        for (final item in widget.items) {
          await _client.from("sales").insert({
            'bill_id': billId,
            'product_id': item['id'],
            'quantity': item['pieces'],
            'selling_rate': item['price'],
            'discount_per_piece': item['discount'],
            'line_total': item['total'],
          });
        }

        // Debt records for edited bill
        if (!isPaid && customerId != null) {
          final remaining = widget.total - paidAmount;

          await _client.from("customer_debts").delete().eq('bill_id', billId);
          await _client.from("customer_debts").insert({
            'customer_id': customerId,
            'bill_id': billId,
            'debt_amount': widget.total,
            'paid_amount': paidAmount,
            'remaining_amount': remaining,
            'due_date': DateTime.now()
                .add(const Duration(days: 7))
                .toIso8601String(),
          });
        } else {
          await _client.from("customer_debts").delete().eq('bill_id', billId);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save bill: $e");
      setState(() => isSaving = false);
      return;
    }

    // ==============================================================
    // 4) PRINT BILL  +  5) WHATSAPP SHARE
    //    -- yahan hum wohi bill no use karenge jo upar decide hua
    // ==============================================================
    final String billNoForOutput = sellController.billNo.value;

    try {
      await ThermalPrinterService.printBill(
        billNo: billNoForOutput,
        items: widget.items,
        subTotal: widget.subTotal,
        discount: widget.totalDiscount,
        total: widget.total,
        customer: isPaid
            ? (widget.customerName.isEmpty
            ? "Walking Customer"
            : widget.customerName)
            : debtCustomerNameCtrl.text.trim(),
      );
    } catch (_) {}

    try {
      await WhatsAppShareService.shareBillViaWhatsApp(
        billNo: billNoForOutput,
        customer: isPaid
            ? (widget.customerName.isEmpty
            ? "Walking Customer"
            : widget.customerName)
            : debtCustomerNameCtrl.text.trim(),
        subTotal: widget.subTotal,
        discount: widget.totalDiscount,
        total: widget.total,
        items: widget.items,
      );
    } catch (_) {}

    // ==============================================================
    // 6) DONE
    // ==============================================================
    Get.snackbar(
      "Success",
      "Bill saved successfully!",
      snackPosition: SnackPosition.BOTTOM,
    );

    setState(() => isSaving = false);
    Get.offAllNamed('/sales_bill', arguments: billId);
  }



  // ===================================================================
  // HANDLE PAID BILL CUSTOMER (optional)
  // ===================================================================
  Future<String?> _handlePaidBillCustomer() async {
    if (widget.customerName.trim().isEmpty) return null;

    try {
      final existing = await _client
          .from("customers")
          .select("id")
          .eq("name", widget.customerName.trim())
          .maybeSingle();

      return existing?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ===================================================================
  // HANDLE UNPAID CUSTOMER (MUST EXIST)
  // ===================================================================
  Future<String?> _handleUnpaidCustomer() async {
    final name = debtCustomerNameCtrl.text.trim();
    final phone = debtCustomerPhoneCtrl.text.trim();
    final paid = double.tryParse(paidAmountCtrl.text) ?? 0;

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar("Required", "Enter customer name + phone for debt.");
      return null;
    }

    if (paid < 0 || paid > widget.total) {
      Get.snackbar("Invalid", "Paid amount cannot exceed bill total.");
      return null;
    }

    // 1) Try existing customer by phone
    final existing = await _client
        .from("customers")
        .select()
        .eq("phone", phone)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String?;
    }

    // 2) Register new customer
    final inserted = await Get.to(() => const AddCustomerPage());
    if (inserted == null) return null;

    return inserted['id'] as String?;
  }

  // ===================================================================
  // UI (UNCHANGED)
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(SSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= SUMMARY BOX ==================
                GlossyContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        "Customer",
                        widget.customerName.isEmpty
                            ? "Walking Customer"
                            : widget.customerName,
                      ),
                      _row("Bill No", sellController.billNo.value),
                      _row("Total Items", widget.items.length.toString()),
                      _row(
                          "Subtotal",
                          widget.subTotal.toStringAsFixed(2)),
                      _row(
                          "Total Discount",
                          widget.totalDiscount.toStringAsFixed(2)),
                      const Divider(),
                      _row(
                        "Grand Total",
                        widget.total.toStringAsFixed(2),
                        primary: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= PAID SWITCH ==================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Is Bill Paid?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isPaid,
                      activeColor: SColors.primary,
                      onChanged: (v) => setState(() => isPaid = v),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= UNPAID FORM ==================
                if (!isPaid) _buildUnpaidForm(context, dark),

                SizedBox(height: SSizes.spaceBtwSections),

                // ================= FINAL BUTTON ==================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.primary,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Save & Generate Bill",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // UNPAID FORM UI (unchanged)
  // ===================================================================
  Widget _buildUnpaidForm(BuildContext context, bool dark) {
    return GlossyContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Customer Debt",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SColors.primary,
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: debtCustomerNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Customer Name",
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: debtCustomerPhoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              MobileNumberFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: "Mobile Number",
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: paidAmountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Amount Paid",
              prefixIcon: Icon(Icons.payment),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ===================================================================
  // SMALL ROW
  // ===================================================================
  Widget _row(String label, String value, {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: primary ? SColors.primary : null,
              fontSize: primary ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: primary ? SColors.primary : null,
              fontSize: primary ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
