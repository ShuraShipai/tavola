import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../domain/entities/dining_table.dart';
import '../../../orders/domain/entities/restaurant_order.dart';

/// A selectable occupied table and its active order for a merge operation.
///
/// The merge itself is deliberately performed by the owning page/controller so
/// that persistence, permissions, and audit history remain outside the widget.
class MergeTableOption {
  const MergeTableOption({required this.table, this.order});

  final DiningTable table;
  final RestaurantOrder? order;

  int get totalAmount => order?.totalAmount ?? 0;
  bool get canMerge =>
      table.status == DiningTableStatus.occupied && order != null;
}

Future<void> showMergeTablesDialog({
  required BuildContext context,
  required MergeTableOption primaryTable,
  required List<MergeTableOption> tableOptions,
  required ValueChanged<List<MergeTableOption>> onMerge,
}) => showDialog<void>(
  context: context,
  builder: (_) => MergeTablesDialog(
    primaryTable: primaryTable,
    tableOptions: tableOptions,
    onMerge: onMerge,
  ),
);

class MergeTablesDialog extends StatefulWidget {
  const MergeTablesDialog({
    super.key,
    required this.primaryTable,
    required this.tableOptions,
    required this.onMerge,
  });

  final MergeTableOption primaryTable;
  final List<MergeTableOption> tableOptions;
  final ValueChanged<List<MergeTableOption>> onMerge;

  @override
  State<MergeTablesDialog> createState() => _MergeTablesDialogState();
}

class _MergeTablesDialogState extends State<MergeTablesDialog> {
  final Set<String> _selectedIds = {};

  List<MergeTableOption> get _additionalTables => widget.tableOptions
      .where(
        (option) =>
            option.table.id != widget.primaryTable.table.id &&
            _selectedIds.contains(option.table.id),
      )
      .toList(growable: false);

  int get _combinedTotal =>
      widget.primaryTable.totalAmount +
      _additionalTables.fold(0, (sum, table) => sum + table.totalAmount);

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(TavolaSpace.lg),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
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
                  'Merge Tables',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close merge tables dialog',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
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
                    'Combine orders from multiple tables into one bill. Select the tables to merge into the primary table.',
                    style: TextStyle(color: TavolaColors.textSecondary),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 1;
                      return GridView.count(
                        crossAxisCount: columns,
                        childAspectRatio: columns == 1 ? 3.4 : 1.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: TavolaSpace.sm,
                        mainAxisSpacing: TavolaSpace.sm,
                        children: widget.tableOptions
                            .map(_buildTableOption)
                            .toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: TavolaSpace.lg),
                  _BillPreview(
                    primaryTable: widget.primaryTable,
                    selectedTables: _additionalTables,
                    combinedTotal: _combinedTotal,
                  ),
                ],
              ),
            ),
          ),
          _DialogFooter(
            cancelLabel: 'Cancel',
            confirmLabel: 'Merge into ${widget.primaryTable.table.label}',
            enabled: _additionalTables.isNotEmpty,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              widget.onMerge(_additionalTables);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildTableOption(MergeTableOption option) {
    final isPrimary = option.table.id == widget.primaryTable.table.id;
    final isSelected = _selectedIds.contains(option.table.id);
    final selectable = option.canMerge && !isPrimary;
    final borderColor = isPrimary || isSelected
        ? TavolaColors.accent
        : option.table.status == DiningTableStatus.available
        ? TavolaColors.success
        : TavolaColors.border;
    final meta = isPrimary
        ? 'Primary · ${AppFormatters.currency.format(option.totalAmount / 100)}'
        : isSelected
        ? 'Selected · ${AppFormatters.currency.format(option.totalAmount / 100)}'
        : option.table.status == DiningTableStatus.available
        ? 'Free'
        : option.order == null
        ? option.table.status.label
        : AppFormatters.currency.format(option.totalAmount / 100);
    return Semantics(
      button: selectable,
      selected: isPrimary || isSelected,
      label: '${option.table.label}, $meta',
      child: InkWell(
        borderRadius: TavolaRadius.medium,
        onTap: !selectable
            ? null
            : () => setState(() {
                isSelected
                    ? _selectedIds.remove(option.table.id)
                    : _selectedIds.add(option.table.id);
              }),
        child: Ink(
          decoration: BoxDecoration(
            color: (isPrimary || isSelected)
                ? TavolaColors.accentLight.withValues(alpha: .4)
                : TavolaColors.surface,
            border: Border.all(
              color: borderColor,
              width: isPrimary || isSelected ? 1.5 : 1,
            ),
            borderRadius: TavolaRadius.medium,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TavolaSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant_outlined, color: borderColor),
                const SizedBox(height: TavolaSpace.xs),
                Text(
                  option.table.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: TavolaSpace.xxs),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TavolaColors.textSecondary,
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

class _BillPreview extends StatelessWidget {
  const _BillPreview({
    required this.primaryTable,
    required this.selectedTables,
    required this.combinedTotal,
  });
  final MergeTableOption primaryTable;
  final List<MergeTableOption> selectedTables;
  final int combinedTotal;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.background,
      borderRadius: TavolaRadius.medium,
      border: Border.all(color: TavolaColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combined Bill Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: TavolaSpace.sm),
          _totalRow(
            '${primaryTable.table.label} current total',
            primaryTable.totalAmount,
          ),
          for (final table in selectedTables)
            _totalRow('${table.table.label} current total', table.totalAmount),
          const Divider(height: TavolaSpace.lg),
          _totalRow('New Combined Total', combinedTotal, bold: true),
        ],
      ),
    ),
  );
  Widget _totalRow(String label, int amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ),
        Text(
          AppFormatters.currency.format(amount / 100),
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ],
    ),
  );
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.enabled,
    required this.onCancel,
    required this.onConfirm,
  });
  final String cancelLabel, confirmLabel;
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
        OutlinedButton(onPressed: onCancel, child: Text(cancelLabel)),
        FilledButton(
          onPressed: enabled ? onConfirm : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
