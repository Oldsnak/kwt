// lib/features/dashboard/view/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/controllers/category_controller.dart';
import 'package:kwt/core/controllers/product_controller.dart';
import 'package:kwt/features/dashboard/widgets/dashboard_categories.dart';
import 'package:kwt/widgets/custom_appbar/custom_appbar.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/layouts/grid_layout.dart';
import 'package:kwt/widgets/products/product_cards/product_card_vertical.dart';
import '../../core/controllers/notification_controller.dart';
import '../product_detail/product_detail_page.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final CategoryController categoryController = Get.put(CategoryController());
  final ProductController productController = Get.put(ProductController());
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NotificationController notificationController = Get.put(NotificationController());

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔼 HEADER: Search + Categories
            PrimaryHeaderContainer(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SSizes.defaultSpace,
                  bottom: SSizes.spaceBtwSections,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: SSizes.defaultSpace,
                        bottom: SSizes.spaceBtwItems,

                      ),
                      child: Column(
                        children: [
                          const CustomAppbar(),
                          const SizedBox(height: SSizes.spaceBtwItems),

                          /// 🔍 SEARCH BOX
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: SSizes.md, vertical: SSizes.xs),
                            decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(SSizes.productImageRadius),
                                border: Border.all(color: SColors.grey)),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.white70),
                                const SizedBox(width: SSizes.sm),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      hintText: 'Search in Store',
                                      hintStyle: TextStyle(color: Colors.white54),
                                    ),
                                    onChanged: (query) {
                                      productController.updateSearch(query);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // const SizedBox(height: SSizes.spaceBtwItems),

                    /// 🏷 CATEGORY TITLE
                    const Text(
                      "Categories",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: SColors.dark,
                      ),
                    ),

                    const SizedBox(height: SSizes.sm),

                    /// CATEGORY LISTING
                    DashboardCategories(),
                  ],
                ),
              ),
            ),

            /// 🔽 PRODUCT GRID LIST
            Padding(
              padding: const EdgeInsets.all(SSizes.defaultSpace),
              child: Obx(() {
                final products = productController.filteredProducts;

                if (productController.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }

                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No products found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                return GridLayout(
                  itemCount: products.length,
                  itemBuilder: (_, index) {
                    final p = products[index];
                    final int remaining = p.stockQuantity;
                    final int purchase_price=p.purchaseRate.round();
                    final int sold = p.totalSold ?? 0;
                    final int totalStock = remaining + sold;
                    final int price = p.sellingRate.round();
                    final double netProfit = p.totalProfit ?? 0;

                    return ProductCardVertical(
                      remaining: remaining,
                      purchasePrice: purchase_price,
                      sold: sold,
                      price: price,
                      name: p.name,
                      totalProfit: netProfit,
                      totalStock: totalStock,
                      onTap: () => Get.to(() => ProductDetailPage(productId: p.id!)),
                    );


                  },
                );
              }),
            ),
            SizedBox(height: SSizes.appBarHeight,)
          ],
        ),
      ),
    );
  }
}
