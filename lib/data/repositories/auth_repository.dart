import 'package:jabatkopi/core/network/api_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthModel> login(String email, String password) async {
    try {
      final response = await apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final authData = AuthModel.fromJson(response['data']);
      await apiClient.setToken(authData.token);
      return authData;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}
