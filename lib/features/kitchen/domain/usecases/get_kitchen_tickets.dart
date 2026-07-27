import '../entities/kitchen_ticket.dart';
import '../repositories/kitchen_ticket_repository.dart';

class GetKitchenTickets {
  const GetKitchenTickets(this._repository);
  final KitchenTicketRepository _repository;

  Future<List<KitchenTicket>> call(String restaurantId) =>
      _repository.getTickets(restaurantId);
}
