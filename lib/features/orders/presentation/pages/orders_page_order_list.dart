part of 'orders_page.dart';

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders, required this.tables});
  final List<RestaurantOrder> orders;
  final List<DiningTable> tables;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: SizedBox(
      width: double.infinity,
      height: 358,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: false,
          child: Scrollbar(
            thumbVisibility: true,
            notificationPredicate: (notification) => notification.depth == 1,
            child: SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(
                      color: TavolaColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TavolaColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                columns: const [
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Table')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('')),
                ],
                rows: orders
                    .map(
                      (order) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#ORD-${order.orderNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: TavolaColors.textPrimary,
                              ),
                            ),
                          ),
                          DataCell(Text(_tableLabel(order))),
                          DataCell(Text(order.orderType.label)),
                          DataCell(Text(_itemsLabel(order))),
                          DataCell(
                            TavolaStatusBadge(
                              label: order.status.label,
                              color: statusColor(order.status),
                            ),
                          ),
                          DataCell(
                            Text(
                              AppFormatters.currency.format(
                                order.totalAmount / 100,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              AppFormatters.time.format(
                                order.openedAt ?? order.createdAt,
                              ),
                            ),
                          ),
                          DataCell(
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: TavolaColors.textPrimary,
                              ),
                              onPressed: () =>
                                  context.go('/orders/detail/${order.id}'),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String _tableLabel(RestaurantOrder order) {
    if (order.tableId == null) return order.orderType.label;
    return tables
            .where((table) => table.id == order.tableId)
            .firstOrNull
            ?.label ??
        'Table';
  }

  String _itemsLabel(RestaurantOrder order) {
    final units = order.items.fold<num>(0, (sum, item) => sum + item.quantity);
    return '${order.items.length} lines · $units units';
  }
}

Color statusColor(RestaurantOrderStatus status) => switch (status) {
  RestaurantOrderStatus.draft => TavolaColors.textMuted,
  RestaurantOrderStatus.open => TavolaColors.info,
  RestaurantOrderStatus.sentToKitchen ||
  RestaurantOrderStatus.preparing => TavolaColors.warning,
  RestaurantOrderStatus.ready ||
  RestaurantOrderStatus.served => TavolaColors.success,
  RestaurantOrderStatus.billed => TavolaColors.accent,
  RestaurantOrderStatus.paid => TavolaColors.success,
  RestaurantOrderStatus.cancelled => TavolaColors.error,
};
