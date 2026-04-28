import '../../../../services/api/api_client.dart';

class CreditNoteRemoteDataSource {
  CreditNoteRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listByOrder(String orderId) async {
    final response = await _apiClient.get('/orders/$orderId/credit-notes');
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _apiClient.get('/credit-notes/$id');
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/credit-notes', data: data);
    return response.data ?? {};
  }
}
