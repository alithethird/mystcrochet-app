import 'user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  final String serverUrl;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
    this.serverUrl = 'http://localhost:8080',
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty && user != null;

  AuthState copyWith({
    UserModel? user,
    bool clearUser = false,
    String? token,
    bool clearToken = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? serverUrl,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}
