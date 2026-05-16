import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jabatkopi/core/network/api_client.dart';
import 'package:jabatkopi/data/repositories/menu_repository.dart';

void main() {
  late MenuRepository menuRepository;
  late ApiClient apiClient;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    apiClient = ApiClient();
    menuRepository = MenuRepository(apiClient: apiClient);
  });

  group('Menu Integration Test', () {
    test('getMenus returns list of menus from real backend', () async {
      final menus = await menuRepository.getMenus();
      // Since it's a mock DB in handler, it currently returns an empty array []
      // Or if seeded, might return items. We just assert it doesn't throw.
      expect(menus, isA<List>());
    });
  });
}
