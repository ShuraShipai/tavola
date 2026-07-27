import '../entities/discount_entities.dart';
import '../repositories/discount_repository.dart';

class GetDiscountCatalog {
  const GetDiscountCatalog(this._repository);
  final DiscountRepository _repository;
  Future<DiscountCatalog> call(String restaurantId) =>
      _repository.getCatalog(restaurantId);
}
