part of 'orders_page.dart';

class _OrderDetailsDialog extends ConsumerWidget {
  const _OrderDetailsDialog({required this.order});
  final RestaurantOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutation = ref.watch(orderMutationControllerProvider);
    final next = _nextStatuses(order.status);
    return AlertDialog(
      title: Text('Order #ORD-${order.orderNumber}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaStatusBadge(
              label: order.status.label,
              color: statusColor(order.status),
            ),
            const SizedBox(height: TavolaSpace.md),
            ...order.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} × ${AppFormatters.currency.format(item.unitPriceAmount / 100)}',
                ),
                trailing: Text(
                  AppFormatters.currency.format(item.lineTotalAmount / 100),
                ),
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total  ${AppFormatters.currency.format(order.totalAmount / 100)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (mutation.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: TavolaSpace.sm),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        if (order.status == RestaurantOrderStatus.open)
          TextButton(
            onPressed: mutation.isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (_) => _OrderComposerDialog(order: order),
                    );
                  },
            child: const Text('Edit'),
          ),
        if (order.status == RestaurantOrderStatus.open)
          FilledButton(
            onPressed: mutation.isLoading
                ? null
                : () async {
                    await ref
                        .read(orderMutationControllerProvider.notifier)
                        .transition(
                          order: order,
                          to: RestaurantOrderStatus.sentToKitchen,
                        );
                    if (context.mounted &&
                        !ref.read(orderMutationControllerProvider).hasError) {
                      Navigator.pop(context);
                    }
                  },
            child: const Text('Send to kitchen'),
          ),
        if (next.isNotEmpty)
          PopupMenuButton<RestaurantOrderStatus>(
            enabled: !mutation.isLoading,
            onSelected: (status) async {
              await ref
                  .read(orderMutationControllerProvider.notifier)
                  .transition(order: order, to: status);
              if (context.mounted &&
                  !ref.read(orderMutationControllerProvider).hasError) {
                Navigator.pop(context);
              }
            },
            itemBuilder: (_) => next
                .map(
                  (status) => PopupMenuItem(
                    value: status,
                    child: Text('Mark ${status.label}'),
                  ),
                )
                .toList(),
            child: const Padding(
              padding: EdgeInsets.all(TavolaSpace.sm),
              child: Text('Change status'),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

List<RestaurantOrderStatus> _nextStatuses(RestaurantOrderStatus status) =>
    RestaurantOrderStatus.values
        .where(status.canTransitionTo)
        .where(
          (next) =>
              next != RestaurantOrderStatus.preparing &&
              next != RestaurantOrderStatus.ready &&
              next != RestaurantOrderStatus.served,
        )
        .toList();
