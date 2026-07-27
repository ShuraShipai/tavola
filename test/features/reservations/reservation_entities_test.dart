import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/reservations/domain/entities/reservation.dart';

void main() {
  test('no-show has a staff-readable status label', () {
    expect(ReservationStatus.noShow.label, 'No show');
  });

  test(
    'reservation query retains the explicit status and time constraints',
    () {
      final from = DateTime.utc(2026, 7, 28, 12);
      final query = ReservationQuery(
        branchId: 'branch-a',
        statuses: {ReservationStatus.confirmed, ReservationStatus.seated},
        from: from,
      );

      expect(query.branchId, 'branch-a');
      expect(
        query.statuses,
        containsAll(<ReservationStatus>[
          ReservationStatus.confirmed,
          ReservationStatus.seated,
        ]),
      );
      expect(query.from, from);
    },
  );
}
