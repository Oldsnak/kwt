import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';

class DecorationCircle extends StatelessWidget {
  const DecorationCircle({
    super.key,
    this.height,
    this.width,
    this.mainBox=false,
    this.reverse=false
  });

  final double? height;
  final double? width;
  final bool mainBox;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: mainBox ? 40 : height,
      width: mainBox ? 5 : width,
      decoration: BoxDecoration(
          color: SColors.primary,
          borderRadius: mainBox
            ? reverse
              ? BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5))
              : BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5))
            : BorderRadius.circular(10)
      ),
    );
  }
}
