import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/helpers.dart';
import '../../images/t_rounded_image.dart';
import '../../texts/product_price_text.dart';
import '../../texts/product_title_text.dart';
import '../../texts/brand_title_text_verified_icon.dart';
import 'card/rounded_container.dart';

class TProductCardhohrizontal extends StatelessWidget {
  const TProductCardhohrizontal({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = SHelperFunctions.isDarkMode(context);
    return Container(
      width: 310,
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SSizes.productImageRadius),
        color: isDark ? Color(0xFF3C3C3C):SColors.lightContainer
      ),
      child: Row(
        children: [
          // Thumbnail
          TRoundedContainer(
            height: 120,
            padding: EdgeInsets.all(SSizes.sm),
            backgroundColor: isDark ? SColors.dark : SColors.light,
            child: Stack(
              children: [
                SizedBox(height: 120, width: 120,child: RoundedImage(imageUrl: SImages.productImage1, applyImageRadius: true, backgroundColor: Colors.transparent,)),

                Positioned(
                  top: 0,
                  child: TRoundedContainer(
                    radius: SSizes.sm,
                    backgroundColor: SColors.secondary.withOpacity(0.8),
                    padding: EdgeInsets.symmetric(horizontal: SSizes.sm, vertical: SSizes.xs),
                    child: Text('25%', style: Theme.of(context).textTheme.labelLarge!.apply(color: SColors.black),),
                  ),
                ),

                // Positioned(
                //     top: -9,
                //     right: -10,
                //     // child: TCircularIcon(
                //     //   icon: Icons.favorite,
                //     //   color: Colors.red,
                //     //   backgroundColor: Colors.transparent,
                //     // )
                // )
              ],
            ),
          ),

          // Details
          SizedBox(
            width: 172,
            child: Padding(
              padding: EdgeInsets.only(top: SSizes.sm, left: SSizes.sm),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductTitleText(title: 'Green Nike Half Sleeves Shirt', smallSize: true,),
                      SizedBox(height: SSizes.spaceBtwItems/2,),
                      BrandTitleWithVerifiedIcon(title: 'Nike'),
                    ],
                  ),

                  Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: ProductPriceText(price: "256.0",)),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: SColors.dark,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(SSizes.cardRdiusMd),
                            bottomRight: Radius.circular(SSizes.productImageRadius),
                          )
                        ),
                        child: SizedBox(
                          width: SSizes.iconLg*1.2,
                          height: SSizes.iconLg*1.2,
                          child: Center(child: Icon(Icons.add, color: SColors.white,),),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
