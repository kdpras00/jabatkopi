import 'package:jabatkopi/core/network/api_client.dart';

class ReservationRepository {
  final ApiClient apiClient;

  ReservationRepository({required this.apiClient});

  Future<List<Map<String, dynamic>>> checkAvailability(String date, String time) async {
    try {
      final response = await apiClient.get('/tables/available?date=$date&time=$time');
      final List<dynamic> data = response['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }

  Future<Map<String, dynamic>> createReservation(String date, String time, int guests, int customerId, int tableId) async {
    try {
      final response = await apiClient.post('/reservations', {
        'date': date,
        'time': time,
        'guests': guests,
        'customer_id': customerId,
        'table_id': tableId,
      });
      return response['data'];
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReservationHistory() async {
    try {
      final response = await apiClient.get('/reservations/history');
      final List<dynamic> data = response['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get reservation history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAdminReservations() async {
    try {
      final response = await apiClient.get('/admin/reservations');
      final List<dynamic> data = response['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get admin reservations: $e');
    }
  }

  Future<void> cancelReservation(int id) async {
    try {
      await apiClient.put('/reservations/$id/cancel', {});
    } catch (e) {
      throw Exception('Failed to cancel reservation: $e');
    }
  }
}
