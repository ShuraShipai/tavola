import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/kitchen/domain/entities/kitchen_ticket.dart';
import 'package:tavola/features/kitchen/domain/repositories/kitchen_ticket_repository.dart';
import 'package:tavola/features/kitchen/domain/usecases/update_kitchen_ticket_status.dart';

void main() {
  test('advances queued tickets to preparing only', () async {
    final repository = _FakeKitchenTicketRepository();
    await UpdateKitchenTicketStatus(repository)(
      ticketId: 'ticket-1',
      currentStatus: KitchenTicketStatus.queued,
    );
    expect(repository.status, KitchenTicketStatus.preparing);
  });

  test('does not advance served tickets', () async {
    final repository = _FakeKitchenTicketRepository();
    await expectLater(
      UpdateKitchenTicketStatus(repository)(
        ticketId: 'ticket-1',
        currentStatus: KitchenTicketStatus.served,
      ),
      throwsStateError,
    );
    expect(repository.status, isNull);
  });
}

class _FakeKitchenTicketRepository implements KitchenTicketRepository {
  KitchenTicketStatus? status;
  @override
  Future<List<KitchenTicket>> getTickets(String restaurantId) async => const [];
  @override
  Future<void> updateStatus({
    required String ticketId,
    required KitchenTicketStatus nextStatus,
  }) async {
    status = nextStatus;
  }

  @override
  Stream<List<KitchenTicket>> watchTickets(String restaurantId) =>
      const Stream.empty();
}
