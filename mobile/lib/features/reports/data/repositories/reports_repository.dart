import 'package:dio/dio.dart';

import '../datasources/reports_remote_datasource.dart';

class ReportsRepository {
  ReportsRepository({required ReportsRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;

  final ReportsRemoteDataSource _remote;

  Future<Map<String, dynamic>> summary(Map<String, dynamic> query) => _safe(() async => (await _remote.summary(query))['data'] as Map<String, dynamic>? ?? {});
  Future<Map<String, dynamic>> sales(Map<String, dynamic> query) => _safe(() async => (await _remote.sales(query))['data'] as Map<String, dynamic>? ?? {});
  Future<Map<String, dynamic>> profit(Map<String, dynamic> query) => _safe(() async => (await _remote.profit(query))['data'] as Map<String, dynamic>? ?? {});
  Future<Map<String, dynamic>> topClients(Map<String, dynamic> query) => _safe(() async => (await _remote.topClients(query))['data'] as Map<String, dynamic>? ?? {});
  Future<Map<String, dynamic>> topProducts(Map<String, dynamic> query) => _safe(() async => (await _remote.topProducts(query))['data'] as Map<String, dynamic>? ?? {});
  Future<Map<String, dynamic>> debt(Map<String, dynamic> query) => _safe(() async => (await _remote.debt(query))['data'] as Map<String, dynamic>? ?? {});
  Future<List<Map<String, dynamic>>> stock(Map<String, dynamic> query) => _safe(() async => ((await _remote.stock(query))['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
  Future<Map<String, dynamic>> payments(Map<String, dynamic> query) => _safe(() async => (await _remote.payments(query))['data'] as Map<String, dynamic>? ?? {});
  Future<List<Map<String, dynamic>>> zones(Map<String, dynamic> query) => _safe(() async => ((await _remote.zones(query))['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());

  Future<T> _safe<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response?.data as Map<String, dynamic>;
        throw Exception((data['message'] as String?) ?? 'Error al obtener reportes.');
      }
      throw Exception('No se pudo conectar con reportes.');
    }
  }
}
