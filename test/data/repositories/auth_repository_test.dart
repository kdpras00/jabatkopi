import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:jabatkopi/data/repositories/auth_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late AuthRepository authRepository;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    authRepository = AuthRepository(client: mockHttpClient);
  });

  group('AuthRepository', () {
    test('login returns a model on success', () async {
      // Arrange
      const username = 'testuser';
      const password = 'password123';
      const responseBody = '{"token": "fake_jwt_token", "role": "customer"}';
      
      when(() => mockHttpClient.post(
            Uri.parse('https://api.jabatkopi.com/login'),
            body: {'username': username, 'password': password},
          )).thenAnswer((_) async => http.Response(responseBody, 200));

      // Act
      final result = await authRepository.login(username, password);

      // Assert
      expect(result.token, 'fake_jwt_token');
      expect(result.role, 'customer');
    });

    test('login throws an exception on failure', () async {
      // Arrange
      const username = 'testuser';
      const password = 'wrongpassword';
      
      when(() => mockHttpClient.post(
            Uri.parse('https://api.jabatkopi.com/login'),
            body: {'username': username, 'password': password},
          )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      // Act & Assert
      expect(
        () => authRepository.login(username, password),
        throwsException,
      );
    });
  });
}
