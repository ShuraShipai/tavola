import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../branches/domain/entities/branch.dart';
import '../../../branches/presentation/providers/branch_providers.dart';
import '../../../menu/domain/entities/menu_entities.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../tables/domain/entities/dining_table.dart';
import '../../../tables/presentation/providers/dining_table_providers.dart';
import '../../domain/entities/restaurant_order.dart';
import '../../domain/repositories/restaurant_order_repository.dart';
import '../providers/restaurant_order_providers.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(restaurantOrdersProvider);
    return TavolaAppShell(
      activeRoute: '/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
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
                        'Orders',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: TavolaSpace.xxs),
                      Text(
                        orders.when(
                          data: (data) =>
                              '${data.length} orders across this restaurant',
                          loading: () => 'Loading orders…',
                          error: (_, _) => 'Unable to load orders',
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _OrderComposerDialog(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Order'),
                ),
              ],
            ),
            const SizedBox(height: TavolaSpace.lg),
            orders.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(label: 'Loading orders…'),
              ),
              error: (error, _) => TavolaErrorState(
                message: 'We could not load your restaurant orders.',
                onRetry: () => ref.invalidate(restaurantOrdersProvider),
              ),
              data: (data) => data.isEmpty
                  ? const TavolaEmptyState(
                      title: 'No orders yet',
                      message:
                          'Orders created during service will appear here.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : _OrderList(orders: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});
  final List<RestaurantOrder> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Opened')),
          DataColumn(label: Text('')),
        ],
        rows: orders
            .map(
              (order) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#ORD-${order.orderNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text(order.orderType.label)),
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
  );
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
  const _OrderComposerDialog({this.order});
  final RestaurantOrder? order;
  @override
  ConsumerState<_OrderComposerDialog> createState() =>
      _OrderComposerDialogState();
}

class _OrderComposerDialogState extends ConsumerState<_OrderComposerDialog> {
  final Map<String, int> _quantities = {};
  RestaurantOrderType _type = RestaurantOrderType.dineIn;
  String? _branchId;
  String? _tableId;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order != null) {
      _type = order.orderType;
      _branchId = order.branchId;
      _tableId = order.tableId;
      for (final line in order.items) {
        if (line.menuItemId != null) {
          _quantities[line.menuItemId!] = line.quantity.toInt();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(restaurantBranchesProvider);
    final tables = ref.watch(restaurantTablesProvider);
    final menu = ref.watch(menuCatalogProvider);
    final mutation = ref.watch(orderMutationControllerProvider);
    return AlertDialog(
      title: Text(widget.order == null ? 'New order' : 'Edit order'),
      content: SizedBox(
        width: 720,
        child: branches.when(
          loading: () =>
              const TavolaLoadingIndicator(label: 'Loading order setup…'),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order setup could not load: $error'),
              const SizedBox(height: TavolaSpace.sm),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(restaurantBranchesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry setup'),
              ),
            ],
          ),
          data: (branchData) => menu.when(
            loading: () => const TavolaLoadingIndicator(label: 'Loading menu…'),
            error: (_, _) =>
                const Text('Menu is unavailable. Try again shortly.'),
            data: (catalog) => _composerContent(
              branchData,
              tables.asData?.value ?? const [],
              catalog,
              mutation,
            ),
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
    List<Branch> branches,
    List<DiningTable> tables,
    MenuCatalog catalog,
    AsyncValue<void> mutation,
  ) {
    final branchId = _branchId ?? (branches.isEmpty ? null : branches.first.id);
    final scopedTables = tables
        .where(
          (table) =>
              table.branchId == branchId &&
              table.status != DiningTableStatus.unavailable,
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: TavolaSpace.md,
          runSpacing: TavolaSpace.sm,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                initialValue: branchId,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: branches
                    .map<DropdownMenuItem<String>>(
                      (branch) => DropdownMenuItem(
                        value: branch.id,
                        child: Text(branch.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _branchId = value;
                  _tableId = null;
                }),
              ),
            ),
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
    final loadedBranches = ref.read(restaurantBranchesProvider).asData?.value;
    final branchId =
        _branchId ??
        (loadedBranches == null || loadedBranches.isEmpty
            ? null
            : loadedBranches.first.id);
    if (branchId == null) {
      _showValidation('Create or activate a branch before opening an order.');
      return;
    }
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
              branchId: branchId,
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
              branchId: branchId,
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
