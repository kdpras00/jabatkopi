import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'handlers/auth_handler.dart';
import 'handlers/menu_handler.dart';
import 'handlers/table_handler.dart';
import 'handlers/reservation_handler.dart';
import 'handlers/order_handler.dart';
import 'handlers/notification_handler.dart';

class ApiClient {
  final FlutterSecureStorage secureStorage;

  late final AuthHandler _authHandler;
  late final MenuHandler _menuHandler;
  late final TableHandler _tableHandler;
  late final ReservationHandler _reservationHandler;
  late final OrderHandler _orderHandler;
  late final NotificationHandler _notificationHandler;

  ApiClient({FlutterSecureStorage? storage})
      : secureStorage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ) {
    _authHandler = AuthHandler(secureStorage);
    _menuHandler = MenuHandler();
    _tableHandler = TableHandler(secureStorage);
    _reservationHandler = ReservationHandler(secureStorage);
    _orderHandler = OrderHandler(secureStorage);
    _notificationHandler = NotificationHandler(secureStorage);
  }

  Future<void> setToken(String token) async {
    await secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_token');
  }

  Future<dynamic> _proxyRequest(String method, String endpoint,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse(endpoint);
    final cleanPath = uri.path;
    final pathSegments = uri.pathSegments;
    final params = uri.queryParameters;

    try {
      if (cleanPath.startsWith('/auth') || cleanPath.startsWith('/profile')) {
        return _authHandler.handle(method, cleanPath, body);
      }
      if (cleanPath.startsWith('/menus') ||
          cleanPath.startsWith('/admin/menus')) {
        return _menuHandler.handle(method, cleanPath, pathSegments, body);
      }
      if (cleanPath.startsWith('/tables') ||
          cleanPath.startsWith('/admin/tables')) {
        return _tableHandler.handle(
            method, cleanPath, pathSegments, params, body);
      }
      if (cleanPath.startsWith('/reservations') ||
          cleanPath.startsWith('/admin/reservations')) {
        return _reservationHandler.handle(
            method, cleanPath, pathSegments, body);
      }
      if (cleanPath.startsWith('/orders') ||
          cleanPath.startsWith('/admin/users')) {
        return _orderHandler.handle(method, cleanPath, pathSegments, body);
      }
      if (cleanPath.startsWith('/notifications')) {
        return _notificationHandler.handle(method, cleanPath);
      }

      throw Exception('Route not handled: $method $cleanPath');
    } catch (e) {
      throw Exception('Serverless error ($cleanPath): $e');
    }
  }

  Future<dynamic> get(String endpoint) => _proxyRequest('GET', endpoint);

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) =>
      _proxyRequest('POST', endpoint, body);

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) =>
      _proxyRequest('PUT', endpoint, body);

  Future<dynamic> delete(String endpoint) => _proxyRequest('DELETE', endpoint);
}
