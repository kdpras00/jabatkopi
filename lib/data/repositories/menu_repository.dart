import 'package:jabatkopi/core/network/api_client.dart';
import '../models/menu_model.dart';

class MenuRepository {
  final ApiClient apiClient;

  MenuRepository({required this.apiClient});

  Future<List<MenuModel>> getMenus() async {
    try {
      final response = await apiClient.get('/menus');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menus: $e');
    }
  }
}
