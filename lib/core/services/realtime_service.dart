import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final SupabaseClient client;
  StreamSubscription? _orderSubscription;

  RealtimeService({required this.client});

  void listenToOrders(void Function(List<Map<String, dynamic>> payload) onData) {
    _orderSubscription = client
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      onData(data);
    });
  }

  void stopListening() {
    _orderSubscription?.cancel();
  }
}
