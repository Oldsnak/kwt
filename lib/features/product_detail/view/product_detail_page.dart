// lib/features/product_detail/view/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';

import '../../../app/theme/colors.dart';
import '../../../core/controllers/stock_controller.dart';
import '../../../core/models/product_model.dart';
import '../../stock/view/add_stock_page.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  ProductDetailPage({super.key, required this.productId});

  final StockController controller = Get.put(StockController());

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);
    
    controller.loadStockHistory(productId); // Load on page open

    return Scaffold(

      floatingActionButton: FloatingActionButton(
        backgroundColor: dark ? SColors.darkOptional : SColors.primary,
        foregroundColor: dark ? SColors.primary : Colors.white,
        tooltip: "Add new Stock",
        onPressed: () {
          Get.to(() => AddStockPage(productId: productId))!
              .then((_) => controller.loadStockHistory(productId));
        },
        child: const Icon(Icons.add,size: 35),
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
            // --------------------------------------------------------------
            // PRODUCT SUMMARY CARD
            // --------------------------------------------------------------
            SizedBox(height: SSizes.appBarHeight,),
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
                    SizedBox(height: SSizes.sm,),
                    Divider(color: dark ? SColors.darkGrey : SColors.primary, thickness: 1),
                    SizedBox(height: SSizes.sm,),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: SSizes.sm),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Category:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                              Text(product.categoryName ?? '---',textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Barcode:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                              Text(product.barcode,textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Stock:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                              Text("${product.stockQuantity}",textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Price:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                              Text("${product.sellingRate}",textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Purchase Rate:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                              Text("${product.purchaseRate}",textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: SSizes.xl),

            // --------------------------------------------------------------
            // STOCK HISTORY TITLE
            // --------------------------------------------------------------
            const Text(
              "Stock History",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SColors.primary),
            ),

            // const SizedBox(height: 10),

            // --------------------------------------------------------------
            // STOCK HISTORY LIST
            // --------------------------------------------------------------
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
                        SizedBox(height: SSizes.sm,),
                        Divider(color: dark ? SColors.darkGrey : SColors.primary, thickness: 1),
                        SizedBox(height: SSizes.sm,),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SSizes.sm),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Quantity:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                                  Text("${entry.quantity}" ?? '---',textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Purchase:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                                  Text("${entry.purchaseRate}",textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Selling:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark)),
                                  Text("${entry.sellingRate}",textDirection: TextDirection.rtl,style: Theme.of(context).textTheme.headlineSmall!.apply(color: dark ? Colors.grey : SColors.dark),),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                },
              ),
            SizedBox(height: SSizes.appBarHeight,)
          ],
        );
      }),
    );
  }
}
