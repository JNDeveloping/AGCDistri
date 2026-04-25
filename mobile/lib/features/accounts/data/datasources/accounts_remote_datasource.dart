import '../../../../services/api/api_client.dart';

class AccountsRemoteDataSource {
  AccountsRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> account(String clientId) async => (await _apiClient.get('/clients/$clientId/account')).data ?? {};
  Future<Map<String, dynamic>> movements(String clientId, {String? type, String? dateFrom, String? dateTo}) async =>
      (await _apiClient.get('/clients/$clientId/account-movements', queryParameters: {
        if (type != null) 'type': type,
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      })).data ?? {};

  Future<Map<String, dynamic>> createMovement(String clientId, Map<String, dynamic> data) async => (await _apiClient.post('/clients/$clientId/account-movements', data: data)).data ?? {};
  Future<Map<String, dynamic>> adjust(String clientId, Map<String, dynamic> data) async => (await _apiClient.post('/clients/$clientId/account-adjustment', data: data)).data ?? {};

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async => (await _apiClient.post('/client-payments', data: data)).data ?? {};
}
