// lib/features/core_controllers/registered_customer_controller.dart
import 'package:get/get.dart';
import 'package:kwt/core/services/customer_service.dart';

import '../models/customer_model.dart';

class RegisteredCustomerController extends GetxController {
  final CustomerService _service = CustomerService();

  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      final res = await _service.fetchCustomers();
      customers.value = res;
    } catch (e) {
      print('RegisteredCustomerController.load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer c) async {
    await _service.addCustomer(c);
    await load();
  }

  Future<void> updateCustomer(String id, Customer c) async {
    await _service.updateCustomer(id, c);
    await load();
  }

  Future<void> deleteCustomer(String id) async {
    await _service.deleteCustomer(id);
    customers.removeWhere((x) => x.id == id);
  }
}
