import '../entities/kitchen_ticket.dart';
import '../repositories/kitchen_ticket_repository.dart';

class WatchKitchenTickets {
  const WatchKitchenTickets(this._repository);
  final KitchenTicketRepository _repository;

  Stream<List<KitchenTicket>> call(String restaurantId) =>
      _repository.watchTickets(restaurantId);
}
