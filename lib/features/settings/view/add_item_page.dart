import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:kwt/core/services/supabase_service.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/controllers/category_controller.dart';
import 'package:kwt/core/controllers/product_controller.dart';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final SupabaseClient _client = SupabaseService.client;

  final _categoryNameController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _sellingRateController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCategory;
  bool _loading = false;
  final CategoryController categoryController = Get.put(CategoryController());
  final ProductController productController = Get.put(ProductController());

  @override
  void initState() {
    super.initState();
    categoryController.load(); // Load existing categories
  }

  /// Adds a new category to Supabase
  Future<void> _addCategory() async {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar("Error", "Please enter category name");
      return;
    }

    try {
      setState(() => _loading = true);
      await _client.from('categories').insert({'name': name});
      _categoryNameController.clear();
      Get.snackbar("Success", "Category added successfully");
      await categoryController.load();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Adds a new product and generates barcode
  Future<void> _addItem() async {
    final itemName = _itemNameController.text.trim();
    final purchaseRate = _purchaseRateController.text.trim();
    final sellingRate = _sellingRateController.text.trim();
    final quantity = _quantityController.text.trim();

    if (_selectedCategory == null ||
        itemName.isEmpty ||
        purchaseRate.isEmpty ||
        sellingRate.isEmpty ||
        quantity.isEmpty) {
      Get.snackbar("Missing Info", "Please fill all fields");
      return;
    }

    try {
      setState(() => _loading = true);

      // Find category ID using selected name
      final selectedCategoryObj = categoryController.categories
          .firstWhere((cat) => cat.name == _selectedCategory);

      final inserted = await _client
          .from('products')
          .insert({
        'category_id': selectedCategoryObj.id, // 👈 Use category_id instead
        'name': itemName,
        'purchase_rate': double.parse(purchaseRate),
        'selling_rate': double.parse(sellingRate),
        'stock_quantity': int.parse(quantity),
      })
          .select()
          .single();

      final productId = inserted['id'].toString();
      final barcodeData = productId;

      // Generate barcode PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.BarcodeWidget(
              data: barcodeData,
              barcode: Barcode.code128(),
              width: 200,
              height: 80,
            ),
          ),
        ),
      );

      Get.dialog(
        AlertDialog(
          title: const Text("Barcode Generated"),
          content: const Text(
              "Product added successfully!\nWould you like to download the barcode?"),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final Uint8List pdfBytes = await pdf.save();
                await Printing.sharePdf(
                    bytes: pdfBytes, filename: '$itemName-barcode.pdf');
                Get.back();
              },
              child: const Text("Download"),
            ),
          ],
        ),
      );

      _itemNameController.clear();
      _purchaseRateController.clear();
      _sellingRateController.clear();
      _quantityController.clear();
      _selectedCategory = null;

      await productController.loadAll();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: SSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== Add New Category =====
              GlossyContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add New Category",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .apply(color: SColors.primary)),
                    const SizedBox(height: SSizes.spaceBtwInputFields),
                    TextField(
                      controller: _categoryNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Iconsax.category),
                      ),
                    ),
                    const SizedBox(height: SSizes.spaceBtwInputFields),
                    Center(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addCategory,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Add Category"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SSizes.spaceBtwSections),

              // ===== Add New Item =====
              GlossyContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add New Item",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .apply(color: SColors.primary)),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    /// Category Dropdown
                    Obx(() {
                      final categories = categoryController.categories;
                      if (categories.isEmpty) {
                        return const Text("No categories found. Add one first.");
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Select Category',
                          prefixIcon: Icon(Iconsax.category),
                        ),
                        items: categories
                            .map((cat) => DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedCategory = val;
                        }),
                      );
                    }),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    TextField(
                      controller: _itemNameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: Icon(Iconsax.box),
                      ),
                    ),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    TextField(
                      controller: _purchaseRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Rate',
                        prefixIcon: Icon(Iconsax.money),
                      ),
                    ),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    TextField(
                      controller: _sellingRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Rate',
                        prefixIcon: Icon(Iconsax.money_send),
                      ),
                    ),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Iconsax.shopping_cart),
                      ),
                    ),
                    const SizedBox(height: SSizes.spaceBtwInputFields),

                    Center(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addItem,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Add Item"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
