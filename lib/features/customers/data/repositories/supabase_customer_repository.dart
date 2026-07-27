import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Customer>> getCustomers(String restaurantId) async {
    final rows = await _query(restaurantId);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Customer>> searchCustomers(
    String restaurantId,
    String query,
  ) async {
    final term = query.trim();
    if (term.isEmpty) {
      return getCustomers(restaurantId);
    }
    final rows = await _query(restaurantId, term);
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _query(
    String restaurantId, [
    String? term,
  ]) async {
    var request = _client
        .from('customers')
        .select(
          'id, restaurant_id, full_name, phone, email, notes, visit_count, created_at, updated_at',
        )
        .eq('restaurant_id', restaurantId);
    if (term != null) {
      request = request.or(
        'full_name.ilike.%$term%,phone.ilike.%$term%,email.ilike.%$term%',
      );
    }
    final rows = await request.order('full_name');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> saveCustomer({
    required String restaurantId,
    String? id,
    required String fullName,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'email': email?.trim(),
      'notes': notes?.trim(),
    };
    if (id == null) {
      await _client.from('customers').insert(row);
    } else {
      await _client.from('customers').update(row).eq('id', id);
    }
  }

  @override
  Future<void> associateWithOrder({
    required String orderId,
    required String customerId,
  }) => _client.rpc(
    'associate_order_customer',
    params: {'p_order_id': orderId, 'p_customer_id': customerId},
  );

  Customer _fromRow(Map<String, dynamic> row) => Customer(
    id: row['id'] as String,
    restaurantId: row['restaurant_id'] as String,
    fullName: row['full_name'] as String,
    phone: row['phone'] as String?,
    email: row['email'] as String?,
    notes: row['notes'] as String?,
    visitCount: row['visit_count'] as int,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}
