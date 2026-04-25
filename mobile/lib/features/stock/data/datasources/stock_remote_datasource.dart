import '../../../../services/api/api_client.dart';

class StockRemoteDataSource {
  StockRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> list({String? q, bool lowStock = false, bool outOfStock = false}) async =>
      (await _apiClient.get('/stock', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (lowStock) 'lowStock': true,
        if (outOfStock) 'outOfStock': true,
      })).data ?? {};

  Future<Map<String, dynamic>> detail(String productId) async => (await _apiClient.get('/stock/products/$productId')).data ?? {};
  Future<Map<String, dynamic>> movements(String productId) async => (await _apiClient.get('/stock/products/$productId/movements')).data ?? {};

  Future<Map<String, dynamic>> adjust(Map<String, dynamic> payload) async => (await _apiClient.post('/stock/adjust', data: payload)).data ?? {};
}
