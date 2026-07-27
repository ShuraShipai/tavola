import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/domain/entities/restaurant_membership.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_providers.dart';

/// Screen 84 — the restaurant's operational reservation board.
///
/// Mutations deliberately stay in the editor and seating routes. This page
/// only renders provider state and sends a stable reservation id through the
/// router, keeping it free of repository/Supabase knowledge.
class ReservationsPage extends ConsumerStatefulWidget {
  const ReservationsPage({super.key});

  @override
  ConsumerState<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends ConsumerState<ReservationsPage> {
  _ReservationTab _tab = _ReservationTab.today;

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(restaurantReservationsProvider);
    final membership = ref.watch(currentMembershipProvider);
    final today = DateUtils.dateOnly(DateTime.now());

    return TavolaAppShell(
      activeRoute: '/reservations',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TavolaSize.maxContentWidth,
          ),
          child: reservations.when(
            loading: () => const _ReservationLoadingPage(),
            error: (error, _) => _ReservationErrorPage(
              onRetry: () => ref.invalidate(restaurantReservationsProvider),
            ),
            data: (allReservations) {
              final filtered = _filter(allReservations, today);
              final summary = _summaryForToday(allReservations, today);
              final role = membership.dataOrNull?.role;
              final canManage = role != null && _canManageReservations(role);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TavolaPageHeader(
                    title: 'Reservations',
                    subtitle: summary,
                    actionLabel: 'New Reservation',
                    onAction: canManage
                        ? () => context.go('/reservations/new')
                        : null,
                  ),
                  if (membership.hasValue && !canManage) ...[
                    const SizedBox(height: TavolaSpace.sm),
                    const _PermissionHint(),
                  ],
                  const SizedBox(height: TavolaSpace.lg),
                  _ReservationTabs(
                    selected: _tab,
                    reservations: allReservations,
                    today: today,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  if (filtered.isEmpty)
                    _TabEmptyState(tab: _tab)
                  else
                    _ReservationTable(
                      reservations: filtered,
                      canManage: canManage,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Reservation> _filter(List<Reservation> reservations, DateTime today) {
    final tomorrow = today.add(const Duration(days: 1));
    final selected = switch (_tab) {
      _ReservationTab.today => reservations.where(
        (item) => _isOnDay(item.reservedFor, today),
      ),
      _ReservationTab.upcoming => reservations.where(
        (item) => !item.reservedFor.isBefore(tomorrow),
      ),
      _ReservationTab.waitlist => reservations.where(
        (item) =>
            item.status == ReservationStatus.pending &&
            item.tableLabel == null &&
            !item.reservedFor.isBefore(today),
      ),
      _ReservationTab.past => reservations.where(
        (item) =>
            item.reservedFor.isBefore(today) ||
            item.status == ReservationStatus.completed ||
            item.status == ReservationStatus.cancelled ||
            item.status == ReservationStatus.noShow,
      ),
    };
    final result = selected.toList()
      ..sort((a, b) => a.reservedFor.compareTo(b.reservedFor));
    return result;
  }

  String _summaryForToday(List<Reservation> reservations, DateTime today) {
    final bookings = reservations.where(
      (item) => _isOnDay(item.reservedFor, today),
    );
    final active = bookings.where(
      (item) =>
          item.status != ReservationStatus.cancelled &&
          item.status != ReservationStatus.noShow,
    );
    final guestCount = active.fold<int>(0, (sum, item) => sum + item.partySize);
    return '${DateFormat('EEEE, d MMMM', 'en_IN').format(today)} · '
        '${active.length} bookings · $guestCount expected guests';
  }
}

enum _ReservationTab { today, upcoming, waitlist, past }

bool _canManageReservations(TavolaRole role) => role != TavolaRole.kitchen;

bool _isOnDay(DateTime value, DateTime day) =>
    value.year == day.year && value.month == day.month && value.day == day.day;

class _ReservationLoadingPage extends StatelessWidget {
  const _ReservationLoadingPage();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(TavolaSpace.xl),
    child: TavolaLoadingIndicator(label: 'Loading reservations…'),
  );
}

class _ReservationErrorPage extends StatelessWidget {
  const _ReservationErrorPage({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => TavolaErrorState(
    message: 'We could not load reservations.',
    onRetry: onRetry,
  );
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.infoLight,
      borderRadius: TavolaRadius.small,
    ),
    child: const Padding(
      padding: EdgeInsets.all(TavolaSpace.sm),
      child: Text(
        'Your role can view reservations but cannot create, edit, assign, or seat them.',
        style: TextStyle(color: TavolaColors.info),
      ),
    ),
  );
}

class _ReservationTabs extends StatelessWidget {
  const _ReservationTabs({
    required this.selected,
    required this.reservations,
    required this.today,
    required this.onSelected,
  });

  final _ReservationTab selected;
  final List<Reservation> reservations;
  final DateTime today;
  final ValueChanged<_ReservationTab> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: TavolaSpace.xs,
    runSpacing: TavolaSpace.xs,
    children: _ReservationTab.values
        .map((tab) {
          final active = tab == selected;
          final label = switch (tab) {
            _ReservationTab.today => 'Today (${_countToday()})',
            _ReservationTab.upcoming => 'Upcoming',
            _ReservationTab.waitlist => 'Waitlist (${_countWaitlist()})',
            _ReservationTab.past => 'Past',
          };
          return Semantics(
            selected: active,
            button: true,
            label: label,
            child: OutlinedButton(
              onPressed: () => onSelected(tab),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, TavolaSize.touchTarget),
                foregroundColor: active
                    ? TavolaColors.textInverse
                    : TavolaColors.textSecondary,
                backgroundColor: active
                    ? TavolaColors.primary
                    : TavolaColors.surface,
                side: BorderSide(
                  color: active ? TavolaColors.primary : TavolaColors.border,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: TavolaRadius.large,
                ),
              ),
              child: Text(label),
            ),
          );
        })
        .toList(growable: false),
  );

  int _countToday() =>
      reservations.where((item) => _isOnDay(item.reservedFor, today)).length;

  int _countWaitlist() => reservations
      .where(
        (item) =>
            item.status == ReservationStatus.pending && item.tableLabel == null,
      )
      .length;
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.tab});
  final _ReservationTab tab;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (tab) {
      _ReservationTab.today => (
        'No reservations today',
        'Create a reservation to start planning today’s service.',
      ),
      _ReservationTab.upcoming => (
        'No upcoming reservations',
        'Future bookings will appear here.',
      ),
      _ReservationTab.waitlist => (
        'No waitlist guests',
        'Guests waiting for a table will appear here.',
      ),
      _ReservationTab.past => (
        'No past reservations',
        'Completed, cancelled, and historical bookings will appear here.',
      ),
    };
    return TavolaEmptyState(
      title: title,
      message: message,
      icon: Icons.event_available_outlined,
    );
  }
}

class _ReservationTable extends StatelessWidget {
  const _ReservationTable({
    required this.reservations,
    required this.canManage,
  });

  final List<Reservation> reservations;
  final bool canManage;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingTextStyle: const TextStyle(
              color: TavolaColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.48,
            ),
            dataTextStyle: const TextStyle(
              color: TavolaColors.textPrimary,
              fontSize: 14,
            ),
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            horizontalMargin: TavolaSpace.md,
            columnSpacing: TavolaSpace.lg,
            dividerThickness: 1,
            columns: const [
              DataColumn(label: Text('TIME')),
              DataColumn(label: Text('GUEST')),
              DataColumn(label: Text('PARTY')),
              DataColumn(label: Text('TABLE')),
              DataColumn(label: Text('CONTACT')),
              DataColumn(label: Text('NOTES')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: reservations
                .map((reservation) => _row(context, reservation))
                .toList(growable: false),
          ),
        ),
      ),
    ),
  );

  DataRow _row(BuildContext context, Reservation reservation) => DataRow(
    cells: [
      DataCell(
        Text(
          AppFormatters.time.format(reservation.reservedFor),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      DataCell(Text(reservation.guestName)),
      DataCell(Text('${reservation.partySize}')),
      DataCell(Text(reservation.tableLabel ?? 'Unassigned')),
      DataCell(Text(reservation.guestPhone ?? '—')),
      // Notes are intentionally a placeholder until the domain entity exposes
      // the notes persisted by the reservation repository.
      const DataCell(Text('—')),
      DataCell(_ReservationStatusBadge(status: reservation.status)),
      DataCell(_ActionButton(reservation: reservation, canManage: canManage)),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.reservation, required this.canManage});
  final Reservation reservation;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final action = _actionFor(reservation);
    final route = action == 'Edit'
        ? '/reservations/${reservation.id}/edit'
        : '/reservations/${reservation.id}/seat';
    return OutlinedButton(
      onPressed: canManage ? () => context.go(route) : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(58, 34),
        padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.sm),
        foregroundColor: TavolaColors.secondary,
        side: const BorderSide(color: TavolaColors.border),
      ),
      child: Text(action),
    );
  }

  String _actionFor(Reservation item) {
    if (item.status == ReservationStatus.pending && item.tableLabel == null) {
      return 'Assign';
    }
    if (item.status == ReservationStatus.confirmed &&
        _isOnDay(item.reservedFor, DateUtils.dateOnly(DateTime.now()))) {
      return 'Seat';
    }
    return 'Edit';
  }
}

class _ReservationStatusBadge extends StatelessWidget {
  const _ReservationStatusBadge({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReservationStatus.pending => ('Pending', TavolaColors.secondary),
      ReservationStatus.confirmed => ('Confirmed', TavolaColors.info),
      ReservationStatus.seated => ('Seated', TavolaColors.success),
      ReservationStatus.completed => ('Completed', TavolaColors.success),
      ReservationStatus.cancelled => ('Cancelled', TavolaColors.error),
      ReservationStatus.noShow => ('No show', TavolaColors.error),
    };
    return TavolaStatusBadge(label: label, color: color);
  }
}
