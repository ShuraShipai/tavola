import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class GetRestaurantReservations {
  const GetRestaurantReservations(this._repository);
  final ReservationRepository _repository;
  Future<List<Reservation>> call(String restaurantId) =>
      _repository.getReservations(restaurantId);
}
