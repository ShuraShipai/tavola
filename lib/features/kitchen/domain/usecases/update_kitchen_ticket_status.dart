import '../entities/kitchen_ticket.dart';
import '../repositories/kitchen_ticket_repository.dart';

class UpdateKitchenTicketStatus {
  const UpdateKitchenTicketStatus(this._repository);
  final KitchenTicketRepository _repository;

  Future<void> call({
    required String ticketId,
    required KitchenTicketStatus currentStatus,
  }) async {
    final nextStatus = currentStatus.next;
    if (nextStatus == null) {
      throw StateError('This kitchen ticket cannot be advanced further.');
    }
    await _repository.updateStatus(ticketId: ticketId, nextStatus: nextStatus);
  }
}
