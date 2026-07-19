import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// Exception khusus yang dilempar saat server mengembalikan 401 Unauthorized.
/// Berbeda dari error jaringan biasa — ini berarti token tidak valid/expired.
/// Caller (mis. AuthProvider) harus menangani ini dengan melakukan forceLogout().
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Sesi tidak valid. Silakan login kembali.']);
  @override
  String toString() => message;
}

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

    // Sertakan token jika ada
    final token = await secureStorage.read(key: 'jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      // Timeout 15 detik agar aplikasi tidak hang saat internet lambat
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      dynamic jsonBody;
      try {
        jsonBody = jsonDecode(response.body);
      } catch (_) {
        // Server mengembalikan HTML/Teks (bukan JSON) — biasanya error 500
        throw Exception('Server mengembalikan data tidak valid (Code: ${response.statusCode})');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonBody;
      } else if (response.statusCode == 401) {
        // Token tidak valid atau expired — hapus token lokal.
        // INI SATU-SATUNYA tempat token dihapus secara otomatis (selain logout eksplisit).
        // Error jaringan/timeout TIDAK menghapus token.
        debugPrint('[ApiClient] 401 Unauthorized pada $endpoint — menghapus token lokal.');
        await clearToken();
        throw const UnauthorizedException();
      } else {
        final msg = jsonBody is Map ? (jsonBody['message'] ?? 'Permintaan ditolak server (${response.statusCode}).') : 'Error ${response.statusCode}';
        throw Exception(msg);
      }
    } on TimeoutException {
      // Koneksi timeout — JANGAN hapus token, ini masalah jaringan sementara
      throw Exception('Koneksi timeout. Silakan periksa jaringan internet Anda.');
    } on UnauthorizedException {
      // Re-throw tanpa di-wrap agar caller bisa mendeteksi tipe ini
      rethrow;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  Future<dynamic> get(String endpoint) => _proxyRequest('GET', endpoint);

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) => _proxyRequest('POST', endpoint, body);

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) => _proxyRequest('PUT', endpoint, body);

  Future<dynamic> delete(String endpoint) => _proxyRequest('DELETE', endpoint);
}
