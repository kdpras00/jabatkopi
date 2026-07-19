import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  late final AuthRepository _authRepository = AuthRepository(apiClient: _apiClient);

  FlutterSecureStorage get _storage => _apiClient.secureStorage;

  String? _role;
  String? _username;
  int? _userId;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get role => _role;
  String? get username => _username;
  int? get userId => _userId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider();

  Future<void> _syncFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _authRepository.updateFcmToken(fcmToken);
      }
    } catch (e) {
      debugPrint('[AuthProvider] Failed to sync FCM token: $e');
    }
  }

  /// Membaca session yang tersimpan dari secure storage.
  /// Mengembalikan [true] jika session customer valid ditemukan, [false] jika tidak.
  Future<bool> tryRestoreSession() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final savedRole = await _storage.read(key: 'user_role');
      final savedUsername = await _storage.read(key: 'username');
      final savedUserId = await _storage.read(key: 'user_id');

      // Hanya auto-login untuk customer. Admin/pegawai menggunakan web portal.
      if (token != null && savedRole == 'customer') {
        _isAuthenticated = true;
        _role = savedRole;
        _username = savedUsername ?? 'User';
        _userId = int.tryParse(savedUserId ?? '');
        notifyListeners();
        
        // Sinkronisasi FCM token setiap kali buka app
        _syncFcmToken();
        
        return true;
      }
      return false;
    } catch (e) {
      // PENTING: Jangan hapus token saat error! Error bisa disebabkan koneksi
      // buruk atau masalah sementara — token mungkin masih valid.
      // Token hanya dihapus saat server mengkonfirmasi 401 (lihat api_client.dart).
      debugPrint('[AuthProvider] Error restoring session (token TIDAK dihapus): $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authData = await _authRepository.login(email, password);
      
      if (authData.role == 'admin' || authData.role == 'pegawai') {
        _isLoading = false;
        notifyListeners();
        throw Exception('Akses ditolak: Akun admin/pegawai hanya dapat mengakses lewat portal web.');
      }

      _role = authData.role;
      _username = authData.username;
      _userId = authData.id;
      _isAuthenticated = true;
      
      // Persist for auto-login
      await _storage.write(key: 'user_role', value: _role!);
      await _storage.write(key: 'username', value: _username!);
      await _storage.write(key: 'user_id', value: _userId!.toString());
      
      // Sinkronisasi FCM token setiap kali login berhasil
      _syncFcmToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Dipanggil oleh ApiClient saat server mengembalikan 401 Unauthorized.
  /// Ini satu-satunya cara yang sah untuk menghapus sesi secara paksa.
  Future<void> forceLogout() async {
    debugPrint('[AuthProvider] forceLogout dipanggil — token server tidak valid (401).');
    await logout();
  }

  Future<void> logout() async {
    _role = null;
    _username = null;
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();

    await Future.wait([
      _storage.delete(key: 'jwt_token'),
      _storage.delete(key: 'user_role'),
      _storage.delete(key: 'username'),
      _storage.delete(key: 'user_id'),
    ]);
  }
}
