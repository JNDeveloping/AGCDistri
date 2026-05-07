import '../../../../services/api/api_client.dart';

class PromotionRemoteDataSource {
  PromotionRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> list({String? q, bool? isActive, String? type}) async =>
      (await _apiClient.get('/promotions', queryParameters: {'q': q, 'isActive': isActive, 'type': type}..removeWhere((k,v)=>v==null||v==''))).data ?? {};
  Future<Map<String, dynamic>> getById(String id) async => (await _apiClient.get('/promotions/$id')).data ?? {};
  Future<void> create(Map<String, dynamic> data) async => _apiClient.post('/promotions', data: data);
  Future<void> update(String id, Map<String, dynamic> data) async => _apiClient.put('/promotions/$id', data: data);
  Future<void> archive(String id) async => _apiClient.delete('/promotions/$id');
  Future<void> toggle(String id) async => _apiClient.post('/promotions/$id/toggle');
}
