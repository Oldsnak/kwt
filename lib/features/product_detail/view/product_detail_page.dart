import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/features/stock/view/add_stock_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String name;
  final int stockQuantity;
  final double sellingRate;
  final double totalProfit;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.name,
    required this.stockQuantity,
    required this.sellingRate,
    required this.totalProfit,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final RxList<Map<String, dynamic>> stockEntries = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _fetchStockEntries();
  }

  Future<void> _fetchStockEntries() async {
    try {
      // 1️⃣ Fetch stock history
      final response = await _client
          .from('stock_entries')
          .select()
          .eq('product_id', widget.productId)
          .order('received_date', ascending: false);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // 2️⃣ If there’s no stock history, create one record using product info
      if (data.isEmpty) {
        final product = await _client
            .from('products')
            .select()
            .eq('id', widget.productId)
            .single();

        data.add({
          'received_date': product['created_at'],
          'quantity': product['stock_quantity'] ?? 0,
          'selling_rate': product['selling_rate'] ?? 0,
        });
      }

      stockEntries.assignAll(data);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stock history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    // Dynamic percentage logic (temporary based on available stock)
    final percent = (widget.stockQuantity > 0 ? widget.stockQuantity / (widget.stockQuantity + 1) : 0.0)
        .clamp(0.0, 1.0);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: SSizes.appBarHeight),

              // 🔵 Circular Percent Indicator
              CircularPercentIndicator(
                radius: 70,
                lineWidth: 15,
                backgroundColor: dark ? SColors.darkGrey : Colors.grey.shade300,
                progressColor: SColors.primary,
                percent: percent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.stockQuantity.toString(),
                      style: const TextStyle(
                        color: SColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      'Price: ${widget.sellingRate.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: SColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
              ),

              const SizedBox(height: SSizes.spaceBtwItems),

              // 🔵 Product Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .apply(color: SColors.primary)),
                  Text('Profit: ${widget.totalProfit}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .apply(color: SColors.primary, fontWeightDelta: 2)),
                ],
              ),

              const SizedBox(height: SSizes.spaceBtwSections),

              // 🔵 Stock Entries
              Obx(() {
                if (stockEntries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No stock history found.'),
                  );
                }

                return Column(
                  children: stockEntries.map((entry) {
                    final date = DateTime.parse(entry['received_date']);
                    final formatted =
                        "${date.day.toString().padLeft(2, '0')}-${_monthName(date.month)}, ${date.year}";
                    return _StockDetailCard(
                      date: formatted,
                      itemCount: entry['quantity'] ?? 0,
                      price: entry['selling_rate'] ?? 0,
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: SSizes.appBarHeight * 2),
            ],
          ),
        ),
      ),

      // 🔵 Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: dark ? SColors.darkSecondary : SColors.primary,
        foregroundColor: dark ? SColors.primary : Colors.white,
        tooltip: "Add new Stock",
        onPressed: () {
          Get.to(() => AddStockPage(productId: widget.productId));
        },
        child: const Icon(Icons.add, size: 35),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _StockDetailCard extends StatelessWidget {
  final String date;
  final int itemCount;
  final double price;

  const _StockDetailCard({
    required this.date,
    required this.itemCount,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SSizes.md),
      margin: const EdgeInsets.only(bottom: SSizes.spaceBtwItems),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(date,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .apply(color: SColors.primary, fontWeightDelta: 2)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Item Count:",
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold)),
              Text("$itemCount",
                  style: const TextStyle(
                      color: SColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Price:",
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold)),
              Text("$price",
                  style: const TextStyle(
                      color: SColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
