import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';

class AuthRepository {
  final http.Client client;

  AuthRepository({required this.client});

  Future<AuthModel> login(String username, String password) async {
    final response = await client.post(
      Uri.parse('https://api.jabatkopi.com/login'),
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AuthModel.fromJson(data);
    } else {
      throw Exception('Failed to login');
    }
  }
}
