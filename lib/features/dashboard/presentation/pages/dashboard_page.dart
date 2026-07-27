import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: '/',
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: ref
          .watch(dashboardSnapshotProvider)
          .when(
            loading: () => const TavolaLoadingIndicator(
              label: 'Loading today’s performance…',
            ),
            error: (error, _) => TavolaErrorState(
              message: 'Unable to load the dashboard.',
              onRetry: () => ref.invalidate(dashboardSnapshotProvider),
            ),
            data: (snapshot) => _DashboardContent(
              snapshot: snapshot,
              onRefresh: () => ref.invalidate(dashboardSnapshotProvider),
            ),
          ),
    ),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot, required this.onRefresh});
  final DashboardSnapshot snapshot;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TavolaPageHeader(
          title: 'Today’s Overview',
          subtitle: 'Live restaurant performance for today',
          actionLabel: 'Refresh',
          actionIcon: Icons.refresh_rounded,
          onAction: onRefresh,
        ),
        const SizedBox(height: TavolaSpace.lg),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= TavolaBreakpoints.expanded
                ? 4
                : c.maxWidth >= TavolaBreakpoints.compact
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: 1.55,
              children: [
                TavolaMetricCard(
                  label: 'Today’s Sales',
                  value: AppFormatters.currency.format(
                    snapshot.todaySalesAmount / 100,
                  ),
                  icon: Icons.payments_outlined,
                  tone: TavolaColors.accent,
                  detail: '${snapshot.todayOrderCount} completed orders',
                  onTap: () => context.go('/orders'),
                ),
                TavolaMetricCard(
                  label: 'Orders Today',
                  value: '${snapshot.todayOrderCount}',
                  icon: Icons.receipt_long_outlined,
                  tone: TavolaColors.primary,
                  detail: 'Live service total',
                  onTap: () => context.go('/orders'),
                ),
                TavolaMetricCard(
                  label: 'Occupied Tables',
                  value: '${snapshot.occupiedTables} / ${snapshot.totalTables}',
                  icon: Icons.table_restaurant_outlined,
                  tone: TavolaColors.info,
                  detail:
                      '${snapshot.availableTables} free · ${snapshot.reservedTables} reserved',
                  onTap: () => context.go('/tables'),
                ),
                TavolaMetricCard(
                  label: 'Avg. Order Value',
                  value: AppFormatters.currency.format(
                    snapshot.averageOrderAmount / 100,
                  ),
                  icon: Icons.trending_up_rounded,
                  tone: TavolaColors.success,
                  detail: 'Based on today’s orders',
                  onTap: () => context.go('/reports'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: TavolaSpace.lg),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= TavolaBreakpoints.medium
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _SalesChart(snapshot.weeklySales)),
                    const SizedBox(width: TavolaSpace.md),
                    Expanded(child: _TopItems(snapshot.topItems)),
                  ],
                )
              : Column(
                  children: [
                    _SalesChart(snapshot.weeklySales),
                    const SizedBox(height: TavolaSpace.md),
                    _TopItems(snapshot.topItems),
                  ],
                ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        _RecentOrders(snapshot.recentOrders),
      ],
    ),
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart(this.sales);
  final List<DailySales> sales;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales This Week',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        const Text(
          'Total revenue by day',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(height: 196, child: _Bars(sales)),
      ],
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars(this.sales);
  final List<DailySales> sales;

  @override
  Widget build(BuildContext context) {
    final highest = sales.fold<int>(
      0,
      (maximum, sale) => sale.amount > maximum ? sale.amount : maximum,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sales
          .map(
            (sale) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TavolaSpace.xs / 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: highest == 0
                              ? 0
                              : sale.amount / highest,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: TavolaColors.accent,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TavolaSpace.xs),
                    Text(
                      sale.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TavolaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TopItems extends StatelessWidget {
  const _TopItems(this.items);
  final List<TopSellingItem> items;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Selling Items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        const Text(
          'Today',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.lg),
        if (items.isEmpty)
          const TavolaEmptyState(
            title: 'No sales yet',
            message: 'Top-selling items will appear as orders arrive.',
            icon: Icons.restaurant_menu_outlined,
          )
        else
          for (final entry in items.indexed)
            InkWell(
              onTap: () => context.go('/menu'),
              borderRadius: TavolaRadius.small,
              child: Padding(
                padding: const EdgeInsets.only(bottom: TavolaSpace.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: TavolaColors.accentLight,
                      child: Text(
                        '${entry.$1 + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: TavolaColors.accentDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: TavolaSpace.sm),
                    Expanded(
                      child: Text(
                        entry.$2.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${entry.$2.quantity} sold',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

class _RecentOrders extends StatelessWidget {
  const _RecentOrders(this.orders);
  final List<DashboardOrder> orders;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(TavolaSpace.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Orders',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Latest activity across all tables',
                      style: TextStyle(
                        fontSize: 12,
                        color: TavolaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View All Orders'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (orders.isEmpty)
          const SizedBox(
            height: 200,
            child: TavolaEmptyState(
              title: 'No orders yet',
              message: 'Orders created today will appear here.',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Time')),
              ],
              rows: orders
                  .map(
                    (order) => DataRow(
                      onSelectChanged: (_) =>
                          context.go('/orders/detail/${order.id}'),
                      cells: [
                        DataCell(Text('#ORD-${order.number}')),
                        DataCell(
                          Text(order.tableLabel ?? _orderType(order.orderType)),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              order.itemSummary.isEmpty
                                  ? '—'
                                  : order.itemSummary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          TavolaStatusBadge(
                            label: _statusLabel(order.status),
                            color: _statusColor(order.status),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.currency.format(
                              order.totalAmount / 100,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(AppFormatters.time.format(order.createdAt)),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );
}

String _orderType(String type) => switch (type) {
  'takeaway' => 'Takeaway',
  'delivery' => 'Delivery',
  _ => 'Dine-in',
};
String _statusLabel(String status) => status
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
Color _statusColor(String status) => switch (status) {
  'ready' => TavolaColors.info,
  'cancelled' => TavolaColors.error,
  'paid' => TavolaColors.success,
  _ => TavolaColors.accentDark,
};
