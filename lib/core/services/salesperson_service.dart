// lib/core/services/salesperson_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salesperson_model.dart';

class SalespersonService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // FETCH ALL SALESPERSONS  (RLS SAFE)
  // ============================================================
  Future<List<Salesperson>> fetchSalespersons() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'salesperson')
          .order('created_at');

      return response
          .map<Salesperson>((json) => Salesperson.fromJson(json))
          .toList();
    } catch (e) {
      SnackBar(content: Text("❌ fetchSalespersons error: $e"));
      rethrow;
    }
  }

  // ============================================================
  // CREATE SALESPERSON (Edge function)
  // ============================================================
  Future<String?> createSalesperson({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final result = await _client.functions.invoke(
        'create_salesperson',
        body: {
          "name": name,
          "phone": phone,
          "password": password,
        },
      );

      final data = result.data;

      if (data == null || data["success"] != true) {
        throw Exception(data?["error"] ?? "Failed to create salesperson.");
      }

      return data["user_id"];
    } catch (e) {
      SnackBar(content: Text("❌ createSalesperson error: $e"));
      rethrow;
    }
  }

  // ============================================================
  // UPDATE SALESPERSON PROFILE
  // ============================================================
  Future<bool> updateSalesperson({
    required String salespersonId,
    required String name,
    required String phone,
  }) async {
    try {
      final result = await _client.functions.invoke(
        'update_salesperson_profile',
        body: {
          "salesperson_id": salespersonId,
          "name": name,
          "phone": phone,
        },
      );

      final data = result.data;
      return data?["success"] == true;
    } catch (e) {
      SnackBar(content: Text("❌ updateSalesperson error: $e"));
      return false;
    }
  }

  // ============================================================
  // ENABLE / DISABLE SALESPERSON
  // ============================================================
  Future<bool> toggleSalespersonAccess({
    required String salespersonId,
    required bool status,
  }) async {
    try {
      final result = await _client.functions.invoke(
        'toggle_salesperson_access',
        body: {
          "salesperson_id": salespersonId,
          "status": status,
        },
      );

      final data = result.data;
      return data?["success"] == true;
    } catch (e) {
      SnackBar(content: Text("❌ toggleSalespersonAccess error: $e"));
      return false;
    }
  }

  // ============================================================
  // DELETE SALESPERSON (safe)
  // ============================================================
  Future<bool> deleteSalesperson(String salespersonId) async {
    try {
      final result = await _client.functions.invoke(
        'delete_salesperson',
        body: {
          "salesperson_id": salespersonId,
        },
      );

      final data = result.data;
      return data?["success"] == true;
    } catch (e) {
      SnackBar(content: Text("❌ deleteSalesperson error: $e"));
      return false;
    }
  }
}
