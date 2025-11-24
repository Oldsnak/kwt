import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

class PayDebtPage extends StatefulWidget {
  final String customerId;
  final double remainingDebt;

  const PayDebtPage({
    super.key,
    required this.customerId,
    required this.remainingDebt,
  });

  @override
  State<PayDebtPage> createState() => _PayDebtPageState();
}

class _PayDebtPageState extends State<PayDebtPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _payCtrl = TextEditingController();

  bool _loading = false;

  String get _date =>
      DateFormat('dd-MM-yyyy').format(DateTime.now());

  Future<void> _submitPayment() async {
    final payText = _payCtrl.text.trim();
    if (payText.isEmpty) {
      Get.snackbar("Error", "Please enter payment amount.");
      return;
    }

    final amount = double.tryParse(payText);
    if (amount == null || amount <= 0) {
      Get.snackbar("Error", "Invalid payment amount.");
      return;
    }

    if (amount > widget.remainingDebt) {
      Get.snackbar("Error", "Paying more than remaining debt is not allowed.");
      return;
    }

    setState(() => _loading = true);

    try {
      // -------------------------------------------
      // 1) Fetch all active debt rows for customer
      // -------------------------------------------
      final debts = await _client
          .from("customer_debts")
          .select()
          .eq("customer_id", widget.customerId)
          .order("created_at", ascending: true);

      double leftToPay = amount;

      // -------------------------------------------
      // 2) Reduce remaining_amount FIFO
      // -------------------------------------------
      for (final row in debts) {
        if (leftToPay <= 0) break;

        final debtId = row['id'];
        final currentRemaining =
            (row['remaining_amount'] as num?)?.toDouble() ??
                (row['debt_amount'] as num?)?.toDouble() ??
                0.0;

        if (currentRemaining <= 0) continue;

        if (leftToPay >= currentRemaining) {
          // Completely clear this debt row
          await _client.from("customer_debts").update({
            "remaining_amount": 0,
          }).eq("id", debtId);

          leftToPay -= currentRemaining;
        } else {
          // Partially reduce
          await _client.from("customer_debts").update({
            "remaining_amount": currentRemaining - leftToPay,
          }).eq("id", debtId);

          leftToPay = 0;
        }
      }

      // -------------------------------------------
      // 3) Insert into customer_payments
      // -------------------------------------------
      await _client.from("customer_payments").insert({
        "customer_id": widget.customerId,
        "paid_amount": amount,
        "payment_date": DateTime.now().toIso8601String(),
      });

      Get.back(result: true);
      Get.snackbar("Success", "Debt payment recorded successfully.");

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SSizes.defaultSpace),
            child: GlossyContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------------------ DATE ------------------
                  Text(
                    _date,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: SColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
          
                  // ------------------ REMAINING DEBT ------------------
                  Text(
                    "Remaining Debt",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    widget.remainingDebt.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
          
                  // ------------------ TEXT FIELD ------------------
                  TextField(
                    controller: _payCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      labelText: "Enter Amount to Pay",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: SColors.primary),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
          
                  const SizedBox(height: 30),
          
                  // ------------------ BUTTON ------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "PAY DEBT",
                        style: TextStyle(
                          fontSize: 20,
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
      ),
    );
  }
}
