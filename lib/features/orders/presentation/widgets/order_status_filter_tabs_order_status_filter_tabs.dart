part of 'order_status_filter_tabs.dart';

class OrderStatusFilterTabs extends StatelessWidget {
  const OrderStatusFilterTabs({
    required this.selected,
    required this.orders,
    required this.onSelected,
    super.key,
  });

  final OrderStatusFilter selected;
  final List<RestaurantOrder> orders;
  final ValueChanged<OrderStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TavolaColors.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: OrderStatusFilter.values
            .map(
              (filter) => _FilterTab(
                label: '${_label(filter)} (${_count(filter)})',
                selected: selected == filter,
                onTap: () => onSelected(filter),
              ),
            )
            .toList(growable: false),
      ),
    ),
  );

  int _count(OrderStatusFilter filter) => filter == OrderStatusFilter.all
      ? orders.length
      : orders.where((order) => matchesOrderFilter(filter, order)).length;

  String _label(OrderStatusFilter filter) => switch (filter) {
    OrderStatusFilter.all => 'All',
    OrderStatusFilter.placed => 'Placed',
    OrderStatusFilter.preparing => 'Preparing',
    OrderStatusFilter.ready => 'Ready',
    OrderStatusFilter.held => 'Held',
  };
}
