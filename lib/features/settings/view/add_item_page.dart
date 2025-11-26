// lib/features/settings/view/add_item_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/add_product_controller.dart';
import '../../../core/models/category_model.dart';

class AddNewItemPage extends StatefulWidget {
  const AddNewItemPage({super.key});

  @override
  State<AddNewItemPage> createState() => _AddNewItemPageState();
}

class _AddNewItemPageState extends State<AddNewItemPage> {
  late final AddProductController controller;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController purchaseCtrl = TextEditingController();
  final TextEditingController sellingCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    // Controller init (if already exists, Get.put reuse karega)
    controller = Get.put(AddProductController());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    purchaseCtrl.dispose();
    sellingCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
      ),

      body: Obx(() {
        if (controller.isLoadingCategories.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // --------------------------------------------------------------
              // CATEGORY DROPDOWN
              // --------------------------------------------------------------
              const Text("Select Category",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() {
                    final selected = controller.selectedCategory.value;

                    return DropdownButton<CategoryModel>(
                      value: selected,
                      isExpanded: true,
                      items: controller.categories
                          .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      ))
                          .toList(),
                      onChanged: (value) {
                        controller.selectedCategory.value = value;
                      },
                      hint: const Text("Choose Category"),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------------------
              // PRODUCT NAME
              // --------------------------------------------------------------
              TextField(
                controller: nameCtrl,
                decoration: _input("Product Name"),
              ),

              const SizedBox(height: 15),

              // --------------------------------------------------------------
              // PURCHASE RATE + SELLING RATE
              // --------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: purchaseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _input("Purchase Rate"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: sellingCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _input("Selling Rate"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // --------------------------------------------------------------
              // INITIAL STOCK
              // --------------------------------------------------------------
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: _input("Initial Stock (optional)"),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------------------
              // SAVE PRODUCT BUTTON
              // --------------------------------------------------------------
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                      final name = nameCtrl.text.trim();
                      final purchaseText = purchaseCtrl.text.trim();
                      final sellingText = sellingCtrl.text.trim();
                      final qtyText = qtyCtrl.text.trim();

                      final purchase =
                          double.tryParse(purchaseText.isEmpty ? '0' : purchaseText) ?? 0;
                      final selling =
                          double.tryParse(sellingText.isEmpty ? '0' : sellingText) ?? 0;
                      final qty =
                          int.tryParse(qtyText.isEmpty ? '0' : qtyText) ?? 0;

                      if (name.isEmpty) {
                        Get.snackbar("Error", "Product name is required.");
                        return;
                      }
                      if (controller.selectedCategory.value == null) {
                        Get.snackbar("Error", "Select a category.");
                        return;
                      }

                      final success = await controller.saveProduct(
                        name: name,
                        purchaseRate: purchase,
                        sellingRate: selling,
                        quantity: qty,
                      );

                      if (success) {
                        Get.back();
                        Get.snackbar("Success", "Product added!");
                      }
                    },
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Save Product",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
