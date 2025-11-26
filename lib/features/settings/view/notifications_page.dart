// lib/features/notifications/view/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import '../../../core/controllers/notification_controller.dart';
import '../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationController());

    /// 🔥 ONCE-FETCH AT PAGE OPEN
    Future.microtask(() async {
      await _triggerBackgroundChecks();
      controller.loadAll();
    });
  }

  /// --------------------------------------------------------
  /// BACKGROUND ALERT GENERATORS
  /// --------------------------------------------------------
  Future<void> _triggerBackgroundChecks() async {
    try {
      await NotificationService().checkLowStock();
      await NotificationService().checkPriceRise();
      await NotificationService().checkOverdueCustomers();
    } catch (_) {
      // ignore, RLS may block in some cases
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        // backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _triggerBackgroundChecks();
              controller.loadAll();
            },
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

            return Dismissible(
              key: ValueKey(n['id'].toString()),
              direction: DismissDirection.horizontal,
              background: _dismissBg(alignLeft: true, dark: dark),
              secondaryBackground: _dismissBg(alignLeft: false, dark: dark),

              onDismissed: (_) async {
                await controller.markRead(n['id'].toString());
                controller.loadAll(); // 🔥 instant refresh
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
    final createdAtRaw = data['created_at']?.toString();

    String formattedDate = createdAtRaw ?? "";
    if (createdAtRaw != null) {
      try {
        final dt = DateTime.parse(createdAtRaw);
        formattedDate = DateFormat("dd MMM yyyy • hh:mm a").format(dt);
      } catch (_) {}
    }

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

            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),

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
    return type == 'overdue_customer';
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
