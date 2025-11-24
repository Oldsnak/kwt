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

class CheckoutPage extends StatefulWidget {
  final String billNo;
  final List<Map<String, dynamic>> items;
  final String customerName;
  final double subTotal;
  final double totalDiscount;
  final double total;

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

  bool isPaid = true;
  bool isSaving = false;

  // Unpaid bill customer fields
  final TextEditingController debtCustomerNameCtrl = TextEditingController();
  final TextEditingController debtCustomerPhoneCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();

  // ===========================================================================
  // SAVE BILL → (NEW: RPC FOR NEW BILL) / (EDIT: MANUAL UPDATE)
  // ===========================================================================
  Future<void> _saveBill() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    String? billId = widget.editingBillId;
    String? customerId;

    try {
      // Logged in user → salesperson / owner
      final user = _client.auth.currentUser;
      if (user == null) {
        Get.snackbar("Auth error", "User not logged in.");
        setState(() => isSaving = false);
        return;
      }
      final String salespersonId = user.id;

      // ------------------------------------------------------------------
      // 1️⃣ CUSTOMER HANDLE (paid vs unpaid)
      // ------------------------------------------------------------------
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

      // kitna paid?
      final double paidAmount = isPaid
          ? widget.total
          : (double.tryParse(paidAmountCtrl.text) ?? 0);

      // ------------------------------------------------------------------
      // 2️⃣ NEW BILL → USE RPC create_sale_transaction
      // ------------------------------------------------------------------
      if (billId == null) {
        /// items ko RPC ke liye convert karo
        final List<Map<String, dynamic>> saleItems =
        widget.items.map((item) {
          return {
            "product_id": item['id'],
            "quantity": item['pieces'],
            "selling_rate": item['price'],
            "discount_per_piece": item['discount'],
          };
        }).toList();

        final result = await _client.rpc(
          'create_sale_transaction',
          params: {
            'p_bill_no': widget.billNo,
            'p_customer_id': customerId,
            'p_salesperson_id': salespersonId,
            'p_items': saleItems,
            'p_sub_total': widget.subTotal,
            'p_total_discount': widget.totalDiscount,
            'p_total': widget.total,
            'p_paid': paidAmount,
            'p_is_fully_paid': isPaid,
          },
        );

        billId = result?.toString();
      } else {
        // ----------------------------------------------------------------
        // 3️⃣ EDITING EXISTING BILL (NO STOCK CHANGE HERE)
        // ----------------------------------------------------------------

        // RLS ensure karega ke:
        // - owner kisi ka bhi bill edit kar sakta
        // - salesperson sirf apna bill edit kare
        // yahan hum sirf bill & sales rows update kar rahe hain.

        // Purane sales delete
        await _client.from("sales").delete().eq('bill_id', billId);

        // Bill row update
        await _client.from("bills").update({
          'customer_id': customerId,
          'total_items': widget.items.length,
          'sub_total': widget.subTotal,
          'total_discount': widget.totalDiscount,
          'total': widget.total,
          'total_paid': paidAmount,
          'is_fully_paid': isPaid,
        }).eq('id', billId);

        // Naye sales insert (LEKIN STOCK KO TOUCH NAHI KARTE)
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

        // DEBT UPDATE
        if (!isPaid && customerId != null) {
          final remaining = widget.total - paidAmount;

          // Purana debt delete + naya insert (sirf 1 row per bill)
          await _client
              .from("customer_debts")
              .delete()
              .eq('bill_id', billId);

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
          // agr ab bill fully paid ho gaya → koi debt record nahi hona chahiye
          await _client
              .from("customer_debts")
              .delete()
              .eq('bill_id', billId);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save bill: $e");
      setState(() => isSaving = false);
      return;
    }

    // ----------------------------------------------------------------------
    // 4️⃣ PRINT BILL
    // ----------------------------------------------------------------------
    try {
      await ThermalPrinterService.printBill(
        billNo: widget.billNo,
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

    // ----------------------------------------------------------------------
    // 5️⃣ SHARE ON WHATSAPP
    // ----------------------------------------------------------------------
    try {
      await WhatsAppShareService.shareBillViaWhatsApp(
        billNo: widget.billNo,
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

    // ----------------------------------------------------------------------
    // 6️⃣ DONE
    // ----------------------------------------------------------------------
    Get.snackbar(
      "Success",
      "Bill saved successfully!",
      snackPosition: SnackPosition.BOTTOM,
    );

    setState(() => isSaving = false);
    Get.offAllNamed('/sales_bill', arguments: billId);
  }

  // ===========================================================================
  // HANDLE PAID BILL CUSTOMER (optional)
  // ===========================================================================
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

  // ===========================================================================
  // HANDLE UNPAID CUSTOMER (MUST EXIST → register if needed)
  // ===========================================================================
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

    // 1) Check by phone number
    final existing = await _client
        .from("customers")
        .select()
        .eq("phone", phone)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String?;
    }

    // 2) Open AddCustomerPage to create new registered customer
    final inserted = await Get.to(() => const AddCustomerPage());
    if (inserted == null) return null;

    return inserted['id'] as String?;
  }

  // ===========================================================================
  // UI
  // ===========================================================================
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
                              : widget.customerName),
                      _row("Bill No", widget.billNo),
                      _row(
                          "Total Items",
                          widget.items.length.toString()),
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
                    const Text("Is Bill Paid?",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Save & Generate Bill",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
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

  // ===========================================================================
  // UNPAID FORM UI
  // ===========================================================================
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
                color: SColors.primary),
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

  // ===========================================================================
  Widget _row(String label, String value, {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: primary ? SColors.primary : null,
                fontSize: primary ? 18 : 16,
                fontWeight: FontWeight.bold,
              )),
          Text(value,
              style: TextStyle(
                color: primary ? SColors.primary : null,
                fontSize: primary ? 18 : 16,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
