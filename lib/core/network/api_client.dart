import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final FlutterSecureStorage secureStorage;

  ApiClient._internal()
      : secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> setToken(String token) async {
    await secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_token');
  }

  Future<dynamic> _proxyRequest(String method, String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${AppConfig.laravelBaseUrl}/api$endpoint');
    
    final request = http.Request(method, uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';
    
    // Auth Token if exists
    final token = await secureStorage.read(key: 'jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      // Tambahkan timeout 15 detik agar aplikasi tidak hang saat internet lambat
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      dynamic jsonBody;
      try {
        jsonBody = jsonDecode(response.body);
      } catch (_) {
        // Jika server error dan mengembalikan HTML/Teks biasa (bukan JSON)
        throw Exception('Server mengembalikan data tidak valid (Code: ${response.statusCode})');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonBody;
      } else {
        throw Exception(jsonBody['message'] ?? 'Permintaan ditolak server (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan periksa jaringan internet Anda.');
    } catch (e) {
      throw Exception('Kesalahan: $e');
    }
  }

  Future<dynamic> get(String endpoint) => _proxyRequest('GET', endpoint);

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) => _proxyRequest('POST', endpoint, body);

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) => _proxyRequest('PUT', endpoint, body);

  Future<dynamic> delete(String endpoint) => _proxyRequest('DELETE', endpoint);
}
