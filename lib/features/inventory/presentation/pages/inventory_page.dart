import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_providers.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsProvider);
    return TavolaAppShell(
      activeRoute: '/inventory',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: 'Inventory',
              subtitle: items.when(
                data: (data) =>
                    '${data.length} inventory items across this restaurant',
                loading: () => 'Loading stock…',
                error: (_, _) => 'Unable to load inventory',
              ),
              actionLabel: 'Record Purchase',
            ),
            const SizedBox(height: TavolaSpace.lg),
            items.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(label: 'Loading inventory…'),
              ),
              error: (error, _) => TavolaErrorState(
                message: 'We could not load inventory.',
                onRetry: () => ref.invalidate(inventoryItemsProvider),
              ),
              data: (data) => data.isEmpty
                  ? const TavolaEmptyState(
                      title: 'No inventory items yet',
                      message: 'Add inventory items to start tracking stock.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : _InventoryDashboard(items: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDashboard extends StatelessWidget {
  const _InventoryDashboard({required this.items});
  final List<InventoryItem> items;
  @override
  Widget build(BuildContext context) {
    final low = items.where((item) => item.isLowStock).length;
    final out = items.where((item) => item.isOutOfStock).length;
    return Column(
      children: [
        LayoutBuilder(
          builder: (_, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
            crossAxisSpacing: TavolaSpace.md,
            mainAxisSpacing: TavolaSpace.md,
            childAspectRatio: 2.1,
            children: [
              TavolaMetricCard(
                label: 'Tracked items',
                value: '${items.length}',
                icon: Icons.inventory_2_outlined,
                tone: TavolaColors.info,
                detail: 'Active inventory',
              ),
              TavolaMetricCard(
                label: 'Low stock',
                value: '$low',
                icon: Icons.warning_amber_rounded,
                tone: TavolaColors.accent,
                detail: 'Needs attention',
              ),
              TavolaMetricCard(
                label: 'Out of stock',
                value: '$out',
                icon: Icons.remove_shopping_cart_outlined,
                tone: TavolaColors.error,
                detail: 'Reorder now',
              ),
            ],
          ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        TavolaPanel(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('In stock')),
                DataColumn(label: Text('Reorder at')),
                DataColumn(label: Text('Unit cost')),
                DataColumn(label: Text('Status')),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(item.sku ?? '—')),
                        DataCell(Text('${item.currentQuantity} ${item.unit}')),
                        DataCell(Text('${item.reorderLevel} ${item.unit}')),
                        DataCell(
                          Text(
                            item.unitCostAmount == null
                                ? '—'
                                : AppFormatters.currency.format(
                                    item.unitCostAmount! / 100,
                                  ),
                          ),
                        ),
                        DataCell(
                          TavolaStatusBadge(
                            label: _status(item),
                            color: _color(item),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }

  String _status(InventoryItem item) => item.isOutOfStock
      ? 'Out of stock'
      : item.isLowStock
      ? 'Low'
      : 'Healthy';
  Color _color(InventoryItem item) => item.isOutOfStock
      ? TavolaColors.error
      : item.isLowStock
      ? TavolaColors.accent
      : TavolaColors.success;
}
