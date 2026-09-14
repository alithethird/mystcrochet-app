import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/models/auth_state.dart';
import 'package:crochet_charts/models/user_model.dart';
import 'package:crochet_charts/providers/auth_provider.dart';
import 'package:crochet_charts/services/auth_service.dart';
import 'package:crochet_charts/widgets/auth_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthDialog Widget Tests', () {
    testWidgets('renders login form by default with tabs and inputs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AuthDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('auth_login_username')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_login_password')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_login_submit')), findsOneWidget);
    });

    testWidgets('switches to register tab and shows registration inputs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AuthDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap register tab
      final registerTab = find.text('Kayıt Ol');
      expect(registerTab, findsOneWidget);
      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('auth_register_username')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_register_email')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_register_password')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_register_submit')), findsOneWidget);
    });

    testWidgets('renders user profile when already authenticated', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockUser = UserModel(
        id: 'usr_5',
        username: 'crochet_lover',
        email: 'lover@crochet.com',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final authNotifier = AuthNotifier(AuthService());
      authNotifier.state = AuthState(
        user: mockUser,
        token: 'sample-token',
        serverUrl: 'http://custom-host:8080',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => authNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('crochet_lover'), findsOneWidget);
      expect(find.text('lover@crochet.com'), findsOneWidget);
      expect(find.text('http://custom-host:8080'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_logout_button')), findsOneWidget);

      // Tap logout button
      await tester.tap(find.byKey(const ValueKey('auth_logout_button')));
      await tester.pumpAndSettle();

      expect(authNotifier.state.isAuthenticated, isFalse);
    });

    testWidgets('login success closes dialog or sets state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'logged-in-jwt',
            'user': {
              'id': 'usr_1',
              'username': 'ali',
              'email': 'ali@example.com',
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('auth_login_username')), 'ali');
      await tester.enterText(find.byKey(const ValueKey('auth_login_password')), 'secret123');
      await tester.tap(find.byKey(const ValueKey('auth_login_submit')));
      await tester.pumpAndSettle();

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, equals('ali'));
    });
  });
}
