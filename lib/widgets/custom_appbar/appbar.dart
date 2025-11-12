import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/device_utility.dart';
import '../../core/utils/helpers.dart';

class SAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = false,
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;

  @override
  Widget build(BuildContext context) {
    final isDark= SHelperFunctions.isDarkMode(context);
    return Padding(
      // padding: EdgeInsets.symmetric(horizontal: SSizes.md),
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: showBackArrow
            ? IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_rounded, color: isDark?SColors.white:Colors.black,))
            : leadingIcon!= null? IconButton(onPressed: leadingOnPressed, icon: Icon(leadingIcon)):null,
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(SDeviceUtils.getAppBarHeight());

}