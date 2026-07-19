import 'package:jabatkopi/core/network/api_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient apiClient;

  OrderRepository({required this.apiClient});

  Future<Map<String, dynamic>> createOrder(
    int? tableId,
    String paymentMethod,
    List<Map<String, dynamic>> items, {
    String orderType = 'dine_in',
    String? pickupTime,
  }) async {
    try {
      final body = <String, dynamic>{
        'payment_method': paymentMethod,
        'items': items,
        'order_type': orderType,
      };
      if (tableId != null && tableId != 0) {
        body['table_id'] = tableId;
      }
      if (orderType == 'pickup' && pickupTime != null) {
        body['pickup_time'] = pickupTime;
      }
      final response = await apiClient.post('/orders', body);
      return response['data'];
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByTable(int tableId) async {
    try {
      final response = await apiClient.get('/orders/table/$tableId');
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get orders for table: $e');
    }
  }

  Future<List<OrderModel>> getOrderHistory() async {
    try {
      final response = await apiClient.get('/orders/history');
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get order history: $e');
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final response = await apiClient.get('/orders/active');
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get active orders: $e');
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    try {
      await apiClient.put('/orders/$id/status', {'status': status});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<OrderModel> getOrderDetails(int id) async {
    try {
      final response = await apiClient.get('/orders/$id/details');
      return OrderModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to get order details: $e');
    }
  }

  Future<void> cancelOrder(int id) async {
    try {
      await apiClient.put('/orders/$id/cancel', {});
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
