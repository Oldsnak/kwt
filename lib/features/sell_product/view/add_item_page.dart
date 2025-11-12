import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

class AddItemPage extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final Map<String, dynamic>? scannedProduct;
  final bool fromScan;

  const AddItemPage({
    super.key,
    this.existingItem,
    this.scannedProduct,
    this.fromScan = false, // ✅ this ensures it's never null
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}


class _AddItemPageState extends State<AddItemPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();

  Map<String, dynamic>? productData;
  bool isLoading = false;

  Future<void> _fetchProductByBarcode(String barcode) async {
    try {
      setState(() => isLoading = true);
      final res = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (res == null) {
        Get.snackbar("Not Found", "No product found for this barcode");
        return;
      }
      productData = res;
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch product: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _confirmItem() {
    if (productData == null) {
      Get.snackbar("Error", "No product selected");
      return;
    }

    final int qty = int.tryParse(_quantityCtrl.text) ?? 0;
    final double disc = double.tryParse(_discountCtrl.text) ?? 0.0;

    if (qty <= 0) {
      Get.snackbar("Invalid Quantity", "Enter valid quantity");
      return;
    }

    if (qty > (productData!['stock_quantity'] ?? 0)) {
      Get.snackbar("Stock Error", "Not enough stock available");
      return;
    }

    final double unitPrice = (productData!['selling_rate'] ?? 0.0);
    final double price = unitPrice * qty;
    final double total = price - disc; // ✅ discount in rupees

    final Map<String, dynamic> result = {
      'id': productData!['id'],
      'name': productData!['name'],
      'price': unitPrice,
      'pieces': qty,
      'discount': disc,
      'total': total,
    };

    Get.back(result: result);
  }

  @override
  void initState() {
    super.initState();

    // ✅ priority order: existing item → scanned product
    if (widget.existingItem != null) {
      productData = widget.existingItem;
      _quantityCtrl.text = widget.existingItem!['pieces'].toString();
      _discountCtrl.text = widget.existingItem!['discount'].toString();
    } else if (widget.fromScan && widget.scannedProduct != null) {
      productData = widget.scannedProduct;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem == null
            ? "Add Item to Bill"
            : "Edit Item Details"),
        backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
      ),
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
                Center(
                  child: Text(
                    productData == null ? "Add / Scan Item" : "Item Details",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .apply(color: SColors.primary, fontWeightDelta: 3),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwSections),

                // ✅ hide scan button when coming from SellPage scan
                if (productData == null && !widget.fromScan)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan Barcode"),
                    onPressed: () async {
                      final barcode = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const _ScannerPage()),
                      );
                      if (barcode != null && barcode.isNotEmpty) {
                        await _fetchProductByBarcode(barcode);
                      }
                    },
                  )
                else if (productData != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white10
                          : Colors.grey.shade100.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Product: ${productData!['name']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                            "Stock: ${productData!['stock_quantity']} pcs   |   Price: ${productData!['selling_rate']}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                const SizedBox(height: SSizes.spaceBtwSections),

                TextField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    prefixIcon: Icon(Icons.production_quantity_limits),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwItems),

                TextField(
                  controller: _discountCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Discount (Rs)",
                    prefixIcon: Icon(Icons.discount),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwSections),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _confirmItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      widget.existingItem == null
                          ? "Add Item"
                          : "Update Item",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
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
}

// ✅ simple internal scanner (used only when manually opened)
class _ScannerPage extends StatefulWidget {
  const _ScannerPage({super.key});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        Navigator.of(context).pop(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
