import 'package:supabase_flutter/supabase_flutter.dart';

class MenuHandler {
  Future<dynamic> handle(String method, String cleanPath, List<String> pathSegments, Map<String, dynamic>? body) async {
    if (cleanPath == '/menus' && method == 'GET') {
      final response = await Supabase.instance.client
          .from('menus')
          .select()
          .is_('deleted_at', null)
          .order('name', ascending: true);

      return {
        'status': 200,
        'message': 'Success',
        'data': response,
      };
    }

    if (cleanPath == '/admin/menus' && method == 'POST' && body != null) {
      final menu = await Supabase.instance.client.from('menus').insert({
        'name': body['name'] as String,
        'category': body['category'] as String,
        'price': (body['price'] as num).toDouble(),
        'image_url': body['image_url'] as String? ?? '',
        'is_available': body['is_available'] as bool? ?? true,
        'stock': body['stock'] as int? ?? 50,
        'description': body['description'] as String? ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return {'status': 201, 'message': 'Menu created', 'data': menu};
    }

    if (pathSegments.length == 3 && pathSegments[0] == 'admin' && pathSegments[1] == 'menus' && method == 'PUT' && body != null) {
      final id = int.parse(pathSegments[2]);
      final menu = await Supabase.instance.client
          .from('menus')
          .update({
            'name': body['name'] as String,
            'category': body['category'] as String,
            'price': (body['price'] as num).toDouble(),
            'image_url': body['image_url'] as String? ?? '',
            'is_available': body['is_available'] as bool? ?? true,
            'stock': body['stock'] as int? ?? 50,
            'description': body['description'] as String? ?? '',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return {'status': 200, 'message': 'Menu updated', 'data': menu};
    }

    if (pathSegments.length == 3 && pathSegments[0] == 'admin' && pathSegments[1] == 'menus' && method == 'DELETE') {
      final id = int.parse(pathSegments[2]);
      await Supabase.instance.client
          .from('menus')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);

      return {'status': 200, 'message': 'Menu deleted'};
    }

    throw Exception('Route not handled in MenuHandler: $method $cleanPath');
  }
}
