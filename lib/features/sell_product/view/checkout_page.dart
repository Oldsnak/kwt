import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

import '../../../core/services/thermal_printer_service.dart';
import '../../../core/services/whatsapp_share_service.dart';

class CheckoutPage extends StatefulWidget {
  /// ✅ Ab billNo String hai (alpha-numeric: A0000 – ZZZZZ)
  final String billNo;
  final List<Map<String, dynamic>> items;
  final String customerName;
  final double subTotal;
  final double totalDiscount;
  final double total;

  const CheckoutPage({
    super.key,
    required this.billNo,
    required this.items,
    required this.customerName,
    required this.subTotal,
    required this.totalDiscount,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool isPaid = true;
  bool isSaving = false;

  // ----------------------------------------------------------------------------
  // SAVE BILL → INSERT SALES → UPDATE STOCK → PRINT → WHATSAPP SHARE
  // ----------------------------------------------------------------------------
  Future<void> _saveBill() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    /// ✅ bills.id = uuid hota hai, isliye String use karo instead of int
    String? billId;

    try {
      final customerName = widget.customerName.trim();
      String? customerId;

      // ---------------------------------------------------------------
      // ENSURE CUSTOMER EXISTS
      // ---------------------------------------------------------------
      if (customerName.isNotEmpty) {
        final existing = await _client
            .from('customers')
            .select()
            .eq('name', customerName)
            .maybeSingle();

        if (existing == null) {
          final inserted = await _client
              .from('customers')
              .insert({'name': customerName})
              .select()
              .single();

          customerId = inserted['id'] as String;
        } else {
          customerId = existing['id'] as String;
        }
      }

      // ---------------------------------------------------------------
      // INSERT BILL  (bill_no already alpha-numeric String)
      // ---------------------------------------------------------------
      final billRow = await _client
          .from('bills')
          .insert({
        'bill_no': widget.billNo,       // ✅ direct string, koi int/parse nahi
        'customer_id': customerId,
        'total_items': widget.items.length,
        'sub_total': widget.subTotal,
        'total_discount': widget.totalDiscount,
        'total': widget.total,
        'total_paid': isPaid ? widget.total : 0,
        'is_fully_paid': isPaid,
      })
          .select()
          .single();

      billId = billRow['id'] as String;

      // ---------------------------------------------------------------
      // INSERT SALES ITEMS
      // ---------------------------------------------------------------
      for (final item in widget.items) {
        await _client.from('sales').insert({
          'bill_id': billId,
          'product_id': item['id'],
          'quantity': item['pieces'],
          'selling_rate': item['price'],
          'discount_per_piece': item['discount'],
          'line_total': item['total'],
        });

        // Decrease stock
        await _client.rpc('decrease_stock', params: {
          'p_product_id': item['id'],
          'p_qty': item['pieces'],
        });
      }

      // ---------------------------------------------------------------
      // CREATE CUSTOMER DEBT IF UNPAID
      // ---------------------------------------------------------------
      if (!isPaid && customerId != null) {
        await _client.from('customer_debts').insert({
          'customer_id': customerId,
          'bill_id': billId,
          'debt_amount': widget.total,
          'due_date':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });
      }
    } catch (e) {
      Get.snackbar("Error Saving Bill", e.toString());
      setState(() => isSaving = false);
      return;
    }

    // -------------------------------------------------------------------
    // PRINT BILL (Bluetooth thermal printer)
    // -------------------------------------------------------------------
    try {
      await ThermalPrinterService.printBill(
        billNo: widget.billNo,  // ✅ alpha-numeric string
        items: widget.items,
        subTotal: widget.subTotal,
        discount: widget.totalDiscount,
        total: widget.total,
        customer: widget.customerName.isEmpty
            ? "Walking Customer"
            : widget.customerName,
      );
    } catch (e) {
      print("Print error: $e");
    }

    // -------------------------------------------------------------------
    // WHATSAPP SHARE AFTER BILL SAVED + PRINTED
    // -------------------------------------------------------------------
    try {
      await WhatsAppShareService.shareBillViaWhatsApp(
        billNo: widget.billNo,  // ✅ same code
        customer: widget.customerName.isEmpty
            ? "Walking Customer"
            : widget.customerName,
        subTotal: widget.subTotal,
        discount: widget.totalDiscount,
        total: widget.total,
        items: widget.items,
      );
    } catch (e) {
      print("WhatsApp share failed: $e");
    }

    // -------------------------------------------------------------------
    // FINAL NAVIGATION
    // -------------------------------------------------------------------
    setState(() => isSaving = false);

    Get.snackbar("Success", "Bill saved, printed & shared!");
    Get.offAllNamed('/salesBill', arguments: billId);
  }

  // ----------------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(SSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BILL SUMMARY BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    "Customer",
                    widget.customerName.isEmpty
                        ? "Walking Customer"
                        : widget.customerName,
                  ),
                  _row("Total Items", widget.items.length.toString()),
                  _row("Subtotal", widget.subTotal.toStringAsFixed(2)),
                  _row("Total Discount",
                      widget.totalDiscount.toStringAsFixed(2)),
                  const Divider(),
                  _row("Grand Total", widget.total.toStringAsFixed(2),
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Is Bill Paid?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isPaid,
                  activeColor: SColors.primary,
                  onChanged: (v) => setState(() => isPaid = v),
                ),
              ],
            ),

            const Spacer(),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
