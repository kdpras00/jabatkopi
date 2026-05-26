import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TableHandler {
  final FlutterSecureStorage secureStorage;

  TableHandler(this.secureStorage);

  Future<dynamic> handle(
    String method,
    String cleanPath,
    List<String> pathSegments,
    Map<String, String> params,
    Map<String, dynamic>? body,
  ) async {
    if ((cleanPath == '/admin/tables' || cleanPath == '/tables') && method == 'GET') {
      final tables = await Supabase.instance.client.from('tables').select().is_('deleted_at', null).order('id', ascending: true);
      return {'status': 200, 'message': 'Success', 'data': tables};
    }

    if (cleanPath == '/admin/tables' && method == 'POST' && body != null) {
      final qrCodeRef = body['qr_code_ref'] as String;
      final capacity = body['capacity'] as int? ?? 4;

      final table = await Supabase.instance.client.from('tables').insert({
        'qr_code_ref': qrCodeRef,
        'capacity': capacity,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return {'status': 201, 'message': 'Table created', 'data': table};
    }

    if (pathSegments.length == 4 && pathSegments[0] == 'admin' && pathSegments[1] == 'tables' && pathSegments[3] == 'status' && method == 'PUT' && body != null) {
      final id = int.parse(pathSegments[2]);
      final status = body['status'] as String;

      final table = await Supabase.instance.client
          .from('tables')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return {'status': 200, 'message': 'Table status updated', 'data': table};
    }

    if (cleanPath == '/tables/status' && method == 'GET') {
      final dateStr = params['date'];
      final timeStr = params['time'];

      final tables = await Supabase.instance.client.from('tables').select().is_('deleted_at', null).order('id', ascending: true);

      if (dateStr == null || dateStr.isEmpty || timeStr == null || timeStr.isEmpty) {
        final data = tables.map((t) => {
          'id': t['id'],
          'qr_code_ref': t['qr_code_ref'],
          'capacity': t['capacity'],
          'status': t['status'],
          'display_status': t['status'],
        }).toList();
        return {'status': 200, 'data': data};
      }

      final targetTimeStr = '$dateStr $timeStr';
      final targetDateTime = DateTime.parse(targetTimeStr);

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('reservation_date', targetDateTime.toIso8601String())
          .in_('status', ['booked', 'confirmed', 'valid', 'pending', 'checked_in']);

      final reservedMap = <int, int>{};
      for (final res in reservations) {
        reservedMap[res['table_id'] as int] = res['customer_id'] as int;
      }

      final currentUserIdStr = await secureStorage.read(key: 'user_id');

      final data = tables.map((t) {
        final tableId = t['id'] as int;
        final resCustomerID = reservedMap[tableId];
        String displayStatus = 'available';
        bool isMine = false;

        if (t['status'] == 'occupied') {
          displayStatus = 'occupied';
        } else if (resCustomerID != null) {
          if (currentUserIdStr != null && resCustomerID.toString() == currentUserIdStr) {
            displayStatus = 'available';
            isMine = true;
          } else {
            displayStatus = 'reserved';
          }
        }

        return {
          'id': tableId,
          'qr_code_ref': t['qr_code_ref'],
          'capacity': t['capacity'],
          'status': t['status'],
          'display_status': displayStatus,
          'is_mine': isMine,
        };
      }).toList();

      return {'status': 200, 'message': 'Success', 'data': data};
    }

    if (cleanPath == '/tables/available' && method == 'GET') {
      final dateStr = params['date'] ?? '';
      final timeStr = params['time'] ?? '';

      final targetDateTime = DateTime.parse('$dateStr $timeStr');

      final allTables = await Supabase.instance.client
          .from('tables')
          .select()
          .eq('status', 'available')
          .is_('deleted_at', null);

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select('table_id')
          .eq('reservation_date', targetDateTime.toIso8601String())
          .in_('status', ['booked', 'confirmed', 'valid', 'pending', 'checked_in']);

      final reservedTableIds = reservations.map((r) => r['table_id'] as int).toSet();
      final availableTables = allTables.where((t) => !reservedTableIds.contains(t['id'] as int)).toList();

      return {
        'status': 200,
        'message': 'Success',
        'data': availableTables,
      };
    }

    throw Exception('Route not handled in TableHandler: $method $cleanPath');
  }
}
