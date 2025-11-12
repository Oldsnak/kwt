import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_strings.dart';
import '../notification_icon/notification_Icon.dart';
import 'appbar.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(STexts.homeAppbarTitle, style: Theme.of(context).textTheme.labelMedium!.apply(color: SColors.black),),
          Text(STexts.homeAppbarSubTitle, style: Theme.of(context).textTheme.headlineSmall!.apply(color: SColors.black),),
        ],
      ),
      actions: [NotificationIcon()],
    );
  }
}