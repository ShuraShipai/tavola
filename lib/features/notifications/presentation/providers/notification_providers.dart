import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../domain/entities/operational_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseNotificationRepository(client);
});
final operationalNotificationsProvider =
    StreamProvider<List<OperationalNotification>>(
      (ref) => ref.watch(notificationRepositoryProvider).watchNotifications(),
    );
