import 'package:get/get.dart';
import 'package:kwt/core/services/salesperson_service.dart';
import '../models/salesperson_model.dart';

class SalespersonController extends GetxController {
  final SalespersonService _service = SalespersonService();

  final salespersons = <Salesperson>[].obs;
  final isLoading = false.obs;

  /// LOAD ALL SALESPERSONS
  Future<void> loadSalespersons() async {
    try {
      isLoading.value = true;
      final res = await _service.fetchSalespersons();
      salespersons.assignAll(res);
    } finally {
      isLoading.value = false;
    }
  }

  /// ADD SALESPERSON
  Future<void> addSalesperson(Salesperson sp) async {
    await _service.addSalesperson(sp);
    salespersons.add(sp);
  }

  /// UPDATE SALESPERSON
  Future<void> updateSalesperson(String id, Salesperson sp) async {
    await _service.updateSalesperson(id, sp);

    final idx = salespersons.indexWhere((p) => p.id == id);
    if (idx != -1) salespersons[idx] = sp;
  }

  /// DELETE SALESPERSON
  Future<void> deleteSalesperson(String id) async {
    await _service.deleteSalesperson(id);
    salespersons.removeWhere((p) => p.id == id);
  }
}
