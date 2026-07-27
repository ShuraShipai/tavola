import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/support_repository.dart';

class SupabaseSupportRepository implements SupportRepository {
  SupabaseSupportRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<void> createRequest({
    required String restaurantId,
    required String subject,
    required String message,
    String priority = 'normal',
  }) => _client.from('support_requests').insert({
    'restaurant_id': restaurantId,
    'created_by': _client.auth.currentUser!.id,
    'subject': subject.trim(),
    'message': message.trim(),
    'priority': priority,
  });
}
