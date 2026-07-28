part of 'order_status_filter_tabs.dart';

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TavolaSpace.xxs,
        vertical: TavolaSpace.sm,
      ),
      margin: const EdgeInsets.only(right: TavolaSpace.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? TavolaColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected
              ? TavolaColors.textPrimary
              : TavolaColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

bool matchesOrderFilter(OrderStatusFilter filter, RestaurantOrder order) =>
    switch (filter) {
      OrderStatusFilter.all =>
        order.status != RestaurantOrderStatus.paid &&
            order.status != RestaurantOrderStatus.cancelled,
      OrderStatusFilter.placed =>
        order.status == RestaurantOrderStatus.open ||
            order.status == RestaurantOrderStatus.sentToKitchen,
      OrderStatusFilter.preparing =>
        order.status == RestaurantOrderStatus.preparing,
      OrderStatusFilter.ready =>
        order.status == RestaurantOrderStatus.ready ||
            order.status == RestaurantOrderStatus.served,
      OrderStatusFilter.held => order.status == RestaurantOrderStatus.draft,
    };
