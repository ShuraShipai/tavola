import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class KitchenOrderDetailPage extends StatelessWidget {
  const KitchenOrderDetailPage({super.key, required this.ticketId});
  final String ticketId;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/kitchen',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kitchen  ›  KOT-3194',
            style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
          ),
          const SizedBox(height: TavolaSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: TavolaSpace.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kitchen Ticket KOT-3194',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const Text(
                    'Table 5 · Dine-in · Sent at 2:14 PM by Anita Nair',
                  ),
                ],
              ),
              Wrap(
                spacing: TavolaSpace.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Preview Ticket'),
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Ready'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth > 720
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _KitchenTicket()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _KitchenMeta()),
                    ],
                  )
                : const Column(
                    children: [
                      _KitchenTicket(),
                      SizedBox(height: TavolaSpace.md),
                      _KitchenMeta(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class KitchenTicketPreviewPage extends StatelessWidget {
  const KitchenTicketPreviewPage({super.key, required this.ticketId});
  final String ticketId;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/kitchen',
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PrintTicket()),
              SizedBox(width: TavolaSpace.md),
              SizedBox(width: 210, child: _PrintOptions()),
            ],
          ),
        ),
      ),
    ),
  );
}

class _KitchenTicket extends StatelessWidget {
  const _KitchenTicket();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Order items', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            const TavolaStatusBadge(
              label: 'Preparing',
              color: TavolaColors.warning,
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.lg),
        const _KitchenLine('1×', 'Margherita Pizza', 'Extra cheese'),
        const _KitchenLine('2×', 'Cold Coffee', 'No sugar'),
        const _KitchenLine('1×', 'Paneer Tikka', '—'),
        const Divider(),
        const Text(
          'Special instruction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please send the pizza first when ready.',
          style: TextStyle(color: TavolaColors.textSecondary),
        ),
      ],
    ),
  );
}

class _KitchenLine extends StatelessWidget {
  const _KitchenLine(this.qty, this.item, this.note);
  final String qty, item, note;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          qty,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: TavolaColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(note, style: const TextStyle(color: TavolaColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _KitchenMeta extends StatelessWidget {
  const _KitchenMeta();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ticket details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Meta('Table', 'Table 5'),
        const _Meta('Guests', '4'),
        const _Meta('Order type', 'Dine-in'),
        const _Meta('Elapsed', '12 min'),
        const _Meta('Assigned station', 'Main kitchen'),
        const Divider(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Start Preparing'),
          ),
        ),
        const SizedBox(height: TavolaSpace.xs),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Mark Ready'),
          ),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TavolaColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _PrintTicket extends StatelessWidget {
  const _PrintTicket();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      children: [
        Text('MAIN KITCHEN', style: Theme.of(context).textTheme.titleMedium),
        const Text(
          'KOT-3194 · Table 5 · 2:14 PM',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const Divider(height: 32),
        const _KitchenLine('1×', 'Margherita Pizza', 'Extra cheese'),
        const _KitchenLine('2×', 'Cold Coffee', 'No sugar'),
        const _KitchenLine('1×', 'Paneer Tikka', '—'),
        const Divider(height: 32),
        const Text(
          'Dine-in · Anita Nair',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
      ],
    ),
  );
}

class _PrintOptions extends StatelessWidget {
  const _PrintOptions();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kitchen ticket',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: TavolaSpace.md),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Destination',
            hintText: 'Main Kitchen Printer',
          ),
        ),
        const SizedBox(height: TavolaSpace.sm),
        const TextField(
          decoration: InputDecoration(labelText: 'Copies', hintText: '1'),
        ),
        const SizedBox(height: TavolaSpace.md),
        const Text(
          'Kitchen tickets never include customer payment information.',
          style: TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const SizedBox(height: TavolaSpace.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Print Kitchen Ticket'),
          ),
        ),
      ],
    ),
  );
}
