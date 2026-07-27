import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_providers.dart';

class ReservationsPage extends ConsumerWidget {
  const ReservationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(restaurantReservationsProvider);
    return TavolaAppShell(
      activeRoute: '/reservations',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: 'Reservations',
              subtitle: reservations.when(
                data: (data) => '${data.length} upcoming and past bookings',
                loading: () => 'Loading bookings…',
                error: (_, _) => 'Unable to load bookings',
              ),
              actionLabel: 'New Reservation',
            ),
            const SizedBox(height: TavolaSpace.lg),
            reservations.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(label: 'Loading reservations…'),
              ),
              error: (error, _) => TavolaErrorState(
                message: 'We could not load reservations.',
                onRetry: () => ref.invalidate(restaurantReservationsProvider),
              ),
              data: (data) => data.isEmpty
                  ? const TavolaEmptyState(
                      title: 'No reservations yet',
                      message:
                          'Bookings will appear here once they are created.',
                      icon: Icons.event_available_outlined,
                    )
                  : _ReservationList(reservations: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  const _ReservationList({required this.reservations});
  final List<Reservation> reservations;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    padding: EdgeInsets.zero,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Guest')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Party')),
          DataColumn(label: Text('Table')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('')),
        ],
        rows: reservations
            .map(
              (reservation) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      reservation.guestName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      AppFormatters.dateTime.format(reservation.reservedFor),
                    ),
                  ),
                  DataCell(Text('${reservation.partySize} guests')),
                  DataCell(Text(reservation.tableLabel ?? 'Unassigned')),
                  DataCell(
                    TavolaStatusBadge(
                      label: reservation.status.label,
                      color: _statusColor(reservation.status),
                    ),
                  ),
                  DataCell(
                    TextButton(onPressed: () {}, child: const Text('View')),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    ),
  );
  Color _statusColor(ReservationStatus status) => switch (status) {
    ReservationStatus.pending => TavolaColors.accent,
    ReservationStatus.confirmed => TavolaColors.success,
    ReservationStatus.seated => TavolaColors.info,
    ReservationStatus.completed => TavolaColors.success,
    ReservationStatus.cancelled ||
    ReservationStatus.noShow => TavolaColors.error,
  };
}
