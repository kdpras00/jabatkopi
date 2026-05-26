import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class ReservationHandler {
  final FlutterSecureStorage secureStorage;

  ReservationHandler(this.secureStorage);

  Future<dynamic> handle(String method, String cleanPath,
      List<String> pathSegments, Map<String, dynamic>? body) async {
    if (cleanPath == '/reservations' && method == 'POST' && body != null) {
      final date = body['date'] as String;
      final timeVal = body['time'] as String;
      final guests = (body['guests'] as num).toInt();
      final notes = body['notes'] as String?;

      if (guests < 1 || guests > 6) {
        throw Exception('Jumlah tamu harus antara 1 dan 6 orang.');
      }

      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      final targetDateTime = DateTime.parse('$date $timeVal');
      final timeEnd = targetDateTime.add(const Duration(hours: 1));

      final activeReservations = await Supabase.instance.client
          .from('reservations')
          .select('id')
          .eq('customer_id', customerId)
          .in_('status', ['booked', 'confirmed', 'valid', 'pending']);

      if (activeReservations.length >= 2) {
        throw Exception(
            'Batas reservasi tercapai. Anda memiliki 2 reservasi aktif saat ini.');
      }

      final sameTimeBooking = await Supabase.instance.client
          .from('reservations')
          .select('id')
          .eq('customer_id', customerId)
          .eq('reservation_date', targetDateTime.toIso8601String())
          .in_('status', ['booked', 'confirmed', 'valid', 'pending', 'checked_in'])
          .maybeSingle();

      if (sameTimeBooking != null) {
        throw Exception(
            'Anda sudah memiliki reservasi di waktu yang sama. Pilih waktu lain.');
      }

      final barcodeStr =
          'QR_CODE_${customerId}_${DateTime.now().microsecondsSinceEpoch}';

      final newReservation = await Supabase.instance.client
          .from('reservations')
          .insert({
            'table_id': null,
            'customer_id': customerId,
            'reservation_date': targetDateTime.toIso8601String(),
            'time_start': targetDateTime.toIso8601String(),
            'time_end': timeEnd.toIso8601String(),
            'pax': guests,
            'barcode': barcodeStr,
            'status': 'booked',
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _notifyLaravel('/api/notify-reservation');

      return {
        'status': 200,
        'message': 'Success',
        'data': {
          'reservation_id': newReservation['id'],
          'table_id': newReservation['table_id'],
          'barcode': newReservation['barcode'],
          'qr_code': newReservation['barcode'],
          'booking_id': 'JK-RES-${newReservation['id']}',
          'reservation_date': newReservation['reservation_date'],
          'time_start': newReservation['time_start'],
          'time_end': newReservation['time_end'],
          'pax': newReservation['pax'],
          'status': newReservation['status'],
        }
      };
    }

    if (cleanPath == '/reservations/active' && method == 'GET') {
      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 24));
      final todayEnd = todayStart.add(const Duration(hours: 72));

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select('*, tables(*)')
          .eq('customer_id', customerId)
          .gte('reservation_date', todayStart.toIso8601String())
          .lt('reservation_date', todayEnd.toIso8601String())
          .in_('status', ['booked', 'confirmed', 'valid', 'checked_in'])
          .order('reservation_date', ascending: true);

      if (reservations.isEmpty) {
        return {'status': 200, 'message': 'No active reservation', 'data': null};
      }

      final activeRes = reservations.firstWhere(
        (r) => r['status'] == 'checked_in',
        orElse: () => reservations.first,
      );

      final table = activeRes['tables'] as Map?;
      final tableRef = table != null && table['qr_code_ref'] != null
          ? table['qr_code_ref']
          : 'Meja ${activeRes['table_id']}';

      return {
        'status': 200,
        'message': 'Success',
        'data': {
          'reservation_id': activeRes['id'],
          'table_id': activeRes['table_id'],
          'table_ref': tableRef,
          'reservation_date': activeRes['reservation_date'],
          'time_start': activeRes['time_start'],
          'pax': activeRes['pax'],
          'status': activeRes['status'],
          'barcode': activeRes['barcode'],
        }
      };
    }

    if (cleanPath == '/reservations/history' && method == 'GET') {
      final currentUserIdStr = await secureStorage.read(key: 'user_id');
      final customerId = int.tryParse(currentUserIdStr ?? '') ?? 0;

      final reservations = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('customer_id', customerId)
          .order('reservation_date', ascending: false);

      final data = reservations
          .map((res) => {
                'id': res['id'],
                'booking_id': 'JK-RES-${res['id']}',
                'table_id': res['table_id'],
                'pax': res['pax'],
                'reservation_date': res['reservation_date'],
                'status': res['status'],
              })
          .toList();

      return {'status': 200, 'message': 'Success', 'data': data};
    }

    if (cleanPath == '/admin/reservations' && method == 'GET') {
      final reservations = await Supabase.instance.client
          .from('reservations')
          .select('*, users(*), tables(*)')
          .order('reservation_date', ascending: true);

      final data = reservations.map((res) {
        final customer = res['users'] as Map?;
        return {
          'id': res['id'],
          'booking_id': 'JK-RES-${res['id']}',
          'customer_name': customer != null ? customer['name'] : 'Pelanggan',
          'table_id': res['table_id'],
          'pax': res['pax'],
          'reservation_date': res['reservation_date'],
          'status': res['status'],
        };
      }).toList();

      return {'status': 200, 'message': 'Success', 'data': data};
    }

    if (pathSegments.length == 4 &&
        pathSegments[0] == 'admin' &&
        pathSegments[1] == 'reservations' &&
        pathSegments[3] == 'arrive' &&
        method == 'PUT') {
      final id = int.parse(pathSegments[2]);
      final nowStr = DateTime.now().toIso8601String();

      final updated = await Supabase.instance.client
          .from('reservations')
          .update({
            'status': 'checked_in',
            'checked_in_at': nowStr,
            'updated_at': nowStr,
          })
          .eq('id', id)
          .select()
          .single();

      final tableId = updated['table_id'] as int?;
      if (tableId != null && tableId > 0) {
        await Supabase.instance.client
            .from('tables')
            .update({'status': 'occupied', 'updated_at': nowStr})
            .eq('id', tableId);
      }

      return {'status': 200, 'message': 'Success', 'data': updated};
    }

    if (pathSegments.length == 4 &&
        pathSegments[0] == 'admin' &&
        pathSegments[1] == 'reservations' &&
        pathSegments[3] == 'complete' &&
        method == 'PUT') {
      final id = int.parse(pathSegments[2]);
      final nowStr = DateTime.now().toIso8601String();

      final updated = await Supabase.instance.client
          .from('reservations')
          .update({
            'status': 'completed',
            'completed_at': nowStr,
            'updated_at': nowStr,
          })
          .eq('id', id)
          .select()
          .single();

      final tableId = updated['table_id'] as int?;
      if (tableId != null && tableId > 0) {
        await Supabase.instance.client
            .from('tables')
            .update({'status': 'available', 'updated_at': nowStr})
            .eq('id', tableId);
      }

      return {'status': 200, 'message': 'Success', 'data': updated};
    }

    if (pathSegments.length == 3 &&
        pathSegments[0] == 'reservations' &&
        pathSegments[2] == 'cancel' &&
        method == 'PUT') {
      final id = int.parse(pathSegments[1]);
      final nowStr = DateTime.now().toIso8601String();

      final updated = await Supabase.instance.client
          .from('reservations')
          .update({'status': 'cancelled', 'updated_at': nowStr})
          .eq('id', id)
          .select()
          .single();

      final tableId = updated['table_id'] as int?;
      if (tableId != null && tableId > 0) {
        await Supabase.instance.client
            .from('tables')
            .update({'status': 'available', 'updated_at': nowStr})
            .eq('id', tableId);
      }

      return {'status': 200, 'message': 'Success', 'data': updated};
    }

    throw Exception(
        'Route not handled in ReservationHandler: $method $cleanPath');
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
