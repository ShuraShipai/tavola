import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../orders/domain/entities/restaurant_order.dart';
import '../../../orders/presentation/providers/restaurant_order_providers.dart';
import '../../domain/entities/dining_table.dart';
import '../providers/dining_table_providers.dart';
import '../widgets/merge_tables_dialog.dart';
import '../widgets/split_table_dialog.dart';

/// Route hosts for handoff screens 18–19. The visual work stays in reusable
/// dialogs; these pages supply tenant-scoped live data and mutation callbacks.
class TableMergePage extends ConsumerWidget {
  const TableMergePage({super.key, this.primaryTableId});

  final String? primaryTableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(restaurantTablesProvider);
    final orders = ref.watch(restaurantOrdersProvider);
    final mutation = ref.watch(tableStatusControllerProvider);
    ref.listen<AsyncValue<void>>(tableStatusControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to merge these tables.')),
        );
      } else if (previous?.isLoading == true && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tables merged successfully.')),
        );
        context.go(AppRoutes.tables);
      }
    });
    return TavolaAppShell(
      activeRoute: AppRoutes.tables,
      child: _RouteBody(
        tables: tables,
        orders: orders,
        builder: (data, orderData) {
          final primary = data
              .where((table) => table.id == primaryTableId)
              .firstOrNull;
          if (primary == null) {
            return const _MissingTable(
              message: 'Choose a table before merging.',
            );
          }
          final options = data
              .where((table) => table.branchId == primary.branchId)
              .map(
                (table) => MergeTableOption(
                  table: table,
                  order: _activeOrder(table.id, orderData),
                ),
              )
              .toList(growable: false);
          return Center(
            child: MergeTablesDialog(
              primaryTable: MergeTableOption(
                table: primary,
                order: _activeOrder(primary.id, orderData),
              ),
              tableOptions: options,
              onMerge: mutation.isLoading
                  ? (_) {}
                  : (selected) => ref
                        .read(tableStatusControllerProvider.notifier)
                        .merge(
                          primaryTable: primary,
                          secondaryTables: selected
                              .map((option) => option.table)
                              .toList(),
                        ),
            ),
          );
        },
      ),
    );
  }
}

class TableSplitPage extends ConsumerWidget {
  const TableSplitPage({super.key, this.tableId});

  final String? tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: AppRoutes.tables,
    child: _RouteBody(
      tables: ref.watch(restaurantTablesProvider),
      orders: ref.watch(restaurantOrdersProvider),
      builder: (tables, orders) {
        final table = tables.where((item) => item.id == tableId).firstOrNull;
        final order = table == null ? null : _activeOrder(table.id, orders);
        if (table == null || order == null) {
          return const _MissingTable(
            message: 'An active table order is required to split a bill.',
          );
        }
        return Center(
          child: SplitTableDialog(
            tableLabel: table.label,
            order: order,
            onConfirm: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Continue to billing to collect each guest bill.',
                  ),
                ),
              );
              context.go('/billing?order=${order.id}');
            },
          ),
        );
      },
    ),
  );
}

class _RouteBody extends StatelessWidget {
  const _RouteBody({
    required this.tables,
    required this.orders,
    required this.builder,
  });

  final AsyncValue<List<DiningTable>> tables;
  final AsyncValue<List<RestaurantOrder>> orders;
  final Widget Function(List<DiningTable>, List<RestaurantOrder>) builder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(TavolaSpace.lg),
    child: tables.when(
      loading: () => const TavolaLoadingIndicator(label: 'Loading tables…'),
      error: (_, _) => const _MissingTable(message: 'Unable to load tables.'),
      data: (data) => orders.when(
        loading: () => builder(data, const []),
        error: (_, _) => builder(data, const []),
        data: (orderData) => builder(data, orderData),
      ),
    ),
  );
}

class _MissingTable extends StatelessWidget {
  const _MissingTable({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => TavolaEmptyState(
    title: 'Table unavailable',
    message: message,
    icon: Icons.table_restaurant_outlined,
  );
}

RestaurantOrder? _activeOrder(String tableId, List<RestaurantOrder> orders) =>
    orders
        .where(
          (order) =>
              order.tableId == tableId &&
              order.status != RestaurantOrderStatus.paid &&
              order.status != RestaurantOrderStatus.cancelled,
        )
        .firstOrNull;
