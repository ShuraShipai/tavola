import '../entities/menu_entities.dart';
import '../repositories/menu_repository.dart';

class GetMenuCatalog {
  const GetMenuCatalog(this._repository);
  final MenuRepository _repository;

  Future<MenuCatalog> call(String restaurantId) =>
      _repository.getCatalog(restaurantId);
}
