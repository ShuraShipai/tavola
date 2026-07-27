import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/restaurant_report.dart';
import '../providers/report_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _periodDays = 7;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(restaurantReportProvider);
    return TavolaAppShell(
      activeRoute: '/reports',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: report.when(
          loading: () => const SizedBox(
            height: 420,
            child: TavolaLoadingIndicator(label: 'Loading reports…'),
          ),
          error: (error, _) => SizedBox(
            height: 420,
            child: TavolaErrorState(
              message: 'We could not load the restaurant report.',
              onRetry: () => ref.invalidate(restaurantReportProvider),
            ),
          ),
          data: (data) => data.orderCount == 0 && data.refundAmount == 0
              ? const _EmptyReports()
              : _ReportContent(
                  report: data,
                  periodDays: _periodDays,
                  onPeriodChanged: (days) {
                    setState(() => _periodDays = days);
                    ref.read(reportPeriodDaysProvider.notifier).setPeriod(days);
                    ref.invalidate(restaurantReportProvider);
                  },
                  onRefresh: () => ref.invalidate(restaurantReportProvider),
                ),
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TavolaPageHeader(
        title: 'Reports & Analytics',
        subtitle: 'Business performance for the last 7 days',
      ),
      SizedBox(height: TavolaSpace.lg),
      SizedBox(
        height: 300,
        child: TavolaEmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'No report data yet',
          message:
              'Completed payments and refunds will appear here once service starts.',
        ),
      ),
    ],
  );
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.report,
    required this.periodDays,
    required this.onPeriodChanged,
    required this.onRefresh,
  });
  final RestaurantReport report;
  final int periodDays;
  final ValueChanged<int> onPeriodChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TavolaPageHeader(
        title: 'Reports & Analytics',
        subtitle:
            '${AppFormatters.date.format(report.periodStart)} – ${AppFormatters.date.format(report.periodEnd)}',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: TavolaSpace.sm,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyCsv(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ),
      const SizedBox(height: TavolaSpace.lg),
      LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          crossAxisCount: constraints.maxWidth > 900 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: TavolaSpace.md,
          mainAxisSpacing: TavolaSpace.md,
          childAspectRatio: 1.7,
          children: [
            TavolaMetricCard(
              label: 'Net sales',
              value: AppFormatters.currency.format(report.netSalesAmount / 100),
              icon: Icons.payments_rounded,
              tone: TavolaColors.success,
              detail: 'Completed payments less refunds',
            ),
            TavolaMetricCard(
              label: 'Orders',
              value: '${report.orderCount}',
              icon: Icons.receipt_long_rounded,
              tone: TavolaColors.info,
              detail: 'Paid orders in period',
            ),
            TavolaMetricCard(
              label: 'Average order',
              value: AppFormatters.currency.format(
                report.averageOrderAmount / 100,
              ),
              icon: Icons.trending_up_rounded,
              tone: TavolaColors.accent,
              detail: 'Net sales per paid order',
            ),
            TavolaMetricCard(
              label: 'Refunds',
              value: AppFormatters.currency.format(report.refundAmount / 100),
              icon: Icons.replay_rounded,
              tone: TavolaColors.error,
              detail: 'Refunds issued in period',
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
            Wrap(
              spacing: TavolaSpace.xs,
              children: [
                ChoiceChip(
                  label: Text('Last 7 days'),
                  selected: periodDays == 7,
                  onSelected: (_) => onPeriodChanged(7),
                ),
                ChoiceChip(
                  label: Text('Last 30 days'),
                  selected: periodDays == 30,
                  onSelected: (_) => onPeriodChanged(30),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: TavolaSpace.lg),
      LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth > 760
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _RevenuePanel(report: report)),
                  const SizedBox(width: TavolaSpace.md),
                  Expanded(child: _PaymentMix(report: report)),
                ],
              )
            : Column(
                children: [
                  _RevenuePanel(report: report),
                  const SizedBox(height: TavolaSpace.md),
                  _PaymentMix(report: report),
                ],
              ),
      ),
      const SizedBox(height: TavolaSpace.lg),
      _RecentPayments(report: report),
    ],
  );

  void _copyCsv(BuildContext context) {
    final rows = [
      'date,amount',
      ...report.dailySales.map(
        (d) => '${d.date.toIso8601String()},${d.amount}',
      ),
    ];
    Clipboard.setData(ClipboardData(text: rows.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report CSV copied to clipboard')),
    );
  }
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.report});
  final RestaurantReport report;
  @override
  Widget build(BuildContext context) {
    final highest = report.dailySales.fold<int>(
      0,
      (max, day) => day.amount > max ? day.amount : max,
    );
    return TavolaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue trend',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TavolaSpace.lg),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: report.dailySales
                  .map(
                    (day) => _Bar(
                      label: AppFormatters.date
                          .format(day.date)
                          .split(' ')
                          .first,
                      height: highest == 0 ? 0 : day.amount / highest,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.height});
  final String label;
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
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: TavolaColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
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
  const _PaymentMix({required this.report});
  final RestaurantReport report;
  @override
  Widget build(BuildContext context) {
    final gross = report.paymentMix.fold<int>(
      0,
      (total, item) => total + item.amount,
    );
    final primary = report.paymentMix.isEmpty
        ? 0.0
        : report.paymentMix.first.amount / gross;
    return TavolaPanel(
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
                value: primary,
                strokeWidth: 18,
                color: TavolaColors.accent,
                backgroundColor: TavolaColors.surfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: TavolaSpace.md),
          ...report.paymentMix.map(
            (item) => _Mix(
              name: _paymentLabel(item.method),
              value: gross == 0
                  ? '0%'
                  : '${(item.amount * 100 / gross).round()}%',
            ),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String method) => switch (method) {
    'upi' => 'UPI',
    'card' => 'Card',
    'cash' => 'Cash',
    'wallet' => 'Wallet',
    'bank_transfer' => 'Bank transfer',
    _ => 'Other',
  };
}

class _Mix extends StatelessWidget {
  const _Mix({required this.name, required this.value});
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

class _RecentPayments extends StatelessWidget {
  const _RecentPayments({required this.report});
  final RestaurantReport report;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent payments',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: TavolaSpace.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Paid at')),
              DataColumn(label: Text('Method')),
              DataColumn(label: Text('Amount')),
            ],
            rows: report.recentPayments
                .map(
                  (payment) => DataRow(
                    cells: [
                      DataCell(
                        Text(AppFormatters.dateTime.format(payment.paidAt)),
                      ),
                      DataCell(Text(payment.method.toUpperCase())),
                      DataCell(
                        Text(
                          AppFormatters.currency.format(payment.amount / 100),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    ),
  );
}
