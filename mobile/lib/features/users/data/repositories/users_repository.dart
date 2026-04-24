import 'package:dio/dio.dart';

import '../../domain/models/app_user.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepository {
  UsersRepository({required UsersRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final UsersRemoteDataSource _remoteDataSource;

  Future<List<AppUser>> list() async {
    try {
      final payload = await _remoteDataSource.listUsers();
      return (payload['data'] as List<dynamic>? ?? [])
          .map((raw) => AppUser.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw UsersException(_message(error));
    }
  }

  Future<void> save({String? id, required String fullName, required String email, required String role, String? password}) async {
    try {
      final payload = {
        'fullName': fullName,
        'email': email,
        'role': role,
        if (password != null && password.isNotEmpty) 'password': password,
      };

      if (id == null) {
        await _remoteDataSource.createUser(payload);
      } else {
        await _remoteDataSource.updateUser(id, payload);
      }
    } on DioException catch (error) {
      throw UsersException(_message(error));
    }
  }

  Future<void> deactivate(String id) async {
    try {
      await _remoteDataSource.deactivateUser(id);
    } on DioException catch (error) {
      throw UsersException(_message(error));
    }
  }

  String _message(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en usuarios.';
    }
    return 'No se pudo conectar con usuarios.';
  }
}

class UsersException implements Exception {
  UsersException(this.message);
  final String message;
}
