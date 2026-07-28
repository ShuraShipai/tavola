part of 'order_states_pages.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(restaurantOrdersProvider);
    final tables =
        ref.watch(restaurantTablesProvider).asData?.value ?? const [];
    final mutation = ref.watch(orderMutationControllerProvider);
    return TavolaAppShell(
      activeRoute: AppRoutes.orders,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: orders.when(
          loading: () => const TavolaLoadingIndicator(label: 'Loading order…'),
          error: (_, _) => TavolaErrorState(
            message: 'We could not load this order.',
            onRetry: () => ref.invalidate(restaurantOrdersProvider),
          ),
          data: (items) {
            final order = items.where((item) => item.id == orderId).firstOrNull;
            if (order == null) {
              return TavolaEmptyState(
                title: 'Order not found',
                message:
                    'This order may have been removed or you no longer have access.',
                icon: Icons.receipt_long_outlined,
                action: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.orders),
                  child: const Text('Back to orders'),
                ),
              );
            }
            return _LiveOrderDetails(
              order: order,
              table: tables
                  .where((table) => table.id == order.tableId)
                  .firstOrNull,
              isUpdating: mutation.isLoading,
              onEdit: order.status == RestaurantOrderStatus.open
                  ? () => context.go('/orders/edit/${order.id}')
                  : null,
              onSend: order.status == RestaurantOrderStatus.open
                  ? () => ref
                        .read(orderMutationControllerProvider.notifier)
                        .transition(
                          order: order,
                          to: RestaurantOrderStatus.sentToKitchen,
                        )
                  : null,
              onCancel:
                  order.status.canTransitionTo(RestaurantOrderStatus.cancelled)
                  ? (reason) => ref
                        .read(orderMutationControllerProvider.notifier)
                        .cancel(order: order, reason: reason)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _LiveOrderDetails extends StatelessWidget {
  const _LiveOrderDetails({
    required this.order,
    required this.table,
    required this.isUpdating,
    required this.onEdit,
    required this.onSend,
    required this.onCancel,
  });
  final RestaurantOrder order;
  final DiningTable? table;
  final bool isUpdating;
  final VoidCallback? onEdit;
  final VoidCallback? onSend;
  final Future<void> Function(String reason)? onCancel;

  @override
  Widget build(BuildContext context) {
    final placedAt = order.openedAt ?? order.createdAt;
    final tax = order.items.fold<int>(0, (sum, item) => sum + item.taxAmount);
    final subtotal = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.unitPriceAmount * item.quantity).round(),
    );
    return ConstrainedBox(
      // The handoff is a focused desktop workspace, not a full-bleed canvas.
      // This keeps the timeline and bill panel at its intended proportions.
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => context.go(AppRoutes.orders),
                child: const Text('Orders'),
              ),
              const Icon(Icons.chevron_right, size: TavolaSize.iconSmall),
              Text(
                '#ORD-${order.orderNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final summary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order #ORD-${order.orderNumber}',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(width: TavolaSpace.sm),
                      TavolaStatusBadge(
                        label: order.status.label,
                        color: _statusColor(order.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: TavolaSpace.xxs),
                  Text(
                    '${table?.label ?? order.orderType.label} · ${order.orderType.label} · Placed at ${AppFormatters.time.format(placedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TavolaColors.textSecondary,
                    ),
                  ),
                ],
              );
              final actions = Wrap(
                // The handoff uses a deliberately tight 10px action rhythm.
                // Keep it fixed here; compact layouts still wrap cleanly.
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Print setup will be available shortly.'),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print'),
                  ),
                  OutlinedButton(
                    onPressed: isUpdating ? null : onEdit,
                    child: const Text('Edit Order'),
                  ),
                  if (onSend != null)
                    FilledButton(
                      onPressed: isUpdating ? null : onSend,
                      child: const Text('Send to kitchen'),
                    ),
                  if (onCancel != null)
                    OutlinedButton(
                      onPressed: isUpdating
                          ? null
                          : () async {
                              final reason = await showDialog<String>(
                                context: context,
                                builder: (_) => _CancelOrderDialog(
                                  order: order,
                                  tableLabel: table?.label,
                                ),
                              );
                              if (reason != null && context.mounted) {
                                await onCancel!(reason);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TavolaColors.error,
                      ),
                      child: const Text('Cancel Order'),
                    ),
                ],
              );
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: TavolaSpace.lg),
                    actions,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  const SizedBox(height: TavolaSpace.md),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: TavolaSpace.lg),
          _LiveTimeline(order: order, placedAt: placedAt),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _OrderItemsCard(order: order)),
                      const SizedBox(width: TavolaSpace.lg),
                      SizedBox(
                        width: 300,
                        child: _BillSummary(
                          subtotal: subtotal,
                          tax: tax,
                          total: order.totalAmount,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _OrderItemsCard(order: order),
                      const SizedBox(height: TavolaSpace.lg),
                      _BillSummary(
                        subtotal: subtotal,
                        tax: tax,
                        total: order.totalAmount,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveTimeline extends StatelessWidget {
  const _LiveTimeline({required this.order, required this.placedAt});
  final RestaurantOrder order;
  final DateTime placedAt;

  @override
  Widget build(BuildContext context) {
    final current = switch (order.status) {
      RestaurantOrderStatus.draft || RestaurantOrderStatus.open => 0,
      RestaurantOrderStatus.sentToKitchen => 0,
      RestaurantOrderStatus.preparing => 1,
      RestaurantOrderStatus.ready => 2,
      RestaurantOrderStatus.served ||
      RestaurantOrderStatus.billed ||
      RestaurantOrderStatus.paid => 3,
      RestaurantOrderStatus.cancelled => 0,
    };
    const labels = ['Placed', 'Preparing', 'Ready', 'Served'];
    return TavolaPanel(
      child: Row(
        children: List.generate(labels.length, (index) {
          final complete =
              index <= current &&
              order.status != RestaurantOrderStatus.cancelled;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : complete
                            ? TavolaColors.accent
                            : TavolaColors.border,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: complete
                            ? TavolaColors.accent
                            : TavolaColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: complete
                              ? TavolaColors.accent
                              : TavolaColors.border,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        complete ? Icons.check : Icons.circle_outlined,
                        size: 16,
                        color: complete ? Colors.white : TavolaColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == labels.length - 1
                            ? Colors.transparent
                            : index < current
                            ? TavolaColors.accent
                            : TavolaColors.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TavolaSpace.xs),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  index == 0
                      ? AppFormatters.time.format(placedAt)
                      : index == 1 &&
                            order.status == RestaurantOrderStatus.sentToKitchen
                      ? 'Queued'
                      : index == current
                      ? order.status.label
                      : '—',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TavolaColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});
  final RestaurantOrder order;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const Divider(),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text('${item.quantity}', textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                    AppFormatters.currency.format(item.unitPriceAmount / 100),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppFormatters.currency.format(item.lineTotalAmount / 100),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BillSummary extends StatelessWidget {
  const _BillSummary({
    required this.subtotal,
    required this.tax,
    required this.total,
  });
  final int subtotal;
  final int tax;
  final int total;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        _amount('Subtotal', subtotal),
        if (tax > 0) _amount('Tax', tax),
        const Divider(),
        _amount('Total', total, strong: true),
      ],
    ),
  );
  Widget _amount(String label, int amount, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            color: strong
                ? TavolaColors.textPrimary
                : TavolaColors.textSecondary,
          ),
        ),
        Text(
          AppFormatters.currency.format(amount / 100),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Color _statusColor(RestaurantOrderStatus status) => switch (status) {
  RestaurantOrderStatus.open ||
  RestaurantOrderStatus.draft => TavolaColors.info,
  RestaurantOrderStatus.sentToKitchen ||
  RestaurantOrderStatus.preparing => TavolaColors.warning,
  RestaurantOrderStatus.ready ||
  RestaurantOrderStatus.served => TavolaColors.success,
  RestaurantOrderStatus.billed => TavolaColors.accent,
  RestaurantOrderStatus.paid => TavolaColors.success,
  RestaurantOrderStatus.cancelled => TavolaColors.error,
};

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog({required this.order, required this.tableLabel});
  final RestaurantOrder order;
  final String? tableLabel;

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  static const _reasons = [
    'Guest changed their mind',
    'Item unavailable',
    'Order placed by mistake',
    'Other',
  ];
  String _reason = _reasons.first;

  @override
  Widget build(BuildContext context) {
    final units = widget.order.items.fold<num>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final table = widget.tableLabel ?? widget.order.orderType.label;
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 468,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TavolaSpace.lg,
                TavolaSpace.lg,
                TavolaSpace.lg,
                TavolaSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: TavolaColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: TavolaColors.error,
                    ),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  Text(
                    'Cancel Order #ORD-${widget.order.orderNumber}?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: TavolaSpace.xs),
                  Text(
                    'This order has already been sent to the kitchen. Cancelling '
                    'will remove all ${widget.order.items.length} line items '
                    '($units units) from $table\'s bill. This cannot be undone.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TavolaColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  Text(
                    'Reason for cancellation',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: TavolaSpace.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _reason,
                    items: _reasons
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _reason = value!),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: TavolaColors.border),
            Padding(
              padding: const EdgeInsets.all(TavolaSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Order'),
                  ),
                  const SizedBox(width: TavolaSpace.sm),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _reason),
                    style: FilledButton.styleFrom(
                      backgroundColor: TavolaColors.error,
                    ),
                    child: const Text('Cancel Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
