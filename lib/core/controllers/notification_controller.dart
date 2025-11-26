// lib/features/core_controllers/notification_controller.dart

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/core/services/notification_service.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  UserProfile? _currentUser;
  final _client = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    _loadUserAndInit();
  }

  // ===========================================================================
  // LOAD USER FIRST THEN LOAD NOTIFICATIONS
  // ===========================================================================
  Future<void> _loadUserAndInit() async {
    _currentUser = await AuthService.fetchCurrentUserProfile();
    await loadAll();
    // _subscribeRealtime();  // optional
  }

  // ===========================================================================
  // LOAD NOTIFICATIONS FOR CURRENT USER ONLY
  // ===========================================================================
  Future<void> loadAll() async {
    if (_currentUser == null) return;

    try {
      isLoading.value = true;

      final res = await _service.client
          .from("notifications")
          .select()
          .eq("user_id", _currentUser!.id)
          .order("created_at", ascending: false);

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      notifications.value = list;

      unreadCount.value =
          list.where((n) => (n["is_read"] == false)).length;
    } catch (e) {
      print("❌ NotificationController.loadAll error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // MARK AS READ
  // ===========================================================================
  Future<void> markRead(String id) async {
    try {
      await _service.client
          .from("notifications")
          .update({"is_read": true})
          .eq("id", id);

      await loadAll();
    } catch (e) {
      print("❌ markRead error: $e");
    }
  }

  // ===========================================================================
  // HANDLE ACTION NOTIFICATIONS
  // ===========================================================================
  Future<void> handleAction(Map<String, dynamic> n) async {
    try {
      final type = (n["type"] ?? "").toString();
      final meta =
          (n["meta"] as Map?)?.cast<String, dynamic>() ?? {};

      if (type == "overdue_customer") {
        final customerId = meta["customer_id"]?.toString();
        final customerName = meta["customer_name"]?.toString();

        if (customerId != null) {
          await _service.generateCustomerStatementPdfAndShare(
            customerId,
            customerName: customerName,
          );
        }
      }

      // More action handlers can be added here...

      await markRead(n["id"].toString());
    } catch (e) {
      print("❌ handleAction error: $e");
    }
  }

  // ===========================================================================
  // OPTIONAL: REALTIME NOTIFICATIONS (Push alerts)
  // ===========================================================================
  void _subscribeRealtime() {
    _client
        .channel("public:notifications")
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "notifications",
      callback: (payload) async {
        await loadAll();
      },
    )
        .subscribe();
  }
}
