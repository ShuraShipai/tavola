import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static discounts, coupons and editor preview from screens 55–56/91–92/121–122.
class DiscountsPage extends StatelessWidget {
  const DiscountsPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/discounts',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Discounts',
            subtitle: 'Create automatic and staff-applied offers',
            actionLabel: 'Create Discount',
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: c.maxWidth > 850 ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: c.maxWidth > 850 ? 1.55 : 2.2,
              children: const [
                _Offer(
                  '10% off',
                  'Weekday Lunch',
                  'Mon–Fri · 12:00 PM to 3:00 PM',
                  '148 times',
                  '−₹18,420',
                  'Active',
                  TavolaColors.success,
                ),
                _Offer(
                  '₹200 off',
                  'Birthday Reward',
                  'For loyalty members · ₹1,500 minimum',
                  '42 times',
                  '−₹8,400',
                  'Active',
                  TavolaColors.success,
                ),
                _Offer(
                  '15% off',
                  'Independence Week',
                  '12–18 August 2026 · All dine-in',
                  '500 limit',
                  'Starts in 24 days',
                  'Scheduled',
                  TavolaColors.textMuted,
                ),
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
                          'Coupon Codes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Create Coupon'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Offer')),
                      DataColumn(label: Text('Validity')),
                      DataColumn(label: Text('Redemptions')),
                      DataColumn(label: Text('Revenue')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      _Coupon(
                        'WELCOME20',
                        '20% off first order',
                        'Until 31 Dec 2026',
                        '286 / 500',
                        '₹1.86L',
                        'Active',
                        TavolaColors.success,
                      ),
                      _Coupon(
                        'DINNER500',
                        '₹500 off over ₹3,000',
                        'Until 31 Aug 2026',
                        '82 / 200',
                        '₹2.94L',
                        'Active',
                        TavolaColors.success,
                      ),
                      _Coupon(
                        'SUMMER10',
                        '10% off beverages',
                        'Ended 30 Jun 2026',
                        '410 / 500',
                        '₹84,200',
                        'Expired',
                        TavolaColors.textMuted,
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
                  'Create Discount',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('Define an automatic or staff-applied discount'),
                const SizedBox(height: TavolaSpace.md),
                const Wrap(
                  spacing: TavolaSpace.md,
                  runSpacing: TavolaSpace.md,
                  children: [
                    _DiscountInput('Discount name', 'Weekday Lunch'),
                    _DiscountInput('Discount type', 'Percentage'),
                    _DiscountInput('Value', '10%'),
                    _DiscountInput('Applies to', 'Entire bill'),
                    _DiscountInput('Minimum order', '₹800'),
                    _DiscountInput('Valid until', '31 Aug 2026'),
                  ],
                ),
                const SizedBox(height: TavolaSpace.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Save Discount'),
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

class _Offer extends StatelessWidget {
  const _Offer(
    this.amount,
    this.name,
    this.copy,
    this.usage,
    this.impact,
    this.status,
    this.color,
  );
  final String amount, name, copy, usage, impact, status;
  final Color color;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TavolaStatusBadge(label: amount, color: TavolaColors.accentDark),
            const Spacer(),
            TavolaStatusBadge(label: status, color: color),
          ],
        ),
        const Spacer(),
        Text(
          name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          copy,
          style: const TextStyle(
            color: TavolaColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _Line('Usage', usage),
        _Line('Revenue impact', impact),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () {}, child: const Text('Edit Discount')),
      ],
    ),
  );
}

class _Coupon extends DataRow {
  _Coupon(
    String c,
    String o,
    String v,
    String r,
    String revenue,
    String s,
    Color color,
  ) : super(
        cells: [
          DataCell(
            Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          DataCell(Text(o)),
          DataCell(Text(v)),
          DataCell(Text(r)),
          DataCell(Text(revenue)),
          DataCell(TavolaStatusBadge(label: s, color: color)),
        ],
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: TavolaColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _DiscountInput extends StatelessWidget {
  const _DiscountInput(this.label, this.value);
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
