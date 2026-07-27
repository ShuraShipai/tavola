import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../domain/entities/dining_table.dart';
import '../providers/dining_table_providers.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(restaurantTablesProvider);
    return TavolaAppShell(
      activeRoute: '/tables',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TablesHeader(
              subtitle: tables.when(
                data: _tableSubtitle,
                loading: () => 'Loading dining tables…',
                error: (_, _) => 'Unable to load dining tables',
              ),
            ),
            const SizedBox(height: TavolaSpace.lg),
            tables.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(label: 'Loading tables…'),
              ),
              error: (error, _) => TavolaErrorState(
                message: switch (error) {
                  TimeoutException() =>
                    'Tables took too long to load. Check the connection and retry.',
                  StateError(:final message)
                      when message.contains('database migration') =>
                    'Tables needs its database migration before it can load. '
                        'Run 20260725140000_complete_pos_operations.sql in Supabase SQL Editor.',
                  StateError(:final message)
                      when message.contains('editable table-status') =>
                    'Tables needs the latest editor migration. Run '
                        '20260728113000_table_editor_workflow.sql in Supabase SQL Editor.',
                  _ =>
                    'We could not load your dining tables. Retry to check Supabase access.',
                },
                onRetry: () => ref.invalidate(restaurantTablesProvider),
              ),
              data: (data) => data.isEmpty
                  ? const TavolaEmptyState(
                      title: 'No tables yet',
                      message:
                          'Add dining tables in Settings before opening service.',
                      icon: Icons.table_restaurant_outlined,
                    )
                  : GridView.count(
                      crossAxisCount: TavolaBreakpoints.isExpanded(context)
                          ? 4
                          : TavolaBreakpoints.isCompact(context)
                          ? 2
                          : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: TavolaSpace.md,
                      mainAxisSpacing: TavolaSpace.md,
                      childAspectRatio: 1.48,
                      children: data
                          .map(
                            (table) => _TableTile(
                              table: table,
                              onPressed: () =>
                                  context.go('/tables/detail/${table.id}'),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tableSubtitle(List<DiningTable> tables) {
    int count(DiningTableStatus status) =>
        tables.where((table) => table.status == status).length;
    return '${count(DiningTableStatus.occupied)} occupied · '
        '${count(DiningTableStatus.available)} free · '
        '${count(DiningTableStatus.reserved)} reserved · '
        '${tables.length} tables across all dining areas';
  }
}

class _TablesHeader extends StatelessWidget {
  const _TablesHeader({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: TavolaSpace.lg,
    runSpacing: TavolaSpace.sm,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table Overview',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: TavolaSpace.xxs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: TavolaSpace.sm,
        runSpacing: TavolaSpace.xs,
        children: [
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.reservations),
            child: const Text('Reservations'),
          ),
          const _Legend(label: 'Free', color: TavolaColors.success),
          const _Legend(label: 'Occupied', color: TavolaColors.accent),
          const _Legend(label: 'Billing', color: TavolaColors.info),
          const _Legend(label: 'Reserved', color: TavolaColors.textMuted),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.tableNew),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Table'),
          ),
        ],
      ),
    ],
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
  const _TableTile({required this.table, required this.onPressed});
  final DiningTable table;
  final VoidCallback onPressed;

  bool get _isBilling => _statusDetail == 'Billing';

  Color get color {
    if (_isBilling) return const Color(0xFF1D4ED8);
    return switch (table.status) {
      DiningTableStatus.available => TavolaColors.success,
      DiningTableStatus.occupied => TavolaColors.accent,
      DiningTableStatus.reserved => TavolaColors.textMuted,
      DiningTableStatus.unavailable => TavolaColors.error,
    };
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${table.label}, ${table.status.label}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: TavolaRadius.medium,
        child: Ink(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: TavolaRadius.medium,
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TavolaSpace.md),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: TavolaSpace.xxl,
                        height: TavolaSpace.xxl,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_restaurant_outlined,
                          size: TavolaSize.iconMedium,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: TavolaSpace.sm),
                      Text(
                        table.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${table.capacity} seats · $_statusDetail',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: TavolaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Color get _borderColor {
    if (_isBilling) return const Color(0xFF93C5FD);
    return switch (table.status) {
      DiningTableStatus.available => TavolaColors.border,
      DiningTableStatus.occupied => const Color(0xFFFCD34D),
      DiningTableStatus.reserved => TavolaColors.border,
      DiningTableStatus.unavailable => TavolaColors.error.withValues(alpha: .5),
    };
  }

  Color get _backgroundColor {
    if (_isBilling) return const Color(0xFFEFF6FF);
    return switch (table.status) {
      DiningTableStatus.available => TavolaColors.surface,
      DiningTableStatus.occupied => const Color(0xFFFFFBEA),
      DiningTableStatus.reserved => TavolaColors.background,
      DiningTableStatus.unavailable => TavolaColors.errorLight,
    };
  }

  String get _statusDetail =>
      table.currentStatusDetail ??
      switch (table.status) {
        DiningTableStatus.available => 'Free',
        DiningTableStatus.occupied => 'Occupied',
        DiningTableStatus.reserved => 'Reserved',
        DiningTableStatus.unavailable => 'Unavailable',
      };
}
