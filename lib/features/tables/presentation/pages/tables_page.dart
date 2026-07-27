import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/dining_table.dart';
import '../providers/dining_table_providers.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(restaurantTablesProvider);
    final statusState = ref.watch(tableStatusControllerProvider);
    ref.listen<AsyncValue<void>>(tableStatusControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update table status.')),
        );
      } else if (previous?.isLoading == true && next.hasValue) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table status updated.')));
      }
    });
    return TavolaAppShell(
      activeRoute: '/tables',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: 'Table Overview',
              subtitle: tables.when(
                data: _tableSubtitle,
                loading: () => 'Loading dining tables…',
                error: (_, _) => 'Unable to load dining tables',
              ),
              actionLabel: 'New Order',
              actionIcon: Icons.add_rounded,
            ),
            const SizedBox(height: TavolaSpace.md),
            const Wrap(
              spacing: TavolaSpace.md,
              runSpacing: TavolaSpace.xs,
              children: [
                _Legend(label: 'Free', color: TavolaColors.success),
                _Legend(label: 'Occupied', color: TavolaColors.accent),
                _Legend(label: 'Billing', color: TavolaColors.info),
                _Legend(label: 'Reserved', color: TavolaColors.textMuted),
              ],
            ),
            const SizedBox(height: TavolaSpace.lg),
            tables.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(label: 'Loading tables…'),
              ),
              error: (error, _) => TavolaErrorState(
                message: 'We could not load your dining tables.',
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
                      childAspectRatio: 1.35,
                      children: data
                          .map(
                            (table) => _TableTile(
                              table: table,
                              isUpdating: statusState.isLoading,
                              onStatusSelected: (status) => ref
                                  .read(tableStatusControllerProvider.notifier)
                                  .updateStatus(
                                    tableId: table.id,
                                    status: status,
                                  ),
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
    required this.table,
    required this.isUpdating,
    required this.onStatusSelected,
  });
  final DiningTable table;
  final bool isUpdating;
  final ValueChanged<DiningTableStatus> onStatusSelected;

  Color get color => switch (table.status) {
    DiningTableStatus.available => TavolaColors.success,
    DiningTableStatus.occupied => TavolaColors.accent,
    DiningTableStatus.reserved => TavolaColors.textMuted,
    DiningTableStatus.unavailable => TavolaColors.error,
  };
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
          Align(
            alignment: Alignment.topRight,
            child: isUpdating
                ? SizedBox(
                    width: TavolaSize.iconMedium,
                    height: TavolaSize.iconMedium,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<DiningTableStatus>(
                    tooltip: 'Change table status',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: onStatusSelected,
                    itemBuilder: (_) => DiningTableStatus.values
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            enabled: status != table.status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const Spacer(),
          Text(
            table.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${table.capacity} seats · ${table.status.label}',
            style: const TextStyle(
              fontSize: 11,
              color: TavolaColors.textSecondary,
            ),
          ),
          const SizedBox(height: TavolaSpace.xs),
          TavolaStatusBadge(label: table.status.label, color: color),
        ],
      ),
    ),
  );
}
