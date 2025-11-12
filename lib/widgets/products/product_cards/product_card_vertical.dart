import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/helpers.dart';
import 'card/rounded_container.dart';

class ProductCardVertical extends StatelessWidget {
  const ProductCardVertical({
    super.key,
    required this.remaining,
    required this.total_stock,
    required this.price,
    required this.name,
    required this.total_profit,
    this.onTap, // 👈 add this
  });

  final int remaining;
  final int total_stock;
  final int price;
  final String name;
  final int total_profit;
  final VoidCallback? onTap; // 👈 add this

  @override
  Widget build(BuildContext context) {
    int sold=total_stock-remaining;
    final dark=SHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: SColors.darkGrey.withOpacity(0.1),
              blurRadius: 50,
              spreadRadius: 7,
              offset: Offset(0, 2)
            )
          ],
          borderRadius: BorderRadius.circular(SSizes.productImageRadius),
          color: dark ? Color(0xFF3C3C3C):SColors.borderPrimary
        ),
        child: Column(
          children: [
            // Thumbnail, wishlist Button, Discount Tag
            TRoundedContainer(
              height: 180,
              width: double.infinity,
              padding: EdgeInsets.all(SSizes.sm),
              backgroundColor: dark ? SColors.dark : SColors.buttonDisabled,
              child: CircularPercentIndicator(
                radius: 60,
                lineWidth: 15,
                backgroundColor: dark ? SColors.darkOptional : Colors.grey.shade400,
                progressColor: SColors.primary,
                percent: remaining / total_stock,
                center: Text(
                  remaining.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
            SizedBox(height: SSizes.spaceBtwItems/2,),

            // -- Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: double.infinity,),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis, // 👈 this adds "..."
                    maxLines: 1, // 👈 limit to one line
                    softWrap: false, // 👈 prevent wrapping to next line
                  ),
                  // Divider(color: TColors.primary,),
                  SizedBox(height: SSizes.xs,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Price:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                      Text('$price', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold),),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Avg Profit:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                      Text(
                        sold != 0
                            ? (() {
                          final value = total_profit / sold;
                          final formatted = value.toStringAsFixed(1);
                          // Remove trailing ".0" if it's a whole number
                          return formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted;
                        })()
                            : '0',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Profit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                      Text('$total_profit', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold),),
                    ],
                  ),
                ],
              ),
            ),

            // Spacer(),
            //
            // Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     border: Border.all( color: TColors.primary),
            //     borderRadius: BorderRadius.only(
            //       bottomLeft: Radius.circular(TSizes.cardRdiusMd+5),
            //       bottomRight: Radius.circular(TSizes.productImageRadius)
            //     )
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       //Price
            //       Flexible(
            //         flex: 3,
            //         child: Center(child: Text("Price: $price", style: Theme.of(context).textTheme.headlineSmall,)),
            //       ),
            //       Flexible(
            //         child: Container(
            //           decoration: BoxDecoration(
            //             color: TColors.primary,
            //             borderRadius: BorderRadius.only(
            //               topLeft: Radius.circular(TSizes.cardRdiusMd),
            //               bottomRight: Radius.circular(TSizes.productImageRadius)
            //             )
            //           ),
            //           child: SizedBox(
            //             width: TSizes.iconLg*1.2,
            //             height: TSizes.iconLg*1.2,
            //             child: Center(
            //               child: Icon(
            //                 Icons.add,
            //                 color: dark?TColors.dark:TColors.light,
            //               ),
            //             )
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}






