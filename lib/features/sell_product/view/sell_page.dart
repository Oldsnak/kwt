import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kwt/features/sell_product/view/widgets/sell_item_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/texts/section_heading.dart';
import 'add_item_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final RxList<Map<String, dynamic>> billItems = <Map<String, dynamic>>[].obs;
  final TextEditingController customerCtrl = TextEditingController();
  int? billNumber;

  @override
  void initState() {
    super.initState();
    _fetchNextBillNumber();
  }

  Future<void> _fetchNextBillNumber() async {
    try {
      final result = await _client
          .from('sales')
          .select('bill_no')
          .order('bill_no', ascending: false)
          .limit(1)
          .maybeSingle();

      print("Latest sale record: $result"); // 👈 debug print

      setState(() {
        billNumber = (result != null && result['bill_no'] != null)
            ? (result['bill_no'] as int) + 1
            : 1;
      });
    } catch (e) {
      print("Error fetching bill number: $e");
      Get.snackbar("Error", "Failed to load bill number: $e");
    }
  }


  bool showTrash = false;

  double get total => billItems.fold(0, (sum, e) => sum + (e['total'] ?? 0));

  void _addProduct(Map<String, dynamic> product) {
    billItems.add(product);
  }

  void _removeProduct(Map<String, dynamic> product) {
    billItems.remove(product);
  }

  // 🧭 Scan barcode, fetch product, open AddItemPage directly
  Future<void> _startBarcodeScan(BuildContext context) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );

    if (barcode != null && barcode.isNotEmpty) {
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

        if (result != null) _addProduct(result);
      } catch (e) {
        Get.snackbar("Error", "Failed to fetch product: $e");
      }
    }
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
                          billNumber == null
                              ? "Loading Bill..."
                              : "Bill # B$billNumber",
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .apply(color: Colors.black, fontWeightDelta: 2),
                        ),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      Container(
                        decoration: BoxDecoration(
                          color: SColors.accent.withOpacity(0.3),
                          border: Border.all(color: SColors.accent),
                          borderRadius: BorderRadius.circular(SSizes.sm),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: SSizes.xl),
                        padding: const EdgeInsets.only(right: SSizes.lg),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: SSizes.md),
                              decoration: BoxDecoration(
                                color: SColors.accent,
                                border: Border.all(color: SColors.accent),
                                borderRadius: BorderRadius.circular(SSizes.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Date",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black
                                    )
                                  ),
                                  Text(
                                    "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: SSizes.lg),
                            Expanded(
                              child: TextField(
                                controller: customerCtrl,
                                textCapitalization: TextCapitalization.words,
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
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: SColors.accent, width: 2),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: SColors.accent, width: 2),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: SSizes.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeading(
                                title: "Listed Item",
                                showActionButton: false,
                                textColor: Colors.black),
                            const SizedBox(height: SSizes.sm),
                            Obx(() => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  ...billItems.map((item) => Draggable(
                                    data: item,
                                    feedback: Opacity(
                                        opacity: 0.7,
                                        child: SellItemCard(
                                            name: item['name'],
                                            price: item['price'],
                                            pieces: item['pieces'],
                                            discount: item['discount'])),
                                    childWhenDragging: const SizedBox(width: 100),
                                    onDragStarted: () =>
                                        setState(() => showTrash = true),
                                    onDragEnd: (_) =>
                                        setState(() => showTrash = false),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final updated = await Get.to(
                                                () => AddItemPage(existingItem: item));
                                        if (updated != null) {
                                          final index = billItems.indexOf(item);
                                          billItems[index] = updated;
                                        }
                                      },
                                      child: SellItemCard(
                                          name: item['name'],
                                          price: item['price'],
                                          pieces: item['pieces'],
                                          discount: item['discount']),
                                    ),
                                  )),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: SSizes.spaceBtwSections),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Obx(() => Text(
                          "Total: ${total.toStringAsFixed(2)}",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        )),
                      ),
                      const SizedBox(height: SSizes.spaceBtwItems),
                      Obx(() => SingleChildScrollView(
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
                            return DataRow(cells: [
                              DataCell(Text(data['name'])),
                              DataCell(Text('${data['price']}')),
                              DataCell(Text('${data['discount']}')),
                              DataCell(Text('${data['pieces']}')),
                              DataCell(Text('${data['total']}')),
                            ]);
                          }).toList(),
                        ),
                      )),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SColors.primary,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Proceed Bill",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                )
              ],
            ),
          ),

          // ✅ Fixed Floating Action Button
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor:
              dark ? SColors.darkPrimaryContainer : SColors.buttonPrimary,
              foregroundColor: dark ? SColors.primary : Colors.white,
              tooltip: "Scan Product",
              onPressed: () => _startBarcodeScan(context),
              child: const Icon(Icons.barcode_reader, size: 35),
            ),
          ),

          // 🗑 Trash box while dragging
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
                    child:
                    const Icon(Icons.delete, color: Colors.white, size: 40),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ✅ Barcode scanner page
class _ScannerPage extends StatefulWidget {
  const _ScannerPage({super.key});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
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
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
