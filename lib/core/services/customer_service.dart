import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Customer>> fetchCustomers() async {
    final response = await _client.from('customers').select();
    return (response as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<void> addCustomer(Customer customer) async {
    await _client.from('customers').insert(customer.toJson());
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    await _client.from('customers').update(customer.toJson()).eq('id', id);
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}
