import 'package:flutter/material.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

class SellItemCard extends StatelessWidget {
  final String name;
  final double price;
  final int pieces;
  final double discount; // 🔹 discount per piece in Rupees

  const SellItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.pieces,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: SSizes.sm),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.6),
        border: Border.all(
          color: SColors.primary.withOpacity(0.8),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(SSizes.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: dark
                  ? SColors.darkContainer
                  : SColors.primary.withOpacity(0.8),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(context, "Price", price.toStringAsFixed(0)),
                _infoRow(context, "Pcs", pieces.toString()),
                // 🔹 discount per piece (Rs)
                _infoRow(context, "Disc", discount.toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: SColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: SColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
