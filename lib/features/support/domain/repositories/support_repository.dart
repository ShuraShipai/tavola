abstract interface class SupportRepository {
  Future<void> createRequest({
    required String restaurantId,
    required String subject,
    required String message,
    String priority,
  });
}
