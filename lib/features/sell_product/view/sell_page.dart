import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/texts/section_heading.dart';
import 'package:kwt/features/sell_product/view/widgets/sell_item_card.dart';
import 'add_item_page.dart';
import 'checkout_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final SupabaseClient _client = Supabase.instance.client;

  /// Line items in current bill
  final List<Map<String, dynamic>> billItems = [];

  final TextEditingController customerCtrl = TextEditingController();

  /// ✅ Ab bill number TEXT hoga (e.g. A0000, A0001, ...)
  String? billNo;

  bool showTrash = false;

  @override
  void initState() {
    super.initState();
    _fetchNextBillNo();
  }

  // ---------------------------------------------------------------------------
  // FETCH NEXT BILL NUMBER: pattern [A-Z][A-Z0-9]{4}
  // ---------------------------------------------------------------------------
  Future<void> _fetchNextBillNo() async {
    try {
      final result = await _client
          .from('bills')
          .select('bill_no')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        if (result == null || result['bill_no'] == null) {
          // No bills yet → start from A0000
          billNo = 'A0000';
        } else {
          final last = (result['bill_no'] as String).trim();
          billNo = _getNextBillNo(last);
        }
      });
    } catch (e) {
      print("Error fetching bill number: $e");
      Get.snackbar("Error", "Failed to load bill number, using fallback.");
      // Fallback safe start
      setState(() {
        billNo = 'A0000';
      });
    }
  }

  /// ✅ Generate next bill number from last one
  /// last: e.g. A0000 → A0001 → ... → A000Z → A0010 → ... → ZZZZZ
  String _getNextBillNo(String last) {
    final regex = RegExp(r'^[A-Z][A-Z0-9]{4}$');
    if (!regex.hasMatch(last)) {
      // Agar kisi wajah se DB me galat format mila, hum safe side par reset kar denge
      return 'A0000';
    }

    const digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final chars = last.split(''); // [A,0,0,0,0]

    // Rightmost 4 positions (index 4 → 1) ko base36 me increment karna
    for (int i = 4; i >= 1; i--) {
      final current = chars[i];
      final idx = digits.indexOf(current);
      if (idx == -1) {
        return 'A0000'; // unexpected char → reset
      }

      if (idx < digits.length - 1) {
        // Normal increment
        chars[i] = digits[idx + 1];
        return chars.join();
      } else {
        // Z → overflow → is position ko 0 karo aur next left position pe jao
        chars[i] = '0';
      }
    }

    // Agar yahan tak aaye, iska matlab last 4 positions sab overflow ho chuki
    // Ab first letter ko A→B→C...Z increment karna hoga
    final first = chars[0];
    if (first != 'Z') {
      final nextCharCode = first.codeUnitAt(0) + 1; // A→B etc.
      chars[0] = String.fromCharCode(nextCharCode);
      // Baaki 4 ko reset
      chars[1] = '0';
      chars[2] = '0';
      chars[3] = '0';
      chars[4] = '0';
      return chars.join();
    } else {
      // Z ke baad koi letter nahi bacha → theoretical limit reached
      // Tum chaho to yahan error throw kar sakte ho ya wrap kar sakte ho.
      throw Exception('Bill number limit reached (ZZZZZ).');
    }
  }

  // ---------------------------------------------------------------------------
  // BILL TOTALS WITH PER-PIECE DISCOUNT
  // ---------------------------------------------------------------------------
  double get subTotal {
    double sum = 0;
    for (final item in billItems) {
      final double price =
          (item['price'] as num?)?.toDouble() ?? 0.0; // unit price
      final int pcs = (item['pieces'] as num?)?.toInt() ?? 0;
      sum += price * pcs;
    }
    return sum;
  }

  double get totalDiscount {
    double sum = 0;
    for (final item in billItems) {
      final double discPerPiece =
          (item['discount'] as num?)?.toDouble() ?? 0.0;
      final int pcs = (item['pieces'] as num?)?.toInt() ?? 0;
      sum += discPerPiece * pcs;
    }
    return sum;
  }

  double get total => subTotal - totalDiscount;

  // ---------------------------------------------------------------------------
  // MUTATIONS
  // ---------------------------------------------------------------------------
  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      billItems.add(product);
    });
  }

  void _updateProduct(int index, Map<String, dynamic> updated) {
    setState(() {
      billItems[index] = updated;
    });
  }

  void _removeProduct(Map<String, dynamic> product) {
    setState(() {
      billItems.remove(product);
    });
  }

  // ---------------------------------------------------------------------------
  // BARCODE SCAN → FETCH PRODUCT → OPEN AddItemPage
  // ---------------------------------------------------------------------------
  Future<void> _startBarcodeScan(BuildContext context) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );

    if (barcode == null || barcode.isEmpty) return;

    try {
      final product = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (product == null) {
        Get.snackbar("Not Found", "No product found for this barcode");
        return;
      }

      final result = await Get.to(() => AddItemPage(
        scannedProduct: product,
        fromScan: true,
      ));

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
                        child: Text(
                          billNo == null
                              ? "Loading Bill..."
                              : "Bill # $billNo", // ✅ Ab direct bill code show hoga, koi extra 'B' nahi
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .apply(
                            color: Colors.black,
                            fontWeightDelta: 2,
                          ),
                        ),
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
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  ...billItems.map((item) {
                                    final index =
                                    billItems.indexOf(item);
                                    return Draggable<
                                        Map<String, dynamic>>(
                                      data: item,
                                      feedback: Opacity(
                                        opacity: 0.7,
                                        child: SellItemCard(
                                          name: item['name'],
                                          price: (item['price']
                                          as num?)
                                              ?.toDouble() ??
                                              0.0,
                                          pieces:
                                          (item['pieces'] as num?)
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
                                      const SizedBox(width: 100),
                                      onDragStarted: () => setState(
                                              () => showTrash = true),
                                      onDragEnd: (_) => setState(
                                              () => showTrash = false),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final updated =
                                          await Get.to(() =>
                                              AddItemPage(
                                                  existingItem:
                                                  item));
                                          if (updated != null &&
                                              updated
                                              is Map<String,
                                                  dynamic>) {
                                            _updateProduct(
                                                index, updated);
                                          }
                                        },
                                        child: SellItemCard(
                                          name: item['name'],
                                          price: (item['price']
                                          as num?)
                                              ?.toDouble() ??
                                              0.0,
                                          pieces:
                                          (item['pieces'] as num?)
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
                            ),
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
                        child: Text(
                          "Total: ${total.toStringAsFixed(2)}",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Items')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Disc.')),
                            DataColumn(label: Text('Pcs.')),
                            DataColumn(label: Text('Total')),
                          ],
                          rows: billItems.map((data) {
                            final lineTotal = _lineTotal(data);
                            return DataRow(cells: [
                              DataCell(Text(data['name'] ?? '')),
                              DataCell(
                                  Text('${data['price'] ?? 0}')),
                              DataCell(
                                  Text('${data['discount'] ?? 0}')),
                              DataCell(
                                  Text('${data['pieces'] ?? 0}')),
                              DataCell(Text(
                                  lineTotal.toStringAsFixed(2))),
                            ]);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          if (billNo == null) {
                            Get.snackbar(
                                "Bill", "Bill number not ready yet.");
                            return;
                          }
                          Get.to(
                                () => CheckoutPage(
                              billNo: billNo!, // ✅ String
                              items: billItems,
                              customerName:
                              customerCtrl.text.trim(),
                              subTotal: subTotal,
                              totalDiscount: totalDiscount,
                              total: total,
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
        backgroundColor: SColors.primary,
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
