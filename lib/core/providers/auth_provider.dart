import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository(apiClient: ApiClient());
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _role;
  String? _username;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get role => _role;
  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    final savedRole = await _storage.read(key: 'user_role');
    final savedUsername = await _storage.read(key: 'username');
    
    if (token != null && savedRole != null) {
      _isAuthenticated = true;
      _role = savedRole;
      _username = savedUsername ?? 'User';
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authData = await _authRepository.login(username, password);
      _role = authData.role;
      _username = authData.username;
      _isAuthenticated = true;
      
      // Persist role for auto-login
      await _storage.write(key: 'user_role', value: _role!);
      await _storage.write(key: 'username', value: _username!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'username');
    _role = null;
    _username = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
