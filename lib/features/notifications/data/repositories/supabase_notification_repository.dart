import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/operational_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<OperationalNotification>> getNotifications() async {
    final rows = await _client
        .from('operational_notifications')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Stream<List<OperationalNotification>> watchNotifications() => _client
      .from('operational_notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(_fromRow).toList(growable: false));
  @override
  Future<void> markRead(String notificationId) => _client.rpc(
    'mark_notification_read',
    params: {'p_notification_id': notificationId},
  );
  OperationalNotification _fromRow(Map<String, dynamic> row) =>
      OperationalNotification(
        id: row['id'] as String,
        restaurantId: row['restaurant_id'] as String,
        eventType: row['event_type'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        readAt: row['read_at'] == null
            ? null
            : DateTime.parse(row['read_at'] as String),
      );
}
