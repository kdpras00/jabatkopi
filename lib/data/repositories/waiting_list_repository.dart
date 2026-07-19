import '../../core/network/api_client.dart';

class WaitingListRepository {
  final ApiClient apiClient;

  WaitingListRepository({required this.apiClient});

  Future<Map<String, dynamic>> joinWaitingList(int partySize, {String? notes, String? fcmToken}) async {
    try {
      final response = await apiClient.post('/waiting-list', {
        'party_size': partySize,
        'notes': notes,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });
      return response['data'];
    } catch (e) {
      throw Exception('Failed to join waiting list: $e');
    }
  }

  Future<Map<String, dynamic>?> getMyStatus() async {
    try {
      final response = await apiClient.get('/waiting-list/my');
      return response['data'];
    } catch (e) {
      throw Exception('Failed to get waiting list status: $e');
    }
  }

  Future<void> cancelMyWaitingList(int id) async {
    try {
      await apiClient.put('/waiting-list/$id/cancel', {});
    } catch (e) {
      throw Exception('Failed to cancel waiting list: $e');
    }
  }
}
