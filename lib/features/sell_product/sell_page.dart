import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/features/sell_product/widgets/sell_item_card.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/texts/section_heading.dart';

import 'package:kwt/core/controllers/sell_controller.dart';
import 'package:kwt/core/models/product_model.dart';

import '../../core/controllers/product_scan_controller.dart';
import 'add_item_page.dart';
import 'checkout_page.dart';

class SellPage extends StatefulWidget {
  final String? editingBillId;
  final String? editingBillNo;
  final String? editingCustomerName;
  final List<Map<String, dynamic>>? editingItems;

  const SellPage({
    super.key,
    this.editingBillId,
    this.editingBillNo,
    this.editingCustomerName,
    this.editingItems,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  /// Use central SellController (RPC-based)
  final SellController sellController = Get.find<SellController>();

  /// Use ProductScanController for barcode → Product lookup
  final ProductScanController scanController = Get.find<ProductScanController>();

  final TextEditingController customerCtrl = TextEditingController();

  bool showTrash = false;

  @override
  void initState() {
    super.initState();

    // -------------------------------
    // 🚫 DO NOT RESET when editing bill
    // -------------------------------
    if (widget.editingBillId == null) {
      // NEW BILL → safe to clear UI items only
      sellController.billItems.clear();
      sellController.customerName.value = "";
    }

    // -------------------------------
    // EDIT MODE
    // -------------------------------
    if (widget.editingBillId != null && widget.editingItems != null) {
      sellController.billNo.value =
          widget.editingBillNo ?? sellController.billNo.value;

      customerCtrl.text = widget.editingCustomerName ?? '';

      final mapped = widget.editingItems!.map((item) {
        return {
          'id': item['product_id'],
          'name': item['products']?['name']?.toString() ?? "",   // FIX
          'product_name': item['products']?['name']?.toString(), // NEW FIX
          'price': (item['selling_rate'] as num?)?.toDouble() ?? 0,
          'pieces': (item['quantity'] as num?)?.toInt() ?? 0,
          'discount': (item['discount_per_piece'] as num?)?.toDouble() ?? 0,
          'total': (item['line_total'] as num?)?.toDouble() ?? 0,
        };
      }).toList();


      sellController.billItems.assignAll(mapped);
    }

    // 🚫 DO NOT call loadNextBillNo here — SellController handles it.
  }


  // ---------------------------------------------------------------------------
  // BILL TOTALS (delegated to SellController)
  // ---------------------------------------------------------------------------
  double get _subTotal => sellController.subTotal;
  double get _totalDiscount => sellController.totalDiscount;
  double get _total => sellController.total;

  // ---------------------------------------------------------------------------
  // MUTATIONS (delegate to SellController)
  // ---------------------------------------------------------------------------
  void _addProduct(Map<String, dynamic> product) {
    sellController.addItem(product);
  }

  void _updateProduct(int index, Map<String, dynamic> updated) {
    sellController.updateItem(index, updated);
  }

  void _removeProduct(Map<String, dynamic> product) {
    sellController.removeItem(product);
  }

  // ---------------------------------------------------------------------------
  // BARCODE SCAN → ProductScanController → AddItemPage
  // ---------------------------------------------------------------------------
  Future<void> _startBarcodeScan(BuildContext context) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );
    // print("📷 SCANNED BARCODE RAW → '$barcode'");
    if (barcode == null || barcode.isEmpty) return;

    try {
      final Product? product = await scanController.find(barcode);

      if (product == null) {
        Get.snackbar("Not Found", "No product found for this barcode");
        return;
      }

      // Map Product → Map to stay compatible with AddItemPage
      final scannedMap = {
        'id': product.id,
        'name': product.name,
        'selling_rate': product.sellingRate,
        'purchase_rate': product.purchaseRate,
        'stock_quantity': product.stockQuantity,
        'barcode': product.barcode,
      };

      final result = await Get.to(
            () => AddItemPage(
          scannedProduct: scannedMap,
          fromScan: true,
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        _addProduct(result);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch product: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // LINE TOTAL (for table)
  // ---------------------------------------------------------------------------
  double _lineTotal(Map<String, dynamic> item) {
    final double price =
        (item['price'] as num?)?.toDouble() ?? 0.0; // unit price
    final double discPerPiece =
        (item['discount'] as num?)?.toDouble() ?? 0.0;
    final int pcs = (item['pieces'] as num?)?.toInt() ?? 0;
    final effective = price - discPerPiece;
    return pcs * (effective < 0 ? 0 : effective);
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                PrimaryHeaderContainer(
                  child: Column(
                    children: [
                      const SizedBox(height: SSizes.appBarHeight),
                      Center(
                        child: Obx(() {
                          final code = sellController.billNo.value;
                          return Text(
                            code.isEmpty
                                ? "Loading Bill..."
                                : "Bill # $code",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .apply(
                              color: Colors.black,
                              fontWeightDelta: 2,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      Container(
                        decoration: BoxDecoration(
                          color: SColors.accent.withOpacity(0.3),
                          border: Border.all(color: SColors.accent),
                          borderRadius: BorderRadius.circular(SSizes.sm),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: SSizes.xl),
                        padding:
                        const EdgeInsets.only(right: SSizes.lg),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: SSizes.md),
                              decoration: BoxDecoration(
                                color: SColors.accent,
                                border:
                                Border.all(color: SColors.accent),
                                borderRadius:
                                BorderRadius.circular(SSizes.sm),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Date",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: SSizes.lg),
                            Expanded(
                              child: TextField(
                                controller: customerCtrl,
                                textCapitalization:
                                TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'Customer Name',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.grey.shade900,
                                  ),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: SColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder:
                                  const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: SColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder:
                                  const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                                cursorColor: Colors.black,
                                cursorWidth: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SSizes.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeading(
                              title: "Listed Item",
                              showActionButton: false,
                              textColor: Colors.black,
                            ),
                            const SizedBox(height: SSizes.sm),
                            Obx(() {
                              final items =
                                  sellController.billItems;

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    ...items.map((item) {
                                      final index =
                                      items.indexOf(item);
                                      return Draggable<
                                          Map<String, dynamic>>(
                                        data: item,
                                        feedback: Opacity(
                                          opacity: 0.7,
                                          child: SellItemCard(
                                            name: item['name']?.toString()
                                                ?? item['product_name']?.toString()
                                                ?? item['products']?['name']?.toString()
                                                ?? "",
                                            price: (item['price']
                                            as num?)
                                                ?.toDouble() ??
                                                0.0,
                                            pieces:
                                            (item['pieces']
                                            as num?)
                                                ?.toInt() ??
                                                0,
                                            discount:
                                            (item['discount']
                                            as num?)
                                                ?.toDouble() ??
                                                0.0,
                                          ),
                                        ),
                                        childWhenDragging:
                                        const SizedBox(
                                            width: 100),
                                        onDragStarted: () =>
                                            setState(() =>
                                            showTrash = true),
                                        onDragEnd: (_) =>
                                            setState(() =>
                                            showTrash = false),
                                        child: GestureDetector(
                                          onTap: () async {
                                            final updated =
                                            await Get.to(
                                                  () => AddItemPage(
                                                  existingItem:
                                                  item),
                                            );
                                            if (updated != null &&
                                                updated
                                                is Map<String,
                                                    dynamic>) {
                                              _updateProduct(
                                                  index, updated);
                                            }
                                          },
                                          child: SellItemCard(
                                            name: item['name']?.toString()
                                                ?? item['product_name']?.toString()
                                                ?? item['products']?['name']?.toString()
                                                ?? "",
                                            price: (item['price']
                                            as num?)
                                                ?.toDouble() ??
                                                0.0,
                                            pieces:
                                            (item['pieces']
                                            as num?)
                                                ?.toInt() ??
                                                0,
                                            discount:
                                            (item['discount']
                                            as num?)
                                                ?.toDouble() ??
                                                0.0,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: SSizes.spaceBtwSections),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Obx(() {
                          final t = _total;
                          return Text(
                            "Total: ${t.toStringAsFixed(2)}",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                fontWeight: FontWeight.bold),
                          );
                        }),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      Obx(() {
                        final items = sellController.billItems;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Items')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Disc.')),
                              DataColumn(label: Text('Pcs.')),
                              DataColumn(label: Text('Total')),
                            ],
                            rows: items.map((data) {
                              final lineTotal =
                              _lineTotal(data);
                              return DataRow(cells: [
                                DataCell(Text(
                                    (data['name']?.toString()
                                        ?? data['product_name']?.toString()
                                        ?? data['products']?['name']?.toString()
                                        ?? "")
                                )),
                                DataCell(Text(
                                    '${data['price'] ?? 0}')),
                                DataCell(Text(
                                    '${data['discount'] ?? 0}')),
                                DataCell(Text(
                                    '${data['pieces'] ?? 0}')),
                                DataCell(Text(lineTotal
                                    .toStringAsFixed(2))),
                              ]);
                            }).toList(),
                          ),
                        );
                      }),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          final billCode =
                              sellController.billNo.value;
                          if (billCode.isEmpty) {
                            Get.snackbar("Bill",
                                "Bill number not ready yet.");
                            return;
                          }

                          // sync name into controller too (optional)
                          sellController.customerName.value =
                              customerCtrl.text.trim();

                          final items =
                          sellController.billItems.toList();

                          Get.to(
                                () => CheckoutPage(
                              billNo: billCode,
                              items: items,
                              customerName:
                              customerCtrl.text.trim(),
                              subTotal: _subTotal,
                              totalDiscount: _totalDiscount,
                              total: _total,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Proceed Bill",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Floating Action Button
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: dark
                  ? SColors.darkPrimaryContainer
                  : SColors.buttonPrimary,
              foregroundColor:
              dark ? SColors.primary : Colors.white,
              tooltip: "Scan Product",
              onPressed: () => _startBarcodeScan(context),
              child: const Icon(Icons.barcode_reader, size: 35),
            ),
          ),

          // Trash box while dragging
          if (showTrash)
            Align(
              alignment: Alignment.bottomCenter,
              child: DragTarget<Map<String, dynamic>>(
                onAccept: (item) => _removeProduct(item),
                builder: (context, _, __) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BARCODE SCANNER PAGE USED BY SellPage
// ---------------------------------------------------------------------------
class _ScannerPage extends StatefulWidget {
  const _ScannerPage({super.key});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController controller =
  MobileScannerController();
  bool _isProcessed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessed) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _isProcessed = true;
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product"),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.greenAccent, width: 3),
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
    controller.dispose();
    super.dispose();
  }
}
