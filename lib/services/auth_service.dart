import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String baseUrl, String path) {
    var base = baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse('$base$path');
  }

  /// Authenticate an existing user with username and password
  Future<({String token, UserModel user})> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final uri = _buildUri(baseUrl, '/api/v1/auth/login');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return (token: token, user: user);
      } else {
        final errorMsg = data['error'] as String? ?? 'Giriş başarısız oldu (${response.statusCode})';
        throw AuthException(errorMsg, response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sunucuya bağlanılamadı: $e');
    }
  }

  /// Register a new account with username, email, and password
  Future<({String token, UserModel user})> register({
    required String baseUrl,
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = _buildUri(baseUrl, '/api/v1/auth/register');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return (token: token, user: user);
      } else {
        final errorMsg = data['error'] as String? ?? 'Kayıt başarısız oldu (${response.statusCode})';
        throw AuthException(errorMsg, response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sunucuya bağlanılamadı: $e');
    }
  }

  /// Fetch the authenticated user profile using a JWT token
  Future<UserModel> getProfile({
    required String baseUrl,
    required String token,
  }) async {
    final uri = _buildUri(baseUrl, '/api/v1/auth/me');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return UserModel.fromJson(data);
      } else {
        final errorMsg = data['error'] as String? ?? 'Kullanıcı profili alınamadı (${response.statusCode})';
        throw AuthException(errorMsg, response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sunucuya bağlanılamadı: $e');
    }
  }
}
