import '../../../../services/api/api_client.dart';

class ReportsRemoteDataSource {
  ReportsRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> summary(Map<String, dynamic> query) async => (await _apiClient.get('/reports/summary', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> sales(Map<String, dynamic> query) async => (await _apiClient.get('/reports/sales', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> profit(Map<String, dynamic> query) async => (await _apiClient.get('/reports/profit', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> topClients(Map<String, dynamic> query) async => (await _apiClient.get('/reports/top-clients', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> topProducts(Map<String, dynamic> query) async => (await _apiClient.get('/reports/top-products', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> debtors(Map<String, dynamic> query) async => (await _apiClient.get('/reports/debtors', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> stock(Map<String, dynamic> query) async => (await _apiClient.get('/reports/stock', queryParameters: query)).data ?? {};
  Future<Map<String, dynamic>> payments(Map<String, dynamic> query) async => (await _apiClient.get('/reports/payments', queryParameters: query)).data ?? {};
}
