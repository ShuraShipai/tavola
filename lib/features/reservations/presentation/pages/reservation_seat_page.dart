import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/domain/entities/restaurant_membership.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_providers.dart';

final _eligibleReservationTablesProvider =
    FutureProvider.family<List<ReservationTableCandidate>, Reservation>(
      (ref, reservation) => ref
          .watch(reservationRepositoryProvider)
          .getEligibleTables(
            restaurantId: reservation.restaurantId,
            branchId: reservation.branchId,
            reservedFor: reservation.reservedFor,
            partySize: reservation.partySize,
            durationMinutes: reservation.durationMinutes,
            excludeReservationId: reservation.id,
          ),
    );

/// Table assignment and seating workflow from handoff screen 110.
class ReservationSeatPage extends ConsumerStatefulWidget {
  const ReservationSeatPage({required this.reservationId, super.key});

  final String reservationId;

  @override
  ConsumerState<ReservationSeatPage> createState() =>
      _ReservationSeatPageState();
}

class _ReservationSeatPageState extends ConsumerState<ReservationSeatPage> {
  String? _selectedTableId;
  bool _startDineInOrder = true;
  bool _submitting = false;
  String? _error;

  void _selectTable(String tableId) =>
      setState(() => _selectedTableId = tableId);

  void _setStartDineInOrder(bool value) =>
      setState(() => _startDineInOrder = value);

  Future<void> _seat(
    Reservation reservation,
    ReservationTableCandidate table,
  ) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (!mounted) return;
    if (membership == null || membership.role == TavolaRole.kitchen) {
      setState(() => _error = 'Your role is not allowed to seat reservations.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(reservationRepositoryProvider)
          .seatReservation(reservationId: reservation.id, tableId: table.id);
      ref.invalidate(restaurantReservationsProvider);
      if (mounted) {
        // An order cannot be created without items. Continue to the order
        // workflow when requested, after the authoritative seat succeeds.
        context.go(
          _startDineInOrder ? AppRoutes.orders : AppRoutes.reservations,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not seat this reservation. Refresh tables and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(restaurantReservationsProvider);
    return TavolaAppShell(
      activeRoute: AppRoutes.reservations,
      child: Padding(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: reservations.when(
          loading: () =>
              const TavolaLoadingIndicator(label: 'Loading reservation…'),
          error: (_, _) => TavolaErrorState(
            message: 'Unable to load this reservation.',
            onRetry: () => ref.invalidate(restaurantReservationsProvider),
          ),
          data: (items) {
            final reservation = items
                .where((item) => item.id == widget.reservationId)
                .firstOrNull;
            if (reservation == null) {
              return const TavolaEmptyState(
                title: 'Reservation not found',
                message:
                    'It may have been cancelled or you may no longer have access.',
                icon: Icons.event_busy_outlined,
              );
            }
            if (reservation.status == ReservationStatus.seated ||
                reservation.status == ReservationStatus.completed) {
              return const TavolaEmptyState(
                title: 'Guest is already seated',
                message: 'This reservation cannot be seated again.',
                icon: Icons.event_seat_outlined,
              );
            }
            return _SeatContent(reservation: reservation);
          },
        ),
      ),
    );
  }
}

class _SeatContent extends ConsumerWidget {
  const _SeatContent({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = context.findAncestorStateOfType<_ReservationSeatPageState>()!;
    final candidates = ref.watch(
      _eligibleReservationTablesProvider(reservation),
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: 'Back to reservations',
                    onPressed: () => context.go(AppRoutes.reservations),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: TavolaSpace.xs),
                  Expanded(
                    child: TavolaPageHeader(
                      title: 'Seat ${reservation.guestName}',
                      subtitle:
                          'Reservation · Party of ${reservation.partySize} · ${TimeOfDay.fromDateTime(reservation.reservedFor).format(context)}',
                    ),
                  ),
                  const TavolaStatusBadge(
                    label: 'Guest arrived',
                    color: TavolaColors.accentDark,
                  ),
                ],
              ),
              const SizedBox(height: TavolaSpace.lg),
              TavolaPanel(
                child: candidates.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(TavolaSpace.xl),
                    child: TavolaLoadingIndicator(label: 'Finding tables…'),
                  ),
                  error: (_, _) => TavolaErrorState(
                    message: 'We could not check eligible tables.',
                    onRetry: () => ref.invalidate(
                      _eligibleReservationTablesProvider(reservation),
                    ),
                  ),
                  data: (tables) => _SeatForm(
                    reservation: reservation,
                    tables: tables,
                    state: state,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatForm extends ConsumerWidget {
  const _SeatForm({
    required this.reservation,
    required this.tables,
    required this.state,
  });

  final Reservation reservation;
  final List<ReservationTableCandidate> tables;
  final _ReservationSeatPageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = tables.where(
      (table) => table.id == state._selectedTableId,
    );
    final selectedTable = selected.isEmpty ? null : selected.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a table', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.xs),
        const Text(
          'Only tables that fit the party and are free for this reservation are shown.',
          style: TextStyle(color: TavolaColors.textSecondary),
        ),
        const SizedBox(height: TavolaSpace.md),
        if (tables.isEmpty)
          const TavolaEmptyState(
            title: 'No eligible tables',
            message:
                'Try a different reservation time or free a suitable table first.',
            icon: Icons.table_restaurant_outlined,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? 3
                  : constraints.maxWidth >= 440
                  ? 2
                  : 1;
              return GridView.builder(
                itemCount: tables.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: TavolaSpace.sm,
                  crossAxisSpacing: TavolaSpace.sm,
                  childAspectRatio: 1.7,
                ),
                itemBuilder: (_, index) {
                  final table = tables[index];
                  final isSelected = table.id == state._selectedTableId;
                  return _TableChoice(
                    table: table,
                    selected: isSelected,
                    onTap: state._submitting
                        ? null
                        : () => state._selectTable(table.id),
                  );
                },
              );
            },
          ),
        const SizedBox(height: TavolaSpace.lg),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: state._startDineInOrder,
          onChanged: state._submitting
              ? null
              : (value) => state._setStartDineInOrder(value ?? false),
          title: const Text('Continue to orders after seating'),
          subtitle: const Text(
            'Seating is saved first; then Tavola opens the order workflow.',
            style: TextStyle(color: TavolaColors.textSecondary),
          ),
        ),
        if (selectedTable != null) ...[
          const SizedBox(height: TavolaSpace.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: TavolaColors.infoLight,
              borderRadius: TavolaRadius.small,
            ),
            child: Padding(
              padding: const EdgeInsets.all(TavolaSpace.sm),
              child: Text(
                '${selectedTable.label} fits this party and is ready for reservation assignment.',
                style: const TextStyle(color: TavolaColors.info),
              ),
            ),
          ),
        ],
        if (state._error != null) ...[
          const SizedBox(height: TavolaSpace.sm),
          Text(
            state._error!,
            style: const TextStyle(color: TavolaColors.error),
          ),
        ],
        const SizedBox(height: TavolaSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: state._submitting
                  ? null
                  : () => context.go(AppRoutes.reservations),
              child: const Text('Back'),
            ),
            const SizedBox(width: TavolaSpace.sm),
            FilledButton(
              onPressed: state._submitting || selectedTable == null
                  ? null
                  : () => state._seat(reservation, selectedTable),
              child: state._submitting
                  ? const SizedBox(
                      width: TavolaSize.iconMedium,
                      height: TavolaSize.iconMedium,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TavolaColors.textInverse,
                      ),
                    )
                  : Text('Seat at ${selectedTable?.label ?? 'table'}'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TableChoice extends StatelessWidget {
  const _TableChoice({
    required this.table,
    required this.selected,
    required this.onTap,
  });

  final ReservationTableCandidate table;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? TavolaColors.infoLight : TavolaColors.surface,
    borderRadius: TavolaRadius.medium,
    child: InkWell(
      onTap: onTap,
      borderRadius: TavolaRadius.medium,
      child: Container(
        padding: const EdgeInsets.all(TavolaSpace.md),
        decoration: BoxDecoration(
          borderRadius: TavolaRadius.medium,
          border: Border.all(
            color: selected ? TavolaColors.info : TavolaColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(table.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: TavolaSpace.xxs),
            Text(
              '${table.capacity} seats',
              style: const TextStyle(color: TavolaColors.textSecondary),
            ),
            const Spacer(),
            const TavolaStatusBadge(
              label: 'Available',
              color: TavolaColors.success,
            ),
          ],
        ),
      ),
    ),
  );
}
