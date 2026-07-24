import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static help guides, support chat and system-health states from screens 118–120.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/settings',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Help & Support',
            subtitle: 'Guides, support and operational health',
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: c.maxWidth > 900
                  ? 4
                  : c.maxWidth > 550
                  ? 2
                  : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: 1.25,
              children: const [
                _Guide(
                  'Setup',
                  'Open your restaurant',
                  'Taxes, tables, staff, menu and printers.',
                  Icons.rocket_launch_outlined,
                  TavolaColors.info,
                ),
                _Guide(
                  'Service',
                  'Take and manage orders',
                  'Dine-in, takeaway, delivery and kitchen tickets.',
                  Icons.room_service_outlined,
                  TavolaColors.accent,
                ),
                _Guide(
                  'Billing',
                  'Bills and payments',
                  'Split bills, refunds, unpaid bills and receipts.',
                  Icons.receipt_long_outlined,
                  TavolaColors.success,
                ),
                _Guide(
                  'Closing',
                  'End-of-day closing',
                  'Settle drawers, shifts, terminals and reports.',
                  Icons.lock_clock_outlined,
                  TavolaColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth > 800
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _Chat()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _Status()),
                    ],
                  )
                : const Column(
                    children: [
                      _Chat(),
                      SizedBox(height: TavolaSpace.md),
                      _Status(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _Guide extends StatelessWidget {
  const _Guide(this.tag, this.title, this.copy, this.icon, this.color);
  final String tag, title, copy;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 14),
        TavolaStatusBadge(label: tag, color: color),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          copy,
          style: const TextStyle(
            fontSize: 12,
            color: TavolaColors.textSecondary,
          ),
        ),
        const Spacer(),
        OutlinedButton(onPressed: () {}, child: const Text('Read Guide')),
      ],
    ),
  );
}

class _Chat extends StatelessWidget {
  const _Chat();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tavola Support',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Text(
                  'Typical response time under 3 minutes',
                  style: TextStyle(
                    color: TavolaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            TavolaStatusBadge(label: 'Online', color: TavolaColors.success),
          ],
        ),
        const SizedBox(height: 18),
        const _Message(
          'Support · Priya',
          'Hello Rahul! How can I help with La Rosetta Café today?',
          false,
        ),
        const _Message(
          'You',
          'I need help reconciling the cash drawer before daily closing.',
          true,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TavolaColors.infoLight,
            borderRadius: TavolaRadius.small,
          ),
          child: const Text(
            'Do not share customer payment details or staff PINs in chat.',
            style: TextStyle(fontSize: 12, color: TavolaColors.info),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: 'Write a message…'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: () {}, child: const Text('Send')),
          ],
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.name, this.message, this.me);
  final String name, message;
  final bool me;
  @override
  Widget build(BuildContext context) => Align(
    alignment: me ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: me ? TavolaColors.accentLight : TavolaColors.surfaceVariant,
        borderRadius: TavolaRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(message),
        ],
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'System Status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
            TavolaStatusBadge(
              label: 'All operational',
              color: TavolaColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Service(
          'POS & Ordering',
          'Order creation, tables and kitchen tickets',
        ),
        const _Service('Payments', 'UPI, card terminal and payment records'),
        const _Service('Cloud Sync', 'Restaurant data and multi-location sync'),
        const _Service(
          'Reports',
          'Sales summaries, exports and closing reports',
        ),
        const Divider(height: 28),
        const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: TavolaColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No incidents in the last 30 days',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Service extends StatelessWidget {
  const _Service(this.title, this.copy);
  final String title, copy;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                copy,
                style: const TextStyle(
                  fontSize: 11,
                  color: TavolaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TavolaStatusBadge(label: 'Operational', color: TavolaColors.success),
      ],
    ),
  );
}
