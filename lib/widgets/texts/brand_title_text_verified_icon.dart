import 'package:flutter/material.dart';
import 'package:kwt/widgets/texts/brand_title_text.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/enums.dart';

class BrandTitleWithVerifiedIcon extends StatelessWidget {
  const BrandTitleWithVerifiedIcon({
    super.key,
    required this.title,
    this.maxLines=1,
    this.textColor,
    this.iconColor = SColors.primary,
    this.textAlign = TextAlign.center,
    this.brandTextSize=TextSizes.small,
  });

  final String title;
  final int maxLines;
  final Color? textColor, iconColor;
  final TextAlign? textAlign;
  final TextSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: BrandTitleText(
            title: title,
            color: textColor,
            maxLines: maxLines,
            textAlign: textAlign,
            brandTextSize: brandTextSize,
          ),
        ),
        SizedBox(width: SSizes.xs,),
        Icon(Icons.verified, color: iconColor, size: SSizes.iconXs,),
        // Text(
        //   "Zara",
        //   overflow: TextOverflow.ellipsis,
        //   maxLines: 1,
        //   style: Theme.of(context).textTheme.labelMedium,
        // ),
        // SizedBox(width: TSizes.xs,),
        // Icon(Icons.verified, color: TColors.primary, size: TSizes.iconXs,),
      ],
    );
  }
}