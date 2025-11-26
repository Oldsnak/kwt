import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import 'package:flutter/material.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // FETCH ALL CUSTOMERS (Owner + Salesperson read allowed by RLS)
  // ===========================================================================
  Future<List<Customer>> fetchCustomers() async {
    try {
      final response =
      await _client.from('customers').select().order('name');

      return (response as List)
          .map((json) => Customer.fromMap(json))
          .toList();
    } catch (e) {
      SnackBar(content:Text("❌ fetchCustomers ERROR: $e"),);

      // RLS error → salesperson not allowed?
      throw Exception("Unable to load customers. Access denied.");
    }
  }

  // ===========================================================================
  // INSERT CUSTOMER (OWNER ONLY — RLS will handle)
  // ===========================================================================
  Future<void> addCustomer(Customer customer) async {
    try {
      await _client.from('customers').insert(customer.toMap());
    } catch (e) {
      SnackBar(content:Text("❌ addCustomer ERROR: $e"),);
      throw Exception("You are not allowed to add customers.");
    }
  }

  // ===========================================================================
  // UPDATE CUSTOMER (OWNER ONLY)
  // ===========================================================================
  Future<void> updateCustomer(String id, Customer customer) async {
    try {
      await _client.from('customers').update(customer.toMap()).eq('id', id);
    } catch (e) {
      SnackBar(content:Text("❌ updateCustomer ERROR: $e"),);
      throw Exception("You are not allowed to update customers.");
    }
  }

  // ===========================================================================
  // DELETE CUSTOMER (OWNER ONLY)
  // ===========================================================================
  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      SnackBar(content:Text("❌ deleteCustomer ERROR: $e"),);
      throw Exception("You are not allowed to delete customers.");
    }
  }

  // ===========================================================================
  // FETCH SINGLE CUSTOMER BY ID
  // ===========================================================================
  Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Customer.fromMap(response);
    } catch (e) {
      SnackBar(content:Text("❌ getCustomerById ERROR: $e"),);
      throw Exception("Unable to fetch customer details.");
    }
  }

  // ===========================================================================
  // SEARCH CUSTOMERS (Owner + allowed Salesperson)
  // ===========================================================================
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('customers')
          .select()
          .or("name.ilike.%$query%,cnic.ilike.%$query%")
          .order('name');

      return (response as List)
          .map((json) => Customer.fromMap(json))
          .toList();
    } catch (e) {
      SnackBar(content:Text("❌ searchCustomers ERROR: $e"),);

      throw Exception("You are not allowed to search customers.");
    }
  }
}
