import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/bill.dart';
import '../providers/billing_providers.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({this.orderId, super.key});

  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: '/billing',
    child: ref
        .watch(billsProvider)
        .when(
          loading: () => const TavolaLoadingIndicator(label: 'Loading bills…'),
          error: (error, _) => TavolaErrorState(
            message: 'Could not load bills: $error',
            onRetry: () => ref.invalidate(billsProvider),
          ),
          data: (bills) {
            if (bills.isEmpty) {
              return const TavolaEmptyState(
                title: 'No bills to settle',
                message:
                    'Served orders will appear here when they are ready for payment.',
              );
            }
            final bill = orderId == null
                ? bills.firstWhere(
                    (value) => value.status != BillStatus.paid,
                    orElse: () => bills.first,
                  )
                : bills.firstWhere(
                    (value) => value.orderId == orderId,
                    orElse: () => bills.first,
                  );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(TavolaSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TavolaPageHeader(
                    title: bill.status == BillStatus.paid
                        ? 'Paid bill'
                        : 'Create bill',
                    subtitle: 'Order #${bill.orderNumber}',
                    actionLabel:
                        '${bills.where((item) => item.amountDue > 0).length} unpaid bills',
                    actionIcon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: TavolaSpace.lg),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= TavolaBreakpoints.medium
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _BillItems(bill: bill)),
                              const SizedBox(width: TavolaSpace.md),
                              Expanded(
                                flex: 2,
                                child: _BillSummary(bill: bill),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _BillItems(bill: bill),
                              const SizedBox(height: TavolaSpace.md),
                              _BillSummary(bill: bill),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
  );
}

class _BillItems extends StatelessWidget {
  const _BillItems({required this.bill});
  final Bill bill;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order items',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: TavolaSpace.xs),
        const Text(
          'Immutable item and price snapshots from the order.',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.md),
        for (final line in bill.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.name} × ${line.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (line.notes?.isNotEmpty ?? false)
                        Text(
                          line.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: TavolaColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.currency.format(line.lineTotalAmount / 100),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _BillSummary extends ConsumerWidget {
  const _BillSummary({required this.bill});
  final Bill bill;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutation = ref.watch(billingMutationProvider);
    final settled = bill.amountDue == 0;
    return TavolaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bill summary',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TavolaStatusBadge(
                label: settled ? 'Paid' : bill.status.name,
                color: settled ? TavolaColors.success : TavolaColors.warning,
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.md),
          _Amount(
            'Order total',
            AppFormatters.currency.format(bill.totalAmount / 100),
          ),
          _Amount('Paid', AppFormatters.currency.format(bill.paidAmount / 100)),
          const Divider(),
          _Amount(
            'Amount due',
            AppFormatters.currency.format(bill.amountDue / 100),
            bold: true,
          ),
          const SizedBox(height: TavolaSpace.lg),
          if (!settled) ...[
            SizedBox(
              width: double.infinity,
              child: PopupMenuButton<PaymentMethod>(
                enabled: !mutation.isLoading,
                onSelected: (method) => ref
                    .read(billingMutationProvider.notifier)
                    .collect(bill: bill, method: method),
                itemBuilder: (_) => PaymentMethod.values
                    .map(
                      (method) => PopupMenuItem(
                        value: method,
                        child: Text('Collect via ${method.label}'),
                      ),
                    )
                    .toList(),
                child: FilledButton.icon(
                  onPressed: null,
                  icon: mutation.isLoading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    mutation.isLoading ? 'Processing…' : 'Collect payment',
                  ),
                ),
              ),
            ),
            if (mutation.hasError)
              Padding(
                padding: const EdgeInsets.only(top: TavolaSpace.sm),
                child: Text(
                  'Payment failed: ${mutation.error}',
                  style: const TextStyle(color: TavolaColors.error),
                ),
              ),
          ] else
            const Text(
              'This bill is fully settled. Receipt and refund actions will be added with the invoice workflow.',
              style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    ),
  );
}
