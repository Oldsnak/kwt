import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';

class RoundedImage extends StatelessWidget {
  const RoundedImage({
    super.key,
    this.border,
    this.padding,
    this.onPressed,
    this.width,
    this.height,
    this.applyImageRadius=true,
    required this.imageUrl,
    this.fit=BoxFit.contain,
    this.backgroundColor=SColors.light,
    this.isNetworkImage=false,
    this.borderRadius=SSizes.md
  });

  final double? width, height;
  final double borderRadius;
  final String imageUrl;
  final bool applyImageRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final bool isNetworkImage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(color: backgroundColor,border: border,borderRadius: BorderRadius.circular(SSizes.md),),
        child: ClipRRect(
          borderRadius: applyImageRadius ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
          child: Image(fit: fit, image: isNetworkImage?NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider,),
        )
        ,
      ),
    );
  }
}