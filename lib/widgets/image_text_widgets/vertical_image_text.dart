import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';

class VerticalImageText extends StatelessWidget {
  const VerticalImageText({
    super.key,
    required this.image,
    required this.title,
    this.textColor=SColors.white,
    this.backgroundColor,
    this.onTap,
    this.imgTheme=true
  });

  final String image, title;
  final Color textColor;
  final Color? backgroundColor;
  final bool imgTheme;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = backgroundColor!=SColors.white;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: SSizes.spaceBtwItems),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              // Circular Icon
              width: 56,
              height: 56,
              padding: EdgeInsets.all(SSizes.sm),
              decoration: BoxDecoration(
                color: backgroundColor ?? (dark ? SColors.black: SColors.white),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Image(image: AssetImage(image), fit: BoxFit.cover, color: imgTheme ? dark ? SColors.light: SColors.dark : null,),
              ),
            ),

            //Text
            const SizedBox(height: SSizes.spaceBtwItems/2,),
            SizedBox(
              width: 55,
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.apply(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            )
          ],
        ),
      ),
    );
  }
}