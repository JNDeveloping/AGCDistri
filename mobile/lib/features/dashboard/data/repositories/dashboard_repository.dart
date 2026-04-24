import 'package:dio/dio.dart';

import '../../domain/models/dashboard_stats.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepository {
  DashboardRepository({required DashboardRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final DashboardRemoteDataSource _remoteDataSource;

  Future<DashboardStats> fetchStats() async {
    try {
      final payload = await _remoteDataSource.fetchStats();
      return DashboardStats.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      if (error.response?.data is Map<String, dynamic>) {
        throw DashboardException(error.response?.data['message'] as String? ?? 'No se pudo cargar dashboard.');
      }

      throw DashboardException('No se pudo cargar dashboard.');
    }
  }
}

class DashboardException implements Exception {
  DashboardException(this.message);
  final String message;
}
