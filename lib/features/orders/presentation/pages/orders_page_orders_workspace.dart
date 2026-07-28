part of 'orders_page.dart';

class _OrdersWorkspace extends ConsumerStatefulWidget {
  const _OrdersWorkspace({required this.orders, this.initialTableId});

  final List<RestaurantOrder> orders;
  final String? initialTableId;

  @override
  ConsumerState<_OrdersWorkspace> createState() => _OrdersWorkspaceState();
}

class _OrdersWorkspaceState extends ConsumerState<_OrdersWorkspace> {
  OrderStatusFilter _filter = OrderStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final tables =
        ref.watch(restaurantTablesProvider).asData?.value ?? const [];
    final visibleOrders = widget.orders.where(_matchesFilter).toList()
      ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: TavolaSpace.xxs),
                    Text(
                      'Orders currently in progress across the restaurant',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go(
                  '${AppRoutes.ordersNew}${widget.initialTableId == null ? '' : '?table=${Uri.encodeQueryComponent(widget.initialTableId!)}'}',
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Order'),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          const OrderViewTabs(),
          const SizedBox(height: TavolaSpace.md),
          OrderStatusFilterTabs(
            selected: _filter,
            orders: widget.orders,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: TavolaSpace.lg),
          if (visibleOrders.isEmpty)
            const TavolaEmptyState(
              title: 'No active orders',
              message: 'Orders that are in progress will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          else
            _OrderList(orders: visibleOrders, tables: tables),
        ],
      ),
    );
  }

  bool _matchesFilter(RestaurantOrder order) =>
      matchesOrderFilter(_filter, order);
}
