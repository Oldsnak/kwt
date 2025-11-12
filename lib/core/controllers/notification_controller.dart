// lib/features/core_controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final res = await _service.client.from('notifications').select().order('created_at', ascending: false);
      notifications.value = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('NotificationController.loadAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    await _service.client.from('notifications').update({'is_read': true}).eq('id', id);
    await loadAll();
  }
}
