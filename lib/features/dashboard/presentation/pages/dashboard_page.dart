import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const TavolaAppShell(activeRoute: '/', child: _DashboardContent());
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(TavolaSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TavolaPageHeader(
          title: 'Good afternoon, Rahul 👋',
          subtitle:
              "Here's how La Rosetta Café is doing today, Sunday 19 July 2026.",
          actionLabel: 'New Order',
          actionIcon: Icons.add_rounded,
        ),
        const SizedBox(height: TavolaSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= TavolaBreakpoints.expanded
                ? 4
                : constraints.maxWidth >= TavolaBreakpoints.compact
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: 1.55,
              children: const [
                TavolaMetricCard(
                  label: "Today's Sales",
                  value: '₹48,250',
                  icon: Icons.payments_outlined,
                  tone: TavolaColors.accent,
                  detail: '▲ 12.4% vs yesterday',
                ),
                TavolaMetricCard(
                  label: 'Orders Today',
                  value: '186',
                  icon: Icons.receipt_long_outlined,
                  tone: TavolaColors.primary,
                  detail: '▲ 8 more than yesterday',
                ),
                TavolaMetricCard(
                  label: 'Occupied Tables',
                  value: '14 / 22',
                  icon: Icons.table_restaurant_outlined,
                  tone: TavolaColors.info,
                  detail: '6 free · 2 reserved',
                ),
                TavolaMetricCard(
                  label: 'Avg. Order Value',
                  value: '₹259',
                  icon: Icons.trending_up_rounded,
                  tone: TavolaColors.success,
                  detail: '▼ 2.1% vs last week',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: TavolaSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= TavolaBreakpoints.medium
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _SalesChart()),
                    SizedBox(width: TavolaSpace.md),
                    Expanded(child: _TopItems()),
                  ],
                )
              : const Column(
                  children: [
                    _SalesChart(),
                    SizedBox(height: TavolaSpace.md),
                    _TopItems(),
                  ],
                ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        const _RecentOrders(),
      ],
    ),
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales This Week',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Total revenue by day',
                    style: TextStyle(
                      fontSize: 12,
                      color: TavolaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('Week')),
            TextButton(onPressed: () {}, child: const Text('Month')),
          ],
        ),
        const SizedBox(height: TavolaSpace.lg),
        const SizedBox(height: 196, child: _Bars()),
      ],
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [.55, .70, .48, .82, .65, .94, .40];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        days.length,
        (index) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.xs / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: values[index],
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: index == 6
                              ? TavolaColors.borderStrong
                              : TavolaColors.accent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TavolaSpace.xs),
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 11,
                    color: TavolaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopItems extends StatelessWidget {
  const _TopItems();

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
        for (final item in const [
          ('1', 'Margherita Pizza', '52 sold'),
          ('2', 'Butter Chicken', '41 sold'),
          ('3', 'Cold Coffee', '38 sold'),
          ('4', 'Paneer Tikka', '29 sold'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: TavolaSpace.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: TavolaColors.accentLight,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TavolaColors.accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: TavolaSpace.sm),
                Expanded(
                  child: Text(item.$2, style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  item.$3,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(TavolaSpace.lg),
          child: Row(
            children: [
              const Expanded(
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
                onPressed: () {},
                child: const Text('View All Orders'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('#ORD-1042')),
                  DataCell(Text('Table 5')),
                  DataCell(Text('Pizza, Cold Coffee ×2')),
                  DataCell(
                    TavolaStatusBadge(
                      label: 'Preparing',
                      color: TavolaColors.accentDark,
                    ),
                  ),
                  DataCell(Text('₹946')),
                  DataCell(Text('2:14 PM')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('#ORD-1041')),
                  DataCell(Text('Table 2')),
                  DataCell(Text('Butter Chicken, Naan ×3')),
                  DataCell(
                    TavolaStatusBadge(
                      label: 'Preparing',
                      color: TavolaColors.accentDark,
                    ),
                  ),
                  DataCell(Text('₹1,240')),
                  DataCell(Text('2:09 PM')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('#ORD-1040')),
                  DataCell(Text('Takeaway')),
                  DataCell(Text('Cold Coffee ×2')),
                  DataCell(
                    TavolaStatusBadge(label: 'Ready', color: TavolaColors.info),
                  ),
                  DataCell(Text('₹260')),
                  DataCell(Text('1:58 PM')),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
