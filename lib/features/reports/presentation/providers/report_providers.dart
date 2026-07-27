import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_report_repository.dart';
import '../../domain/entities/restaurant_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/get_restaurant_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseReportRepository(client);
});

final getRestaurantReportProvider = Provider<GetRestaurantReport>(
  (ref) => GetRestaurantReport(ref.watch(reportRepositoryProvider)),
);

final reportPeriodDaysProvider =
    NotifierProvider<ReportPeriodDaysController, int>(
      ReportPeriodDaysController.new,
    );

class ReportPeriodDaysController extends Notifier<int> {
  @override
  int build() => 7;

  void setPeriod(int days) => state = days.clamp(1, 90);
}

final restaurantReportProvider = FutureProvider<RestaurantReport>((ref) async {
  final periodDays = ref.watch(reportPeriodDaysProvider);
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    final now = DateTime.now();
    return RestaurantReport(
      periodStart: now.subtract(const Duration(days: 6)),
      periodEnd: now,
      netSalesAmount: 0,
      orderCount: 0,
      refundAmount: 0,
      dailySales: const [],
      paymentMix: const [],
      recentPayments: const [],
    );
  }
  return ref.watch(getRestaurantReportProvider)(
    restaurantId: membership.restaurantId,
    periodEnd: DateTime.now(),
    periodDays: periodDays,
  );
});
