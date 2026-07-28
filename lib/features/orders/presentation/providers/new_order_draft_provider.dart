import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/restaurant_order.dart';

/// Ephemeral, UI-only state for the New Order workspace.
///
/// Persistence and order mutations remain the responsibility of
/// [OrderMutationController] in `restaurant_order_providers.dart`.
final newOrderDraftProvider =
    NotifierProvider<NewOrderDraftController, NewOrderDraft>(
      NewOrderDraftController.new,
    );

class NewOrderDraft {
  NewOrderDraft({
    this.orderType = RestaurantOrderType.dineIn,
    this.tableId,
    this.categoryId,
    this.searchQuery = '',
    Map<String, int> quantities = const {},
  }) : _quantities = Map.unmodifiable(quantities);

  final RestaurantOrderType orderType;
  final String? tableId;
  final String? categoryId;
  final String searchQuery;
  final Map<String, int> _quantities;

  /// Menu-item quantities keyed by menu item id. Values are always positive.
  Map<String, int> get quantities => _quantities;

  int quantityFor(String menuItemId) => _quantities[menuItemId] ?? 0;

  NewOrderDraft copyWith({
    RestaurantOrderType? orderType,
    String? tableId,
    bool clearTableId = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? searchQuery,
    Map<String, int>? quantities,
  }) {
    return NewOrderDraft(
      orderType: orderType ?? this.orderType,
      tableId: clearTableId ? null : tableId ?? this.tableId,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      quantities: quantities ?? _quantities,
    );
  }
}

class NewOrderDraftController extends Notifier<NewOrderDraft> {
  @override
  NewOrderDraft build() => NewOrderDraft();

  void selectOrderType(RestaurantOrderType orderType) {
    state = state.copyWith(
      orderType: orderType,
      clearTableId: orderType != RestaurantOrderType.dineIn,
    );
  }

  void selectTable(String? tableId) {
    state = state.copyWith(tableId: tableId, clearTableId: tableId == null);
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void addItem(String menuItemId) {
    setQuantity(menuItemId, state.quantityFor(menuItemId) + 1);
  }

  void removeItem(String menuItemId) {
    setQuantity(menuItemId, state.quantityFor(menuItemId) - 1);
  }

  void setQuantity(String menuItemId, int quantity) {
    final quantities = Map<String, int>.of(state.quantities);
    if (quantity <= 0) {
      quantities.remove(menuItemId);
    } else {
      quantities[menuItemId] = quantity;
    }
    state = state.copyWith(quantities: quantities);
  }

  void reset() => state = NewOrderDraft();
}
