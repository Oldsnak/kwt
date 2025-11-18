import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/features/settings/view/notifications_page.dart';
import '../../app/theme/colors.dart';
import '../../core/controllers/notification_controller.dart';
import 'notifications.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController c = Get.put(NotificationController());

    return Obx(() {
      final count = c.unreadCount.value;

      return Stack(
        children: [
          IconButton(
            onPressed: () async {
              await Get.to(() => NotificationsPage());
              c.loadAll(); // refresh after coming back
            },
            icon: Icon(Icons.notifications, color: SColors.black),
          ),

          // ⭐ Only show bubble if unread > 0
          if (count > 0)
            Positioned(
              right: 8,
              top: 5,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
