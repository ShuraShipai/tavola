import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static reservation list, booking form and seating preview from screens 84–86/110.
class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/reservations',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Reservations',
            subtitle: 'Manage upcoming bookings and seating',
            actionLabel: 'New Reservation',
          ),
          const SizedBox(height: TavolaSpace.lg),
          const Wrap(
            spacing: TavolaSpace.xs,
            children: [
              ChoiceChip(label: Text('Today · 19 Jul'), selected: true),
              ChoiceChip(label: Text('Tomorrow'), selected: false),
              ChoiceChip(label: Text('This week'), selected: false),
            ],
          ),
          const SizedBox(height: TavolaSpace.md),
          TavolaPanel(
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
                rows: [
                  _Reservation(
                    'Arjun Mehta',
                    '7:30 PM',
                    '4 guests',
                    'Table 12',
                    'Confirmed',
                    TavolaColors.success,
                  ),
                  _Reservation(
                    'Sneha Kapoor',
                    '8:00 PM',
                    '2 guests',
                    'Table 5',
                    'Arrived',
                    TavolaColors.info,
                  ),
                  _Reservation(
                    'Rohan Singh',
                    '8:30 PM',
                    '6 guests',
                    'Patio 3',
                    'Pending',
                    TavolaColors.accent,
                  ),
                  _Reservation(
                    'Maya Nair',
                    '9:00 PM',
                    '3 guests',
                    '—',
                    'Waitlist',
                    TavolaColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth > 760
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _BookingForm()),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(child: _SeatingPreview()),
                    ],
                  )
                : const Column(
                    children: [
                      _BookingForm(),
                      SizedBox(height: TavolaSpace.md),
                      _SeatingPreview(),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _Reservation extends DataRow {
  _Reservation(
    String guest,
    String time,
    String party,
    String table,
    String status,
    Color color,
  ) : super(
        cells: [
          DataCell(
            Text(guest, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          DataCell(Text(time)),
          DataCell(Text(party)),
          DataCell(Text(table)),
          DataCell(TavolaStatusBadge(label: status, color: color)),
          DataCell(OutlinedButton(onPressed: null, child: const Text('Edit'))),
        ],
      );
}

class _BookingForm extends StatelessWidget {
  const _BookingForm();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New Reservation', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: TavolaSpace.md),
        const Wrap(
          spacing: TavolaSpace.md,
          runSpacing: TavolaSpace.md,
          children: [
            _RField('Guest name', 'Arjun Mehta'),
            _RField('Phone', '+91 98100 44218'),
            _RField('Date', '19 Jul 2026'),
            _RField('Arrival time', '7:30 PM'),
            _RField('Party size', '4 guests'),
            _RField('Dining area', 'Main Dining'),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        const Text(
          'Special request',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const TextField(
          maxLines: 2,
          decoration: InputDecoration(hintText: 'Celebrating an anniversary'),
        ),
        const SizedBox(height: TavolaSpace.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Save Reservation'),
          ),
        ),
      ],
    ),
  );
}

class _RField extends StatelessWidget {
  const _RField(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: value)),
      ],
    ),
  );
}

class _SeatingPreview extends StatelessWidget {
  const _SeatingPreview();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign a table',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ready tables for 4 guests',
          style: TextStyle(color: TavolaColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _Table('12', '8 seats', true),
            _Table('5', '4 seats', true),
            _Table('7', '4 seats', false),
            _Table('Patio 3', '6 seats', true),
          ],
        ),
        const SizedBox(height: 16),
        const TavolaStatusBadge(
          label: 'Table 12 recommended',
          color: TavolaColors.success,
        ),
      ],
    ),
  );
}

class _Table extends StatelessWidget {
  const _Table(this.name, this.seats, this.open);
  final String name, seats;
  final bool open;
  @override
  Widget build(BuildContext context) => Container(
    width: 95,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: open ? TavolaColors.infoLight : TavolaColors.surfaceVariant,
      borderRadius: TavolaRadius.small,
      border: Border.all(color: open ? TavolaColors.info : TavolaColors.border),
    ),
    child: Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(
          seats,
          style: const TextStyle(
            fontSize: 10,
            color: TavolaColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
