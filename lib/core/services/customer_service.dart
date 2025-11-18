// lib/core/services/customer_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all customers
  Future<List<Customer>> fetchCustomers() async {
    final response = await _client.from('customers').select().order('name');

    return (response as List)
        .map((json) => Customer.fromMap(json))
        .toList();
  }

  /// Insert a new customer
  Future<void> addCustomer(Customer customer) async {
    await _client.from('customers').insert(customer.toMap());
  }

  /// Update customer by id
  Future<void> updateCustomer(String id, Customer customer) async {
    await _client.from('customers').update(customer.toMap()).eq('id', id);
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  /// Fetch a single customer by id
  Future<Customer?> getCustomerById(String id) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return Customer.fromMap(response);
  }

  /// Search customers by name or CNIC
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _client
        .from('customers')
        .select()
        .or("name.ilike.%$query%,cnic.ilike.%$query%")
        .order('name');

    return (response as List)
        .map((json) => Customer.fromMap(json))
        .toList();
  }
}
