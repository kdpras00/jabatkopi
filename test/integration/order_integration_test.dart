import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jabatkopi/core/network/api_client.dart';
import 'package:jabatkopi/data/repositories/order_repository.dart';

void main() {
  late OrderRepository orderRepository;
  late ApiClient apiClient;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    apiClient = ApiClient();
    orderRepository = OrderRepository(apiClient: apiClient);
  });

  group('Order Integration Test', () {
    test('createOrder returns order data on success', () async {
      // Create a mock order to the real backend
      final items = [
        {'menu_id': 1, 'qty': 2, 'subtotal': 30000}
      ];
      
      final result = await orderRepository.createOrder(4, 1, 30000, 'qris', items);
      final order = result['order'] as Map<String, dynamic>;
      
      expect(order['id'], isNotNull);
      expect(order['table_id'], 4);
      expect(order['status'], 'pending');
    });

    test('getOrdersByTable returns list of orders', () async {
      final orders = await orderRepository.getOrdersByTable(4);
      expect(orders, isA<List>());
    });
  });
}
