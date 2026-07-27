import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  SupabaseReservationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Reservation>> getReservations(String restaurantId) async {
    final rows = await _client
        .from('reservations')
        .select(
          'id, restaurant_id, branch_id, guest_name, guest_phone, party_size, reserved_for, status, dining_tables(label)',
        )
        .eq('restaurant_id', restaurantId)
        .order('reserved_for');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList(growable: false);
  }

  Reservation _fromRow(Map<String, dynamic> row) {
    final table = row['dining_tables'] as Map<String, dynamic>?;
    return Reservation(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      branchId: row['branch_id'] as String,
      guestName: row['guest_name'] as String,
      guestPhone: row['guest_phone'] as String?,
      partySize: row['party_size'] as int,
      reservedFor: DateTime.parse(row['reserved_for'] as String),
      status: ReservationStatus.values.byName(
        _camelCase(row['status'] as String),
      ),
      tableLabel: table?['label'] as String?,
    );
  }

  String _camelCase(String value) {
    final parts = value.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join();
  }

  @override
  Future<void> saveReservation({
    required String restaurantId,
    String? id,
    required String branchId,
    String? customerId,
    String? tableId,
    required String guestName,
    String? guestPhone,
    required int partySize,
    required DateTime reservedFor,
    String? notes,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'branch_id': branchId,
      'customer_id': customerId,
      'table_id': tableId,
      'guest_name': guestName.trim(),
      'guest_phone': guestPhone?.trim(),
      'party_size': partySize,
      'reserved_for': reservedFor.toIso8601String(),
      'notes': notes?.trim(),
    };
    if (id == null) {
      await _client.from('reservations').insert(row);
    } else {
      await _client.from('reservations').update(row).eq('id', id);
    }
  }

  @override
  Future<void> transition({
    required String reservationId,
    required ReservationStatus status,
    String? tableId,
  }) => _client.rpc(
    'transition_reservation',
    params: {
      'p_reservation_id': reservationId,
      'p_status': _databaseStatus(status),
      'p_table_id': tableId,
    },
  );

  String _databaseStatus(ReservationStatus status) =>
      status == ReservationStatus.noShow ? 'no_show' : status.name;
}
