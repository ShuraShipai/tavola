import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../menu/domain/entities/menu_entities.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../tables/domain/entities/dining_table.dart';
import '../../../tables/presentation/providers/dining_table_providers.dart';
import '../../domain/entities/restaurant_order.dart';
import '../../domain/repositories/restaurant_order_repository.dart';
import '../providers/restaurant_order_providers.dart';
import '../widgets/order_status_filter_tabs.dart';
import '../widgets/order_view_tabs.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({this.initialTableId, super.key});

  final String? initialTableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(restaurantOrdersProvider);
    return TavolaAppShell(
      activeRoute: '/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: orders.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(TavolaSpace.xl),
            child: TavolaLoadingIndicator(label: 'Loading orders…'),
          ),
          error: (error, _) => TavolaErrorState(
            message: 'We could not load your restaurant orders.',
            onRetry: () => ref.invalidate(restaurantOrdersProvider),
          ),
          data: (data) =>
              _OrdersWorkspace(orders: data, initialTableId: initialTableId),
        ),
      ),
    );
  }
}

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
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _OrderComposerDialog(
                    initialTableId: widget.initialTableId,
                  ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                        AppFormatters.currency.format(order.totalAmount / 100),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _OrderDetailsDialog(order: order),
                        ),
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

class _OrderComposerDialog extends ConsumerStatefulWidget {
  const _OrderComposerDialog({this.order, this.initialTableId});
  final RestaurantOrder? order;
  final String? initialTableId;
  @override
  ConsumerState<_OrderComposerDialog> createState() =>
      _OrderComposerDialogState();
}

class _OrderComposerDialogState extends ConsumerState<_OrderComposerDialog> {
  final Map<String, int> _quantities = {};
  RestaurantOrderType _type = RestaurantOrderType.dineIn;
  String? _tableId;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order != null) {
      _type = order.orderType;
      _tableId = order.tableId;
      for (final line in order.items) {
        if (line.menuItemId != null) {
          _quantities[line.menuItemId!] = line.quantity.toInt();
        }
      }
    } else if (widget.initialTableId != null) {
      _tableId = widget.initialTableId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(restaurantTablesProvider);
    final menu = ref.watch(menuCatalogProvider);
    final mutation = ref.watch(orderMutationControllerProvider);
    return AlertDialog(
      title: Text(widget.order == null ? 'New order' : 'Edit order'),
      content: SizedBox(
        width: 720,
        child: menu.when(
          loading: () => const TavolaLoadingIndicator(label: 'Loading menu…'),
          error: (_, _) =>
              const Text('Menu is unavailable. Try again shortly.'),
          data: (catalog) => _composerContent(
            tables.asData?.value ?? const [],
            catalog,
            mutation,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: mutation.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: mutation.isLoading ? null : _submit,
          child: Text(widget.order == null ? 'Create order' : 'Save order'),
        ),
      ],
    );
  }

  Widget _composerContent(
    List<DiningTable> tables,
    MenuCatalog catalog,
    AsyncValue<void> mutation,
  ) {
    final scopedTables = tables
        .where((table) => table.status != DiningTableStatus.unavailable)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: TavolaSpace.md,
          runSpacing: TavolaSpace.sm,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<RestaurantOrderType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Order type'),
                items: RestaurantOrderType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
            ),
            if (_type == RestaurantOrderType.dineIn)
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _tableId,
                  decoration: const InputDecoration(labelText: 'Table'),
                  items: scopedTables
                      .map(
                        (table) => DropdownMenuItem(
                          value: table.id,
                          child: Text(table.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _tableId = value),
                ),
              ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        SizedBox(
          height: 360,
          child: ListView(
            children: catalog.items
                .where((item) => item.isAvailable)
                .map(_menuRow)
                .toList(),
          ),
        ),
        if (mutation.isLoading) const LinearProgressIndicator(),
        if (mutation.hasError)
          Padding(
            padding: const EdgeInsets.only(top: TavolaSpace.sm),
            child: Text(
              'Could not create this order. ${mutation.error}',
              style: const TextStyle(color: TavolaColors.error),
            ),
          ),
      ],
    );
  }

  Widget _menuRow(MenuItem item) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(item.name),
    subtitle: Text(AppFormatters.currency.format(item.priceMinor / 100)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: (_quantities[item.id] ?? 0) == 0
              ? null
              : () => setState(
                  () => _quantities[item.id] = _quantities[item.id]! - 1,
                ),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${_quantities[item.id] ?? 0}'),
        IconButton(
          onPressed: () => setState(
            () => _quantities[item.id] = (_quantities[item.id] ?? 0) + 1,
          ),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (membership == null) {
      _showValidation('Select a restaurant before opening an order.');
      return;
    }
    final items = _quantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) =>
              OrderItemInput(menuItemId: entry.key, quantity: entry.value),
        )
        .toList();
    final tableId = _type == RestaurantOrderType.dineIn ? _tableId : null;
    if (items.isEmpty) {
      _showValidation('Add at least one available menu item.');
      return;
    }
    if (_type == RestaurantOrderType.dineIn && tableId == null) {
      _showValidation('Select a table for a dine-in order.');
      return;
    }
    if (widget.order case final order?) {
      await ref
          .read(orderMutationControllerProvider.notifier)
          .save(
            UpdateOrderInput(
              orderId: order.id,
              restaurantId: membership.restaurantId,
              orderType: _type,
              tableId: tableId,
              items: items,
            ),
          );
    } else {
      await ref
          .read(orderMutationControllerProvider.notifier)
          .create(
            CreateOrderInput(
              restaurantId: membership.restaurantId,
              orderType: _type,
              tableId: tableId,
              items: items,
            ),
          );
    }
    if (mounted && !ref.read(orderMutationControllerProvider).hasError) {
      Navigator.pop(context);
    }
  }

  void _showValidation(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
