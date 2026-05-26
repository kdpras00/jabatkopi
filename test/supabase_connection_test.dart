// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Check Supabase connection and users table', () async {
    print('Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://tmudxkcovejdrweucpjl.supabase.co',
      anonKey: 'sb_publishable_cG85tYuK5oYYN-0ZxUqiMg_wlCvJvKO',
    );
    
    print('Supabase initialized. querying users...');
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select();
      
      print('Query successful! Row count: ${response.length}');
      print('Users inside the table:');
      for (var user in response) {
        print('- ID: ${user['id']}, Username: ${user['username']}, Email: ${user['email']}, Role: ${user['role']}');
      }
    } catch (e) {
      print('Error querying users table: $e');
    }
  });
}
