import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';

class BillService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Bill>> fetchBills() async {
    final response = await _client.from('bills').select('*, sales(*)');
    return (response as List)
        .map((json) => Bill.fromJson(json))
        .toList();
  }

  Future<void> addBill(Bill bill) async {
    await _client.from('bills').insert(bill.toJson());
    // Optionally also insert its Sale line items
    for (final sale in bill.items) {
      await _client.from('sales').insert(sale.toJson());
    }
  }

  Future<void> deleteBill(String id) async {
    await _client.from('bills').delete().eq('id', id);
    await _client.from('sales').delete().eq('bill_no', id);
  }
}
