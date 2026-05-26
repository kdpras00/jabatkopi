import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../config/app_config.dart';

class OrderHandler {
  final FlutterSecureStorage secureStorage;

  OrderHandler(this.secureStorage);

  Future<dynamic> handle(String method, String cleanPath,
      List<String> pathSegments, Map<String, dynamic>? body) async {
    if (cleanPath == '/orders' && method == 'POST' && body != null) {
      return _createOrder(body);
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'orders' &&
        pathSegments[1] == 'table' &&
        method == 'GET') {
      return _getOrdersByTable(int.parse(pathSegments[2]));
    }

    if (cleanPath == '/orders/history' && method == 'GET') {
      return _getOrderHistory();
    }

    if (cleanPath == '/orders/active' && method == 'GET') {
      return _getActiveOrders();
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'orders' &&
        pathSegments[2] == 'cancel' &&
        method == 'PUT') {
      return _cancelOrder(int.parse(pathSegments[1]));
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'orders' &&
        pathSegments[2] == 'status' &&
        method == 'PUT' &&
        body != null) {
      return _updateOrderStatus(int.parse(pathSegments[1]), body);
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'orders' &&
        pathSegments[2] == 'details' &&
        method == 'GET') {
      return _getOrderDetails(int.parse(pathSegments[1]));
    }

    if (cleanPath == '/admin/users' && method == 'GET') {
      return _getUsers();
    }

    if (cleanPath == '/admin/users' && method == 'POST' && body != null) {
      return _createUser(body);
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'admin' &&
        pathSegments[1] == 'users' &&
        method == 'PUT' &&
        body != null) {
      return _updateUser(int.parse(pathSegments[2]), body);
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'admin' &&
        pathSegments[1] == 'users' &&
        method == 'DELETE') {
      return _deleteUser(int.parse(pathSegments[2]));
    }

    throw Exception('Route not handled in OrderHandler: $method $cleanPath');
  }

  Future<dynamic> _createOrder(Map<String, dynamic> body) async {
    final tableId = body['table_id'] as int;
    final totalAmount = (body['total_amount'] as num).toDouble();
    final paymentMethod = body['payment_method'] as String;
    final items = body['items'] as List<dynamic>;

    final currentUserIdStr = await secureStorage.read(key: 'user_id');
    final customerId = int.tryParse(currentUserIdStr ?? '') ?? 1;

    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 24));
    final todayEnd = todayStart.add(const Duration(hours: 72));

    final activeRes = tableId == 0
        ? null
        : await Supabase.instance.client
            .from('reservations')
            .select()
            .eq('customer_id', customerId)
            .eq('table_id', tableId)
            .gte('reservation_date', todayStart.toIso8601String())
            .lt('reservation_date', todayEnd.toIso8601String())
            .in_('status', ['booked', 'confirmed', 'valid', 'checked_in'])
            .maybeSingle();

    bool isWalkIn = true;
    int? reservationId;
    if (activeRes != null) {
      isWalkIn = false;
      reservationId = activeRes['id'] as int;
    }

    for (final item in items) {
      final menuId = item['menu_id'] as int;
      final qty = item['qty'] as int;

      final menu = await Supabase.instance.client
          .from('menus')
          .select()
          .eq('id', menuId)
          .single();
      final stock = menu['stock'] as int;

      if (stock < qty) {
        throw Exception(
            'Stok menu "${menu['name']}" tidak mencukupi. Sisa stok: $stock.');
      }

      await Supabase.instance.client
          .from('menus')
          .update({'stock': stock - qty, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', menuId);
    }

    final newOrder = await Supabase.instance.client
        .from('orders')
        .insert({
          'customer_id': customerId,
          'table_id': tableId == 0 ? null : tableId,
          'is_walk_in': isWalkIn,
          'reservation_id': reservationId,
          'total_amount': totalAmount,
          'status': 'pending',
          'payment_method': paymentMethod,
          'staff_name': 'SISTEM',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final orderId = newOrder['id'] as int;

    for (final item in items) {
      await Supabase.instance.client.from('order_items').insert({
        'order_id': orderId,
        'menu_id': item['menu_id'] as int,
        'qty': item['qty'] as int,
        'subtotal': (item['subtotal'] as num).toDouble(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    String? snapToken;
    String? snapRedirectUrl;
    Map<String, dynamic> paymentDetails = {};

    if (paymentMethod != 'cash') {
      try {
        final credentials = _buildMidtransCredentials();
        if (paymentMethod == 'midtrans') {
          final result = await _createSnapTransaction(
              orderId, totalAmount, credentials['authString']!);
          snapToken = result['token'];
          snapRedirectUrl = result['redirect_url'];
        } else {
          paymentDetails = await _chargePayment(
              orderId, totalAmount, paymentMethod, credentials['authString']!);
        }
      } catch (_) {
        paymentDetails = _getFallbackPaymentDetails(paymentMethod, orderId);
      }
    }

    _notifyLaravel('/api/notify-order');

    return {
      'status': 201,
      'message': 'Order created successfully',
      'data': {
        'order': {
          'id': orderId,
          'customer_id': customerId,
          'table_id': tableId == 0 ? null : tableId,
          'total_amount': totalAmount,
          'status': 'pending',
          'payment_method': paymentMethod,
          'staff_name': 'SISTEM',
          'created_at': newOrder['created_at'],
        },
        'snap_token': snapToken ?? '',
        'snap_redirect_url': snapRedirectUrl ?? '',
        'payment_details': paymentDetails,
      }
    };
  }

  Future<dynamic> _getOrdersByTable(int tableId) async {
    final orders = await Supabase.instance.client
        .from('orders')
        .select('*, order_items(*, menus(*))')
        .eq('table_id', tableId)
        .is_('deleted_at', null);

    return {
      'status': 200,
      'message': 'Success fetching orders for table $tableId',
      'data': orders.map((o) => {...o, 'items': _mapItems(o)}).toList(),
    };
  }

  Future<dynamic> _getOrderHistory() async {
    final currentUserIdStr = await secureStorage.read(key: 'user_id');
    final customerId = int.tryParse(currentUserIdStr ?? '') ?? 1;

    final orders = await Supabase.instance.client
        .from('orders')
        .select('*, users(*), order_items(*, menus(*))')
        .eq('customer_id', customerId)
        .is_('deleted_at', null)
        .order('created_at', ascending: false);

    return {
      'status': 200,
      'message': 'Success',
      'data': orders
          .map((o) => {...o, 'customer': o['users'], 'items': _mapItems(o)})
          .toList(),
    };
  }

  Future<dynamic> _getActiveOrders() async {
    final orders = await Supabase.instance.client
        .from('orders')
        .select('*, order_items(*, menus(*))')
        .in_('status', ['pending', 'processing', 'preparing', 'ready'])
        .is_('deleted_at', null)
        .order('created_at', ascending: true);

    return {
      'status': 200,
      'message': 'Success',
      'data': orders.map((o) => {...o, 'items': _mapItems(o)}).toList(),
    };
  }

  Future<dynamic> _cancelOrder(int orderId) async {
    final nowStr = DateTime.now().toIso8601String();

    final order = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();
    if (order['status'] != 'pending') {
      throw Exception('Pesanan tidak dapat dibatalkan karena sedang diproses.');
    }

    final updatedOrder = await Supabase.instance.client
        .from('orders')
        .update({'status': 'cancelled', 'updated_at': nowStr})
        .eq('id', orderId)
        .select()
        .single();

    await _restoreStock(orderId, nowStr);

    return {
      'status': 200,
      'message': 'Order cancelled successfully',
      'data': updatedOrder
    };
  }

  Future<dynamic> _updateOrderStatus(
      int orderId, Map<String, dynamic> body) async {
    final status = body['status'] as String;
    final nowStr = DateTime.now().toIso8601String();
    final currentUsername =
        await secureStorage.read(key: 'username') ?? 'BARISTA';

    final updatedOrder = await Supabase.instance.client
        .from('orders')
        .update({
          'status': status,
          'staff_name': currentUsername,
          'updated_at': nowStr,
        })
        .eq('id', orderId)
        .select()
        .single();

    if (status == 'cancelled') {
      await _restoreStock(orderId, nowStr);
    }

    return {
      'status': 200,
      'message': 'Order status updated',
      'data': updatedOrder
    };
  }

  Future<dynamic> _getOrderDetails(int orderId) async {
    try {
      final order = await Supabase.instance.client
          .from('orders')
          .select('*, users(*), order_items(*, menus(*))')
          .eq('id', orderId)
          .single();

      String status = order['status'] as String;
      String paymentMethod = order['payment_method'] as String;
      Map<String, dynamic> paymentDetails = {};

      if (paymentMethod != 'cash' && status == 'pending') {
        try {
          final credentials = _buildMidtransCredentials();
          final result = await _checkMidtransStatus(
              orderId, credentials['authString']!);

          final txStatus = result['transaction_status'] as String?;
          final paymentType = result['payment_type'] as String?;
          final vaNumbers = result['va_numbers'] as List?;

          if (txStatus == 'settlement' ||
              txStatus == 'capture' ||
              txStatus == 'success') {
            status = 'processing';
            paymentMethod = vaNumbers != null && vaNumbers.isNotEmpty
                ? (vaNumbers[0]['bank'] as String).toUpperCase()
                : paymentType != null
                    ? paymentType.toUpperCase().replaceAll('_', ' ')
                    : 'MIDTRANS';

            await Supabase.instance.client
                .from('orders')
                .update({
                  'status': status,
                  'payment_method': paymentMethod,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', orderId);
          } else if (txStatus == 'cancel' ||
              txStatus == 'deny' ||
              txStatus == 'expire') {
            status = 'cancelled';
            await Supabase.instance.client
                .from('orders')
                .update({
                  'status': status,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', orderId);

            await _restoreStock(orderId, DateTime.now().toIso8601String());
          } else {
            paymentDetails = _extractPaymentDetails(result);
          }
        } catch (_) {
          paymentDetails =
              _getFallbackPaymentDetails(paymentMethod, orderId);
        }
      }

      return {
        'status': 200,
        'message': 'Success fetching details for order $orderId',
        'data': {
          ...order,
          'status': status,
          'payment_method': paymentMethod,
          'customer': order['users'],
          'items': _mapItems(order),
          'payment_details': paymentDetails,
        }
      };
    } catch (e, stack) {
      debugPrint('Error fetching order details for order $orderId: $e\n$stack');
      rethrow;
    }
  }

  Future<dynamic> _getUsers() async {
    final users = await Supabase.instance.client
        .from('users')
        .select()
        .is_('deleted_at', null)
        .order('id', ascending: true);
    return {'status': 200, 'message': 'Success', 'data': users};
  }

  Future<dynamic> _createUser(Map<String, dynamic> body) async {
    final username = body['username'] as String;
    final email = body['email'] as String;

    final existing = await Supabase.instance.client
        .from('users')
        .select()
        .or('username.eq.$username,email.eq.$email')
        .is_('deleted_at', null)
        .maybeSingle();

    if (existing != null) {
      throw Exception(existing['username'] == username
          ? 'Username "$username" sudah digunakan.'
          : 'Email "$email" sudah digunakan.');
    }

    final passwordHash =
        BCrypt.hashpw(body['password'] as String, BCrypt.gensalt());
    final user = await Supabase.instance.client
        .from('users')
        .insert({
          'name': body['name'] as String,
          'username': username,
          'email': email,
          'role': body['role'] as String,
          'password_hash': passwordHash,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return {'status': 201, 'message': 'User created', 'data': user};
  }

  Future<dynamic> _updateUser(int id, Map<String, dynamic> body) async {
    final username = body['username'] as String;
    final email = body['email'] as String;

    final existing = await Supabase.instance.client
        .from('users')
        .select()
        .or('username.eq.$username,email.eq.$email')
        .neq('id', id)
        .is_('deleted_at', null)
        .maybeSingle();

    if (existing != null) {
      throw Exception(existing['username'] == username
          ? 'Username "$username" sudah digunakan oleh pengguna lain.'
          : 'Email "$email" sudah digunakan oleh pengguna lain.');
    }

    final updateData = {
      'name': body['name'] as String,
      'username': username,
      'email': email,
      'role': body['role'] as String,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (body['password'] != null && (body['password'] as String).isNotEmpty) {
      updateData['password_hash'] =
          BCrypt.hashpw(body['password'] as String, BCrypt.gensalt());
    }

    final user = await Supabase.instance.client
        .from('users')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return {'status': 200, 'message': 'User updated', 'data': user};
  }

  Future<dynamic> _deleteUser(int id) async {
    await Supabase.instance.client
        .from('users')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    return {'status': 200, 'message': 'User deleted'};
  }

  Future<void> _restoreStock(int orderId, String nowStr) async {
    final items = await Supabase.instance.client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    for (final item in items) {
      final menuId = item['menu_id'] as int;
      final qty = item['qty'] as int;

      final menu = await Supabase.instance.client
          .from('menus')
          .select('stock')
          .eq('id', menuId)
          .single();

      await Supabase.instance.client
          .from('menus')
          .update({'stock': (menu['stock'] as int) + qty, 'updated_at': nowStr})
          .eq('id', menuId);
    }
  }

  List<Map<String, dynamic>> _mapItems(Map<String, dynamic> order) {
    return (order['order_items'] as List? ?? [])
        .map<Map<String, dynamic>>((item) => {
              'id': item['id'],
              'menu_id': item['menu_id'],
              'qty': item['qty'],
              'subtotal': item['subtotal'],
              'menu': item['menus'],
            })
        .toList();
  }

  Map<String, String> _buildMidtransCredentials() {
    const serverKey = 'Mid-server-ZUzaCDD3haOd0PZWqHSAQO6i';
    final authString = base64Encode(utf8.encode('$serverKey:'));
    return {'serverKey': serverKey, 'authString': authString};
  }

  Future<Map<String, dynamic>> _createSnapTransaction(
      int orderId, double totalAmount, String authString) async {
    final resp = await http.post(
      Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic $authString',
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': 'JK-ORDER-$orderId',
          'gross_amount': totalAmount.toInt(),
        },
        'credit_card': {'secure': true},
        'callbacks': {
          'finish': 'jabatkopi://payment/finish?order_id=JK-ORDER-$orderId',
        }
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> _chargePayment(
      int orderId, double totalAmount, String paymentMethod, String authString) async {
    String chargeUrl = 'https://api.sandbox.midtrans.com/v2/charge';
    if (kIsWeb) {
      chargeUrl = 'https://corsproxy.io/?$chargeUrl';
    }

    final chargeBody = _buildChargeBody(orderId, totalAmount, paymentMethod);

    final resp = await http.post(
      Uri.parse(chargeUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic $authString',
      },
      body: jsonEncode(chargeBody),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return _extractPaymentDetails(
          jsonDecode(resp.body) as Map<String, dynamic>);
    }
    return _getFallbackPaymentDetails(paymentMethod, orderId);
  }

  Future<Map<String, dynamic>> _checkMidtransStatus(
      int orderId, String authString) async {
    String statusUrl =
        'https://api.sandbox.midtrans.com/v2/JK-ORDER-$orderId/status';
    if (kIsWeb) {
      statusUrl = 'https://corsproxy.io/?$statusUrl';
    }

    final resp = await http.get(
      Uri.parse(statusUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $authString',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return {};
  }

  Map<String, dynamic> _buildChargeBody(
      int orderId, double totalAmount, String paymentMethod) {
    final body = <String, dynamic>{
      'transaction_details': {
        'order_id': 'JK-ORDER-$orderId',
        'gross_amount': totalAmount.toInt(),
      }
    };

    switch (paymentMethod) {
      case 'bank_transfer_bca':
        body['payment_type'] = 'bank_transfer';
        body['bank_transfer'] = {'bank': 'bca'};
        break;
      case 'bank_transfer_bni':
        body['payment_type'] = 'bank_transfer';
        body['bank_transfer'] = {'bank': 'bni'};
        break;
      case 'bank_transfer_bri':
        body['payment_type'] = 'bank_transfer';
        body['bank_transfer'] = {'bank': 'bri'};
        break;
      case 'bank_transfer_permata':
        body['payment_type'] = 'bank_transfer';
        body['bank_transfer'] = {'bank': 'permata'};
        break;
      case 'bank_transfer_mandiri':
        body['payment_type'] = 'echannel';
        body['echannel'] = {
          'bill_info1': 'Payment:',
          'bill_info2': 'Jabat Kopi Order #$orderId',
        };
        break;
      case 'cstore_alfamart':
        body['payment_type'] = 'cstore';
        body['cstore'] = {
          'store': 'alfamart',
          'message': 'Jabat Kopi Order #$orderId'
        };
        break;
      case 'cstore_indomaret':
        body['payment_type'] = 'cstore';
        body['cstore'] = {
          'store': 'indomaret',
          'message': 'Jabat Kopi Order #$orderId'
        };
        break;
      case 'gopay':
        body['payment_type'] = 'gopay';
        body['gopay'] = {
          'enable_callback': true,
          'callback_url': 'jabatkopi://payment/finish',
        };
        break;
      case 'qris':
        body['payment_type'] = 'qris';
        body['qris'] = {'acquirer': 'gopay'};
        break;
      case 'shopeepay':
        body['payment_type'] = 'shopeepay';
        body['shopeepay'] = {'callback_url': 'jabatkopi://payment/finish'};
        break;
    }

    return body;
  }

  Map<String, dynamic> _extractPaymentDetails(Map<String, dynamic> res) {
    final details = <String, dynamic>{};

    final vaNumbers = res['va_numbers'] as List?;
    if (vaNumbers != null && vaNumbers.isNotEmpty) {
      details['va_number'] = vaNumbers[0]['va_number'];
      details['bank'] = vaNumbers[0]['bank'];
    } else if (res['permata_va_number'] != null) {
      details['va_number'] = res['permata_va_number'];
      details['bank'] = 'permata';
    }

    if (res['bill_key'] != null) {
      details['bill_key'] = res['bill_key'];
      details['biller_code'] = res['biller_code'];
    }

    if (res['payment_code'] != null) {
      details['payment_code'] = res['payment_code'];
    }

    if (res['actions'] != null) {
      final actions = res['actions'] as List;
      final qrAction = actions.firstWhere(
          (a) => a['name'] == 'generate-qr-code',
          orElse: () => null);
      if (qrAction != null) details['qr_url'] = qrAction['url'];

      final dlAction = actions.firstWhere(
          (a) => a['name'] == 'deeplink-redirect',
          orElse: () => null);
      if (dlAction != null) details['deeplink_url'] = dlAction['url'];
    }

    return details;
  }

  Map<String, dynamic> _getFallbackPaymentDetails(
      String method, int orderId) {
    final pad = orderId.toString().padLeft(3, '0');
    switch (method) {
      case 'bank_transfer_bca':
        return {'va_number': '11171089999$pad', 'bank': 'bca'};
      case 'bank_transfer_bni':
        return {'va_number': '22271089999$pad', 'bank': 'bni'};
      case 'bank_transfer_bri':
        return {'va_number': '88871089999$pad', 'bank': 'bri'};
      case 'bank_transfer_permata':
        return {'va_number': '77771089999$pad', 'bank': 'permata'};
      case 'bank_transfer_mandiri':
        return {
          'bill_key': '99991$pad',
          'biller_code': '89898',
          'bank': 'mandiri',
        };
      case 'cstore_alfamart':
        return {'payment_code': '12345089999$pad'};
      case 'cstore_indomaret':
        return {'payment_code': '54321089999$pad'};
      case 'qris':
        return {
          'qr_url':
              'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=JK-ORDER-$orderId'
        };
      case 'gopay':
        return {
          'qr_url':
              'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=JK-ORDER-$orderId-GOPAY',
          'deeplink_url': 'https://gopay.co.id/mock-pay?order=$orderId',
        };
      case 'shopeepay':
        return {
          'deeplink_url':
              'https://deeplink.shopeepay.co.id/mock-pay?order=$orderId'
        };
      default:
        return {};
    }
  }

  void _notifyLaravel(String path) async {
    if (AppConfig.laravelBaseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('${AppConfig.laravelBaseUrl}$path');
        await http.post(uri).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    final hosts = ['10.0.2.2:8000', '127.0.0.1:8000', 'localhost:8000'];
    for (final host in hosts) {
      try {
        final localUri = Uri.parse('http://$host$path');
        if (localUri.toString() != AppConfig.laravelBaseUrl) {
          await http.post(localUri).timeout(const Duration(seconds: 2));
        }
      } catch (_) {}
    }
  }
}
