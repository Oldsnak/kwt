import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/device_utility.dart';
import '../../../core/utils/helpers.dart';

class SearchContainer extends StatelessWidget {
  const SearchContainer({
    super.key,
    required this.text,
    this.icon = Icons.search,
    this.showBackground=true,
    this.showBorder=true,
    this.onTap,
    this.padding=const EdgeInsets.symmetric(horizontal: SSizes.defaultSpace)
  });

  final String text;
  final IconData? icon;
  final bool showBackground, showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark=SHelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Container(
          width: SDeviceUtils.getScreenWidth(context),
          padding: EdgeInsets.all(SSizes.md),
          decoration: BoxDecoration(
              color: showBackground
                  ? dark
                    ? SColors.black
                    : SColors.light
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(SSizes.cardRdiusLg),
              border: showBorder ? Border.all(color: SColors.grey) : null
          ),
          child: Row(
            children: [
              Icon(icon, color: SColors.darkerGrey,),
              SizedBox(width: SSizes.spaceBtwItems,),
              Text(text, style: Theme.of(context).textTheme.bodySmall,),
            ],
          ),
        ),
      ),
    );
  }
}