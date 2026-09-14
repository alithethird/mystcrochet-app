import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';

const String _kAuthTokenKey = 'auth_token';
const String _kAuthServerUrlKey = 'auth_server_url';
const String _kDefaultServerUrl = 'http://localhost:8080';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(service);
  notifier.loadSavedSession();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Load persisted session and custom server URL from SharedPreferences
  Future<void> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_kAuthServerUrlKey) ?? _kDefaultServerUrl;
      final savedToken = prefs.getString(_kAuthTokenKey);

      state = state.copyWith(serverUrl: savedUrl);

      if (savedToken != null && savedToken.isNotEmpty) {
        state = state.copyWith(isLoading: true, clearError: true);
        try {
          final user = await _authService.getProfile(
            baseUrl: savedUrl,
            token: savedToken,
          );
          state = state.copyWith(
            token: savedToken,
            user: user,
            isLoading: false,
          );
        } catch (_) {
          // Token expired or invalid; clear stored token
          await prefs.remove(_kAuthTokenKey);
          state = state.copyWith(
            clearToken: true,
            clearUser: true,
            isLoading: false,
          );
        }
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Change backend server URL
  Future<void> setServerUrl(String url) async {
    final cleanUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuthServerUrlKey, cleanUrl);
    state = state.copyWith(serverUrl: cleanUrl);
  }

  /// Perform login and persist token
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(
        baseUrl: state.serverUrl,
        username: username,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuthTokenKey, result.token);

      state = state.copyWith(
        token: result.token,
        user: result.user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Perform registration and persist token
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.register(
        baseUrl: state.serverUrl,
        username: username,
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuthTokenKey, result.token);

      state = state.copyWith(
        token: result.token,
        user: result.user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out and clear stored session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAuthTokenKey);
    } catch (_) {}

    state = state.copyWith(
      clearToken: true,
      clearUser: true,
      clearError: true,
      isLoading: false,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}
