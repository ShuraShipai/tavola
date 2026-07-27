class OperationalNotification {
  const OperationalNotification({
    required this.id,
    required this.restaurantId,
    required this.eventType,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });
  final String id;
  final String restaurantId;
  final String eventType;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  bool get isRead => readAt != null;
}
