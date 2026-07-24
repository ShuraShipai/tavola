import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static inventory overview, items and purchasing form from screens 50–54/104–106.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/inventory',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Inventory',
            subtitle: 'Stock health and purchasing overview',
            actionLabel: 'Record Purchase',
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: c.maxWidth > 900 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: 2.1,
              children: const [
                TavolaMetricCard(
                  label: 'Stock value',
                  value: '₹2.84L',
                  icon: Icons.inventory_2_outlined,
                  tone: TavolaColors.info,
                  detail: '▲ 4.2%',
                ),
                TavolaMetricCard(
                  label: 'Low stock',
                  value: '12',
                  icon: Icons.warning_amber_rounded,
                  tone: TavolaColors.accent,
                  detail: 'Needs attention',
                ),
                TavolaMetricCard(
                  label: 'Out of stock',
                  value: '3',
                  icon: Icons.remove_shopping_cart_outlined,
                  tone: TavolaColors.error,
                  detail: 'Reorder now',
                ),
                TavolaMetricCard(
                  label: 'Suppliers',
                  value: '18',
                  icon: Icons.local_shipping_outlined,
                  tone: TavolaColors.success,
                  detail: '15 active',
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth > 740
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StockAlerts()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _CategoryValue()),
                    ],
                  )
                : const Column(
                    children: [
                      _StockAlerts(),
                      SizedBox(height: TavolaSpace.md),
                      _CategoryValue(),
                    ],
                  ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(TavolaSpace.lg),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Inventory Items',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('In stock')),
                      DataColumn(label: Text('Reorder at')),
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      _InventoryRow(
                        'Mozzarella Cheese',
                        'DRY-014',
                        '1.8 kg',
                        '5 kg',
                        'Fresh Farms',
                        'Critical',
                        TavolaColors.error,
                      ),
                      _InventoryRow(
                        'Arabica Coffee Beans',
                        'BEV-008',
                        '3.2 kg',
                        '4 kg',
                        'Bean House',
                        'Low',
                        TavolaColors.accent,
                      ),
                      _InventoryRow(
                        'Basmati Rice',
                        'GRN-003',
                        '18 kg',
                        '8 kg',
                        'Kapoor Foods',
                        'Healthy',
                        TavolaColors.success,
                      ),
                      _InventoryRow(
                        'Tomatoes',
                        'FRS-021',
                        '12 kg',
                        '6 kg',
                        'Fresh Farms',
                        'Healthy',
                        TavolaColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Purchase',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TavolaSpace.md),
                const Wrap(
                  spacing: TavolaSpace.md,
                  runSpacing: TavolaSpace.md,
                  children: [
                    _Input('Supplier', 'Fresh Farms · SUP-014'),
                    _Input('Supplier invoice', 'FF-7821'),
                    _Input('Purchase date', '19 Jul 2026'),
                    _Input('Payment status', 'Credit · Due in 15 days'),
                  ],
                ),
                const SizedBox(height: TavolaSpace.md),
                const _PurchaseLine(),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Receive Stock'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StockAlerts extends StatelessWidget {
  const _StockAlerts();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock alerts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const _Alert(
          'Mozzarella Cheese',
          'Dairy',
          '1.8 kg left',
          TavolaColors.error,
        ),
        const _Alert(
          'Arabica Coffee Beans',
          'Beverages',
          '3.2 kg left',
          TavolaColors.accent,
        ),
        const _Alert(
          'Basmati Rice',
          'Grains',
          '6 kg left',
          TavolaColors.accent,
        ),
      ],
    ),
  );
}

class _Alert extends StatelessWidget {
  const _Alert(this.name, this.type, this.amount, this.color);
  final String name, type, amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                type,
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TavolaStatusBadge(label: amount, color: color),
      ],
    ),
  );
}

class _CategoryValue extends StatelessWidget {
  const _CategoryValue();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory by category',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        const _Progress('Fresh produce', '₹82,400', .72),
        const _Progress('Dairy', '₹61,800', .54),
        const _Progress('Dry goods', '₹56,200', .48),
      ],
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress(this.name, this.value, this.factor);
  final String name, value;
  final double factor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      children: [
        Row(
          children: [
            Text(name),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: factor,
          color: TavolaColors.accent,
          backgroundColor: TavolaColors.surfaceVariant,
        ),
      ],
    ),
  );
}

class _InventoryRow extends DataRow {
  _InventoryRow(
    String n,
    String sku,
    String stock,
    String reorder,
    String supplier,
    String status,
    Color c,
  ) : super(
        cells: [
          DataCell(
            Text(n, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          DataCell(Text(sku)),
          DataCell(Text(stock)),
          DataCell(Text(reorder)),
          DataCell(Text(supplier)),
          DataCell(TavolaStatusBadge(label: status, color: c)),
        ],
      );
}

class _Input extends StatelessWidget {
  const _Input(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: value)),
      ],
    ),
  );
}

class _PurchaseLine extends StatelessWidget {
  const _PurchaseLine();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TavolaColors.surfaceVariant,
      borderRadius: TavolaRadius.small,
    ),
    child: const Row(
      children: [
        Expanded(child: Text('Mozzarella Cheese · 10 kg')),
        Text('₹5,460', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
