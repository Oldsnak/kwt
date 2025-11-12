import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/controllers/category_controller.dart';
import 'package:kwt/core/controllers/product_controller.dart';
import 'package:kwt/widgets/custom_appbar/custom_appbar.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/layouts/grid_layout.dart';
import 'package:kwt/widgets/products/product_cards/product_card_vertical.dart';
import '../../product_detail/view/product_detail_page.dart';
import 'widgets/dashboard_categories.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final CategoryController categoryController = Get.put(CategoryController());
  final ProductController productController = Get.put(ProductController());
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: isDark ? SColors.dark : Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔼 HEADER AREA (green background + search + categories)
            PrimaryHeaderContainer(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SSizes.defaultSpace,
                  right: SSizes.defaultSpace,
                  bottom: SSizes.spaceBtwSections,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomAppbar(),

                    const SizedBox(height: SSizes.spaceBtwItems),

                    /// 🔍 Search box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSizes.md, vertical: SSizes.xs),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(SSizes.productImageRadius),
                        border: Border.all(color: SColors.grey)
                      ),
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
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Search in Store',
                                hintStyle:
                                TextStyle(color: Colors.white54),
                              ),
                              onChanged: productController.updateSearch,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SSizes.spaceBtwItems),

                    /// 🏷 Categories pills
                    const Text(
                      "Categories",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18, color: SColors.dark),
                    ),
                    const SizedBox(height: SSizes.sm),
                    DashboardCategories(),

                  ],
                ),
              ),
            ),

            /// 🔽 BODY: product cards grid (same as purana UI)
            Padding(
              padding: const EdgeInsets.all(SSizes.defaultSpace),
              child: Obx(() {
                final products = productController.filteredProducts;
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
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

                    // yahan abhi profit & totalStock ko simple set kiya hai.
                    // Later hum Sales/Stock se real numbers nikal lenge.
                    final remaining = p.stockQuantity ?? 0;
                    final totalStock =
                    remaining == 0 ? 1 : remaining; // avoid /0
                    final price = p.sellingRate?.toInt() ?? 0;
                    const totalProfit = 0;

                    return ProductCardVertical(
                      remaining: remaining,
                      total_stock: totalStock,
                      price: price,
                      name: p.name,
                      total_profit: totalProfit,
                      onTap: () => Get.to(() => ProductDetailPage(
                        productId: p.id,
                        name: p.name,
                        stockQuantity: p.stockQuantity ?? 0,
                        sellingRate: p.sellingRate?.toDouble() ?? 0.0,
                        totalProfit: 0, // you can replace later with real calculation
                      )),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
