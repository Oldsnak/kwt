// lib/features/core_controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;     // ⭐ NEW

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }


  // ----------------------------------------------------------
  // LOAD ONLY UNREAD (NOT DISMISSED) NOTIFICATIONS
  // ----------------------------------------------------------
  Future<void> loadAll() async {
    try {
      isLoading.value = true;

      final res = await _service.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      notifications.value = list;

      // ⭐ Count unread
      unreadCount.value = list.where((n) => n['is_read'] == false).length;

    } catch (e) {
      print('NotificationController.loadAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------------------------------------
  // MARK AS READ (DISMISS)
  // ----------------------------------------------------------
  Future<void> markRead(String id) async {
    await _service.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    await loadAll();  // update count + list
  }

  // ----------------------------------------------------------
  // ACTION HANDLER (for action-type notifications)
  // ----------------------------------------------------------
  Future<void> handleAction(Map<String, dynamic> n) async {
    final type = (n['type'] ?? '').toString();
    final meta = (n['meta'] as Map?)?.cast<String, dynamic>();

    try {
      if (type == 'overdue_customer' && meta != null) {
        final customerId = meta['customer_id']?.toString();
        final customerName = meta['customer_name']?.toString();
        if (customerId != null) {
          await _service.generateCustomerStatementPdfAndShare(
            customerId,
            customerName: customerName,
          );
        }
      }

      // You can add more action types here (e.g. open product page for low_stock)

      // After action, mark as read so it doesn't show again
      await markRead(n['id'].toString());
    } catch (e) {
      print('NotificationController.handleAction error: $e');
    }
  }
}

