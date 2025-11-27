// lib/widgets/products/product_cards/product_card_vertical.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/helpers.dart';
import 'card/rounded_container.dart';

class ProductCardVertical extends StatelessWidget {
  const ProductCardVertical({
    super.key,
    required this.remaining,
    required this.totalStock,   // remaining + sold (last 7 days window from controller)
    required this.price,
    required this.name,
    required this.totalProfit,  // net profit (last 7 days)
    required this.sold,         // total sold (last 7 days)
    this.onTap,
    required this.purchasePrice,
  });

  final int remaining;
  final int totalStock;
  final int sold;
  final int price;
  final int purchasePrice;
  final String name;
  final double totalProfit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    // percentage of stock remaining
    final double percent = totalStock == 0
        ? 0
        : (remaining / totalStock).clamp(0.0, 1.0);

    final double avgProfit = sold == 0 ? 0 : (totalProfit / sold)-purchasePrice;
    final double netProfit=totalProfit-(purchasePrice*sold);

    String format1(double v) {
      final s = v.toStringAsFixed(1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: dark ? Color(0xFF3C3C3C):SColors.borderPrimary,
          borderRadius: BorderRadius.circular(SSizes.productImageRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          // border: Border.all(
          //   color: dark ? SColors.darkGrey : SColors.black,
          //   width: 1.2,
          // ),
        ),
        child: Column(
          children: [
            /// ------------------ TOP: Circular stock indicator ------------------
            TRoundedContainer(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(SSizes.sm),
              backgroundColor: dark ? SColors.dark : SColors.buttonDisabled,
              child: Center(
                child: CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 15,
                  backgroundColor: dark ? SColors.darkOptional : Colors.grey.shade400,
                  progressColor: SColors.primary,
                  percent: percent,
                  center: Text(
                    remaining.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
            ),

            const SizedBox(height: SSizes.spaceBtwItems / 2),

            /// ------------------ BOTTOM: Info rows ------------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: double.infinity),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white,),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(height: SSizes.xs),

                  // Price Row
                  _infoRow(
                    context: context,
                    label: 'Price:',
                    value: price.toString(),
                  ),

                  // Avg Profit Row
                  _infoRow(
                    context: context,
                    label: 'Avg Profit:',
                    value: format1(avgProfit),
                  ),

                  // Net Profit Row
                  _infoRow(
                    context: context,
                    label: 'Net Profit',
                    value: format1(netProfit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
