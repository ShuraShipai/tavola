part of 'order_states_pages.dart';

class EditOrderPage extends ConsumerStatefulWidget {
  const EditOrderPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends ConsumerState<EditOrderPage> {
  List<_EditableOrderLine>? _draft;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(restaurantOrdersProvider);
    final catalog = ref.watch(menuCatalogProvider);
    final mutation = ref.watch(orderMutationControllerProvider);
    return orders.when(
      loading: () => const _OrderShell(
        title: 'Edit Order',
        subtitle: 'Loading order…',
        child: TavolaLoadingIndicator(label: 'Loading order…'),
      ),
      error: (error, _) => _OrderShell(
        title: 'Edit Order',
        subtitle: 'Order unavailable',
        child: TavolaErrorState(
          message: 'Could not load this order: $error',
          onRetry: () => ref.invalidate(restaurantOrdersProvider),
        ),
      ),
      data: (orders) {
        final order = _findOrder(orders);
        if (order == null) {
          return _OrderShell(
            title: 'Edit Order',
            subtitle: 'Order unavailable',
            child: TavolaErrorState(
              message: 'This order is no longer available.',
              onRetry: () => context.go('/orders/active'),
            ),
          );
        }
        _draft ??= order.items.map(_EditableOrderLine.fromOrderLine).toList();
        final canSave =
            _draft!.isNotEmpty &&
            _draft!.every((line) => line.menuItemId != null) &&
            !mutation.isLoading;
        return _OrderShell(
          title: 'Edit Order #ORD-${order.orderNumber}',
          subtitle:
              '${order.orderType.label} · Add or remove items before sending updates to the kitchen',
          actions: [
            _Action('Discard Changes', Icons.undo_outlined, onTap: _discard),
            _Action(
              mutation.isLoading ? 'Saving…' : 'Save Changes',
              Icons.save_outlined,
              primary: true,
              enabled: canSave,
              onTap: () => _save(order),
            ),
          ],
          child: _EditableTicket(
            lines: _draft!,
            menuItems:
                catalog.asData?.value.items
                    .where((item) => item.isOrderable)
                    .toList(growable: false) ??
                const [],
            onDecrease: (index) => _changeQuantity(index, -1),
            onIncrease: (index) => _changeQuantity(index, 1),
            onRemove: _remove,
            onAddItem: _addItem,
          ),
        );
      },
    );
  }

  RestaurantOrder? _findOrder(List<RestaurantOrder> orders) {
    for (final order in orders) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _changeQuantity(int index, int adjustment) {
    setState(() {
      final line = _draft![index];
      final quantity = line.quantity + adjustment;
      if (quantity <= 0) {
        _draft!.removeAt(index);
      } else {
        _draft![index] = line.copyWith(quantity: quantity);
      }
    });
  }

  void _remove(int index) => setState(() => _draft!.removeAt(index));

  void _addItem(MenuItem item) {
    setState(() {
      final index = _draft!.indexWhere((line) => line.menuItemId == item.id);
      if (index >= 0) {
        _draft![index] = _draft![index].copyWith(
          quantity: _draft![index].quantity + 1,
        );
      } else {
        _draft!.add(
          _EditableOrderLine(
            menuItemId: item.id,
            name: item.name,
            unitPriceAmount: item.priceMinor,
            quantity: 1,
          ),
        );
      }
    });
  }

  void _discard() => setState(() => _draft = null);

  Future<void> _save(RestaurantOrder order) async {
    final lines = _draft!;
    if (lines.any((line) => line.menuItemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A removed menu item cannot be saved. Restore it from the menu first.',
          ),
        ),
      );
      return;
    }
    await ref
        .read(orderMutationControllerProvider.notifier)
        .save(
          UpdateOrderInput(
            orderId: order.id,
            restaurantId: order.restaurantId,
            orderType: order.orderType,
            tableId: order.tableId,
            customerId: order.customerId,
            notes: order.notes,
            items: lines
                .map(
                  (line) => OrderItemInput(
                    menuItemId: line.menuItemId!,
                    quantity: line.quantity,
                    notes: line.notes,
                  ),
                )
                .toList(growable: false),
          ),
        );
    if (!mounted) return;
    final state = ref.read(orderMutationControllerProvider);
    if (state.hasError) return;
    context.go('/orders/detail/${order.id}');
  }
}

class _EditableOrderLine {
  const _EditableOrderLine({
    required this.menuItemId,
    required this.name,
    required this.unitPriceAmount,
    required this.quantity,
    this.notes,
  });
  factory _EditableOrderLine.fromOrderLine(OrderLine line) =>
      _EditableOrderLine(
        menuItemId: line.menuItemId,
        name: line.name,
        unitPriceAmount: line.unitPriceAmount,
        quantity: line.quantity,
        notes: line.notes,
      );
  final String? menuItemId;
  final String name;
  final int unitPriceAmount;
  final num quantity;
  final String? notes;
  int get lineTotalAmount => (unitPriceAmount * quantity).round();
  _EditableOrderLine copyWith({num? quantity}) => _EditableOrderLine(
    menuItemId: menuItemId,
    name: name,
    unitPriceAmount: unitPriceAmount,
    quantity: quantity ?? this.quantity,
    notes: notes,
  );
}
