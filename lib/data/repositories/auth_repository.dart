import 'package:jabatkopi/core/network/api_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthModel> login(String username, String password) async {
    try {
      final response = await apiClient.post('/auth/login', {
        'username': username,
        'password': password,
      });
      
      final data = response['data'];
      final authData = AuthModel.fromJson(data);
      
      // Auto-set token in ApiClient for subsequent requests
      await apiClient.setToken(authData.token);
      
      return authData;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}
