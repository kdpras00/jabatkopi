import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiClient {
  static String get baseUrl {
    // Return different localhost mapping based on platform
    // 10.0.2.2 is the special alias to your host loopback interface in Android emulator
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  final FlutterSecureStorage secureStorage;
  String? _authToken;

  ApiClient({FlutterSecureStorage? storage}) 
      : secureStorage = storage ?? const FlutterSecureStorage() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _authToken = await secureStorage.read(key: 'jwt_token');
  }

  Future<void> setToken(String token) async {
    _authToken = token;
    await secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    _authToken = null;
    await secureStorage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> get _headers async {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken == null) {
      await _loadToken();
    }
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _headers;
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _headers;
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'API Error');
    }
  }
}
