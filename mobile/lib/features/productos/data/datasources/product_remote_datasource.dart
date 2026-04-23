import '../../../../services/api/api_client.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProducts({required String query, bool? isActive, bool? lowStock}) async {
    final response = await _apiClient.get(
      '/productos',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
        if (isActive != null) 'isActive': isActive,
        if (lowStock != null && lowStock) 'lowStock': true,
      },
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getProduct(String id) async => (await _apiClient.get('/productos/$id')).data ?? {};
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async => (await _apiClient.post('/productos', data: data)).data ?? {};
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async => (await _apiClient.put('/productos/$id', data: data)).data ?? {};
  Future<Map<String, dynamic>> deactivateProduct(String id) async => (await _apiClient.patch('/productos/$id/deactivate')).data ?? {};
}
