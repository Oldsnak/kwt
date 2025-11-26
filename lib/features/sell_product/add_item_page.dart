import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/core/services/product_scan_service.dart';
import 'package:kwt/core/models/product_model.dart';

class AddItemPage extends StatefulWidget {
  /// existingItem: jo bill me already add ho chuka hai (edit case)
  final Map<String, dynamic>? existingItem;

  /// scannedProduct: SellPage se aane wala product row (products table se)
  final Map<String, dynamic>? scannedProduct;

  /// fromScan: agar SellPage ke scanner se aya ho
  final bool fromScan;

  const AddItemPage({
    super.key,
    this.existingItem,
    this.scannedProduct,
    this.fromScan = false,
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final ProductScanService _scanService = Get.find<ProductScanService>();

  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();

  /// Product row data (mixed: DB row / result map) – UI isi pe chal rahi hai
  Map<String, dynamic>? productData;

  bool isLoading = false;

  // ---------------------------------------------------------------------------
  // FETCH PRODUCT BY BARCODE (VIA SERVICE)
  // ---------------------------------------------------------------------------
  Future<void> _fetchProductByBarcode(String barcode) async {
    try {
      setState(() => isLoading = true);

      final Product? p = await _scanService.getProductByBarcode(barcode);

      if (p == null) {
        Get.snackbar("Not Found", "No product found for this barcode");
        return;
      }

      // Minimal map jo puranay UI ke keys se match kare
      productData = {
        'id': p.id,
        'name': p.name,
        'stock_quantity': p.stockQuantity, // ✅ non-nullable in Product model
        'selling_rate': p.sellingRate,
      };
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch product: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // CONFIRM ITEM (CREATE / UPDATE LINE ITEM)
  // ---------------------------------------------------------------------------
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

    // Available stock from productData
    final int availableStock =
        (productData!['stock_quantity'] as num?)?.toInt() ?? 0;

    if (availableStock > 0 && qty > availableStock) {
      Get.snackbar(
        "Stock Error",
        "Not enough stock available (Available: $availableStock)",
      );
      return;
    }

    // Unit price from productData
    final double unitPrice =
        (productData!['selling_rate'] as num?)?.toDouble() ??
            (productData!['price'] as num?)?.toDouble() ??
            0.0;

    // 👉 Discount per piece (in Rupees)
    final double discountPerPiece = disc;

    if (discountPerPiece < 0) {
      Get.snackbar("Error", "Discount cannot be negative.");
      return;
    }

    if (discountPerPiece > unitPrice) {
      Get.snackbar(
        "Error",
        "Discount per piece cannot be greater than item price.",
      );
      return;
    }

    /// 👉 Correct formula:
    /// total = qty * (unitPrice - discountPerPiece)
    final double total = qty * (unitPrice - discountPerPiece);

    final Map<String, dynamic> result = {
      'id': productData!['id'],
      'name': productData!['name'],
      'price': unitPrice,              // unit price
      'pieces': qty,                   // quantity
      'discount': discountPerPiece,    // discount per piece (Rs)
      'total': total,                  // line total

      // extra fields taake edit / validation me stock issue na aaye
      'stock_quantity': availableStock,
      'selling_rate': unitPrice,
    };

    // Make sure result hamesha caller ko mile
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(result);
    } else {
      Get.back(result: result);
    }
  }

  // ---------------------------------------------------------------------------
  // INIT: existing item ya scanned product ko handle karo
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    // 1) Edit existing item
    if (widget.existingItem != null) {
      productData = Map<String, dynamic>.from(widget.existingItem!);

      _quantityCtrl.text = widget.existingItem!['pieces'].toString();
      _discountCtrl.text = widget.existingItem!['discount'].toString();

      // ensure stock_quantity & selling_rate present
      productData!['stock_quantity'] =
      (widget.existingItem!['stock_quantity'] ?? 0);
      productData!['selling_rate'] =
      (widget.existingItem!['price'] ??
          widget.existingItem!['selling_rate'] ??
          0.0);
    }
    // 2) Directly scanned product from SellPage
    else if (widget.fromScan && widget.scannedProduct != null) {
      productData = Map<String, dynamic>.from(widget.scannedProduct!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
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
                // ----------------------------------------------------------
                // TITLE
                // ----------------------------------------------------------
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

                // ----------------------------------------------------------
                // SCAN BUTTON (sirf jab koi product selected nahi & fromScan false)
                // ----------------------------------------------------------
                if (productData == null && !widget.fromScan)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan Barcode"),
                    onPressed: () async {
                      final barcode = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const _ScannerPage(),
                        ),
                      );
                      if (barcode != null && barcode.isNotEmpty) {
                        await _fetchProductByBarcode(
                            barcode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '')
                        );
                      }
                    },
                  )
                // ----------------------------------------------------------
                // PRODUCT SUMMARY BOX (jab product mil gaya)
                // ----------------------------------------------------------
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
                        Text(
                          "Product: ${productData!['name']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Stock: ${(productData!['stock_quantity'] ?? 0)} pcs   |   Price: ${productData!['selling_rate'] ?? productData!['price']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: SSizes.spaceBtwSections),

                // ----------------------------------------------------------
                // QUANTITY FIELD
                // ----------------------------------------------------------
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

                // ----------------------------------------------------------
                // DISCOUNT FIELD (RUPEES PER PIECE)
                // ----------------------------------------------------------
                TextField(
                  controller: _discountCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Discount per piece (Rs)",
                    prefixIcon: Icon(Icons.discount),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: SSizes.spaceBtwSections),

                // ----------------------------------------------------------
                // CONFIRM BUTTON
                // ----------------------------------------------------------
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
                        fontSize: 16,
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
}

// ---------------------------------------------------------------------------
// INTERNAL SCANNER PAGE (UI SAME AS BEFORE)
// ---------------------------------------------------------------------------
class _ScannerPage extends StatefulWidget {
  const _ScannerPage({super.key});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessed) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _isProcessed = true;
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
