import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

class AddStockPage extends StatefulWidget {
  final String productId;
  const AddStockPage({super.key, required this.productId});

  @override
  State<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController quantityCtrl = TextEditingController();
  final TextEditingController purchaseRateCtrl = TextEditingController();
  final TextEditingController sellingRateCtrl = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> _addStock() async {
    final quantity = int.tryParse(quantityCtrl.text) ?? 0;
    final purchaseRate = double.tryParse(purchaseRateCtrl.text) ?? 0.0;
    final sellingRate = double.tryParse(sellingRateCtrl.text) ?? 0.0;

    if (quantity <= 0 || purchaseRate <= 0 || sellingRate <= 0) {
      Get.snackbar("Invalid Input", "Please fill all fields correctly");
      return;
    }

    try {
      isLoading.value = true;

      // 1️⃣ Insert new stock entry
      await _client.from('stock_entries').insert({
        'product_id': widget.productId,
        'quantity': quantity,
        'purchase_rate': purchaseRate,
        'selling_rate': sellingRate,
        'received_date': DateTime.now().toIso8601String(),
      });

      // 2️⃣ Update product's total stock quantity
      final current = await _client
          .from('products')
          .select('stock_quantity')
          .eq('id', widget.productId)
          .single();

      final newStock = (current['stock_quantity'] ?? 0) + quantity;
      await _client
          .from('products')
          .update({'stock_quantity': newStock})
          .eq('id', widget.productId);

      Get.back(result: true);
      Get.snackbar("Success", "Stock added successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to add stock: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Add Stock"),
      //   backgroundColor: SColors.primary,
      //   foregroundColor: Colors.white,
      // ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SSizes.defaultSpace),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SSizes.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
                    : [Colors.white, Colors.grey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Header
                Center(
                  child: Text(
                    "Add New Stock",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .apply(color: SColors.primary, fontWeightDelta: 3),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwSections),

                // 🟢 Quantity
                Text("Quantity",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: SColors.primary)),
                const SizedBox(height: SSizes.xs),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter quantity",
                    prefixIcon: const Icon(Icons.shopping_cart),
                    filled: true,
                    fillColor: dark ? Colors.black26 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwItems),

                // 🟢 Purchase Price
                Text("Purchase Rate",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: SColors.primary)),
                const SizedBox(height: SSizes.xs),
                TextField(
                  controller: purchaseRateCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "Enter purchase rate",
                    prefixIcon: const Icon(Icons.attach_money),
                    filled: true,
                    fillColor: dark ? Colors.black26 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwItems),

                // 🟢 Selling Price
                Text("Selling Rate",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: SColors.primary)),
                const SizedBox(height: SSizes.xs),
                TextField(
                  controller: sellingRateCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "Enter selling rate",
                    prefixIcon: const Icon(Icons.currency_exchange),
                    filled: true,
                    fillColor: dark ? Colors.black26 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: SSizes.spaceBtwSections),

                // 🟢 Add Stock Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : _addStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading.value
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Add Stock",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
