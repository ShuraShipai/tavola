import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class SplitBillPage extends StatelessWidget {
  const SplitBillPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Split Bill',
    subtitle: 'Invoice #INV-2048 · Total ₹891.00',
    child: LayoutBuilder(
      builder: (context, box) => box.maxWidth > 720
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _SplitItems()),
                SizedBox(width: TavolaSpace.md),
                Expanded(child: _SplitSummary()),
              ],
            )
          : const Column(
              children: [
                _SplitItems(),
                SizedBox(height: TavolaSpace.md),
                _SplitSummary(),
              ],
            ),
    ),
  );
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Collect Payment',
    subtitle: 'Invoice #INV-2048 · Table 5',
    child: LayoutBuilder(
      builder: (context, box) => box.maxWidth > 720
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _PayMethods()),
                SizedBox(width: TavolaSpace.md),
                Expanded(child: _PaymentSummary()),
              ],
            )
          : const Column(
              children: [
                _PayMethods(),
                SizedBox(height: TavolaSpace.md),
                _PaymentSummary(),
              ],
            ),
    ),
  );
}

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Payment Successful',
    subtitle: '₹891.00 received in cash',
    child: Column(
      children: [
        const TavolaPanel(child: _Settlement()),
        const SizedBox(height: TavolaSpace.lg),
        const Center(child: SizedBox(width: 360, child: _ReceiptPaper())),
      ],
    ),
  );
}

class BillPreviewPage extends StatelessWidget {
  const BillPreviewPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Bill Preview',
    subtitle: 'Invoice #INV-2048 · Table 5',
    child: const Center(child: SizedBox(width: 390, child: _ReceiptPaper())),
  );
}

class ReprintReceiptPage extends StatelessWidget {
  const ReprintReceiptPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Reprint Receipt',
    subtitle: 'Find a completed invoice and print or email it again',
    child: const TavolaPanel(child: _ReceiptSearch()),
  );
}

class RefundVoidPage extends StatelessWidget {
  const RefundVoidPage({super.key});
  @override
  Widget build(BuildContext context) => _BillingShell(
    title: 'Refund & Void',
    subtitle: 'Invoice #INV-2048 · Paid by UPI at 2:32 PM',
    child: const TavolaPanel(child: _RefundForm()),
  );
}

class _BillingShell extends StatelessWidget {
  const _BillingShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/billing',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TavolaPageHeader(title: title, subtitle: subtitle),
          const SizedBox(height: TavolaSpace.lg),
          child,
        ],
      ),
    ),
  );
}

class _SplitItems extends StatelessWidget {
  const _SplitItems();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign items to bills',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: TavolaSpace.xs),
        const Text(
          'Select an item and assign it to Bill 1, 2 or 3.',
          style: TextStyle(color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.md),
        const _AssignedItem('Margherita Pizza × 1', '₹340', 'Bill 1'),
        const _AssignedItem('Cold Coffee × 2', '₹260', 'Bill 1'),
        const _AssignedItem('Paneer Tikka × 1', '₹260', 'Bill 2'),
      ],
    ),
  );
}

class _AssignedItem extends StatelessWidget {
  const _AssignedItem(this.name, this.price, this.bill);
  final String name, price, bill;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: TavolaSpace.sm),
    padding: const EdgeInsets.all(TavolaSpace.sm),
    decoration: BoxDecoration(
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.medium,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(price),
        const SizedBox(width: TavolaSpace.md),
        TavolaStatusBadge(label: bill, color: TavolaColors.info),
      ],
    ),
  );
}

class _SplitSummary extends StatelessWidget {
  const _SplitSummary();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill 1 of 3', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Money('Items', '₹600.00'),
        const _Money('Taxes', '₹60.00'),
        const Divider(),
        const _Money('Total with taxes', '₹660.00', bold: true),
        const SizedBox(height: TavolaSpace.md),
        const Text(
          'Each split is collected as its own bill. Start with Bill 1, then continue to the next unpaid split.',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Continue to Payment · Bill 1 of 3'),
          ),
        ),
      ],
    ),
  );
}

class _PayMethods extends StatelessWidget {
  const _PayMethods();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const TavolaStatusBadge(
              label: 'Unpaid',
              color: TavolaColors.warning,
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        Wrap(
          spacing: TavolaSpace.sm,
          runSpacing: TavolaSpace.sm,
          children: ['Cash', 'UPI', 'Card', 'Other']
              .map(
                (e) => SizedBox(
                  width: 135,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: BorderSide(
                        color: e == 'Cash'
                            ? TavolaColors.primary
                            : TavolaColors.border,
                      ),
                    ),
                    child: Text(e),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: TavolaSpace.lg),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Amount received',
            prefixText: '₹ ',
            hintText: '891.00',
          ),
        ),
      ],
    ),
  );
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Money('Bill total', '₹891.00'),
        const _Money('Paid', '₹0.00'),
        const _Money('Balance', '₹891.00', danger: true),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Confirm ₹891 Payment'),
          ),
        ),
        const SizedBox(height: TavolaSpace.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            child: const Text('Save as unpaid'),
          ),
        ),
      ],
    ),
  );
}

class _Money extends StatelessWidget {
  const _Money(
    this.label,
    this.value, {
    this.bold = false,
    this.danger = false,
  });
  final String label, value;
  final bool bold, danger;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : null,
            color: danger ? TavolaColors.error : null,
          ),
        ),
      ],
    ),
  );
}

class _Settlement extends StatelessWidget {
  const _Settlement();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.check_circle, color: TavolaColors.success, size: 52),
      const SizedBox(height: TavolaSpace.sm),
      const Text(
        'Bill settled',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const Text(
        'Invoice #INV-2048 · 19 Jul 2026, 2:32 PM',
        style: TextStyle(color: TavolaColors.textMuted),
      ),
      const SizedBox(height: TavolaSpace.lg),
      Wrap(
        spacing: TavolaSpace.sm,
        runSpacing: TavolaSpace.sm,
        alignment: WrapAlignment.center,
        children: [
          FilledButton(onPressed: () {}, child: const Text('Print Receipt')),
          OutlinedButton(onPressed: () {}, child: const Text('Email Receipt')),
          OutlinedButton(onPressed: () {}, child: const Text('Download PDF')),
          OutlinedButton(onPressed: () {}, child: const Text('New Order')),
        ],
      ),
    ],
  );
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      children: [
        Text(
          'LA ROSETTA CAFÉ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Text(
          '12, Khan Market · New Delhi',
          style: TextStyle(fontSize: 11, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Invoice #INV-2048 · Table 5',
          style: TextStyle(fontSize: 11, color: TavolaColors.textMuted),
        ),
        const Divider(height: 28),
        const _Money('Margherita Pizza', '₹340'),
        const _Money('Cold Coffee × 2', '₹260'),
        const _Money('Paneer Tikka', '₹260'),
        const Divider(),
        const _Money('Subtotal', '₹860'),
        const _Money('GST + service', '₹31'),
        const _Money('Total paid', '₹891', bold: true),
        const Divider(),
        const Text(
          'Paid by cash · Thank you for dining with us!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: TavolaColors.textMuted),
        ),
      ],
    ),
  );
}

class _ReceiptSearch extends StatelessWidget {
  const _ReceiptSearch();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search invoice, order or customer',
        ),
      ),
      const SizedBox(height: TavolaSpace.md),
      const _InvoiceRow(
        '#INV-2048',
        'Table 5 · 19 Jul 2026, 2:32 PM',
        '₹891 · Cash',
      ),
      const _InvoiceRow(
        '#INV-2041',
        'Table 9 · 19 Jul 2026, 1:52 PM',
        '₹980 · UPI',
      ),
      const _InvoiceRow(
        '#INV-2038',
        'Table 3 · 19 Jul 2026, 1:15 PM',
        '₹1,560 · Card',
      ),
    ],
  );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.id, this.detail, this.amount);
  final String id, detail, amount;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(id, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(detail),
    trailing: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: TavolaSpace.sm,
      children: [
        Text(amount),
        OutlinedButton(onPressed: () {}, child: const Text('Print')),
      ],
    ),
  );
}

class _RefundForm extends StatelessWidget {
  const _RefundForm();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Refund payment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          const TavolaStatusBadge(label: 'Paid', color: TavolaColors.success),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      const _Money('Original payment', '₹891.00'),
      const _Money('Refunded so far', '₹0.00'),
      const Divider(),
      const TextField(
        decoration: InputDecoration(
          labelText: 'Refund amount',
          prefixText: '₹ ',
          hintText: '0.00',
        ),
      ),
      const SizedBox(height: TavolaSpace.md),
      const TextField(
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Reason for refund or void',
          hintText: 'Describe the reason for this adjustment',
        ),
      ),
      const SizedBox(height: TavolaSpace.lg),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: TavolaColors.error),
          onPressed: () {},
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text('Confirm Refund'),
        ),
      ),
    ],
  );
}
