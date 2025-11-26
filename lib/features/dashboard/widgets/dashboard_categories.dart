import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/controllers/category_controller.dart';
import 'package:kwt/core/controllers/product_controller.dart';

class DashboardCategories extends StatelessWidget {
  DashboardCategories({super.key});

  final CategoryController categoryController = Get.find<CategoryController>();
  final ProductController productController = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = categoryController.categories;
      final selectedId = categoryController.selectedCategoryId.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: 1750,
          // constraints: const BoxConstraints(minWidth: 500),
          child: Wrap(
            children: [
              /// ALL category
              _CategoryChip(
                label: 'All',
                isSelected: selectedId == null,
                onTap: () {
                  categoryController.selectCategory(null);
                  productController.filterByCategory(null);
                },
              ),

              /// REAL CATEGORIES
              ...categories.map((c) {
                return _CategoryChip(
                  label: c.name,
                  isSelected: selectedId == (c.id ?? ''),
                  onTap: () {
                    if (c.id != null) {
                      categoryController.selectCategory(c.id);
                      productController.filterByCategory(c.id);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SSizes.xs,
          horizontal: SSizes.md,
        ),
        margin: const EdgeInsets.only(
          right: SSizes.xs,
          bottom: SSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? SColors.primary : SColors.dark,
          borderRadius: BorderRadius.circular(SSizes.lg),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : SColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
