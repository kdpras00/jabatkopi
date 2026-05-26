import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthHandler {
  final FlutterSecureStorage secureStorage;

  AuthHandler(this.secureStorage);

  Future<dynamic> handle(
      String method, String cleanPath, Map<String, dynamic>? body) async {
    if (cleanPath == '/auth/login' && method == 'POST' && body != null) {
      final email = body['email'] as String;
      final password = body['password'] as String;

      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        throw Exception('Maaf, email tidak ditemukan.');
      }

      final passwordHash = response['password_hash'] as String?;
      if (passwordHash == null || !BCrypt.checkpw(password, passwordHash)) {
        throw Exception(
            'Maaf, email atau password salah. Silakan periksa kembali.');
      }

      final token =
          'session_${response['id']}_${DateTime.now().millisecondsSinceEpoch}';
      return {
        'status': 200,
        'message': 'Berhasil masuk!',
        'data': {
          'id': response['id'],
          'token': token,
          'role': response['role'] ?? 'customer',
          'username': response['username'] ?? 'User',
        }
      };
    }

    if (cleanPath == '/auth/register' && method == 'POST' && body != null) {
      final name = body['name'] as String;
      final username = body['username'] as String;
      final email = body['email'] as String;
      final password = body['password'] as String;

      final existing = await Supabase.instance.client
          .from('users')
          .select()
          .or('username.eq.$username,email.eq.$email')
          .maybeSingle();

      if (existing != null) {
        throw Exception(
            'Username atau Email sudah terdaftar. Gunakan yang lain.');
      }

      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());
      await Supabase.instance.client.from('users').insert({
        'name': name,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'role': 'customer',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'status': 201,
        'message': 'Pendaftaran berhasil! Silakan masuk.',
      };
    }

    if (cleanPath == '/profile' && method == 'GET') {
      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      final user = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', customerId)
          .single();

      return {
        'status': 200,
        'data': {
          'id': user['id'],
          'name': user['name'] ?? '',
          'username': user['username'] ?? '',
          'email': user['email'] ?? '',
          'image_url': user['image_url'] ?? '',
          'role': user['role'] ?? 'customer',
        }
      };
    }

    if (cleanPath == '/profile' && method == 'PUT' && body != null) {
      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      await Supabase.instance.client
          .from('users')
          .update({
            'name': body['name'],
            'username': body['username'],
            'email': body['email'],
            'image_url': body['image_url'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      return {
        'status': 200,
        'message': 'Profil berhasil diperbarui!',
      };
    }

    if (cleanPath == '/profile/password' && method == 'PUT' && body != null) {
      final oldPassword = body['old_password'] as String;
      final newPassword = body['new_password'] as String;

      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      final user = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', customerId)
          .single();
      final passwordHash = user['password_hash'] as String?;

      if (passwordHash == null || !BCrypt.checkpw(oldPassword, passwordHash)) {
        throw Exception('Password lama Anda tidak sesuai.');
      }

      final newPasswordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await Supabase.instance.client
          .from('users')
          .update({
            'password_hash': newPasswordHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      return {
        'status': 200,
        'message': 'Password berhasil diperbarui!',
      };
    }

    throw Exception('Route not handled in AuthHandler: $method $cleanPath');
  }
}
