import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jabatkopi/core/network/api_client.dart';
import 'package:jabatkopi/data/repositories/auth_repository.dart';

void main() {
  late AuthRepository authRepository;
  late ApiClient apiClient;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    apiClient = ApiClient();
    authRepository = AuthRepository(apiClient: apiClient);
  });

  group('AuthRepository Integration Test', () {
    test('login returns AuthModel on success with real local backend', () async {
      // NOTE: Ensure Go backend is running on localhost:8080
      // We are testing with the seeded admin account
      const username = 'admin';
      const password = 'admin123';
      
      final result = await authRepository.login(username, password);

      expect(result.token, isNotEmpty);
      expect(result.role, 'admin');
    });

    test('login throws an exception on invalid credentials', () async {
      const username = 'admin';
      const password = 'wrongpassword';
      
      expect(
        () => authRepository.login(username, password),
        throwsException,
      );
    });
  });
}
