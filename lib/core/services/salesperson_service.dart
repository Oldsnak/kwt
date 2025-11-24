import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salesperson_model.dart';

class SalespersonService {
  final SupabaseClient _client = Supabase.instance.client;

  /// FETCH ALL SALESPERSONS
  Future<List<Salesperson>> fetchSalespersons() async {
    final response = await _client
        .from('user_profiles')
        .select()
        .eq('role', 'salesperson');

    return (response as List)
        .map((json) => Salesperson.fromJson(json))
        .toList();
  }

  /// ADD NEW SALESPERSON
  Future<void> addSalesperson(Salesperson salesperson) async {
    await _client.from('user_profiles').insert({
      'id': salesperson.id,
      'full_name': salesperson.fullName,
      'email': salesperson.email,
      'phone': salesperson.phone,
      'role': 'salesperson',
    });
  }

  /// UPDATE SALESPERSON
  Future<void> updateSalesperson(String id, Salesperson salesperson) async {
    await _client.from('user_profiles').update({
      'full_name': salesperson.fullName,
      'email': salesperson.email,
      'phone': salesperson.phone,
    }).eq('id', id);
  }

  /// DELETE SALESPERSON + AUTH USER
  Future<void> deleteSalesperson(String id) async {
    await _client.from('user_profiles').delete().eq('id', id);
    await _client.auth.admin.deleteUser(id);
  }
}
