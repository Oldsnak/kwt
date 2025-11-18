// lib/features/notifications/view/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import '../../../core/controllers/notification_controller.dart';
import '../../../core/services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller =
    Get.put(NotificationController());
    Future.delayed(Duration(milliseconds: 500), () async {
      await NotificationService().checkLowStock();
      await NotificationService().checkPriceRise();
      await NotificationService().checkOverdueCustomers();
      controller.loadAll();
    });
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadAll,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return const Center(
            child: Text('No notifications 🎉'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(SSizes.defaultSpace),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final n = controller.notifications[index];
            final type = (n['type'] ?? '').toString();

            return Dismissible(
              key: ValueKey(n['id'].toString()),
              direction: DismissDirection.horizontal,
              background: _dismissBg(
                alignLeft: true,
                dark: dark,
              ),
              secondaryBackground: _dismissBg(
                alignLeft: false,
                dark: dark,
              ),
              onDismissed: (_) async {
                await controller.markRead(n['id'].toString());
              },
              child: _NotificationCard(
                data: n,
                onActionTap: () => controller.handleAction(n),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _dismissBg({required bool alignLeft, required bool dark}) {
    return Container(
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
        alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 8),
          Text('Dismiss', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onActionTap;

  const _NotificationCard({
    required this.data,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final title = (data['title'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    final createdAt = data['created_at']?.toString();

    final iconData = _iconForType(type);
    final iconColor = _colorForType(type);

    final bool hasAction = _hasAction(type);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(iconData, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: SColors.primary,
                  ),
                  icon: const Icon(Iconsax.document_text),
                  label: const Text('Generate Statement'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasAction(String type) {
    // Abhi sirf overdue_customer pe action
    if (type == 'overdue_customer') return true;
    return false;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'low_stock':
        return Iconsax.box_1;
      case 'price_rise':
        return Iconsax.graph;
      case 'overdue_customer':
        return Iconsax.warning_2;
      default:
        return Iconsax.notification;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'low_stock':
        return Colors.orange;
      case 'price_rise':
        return Colors.blue;
      case 'overdue_customer':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
