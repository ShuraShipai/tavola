import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static handoff states for future order routes. Navigation is wired later.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) => _OrderShell(
    title: 'Order #ORD-1042',
    subtitle: 'Table 5 · Dine-in · Placed at 2:14 PM by Anita Nair',
    badge: const TavolaStatusBadge(
      label: 'Preparing',
      color: TavolaColors.warning,
    ),
    actions: const [
      _Action('Print', Icons.print_outlined),
      _Action('Edit Order', Icons.edit_outlined),
      _Action('Cancel Order', Icons.cancel_outlined, danger: true),
    ],
    child: Column(
      children: const [
        _OrderTimeline(),
        SizedBox(height: TavolaSpace.lg),
        _OrderSummary(),
      ],
    ),
  );
}

class EditOrderPage extends StatelessWidget {
  const EditOrderPage({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) => _OrderShell(
    title: 'Edit Order #ORD-1042',
    subtitle:
        'Table 5 · Dine-in · Add or remove items before sending updates to the kitchen',
    actions: const [
      _Action('Discard Changes', Icons.undo_outlined),
      _Action('Save Changes', Icons.save_outlined, primary: true),
    ],
    child: const TavolaPanel(child: _EditableTicket()),
  );
}

class ActiveOrdersPage extends StatelessWidget {
  const ActiveOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const _OrderListPage(completed: false);
}

class CompletedOrdersPage extends StatelessWidget {
  const CompletedOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const _OrderListPage(completed: true);
}

class _OrderShell extends StatelessWidget {
  const _OrderShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.actions = const [],
  });
  final String title;
  final String subtitle;
  final Widget child;
  final TavolaStatusBadge? badge;
  final List<_Action> actions;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/orders',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders  ›  $title',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: TavolaColors.textMuted),
          ),
          const SizedBox(height: TavolaSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: TavolaSpace.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: TavolaSpace.xs,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      // The current SDK does not parse null-aware list elements.
                      // ignore: use_null_aware_elements
                      if (badge case final activeBadge?) activeBadge,
                    ],
                  ),
                  const SizedBox(height: TavolaSpace.xxs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Wrap(
                spacing: TavolaSpace.xs,
                runSpacing: TavolaSpace.xs,
                children: actions.map((action) => action.build()).toList(),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          child,
        ],
      ),
    ),
  );
}

class _Action {
  const _Action(
    this.label,
    this.icon, {
    this.primary = false,
    this.danger = false,
  });
  final String label;
  final IconData icon;
  final bool primary;
  final bool danger;
  Widget build() => primary
      ? FilledButton.icon(
          onPressed: () {},
          icon: Icon(icon),
          label: Text(label),
        )
      : OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(icon, color: danger ? TavolaColors.error : null),
          label: Text(
            label,
            style: danger ? const TextStyle(color: TavolaColors.error) : null,
          ),
        );
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Row(
      children: const [
        Expanded(child: _Step('✓', 'Placed', '2:14 PM', true)),
        Expanded(child: _Step('🍳', 'Preparing', '2:16 PM', true)),
        Expanded(child: _Step('✓', 'Ready', '—', false)),
        Expanded(child: _Step('⌕', 'Served', '—', false)),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.label, this.time, this.active);
  final String icon, label, time;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: (active ? TavolaColors.primary : TavolaColors.border)
            .withValues(alpha: .18),
        child: Text(icon),
      ),
      const SizedBox(height: TavolaSpace.xs),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(
        time,
        style: const TextStyle(fontSize: 11, color: TavolaColors.textMuted),
      ),
    ],
  );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth > 720
        ? const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _ItemsCard()),
              SizedBox(width: TavolaSpace.md),
              Expanded(child: _BillCard()),
            ],
          )
        : const Column(
            children: [
              _ItemsCard(),
              SizedBox(height: TavolaSpace.md),
              _BillCard(),
            ],
          ),
  );
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Item('Margherita Pizza', 'Extra cheese', '1', '₹340'),
        const _Item('Cold Coffee', 'No sugar', '2', '₹260'),
        const _Item('Paneer Tikka', '—', '1', '₹260'),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.name, this.note, this.qty, this.total);
  final String name, note, qty, total;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(qty),
        const SizedBox(width: 40),
        Text(total, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _BillCard extends StatelessWidget {
  const _BillCard();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _BillLine('Subtotal', '₹860'),
        const _BillLine('Tax (5%)', '₹43'),
        const _BillLine('Service Charge', '₹43'),
        const Divider(),
        const _BillLine('Total', '₹946', bold: true),
      ],
    ),
  );
}

class _BillLine extends StatelessWidget {
  const _BillLine(this.name, this.value, {this.bold = false});
  final String name, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ],
    ),
  );
}

class _EditableTicket extends StatelessWidget {
  const _EditableTicket();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Items in this order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
      const SizedBox(height: TavolaSpace.sm),
      const _Editable('Margherita Pizza', 'Extra cheese · ₹340 each', '1'),
      const _Editable('Cold Coffee', 'No sugar · ₹130 each', '2'),
      const _Editable('Paneer Tikka', '₹260 each', '1'),
      const Divider(),
      const _BillLine('New Total', '₹946', bold: true),
    ],
  );
}

class _Editable extends StatelessWidget {
  const _Editable(this.name, this.note, this.qty);
  final String name, note, qty;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: () {}, child: const Text('−')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(qty),
        ),
        OutlinedButton(onPressed: () {}, child: const Text('+')),
        IconButton(
          onPressed: () {},
          color: TavolaColors.error,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class _OrderListPage extends StatelessWidget {
  const _OrderListPage({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final rows = completed
        ? const [
            [
              '#ORD-1039',
              'Table 9',
              '4 items',
              'Paid — UPI',
              '₹980',
              '1:52 PM',
            ],
            [
              '#ORD-1036',
              'Table 3',
              '6 items',
              'Paid — Card',
              '₹1,560',
              '1:15 PM',
            ],
            [
              '#ORD-1031',
              'Takeaway',
              '2 items',
              'Paid — Cash',
              '₹340',
              '12:40 PM',
            ],
          ]
        : const [
            [
              '#ORD-1042',
              'Table 5',
              '3 lines · 4 units',
              'Preparing',
              '₹946',
              '2:14 PM',
            ],
            [
              '#ORD-1041',
              'Table 2',
              '5 items',
              'Preparing',
              '₹1,240',
              '2:09 PM',
            ],
            ['#ORD-1040', 'Takeaway', '2 items', 'Ready', '₹260', '1:58 PM'],
            ['#ORD-1037', 'Table 7', '4 items', 'Placed', '₹720', '1:26 PM'],
          ];
    return TavolaAppShell(
      activeRoute: '/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: completed ? 'Completed Orders' : 'Active Orders',
              subtitle: completed
                  ? 'Orders served and paid today'
                  : 'Orders currently in progress across the restaurant',
              actionLabel: completed ? 'Export CSV' : 'New Order',
              actionIcon: completed ? Icons.download_outlined : Icons.add,
            ),
            const SizedBox(height: TavolaSpace.lg),
            TavolaPanel(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Table')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Payment / Status')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('')),
                  ],
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                row[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...row
                                .sublist(1)
                                .map((cell) => DataCell(Text(cell))),
                            DataCell(
                              TextButton(
                                onPressed: () {},
                                child: Text(completed ? 'Receipt' : 'View'),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
