import 'package:flutter/cupertino.dart';

import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/helpers.dart';

class CircularImage extends StatelessWidget {
  const CircularImage({
    super.key,
    this.fit=BoxFit.cover,
    required this.image,
    this.isNetworkImage=false,
    this.overlayColor,
    this.backgroundColor,
    this.width = 56,
    this.height = 56,
    this.padding = SSizes.sm,
    this.applyOverlayColor=true,
  });

  final BoxFit? fit;
  final String image;
  final bool isNetworkImage, applyOverlayColor;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;

  @override
  Widget build(BuildContext context) {
    final dark= SHelperFunctions.isDarkMode(context);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? (dark ? SColors.black : SColors.white),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Image(
          color: applyOverlayColor ? overlayColor ?? (dark ? SColors.white : SColors.black):null,
          image: isNetworkImage ? NetworkImage(image) : AssetImage(image) as ImageProvider,
        ),
      ),
    );
  }
}
