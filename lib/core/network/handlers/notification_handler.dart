import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationHandler {
  final FlutterSecureStorage secureStorage;

  NotificationHandler(this.secureStorage);

  Future<dynamic> handle(String method, String cleanPath) async {
    if (cleanPath == '/notifications' && method == 'GET') {
      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 1;

      final notifications = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return {
        'status': 200,
        'message': 'Success',
        'data': notifications,
      };
    }

    throw Exception('Route not handled in NotificationHandler: $method $cleanPath');
  }
}
