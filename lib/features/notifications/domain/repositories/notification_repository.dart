import '../entities/operational_notification.dart';

abstract interface class NotificationRepository {
  Future<List<OperationalNotification>> getNotifications();
  Stream<List<OperationalNotification>> watchNotifications();
  Future<void> markRead(String notificationId);
}
