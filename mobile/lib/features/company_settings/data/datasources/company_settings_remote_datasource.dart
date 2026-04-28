import '../../../../services/api/api_client.dart';

class CompanySettingsRemoteDataSource {
  CompanySettingsRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getSettings() async => (await _apiClient.get('/company-settings')).data ?? {};

  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> data) async =>
      (await _apiClient.put('/company-settings', data: data)).data ?? {};

  Future<Map<String, dynamic>> resetDefaults() async => (await _apiClient.post('/company-settings/reset')).data ?? {};
}
