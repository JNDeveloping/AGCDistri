import 'package:dio/dio.dart';

import '../../../../services/storage/token_storage.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final payload = await _remoteDataSource.login(email: email, password: password);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const FormatException('Respuesta inválida del servidor.');
      }

      final session = AuthSession.fromJson(data);
      await _tokenStorage.save(session.token);
      return session;
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message'] as String? ?? 'Error de autenticación.')
          : 'Error de autenticación.';
      throw AuthException(message);
    }
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final payload = await _remoteDataSource.me();
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        await _tokenStorage.clear();
        return null;
      }

      final user = AuthUser(
        id: data['id'] as String,
        fullName: data['fullName'] as String,
        email: data['email'] as String,
        role: data['role'] as String,
        permissions: const [],
      );

      return AuthSession(token: token, user: user);
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}
