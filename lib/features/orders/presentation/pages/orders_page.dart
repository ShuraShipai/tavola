import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/orders',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'New Order',
            subtitle: 'Table 5 · 4 guests · Anita Nair',
            actionLabel: 'Hold Order',
            actionIcon: Icons.pause_circle_outline,
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= TavolaBreakpoints.medium
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _MenuBrowser()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _OrderTicket()),
                    ],
                  )
                : const Column(
                    children: [
                      _MenuBrowser(),
                      SizedBox(height: TavolaSpace.md),
                      _OrderTicket(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _MenuBrowser extends StatelessWidget {
  const _MenuBrowser();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Starters', 'Main Course', 'Beverages', 'Desserts']
              .map(
                (label) => Padding(
                  padding: const EdgeInsets.only(right: TavolaSpace.xs),
                  child: label == 'Starters'
                      ? FilledButton(onPressed: () {}, child: Text(label))
                      : OutlinedButton(onPressed: () {}, child: Text(label)),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: TavolaSpace.md),
      GridView.count(
        crossAxisCount: TavolaBreakpoints.isCompact(context) ? 1 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: TavolaSpace.md,
        crossAxisSpacing: TavolaSpace.md,
        childAspectRatio: 1.7,
        children: const [
          _MenuItem(
            name: 'Paneer Tikka',
            description: 'Cottage cheese, yoghurt and charred peppers',
            price: '₹260',
            tone: TavolaColors.accent,
          ),
          _MenuItem(
            name: 'Garlic Bread',
            description: 'Herb butter, parmesan and parsley',
            price: '₹180',
            tone: TavolaColors.info,
          ),
          _MenuItem(
            name: 'Crispy Corn',
            description: 'Sweet corn, chilli and lime',
            price: '₹220',
            tone: TavolaColors.success,
          ),
          _MenuItem(
            name: 'Tomato Soup',
            description: 'Roasted tomato and basil',
            price: '₹160',
            tone: TavolaColors.error,
          ),
          _MenuItem(
            name: 'Chicken Wings',
            description: 'Smoky barbeque glaze',
            price: '₹320',
            tone: TavolaColors.primary,
          ),
          _MenuItem(
            name: 'Loaded Nachos',
            description: 'Salsa, cheese and jalapeños',
            price: '₹240',
            tone: TavolaColors.accentDark,
          ),
        ],
      ),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.tone,
  });
  final String name;
  final String description;
  final String price;
  final Color tone;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: Row(
      children: [
        Container(
          width: 84,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: .14),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
          child: Icon(Icons.restaurant_rounded, color: tone, size: 30),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(TavolaSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TavolaColors.textMuted,
                  ),
                ),
                const SizedBox(height: TavolaSpace.xs),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(34, 32),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrderTicket extends StatelessWidget {
  const _OrderTicket();

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Current Order',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TavolaStatusBadge(
              label: '3 items',
              color: TavolaColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        const _TicketLine(
          name: 'Margherita Pizza',
          detail: 'Extra cheese',
          quantity: '1×',
          price: '₹380',
        ),
        const _TicketLine(
          name: 'Cold Coffee',
          detail: 'No sugar',
          quantity: '2×',
          price: '₹260',
        ),
        const _TicketLine(
          name: 'Paneer Tikka',
          detail: '—',
          quantity: '1×',
          price: '₹260',
        ),
        const Divider(),
        const _TotalLine(label: 'Subtotal', amount: '₹900'),
        const _TotalLine(label: 'GST (5%)', amount: '₹45'),
        const _TotalLine(label: 'Service charge', amount: '₹90'),
        const Divider(),
        const _TotalLine(label: 'Total', amount: '₹1,035', bold: true),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Send to Kitchen'),
          ),
        ),
        const SizedBox(height: TavolaSpace.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            child: const Text('Save changes'),
          ),
        ),
      ],
    ),
  );
}

class _TicketLine extends StatelessWidget {
  const _TicketLine({
    required this.name,
    required this.detail,
    required this.quantity,
    required this.price,
  });
  final String name;
  final String detail;
  final String quantity;
  final String price;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(quantity, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: TavolaSpace.xs),
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
        Text(price, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.amount,
    this.bold = false,
  });
  final String label;
  final String amount;
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
          amount,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
