import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/billing',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Create Bill',
            subtitle: 'Table 5 · Order #ORD-1042 · 4 guests',
            actionLabel: 'Unpaid Bills',
            actionIcon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= TavolaBreakpoints.medium
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _BillItems()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(flex: 2, child: _BillSummary()),
                    ],
                  )
                : const Column(
                    children: [
                      _BillItems(),
                      SizedBox(height: TavolaSpace.md),
                      _BillSummary(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _BillItems extends StatelessWidget {
  const _BillItems();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order items',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Review items before generating the bill',
                    style: TextStyle(
                      fontSize: 12,
                      color: TavolaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Edit Order')),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        const _Line('Margherita Pizza × 1', 'Extra cheese', '₹340.00'),
        const _Line('Cold Coffee × 2', 'No sugar', '₹260.00'),
        const _Line('Paneer Tikka × 1', '—', '₹260.00'),
        const SizedBox(height: TavolaSpace.lg),
        Row(
          children: [
            const Expanded(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Coupon or discount code',
                ),
              ),
            ),
            const SizedBox(width: TavolaSpace.sm),
            OutlinedButton(onPressed: () {}, child: const Text('Apply')),
          ],
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.name, this.detail, this.amount);
  final String name, detail, amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _BillSummary extends StatelessWidget {
  const _BillSummary();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Bill summary',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TavolaStatusBadge(
              label: '#INV-2048',
              color: TavolaColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        const _Amount('Subtotal', '₹860.00'),
        const _Amount('Discount', '− ₹50.00'),
        const _Amount('CGST (2.5%)', '₹20.25'),
        const _Amount('SGST (2.5%)', '₹20.25'),
        const _Amount('Service charge', '₹40.50'),
        const Divider(),
        const _Amount('Amount due', '₹891.00', bold: true),
        const SizedBox(height: TavolaSpace.md),
        const Text(
          'Customer',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TavolaColors.textSecondary,
          ),
        ),
        const SizedBox(height: TavolaSpace.xs),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Arjun Mehta · +91 98765 43210',
          ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Split Bill'),
          ),
        ),
        const SizedBox(height: TavolaSpace.xs),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Proceed to Payment'),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('Preview Bill')),
        TextButton(onPressed: () {}, child: const Text('Save as Unpaid')),
      ],
    ),
  );
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
