import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/providers/auth_provider.dart';
import 'package:crochet_charts/services/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    const baseUrl = 'http://localhost:8080';

    test('login success returns token and UserModel', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/auth/login'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], equals('testuser'));
        expect(body['password'], equals('secret123'));

        return http.Response(
          jsonEncode({
            'token': 'jwt-test-token',
            'user': {
              'id': 'usr_1',
              'username': 'testuser',
              'email': 'test@example.com',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);
      final result = await authService.login(
        baseUrl: baseUrl,
        username: 'testuser',
        password: 'secret123',
      );

      expect(result.token, equals('jwt-test-token'));
      expect(result.user.username, equals('testuser'));
      expect(result.user.email, equals('test@example.com'));
      expect(result.user.id, equals('usr_1'));
    });

    test('login failure throws AuthException with error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Geçersiz kullanıcı adı veya şifre'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);
      expect(
        () => authService.login(
          baseUrl: baseUrl,
          username: 'testuser',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Geçersiz kullanıcı adı veya şifre')),
      );
    });

    test('register success returns token and UserModel', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/auth/register'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], equals('newuser'));
        expect(body['email'], equals('new@example.com'));

        return http.Response(
          jsonEncode({
            'token': 'jwt-reg-token',
            'user': {
              'id': 'usr_2',
              'username': 'newuser',
              'email': 'new@example.com',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);
      final result = await authService.register(
        baseUrl: baseUrl,
        username: 'newuser',
        email: 'new@example.com',
        password: 'Password123!',
      );

      expect(result.token, equals('jwt-reg-token'));
      expect(result.user.username, equals('newuser'));
    });

    test('register failure throws AuthException on conflict', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Kullanıcı adı zaten kullanımda'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);
      expect(
        () => authService.register(
          baseUrl: baseUrl,
          username: 'existing',
          email: 'test@example.com',
          password: 'pass',
        ),
        throwsA(isA<AuthException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });

    test('getProfile sends Authorization header and returns UserModel', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/auth/me'));
        expect(request.headers['Authorization'], equals('Bearer test-token-123'));

        return http.Response(
          jsonEncode({
            'id': 'usr_10',
            'username': 'profileuser',
            'email': 'profile@example.com',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);
      final user = await authService.getProfile(
        baseUrl: baseUrl,
        token: 'test-token-123',
      );

      expect(user.username, equals('profileuser'));
      expect(user.id, equals('usr_10'));
    });

    test('handles network exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final authService = AuthService(client: mockClient);
      expect(
        () => authService.login(
          baseUrl: baseUrl,
          username: 'user',
          password: 'pw',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Sunucuya bağlanılamadı'))),
      );
    });
  });

  group('AuthNotifier Tests', () {
    test('login updates state and saves token to SharedPreferences', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'saved-token',
            'user': {
              'id': 'usr_1',
              'username': 'loggeduser',
              'email': 'u@u.com',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: mockClient);
      final notifier = AuthNotifier(service);

      expect(notifier.state.isAuthenticated, isFalse);

      final ok = await notifier.login(username: 'loggeduser', password: 'password');
      expect(ok, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals('loggeduser'));
      expect(notifier.state.token, equals('saved-token'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), equals('saved-token'));
    });

    test('logout clears user state and removes token from SharedPreferences', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'saved-token',
            'user': {
              'id': 'usr_1',
              'username': 'loggeduser',
              'email': 'u@u.com',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: mockClient);
      final notifier = AuthNotifier(service);

      await notifier.login(username: 'loggeduser', password: 'password');
      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.logout();
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);
      expect(notifier.state.token, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    test('setServerUrl updates state and persists in SharedPreferences', () async {
      final notifier = AuthNotifier(AuthService());
      await notifier.setServerUrl('http://192.168.1.100:8080');

      expect(notifier.state.serverUrl, equals('http://192.168.1.100:8080'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_server_url'), equals('http://192.168.1.100:8080'));
    });

    test('loadSavedSession restores session if token valid', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'valid-saved-token',
        'auth_server_url': 'http://custom-server:8080',
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/me') {
          return http.Response(
            jsonEncode({
              'id': 'usr_42',
              'username': 'restoreduser',
              'email': 'restored@example.com',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = AuthService(client: mockClient);
      final notifier = AuthNotifier(service);
      await notifier.loadSavedSession();

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals('restoreduser'));
      expect(notifier.state.serverUrl, equals('http://custom-server:8080'));
    });

    test('loadSavedSession purges invalid token when getProfile fails', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired-token',
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Token expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: mockClient);
      final notifier = AuthNotifier(service);
      await notifier.loadSavedSession();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.token, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });
  });
}
