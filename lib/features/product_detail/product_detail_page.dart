import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';

import '../../app/theme/colors.dart';
import '../../core/controllers/stock_controller.dart';
import '../stock/add_stock_page.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  ProductDetailPage({super.key, required this.productId});

  final StockController controller = Get.find<StockController>();

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    /// FIX: run loading only once, not every rebuild
    Future.microtask(() {
      if (controller.product.value?.id != productId) {
        controller.loadStockHistory(productId);
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: dark ? SColors.darkOptional : SColors.primary,
        foregroundColor: dark ? SColors.primary : Colors.white,
        tooltip: "Add new Stock",
        onPressed: () {
          Get.to(() => AddStockPage(productId: productId))!
              .then((_) => controller.loadStockHistory(productId));
        },
        child: const Icon(Icons.add, size: 35),
      ),

      body: Obx(() {
        if (controller.isLoadingHistory.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final product = controller.product.value;
        final stockList = controller.stockHistory;

        if (product == null) {
          return const Center(child: Text("Product not found."));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(height: SSizes.appBarHeight),

            // PRODUCT SUMMARY CARD
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SSizes.defaultSpace),
              child: GlossyContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: SColors.primary),
                    ),
                    SizedBox(height: SSizes.sm),
                    Divider(color: dark ? SColors.darkGrey : SColors.primary, thickness: 1),
                    SizedBox(height: SSizes.sm),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: SSizes.sm),
                      child: Column(
                        children: [
                          _infoRow(context, dark, "Category:", product.categoryName ?? "---"),
                          _infoRow(context, dark, "Barcode:", product.barcode),
                          _infoRow(context, dark, "Stock:", "${product.stockQuantity}"),
                          _infoRow(context, dark, "Price:", "${product.sellingRate}"),
                          _infoRow(context, dark, "Purchase Rate:", "${product.purchaseRate}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: SSizes.xl),

            const Text(
              "Stock History",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SColors.primary),
            ),

            if (stockList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No stock entries found."),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stockList.length,
                itemBuilder: (context, index) {
                  final entry = stockList[index];

                  return GlossyContainer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${entry.receivedDate.day}-"
                              "${entry.receivedDate.month}-"
                              "${entry.receivedDate.year}",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold, color: SColors.primary),
                        ),
                        SizedBox(height: SSizes.sm),
                        Divider(color: dark ? SColors.darkGrey : SColors.primary, thickness: 1),
                        SizedBox(height: SSizes.sm),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SSizes.sm),
                          child: Column(
                            children: [
                              _infoRow(context, dark, "Quantity:", "${entry.quantity}"),
                              _infoRow(context, dark, "Purchase:", "${entry.purchaseRate}"),
                              _infoRow(context, dark, "Selling:", "${entry.sellingRate}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            SizedBox(height: SSizes.appBarHeight),
          ],
        );
      }),
    );
  }

  Widget _infoRow(BuildContext context, bool dark, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: dark ? Colors.grey : SColors.dark)),
        Text(value,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineSmall!
                .apply(color: dark ? Colors.grey : SColors.dark)),
      ],
    );
  }
}
