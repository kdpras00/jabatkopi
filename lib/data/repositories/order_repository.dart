import 'package:jabatkopi/core/network/api_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient apiClient;

  OrderRepository({required this.apiClient});

  Future<Map<String, dynamic>> createOrder(int tableId, int customerId, double totalAmount, String paymentMethod, List<Map<String, dynamic>> items) async {
    try {
      final response = await apiClient.post('/orders', {
        'table_id': tableId,
        'customer_id': customerId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'items': items,
      });
      return response['data'];
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByTable(int tableId) async {
    try {
      final response = await apiClient.get('/orders/table/$tableId');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get orders for table: $e');
    }
  }

  Future<List<OrderModel>> getOrderHistory() async {
    try {
      final response = await apiClient.get('/orders/history');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get order history: $e');
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final response = await apiClient.get('/orders/active');
      final List<dynamic> data = response['data'] ?? [];
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
