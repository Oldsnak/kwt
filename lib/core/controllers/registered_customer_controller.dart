// lib/features/core_controllers/registered_customer_controller.dart

import 'package:get/get.dart';
import 'package:kwt/core/services/customer_service.dart';
import '../models/customer_model.dart';
import 'auth_controller.dart';

class RegisteredCustomerController extends GetxController {
  final CustomerService _service = CustomerService();

  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  late final AuthController auth; // to check role

  @override
  void onInit() {
    super.onInit();
    auth = Get.find<AuthController>();
    load();
  }

  // ============================================================
  // LOAD CUSTOMERS (allowed only for Owner)
  // ============================================================
  Future<void> load() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final res = await _service.fetchCustomers();
      customers.value = res;

    } catch (e) {
      errorMessage.value = "Failed to load customers: $e";
      print('❌ RegisteredCustomerController.load error: $e');

    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ADD
  // ============================================================
  Future<bool> addCustomer(Customer c) async {
    if (!auth.isOwner) {
      errorMessage.value = "Only owner can add customers.";
      return false;
    }

    try {
      await _service.addCustomer(c);
      await load();
      return true;

    } catch (e) {
      errorMessage.value = "Failed to add customer: $e";
      return false;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================
  Future<bool> updateCustomer(String id, Customer c) async {
    if (!auth.isOwner) {
      errorMessage.value = "Only owner can update customers.";
      return false;
    }

    try {
      await _service.updateCustomer(id, c);
      await load();
      return true;

    } catch (e) {
      errorMessage.value = "Failed to update: $e";
      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================
  Future<bool> deleteCustomer(String id) async {
    if (!auth.isOwner) {
      errorMessage.value = "Only owner can delete customers.";
      return false;
    }

    try {
      await _service.deleteCustomer(id);
      customers.removeWhere((x) => x.id == id);
      return true;

    } catch (e) {
      errorMessage.value = "Failed to delete: $e";
      return false;
    }
  }
}
