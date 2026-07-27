import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../orders/domain/entities/restaurant_order.dart';
import '../../../orders/presentation/providers/restaurant_order_providers.dart';
import '../../domain/entities/dining_table.dart';
import '../providers/dining_table_providers.dart';

/// Screen 17. A live view composed from the table and order streams.
class TableDetailPage extends ConsumerWidget {
  const TableDetailPage({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(restaurantTablesProvider);
    final orders = ref.watch(restaurantOrdersProvider);
    return TavolaAppShell(
      activeRoute: AppRoutes.tables,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: tables.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(TavolaSpace.xl),
            child: TavolaLoadingIndicator(label: 'Loading table…'),
          ),
          error: (_, _) => TavolaErrorState(
            message: 'We could not load this table.',
            onRetry: () => ref.invalidate(restaurantTablesProvider),
          ),
          data: (tables) {
            final table = tables
                .where((item) => item.id == tableId)
                .firstOrNull;
            if (table == null) {
              return const TavolaEmptyState(
                title: 'Table not found',
                message: 'This table may have been removed or is unavailable.',
                icon: Icons.table_restaurant_outlined,
              );
            }
            return orders.when(
              loading: () => _TableDetailContent(table: table),
              error: (_, _) => _TableDetailContent(table: table),
              data: (orders) => _TableDetailContent(
                table: table,
                order: _activeOrderFor(table, orders),
              ),
            );
          },
        ),
      ),
    );
  }

  RestaurantOrder? _activeOrderFor(
    DiningTable table,
    List<RestaurantOrder> orders,
  ) => orders.where((order) {
    return order.tableId == table.id &&
        order.status != RestaurantOrderStatus.paid &&
        order.status != RestaurantOrderStatus.cancelled;
  }).firstOrNull;
}

class _TableDetailContent extends StatelessWidget {
  const _TableDetailContent({required this.table, this.order});

  final DiningTable table;
  final RestaurantOrder? order;

  @override
  Widget build(BuildContext context) {
    final hasOrder = order != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Breadcrumb(table: table),
        const SizedBox(height: TavolaSpace.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TavolaSpace.lg,
          runSpacing: TavolaSpace.sm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: TavolaSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      table.label,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    TavolaStatusBadge(
                      label: table.status.label,
                      color: _tableStatusColor(table.status),
                    ),
                  ],
                ),
                const SizedBox(height: TavolaSpace.xxs),
                Text(
                  '${table.capacity} seats · ${_tableStatusDescription(table.status)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            Wrap(
              spacing: TavolaSpace.xs,
              runSpacing: TavolaSpace.xs,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/tables/${table.id}/edit'),
                  child: const Text('Edit Table'),
                ),
                OutlinedButton(
                  onPressed: hasOrder
                      ? () => context.go('/tables/merge?primary=${table.id}')
                      : null,
                  child: const Text('Merge Tables'),
                ),
                OutlinedButton(
                  onPressed: hasOrder
                      ? () => context.go('/tables/split?table=${table.id}')
                      : null,
                  child: const Text('Split Table'),
                ),
                FilledButton(
                  onPressed: () => context.go('/orders?table=${table.id}'),
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth > 720
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _CurrentOrderCard(order: order)),
                    const SizedBox(width: TavolaSpace.md),
                    Expanded(child: _TableActions(order: order)),
                  ],
                )
              : Column(
                  children: [
                    _CurrentOrderCard(order: order),
                    const SizedBox(height: TavolaSpace.md),
                    _TableActions(order: order),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.table});
  final DiningTable table;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextButton(
        onPressed: () => context.go(AppRoutes.tables),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: TavolaColors.textMuted,
        ),
        child: const Text('Tables'),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: TavolaSpace.xxs),
        child: Icon(Icons.chevron_right_rounded, size: TavolaSize.iconSmall),
      ),
      Text(
        table.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TavolaColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _CurrentOrderCard extends StatelessWidget {
  const _CurrentOrderCard({this.order});
  final RestaurantOrder? order;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: order == null
        ? const Padding(
            padding: EdgeInsets.all(TavolaSpace.lg),
            child: _NoActiveOrder(),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(TavolaSpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current Order — #ORD-${order!.orderNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TavolaStatusBadge(
                      label: order!.status.label,
                      color: _orderStatusColor(order!.status),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (order!.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(TavolaSpace.lg),
                  child: Text('No items have been added to this order yet.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: Theme.of(context).textTheme.labelSmall,
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Total')),
                    ],
                    rows: order!.items
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text(item.quantity.toString())),
                              DataCell(
                                Text(
                                  AppFormatters.currency.format(
                                    item.lineTotalAmount / 100,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
            ],
          ),
  );
}

class _NoActiveOrder extends StatelessWidget {
  const _NoActiveOrder();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Current Order', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: TavolaSpace.xs),
      Text(
        'There is no active order for this table.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

class _TableActions extends StatelessWidget {
  const _TableActions({this.order});
  final RestaurantOrder? order;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        OutlinedButton(
          onPressed: order == null
              ? null
              : () => context.go('/orders/detail/${order!.id}'),
          child: const Text('View Full Order'),
        ),
        const SizedBox(height: TavolaSpace.sm),
        OutlinedButton(
          onPressed: order == null
              ? null
              : () => context.go('/billing/preview?order=${order!.id}'),
          child: const Text('Print Bill Preview'),
        ),
        const SizedBox(height: TavolaSpace.sm),
        FilledButton(
          onPressed: order == null
              ? null
              : () => context.go('/billing?order=${order!.id}'),
          child: const Text('Proceed to Billing'),
        ),
        const SizedBox(height: TavolaSpace.sm),
        const _ActiveOrderNotice(),
        const SizedBox(height: TavolaSpace.sm),
        const OutlinedButton(
          onPressed: null,
          child: Text('Mark Table Available'),
        ),
      ],
    ),
  );
}

class _ActiveOrderNotice extends StatelessWidget {
  const _ActiveOrderNotice();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: TavolaColors.warningLight,
      borderRadius: TavolaRadius.small,
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.sm),
      child: Text(
        'Settle or cancel the active order before releasing this table.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: TavolaColors.accentDark),
      ),
    ),
  );
}

Color _tableStatusColor(DiningTableStatus status) => switch (status) {
  DiningTableStatus.available => TavolaColors.success,
  DiningTableStatus.occupied => TavolaColors.accent,
  DiningTableStatus.reserved => TavolaColors.textMuted,
  DiningTableStatus.unavailable => TavolaColors.error,
};

Color _orderStatusColor(RestaurantOrderStatus status) => switch (status) {
  RestaurantOrderStatus.cancelled => TavolaColors.error,
  RestaurantOrderStatus.ready ||
  RestaurantOrderStatus.served => TavolaColors.success,
  RestaurantOrderStatus.billed ||
  RestaurantOrderStatus.paid => TavolaColors.info,
  _ => TavolaColors.accent,
};

String _tableStatusDescription(DiningTableStatus status) => switch (status) {
  DiningTableStatus.available => 'Free to seat',
  DiningTableStatus.occupied => 'Currently occupied',
  DiningTableStatus.reserved => 'Reserved for an upcoming guest',
  DiningTableStatus.unavailable => 'Currently unavailable',
};
