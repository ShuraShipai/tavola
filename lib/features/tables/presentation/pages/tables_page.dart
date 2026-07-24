import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/tables',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Table Overview',
            subtitle:
                '14 occupied · 6 free · 2 reserved · 22 tables across all dining areas',
            actionLabel: 'New Order',
            actionIcon: Icons.add_rounded,
          ),
          const SizedBox(height: TavolaSpace.md),
          Wrap(
            spacing: TavolaSpace.md,
            runSpacing: TavolaSpace.xs,
            children: const [
              _Legend(label: 'Free', color: TavolaColors.success),
              _Legend(label: 'Occupied', color: TavolaColors.accent),
              _Legend(label: 'Billing', color: TavolaColors.info),
              _Legend(label: 'Reserved', color: TavolaColors.textMuted),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          GridView.count(
            crossAxisCount: TavolaBreakpoints.isExpanded(context)
                ? 4
                : TavolaBreakpoints.isCompact(context)
                ? 2
                : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: TavolaSpace.md,
            mainAxisSpacing: TavolaSpace.md,
            childAspectRatio: 1.35,
            children: const [
              _TableTile(
                number: '1',
                seats: '4 seats · 32 min',
                status: 'Occupied',
                color: TavolaColors.accent,
              ),
              _TableTile(
                number: '2',
                seats: '2 seats · Free',
                status: 'Free',
                color: TavolaColors.success,
              ),
              _TableTile(
                number: '3',
                seats: '4 seats · 18 min',
                status: 'Occupied',
                color: TavolaColors.accent,
              ),
              _TableTile(
                number: '4',
                seats: '6 seats · Billing',
                status: 'Billing',
                color: TavolaColors.info,
              ),
              _TableTile(
                number: '5',
                seats: '4 seats · 12 min',
                status: 'Occupied',
                color: TavolaColors.accent,
              ),
              _TableTile(
                number: '6',
                seats: '4 seats · 8:00 PM',
                status: 'Reserved',
                color: TavolaColors.textMuted,
              ),
              _TableTile(
                number: '7',
                seats: '2 seats · Free',
                status: 'Free',
                color: TavolaColors.success,
              ),
              _TableTile(
                number: '8',
                seats: '8 seats · 44 min',
                status: 'Occupied',
                color: TavolaColors.accent,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: TavolaColors.textSecondary),
      ),
    ],
  );
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.number,
    required this.seats,
    required this.status,
    required this.color,
  });
  final String number;
  final String seats;
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: TavolaRadius.medium,
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .18),
            foregroundColor: color,
            child: const Icon(Icons.table_restaurant_outlined),
          ),
          const Spacer(),
          Text(
            'Table $number',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            seats,
            style: const TextStyle(
              fontSize: 11,
              color: TavolaColors.textSecondary,
            ),
          ),
          const SizedBox(height: TavolaSpace.xs),
          TavolaStatusBadge(label: status, color: color),
        ],
      ),
    ),
  );
}
