import '../../../../services/api/api_client.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _apiClient.get('/dashboard');
    return response.data ?? {};
  }
}
