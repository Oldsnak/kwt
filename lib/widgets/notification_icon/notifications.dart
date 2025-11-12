import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/helpers.dart';
import '../custom_appbar/appbar.dart';
import '../snack_bar/GlossySnackBar.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dummy notifications
  List<String> notifications = List.generate(10, (index) => "Notification $index");

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: SAppBar(
        showBackArrow: true,
        title: const Text("Notifications"),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (BuildContext context, int index) {
          final item = notifications[index];

          return Dismissible(
            key: Key(item),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              setState(() {
                notifications.removeAt(index);
              });

              if (direction == DismissDirection.startToEnd) {
                GlossySnackBar.show(
                  context,
                  message: "$item marked as read ✅",
                );
              } else {
                GlossySnackBar.show(
                  context,
                  message: "$item deleted ❌",
                  isError: true,
                );
              }
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(SSizes.borderRadiusMd),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(SSizes.borderRadiusMd),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SSizes.defaultSpace,
                vertical: SSizes.sm,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF3C3C3C) : SColors.borderPrimary,
                border: Border.all(
                  color: dark ? SColors.darkContainer : SColors.softGrey,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(SSizes.borderRadiusMd),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: SColors.primary),
                title: Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("This is detail for $item"),
              ),
            ),
          );

        },
      ),
    );
  }
}
