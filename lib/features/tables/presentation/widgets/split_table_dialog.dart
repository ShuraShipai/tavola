import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../orders/domain/entities/restaurant_order.dart';

/// UI-only allocation from a table order to guest bills.
///
/// Each [OrderLine] remains whole; persisting guest bills or moving items is
/// intentionally delegated to the page/controller that owns the billing flow.
class TableSplit {
  const TableSplit({required this.guestNumber, required this.items});

  final int guestNumber;
  final List<OrderLine> items;
  int get totalAmount =>
      items.fold(0, (total, item) => total + item.lineTotalAmount);
}

Future<void> showSplitTableDialog({
  required BuildContext context,
  required String tableLabel,
  required RestaurantOrder order,
  int guestCount = 3,
  required ValueChanged<List<TableSplit>> onConfirm,
}) => showDialog<void>(
  context: context,
  builder: (_) => SplitTableDialog(
    tableLabel: tableLabel,
    order: order,
    guestCount: guestCount,
    onConfirm: onConfirm,
  ),
);

class SplitTableDialog extends StatefulWidget {
  const SplitTableDialog({
    super.key,
    required this.tableLabel,
    required this.order,
    this.guestCount = 3,
    required this.onConfirm,
  }) : assert(guestCount > 0);

  final String tableLabel;
  final RestaurantOrder order;
  final int guestCount;
  final ValueChanged<List<TableSplit>> onConfirm;

  @override
  State<SplitTableDialog> createState() => _SplitTableDialogState();
}

class _SplitTableDialogState extends State<SplitTableDialog> {
  late final List<int> _guestForItem = List<int>.generate(
    widget.order.items.length,
    (index) => index % widget.guestCount,
  );

  List<TableSplit> get _splits => List<TableSplit>.generate(
    widget.guestCount,
    (guestIndex) => TableSplit(
      guestNumber: guestIndex + 1,
      items: [
        for (
          var itemIndex = 0;
          itemIndex < widget.order.items.length;
          itemIndex++
        )
          if (_guestForItem[itemIndex] == guestIndex)
            widget.order.items[itemIndex],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(TavolaSpace.lg),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TavolaSpace.lg,
              TavolaSpace.lg,
              TavolaSpace.sm,
              0,
            ),
            child: Row(
              children: [
                Text(
                  'Split ${widget.tableLabel} — ${widget.guestCount} Ways',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close split table dialog',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TavolaSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign each item to a guest to divide the bill.',
                    style: TextStyle(color: TavolaColors.textSecondary),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720
                          ? widget.guestCount
                          : 1;
                      return GridView.count(
                        crossAxisCount: columns,
                        childAspectRatio: columns == 1 ? 3.1 : 1.12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: TavolaSpace.sm,
                        mainAxisSpacing: TavolaSpace.sm,
                        children: _splits
                            .map(_guestCard)
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _SplitFooter(
            enabled: widget.order.items.isNotEmpty,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              widget.onConfirm(_splits);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
  );

  Widget _guestCard(TableSplit split) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.background,
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.medium,
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Guest ${split.guestNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                AppFormatters.currency.format(split.totalAmount / 100),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.xs),
          const Divider(height: 1),
          const SizedBox(height: TavolaSpace.xs),
          Expanded(
            child: split.items.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No items assigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: TavolaColors.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: split.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: TavolaSpace.xs),
                    itemBuilder: (_, splitIndex) {
                      final item = split.items[splitIndex];
                      final orderIndex = widget.order.items.indexOf(item);
                      return _SplitLine(
                        item: item,
                        guestCount: widget.guestCount,
                        assignedGuest: _guestForItem[orderIndex],
                        onGuestChanged: (guest) =>
                            setState(() => _guestForItem[orderIndex] = guest),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class _SplitLine extends StatelessWidget {
  const _SplitLine({
    required this.item,
    required this.guestCount,
    required this.assignedGuest,
    required this.onGuestChanged,
  });
  final OrderLine item;
  final int guestCount, assignedGuest;
  final ValueChanged<int> onGuestChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '${item.name}${item.quantity == 1 ? '' : ' ×${item.quantity}'}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      PopupMenuButton<int>(
        tooltip: 'Assign ${item.name} to another guest',
        initialValue: assignedGuest,
        onSelected: onGuestChanged,
        itemBuilder: (_) => List.generate(
          guestCount,
          (index) => PopupMenuItem(
            value: index,
            child: Text('Move to Guest ${index + 1}'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TavolaSpace.xs,
            vertical: TavolaSpace.xxs,
          ),
          child: Text(
            AppFormatters.currency.format(item.lineTotalAmount / 100),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    ],
  );
}

class _SplitFooter extends StatelessWidget {
  const _SplitFooter({
    required this.enabled,
    required this.onCancel,
    required this.onConfirm,
  });
  final bool enabled;
  final VoidCallback onCancel, onConfirm;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(TavolaSpace.md),
    decoration: const BoxDecoration(
      color: Color(0xFFFAFBFC),
      border: Border(top: BorderSide(color: TavolaColors.border)),
    ),
    child: Wrap(
      alignment: WrapAlignment.end,
      spacing: TavolaSpace.sm,
      runSpacing: TavolaSpace.xs,
      children: [
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: enabled ? onConfirm : null,
          child: const Text('Confirm Split & Proceed to Billing'),
        ),
      ],
    ),
  );
}
