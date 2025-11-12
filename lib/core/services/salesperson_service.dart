import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salesperson_model.dart';

class SalespersonService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Salesperson>> fetchSalespersons() async {
    final response = await _client.from('salespersons').select();
    return (response as List)
        .map((json) => Salesperson.fromJson(json))
        .toList();
  }

  Future<void> addSalesperson(Salesperson salesperson) async {
    await _client.from('salespersons').insert(salesperson.toJson());
  }

  Future<void> updateSalesperson(String id, Salesperson salesperson) async {
    await _client.from('salespersons').update(salesperson.toJson()).eq('id', id);
  }

  Future<void> deleteSalesperson(String id) async {
    await _client.from('salespersons').delete().eq('id', id);
  }
}
