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
import '../../../tables/domain/entities/dining_table.dart';
import '../../../tables/presentation/providers/dining_table_providers.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_providers.dart';

/// Reservation create/edit workflow based on handoff screens 85 and 86.
class ReservationEditorPage extends ConsumerStatefulWidget {
  const ReservationEditorPage({this.reservationId, super.key});

  final String? reservationId;

  bool get isNew => reservationId == null;

  @override
  ConsumerState<ReservationEditorPage> createState() =>
      _ReservationEditorPageState();
}

class _ReservationEditorPageState extends ConsumerState<ReservationEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _guestName = TextEditingController();
  final _guestPhone = TextEditingController();
  final _partySize = TextEditingController(text: '2');
  final _notes = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String? _tableId;
  bool _sendSms = true;
  bool _initialised = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _guestName.dispose();
    _guestPhone.dispose();
    _partySize.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _initialise(Reservation? reservation) {
    if (_initialised || reservation == null) return;
    _initialised = true;
    _guestName.text = reservation.guestName;
    _guestPhone.text = reservation.guestPhone ?? '';
    _partySize.text = reservation.partySize.toString();
    _date = DateUtils.dateOnly(reservation.reservedFor);
    _time = TimeOfDay.fromDateTime(reservation.reservedFor);
    _tableId = reservation.tableId;
    _notes.text = reservation.notes ?? '';
    _sendSms = reservation.sendConfirmationSms;
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(restaurantReservationsProvider);
    final tables = ref.watch(restaurantTablesProvider);
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
            final reservation = widget.isNew
                ? null
                : items
                      .where((item) => item.id == widget.reservationId)
                      .firstOrNull;
            if (!widget.isNew && reservation == null) {
              return const TavolaEmptyState(
                title: 'Reservation not found',
                message:
                    'It may have been cancelled or you may no longer have access.',
                icon: Icons.event_busy_outlined,
              );
            }
            _initialise(reservation);
            return _Editor(
              reservation: reservation,
              tables: tables,
              child: _form(reservation, tables),
            );
          },
        ),
      ),
    );
  }

  Widget _form(Reservation? reservation, AsyncValue<List<DiningTable>> tables) {
    final tableOptions = tables.asData?.value ?? const <DiningTable>[];
    final matchingTable = tableOptions.where((table) => table.id == _tableId);
    final selectedTableIsVisible = matchingTable.isNotEmpty;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(
            label: 'Guest name',
            child: TextFormField(
              controller: _guestName,
              autofocus: widget.isNew,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Full name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the guest name'
                  : null,
            ),
          ),
          const SizedBox(height: TavolaSpace.md),
          _FormField(
            label: 'Phone number',
            child: TextFormField(
              controller: _guestPhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: '+91 00000 00000'),
            ),
          ),
          const SizedBox(height: TavolaSpace.md),
          Row(
            children: [
              Expanded(child: _dateField(context)),
              const SizedBox(width: TavolaSpace.md),
              Expanded(child: _timeField(context)),
            ],
          ),
          const SizedBox(height: TavolaSpace.md),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Party size',
                  child: TextFormField(
                    controller: _partySize,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '2'),
                    validator: (value) {
                      final size = int.tryParse(value?.trim() ?? '');
                      return size == null || size < 1
                          ? 'Enter the number of guests'
                          : null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: TavolaSpace.md),
              Expanded(
                child: _FormField(
                  label: 'Table',
                  child: tables.isLoading
                      ? const SizedBox(
                          height: TavolaSize.buttonHeight,
                          child: Center(
                            child: SizedBox(
                              width: TavolaSize.iconMedium,
                              height: TavolaSize.iconMedium,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: selectedTableIsVisible
                              ? _tableId
                              : null,
                          isExpanded: true,
                          hint: const Text('Assign later'),
                          items: tableOptions
                              .where(
                                (table) =>
                                    table.status ==
                                        DiningTableStatus.available ||
                                    table.id == _tableId,
                              )
                              .map(
                                (table) => DropdownMenuItem(
                                  value: table.id,
                                  child: Text(
                                    '${table.label} · ${table.capacity} seats',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _tableId = value),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.md),
          _FormField(
            label: 'Guest notes',
            child: TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Occasion, allergies or seating preference',
              ),
            ),
          ),
          const SizedBox(height: TavolaSpace.md),
          CheckboxListTile(
            value: _sendSms,
            contentPadding: EdgeInsets.zero,
            title: const Text('Send confirmation by SMS'),
            subtitle: const Text(
              'A confirmation is sent when SMS delivery is configured.',
              style: TextStyle(color: TavolaColors.textSecondary),
            ),
            onChanged: (value) => setState(() => _sendSms = value ?? false),
          ),
          if (_error != null) ...[
            const SizedBox(height: TavolaSpace.sm),
            Text(_error!, style: const TextStyle(color: TavolaColors.error)),
          ],
          const SizedBox(height: TavolaSpace.lg),
          Row(
            children: [
              if (reservation != null &&
                  (reservation.status == ReservationStatus.pending ||
                      reservation.status == ReservationStatus.confirmed))
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _cancelReservation(reservation),
                  style: TextButton.styleFrom(
                    foregroundColor: TavolaColors.error,
                  ),
                  child: const Text('Cancel Reservation'),
                ),
              const Spacer(),
            ],
          ),
          if (reservation != null) const SizedBox(height: TavolaSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => context.go(AppRoutes.reservations),
                child: Text(reservation == null ? 'Cancel' : 'Discard'),
              ),
              const SizedBox(width: TavolaSpace.sm),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () => _save(reservation, tableOptions),
                child: _saving
                    ? const SizedBox(
                        width: TavolaSize.iconMedium,
                        height: TavolaSize.iconMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TavolaColors.textInverse,
                        ),
                      )
                    : Text(
                        reservation == null
                            ? 'Create Reservation'
                            : 'Save Changes',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(BuildContext context) => _FormField(
    label: 'Date',
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(TavolaSize.buttonHeight),
      ),
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateUtils.dateOnly(DateTime.now()),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selected != null && mounted) setState(() => _date = selected);
      },
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(MaterialLocalizations.of(context).formatMediumDate(_date)),
    ),
  );

  Widget _timeField(BuildContext context) => _FormField(
    label: 'Time',
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(TavolaSize.buttonHeight),
      ),
      onPressed: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: _time,
        );
        if (selected != null && mounted) setState(() => _time = selected);
      },
      icon: const Icon(Icons.schedule_outlined),
      label: Text(_time.format(context)),
    ),
  );

  Future<void> _save(Reservation? existing, List<DiningTable> tables) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = await ref.read(currentMembershipProvider.future);
    if (!mounted) return;
    if (membership == null || !_canManageReservations(membership.role)) {
      setState(() => _error = 'Your role is not allowed to save reservations.');
      return;
    }
    final selectedTable = tables
        .where((table) => table.id == _tableId)
        .firstOrNull;
    final branchId = existing?.branchId ?? selectedTable?.branchId;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final reservedFor = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      await ref
          .read(reservationRepositoryProvider)
          .saveReservation(
            restaurantId: membership.restaurantId,
            id: existing?.id,
            branchId: branchId,
            tableId: _tableId,
            guestName: _guestName.text,
            guestPhone: _guestPhone.text.trim().isEmpty
                ? null
                : _guestPhone.text,
            partySize: int.parse(_partySize.text),
            reservedFor: reservedFor,
            notes: _notes.text.trim().isEmpty ? null : _notes.text,
            sendConfirmationSms: _sendSms,
          );
      ref.invalidate(restaurantReservationsProvider);
      if (mounted) context.go(AppRoutes.reservations);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save the reservation. Check the table availability and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text(
          '${reservation.guestName}\'s reservation will be cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep reservation'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TavolaColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(reservationRepositoryProvider)
          .cancelReservation(reservationId: reservation.id);
      ref.invalidate(restaurantReservationsProvider);
      if (mounted) context.go(AppRoutes.reservations);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not cancel the reservation. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _canManageReservations(TavolaRole role) => role != TavolaRole.kitchen;
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.reservation,
    required this.tables,
    required this.child,
  });

  final Reservation? reservation;
  final AsyncValue<List<DiningTable>> tables;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final existing = reservation;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to reservations',
                    onPressed: () => context.go(AppRoutes.reservations),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: TavolaSpace.xs),
                  Expanded(
                    child: TavolaPageHeader(
                      title: existing == null
                          ? 'New Reservation'
                          : 'Edit Reservation · ${existing.id.substring(0, 8).toUpperCase()}',
                      subtitle: existing == null
                          ? 'Add a guest, time, party size, and table.'
                          : 'Update this guest booking and table assignment.',
                    ),
                  ),
                  if (existing != null)
                    TavolaStatusBadge(
                      label: existing.status.label,
                      color: existing.status == ReservationStatus.confirmed
                          ? TavolaColors.info
                          : TavolaColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: TavolaSpace.lg),
              TavolaPanel(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: TavolaSpace.xs),
      child,
    ],
  );
}
