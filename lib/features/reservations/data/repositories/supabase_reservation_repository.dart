import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  SupabaseReservationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Reservation>> getReservations(
    String restaurantId, {
    ReservationQuery? query,
  }) async {
    var request = _client
        .from('reservations')
        .select(
          'id, restaurant_id, branch_id, customer_id, table_id, guest_name, guest_phone, party_size, reserved_for, duration_minutes, status, notes, send_confirmation_sms, dining_tables(label)',
        )
        .eq('restaurant_id', restaurantId);
    if (query?.branchId != null) {
      request = request.eq('branch_id', query!.branchId!);
    }
    if (query?.from != null) {
      request = request.gte('reserved_for', query!.from!.toIso8601String());
    }
    if (query?.until != null) {
      request = request.lt('reserved_for', query!.until!.toIso8601String());
    }
    if (query?.statuses != null && query!.statuses!.isNotEmpty) {
      request = request.inFilter(
        'status',
        query.statuses!.map(_databaseStatus).toList(growable: false),
      );
    }
    final rows = await request.order('reserved_for');
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
      customerId: row['customer_id'] as String?,
      tableId: row['table_id'] as String?,
      notes: row['notes'] as String?,
      durationMinutes: row['duration_minutes'] as int? ?? 90,
      sendConfirmationSms: row['send_confirmation_sms'] as bool? ?? true,
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
    required String? branchId,
    String? customerId,
    String? tableId,
    required String guestName,
    String? guestPhone,
    required int partySize,
    required DateTime reservedFor,
    String? notes,
    int durationMinutes = 90,
    bool sendConfirmationSms = true,
  }) async {
    await _client.rpc(
      'save_reservation',
      params: {
        'p_reservation_id': id,
        'p_restaurant_id': restaurantId,
        'p_branch_id': branchId,
        'p_customer_id': customerId,
        'p_table_id': tableId,
        'p_guest_name': guestName.trim(),
        'p_guest_phone': guestPhone?.trim(),
        'p_party_size': partySize,
        'p_reserved_for': reservedFor.toIso8601String(),
        'p_duration_minutes': durationMinutes,
        'p_notes': notes?.trim(),
        'p_send_confirmation_sms': sendConfirmationSms,
      },
    );
  }

  @override
  Future<List<ReservationTableCandidate>> getEligibleTables({
    required String restaurantId,
    required String branchId,
    required DateTime reservedFor,
    required int partySize,
    int durationMinutes = 90,
    String? excludeReservationId,
  }) async {
    final rows = await _client.rpc(
      'list_reservation_eligible_tables',
      params: {
        'p_restaurant_id': restaurantId,
        'p_branch_id': branchId,
        'p_reserved_for': reservedFor.toIso8601String(),
        'p_party_size': partySize,
        'p_duration_minutes': durationMinutes,
        'p_exclude_reservation_id': excludeReservationId,
      },
    );
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => ReservationTableCandidate(
            id: row['id'] as String,
            label: row['label'] as String,
            capacity: row['capacity'] as int,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> assignTable({
    required String reservationId,
    required String tableId,
  }) => _client.rpc(
    'assign_reservation_table',
    params: {'p_reservation_id': reservationId, 'p_table_id': tableId},
  );

  @override
  Future<void> seatReservation({
    required String reservationId,
    String? tableId,
  }) => _client.rpc(
    'seat_reservation',
    params: {'p_reservation_id': reservationId, 'p_table_id': tableId},
  );

  @override
  Future<void> cancelReservation({required String reservationId}) => _client
      .rpc('cancel_reservation', params: {'p_reservation_id': reservationId});

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
