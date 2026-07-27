import '../entities/kitchen_ticket.dart';

abstract interface class KitchenTicketRepository {
  Future<List<KitchenTicket>> getTickets(String restaurantId);
  Stream<List<KitchenTicket>> watchTickets(String restaurantId);
  Future<void> updateStatus({
    required String ticketId,
    required KitchenTicketStatus nextStatus,
  });
}
