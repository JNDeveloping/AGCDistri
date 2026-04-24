import 'package:dio/dio.dart';

import '../../domain/models/company_settings_model.dart';
import '../datasources/company_settings_remote_datasource.dart';

class CompanySettingsRepository {
  CompanySettingsRepository({required CompanySettingsRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final CompanySettingsRemoteDataSource _remoteDataSource;

  Future<CompanySettingsModel> getSettings() async {
    try {
      final payload = await _remoteDataSource.getSettings();
      return CompanySettingsModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw CompanySettingsException(_message(error));
    }
  }

  Future<CompanySettingsModel> saveSettings(CompanySettingsModel settings) async {
    try {
      final payload = await _remoteDataSource.saveSettings(settings.toJson());
      return CompanySettingsModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw CompanySettingsException(_message(error));
    }
  }

  Future<CompanySettingsModel> resetDefaults() async {
    try {
      final payload = await _remoteDataSource.resetDefaults();
      return CompanySettingsModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw CompanySettingsException(_message(error));
    }
  }

  String _message(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en configuración de empresa.';
    }
    return 'No se pudo conectar con configuración de empresa.';
  }
}

class CompanySettingsException implements Exception {
  CompanySettingsException(this.message);
  final String message;
}
