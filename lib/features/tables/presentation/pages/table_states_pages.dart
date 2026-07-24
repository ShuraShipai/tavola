import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class TableDetailPage extends StatelessWidget {
  const TableDetailPage({super.key});
  @override
  Widget build(BuildContext context) => _TableShell(
    title: 'Table 5',
    subtitle: '4 seats · Occupied for 12 minutes · Waiter: Anita Nair',
    child: LayoutBuilder(
      builder: (context, box) => box.maxWidth > 720
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _CurrentOrder()),
                SizedBox(width: TavolaSpace.md),
                Expanded(child: _TableFacts()),
              ],
            )
          : const Column(
              children: [
                _CurrentOrder(),
                SizedBox(height: TavolaSpace.md),
                _TableFacts(),
              ],
            ),
    ),
  );
}

class MergeTablesPage extends StatelessWidget {
  const MergeTablesPage({super.key});
  @override
  Widget build(BuildContext context) => _TableShell(
    title: 'Merge Tables',
    subtitle: 'Combine occupied tables and keep a single order',
    child: const TavolaPanel(child: _MergeContent()),
  );
}

class SplitTablePage extends StatelessWidget {
  const SplitTablePage({super.key});
  @override
  Widget build(BuildContext context) => _TableShell(
    title: 'Split Table',
    subtitle: 'Move guests and their items to another table',
    child: const TavolaPanel(child: _SplitContent()),
  );
}

class _TableShell extends StatelessWidget {
  const _TableShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/tables',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tables  ›  $title',
            style: const TextStyle(fontSize: 12, color: TavolaColors.textMuted),
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
                    spacing: TavolaSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const TavolaStatusBadge(
                        label: 'Occupied',
                        color: TavolaColors.warning,
                      ),
                    ],
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Wrap(
                spacing: TavolaSpace.xs,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Merge Tables'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Split Table'),
                  ),
                  FilledButton(onPressed: () {}, child: const Text('Add Item')),
                ],
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

class _CurrentOrder extends StatelessWidget {
  const _CurrentOrder();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Current Order — #ORD-1042',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const TavolaStatusBadge(
              label: 'Preparing',
              color: TavolaColors.warning,
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        const _TableItem('Margherita Pizza', '1', '₹340'),
        const _TableItem('Cold Coffee', '2', '₹260'),
        const _TableItem('Paneer Tikka', '1', '₹260'),
        const Divider(),
        const _Fact('Current total', '₹946', bold: true),
      ],
    ),
  );
}

class _TableItem extends StatelessWidget {
  const _TableItem(this.name, this.qty, this.total);
  final String name, qty, total;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(qty),
        const SizedBox(width: 34),
        Text(total),
      ],
    ),
  );
}

class _TableFacts extends StatelessWidget {
  const _TableFacts();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Table details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Fact('Guests', '4'),
        const _Fact('Area', 'Main dining'),
        const _Fact('Opened', '2:14 PM'),
        const _Fact('Waiter', 'Anita Nair'),
        const Divider(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('View Order Details'),
          ),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TavolaColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _MergeContent extends StatelessWidget {
  const _MergeContent();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Select tables to merge',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: TavolaSpace.xs),
      const Text(
        'The earliest order stays active after tables are combined.',
        style: TextStyle(color: TavolaColors.textMuted),
      ),
      const SizedBox(height: TavolaSpace.lg),
      const _Pick('Table 5', '4 guests · #ORD-1042', true),
      const _Pick('Table 6', '2 guests · #ORD-1044', true),
      const _Pick('Table 9', 'Available', false),
      const Divider(),
      const _Fact('Merged capacity', '6 seats'),
      const _Fact('Combined order', '₹1,466', bold: true),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () {},
          child: const Text('Merge 2 Tables'),
        ),
      ),
    ],
  );
}

class _SplitContent extends StatelessWidget {
  const _SplitContent();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Move guests to a new table',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: TavolaSpace.md),
      const _Pick('From: Table 5', '4 guests · #ORD-1042', true),
      const _Pick('To: Table 8', 'Available · 4 seats', true),
      const Divider(),
      const Text(
        'Items to move',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const _Pick('Cold Coffee × 2', '₹260', true),
      const _Pick('Paneer Tikka × 1', '₹260', false),
      const SizedBox(height: TavolaSpace.md),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(onPressed: () {}, child: const Text('Split Table')),
      ),
    ],
  );
}

class _Pick extends StatelessWidget {
  const _Pick(this.title, this.subtitle, this.selected);
  final String title, subtitle;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: TavolaSpace.sm),
    padding: const EdgeInsets.all(TavolaSpace.sm),
    decoration: BoxDecoration(
      border: Border.all(
        color: selected ? TavolaColors.primary : TavolaColors.border,
      ),
      borderRadius: TavolaRadius.medium,
      color: selected ? TavolaColors.primary.withValues(alpha: .06) : null,
    ),
    child: Row(
      children: [
        Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected ? TavolaColors.primary : TavolaColors.textMuted,
        ),
        const SizedBox(width: TavolaSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
