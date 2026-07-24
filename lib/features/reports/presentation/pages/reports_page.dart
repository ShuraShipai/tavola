import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static reports dashboard and focused-sales preview, matching screens 44–49.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/reports',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Reports & Analytics',
            subtitle: 'Business performance for 13–19 July 2026',
            actionLabel: 'Export',
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: c.maxWidth > 900 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              // Metric cards include an icon, value, and trend; keep enough
              // vertical room at desktop and tablet widths to avoid overflow.
              childAspectRatio: 1.7,
              children: const [
                TavolaMetricCard(
                  label: 'Net sales',
                  value: '₹3.18L',
                  icon: Icons.payments_rounded,
                  tone: TavolaColors.success,
                  detail: '▲ 12.4%',
                ),
                TavolaMetricCard(
                  label: 'Orders',
                  value: '1,286',
                  icon: Icons.receipt_long_rounded,
                  tone: TavolaColors.info,
                  detail: '▲ 8.1%',
                ),
                TavolaMetricCard(
                  label: 'Average order',
                  value: '₹247',
                  icon: Icons.trending_up_rounded,
                  tone: TavolaColors.accent,
                  detail: '▲ 3.6%',
                ),
                TavolaMetricCard(
                  label: 'Refunds',
                  value: '₹4,820',
                  icon: Icons.replay_rounded,
                  tone: TavolaColors.error,
                  detail: '1.5% of sales',
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
                  'Detailed Reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: TavolaSpace.sm),
                const Wrap(
                  spacing: TavolaSpace.xs,
                  children: [
                    _ReportChip('Daily Sales', true),
                    _ReportChip('Weekly Sales'),
                    _ReportChip('Monthly Sales'),
                    _ReportChip('Best Sellers'),
                    _ReportChip('Payment Reports'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth > 760
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _RevenuePanel()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _PaymentMix()),
                    ],
                  )
                : const Column(
                    children: [
                      _RevenuePanel(),
                      SizedBox(height: TavolaSpace.md),
                      _PaymentMix(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _ReportChip extends StatelessWidget {
  const _ReportChip(this.label, [this.selected = false]);
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) =>
      ChoiceChip(label: Text(label), selected: selected, onSelected: (_) {});
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Revenue trend',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TavolaStatusBadge(label: '+12.4%', color: TavolaColors.success),
          ],
        ),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _Bar('Mon', .55),
              _Bar('Tue', .68),
              _Bar('Wed', .61),
              _Bar('Thu', .82),
              _Bar('Fri', .73),
              _Bar('Sat', .96),
              _Bar('Sun', .88),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar(this.day, this.height);
  final String day;
  final double height;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: height,
              widthFactor: .48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TavolaColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: TavolaColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _PaymentMix extends StatelessWidget {
  const _PaymentMix();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment mix',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: TavolaSpace.md),
        Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: .58,
              strokeWidth: 18,
              color: TavolaColors.accent,
              backgroundColor: TavolaColors.surfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: TavolaSpace.md),
        const _Mix('UPI', '58%'),
        const _Mix('Card', '24%'),
        const _Mix('Cash', '12%'),
        const _Mix('Wallet / Other', '6%'),
      ],
    ),
  );
}

class _Mix extends StatelessWidget {
  const _Mix(this.name, this.value);
  final String name, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(name),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
