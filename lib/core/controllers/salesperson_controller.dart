import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/core/services/salesperson_service.dart';
import '../models/salesperson_model.dart';

class SalespersonController extends GetxController {
  final SalespersonService _service = SalespersonService();

  final salespersons = <Salesperson>[].obs;
  final isLoading = false.obs;

  // ===========================================================================
  // LOAD ALL SALESPERSONS
  // ===========================================================================
  Future<void> loadSalespersons() async {
    try {
      isLoading.value = true;
      final list = await _service.fetchSalespersons();
      salespersons.assignAll(list);
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ loadSalespersons ERROR: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // CREATE SALESPERSON
  // ===========================================================================
  Future<bool> createSalesperson({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final userId = await _service.createSalesperson(
        name: name,
        phone: phone,
        password: password,
      );

      if (userId != null) {
        await loadSalespersons();
        return true;
      }

      return false;
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ createSalesperson ERROR: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // UPDATE SALESPERSON
  // ===========================================================================
  Future<bool> updateSalesperson({
    required String id,
    required String name,
    required String phone,
  }) async {
    try {
      isLoading.value = true;

      final ok = await _service.updateSalesperson(
        salespersonId: id,
        name: name,
        phone: phone,
      );

      if (ok) {
        final idx = salespersons.indexWhere((e) => e.id == id);

        if (idx != -1) {
          final old = salespersons[idx];
          salespersons[idx] = old.copyWith(
            fullName: name,
            phone: phone,
          );
        }
      }

      return ok;
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ updateSalesperson ERROR: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // DELETE SALESPERSON
  // ===========================================================================
  Future<bool> deleteSalesperson(String id) async {
    try {
      isLoading.value = true;

      final ok = await _service.deleteSalesperson(id);

      if (ok) {
        salespersons.removeWhere((sp) => sp.id == id);
      }

      return ok;
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ deleteSalesperson ERROR: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
